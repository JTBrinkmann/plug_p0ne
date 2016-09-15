/**
 * plug_p0ne modules to add styles.
 * This needs to be kept in sync with plug_pony.css
 *
 * @author jtbrinkmann aka. Brinkie Pie
 * @license MIT License
 * @copyright (c) 2015 J.-T. Brinkmann
 */


module \p0neStylesheet, do
    setup: ({loadStyle}) !->
        loadStyle "#{p0ne.host}/css/plug_p0ne.css?r=47"

/*
window.moduleStyle = (name, d) !->
    options =
        settings: true
        module: !-> @toggle!
    if typeof d == \string
        if isURL(d) # load external CSS
            options.setup = ({loadStyle}) !->
                loadStyle d
        else if d.0 == "." # toggle class
            options.setup = !->
                $body .addClass d
            options.disable = !->
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
    setup: ({loadStyle}) !->
        loadStyle "#{p0ne.host}/css/fimplug.css?r=28"


/*####################################
#          ANIMATED DIALOGS          #
####################################*/
module \animatedUI, do
    require: <[ Dialog ]>
    setup: ({addListener, replace}) !->
        $ \.dialog .addClass \opaque
        replace Dialog, \render, !-> return !->
            @show!
            sleep 0ms, !~> @$el.addClass \opaque
            return this

        addListener _$context, \ShowDialogEvent:show, (d) !->
                if d.dialog.options?.media?.format == 2
                    sleep 0ms, !~> @$el.addClass \opaque

        replace Dialog, \close, (close_) !-> return !->
            @$el.removeClass \opaque
            sleep 200ms, !~> close_.call this
            return this


/*####################################
#        FIX HIGH RESOLUTIONS        #
####################################*/
module \fixHiRes, do
    displayName: "☢ Fix high resolutions"
    settings: \fixes
    help: '''
        This will fix some odd looking things on larger screens
        NOTE: This is WORK IN PROGESS! Right now it doesn't help much.
    '''
    setup: ({}) !->
        $body .addClass \p0ne-fix-hires
    disable: !->
        $body .removeClass \p0ne-fix-hires


