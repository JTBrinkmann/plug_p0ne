/**
 * plug_p0ne modules to add styles.
 * This needs to be kept in sync with plug_pony.css
 * @author jtbrinkmann aka. Brinkie Pie
 * @version 1.0
 * @license MIT License
 * @copyright (c) 2014 J.-T. Brinkmann
 */


loadStyle "#{p0ne.host}/css/plug_p0ne.css?v=1.2"

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
    settings: true
    displayName: "Brinkie's fimplug Theme"
    module: -> @toggle!
    setup: ({loadStyle}) ->
        loadStyle "#{p0ne.host}/css/fimplug.css"

/*####################################
#          ANIMATED DIALOGS          #
####################################*/
module \animatedUI, do
    require: <[ DialogAlert ]>
    module: -> @toggle!
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
    help: '''
        Shows songs in the playlist and history panel in an icon view instead of the default list view.
    '''
    settings: true
    module: -> @toggle!
    setup: ({addListener, replace, $create}, playlistIconView,, isUpdate) ->
        $body .addClass \playlist-icon-view if not isUpdate
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
    help: '''
        Shows the chat in the old format, before badges were added to it in December 2014.
    '''
    settings: true
    module: -> @toggle!
    setup: ({addListener},,, isUpdate) ->
        $body .addClass \legacy-chat if not isUpdate
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
    help: '''
        blurs some information like playlist names, counts, EP and Plug Notes.
        Great for taking screenshots
    '''
    disabled: true
    settings: true
    module: -> @toggle!
    setup: ->
        $body .addClass \censored
    disable: ->
        $body .removeClass \censored