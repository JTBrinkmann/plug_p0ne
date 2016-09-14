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
module \getActivePlaylist, do
    require: <[ playlists ]>
    module: ->
        return playlists.findWhere active: true
module \_API_, do
    optional: <[]>
    setup: ->
        for k,v of API when not @[k]
            @[k] = v
    chatLog: API.chatLog
    on: API.on
    once: API.once
    off: API.off
    _events: API.{}_events
    getAdmins: -> ...
    getAmbassadors: -> ...
    getAudience: -> ...
    getBannedUsers: -> ...
    getDJ: -> ...
    getHistory: -> return roomHistory
    getHost: -> ...
    getMedia: -> ...
    getNextMedia: -> ...
    getUser: -> return user_
    getUsers: -> return users
    getPlaylists: -> ...
    getStaff: -> ...
    getWaitList: -> ...
module \updateUserData, do
    require: <[ user_ users _$context ]>
    setup: ({addListener}) ->
        addListener window.user_, \change:username, ->
            user.username = window.user_.get \username
        addListener _$context, \user:join, ({id}) ->
            users.get(id).set \joinedRoom, Date.now!
        for user in users.models
            user.set \joinedRoom, -1
module \throttleOnFloodAPI, do
    setup: ({addListener}) ->
        addListener API, \socket:floodAPI, ->
            /* all AJAX and Socket functions should check if the counter is AT LEAST below 20 */
            window.floodAPI_counter += 20
            sleep 15_000ms, ->
                /* it is assumed, that the API counter resets every 10 seconds. 15s is to provide enough buffer */
                window.floodAPI_counter -= 20

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
        @one = @once # because jQuery uses .one instead of .once
        cm = $cm!
        on_ = @on; @on = ->
            on_ ...
            cm.on .apply cm, arguments
        off_ = @off; @off = ->
            off_ ...
            cm.off .apply cm, arguments

        patchCM = ~>
            cm = PopoutListener.chat
            for event, callbacks of @_events
                for cb in callbacks
                    #cm .off event, cb.callback, cb.context #ToDo test if this is necessary
                    cm .on event, cb.callback, cb.context
        addListener API, \popout:open, patchCM

module \grabMedia, do
    require: <[ playlists auxiliaries ]>
    optional: <[ _$context ]>
    module: (playlistIDOrName, media, appendToEnd) ->
        currentPlaylist = playlists.get(playlists.getActiveID!)
        # get playlist
        if typeof playlistIDOrName == \string and not playlistIDOrName .startsWith \http
            for pl in playlists.models when playlistIDOrName == pl.get \name
                playlist = pl; break
        else if not playlist = playlists.get(playlistIDOrName)
            playlist = currentPlaylist # default to current playlist
            appendToEnd = media; media = playlistIDOrName

        if not playlist
            console.error "[grabMedia] could not find playlist", arguments
            return

        # get media
        if not media # default to current song
            addMedia API.getMedia!
        else if media.id
            addMedia media
        else
            mediaLookup media, do
                success: addMedia
                fail: (err) ->
                    console.error "[grabMedia] couldn't grab", err

        # add media to playlist
        function addMedia media
            console.log "[grabMedia] add '#{media.author} - #{media.title}' to playlist:", playlist
            playlist.set \syncing, true
            media.get = l("it -> this[it]")
            ajax \POST, "playlists/#{playlist.id}/media/insert", media: auxiliaries.serializeMediaItems([media]), append: !!appendToEnd
                .then ({[e]:data}) ->
                    if playlist.id != e.id
                        console.warn "playlist mismatch", playlist.id, e.id
                        playlist.set \syncing, false
                        playlist := playlists.get(e.id) || playlist
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
    urlMap: {}
    persistent: <[ styles ]>
    setup: ({addListener, $create}) ->
        @$el = $create \<style> .appendTo \head
        {$el, $popoutEl, styles, urlMap} = this
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

            if not throttled
                throttled := true
                requestAnimationFrame ->
                    throttled := false
                    res = ""
                    for n,css of styles
                        res += "/* #n */\n#css\n\n"
                    $el       .first! .text res
                    $popoutEl .first! .text res

        export @loadStyle = (url) ->
            console.log "[loadStyle] %c#url", "color: #009cdd"
            if urlMap[url]
                return urlMap[url]++
            else
                urlMap[url] = 1
            s = $ "<link rel='stylesheet' >"
                #.attr \href, "#url?p0=#{p0ne.version}" /* ?p0 to force redownload instead of using obsolete cached versions */
                .attr \href, url /* ?p0 to force redownload instead of using obsolete cached versions */
                .appendTo document.head
            $el       .push s.0

            if PopoutView?._window
                $popoutEl .push do
                    s.clone!
                        .appendTo PopoutView?._window.document.head

        export @unloadStyle = (url) ->
            if urlMap[url] > 0
                urlMap[url]--
            if urlMap[url] == 0
                console.log "[loadStyle] unload %c#url", "color: #009cdd"
                delete urlMap[url]
                if -1 != i = $el       .indexOf "[href='#url']"
                    $el.eq(i).remove!
                    $el.splice(i, 1)
                if -1 != i = $popoutEl .indexOf "[href='#url']"
                    $popoutEl.eq(i).remove!
                    $popoutEl.splice(i, 1)
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
    persistent: <[ showLogin ]>
    module: ->
        if @showLogin
            @showLogin!
        else if not @loading
            @loading = true
            $.getScript "#{p0ne.host}/plug_p0ne.login.js"