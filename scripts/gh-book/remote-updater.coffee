define [
  'jquery'
  'cs!session'
  'cs!collections/content'
], ($, session, allContent) ->

  UPDATE_TIMEOUT = 15 * 1000 # Update 15 seconds

  # Returns a promise that is resolved once all promises in the array `promises`
  # are resolved.
  onceAll = (promises) -> return $.when.apply($, promises)

  return new class RemoteUpdater
    # This is updated every time the Remote Updater fetches
    lastSeenSha: null

    initialize: () ->
      # If the session config changes then clear the lastSeenSha because it may point to a different repo
      session.on 'change', () =>
        @lastSeenSha = null

    start: () ->
      # Get the current repo and last commit
      # Periodically check the commits list
      # If there are new commits
      #  invalidate the .loaded variable on content
      #  and if it has been loaded, reload

      @keepUpdating = true

      # Return a promise that is resolved once a start hash has been recorded
      # Note: This promise may still fail
      @_runningPromise = @pollUpdates()
      return @_runningPromise

    stop: () ->
      @keepUpdating = false
      @_runningPromise and @_runningPromise.timeoutId and clearTimeout(@_runningPromise.timeoutId)
      promise = @_runningPromise or (new $.Deferred()).resolve(@)

      return promise.always () =>
        @lastSeenSha = null


    # Returns a promise that is resolved when `@lastSeenSha` has been set.
    pollUpdates: () ->
      return if not @keepUpdating

      throw new Error('BUG! remoteUpdater seems to be running twice. did you change repos?') if @_runningPromise
      @_runningPromise = allContent.load().then () =>
        branch = session.getBranch()

        return branch.getCommits().then (commits) =>
          lastUpdatedSha = @lastSeenSha

          lastSeenSha = commits[0].sha

          if not lastUpdatedSha
            @lastSeenSha = lastSeenSha
            return

          # If the commit sha's differ then someone has committed (maybe us)
          if lastUpdatedSha == lastSeenSha
            @lastSeenSha = lastSeenSha
          else

            commitsPromises = for commitItem in commits
              # Stop updating once we hit the lastUpdatedSha (everything after has old)
              break if lastUpdatedSha == commitItem.sha

              branch.getCommit(commitItem.sha).then (commit) =>

                commitSha = commit.sha
                dateCommittedUTC = commit.commit.author.date

                # Collect all the model load (and update) promises
                # so the `lastSeenSha` is updated after they have been updated
                promises = _.compact _.map commit.files, (file) =>
                  filePath = file.filename
                  model = allContent.get(filePath)

                  if model?._loading
                    # TODO: Just invalidate the model by clearing `isLoaded`
                    return model.reload().then () =>
                      attributes =
                        dateLastModifiedUTC: dateCommittedUTC
                        lastEditedBy: commit.author.login

                      return model.set attributes, {parse:true}

                return onceAll(promises)

            return onceAll(commitsPromises).then () => @lastSeenSha = lastSeenSha

      return @_runningPromise.always () =>
        @_runningPromise and @_runningPromise.timeoutId and clearTimeout(@_runningPromise.timeoutId)
        @_runningPromise = false
      .then () =>
        @_runningPromise.timeoutId = setTimeout (() => @pollUpdates()), UPDATE_TIMEOUT if @keepUpdating

