/*@author jtbrinkmann aka. Brinkie Pie */
/*@license https://creativecommons.org/licenses/by-nc/4.0/ */
/*####################################
#            AUXILIARIES             #
####################################*/
window.p0ne = {
    version: \1.0.0
    host: 'https://dl.dropboxusercontent.com/u/4217628/plug_p0ne'
    SOUNDCLOUD_KEY: \aff458e0e87cfbc1a2cde2f8aeb98759
    YOUTUBE_KEY: \AI39si6XYixXiaG51p_o0WahXtdRYFCpMJbgHVRKMKCph2FiJz9UCVaLdzfltg1DXtmEREQVFpkTHx_0O_dSpHR5w0PTVea4Lw
    has_$context: false
    started: new Date
    modules: {}
    lsBound: {}
}

# helper for defining non-enumerable functions via Object.defineProperty
let (d = (property, fn) -> if @[property] != fn then Object.defineProperty this, property, { enumerable: false, writable: true, configurable: true, value: fn })
    d.call Object::, \define, d

Array::define \remove, (i) -> return @splice i, 1
Array::define \random, -> return this[~~(Math.random! * @length)]

String::define \reverse, ->
    res = ""
    i = @length
    while i--
        res += @[i]
    return res
jQuery.fn.fixSize = ->
    for el in this
        el.style .width = "#{el.width}px"
        el.style .height = "#{el.height}px"
    return this

window.localStorageBind = (name, defaultVal={}) ->
    return p0ne.lsBound[name] = do
        if localStorage[name]
            JSON.parse(localStorage[name])
        else
            defaultVal

window.localStorageSave = !->
    err = ""
    for k,v of p0ne.lsBound
        try
            localStorage[k] = v.toJSON?! || JSON.stringify(v)
        catch
            err += "failed to store '#k' to localStorage"
    alert err if err
$ window .on \beforeunload, localStorageSave
setInterval localStorageSave, 15min *60_000ms_to_min

