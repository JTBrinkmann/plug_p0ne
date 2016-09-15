/**
 * fimplug related modules
 *
 * @author jtbrinkmann aka. Brinkie Pie
 * @license MIT License
 * @copyright (c) 2015 J.-T. Brinkmann
 */

/*not really implemented yet*/
/*
module \songNotifRuleskip, do
    require: <[ songNotif ]>
    setup: ({replace, addListener}) ->
        replace songNotif, \skip, -> return ($notif) ->
            songNotif.showDescription $notif, """
                <span class="ruleskip-btn ruleskip-1" data-rule=1>!ruleskip 1 MLP-related only</span>
                <span class="ruleskip-btn" data-rule=2>!ruleskip 2 Loops / Pictures</span>
                <span class="ruleskip-btn" data-rule=3>!ruleskip 3 low-efford mixes</span>
                <span class="ruleskip-btn" data-rule=4>!ruleskip 4 history</span>
                <span class="ruleskip-btn" data-rule=6>!ruleskip 6 &gt;10min</span>
                <span class="ruleskip-btn" data-rule=13>!ruleskip 13 clop/porn/gote</span>
                <span class="ruleskip-btn" data-rule=14>!ruleskip 14 episode / not music</span>
                <span class="ruleskip-btn" data-rule=23>!ruleskip 23 WD-only</span>
            """
        addListener chatDomEvents, \click, \.ruleskip-btn, (btn) ->
            songNotif.hideDescription!
            if num = $ btn .data \rule
                API.sendChat "!ruleskip #num"
*/

/*####################################
#              FIMSTATS              #
####################################*/
module \fimstats, do
    settings: \pony
    optional: <[ _$context ]>
    disabled: true
    setup: ({addListener, $create}, lookup) ->
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
                bottom: 16px;
                width: 100%;
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
        '
        $el = $create '<span class=p0ne-fimstats>' .appendTo \#room
        addListener API, \advance, @updateStats = (d) ->
            d ||= media: API.getMedia!
            if d.media
                lookup d.media
                    .then (d) ->
                        $el
                            .html d.html
                    .fail (err) ->
                        $el
                            .html err.html

            else
                $el.html ""
        if _$context?
            addListener _$context, \ShowDialogEvent:show, (d) -> #\PreviewEvent:preview, (d) ->
                _.defer -> if d.dialog.options?.media
                    console.log "[fimstats]", d.dialog.options.media
                    lookup d.dialog.options.media.toJSON!
                        .then (d) ->
                            $ \#dialog-preview .after do
                                $ '<div class=p0ne-fimstats>' .html d.html
        if app?.dialog?.dialog?.options?.media
            console.log "[fimstats]", that
            lookup that.toJSON!
                .then (d) ->
                    $ \#dialog-preview .after do
                        $ '<div class=p0ne-fimstats>' .html d.html

        # prevent the p0ne settings from overlaying the ETA
        do addListener API, \p0ne:stylesLoaded, ->
            $ \#p0ne-menu .css bottom: 54px + 21px
        addListener API, \p0ne:moduleEnabled, (m) -> if m.name == \p0neSettings
            $ \#p0ne-menu .css bottom: 54px + 21px

        # show stats for current song
        @updateStats!

    module: (media) ->
        $ \#p0ne-menu .css bottom: 54px
        def = $.Deferred!
        $.getJSON "https://fimstats.anjanms.com/_/media/#{media.format}/#{media.cid}?key=#{p0ne.FIMSTATS_KEY}"
            .then (d) ->
                # note: `d.plays` (playcount) doesn't contain current play
                d = d.data.0

                if d.firstPlay.time != d.lastPlay.time
                    d.text = "last played by #{d.lastPlay.user} \xa0 - (#{d.plays}x) - \xa0 first played by #{d.firstPlay.user}"
                    d.html = "
                        <span class='p0ne-fimstats-field p0ne-fimstats-last p0ne-name' data-uid=#{d.lastPlay.id}>#{d.lastPlay.user}
                            <span class=p0ne-fimstats-last-time>#{ago d.lastPlay.time*1000s_to_ms}</span>
                        </span>
                        <span class='p0ne-fimstats-field p0ne-fimstats-plays'>#{d.plays}</span>
                        <span class='p0ne-fimstats-field p0ne-fimstats-first p0ne-name' data-uid=#{d.firstPlay.id}>#{d.firstPlay.user}
                            <span class=p0ne-fimstats-first-time>#{ago d.firstPlay.time*1000s_to_ms}</span>
                        </span>
                    "
                else
                    d.text = "once played by #{d.firstPlay.user}"
                    d.html = "
                        <span class='p0ne-fimstats-field p0ne-fimstats-once'>#{d.firstPlay.user}
                            <span class=p0ne-fimstats-once-time>#{ago d.firstPlay.time*1000s_to_ms}</span>
                        </span>"
                def.resolve d
            .fail (d,,status) ->
                if status == "Not Found"
                    d.text = "first played just now!"
                    d.html = "<span class='p0ne-fimstats-field p0ne-fimstats-first-notyet'></span>"
                    def.resolve d
                #else if status == \Unauthorized
                else
                    d.text = d.html = "error loading fimstats"
                    def.reject d
        return def.promise!