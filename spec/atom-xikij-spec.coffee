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
      #expect(atom.workspaceView.find('.xikij')).not.toExist()

      # This is an activation event, triggering it will cause the package to be
      # activated.
      atom.workspaceView.trigger 'xikij:toggle'

      waitsForPromise ->
        activationPromise

      runs ->
        expect(atom.workspaceView.hasClass('xikij')).toBe false
        atom.workspaceView.trigger 'xikij:toggle'
        expect(atom.workspaceView.hasClass('xikij')).toBe true

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
        atom.workspace.open(filename).then (o) ->
          editor = o
          editor.getBuffer().setText("")


    it "runs xiki and inserts its output into lines after request line", ->

      runs ->
        editor.insertText "hostname\n"
        editor.setCursorBufferPosition([0,0])

        debugger

        atom.workspaceView.trigger 'xikij:run'

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

        atom.workspaceView.trigger "xikij:run"

        waitsFor ->
          not xikij.isProcessing()

        runs ->
          expect editor.getText()
            .toBe """
              - first line
                + second line\n
            """

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
        editor.setCursorBufferPosition([2,0])

        atom.workspaceView.trigger "xikij:run"

        waitsFor ->
          not xikij.isProcessing()

        runs ->
          expect editor.getText()
            .toBe """
              - first line
                - second line
                  here is some

                  input, with an empty line
                  in-between\n
            """

    it "can execute commands", ->

      runs ->
        editor.insertText """
          $ echo "hello world"
        """
        editor.setCursorBufferPosition([0,0])

        atom.workspaceView.trigger "xikij:run"

        waitsFor ->
          not xikij.isProcessing()

        runs ->
          expected =  """
              $ echo "hello world"
                hello world\n
            """
          text = editor.getText()
          expect text
            .toEqual expected

    it "can process input", ->
      runs ->
        text = """
          $ cat
            hello world\n
        """
        editor.insertText text
        editor.setCursorBufferPosition([0,0])

        atom.workspaceView.trigger "xikij:run-with-input"

        waitsFor ->
          not xikij.isProcessing()

        runs ->
          expect(editor.getText()).toEqual text
