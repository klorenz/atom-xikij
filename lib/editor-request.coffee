{util} = require 'xikij'
uuid = require 'uuid'
{extend,keys} = require "underscore"

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

    extend(args, atom.config.get('atom-xikij'))

    for k,v of @args
      args[k] = v

    @range  = @cursor.getCurrentLineBufferRange includeNewline: yes
    @mark   = @editor.markBufferRange(@range)
    @line   = @buffer.getTextInRange(@range)
    @indent = util.getIndent @line

    @id = uuid.v4()
    @atomXikij.processing[@id] = @

    @body = "" unless @body

    @atomXikij.request {@body, args, action}, (response) =>
      unless @body
        response.indent = ""
      else
        response.indent = INDENT

      callback response, =>
        # console.log response
        # text = "  "+response.data.replace "\n", "\n  "
        # editor.getBuffer().insert(range.end, text
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
      console.log("nextNonBlankRow", startRow, row)
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

    if nextRow
     if nextRow-1 > row
       row += 1

    while startRow > 0
      nextRow = @buffer.previousNonBlankRow(startRow)
      break unless nextRow
      break if indentation > @editor.indentationForBufferRow(nextRow)
      startRow = nextRow

    range = @buffer.rangeForRow(row, yes)
    range.start.row = startRow
    console.log "range", range
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

    util.indented(response.data, "#{@indent}#{response.indent}")
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
          @buffer.insert([row, col], "\n")
        # request.cursor.setBufferPosition request.args.position
        done()

  apply_action: (response, done) ->
    if response.data.action is "message"
      alert(response.data.message)

  apply_object: (response, done) ->
    result = ""
    for k in keys(response.data).sort()
      result += "+ .#{k}\n"

    text = util.indented(result, "#{@indent}#{response.indent}")
    text += "\n" unless /\n$/.test text
    @buffer.insert(@range.end, text)
    done()

  apply_array: (response, done) ->
    result = ""
    for e in response.data
      result += "+ #{e}\n"

    text = util.indented(result, "#{@indent}#{response.indent}")
    text += "\n" unless /\n$/.test text
    @buffer.insert(@range.end, text)
    done()

  apply_default: (response, done) ->
    return done() unless response.data

    text = util.indented(response.data, "#{@indent}#{response.indent}")
    text += "\n" unless /\n$/.test text
    @buffer.insert(@range.end, text)
    done()

  apply_error: (response, done) ->
    text = util.indented(response.data.stack, "#{@indent}#{response.indent}! ")
    text += "\n" unless /\n$/.test text
    @buffer.insert(@range.end, text)
    done()

  applyResponse: (response, done) ->
    console.log "response (#{response.type})", response
    handler = "apply_#{response.type}"
    if handler of @
      @[handler] response, done
    else
      @apply_default response, done

  # run editor request having @cursor of @editor at @startRow
  run: ->
    console.log "run"
    xikiNodePath = []
    startRow = @startRow
    row = @startRow

    unless @withInput
      line = @editor.lineTextForBufferRow(startRow)
      return @expand() if line is ""

    until row < 0
      curRow = row--
      line = @editor.lineTextForBufferRow(curRow)

      xikiNodePath.unshift line

      if /^\s*$/.test line
        continue

      break if @editor.indentationForBufferRow(curRow) == 0

    bodyRow = @startRow - curRow
    @body = xikiNodePath.join("\n")+"\n"

    nextNonBlankRow = @buffer.nextNonBlankRow(@startRow+1)

    curIndent  = @editor.indentationForBufferRow(@startRow)

    if @startRow+1 < @editor.getLineCount()
      nextIndent = @editor.indentationForBufferRow(@startRow+1)
      nextLine   = @editor.lineTextForBufferRow(@startRow+1)
    else
      nextIndent = curIndent
      nextNoneBlankRow = @startRow

    if nextNonBlankRow
      nonbIndent = @editor.indentationForBufferRow(nextNonBlankRow)
    else
      nonbIndent = nextIndent
      nextNonBlankRow = @startRow


    console.log "curIndent", curIndent
    console.log "nextIndent", nextIndent
    console.log "nonbIndent", nonbIndent
    console.log "nextNonBlankRow", nextNonBlankRow

    return @expand() if curIndent == nextIndent

    if nextIndent > nonbIndent
      if nextLine.match /^\s*$/
        return @expand()

      nextNonBlankRow = @startRow + 1

    console.log "startRow", startRow
    console.log "nextNonBlankRow", nextNonBlankRow

    # collapse - if requested
    if @startRow+1 < @editor.getLineCount() and not @withInput
      @curIndent = @editor.indentationForBufferRow(@startRow)
      if @curIndent < @editor.indentationForBufferRow(nextNonBlankRow)
        @curIndent += 1

        return @collapse()

    # expand - with input
    if @startRow+1 < @editor.getLineCount() and @withInput
      @curIndent = @editor.indentationForBufferRow(@startRow)
      if @curIndent < @editor.indentationForBufferRow(nextNonBlankRow)
        @inputRange = @getIndentedRange(@startRow+1)

        if @inputRange?
          @body += @editor.getBuffer().getTextInRange(@inputRange)

        @args =
          line: bodyRow

        return @expandWithInput()

    # expand
    return @expand()

module.exports = {EditorRequest}
