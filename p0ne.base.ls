/*@author jtbrinkmann aka. Brinkie Pie */
/*@license https://creativecommons.org/licenses/by-nc/4.0/ */

usernameToSlug = (un) ->
    $ \<span> .text un .html!
        .replace /[&;\s]+/g, '-'
        # some more characters get collapsed
        # some characters get converted to \u####

/*####################################
#            AUXILIARIES             #
####################################*/
module \PopoutListener, do
    require: <[ PopoutView ]>
    optional: <[ _$context ]>
    setup: ->
        replace PopoutView, \render, (r_) -> return ->
            r_ ...
            _$context?.trigger \popout:open, Popout._window, Popout
            API.trigger \popout:open, Popout._window, Popout


/*####################################
#             CUSTOM CSS             #
####################################*/
module \p0neCSS, do
    optional: <[ PopoutListener PopoutView ]>
    setup: ({addListener}) ->
        $popoutEl = $!; styles = {}; $el = $ \<style> .appendTo \head
        addListener do
            target: API
            event: \popout:open
            callback: (_window) ->
                $popoutEl := $el .clone!
                    .appendTo _window.document.head
        PopoutView.render! if PopoutView?._window

        window.getCustomCSS = (inclExternal) ->
            res = "<style>\n"
            for n,css of styles
                res += "/* #n */\n#css\n\n"
            res += "</style>"
            res += [].slice.call $el, 1 .map (.outerHTML) .join \\n if inclExternal
            return res

        window.css = (name, css) ->
            return styles[name] if not css?

            styles[name] = css
            res = getCustomCSS!
            $el       .first! .text res
            $popoutEl .first! .text res

        window.loadStyle = (url) ->
            s = $ "<link rel='stylesheet' >"
                .attr \href, url
                .appendTo document.head
            $el       .push s.0
            return if not PopoutView?._window
            s = s.clone!
            $popoutEl .push s.0
            s.appendTo PopoutView?._window.document.head
        @disable = ->
            $el       .remove!
            $popoutEl .remove!


module \getStatus, do
    module: ->
        if plugCubed?.init and not plugCubed.settings # plug³ alpha
            requireHelper do
                name: \plugCubdeAlphaVersion
                test: (.major)
        status = "Running plug_p0ne v#{p0ne.version}"
        status += " (incl. chat script)" if window.p0ne_chat
        status += "\t and plug³ v#{getPlugCubedVersion!}" if window.plugCubed
        status += "\t and plugplug #{getVersionShort!}" if window.ppSaved
        status += ".\t Started #{ago p0ne.started}"

module \statusCommand, timeout: false, callback:
    target: API
    event: API.CHAT
    bound: true
    callback: (data) ->
        return if @timeout
        if data.message.indexOf("@#{user.username}") != -1 and data.message.indexOf("!status") != -1
            @timeout = true
            status = "#{getStatus!}"
            console.log "[AUTORESPOND] '#status'"
            API.sendChat status, data
            sleep 30min *60_000to_ms, ->
                @timeout = false
                console.info "[status] timeout reset"


module \_$contextUpdateEvent, do
    require: <[ _$context ]>
    setup: ({replace}) ->
        for fn in <[ on off onEarly ]>
            replace _$context, fn,  (fn_) -> return (type, cb, context) ->
                fn_ ...
                _$context .trigger \context:update, type, cb, context

/*####################################
#                FIXES               #
####################################*/
module \simpleFixes, do
    setup: ({replace}) ->
        # kill p³'s Socket server
        # (as there is no functionality gained by using it. Only PMs are noteworthy, but those are broken)
        /*
        plugCubedLoaded .then ->
            if plugCubed.Socket
                replace plugCubed, \Socket, (-> return ->)
            else
                replace require("plugCubed/Socket")@@::, \connect, (-> return ->)
        */

        # fix plug dying on a reconnect
        #NOTE: an initial ack is required to load the room. it is assumed, that this script is run AFTER the room is already loaded
        /*
        Socket = requireHelper do
                name: \Socket
                test: (.ack)
        Socket?.ack = ->
        */

        # hide social-menu (because personally, i only accidentally click on it. it's just badly positioned)
        @$sm = $ \.social-menu .remove!

        # add tab-index to chat-input
        $ \#chat-input-field .prop \tabIndex, 1
    disable: ->
        @$sm = $ \.social-menu .insertAfter \#playlist-panel

module \soundCloudThumbnailFix, do
    require: <[ auxiliaries ]>
    setup: ->
        auxiliaries.deserializeMedia = (e) !->
            e.author = this.h2t( e.author )
            e.title = this.h2t( e.title )
            if e.image
                e.image .= replace /^https?:\/\//, '//'


