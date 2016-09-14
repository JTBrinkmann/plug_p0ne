/*@author jtbrinkmann aka. Brinkie Pie */
/*@license https://creativecommons.org/licenses/by-nc/4.0/ */
/*####################################
#            AUXILIARIES             #
####################################*/
window.p0ne = {
    version: \0.8.6
    host: 'https://dl.dropboxusercontent.com/u/4217628/plug_p0ne'
    has_$context: false
    started: new Date
}

# helper for defining non-enumerable functions via Object.defineProperty
let (d = (property, fn) -> if @[property] != fn then Object.defineProperty this, property, { enumerable: false, writable: true, configurable: true, value: fn })
    d.call Object::, \define, d

Array::define \remove, (i) -> return @splice i, 1
Array::define \random, -> return this[~~(Math.random! * @length)]


window <<<<
    repeat: (timeout, fn) -> return setInterval (-> fn ... if not disabled), timeout
    sleep: (timeout, fn) -> return setTimeout fn, timeout

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

    requireHelper: ({name, id, test, onfail, fallback}:a) ->
        if typeof a == \function
            test = a
        module = require.s.contexts._.defined[id] if id
        if module and test module
            module.id ||= id
            return module
        else
            for id, module of require.s.contexts._.defined when module and test module, id
                module.id ?= id
                console.warn "[requireHelper] module '#name' updated to ID '#id'"
                window[name] = module if name
                return module
            onfail?!
            window[name] = fallback if name
            return fallback

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
    ajax: (command,  body, cb) ->
        cb_ = (error, body) ->
            if error
                console.error "[#command]", error, body
            else if body.length == 0
                console.warn "[#command]", body
            else
                console.log "[#command]", body
            cb? ...
        return $.ajax do
                type: \POST
                url: "http://plug.dj/_/#command"
                contentType: \application/json
                data: JSON.stringify(body: body)
                success: ({status, body}) ->
                    cb_(status, body)
                error: (err) ->
                    cb_(-1, err)

    #ajax "room.staff_1", "brinkiepie-testroom"

    humanList: (arr) ->
        arr = []<<<<arr
        if arr.length > 1
            arr[*-2] += " and\xa0#{elements.pop!}" # \xa0 is NBSP
        return arr.join ", "
    getTime: (t = new Date) ->
        return t.toISOString! .replace(/.+?T|\..+/g, '')
    getISOTime: ->
        return new Date! .toISOString! .replace(/T|\..+/g, " ")
    # show a timespan (in ms) in a human friendly format (e.g. 2 hours)
    humanTime: (diff) ->
        return "-#{humanTime -diff}" if diff < 0
        b=[60to_min, 60to_h, 24to_days, 360.25to_years]; c=0
        diff /= 1000to_s
        while diff > 2*b[c] then diff /= b[c++]
        return "#{~~diff} #{'seconds/minutes/hours/days'.split(\/)[c]}"

    # create string saying how long ago a given timestamp (in ms since epoche) is
    ago: (d) ->
        return "#{humanTime (Date.now! - d)} ago"


    css: let $style = $(\<style>).appendTo(\body), styles = {}
        (name, styles) ->
            styles[name] = styles
            res = ""
            for n,styles of styles
                res += "/* #n */\n#styles\n\n"
            $style.html res

    lssize: (sizeWhenDecompressed) ->
        size = 0mb
        for ,x of localStorage
            x = decompress x if sizeWhenDecompressed
            size += x.length / 524288 # x.length * 2 / 1024 / 1024
        return size
    formatMB: ->
        return "#{it.toFixed(2)}MB"

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
    user: API.getUser!
    roomname: location.pathname.substr(1, location.pathname.length - 2)
    #socket: window.io?.sockets["http://plug.dj:80"] #ToDo
    $popup: $ \#dialog-container
    stats: localStorage.stats && JSON.parse(localStorage.stats) or {users:[]}
    userID: API.getUser!.id
    IDs:
        #Bot:                        \52bd9cbe3b7903590ba23291
        Sgt_Chrysalis:              4131382 #\50aeb2f9c3b97a2cb4c2f945
        The_Sensational_Stallion:   4103672 #\5275ba823e083e58877329cb
        Sweetie_Mash:               3919787 #\5323dafec3b97a1b769dd8fb
        BrinkieBot:                 4067112
        Brinkie:                    3966366
        BrinkiePie:                 3966366


/*####################################
#          REQUIRE MODULES           #
####################################*/
#= _$context =
window.has_$context = true
window._$context = requireHelper do
    name: \_$context
    id: \de369/dcf72/c5fc5 # 2014-09-03
    test: (._events?['chat:receive'])
    fallback: {_events: {}}
    onfail: ->
        console.error "[p0ne require] couldn't load '_$context'. Some modules might not work"
        window.has_$context = false
window._$context.onEarly = (type, callback, context) ->
    this._events[][type] .unshift({callback, context, ctx: context || this})
        # ctx: this # used for .trigger in Backbone
        # context: this # used for .off in Backbone
    return this

#= app =
window.app = null if window.app?.nodeType
<-  (cb) ->
    return cb! if window.app

    window.App = requireHelper do
        name: \App
        id: \de369/d86c0/de369/f9f73 # 2014-09-01
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
window.room = requireHelper do
    name: \room
    id: \ce221/bbc3c/ecebe #2014-09-09
    test: ((m) -> \staffAvatar of m@@?::defaults)

#= compressor =
window.compressor_ = requireHelper do
    name: \compressor
    id: \e1722/cbf30/b8829
    test: (.compress)
    onfail: ->
            console.error "[p0ne require] couldn't load 'compress'. The restoreChatScript may only run in restricted mode."
            console.warn "[rCS] occupied LocalStorage space: #{formatMB lssize!} / 10MB"
if compressor_
    window.compress = (data) -> "1|#{compressor_.compress data}"
