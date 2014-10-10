{XikijClient, Xikij, util} = require "xikij"
{EditorRequest} = require './editor-request'
fs = require 'atom'

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

    #@xikijView = new XikijView(state.xikijViewState)
    atom.workspaceView.command "xikij:toggle", => @toggle()
    atom.workspaceView.command "xikij:run", => @toggleContent()
    atom.workspaceView.command "xikij:goto-level-up", => @gotoLevelUp()
    atom.workspaceView.command "xikij:goto-level-up-and-run-with-input", =>
      @gotoLevelUp()
      @toggleContent withInput: true
    atom.workspaceView.command "xikij:run-with-prompt", =>
      @toggleContent withPrompt: true

    atom.workspaceView.command "xikij:run-with-input", =>
      @toggleContent withInput: true

    @toggle()

  isProcessing: ->
    for k,v of @processing
      return true
    return false

  toggle: ->

    $wv = atom.workspaceView
    if $wv.hasClass "xikij"
      $wv.removeClass "xikij"
      #@xikij.shutdown()

    else
      $wv.addClass "xikij"
      @xikij = new XikijClient

  request: (request, args...) ->
    request.args = {} unless request.args?
    unless request.args.filePath?
      request.args.filePath = atom.workspace.getActiveEditor().getPath()

    @xikij.request request, args...

  getBody: (row, opts={}) ->
    editor   = opts.editor ? atom.workspace.getActiveEditor()
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
    editor = atom.workspace.getActiveEditor()
    for cursor,i in editor.getCursors()
      startRow = cursor.getBufferRow()
      startIndent = editor.indentationForBufferRow(startRow)

      continue if startIndent == 0

      curRow = row = startRow
      until row <= 0
        line = editor.lineForBufferRow(row)
        curRow = row--
        continue if line is ""
        break if startIndent > editor.indentationForBufferRow(curRow)

      cursor.setBufferPosition([curRow, 0])

      #console.log "cursor", i, cursor

  toggleContent: (opts) ->
    {withPrompt, withInput} = opts ? {}
    editor = atom.workspace.getActiveEditor()
    return unless editor

    # collect nodePath
    indentationLevel = 1
    rows = []
    for cursor,i in editor.getCursors()
      startRow = cursor.getBufferRow()
      continue if startRow in rows

      cursor.setBufferPosition([startRow, 0])

      # put row number on list of processed rows
      rows.push startRow

      opts = {atomXikij: @, editor, cursor, startRow, withInput, withPrompt}
      req  = new EditorRequest(opts)
      req.run()

  deactivate: ->

  serialize: ->
