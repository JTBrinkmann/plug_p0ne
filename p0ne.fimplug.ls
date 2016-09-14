/**
 * fimplug related modules
 * @author jtbrinkmann aka. Brinkie Pie
 * @version 1.0
 * @license MIT License
 * @copyright (c) 2014 J.-T. Brinkmann
 */

/*not really implemented yet*/
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

module \fimstats, do
    setup: ({addListener, $create}) ->
        $el = $create '<span class=p0ne-last-played>' .appendTo \#now-playing-bar
        addListener API, \advance, @updateStats = (d) ->
            d ||= media: API.getMedia!
            if d.media
                $.getJSON "https://fimstats.anjanms.com/_/media/#{d.media.format}/#{d.media.cid}"
                    .then (d) ->
                        first = "#{d.data.0.firstPlay.user} #{ago d.data.0.firstPlay.time*1000}"
                        last = "#{d.data.0.lastPlay.user} #{ago d.data.0.lastPlay.time*1000}"
                        if first != last
                            $el.text "last played by #last \xa0 - \xa0 first played by #first"
                        else
                            $el.text "first&last played by #first"
                    .fail (,,status) ->
                        if status == "Not Found"
                            $el.text "first played just now!"
                        else
                            $el.text ""

            else
                $el.text ""
        @updateStats!