else
    window.compress = (data) -> "0|#data"
window.decompress = (data) ->
    if data.1 == "|"
        if data.0 == "1"
            if compressor_
                return compressor_.decompress data.substr(2)
            else
                console.warn "[p0ne compress] can't decompress, because plug.dj Compress module is missing."
                return false
        else if data.0 == "0"
            return data.substr(2)
    else
        return data

#if has_$context and not _$context._events['chat:send'] # fix for before 2014-08-26, when chat:send got renamed to a hexadecimal code, randomized on each pageload
#   window.chat_send = Object.keys(_$context._events).filter(-> /\d/.test it).0

window.Curate = requireHelper do
    name: \Curate
    id: \de369/d2d18/b87de/b006c # 2014-09-03
    test: (m) -> m:: and "#{m::execute}".indexOf("/media/insert") != -1

window.playlists = requireHelper do
    name: \playlists
    id: \de369/a4447/eb1cd # 2014-09-03
    test: (.activeMedia)

window.users = requireHelper do
    name: \users
    id: \de369/a4447/faa37 #2014-09-03
    test: (it) ->
        return it.models?.0?.attributes.avatarID
            and \isTheUserPlaying not of it
            and \lastFilter not of it

window.auxiliaries = requireHelper do
    name: \auxiliaries
    id: \de369/a7486/bc55d # 2014-09-03
    test: (.deserializeMedia)

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
                this.playSound \mention
            else if $ \.icon-chat-sound-on .length > 0
                this.playSound \chat
else
    cm = $ \#chat-messages
    window <<<<
        $cm: ->
            return cm
        playChatSound: (isMention) ->

window <<<<
    appendChat: (div, isMention, wasAtBottom) ->
        wasAtBottom ?= chatIsAtBottom!
        if window.saveChat
            window.saveChat.$cChunk.append div
        else
            $cm!.append div
        chatScrollDown! if wasAtBottom

        playChatSound isMention

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
    d = Date.now!
    res = Deferred_ ...
    timeStarted = res.timeStarted = d
    res.timeout = timeout
    replace res, \promise, (promise_) -> return ->
        res = promise_ ...
        res.timeout = timeout; res.timeStarted = timeStarted
        return res
    return res

    function timeout time, callback
        now = Date.now!
        if @state! != \pending
            console.log "[timeout] already #{@state!}"
            return

        if timeStarted + time <= now
            console.log "[timeout] running callback now (Deferred started #{ago timeStarted})"
            callback.call this, this
        else
            console.log "[timeout] running callback in #{humanTime(timeStarted + time - now)} / #{humanTime time} (Deferred started #{ago timeStarted})"
            this$ = this
            setTimeout (-> callback.call this$, this$ if @state! == \pending), timeStarted + time - now


/*####################################
#     Listener for other Scripts     #
####################################*/
# plug³
let d = $.Deferred!
    if window.plugCubed
        d.resolve!
    else
        plugCubed = {close: d.resolve}
    window.plugCubedLoaded = d.promise!

# plugplug
let d = $.Deferred!
    if window.ppSaved
        d.resolve!
    else
        ppStop = d.resolve
    window.plugplugLoaded = d.promise!

/*@author jtbrinkmann aka. Brinkie Pie */
/*@license https://creativecommons.org/licenses/by-nc/4.0/ */
module \statusCommand, timeout: false, callback:
    target: API
    event: API.CHAT
    bound: true
    callback: (data) ->
        return if @timeout
        if data.message.indexOf("@#{user.username}") != -1 and  data.message.indexOf("!status") != -1
            @timeout = true
            msg = "Running plug_p0ne v#{p0ne.version}"
            msg += " (incl. chat script)" if window.p0ne_chat
            msg += " and plug³ v#{require \plugCubed/Version}" if requirejs.defined \plugCubed/Version
            msg += " and plugplug #{getVersionShort!}" if window.ppSaved
            msg += ". Started #{ago p0ne.started}"
            console.log "[AUTORESPOND] '#msg @#{data.un}'"
            API.sendChat "#msg @#{data.un}"
            sleep 30min*60_000to_ms, ->
                @timeout = false
                console.info "[autoPostFaces] timeout reset"


module \_$contextUpdateEvent, do
    require: <[ _$context ]>
    setup: ({replace}) ->
        replace _$context, \on, \cb
        replace _$context, \off, \cb
    cb: (fn_) -> return (type, cb, context) ->
        fn_ ...
        _$context .trigger \context:update, type, cb, context

/*####################################
#                FIXES               #
####################################*/
module \simpleFixes, do
    setup: ({replace}) ->
        # kill p³'s Socket server
        # (as there is no functionality gained by using it. Only PMs are noteworthy, but those are broken)
        plugCubedLoaded .then ->
            replace require("plugCubed/Socket").__proto__, \connect, (->)

        # fix plug dying on a reconnect
        #NOTE: an initial ack is required to load the room. it is assumed, that this script is run AFTER the room is already loaded
        requireHelper {test: (.ack)} .ack = ->

        # hide social-menu (because personally, i only accidentally click on it. it's just badly positioned)
        $ \.social-menu .hide!
        $ \#chat-input-field .prop \tabIndex, 1
    disable: ->
        $ \.social-menu .show!

module \soundCloudThumbnailFix, do
    require: <[ auxiliaries ]>
    setup: ->
        auxiliaries.deserializeMedia = (e) !->
            e.author = this.h2t( e.author )
            e.title = this.h2t( e.title )
            if e.image
                e.image .= replace /^https?:\/\//, '//'


