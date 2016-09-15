/**
 * Auxiliary-functions for plug_p0ne
 *
 * @author jtbrinkmann aka. Brinkie Pie
 * @license MIT License
 * @copyright (c) 2015 J.-T. Brinkmann
*/

export $window = $ window
export $body = $ document.body

/**/ # RequireJS fix
window.require = window.requirejs
window.define = window.requirejs.define

/*/ # no RequireJS fix
(localforage) <- require <[ localforage ]>
/**/
export localforage


/*####################################
#         PROTOTYPE FUNCTIONS        #
####################################*/
# helper for defining non-enumerable functions via Object.defineProperty
tmp = (property, value) !-> if @[property] != value then Object.defineProperty this, property, {-enumerable, +writable, +configurable, value}
tmp.call Object::, \define, tmp
Object::define \defineGetter, (property, get) !-> if @[property] != get then Object.defineProperty this, property, {-enumerable, +configurable, get}

Object::define \hasAttribute, (property) !-> return property of this

Array::define \remove, (i) !-> return @splice i, 1
Array::define \removeItem, (el) !->
    if -1 != (i = @indexOf(el))
        @splice i, 1
    return this
Array::define \random, !-> return this[~~(Math.random! * @length)]
Array::define \unique, !->
    res = []; l=0
    for el, i in this
        for o til i
            break if @[o] == el
        else
            res[l++] = el
    return res
Array::define \joinWrapped, (pre, post, between) !->
    return "" if @length == 0
    pre ||= ''; post ||= ''; between ||= ''
    res = "#pre#{@0}#post"
    for i from 1 til @length
        res += "#between#pre#{@[i]}#post"
    return res

String::define \reverse, !->
    res = ""
    i = @length
    while i--
        res += @[i]
    return res
String::define \startsWith, (str) !->
    i=str.length
    while i>0
        return false if str[--i] != this[i]
    return true
String::define \endsWith, (str) !->
    i=str.length; o=@length - i
    while i>0
        return false if str[--i] != this[o+i]
    return true
String::define \replaceSansHTML, (rgx, rpl) !->
    # this acts like .replace, but avoids HTML tags and their content
    return this .replace /(.*?)(<(?:br>|.*?>.*?<\/\w+>|.*?\/>)|$)/gi, (,pre, post) !->
        return "#{pre .replace(rgx, rpl)}#post"

for Constr in [String, Array]
    Constr::define \has, (needle) !-> return -1 != @indexOf needle
    Constr::define \hasAny, (needles) !->
        for needle in needles when -1 != @indexOf needle
            return true
        return false

Number::defineGetter \s,   !-> return this *     1_000s_to_ms
Number::defineGetter \min, !-> return this *    60_000min_to_ms
Number::defineGetter \h,   !-> return this * 3_600_000h_to_ms


jQuery.fn <<<<
    indexOf: (selector) !->
        /* selector may be a String jQuery Selector or an HTMLElement */
        if @length and selector not instanceof HTMLElement
            i = [].indexOf.call this, selector
            return i if i != -1
        for el, i in this when jQuery(el).is selector
            return i
        return -1

    concat: (arr2) !->
        l = @length
        return this if not arr2 or not arr2.length
        return arr2 if not l
        for el, i in arr2
            @[i+l] = el
        @length += arr2.length
        return this
    fixSize: !-> #… only used in saveChat so far
        for el in this
            el.style .width = "#{el.width}px"
            el.style .height = "#{el.height}px"
        return this
    loadAll: (cb) !-> # adds an event listener for when all elements are loaded
        remaining = @length
        if not cb or not remaining
            _.defer cb!
        else
            @load !->
                if --remaining == 0
                    cb!
        return this
    binaryGuess: (checkFn) !->
        # returns element with index `n` for which:
        # if checkFn(element) for all elements in this from 0 to `n` all returns false,
        # and for all elements in this from `n` to the last one returns true
        # returns an empty jQuery object if there is no matching `n`
        # (i.e. checkFn(element) returns false for all elements, or this object is empty)
        # example use case: find the first item that is visible in a scrollable list

        step = @length
        if step == 0 or not checkFn @[step-1], step, @[step-1] # test this.length and last element
            return $!
        else if checkFn.call @0, 0, @0 # test first element
            return @first!

        i = @length - 1
        goingUp = true
        do
            step = ~~(step / 2)
            if checkFn.call @[i], i, @[i]
                goingUp = false
                i = Math.floor(i - step)
            else
                goingUp = true
                i = Math.ceil(i + step)
                console.log "going up to #i (#step)"
        while step > 0
        i++ if goingUp
        return @eq i

$.easing <<<<
    easeInQuad: (p) !->
        return p * p
    easeOutQuad: (p) !->
        return 1-(1-p)*(1-p)



/*####################################
#            DATA MANAGER            #
####################################*/
# compress to invalid UTF16 to save space, if supported by the browser. compress to valid UTF16 if not
if window.chrome
    window{compress, decompress} = LZString
else
    window{compressToUTF16:compress, decompressFromUTF16:decompress} = LZString

# function to load data using localforage, decompress it and parse it as JSON
window.dataLoad = (name, defaultVal={}, callback/*(err, data)*/) !->
    if p0ne.autosave[name]
        p0ne.autosave_num[name]++
        return callback(null, p0ne.autosave[name])
    p0ne.autosave_num[name] = 0

    #if localStorage[name]
    localforage.getItem name, (err, data) !->
        if err
            warning = "failed to load '#name' from localforage"
            errorCode = \localforage
        else if data
            p0ne.autosave[name] = data
            return callback err, data
            /*
            if decompress(data)
                try
                    p0ne.autosave[name]=JSON.parse(that)
                    return callback err, p0ne.autosave[name]
                catch err
                    warning = "failed to parse '#name' as JSON"
                    errorCode = \JSON
            else
                warning = "failed to decompress '#name' data"
                errorCode = \decompress
            */
        else
            p0ne.autosave[name]=defaultVal
            return callback err, defaultVal

        # if data failed to load
        name_ = "#{name}_#{getISOTime!}"
        console.warn "#{getTime!} [dataLoad] #warning, it seems to be corrupted! making a backup to '#name_' and continuing with default value", err
        #localStorage[name_]=localStorage[name]
        localforage.setItem name_, data
        p0ne.autosave[name] = defaultVal
        callback new TypeError("data corrupted (#errorCode)"), defaultVal

window.dataLoadAll = (defaults, callback/*(err, data)*/) !->
    /*defaults is to be in the format `{name: defaultVal, name2: defaultVal2, …}` where `name` is the name of the data to load */
    remaining = 0; for name of defaults then remaining++
    if remaining == 0
        callback(null, {})
    else
        errors = {}; hasError = false
        res = {}
        for let name, defaultVal of defaults
            dataLoad name, defaultVal, (err, data) !->
                if err
                    hasError := true
                    errors[name] = err
                res[name] = data
                if --remaining == 0
                    errors := null if not hasError
                    callback(errors, res)

window.dataUnload = (name) !->
    if p0ne.autosave_num[name]
        p0ne.autosave_num[name]--
    if p0ne.autosave_num[name] == 0
        delete p0ne.autosave[name]
window.dataSave = !->
    err = ""
    for k,v of p0ne.autosave when v
        for _ of v # check if `v` is not an empty object
            try
                localforage.setItem k, v #compress(v.toJSON?! || JSON.stringify(v))
            catch
                err += "failed to store '#k' to localStorage\n"
            break
    if err
        alert err
    else
        console.log "[Data Manager] saved data"
$window .on \beforeunload, dataSave
dataSave.interval = setInterval dataSave, 15.min



