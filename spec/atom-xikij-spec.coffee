{WorkspaceView} = require 'atom'
Xikij = require '../lib/xikij'

# Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block.

describe "Xikij", ->
  activationPromise = null

  beforeEach ->
    atom.workspaceView = new WorkspaceView
    activationPromise = atom.packages.activatePackage('xikij')

  describe "when the xikij:toggle event is triggered", ->
    it "attaches and then detaches the view", ->
      expect(atom.workspaceView.find('.xikij')).not.toExist()

      # This is an activation event, triggering it will cause the package to be
      # activated.
      atom.workspaceView.trigger 'xikij:toggle'

      waitsForPromise ->
        activationPromise

      runs ->
        expect(atom.workspaceView.hasClass('xikij')).toBe true
        atom.workspaceView.trigger 'xikij:toggle'
        expect(atom.workspaceView.hasClass('xikij')).toBe false

  describe "basic features", ->
    editor = null
    xikij  = null

    beforeEach ->
      atom.workspaceView.trigger 'xikij:toggle'

      waitsForPromise ->
        activationPromise

      waitsForPromise ->
        xikij = activationPromise.valueOf().mainModule
        filename = "#{__dirname}/fixtures/newfile.md"
        atom.workspace.open(filename).then (o) -> editor = o


    it "runs xiki and inserts its output into lines after request line", ->

      runs ->
        editor.insertText "hostname\n"
        editor.setCursorBufferPosition([0,0])
        atom.workspaceView.trigger 'xikij:toggle-content'

        waitsFor ->
          not xikij.isProcessing()

        runs ->
          os = require "os"
          expect editor.getBuffer().lineForRow(1)
            .toBe "  #{os.hostname()}"

    it "collapses lines", ->

      runs ->
        editor.insertText """
          - first line
            - second line
              here is some
                 indented

              input, with an empty line
              in-between\n
          """
        editor.setCursorBufferPosition([1,0])

        atom.workspaceView.trigger "xikij:toggle-content"

        waitsFor ->
          not xikij.isProcessing()

        runs ->
          expect editor.getText()
            .toBe """
              - first line
                - second line
            """

    it "can execute commands", ->

      runs ->
        editor.insertText """
          $ echo "hello world"
        """
        editor.setCursorBufferPosition([0,0])

        atom.workspaceView.trigger "xikij:toggle-content"

        waitsFor ->
          not xikij.isProcessing()

        runs ->
          expect editor.getText()
            .toBe """
              $ echo "hello world"
                hello world\n
            """