/*####################################
#             /COMMANDS              #
####################################*/
module \chatCommands, do
    callback:
        target: API
        event: API.CHAT_COMMAND
        bound: true
        callback: (msg) ->
            if c = @commands[msg .split " " .0 .substr 1]
                substr = msg.substr(c.length + 2) # +2 because of the space and the truncated slash
                c = @commands[c] if typeof c == \string
                return false == c(substr, msg)
    commands: #NOTE: if a command doesn't apply, it must return FALSE, which will cause the message to be SEND, rather than executed (e.g. with /me)
        chat: (message) -> # To avoid the 10min link timeout
            if window._$context
                _$context.trigger \chat:send, message



/*####################################
#           FIX POPUP BUG            #
####################################*/
/*
#ToDo
module \fixPopup, callback:
    target: socket
    event: \connect
    callback: ->
        if $popup.css(\display) != \none
            console.log "===================\nfixed popup\n==================="
            $popup .hide!
        else
            sleep 200ms, ->
                console.log "===================\nlate fixed popup\n==================="
                $popup .hide!
*/


/*####################################
#            GRAB / CURATE           #
####################################*/
window.grab = null if window.grab.nodeType
module \grab, do
    optional: <[ Curate playlists]>
    module: (playlistIDOrName) ->
        m = API.getMedia!
        if m
            console.log "[Curate] add '#{m.author} - #{m.title}' to playlist: #playlist"
        else
            return console.error "[Curate] no DJ is playing!"

        if Curate
            if typeof playlistID == \string
                if playlists
                    for pl in playlists.models when playlistID == pl.id or playlistID == pl.get \name
                        playlist = pl; break
                else
                    console.warn "[grab] warning: using fallback, because the list of playlists couldn't be loaded"
            if playlist
                t = new Curate(pl.id, [m], false)
                t
                    .on \success, ->
                        console.log("[grab] success", arguments)
                    .on \error, ->
                        console.log("[grab] error", arguments)
                return true
        if typeof playlistIDOrName != \string
            console.error "[grab] error: can't curate to playlist by ID in fallback-mode (proper playlist module failed to load)"
            return

        $ \#grab .click!
        <- sleep 500ms
        pls = $ '.pop-menu.grab ul span'
            .filter (-> @innerText == playlistIDOrName)
            .mousedown!
        if not pls.length
            console.warn "[Curate] playlist '#playlist' not found", pls


/*####################################
#             ZALGO FIX              #
####################################*/
module \zalgoFix, do
    setup: ->
        css \zalgoFix, '
            .message {
                overflow: hidden;
            }
        '


/*####################################
#       TITLE FOR CURRENT SONG       #
####################################*/
module \titleCurrentSong, do
    disable: ->
        $ \#now-playing-media .prop \title, ""
    callback:
        target: API
        event: API.ADVANCE
        callback: (d) ->
            $ \#now-playing-media .prop \title, "#{d.media.author} - #{d.media.title}"


/*####################################
#           RESTORE CHAT             #
####################################*/
module \restoreChatScript, do
    require: <[ compressor ]>
    setup: ({addListener}, rCS) ->
        # Event Listeners
        addListener target: $(window), event: \beforeunload, callback: -> return "are you sure you want to leave?"
        addListener target: $(window), event: \unload, callback: -> window.restoreChatScript.save!

        if rCS.maxAge > Date.now! - rCS.savedChatTime
            rCS.restore!
        else if rCS.savedChatTime
            console.log "[rCS] not restoring chat from #{ago rCS.savedChatTime} (too old)"
            $cm .prepend do
                btn = $ \<button>
                    .text "force loading previous chatlog (#{ago rCS.savedChatTime})"
                    .click ->
                        window.restoreChatScript.restore!
                        $ this .remove!
        else
            console.error "[rCS] no chatlog found"
            API.chatLog "[rCS] no chatlog found", true

    module: do ->
        lssize_ = lssize!
        if lssize_ > 8
            API.chatLog "[rCS] WARNING: the LocalStorage is nearly full. Further chatlogs might not be saved. (#{formatMB lssize_} / 10MB)", true
        $cm = $ \#chat-messages
        hasCompressor = +!!window.compressor
        savedChatTime = +localStorage.getItem \plugDjChatTime
        return do
            maxAge: 10min  *  1000to_s*60to_min
            savedChatTime: savedChatTime
            ago: ago new Date +
            save: ->
                btn? .remove!
                html = "#{+hasCompressor}|#{compressor.compress($cm .0 .innerHTML)}"
                #localStorage.setItem \plugDjChat, html
                localStorage.setItem \plugDjChatTime, Date.now!
                localStorage.setItem "plugDjChat-#{new Date! .toISOString!}", html
            restore: ->
                console.log "[rCS] restoring chat from #{rCS.ago}"
                html = localStorage.getItem "plugDjChat-#{new Date(savedChatTime) .toISOString!}"
                isCompressed = html.0
                html .= substr 2
                console.log "[rCS]", html.substr 0, 100

                if isCompressed # if compressed
                    console.info "[rCS] compressed"
                    if not hasCompressor
                        API.chatLog "[rCS] WARNING: couldn't load last chat because the it is compressed, but the compressor couldn't be loaded. Sorry =(", true
                        return
                    html = compressor.decompress html
                else
                    console.warn "[rCS] not compressed"
                $cm
                    ..prepend html
                    ..animate scrollTop: ..prop \scrollHeight, 1_000ms


