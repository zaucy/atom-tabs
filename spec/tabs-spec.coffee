$ = require 'jquery'
_ = require 'underscore'
RootView = require 'root-view'
Tabs = require 'tabs'
fs = require 'fs'

describe "Tabs", ->
  [rootView, editor, statusBar, buffer, tabs] = []

  beforeEach ->
    rootView = new RootView(require.resolve('fixtures/sample.js'))
    rootView.open('sample.txt')
    rootView.simulateDomAttachment()
    atom.loadPackage("tabs")
    editor = rootView.getActiveEditor()
    tabs = rootView.find('.tabs').view()

  afterEach ->
    rootView.remove()

  describe "@activate", ->
    it "appends a status bear to all existing and new editors", ->
      expect(rootView.panes.find('.pane').length).toBe 1
      expect(rootView.panes.find('.pane > .tabs').length).toBe 1
      editor.splitRight()
      expect(rootView.find('.pane').length).toBe 2
      expect(rootView.panes.find('.pane > .tabs').length).toBe 2

  describe "#initialize()", ->
    it "creates a tab for each edit session on the editor to which the tab-strip belongs", ->
      expect(editor.editSessions.length).toBe 2
      expect(tabs.find('.tab').length).toBe 2

      expect(tabs.find('.tab:eq(0) .file-name').text()).toBe editor.editSessions[0].buffer.getBaseName()
      expect(tabs.find('.tab:eq(1) .file-name').text()).toBe editor.editSessions[1].buffer.getBaseName()

    it "highlights the tab for the current active edit session", ->
      expect(editor.getActiveEditSessionIndex()).toBe 1
      expect(tabs.find('.tab:eq(1)')).toHaveClass 'active'

  describe "when the active edit session changes", ->
    it "highlights the tab for the newly-active edit session", ->
      editor.setActiveEditSessionIndex(0)
      expect(tabs.find('.active').length).toBe 1
      expect(tabs.find('.tab:eq(0)')).toHaveClass 'active'

      editor.setActiveEditSessionIndex(1)
      expect(tabs.find('.active').length).toBe 1
      expect(tabs.find('.tab:eq(1)')).toHaveClass 'active'

  describe "when a new edit session is created", ->
    it "adds a tab for the new edit session", ->
      rootView.open('two-hundred.txt')
      expect(tabs.find('.tab').length).toBe 3
      expect(tabs.find('.tab:eq(2) .file-name').text()).toBe 'two-hundred.txt'

    describe "when the edit session's buffer has an undefined path", ->
      it "makes the tab text 'untitled'", ->
        rootView.open()
        expect(tabs.find('.tab').length).toBe 3
        expect(tabs.find('.tab:eq(2) .file-name').text()).toBe 'untitled'

  describe "when an edit session is removed", ->
    it "removes the tab for the removed edit session", ->
      editor.setActiveEditSessionIndex(0)
      editor.destroyActiveEditSession()
      expect(tabs.find('.tab').length).toBe 1
      expect(tabs.find('.tab:eq(0) .file-name').text()).toBe 'sample.txt'

  describe "when a tab is clicked", ->
    it "activates the associated edit session", ->
      expect(editor.getActiveEditSessionIndex()).toBe 1
      tabs.find('.tab:eq(0)').click()
      expect(editor.getActiveEditSessionIndex()).toBe 0
      tabs.find('.tab:eq(1)').click()
      expect(editor.getActiveEditSessionIndex()).toBe 1

  describe "when a file name associated with a tab changes", ->
    [buffer, oldPath, newPath] = []

    beforeEach ->
      buffer = editor.editSessions[0].buffer
      oldPath = "/tmp/file-to-rename.txt"
      newPath = "/tmp/renamed-file.txt"
      fs.write(oldPath, "this old path")
      rootView.open(oldPath)

    afterEach ->
      fs.remove(newPath) if fs.exists(newPath)

    it "updates the file name in the tab", ->
      tabFileName = tabs.find('.tab:eq(2) .file-name')
      expect(tabFileName).toExist()
      editor.setActiveEditSessionIndex(0)
      fs.move(oldPath, newPath)
      waitsFor "file to be renamed", ->
        tabFileName.text() == "renamed-file.txt"

  describe "when the close icon is clicked", ->
    it "closes the selected non-active edit session", ->
      activeSession = editor.activeEditSession
      expect(editor.getActiveEditSessionIndex()).toBe 1
      tabs.find('.tab .close-icon:eq(0)').click()
      expect(editor.getActiveEditSessionIndex()).toBe 0
      expect(editor.activeEditSession).toBe activeSession

    it "closes the selected active edit session", ->
      firstSession = editor.getEditSessions()[0]
      expect(editor.getActiveEditSessionIndex()).toBe 1
      tabs.find('.tab .close-icon:eq(1)').click()
      expect(editor.getActiveEditSessionIndex()).toBe 0
      expect(editor.activeEditSession).toBe firstSession