/*####################################
#             /COMMANDS              #
####################################*/
module \chatCommands, do
    callback:
        target: API
        event: API.CHATCOMMAND
        callback: (msg) ->
            if c = @commands[msg .split " " .0 .substr 1]
                substr = msg.substr(c.length + 2) # +2 because of the space and the truncated slash
                c = @commands[c] if typeof c == \string
                return false == c(substr, msg)
    commands: #NOTE: if a command doesn't apply, it must return FALSE, which will cause the message to be SEND, rather than executed (e.g. with /me)
        chat: (message) -> # To avoid the 10min link timeout
            if window._$context
                _$context.trigger \chat:send, message



/*####################################
#           FIX POPUP BUG            #
####################################*/
/*
#ToDo
module \fixPopup, callback:
    target: socket
    event: \connect
    callback: ->
        if $popup.css(\display) != \none
            console.log "===================\nfixed popup\n==================="
            $popup .hide!
        else
            sleep 200ms, ->
                console.log "===================\nlate fixed popup\n==================="
                $popup .hide!
*/


/*####################################
#            GRAB / CURATE           #
####################################*/
window.grab = null if window.grab.nodeType
module \grab, do
    optional: <[ Curate playlists]>
    module: (playlist) ->
        m = API.getMedia!
        if m
            console.log "[Curate] add '#{m.author} - #{m.title}' to playlist: #playlist"
        else
            return console.error "[Curate] no DJ is playing!"

        if Curate
            if typeof playlist == \string
                id = playlist; playlist = false
                if playlists
                    for pl in playlists when pl.id == id
                        playlist = pl; break
                else
                    console.warn "[grab] warning: using fallback, because the list of playlists couldn't be loaded"
            if playlist
                t = new Curate(4759858, [m], false)
                t
                    .on \success, ->
                        console.log("[grab] success", arguments)
                    .on \error, ->
                        console.log("[grab] error", arguments)
                return true
        if typeof playlist != \string
            console.error "[grab] error: can't curate to playlist by ID in fallback-mode (proper playlist module failed to load)"
        $ \#curate .click!
        <- sleep 500ms
        pls = $ '.pop-menu.curate ul span'
            .filter (-> @innerText == playlist)
            .mousedown!
        if not pls.length
            console.warn "[Curate] playlist '#playlist' not found", pls


/*####################################
#             ZALGO FIX              #
####################################*/
module \zalgoFix, do
    setup: ->
        css \zalgoFix, '
            .message {
                overflow: hidden;
            }
        '


/*####################################
#       TITLE FOR CURRENT SONG       #
####################################*/
module \titleCurrentSong, do
    disable: ->
        $ \#now-playing-media .prop \title, ""
    callback:
        target: API
        event: API.ADVANCE
        callback: (d) ->
            $ \#now-playing-media .prop \title, "#{d.media.author} - #{d.media.author}"


/*####################################
#           RESTORE CHAT             #
####################################*/
module \restoreChatScript, do
    require: <[ compressor ]>
    setup: ({addListener}, rCS) ->
        # Event Listeners
        addListener target: $(window), event: \beforeunload, callback: -> return "are you sure you want to leave?"
        addListener target: $(window), event: \unload, callback: -> window.restoreChatScript.save!

        if rCS.maxAge > Date.now! - rCS.savedChatTime
            rCS.restore!
        else if rCS.savedChatTime
            console.log "[rCS] not restoring chat from #{ago rCS.savedChatTime} (too old)"
            $cm .prepend do
                btn = $ \<button>
                    .text "force loading previous chatlog (#{ago rCS.savedChatTime})"
                    .click ->
                        window.restoreChatScript.restore!
                        $ this .remove!
        else
            console.error "[rCS] no chatlog found"
            API.chatLog "[rCS] no chatlog found", true

    module: do ->
        lssize_ = lssize!
        if lssize_ > 8
            API.chatLog "[rCS] WARNING: the LocalStorage is nearly full. Further chatlogs might not be saved. (#{formatMB lssize_} / 10MB)", true
        $cm = $ \#chat-messages
        hasCompressor = +!!compressor_
        savedChatTime = +localStorage.getItem \plugDjChatTime
        return do
            maxAge: 10min  *  1000to_s*60to_min
            savedChatTime: savedChatTime
            ago: ago new Date +
            save: ->
                btn? .remove!
                html = "#{+hasCompressor}|#{compressor.compress($cm .0 .innerHTML)}"
                #localStorage.setItem \plugDjChat, html
                localStorage.setItem \plugDjChatTime, Date.now!
                localStorage.setItem "plugDjChat-#{new Date! .toISOString!}", html
            restore: ->
                console.log "[rCS] restoring chat from #{rCS.ago}"
                html = localStorage.getItem "plugDjChat-#{new Date(savedChatTime) .toISOString!}"
                isCompressed = html.0
                html .= substr 2
                console.log "[rCS]", html.substr 0, 100

                if isCompressed # if compressed
                    console.info "[rCS] compressed"
                    if not hasCompressor
                        API.chatLog "[rCS] WARNING: couldn't load last chat because the it is compressed, but the compressor couldn't be loaded. Sorry =(", true
                        return
                    html = compressor.decompress html
                else
                    console.warn "[rCS] not compressed"
                $cm
                    ..prepend html
                    ..animate scrollTop: ..prop \scrollHeight, 1_000ms


/*####################################
#             YELLOW MOD             #
####################################*/
module \yellowMod, do
    setup: ->
        css \yellowMod, "
            \#chat .from-#{API.getUser! .id} .from {
                color: \#ffdd6f !important;
            }
        "


