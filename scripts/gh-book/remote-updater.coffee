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

    start: () ->
      # Get the current repo and last commit
      # Periodically check the commits list
      # If there are new commits
      #  invalidate the .loaded variable on content
      #  and if it has been loaded, reload

      @keepUpdating = true

      # Return a promise that is resolved once a start hash has been recorded
      # Note: This promise may still fail
      return @pollUpdates()

    stop: () -> @keepUpdating = false


    # Returns a promise that is resolved when `@lastSeenSha` has been set.
    pollUpdates: () ->
      return if not @keepUpdating

      return allContent.load().then () =>
        branch = session.getBranch()

        return branch.getCommits().then (commits) =>
          lastUpdatedSha = @lastSeenSha

          lastSeenSha = commits[0].sha

          setTimeout (() => @pollUpdates()), UPDATE_TIMEOUT

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

                  if model
                    modelSha = model.blobSha
                    if modelSha and commitSha and modelSha != commitSha
                      # TODO: Just invalidate the model by clearing `isLoaded`
                      return model.reload().then () =>
                        attributes =
                          dateLastModifiedUTC: dateCommittedUTC
                          lastEditedBy: commit.author.login

                        return model.set attributes, {parse:true}

                return onceAll(promises)

            return onceAll(commitsPromises).then () => @lastSeenSha = lastSeenSha