window <<<<
    repeat: (timeout, fn) -> return setInterval (-> fn ... if not disabled), timeout
    sleep: (timeout, fn) -> return setTimeout fn, timeout
    pad: (num) ->
        if num < 10
            return num = "0#num"
        else
            return "#num"

    generateID: -> return (~~(Math.random!*0xFFFFFF)) .toString(16).toUpperCase!


    getUserByName: (name) !->
        for user in API.getUsers! when user.username == name
            return user
        for user in stats.users||[] when user.username == name
            return user
    getUserByID: (id) !->
        for user in API.getUsers! when user.id == id
            return user
        for user in stats.users||[] when user.id == id
            return user

    logger: (loggerName, fn) ->
        return ->
            console.log "[#loggerName]", arguments
            return fn? ...

    replace: (context, attribute, cb) ->
        context["#{attribute}_"] ||= context[attribute]
        context[attribute] = cb(context["#{attribute}_"])

    loadScript: (loadedEvent, data, file, callback) ->
        d = $.Deferred!
        d.then callback if callback

        if data
            d.resolve!
        else
            $.getScript "#{p0ne.host}/#file"
            $ window .one loadedEvent, d.resolve #Note: .resolve() is always bound to the Deferred
        return d.promise!

    requireIDs: localStorageBind \requireIDs
    requireHelper: ({name, test, onfail, fallback}:a) ->
        if typeof a == \function
            test = a

        if (module = window[name]) and test module
            id = module.id
            res = module
        else if (id = requireIDs[name]) and (module = require.s.contexts._.defined[id]) and test module
            res = module
        else
            for id, module of require.s.contexts._.defined when module and test module, id
                console.warn "[requireHelper] module '#name' updated to ID '#id'"
                requireIDs[name] = id
                res = module
                break
        if res
            #p0ne.modules[name] = res
            res.id ||= id
            window[name] = res if name
            return res
        else
            onfail?!
            window[name] = fallback if name
            return fallback
    requireAll: (test) ->
        return [m for id, m of require.s.contexts._.defined when m and test(m, id)]

    addListener: ({name, setup, update, callback, disable}:data, b) ->
        # will either set-up or update the listener
        # will be disabled if window.disable is true
        if typeof data == \string
            b.name = data
            {name, setup, update, callback, disable} = data = b
        disabled = false

        name ||= "unnamed_#{generateID!}"

        if not window[name]
            wrapper = -> window[name] ... if not window.disable and not window.disable and not disabled
            setup? wrapper, update
            console.warn "[#name] initialized"
        else if update or callback && window[name] != callback
            update? window[name]
            console.warn "[#name] updated"
        else
            #console.warn "[#name] already loaded!"
            return
        if callback
            window[name] = callback
            window[name]?.disable = ->
                return console.warn "[#name] already disabled" if disabled
                disabled := true
                disable? wrapper
                console.warn "[#name] disabled"
        else
            window[name] = true

    replace_$Listener: (type, callback) ->
        if not _$context
            console.error "[ERROR] unable to replace listener in _$context._events['#type'] (no _$context)"
            return false
        if not evts = _$context._events[type]
            console.error "[ERROR] unable to replace listener in _$context._events['#type'] (no such event)"
            return false
        for e in evts
            if e.context?.cid
                e.callback_ ||= e.callback
                e.callback = callback
                disabled = false
                console.warn "[#name] replaced eventlistener", e
                return do
                    type: type
                    listener: e
                    callback: callback
                    original: e.callback_
                    disable: ->
                        return console.warn "[#name] already disabled" if disabled
                        e.callback = e.callback_
                        disabled = true
                    enable: ->
                        return console.warn "[#name] already enabled" if not disabled
                        e.callback = callback
                        disabled = false
                    update: (fn) ->
                        callback := fn
                        e.callback = fn if not disabled

        console.error "[ERROR] unable to replace listener in _$context._events['#type'] (no vanilla callback found)"
        return false

    /* callback gets called with the arguments cb(errorCode, response, event) */
    ajax: (url,  data, cb) ->
        cb_ = (status, data) ->
            if status == -1
                console.error "[#url]", status, data
            else if not data?.length
                console.warn "[#url]", data
            else
                console.log "[#url]", data
            cb? ...
        command = (delete data.command) or \POST
        return $.ajax do
                type: command
                url: "https://plug.dj/_/#url"
                contentType: \application/json
                data: JSON.stringify(data)
                success: ({status, data}) ->
                    cb_(status, data)
                error: (err) ->
                    cb_(-1, err)

    befriend: (userID, cb) -> ajax "friends", command: "POST", id: userID, cb
    ban: (userID, cb) -> ajax "bans/add", userID: userID, duration: API.BAN.PERMA, reason: 1, cb
    unban: (userID, cb) -> ajax "bans/#userID", command: \DELETE, cb
    chatDelete: (chatID, cb) -> ajax "chat/#chatID", command: "DELETE", cb
    kick: (userID, cb) ->
        <- ban userID
        <- sleep 1_000ms
        unban userID, cb

    getChat: (cid) ->
        return $ \#chat-messages .children "[data-cid='#cid']"

    #ToDo test this
    getMentions: (data) ->
        names = []; l=0
        data.message.replace /@(\w+)/g, (_, name, i) ->
            helper = (name) ->
                possibleMatches = [username for {username} in API.getUsers! when username.indexOf(name) == 0]
                switch possibleMatches.length
                | 0 =>
                | 1 => if data.message.substr(i + 1, possibleMatches.0.length) == possibleMatches.0
                    names[l++] = possibleMatches.0
                | otherwise =>
                    return helper(data.message.substr(i + 1, _.length))
                return _
            return helper(name)

        if not names.length
            names = [data.un]
        else
            names = $.unique names

        names.toString = -> return humanList this
        return names


    htmlEscapeMap: {sp: 32, blank: 32, excl: 33, quot: 34, num: 35, dollar: 36, percnt: 37, amp: 38, apos: 39, lpar: 40, rpar: 41, ast: 42, plus: 43, comma: 44, hyphen: 45, dash: 45, period: 46, sol: 47, colon: 58, semi: 59, lt: 60, equals: 61, gt: 62, quest: 63, commat: 64, lsqb: 91, bsol: 92, rsqb: 93, caret: 94, lowbar: 95, lcub: 123, verbar: 124, rcub: 125, tilde: 126, sim: 126, nbsp: 160, iexcl: 161, cent: 162, pound: 163, curren: 164, yen: 165, brkbar: 166, sect: 167, uml: 168, die: 168, copy: 169, ordf: 170, laquo: 171, not: 172, shy: 173, reg: 174, hibar: 175, deg: 176, plusmn: 177, sup2: 178, sup3: 179, acute: 180, micro: 181, para: 182, middot: 183, cedil: 184, sup1: 185, ordm: 186, raquo: 187, frac14: 188, half: 189, frac34: 190, iquest: 191}
    htmlEscape: (str) ->
        return $ \<span> .text str .html!
        /*
        if not window.htmlEscapeRegexp
            window.htmlEscapeRegexp = []; l=0; window.htmlEscapeMap_reversed = {}
            for k,v of htmlEscapeMap when v != 32 #spaces
                window.htmlEscapeMap_reversed[v] = k
                v .= toString 16
                if v.length <= 2
                    v = "0#v"
                window.htmlEscapeRegexp[l++] = "\\u0#v"
        return str.replace //#{window.htmlEscapeRegexp .join "|"}//g, (c) -> return "&#{window.htmlEscapeMap_reversed[c.charCodeAt 0]};"
        */

    htmlUnescape: (html) ->
        return html.replace /&(\w+);|&#(\d+);|&#x([a-fA-F0-9]+);/g, (_,a,b,c) ->
            return String.fromCharCode(+b or htmlEscapeMap[a] or parseInt(c, 16)) or _
    stripHTML: (msg) ->
        return msg .replace(/<.*?>/g, '')
    unemotify: (str) ->
        map = window.emoticons?.map
        return str if not map
        str .replace /<span class="emoji-glow"><span class="emoji emoji-(\w+)"><\/span><\/span>/g, (_, emoteID) ->
            if emoticons.reverseMap[emoteID]
                return ":#that:"
            else
                return _

    #== RTL emulator ==
    # str = "abc\u202edef\u202dghi"
    # [str, resolveRTL(str)]
    resolveRTL: (str, dontJoin) ->
        a = b = ""
        isRTLoverridden = false
        "#str\u202d".replace /(.*?)(\u202e|\u202d)/g, (_,pre,c) ->
            if isRTLoverridden
                b += pre.reverse!
            else
                a += pre
            isRTLoverridden := (c == \\u202e)
            return _
        if dontJoin
            return [a,b]
        else
            return a+b
    cleanMessage: (str) -> return str |> unemotify |> stripHTML |> htmlUnescape |> resolveRTL


    humanList: (arr) ->
        return "" if not arr.length
        arr = []<<<<arr
        if arr.length > 1
            arr[*-2] += " and\xa0#{arr.pop!}" # \xa0 is NBSP
        return arr.join ", "

    plural: (num, singular, plural=singular+'s') ->
        # for further functionality, see
        # * http://unicode.org/repos/cldr-tmp/trunk/diff/supplemental/language_plural_rules.html
        # * http://www.unicode.org/cldr/charts/latest/supplemental/language_plural_rules.html
        # * https://developer.mozilla.org/en-US/docs/Localization_and_Plurals
        if num == 1 # note: 0 will cause an s at the end, too
            return "#num\xa0#singular" # \xa0 is NBSP
        else
            return "#num\xa0#plural"


    # formatting
    getTime: (t = new Date) ->
        return t.toISOString! .replace(/.+?T|\..+/g, '')
    getISOTime: ->
        return new Date! .toISOString! .replace(/T|\..+/g, " ")
    # show a timespan (in ms) in a human friendly format (e.g. "2 hours")
    humanTime: (diff) ->
        return "-#{humanTime -diff}" if diff < 0
        b=[60to_min, 60to_h, 24to_days, 360.25to_years]; c=0
        diff /= 1000to_s
        while diff > 2*b[c] then diff /= b[c++]
        return plural ~~diff, <[ second minute hour day ]>[c]
    # show a timespan (in s) in a format like "mm:ss" or "hh:mm:ss" etc
    mediaTime: (~~dur) ->
        return "-#{mediaTime -dur}" if dur < 0
        b=[60to_min, 60to_h, 24to_days, 360.25to_years]; c=0
        res = pad dur%60
        while dur = ~~(dur / b[c++])
            res = "#{pad dur % b[c]}:#res"
        if res.length == 2
            return "00:#res"
        else
            return res

    # create string saying how long ago a given timestamp (in ms since epoche) is
    ago: (d) ->
        return "#{humanTime (Date.now! - d)} ago"

    lssize: (sizeWhenDecompressed) ->
        size = 0mb
        for ,x of localStorage
            x = decompress x if sizeWhenDecompressed
            size += x.length / 524288 # x.length * 2 / 1024 / 1024
        return size
    formatMB: ->
        return "#{it.toFixed(2)}MB"

    getRank: (user) ->
        if user.gRole || user.get?(\gRole) || 0
            if that == 5
                return \admin
            else
                return \BA
        return <[ user RDJ bouncer manager co-host host ]>[user.role || user.get?(\role) || 0]

    getArgs: ->
        f = &callee
        i = 0
        stack = []
        res = []
        while -1 == stack.indexOf(f=f.caller) && f
            stack[i] = f
            res[i] = [f]
            for a, o in f.arguments
                res[i][1+o] = a
            i++
        return res



    # variables
    disabled: false
    userID: API?.getUser!.id
    user: API?.getUser!
    roomname: location.pathname.substr(1)
    #socket: window.io?.sockets["http://plug.dj:80"] #ToDo
    #$popup: $ \#dialog-container
    #stats: localStorage.stats && JSON.parse(localStorage.stats) or {users:[]}
    IDs:
        Bot:                        3730413
        Sgt_Chrysalis:              4131382
        The_Sensational_Stallion:   4103672
        Sweetie_Mash:               3919787
        BrinkieBot:                 4067112
        Brinkie:                    3966366
        BrinkiePie:                 3966366
        nejento:                    3460593
        Mateon1:                    4187008
        MadPacman:                  3947647



