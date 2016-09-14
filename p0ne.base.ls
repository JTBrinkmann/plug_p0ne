/**
 * Base plug_p0ne modules
 * @author jtbrinkmann aka. Brinkie Pie
 * @version 1.0
 * @license MIT License
 * @copyright (c) 2014 J.-T. Brinkmann
 */
usernameToSlug = (un) ->
    $ \<span> .text un .html!
        .replace /[&;\s]+/g, '-'
        # some more characters get collapsed
        # some characters get converted to \u####


$body .addClass \playlist-view-icon if not window.playlistIconView
$body .addClass \legacy-chat if not window.legacyChat

window.censor = -> $body .toggleClass \censored
window.playlistIconView = -> $body .toggleClass \playlist-view-icon
window.legacyChat = -> $body.toggleClass \legacy-chat

/*####################################
#            AUXILIARIES             #
####################################*/
module \PopoutListener, do
    require: <[ PopoutView ]>
    optional: <[ _$context ]>
    setup: ->
        replace PopoutView, \render, (r_) -> return ->
            r_ ...
            _$context?.trigger \popout:open, PopoutView._window, PopoutView
            API.trigger \popout:open, PopoutView._window, PopoutView

module \grabMedia, do
    optional: <[ Curate playlists]>
    module: (playlistIDOrName, name) ->
        m = API.getMedia!
        id = +playlistIDOrName
        name = playlistIDOrName if not name and typeof playlistIDOrName == \string
        if m
            console.log "[Curate] add '#{m.author} - #{m.title}' to playlist: #playlist"
        else
            return console.error "[Curate] no DJ is playing!"

        if Curate
            if id
                for pl in playlists.models when playlistID == pl.id
                    playlist = pl; break
            else if name
                for pl in playlists.models when playlistID == pl.get \name
                    playlist = pl; break

            if playlist
                t = new Curate(pl.id, [m], false)
                t
                    .on \success, ->
                        console.log("[grab] success", arguments)
                    .on \error, ->
                        console.log("[grab] error", arguments)
                return true
            else
                console.warn "[grab] warning: using fallback, because the list of playlists couldn't be loaded"
        if typeof playlistIDOrName != \string
            console.error "[grab] error: can't curate to playlist by ID in fallback-mode (proper playlist module failed to load)"
            return

        $ \#grab .click!
        sleep 500ms, ->
            pls = $ '.pop-menu.grab ul span'
            for pl in pls when pl.innerText == name
                pl .mousedown!
                return

            console.warn "[Curate] playlist '#name' [#id] not found", pls


/*####################################
#             CUSTOM CSS             #
####################################*/
module \p0neCSS, do
    optional: <[ PopoutListener PopoutView ]>
    $popoutEl: $!
    styles: {}
    setup: ({addListener}) ->
        @$el = $ \<style> .appendTo \head
        {$el, $popoutEl, styles} = this
        addListener API, \popout:open, (_window) ->
            $popoutEl := $el .clone! .appendTo _window.document.head
        PopoutView.render! if PopoutView?._window

        export @getCustomCSS = (inclExternal) ->
            return $el .map (.outerHTML) .join \\n if inclExternal

        export @css = (name, css) ->
            return styles[name] if not css?

            styles[name] = css
            res = "<style>\n"
            for n,css of styles
                res += "/* #n */\n#css\n\n"
            res += "</style>"
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
                        .0
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
        @$sm .insertAfter \#playlist-panel

module \soundCloudThumbnailFix, do
    require: <[ auxiliaries ]>
    setup: ({replace}) ->
        a = $ \<a> .0
        replace auxiliaries, \deserializeMedia, -> return (e) !->
            e.author = this.h2t( e.author )
            e.title = this.h2t( e.title )
            if e.image
                if e.format == 2 # SoundCloud
                    a.href = e.image
                    if a.host == "plug.dj"
                        e.image = "https://cdn.plug.dj/_/static/images/soundcloud_thumbnail.c6d6487d52fe2e928a3a45514aa1340f4fed3032.png"
                else
                    e.image .= replace /^https?:\/\//, '//'


# adds a user-rollover to the FriendsList when clicking someone's name
module \friendslistUserPopup, do
    require: <[ friendsList FriendsList chat ]>
    setup: ({addListener}) ->
        addListener $ \.friends, \click, '.name, .image', (e) ->
            id = friendsList.rows[$ this.closest \.row .index!] ?.model.id
            user = users.get(id) if id
            data = x: $body.width! - 353px, y: e.screenY - 90px
            if user
                chat.onShowChatUser user, data
            else if id
                chat.getExternalUser id, data, (user) ->
                    chat.onShowChatUser user, data
        #replace friendsList, \drawBind, -> return _.bind friendsList.drawRow, friendsList

