/**
 * plug_p0ne Custom Avatars
 * adds custom avatars to plug.dj when connected to a plug_p0ne Custom Avatar Server (ppCAS)
 *
 * @author jtbrinkmann aka. Brinkie Pie
 * @license MIT License
 * @copyright (c) 2015 J.-T. Brinkmann
 *
 * Developer's note: if you create your own custom avatar script or use a modified version of this,
 * you are hereby granted permission connect to this one's default avatar server.
 * However, please drop me an e-mail so I can keep an overview of things.
 * I remain the right to revoke this right anytime.
 */
console.log "~~~~~~~ p0ne.avatars ~~~~~~~"

/* THIS IS A TESTING VERSION! SOME THINGS ARE NOT IMPLEMENTED YET! */
/* (this includes things mentioned in the "notes" section below) */
#== custom Avatars ==
#ToDo:
# - check if the "lost connection to server" warning works as expected (only warn on previous successfull connection)
# - improve hitArea (e.g. audience.drawHitArea)
# - avatar creator / viewer
#   - https://github.com/buzzfeed/libgif-js

/*
Notes for Socket Servers:
- server-side:
    - push avatars using something like `socket.trigger('addAvatar', …)`
    - remember, you can offer specific avatars that are for moderators only
    - for people without a role, please do NOT allow avatars that might be confused with staff avatars (e.g. the (old) admin avatars)
        => to avoid confusion
    - dynamically loading avatars is possible
        - e.g. allow users customizing avatars and add them with addAvatar()
            with unique IDs and a URL to a PHP site that generates the avatar
        - WARNING: I HIGHLY discourage from allowing users to set their own images as avatars
            There's ALWAYS "this one guy" who abuses it.
            And most people don't want a bunch of dancing dicks on their screen
- client-side (custom scripts)
    - when listening to userJoins, please use API.on(API.USER_JOIN, …) to avoid conflicts
    - add avatars using addAvatar(…)
    - do not access p0ne._avatars directly, do avoid conflicts and bugs!
    - if you however STILL manually change something, you might need to do updateAvatarStore() to update it
*/

# Hotfix for missing SockJS
#ToDo set up a proper WebSocket ppCAS server xD
if not window.SockJS
    window.Socket = window.WebSocket
    require.config do
        paths:
            sockjs: "#{p0ne.host}/scripts/sockjs"
