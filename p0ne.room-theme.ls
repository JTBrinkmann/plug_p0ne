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
    optional: <[ _$context ]>
    settings: false
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

        if not roomDescription = $ '#room-info .description .value' .text!
            return
        url = /@p3=(.*)/i .exec roomDescription
        return if not url
        $.getJSON p0ne.proxy(url.1)
            .then (@_data) ~>
                console.log "[p0ne] loaded p³ compatible Room Settings"
                @_room = roomslug
                @_trigger!
            .fail fail
        function fail
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
    settings: true
    setup: ({addListener, replace, css, loadStyle}) ->
        roles = <[ residentdj bouncer manager cohost host ambassador admin ]> #TODO
        @$playbackBackground = $ '#playback .background img'
            ..data \_o, ..data(\_o) || ..attr(\src)

        addListener roomSettings, \loaded, (d) ~>
            return if not d or @currentRoom == (roomslug = getRoomSlug!)
            @currentRoom = roomslug
            @clear!
            styles = ""

            /*== colors ==*/
            if d.colors
                for role, color of d.colors.chat when role in roles and isColor(color)
                    styles += """
                    /* #role => #color */
                    \#user-panel:not(.is-none) .user > .icon-chat-#role + .name, \#user-lists .user > .icon-chat-#role + .name, .cm.from-#role ~ .from {
                            color: #color !important;
                    }\n""" #ToDo add custom colors
                colorMap =
                    background: \#app
                    header: \.app-header
                    footer: \#footer
                for k, selector of colorMap when isColor(d.colors[k])
                    styles += "#selector { background-color: #{d.colors[k]} !important }\n"

            /*== CSS ==*/
            if d.css
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
                if isURL(d.images.background)
                    styles += "\#app { background-image: url(#{d.images.background}) }\n"
                if isURL(d.images.playback) and roomLoader? and Layout?
                    new Image
                        ..onload ->
                            @$playbackBackground .attr \src, d.images.playback
                            replace roomLoader, \frameHeight,   -> return ..height - 10px
                            replace roomLoader, \frameWidth,    -> return ..width  - 18px
                            roomLoader.onVideoResize Layout.getSize!
                            console.log "[roomTheme] loaded playback frame"
                        ..onerror ->
                            console.error "[roomTheme] failed to load playback frame"
                        ..src = d.images.playback
                    replace roomLoader, \src, -> return d.images.playback
                if isURL(d.images.booth)
                    styles += """
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
        if not skipDisables
            # copied from p0ne.module
            for [target, attr /*, repl*/] in @_cbs.replacements ||[]
                target[attr] = target["#{attr}_"]
            for style of @_cbs.css
                p0neCSS.css style, "/* disabled */"
            for url of @_cbs.loadedStyles
                p0neCSS.unloadStyle url
            delete [@_cbs.replacements, @_cbs.css, @_cbs.loadedStyles]

        if roomLoader? and Layout?
            roomLoader?.onVideoResize Layout.getSize!
        @$playbackBackground
            .attr \src, @$playbackBackground.data(\_o)

    disable: -> @clear true
