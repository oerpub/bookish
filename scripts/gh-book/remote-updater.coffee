define [
  'session'
  'collections/content'
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
      @_pollUpdates()

    stop: () -> @keepUpdating = false


    _pollUpdates: () ->
      return if not @keepUpdating

      branch = session.getBranch()

      branch.getCommits().done (commits) =>
        lastUpdatedSha = @lastSeenSha

        @lastSeenSha = commits[0].sha

        # If the commit sha's differ then someone has committed (maybe us)
        if lastUpdatedSha != @lastSeenSha

          for commitItem in commits
            # Stop updating once we hit the lastUpdatedSha (everything after has old)
            break if lastUpdatedSha == commitItem.sha

            branch.getCommit(commitItem.sha).done (commit) =>
              for file in commit.files
                fileSha = file.sha
                filePath = file.filename
                allContent.load().done () =>
                  model = allContent.get(filePath)
                  if model
                    modelSha = model.get('sha')
                    if modelSha and fileSha and modelSha != fileSha
                      # TODO: Just invalidate the model by clearing `isLoaded`
                      model.reload()

      setTimeout (() => @_pollUpdates()), UPDATE_TIMEOUT