/*####################################
#            DATA EMITTER            #
####################################*/
# a mix between a Promise and an EventEmitter
# initially, its data (`_data`) is not set (think of a Promise's state being "pending").
# Event listeners can be attached with `.on(type, fn, ctx?)` or the shorthands `.data(fn, ctx?)` and `.cleared(fn, ctx?)`.
# Everytime its data is set (using `.set(data)`) all "data" event listeners are executed with the data (similar to resolving a Promise),
# except if `.set(newData)` is called with the same data as already present (`oldData === newData`), then no event listener is executed.
# While its data is set, newly attached "data" handlers are immediately called with the data. (similar to resolved Promises)
# Unlike Promises' state, the data is not immutable, it can be changed again (using `.set(newData)` again).
# The data can be cleared (using `.clear()`), and if data was set before, all "cleared" event listeners are executed with `undefined`
# With event listeners attached with `.on("all", fn, ctx?)` will be executed on all "data" and "cleared" events.
# Note:
#   - The data can be set to another without clearing it first
#   - "cleared" event listeners will NOT be immediately triggered
#   - If you want to read the data from outside an event listener, use `._data`
#     Remember that `.data` is a shorthand for `.on("data", fn, ctx?)`!
#   - A DataEmitter can theoretically also have other events than "data" and "cleared".
#     Please keep in mind, that other scripts might not expect "all" to be triggered by other events
#
# An example for a DataEmitter is the roomSettings module with the data being the room's p3-compatible room settings (if any).
# The roomTheme module applies the room theme everytime the room's settings are loaded (e.g. after joining a room with them),
# so roomSettings is regarded like a Promise, waiting for when the data is loaded.
# If however the room settings are already loaded, the callback should be immediately executed.
# But if another room is joined (or the room's settings change), it should be executed again.
#
# To create a plug_p0ne module as a DataEmitter, use `module(moduleName, { module: new DataEmitter(moduleName), … })`
export class DataEmitter extends {prototype: Backbone.Events}
    (@_name) !->
    _name: 'unnamed DataEmitter'
    set: (newData) !->
        if @_data != newData
            @_data = newData
            @trigger \data, @_data
        return this
    clear: !->
        delete @_data
        @trigger \cleared
        return this

    on: (type, fn, context) !->
        super ...
        # immediately execute "data" and "all" events
        if @_data and type in <[ data all ]>
            try
                fn .call context||this, @_data
            catch e
                console.error "[#{@_name}] Error while triggering #type [#{@_listeners[type].length - 1}]", this, args, e.stack
        return this
    # shorthands
    data: (fn, context) !-> return @on \data, fn, context
    cleared: (fn, context) !-> return @on \cleared, fn, context

