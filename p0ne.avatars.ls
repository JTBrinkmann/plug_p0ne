/*@author jtbrinkmann aka. Brinkie Pie */
/*@license all rights reserved. you may use it but not look at/edit/copy/share the code */

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

#=======================
# for Standalone testing
if not window.p0ne
    window.p0ne = {}

    window.module ||= (name, {require, setup}:module) ->
        # poor man's module()
        failedRequirements = [r for r in require||[] when !r or (typeof r == \string and not window[r])]
        if failedRequirements.length
            console.error "[#name] didn't initialize (#failedRequirements #{if failedRequirements.length > 1 then 'are' else 'is'} required)"
            return module
        replacements = []
        aux =
            replace: (target, attr, repl) ->
                replacements[*] = [target, attr, repl]
                target["#{attr}_"] ||= target[attr]
                repl = module[repl] if typeof repl == \string and module[repl]
                if typeof repl == \function
                    target[attr] = repl(target["#{attr}_"])
                else
                    target[attr] = repl
        module.disable = ->
            for [target, attr] in replacements
                target[attr] = target["#{attr}_"]
            delete window[name]
        window[name] = module
        setup(aux)
    window.requireHelper ||= ({name, id, test}:a) !->
        if typeof a == \function
            test = a
        module = require.s.contexts._.defined[id] if id
        if module and test module
            module.id ||= id
            window[name] = module
            return module
        else
            for id, module of require.s.contexts._.defined when module
                if test module, id
                    module.id ?= id
                    console.warn "[requireHelper] module '#{module.name}' updated to ID '#id'"
                    window[name] = module
                    return module
    window.requireAll ||= (test) ->
        return [m for id, m of require.s.contexts._.defined when m and test(m, id)]


    window.css = do ->
        styles = {}; $el = $ \<style> .appendTo \head
        return (name, css) ->
            styles[name] = css
            res = ""
            for n,css of styles
                res += "/* #n */\n#css\n\n"
            $el.text res

    # users
    requireHelper do
        name: \users
        id: \ce221/cfb6f/b8135 # 2014-09-22
        test: (it) ->
            return it.models?.0?.attributes.avatarID
                and \isTheUserPlaying not of it
                and \lastFilter not of it
    window.userID = API.getUser!.id
    window.user_ = users.get(userID) if users?
#=======================

if window.updateAvatarStore
    window.updateAvatarStore!

# auxiliaries

requireHelper do
    name: \avatarAuxiliaries
    id: \d96a5/fe098/b43bc # 2014-09-23
    test: (.getAvatarUrl)

requireHelper do
    name: \Avatar
    id: \d96a5/fb748/e14bb # 2014-09-23
    test: (.AUDIENCE)

requireHelper do
    name: \AvatarList
    id: \d96a5/b3c7a/b0e22
    test: (._byId?.admin01)

window.Lang = require \lang/Lang

requireHelper do
    name: \myAvatars
    id: \c8ba2/c93f6/d2a43 # 2014-09-23
    test: (.comparator == \id) # (_) -> _.comparator == \id and _._events?.reset and (!_.length || _.models[0].attributes.type == \avatar)

window.Cells = requireAll (m) -> m::?.className == \cell and m::getBlinkFrame
console.log "loaded Lang, myAvatars and Cells", Lang, myAvatars, Cells

