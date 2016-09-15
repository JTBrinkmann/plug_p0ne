/**
 * fimplug related modules
 *
 * @author jtbrinkmann aka. Brinkie Pie
 * @license MIT License
 * @copyright (c) 2015 J.-T. Brinkmann
 */

/*####################################
#              RULESKIP              #
####################################*/
module \forceSkipButtonRuleskip, do
    displayName: "Ruleskip Button"
    settings: \pony
    help: """
        Makes the Skip button show a ruleskip list instead.
        (you can still instaskip)
    """
    screenshot: 'https://i.imgur.com/jGwYsn3.png'
    moderator: true
    setup: ({addListener, replace, $create, css}) !->
        #TODO add this http://pastebin.com/hgmHKzYC
        css \forceSkipButtonRuleskip, '
            .p0ne-skip-ruleskip {
                position: absolute;
                right: 0;
                bottom: 54px;
                width: 250px;
                list-style: none;
                line-height: 2em;
                display: none;
            }
            .p0ne-skip-ruleskip li {
                padding: 5px;
                background: #222;
            }
            .p0ne-skip-ruleskip li:hover {
                background: #444;
            }
        '
        var $rulelist
        visible = false
        fn = addListener API, \p0ne:moduleEnabled, (m) !-> if m.name == \forceSkipButton
            $rulelist := $create '
                <ul class=p0ne-skip-ruleskip>
                    <li data-rule=insta><b>insta skip</b></li>
                    <li data-rule=30><b>!ruleskip 30</b> (WD-only &gt; brony artist)</li>
                    <li data-rule=23><b>!ruleskip 23</b> (WD-only &gt; weird)</li>
                    <li data-rule=20><b>!ruleskip 20</b> (alts)</li>
                    <li data-rule=13><b>!ruleskip 13</b> (NSFW)</li>
                    <li  data-rule=6><b>!ruleskip  6</b> (too long)</li>
                    <li  data-rule=4><b>!ruleskip  4</b> (history)</li>
                    <li  data-rule=3><b>!ruleskip  3</b> (low effort mix)</li>
                    <li  data-rule=2><b>!ruleskip  2</b> (loop / slideshow)</li>
                    <li  data-rule=1><b>!ruleskip  1</b> (nonpony)</li>
                </ul>
            ' .appendTo m.$btn

            replace m, \onClick, !-> return (e) !->
                if visible
                    if num = $ e.target .closest \li .data \rule
                        if num == \insta
                            API.moderateForceSkip!
                        else
                            API.sendChat "!ruleskip #num"
                    m.$btn .find \.icon:first .addClass \icon-skip .removeClass \icon-arrow-down
                    $rulelist .fadeOut!
                    visible := false
                else if $ e.target .is '.p0ne-skip-btn, .p0ne-skip-btn>.icon'
                    m.$btn .find \.icon:first .removeClass \icon-skip .addClass \icon-arrow-down
                    $rulelist .fadeIn!
                    visible := true

            console.log "[forceSkipButton] 'fimplug !ruleskip list' patch applied"

        addListener \early, (window._$context || API), \advance, !-> if visible
            # trying to attach the lister as early as possible to prevent accidental double-skips
            visible := false
            $rulelist .fadeOut!
            $ \.p0ne-skip-btn>.icon:first .addClass \icon-skip .removeClass \icon-arrow-down

        if forceSkipButton?
            fn(forceSkipButton)