console.time("[p0ne custom avatars] loaded SockJS")
require <[ sockjs ]>, (SockJS) !->
    console.timeEnd "[p0ne custom avatars] loaded SockJS"
    # users
    if not window.p0ne
        requireHelper \users, (it) !->
            return it.models?.0?.attributes.avatarID
                and \isTheUserPlaying not of it
                and \lastFilter not of it
        window.userID ||= API.getUser!.id
        window.user_ ||= users.get(userID) if users?
        #=======================


        # auxiliaries
        window.sleep ||= (delay, fn) !-> return setTimeout fn, delay

        requireHelper \InventoryDropdown, (.selected)
        requireHelper \avatarAuxiliaries, (.getAvatarUrl)
        requireHelper \Avatar, (.AUDIENCE)
        #requireHelper \AvatarList, (._byId?.admin01)
        for ev in user_?._events?[\change:avatarID] ||[] when ev.ctx.comparator == \id
            window.myAvatars = ev.ctx
            break

        if requireHelper \InventoryAvatarPage, ((a) -> a::?.className == 'avatars' && a::eventName)
            window.InventoryDropdown = new InventoryAvatarPage().dropDown.constructor

    window.Lang = require \lang/Lang

    window.Cells = requireAll (m) !-> return m::?.className == \cell and m::getBlinkFrame


    /*####################################
    #           CUSTOM AVATARS           #
    ####################################*/
    user.avatarID = API.getUser!.avatarID
    module \customAvatars, do
        require: <[ users Lang avatarAuxiliaries Avatar myAvatars InventoryDropdown ]>
        optional: <[ user_ _$context ]>
        displayName: 'Custom Avatars'
        settings: \base
        settingsSimple: true
        disabled: true
        help: '''
            This adds a few custom avatars to plug.dj

            You can select them like any other avatar, by clicking on your username (below the chat) and then clicking "My Stuff".
            Click on the Dropdown field in the top-left to select another category.

            Everyone who uses plug_p0ne sees you with your custom avatar.
        '''
        persistent: <[ socket ]>
        _settings:
            vanillaAvatarID: user.avatarID
            avatarID: user.avatarID
        DEFAULT_SERVER: 'https://ppcas.p0ne.com/_'
        setup: ({addListener, @replace, revert, css, addCommand}, customAvatars) !->
            console.info "[p0ne custom avatars] initializing"

            p0ne._avatars = {}

            avatarID = API.getUser!.avatarID
            if @hasNewAvatar = (@_settings.vanillaAvatarID and @_settings.vanillaAvatarID != avatarID)
                @_settings.vanillaAvatarID = avatarID

            # - display custom avatars
            replace avatarAuxiliaries, \getAvatarUrl, (gAU_) !-> return (avatarID, type) !->
                return p0ne._avatars[avatarID]?[type] || gAU_(avatarID, type)
            getAvatarUrl_ = avatarAuxiliaries.getAvatarUrl_
            #replace avatarAuxiliaries, \getHitSlot, (gHS_) !-> return (avatarID) !->
            #    return customAvatarManifest.getHitSlot(avatarID) || gHS_(avatarID)
            #ToDo


            #== AUXILIARIES ==
            # - set avatarID to custom value
            _internal_addAvatar = (d) !->
                # d =~ {category, thumbOffsetTop, thumbOffsetLeft, base_url, anim, dj, b, permissions}
                #   soon also {h, w, standingLength, standingDuration, standingFn, dancingLength, dancingFn}
                avatarID = d.avatarID
                /*if p0ne._avatars[avatarID]
                    console.info "[p0ne custom avatars] updating '#avatarID'", d
                else if not d.isVanilla
                    console.info "[p0ne custom avatars] adding '#avatarID'", d*/

                avatar =
                    inInventory: false
                    category: d.category || \p0ne
                    thumbOffsetTop: d.thumbOffsetTop
                    thumbOffsetLeft: d.thumbOffsetLeft
                    isVanilla: !!d.isVanilla
                    permissions: d.permissions || 0
                    #h: d.h || 150px
                    #w: d.w || 150px
                    #standingLength: d.standingLength || 4frames
                    #standingDuration: d.standingDuration || 20frames
                    #standingFn: if typeof d.standingFn == \function then d.standingFn
                    #dancingLength: d.dancingLength || 20frames
                    #dancingFn: if typeof d.dancingFn == \function then d.dancingFn

                #avatar.sw = avatar.w * (avatar.standingLength + avatar.dancingLength) # sw is SourceWidth
                if d.isVanilla
                    avatar."" = getAvatarUrl_(avatarID, "")
                    avatar.dj = getAvatarUrl_(avatarID, \dj)
                    avatar.b = getAvatarUrl_(avatarID, \b)
                else
                    base_url = d.base_url || ""
                    avatar."" = base_url + (d.anim || avatarID+'.png')
                    avatar.dj = base_url + (d.dj || avatarID+'dj.png')
                    avatar.b = base_url + (d.b || avatarID+'b.png')
                p0ne._avatars[avatarID] = avatar
                if avatar.category not of Lang.userAvatars
                    Lang.userAvatars[avatar.category] = avatar.category
                #p0ne._myAvatars[*] = avatar

                delete Avatar.IMAGES["#{avatarID}"] # delete image cache
                delete Avatar.IMAGES["#{avatarID}dj"] # delete image cache
                delete Avatar.IMAGES["#{avatarID}b"] # delete image cache
                #for avi in audience.images when avi.avatarID == avatarID
                #   #ToDo
                if not customAvatars.updateAvatarStore.loading
                    customAvatars.updateAvatarStore.loading = true
                    requestAnimationFrame !-> # throttle to avoid updating every time when avatars get added in bulk
                        customAvatars.updateAvatarStore!
                        customAvatars.updateAvatarStore.loading = false

            @addAvatar = (avatarID, d) !->
                # d =~ {h, w, standingLength, standingDuration, standingFn, dancingLength, dancingFn, url: {base_url, "", dj, b}}
                if typeof d == \object
                    avatar = d
                    d.avatarID = avatarID
                else if typeof avatarID == \object
                    avatar = avatarID
                else
                    throw new TypeError "invalid avatar data passed to addAvatar(avatarID*, data)"
                d.isVanilla = false
                return _internal_addAvatar d
            @removeAvatar = (avatarID, replace) !->
                for u in users.models
                    if u.get(\avatarID) == avatarID and vaID = u.get(\vanillaAvatarID)
                        u.set(\avatarID, vaID)
                delete p0ne._avatars[avatarID]



            # - set avatarID to custom value
            @changeAvatar = (uid, avatarID) !~>
                if not (u = users.get(uid)) or not (avatar = p0ne._avatars[avatarID]) and not (avatarID = u.get \vanillaAvatarID)
                    console.warn "[p0ne custom avatars] can't load user or avatar: '#uid', '#avatarID'"
                    return


                if not avatar.permissions or API.hasPermissions(uid, avatar.permissions)
                    if not u.get \vanillaAvatarID
                        u.set \vanillaAvatarID, u.get(\avatarID)
                    u.set \avatarID, avatarID
                else
                    console.warn "user with ID #uid doesn't have permissions for avatar '#{avatarID}'"

                if uid == userID
                    if p0ne._avatars[avatarID]?.isVanilla
                        @_settings.vanillaAvatarID = avatarID
                    @_settings.avatarID = avatarID

            @updateAvatarStore = !->
                # update thumbs
                styles = ""
                avatarIDs = []; l=0
                for avatarID, avi of p0ne._avatars when not avi.isVanilla
                    avatarIDs[l++] = avatarID
                    styles += "
                        .avi-#avatarID {
                            background-image: url('#{avi['']}');
                            background-position: #{avi.thumbOffsetLeft ||0}px #{avi.thumbOffsetTop ||0}px"
                    styles += "}\n"
                if l
                    css \p0ne_avatars, "
                        .avi {
                            background-repeat: no-repeat;
                        }\n
                        .thumb.small .avi-#{avatarIDs.join(', .thumb.small .avi-')} {
                            background-size: 1393px; /* = 836/15*24 thumbsWidth / thumbsCount * animCount*/
                        }\n
                        .thumb.medium .avi-#{avatarIDs.join(', .thumb.medium .avi-')} {
                            background-size: 1784px; /* = 1115/15*24 thumbsWidth / thumbsCount * animCount*/
                        }\n
                        #styles
                    "

                # update store
                vanilla = []; l=0
                categories = {}
                for avatarID, avi of p0ne._avatars when avi.inInventory /*TEMP FIX*/ or not avi.isVanilla
                    # the `or not avi.isVanilla` should be removed as soon as the server is fixed
                    if avi.isVanilla
                        # add vanilla avatars later to have custom avatars in the top
                        vanilla[l++] = new Avatar(id: avatarID, category: avi.category, type: \avatar)
                    else
                        categories[][avi.category][*] = avatarID
                myAvatars.models = [] #.splice 0 # empty it
                l = 0
                for category, avis of categories
                    for avatarID in avis
                        myAvatars.models[l++] = new Avatar(id: avatarID, category: category, type: \avatar)
                myAvatars.models ++= vanilla
                myAvatars.length = myAvatars.models.length
                myAvatars.trigger \reset, false
                console.log "#{getTime!} [p0ne custom avatars] avatar inventory updated"
                return true

            #== Event Listeners ==
            addListener myAvatars, \reset, (vanillaTrigger) !~>
                @updateAvatarStore! if vanillaTrigger

            #== patch avatar inventory view ==
            replace InventoryDropdown::, \draw, (d_) !-> return !->
                html = ""
                categories = {}
                curAvatarID = API.getUser!.avatarID
                for avi in myAvatars.models
                    categories[avi.get \category] = true
                    if avi.id == curAvatarID
                        curCategory = avi.get \category
                curCategory ||= myAvatars.models.0?.get \category

                for category of categories
                    html += "
                        <div class=row data-value='#category'><span>#{Lang.userAvatars[category]}</span></div>
                    "

                @$el
                    .html "
                        <dl class=dropdown>
                            <dt><span></span><i class='icon icon-arrow-down-grey'></i><i class='icon icon-arrow-up-grey'></i></dt>
                            <dd>#html</dd>
                        </dl>
                    "
                    .on \click, \dt,   @~onBaseClick
                    .on \click, \.row, @~onRowClick
                InventoryDropdown.selected = curCategory if not categories[InventoryDropdown.selected]
                @select InventoryDropdown.selected

                @$el.show!


            Lang.userAvatars.p0ne = "Custom Avatars"

            #== add vanilla avatars ==
            /*for {id:avatarID, attributes:{category}} in AvatarList.models
                _internal_addAvatar do
                    avatarID: avatarID
                    isVanilla: true
                    category: category
                    #category: avatarID.replace /\d+$/, ''
                    #category: avatarID.substr(0,avatarID.length-2) damn you "tastycat"
            console.log "[p0ne custom avatars] added internal avatars", p0ne._avatars
            */

            #== patch Avatar Selection ==
            var $vanillaAvatarCell
            for Cell in window.Cells
                # highlight the user's vanilla avatar (if the user has a custom avatar)
                replace Cell::, \render, (r_) !-> return !->
                    r_.call this
                    if customAvatars._settings.avatarID != customAvatars._settings.vanillaAvatarID and customAvatars._settings.vanillaAvatarID == @model.get \id
                        $vanillaAvatarCell := $ "<div class=p0ne-vanilla-avatar-highlight>your vanilla avatar</div>"
                            .appendTo(@$el .find \.top)

                # propagate custom avatar selection to ppCAS
                replace Cell::, \onClick, (oC_) !-> return !->
                    #console.log "[p0ne custom avatars] Avatar Cell click", this
                    avatarID = @model.get \id
                    if not p0ne._avatars[avatarID] or p0ne._avatars[avatarID].inInventory
                        # if avatatar is in the Inventory or not bought, properly select it
                        oC_ ...
                        user_.set \vanillaAvatarID, customAvatars._settings.vanillaAvatarID=avatarID
                        customAvatars.socket? .emit \changeAvatarID, null
                    else
                        # if not, hax-apply it
                        customAvatars.changeAvatar(userID, avatarID)
                        customAvatars.socket? .emit \changeAvatarID, avatarID
                        @onSelected!

            addListener user_, \change:vanillaAvatarID, (user_, newAvatarID) !->
                $vanillaAvatarCell? .remove!
                if view = app?.user.view?.view
                    for cell in view.cells ||[] when cell.model.id == newAvatarID
                        $vanillaAvatarCell := $ "<div class=p0ne-vanilla-avatar-highlight>your vanilla avatar</div>"
                            .appendTo(cell.$el .find \.top)
                        break
            user_.set \vanillaAvatarID, @_settings.vanillaAvatarID

            #- get avatars in inventory -
            $.ajax do
                url: '/_/store/inventory/avatars'
                success: (d) !~>
                    for avatar in d.data
                        if not p0ne._avatars[avatar.id]
                            _internal_addAvatar do
                                avatarID: avatar.id
                                isVanilla: true
                                category: avatar.category
                        p0ne._avatars[avatar.id] .inInventory = true
                    @updateAvatarStore!





            #== fix avatar after reset on socket reconnect ==
            # the order is usually the following:
            # sjs:reconnected, socket:ack, ack, UserEvent:me, RoomEvent:state, change:avatarID (and just about every other user attribute), UserEvent:friends, room:joined, CustomRoomEvent:custom
            # we patch the user_.set after the ack and revert it on the UserEvent:friends. Between those two, the avatar cannot be reverted to the vanilla one, as it's most likely plug automatically doing that
            if _$context? and user_?
                addListener _$context, \ack, !->
                    replace user_, \set, (s_) !-> return (obj, val) !->
                        if obj.avatarID and obj.avatarID == @.get \vanillaAvatarID
                            delete obj.avatarID
                        return s_.call this, obj, val
                addListener _$context, \UserEvent:friends, !->
                    revert user_, \set


            /*####################################
            #         ppCAS Integration          #
            ####################################*/
            @oldBlurb = API.getUser!.blurb
            @blurbIsChanged = false

            urlParser = document.createElement \a
            addCommand \ppcas, do
                description: 'changes the plug_p0ne Custom Avatar Server ("ppCAS")'
                callback: (str) !~>
                    server = $.trim str.substr(6)
                    if server == "<url>"
                        chatWarn "hahaha, no. You have to replace '<url>' with an actual URL of a ppCAS server, otherwise it won't work.", "p0ne avatars"
                        return
                    else if server == \default
                        server = @DEFAULT_SERVER
                    else if server == \reconnect
                        server = @socket?.url || @DEFAULT_SERVER
                        forceReconnect = true
                    else if server.length == 0
                        chatWarn "Use `/ppCAS <url>` to connect to a plug_p0ne Custom Avatar Server. Use `/ppCAS default` to connect to the default server again. or `/ppCAS reconnect` to force-reconnect to the current server", "p0ne avatars"
                        return
                    urlParser.href = server
                    if urlParser.host != location.host
                        console.log "#{getTime!} [p0ne custom avatars] connecting to", server
                        @connect server, forceReconnect
                    else
                        console.warn "#{getTime!} [p0ne custom avatars] invalid ppCAS server"
            # END /ppCAS command

            @connect(@DEFAULT_SERVER)


        connectAttemps: 1
        connect: (url, reconnecting, reconnectWarning) !->
            if not reconnecting and @socket
                return if url == @socket.url and @socket.readyState == 1
                @socket.close!
            console.log "[p0ne custom avatars] using socket as ppCAS avatar server"
            reconnect = true

            #if reconnectWarning
            #    sleep 10_000ms, !~> if @connectAttemps==0
            #        chatWarn "lost connection to avatar server \xa0 =(", "p0ne avatars"

            _$context.trigger \ppCAS:connecting
            API.trigger \ppCAS:connecting
            @socket = new SockJS(url)
            @socket.url = url
            @socket.on = @socket.addEventListener
            @socket.off = @socket.removeEventListener
            @socket.once = (type, callback) !-> @on type, !-> @off(type, callback); callback ...
            @socket.emit = (type, ...data) !->
                console.log "#{getTime!} [ppCAS] > [#type]", data
                @send JSON.stringify {type, data}

            @socket.trigger = (type, args) !->
                args = [args] if typeof args != \object or not args?.length
                listeners = @_listeners[type]
                if listeners
                    for fn in listeners
                        fn .apply this, args
                else
                    console.error "#{getTime!} [ppCAS] unknown event '#type'"

            @socket.onmessage = ({data: message}) !~>
                try
                    {type, data} = JSON.parse(message)
                    console.log "#{getTime!} [ppCAS] < [#type]", data
                catch e
                    console.warn "#{getTime!} [ppCAS] invalid message received", message, e
                    return

                @socket.trigger type, data

            close_ = @socket.close
            @socket.close = !->
                @trigger \close
                close_ ...

            # replace old authTokens
            user = API.getUser!
            oldBlurb = user.blurb || ""
            newBlurb = oldBlurb .replace /🐎\w{6}/g, '' # THIS SHOULD BE KEPT IN SYNC WITH ppCAS' AUTH_TOKEN GENERATION
            if oldBlurb != newBlurb
                @changeBlurb newBlurb, do
                    success: !~>
                        console.info "#{getTime!} [ppCAS] removed old authToken from user blurb"

            @socket.on \authToken, (authToken) !~>
                user = API.getUser!
                @oldBlurb = user.blurb || ""
                if not user.blurb # user.blurb is actually `null` by default, not ""
                    newBlurb = authToken
                else if user.blurb.length >= 72
                    newBlurb = "#{user.blurb.substr(0, 71)}… 🐎#authToken"
                else
                    newBlurb = "#{user.blurb} 🐎#authToken"

                @blurbIsChanged = true
                @changeBlurb newBlurb, do
                    success: !~>
                        @blurbIsChanged = false
                        @socket.emit \auth, userID
                    error: !~>
                        console.error "#{getTime!} [ppCAS] failed to authenticate by changing the blurb."
                        @changeBlurb @oldBlurb, success: !->
                            console.info "#{getTime!} [ppCAS] blurb reset."

            @socket.on \authAccepted, !~>
                @connectAttemps := 0
                reconnecting := false
                @changeBlurb @oldBlurb, do
                    success: !~>
                        @blurbIsChanged = false
                    error: !~>
                        chatWarn "failed to authenticate to avatar server, maybe plug.dj is down or changed it's API?", "p0ne avatars"
                        @changeBlurb @oldBlurb, error: !->
                            console.error "#{getTime!} [ppCAS] failed to reset the blurb."
            @socket.on \authDenied, !~>
                console.warn "#{getTime!} [ppCAS] authDenied"
                chatWarn "authentification failed", "p0ne avatars"
                @changeBlurb @oldBlurb, do
                    success: !~>
                        @blurbIsChanged = false
                    error: !~>
                        @changeBlurb @oldBlurb, error: !->
                            console.error "#{getTime!} [ppCAS] failed to reset the blurb."
                chatWarn "Failed to authenticate with user id '#userID'", "p0ne avatars"

            @socket.on \avatars, (avatars) !~>
                user = API.getUser!
                @socket.avatars = avatars
                for avatarID, avatar of avatars
                    @addAvatar avatarID, avatar

                if @_settings.avatarID of avatars
                    @changeAvatar userID, @_settings.avatarID
                    @socket.emit \changeAvatarID, @_settings.avatarID
                /*else if not @hasNewAvatar and @_settings.avatarID of avatars
                    @socket.emit \changeAvatarID, @_settings.avatarID*/
                requestAnimationFrame initUsers if @socket.users

            @socket.on \users, (users) !~>
                @socket.users = users
                requestAnimationFrame initUsers if @socket.avatars

            # initUsers() is used by @socket.on \users and @socket.on \avatars
            ~function initUsers avatarID
                for userID, avatarID of @socket.users
                    #console.log "#{getTime!} [ppCAS] change other's avatar", userID, "(#{users.get userID ?.get \username})", avatarID
                    @changeAvatar userID, avatarID
                if reconnecting
                    chatWarn "reconnected", "p0ne avatars"
                _$context.trigger \ppCAS:connected
                API.trigger \ppCAS:connected
            @socket.on \changeAvatarID, (userID, avatarID) !~>
                console.log "#{getTime!} [ppCAS] change other's avatar:", userID, avatarID

                #users.get userID ?.set \avatarID, avatarID
                @changeAvatar userID, avatarID

            @socket.on \disconnect, (userID) !~>
                console.log "#{getTime!} [ppCAS] user disconnected:", userID
                @changeAvatarID userID, avatarID

            @socket.on \disconnected, (reason) !~>
                @socket.trigger \close, reason
            @socket.onclose = (e) !~>
                reconnect := false
                console.warn "#{getTime!} [ppCAS] DISCONNECTED", e
                _$context.trigger \ppCAS:disconnected
                API.trigger \ppCAS:disconnected
                /*if e.wasClean
                    reconnect := false
                else*/ if reconnect and not @disabled
                    if @connectAttemps < 90
                        timeout = ~~((5_000ms + Math.random!*5_000ms)*@connectAttemps*@connectAttemps)
                    else
                        timeout = 15.min
                    console.info "#{getTime!} [ppCAS] reconnecting in #{humanTime timeout} (#{xth @connectAttemps} attempt)"
                    @reconnectTimer = sleep timeout, !~>
                        console.log "#{getTime!} [ppCAS] reconnecting…"
                        @connectAttemps++
                        @connect(url, true, @connectAttemps==1)
                        _$context.trigger \ppCAS:connecting
                        API.trigger \ppCAS:connecting


        changeBlurb: (newBlurb, options={}) !->
            $.ajax do
                method: \PUT
                url: '/_/profile/blurb'
                contentType: \application/json
                data: JSON.stringify(blurb: newBlurb)
                success: options.success
                error: options.error

            #sleep 5_000ms, !-> if @connectAttemps
            #   @socket.emit \reqAuthToken

        disable: !->
            @changeBlurb @oldBlurb if @blurbIsChanged
            @socket? .close!
            clearTimeout @reconnectTimer
            for avatarID, avi of p0ne._avatars
                avi.inInventory = false
            @updateAvatarStore!
            for ,user of users.models when user.get \vanillaAvatarID
                user.set \avatarID, that

    module \ppCASStatusRing, do
        settings: \dev
        help: '''
            shows whether or not you are connected to the ppCAS (plug_p0ne Custom Avatar Server) by drawing a ring around your avatar in the footer (below the chat).
            green: connected
            orange: connecting
            red: disconnected
        '''
        setup: ({addListener}) !->
            @$footerAvi = $ '#footer-user .thumb'
            addListener API, \ppCAS:connected, !~>
                @$footerAvi .css borderColor: \limegreen
            addListener API, \ppCAS:connecting, !~>
                @$footerAvi .css borderColor: \orange
            addListener API, \ppCAS:disconnected, !~>
                @$footerAvi .css borderColor: \red

            # see https://developer.mozilla.org/en-US/docs/Web/API/WebSocket#Ready_state_constants
            switch customAvatars.socket?.readyState
            | 0 => # CONNECTING
                @$footerAvi .css borderColor: \orange
            | 1 => # OPEN
                @$footerAvi .css borderColor: \limegreen
            | otherwise => # CLOSING, CLOSED, no socket
                @$footerAvi .css borderColor: \red

        disable: !->
            if @$footerAvi
                @$footerAvi .css borderColor: ''
            $ \.p0ne-vanilla-avatar-highlight .remove!