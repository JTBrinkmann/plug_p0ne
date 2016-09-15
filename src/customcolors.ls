#DEBUG
window.clear = (obj) !-> for k of obj then delete obj[k]

requireHelper \SuggestionView, (.::?id == \chat-suggestion)

if not window.staff
    staff =
        loading: $.Deferred!
    ajax \GET, \staff, (d) !->
        l = staff .loading
        staff := {}
        for u in d when u.username
            staff[u.id] = u{role, gRole, sub, username, badge}
        l.resolve!

if not window.colorPicker
    colorPicker = {}

/*####################################
#           CUSTOM  COLORS           #
####################################*/
module \customColors, do
    displayName: "☢ Custom Colours"
    settings: \look&feel
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
        you:        color: \#ffdd6f, test: (.id == userID)
        regular:    color: \#777f92, icon: false, test: (.role == 0)
        friend:     test: (.friend)
        subscriber: color: \#c59840, icon: \icon-chat-subscriber, test: (.sub)
        dj:         color: \#ac76ff, icon: \icon-chat-dj, perRoom: true, test: (.role == 1)
        bouncer:    color: \#ac76ff, icon: \icon-chat-bouncer, perRoom: true, test: (.role == 2)
        manager:    color: \#ac76ff, icon: \icon-chat-manager, perRoom: true, test: (.role == 3)
        cohost:     color: \#ac76ff, icon: \icon-chat-host, perRoom: true, test: (.role == 4)
        host:       color: \#ac76ff, icon: \icon-chat-host, perRoom: true, test: (.role == 5)
        ambassador: color: \#89be6c, icon: \icon-chat-ambassador, test: (u) !-> return 0 < u.gRole < 5
        admin:      color: \#42a5dc, icon: \icon-chat-admin, test: (.gRole == 5)
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

    setup: ({@css, loadStyle, @addListener}) !->
        loadStyle "#{p0ne.host}/playground/customcolors.css"
        @scopes.vanilla = @roles
        @scopes.globalCustomRole = @_settings.global.roles
        @scopes.globalCustomUser = @_settings.global.users
        do @addListener _$context, \room:joined, ~>
            @room = @_settings.perRoom[slug = getRoomSlug!] ||= {userRole: {}, users: {}, roles: {}}
            #@scopes.roomCustomUser = @room.users
            #@scopes.roomCustomRole = @room.roles
            @scopes.roomThemeRole = {}
            @scopes.roomThemeUser = {}

        # loading custom CSS
        for role, style of @roles
            #style.role = role
            @roles[role].css = @calcCSSRole(role)
        for uid of @users
            @users[uid] = @calcCSSUser(uid)


        @updateCSS!



    updateCSS: !->
        styles = ""
        for key, data of @roles when key != colorPicker.key
            styles += data.css
        for key, data of @users when key != colorPicker.key
            styles += data.css

        @css \customColors, styles

    calcCSSRole: (roleName, style) !->
        #name = "regular.from-#roleName" if role.regularOnly
        style ||= @getRoleStyle(roleName, true)
        styles = "/*= #{roleName} =*/"
        role = @roles[roleName]
        if style.color or style.font
            font = style.font ||{}
            if role.icon
                styles += "
                    \#app \#user-lists .#{role.icon} + .name,
                    \#app \#waitlist .#{role.icon} + span,
                    \#app \#user-rollover .#{role.icon} + span,
                "
            styles += "
                \#app \#chat .from-#roleName .un,
                \#app .p0ne-name.#roleName {
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
        styles = "/*= #{uid} (#{@_settings.users[uid]}) =*/"

        if style.color
            font = style.font ||{}
            styles += "
                \#app \#chat .fromID-#uid .un,
                \#app .p0ne-uid-#uid .p0ne-name {
                    color: #{style.color};
                    #{if not font.b then 'font-weight: normal;' else ''}
                    #{if font.i then 'font-style: italic;' else ''}
                    #{if font.u then 'text-decoration: underline;' else ''}
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


export cc = customColors
<- (fn) -> if cc.loading then cc.loading.then fn else fn!
customColors_test?.disable!.enable!