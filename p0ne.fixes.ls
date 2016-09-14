/**
 * Fixes for plug.dj bugs
 * @author jtbrinkmann aka. Brinkie Pie
 * @version 1.0
 * @license MIT License
 * @copyright (c) 2014 J.-T. Brinkmann
 */


/*####################################
#                FIXES               #
####################################*/
module \simpleFixes, do
    setup: ({replace}) ->
        # hide social-menu (because personally, i only accidentally click on it. it's just badly positioned)
        @$sm = $ \.social-menu .remove!

        # add tab-index to chat-input
        $ \#chat-input-field .prop \tabIndex, 1
    disable: ->
        @$sm .insertAfter \#playlist-panel
        $ \#chat-input-field .prop \tabIndex, null

module \soundCloudThumbnailFix, do
    require: <[ auxiliaries ]>
    help: '''
        Plug.dj changed the Soundcloud thumbnail file location several times, but never updated the paths in their song database, so many songs have broken thumbnail images.
        This module fixes this issue.
    '''
    setup: ({replace, $create}) ->
        replace auxiliaries, \deserializeMedia, -> return (e) !->
            e.author = this.h2t( e.author )
            e.title = this.h2t( e.title )
            if e.image
                if e.format == 2 # SoundCloud
                    if parseURL(e.image).host in <[ plug.dj cdn.plug.dj ]>
                        e.image = "https://i.imgur.com/41EAJBO.png"
                        #"https://cdn.plug.dj/_/static/images/soundcloud_thumbnail.c6d6487d52fe2e928a3a45514aa1340f4fed3032.png" # 2014-12-22
                else if e.image.startsWith("http:") or e.0 == e.1 == '/'
                    e.image = "https:#{e.image.substr(5)}"


module \fixGhosting, do
    displayName: 'Fix Ghosting'
    require: <[ PlugAjax ]>
    optional: <[ login ]>
    settings: -> return $ '<toggle val=warnings>Show Warnings</toggle>'
    help: '''
        Plug.dj sometimes marks you internally as "not in any room" even though you still are. This is also called "ghosting" because you can chat in a room that technically you are not in anymore. While ghosting you can still chat, but not join the waitlist or moderate. If others want to @mention you, you don't show up in the autocomplete.

        tl;dr this module automatically rejoins the room when you are ghosting
    '''
    _settings:
        warnings: true
    setup: ({replace, addListener}) ->
        _settings = @_settings
        rejoining = false
        queue = []

        addListener API, \socket:userLeave, ({p}) -> if p == userID
            rejoinRoom 'you left the room'

        replace PlugAjax::, \onError, (oE_) -> return (status, data) ->
            if status == \notInRoom
                #or status == \notFound # note: notFound is only returned for valid URLs, actually requesting not existing files returns a 404 error instead; update: TOO RISKY!
                queue[*] = this
                rejoinRoom "got 'notInRoom' error from plug", true
            else
                oE_ ...

        export rejoinRoom = (reason, throttled) ->
                if rejoining and throttled
                    console.warn "[fixGhosting] You are still ghosting, retrying to connect."
                else
                    console.warn "[fixGhosting] You are ghosting!", "Reason: #reason"
                    rejoining := true
                    ajax \POST, \rooms/join, slug: getRoomSlug!, do
                        success: (data) ~>
                            if data.responseText?.0 == "<" # indicator for IP/user ban
                                if data.responseText .has "You have been permanently banned from plug.dj"
                                    # for whatever reason this responds with a status code 200
                                    API.chatLog "your account got permanently banned. RIP", true
                                else
                                    API.chatLog "[fixGhosting] cannot rejoin the room. Plug is acting weird, maybe it is in maintenance mode or you got IP banned?", true
                            else
                                API.chatLog "[fixGhosting] reconnected to the room", true if _settings.warnings
                                for req in queue
                                    req.execute! # re-attempt whatever ajax requests just failed
                                rejoining := false
                        error: ({statusCode, responseJSON}:data) ~>
                            status = responseJSON?.status
                            switch status
                            | \ban =>
                                API.chatLog "you are banned from this community", true
                            | \roomCapacity =>
                                API.chatLog "the room capacity is reached :/", true
                            | \notAuthorized =>
                                API.chatLog "you got logged out", true
                                login?!
                            | otherwise =>
                                switch statusCode
                                | 401 =>
                                    API.chatLog "[fixGhosting] unexpected permission error while rejoining the room.", true
                                    #ToDo is an IP ban responding with status 401?
                                | 503 =>
                                    API.chatLog "plug.dj is in mainenance mode. nothing we can do here"
                                | 521, 522, 524 =>
                                    API.chatLog "plug.dj is currently completly down"
                                | otherwise =>
                                    API.chatLog "[fixGhosting] cannot rejoin the room, unexpected error #{statusCode} (#{datastatus})", true
                            # don't try again for the next 10min
                            sleep 10 *min_to_ms, ->
                                rejoining := false

