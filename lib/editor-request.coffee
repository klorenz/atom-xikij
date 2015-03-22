{util} = require 'xikij'
uuid = require 'uuid'
{extend,keys} = require "underscore"

INDENT = "  "

cleanup = (text) -> text.replace /\r/, ''

class EditorRequest
  constructor: ({@atomXikij, @editor, @cursor, @startRow, @withInput, @withPrompt, @append}) ->
    @inputRange  = null

    @buffer = @editor.getBuffer()

    @range  = @cursor.getCurrentLineBufferRange includeNewline: no
    @line   = @buffer.getTextInRange(@range)
    @indent = util.getIndent @line

    nextRow = @range.start.row + 1

    # missing eol
    unless @buffer.lineEndingForRow(@range.start.row)
      @buffer.append("\n")

    @requestMark = @editor.markBufferRange(@range, xikijRequest: true)
    @mark = @editor.markBufferRange([[nextRow, 0], [nextRow, 0]], xikijResponse: true)


  # get ready for request and perform it
  request: (action, callback) ->
    args = {
      projectDirs: (d.path for d in atom.project.rootDirectories)
      fileName: @editor.getBuffer().file.path
      position: @cursor.getBufferPosition()
    }

    extend(args, atom.config.get('atom-xikij'))

    for k,v of @args
      args[k] = v

    # requestMark decorations will automatically be destroyed
    @editor.decorateMarker @requestMark,
      type: 'line', class: 'xikij-request-running'

    @editor.decorateMarker @requestMark,
      type: 'gutter', class: 'xikij-request-running'

    # to be destroyed after request is done
    @runningDeco = @editor.decorateMarker @mark,
      type: 'line', class: 'xikij-response-running'

    # this decoration persists
    @decoration = @editor.decorateMarker(@mark, {type: 'gutter', class: 'xikij-response'})

    @id = uuid.v4()
    @atomXikij.processing[@id] = @

    @body = "" unless @body

    if @append
      if @body.match /\n/
        @body = @body.replace /\n/, "#{@append}\n"
      else
        @body += @append

    @atomXikij.request {@body, args, action}, (response) =>
      unless @body
        response.indent = ""
      else
        response.indent = INDENT

      callback response, =>
        console.debug "mark2", @mark.getBufferRange()
        console.debug "requestMark2", @requestMark.getBufferRange()
        # console.log response
        # text = "  "+response.data.replace "\n", "\n  "
        # editor.getBuffer().insert(range.end, text

        if @mark.getBufferRange().isEmpty()
          @mark.destroy()

        else
          # make sure mark does not span request line
          reqStart = @requestMark.getStartBufferPosition()
          r = @mark.getBufferRange()

          @mark.setBufferRange([[reqStart.row+1, 0], r.end])

        @requestMark.destroy()
        @runningDeco.destroy()

        #@atomXikij.pushMark(@mark)
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
      #console.log("nextNonBlankRow", startRow, row)
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
    #console.log "range", range
    range

  # collapse request handler
  collapse: ->
    @request "collapse", (response, done) =>
      @markLine("-", "+")
      collapseRange = @getIndentedRange(@startRow+1, @editor)
      console.debug "collapseRange", collapseRange

      @buffer.delete(collapseRange)
      done()

  expandWithInput: ->
    @request "expand", (response, done) =>
      if response.action is "replace" or not response.action
        @buffer.delete(@inputRange)
      @markLine("+", "-")
      @applyResponse(response, done)

  expand: ->
    if @withPrompt
      @cursor.moveToEndOfLine()
      @buffer.insert(@cursor.getBufferPosition(), "\n" + @indent + @prompt + "\n")

      @cursor.moveLeft()

      # redo the mark
      row = @requestMark.getStartBufferPosition().row
      @mark.destroy()

      @range = @buffer.rangeForRow(row, includeNewline: yes)
      @mark = @editor.markBufferRange(@range)

