/**
 * Modules for Audio-Only stream and stream settings for plug_p0ne
 * @author jtbrinkmann aka. Brinkie Pie
 * @license MIT License
 * @copyright (c) 2015 J.-T. Brinkmann
*/

module \streamSettings, do
    require: <[ app currentMedia _$context ]>
    optional: <[ database ]>
    audioOnly: false
    setup: ({addListener, replace, replaceListener, $create, css}, streamSettings,,m_) ->
        $playback = $ \#playback
        $el = $create '<div class=p0ne-stream-select>'

        # keep audio-only on update
        if m_
            @audioOnly = m_.audioOnly

        # replace HD button
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
        replace Playback::, \onHDClick, -> return $.noop
        $btn = $ '#playback .hd'
            .addClass \p0ne-stream-select
            .html '
                <div class="box">
                    <span id=p0ne-stream-label>Stream: Video</span>
                    <div class="p0ne-stream-buttons">
                        <i class="icon icon-stream-video"></i> <i class="icon icon-stream-audio"></i> <i class="icon icon-stream-off"></i> <div class="p0ne-stream-fancy"></div>
                    </div>
                </div>
            '
        @$label = $btn.find \#p0ne-stream-label

        addListener $btn.find(\.icon-stream-video), \click, ~> @changeStream \video
        addListener $btn.find(\.icon-stream-audio), \click, ~> @changeStream \audio
        addListener $btn.find(\.icon-stream-off),   \click, ~> @changeStream \off

        @changeStream!

        @audio = audio = new Audio!
        export audio # TEST
        audio.volume = currentMedia.get(\volume) / 100perc
        HDsettings = database?.settings || {hd720: true}
        audio.addEventListener \canplay, ->
            console.log "[audioStream] finished buffering"
            if currentMedia.get(\media) == audio.media
                if audio.init
                    audio.init = false
                    seek!
                else
                    audio.play!
                    console.log "[audioStream] audio.play()"
            else
                console.warn "[audioStream] next song already started"

        replace Playback::, \onVolumeChange, (oVC_) -> return ->
            audio.volume = currentMedia.get(\volume) / 100perc
            oVC_ ...

        replace Playback::, \onMediaChange, -> return ->
            @reset!
            @$controls.removeClass \snoozed
            media = currentMedia.get \media
            audio.src = null
            audio.media = {}
            if media
                @$noDJ.hide!
                return if currentMedia.get \streamDisabled

                @ignoreComplete = true
                console.log "[audioStream] B"
                sleep 1_000ms, ~> @resetIgnoreComplete!
                if media.get(\format) == 1 # youtube
                    console.log "[audioStream] C"
                    if streamSettings.audioOnly and not audio.failed
                        /*== audio only streaming ==*/
                        console.log "[audioStream] looking for URL"
                        if media.id == audio.media.id
                            seek!
                        else
                            audio.init = true
                            mediaDownload media, true
                                .then (d) ->
                                    console.log "[audioStream] found url", d
                                    media.src = d.preferredDownload.url

                                    audio.media = media
                                    audio.src = media.src
                                    seek!
                                    audio.load!
                                .fail (err) ->
                                    console.error "[audioStream] couldn't get audio stream", err
                                    audio.failed := true
                                    refresh!
                                    API.once \advance, ->
                                        audio.failed = false
                    else
                        console.log "[audioStream] loading video stream"
                        startTime = currentMedia.get \elapsed
                        @buffering = false
                        @yto =
                            id: media.get \cid
                            volume: currentMedia.get \volume
                            seek: if startTime < 4s then 0s else startTime
                            quality: if HDsettings.hdVideo then \hd720 else ""

                        a = \yt5
                        if window.location.host != \plug.dj
                            a += if window.location.host == \localhost then \local else \staging
                        @$container.append do
                            $ "<iframe id=yt-frame frameborder=0 src='#{window.location.protocol}//plgyte.appspot.com/#a.html'>"
                                .load @ytFrameLoadedBind
                else if media.get(\format) == 2 # soundcloud
                    console.log "[audioStream] loading Soundcloud"
                    if soundcloud.r
                        if soundcloud.sc
                            @$container.empty!.append do
                                $ "<iframe id=yt-frame frameborder=0 src='#{@visualizers[@random.integer(0, 1)]}'></iframe>"
                            soundcloud.sc.whenStreamingReady ~>
                                if currentMedia.get \media == media # SC DOUBLE PLAY FIX
                                    startTime = currentMedia.get \elapsed
                                    @player = soundcloud.sc.stream media.get(\cid), do
                                        autoPlay: true
                                        volume: currentMedia.get \volume
                                        position: if startTime < 4s then 0s else startTime * 1_000ms
                                        onload: @scOnLoadBind
                                        whileloading: @scLoadingBind
                                        onfinish: @playbackCompleteBind
                                        ontimeout: @scTimeoutBind
                        else
                            @$container.append do
                                $ '<img src="https://soundcloud-support.s3.amazonaws.com/images/downtime.png" height="271"/>'
                                    .css do
                                        position: \absolute
                                        left: 46px
                else
                    console.log "[audioStream] wut", media.get(\format), typeof media.get(\format)
                    _$context.on \sc:ready, @onSCReady, this
            else
                @$noDJ.show!
                @$controls.hide!

        replace Playback::, \stop, (s_) -> return ->
            audio.pause!
            s_ ...

        replaceListener currentMedia, \change:media, Playback, -> return app.room.playback~onMediaChange
        replaceListener currentMedia, \change:streamDisabled, Playback, -> return app.room.playback~onMediaChange
        replaceListener currentMedia, \change:volume, Playback, -> return app.room.playback~onVolumeChange

        if streamSettings.audioOnly
            refresh!

        function seek
            startTime = currentMedia.get \elapsed
            audio.currentTime = if startTime < 4s then 0s else startTime
    changeStream: (mode) ->
        prevMode =
            if currentMedia.get \streamDisabled
                \off
            else if streamSettings.audioOnly
                \audio
            else
                \video
        if mode != prevMode
            mode ||= prevMode
            console.log "[streamSettings] stream-#mode"
            @$label .text "Stream: #mode"
            streamSettings.audioOnly = (mode == \audio)
            stream(mode != \off)
            $body
                .removeClass "p0ne-stream-#prevMode"
                .addClass "p0ne-stream-#mode"
            refresh!

    disable: ->
        @audio.src = null
        sleep 0, ->
            if streamSettings.audioOnly
                refresh!
        $body
            .removeClass \p0ne-stream-video
            .removeClass \p0ne-stream-audio
            .removeClass \p0ne-stream-off