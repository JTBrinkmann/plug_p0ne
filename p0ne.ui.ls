/**
 * plug_p0ne modules to add some eye-candy to plug.dj
 * besides esthetics, these modules don't provide functionality
 *
 * @author jtbrinkmann aka. Brinkie Pie
 * @license MIT License
 * @copyright (c) 2015 J.-T. Brinkmann
 */

$body ||= $ document.body
css \ripple, "
    .p0ne-ripple {
        position: block;
        border-radius: 50%;
        background: rgba(255,255,255, .5)
    }"
$.fn.paperBtn = ->
    this
        .css overflow: \hide
        .each ->
            $this = $ this
            return if $this .data \ripple
            $ripple = $ '<div class=p0ne-ripple>'
            $this
                .prepend $ripple
                .data \ripple, $ripple.0

        .on \mousedown, (e) ->
            $this = $ this
            w = $ this .width!
            h = $ this .height!
            d = w+h/2 >? h+w/2

            $ripple = $($this .data \ripple)
                .stop!
                .css do
                    left:    w/2
                    top:     h/2
                    width:   20px
                    height:  20px
                    opacity: 1
                .animate do
                    left:   if h > w then w/2 - d/2 else -h/4
                    top:    if w > h then h/2 - d/2 else -w/4
                    width:  d
                    height: d
                    \slow
                    \easeOutQuad
            $body .one \mouseup, ->
                $ripple .fadeOut!

btn = $ \#playback-controls
    .show!
    .find \.refresh
    .paperBtn!