/*####################################
#             YELLOW MOD             #
####################################*/
module \yellowMod, do
    setup: ->
        id = API.getUser! .id
        css \yellowMod, "
            \#chat .from-#id .from,
            \#chat .fromID-#id .from {
                color: \#ffdd6f !important;
            }
        "


/*####################################
#      DISABLE MESSAGE DELETE        #
####################################*/
module \disableChatDelete, do
    require: <[ _$context ]>
    optional: <[ socketListeners ]>
    setup: ({replace_$Listener, addListener}) ->
        css \disableChatDelete, '
            .deleted {
                border-left: 2px solid red;
            }
            .deleted-message {
                display: block;
                text-align: right;
                color: red;
                font-family: monospace;
            }
        '
        cb = (cid, moderator) -> # used to be \ChatFacadeEvent:delete before the big summer-2014-update
            $msg = getChat cid
            console.log "[Chat Delete]", cid, $msg.text!
            t  = getISOTime!
            t += " by #moderator" if moderator
            try
                #wasAtBottom = isChatAtBottom?!
                $msg
                    .addClass \deleted
                d = $ \<time>
                    .addClass \deleted-message
                    .addClass \timestamp
                    .attr \datetime, t
                    .text t
                    .appendTo $msg
                cm = $cm!
                cm.scrollTop cm.scrollTop! + d.height!
                #scrollChatDown?! if wasAtBottom
        replace_$Listener \chat:delete, ->
            if not window.socket
                cb(cid)
        addListener do
            target: _$context
            event: \socket:chatDelete
            callback: ({c, u}) ->
                cb(c, users.get(u)?.username || u)

        replace_$Listener \ChatFacadeEvent:clear, ->
            t = getISOTime!
            console.log """
                ======================
                [CHAT CLEAR]
                ======================
            """
            wasAtBottom = isChatAtBottom?!
            this.$chatMessages.append do
                $ \<div> .addClass "system drag-media-label"
                    .css top: 0
                    .append '<span class="text">
                            ~~~~~~~~~~~~~~~~<br>
                            CHAT GOT CLEARED<br>
                            ~~~~~~~~~~~~~~~~
                        </span>'
                    .append do
                        $ \<time>
                            .addClass \timestamp
                            .attr \datetime, t
                            .text t
            scrollChatDown?! if wasAtBottom


/*####################################
#        DBLCLICK to @MENTION        #
####################################*/
module \chatDblclick2Mention, do
    require: <[ chat ]>
    optional: <[ PopoutListener ]>
    setup: ({addListener, replace}) ->
        /*addListener do
            target: API
            event: \popout:open
            callback: ->
                # wait doesn't chat.fromClickBind handle this?
                */
        replace chat, \fromClickBind, ~> return (e) ~>
            if not @timer # single click
                @timer = sleep 200ms, ~> if @timer
                    @timer = 0
                    chat.onFromClick e
            else # double click
                clearTimeout @timer
                @timer = 0
                chat.onInputMention e.target.innerText.substr(0, e.target.innerText.length - 1)
            e .stopPropagation!; e .preventDefault!


/*####################################
#         FRIENDLIST POPUP           #
####################################*/
module \friendslistPopup, do
    require: <[ friendsList FriendsList chat ]>
    setup: (aux) -> @update aux
    update: ({replace}) ->
        replace FriendsList::render, (r_) -> return ->
            r_ ...
            @rows.push_ ||= @rows.push
            @rows.push = (row) ->
                @push_ row
                row.$el
                    .click chat.fromClickBind
                    .data \uid, row.model.id
        #replace friendsList, \drawBind, -> return _.bind friendsList.drawRow, friendsList