#      @cursor.setBufferPosition([@mark.getEndBufferPosition().row, 0])

    @request "expand", (response, done) =>
      @markLine "+", "-"
      @applyResponse response, done

  apply_stream: (response, done) ->
    isFirst = true

    # this range is always about the row, the user wants to be executed
    row = @mark.getEndBufferPosition().row

    if row == @requestMark.getStartBufferPosition().row
      if @buffer.lineEndingForRow(row) is ""
        @buffer.insert(@mark.getEndBufferPosition(), "\n")

    col = 0
    hadLF = false

    #whitespace = ""

    util.indented(response.data, "#{@indent}#{response.indent}")
      .on "data", (data) =>
        data = cleanup(data.toString())

        @buffer.insert(@mark.getEndBufferPosition(), data)

        console.log "marked range", @mark.getBufferRange()

        # @buffer.insert([row, col], data)
        #
        # if /\n/.test data
        #   m = /\n(.*)$/.exec data
        #   col = m[1].length
        #   row += data.match(/\n/g).length
        # else
        #   col = data.length

        hadLF = /\n$/.test data

      .on "end", =>
        unless hadLF
          @buffer.insert(@mark.getEndBufferPosition(), "\n")
          #@buffer.insert([row, col], "\n")
        # request.cursor.setBufferPosition request.args.position
        done()

      .on "error", (error) =>
        console.log "error", error
        text = util.indented(error.stack, "#{@indent}  ! ")
        text += "\n" unless /\n$/.test text

        @buffer.insert(@mark.getEndBufferPosition(), text)
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
    @buffer.insert(@mark.getEndBufferPosition(), text)
    done()

  apply_array: (response, done) ->
    result = ""
    for e in response.data
      result += "+ #{e}\n"

    text = util.indented(result, "#{@indent}#{response.indent}")
    text += "\n" unless /\n$/.test text
    @buffer.insert(@mark.getEndBufferPosition(), text)
    done()

  apply_default: (response, done) ->
    return done() unless response.data

    text = util.indented(response.data, "#{@indent}#{response.indent}")
    text += "\n" unless /\n$/.test text
    @buffer.insert(@mark.getEndBufferPosition(), text)
    done()

  apply_error: (response, done) ->
    text = util.indented(response.data.stack, "#{@indent}#{response.indent}! ")
    text += "\n" unless /\n$/.test text
    @buffer.insert(@mark.getEndBufferPosition(), text)
    done()

  applyResponse: (response, done) ->
    #console.log "response (#{response.type})", response
    handler = "apply_#{response.type}"
    if handler of @
      @[handler] response, done
    else
      @apply_default response, done

  # run editor request having @cursor of @editor at @startRow
  run: ->
    # TODO if first line does not end with \n, append it

    if @withPrompt
      stripped = util.strip(@line)
      isPrompt = false
      for prompt in @atomXikij.prompts
        if util.startsWith stripped, prompt
          isPrompt = true
          @prompt = prompt
          break

      if not isPrompt
        row = @cursor.getBufferRow()
        indentLevel = @editor.indentationForBufferRow(row)
        pos = @cursor.getBufferPosition()
        @editor.getBuffer().insert pos, "\n", normalizeLineEndings: true
        @editor.setIndentationForBufferRow(row+1, indentLevel)
        return

    #console.log "run"
    xikiNodePath = []
    startRow = @startRow

    unless @withInput
      line = @editor.lineTextForBufferRow(startRow)
      return @expand() if line is ""

    @body   = @atomXikij.getBody(@startRow, @editor)
    bodyRow = (@body.match /\n/g).length - 1

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


    #console.log "curIndent", curIndent
    #console.log "nextIndent", nextIndent
    #console.log "nonbIndent", nonbIndent
    #console.log "nextNonBlankRow", nextNonBlankRow

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

    #@cursor.setBufferPosition([@range.end.row, 0])


      # ../../xikij

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