/*####################################
#         PLAYLIST ICON VIEW         #
####################################*/
# fix drag'n'drop styles for playlist icon view
module \playlistIconView, do
    displayName: "Playlist Grid View"
    settings: \look&feel
    help: '''
        Shows songs in the playlist and history panel in an icon view instead of the default list view.
    '''
    optional: <[ PlaylistItemList pl ]>
    setup: ({addListener, replace, replaceListener}, playlistIconView) !->
        $body .addClass \playlist-icon-view

        #= fix visiblerows calculation =
        if not PlaylistItemList?
            chatWarn playlistIconView.displayName, "this module couldn't fully load, it might not act 100% as expected. If you have problems, you might want to disable this."
            return
        const CELL_HEIGHT = 185px # keep in sync with plug_p0ne.css
        const CELL_WIDTH = 160px
        replace PlaylistItemList::, \onResize, !-> return !->
            @@@__super__.onResize .call this
            newCellsPerRow = ~~((@$el.width! - 10px) / CELL_WIDTH)
            newVisibleRows = Math.ceil(2rows + @$el.height!/CELL_HEIGHT) * newCellsPerRow
            if newVisibleRows != @visibleRows or newCellsPerRow != @cellsPerRow
                #console.log "[pIV resize]", newVisibleRows, newCellsPerRow
                @visibleRows = newVisibleRows
                @cellsPerRow = newCellsPerRow
                delete @currentRow
                @onScroll!

        replace PlaylistItemList::, \onScroll, (oS) !-> return !->
            if @scrollPane
                top = ~~(@scrollPane.scrollTop! / CELL_HEIGHT) - 1row >? 0
                @firstRow = top * @cellsPerRow
                lastRow = @firstRow + @visibleRows <? @collection.length
                if @currentRow != @firstRow
                    #console.log "[scroll]", @firstRow, lastRow, @visibleRows
                    @currentRow = @firstRow
                    @$firstRow.height top * CELL_HEIGHT
                    @$lastRow.height do
                        ~~((@collection.length - lastRow) / @cellsPerRow) * CELL_HEIGHT
                    @$container.empty!.append @$firstRow
                    for e from @firstRow to lastRow when row = @rows[e]
                        @$container.append row.$el
                        row.render!
                    @$container.append(@$lastRow)


        if pl?.list?.rows
            # onResize hook
            Layout
                .off \resize, pl.list.resizeBind
                .resize replace(pl.list, \resizeBind, !~> return pl.list~onResize)

            # onScroll hook
            pl.list.$el
                .off \jsp-scroll-y, pl.list.scrollBind
                .on \jsp-scroll-y, replace(pl.list, \scrollBind, !~> return pl.list~onScroll)

            # opening playlist drawer animation fix
            replaceListener _$context, \anim:playlist:progress, PlaylistItemList, !~> return !~>
                #pl.list.onResize! if pl.list.$el

            # to force rerender
            delete pl.list.currentRow
            pl.list.onResize Layout.getSize!
            pl.list.onScroll?!
        else
            console.warn "no pl"

        #= fix dragRowLine =
        # (The line that indicates when drag'n'dropping, where a song would be dropped)
        $hovered = $!
        $mediaPanel = $ \#media-panel
        addListener $mediaPanel, \mouseover, \.row, !->
            $hovered .removeClass \hover
            $hovered := $ this
            $hovered .addClass \hover if not $hovered.hasClass \selected
        addListener $mediaPanel, \mouseout, \.hovered, !->
            $hovered.removeClass \hover



        # usually, when you drag a song (row) plug checks whether you drag it BELOW or ABOVE the currently hovered row
        # however with icons, we would rather want to move them LEFT or RIGHT of the hovered song (icon)
        # sadly the easiest way that's not TOO haxy requires us to redefine the whole function just to change two words
        # also some lines are removed, because the vanilla $dragRowLine is not used anymore, we use a CSS-based solution
        replace PlaylistItemList::, \onDragUpdate, !-> return (e) !->
            @@@__super__.onDragUpdate .call this, e
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
                        @targetDropIndex =
                            if i == @lastClickedIndex - 1
                                @lastClickedIndex
                            else
                                @targetDropIndex = i + 1
                    else
                        @$el .removeClass \p0ne-drop-right
                        @targetDropIndex =
                            if i == @lastClickedIndex + 1
                                @lastClickedIndex
                            else
                                @targetDropIndex = i
                else if i == 0
                    @targetDropIndex = 1

            o = @onCheckListScroll!

    disableLate: !->
        # using disableLate so that `pl.scrollBind` is already reset
        console.info "#{getTime!} [playlistIconView] disabling"
        $body .removeClass \playlist-icon-view
        pl?.list?.$el?
            .off \jsp-scroll-y
            .on \jsp-scroll-y, pl.list.scrollBind


        /*
        #= load all songs at once =
        replace PlaylistItemList::, \onScroll, !-> return $.noop
        replace PlaylistItemList::, \drawList, !-> return !->
            @@@__super__.drawList .call this
            if this.collection.length == 1
                this.$el.addClass \only-one
            else
                this.$el.removeClass \only-one
            for row in pl.rows
              row.$el.appendTo pl.$container
              row.render!
        */

        /*
        #= icon to toggle playlistIconView =
        replace MediaPanel::, \show, (s_) !-> return !->
            s_ ...
            @header.$el .append do
                $create '<div class="button playlist-view-button"><i class="icon icon-playlist"></i></div>'
                    .on \click, playlistIconView
        */






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
    setup: ({addListener}) !->
        $room = $ \#room
        $playbackImg = $ \#playback-container
        addListener API, \advance, updatePic
        updatePic media: API.getMedia!

        function updatePic d
            if not d.media
                #console.log "[Video Placeholder Image] hide"
                $playbackImg .css backgroundColor: \transparent, backgroundImage: \none
            else if d.media.format == 1  # YouTube
                #console.log "[Video Placeholder Image] #img"
                $playbackImg .css backgroundColor: \#000, backgroundImage: "url(https://i.ytimg.com/vi/#{d.media.cid}/0.jpg)"
            else # SoundCloud
                #console.log "[Video Placeholder Image] #{d.media.image}"
                $playbackImg .css backgroundColor: \#000, backgroundImage: "url(#{d.media.image})"
    disable: !->
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
    setup: ({addListener}) !->
        $body .addClass \legacy-chat
        $cb = $ \#chat-button
        addListener $cb, \dblclick, (e) !~>
            @toggle!
            e.preventDefault!
        addListener chatDomEvents, \dblclick, '.popout .icon-chat', (e) !~>
            @toggle!
            e.preventDefault!
    disable: !->
        $body .removeClass \legacy-chat


