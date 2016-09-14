/**
 * plug_p0ne Custom Avatars
 * adds custom avatars to plug.dj when connected to a plug_p0ne Custom Avatar Server (ppCAS)
 *
 * @author jtbrinkmann aka. Brinkie Pie
 * @version 1.0
 * @license MIT License
 * @copyright (c) 2014 J.-T. Brinkmann
 *
 * Developer's note: if you create your own custom avatar script or use a modified version of this,
 * you are hereby granted permission connect to this one's default avatar server.
 * However, please drop me an e-mail so I can keep an overview of things.
 * I remain the right to revoke this right anytime.
 */

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

# users
requireHelper \users, (it) ->
    return it.models?.0?.attributes.avatarID
        and \isTheUserPlaying not of it
        and \lastFilter not of it
window.userID ||= API.getUser!.id
window.user_ ||= users.get(userID) if users?
#=======================


# auxiliaries
window.sleep ||= (delay, fn) -> return setTimeout fn, delay

requireHelper \avatarAuxiliaries, (.getAvatarUrl)
requireHelper \Avatar, (.AUDIENCE)
requireHelper \AvatarList, (._byId?.admin01)
requireHelper \myAvatars, (.comparator == \id) # (_) -> _.comparator == \id and _._events?.reset and (!_.length || _.models[0].attributes.type == \avatar)
requireHelper \InventoryDropdown, (.selected)

window.Lang = require \lang/Lang

window.Cells = requireAll (m) -> m::?.className == \cell and m::getBlinkFrame