p0ne.wrap = (obj) ->
    obj.get = (name) ->
        return this if name == \media
        a = this[name]
        if a and typeof a == \object
            p0ne.wrap(a)
        else
            return a
    obj.set = (name, val) -> obj[name] = val
    l = obj.length
    while l--
        obj[l] = p0ne.wrap(obj[l])
    return obj


requireHelper do
    name: \PopoutView
    test: (\_window of)

/*####################################
#          REQUIRE MODULES           #
####################################*/
#= _$context =
window.has_$context = true
requireHelper do
    name: \_$context
    test: (._events?['chat:receive'])
    fallback: {_events: {}}
    onfail: ->
        console.error "[p0ne require] couldn't load '_$context'. Some modules might not work"
        window.has_$context = false
window._$context.onEarly = (type, callback, context) ->
    this._events[][type] .unshift({callback, context, ctx: context || this})
        # ctx:  used for .trigger in Backbone
        # context:  used for .off in Backbone
    return this

#= app =
window.app = null if window.app?.nodeType
<-  (cb) ->
    return cb! if window.app

    requireHelper do
        name: \App
        test: (.::?.el == \body)
        fallback: {prototype:{}}
    App::animate = let animate_ = App::animate then !->
        window.app = p0ne.app = this
        console.log "[p0ne] got `app`"
        App::animate = animate_
        return animate_ ...

    do waitForApp = ->
        return cb! if window.app
        sleep 50ms, waitForApp

