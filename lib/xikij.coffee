{XikijClient, Xikij, util} = require "xikij"
{EditorRequest} = require './editor-request'
#atom = require 'atom'

INDENT = "  "

getUserHome = () -> process.env.HOME || process.env.USERPROFILE

module.exports =
  configDefaults:
    userDir:             getUserHome()
    xikijUserDirName:    ".xikij"
    xikijProjectDirName: ".xikij"

  activate: (state) ->
    @xikij = null
    @processing = {}
    @prompts = []
    @cursorObservers = {}

    #@xikijView = new XikijView(state.xikijViewState)
    atom.commands.add "atom-workspace", "xikij:toggle", => @toggle()
    atom.commands.add "atom-workspace", "xikij:run", => @toggleContent()
    atom.commands.add "atom-workspace", "xikij:goto-level-up", => @gotoLevelUp()
    atom.commands.add "atom-workspace", "xikij:goto-level-up-and-run-with-input", =>
      @gotoLevelUp()
      @toggleContent withInput: true

    atom.commands.add "atom-workspace", "xikij:item-get-help", =>
      @toggleContent append: "?"

    atom.commands.add "atom-workspace", "xikij:item-get-attributes", =>
      @toggleContent append: "*"

    atom.commands.add "atom-workspace", "xikij:run-with-prompt", =>
      @toggleContent withPrompt: true

    atom.commands.add "atom-workspace", "xikij:run-with-input", =>
      @toggleContent withInput: true

    @toggle()

  isProcessing: ->
    for k,v of @processing
      return true
    return false

  # attach .xikij class to workspace view and manage cursor observers
  toggle: ->
    wv = atom.views.getView(atom.workspace)
    if "xikij" in wv.classList
      wv.classList.remove("xikij")

      for k,v of @cursorObservers
        v.dispose()

      @cursorObservers = {}
      @editorObserver.dispose()
      @editorObserver = null

    else
      wv.classList.add("xikij")
      @xikij = new XikijClient
      # have to reload this from time to time maybe interval of some seconds
      @xikij.getPrompts().then (prompts) =>
        @prompts = prompts

      @editorObserver = atom.workspace.observeTextEditors (editor) =>
        observer = editor.onDidChangeCursorPosition (event) =>
          # find out if cursor in a xikijResponse in.  If so, highlight it
          # in gutter.

          # rather do editor.getDecorations class: "xikij-response"
          newRow = event.newBufferPosition.row
          markers = editor.findMarkers xikijResponse: yes, containsBufferPosition: [newRow, 0]

          if markers.length
            smallest = markers[0]
            smallest_rc = smallest.getBufferRange().getRowCount()

            for marker in markers
              rc = marker.getBufferRange().getRowCount()
              if rc < smallest_rc
                smallest_rc = rc
                smallest = marker

        @cursorObservers[editor.id] = observer

        editor.onDidDestroy () =>
          observer.dispose()
          delete @cursorObservers[editor.id]

  request: (request, args...) ->
    request.args = {} unless request.args?
    unless request.args.filePath?
      request.args.filePath = atom.workspace.getActiveTextEditor().getPath()

    @xikij.request request, args...

  getBody: (row, opts={}) ->
    editor   = opts.editor ? atom.workspace.getActiveTextEditor()
    startRow = row

    xikiNodePath = []

    until row < 0
      curRow = row--
      line = editor.lineTextForBufferRow(curRow)

      xikiNodePath.unshift line

      if /^\s*$/.test line
        continue

      break if editor.indentationForBufferRow(curRow) == 0

    return xikiNodePath.join("\n")+"\n"

    # buffer = editor.getBuffer()
    #
    # nextNonBlankRow = buffer.nextNonBlankRow(startRow+1)
    #
    # curIndent  = editor.indentationForBufferRow(startRow)
    #
    # if startRow+1 < editor.getLineCount()
    #   nextIndent = editor.indentationForBufferRow(startRow+1)
    #   nextLine   = editor.lineTextForBufferRow(startRow+1)
    # else
    #   nextIndent = curIndent
    #   nextNoneBlankRow = startRow
    #
    # if nextNonBlankRow
    #   nonbIndent = editor.indentationForBufferRow(nextNonBlankRow)
    # else
    #   nonbIndent = nextIndent
    #   nextNonBlankRow = startRow




  gotoLevelUp: ->
    editor = atom.workspace.getActiveTextEditor()
    for cursor,i in editor.getCursors()
      startRow = cursor.getBufferRow()
      startIndent = editor.indentationForBufferRow(startRow)

      continue if startIndent == 0

      curRow = row = startRow
      until row <= 0
        line = editor.lineTextForBufferRow(row)
        curRow = row--
        continue if line is ""
        break if startIndent > editor.indentationForBufferRow(curRow)

      cursor.setBufferPosition([curRow, 0])

      #console.log "cursor", i, cursor

  toggleContent: (opts) ->
    {withPrompt, withInput, append} = opts ? {}
    editor = atom.workspace.getActiveTextEditor()
    return unless editor

    # collect nodePath
    indentationLevel = 1
    rows = []
    for cursor,i in editor.getCursors()
      startRow = cursor.getBufferRow()
      continue if startRow in rows

      # if withPrompt
      #     pos = cursor.getBufferPosition()
      #
      #
      #
      #
      #     console.debug "scopes", scopes
      #     isCommand = false
      #     for scope in scopes
      #       if scope.match /\.command/
      #         isCommand = true
      #         break
      #     console.debug "isCommand", isCommand
      #
      #     if not isCommand
      #       row = cursor.getBufferRow()
      #       indentLevel = editor.indentationForBufferRow(row)
      #       editor.getBuffer().insert pos, "\n", normalizeLineEndings: true
      #       #cursor.moveDown()
      #       console.debug "inserted newline"
      #       editor.setIndentationForBufferRow(row+1, indentLevel)
      #       cursor.moveToEndOfLine()
      #       return

      # is this needed?
      #cursor.setBufferPosition([startRow, 0])

      # put row number on list of processed rows
      rows.push startRow

      console.log "============ xikij request"

      opts = {atomXikij: @, editor, cursor, startRow, withInput, withPrompt, append}
      req  = new EditorRequest(opts)
      req.run()

  deactivate: ->

  serialize: ->