module \customAvatars, do
    require: <[ users Lang avatarAuxiliaries Avatar myAvatars ]>
    displayName: 'Custom Avatars'
    settings: \base
    help: '''
        This adds a few custom avatars to plug.dj

        You can select them like any other avatar, by clicking on your username (below the chat) and then clicking "My Stuff".
        Click on the Dropdown field in the top-left to select another category.

        Everyone who uses plug_p0ne sees you with your custom avatar.
    '''
    persistent: <[ socket ]>
    setup: ({addListener, replace, css}) ->
        @replace = replace
        console.info "[p0ne avatars] initializing"

        p0ne._avatars = {}

        user = API.getUser!
        hasNewAvatar = localStorage.vanillaAvatarID and localStorage.vanillaAvatarID == user.avatarID
        localStorage.vanillaAvatarID = user.avatarID

        # - display custom avatars
        replace avatarAuxiliaries, \getAvatarUrl, (gAU_) -> return (avatarID, type) ->
            return p0ne._avatars[avatarID]?[type] || gAU_(avatarID, type)
        getAvatarUrl_ = avatarAuxiliaries.getAvatarUrl_
        #replace avatarAuxiliaries, \getHitSlot, (gHS_) -> return (avatarID) ->
        #    return customAvatarManifest.getHitSlot(avatarID) || gHS_(avatarID)
        #ToDo


        # - set avatarID to custom value
        _internal_addAvatar = (d) ->
            # d =~ {category, thumbOffsetTop, thumbOffsetLeft, base_url, anim, dj, b, permissions}
            #   soon also {h, w, standingLength, standingDuration, standingFn, dancingLength, dancingFn}
            avatarID = d.avatarID
            if p0ne._avatars[avatarID]
                console.info "[p0ne avatars] updating '#avatarID'"
            else if not d.isVanilla
                console.info "[p0ne avatars] adding '#avatarID'"

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

            delete Avatar.IMAGES[avatarID] # delete image cache
            if not updateAvatarStore.loading
                updateAvatarStore.loading = true
                requestAnimationFrame -> # throttle to avoid updating every time when avatars get added in bulk
                    updateAvatarStore!
                    updateAvatarStore.loading = false

        export @addAvatar = (avatarID, d) ->
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
        export @removeAvatar = (avatarID, replace) ->
            for u in users.models
                if u.get(\avatarID) == avatarID
                    u.set(\avatarID, u.get(\avatarID_))
            delete p0ne._avatars[avatarID]



        # - set avatarID to custom value
        export @changeAvatar = (userID, avatarID) ->
            avatar = p0ne._avatars[avatarID]
            if not avatar
                console.warn "[p0ne avatars] can't load avatar: '#{avatarID}'"
                return

            return if not user = users.get userID

            if not avatar.permissions or API.hasPermissions(userID, avatar.permissions)
                user.attributes.avatarID_ ||= user.get \avatarID
                user.set \avatarID, avatarID
            else
                console.warn "user with ID #userID doesn't have permissions for avatar '#{avatarID}'"

            if userID == user_.id
                customAvatars.socket? .emit \changeAvatarID, avatarID
                localStorage.avatarID = avatarID

        export @updateAvatarStore = ->
            # update thumbs
            styles = ""
            avatarIDs = []; l=0
            for avatarID, avi of p0ne._avatars when not avi.isVanilla
                avatarIDs[l++] = avatarID
                styles += "
                    .avi-#avatarID {
                        background-image: url('#{avi['']}')
                "
                if avi.thumbOffsetTop
                    styles += ";background-position-y: #{avi.thumbOffsetTop}px"
                if avi.thumbOffsetLeft
                    styles += ";background-position-x: #{avi.thumbOffsetLeft}px"
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
            console.log "[p0ne avatars] store updated"
            return true
        addListener myAvatars, \reset, (vanillaTrigger) ->
            console.log "[p0ne avatars] store reset"
            updateAvatarStore! if vanillaTrigger

        #== patch avatar inventory view ==
        replace InventoryDropdown::, \draw, (d_) -> return ->
            html = ""
            categories = {}

            for avi in myAvatars.models
                categories[avi.get \category] = true

            for category of categories
                html += """
                    <div class="row" data-value="#category"><span>#{Lang.userAvatars[category]}</span></div>
                """

            @$el.html """
                <dl class="dropdown">
                    <dt><span></span><i class="icon icon-arrow-down-grey"></i><i class="icon icon-arrow-up-grey"></i></dt>
                    <dd>#html</dd>
                </dl>
            """

            $ \dt   .on \click, (e) ~> @onBaseClick e
            $ \.row .on \click, (e) ~> @onRowClick  e
            @select InventoryDropdown.selected

            @$el.show!


        Lang.userAvatars.p0ne = "Custom Avatars"

        # - add vanilla avatars
        for {id:avatarID, attributes:{category}} in AvatarList.models
            _internal_addAvatar do
                avatarID: avatarID
                isVanilla: true
                category: category
                #category: avatarID.replace /\d+$/, ''
                #category: avatarID.substr(0,avatarID.length-2) damn you "tastycat"
        console.log "[p0ne avatars] added internal avatars", p0ne._avatars
        # - fix Avatar selection -
        for Cell in window.Cells
            replace Cell::, \onClick, (oC_) -> return ->
                console.log "[p0ne avatars] Avatar Cell click", this
                avatarID = this.model.get("id")
                if /*not this.$el.closest \.inventory .length or*/ p0ne._avatars[avatarID].isVanilla and p0ne._avatars[avatarID].inInventory
                    # if avatatar is in the Inventory or not bought, properly select it
                    oC_ ...
                else
                    # if not, hax-apply it
                    changeAvatar(userID, avatarID)
                    this.onSelected!
        # - get avatars in inventory -
        $.ajax do
            url: '/_/store/inventory/avatars'
            success: (d) ->
                avatarIDs = []; l=0
                for avatar in d.data
                    avatarIDs[l++] = avatar.id
                    if not  p0ne._avatars[avatar.id]
                        _internal_addAvatar do
                            avatarID: avatar.id
                            isVanilla: true
                            category: avatar.category
                    p0ne._avatars[avatar.id] .inInventory = true
                        #..category = d.category
                updateAvatarStore!
                /*requireAll (m) ->
                    return if not m._models or not m._events?.reset
                    m_avatarIDs = ""
                    for el, i in m._models
                        return if avatarIDs[i] != el
                */

        if not hasNewAvatar and localStorage.avatarID
            changeAvatar(userID, that)




        /*####################################
        #         ppCAS Integration          #
        ####################################*/
        @oldBlurb = API.getUser!.blurb
        @blurbIsChanged = false

        urlParser = document.createElement \a
        addListener API, \chatCommand, (str) ~>
            #str = "/ppcas https://p0ne.com/_" if str == "//" # FOR TESTING ONLY
            if 0 == str .toLowerCase! .indexOf "/ppcas"
                server = $.trim str.substr(6)
                if server == "<url>"
                    API.chatLog "hahaha, no. You have to replace '<url>' with an actual URL of a ppCAS server, otherwise it won't work.", true
                else if server == "."
                    # Veteran avatars
                    helper = (fn) ->
                        fn = window[fn]
                        for avatarID in <[ su01 su02 space03 space04 space05 space06 ]>
                            fn avatarID, do
                                category: "Veteran"
                                base_url: base_url
                                thumbOffsetTop: -5px
                        fn \animal12, do
                            category: "Veteran"
                            base_url: base_url
                            thumbOffsetTop: -19px
                            thumbOffsetLeft: -16px
                        for avatarID in <[ animal01 animal02 animal03 animal04 animal05 animal06 animal07 animal08 animal09 animal10 animal11 animal12 animal13 animal14 lucha01 lucha02 lucha03 lucha04 lucha05 lucha06 lucha07 lucha08 monster01 monster02 monster03 monster04 monster05 _tastycat _tastycat02 warrior01 warrior02 warrior03 warrior04 ]>
                            fn avatarID, do
                                category: "Veteran"
                                base_url: base_url
                                thumbOffsetTop: -10px

                    @socket = close: ->
                        helper \removeAvatar
                        delete @socket
                    helper \addAvatar
                urlParser.href = server
                if urlParser.host != location.host
                    console.log "[p0ne avatars] connecting to", server
                    @connect server
                else
                    console.warn "[p0ne avatars] invalid ppCAS server"

        @connect 'https://p0ne.com/_'

    connect: (url, reconnecting, reconnectWarning) ->
        if not reconnecting and @socket
            return if url == @socket.url and @socket.readyState == 1
            @socket.close!
        console.log "[p0ne avatars] using socket as ppCAS avatar server"
        reconnect = true
        connected = false

        if reconnectWarning
            setTimeout (-> if not connected then API.chatLog "[p0ne avatars] lost connection to avatar server \xa0 =("), 10_000ms

        @socket = new SockJS(url)
        @socket.url = url
        @socket.on = @socket.addEventListener
        @socket.off = @socket.removeEventListener
        @socket.once = (type, callback) -> @on type, -> @off type, callback; callback ...

        @socket.emit = (type, ...data) ->
            console.log "[ppCAS] > [#type]", data
            this.send JSON.stringify {type, data}

        @socket.trigger = (type, args) ->
            args = [args] if typeof args != \object or not args.length
            listeners = @_listeners[type]
            if listeners
                for fn in listeners
                    fn .apply this, args
            else
                console.error "[ppCAS] unknown event '#type'"

        @socket.onmessage = ({data: message}) ~>
            try
                {type, data} = JSON.parse(message)
                console.log "[ppCAS] < [#type]", data
            catch e
                console.warn "[ppCAS] invalid message received", message, e
                return

            @socket.trigger type, data

        @replace @socket, close, (close_) ~> return ->
                @trigger close
                close_ ...

        # replace old authTokens
        do ->
            user = API.getUser!
            oldBlurb = user.blurb || ""
            newBlurb = oldBlurb .replace /🐎\w{4}/g, '' # THIS SHOULD BE KEPT IN SYNC WITH ppCAS' AUTH_TOKEN GENERATION
            if oldBlurb != newBlurb
                @changeBlurb newBlurb, do
                    success: ~>
                        console.info "[ppCAS] removed old authToken from user blurb"

        @socket.on \authToken, (authToken) ~>
            console.log "[ppCAS] authToken: ", authToken
            user = API.getUser!
            @oldBlurb = user.blurb || ""
            if not user.blurb # user.blurb is actually `null` by default, not ""
                newBlurb = authToken
            else if user.blurb.length >= 72
                newBlurb = "#{user.blurb.substr(0, 71)}… 🐎#authToken"
            else
                newBlurb = "#{user.blurb} #authToken"

            @blurbIsChanged = true
            @changeBlurb newBlurb, do
                success: ~>
                    @blurbIsChanged = false
                    @socket.emit \auth, userID
                error: ~>
                    console.error "[ppCAS] failed to authenticate by changing the blurb."
                    @changeBlurb @oldBlurb, success: ->
                        console.info "[ppCAS] blurb reset."

        @socket.on \authAccepted, ~>
            console.log "[ppCAS] authAccepted"
            connected := true
            reconnecting := false
            @changeBlurb @oldBlurb, do
                success: ~>
                    @blurbIsChanged = false
                error: ~>
                    API.chatLog "[p0ne avatars] failed to authenticate to avatar server, maybe plug.dj is down or changed it's API?"
                    @changeBlurb @oldBlurb, error: ->
                        console.error "[ppCAS] failed to reset the blurb."
        @socket.on \authDenied, ~>
            console.warn "[ppCAS] authDenied"
            API.chatLog "[p0ne avatars] authentification failed"
            @changeBlurb @oldBlurb, do
                success: ~>
                    @blurbIsChanged = false
                error: ~>
                    @changeBlurb @oldBlurb, error: ->
                        console.error "[ppCAS] failed to reset the blurb."
            API.chatLog "[p0ne avatars] Failed to authenticate with user id '#userID'", true

        @socket.on \avatars, (avatars) ~>
            console.log "[ppCAS] avatars", avatars
            user = API.getUser!
            @socket.avatars = avatars
            requestAnimationFrame initUsers if @socket.users
            for avatarID, avatar of avatars
                addAvatar avatarID, avatar
            if localStorage.avatarID of avatars
                changeAvatar userID, localStorage.avatarID
            else if user.avatarID of avatars
                @socket.emit \changeAvatarID, user.avatarID

        @socket.on \users, (users) ~>
            console.log "[ppCAS] users", users
            @socket.users = users
            requestAnimationFrame initUsers if @socket.avatars

        # initUsers() is used by @socket.on \users and @socket.on \avatars
        ~function initUsers avatarID
            for userID, avatarID of @socket.users
                console.log "[ppCAS] change other's avatar", userID, "(#{users.get userID ?.get \username})", avatarID
                @changeAvatar userID, avatarID
            #API.chatLog "[p0ne avatars] connected to ppCAS"
            if reconnecting
                API.chatLog "[p0ne avatars] reconnected"
            #else
            #    API.chatLog "[p0ne avatars] avatars loaded. Click on your name in the bottom right corner and then 'Avatars' to become a :horse: pony!"
        @socket.on \changeAvatarID, (userID, avatarID) ->
            console.log "[ppCAS] change other's avatar:", userID, avatarID

            users.get userID ?.set \avatarID, avatarID

        @socket.on \disconnect, (userID) ->
            console.log "[ppCAS] user disconnected:", userID
            @changeAvatarID userID, avatarID

        @socket.on \disconnected, (reason) ->
            @socket.trigger \close, reason
        @socket.on \close, (reason) ->
            console.warn "[ppCAS] connection closed", reason
            reconnect := false
        @socket.onclose = (e) ~>
            console.warn "[ppCAS] DISCONNECTED", e
            return if e.wasClean
            if reconnect
                if connected
                    console.log "[ppCAS] reconnecting…"; @connect(url, true, true)
                else
                    sleep 5_000ms + Math.random()*5_000ms, ~>
                        console.log "[ppCAS] reconnecting…"
                        @connect(url, true, false)


    changeBlurb: (newBlurb, options={}) ->
        $.ajax do
            method: \PUT
            url: '/_/profile/blurb'
            contentType: \application/json
            data: JSON.stringify(blurb: newBlurb)
            success: options.success
            error: options.error

        #setTimeout (-> @socket.emit \reqAuthToken if not connected), 5_000ms

    disable: ->
        @changeBlurb @oldBlurb if @blurbIsChanged
        @socket? .close!
        for avatarID, avi of p0ne._avatars
            avi.inInventory = false
        @updateAvatarStore!
        for ,user of users.models when user.attributes.avatarID_
            user.set \avatarID, that
    #API.chatLog "[ppCAS] custom avatar script loaded. type '/ppCAS <url>' into chat to connect to an avatar server :horse:"