# continue only after `app` was loaded
#= room =
requireHelper do
    name: \room
    test: (.attributes?.hostID)

#= compressor =
/*
requireHelper do
    name: \compressor
    id: \e1722/cbf30/b8829
    test: (.compress)
    onfail: ->
            console.error "[p0ne require] couldn't load 'compress'. The restoreChatScript may only run in restricted mode."
            console.warn "[rCS] occupied LocalStorage space: #{formatMB lssize!} / 10MB"
*/
window.compress = (data) ->
    if window.compressor
        return "1|#{compressor.compress data}"
    else
        return "0|#data"
window.decompress = (data) ->
    if data.1 == "|"
        if data.0 == "1"
            if compressor
                return compressor.decompress data.substr(2)
            else
                console.warn "[p0ne compress] can't decompress, because plug.dj Compress module is missing."
                return false
        else if data.0 == "0"
            return data.substr(2)
    else
        return data

#if has_$context and not _$context._events['chat:send'] # fix for before 2014-08-26, when chat:send got renamed to a hexadecimal code, randomized on each pageload
#   window.chat_send = Object.keys(_$context._events).filter(-> /\d/.test it).0

requireHelper do
    name: \Curate
    test: (m) -> m:: and "#{m::execute}".indexOf("/media/insert") != -1

