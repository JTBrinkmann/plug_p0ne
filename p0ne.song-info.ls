/**
 * plug_p0ne songInfo
 * adds a dropdown with the currently playing song's description when clicking on the now-playing-bar (in the top-center of the page)
 * @author jtbrinkmann aka. Brinkie Pie
 * @version 1.0
 * @license MIT License
 * @copyright (c) 2014 J.-T. Brinkmann
 */
module \songInfo, do
    optional: <[ _$context ]>
    setup: ({addListener}) ->
        @$el = $ \<div> .addClass \p0ne-song-info .appendTo \body
        @loadBind = @~load
        addListener $ \#now-playing-bar, \click, (e) ~>
            $target = $ e.target
            return if  $target .closest \#history-button .length or $target .closest \#volume .length
            if @visible # visible
                media = API.getMedia!
                if @lastMedia == media.id
                    API.once \advance, @loadBind
                else
                    @$el .html "loading…"
                    @load media: media
                @$el .addClass \expanded
            else # hidden
                @$el .removeClass \expanded
                API.off \advance, @loadBind
            @visible = not @visible
        css \songInfo, '
            #now-playing-bar {
                cursor: pointer;
            }
        '

        return if not _$context
        addListener _$context, <[ show:user show:history show:dashboard dashboard:disable ]>, ~> if @visible
            @$el .removeClass \expanded
            API.off \advance, @loadBind
    load: ({media}, isRetry) ->
        console.log "[song-info]", media
        @lastMedia = media
        if media.format != 1
            console.error "[song-notif] unsupported media source #{media.format}"
            @$el .html "Cannot load song info, sorry :(<br/>Reason: unsupported media source"
            return
        mediaLookup media
            fail: ~>
                if isRetry
                    @$el .html "error loading, retrying…"
                    load {media}, true
                else
                    @$el .html "Couldn't load song info, sorry =("
            success: ({entry: d}) ~>
                console.log "[song-info] got data", @lastMedia != media
                return if @lastMedia != media or @disabled # skip if another song is already playing
                d <<<< d.media$group

                @$el .html ""
                $meta = $ \<div>  .addClass \p0ne-song-info-meta        .appendTo @$el
                $parts = {}

                $ \<span> .addClass \p0ne-song-info-author      .appendTo $meta
                    .click -> mediaSearch media.author
                    .attr \title, "search for '#{media.author}'"
                    .text media.author
                $ \<span> .addClass \p0ne-song-info-title       .appendTo $meta
                    .click -> mediaSearch media.title
                    .attr \title, "search for '#{media.title}'"
                    .text media.title
                $ \<br>                                         .appendTo $meta
                $ \<a> .addClass \p0ne-song-info-uploader       .appendTo $meta
                    .attr \href, "https://www.youtube.com/channel/#{d.yt$uploaderId.$t}"
                    .attr \target, \_blank
                    .attr \title, "open channel of '#{d.author.0.name.$t}'"
                    .text d.author.0.name.$t
                $ \<a> .addClass \p0ne-song-info-ytTitle        .appendTo $meta
                    .attr \href, "http://youtube.com/watch?v=#{media.cid}"
                    .attr \target, \_blank
                    .attr \title, "open video on Youtube"
                    .text d.title.$t
                $ \<br>                                         .appendTo $meta
                $ \<span> .addClass \p0ne-song-info-date        .appendTo $meta
                    .text getISOTime new Date(d.yt$uploaded.$t)
                $ \<span> .addClass \p0ne-song-info-duration    .appendTo $meta
                    .text mediaTime +d.yt$duration.seconds
                #$ \<div> .addClass \p0ne-song-info-songStats   #ToDo
                #$ \<div> .addClass \p0ne-song-info-tags    #ToDo
                $ \<div> .addClass \p0ne-song-info-description  .appendTo @$el
                    .html formatPlainText(d.media$description.$t)
                #$ \<ul> .addClass \p0ne-song-info-remixes      #ToDo
        API.once \advance, @loadBind
    disable: ->
        @$el .remove!