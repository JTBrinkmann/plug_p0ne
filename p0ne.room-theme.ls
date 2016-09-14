/**
 * Room Settings module for plug_p0ne
 * made to be compatible with plugCubes Room Settings
 * so room hosts don't have to bother with mutliple formats
 * that also means, that a lot of inspiration came from and credits go to the PlugCubed team ♥
 * @author jtbrinkmann aka. Brinkie Pie
 * @license MIT License
 * @copyright (c) 2014 J.-T. Brinkmann
*/

module \roomSettings, do
    require: <[ room ]>
    optional: <[ _$context ]>
    persistent: <[ _data _room ]>
    setup: ({addListener}) ->
        @_update!
        if _$context?
            addListener _$context, \room:joining, @~_clear
            addListener _$context, \room:joined, @~_update
    _update: ->
        @_listeners = []

        roomslug = getRoomSlug!
        return if @_data and roomslug == @_room

        if not roomDescription = room.get \description #$ '#room-info .description .value' .text!
            console.warn "[p0ne] no p³ compatible Room Settings found"
        else if url = /@p3=(.*)/i .exec roomDescription
            console.log "[p0ne] p³ compatible Room Settings found", url.1
            $.getJSON httpsify(url.1)
                .then (@_data) ~>
                    console.log "#{getTime!} [p0ne] loaded p³ compatible Room Settings"
                    @_room = roomslug
                    @_trigger!
                .fail ->
                    API.chatLog "[p0ne] cannot load Room Settings", true
    _trigger: ->
        for fn in @_listeners
            fn @_data
    _clear: ->
        @_data = null
        @_trigger
    on: (,fn) ->
        @_listeners[*] = fn
        if @_data
            fn @_data
    off: (,fn) ->
        if -1 != (i = @_listeners .indexOf fn)
            @_listeners .splice i, 1
            return true
        else
            return false

module \roomTheme, do
    displayName: "Room Theme"
    require: <[ roomSettings ]>
    optional: <[ roomLoader ]>
    settings: \look&feel
    help: '''
        Applies the room theme, if this room has one.
        Room Settings and thus a Room Theme can be added by (co-) hosts of the room.
    '''
    setup: ({addListener, replace, css, loadStyle}) ->
        roles = <[ residentdj bouncer manager cohost host ambassador admin ]> #TODO
        @$playbackBackground = $ '#playback .background img'
        @playbackBackgroundVanilla = @$playbackBackground .attr(\src)

        console.log "#{getTime!} [roomTheme] initializing"
        addListener roomSettings, \loaded, (d) ~>
            console.log "#{getTime!} [roomTheme] loading theme"
            return if not d or @currentRoom == (roomslug = getRoomSlug!)
            @currentRoom = roomslug
            @clear!
            styles = ""

            /*== colors ==*/
            if d.colors
                styles += "\n/*== colors ==*/\n"
                for role, color of d.colors.chat when /*role in roles and*/ isColor(color)
                    styles += """
                    /* #role => #color */
                    \#user-panel:not(.is-none) .user > .icon-chat-#role + .name, \#user-lists .user > .icon-chat-#role + .name, .cm.from-#role .from
                    \#waitlist .icon-chat-#role + span, \#user-rollover .icon-chat-cohost + span {
                            color: #color !important;
                    }\n"""
                colorMap =
                    background: \.room-background
                    header: \.app-header
                    footer: \#footer
                for k, selector of colorMap when isColor(d.colors[k])
                    styles += "#selector { background-color: #{d.colors[k]} !important }\n"

            /*== CSS ==*/
            if d.css
                styles += "\n/*== custom CSS ==*/\n"
                for rule,attrs of d.css.rule
                    styles += "#rule {"
                    for k, v of attrs
                        styles += "\n\t#k: #v"
                        styles += ";" if not /;\s*$/.test v
                    styles += "\n}\n"
                for {name, url} in d.css.fonts ||[] when name and url
                    if $.isArray url
                        url = [].join.call(url, ", ")
                    styles += """
                    @font-face {
                        font-family: '#name';
                        src: '#url';
                    }\n"""
                for url in d.css.import ||[]
                    loadStyle url
                #for rank, color of d.colors?.chat ||{}
                #   ...

            /*== images ==*/
            if d.images
                styles += "\n/*== images ==*/\n"
                /* custom p0ne stuff */
                if isURL(d.images.backgroundScalable)
                    styles += "\#app { background-image: url(#{d.images.background}) fixed center center / cover }\n"

                    /* original plug³ stuff */
                else if isURL(d.images.background)
                    styles += ".room-background { background-image: url(#{d.images.background}) !important }\n"
                if isURL(d.images.playback) and roomLoader? and Layout?
                    new Image
                        ..onload = ~>
                            @$playbackBackground .attr \src, d.images.playback
                            replace roomLoader, \frameHeight,   -> return ..height - 10px
                            replace roomLoader, \frameWidth,    -> return ..width  - 18px
                            roomLoader.onVideoResize Layout.getSize!
                            console.log "#{getTime!} [roomTheme] loaded playback frame"
                        ..onerror = ->
                            console.error "#{getTime!} [roomTheme] failed to load playback frame"
                        ..src = d.images.playback
                    replace roomLoader, \src, -> return d.images.playback
                if isURL(d.images.booth)
                    styles += """
                        /* custom booth */
                        \#avatars-container::before {
                            background-image: url(#{d.images.booth});
                        }\n"""
                for role, url of d.images.icons when role in roles
                    styles += """
                        .icon-chat-#role {
                            background-image: url(#url);
                            background-position: 0 0;
                        }\n"""

            /*== text ==*/
            if d.text
                for key, text of d.text.plugDJ
                    for lang of Lang[key]
                        replace Lang[key], lang, -> return text

            css \roomTheme, styles
            @styles = styles

    clear: (skipDisables) ->
        console.log "#{getTime!} [roomTheme] clearing RoomTheme"
        if not skipDisables
            # copied from p0ne.module
            for [target, attr /*, repl*/] in @_cbs.replacements ||[]
                target[attr] = target["#{attr}_"]
            for style of @_cbs.css
                p0neCSS.css style, "/* disabled */"
            for url of @_cbs.loadedStyles
                p0neCSS.unloadStyle url
            delete [@_cbs.replacements, @_cbs.css, @_cbs.loadedStyles]

        @currentRoom = null
        @$playbackBackground
            .one \load ->
                roomLoader?.onVideoResize Layout.getSize! if Layout?
            .attr \src, @playbackBackgroundVanilla

    disable: -> @clear true
