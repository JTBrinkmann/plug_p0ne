/**
 * Fixes for plug.dj bugs
 *
 * @author jtbrinkmann aka. Brinkie Pie
 * @license MIT License
 * @copyright (c) 2015 J.-T. Brinkmann
 */


/*####################################
#                FIXES               #
####################################*/
module \simpleFixes, do
    setup: ({addListener, replace}) !->
        # hide social-menu (because personally, i only accidentally click on it. it's just badly positioned)
        @scm = $ '#twitter-menu, #facebook-menu, .shop-button' .detach! # not using .social-menu in case other scripts use this class to easily add buttons

        # add tab-index to chat-input
        replace $(\#chat-input-field).0, \tabIndex, !-> return 1

        # why would plug such a horrible thing as cleaning the localStorage?! Q~Q
        replace localStorage, \clear, !-> return $.noop

        # close Connection Error dialog when reconnected
        # otherwise the dialog FORCES you to refresh the page
        addListener API, \socket:reconnected, !->
            if app?.dialog.dialog?.options.title == Lang.alerts.connectionError
                app.dialog.$el.hide!

        # underscore.bind fix to allow `null` as first argument
        # this allows us performance optimizations (e.g. in chatDblclick2Mention)
        replace window._, \bind, (bind_) !-> return (func, context) !->
            if func
                return bind_ ...
            else
                return null
    disable: !->
        @scm? .insertAfter \#playlist-panel

# This fixes the current media reloading on socket reconnects, even if the song didn't change
/* NOT WORKING
module \fixMediaReload, do
    require: <[ currentMedia ]>
    setup: ({replace}) !->
        replace currentMedia, \set, (s_) !-> return (a, b) !->
            if a.historyID and a.historyID == @get \historyID
                console.log "avoid force-reloading current song"
                return this
            else
                return s_.call this, a, b

replaced with:
*/
/*
module \fixPseudoAdvance, do
    require: <[ socketEvents ]>
    setup: ({replace}) ->
        var lastHistoryID
        replace socketEvents, \advance, (a_) !-> return (data) !->
            if lastHistoryID != data.h
                # only trigger `advance()` if the historyID differs from the current one
                lastHistoryID := data.h
                return a_.call(this, data)
*/


module \fixMediaThumbnails, do
    require: <[ auxiliaries ]>
    help: '''
        Plug.dj changed the Soundcloud thumbnail URL several times, but never updated the paths in their song database, so many songs have broken thumbnail images.
        This module fixes this issue.
    '''
    setup: ({replace, $create}) !->
        replace auxiliaries, \deserializeMedia, !-> return (e) !->
            e.author = this.h2t( e.author )
            e.title = this.h2t( e.title )
            if e.image
                if e.format == 2 # SoundCloud
                    if parseURL(e.image).host in <[ plug.dj cdn.plug.dj ]>
                        e.image = "https://i.imgur.com/41EAJBO.png"
                        #"https://cdn.plug.dj/_/static/images/soundcloud_thumbnail.c6d6487d52fe2e928a3a45514aa1340f4fed3032.png" # 2014-12-22
                else
                    if e.image.startsWith("http:") or e.image.startsWith("//")
                        e.image = "https:#{e.image.substr(e.image.indexOf('//'))}"
                    #if window.webkitURL # use webp on webkit browsers, for moar speed
                    #    not available on all videos
                    #    e.image = "https://i.ytimg.com/vi_webp/#{e.cid}/sddefault.webp


module \fixGhosting, do
    displayName: 'Fix Ghosting'
    require: <[ PlugAjax ]>
    settings: \fixes
    settingsMore: !-> return $ '<toggle val=warnings>Show Warnings</toggle>'
    help: '''
        Plug.dj sometimes considers you to be "not in any room" even though you still are. This is also called "ghosting" because you can chat in a room that technically you are not in anymore. While ghosting you can still chat, but not join the waitlist or moderate. If others want to @mention you, you don't show up in the autocomplete.

        tl;dr this module automatically rejoins the room when you are ghosting
    '''
    _settings:
        verbose: true
    setup: ({replace, addListener}) !->
        _settings = @_settings
        rejoining = false
        queue = []

        addListener API, \socket:userLeave, ({p}) !-> if p == userID
            sleep 100ms, !->
                # to avoid problems, like auto-rejoining when closing the tab
                rejoinRoom 'you left the room'

        replace PlugAjax::, \onError, (oE_) !-> return (code, e) !->
            if e.status == \notInRoom
                #or status == \notFound # note: notFound is only returned for valid URLs, actually requesting not existing files returns a 404 error instead; update: TOO RISKY!
                queue[*] = this
                rejoinRoom "got 'notInRoom' error from plug", true
            else
                oE_.call(this, e)

        export rejoinRoom = (reason, throttled) !->
                if rejoining and throttled
                    console.warn "[fixGhosting] You are still ghosting, retrying to connect."
                else
                    console.warn "[fixGhosting] You are ghosting!", "Reason: #reason"
                    rejoining := true
                    ajax \POST, \rooms/join, slug: getRoomSlug!, do
                        success: (data) !->
                            if data.responseText?.0 == "<" # indicator for IP/user ban
                                if data.responseText .has "You have been permanently banned from plug.dj"
                                    # for whatever reason this responds with a status code 200
                                    chatWarn "your account got permanently banned. RIP", "fixGhosting"
                                else
                                    chatWarn "cannot rejoin the room. Plug is acting weird, maybe it is in maintenance mode or you got IP banned?", "fixGhosting"
                            else
                                chatWarn "reconnected to the room", "fixGhosting" if _settings.verbose
                                for req in queue
                                    req.execute! # re-attempt whatever ajax requests just failed
                                rejoining := false
                                _$context?.trigger \p0ne:reconnected
                                API.trigger \p0ne:reconnected
                        error: ({statusCode, responseJSON}:data) !~>
                            status = responseJSON?.status
                            switch status
                            | \ban =>
                                chatWarn "you are banned from this community", "fixGhosting"
                            | \roomCapacity =>
                                chatWarn "the room capacity is reached :/", "fixGhosting"
                            | \notAuthorized =>
                                chatWarn "you got logged out", "fixGhosting"
                                #login?!
                            | otherwise =>
                                switch statusCode
                                | 401 =>
                                    chatWarn "unexpected permission error while rejoining the room.", "fixGhosting"
                                    #ToDo is an IP ban responding with status 401?
                                | 503 =>
                                    chatWarn "plug.dj is in mainenance mode. nothing we can do here", "fixGhosting"
                                | 521, 522, 524 =>
                                    chatWarn "plug.dj is currently completly down", "fixGhosting"
                                | otherwise =>
                                    chatWarn "cannot rejoin the room, unexpected error #{statusCode} (#{datastatus})", "fixGhosting"
                            # don't try again for the next 10min
                            sleep 10.min, !->
                                rejoining := false


module \fixOthersGhosting, do
    require: <[ users socketEvents ]>
    displayName: "Fix Other Users Ghosting"
    settings: \fixes
    settingsMore: !-> return $ '<toggle val=warnings>Show Warnings</toggle>'
    help: '''
        Sometimes plug.dj does not properly emit join notifications, so that clients don't know another user joined a room. Thus they appear as "ghosts", as if they were not in the room but still can chat

        This module detects "ghost" users and force-adds them to the room.
    '''
    _settings:
        verbose: true
    setup: ({addListener, css}) !->
        addListener API, \chat, (d) !~> if d.uid and not users.get(d.uid)
            console.info "[fixOthersGhosting] seems like '#{d.un}' (#{d.uid}) is ghosting"

            #ajax \GET, "users/#{d.uid}", (status, data) !~>
            ajax \GET, "rooms/state"
                .then (data) !~>
                    # "manually" trigger socket event for DJ advance
                    for u, i in data.0.users when not users.get(u.id)
                        socketEvents.userJoin u
                        chatWarn "force-joined ##i #{d.un} (#{d.uid}) to the room", "p0ne" if @_settings.verbose
                    else
                        ajax \GET "users/#{d.uid}", (data) !~>
                            data.role = -1
                            socketEvents.userJoin data
                            chatWarn "#{d.un} (#{d.uid}) is ghosting", "p0ne" if @_settings.verbose
                .fail !->
                    console.error "[fixOthersGhosting] cannot load room data:", status, data
                    console.error "[fixOthersGhosting] cannot load user data:", status, data


module \fixStuckDJ, do
    require: <[ socketEvents ]>
    optional: <[ votes ]>
    displayName: "Fix Stuck Advance"
    settings: \fixes
    settingsMore: !-> return $ '<toggle val=warnings>Show Warnings</toggle>'
    help: '''
        Sometimes plug.dj does not automatically start playing the next song. Usually you would have to reload the page to fix this bug.

        This module detects stuck advances and automatically force-loads the next song.
    '''
    _settings:
        verbose: true
    setup: ({replace, addListener}) !->
        fixStuckDJ = this
        @timer := sleep 5_000ms, fixStuckDJ if API.getTimeRemaining! == 0s and API.getMedia!

        addListener API, \advance, (d) !~>
            console.log "#{getTime!} [API.advance]"
            clearTimeout @timer
            if d.media
                @timer = sleep d.media.duration*1_000s_to_ms + 2_000ms, fixStuckDJ
    module: !->
        # no new song played yet (otherwise this change:media would have cancelled this)
        fixStuckDJ = this
        if showWarning = API.getTimeRemaining! == 0s
            console.warn "[fixNoAdvance] song seems to be stuck, trying to fix…"

        m = API.getMedia! ||{}
        ajax \GET, \rooms/state, do
            error: (data) !~>
                console.error "[fixNoAdvance] cannot load room data:", status, data
                @timer := sleep 10_000ms, fixStuckDJ
            success: (data) !~>
                data.0.playback ||= {}
                if m.id == data.0.playback?.media?.id
                    console.log "[fixNoAdvance] the same song is still playing."
                else
                    # "manually" trigger socket event for DJ advance
                    data.0.playback ||= {}
                    socketEvents.advance do
                        c: data.0.booth.currentDJ
                        d: data.0.booth.waitingDJs
                        h: data.0.playback.historyID
                        m: data.0.playback.media
                        t: data.0.playback.startTime
                        p: data.0.playback.playlistID

                    if votes?
                        for uid of data.0.grabs
                            votes.grab uid
                        for i,v of data.0.votes
                            votes.vote {i,v}
                    else
                        console.warn "[fixNoAdvance] cannot properly set votes, because optional requirement `votes` is missing"
                    chatWarn "fixed DJ not advancing", "p0ne" if @_settings.verbose and showWarning


/*
module \fixNoPlaylistCycle, do
    require: <[ _$context ActivateEvent ]>
    displayName: "Fix No Playlist Cycle"
    settings: \fixes
    settingsMore: !-> return $ '<toggle val=warnings>Show Warnings</toggle>'
    help: '''
        Sometimes after DJing, plug.dj does not move the played song to the bottom of the playlist.

        This module automatically detects this bug and moves the song to the bottom.
    '''
    _settings:
        verbose: true
    setup: ({addListener}) !->
        addListener API, \socket:reconnected, !->
            _$context.dispatch new LoadEvent(LoadEvent.LOAD)
            _$context.dispatch new ActivateEvent(ActivateEvent.ACTIVATE)
        / *
        # manual check
        addListener API, \advance, ({dj, lastPlay}) !~>
            #ToDo check if spelling is correctly
            #ToDo get currentPlaylist
            if dj?.id == userID and lastPlay.media.id == currentPlaylist.song.id
                #_$context .trigger \MediaMoveEvent:move
                ajax \PUT, "playlists/#{currentPlaylist.id}/media/move", ids: [lastPlay.media.id], beforeID: 0
                chatWarn "fixed playlist not cycling", "p0ne" if @_settings.verbose
        * /
*/

module \fixStuckDJButton, do
    settings: \fixes
    displayName: 'Fix Stuck DJ Button'
    require: <[ _$context ]>
    setup: ({addListener}) ->
        var fixTimeout
        $djbtn = $ \#dj-button
        hasSpinner = $djbtn.find \.spinner .length != 0
        addListener _$context, \djButton:update, ->
            if $djbtn.find \.spinner .length == 0
                hasSpinner := false
                clearTimeout fixTimeout
            else if not hasSpinner
                hasSpinner := true
                fixTimeout = sleep 10_000ms, ->
                    getRoomState! .then (d) ->
                        d = d.data.0
                        if (d.currentDJ == userID or d.waitingDJs .lastIndexOf(userID) != -1)
                            if app?.room.djButton
                                app.room.djButton.hideSpinner!
                            else # pseudo djButton.hideSpinner()
                                $djbtn .find \.spinner .remove!
                                $djbtn .find \.icon .show!


module \zalgoFix, do
    settings: \fixes
    displayName: 'Fix Zalgo Messages'
    help: '''
        This avoids messages' text bleeding out of the message, as it is the case with so called "Zalgo" messages.
        Enable this if you are dealing with spammers in the chat who use Zalgo.
    '''
    setup: ({css}) !->
        css \zalgoFix, '
            .message {
                overflow: hidden;
            }
        '



module \warnOnAdblockPopoutBlock, do
    require: <[ PopoutListener ]>
    setup: ({addListener}) !->
        isOpen = false
        warningShown = false
        addListener API, \popout:open, (_window, PopoutView) !->
            isOpen := true
            sleep 1_000ms, !-> isOpen := false
        addListener API, \popout:close, (_window, PopoutView) !->
            if isOpen and not warningShown
                chatWarn "Popout chat immediately closed again. This might be because of an adblocker. You'd have to make an exception for plug.dj or disable your adblocker. Specifically Adblock Plus is known for causing this problem", "p0ne"
                warningShown := true
                sleep 15.min !->
                    warningShown := false


module \chatEmojiPolyfill, do
    require: <[ users ]>
    #optional: <[ chatPlugin socketEvents database ]> defined later
    _settings:
        verbose: true
    fixedUsernames: {}
    originalNames: {}
    setup: ({addListener, replace}) !-> _.defer !~>
        /*@security HTML injection should NOT be possible */
        /* Emoji-support detection from Modernizr https://github.com/Modernizr/Modernizr/blob/master/feature-detects/emoji.js */
        try
            pixelRatio = window.devicePixelRatio || 1; offset = 12 * pixelRatio
            document.createElement \canvas .getContext \2d
                ..fillStyle = \#f00
                ..textBaseline = \top
                ..font = '32px Arial'
                ..fillText '\ud83d\udc28', 0px, 0px # U+1F428 KOALA
                if ..getImageData(offset, offset, 1, 1).data[0] !== 0
                    console.info "[chatPolyfixEmoji] emojicons appear to be natively supported. fix will not be applied"
                    @disable!
                else
                    console.info "[chatPolyfixEmoji] emojicons appear to NOT be natively supported. applying fix…"
                    css \chatPolyfixEmoji, '
                        .emoji {
                            position: relative;
                            display: inline-block;
                        }
                    '
                    # cache usernames that require fixing
                    # note: .rawun is used, because it's already HTML escaped
                    for u in users?.models ||[] when (tmp=emojifyUnicode u.get(\rawun)) != (original=u.get \rawun)
                        console.log "\t[chatPolyfixEmoji] fixed username from '#original' to '#{unemojify tmp}'" if @_settings.verbose
                        u.set \rawun, @fixedUsernames[u.id] = tmp
                        @originalNames[u.id] = original
                        # ooooh dangerous dangerous :0
                        # (not with regard to security, but breaking other scripts)
                        # (though .rawun should only be used for inserting HTML)
                        # i really hope this doesn't break anything :I
                        #                                   --Brinkie 2015
                    if @fixedUsernames[userID]
                        user.rawun = @fixedUsernames[userID]
                        userRegexp = //@#{user.rawun}//g


                    if _$context?
                        # fix joining users
                        addListener _$context, \user:join, (u) !~>
                            if  (tmp=emojifyUnicode u.get(\rawun)) != (original=u.get \rawun)
                                console.log "[chatPolyfixEmoji] fixed username '#original' => '#{unemojify tmp}'" if @_settings.verbose
                                u.set \rawun, @fixedUsernames[u.id] = tmp
                                @originalNames[u.id] = original

                        # prevent memory leak
                        addListener _$context, \user:leave, (u) !~>
                            delete @fixedUsernames[u.id]
                            delete @originalNames[u.id]

                        # fix incoming messages
                        addListener _$context, \chat:plugin, (msg) !~>
                            # fix the message body
                            if msg.uid and msg.message != (tmp = emojifyUnicode(msg.message))
                                console.log "\t[chatPolyfixEmoji] fixed message '#{msg.message}' to '#{unemojify tmp}'" if @_settings.verbose
                                msg.message = tmp

                                # fix the username
                                if @fixedUsernames[msg.uid]
                                    # usernames may not contain HTML, also .rawun is HTML escaped.
                                    # The HTML that's added by the emoji fix is considered safe
                                    # we modify it, so that the sender's name shows up fixed in the chat
                                    msg.un_ = msg.un
                                    msg.un = that

                                if userRegexp?
                                    userRegexp.lastIndex = 0
                                    if userRegexp.test msg.message
                                        console.log "\t[chatPolyfixEmoji] fix mention"
                                        msg.type = \mention
                                        msg.sound = \mention if database?.settings.chatSound
                                        msg.[]mentions.push "@#{user.rawun}"
                        # as soon as possible, we have to restore the sender's username again
                        # otherwise other modules might act weird, such as disableCommand
                        addListener \early, API, \chat, (msg) !->
                            if msg.un_
                                msg.un = msg.un_
                                delete msg.un_

                        # fix users on name changes
                        addListener _$context, \socket:userUpdate, (u) !~>
                            # note: this gets called BEFORE userUpdate is natively processed
                            # so changes to `u` will be applied
                            delete @fixedUsernames[u.id]
                            if (tmp=emojifyUnicode u.rawun) != u.rawun
                                console.log "[chatPolyfixEmoji] fixed username '#{u.rawun}' => '#{unemojify tmp}'" if @_settings.verbose
                                u.rawun = @fixedUsernames[u.id] = tmp
                                if u.id == userID
                                    user.rawun = @fixedUsernames[userID]
                                    userRegexp := //@#{user.rawun}//g
        catch err
            console.error "[chatPolyfixEmoji] error", err.stack
    disable: !->
        for uid, original of @originalNames
            getUserInternal(uid)? .set \rawun, original
        if @originalNames[userID]
            user.rawun = @originalNames[userID]


module \disableIntercomTracking, do
    require: <[ tracker ]>
    disabled: true
    settings: \dev
    displayName: 'Disable Tracking'
    setup: ({replace}) !->
        for k,v of tracker when typeof v == \function
            replace tracker, k, !-> return !-> return $.noop
        replace tracker, \event, !-> return !-> return this