module \fixOthersGhosting, do
    require: <[ users socketEvents ]>
    displayName: "Fix Other Users Ghosting"
    settings: -> return $ '<toggle val=warnings>Show Warnings</toggle>'
    help: '''
        Sometimes plug.dj does not properly emit join notifications, so that clients don't know another user joined a room. Thus they appear as "ghosts", as if they were not in the room but still can chat

        This module detects "ghost" users and force-adds them to the room.
    '''
    _settings:
        warnings: true
    setup: ({addListener, css}) ->
        addListener API, \chat, (d) ~> if d.uid and not users.get(d.uid)
            console.info "[fixOthersGhosting] seems like '#{d.un}' (#{d.uid}) is ghosting"

            #ajax \GET, "users/#{d.uid}", (status, data) ~>
            ajax \GET, "rooms/state"
                .then (data) ~>
                    # "manually" trigger socket event for DJ advance
                    for u, i in data.0.users when not users.get(u.id)
                        socketEvents.userJoin u
                        API.chatLog "[p0ne] force-joined ##i #{d.un} (#{d.uid}) to the room", true if @_settings.warnings
                    else
                        ajax \GET "users/#{d.uid}", (data) ~>
                            data.role = -1
                            socketEvents.userJoin data
                            API.chatLog "[p0ne] #{d.un} (#{d.uid}) is ghosting", true if @_settings.warnings
                .fail ->
                    console.error "[fixOthersGhosting] cannot load room data:", status, data
                    console.error "[fixOthersGhosting] cannot load user data:", status, data

module \fixStuckDJ, do
    require: <[ Playback socketEvents ]>
    displayName: "Fix Stuck Advance"
    settings: -> return $ '<toggle val=warnings>Show Warnings</toggle>'
    help: '''
        Sometimes plug.dj does not automatically start playing the next song. Usually you would have to reload the page to fix this bug.

        This module detects stuck advances and automatically force-loads the next song.
    '''
    _settings:
        warnings: true
    setup: ({replace, addListener}) ->
        _settings = @_settings
        fixStuckDJ = this
        fixStuckDJ.timer := sleep 15s *s_to_ms, fixStuckDJ if API.getTimeRemaining! == 0s
        replace Playback::, \playbackComplete, (pC_) -> return ->
            args = arguments
            replace Playback::, \playbackComplete, ~>
                fn = ->
                    # wait 5s before checking if advance is stuck
                    fixStuckDJ.timer := sleep 15s *s_to_ms, fixStuckDJ
                    clearTimeout fixStuckDJ.timer
                    pC_ ...
                fn.apply this, args
                return fn

        addListener API, \advance, ~>
            clearTimeout @timer
    module: ->
        # no new song played yet (otherwise this change:media would have cancelled this)
        fixStuckDJ = this
        console.warn "[fixNoAdvance] song seems to be stuck, trying to fix…"
        ajax \GET, \rooms/state, (data) ~>
            if not status == 200
                console.error "[fixNoAdvance] cannot load room data:", status, data
                @timer := sleep 5s *s_to_ms, fixStuckDJ
            else
                # "manually" trigger socket event for DJ advance
                socketEvents.advance do
                    c: data.0.booth.currentDJ
                    d: data.0.booth.waitingDJs
                    h: data.0.playback.historyID
                    m: data.0.playback.media
                    t: data.0.playback.startTime
                    p: data.0.playback.playlistID

                API.chatLog "[p0ne] fixed DJ not advancing", true if @_settings.warnings

module \fixNoPlaylistCycle, do
    require: <[ NOT_FINISHED ]>
    displayName: "Fix No Playlist Cycle"
    settings: -> return $ '<toggle val=warnings>Show Warnings</toggle>'
    help: '''
        Sometimes after DJing, plug.dj does not move the played song to the bottom of the playlist.

        This module automatically detects this bug and moves the song to the bottom.
    '''
    _settings:
        warnings: true
    setup: ({addListener}) ->
        addListener API, \advance, ({dj, lastPlay}) ~>
            #ToDo check if spelling is correctly
            #ToDo get currentPlaylist
            if dj?.id == userID and lastPlay.media.id == currentPlaylist.song.id
                #_$context .trigger \MediaMoveEvent:move
                ajax \PUT, "playlists/#{currentPlaylist.id}/media/move", ids: [lastPlay.media.id], beforeID: 0
                API.chatLog "[p0ne] fixed playlist not cycling", true if @_settings.warnings



module \zalgoFix, do
    settings: true
    displayName: 'Fix Zalgo Messages'
    setup: ({css}) ->
        css \zalgoFix, '
            .message {
                overflow: hidden;
            }
        '

module \fixWinterThumbnails, do
    setup: ({css}) ->
        avis = [".thumb .avi-2014winter#{pad i}" for i from 1 to 10].join(', ')
        css \fixWinterThumbnails, "
            #{avis} {
                background-position-y: 0 !important;
            }
        "
