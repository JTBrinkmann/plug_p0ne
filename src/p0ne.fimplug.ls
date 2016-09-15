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
            .p0ne-last-played {
                position: absolute;
                right: 140px;
                top: 30px;
                font-size: .9em;
                color: #ddd;
                transition: opacity .2s ease-out;
            }
            #volume:hover ~ .p0ne-last-played {
              opacity: 0;
            }
            #dialog-preview .p0ne-last-played {
              right: 0;
              top: 23px;
              left: 0;
            }

            /*@media (min-width: 0px) {*/
                .p0ne-fimstats-last { display: none; }
                .p0ne-fimstats-first { display: none; }

                .p0ne-fimstats-plays::before { content: " ("; }
                .p0ne-fimstats-plays::after { content: "x) "; }
                .p0ne-fimstats-first-notyet::before { content: "first play!"; }
                .p0ne-fimstats-once::before { content: "once "; }
            /*}*/
            @media (min-width: 1600px) {
                .p0ne-fimstats-last { display: inline; }
                .p0ne-fimstats-first { display: inline; }

                .p0ne-fimstats-plays::before { content: " …("; }
                .p0ne-fimstats-plays::after { content: "x)… "; }

                .p0ne-fimstats-first-notyet::before { content: "first played just now!"; }
                .p0ne-fimstats-once::before { content: "once played by "; }
            }
            @media (min-width: 1700px) {
                .p0ne-fimstats-last::before { content: "last: "; }
                .p0ne-fimstats-plays::before { content: " - (played "; }
                .p0ne-fimstats-plays::after { content: "x)"; }
                .p0ne-fimstats-first::before { content: " - first: "; }
            }
            @media (min-width: 1800px) {
                .p0ne-fimstats-last::before { content: "last played by "; }
                .p0ne-fimstats-plays::before { content: " \xa0 - (played "; }
                .p0ne-fimstats-plays::after { content: "x)"; }
                .p0ne-fimstats-first::before { content: " - \xa0 first played by "; }
            }
        '
        $el = $create '<span class=p0ne-last-played>' .appendTo \#now-playing-bar
        addListener API, \advance, @updateStats = (d) ->
            d ||= media: API.getMedia!
            if d.media
                lookup d.media
                    .then (d) ->
                        $el
                            .html d.html
                            .prop \title, d.text
                    .fail (err) ->
                        $el
                            .html err.html
                            .prop \title, err.text

            else
                $el.html ""
        if _$context?
            addListener _$context, \ShowDialogEvent:show, (d) -> #\PreviewEvent:preview, (d) ->
                if d.dialog.options?.media
                    console.log "[fimstats]", d.media
                    lookup d.dialog.options.media.toJSON!
                        .then (d) ->
                            console.log "[fimstats] ->", d.media, d, $('#dialog-preview .message')
                            $ '#dialog-preview .message' .after do
                                $ '<div class=p0ne-last-played>' .html d.html
        @updateStats!
    module: (media) ->
        return $.getJSON "https://fimstats.anjanms.com/_/media/#{media.format}/#{media.cid}?key=#{p0ne.FIMSTATS_KEY}"
            .then (d) ->
                d.firstPlay = d.data.0.firstPlay; d.lastPlay = d.data.0.lastPlay; d.plays = d.data.0.plays
                first = "#{d.firstPlay.user} #{ago d.firstPlay.time*1000}"
                last = "#{d.lastPlay.user} #{ago d.lastPlay.time*1000}"
                if first != last
                    #                       note: playcount doesn't contain current play
                    d.text = "last played by #last \xa0 - (#{d.plays}x) - \xa0 first played by #first"
                    d.html = "<span class=p0ne-fimstats-last>#last</span><span class=p0ne-fimstats-plays>#{d.plays}</span><span class=p0ne-fimstats-first>#first</span>"
                else
                    d.text = "once played by #first"
                    d.html = "<span class=p0ne-fimstats-once>#first</span>"
                return d
            .fail (d,,status) ->
                if status == "Not Found"
                    d.text = "first played just now!"
                    d.html = "<span class=p0ne-fimstats-first-notyet></span>"
                else
                    d.text = d.html = ""
                return d