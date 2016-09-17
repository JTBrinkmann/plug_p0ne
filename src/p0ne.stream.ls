/**
 * Modules for Audio-Only stream and stream settings for plug_p0ne
 *
 * @author jtbrinkmann aka. Brinkie Pie
 * @license MIT License
 * @copyright (c) 2015 J.-T. Brinkmann
*/
/* This modules includes the following things:
    - audio steam
    - a stream-settings field in the playback-controls (replacing the HD-button)
    - a blocked-video-unblocker
   These are all conbined into this one module to avoid conflicts
   and due to them sharing a lot of code
*/
module \streamSettings, do
    settings: \dev
    displayName: 'Stream-Settings'
    require: <[ app Playback currentMedia database _$context ]>
    optional: <[ database plugUrls ]>
    audioOnly: false
    _settings:
        audioOnly: false
    setup: ({addListener, replace, revert, replaceListener, $create, css}, streamSettings, m_) !->
        css \streamSettings "
            .icon-stream-video {
                background: #{getIcon \icon-chat-sound-on .background};
            }
            .icon-stream-audio {
                background: #{getIcon \icon-chat-room .background};
            }
            .icon-stream-off {
                background: #{getIcon \icon-chat-sound-off .background};
            }
        "

        $playback = $ \#playback
        $playbackContainer = $ \#playback-container
        $el = $create '<div class=p0ne-stream-select>'
        playback = {}

        if m_?._settings # keep audio-only setting on update
            @_settings.audioOnly = m_._settings.audioOnly


        # replace HD button
        $ \#playback-controls .removeClass 'no-hd snoozed'
        replace Playback::, \onHDClick, !-> return $.noop
        $btn = $ '#playback .hd'
            .addClass \p0ne-stream-select
        @$btn_ = $btn.children!
        $btn .html '
                <div class="box">
                    <span id=p0ne-stream-label></span>
                    <div class="p0ne-stream-buttons">
                        <i class="icon icon-stream-video enabled"></i> <i class="icon icon-stream-audio enabled"></i> <i class="icon icon-stream-off enabled"></i> <div class="p0ne-stream-fancy"></div>
                    </div>
                </div>
            '
        @$label = $label = $btn .find \#p0ne-stream-label
        $icons = $btn .find \.icon

        #= make buttons disable-able =
        disabledBtns = {}
        function disableBtn mode
            disabledBtns[mode] = true
            $icon = $btn.find ".icon-stream-#mode" .removeClass \enabled

        addListener API, \advance, (d) !~> if d.media
            for mode of disabledBtns
                $btn.find ".icon-stream-#mode" .addClass \enabled
                delete disabledBtns[mode]
            if d.media.format == 2
                disableBtn \video


        # not using addListener here, because we are working on module-created elements
        $btn.find \.icon-stream-video .on \click, !~> if not disabledBtns.video
            database.settings.streamDisabled = false
            @_settings.audioOnly = false
            changeStream \video
            refresh!
        $btn.find \.icon-stream-audio .on \click, !~> if not disabledBtns.audio
            database.settings.streamDisabled = false
            @_settings.audioOnly = true if 2 != currentMedia.get(\media)?.get(\format)
            changeStream \audio
            refresh!
        $btn.find \.icon-stream-off   .on \click, !~>
            database.settings.streamDisabled = true
            changeStream \off
            refresh!


        #== Define Players ==
        Player =
            enable: !->
                console.log "[StreamSettings] loading #{@name} stream"
                media = currentMedia.get \media
                if @media == media and this == player
                    @start!
                else
                    @media = media
                    @getURL(media)
            /*getURL: !->
                ...
                @media.src = ...
                @start!*/
            start: !->
                @seek!
                @src = @media.src
                @load!
                @updateVolume(currentMedia.get \volume)
                $playbackContainer .append this
            disable: !->
                @src = "" # note: `null` would actually refer to https://plug.dj/null
                $playbackContainer .empty!
            seek: !->
                startTime = currentMedia.get \elapsed
                if player != this
                    return
                else if startTime > 4s and currentMedia.get(\remaining) > 4s
                    @seekTo(startTime)
                    console.log "[StreamSettings] #{@name} seeking…", mediaTime(startTime)
                else
                    @play!
            seekTo: (t) !->
                @currentTime = t
            updateVolume: (vol) !->
                @volume = vol / 100perc

        #= Audio and Video Players common core =
        audio = m_?.audio || new Audio()
        unblocker = m_?.audio || document.createElement \video # because why should `new Video` work >_>
        $ [unblocker, audio] .addClass \media



        for let k, p of {audio, unblocker}
            p <<<< Player
            p.addEventListener \canplay, !->
                console.log "[#k stream] finished buffering"
                if currentMedia.get(\media) == player.media and player == this
                    diff = currentMedia.get(\elapsed) - player.currentTime
                    if diff > 4s and currentMedia.get(\remaining) > 4s
                        #player.init = false
                        @seek!
                        #sleep 2_000ms, !-> if player.paused
                        #    console.warn "[#k stream] still not playing. forcing #k.play()"
                        #    player.play!
                    else
                        player.play!
                        console.log "[#k stream] playing song (diff #{humanTime(diff, true)})"
                else
                    console.warn "[#k stream] next song already started"

        #= Audio Player =
        audio.name = "Audio-Only"
        audio.mode = \audio
        audio.getURL = (media) !->
            #audio.init = true
            mediaDownload media, true
                .then (d) !~>
                    console.log "[audioStream] found url. Buffering…", d
                    audio.media = media
                    media.src = d.preferredDownload.url
                    @enable!

                .fail (err) !->
                    console.error "[audioStream] couldn't get audio-only stream", err
                    chatWarn "couldn't load audio-only stream, using video instead", "audioStream", true
                    media.audioFailed = true
                    refresh!
                    disableBtn \audio
                    $playback .addClass \p0ne-stream-audio-failed
                    API.once \advance, !->
                        $playback .addClass \p0ne-stream-audio-failed

        #= Unblocked Youtube Player =
        /*not working*/
        unblocker.name = "Youtube (unblocked)"
        unblocker.mode = \video
        unblocker.getURL = (media) !->
            console.log "[YT Unblocker] receiving video URL", media
            blocked = media.get \blocked
            mediaDownload media
                .then (d) !~>
                    media.src = d.preferredDownload.url
                    console.log "[YT Unblocker] got video URL", media.src
                    @start!
                .fail !->
                    media.set \blocked, blocked++
                    if blocked == 2
                        chatWarn "failed, trying again…", "YT Unblocker"
                        refresh!
                    else
                        chatWarn "failed to unblock video :(", "YT Unblocker"
                        disableBtn \video

        #= Vanilla Youtube Player =
        youtube = Player with
            name: "Video"
            mode: \video
            enable: (@media) !->
                console.log "[StreamSettings] loading Youtube stream"
                startTime = currentMedia.get \elapsed
                playback.buffering = false
                playback.yto =
                    id: media.get \cid
                    volume: currentMedia.get \volume
                    seek: if startTime < 4s then 0s else startTime
                    quality: if database.hdVideo then \hd720 else ""

                $ "<iframe id=yt-frame frameborder=0 src='//plgyte.appspot.com/yt5.html'>"
                    .load playback.ytFrameLoadedBind
                    .appendTo playback.$container
            disable: !->
                $playbackContainer .empty!
            updateVolume: (vol) !->
                playback.tx "setVolume=#vol"

        #= Vanilla Soundcloud Player =
        sc = Player with
            name: "SoundCloud"
            mode: \audio
            enable: (@media) !~>
                console.log "[StreamSettings] loading Soundcloud audio stream"
                if soundcloud.r # soundcloud player is ready (loaded)
                    if soundcloud.sc
                        playback.$container
                            .empty!
                            .append "<iframe id=yt-frame frameborder=0 src='#{playback.visualizers.random!}'></iframe>"
                        b = setTimeout playback.scTimeoutBind, 5_000ms
                        soundcloud.sc.whenStreamingReady !->
                            soundcloud.sc.stream do
                                media .get \cid
                                autoPlay: true
                                (e) !->
                                    clearTimeout(b)
                                    if media != currentMedia.get \media # SC DOUBLE PLAY FIX
                                        return e.stop!
                                    playback.player = e
                                    startTime = currentMedia.get \elapsed
                                    e.seek(if startTime < 4s then 0ms else startTime *1_000s_to_ms)
                                    e.setVolume(currentMedia.get(\volume) / 100)
                                    e._player.on \stateChange, playback.scStateBind
                    else
                        playback.$container.append do
                            $ '<img src="https://soundcloud-support.s3.amazonaws.com/images/downtime.png" height="271"/>'
                                .css do
                                    position: \absolute
                                    left: 46px
                else
                    _$context.off \sc:ready, @SCReadyCB if @SCReadyCB
                    _$context.once \sc:ready, @SCReadyCB = !~>
                        soundcloud.updateVolume(currentMedia.get \volume)
                        if media == currentMedia.get \media
                            playback.onSCReady!
                        else
                            console.warn "[StreamSettings] Soundcloud: a different song already started playing"
            disable: !->
                playback.player?
                    .stop!
                playback.buffering = false
                $playbackContainer .empty!
            #seekTo: $.noop
            updateVolume: (vol) !->
                playback.player.setVolume vol / 100

        # pseudo players
        DummyPlayer =
            enable: $.noop
            disable: $.noop
            updateVolume: $.noop

        noDJ = DummyPlayer with
            name: "No DJ"
            mode: \off
            enable: !->
                playback.$noDJ.show!
                playback.$controls.hide!
            disable: !->
                playback.$noDJ.hide!

        syncingPlayer = DummyPlayer with
            name: "waiting…"
            mode: \off
            enable: !->
                $playbackContainer
                    .html "<iframe id=yt-frame frameborder=0 src='#{plugUrls?.syncing || '/_/visualizers/arcs'}'></iframe>"
            updateVolume: $.noop

        streamOff = DummyPlayer with
            name: "Stream: OFF"
            mode: \off
        snoozed = DummyPlayer with
            name: "Snoozed"
            mode: \off

        if m = currentMedia.get \media
            player = do
                if database.settings.streamDisabled
                    streamOff
                else if isSnoozed!
                    snoozed
                else
                    [youtube, sc][m .get(\format) - 1]
        else
            player = noDJ
        changeStream player




        replace Playback::, \onVolumeChange, !-> return (,vol) !->
            player.updateVolume vol

        replace Playback::, \onMediaChange, (oMC_) !-> return !->
            @reset!
            @$controls.removeClass \snoozed
            media = currentMedia.get \media
            if media
                if database.settings.streamDisabled
                    changeStream streamOff
                    return

                @ignoreComplete = true; sleep 1_000ms, !~> @resetIgnoreComplete!

                oldPlayer = player
                if media.get(\format) == 1 # youtube

                    /*== AudioOnly Stream (YT) ==*/
                    if streamSettings._settings.audioOnly and not media.audioFailed
                        player := audio

                    #== Unblocked YT ==
                    else if media.blocked == 3
                        player := syncingPlayer # cannot be unblocked
                    else if media.blocked
                        player := unblocker # use unblocker

                    #== regular YT ==
                    else
                        player := youtube


                #== SoundCloud ==
                else if media.get(\format) == 2
                    disableBtn \video
                    player := sc

            else
                player := noDJ

            #= update player =
            changeStream player

            player.enable(media)

        replace Playback::, \stop, !-> return !->
            player.disable!
        replace Playback::, \reset, (r_) !-> return !->
            if database.settings.streamDisabled
                changeStream streamOff
            player.disable!
            r_ ...


        #== unlock Youtube if blocekd ==
        replace Playback::, \onYTPlayerError, !-> return (e) !->
            console.log "[streamSettings] Youtube Playback Error", e
            if not database.settings.streamDisabled and not streamSettings._settings.audioOnly
                streamSettings.unblockYT!

        #== force all buttons to be always shown ==
        replace Playback::, \onPlaybackEnter, !-> return !->
            if currentMedia.get(\media)
                @$controls .show!
        replace Playback::, \onSnoozeClick, !-> return !->
            if not isSnoozed!
                changeStream snoozed
                @reset!
        #window.snooze = !-> changeStream snoozed
        /*replace Playback::, \onRefreshClick, !-> return !->
            if currentMedia.get(\media) and restr = currentMedia.get \restricted
                currentMedia.set do
                    media: restr
                    restricted: void
            else
                @onMediaChange!*/


        if app?
            @playback = playback = app.room.playback
            onGotPlayback(playback)
        else
            replace Playback::, \onRemainingChange, (oMC) !~> return !~>
                # patch playback
                @playback = playback := this
                oMC ...
                onGotPlayback(playback)

        if @_settings.audioOnly
            refresh!


        function onGotPlayback playback
            revert Playback::, \onRemainingChange

            # update events with bound listeners
            window.snooze = playback~onSnoozeClick
            replaceListener _$context, \change:streamDisabled, Playback, !-> return playback~onMediaChange
            replaceListener currentMedia, \change:media, Playback, !-> return playback~onMediaChange
            replaceListener currentMedia, \change:volume, Playback, !-> return playback~onVolumeChange

            $playback
                .off \mouseenter .on \mouseenter, !-> playback.onPlaybackEnter!
            $playback .find \.snooze
                .off \click      .on \click,      !-> playback.onSnoozeClick!
            /*$playback .find \.refresh
                .off \click      .on \click,      !->
                    database.settings.streamDisabled = false # turn stream on
                    playback.onRefreshClick!*/

        function changeStream mode, name
            if typeof mode == \object
                {mode, name} = mode
            console.log "[streamSettings] => stream-#mode"
            $label .text (name || player.name)
            $playback
                .removeClass!
                .addClass "p0ne-stream-#mode"

            _$context?.trigger \p0ne:changeMode
            API.trigger \p0ne:changeMode, mode, name

        @unblockYT = !->
            console.error "Cannot unblock blocked Youtube video"
            return
            #currentMedia.get \media ? .blocked = true
            #refresh!


    disable: !->
        window.removeEventListener \message, @onRestricted
        $playback = $ \#playback
            .removeClass!
        $ '#playback .hd'
            .removeClass \p0ne-stream-select
            .empty!
            .append @$btn_

        sleep 0, !~>
            # after module is properly reset
            refresh! if @_settings.audioOnly and not isSnoozed!
            if @Playback
                $playback
                    .off \mouseenter
                    .on \mouseenter, @playback~onPlaybackEnter