module \customAvatars, do
    require: <[ users Lang avatarAuxiliaries Avatar myAvatars ]>
    setup: ({replace}) ->
        console.info "initializing p0ne avatar"
        p0ne._avatars = {}

        user = API.getUser!
        hasNewAvatar = localStorage.vanillaAvatarID and localStorage.vanillaAvatarID == user.avatarID
        localStorage.vanillaAvatarID = user.avatarID

        # - display custom avatars
        getAvatarUrl_ = avatarAuxiliaries.getAvatarUrl .bind avatarAuxiliaries
        replace avatarAuxiliaries, \getAvatarUrl, (gAU_) -> return (avatarID, type) ->
            return p0ne._avatars[avatarID]?[type] || gAU_(avatarID, type)
        #replace avatarAuxiliaries, \getHitSlot, (gHS_) -> return (avatarID) ->
        #    return customAvatarManifest.getHitSlot(avatarID) || gHS_(avatarID)
        #ToDo


        # - set avatarID to custom value
        _internal_addAvatar = (d) ->
            # d =~ {category, thumbOffsetTop, thumbOffsetLeft, base_url, anim, dj, b, permissions}
            #   soon also {h, w, standingLength, standingDuration, standingFn, dancingLength, dancingFn}
            avatarID = d.avatarID
            if p0ne._avatars[avatarID]
                delete Avatar.IMAGES[avatarID]
                console.warn "[p0ne avatars] updating '#avatarID'"
            else if not d.isVanilla
                console.log "[p0ne avatars] adding '#avatarID'"

            avatar = {
                inInventory: false
                category: d.category || "p0ne"
                thumbOffsetTop: d.thumbOffsetTop
                thumbOffsetLeft: d.thumbOffsetLeft
                isVanilla: !!d.isVanilla
                permissions: d.permissions || 0
                #h: d.h || 150px
                #w: d.w || 150px
                # not yet implemented
                #standingLength: d.standingLength || 4frames
                #standingDuration: d.standingDuration || 20frames
                #standingFn: if typeof d.standingFn == \function then d.standingFn
                #dancingLength: d.dancingLength || 20frames
                #dancingFn: if typeof d.dancingFn == \function then d.dancingFn
            }
            avatar.sw = avatar.w * (avatar.standingLength + avatar.dancingLength)
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
            if not updateAvatarStore.loading
                updateAvatarStore.loading = true
                requestAnimationFrame -> # to avoid updating every time when avatars get added in bulk
                    updateAvatarStore.loading = false
                    updateAvatarStore!

        window.addAvatar = (avatarID, d) ->
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
        window.removeAvatar = (avatarID, replace) ->
            for u in users.models
                if u.get(\avatarID) == avatarID
                    u.set(\avatarID, u.get(\avatarID_))
            delete p0ne._avatars[avatarID]



        # - set avatarID to custom value
        window.changeAvatar = (userID, avatarID) ->
            avatar = p0ne._avatars[avatarID]
            if not avatar
                console.warn "can't load avatar from last time: '#{avatarID}'"
                return
            if not avatar.permissions or API.hasPermissions(userID, avatar.permissions)
                users.get userID .set \avatarID, avatarID
            else
                throw "user with ID #userID doesn't have permissions for avatar '#{avatarID}'"

            if userID == user_.id
                p0ne.socket? .emit \changeAvatarID, avatarID
                localStorage.avatarID = avatarID

        window.updateAvatarStore = ->
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
            for avatarID, avi of p0ne._avatars
                if avi.isVanilla
                    if avi.inInventory
                        vanilla[l++] = new Avatar(id: avatarID, category: avi.category, type: \avatar)
                    # otherwise ignore
                else
                    categories[][avi.category][*] = avatarID
            myAvatars.models.splice 0 # empty it
            l = 0
            for category, avis of categories
                for avatarID in avis
                    myAvatars.models[l++] = new Avatar(id: avatarID, category: category, type: \avatar)
            myAvatars.models ++= vanilla
            myAvatars.length = myAvatars.models.length
            myAvatars.trigger \reset, false
            console.log "store updated"
            return true
        myAvatars.on \reset, (vanillaTrigger) ->
            console.log "store reset"
            updateAvatarStore! if vanillaTrigger



        Lang.userAvatars.p0ne = "Custom Avatars"

        # - add vanilla avatars
        for {id:avatarID, attributes:{category}} in AvatarList.models
            _internal_addAvatar do
                avatarID: avatarID
                isVanilla: true
                category: category
                #category: avatarID.replace /\d+$/, ''
                #category: avatarID.substr(0,avatarID.length-2) damn you "tastycat"
        console.log "added internal avatars", p0ne._avatars
        # - fix Avatar selection -
        for Cell in window.Cells
            replace Cell::, \onClick, (oC_) -> return ->
                console.log "[Avatar Cell click]", this
                avatarID = this.model.get("id")
                if not this.$el.closest \.my-avatars .length or p0ne._avatars[avatarID].inInventory
                    # if avatatar is in the Inventory or not bought, properly select it
                    oC_ ...
                else
                    # if not, hax-apply it
                    changeAvatar(userID, avatarID)
                    this.onSelected!
        # - get avatars in inventory -
        $.ajax do
            url: '//plug.dj/_/store/inventory/avatars'
            success: (d) ->
                avatarIDs = []; l=0
                for avatar in d.data
                    avatarIDs[l++] = avatar.id
                    if not  p0ne._avatars[avatar.id]
                        _internal_addAvatar do
                            avatarID: avatar.id
                            isVanilla: true
                            category: avatar.category
                    p0ne._avatars[avatar.id]
                        .inInventory = true
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

#== ppCAS compatibility ==
# e.g.
# p0ne.ppCAS 'https://p0ne.com/_'
if not p0ne.ppCAS
    let a = document.createElement "a"
        API.on API.CHAT_COMMAND, (str) ->
            str = "/ppcas https://p0ne.com/_" if str == "//" # FOR TESTING ONLY
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

                    p0ne.socket = close: ->
                        helper \removeAvatar
                        delete p0ne.socket
                    helper \addAvatar
                a.href = server
                if a.host != location.host
                    console.log "[p0ne avatars] connecting to", server
                    p0ne.ppCAS server
                else
                    console.warn "[p0ne avatars] invalid ppCAS server"