/*####################################
#         JOIN NOTIFICATION          #
####################################*/
/*
module \joinNotif, do
    require: <[ _$context ]>
    setup: ->
        css \joinNotif, '.p0ne-join-notif { color: rgb(51, 102, 255); font-weight: bold; }'
        $ \#chat .on \click, \.p0ne-join-notif, @nameClick
    lastNotif1: null
    lastNotif2: null
    nameClick: (e) ->
        greet = "#{<[ hey hi sup hoi hallu ]>.random!} #{<[ ! ~ . ]>.random!}"
        un = escape($ e.target .closest \p0ne-join-notif .data \un)
        console.log "[joinNotif] semi-autogreet '@#un #greet'"
        _$context.trigger \chat:mention, "#un #greet"
    callback:
        target: API
        event: API.USER_JOIN
        callback: (data) ->
            appendChat do
                $ "<div class='update p0ne-join-notif' data-un='#{escape un}'><span class='name'>#{data.username}</span> just joined the room</div>"
*/
/*####################################
#           LOG EVERYTHING           #
####################################*/
module \logAllEvents, do
    require: <[ _$context ]>
    optional: <[ socketListeners ]>
    setup: ({replace}) ->
        replace _$context, \trigger, \trigger
    trigger: (trigger_) -> return (type) ->
        group = type.substr(0, type.indexOf(":"))
        if group not in <[ socket tooltip djButton chat sio popout playback playlist notify drag audience anim HistorySyncEvent user ]> and type not in <[ ChatFacadeEvent:muteUpdate PlayMediaEvent:play userPlaying:update]>
            console.log "#{getTime!} [#type]", getArgs!
        else if group == \socket and type not in <[ socket:chat socket:vote socket:grab socket:earn ]>
            console.info "#{getTime!} [#type]", [].slice.call(arguments, 1)
        /*else if type == "chat:receive"
            data = &1
            console.log "#{getTime!} [CHAT]", "#{data.from.id}:\t", data.text, {data}*/
        try
            return trigger_ ...
        catch e
            console.error "[_$context.trigger] Error when triggering '#type'", window.e=e

module \logChat, do
    require: <[ htmlUnescape ]>
    optional: <[ _$context ]>
    setup: ({addListener}) ->
        addListener do
            target: API
            event: \chat
            callback: (data) ->
                message = htmlUnescape(data.message) .replace(/\u202e/g, '\\u202e')
                if data.un
                    name = data.un .replace(/\u202e/g, '\\u202e') + ":"
                    name = " " * (24 - name.length) + name
                    console.log "#{getTime!} [CHAT]", "#name #message"
                else
                    name = "[system]"
                    console.info "#{getTime!} [CHAT]", "#name #message"

        addListener do
            target: API
            event: \userJoin
            callback: (data) ->
                name = htmlUnescape(data.username) .replace(/\u202e/g, '\\u202e')
                console.log "#{getTime!} + [JOIN]", data.id, name, "(#{getRank data})", data
        addListener do
            target: API
            event: \userLeave
            callback: (data) ->
                name = htmlUnescape(data.username) .replace(/\u202e/g, '\\u202e')
                console.log "#{getTime!} - [LEAVE]", data.id, name, "(#{getRank data})", data

        return if not window._$context
        addListener do
            target: _$context
            event: \PlayMediaEvent:play
            callback: (data) ->
                #data looks like {type: "PlayMediaEvent:play", media: n.hasOwnProperty.i, startTime: "1415645873000,0000954135", playlistID: 5270414, historyID: "d38eeaec-2d26-4d76-8029-f64e3d080463"}

                console.log "#{getTime!} [SongInfo]", "playlist:",data.playlistID, "historyID:",data.historyID

/*####################################
#         MODERATOR STUFF            #
####################################*/
module \improveModeration, do
    require: <[ permissions ]>
    setup: ->
        replace permissions, \canModChat, -> return ->
            return true

/*####################################
#           SMALL THINGS             #
####################################*/
requireHelper do
    name: \UserRollover
    test: (.id == 'user-rollover')
module \improvedUserRollover, do
    require: <[ UserRollover ]>
    setup: ({replace}) ->
        replace UserRollover, \render, (r_) -> ->
            r_ ...
            @$el .find \.joined .before do
                $ \<span> .text @user .get \language


