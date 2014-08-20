{View} = require 'atom'

module.exports =
class XikijView extends View
  @content: ->
    @div class: 'xikij overlay from-top', =>
      @div "The Xikij package is Alive! It's ALIVE!", class: "message"

  initialize: (serializeState) ->

  # Returns an object that can be retrieved when package is activated
  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @detach()

  toggle: ->
    console.log "XikijView was toggled!"
    if @hasParent()
       @detach()
    else
       atom.workspaceView.append(this)

    atom.workspaceView.getActiveView()
