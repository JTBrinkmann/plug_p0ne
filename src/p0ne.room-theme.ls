/**
 * Room Settings module for plug_p0ne
 * made to be compatible with plugCubes Room Settings
 * so room hosts don't have to bother with mutliple formats
 * that also means, that a lot of inspiration came from and credits go to the PlugCubed team ♥
 *
 * for more information, see https://issue.plugcubed.net/wiki/Plug3%3ARS
 *
 * @author jtbrinkmann aka. Brinkie Pie
 * @license MIT License
 * @copyright (c) 2015 J.-T. Brinkmann
*/

/*####################################
#            ROOM SETTINGS           #
####################################*/
module \roomSettings, do
    require: <[ room ]>
    optional: <[ _$context ]>
    persistent: <[ _data _room ]>
    module: new DataEmitter(\roomSettings)

    _room: \dashboard
    setup: ({addListener}) !->
        @_update!
        if _$context?
            addListener _$context, \room:joining, @clear, this
            addListener _$context, \room:joined, @_update, this

    _update: !->
        roomslug = getRoomSlug!
        return if @_data and roomslug == @_room

        if not roomDescription = room.get \description #$ '#room-info .description .value' .text!
            console.warn "[p0ne] no p³ compatible Room Settings found"
        else if url = /@p3=(.*)/i .exec roomDescription
            console.log "[p0ne] p³ compatible Room Settings found", url.1
            $.getJSON proxify(url.1)
                .then (data) !~>
                    console.log "#{getTime!} [p0ne] loaded p³ compatible Room Settings"
                    @_room = roomslug
                    @set data
                .fail !->
                    chatWarn "cannot load Room Settings", "p0ne"

/*####################################
#             YELLOW MOD             #
####################################*/
module \yellowMod, do
    disabled: true
    setup: ({@css}) !->
        @update!
    update: !-> if not @disabled
        @css \yellowMod, "
            \#chat .fromID-#userID .un,
            .user[data-uid='#userID'] .name > span {
                color: #{customColors?.colors?.you || roomSettings?._data?.colors.chat.you || \#ffdd6f} !important;
            }
        "


/*####################################
#           CUSTOM  COLORS           #
####################################*/
window.ColorPicker = !!$.fn.ColorPicker
module \customColors, do
    displayName: "☢ Custom Colours"
    settings: \look&feel
    help: """
        Change colours of usernames, depending on their role.

        Note: some aggressive Room Themes might override custom colour settings from this module.
    """
    require: <[ yellowMod ColorPicker ]>
    _settings:
        global: {}
        perRoom: {}
    setup: ({@css, loadStyle}) !->
        loadStyle "#{p0ne.host}/vendor/colorpicker/css/colorpicker.css"

    roles:
        * displayName: 'You',              name: \you,        default: 0xffdd6f, regular: true, noIcon: true
        * displayName: 'Regular',          name: \regular,    default: 0xb0b0b0, regular: true, noIcon: true
        * displayName: 'Friend',           name: \friend,     default: 0xb0b0b0, regular: true, noIcon: true
        * displayName: 'Subscriber',       name: \subscriber, default: 0xc59840, regular: true
        * displayName: 'Resident DJ',      name: \dj,         default: 0xac76ff, staff: true
        * displayName: 'Bouncer',          name: \bouncer,    default: 0xac76ff, staff: true
        * displayName: 'Manager',          name: \manager,    default: 0xac76ff, staff: true
        #* displayName: 'Co-Host',          name: \co-host,    default: 0xac76ff, staff: true
        * displayName: '(Co-) Host',       name: \host,       default: 0xac76ff, staff: true
        * displayName: 'Brand Ambassador', name: \ambassador, default: 0x89be6c
        * displayName: 'Admin',            name: \admin,      default: 0x42a5dc

    settingsExtra: ($wrapper) !->
        #ToDo add custom icons
        #ToDo add icon colourizing (?)
        #   possibly via:
        #   - canvas + to BlobURI
        #   - canvas + to Base64
        #   - SVG
        #   - PHP
        #ToDo implement "Co-Host" class in ChatClasses
        #ToDo add custom colours for custom users
        cc = this
        @colors = @_settings.global with @_settings.perRoom[getRoomSlug!]

        visible = false
        $wrapper .append do
            $ \<button>
                .text "change custom colours"
                .click !~>
                    if visible
                        @$el.fadeOut!
                        visible := false
                    else
                        @$el.fadeIn!
                        visible := true

        @$el = $ '<div class=p0ne-cc-settings>'
            .hide!
            #.css do
            #    left: $ \.p0ne-settings .width!
            .appendTo $body

        # for simplicity, we only support setting global custom colours yet.
        #ToDo add perRoom settings
        scope = @_settings.global

        @rolesHashmap = {}
        i = @roles.length
        while role = @roles[--i]
            @rolesHashmap[role.name] = role
            if not c = scope[role.name] || roomTheme._data?.colors?.chat?[role.name]
                c = "##{role.default.toString(16)}"
                isDefault = true
            $ "
                <div data-role=#{role.name} class='
                        p0ne-cc-row from-#{role.name}
                        #{if role.staff then ' from-staff' else ''}
                        #{if scope[role.name] then '' else ' p0ne-cc-default'}'>
                    #{if role.noIcon then '' else '<i class=\'icon icon-chat-'+role.name+'\'></i>'}
                    <span class=name>#{role.displayName}</span>
                    <i class='icon icon-clear-input'></i>
                </div>
            "
                .css color: c
                .appendTo @$el

        var roleName, $row
        @$cp = $cp = $ \<div>
            .ColorPicker do
                onChange: (hsb, hex, rgb) !->
                    c = "##hex"
                    scope[roleName] = c
                    $row
                        .css color: c
                        .removeClass \p0ne-cc-default
                    cc.updateCSS!
        $cpDialog = $ "##{@$cp.data(\colorpickerId)}"

        @$el
            .on \click, \.icon-clear-input, !->
                $row = $ this .parent!
                name = $row .data \role
                $row
                    .css color: roomTheme._data?.colors?.chat?[name] || "##{cc.rolesHashmap[name].default.toString(16)}"
                    .addClass \p0ne-cc-default
                delete scope[name]
                cc.updateCSS!
                return false
            .on \click, \.p0ne-cc-row, !->
                $row := $ this
                roleName := $row .data \role
                $cp
                    .ColorPickerSetColor scope[roleName] || roomTheme._data?.colors?.chat?[roleName] || "##{cc.rolesHashmap[roleName].default.toString(16)}"
                    .ColorPickerShow!
                console.log "[colorpicker]", $cpDialog.0, $row.offset!
                offset = $row.offset!
                $cpDialog .css do
                    left: offset.left
                    top: offset.top + 24px;

        $ '<label class=p0ne-css-override-you><input type=checkbox class=checkbox> "You" overrides other rules</label>'
            .attr \checked, not yellowMod.disabled
            .appendTo @$el
            .find \input
                .on \click, (e) !->
                    console.log "[custom colors] force 'you' Override:", @checked
                    if @checked
                        yellowMod.enable!
                    else
                        yellowMod.disable!
        @updateCSS!

    updateCSS: !->
        styles = ""
        scope = @_settings.global
        for role in @roles when color = scope[role.name]
            name = role.name
            name = "regular.from-#name" if role.regularOnly
            styles += "/* #{role.name} => #color */\n"
            if not role.noIcon
                styles += """
                    \#app \#user-lists .icon-chat-#{role.name} + .name,
                    \#app \#waitlist .icon-chat-#{role.name} + span,
                    \#app \#user-rollover .icon-chat-#{role.name} + span,\n
                """
            styles += """
                \#app \#chat .from-#name#{if role.regularOnly then '.from-regular' else ''} .un,
                \#app .p0ne-name.#{role.name}#{if role.regularOnly then '.regular' else ''}
                {
                    color: #color !important;
                }\n
            """
        @css \customColors, styles
        yellowMod.update!
        #if roomTheme? and not roomTheme.disabled
        #    roomTheme.applyTheme roomSettings._data

    disable: !->
        if @$cp
            @$cp .ColorPickerHide!
            $ "##{@$cp.data(\colorpickerId)}" .remove!
            @$cp .remove!
        @$el?.remove!