/*####################################
#             DEV TOOLS              #
####################################*/
module \downloadLink, do
    setup: -> @update!
    update: ->
        css \downloadLink, '
            .p0ne_downloadlink::before {
                content: " ";
                position: absolute;
                margin-top: -6px;
                margin-left: -27px;
                width: 30px;
                height: 30px;
                background-position: -140px -280px;
                background-image: url(/_/static/images/icons.26d92b9.png);
            }
        '
    module: (name, filename, data) ->
        if not data
            data = filename; filename = name
        data = JSON.stringify data if typeof data != \string
        url = URL.createObjectURL new Blob([data], {type: \text/plain})
        (window.$cm || $ \#chat-messages) .append "
            <div class='message p0ne_downloadlink'>
                <i class='icon'></i>
                <span class='text'>
                    <a href='#url' download='#filename'>#name</a>
                </span>
            </div>
        "


# DEBUGGING
window <<<<
    rename: (newName) ->
        ajax \user.change_name_1, [newName]

    searchEvents: (regx) ->
        regx = new RegExp(regx, \i) if regx not instanceof RegExp
        return [k for k of _$context?._events when regx.test k]


    listUsers: ->
        res = ""
        for u in API.getUsers!
            res += "#{u.id}\t#{u.username}\n"
        console.log res
    listUsersByAge: ->
        a = API.getUsers! .sort (a,b) ->
            a = +a.dateJoined.replace(/\D/g,'')
            b = +b.dateJoined.replace(/\D/g,'')
            return (a > b && 1) || (a == b && 0) || -1

        for u in a
            console.log u.dateJoined.replace(/T|\..+/g, ' '), u.username

    getUserData: (user) !->
        if typeof user == \number
            return $.get "/_/users/#user"
                .then ({[user]:data}) ->
                    console.log "[userdata]", user
                    console.log "[userdata] https://plug.dj/@/#{encodeURI user.slug}" if user.level >= 5
                .fail ->
                    console.warn "couldn't get slug for user with id '#{id}'"
        else if typeof user == \string
            user .= toLowerCase!
            for u in API.getUsers! when u.username.toLowerCase! == user
                return getUserData u.id
            console.warn "[userdata] user '#user' not found"
            return null

    findModule: (test) ->
        if typeof test == \string and window.l
            test = l(test)
        res = []
        for id, module of require.s.contexts._.defined when module
            if test module, id
                module.id ||= id
                console.log "[findModule]", id, module
                res[*] = module
        return res

    validateUsername: (username, cb) !->
        if not cb
            cb = (slug, err) -> console[err && \error || \log] "username '#username': ", err || slug

        if length < 2
            cb(false, "too short")
        else if length >= 25
            cb(false, "too long")
        else if username.indexOf("/") != -1
            cb(false, "forward slashes are not allowed")
        else if username.indexOf("\n") != -1
            cb(false, "line breaks are not allowed")
        else
            (d) <- $.getJSON "https://plug.dj/_/users/validate/#{encodeURIComponent username}"
            cb(d && d.data.0?.slug)

    getRequireArg: (haystack, needle) ->
        b = haystack.split "], function( "
        a = b.0.substr(b.0.indexOf('"')).split('", "')
        b = b.1.substr(0, b.1.indexOf(' )')).split(', ')
        return b[a.indexOf(needle)] || a[b.indexOf(needle)]

    logOnce: (base, event) ->
        if not event
            event = base
            if -1 != event.indexOf \:
                base = _$context
            else
                base = API
        base.once \event, (...args) ->
            console.log "[#{event .toUpperCase!}]", args

module \renameUser, do
    require: <[ users ]>
    module: (idOrName, newName) ->
        u = users.get(idOrName)
        if not u
            idOrName .= toLowerCase!
            for user in users.models when user.attributes.username.toLowerCase! == idOrName
                u = user; break
        if not u
            return console.error "[rename user] can't find user with ID or name '#idOrName'"
        u.set \username, newName
        id = u.id

        if not rup = window.p0ne.renameUserPlugin
            rup = window.p0ne.renameUserPlugin = (d) !->
                d.un = rup[d.fid] || d.un
            window.p0ne.chatPlugins?[*] = rup
        rup[id] = newName


do ->
    window._$events = {}
    for k,v of _$context?._events
        window._$events[k.replace(/:/g,'_')] = v


module \export_, do
    require: <[ downloadLink ]>
    exportRCS: ->
        # $ '.p0ne_downloadlink' .remove!
        for k,v of localStorage
            downloadLink "plugDjChat '#k'", k.replace(/plugDjChat-(.*?)T(\d+):(\d+):(\d+)\.\d+Z/, "$1 $2.$3.$4.html"), v

    exportPlaylists: ->
        # $ '.p0ne_downloadlink' .remove!
        for let pl in playlists
            $.get "/_/playlists/#{pl.id}/media" .then (data) ->
                downloadLink "playlist '#{pl.name}'",  "#{pl.name}.txt", data