requireHelper do
    name: \playlists
    test: (.activeMedia)

requireHelper do
    name: \users
    test: (it) ->
        return it.models?.0?.attributes.avatarID
            and \isTheUserPlaying not of it
            and \lastFilter not of it
window.user_ = users.get(userID) if users

requireHelper do
    name: \room
    test: (.attributes?.hostID)

requireHelper do
    name: \auxiliaries
    test: (.deserializeMedia)

requireHelper do
    name: \database
    test: (.settings)

requireHelper do
    name: \socketEvents
    test: (.ack)
requireHelper do
    name: \permissions
    test: (.::?canModChat)


requireHelper do # the friendslist as rendered in .app-right
    name: \FriendsList
    test: (.::?className == \friends)
window.friendsList = app.room.friends

requireHelper do
    name: \emoticons
    test: (.emojify)
emoticons.reverseMap = {[v, k] for k,v of emoticons.map} if window.emoticons

# chat
if not window.chat = app.room.chat
    for e in _$context?._events[\chat:receive] || [] when e.context?.cid
        window.chat = e.context
        break

if chat
    window <<<<
        $cm: ->
            if window.saveChat
                return saveChat.$cm
            else
                return chat.$chatMessages

        playChatSound: (isMention) ->
            if isMention
                chat.playSound \mention
            else if $ \.icon-chat-sound-on .length > 0
                chat.playSound \chat
else
    cm = $ \#chat-messages
    window <<<<
        $cm: ->
            return cm
        playChatSound: (isMention) ->

window <<<<
    appendChat: (div, wasAtBottom) ->
        wasAtBottom ?= chatIsAtBottom!
        if window.saveChat
            window.saveChat.$cChunk.append div
        else
            $cm!.append div
        chatScrollDown! if wasAtBottom

        #playChatSound isMention

    chatIsAtBottom: ->
        cm = $cm!
        return cm.scrollTop! > cm.0 .scrollHeight - cm.height! - 20
    chatScrollDown: ->
        $cm!
            ..scrollTop( ..0 .scrollHeight )


/*####################################
#           extend jQuery            #
####################################*/
# add .timeout(time, fn) to Deferreds and Promises
replace jQuery, \Deferred, (Deferred_) -> return ->
    var timeStarted
    res = Deferred_ ...
    res.timeout = timeout
    promise_ = res.promise
    res.promise = ->
        res = promise_ ...
        res.timeout = timeout; res.timeStarted = timeStarted
        return res
    return res

    function timeout time, callback
        now = Date.now!
        timeStarted ||= Date.now!
        if @state! != \pending
            #console.log "[timeout] already #{@state!}"
            return

        if timeStarted + time <= now
            #console.log "[timeout] running callback now (Deferred started #{ago timeStarted_})"
            callback.call this, this
        else
            #console.log "[timeout] running callback in #{humanTime(timeStarted + time - now)} / #{humanTime time}"
            sleep timeStarted + time - now, ~>
                callback.call this, this if @state! == \pending



/*####################################
#     Listener for other Scripts     #
####################################*/
# plug³
let d = $.Deferred!
    var rR_
    onLoaded = ->
        console.info "[p0ne] plugCubed detected"
        rR_ = Math.randomRange
        #window.plugCubed = null
        do waiting = ->
            # wait for plugCube to finish loading
            requestAnimationFrame ->
                if window.plugCubed and not window.plugCubed.plug_p0ne
                    d.resolve!
                    replace plugCubed, \close, (close_) -> return !->
                        close_!
                        if Math.randomRange != rR_
                            # plugCubed got reloaded
                            onLoaded!
                        else
                            window.plugCubed = {close: onLoaded}
                else
                    waiting!
    if window.plugCubed
        onLoaded!
    else
        window.plugCubed = {close: onLoaded, plug_p0ne: true}
    window.plugCubedLoaded = d.promise!

