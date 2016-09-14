/**
 * Auxiliary plug_p0ne modules
 * @author jtbrinkmann aka. Brinkie Pie
 * @version 1.0
 * @license MIT License
 * @copyright (c) 2014 J.-T. Brinkmann
 */


/*####################################
#            AUXILIARIES             #
####################################*/
module \updateUserObj, do
    require: <[ user_ ]>
    setup: ({addListener}) ->
        addListener window.user_, \change:username, ->
            user.username = window.user_.get \username

module \PopoutListener, do
    require: <[ PopoutView ]>
    optional: <[ _$context chat ]>
    setup: ({replace}) ->
        # also works with chatDomEvents.on \click, \.un, -> example!
        # even thought cb.callback becomes \.un and cb.context becomes -> example!
        replace PopoutView, \render, (r_) -> return ->
            r_ ...
            _$context?.trigger \popout:open, PopoutView._window, PopoutView
            API.trigger \popout:open, PopoutView._window, PopoutView

module \chatDomEvents, do
    require: <[ backbone ]>
    optional: <[ PopoutView PopoutListener ]>
    persistent: <[ _events ]>
    setup: ({addListener}) ->
        @ <<<< backbone.Events
        @one = @once
        cm = $cm!
        on_ = @on; @on = ->
            on_ ...
            cm.on .apply cm, arguments
        off_ = @off; @off = ->
            off_ ...
            cm.off .apply cm, arguments

        patchCM = ~>
            PopoutListener.chat
            for event, callbacks of @_events
                for cb in callbacks
                    #cm .off event, cb.callback, cb.context #ToDo test if this is necessary
                    cm .on event, cb.callback, cb.context
        addListener API, \popout:open, patchCM

module \grabMedia, do
    require: <[ playlists ]>
    optional: <[ _$context ]>
    module: (playlistIDOrName, media, appendToEnd) ->
        currentPlaylist = playlists.get(playlists.getActiveID!)
        # get playlist
        if typeof playlistIDOrName == \string and not playlistIDOrName .startsWith \http
            for pl in playlists.models when playlistIDOrName == pl.get \name
                playlist = pl; break
        else if id = +playlistIDOrName
            playlist = playlists.get(playlistIDOrName)
        else
            playlist = currentPlaylist # default to current playlist
            appendToEnd = media; media = playlistIDOrName
        if not playlist
            console.error "[grabMedia] could not find playlist", arguments
            return

        # get media
        if not media # default to current song
            addMedia API.getMedia!
        else
            mediaLookup media, do
                success: addMedia
                fail: (err) ->
                    console.error "[grabMedia] couldn't grab", err

        # add media to playlist
        function addMedia media
            console.log "[grabMedia] add '#{media.author} - #{media.title}' to playlist: #playlist"
            playlist.set \syncing, true
            ajax \POST, "playlists/#{playlist.id}/media/insert", media: [media], append: !!appendToEnd
                .then (e) ->
                    if playlist.id != e.id
                        playlist.set \syncing, false
                        playlist := playlists.get(e.id)
                    playlist.set \count, e.count
                    if playlist.id == currentPlaylist.id
                        _$context? .trigger \PlaylistActionEvent:load, playlist.id, do
                            playlists.getActiveID! != playlists.getVisibleID! && playlist.toArray!
                    # update local playlist
                    playlist.set \syncing, false
                    console.info "[grabMedia] successfully added to playlist"
                .fail ->
                    console.error "[grabMedia] error adding song to the playlist"



/*####################################
#             CUSTOM CSS             #
####################################*/
module \p0neCSS, do
    optional: <[ PopoutListener PopoutView ]>
    $popoutEl: $!
    styles: {}
    persistent: <[ styles ]>
    setup: ({addListener, $create}) ->
        @$el = $create \<style> .appendTo \head
        {$el, $popoutEl, styles} = this
        addListener API, \popout:open, (_window) ->
            $popoutEl := $el .clone! .appendTo _window.document.head
        PopoutView.render! if PopoutView?._window

        export @getCustomCSS = (inclExternal) ->
            if inclExternal
                return [el.outerHTML for el in $el] .join '\n'
            else
                return $el .first! .text!

        throttled = false
        export @css = (name, css) ->
            return styles[name] if not css?

            styles[name] = css
            res = ""
            for n,css of styles
                res += "/* #n */\n#css\n\n"

            if not throttled
                throttled := true
                requestAnimationFrame ->
                    throttled := false
                    $el       .first! .text res
                    $popoutEl .first! .text res

        export @loadStyle = (url) ->
            console.log "[loadStyle]", url
            s = $ "<link rel='stylesheet' >"
                .attr \href, url
                .appendTo document.head
            $el       .push s.0

            if PopoutView?._window
                $popoutEl .push do
                    s.clone!
                        .appendTo PopoutView?._window.document.head

        export @unloadStyle = (url) ->
            $el       .find "[href='#url']" .remove!
            $popoutEl .find "[href='#url']" .remove!
                        .0
        @disable = ->
            $el       .remove!
            $popoutEl .remove!


module \_$contextUpdateEvent, do
    require: <[ _$context ]>
    setup: ({replace}) ->
        for fn in <[ on off onEarly ]>
            replace _$context, fn,  (fn_) -> return (type, cb, context) ->
                fn_ ...
                _$context .trigger \context:update, type, cb, context



module \login, do
    settings: false
    persistent: <[ showLogin ]>
    module: ->
        if @showLogin
            @showLogin!
        else if not @loading
            @loading = true
            $.getScript "#{p0ne.host}/plug_p0ne.login.js"