/*####################################
#      DISABLE MESSAGE DELETE        #
####################################*/
module \disableChatDelete, do
    require: <[ _$context ]>
    setup: ({replace_$Listener}) ->
        css \disableChatDelete, '
            .deleted {
                border-left: 2px solid red;
            }
            .deleted-message {
                display: block;
                text-align: right;
                color: red;
                font-family: monospace;
            }
        '
        replace_$Listener \chat:delete, ({data:{moderator, cid}}) -> # used to be \ChatFacadeEvent:delete before the big summer-2014-update
            wasAtBottom = isChatAtBottom?!
            $ ".cid-#{cid}"
                .addClass \deleted
                .append do
                    $ \<span>
                        .addClass \deleted-message
                        .text "deleted by #moderator at #{getISOTime?! or new Date!.toISOString!}"
            scrollChatDown?! if wasAtBottom

        replace_$Listener \ChatFacadeEvent:clear, ->
            t = getISOTime! || new Date() .toISOString!
            console.log """
                ======================
                [CHAT CLEAR]
                ======================
            """
            wasAtBottom = isChatAtBottom?!
            this.$chatMessages.append do
                $ \<div> .addClass "system drag-media-label"
                    .css top: 0
                    .append '<span class="text">
                            ~~~~~~~~~~~~~~~~<br>
                            CHAT GOT CLEARED<br>
                            ~~~~~~~~~~~~~~~~
                        </span>'
                    .append do
                        $ \<time>
                            .addClass \timestamp
                            .attr \datetime, t
                            .text t
            scrollChatDown?! if wasAtBottom


/*####################################
#           LOG EVERYTHING           #
####################################*/
module \logAllEvents, do
    require: <[ _$context ]>
    setup: ({replace}) ->
        replace _$context, \trigger, \trigger
    trigger: (trigger_) -> return (type) ->
        type_ = type
        if type == window.chat_send
            type_ = "chat:send*"
        if type.split(":").0 not in <[ tooltip chat sio popout playback playlist notify drag audience anim HistorySyncEvent ]>
            console.log "#{getTime!} [#type_]", getArgs!
        /*else if type == "chat:receive"
            data = &1
            console.log "#{getTime!} [CHAT]", "#{data.from.id}:\t", data.text, {data}*/
        return trigger_ ...

module \logChat, callback:
    target: API
    event: \chat
    callback: (data) ->
        console.log "#{getTime!} [CHAT]", "#{data.un}:\t", data.message


