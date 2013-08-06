define [
  'cs!session'
  'cs!collections/content'
], (session, allContent) ->

  UPDATE_TIMEOUT = 60 * 1000 # Update every minute

  return new class RemoteUpdater
    start: () ->
      # Get the current repo and last commit
      # Periodically check the commits list
      # If there are new commits
      #  invalidate the .loaded variable on content
      #  and if it has been loaded, reload

      @keepUpdating = true

      # Return a promise that is resolved once a start hash has been recorded
      # Note: This promise may still fail
      return @_pollUpdates()

    stop: () -> @keepUpdating = false


    # Returns a promise that is resolved when `@lastSeenSha` has been set.
    _pollUpdates: () ->
      return if not @keepUpdating

      branch = session.getBranch()

      return branch.getCommits().done (commits) =>
        lastUpdatedSha = @lastSeenSha

        @lastSeenSha = commits[0].sha

        setTimeout (() => @_pollUpdates()), UPDATE_TIMEOUT

        return if not lastUpdatedSha

        # If the commit sha's differ then someone has committed (maybe us)
        if lastUpdatedSha != @lastSeenSha

          for commitItem in commits
            # Stop updating once we hit the lastUpdatedSha (everything after has old)
            break if lastUpdatedSha == commitItem.sha

            branch.getCommit(commitItem.sha).done (commit) =>

              commitSha = commit.sha
              dateCommittedUTC = commit.commit.author.date

              for file in commit.files
                filePath = file.filename
                allContent.load().done () =>
                  model = allContent.get(filePath)
                  if model
                    modelSha = model.commitSha
                    if modelSha and commitSha and modelSha != commitSha
                      # TODO: Just invalidate the model by clearing `isLoaded`
                      model.reload().done () =>
                        attributes =
                          dateLastModifiedUTC: dateCommittedUTC
                          lastEditedBy: commit.author.login

                        model.set attributes, {parse:true}