/*####################################
#             ROOM THEME             #
####################################*/
module \roomTheme, do
    displayName: "Room Theme"
    require: <[ roomSettings ]>
    optional: <[ roomLoader ]>
    settings: \look&feel
    help: '''
        Applies the room theme, if this room has one.
        Room Settings and thus a Room Theme can be added by (co-) hosts of the room.
    '''
    setup: ({addListener, replace, css, loadStyle}) !->
        @$playbackBackground = $ '#playback .background img'
        @playbackBackgroundVanilla = @$playbackBackground .attr \src

        addListener roomSettings, \data, @applyTheme = (d) !~>
            console.log "#{getTime!} [roomTheme] loading theme"
            @clear d.images.background, false
            @_data = d
            cc = customColors?.colors ||{}
            styles = ""

            /*== colors ==*/
            if d.colors
                styles += "\n/*== colors ==*/\n"
                for role, color of d.colors.chat when isColor(color)
                    if role in <[ rdj residentdj ]>
                        role = \dj
                        d.colors.chat.dj = color
                    styles += """
                    /* #role => #color */
                    \#user-lists .icon-chat-#role + .name,
                    .from-#role .from, \#waitlist .icon-chat-#role + span,
                    \#user-rollover .icon-chat-#role + span, .p0ne-name.#role {
                            color: #color !important;
                    }\n"""
                    if role == \you
                        yellowMod?.update!
                    #ToDo @mention other colours
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
                        ..onload = !~>
                            @$playbackBackground .attr \src, d.images.playback
                            replace roomLoader, \frameHeight,   !-> return ..height - 10px
                            replace roomLoader, \frameWidth,    !-> return ..width  - 18px
                            roomLoader.onVideoResize Layout.getSize!
                            console.log "#{getTime!} [roomTheme] loaded playback frame"
                        ..onerror = !->
                            console.error "#{getTime!} [roomTheme] failed to load playback frame"
                        ..src = d.images.playback
                    replace roomLoader, \src, !-> return d.images.playback
                if isURL(d.images.booth)
                    styles += """
                        /* custom booth */
                        \#avatars-container::before {
                            background-image: url(#{d.images.booth});
                        }\n"""
                for role, url of d.images.icons
                    styles += """
                        .icon-chat-#role {
                            background-image: url(#url);
                            background-position: 0 0;
                        }\n"""
                    if role == \cohost
                        styles += """
                            .from-cohost .icon-chat-host { /* cohost icon fix */
                                background-image: url(#url);
                                background-position: 0 0;
                            }\n"""

            /*== text ==*/
            if d.text
                for key, text of d.text.plugDJ
                    for lang of Lang[key]
                        replace Lang[key], lang, !-> return text

            css \roomTheme, styles
            yellowMod.update!
            @styles = styles

        addListener roomSettings, \cleared, @clear, this

    clear: (resetBackground, skipDisables) !->
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
        if resetBackground and @$playbackBackground
            @$playbackBackground
                .one \load !->
                    roomLoader?.onVideoResize Layout.getSize! if Layout?
                .attr \src, @playbackBackgroundVanilla

    disable: !->
        @clear true, true
        @_data = {}
