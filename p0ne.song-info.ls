/**
 * plug_p0ne songInfo
 * adds a dropdown with the currently playing song's description when clicking on the now-playing-bar (in the top-center of the page)
 * @author jtbrinkmann aka. Brinkie Pie
 * @version 1.0
 * @license MIT License
 * @copyright (c) 2014 J.-T. Brinkmann
 */
# maybe add "other videos by artist", which loads a list of other uploads by the uploader?
# http://gdata.youtube.com/feeds/api/users/#{channel}/uploads?alt=json&max-results=10
module \songInfo, do
    optional: <[ _$context ]>
    settings: \base
    displayName: 'Song-Info Dropdown'
    help: '''
        A panel with the song's description and links to the artist and song.
        Click on the now-playing-bar (in the top-center of the page) to open it.
    '''
    setup: ({addListener, $create, css}) ->
        @$create = $create
        @$el = $create \<div> .addClass \p0ne-song-info .appendTo \body
        @loadBind = @~load
        addListener $(\#now-playing-bar), \click, (e) ~>
            $target = $ e.target
            return if  $target .closest \#history-button .length or $target .closest \#volume .length
            if not @visible # show
                media = API.getMedia!
                if not media
                    @$el .html "Cannot load information if No song playing!"
                else if @lastMediaID == media.id
                    API.once \advance, @loadBind
                else
                    @$el .html "loading…"
                    @load media: media
                @$el .addClass \expanded
            else # hide
                @$el .removeClass \expanded
                API.off \advance, @loadBind
            @visible = not @visible
        css \songInfo, '
            #now-playing-bar {
                cursor: pointer;
            }
        '

        return if not _$context
        addListener _$context,  'show:user show:history show:dashboard dashboard:disable', ~> if @visible
            @$el .removeClass \expanded
            API.off \advance, @loadBind
    load: ({media}, isRetry) ->
        console.log "[song-info]", media
        if @lastMediaID == media.id
            @showInfo media
        else
            @lastMediaID = media.id
            @mediaData = null
            mediaLookup media, do
                fail: (err) ~>
                    console.error "[song-info]", err
                    if isRetry
                        @$el .html "error loading, retrying…"
                        load {media}, true
                    else
                        @$el .html "Couldn't load song info, sorry =("
                success: (@mediaData) ~>
                    console.log "[song-info] got data", @mediaData
                    @showInfo media
            API.once \advance, @loadBind
    showInfo: (media) ->
        return if @lastMediaID != media.id or @disabled # skip if another song is already playing
        d = @mediaData

        @$el .html ""
        $meta = @$create \<div>  .addClass \p0ne-song-info-meta        .appendTo @$el
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
            .attr \href, "https://www.youtube.com/channel/#{d.uploader.id}"
            .attr \target, \_blank
            .attr \title, "open channel of '#{d.uploader.name}'"
            .text d.uploader.name
        $ \<a> .addClass \p0ne-song-info-ytTitle        .appendTo $meta
            .attr \href, "http://youtube.com/watch?v=#{media.cid}"
            .attr \target, \_blank
            .attr \title, "open video on Youtube"
            .text d.title
        $ \<br>                                         .appendTo $meta
        $ \<span> .addClass \p0ne-song-info-date        .appendTo $meta
            .text getISOTime new Date(d.uploadDate)
        $ \<span> .addClass \p0ne-song-info-duration    .appendTo $meta
            .text mediaTime +d.duration
        if media.format == 1
            for r in d.data.entry.media$group.media$restriction ||[]
                $ \<span> .addClass \p0ne-song-info-blocked     .appendTo @$el
                    .text "blocked (#{r.type}): #{r.$t}"
        #$ \<div> .addClass \p0ne-song-info-songStats   #ToDo
        #$ \<div> .addClass \p0ne-song-info-songStats   #ToDo
        #$ \<div> .addClass \p0ne-song-info-tags    #ToDo
        $ \<div> .addClass \p0ne-song-info-description  .appendTo @$el
            .html formatPlainText(d.description)
        #$ \<ul> .addClass \p0ne-song-info-remixes      #ToDo
    disable: ->
        @$el .remove!