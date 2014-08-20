{XikijClient, Xikij, util} = require "xikij"
{EditorRequest} = require './editor-request'

INDENT = "  "

module.exports =
  xikijView: null

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

  request: (args...) ->
    @xikij.request args...

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
