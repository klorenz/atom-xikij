{util} = require 'xikij'
uuid = require 'uuid'

INDENT = "  "

class EditorRequest
  constructor: ({@atomXikij, @editor, @cursor, @startRow, @withInput, @withPrompt}) ->
    @inputRange = null
    @buffer = @editor.getBuffer()

  # get ready for request and perform it
  request: (action, callback) ->
    args = {
      projectDirs: [ atom.project.rootDirectory.path ]
      fileName: @editor.getBuffer().file.path
      position: @cursor.getBufferPosition()
    }

    for k,v of @args
      args[k] = v

    @range  = @cursor.getCurrentLineBufferRange includeNewline: yes
    @mark   = @editor.markBufferRange(@range)
    @line   = @buffer.getTextInRange(@range)
    @indent = util.getIndent @line

    @id = uuid.v4()
    @atomXikij.processing[@id] = @

    @atomXikij.request {@body, args, action}, (response) =>
      callback response, =>
        # console.log response
        # text = "  "+response.data.replace "\n", "\n  "
        # editor.getBuffer().insert(range.end, text)
        @mark.destroy()
        delete @atomXikij.processing[@id]

  # switches line marking from `from` to `to`
  #
  # e.g. if you have a line
  # ```
  #   + an item
  # ```
  # you can swith line marking from "+" to "-"
  #
  markLine: (from, to) ->
    indlen  = @indent.length
    fromlen = from.length

    if @line[indlen...indlen+fromlen] is from
      @buffer.setTextInRange(@range, @indent+to+@line[indlen+fromlen..])

    # TODO: should update @line and @body or at least invalidate them

  # return indented range around startRow
  #
  getIndentedRange: (aRow) ->
    startRow = aRow
    if @buffer.lineForRow(startRow).match /^\s*$/
      row = @buffer.nextNonBlankRow(startRow)
    else
      row = startRow

    if row is null
      return @buffer.rangeForRow(startRow, yes) if row is null

    indentation = @editor.indentationForBufferRow(row)

    until row >= @buffer.getLineCount()
      nextRow = @buffer.nextNonBlankRow(row)
      break unless nextRow
      break if indentation > @editor.indentationForBufferRow(nextRow)
      row = nextRow

    while startRow > 0
      nextRow = @buffer.previousNonBlankRow(startRow)
      break unless nextRow
      break if indentation > @editor.indentationForBufferRow(nextRow)
      startRow = nextRow

    range = @buffer.rangeForRow(row, yes)
    range.start.row = startRow
    range

  # collapse request handler
  collapse: ->
    @request "collapse", (response, done) =>
      @markLine("-", "+")
      collapseRange = @getIndentedRange(@startRow+1, @editor)
      @buffer.delete(collapseRange)
      done()

  expandWithInput: ->
    @request "expand", (response, done) =>
      if response.action is "replace" or not response.action
        @buffer.delete(@inputRange)
      @markLine("+", "-")
      @applyResponse(response, done)

  expand: ->
    @request "expand", (response, done) =>
      @markLine "+", "-"
      @applyResponse response, done

  apply_stream: (response, done) ->
    isFirst = true

    # this range is always about the row, the user wants to be executed
    row = @range.end.row
    if row == @range.start.row
      if @buffer.lineEndingForRow(row) is ""
        @buffer.insert(@range.end, "\n")
        @range.end.column += 1
        row = @range.end.row+1

    col = 0
    hadLF = false

    util.indented(response.data, "#{@indent}#{INDENT}")
      .on "data", (data) =>
        data = data.toString()

        @buffer.insert([row, col], data)

        if /\n/.test data
          m = /\n(.*)$/.exec data
          col = m[1].length
          row += data.match(/\n/g).length
        else
          col = data.length

        hadLF = /\n$/.test data

      .on "end", =>
        unless hadLF
          buffer.insert([row, col], "\n")
        # request.cursor.setBufferPosition request.args.position
        done()

  apply_object: (response, done) ->
    if response.data.action is "message"
      alert(response.data.message)

  apply_default: (response, done) ->
    text = util.indented(response.data, "#{@indent}#{INDENT}")
    text += "\n" unless /\n$/.test text
    @buffer.insert(@range.end, text)
    done()

  applyResponse: (response, done) ->
    handler = "apply_#{response.type}"
    if handler of @
      @[handler] response, done
    else
      @apply_default response, done

  # run editor request having @cursor of @editor at @startRow
  run: ->
    xikiNodePath = []
    startRow = @startRow
    row = @startRow
    until row < 0
      curRow = row--
      line = @editor.lineForBufferRow(curRow)

      xikiNodePath.unshift line

      if /^\s*$/.test line
        continue

      break if @editor.indentationForBufferRow(curRow) == 0

    bodyRow = @startRow - curRow
    @body = xikiNodePath.join("\n")+"\n"

    # collapse - if requested
    if @startRow+1 < @editor.getLineCount() and not @withInput
      @curIndent = @editor.indentationForBufferRow(@startRow)
      if @curIndent < @editor.indentationForBufferRow(@startRow+1)
        @curIndent += 1

        return @collapse()

    # expand - with input
    if @startRow+1 < @editor.getLineCount() and @withInput
      @curIndent = @editor.indentationForBufferRow(@startRow)
      if @curIndent < @editor.indentationForBufferRow(@startRow+1)
        @inputRange = @getIndentedRange(@startRow+1)

        if @inputRange?
          @body += @editor.getBuffer().getTextInRange(@inputRange)

        @args =
          line: bodyRow

        return @expandWithInput()

    return @expand()

module.exports = {EditorRequest}