/*####################################
#            LEGACY FOOTER           #
####################################*/
module \legacyFooter, do
    displayName: "Info Footer"
    settings: \look&feel
    help: '''
        Restore the old look of the footer (the thing below the chat) and transform it into a more useful information panel.
        To get to the settings etc, click anywhere on the panel.
    '''
    disabled: true
    setup: ({addListener}) !->
        # most of this module's magic is in the CSS
        $body .addClass \legacy-footer

        # show the menu when the user clicks the footer
        $foo = $ \#footer-user
        addListener $foo.find(\.info), \click, !->
            $foo.addClass \menu
            <- _.delay
            $body.one \click, !-> $foo.removeClass \menu

        # make sure the "Back To Community" button text is loaded
        # it usually isn't if the user didn't open the playlist-/settings-drawer yet
        $foo .find '.back span:first'
            ..text Lang?.userMeta.backToCommunity || "Back To Community" if not /\S/.test ..text!

    disable: !->
        $body .removeClass \legacy-footer
        $ \#footer-user .removeClass \menu


/*####################################
#            CHAT DJ ICON            #
####################################*/
module \djIconChat, do
    require: <[ chatPlugin ]>
    settings: \look&feel
    displayName: "Current-DJ-icon in Chat"
    setup: ({addListener, css}) !->
        # get the DJ icon image URL and background-position
        icon = getIcon \icon-current-dj
        css \djIconChat, "\#chat .from-current-dj .timestamp::before { background: #{icon.background}; }"

        # add .from-current-dj class to messages from the current DJ
        addListener _$context, \chat:plugin, (message) !->
            if message.uid and message.uid == API.getDJ!?.id
                message.addClass \from-current-dj


