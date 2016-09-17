/**
 * Custom Colors module for plug_p0ne
 *
 * @author jtbrinkmann aka. Brinkie Pie
 * @license MIT License
 * @copyright (c) 2015 J.-T. Brinkmann
*/
console.log "~~~~~~~ p0ne.customcolors.picker ~~~~~~~"
if not window.staff
    staff =
        loading: $.Deferred!
    ajax \GET, \staff, (d) !->
        l = staff .loading
        staff := {}
        for u in d when u.username
            staff[u.id] = u{role, gRole, sub, username, badge}
        l.resolve!

/*####################################
#           CUSTOM  COLORS           #
####################################*/
module \customColors, do
    displayName: "☢ Custom Colours"
    settings: \look&feel
    settingsSimple: true
    help: """
        Change colours of usernames, depending on their role.

        Note: some aggressive Room Themes might override custom colour settings from this module.
    """
    CLEAR_USER_CACHE: 14days * 24.h
    _settings:
        rolesOrder: <[ admin ambassador host cohost manager bouncer dj subscriber you friend regular ]>
        global: {users: {}, roles: {}}
        perRoom: {}
        /*  <slug>:
                userRole: {}
                    <uid>: 0
                users: {}, roles: {}
        */

        users: {}
        /*  <uid>:
                username: "…"
                defaultBadge: "…"
                gRole: 0
                roles: <[ … … ]> # e.g. friend, subscriber, BA
                lastUsed: new Date(…)
            */

    roles:
        /*<role>:
            color: "…"
            icon: "…"
            perRoom: false
            test: !-> …
            css: "…" # cache
        */
        you:        color: \#FFDD6F, test: (.id == userID)
        regular:    color: \#777F92, icon: false, test: (.role == 0)
        friend:     color: \#777F92, test: (.friend)
        subscriber: color: \#C59840, icon: \icon-chat-subscriber, test: (.sub)
        dj:         color: \#AC76FF, icon: \icon-chat-dj, perRoom: true, test: (.role == 1)
        bouncer:    color: \#AC76FF, icon: \icon-chat-bouncer, perRoom: true, test: (.role == 2)
        manager:    color: \#AC76FF, icon: \icon-chat-manager, perRoom: true, test: (.role == 3)
        cohost:     color: \#AC76FF, icon: \icon-chat-host, perRoom: true, test: (.role == 4)
        host:       color: \#AC76FF, icon: \icon-chat-host, perRoom: true, test: (.role == 5)
        ambassador: color: \#89BE6C, icon: \icon-chat-ambassador, test: (u) !-> return 0 < u.gRole < 5
        admin:      color: \#42A5DC, icon: \icon-chat-admin, test: (.gRole == 5)
    users: {}
    /*    <uid>:
            css: "…" # cache
        */


    scopes: {}
    #    vanilla: @roles
    #    roomTheme: {}
    #    customRoom: @_settings.perRoom[slug]
    #    customGlobal: @_settings.global
    scopeOrderRole: <[ globalCustomRole roomThemeRole vanilla ]>
    scopeOrderUser: <[ globalCustomUser roomThemeUser ]>

    setup: ({@css, @addListener}) !->
        @users = {}
        @scopes.vanilla = @roles
        @scopes.globalCustomRole = @_settings.global.roles
        @scopes.globalCustomUser = @_settings.global.users
        do @addListener _$context, \room:joined, ~>
            slug = getRoomSlug!
            @room = @_settings.perRoom[slug] ||= {
                userRole: {}, users: {}, roles: {}
            }
            #@scopes.roomCustomUser = @room.users
            #@scopes.roomCustomRole = @room.roles
            @scopes.roomThemeRole = {}
            @scopes.roomThemeUser = {}

        # loading custom CSS
        for role, style of @roles
            #style.role = role
            @roles[role].css = @calcCSSRole(role)
        for uid of @scopes.globalCustomUser
            @users[uid] = css: @calcCSSUser(uid)

        @updateCSS!

        # clear user cache
        d = Date.now! - @CLEAR_USER_CACHE
        for uid, u of @_settings.users when not @users[uid] and u.lastUsed < d
            console.log "[customColors] removing #{u.id} (#{u.username}) from cache"
            delete @_settings.users[uid]

    settingsPanel: ($wrapper) !->
        $wrapper .text "loading…"
        loadModule \customColorsPicker, "#{p0ne.host}/scripts/p0ne.customcolors.picker.js?r=1"
            .then (ccp) !~>
                console.log "[ccp]", ccp
                ccp.disable!.enable!

    updateCSS: !->
        ccp = p0ne.modules.customColorsPicker
        if ccp and not ccp.disabled
            cpKey = "#{ccp.key}"
        styles = ""
        for key, data of @roles when key != cpKey
            styles += data.css
        for key, data of @users when key != cpKey
            styles += data.css

        @css \customColors, styles

    calcCSSRole: (roleName, style) !->
        #name = "regular.from-#roleName" if role.regularOnly
        style ||= @getRoleStyle(roleName, true)
        styles = "/*= #{roleName} =*/"
        role = @roles[roleName]
        if style.color or style.font
            font = style.font ||{+b}
            if role.icon
                styles += "
                    \#app \#user-lists .#{role.icon} + .name,
                    \#app \#waitlist .#{role.icon} + span,
                    \#app \#user-rollover .#{role.icon} + span,
                "
            if roleName != \regular
                styles += "\#app .p0ne-name.#roleName,"
            styles += "
                \#app \#chat .from-#roleName .un {
                    color: #{style.color};
                    #{if not font.b then 'font-weight: normal;' else ''}
                    #{if font.i then 'font-style: italic;' else ''}
                    #{if font.u then 'text-decoration: underline;' else ''}
                }
            "

        if style.icon
            if role.icon and style.icon != role.icon
                if typeof style.icon == \string
                    icon = getIcon style.icon, true
                else
                    icon = style.icon
                styles += "
                    \#app \#user-lists .#{role.icon},
                    \#app \#waitlist .#{role.icon},
                    \#app \#user-rollover .#{role.icon},
                    .p0ne-name .#{role.icon},
                    \#chat .from-#roleName .#{role.icon} {
                        background: url(#{icon.url}) #{-icon.x}px #{-icon.y}px
                    }
                "
            #else
                #TODO

        return "#styles"

    calcCSSUser: (uid, style) !->
        style ||= @getUserStyle(uid)
        styles = "/*= #{uid} (#{@_settings.users[uid].username}) =*/"

        if style.color
            color = "color: #{style.color};"
        if style.font
            font = "
                    #{if not style.font.b then 'font-weight: normal;' else ''}
                    #{if style.font.i then 'font-style: italic;' else ''}
                    #{if style.font.u then 'text-decoration: underline;' else ''}
            "
        if color || font
            styles += "
                \#app \#chat .fromID-#uid .un,
                \#app .p0ne-uid-#uid .p0ne-name .name {
                    #{color ||''}
                    #{font  ||''}
                }
            "

        if style.icon
            styles += "
                .p0ne-uid-#uid .icon:first-of-type,
                \#chat .fromID-#uid .icon:last-of-type {
                    background: url(#{style.icon.url}) #{-style.icon.x}px #{-style.icon.y}px
                }
            "

        if bdg = style.badge
            styles += "
                .p0ne-uid-#uid .bdg,
                .fromID-#uid .bdg {
                    background: url(#{bdg.url}) #{-30px * bdg.x / bdg.w}px #{-30px * bdg.y / bdg.h}px / #{bdg.srcW*30px/bdg.w ||30}px #{bdg.srcH*30px/bdg.h ||30}px
                }
            "

        return "#styles\n"

    getRoleStyle: (roleName, includeVanilla) !->
        res = {}
        if includeVanilla
            scopes = @scopeOrderRole
        else
            scopes = @scopeOrderRole.slice(0, @scopeOrderRole.length - 1) # excluding Vanilla

        for scopeName in scopes
            for k,v of @scopes[scopeName][roleName] when k not of res
                res[k] = v
        return res

    getUserStyle: (uid, includeVanilla) !->
        res = {}
        for scopeName in @scopeOrderUser
            for k,v of @scopes[scopeName][uid] when k not of res
                res[k] = v

        if includeVanilla
            for roleName in @getRoles(uid)
                for k,v of @getRoleStyle(roleName, true) when k not of res
                    res[k] = v
            res.badge ||= getUser(uid)?.badge || @_settings.users[uid]?.defaultBadge
            res.font ||= {+b, -i, -u}
        return res

    getRoles: (uid, user) ->
        if getUser(uid)
            [role for role in @_settings.rolesOrder when @roles[role].test(that)]
        else if @_settings.users[uid]
            roomRole = getRank(role: that, true) if @room.userRole[uid] || staff[uid]?.role
            [role for role in @_settings.rolesOrder when role in @_settings.users[uid].roles or role == roomRole]
        else
            []

#export cc = customColors
#<- (fn) -> if cc.loading then cc.loading.then fn else fn!
#customColors_test?.disable!.enable!