/*####################################
#         GENERAL AUXILIARIES        #
####################################*/
$dummy = $ \<a>
window <<<<
    YT_REGEX: /https?:\/\/(?:www\.)?(?:youtube(?:-nocookie)?\.com\/(?:[^\/]+\/.+\/|(?:v|embed|e)\/|.*(?:\?|&amp;)v=)|youtu\.be\/)([^"&?\/<>\s]{11})(?:&.*?|#.*?|)$/i
    repeat: (timeout, fn) !-> return setInterval (!-> fn ... if not disabled), timeout
    sleep: (timeout, fn) !-> return setTimeout fn, timeout
    throttle: (timeout, fn) !-> return _.throttle fn, timeout
    pad: (num, digits) !->
        if digits
            return "#num" if not isFinite num
            a = ~~num
            b = "#{num - a}"
            num = "#a"
            while num.length < digits
                num = "0#num"
            return "#num#{b .substr 1}"
        else
            return
                if 0 <= num < 10 then "0#num"
                else             then "#num"

    generateID: !-> return (~~(Math.random!*0xFFFFFF)) .toString(16).toUpperCase!



    getUser: (user) !->
        return if not user
        if typeof user == \object
            return that if user.id and getUser(user.id)
            if user.username
                return user
            else if user.attributes and user.toJSON
                return user.toJSON!
            else if user.username || user.dj || user.user || user.uid
                return getUser(that)
            return null
        userList = API.getUsers!
        if +user
            if users?.get? user
                return that .toJSON!
            else
                for u in userList when u.id == user
                    return u
        else if typeof user == \string
            for u in userList when u.username == user
                return u
            user .= toLowerCase!
            for u in userList when u.username .toLowerCase! == user
                return u
        else
            console.warn "unknown user format", user
    getUserInternal: (user) !->
        return if not user or not users
        if typeof user == \object
            return that if user.id and getUserInternal(user.id)
            if user.attributes
                return user
            else if user.username || user.dj || user.user || user.id
                return getUserInternal(that)
            return null

        if +user
            return users.get user
        else if typeof user == \string
            for u in users.models when u.get(\username) == user
                return u
            user .= toLowerCase!
            for u in users.models when u.get(\username) .toLowerCase! == user
                return u
        else
            console.warn "unknown user format", user

    logger: (loggerName, fn) !->
        if typeof fn == \function
            return !->
                console.log "[#loggerName]", arguments
                return fn ...
        else
            return !-> console.log "[#loggerName]", arguments

    replace: (context, attribute, cb) !->
        context["#{attribute}_"] ||= context[attribute]
        context[attribute] = cb(context["#{attribute}_"])

    loadScript: (loadedEvent, data, file, callback) !->
        d = $.Deferred!
        d.then callback if callback

        if data
            d.resolve!
        else
            $.getScript "#{p0ne.host}/#file"
            $ window .one loadedEvent, d.resolve #Note: .resolve() is always bound to the Deferred
        return d.promise!

    requireHelper: (name, test, {id, onfail, fallback}=0) !->
        if (module = window[name] || require.s.contexts._.defined[id]) and test module
            id = module.requireID
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
            res.requireID = id
            window[name] = res if name
            return res
        else
            console.error "[requireHelper] could not require '#name'"
            onfail?!
            window[name] = fallback if name
            return fallback
    requireAll: (test) !->
        return [m for id, m of require.s.contexts._.defined when m and test(m, id)]


    /* callback gets called with the arguments cb(errorCode, response, event) */
    floodAPI_counter: 0
    ajax: (type, url, data, cb) !->
        if typeof url != \string
            [url, data, cb] = [type, url, data]
            type = data?.type || \POST
        if typeof data == \function
            success = data; data = null
        else if typeof cb == \function
            success = cb
        else if data and (data.success or data.error)
            {success, error} = data
            delete data.success
            delete data.error
        else if typeof cb == \object
            {success, fail} = cb if cb

        if data
            silent = data.silent
            delete data.type
            delete data.silent
        # data ||= {}
        # data.key = p0ne.PLUG_KEY
        options = do
                type: type
                url: "https://plug.dj/_/#url"
                contentType: \application/json
                data: JSON.stringify(data)
                success: ({data}) !->
                    console.info "[#url]", data if not silent
                    success? data
                error: (err) !->
                    console.error "[#url]", data if not silent
                    error? data

        def = $.Deferred!
        do delay = !->
            if window.floodAPI_counter >= 15 /* 20 requests / 10s will trigger socket:floodAPI. This should leave us enough buffer in any case */
                sleep 1_000ms, delay
            else
                window.floodAPI_counter++; sleep 10_000ms, !-> window.floodAPI_counter--
                return $.ajax options
                    .then def.resolve, def.reject, def.progress
        return def

    befriend: (userID, cb) !-> ajax \POST, "friends", id: userID, cb
    ban: (userID, cb) !-> ajax \POST, "bans/add", userID: userID, duration: API.BAN.HOUR, reason: 1, cb
    banPerma: (userID, cb) !-> ajax \POST, "bans/add", userID: userID, duration: API.BAN.PERMA, reason: 1, cb
    unban: (userID, cb) !-> ajax \DELETE, "bans/#userID", cb
    modMute: (userID, cb) !-> ajax \POST, "mutes/add", userID: userID, duration: API.MUTE.SHORT, reason: 1, cb
    modUnmute: (userID, cb) !-> ajax \DELETE, "mutes/#userID", cb
    chatDelete: (chatID, cb) !-> ajax \DELETE, "chat/#chatID", cb
    kick: (userID, cb) !->
        def = $.Deferred!
        ban userID
            .then !->
                unban userID, cb
                    .then def.resolve, def.reject
            .fail def.reject
    addDJ: (userID, cb) !->
        for u in API.getWaitList! when u.id == userID
            # specified user is in the waitlist
            cb \alreadyInWaitlist
            return $.Deferred! .resolve \alreadyInWaitlist
        else
            return ajax \POST, "booth/add", id: userID, cb
    moveDJ: (userID, position, cb) !->
        def = $.Deferred
        addDJ userID
            .then !->
                ajax \POST, "booth/move", userID: userID, position: position, cb
                    .then def.resolve, def.reject
            .fail def.reject
        return def .promise!

    joinRoom: (slug) !->
        return ajax \POST, \rooms/join, {slug}

    getUserData: (user, cb) !->
        if typeof user != \number
            user = getUser user
        cb ||= (data) !-> console.log "[userdata]", data, (if data.level >= 5 then "https://plug.dj/@/#{encodeURI data.slug}")
        return $.get "/_/users/#user"
            .then ({[data]:data}:arg) !->
                return data
            .fail !->
                console.warn "couldn't get slug for user with id '#{id}'"

    $djButton: $ \#dj-button
    mute: !->
        return $ '#volume .icon-volume-half, #volume .icon-volume-on' .click! .length
    muteonce: !->
        mute!
        muteonce.last = API.getMedia!.id
        API.once \advance, !->
            unmute! if API.getMedia!.id != muteonce.last
    unmute: !->
        return $ '#playback .snoozed .refresh, #volume .icon-volume-off, #volume .icon-volume-mute-once'.click! .length
    snooze: !->
        return $ '#playback .snooze' .click! .length
    isSnoozed: !-> $ \#playback-container .children! .length == 0
    refresh: !->
        return $ '#playback .refresh' .click! .length
    stream: (val) !->
        if not currentMedia
            console.error "[p0ne /stream] cannot change stream - failed to require() the module 'currentMedia'"
        else
            database?.settings.streamDisabled = (val != true and (val == false or currentMedia.get(\streamDisabled)))
    join: !->
        # for this, performance might be essential
        # return $ '#dj-button.is-wait' .click! .length != 0
        if $djButton.hasClass \is-wait
            $djButton.click!
            return true
        else
            return false
    leave: !->
        return $ '#dj-button.is-leave' .click! .length != 0

    $wootBtn: $ \#woot
    woot: !-> $wootBtn .click!
    $mehBtn: $ \#meh
    meh: !-> $mehBtn .click!

    ytItags: do !->
        resolutions = [ 72p, 144p, 240p,  360p, 480p, 720p, 1080p, 1440p, 2160p, 2304p, 3072p, 4320p ]
        list =
            # DASH-only content is commented out, as it is not yet required
            * ext: \flv, minRes: 240p, itags: <[ 5 ]>
            * ext: \3gp, minRes: 144p, itags:  <[ 17 36 ]>
            * ext: \mp4, minRes: 240p, itags:  <[ 83 18,82 _ 22,84 85 ]>
            #* ext: \mp4, minRes: 144p, itags:  <[ 160 133 134 135 136 137 264 138 ]>, type: \video-only
            #* ext: \mp4, minRes: 720p, itags:  <[ 298 299 ]>, fps: 60, type: \video-only
            #* ext: \mp4, minRes: 128kbps, itags:  <[ 140 ]>, type: \audio
            * ext: \webm, minRes: 360p, itags:  <[ 43,100 ]>
            #* ext: \webm, minRes: 240p, itags:  <[ 242 243 244 247 248 271 272 ]>, type: \video-only
            #* ext: \webm, minRes: 720p, itags:  <[ 302 303 ]>, fps: 60, type: \video-only
            #* ext: \webm, minRes: 144p, itags:  <[ 278 ]>, type: \video-only
            #* ext: \webm, minRes: 128kbps, itags:  <[ 171 ]>, type: \audio
            * ext: \ts, minRes: 240p, itags:  <[ 151 132,92 93 94 95 96 ]> # used for live streaming
        ytItags = {}
        for format in list
            for itags, i in format.itags when itags != \_
                # formats with type: \audio not taken into account ignored here
                startI = resolutions.indexOf format.minRes
                for itag in itags.split ","
                    if resolutions[startI + i] == 2304p
                        console.log itag
                    ytItags[itag] =
                        itag: itag
                        ext: format.ext
                        type: format.type || \video
                        resolution: resolutions[startI + i]
        return ytItags

    mediaSearch: (query) !->
        # open playlist drawer
        $ '#playlist-button .icon-playlist'
            .click! # will silently fail if playlist is already open, which is desired

        $ \#search-input-field
            .val query # enter search string
            .trigger do # start search
                type: \keyup
                which: 13 # Enter

    mediaParse: (media, cb) !->
        /* work in progress */
        cb ||= logger \
        if typeof media == \string
            if +media # assume SoundCloud CID
                cb {format: 2, cid: media}
            else if media.length == 11 # assume youtube CID
                cb {format: 1, cid: media}
            else if cid = YT_REGEX .exec(media)?.1
                cb {format: 1, cid}
            else if parseURL media .hostname in <[ soundcloud.com  i1.sndcdn.com ]>
                $.getJSON "https://api.soundcloud.com/resolve/", do
                    url: url
                    client_id: p0ne.SOUNDCLOUD_KEY
                    .then (d) !->
                        cb {format: 2, cid: d.id, data: d}
        else if typeof media == \object and media
            if media.toJSON
                cb media.toJSON!
            else if media.format
                cb media
        else if not media
            cb API.getMedia!
        cb!

    mediaLookup: ({format, id, cid}:url, cb) !->
        if typeof cb == \function
            success = cb
        else
            if typeof cb == \object
                {success, fail} = cb if cb
            success ||= (data) !-> console.info "[mediaLookup] #{<[yt sc]>[format - 1]}:#cid", data
        fail ||= (err) !-> console.error "[mediaLookup] couldn't look up", cid, url, cb, err
        def = $.Deferred()
        def.then(success, fail)

        if typeof url == \string
            if cid = YT_REGEX .exec(url)?.1
                format = 1
            else if parseURL url .hostname in <[ soundcloud.com  i1.sndcdn.com ]>
                format = 2
        else
            cid ||= id

        if window.mediaLookup.lastID == (cid || url) and window.mediaLookup.lastData
            success window.mediaLookup.lastData
        else
            window.mediaLookup.lastID = cid || url
            window.mediaLookup.lastData = null
        if format == 1 # youtube
            /*# Youtube API v2
            $.getJSON "https://gdata.youtube.com/feeds/api/videos/#cid?v=2&alt=json"
                .fail fail
                .success (d) !->
                    cid = d.entry.id.$t.substr(27)
                    def.resolve do
                        window.mediaLookup.lastData =
                            format:       1
                            data:         d
                            cid:          cid
                            uploader:
                                name:     d.entry.author.0.name.$t
                                id:       d.entry.media$group.yt$uploaderId.$t
                                url:      "https://www.youtube.com/channel/#{d.entry.media$group.yt$uploaderId.$t}"
                            image:        "https://i.ytimg.com/vi/#cid/0.jpg"
                            title:        d.entry.title.$t
                            uploadDate:   d.entry.published.$t
                            url:          "https://youtube.com/watch?v=#cid"
                            description:  d.entry.media$group.media$description.$t
                            duration:     d.entry.media$group.yt$duration.seconds # in s

                            restriction:  if d.data.entry.media$group.media$restriction
                                blocked: that
            */
            # Youtube API v3
            $.getJSON "https://www.googleapis.com/youtube/v3/videos?part=contentDetails,snippet&maxResults=1&id=#cid&key=#{p0ne.YOUTUBE_V3_KEY}"
                .fail fail
                .success ({items: [d]}) !->
                    cid = d.id
                    duration = 0
                    if /PT(\d+)M(\d+)S/.exec d.contentDetails.duration
                        duration = that.1 * 60 + that.2
                    def.resolve do
                        window.mediaLookup.lastData =
                            format:       1
                            data:         d
                            cid:          cid
                            uploader:
                                name:     d.snippet.channelTitle
                                id:       d.snippet.channelId
                                url:      "https://www.youtube.com/channel/#{d.snippet.channelId}"
                            image:        "https://i.ytimg.com/vi/#cid/0.jpg"
                            title:        d.snippet.title
                            uploadDate:   d.snippet.publishedAt
                            url:          "https://youtube.com/watch?v=#cid"
                            description:  d.snippet.description
                            duration:     duration # in s

                            restriction: d.contentDetails.regionRestriction
        else if format == 2
            if cid
                req = $.getJSON "https://api.soundcloud.com/tracks/#cid.json", do
                    client_id: p0ne.SOUNDCLOUD_KEY
            else
                req = $.getJSON "https://api.soundcloud.com/resolve/", do
                    url: url
                    client_id: p0ne.SOUNDCLOUD_KEY
            req
                .fail fail
                .success (d) !->
                    def.resolve do
                        window.mediaLookup.lastData =
                            format:         2
                            data:           d
                            cid:            cid
                            uploader:
                                id:         d.user.id
                                name:       d.user.username
                                image:      d.user.avatar_url
                                url:        d.user.permalink_url
                            image:          d.artwork_url
                            title:          d.title
                            uploadDate:     d.created_at
                            url:            d.permalink_url
                            description:    d.description
                            duration:       d.duration / 1000ms_to_s # in s

                            download:       if d.download_url then d.download_url + "?client_id=#{p0ne.SOUNDCLOUD_KEY}" else false
                            downloadSize:   d.original_content_size
                            downloadFormat: d.original_format
        else
            def .reject "unsupported format"
        return def
    # https://www.youtube.com/annotations_invideo?video_id=gkp9ohUPIuo
    # AD,AE,AF,AG,AI,AL,AM,AO,AQ,AR,AS,AT,AU,AW,AX,AZ,BA,BB,BD,BE,BF,BG,BH,BI,BJ,BL,BM,BN,BO,BQ,BR,BS,BT,BV,BW,BY,BZ,CA,CC,CD,CF,CG,CH,CI,CK,CL,CM,CN,CO,CR,CU,CV,CW,CX,CY,CZ,DE,DJ,DK,DM,DO,DZ,EC,EE,EG,EH,ER,ES,ET,FI,FJ,FK,FM,FO,FR,GA,GB,GD,GE,GF,GG,GH,GI,GL,GM,GN,GP,GQ,GR,GS,GT,GU,GW,GY,HK,HM,HN,HR,HT,HU,ID,IE,IL,IM,IN,IO,IQ,IR,IS,IT,JE,JM,JO,JP,KE,KG,KH,KI,KM,KN,KP,KR,KW,KY,KZ,LA,LB,LC,LI,LK,LR,LS,LT,LU,LV,LY,MA,MC,MD,ME,MF,MG,MH,MK,ML,MM,MN,MO,MP,MQ,MR,MS,MT,MU,MV,MW,MX,MY,MZ,NA,NC,NE,NF,NG,NI,NL,NO,NP,NR,NU,NZ,OM,PA,PE,PF,PG,PH,PK,PL,PM,PN,PR,PS,PT,PW,PY,QA,RE,RO,RS,RU,RW,SA,SB,SC,SD,SE,SG,SH,SI,SJ,SK,SL,SM,SN,SO,SR,SS,ST,SV,SX,SY,SZ,TC,TD,TF,TG,TH,TJ,TK,TL,TM,TN,TO,TR,TT,TV,TW,TZ,UA,UG,UM,US,UY,UZ,VA,VC,VE,VG,VI,VN,VU,WF,WS,YE,YT,ZA,ZM,ZW
    mediaDownload: do !->
        regexNormal = {}; regexUnblocked = {}
        for key in <[ title url_encoded_fmt_stream_map fmt_list dashmpd errorcode reason ]>
            regexNormal[key] = //#key=(.*?)(?:&|$)//
            regexUnblocked[key] = //"#key":"(.*?)"//
        for key in <[ url itag type fallback_host ]>
            regexNormal[key] = //#key=(.*?)(?:&|$)//
            regexUnblocked[key] = //#key=(.*?)(?:\\u0026|$)//
        return (media, audioOnly, cb) !->
            /* status codes:
                = success = (resolved)
                0 - downloads found

                = error = (rejected)
                1 - failed to receive video info
                2 - video info loaded, but no downloads found (video likely blocked)
                3 - (for audioOnly) dash.mpd found, but no downloads (basically like 2)

                note: itags are Youtube's code describing the data format
                    https://en.wikipedia.org/wiki/YouTube#Quality_and_formats
                    (click [show] in "Comparison of YouTube media encoding options" to see the whole table)
             */
            # arguments parsing
            if not media or typeof media == \boolean or typeof media == \function or media.success or media.error # if `media` is left out
                [media, audioOnly, cb] = [false, media, cb]
            else if typeof audioOnly != \boolean # if audioOnly is left out
                cb = audioOnly; audioOnly = false

            # parsing cb
            if typeof cb == \function
                success = cb
            else if cb
                {success, error} = cb

            # defaulting arguments
            if media?.attributes
                blocked = media.blocked
                media .= attributes
            else if not media
                media = API.getMedia!
                blocked = 0
            else
                blocked = media.blocked
            {format, cid, id} = media
            media.blocked = blocked = +blocked || 0


            if format == 2
                audioOnly = true


            res =  $.Deferred()
            res
                .then (data) !->
                    data.blocked = blocked
                    if audioOnly
                        return media.downloadAudio = data
                    else
                        return media.download = data
                .fail (err, status) !->
                    if status
                        err =
                            status: 1
                            message: "network error or request rejected"
                    err.blocked = blocked
                    if audioOnly
                        return media.downloadAudioError = err
                    else
                        return media.downloadError = err
                .then success || logger \mediaDownload
                .fail error || logger \mediaDownloadError

            if audioOnly
                return res.resolve media.downloadAudio if media.downloadAudio?.blocked == blocked
                return res.reject media.downloadAudioError if media.downloadAudioError
            else
                return res.resolve media.download if media.download
                return res.reject media.downloadError if media.downloadError?.blocked == blocked

            cid ||= id
            if format == 1 # youtube
                if blocked == 2
                    url = p0ne.proxy "http://vimow.com/watch?v=#cid"
                else if blocked
                    url = p0ne.proxy "https://www.youtube.com/watch?v=#cid"
                else
                    url = p0ne.proxy "https://www.youtube.com/get_video_info?video_id=#cid"
                console.info "[mediaDownload] YT lookup", url
                $.ajax do
                    url: url
                    error: res.reject
                    success: (d) !-> /* see parseYTGetVideoInfo in p0ne.dev for a proper parser of the data */
                        export d
                        file = d # for get()
                        files = {}
                        bestVideo = null
                        bestVideoSize = 0

                        if blocked == 2
                            # getting video proxy URL using vimow.com
                            if d.match /<title>(.*?) - vimow<\/title>/
                                title = htmlUnescape that.1
                            else
                                title = cid
                            files = {}
                            for file in d.match(/<source .*?>/g) ||[]
                                src = /src='(.*?)'/.exec(file)
                                resolution = /src='(.*?)'/.exec(file)
                                mimeType = /src='(\w+\/(\w+))'/.exec(file)
                                if src and resolution and mimeType
                                    (files[that.5] ||= [])[*] = video =
                                        url: src.1
                                        resolution: resolution.1
                                        mimeType: mimeType.1
                                        file: "basename.#{mimeType.2}"
                                    if that.2 > bestVideoSize
                                        bestVideo = video
                                        bestVideoSize = video.resolution

                            if bestVideo
                                files.preferredDownload = bestVideo
                                files.status = 0
                                console.log "[mediaDownload] resolving", files
                                res.resolve files
                            else
                                console.warn "[mediaDownload] vimow.com loaded, but no downloads found"
                                res.reject do
                                    status: 2
                                    message: 'no downloads found'
                            return


                        else if blocked
                            get = (key) !->
                                val = (file || d).match regexUnblocked[key]
                                if key in <[ url itag type fallback_host ]>
                                    return decodeURIComponent val.1
                                return val.1 if val
                            basename = get(\title) || cid
                        else
                            get = (key, unescape) !->
                                val = file.match regexNormal[key]
                                # "+" are not unescaped by default, as they only appear in the title and verticals
                                if val
                                    val = val.1 .replace(/\++/g, ' ') if unescape
                                    return decodeURIComponent val.1
                            basename = get(\title, true) || cid

                            if error = get \errorcode
                                reason = get(\reason, true)
                                switch +error
                                | 150 =>
                                    console.error "[mediaDownload] video_info error 150! Embedding not allowed on some websites"
                                | otherwise =>
                                    console.error "[mediaDownload] video_info error #error! unkown error code", reason

                        if not audioOnly
                            fmt_list_ = get \fmt_list
                            if get \url_encoded_fmt_stream_map
                                for file in that .split ","
                                    #file = unescape(file).replace(/\\u0026/g, '&')
                                    url = get \url
                                    fallback_host = unescape(that.1) if file.match(/fallback_host=(.*?)(?:\\u0026|$)/)
                                    itag = get \itag
                                    if ytItags[itag]
                                        format = that
                                    else
                                        if not fmt_list
                                            fmt_list = {}
                                            if fmt_list_
                                                for e in fmt_list_.split ','
                                                    e .= split '/'
                                                    fmt_list[e.0] = e.1 .split 'x' .1
                                            else
                                                console.warn "[mediaDownload] no fmt_list found"
                                        if fmt_list[itag] and get \type
                                            format =
                                                itag: itag
                                                type: that.1
                                                ext: that.2
                                                resolution: fmt_list[itag]
                                            console.warn "[mediaDownload] unknown itag found, found in fmt_list", itag
                                    if format
                                        original_url = url
                                        url = url
                                            .replace /^.*?googlevideo\.com/, do
                                                "https://#fallback_host" # hack to bypass restrictions
                                                    #.replace 'googlevideo.com', 'c.docs.google.com' # hack to allow HTTPS
                                        #url .= replace('googlevideo.com', 'c.docs.google.com') # supposedly unblocks some videos
                                        (files[format.ext] ||= [])[*] = video =
                                            file: "#basename.#{format.ext}"
                                            url: url
                                            original_url: original_url
                                            fallback_host: fallback_host
                                            #fallback_url: original_url.replace('googlevideo.com', fallback_host)
                                            mimeType: "#{format.type}/#{format.ext}"
                                            resolution: format.resolution
                                            itag: format.itag
                                        if format.resolution > bestVideoSize
                                            bestVideo = video
                                            bestVideoSize = video.resolution
                                    else
                                        console.warn "[mediaDownload] unknown itag found, not in fmt_list", itag

                            if bestVideo
                                files.preferredDownload = bestVideo
                                files.status = 0
                                console.log "[mediaDownload] resolving", files
                                res.resolve files
                            else
                                console.warn "[mediaDownload] no downloads found"
                                res.reject do
                                    status: 2
                                    message: 'no downloads found'

                        # audioOnly
                        else
                            if blocked and d.match(/"dashmpd":"(.*?)"/)
                                url = p0ne.proxy(that.1 .replace(/\\\//g, '/'))
                            else if d.match(/dashmpd=(http.+?)(?:&|$)/)
                                url = p0ne.proxy(unescape that.1 /*parse(d).dashmpd*/)

                            if url
                                console.info "[mediaDownload] DASHMPD lookup", url
                                $.get url
                                    .then (dashmpd) !->
                                        export dashmpd
                                        $dash = dashmpd |> $.parseXML |> jQuery
                                        bestVideo = size: 0
                                        $dash .find \AdaptationSet .each !->
                                            $set = $ this
                                            mimeType = $set .attr \mimeType
                                            type = mimeType.substr(0,5) # => \audio or \video
                                            return if type != \audio #and audioOnly
                                            if mimeType == \audio/mp4
                                                ext = \m4a # audio-only .mp4 files are commonly saved as .m4a
                                            else
                                                ext = mimeType.substr 6
                                            files[mimeType] = []; l=0
                                            $set .find \BaseURL .each !->
                                                $baseurl = $ this
                                                $representation = $baseurl .parent!
                                                #height = $representation .attr \height
                                                files[mimeType][l++] = m =
                                                    file: "#basename.#ext"
                                                    url: httpsify $baseurl.text!
                                                    mimeType: mimeType
                                                    size: $baseurl.attr(\yt:contentLength) / 1_000_000B_to_MB
                                                    samplingRate: "#{$representation .attr \audioSamplingRate}Hz"
                                                    #height: height
                                                    #width: height && $representation .attr \width
                                                    #resolution: height && "#{height}p"
                                                if audioOnly and ~~m.size > ~~bestVideo.size and (window.chrome or mimeType != \audio/webm)
                                                    bestVideo := m
                                        if bestVideo
                                            files.preferredDownload = bestVideo
                                            files.status = 0
                                            console.log "[mediaDownload] resolving", files
                                            res.resolve files
                                        else
                                            console.warn "[mediaDownload] dash.mpd found, but no downloads"
                                            res.reject do
                                                status: 3
                                                message: 'dash.mpd found, but no downloads'

                                        /*
                                        html = ""
                                        for mimeType, files of res
                                            html += "<h3 class=AdaptationSet>#mimeType</h3>"
                                            for f in files
                                                html += "<a href='#{$baseurl.text!}' download='#file' class='download"
                                                html += " preferred-download" if f.preferredDownload
                                                html += "'>#file</a> (#size; #{f.samplingRate || f.resolution})<br>"
                                        */
                                    .fail res.reject
                            else
                                console.error "[mediaDownload] no download found"
                                res.reject "no download found"
                            #window.open(htmlUnescape(/.+>(http.+?)<\/BaseURL>/i.exec(d)[1]))
            else if format == 2 # soundcloud
                audioOnly = true
                mediaLookup media
                    .then (d) !->
                        if d.download
                            res.resolve media.downloadAudio =
                                (d.downloadFormat):
                                    url: d.download
                                    size: d.downloadSize
                        else
                            res.reject "download disabled"
                    .fail res.reject
            else
                console.error "[mediaDownload] unknown format", media
                res.reject "unknown format"

            return res.promise!

    proxify: (url) !->
        if url.startsWith?("http:")
            return p0ne.proxy url
        else
            return url
    httpsify: (url) !->
        if url.startsWith?("http:")
            return "https://#{url.substr 7}"
        else
            return url

    getChatText: (cid) !->
        if not cid
            return $!
        else
            res = $cms! .find ".text.cid-#cid"
            return res
    getChat: (cid) !->
        if typeof cid == \object
            return cid.$el ||= getChat(cid.cid)
        else
            return getChatText cid .parent! .parent!
    isMention: (msg, nameMentionOnly) !->
        user = API.getUser!
        return msg.isMentionName ?= msg.message.has("@#{user.rawun}") if nameMentionOnly
        fromUser = msg.from ||= getUser(msg) ||{}
        return msg.isMention ?=
            msg.message.has("@#{user.rawun}")
            or fromUser.id != userID and do
                    (fromUser.gRole or fromUser.role >= 4) and msg.message.has("@everyone") # @everyone is co-host+
                    or (fromUser.gRole or fromUser.role >= 2) and do # all other special mentions are bouncer+
                        user.role > 1 and do # if the user is staff
                            msg.message.has("@staff")
                            or user.role == 1 and msg.message.has("@rdjs")
                            or user.role == 2 and msg.message.has("@bouncers")
                            or user.role == 3 and msg.message.has("@managers")
                            or user.role == 4 and msg.message.has("@hosts")
                        or msg.message.has("@djs") and API.getWaitListPosition! != -1 # if the user is in the waitlist
        /*
        // for those of you looking at the compiled Javascript, have some readable code:
        return (ref$ = msg.isMention) != null ? ref$ : msg.isMention =
            msg.message.has("@" + user.rawun)
            || fromUser.id !== userID && (
                (fromUser.gRole || fromUser.role >= 4) && msg.message.has("@everyone") // @everyone is co-host+
                || (fromUser.gRole || fromUser.role >= 2) && ( // all other special mentions are bouncer+
                    user.role > 1 && ( // if the user is staff
                        msg.message.has("@staff")
                        || user.role === 1 && msg.message.has("@rdjs")
                        || user.role === 2 && msg.message.has("@bouncers")
                        || user.role === 3 && msg.message.has("@managers")
                        || user.role === 4 && msg.message.has("@hosts")
                    ) || msg.message.has("@djs") && API.getWaitListPosition() !== -1 // if the user is in the waitlist
                )
            );
         */
    getMentions: (data, safeOffsets) !->
        if safeOffsets
            attr = \mentionsWithOffsets
        else
            attr = \mentions
        return that if data[attr]
        # cache properties
        roles = {everyone: 0, djs: 0, rdjs: 1, staff: 2, bouncers: 2, managers: 3, hosts: 4}
        users = API.getUsers!; msgLength = data.message.length

        checkGeneric ||= getUser(data)
        checkGeneric &&= if checkGeneric.gRole then 5 else checkGeneric.role

        # find all @mentions
        var user
        mentions = []; l=0
        data.message.replace /@/g, (_, offset) !->
            offset++
            possibleMatches = users
            i = 0

            # check for generic @mentions, such as @everyone
            if checkGeneric >= 3
                str = data.message.substr(offset, 8)
                for k, v of roles when str.startsWith k and (k != \everyone or checkGeneric >= 4)
                    genericMatch = {rawun: k, username: k, role: v, id: 0}
                    break

            # filter out the best matching name (e.g. "@foobar" would find @foo if @fo, @foo and @fooo are in the room)
            while possibleMatches.length and i < msgLength
                possibleMatches2 = []; l2 = 0
                for m in possibleMatches when m.rawun[i] == data.message[offset + i]
                    if m.rawun.length == i + 1
                        res = m
                    else
                        possibleMatches2[l2++] = m
                possibleMatches = possibleMatches2
                i++
            if res ||= genericMatch
                if safeOffsets
                    mentions[l++] = res with offset: offset - 1
                else if not mentions.has(res)
                    mentions[l++] = res

        mentions = [getUser(data)] if not mentions.length and not safeOffsets
        mentions.toString = !->
            res = ["@#{user.rawun}" for user in this]
            return humanList res # both lines seperate for performance optimization
        data[attr] = mentions
        return mentions

    isMessageVisible: ($msg) !->
        if typeof msg == \string
            $msg = getChat($msg)
        if $msg?.length
            return $cm!.height! > $msg .offset!.top > 101px
        else
            return false


    htmlEscapeMap: {sp: 32, blank: 32, excl: 33, quot: 34, num: 35, dollar: 36, percnt: 37, amp: 38, apos: 39, lpar: 40, rpar: 41, ast: 42, plus: 43, comma: 44, hyphen: 45, dash: 45, period: 46, sol: 47, colon: 58, semi: 59, lt: 60, equals: 61, gt: 62, quest: 63, commat: 64, lsqb: 91, bsol: 92, rsqb: 93, caret: 94, lowbar: 95, lcub: 123, verbar: 124, rcub: 125, tilde: 126, sim: 126, nbsp: 160, iexcl: 161, cent: 162, pound: 163, curren: 164, yen: 165, brkbar: 166, sect: 167, uml: 168, die: 168, copy: 169, ordf: 170, laquo: 171, not: 172, shy: 173, reg: 174, hibar: 175, deg: 176, plusmn: 177, sup2: 178, sup3: 179, acute: 180, micro: 181, para: 182, middot: 183, cedil: 184, sup1: 185, ordm: 186, raquo: 187, frac14: 188, half: 189, frac34: 190, iquest: 191}
    htmlEscape: (str) !->
        return $dummy .text str .html!
        /*
        if not window.htmlEscapeRegexp
            window.htmlEscapeRegexp = []; l=0; window.htmlEscapeMap_reversed = {}
            for k,v of htmlEscapeMap when v != 32 #spaces
                window.htmlEscapeMap_reversed[v] = k
                v .= toString 16
                if v.length <= 2
                    v = "0#v"
                window.htmlEscapeRegexp[l++] = "\\u0#v"
        return str.replace //#{window.htmlEscapeRegexp .join "|"}//g, (c) !-> return "&#{window.htmlEscapeMap_reversed[c.charCodeAt 0]};"
        */

    htmlUnescape: (html) !->
        return html.replace /&(\w+);|&#(\d+);|&#x([a-fA-F0-9]+);/g, (_,a,b,c) !->
            return String.fromCharCode(+b or htmlEscapeMap[a] or parseInt(c, 16)) or _
    stripHTML: (msg) !->
        return msg .replace(/<.*?>/g, '')
    unemojify: (str) !->
        map = window.emoticons?.map
        return str if not map
        return str .replace /(?:<span class="emoji-glow">)?<span class="emoji emoji-(\w+)"><\/span>(?:<\/span>)?/g, (_, emoteID) !->
            if emoticons.reversedMap[emoteID]
                return ":#that:"
            else
                return _

    #== RTL emulator ==
    # str = "abc\u202edef\u202dghi"
    # [str, resolveRTL(str)]
    resolveRTL: (str, dontJoin) !->
        a = b = ""
        isRTLoverridden = false
        "#str\u202d".replace /(.*?)(\u202e|\u202d)/g, (_,pre,c) !->
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

    collapseWhitespace: (str) !->
        return str.replace /\s+/g, ' '
    cleanMessage: (str) !-> return str |> unemojify |> stripHTML |> htmlUnescape |> resolveRTL |> collapseWhitespace

    formatPlainText: (text) !-> # used for song-notif and song-info
        lvl = 0
        text .= replace /([\s\S]*?)($|(?:https?:|www\.)(?:\([^\s\]\)]*\)|\[[^\s\)\]]*\]|[^\s\)\]]+))+([\.\?\!\,])?/g, (,pre,url,post) !->
            pre = pre
                .replace /(\s)(".*?")(\s)/g, "$1<i class='song-description-string'>$2</i>$3"
                .replace /(\s)(\*\w+\*)(\s)/g, "$1<b>$2</b>$3"
                .replace /(lyrics|download|original|re-?upload)/gi, "<b>$1</b>"
                .replace /(\s)(0x)([0-9a-fA-F]+)|(#)([\d\-]+)(\s)/g, "$1<i class='song-description-comment'>$2$4</i><b class='song-description-number'>$3$5</b>$6"
                .replace /(\s)(\d+)(\w*|%|\+)(\s)/g, "$1<b class='song-description-number'>$2</b><i class='song-description-comment'>$3</i>$4"
                .replace /(\s)(\d+)(\s)/g, "$1<b class='song-description-number'>$2</b>$3"
                .replace /^={5,}$/mg, "<hr class='song-description-hr-double' />"
                .replace /^[\-~_]{5,}$/mg, "<hr class='song-description-hr' />"
                .replace /^[\[\-=~_]+.*?[\-=~_\]]+$/mg, "<b class='song-description-heading'>$&</b>"
                .replace /(.?)([\(\)])(.?)/g, (x,a,b,c) !->
                    if "=^".indexOf(x) == -1 or a == ":"
                        return x
                    else if b == \(
                        lvl++
                        return "#a<i class='song-description-comment'>(#c" if lvl == 1
                    else if lvl
                            lvl--
                            return "#a)</i>#c" if lvl == 0
                    return x
            return pre if not url
            return "#pre<a href='#url' target=_blank>#url</a>#{post||''}"
        text += "</i>" if lvl
        return text .replace /\n/g, \<br>


    /*colorKeywords: do !->
        <[ %undefined% black silver gray white maroon red purple fuchsia green lime olive yellow navy blue teal aqua orange aliceblue antiquewhite aquamarine azure beige bisque blanchedalmond blueviolet brown burlywood cadetblue chartreuse chocolate coral cornflowerblue cornsilk crimson darkblue darkcyan darkgoldenrod darkgray darkgreen darkgrey darkkhaki darkmagenta darkolivegreen darkorange darkorchid darkred darksalmon darkseagreen darkslateblue darkslategray darkslategrey darkturquoise darkviolet deeppink deepskyblue dimgray dimgrey dodgerblue firebrick floralwhite forestgreen gainsboro ghostwhite gold goldenrod greenyellow grey honeydew hotpink indianred indigo ivory khaki lavender lavenderblush lawngreen lemonchiffon lightblue lightcoral lightcyan lightgoldenrodyellow lightgray lightgreen lightgrey lightpink lightsalmon lightseagreen lightskyblue lightslategray lightslategrey lightsteelblue lightyellow limegreen linen mediumaquamarine mediumblue mediumorchid mediumpurple mediumseagreen mediumslateblue mediumspringgreen mediumturquoise mediumvioletred midnightblue mintcream mistyrose moccasin navajowhite oldlace olivedrab orangered orchid palegoldenrod palegreen paleturquoise palevioletred papayawhip peachpuff peru pink plum powderblue rosybrown royalblue saddlebrown salmon sandybrown seagreen seashell sienna skyblue slateblue slategray slategrey snow springgreen steelblue tan thistle tomato turquoise violet wheat whitesmoke yellowgreen rebeccapurple ]>
            ..0 = void
            return ..
    isColor: (str) !->
        str = (~~str).toString(16) if typeof str == \number
        return false if typeof str != \string
        str .= trim!
        tmp = /^(?:#(?:[a-fA-F0-9]{6}|[a-fA-F0-9]{3})|(?:rgb|hsl)a?\([\d,]+\)|currentColor|(\w+))$/.exec(str)
        if tmp and tmp.1 in window.colorKeywords
            return str
        else
            return false*/
    isColor: (str) !->
        $dummy.0 .style.color = ""
        $dummy.0 .style.color = str
        return $dummy.0 .style.color != ""

    isURL: (str) !->
        return false if typeof str != \string
        str .= trim! .replace /\\\//g, '/'
        if parseURL(str).host != location.host
            return str
        else
            return false


    mention: (list) !->
        if not list?.length
            return ""
        else if list.0.username
            return humanList ["@#{list[i].username}" for ,i in list]
        else if list.0.attributes?.username
            return humanList ["@#{list[i].get \username}" for ,i in list]
        else
            return humanList ["@#{list[i]}" for ,i in list]
    humanList: (arr) !->
        return "" if not arr.length
        arr = []<<<<arr
        if arr.length > 1
            arr[*-2] += " and\xa0#{arr.pop!}" # \xa0 is NBSP
        return arr.join ", "

    plural: (num, singular, plural="#{singular}s") !->
        # for further functionality, see
        # * http://unicode.org/repos/cldr-tmp/trunk/diff/supplemental/language_plural_rules.html
        # * http://www.unicode.org/cldr/charts/latest/supplemental/language_plural_rules.html
        # * https://developer.mozilla.org/en-US/docs/Localization_and_Plurals
        if num == 1 # note: 0 will cause an s at the end, too
            return "#num\xa0#singular" # \xa0 is NBSP
        else
            return "#num\xa0#plural"
    xth: (i) !->
        ld = i % 10 # last digit
        switch true
        | (i%100 - ld == 10) => "#{i}th" # 11th, 12th, 13th, 2311th, …
        | (ld==1) => return "#{i}st"
        | (ld==2) => return "#{i}nd"
        | (ld==3) => return "#{i}rd"
        return "#{i}th"

    /*fromCodePoints: (str) !->
        res = ""
        for codePoint in str.split \-
            res += String.fromCodePoints(parseInt(codePoint, 16))
        return res
    */
    emojifyUnicode: (str) !->
        if typeof str != \string
            return str
        else
            return str.replace do
                # U+1F300 to  U+1F3FF | U+1F400 to  U+1F64F | U+1F680 to  U+1F6FF
                /\ud83c[\udf00-\udfff]|\ud83d[\udc00-\ude4f]|\ud83d[\ude80-\udeff]/g
                (emoji, all) !->
                    emoji = emoji.codePointAt(0).toString(16)
                    if emoticons.reversedMap[emoji]
                        # emoji is converted to a hexadecimal number, so no undesired HTML injection here
                        return emojifyUnicodeOne(emoji, true)
                    else
                        return all
    emojifyUnicodeOne: (key /*, isCodePoint*/) !->
        #if not isCodePoint
        #    key = emoticons.map[language]
        return "<span class=\"emoji emoji-#key\"></span>"
    flag: (language, unicode) !->
        /*@security HTML injection possible, if Lang.languages[language] is maliciously crafted*/
        if language.0 == \' or language.1 == \' # avoid HTML injection
            return ""
        else
            return "<span class='flag flag-#language' title='#{Lang?.languages[language]}'></span>"
        /*
        if window.emoticons
            language .= language if typeof language == \object
            language = \gb if language == \en
            if key = emoticons.map[language]
                if unicode
                    return key
                else
                    return emojifyOne(key)
        return language*/
    formatUser: (user, showModInfo) !->
        user .= toJSON! if user.toJSON
        info = getRank(user)
        if info == \regular
            info = ""
        else
            info = " #info"

        if showModInfo
            info += " lvl #{if user.gRole == 5 then '∞' else user.level}"
            if Date.now! - 48.h < d = new Date(user.joined) # warn on accounts younger than 2 days
                info += " - created #{ago d}"

        return "#{user.username} (#{user.language}#info)"

    formatUserHTML: (user, showModInfo, fromClass) !->
        /*@security no HTML injection should be possible, unless user.rawun or .id is improperly modified*/
        user = getUser(user)
        if rank = getRankIcon(user)
            rank += " "

        if showModInfo
            info = " (lvl #{if user.gRole == 5 then '∞' else user.level}"
            if Date.now! - 48.h < d = new Date(user.joined) # warn on accounts younger than 2 days
                info += " - created #{ago d}"
            info += ")"
        if fromClass
            fromClass = " #{getRank(user)}"
        else
            fromClass = ""

        # user.rawun should be HTML escaped, < and > are not allowed in usernames (checked serverside)
        return "#rank<span class='un p0ne-name#fromClass' data-uid='#{user.id}'>#{user.rawun}</span> #{flag user.language}#{info ||''}"

    formatUserSimple: (user) !->
        return "<span class=un data-uid='#{user.id}'>#{user.username}</span>"


    # formatting
    timezoneOffset: new Date().getTimezoneOffset!
    getTime: (t = Date.now!) !->
        return new Date(t - timezoneOffset *60_000min_to_ms).toISOString! .replace(/.+?T|\..+/g, '')
    getDateTime: (t = Date.now!) !->
        return new Date(t - timezoneOffset *60_000min_to_ms).toISOString! .replace(/T|\..+/g, ' ')
    getDate: (t = Date.now!) !->
        return new Date(t - timezoneOffset *60_000min_to_ms).toISOString! .replace(/T.+/g, '')
    getISOTime: (t = new Date)!->
        return t.toISOString! .replace(/T|\..+/g, " ")

    # show a timespan (in ms) in a human friendly format (e.g. "2 hours")
    humanTime: (diff, shortFormat) !->
        if diff < 0
            return "-#{humanTime -diff}"
        else if not shortFormat and diff < 2_000ms
            return "just now"
        b=[60to_min, 60to_h, 24to_days, 360.25to_years]; c=0
        diff /= 1000to_s
        while diff > 2*b[c] then diff /= b[c++]
        if shortFormat
            return "#{~~diff}#{<[ s m h d y ]>[c]}"
        else
            return "#{~~diff} #{<[ seconds minutes hours days years ]>[c]}"
    # show a timespan (in s) in a format like "mm:ss" or "hh:mm:ss" etc
    mediaTime: (~~dur) !->
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
    ago: (d) !->
        return "#{humanTime (Date.now! - d)} ago"

    lssize: (sizeWhenDecompressed) !->
        size = 0mb
        for k,v of localStorage when k != \length
            if sizeWhenDecompressed
                try v = decompress v
            size += (v ||'').length / 524288to_mb # x.length * 16bits / 8to_b / 1024to_kb / 1024to_mb
        return size
    formatMB: !->
        return "#{it.toFixed(2)}MB"

    getRank: (user) !-> # returns the name of a rank of a user
        user = getUser(user)
        if not user or (role = user.role || user.get?(\role)) == -1
            return \ghost
        else if user.gRole || user.get?(\gRole)
            if that == 5
                return \admin
            else
                return \ambassador
        else
            return <[ regular dj bouncer manager cohost host ]>[role || 0]
    getRankIcon: (user) !->
        rank = getRank(user)
        return rank != \regular && "<i class='icon icon-chat-#rank p0ne-icon-small'></i>" ||''

    parseURL: (href) !->
        href ||= "//"
        a = document.createElement \a
        a.href = href
        return a
        #$dummy.0{hash, host, hostname, href, pathname, port, protocol, search}

    getIcon: do !->
        # note: this function doesn't cache results, as it's expected to not be used often (only in module setups)
        # if you plan to use it over and over again, use fn.enableCaching()
        $icon = $ "<i class=icon><!-- this is used by plug_p0ne's getIcon() --></i>"
                .css visibility: \hidden
                .appendTo \body
        fn = (className) !->
            $icon.addClass className
            res =
                image:      $icon .css \background-image
                position:   $icon .css \background-position
            res.background = "#{res.image} #{res.position}"
            $icon.removeClass className
            return res
        fn.enableCaching = !-> res = _.memoize(fn); res.enableCaching = $.noop; window.getIcon = res
        return fn

    #= HTML Templates =
    htmlToggle: (checked, data) !->
        if data
            data = ""
            for k,v of data
                data += "data-#k='#v' "
        else
            data=''
        return "<input type=checkbox class=checkbox #data#{if checked then '' else \checked} />"




    #= variables =
    disabled: false
    user: API?.getUser! # preverably for usage with things that should not change, like userID, joindate, …
        # is kept uptodate in updateUserData in p0ne.auxiliary-modules
    getRoomSlug: !->
        return room?.get?(\slug) || decodeURIComponent location.pathname.substr(1)

window.woot.click = window.woot
window.meh.click = window.meh
window.unsnooze = window.refresh

# load cached requireIDs
(err, data) <- dataLoadAll {p0ne_requireIDs: {}, p0ne_disabledModules: {_rooms: {}}}

window.requireIDs = data.p0ne_requireIDs; p0ne.disabledModules = data.p0ne_disabledModules
if err
    console.warn "#{getTime!} [p0ne] the cached requireIDs seem to be corrupted" if err.p0ne_requireIDs
    console.warn "#{getTime!} [p0ne] the user's p0ne settings seem to be corrupted" if err.p0ne_disabledModules
console.info "[p0ne] main function body", p0ne.disabledModules.autojoin


/*####################################
#          REQUIRE MODULES           #
####################################*/
/* requireHelper(moduleName, testFn) */
requireHelper \Curate, (.::?.execute?.toString!.has("/media/insert"))
requireHelper \playlists, (.activeMedia)
requireHelper \auxiliaries, (.deserializeMedia)
requireHelper \database, (.settings)
requireHelper \socketEvents, (.ack)
requireHelper \permissions, (.canModChat)
requireHelper \Playback, (.::?.id == \playback)
requireHelper \PopoutView, (\$document of)
requireHelper \MediaPanel, (.::?.onPlaylistVisible)
requireHelper \PlugAjax, (.::?.hasOwnProperty \permissionAlert)
requireHelper \backbone, (.Events), id: \backbone
requireHelper \roomLoader, (.onVideoResize)
requireHelper \Layout, (.getSize)
requireHelper \popMenu, (.className == \pop-menu)
requireHelper \ActivateEvent, (.ACTIVATE)
requireHelper \votes, (.attributes?.grabbers)
requireHelper \chatAuxiliaries, (.sendChat)
requireHelper \tracker, (.identify)
requireHelper \currentMedia, (.updateElapsedBind)
requireHelper \settings, (.settings)
requireHelper \soundcloud, (.sc)
requireHelper \searchAux, (.ytSearch)
requireHelper \searchManager, (._search)
requireHelper \AlertEvent, (._name == \AlertEvent)
requireHelper \userRollover, (.id == \user-rollover)
requireHelper \booth, (.attributes?.hasOwnProperty \shouldCycle)
requireHelper \currentPlaylistMedia, (\currentFilter of)
requireHelper \userList, (.id == \user-lists)
requireHelper \FriendsList, (.::?.className == \friends)
requireHelper \RoomUserRow, (.::?.vote)
requireHelper \WaitlistRow, (.::?.onAvatar)
requireHelper \room, (.attributes?.hostID)
requireHelper \RoomHistory, (it) !-> return it::?.listClass == \history and it::hasOwnProperty \listClass

if requireHelper \emoticons, (.emojify)
    emoticons.reversedMap = {[v, k] for k,v of emoticons.map}

if requireHelper \PlaylistItemList, (.::?.listClass == \playlist-media)
    export PlaylistItemRow = PlaylistItemList::RowClass

if requireHelper \DialogAlert, (.::?.id == \dialog-alert)
    export Dialog = DialogAlert.__super__


#= _$context =
requireHelper \_$context, (._events?.\chat:receive), do
    onfail: !->
        console.error "[p0ne require] couldn't load '_$context'. A lot of modules will NOT load because of this"
for context in [ Backbone.Events, _$context, API ] when context
    context.onEarly = (type, callback, context) !->
        @_events[][type] .unshift({callback, context, ctx: context || this})
            # ctx:  used for .trigger in Backbone
            # context:  used for .off in Backbone
        return this


#= app =
/* `app` is like the ultimate root object on plug.dj, just about everything is somewhere in there! great for debugging :) */
for cb in (room?._events?[\change:name] || _$context?._events?[\show:room] || Layout?._events?[\resize] ||[]) when cb.ctx.room
    export app = cb.ctx
    export friendsList = app.room.friends
    break

#= user_ =
# the internal user-object
if requireHelper \user_, (.canModChat) #(._events?.'change:username')
    export users = user_.collection # it's the most reliable methode of getting `users`
    export user = user_.toJSON!
if user || user = window.user
    # API.getUser! will fail when used on the Dashboard if no room has been visited before
    export userID = user.id
    user.isStaff = user.role>1 or user.gRole # this is kept up to date in enableModeratorModules in p0ne.moderate


#= underscore =
# this should already be global, but let's be sure to avoid stuff breaking
# (because apparently at some point it did)
export _ = require \underscore

#= Lang =
window.Lang = require \lang/Lang
# security fix to avoid HTML injection
for k,v of Lang?.languages when v.has \'
    Lang.languages[k] .= replace /\\?'/g, "\\'"

#= chat =
if app and not (window.chat = app.room.chat) and window._$context
    for e in _$context._events[\chat:receive] ||[] when e.context?.cid
        window.chat = e.context
        break

#======================
#== CHAT AUXILIARIES ==
#======================
cm = $ \#chat-messages
window <<<<
    $cm: !->
        return PopoutView?.chat?.$chatMessages || chat?.$chatMessages || cm
    $cms: !->
        cm = chat?.$chatMessages || cm
        if PopoutView?.chat?.$chatMessages
            return cm .add that
        else
            return cm

    playChatSound: throttle 200ms, (isMention) !->
        chat?.playSound!
        /*if isMention
            chat.playSound \mention
        else if $ \.icon-chat-sound-on .length > 0
            chat.playSound \chat
        */
    appendChat: (div, wasAtBottom) !->
        wasAtBottom ?= chatIsAtBottom!
        $div = $ div
        $cms!.append $div
        chatScrollDown! if wasAtBottom
        chat.lastType = null # avoid message merging above the appended div
        PopoutView?.chat?.lastType = null
        #playChatSound isMention
        return $div

    chatWarn: (message, /*optional*/ title, isHTML) !->
        return if not message
        if typeof title == \string
            title = $ '<span class=un>' .text title
        else
            isHTML = title
            title = null

        return appendChat do
            $ '<div class="cm p0ne-notif"><div class=badge-box><i class="icon icon-chat-system"></i></div></div>'
                .append do
                    $ '<div class=msg>'
                        .append do
                            $ '<div class=from>'
                                .append title
                                .append getTimestamp!
                        .append do
                            $('<div class=text>')[if isHTML then \html else \text] message

    chatIsAtBottom: !->
        cm = $cm!
        return cm.scrollTop! > cm.0 .scrollHeight - cm.height! - 20
    chatScrollDown: !->
        cm = $cm!
        cm.scrollTop( cm.0 .scrollHeight )

    chatInput: (msg, append) !->
        $input = chat?.$chatInputField || $ \#chat-input-field
        if append and $input.text!
            msg = "#that #msg"
        $input
            .val msg
            .trigger \input
            .focus!
    getTimestamp: (d=new Date) !->
        if auxiliaries?
            return "<time class='timestamp' datetime='#{d.toISOString!}'>#{auxiliaries.getChatTimestamp(database?.settings.chatTimestamps == 24h)}</time>"
        else
            return "<time class='timestamp' datetime='#{d.toISOString!}'>#{pad d.getHours!}:#{pad d.getMinutes!}</time>"



/*####################################
#          extend Deferreds          #
####################################*/
# add .timeout(time, fn) to Deferreds and Promises
replace jQuery, \Deferred, (Deferred_) !-> return !->
    var timeStarted
    res = Deferred_ ...
    res.timeout = timeout
    promise_ = res.promise
    res.promise = !->
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
            sleep timeStarted + time - now, !~>
                callback.call this, this if @state! == \pending



/*####################################
#     Listener for other Scripts     #
####################################*/
# plug³
var rR_
onLoaded = !->
    console.info "[p0ne] plugCubed detected"
    rR_ = Math.randomRange

    # wait for plugCubed to finish loading
    requestAnimationFrame waiting = !->
        if window.plugCubed and not window.plugCubed.plug_p0ne
            API.trigger \plugCubedLoaded, window.plugCubed
            $body .addClass \plugCubed
            replace plugCubed, \close, (close_) !-> return !->
                $body .removeClass \plugCubed
                close_ ...
                if Math.randomRange != rR_
                    # plugCubed got reloaded
                    onLoaded!
                else
                    window.plugCubed = dummyP3
        else
            requestAnimationFrame waiting
dummyP3 = {close: onLoaded, plug_p0ne: true}
if window.plugCubed and not window.plugCubed.plug_p0ne
    onLoaded!
else
    window.plugCubed = dummyP3

# plugplug
onLoaded = !->
    console.info "[p0ne] plugplug detected"
    API.trigger \plugplugLoaded, window.plugplug
    sleep 5_000ms, !-> ppStop = onLoaded
if window.ppSaved
    onLoaded!
else
    export ppStop = onLoaded

/*####################################
#          GET PLUG³ VERSION         #
####################################*/
window.getPlugCubedVersion = !->
    if not plugCubed?.init # plugCubed is not initialized
        return null
    else if plugCubed.version # cached
        return plugCubed.version
    else if v = requireHelper \plugCubedVersion, test: (.major)
        # plug³ alpha
        return v
    else
        # read version from plugCubed settings menu
        if not v = $ '#p3-settings .version' .text!
            # alternative methode (40x slower)
            $ \plugcubed .click!
            v = $ \#p3-settings
                .stop!
                .css left: -500px
                .find \.version .text!
        if v .match /^(\d+)\.(\d+)\.(\d+)(?:-(\w+))?(_min)? \(Build (\d+)\)$/
            v = toString: !->
                return "#{@major}.#{@minor}.#{@patch}#{@prerelease && '-'+@prerelease}#{@minified && '_min' || ''} (Build #{@build})"
            for k,i in <[ major minor patch prerelease minified build ]>
                v[k] = that[i+1]

    return plugCubed.version = v



# draws an image to the console
# `src` can be any url, even data-URIs; relative to the current page
# the optional parameter `customWidth` and `customHeight` need to be in px (integers e.g. `316` for 316px)
# note: if either the width or the height is not defined, the console.log entry will be asynchronious,
# because the image has to be loaded first to get the image's width and height
# returns a promise, so you can attach a callback for asynchronious loading
# e.g. `console.logImg(...).then(function() { ...callback... } )`
#var pending = console && console.logImg && console.logImg.pending
console.logImg = (src, customWidth, customHeight) !->
    def = $.Deferred!
    drawImage = (w, h) !->
        if window.chrome
            console.log "%c\u200B", "color: transparent;
                font-size: #{h*0.854}px !important;
                background: url(#src);display:block;
                border-right: #{w}px solid transparent
            " # 0.854 seems to work perfectly. Kind of a magic number, I guess.
        else # apparently this once worked in Firefox
            console.log "%c", "background: url(#src) no-repeat; display: block;
                width: #{w}px; height: #{h}px;
            "
        def.resolve!
    if isFinite(customWidth) and isFinite(customHeight)
        drawImage(+customWidth, +customHeight)
    else
        new Image
            ..onload = !->
                drawImage(@width, @height)
            ..onerror = !->
                console.log "[couldn't load image %s]", src
                def.reject!
            ..src = src
    return def.promise!