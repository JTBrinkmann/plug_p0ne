/**
 * plug_p0ne modules to add styles.
 * This needs to be kept in sync with plug_pony.css
 * @author jtbrinkmann aka. Brinkie Pie
 * @version 1.0
 * @license MIT License
 * @copyright (c) 2014 J.-T. Brinkmann
 */


module \p0neStylesheet, do
    setup: ({loadStyle}) ->
        loadStyle "#{p0ne.host}/css/plug_p0ne.css?v=1.8"

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
        loadStyle "#{p0ne.host}/css/fimplug.css?v=1.2"

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
            $hovered.removeClass \hover
            $hovered := $ this
            $hovered.addClass \hover if not $hovered.hasClass \selected
        addListener $mediaPanel, \mouseout, \.hover, ->
            $hovered.removeClass \hover

        replace MediaPanel::, \show, (s_) -> return ->
            s_ ...
            this.header.$el .append do
                $create '<div class="button playlist-view-button"><i class="icon icon-playlist"></i></div>'
                    .on \click, playlistIconView
    disable: ->
        $body .removeClass \playlist-icon-view


/*####################################
#             LEGACY CHAT            #
####################################*/
module \legacyChat, do
    displayName: "Legacy Chat"
    settings: \chat
    help: '''
        Shows the chat in the old format, before badges were added to it in December 2014.
    '''
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


module \censor, do
    displayName: "Censor"
    settings: \dev
    help: '''
        blurs some information like playlist names, counts, EP and Plug Notes.
        Great for taking screenshots
    '''
    disabled: true
    setup: ->
        $body .addClass \censored
    disable: ->
        $body .removeClass \censored