{SelectListView} = require 'atom'

module.exports =
class XikijSelectListView extends SelectListView
  initialize: (@data)->
    super
    @addClass('overlay from-top')
    @setItems(@data)
    atom.workspaceView.append(this)
    @focusFilterEditor()

  viewForItem: (item) ->
    "<li>#{item}</li>"

  confirmed: (item) ->
    console.log("#{item} was selected")
