# Copyright (c) 2013 Rice University
#
# This software is subject to the provisions of the GNU AFFERO GENERAL PUBLIC LICENSE Version 3.0 (AGPL).
# See LICENSE.txt for details.

# Checks editing the Metadata and Roles popups.
# Uses global jasmine functions like `describe`, `beforeEach`, `it`, and `expect`.
define ['bookish/models', 'bookish/views', 'test/routes'], (Models, Views, MOCK_CONTENT) ->

  describe 'Edit Metadata/Roles', ->
    beforeEach ->
      @model = new Models.Content()
      @model.set MOCK_CONTENT

      @metadataView = new Views.MetadataEditView(model: @model)
      @rolesView    = new Views.RolesEditView(model: @model)

      @metadataModal = new Views.ModalWrapper(@metadataView, 'Edit Metadata (test)')
      @rolesModal    = new Views.ModalWrapper(@rolesView, 'Edit Roles (test)')

    describe '(Sanity Check) All Views', ->
      it 'should have a .$el', ->
        expect(@metadataView.$el  ).not.toBeFalsy()
        expect(@rolesView.$el     ).not.toBeFalsy()
        expect(@metadataModal.view).not.toBeFalsy()
        expect(@rolesModal.view  ).not.toBeFalsy()
      it 'should initially be hidden', ->
        expect(@metadataView.$el.is(':visible')).toEqual false
      it 'should show without errors', ->
        expect(@metadataModal.show.bind(@metadataModal)).not.toThrow()
        expect(@metadataModal.hide.bind(@metadataModal)).not.toThrow()
        expect(@rolesModal.show.bind(@rolesModal)      ).not.toThrow()
        expect(@rolesModal.hide.bind(@rolesModal)      ).not.toThrow()
