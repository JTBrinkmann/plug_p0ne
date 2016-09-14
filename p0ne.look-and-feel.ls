/**
 * plug_p0ne modules to add styles.
 * This needs to be kept in sync with plug_pony.css
 *
 * @author jtbrinkmann aka. Brinkie Pie
 * @license MIT License
 * @copyright (c) 2015 J.-T. Brinkmann
 */


module \p0neStylesheet, do
    setup: ({loadStyle}) ->
        loadStyle "#{p0ne.host}/css/plug_p0ne.css?r=38"

/*
window.moduleStyle = (name, d) ->
    options =
        settings: true
        module: -> @toggle!
    if typeof d == \string
        if isURL(d) # load external CSS
            options.setup = ({loadStyle}) ->
                loadStyle d
        else if d.0 == "." # toggle class
            options.setup = ->
                $body .addClass d
            options.disable = ->
                $body .removeClass d
    else if typeof d == \function
        options.setup = d
    module name, options
*/

/*####################################
#            FIMPLUG THEME           #
####################################*/
module \fimplugTheme, do
    settings: \look&feel
    displayName: "Brinkie's fimplug Theme"
    setup: ({loadStyle}) ->
        loadStyle "#{p0ne.host}/css/fimplug.css?r=23"

/*####################################
#          ANIMATED DIALOGS          #
####################################*/
module \animatedUI, do
    require: <[ DialogAlert ]>
    setup: ({replace}) ->
        $ \.dialog .addClass \opaque
        # animate dialogs
        Dialog = DialogAlert.__super__

        replace Dialog, \render, -> return ->
            @show!
            sleep 0ms, ~> @$el.addClass \opaque
            return this

        replace Dialog, \close, (close_) -> return ->
            @$el.removeClass \opaque
            sleep 200ms, ~> close_.call this
            return this

/*####################################
#        FIX HIGH RESOLUTIONS        #
####################################*/
module \fixHiRes, do
    displayName: "Fix high resolutions"
    help: '''
        This will fix some odd looking things on larger screens
    '''
    setup: ({}) ->
        $body .addClass \p0ne-fix-hires
    disable: ->
        $body .removeClass \p0ne-fix-hires


/*####################################
#         PLAYLIST ICON VIEW         #
####################################*/
# fix drag'n'drop styles for playlist icon view
module \playlistIconView, do
    displayName: "Playlist Icon View"
    settings: \look&feel
    help: '''
        Shows songs in the playlist and history panel in an icon view instead of the default list view.
    '''
    setup: ({addListener, replace, $create}, playlistIconView) ->
        $body .addClass \playlist-icon-view
        $hovered = $!
        $mediaPanel = $ \#media-panel
        addListener $mediaPanel , \mouseover, \.row, ->
            $hovered := $ this
            $hovered.removeClass \hover
            $hovered.addClass \hover if not $hovered.hasClass \selected
        addListener $mediaPanel, \mouseout, \.hover, ->
            $hovered.removeClass \hover

        /*replace MediaPanel::, \show, (s_) -> return ->
            s_ ...
            @header.$el .append do
                $create '<div class="button playlist-view-button"><i class="icon icon-playlist"></i></div>'
                    .on \click, playlistIconView
        */

        # usually, when you drag a song (row) plug checks whether you drag it BELOW or ABOVE the currently hovered row
        # however with icons, we would rather want to move them LEFT or RIGHT of the hovered song (icon)
        # sadly the easiest way that's not TOO haxy requires us to redefine the whole function just to change two words
        # also some lines are commented out, because the vanilla $dragRowLine is not used anymore, we use a pure CSS solution
        replace PlaylistItemRow::, \onDragUpdate, -> return (e) ->
            @@@__super__.onDragUpdate .call this, e
            #t = @$el.offset!.top
            n = @scrollPane.scrollTop!
            if @currentDragRow && @currentDragRow.$el
                r = 0
                i = @currentDragRow.options.index
                if not @lockFirstItem or i > 0
                    @targetDropIndex = i
                    s = @currentDragRow.$el.offset!.left
                    # if @mouseY >= s + @currentDragRow.$el.height! / 2 # here we go, two words that NEED to be changed
                    if @mouseX >= s + @currentDragRow.$el.width! / 2
                        @$el .addClass \p0ne-drop-right
                        #r = s - t + n + @currentDragRow.$el.height!
                        @targetDropIndex =
                            if i === @lastClickedIndex - 1
                                @lastClickedIndex
                            else
                                @targetDropIndex = i + 1
                    else
                        @$el .removeClass \p0ne-drop-right
                        #r = s - t + n
                        @targetDropIndex =
                            if i === @lastClickedIndex + 1
                                @lastClickedIndex
                            else
                                @targetDropIndex = i
                    #@$dragRowLine.css \top, r
                else if i === 0
                    #r = @currentDragRow.$el.offset!.top - t + n + @currentDragRow.$el.height!
                    @targetDropIndex = 1
                    #@$dragRowLine.css \top, r

            o = @onCheckListScroll!
            /*
            if @withinBounds
                if o > -10 and (not @lockFirstItem || i > 0)
                    @$dragRowLine.css \top, o
                @$dragRowLine.show!
            else
                @$dragRowLine.hide!
            */

    disable: ->
        $body .removeClass \playlist-icon-view