module \zalgoFix, do
    settings: \enableDisable
    displayName: 'Fix Zalgo Messages'
    setup: ->
        css \zalgoFix, '
            .message {
                overflow: hidden;
            }
        '

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
    settings: \enableDisable
    displayName: 'Restore Chat'
    setup: ({addListener}, rCS) ->
        # Event Listeners
        addListener $(window), \beforeunload, -> return "are you sure you want to leave?"
        addListener $(window), \unload, -> window.restoreChatScript.save!

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
    settings: \enableDisable
    displayName: 'Have yellow name as mod'
    setup: ->
        id = API.getUser! .id
        css \yellowMod, "
            \#chat .from-#id .from,
            \#chat .fromID-#id .from,
            \#chat .fromID-#id .un {
                color: \#ffdd6f !important;
            }
        "



/*####################################
#      DISABLE MESSAGE DELETE        #
####################################*/
module \disableChatDelete, do
    require: <[ _$context ]>
    optional: <[ socketListeners ]>
    settings: \enableDisable
    displayName: 'Show deleted messages'
    setup: ({replace_$Listener, addListener}) ->
        $body .addClass \p0ne_showDeletedMessages
        css \disableChatDelete, '
            .deleted {
                border-left: 2px solid red;
                display: none;
            }
            .p0ne_showDeletedMessages .deleted {
                disable: block;
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
                    .attr \datetime, t
                    .text t
                    .appendTo $msg
                cm = $cm!
                cm.scrollTop cm.scrollTop! + d.height!
                #scrollChatDown?! if wasAtBottom
        replace_$Listener \chat:delete, ->
            if not window.socket
                cb(cid)
        addListener _$context, \socket:chatDelete, ({c, u}) ->
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
    disable: ->
        $body .removeClass \p0ne_showDeletedMessages



/*####################################
#        DBLCLICK to @MENTION        #
####################################*/
module \chatDblclick2Mention, do
    require: <[ chat ]>
    optional: <[ PopoutListener ]>
    settings: \enableDisable
    displayName: 'DblClick username to Mention'
    setup: ({addListener, replace}) ->
        replace chat, \fromClickBind, ~> return (e) ~>
            if not @timer # single click
                @timer = sleep 200ms, ~> if @timer
                    @timer = 0
                    chat.onFromClick e
            else # double click
                clearTimeout @timer
                @timer = 0
                chat.onInputMention e.target.innerText
            e .stopPropagation!; e .preventDefault!



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
module \logEventsToConsole, do

    optional: <[ _$context  socketListeners ]>
    setup: ({replace}) ->
        addListener API, \chat, (data) ->
            message = htmlUnescape(data.message) .replace(/\u202e/g, '\\u202e')
            if data.un
                name = data.un .replace(/\u202e/g, '\\u202e') + ":"
                name = " " * (24 - name.length) + name
                console.log "#{getTime!} [CHAT]", "#name #message"
            else
                name = "[system]"
                console.info "#{getTime!} [CHAT]", "#name #message"

        addListener API, \userJoin, (data) ->
            name = htmlUnescape(data.username) .replace(/\u202e/g, '\\u202e')
            console.log "#{getTime!} + [JOIN]", data.id, name, "(#{getRank data})", data
        addListener API, \userLeave, (data) ->
            name = htmlUnescape(data.username) .replace(/\u202e/g, '\\u202e')
            console.log "#{getTime!} - [LEAVE]", data.id, name, "(#{getRank data})", data

        return if not window._$context
        addListener _$context, \PlayMediaEvent:play, (data) ->
            #data looks like {type: "PlayMediaEvent:play", media: n.hasOwnProperty.i, startTime: "1415645873000,0000954135", playlistID: 5270414, historyID: "d38eeaec-2d26-4d76-8029-f64e3d080463"}

            console.log "#{getTime!} [SongInfo]", "playlist:",data.playlistID, "historyID:",data.historyID

        replace _$context, \trigger, \trigger
    trigger: (trigger_) -> return (type) ->
        group = type.substr(0, type.indexOf ":")
        if group not in <[ socket tooltip djButton chat sio popout playback playlist notify drag audience anim HistorySyncEvent user ]> and type not in <[ ChatFacadeEvent:muteUpdate PlayMediaEvent:play userPlaying:update]>
            console.log "#{getTime!} [#type]", getArgs?! || arguments
        else if group == \socket and type not in <[ socket:chat socket:vote socket:grab socket:earn ]>
            console.info "#{getTime!} [#type]", [].slice.call(arguments, 1)
        /*else if type == "chat:receive"
            data = &1
            console.log "#{getTime!} [CHAT]", "#{data.from.id}:\t", data.text, {data}*/
        try
            return trigger_ ...
        catch e
            console.error "[_$context.trigger] Error when triggering '#type'", window.e=e



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
/*
# plug.dj updated somewhere in December 2014 so all .language are set to "en" of all users but yourself
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
*/