p0ne.ppCAS = (url, reconnecting, reconnectWarning) ->
    if not reconnecting and p0ne.socket
        return if url == p0ne.socket.url
        p0ne.socket.close!
    console.log "[p0ne avatars] using socket as ppCAS avatar server"
    user = API.getUser!
    reconnect = true
    connected = false

    if reconnectWarning
        setTimeout (-> if not connected then API.chatLog "[p0ne avatars] lost connection to avatar server =("), 10_000ms

    socket = p0ne.socket = new SockJS(url)
    socket.url = url
    socket.on = socket.addEventListener
    socket.off = socket.removeEventListener
    socket.once = (type, callback) -> @on type, -> @off type, callback; callback ...

    socket.emit = (type, ...data) ->
        console.log "[ppCAS] < [#type]", data
        this.send JSON.stringify {type, data}

    socket.trigger = (type, args) ->
        args = [args] if typeof args != \object or not args.length
        listeners = @_listeners[type]
        if listeners.length
            for fn in listeners
                fn .apply this, args
        else
            console.error "[ppCAS] unknown event '#type'"

    socket.onmessage = ({data: message}) ->
        try
            {type, data} = JSON.parse(message)
            console.log "[ppCAS] > [#type]", data
        catch e
            console.warn "[ppCAS] invalid message received", message, e
            return

        socket.trigger type, data

    let close = socket.close
        socket.close = ->
            socket.trigger close
            close ...


    socket.on \authToken, (authToken) ->
        console.log "[ppCAS] authToken: ", authToken
        user.oldBlurb = user.blurb || ""
        if not user.blurb # user.blurb is actually `null` by default, not ""
            newBlurb = authToken
        else if user.blurb.length >= 73
            newBlurb = "#{user.blurb.substr(0, 72)}… #authToken"
        else
            newBlurb = "#{user.blurb} #authToken"

        changeBlurb newBlurb, do
            success: ->
                socket.emit \auth, userID
            error: ->
                console.error "[ppCAS] failed to authenticate by changing the blurb."
                changeBlurb user.oldBlurb, success: ->
                    console.info "[ppCAS] blurb reset."

    socket.on \authAccepted, ->
        console.log "[ppCAS] authAccepted"
        connected := true
        reconnecting := false
        changeBlurb user.oldBlurb, do
            error: ->
                API.chatLog "[p0ne avatars] failed to authenticate to avatar server, maybe plug.dj is down or changed it's API?"
                changeBlurb user.oldBlurb, error: ->
                    console.error "[ppCAS] failed to reset the blurb."
    socket.on \authDenied, ->
        console.warn "[ppCAS] authDenied"
        API.chatLog "[p0ne avatars] "
        changeBlurb user.oldBlurb, do
            error: ->
                changeBlurb user.oldBlurb, error: ->
                    console.error "[ppCAS] failed to reset the blurb."
        API.chatLog "[p0ne avatars] Failed to authenticate with user id '#userID'", true

    socket.on \avatars, (avatars) ->
        console.log "[avatars]", avatars
        socket.avatars = avatars
        requestAnimationFrame initUsers if socket.users
        for avatarID, avatar of avatars
            addAvatar avatarID, avatar
        if localStorage.avatarID of avatars
            changeAvatar userID, localStorage.avatarID
        else if user.avatarID of avatars
            socket.emit \changeAvatarID, user.avatarID

    socket.on \users, (users) ->
        console.log "[users]", users
        socket.users = users
        requestAnimationFrame initUsers if socket.avatars

    # initUsers() is used by socket.on \users and socket.on \avatars
    function initUsers avatarID
        for userID, avatarID of socket.users
            console.log "[ppCAS] change other's avatar", userID, avatarID
            users.get userID ?.set \avatarID, avatarID
        #API.chatLog "[p0ne avatars] connected to ppCAS"
        if reconnecting
            API.chatLog "[p0ne avatars] reconnected"
        else
            API.chatLog "[p0ne avatars] avatars loaded. Click on your name in the bottom right corner and then 'Avatars' to become a :horse: pony!"

    socket.on \changeAvatarID, (userID, avatarID) ->
        console.log "[ppCAS] change other's avatar:", userID, avatarID
        users.get userID ?.set \avatarID, avatarID

    socket.on \disconnect, (userID) ->
        console.log "[ppCAS] user disconnected:", userID
        users.get userID ?.set \avatarID, avatarID

    socket.on \close, (reason) ->
        console.warn "[ppCAS] connection closed", reason
        reconnect := false
    socket.onclose = (e) ->
        console.warn "[ppCAS] DISCONNECTED", e
        return if e.wasClean
        if reconnect
            if connected
                console.log "[ppCAS] reconnecting…"; p0ne.ppCAS(url, true, true)
            else
                setTimeout (-> console.log "[ppCAS] reconnecting…"; p0ne.ppCAS(url, true, false)),  5_000ms + Math.random()*5_000ms


    function changeBlurb newBlurb, options
        $.ajax do
            method: \PUT
            url: "/_/profile/blurb"
            contentType: \application/json
            data: JSON.stringify(blurb: newBlurb)
            success: options.success
            error: options.error

    #setTimeout (-> socket.emit \reqAuthToken if not connected), 5_000ms

#API.chatLog "[ppCAS] custom avatar script loaded. type '/ppCAS <url>' into chat to connect to an avatar server"
p0ne.ppCAS "https://p0ne.com/_"