/*####################################
#             DEV TOOLS              #
####################################*/
module \downloadLink, do
    setup: -> @update!
    update: ->
        css \downloadLink, '
            .p0ne_downloadlink::before {
                content: " ";
                position: absolute;
                margin-top: -6px;
                margin-left: -27px;
                width: 30px;
                height: 30px;
                background-position: -140px -280px;
                background-image: url(/_/static/images/icons.26d92b9.png);
            }
        '
    module: (name, filename, data) ->
        if not data
            data = filename; filename = name
        data = JSON.stringify data if typeof data != \string
        url = URL.createObjectURL new Blob([data], {type: \text/plain})
        (window.$cm || $ \#chat-messages) .append "
            <div class='message p0ne_downloadlink'>
                <i class='icon'></i>
                <span class='text'>
                    <a href='#url' download='#filename'>#name</a>
                </span>
            </div>
        "


window <<<<
    rename: (newName) ->
        ajax \user.change_name_1, [newName]

    searchEvents: (regx) ->
        regx = new RegExp(regx, \i) if regx not instanceof RegExp
        return [k for k of _$context?._events when regx.test k]


    listUsers: ->
        res = ""
        for u in API.getUsers!
            res += "#{u.id}\t#{u.username}\n"
        console.log res
    listUsersByAge: ->
        a = API.getUsers! .sort (a,b) ->
            a = +a.dateJoined.replace(/\D/g,'')
            b = +b.dateJoined.replace(/\D/g,'')
            return (a > b && 1) || (a == b && 0) || -1

        for u in a
            console.log u.dateJoined.replace(/T|\..+/g, ' '), u.username

    getUserData: (user) !->
        if typeof user == \number
            return $.get "/_/users/#user"
                .then ({[user]:data}) ->
                    console.log "[userdata]", user
                    console.log "[userdata] https://plug.dj/@/#{encodeURI user.slug}" if user.level >= 5
                .fail ->
                    console.warn "couldn't get slug for user with id '#{id}'"
        else if typeof user == \string
            user .= toLowerCase!
            for u in API.getUsers! when u.username.toLowerCase! == user
                return getUserData u.id
            console.warn "[userdata] user '#user' not found"
            return null

    findModule: (test) ->
        res = []
        for id, module of require.s.contexts._.defined when module
            if test module, id
                module.id ||= id
                console.log "[findModule]", id, module
                res[*] = module
        return res

    compressOldChatlogs: ->
        lssize_ = lssize!
        console.log "[compressOldChatlogs] before: #{formatMB lssize_}"
        ls = localStorage
        for k of ls when 0 == k.indexOf "plugDjChat-"
            oldsize = ls[k].length / 524288
            if ls[k].0 == "0"
                ls[k] = "#{+hasCompressor}|#{compressor.compress(ls[k].substr 2)}"
                newsize = ls[k].length / 524288
                console.log "[compressOldChatlogs]", "'#k' [uncompressed] from #{formatMB oldsize} to #{formatMB newsize}"
            else if ls[k].0 != "1"
                ls[k] = "#{+hasCompressor}|#{compressor.compress(ls[k])}"
                newsize = ls[k].length / 524288
                console.log "[compressOldChatlogs]", "'#k' [oldformat] from #{formatMB oldsize} to #{formatMB newsize}"
            else
                console.log "[compressOldChatlogs]", "'#k' [compressed] untouched (#{formatMB oldsize})"
        lssizeNew = lssize!
        console.log "[compressOldChatlogs] compressed from #{formatMB lssize_} to #{formatMB lssizeNew} (#{(100 * lssizeNew / lssize_).toFixed(2)}%)"


module \renameUser, do
    require: <[ users ]>
    module: (idOrName, newName) ->
        u = users.get(idOrName)
        if not u
            idOrName .= toLowerCase!
            for user in users when user.attributes.username.toLowerCase! == idOrName
                u = user; break
        if not u
            return console.error "[rename user] can't find user with ID or name '#idOrName'"
        u.set \username, newName
        id = u.id

        if not rup = window.p0ne.renameUserPlugin 
            rup = window.p0ne.renameUserPlugin = (d) !->
                d.un = rup[d.fid] || d.un
            window.p0ne.chatPlugins?[*] = rup
        rup[id] = newName


do ->
    window._$events = {}
    for k,v of _$context?._events
        window._$events[k.replace(/:/g,'_')] = v


module \export_, do
    require: <[ downloadLink ]>
    exportRCS: ->
        # $ '.p0ne_downloadlink' .remove!
        for k,v of localStorage
            downloadLink "plugDjChat '#k'", k.replace(/plugDjChat-(.*?)T(\d+):(\d+):(\d+)\.\d+Z/, "$1 $2.$3.$4.html"), v

    exportPlaylists: ->
        # $ '.p0ne_downloadlink' .remove!
        for let pl in playlists
            $.get "/_/playlists/#{pl.id}/media" .then (data) ->
                downloadLink "playlist '#{pl.name}'",  "#{pl.name}.txt", data



/*@author jtbrinkmann aka. Brinkie Pie */
/*@license https://creativecommons.org/licenses/by-nc/4.0/ */
p0ne = window.p0ne
d = new Date
dayISO = d.toISOString! .substr(0, 10)
timezoneISO = -d.getTimezoneOffset!
timezoneISO = "#{Math.floor(timezoneISO / 60)}:#{timezoneISO % 60}"

chatWidth = 328px

window.database = requireHelper do
    name: \database
    id: \de369/f76f4/ea401'  # 2014-09-04
    test: (.settings)
    fallback:
        settings: chatTS: 24h

window.lang = requireHelper do
    name: \lang
    id: \lang/Lang
    test: (.welcome?.title)
    fallback:
        chat:
            delete: "Delete"

window.Chat = requireHelper do
    name: \Chat
    id: \de369/d86c0/e7368/eaad6/b2e50 # 2014-09-03
    test: (.::?.onDeleteClick)
    fallback: window.app?.room?.chat.constructor

window.ChatHelper = requireHelper do
    name: \ChatHelper
    id: \de369/ac84a/a8802 # 2014-09-03
    test: (it) -> return it.sendChat and it != window.API

window.Spinner = requireHelper do
    name: \Spinner
    id: \de369/d86c0/bf208/e0fc2 # 2014-09-03
    test: (.::?className == \spinner)
    #ToDo fallback


window.imgError = (elem) ->
    console.warn "[inline-img] converting image back to link", elem.alt, elem, elem.outerHTML
    $ elem .parent!
        ..text ..attr \href
        ..addClass \p0ne_img_failed

p0ne.pendingMessages ||= []
p0ne.failedMessages ||= []
p0ne.chatPlugins ||= []

roles = <[ none dj bouncer manager cohost host _ volunteer ambassador leader admin ]>

module \chatShowPending, do
    require: <[ ChatHelper user Spinner ]>
    setup: ({replace}) ->
        replace ChatHelper, \sendChat, -> chatShowPending.sendChat ...

        # every 5min, remove pending messages older than 5min
        repeat 300_000ms, -> # 5min
            d = Date.now! - 300_000ms
            for i from (p0ne.pendingMessages.length - 1) to 0 by -1 when p0ne.pendingMessages[i].timestamp < d
                p0ne.pendingMessages[i].el?.remove!
                p0ne.pendingMessages.remove i
    update: ->
        ChatHelper.sendChat = -> chatShowPending.sendChat ...

    sendChat: (e) ->
        console.log "[sendChat]"
        return if @chatCommand e
        e = e.replace(/</g, "&lt;").replace(/>/g, "&gt;") # b.cleanTypedString() for the poor
        _$context.trigger \chat:send, e
        d = new Date
        if {'/me ': true, '/em ': true}[e.substr 0, 4]
            e .= substr 4
            type = "emote pending"
        else
            type = "message pending"

        e .= replace(/\b(https?:\/\/[^\s\)\]]+)([\.,\?\!"']?)/g, '<a href="$1" target="_blank">$1</a>$2')
        p0ne_chat do
            message: e
            type: type
            un: user.username
            uid: user.id
            timestamp: "#{d.getHours!}:#{d.getMinutes!}"
            pending: true
        return true


module \p0ne_chat_plugins, do
    require: <[ _$context ]>
    setup: -> @enable!
    enable: ->
        _$context.onEarly \chat:receive, @cb
    disable: ->
        _$context.off \chat:receive, @cb
    cb: (message) -> # run plugins that modify chat messages
        message.wasAtBottom ?= chatIsAtBottom! # p0ne.saveChat also sets this

        # p0ne.chatPlugins
        for plugin in p0ne.chatPlugins
            message = plugin(message, t) || message

        # p0ne.chatLinkPlugins
        onload = ''
        onload = 'onload="chatScrollDown()"' if message.wasAtBottom
        message .= replace /<a (.+?)>((https?:\/\/)(?:www\.)?(([^\/]+).+?))<\/a>/, (all,pre,completeURL,protocol,domain,url)->
            &4 = onload
            for plugin in p0ne.chatLinkPlugins
                return that if plugin ...
            return all

# inline chat images & YT preview
chatWidth = 500px
module \chatInlineImages, do
    setup: ({add}) ->
        add p0ne.chatLinkPlugins, @plugin, {bound: true}
    plugin: (all,pre,completeURL,protocol,domain,url, onload) ->
        # images
        if @imgRegx[domain]
            [rgx, repl] = that
            img = url.replace(rgx, repl)
            if img != url
                console.log "[inline-img]", "[#plugin] #protocol#url ==> #protocol#img"
                return "<a #pre><img src='#protocol#img' class=p0ne_img #onload onerror='imgError(this)'></a>"

        # direct images
        if url.test /^[^\#\?]+\.(?:jpg|jpeg|gif|png|webp|apng)(?:@\dx)?(?:\?.*|\#.*)?$/
            console.log "[inline-img]", "[direct] #url"
            return "<a #pre><img src='#url' class=p0ne_img #onload onerror='imgError(this)'></a>"

        console.log "[inline-img]", "NO MATCH FOR #url (probably isn't an image)"
        return false

    imgRegx:
        \imgur.com :       [/^imgur.com\/(?:r\/\w+\/)?(\w\w\w+)/g, "i.imgur.com/$1.gif"]
        \prntscrn.com :    [/^(prntscr.com\/\w+)(?:\/direct\/)?/g, "$1/direct"]
        \gyazo.com :       [/^gyazo.com\/\w+/g, "i.$&/direct"]
        \dropbox.com :     [/^dropbox.com(\/s\/[a-z0-9]*?\/[^\/\?#]*\.(?:jpg|jpeg|gif|png|webp|apng))/g, "dl.dropboxusercontent.com$1"]
        \pbs.twitter.com : [/^(pbs.twimg.com\/media\/\w+\.(?:jpg|jpeg|gif|png|webp|apng))(?:\:large|\:small)?/g, "$1:small"]
        \googleImg.com :   [/^google\.com\/imgres\?imgurl=(.+?)(?:&|$)/g, (,src) -> return decodeURIComponent url]
        \imageshack.com :  [/^imageshack\.com\/[fi]\/(\w\w)(\w+?)(\w)(?:\W|$)/, -> chatInlineImages.imageshackPlugin ...]
        \imageshack.us :   [/^imageshack\.us\/[fi]\/(\w\w)(\w+?)(\w)(?:\W|$)/, -> chatInlineImages.imageshackPlugin ...]

    imageshackPlugin: (,host,img,ext) ->
        ext = {j: \jpg, p: \png, g: \gif, b: \bmp, t: \tiff}[ext]
        return "https://imagizer.imageshack.us/a/img#{parseInt(host,36)}/#{~~(Math.random!*1000)}/#img.#ext"


/* image plugins using plugCubed API (credits go to TATDK / plugCubed) */
module \chatInlineImages_plugCubedAPI, do
    require: <[ chatInlineImages ]>
    setup: ->
        chatInlineImages.imgRegx <<<< @imgRegx
    imgRegx:
        \deviantart.com :    [/^[\w\-\.]+\.deviantart.com\/(?:art\/|[\w:\-]+#\/)[\w:\-]+/, "https://api.plugCubed.net/redirect/da/$&"]
        \fav.me :            [/^fav.me\/[\w:\-]+/, "https://api.plugCubed.net/redirect/da/$&"]
        \sta.sh :            [/^sta.sh\/[\w:\-]+/, "https://api.plugCubed.net/redirect/da/$&"]
        \gfycat.com :        [/^gfycat.com\/(.+)/, "https://api.plugCubed.net/redirect/gfycat/$1"]

/* meme-plugins inspired by http://userscripts.org/scripts/show/154915.html (mirror: http://userscripts-mirror.org/scripts/show/154915.html while userscripts.org is down) */
module \chatInlineImages_memes, do
    require: <[ chatInlineImages ]>
    setup: ->
        chatInlineImages.imgRegx <<<< @imgRegx
    imgRegx:
        \quickmeme.com :     [/^(?:m\.)?quickmeme\.com\/meme\/(\w+)/, "i.qkme.me/$1.jpg"]
        \qkme.me :           [/^(?:m\.)?qkme\.me\/(\w+)/, "i.qkme.me/$1.jpg"]
        \memegenerator.net : [/^memegenerator\.net\/instance\/(\d+)/, "http://cdn.memegenerator.net/instances/#{chatWidth}x/$1.jpg"]
        \imageflip.com :     [/^imgflip.com\/i\/(.+)/, "i.imgflip.com/$1.jpg"]
        \livememe.com :      [/^livememe.com\/(\w+)/, "i.lvme.me/$1.jpg"]
        \memedad.com :       [/^memedad.com\/meme\/(\d+)/, "memedad.com/memes/$1.jpg"]
        \makeameme.org :     [/^makeameme.org\/meme\/(.+)/, "makeameme.org/media/created/$1.jpg"]


module \chatYoutubeThumbnails, do
    setup: ({add}) ->
        add p0ne.chatLinkPlugins, @plugin
        @animate .= bind this
        @animate.isbound = true
    update: ->
        @animate .= bind this if not @animate.isbound
    plugin: (all,pre,completeURL,protocol,domain,url, onload) ->
        yt = /https?:\/\/(?:www\.)?(?:youtube(?:-nocookie)?\.com\/(?:[^\/]+\/.+\/|(?:v|embed|e)\/|.*(?:\?|&amp;)v=)|youtu\.be\/)([^"&?\/<>\s]{11})(?:&.*?|#.*?|)$/i
            .exec(url)
        if yt and (yt = yt.1)
            console.log "[inline-img]", "[YouTube #yt] #url ==> http://i.ytimg.com/vi/#yt/0.jpg"
            return "
                <a class=p0ne_yt data-yt-cid='#yt' #pre>
                    <div class=p0ne_yt_icon></div>
                    <div class=p0ne_yt_img #onload style='background-image:url(http://i.ytimg.com/vi/#yt/0.jpg)'></div>
                    #url
                </a>
            " # no `onerror` on purpose # when updating the HTML, check if it breaks the animation callback
            # default.jpg for smaller thumbnail; 0.jpg for big thumbnail; 1.jpg, 2.jpg, 3.jpg for previews
        return false
    interval: -1
    frame: 1
    lastID: ''
    callback:
        target: $ \#chat
        event: 'mouseenter mouseleave'
        args: [ \.p0ne_yt_img ]
        bound: true
        callback: (e) ->
            clearInterval @interval
            # assuming that `e.target` always refers to the .p0ne_yt_img
            id = e.parentElement.dataset.ytCid
            img = e.target
            if e.type == \mouseenter
                if id != @lastID
                    @frame = 1
                    @lastID = id
                img.style.backgroundImage = "url(http://i.ytimg.com/vi/#id/#{@frame}.jpg)"
                @interval = repeat 1_000ms, @animate
                console.log "[p0ne_yt_preview]", "started", e, id, @interval
                #ToDo show YT-options (grab, open, preview, [automute])
            else
                img.style.backgroundImage = "url(http://i.ytimg.com/vi/#id/0.jpg)"
                console.log "[p0ne_yt_preview]", "stopped"
                #ToDo hide YT-options
    animate: ->
        console.log "[p0ne_yt_preview]", "showing 'http://i.ytimg.com/vi/#id/#{@frame}.jpg'"
        @frame = (@frame % 3) + 1
        img.style.backgroundImage = "url(http://i.ytimg.com/vi/#id/#{@frame}.jpg)"


/*@author jtbrinkmann aka. Brinkie Pie */
/*@license https://creativecommons.org/licenses/by-nc-sa/4.0/ */
/*
    based on BetterPonymotes https://ponymotes.net/bpm/
    note: even though this is part of the plug_p0ne script, it can also run on it's own with no dependencies 
    only the autocomplete feature will be missing without plug_p0ne

    for a ponymote tutorial see: http://www.reddit.com/r/mylittlepony/comments/177z8f/how_to_use_default_emotes_like_a_pro_works_for/
*/


host = window.p0ne?.host or "https://dl.dropboxusercontent.com/u/4217628/plug_p0ne"
window.emote_map = {}

/*== external sources ==*/
$.getScript "#host/bpm-resources.js"

$ \body .append """
    <link rel="stylesheet" href="#host/css/bpmotes.css" type="text/css">
    <link rel="stylesheet" href="#host/css/emote-classes.css" type="text/css">
    <link rel="stylesheet" href="#host/css/combiners-nsfw.css" type="text/css">
    <link rel="stylesheet" href="#host/css/gif-animotes.css" type="text/css">
    <link rel="stylesheet" href="#host/css/extracss-pure.css" type="text/css">
    <style>
    \#chat-suggestion-items .bpm-emote {
        max-width: 27px;
        max-height: 27px
    }
    </style>
"""


/*== constants ==*/
_FLAG_NSFW = 1
_FLAG_REDIRECT = 2

/*
 * As a note, this regexp is a little forgiving in some respects and strict in
 * others. It will not permit text in the [] portion, but alt-text quotes don't
 * have to match each other.
 */
/*                 [](/   <    emote   >   <    alt-text   >  )*/
emote_regexp = /\[\]\(\/([\w:!#\/\-]+)\s*(?:["']([^"]*)["'])?\)/g


/*== auxiliaries ==*/
/*
 * Escapes an emote name (or similar) to match the CSS classes.
 *
 * Must be kept in sync with other copies, and the Python code.
 */
sanitize_emote = (s) ->
    return s.toLowerCase!.replace("!", "_excl_").replace(":", "_colon_").replace("#", "_hash_").replace("/", "_slash_")


#== main BPM plugin ==
lookup_core_emote = (name, altText) ->
    # Refer to bpgen.py:encode() for the details of this encoding
    data = emote_map[name]
    return null if not data

    nameWithSlash = "/#name"
    parts = data.split '|'
    flag_data = parts.0
    tag_data = parts.1

    flags = parseInt(flag_data.slice(0, 1), 16)     # Hexadecimal
    source_id = parseInt(flag_data.slice(1, 3), 16) # Hexadecimal
    size = parseInt(flag_data.slice(3, 7), 16)      # Hexadecimal
    is_nsfw = (flags .&. _FLAG_NSFW)
    is_redirect = (flags .&. _FLAG_REDIRECT)

    tags = []
    start = 0
    while (str = tag_data.slice(start, start+2)) != ""
        tags.push(parseInt(str, 16)) # Hexadecimal
        start += 2

    if is_redirect
        base = parts.2
    else
        base = name

    return
        name: nameWithSlash,
        is_nsfw: !!is_nsfw
        source_id: source_id
        source_name: sr[source_id]
        max_size: size

        tags: tags

        css_class: "bpmote-" + sanitize_emote name
        base: base

        altText: altText

convert_emote_element = (info, parts) ->
    title = "#{info.name} from #{info.source_name}".replace /"/g, ''
    flags = ""
    for flag,i in parts when i>0
        /* Normalize case, and forbid things that don't look exactly as we expect */
        flag = sanitize_emote flag.toLowerCase!
        flags += " bpflag-#flag" if not /\W/.test flag

    if info.is_nsfw
        title = "[NSFW] #title" if info.is_nsfw
        flags += " bpm-nsfw"

    return "<span class='bpflag-in bpm-emote #{info.css_class} #flags' title='#title' data-bpm_emotename='#{info.name}'>#{info.altText or ''}</span>"
    # data-bpm_srname='#{info.source_name}'


window.bpm = (str) ->
    str.replace emote_regexp, (_, parts, altText) ->
        parts .= split '-'
        name = parts.0
        info = lookup_core_emote name, altText
        if not info
            return _
        else
            return convert_emote_element info, parts

if window.p0ne?.chatPlugins
    /* add BPM as a p0ne chat plugin */
    window.p0ne.chatPlugins[*] = window.bpm
else do ->
    /* add BPM as a standalone script */
    if not window._$context
        module = window.require.s.contexts._.defined[\b1b5f/b8d75/c3237] /* ID as of 2014-09-03 */
        if module and module._events?[\chat:receive]
            window._$context = module
        else
            for id, module of require.s.contexts._.defined when module and module._events?[\chat:receive]
                window._$context = module
                break

    window._$context._events[\chat:receive] .unshift do
        callback: (d) !->
            d.message = bpm(d.message)

$(window) .one \p0ne_emotes_map, ->
    console.log "== Ponymotes loaded =="
    /* ponify old messages */
    $ '#chat .text' .html ->
        return window.bpm this.innerHTML

    /* add autocomplete if/when plug_p0ne and plug_p0ne.autocomplete are loaded */
    cb = ->
        addAutocompletion? do
            name: "Ponymotes"
            data: Object.keys(emote_map)
            pre: "[]"
            check: (str, pos) ->
                if !str[pos+2] or str[pos+2] == "(" and (!str[pos+3] or str[pos+3] == "(/")
                    temp = /^\[\]\(\/([\w#\\!\:\/]+)(\s*["'][^"']*["'])?(\))?/.exec(str.substr(pos))
                    if temp
                        @data = temp.2 || ''
                        return true
                return false
            display: (items) ->
                return [{value: "[](/#emote)", image: bpm("[](/#emote)")} for emote in items]
            insert: (suggestion) ->
                return "#{suggestion.substr(0, suggestion.length - 1)}#{@data})"
    if window.addAutocompletion
        cb!
    else
        $(window) .one \p0ne_autocomplete, cb

/*@author jtbrinkmann aka. Brinkie Pie */
/*@license https://creativecommons.org/licenses/by-nc/4.0/ */
#ToDo check why song-stats aren't properly CSS-justified
/*
module ||= (name, {callback:{target, event, callback}}) ->
    # module() for the poor
    if not window[name]
        target.on event, -> window[name] ...
    window[name] = callback
requireHelper = ({id, test, fallback}:a) ->
    if typeof a == \function
        test = a
    module = require.s.contexts._.defined[id] if id
    if module and test module
        module.id ||= id
        return module
    else
        for id, module of require.s.contexts._.defined when module
            if test module, id
                module.id ?= id
                console.warn "[requireHelper] module '#{module.name}' updated to ID '#id'"
                return module
        return fallback
*/
$ "<link href='#{p0ne.host}/p0ne.notif.css' rel='stylesheet' type='text/css'>" .appendTo \body
icon = (name) ->
    return "<i class='icon icon-#name'></i>"
mediaURL = (media) ->
    if media.format == 1 # YouTube
        return "http://youtube.com/watch?v=#{media.cid}"
    else if media.format == 2 # SoundCloud
        #ToDo improve this
        return "https://soundcloud.com/#{media.author}/#{media.title.replace(/[^\s\w]+/g, '').replace(/\s+/g, '-')}"

module \songNotifications, callback:
    target: API
    event: API.ADVANCE
    callback: (d) ->
        skipped = false #ToDo
        skipper = reason = "" #ToDo

        window.d = d
        console.log "[DJ ADVANCE]", d

        $div = $ \<div> .addClass \update .addClass \song-notif
        html = ""
        /*
        if d.lastPlay
            html += "
                <div class='song-notif-last'>
                    <div class='song-stats'>
                        <span class='song-woots'>#{icon \history-positive}#{d.lastPlay.score.positive} </span>
                        <span class='song-mehs'>#{icon \history-negative}#{d.lastPlay.score.negative} </span>
                        <span class='song-grabs'>#{icon \history-grabs}#{d.lastPlay.score.grabs}</span>
                    </div>
                </div>
            " #note: the spaces in .song-stats are obligatory! otherwise justify won't work
            if skipped
                html += "<div class='song-skipped'>"
                html +=     "<span class='song-skipped-by'>#skipper</span>"
                html +=     "<span class='song-skipped-reason'>#reason</span>" if reason
                html += "</div>"
        */
        if d.media
            media = d.lastPlay.media
            if media.format == 1
                ytID = "data-yt-id='#{media.id}' data-yt-cid='#{media.cid}'"
            else
                ytID = ""
            html += "
                <div class='song-notif-next'>
                    <div class='song-thumb-wrapper'>
                        <img class='song-thumb' #ytID src='#{media.image}' />
                        <div class='song-add' #ytID><i class='icon icon-add'></i></div>
                        <a class='song-open' href='#{mediaURL media}' target='_blank'><i class='icon icon-chat-popout'></i></a>
                    </div>
                    <div class='song-dj'></div>
                    <b class='song-title'></b>
                    <span class='song-author'></span>
                </div>
            "
        $div.html html
        $div .find \.song-dj .text d.dj.username
        $div .find \.song-title .text d.media.title .prop \title, d.media.title
        $div .find \.song-author .text d.media.author

        appendChat $div


window.popup = requireHelper do
    name: \pop-menu
    id: \de369/d86c0/b0607/e1fa4 # 2014-09-04
    test: (.className == \pop-menu)

$ \body .off \click, \.song-add, window.fn
wrap = (obj) ->
    obj.get = (name) ->
        console.log "[get]", name, this[name], arguments.callee.caller.arguments
        return this if name == \media
        a = this[name]
        if a
            return if typeof a == \object then wrap(a) else a
        else
            return null
    return obj
window.fn = ->
    el = $(this)
    msg = el.closest(".song-notif")
    id = el.data \yt-id

    msgOffset = msg.offset!
    el.offset = -> # to fix position
        return { top: msgOffset.top + 13, left: msgOffset.left + 12 }

    obj = [wrap({id: id, format: 1})] #ToDo make compatible with Soundcloud

    window <<<< { el, obj, msg, msgOffset }

    popup.isShowing = false
    popup.show(el, obj)


$ \body .on \click, \.song-add, window.fn

# window <<<< {module, icon, requireHelper, mediaURL, appendChat, popup, wrap}