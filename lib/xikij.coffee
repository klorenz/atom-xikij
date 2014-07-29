#XikijView = require './xikij-view'

{XikijClient, Xikij} = require "xikij"

module.exports =
  xikijView: null

  activate: (state) ->
    @xikij = null
    @processing = {}
    @requestId = 1

    #@xikijView = new XikijView(state.xikijViewState)
    atom.workspaceView.command "xikij:toggle", => @toggle()
    atom.workspaceView.command "xikij:toggle-content", => @toggleContent()
    atom.workspaceView.command "xikij:toggle-content-with-prompt", =>
      @toggleContent withPrompt: true

    atom.workspaceView.command "xikij:toggle-content-with-input", =>
      @toggleContent withInput: true

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

  toggleContent: (opts) ->
    {withPrompt, withInput} = opts ? {}
    editor = atom.workspace.getActiveEditor()
    return unless editor

    indentationLevel = 1
    rows = []
    for cursor in editor.getCursors()
      startRow = cursor.getBufferRow()
      continue if startRow in rows

      # put row number on list of processed rows
      rows.push startRow

      xikiNodePath = []
      row = startRow
      until row < 0
        curRow = row--
        line = editor.lineForBufferRow(curRow)

        xikiNodePath.unshift line

        continue if /^\s*$/.test line

        break if editor.indentationForBufferRow(curRow) == 0

      body = xikiNodePath.join("\n")+"\n"

      if startRow+1 < editor.getLineCount() and not withInput
        curIndent = editor.indentationForBufferRow(startRow)
        if curIndent < editor.indentationForBufferRow(startRow+1)

          @_handleRequest cursor, editor, body, "collapse", (request, response, done) =>
            console.log "->", response

            endRow = startRow+1
            console.log "endRow", endRow
            loop
              endRow++
              break if endRow >= editor.getLineCount()

              continue if editor.lineForBufferRow(endRow) == ""
              break if curIndent > editor.indentationForBufferRow(endRow)

            console.log "delete rows", startRow+1, endRow-1
            editor.getBuffer().deleteRows(startRow+1, endRow-1)
            console.log editor.getText()

            done()

          continue

      @_handleRequest cursor, editor, body, "expand", (request, response, done) =>
        
        if response.type is "stream"
          isFirst = true
          response.data
            .on "data", (data) ->
              if isFirst
                prefix = "  "
                isFirst = false
              else
                prefix = ""

              text = prefix + data.toString().replace "\n", "\n  "
              editor.getBuffer().insert(request.range.end, text)

            .on "end", ->
              debugger
              request.cursor.setBufferPosition request.args.position
              done()
        else
          text = "  "+response.data.toString().replace "\n", "\n  "
          editor.getBuffer().insert(request.range.end, text)
          done()
        # unless line does not end with newline, insert it herekjk

  _handleRequest: (cursor, editor, body, action, callback) ->
      args = {
        projectDirs: [ atom.project.rootDirectory.path ]
        fileName: editor.getBuffer().file.path
        position: cursor.getBufferPosition()
      }

      range = cursor.getCurrentLineBufferRange includeNewline: yes
      mark = editor.markBufferRange(range)

      id = @requestId++
      @processing[id] = request = {body, args, action, mark, range, cursor}
      @processing[id].id = id

      @xikij.request {body, args, action}, (response) =>
        callback request, response, =>
          # console.log response
          # text = "  "+response.data.replace "\n", "\n  "
          # editor.getBuffer().insert(range.end, text)
          mark.destroy()
          delete @processing[id]

  deactivate: ->
    #@xikijView.destroy()

  serialize: ->
    #xikijViewState: @xikijView.serialize()
