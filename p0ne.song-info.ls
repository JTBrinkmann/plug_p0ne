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
    settings: \enableDisable
    displayName: 'Song-Info Dropdown'
    help: '''
        clicking on the now-playing-bar (in the top-center of the page) will open a panel with the song's description and links to the artist and song.
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
                else if @lastMedia == media.id
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
        @lastMedia = media
        mediaLookup media, do
            fail: ~>
                if isRetry
                    @$el .html "error loading, retrying…"
                    load {media}, true
                else
                    @$el .html "Couldn't load song info, sorry =("
            success: (d) ~>
                console.log "[song-info] got data", @lastMedia != media
                return if @lastMedia != media or @disabled # skip if another song is already playing

                @$el .html ""
                $meta = @$create \<div>  .addClass \p0ne-song-info-meta        .appendTo @$el
                $parts = {}

                @$create \<span> .addClass \p0ne-song-info-author      .appendTo $meta
                    .click -> mediaSearch media.author
                    .attr \title, "search for '#{media.author}'"
                    .text media.author
                @$create \<span> .addClass \p0ne-song-info-title       .appendTo $meta
                    .click -> mediaSearch media.title
                    .attr \title, "search for '#{media.title}'"
                    .text media.title
                @$create \<br>                                         .appendTo $meta
                @$create \<a> .addClass \p0ne-song-info-uploader       .appendTo $meta
                    .attr \href, "https://www.youtube.com/channel/#{d.uploader.id}"
                    .attr \target, \_blank
                    .attr \title, "open channel of '#{d.uploader.name}'"
                    .text d.uploader.name
                @$create \<a> .addClass \p0ne-song-info-ytTitle        .appendTo $meta
                    .attr \href, "http://youtube.com/watch?v=#{media.cid}"
                    .attr \target, \_blank
                    .attr \title, "open video on Youtube"
                    .text d.title
                @$create \<br>                                         .appendTo $meta
                @$create \<span> .addClass \p0ne-song-info-date        .appendTo $meta
                    .text getISOTime new Date(d.uploadDate)
                @$create \<span> .addClass \p0ne-song-info-duration    .appendTo $meta
                    .text mediaTime +d.duration
                #@$create \<div> .addClass \p0ne-song-info-songStats   #ToDo
                #@$create \<div> .addClass \p0ne-song-info-songStats   #ToDo
                #@$create \<div> .addClass \p0ne-song-info-tags    #ToDo
                @$create \<div> .addClass \p0ne-song-info-description  .appendTo @$el
                    .html formatPlainText(d.description)
                #@$create \<ul> .addClass \p0ne-song-info-remixes      #ToDo
        API.once \advance, @loadBind
    disable: ->
        @$el .remove!