# plugplug
let d = $.Deferred!
    onLoaded = ->
        console.info "[p0ne] plugplug detected"
        d.resolve!
        sleep 5_000ms, -> ppStop = onLoaded
    if window.ppSaved
        onLoaded!
    else
        ppStop = onLoaded
    window.plugplugLoaded = d.promise!

/*####################################
#          GET PLUG³ VERSION         #
####################################*/
window.getPlugCubedVersion = ->
    if not plugCubed?.init
        return null
    else if plugCubed.version
        return plugCubed.version
    else if v = $ '#p3-settings .version' .text!
        void
    else if plugCubed.settings # plug³ stable
        plugCubed.onMenuClick!
        v = $ \#p3-settings
            .stop!
            .css left: -271px
            .find \.version .text!
    else # plug³ alpha
        v = requireHelper do
            name: \plugCubedAlphaVersion
            test: (.major)
        return v if v

        # alternative methode (40x slower)
        $ \plugcubed .click!
        v = $ \#p3-settings
            .stop!
            .css left: -500px
            .find \.version .text!


    if typeof v == \string
        v .replace /^(\d+)\.(\d+)\.(\d+)(?:-(\w+))?(_min)? \(Build (\d+)\)$/,
            (,major, minor, patch, prerelease="", !!minified, build) ->
                v := {major, minor, patch, prerelease, minified, build}
                v.toString = ->
                    return "#{@major}.#{@minor}.#{@patch}#{@prerelease && '-'+@prerelease}#{@minified && '_min' || ''} (Build #{@build})"
    return plugCubed.version = v



# draws an image in the log
# `src` can be any url, that is valid in CSS (thus data urls etc, too)
# the optional parameter `customWidth` and `customHeight` need to be in px (of the type Number; e.g. `316` for 316px)
#note: if either the width or the height is not defined, the console.log entry will be asynchron because the image has to be loaded first to get the image's width and height
# returns a promise, so you can attach a callback for asynchronious loading with `console.logImg(...).then(function (img){ ...callback... } )`
# an HTML img-node with the picture will be passed to the callback(s)
#var pending = console && console.logImg && console.logImg.pending
console.logImg = (src, customWidth, customHeight) ->
    promise = do
        then: (cb) ->
            this._callbacksAfter ++= cb
            return this

        before: ->
            this._callbacksBefore ++= cb
            return this
        _callbacksAfter: []
        _callbacksBefore: []
        abort: ->
            this._aborted = true
            this.before = this.then = ->
            return this
        _aborted: false

    var img
    logImg = arguments.callee
    logImgLoader = ->
        if promise._aborted
            return

        if promise._callbacksBefore.length
            for cb in promise._callbacksBefore
                cb img
        promise.before = -> it img

        #console.log("height: "+(+customHeight || img.height)+"px; ", "width: "+(+customWidth || img.width)+"px")
        console.log "%c\u200B", "color: transparent; font-size: #{(+customHeight || img.height)*0.854}px !important;
            background: url(#{src});display:block;
            border-right: #{+customWidth || img.width}px solid transparent
        "

        if promise._callbacksAfter.length
            for cb in promise._callbacksAfter
                cb img
        promise.before = promise.then = -> it img

    if +customWidth && +customHeight
        logImgLoader!
    else
        #logImg.pending = logImg.pending || []
        #pendingPos = logImg.pending.push({src: src, customWidth: +customWidth, +customHeight: customHeight, time: new Date(), _aborted: false})
        img = document.createElement \img
            ..src = src
            ..onload = logImgLoader
            ..onerror = ->
                #if(logImg.pending && logImg.pending.constructor == Array)
                #   logImg.pending.splice(pendingPos-1, 1)
                console.log "[couldn't load image %s]", src

    return promise