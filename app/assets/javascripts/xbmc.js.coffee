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
      if data.error
        console?.log "rpc error:", [method, params...], data.error
        deferred.reject(data.error)
      else
        deferred.resolve(data.result)
    .fail (xhr, status, error) ->
      console?.log "rpc error:", [method, params...], xhr, error
      deferred.reject()
    deferred.promise()

class XBMC.Router extends Backbone.Router
  routes:
    "": "home"
    "rpc-documentation(/*anchor)": "rpcDocumentation"
    "movies": "movies"
    "movies/:movie": "movie"
    "shows": "shows"
    "shows/:show": "show"

  initialize: ->
    @on "route", (name, args) ->
      $(":not([data-route~=#{name}]).active").removeClass("active")
      $("[data-route~=#{name}]:not(.active)").addClass("active")

  home: ->
    $(".content").empty()
    XBMC.rpc("Player.GetActivePlayers")
      .done (players) =>
        deferreds = []
        deferreds.push XBMC.rpc("Player.GetItem", players[0].playerid, ["title", "thumbnail", "tvshowid"])
        deferreds.push XBMC.rpc("Playlist.GetItems", players[0].playerid, ["title", "tvshowid"])
        deferreds.push XBMC.rpc("VideoLibrary.GetRecentlyAddedEpisodes", ["title", "tvshowid"], {start: 0, end: 12})
        deferreds.push XBMC.rpc("VideoLibrary.GetRecentlyAddedMovies", ["title"], {start: 0, end: 12})
        $.when(deferreds...)
          .done ({item}, {items}, {episodes}, {movies}) =>
            $(JST["home"]({item, items, episodes, movies})).appendTo(".content")
          .then ->
            NProgress.done()
      .fail ->
        NProgress.done()

  rpcDocumentation: (section) ->
    if $("#rpc-documentation").length
      anchor = ("/#{section}" if section)
      if (a = $("a[name='rpc-documentation#{anchor}']")).length
        $(document).scrollTop(a.offset().top)
    else
      $(".content").empty()
      NProgress.start()
      XBMC.rpcDescriptor()
        .done (descriptor) =>
          $(JST["rpc-documentation"](descriptor)).appendTo(".content")
          @rpcDocumentation(section)
        .then ->
          NProgress.done()

  movies: ->
    $(".content").empty()
    NProgress.start()
    XBMC.rpc("VideoLibrary.GetMovies", ["title", "thumbnail", "playcount"], {}, {method: "title", ignorearticle: true})
      .done (result) =>
        $(JST["movies"](result)).appendTo(".content")
      .then ->
        NProgress.done()

  movie: (id) ->
    $(".content").empty()
    NProgress.start()
    XBMC.rpc("VideoLibrary.GetMovieDetails", parseInt(id), ["title", "thumbnail", "playcount", "plot"])
      .done (result) =>
        $(JST["movie"](movie: result.moviedetails)).appendTo(".content")
      .then ->
        NProgress.done()

  shows: ->
    $(".content").empty()
    NProgress.start()
    XBMC.rpc("VideoLibrary.GetTVShows", ["title", "thumbnail"], {}, {method: "title", ignorearticle: true})
      .done (result) =>
        $(JST["shows"](result)).appendTo(".content")
      .then ->
        NProgress.done()

  show: (id) ->
    $(".content").empty()
    NProgress.start()
    deferreds = []
    deferreds.push XBMC.rpc("VideoLibrary.GetTVShowDetails", parseInt(id), ["title", "thumbnail", "episode", "watchedepisodes", "plot"])
    deferreds.push XBMC.rpc("VideoLibrary.GetSeasons", parseInt(id), ["season"], {}, {method: "season"})
    $.when(deferreds...)
      .done ({tvshowdetails}, {seasons}) =>
        deferreds = []
        if seasons
          for {season} in seasons
            deferreds.push XBMC.rpc("VideoLibrary.GetEpisodes", parseInt(id), season, ["title", "thumbnail", "season", "episode", "playcount"], {}, {method: "episode"})
        $.when(deferreds...)
          .done (episodes...) ->
            $(JST["show"](show: tvshowdetails, seasons: seasons, episodes: episodes)).appendTo(".content")
          .then ->
            NProgress.done()
      .fail ->
        NProgress.done()

$ -> XBMC.init()