/*####################################
#              FIMSTATS              #
####################################*/
module \fimstats, do
    settings: \pony
    optional: <[ _$context app playlists ]>
    disabled: true
    _settings:
        highlightUnplayed: false
    CACHE_DURATION: 1.h
    setup: ({addListener, $create, replace}, fimstats) !->
        css \fimstats, '
            .p0ne-fimstats {
                position: absolute;
                left: 0;
                right: 345px;
                bottom: 54px;
                height: 1em;
                padding: 5px 0;
                font-size: .9em;
                color: #12A9E0;
                background: rgba(0,0,0, 0.4);
                text-align: center;
                z-index: 6;
                transition: opacity .2s ease-out;
            }
            .video-only .p0ne-fimstats {
                bottom: 116px;
                padding-top: 0px;
                background: rgba(0,0,0, 0.8);
            }

            .p0ne-fimstats-field {
                display: block;
                position: absolute;
                width: 100%;
                padding: 0 5px;
                box-sizing: border-box;
            }
            .p0ne-fimstats-last { text-align: left; }
            .p0ne-fimstats-plays, .p0ne-fimstats-once, .p0ne-fimstats-first-notyet { text-align: center; }
            .p0ne-fimstats-first { text-align: right; }

            .p0ne-fimstats-field::before, .p0ne-fimstats-field::after,
            .p0ne-fimstats-first-time, .p0ne-fimstats-last-time, .p0ne-fimstats-once-time {
                color: #ddd;
            }
            #dialog-container .p0ne-fimstats {
                position: fixed;
                bottom: 0;
                left: 0;
                right: 345px;
                background: rgba(0,0,0, 0.8);
            }
            #dialog-container .p0ne-fimstats-first-notyet::before { content: "not played yet!"; color: #12A9E0 }

            .p0ne-fimstats-first-notyet::before { content: "first played just now!"; color: #12A9E0 }
            .p0ne-fimstats-once::before { content: "once played by: "; }
            .p0ne-fimstats-last::before { content: "last played by: "; }
            .p0ne-fimstats-last-time::before,
            .p0ne-fimstats-first-time::before,
            .p0ne-fimstats-once-time::before { content: "("; }
            .p0ne-fimstats-last-time::after,
            .p0ne-fimstats-first-time::after,
            .p0ne-fimstats-once-time::after { content: ")"; }
            .p0ne-fimstats-plays::before { content: "played: "; }
            .p0ne-fimstats-plays::after { content: " times"; }
            .p0ne-fimstats-first::before { content: "first played by: "; }

            .p0ne-fimstats-first-time,
            .p0ne-fimstats-last-time,
            .p0ne-fimstats-once-time {
                font-size: 0.8em;
                display: inline;
                position: static;
                margin-left: 5px;
            }

            .p0ne-fimstats-unplayed {
                color: lime;
            }
        '
        $el = $create '<span class=p0ne-fimstats>' .appendTo \#room
        addListener API, \advance, @updateStats = (d) !~>
            if d?.lastPlay?.media
                delete @cache[id = "#{d.lastPlay.media.format}:#{d.lastPlay.media.cid}"]
            if d.media
                fimstats d.media
                    .then (res) !->
                        $el .html res.html
                    .fail (err) !->
                        $el .html err.html

            else
                $el.html ""
        if _$context?
            addListener _$context, \ShowDialogEvent:show, (d) !-> #\PreviewEvent:preview, (d) !->
                _.defer !-> if d.dialog.options?.media
                    console.log "[fimstats]", d.dialog.options.media
                    fimstats d.dialog.options.media
                        .then (d) !->
                            $ \#dialog-preview .after do
                                $create '<div class=p0ne-fimstats>' .html d.html
        if app?.dialog?.dialog?.options?.media
            console.log "[fimstats]", that
            fimstats that.toJSON!
                .then (d) !->
                    $ \#dialog-preview .after do
                        $create '<div class=p0ne-fimstats>' .html d.html

        # prevent the p0ne settings from overlaying the ETA
        console.info "[fimstats] prevent p0neSettings overlay", $(\#p0ne-menu).css bottom: 54px + 21px
        addListener API, 'p0ne:moduleEnabled p0ne:moduleUpdated', (m) !-> if m.name == \p0neSettings
            $ \#p0ne-menu .css bottom: 54px + 21px

        # show stats for next song in playlist
        if app? and playlists?
            $yourNextMedia = $ \#your-next-media

            @checkUnplayed = !->
                $yourNextMedia .removeClass \p0ne-fimstats-unplayed
                if fimstats._settings.highlightUnplayed and playlists.activeMedia.length > 0
                    console.log "[fimstats] checking next song", playlists.activeMedia.0
                    fimstats playlists.activeMedia.0 .then (d) !->
                        if d.unplayed
                            $yourNextMedia .addClass \p0ne-fimstats-unplayed

            replace app.footer.playlist, \updateMeta, (uM_) !-> return !->
                if playlists.activeMedia.length > 0
                    fimstats.checkUnplayed!
                    uM_ ...
                else
                    clearTimeout @updateMetaBind
            replace app.footer.playlist, \updateMetaBind, !-> return app.footer.playlist~updateMeta

            # apply immediately
            @checkUnplayed!
        else
            console.warn "[fimstats] failed to load requirements for checking next song. next song check disabled."

        # show stats for current song
        @updateStats do
            media: API.getMedia!

    checkUnplayed: !-> # Dummy function in case we cannot get `playlists` (which is required)

    cache: {}
    module: (media=API.getMedia!) !->
        $ \#p0ne-menu .css bottom: 54px
        if media.attributes and media.toJSON
            media .= toJSON!

        # check if data is already cached
        if @cache[id = "#{media.format}:#{media.cid}"]
            clearTimeout @cache[id].timeoutID
            @cache[id].timeoutID = sleep @CACHE_DURATION, ~>
                delete @cache[id]
            return @cache[id]
        else
            # if not yet cached, create a Deferred
            def = $.Deferred!
            @cache[id] = def.promise!
            @cache[id].timeoutID = sleep @CACHE_DURATION, ~>
                delete @cache[id]

        # load data from fimstats
        $.getJSON "https://fimstats.anjanms.com/_/media/#{media.format}/#{media.cid}" #?key=#{p0ne.FIMSTATS_KEY}
            .then (d) !->
                d = d.data.0
                # note: `d.plays` (playcount) doesn't contain current play
                # we need to sanitize everything to avoid HTML injection (some songtitles are actually not HTMl escaped)
                for k,v of d
                    if typeof v == \string
                        d[k] = sanitize v
                    else
                        for k2,v2 of v when typeof v2 == \string
                            v[k2] = sanitize v2

                if d.firstPlay.time != d.lastPlay.time
                    d.text = "last played by #{d.lastPlay.user.username} \xa0 - (#{d.plays}x) - \xa0 first played by #{d.firstPlay.user.username}"
                    d.html = "
                        <span class='p0ne-fimstats-field p0ne-fimstats-last p0ne-name' data-uid=#{d.lastPlay.id}>#{d.lastPlay.user.username}
                            <span class=p0ne-fimstats-last-time>#{ago d.lastPlay.time*1000s_to_ms}</span>
                        </span>
                        <span class='p0ne-fimstats-field p0ne-fimstats-plays'>#{d.plays}</span>
                        <span class='p0ne-fimstats-field p0ne-fimstats-first p0ne-name' data-uid=#{d.firstPlay.id}>#{d.firstPlay.user.username}
                            <span class=p0ne-fimstats-first-time>#{ago d.firstPlay.time*1000s_to_ms}</span>
                        </span>
                    "
                else
                    d.text = "once played by #{d.firstPlay.user.username}"
                    d.html = "
                        <span class='p0ne-fimstats-field p0ne-fimstats-once'>#{d.firstPlay.user.username}
                            <span class=p0ne-fimstats-once-time>#{ago d.firstPlay.time*1000s_to_ms}</span>
                        </span>"
                def.resolve d
            .fail (d,,status) !->
                if status == "Not Found"
                    d.text = "first played just now!"
                    d.html = "<span class='p0ne-fimstats-field p0ne-fimstats-first-notyet'></span>"
                    d.unplayed = true
                    def.resolve d
                else
                    d.text = d.html = "error loading fimstats"
                    def.reject d
        return @cache[id]

        function sanitize str
            return str .replace(/</g, '&lt;') .replace(/>/g, '&gt;')

    settingsExtra: ($el) !->
        fimstats = this
        noReqMissing = app? or not playlists?
        $ "
            <form>
                <label>
                    <input type=checkbox class=p0ne-fimstats-unplayed-setting #{if @_settings.highlightUnplayed and noReqMissing then \checked else ''} #{if noReqMissing then '' else \disabled}> highlight next song if unplayed
                </label>
            </form>"
            .appendTo do
                $el .css paddingLeft: 15px
        if noReqMissing
            $el .on \click, \.p0ne-fimstats-unplayed-setting, !->
                console.log "#{getTime!} [fimstats] updated highlightUnplayed to #{@checked}"
                fimstats._settings.highlightUnplayed = @checked
                if @checked
                    fimstats.checkUnplayed!
                else
                    $ \#your-next-media .removeClass \p0ne-fimstats-unplayed

    disable: !->
        $ \#your-next-media .removeClass \p0ne-fimstats-unplayed