/*####################################
#          VIDEO PLACEHOLDER         #
####################################*/
module \videoPlaceholderImage, do
    displayName: "Video Placeholder Thumbnail"
    settings: \look&feel
    help: '''
        Shows a thumbnail in place of the video, if you snooze the video or turn off the stream.

        This is useful for knowing WHAT is playing, even when don't want to watch it.
    '''
    screenshot: 'https://i.imgur.com/TMHVsrN.gif'
    setup: ({addListener}) ->
        #== add video thumbnail to #playback ==
        $playbackImg = $ \#playback-container
        addListener API, \advance, updatePic
        updatePic media: API.getMedia!
        function updatePic d
            if not d.media
                console.log "[Video Placeholder Image] hide", d
                $playbackImg .css backgroundColor: \transparent, backgroundImage: \none
            else if d.media.format == 1  # YouTube
                console.log "[Video Placeholder Image] https://i.ytimg.com/vi/#{d.media.cid}/0.jpg", d
                $playbackImg .css backgroundColor: \#000, backgroundImage: "url(https://i.ytimg.com/vi/#{d.media.cid}/0.jpg)"
            else # SoundCloud
                console.log "[Video Placeholder Image] #{d.media.image}", d
                $playbackImg .css backgroundColor: \#000, backgroundImage: "url(#{d.media.image})"
    disable: ->
        $ \#playback-container .css backgroundColor: \transparent, backgroundImage: \none

/*####################################
#             LEGACY CHAT            #
####################################*/
module \legacyChat, do
    displayName: "Smaller Chat"
    settings: \chat
    help: '''
        Shows the chat in the old format, before badges were added to it in December 2014.
        Makes the messages smaller, so more fit on the screen
    '''
    disabled: true
    setup: ({addListener}) ->
        $body .addClass \legacy-chat
        $cb = $ \#chat-button
        addListener $cb, \dblclick, (e) ~>
            @toggle!
            e.preventDefault!
        addListener chatDomEvents, \dblclick, '.popout .icon-chat', (e) ~>
            @toggle!
            e.preventDefault!
    disable: ->
        $body .removeClass \legacy-chat

module \legacyFooter, do
    displayName: "Info Footer"
    settings: \look&feel
    help: '''
        Restore the old look of the footer (the thing below the chat) and transform it into a more useful information panel.
        To get to the settings etc, click anywhere on the panel.
    '''
    disabled: true
    setup: ->
        $body .addClass \legacy-footer

        foo = $ \#footer-user
        info = foo.find \.info
        info.on \click, ->
        info.on \click, ->
            foo.addClass \menu
            <- requestAnimationFrame
            $body.one \click, -> foo.removeClass \menu
        foo.find '.back span'
            ..text Lang?.userMeta.backToCommunity || "Back To Community" if not /\S/.test ..text!
    disable: ->
        $body .removeClass \legacy-footer

module \djIconChat, do
    require: <[ chatPlugin ]>
    settings: \look&feel
    displayName: "Current-DJ-icon in Chat"
    setup: ({addListener, css}) ->
        icon = getIcon \icon-current-dj
        css \djIconChat, "\#chat .from-current-dj .timestamp::before { background: #{icon.background}; }"
        addListener _$context, \chat:plugin, (message) ->
            if message.uid and message.uid == API.getDJ!?.id
                message.addClass \from-current-dj

module \censor, do
    displayName: "Censor"
    settings: \dev
    help: '''
        blurs some information like playlist names, counts, EP and Plug Notes.
        Great for taking screenshots
    '''
    disabled: true
    setup: ({css}) ->
        $body .addClass \censored
        css '
            @font-face {
                font-family: "ThePrintedWord";
                src: url("http://letterror.com/wp-content/themes/nextltr/css/fonts/ThePrintedWord.eot");
                src: url("http://letterror.com/wp-content/themes/nextltr/css/fonts/ThePrintedWord.eot?") format("embedded-opentype"),
                     url("http://letterror.com/wp-content/themes/nextltr/css/fonts/ThePrintedWord.woff") format("woff"),
                     url("http://letterror.com/wp-content/themes/nextltr/css/fonts/ThePrintedWord.svg") format("svg"),
                     url("http://letterror.com/wp-content/themes/nextltr/css/fonts/ThePrintedWord.otf") format("opentype");
                font-style: normal;
                font-weight: 400;
                font-stretch: normal;
            }'
    disable: ->
        $body .removeClass \censored