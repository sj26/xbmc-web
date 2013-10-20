#= require jquery
#= require nprogress
#= require underscore
#= require backbone
#= require bootstrap

#= require templates

NProgress.configure showSpinner: false
$(document).on
  "page:fetch": -> NProgress.start()
  "page:change": -> NProgress.done()
  "page:restore": -> NProgress.remove()

@XBMC =
  version: "0.1"
  url: "/jsonrpc"

  init: ->
    $(document.body)
    .on "click", "[data-action=playpause]", =>
      @rpc "Player.PlayPause", 1
    .on "click", "[data-action=play]", =>
      @rpc "Player.PlayPause", 1, true
    .on "click", "[data-action=pause]", =>
      @rpc "Player.PlayPause", 1, false

    @router = new XBMC.Router

    Backbone.history.start()

  rpcDescriptor: ->
    deferred = $.Deferred()
    $.ajax
      type: "GET"
      url: @url
      dataType: "json"
    .done (data, status, xhr) ->
      deferred.resolve(data)
    .fail (xhr, status, error) ->
      deferred.reject()
    deferred.promise()

  rpc: (method, params...) ->
    deferred = $.Deferred()
    data =
      jsonrpc: "2.0"
      id: 1
      method: method
    data.params = params if params?
    $.ajax
      type: "POST"
      url: @url
      data: JSON.stringify(data)
      processData: false
      contentType: "application/json"
      dataType: "json"
    .done (data, status, xhr) ->
      deferred.resolve(data.result)
    .fail (xhr, status, error) ->
      console.log "rpc error:", method, xhr, error
      deferred.reject()
    deferred.promise()

class XBMC.Router extends Backbone.Router
  routes:
    "": "home"
    "rpc-documentation(/*anchor)": "rpcDocumentation"
    "movies": "movies"
    "tv": "tv"

  initialize: ->
    @on "route", (name, args) ->
      $("[data-route!=#{name}].active").removeClass("active")
      $("[data-route=#{name}]:not(.active)").addClass("active")

  home: ->
    $(".content").html("<p>Home...</p>")

  rpcDocumentation: (section) ->
    if $("#rpc-documentation").length
      anchor = ("/#{section}" if section)
      if (a = $("a[name='rpc-documentation#{anchor}']")).length
        $(document.body).scrollTop(a.offset().top)
    else
      $(".content").empty()
      NProgress.start()
      XBMC.rpcDescriptor().done (descriptor) =>
        $(JST["rpc-documentation"](descriptor)).appendTo(".content")
        NProgress.done()
        @rpcDocumentation(section)

  movies: ->
    $(".content").empty()
    NProgress.start()
    XBMC.rpc("VideoLibrary.GetMovies").done (result) =>
      $(JST["movies"](result)).appendTo(".content")
      NProgress.done()

  tv: ->
    $(".content").empty()
    NProgress.start()
    XBMC.rpc("VideoLibrary.GetTVShows").done (result) =>
      $(JST["tv"](result)).appendTo(".content")
      NProgress.done()

$ -> XBMC.init()