/*####################################
#          DRAGGABLE DIALOG          #
####################################*/
module \draggableDialog, do
    require: <[ Dialog ]>
    displayName: '☢ Draggable Dialog'
    settings: \look&feel
    setup: ({addListener, replace, css}) !->
        # set up styles
        css \dialogDragNDrop, '
            .dialog-frame, .p0ne-lightsout-btn { cursor: pointer; }
            #dialog-container { width: 0; }
            #dialog-container.lightsout { width: auto; }
            #dialog-container.dragging .dialog-frame { cursor: move; }
            .dialog { position: absolute; }
            #dialog-container { transition: background .5s ease-out; }
            #dialog-container.dragging { background: rgba(0,0,0, 0); }
            .p0ne-lightsout-btn {
                top: 10px;
                left: 10px;
                opacity: .5;
            }
        '

        # set up event listener to initiate Drag'n'Drop
        var $dialog, startPos, startX, startY
        $dialogContainer = $ \#dialog-container
        addListener $dialogContainer, \mousedown, \.dialog-frame, (e) !->
            # set up drag'n'drop event listeners
            $body
                .on \mousemove, mousemove
                .on \mouseup, mouseup
            $dialog := $ this .closest \.dialog
                .addClass \dragging
            pos = $dialog .position!
            $dialog .css position: \absolute
            startX := e.clientX - pos.left; startY := e.clientY - pos.top
            #$dialogContainer .addClass \dragging

        #addListener $dialogContainer, \click, \.dialog-frame, (e) !->
        #    $dialogContainer .css \width, 0

        /* add lights-out button to dialogs */
        lightsout = true
        replace Dialog, \getHeader, !-> return (title) !->
            $  "<div class=dialog-frame>
                    <span class=title>#title</span>
                    <i class='icon icon-#{if lightsout then '' else 'un'}locked p0ne-lightsout-btn'></i>
                    <i class='icon icon-dialog-close'></i>
                </div>"
                ..find \.icon-dialog-close
                    .on \click, @~close
                return ..
        # if a dialog is already open
        $ \.dialog-frame:first .append "<i class='icon icon-#{if lightsout then '' else 'un'}locked p0ne-lightsout-btn'></i>"

        addListener _$context, \ShowDialogEvent:show, (d) !->
            $dialog := $dialogContainer .find \.dialog
                .css position: \static
            $dialogContainer .addClass \lightsout
            if pos = $dialog .position!
                pos.position = \absolute
                $dialog .css pos
            if not lightsout
                $dialogContainer .removeClass \lightsout

        addListener $dialogContainer, \mousedown, \.p0ne-lightsout-btn, (e) !->
            if lightsout
                $dialogContainer.removeClass \lightsout
                $ this .removeClass \icon-locked .addClass \icon-unlocked
            else
                $dialogContainer.addClass \lightsout
                $ this .addClass \icon-locked .removeClass \icon-unlocked
            lightsout := !lightsout

        # reset when the dialog is closed
        replace Dialog, \close, (c_) !-> return !->
            console.log "[dialogDragNDrop] closing dialog"
            stopDragging true
            c_ ...

        function mousemove e
            # move dialog
            $dialog .css do
                left: e.clientX - startX
                top: e.clientY - startY
            e.preventDefault!

        function mouseup e
            # end dragging mode (i.e. drop the dialog)
            stopDragging!

        @stopDragging = stopDragging = !->
            $dialog? .removeClass \dragging
            $body
                .off \mousemove, mousemove
                .off \mouseup, mouseup
    disable: !->
        @stopDragging?!
        $ '#dialog-container .dialog' .css position: \static
        $ '#dialog-container .p0ne-lightsout-btn' .remove!


/*####################################
#             EMOJI PACK             #
####################################*/
module \emojiPack, do
    displayName: '☢ Emoji Pack [Google]'
    settings: \look&feel
    disabled: true
    help: '''
        Replace all emojis with the one from Google (for Android Lollipop).

        Emojis are are the little images that show up e.g. when you write ":eggplant:" in the chat. <span class="emoji emoji-1f346"></span>

        <small>
        Note: :yellow_heart: <span class="emoji emoji-1f49b"></span> and :green_heart: <span class="emoji emoji-1f49a"></span> look neither yellow nor green with this emoji pack.
        </small>
    '''
    screenshot: 'https://i.imgur.com/Ef94Csn.png'
    _settings:
        pack: \google
        # note: as of now, only Google's emojicons (from Android Lollipop) are supported
        # possible future emoji packs are: Twitter's and EmojiOne's (and native browser)
        # by default, plug.dj uses Apple's emojipack
    setup: ({loadStyle}) !->
        loadStyle "#{p0ne.host}/css/temp.#{@_settings.pack}-emoji.css"


/*####################################
#               CENSOR               #
####################################*/
module \censor, do
    displayName: "Censor"
    settings: \dev
    help: '''
        blurs some information like playlist names, counts, EP and Plug Notes.
        Great for taking screenshots
    '''
    disabled: true
    setup: ({css}) !->
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
    disable: !->
        $body .removeClass \censored
