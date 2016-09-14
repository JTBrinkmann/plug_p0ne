/**
 * Auxiliary-functions for plug_p0ne
 * @author jtbrinkmann aka. Brinkie Pie
 * @version 1.0
 * @license MIT License
 * @copyright (c) 2014 J.-T. Brinkmann
*/

$window = $ window
$body = $ document.body


/*####################################
#         PROTOTYPE FUNCTIONS        #
####################################*/
# helper for defining non-enumerable functions via Object.defineProperty
let (d = (property, value) -> if @[property] != value then Object.defineProperty this, property, {-enumerable, +writable, +configurable, value})
    d.call Object::, \define, d
Object::define \defineGetter, (property, get) -> if @[property] != get then Object.defineProperty this, property, {-enumerable, +configurable, get}

Array::define \remove, (i) -> return @splice i, 1
Array::define \removeItem, (el) ->
    if -1 != (i = @indexOf(el))
        @splice i, 1
    return this
Array::define \random, -> return this[~~(Math.random! * @length)]
Array::define \unique, ->
    res = []; l=0
    for el, i in this
        for o til i
            break if @[o] == el
        else
            res[l++] = el
    return
String::define \reverse, ->
    res = ""
    i = @length
    while i--
        res += @[i]
    return res
String::define \has, (needle) -> return -1 != @indexOf needle
String::define \startsWith, (str) ->
    i=0
    while char = str[i]
        return false if char != this[i++]
    return true
String::define \endsWith, (str) ->
    return this.lastIndexOf == @length - str.length

Number::defineGetter \min, ->   return this * 60_000min_to_ms
Number::defineGetter \s, ->     return this * 1_000min_to_ms


jQuery.fn <<<<
    fixSize: -> #… this is not really used?
        for el in this
            el.style .width = "#{el.width}px"
            el.style .height = "#{el.height}px"
        return this
    concat: (arr2) ->
        l = @length
        return this if not arr2 or not arr2.length
        return arr2 if not l
        for el, i in arr2
            @[i+l] = el
        @length += arr2.length
        return this

/*####################################
#            DATA MANAGER            #
####################################*/
window{compress, decompress} = LZString
if not window.dataSave?.p0ne
    window.dataLoad = (name, defaultVal={}) ->
        return p0ne.lsBound[name] if p0ne.lsBound[name]
        if localStorage[name]
            if decompress(localStorage[name])
                return p0ne.lsBound[name] = JSON.parse(that)
            else
                name_ = Date.now!
                console.warn "failed to load '#name' from localStorage, it seems to be corrupted! made a backup to '#name_' and continued with default value"
                localStorage[name_] = localStorage[name]
        return p0ne.lsBound[name] = defaultVal
    window.dataSave = !->
        err = ""
        for k,v of p0ne.lsBound
            try
                localStorage[k] = compress(v.toJSON?! || JSON.stringify(v))
            catch
                err += "failed to store '#k' to localStorage\n"
        if err
            alert err
        else
            console.log "[Data Manager] saved data"
    window.dataSave.p0ne = true
    $window .on \beforeunload, dataSave
    setInterval dataSave, 15.min


/*####################################
#         GENERAL AUXILIARIES        #
####################################*/
$dummy = $ \<a>
window <<<<
    YT_REGEX: /https?:\/\/(?:www\.)?(?:youtube(?:-nocookie)?\.com\/(?:[^\/]+\/.+\/|(?:v|embed|e)\/|.*(?:\?|&amp;)v=)|youtu\.be\/)([^"&?\/<>\s]{11})(?:&.*?|#.*?|)$/i
    repeat: (timeout, fn) -> return setInterval (-> fn ... if not disabled), timeout
    sleep: (timeout, fn) -> return setTimeout fn, timeout
    pad: (num, digits) ->
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

    generateID: -> return (~~(Math.random!*0xFFFFFF)) .toString(16).toUpperCase!



    getUser: (user) !->
        return if not user
        if typeof user == \object
            if user.username
                return user
            else if user.attributes and user.toJSON
                return user.toJSON!
            return null
        userList = API.getUsers!
        if +user
            if users?.get? user
                return that
            else
                for u in userList when u.id == user
                    return u

        for u in userList when u.username == user
            return u
        user .= toLowerCase!
        for u in userList when u.username .toLowerCase! == user
            return u
    getUserInternal: (user) !->
        return if not user or not users
        if typeof user == \object
            if user.attributes
                return user
            else if user.username
                return users.get(user.id)
            return null

        if +user
            users.get user
        else
            users = users.models
            for u in users when u.username == user
                return u
            user .= toLowerCase!
            for u in users when u.username .toLowerCase! == user
                return u

    logger: (loggerName, fn) ->
        if typeof fn == \function
            return ->
                console.log "[#loggerName]", arguments
                return fn ...
        else
            return -> console.log "[#loggerName]", arguments

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

    requireIDs: dataLoad \requireIDs, {}
    requireHelper: (name, test, {id, onfail, fallback}=0) ->
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
    requireAll: (test) ->
        return [m for id, m of require.s.contexts._.defined when m and test(m, id)]


    /* callback gets called with the arguments cb(errorCode, response, event) */
    floodAPI_counter: 0
    ajax: (type, url, data, cb) ->
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

        options = do
                type: type
                url: "https://plug.dj/_/#url"
                success: ({data}) ->
                    console.info "[#url]", data if not silent
                    success? data
                error: (err) ->
                    console.error "[#url]", data if not silent
                    error? data

        if data
            silent = data.silent
            delete data.type
            delete data.silent
            if Object.keys(data).length
                options.contentType = \application/json
                options.data = JSON.stringify(data)
        def = $.Deferred!
        do delay = ->
            if window.floodAPI_counter >= 15 /* 20 requests / 10s will trigger socket:floodAPI. This should leave us enough buffer in any case */
                sleep 1_000ms, delay
            else
                window.floodAPI_counter++; sleep 10_000ms, -> window.floodAPI_counter--
                return $.ajax options
                    .then def.resolve, def.reject, def.progress
        return def

    befriend: (userID, cb) -> ajax \POST, "friends", id: userID, cb
    ban: (userID, cb) -> ajax \POST, "bans/add", userID: userID, duration: API.BAN.HOUR, reason: 1, cb
    banPerma: (userID, cb) -> ajax \POST, "bans/add", userID: userID, duration: API.BAN.PERMA, reason: 1, cb
    unban: (userID, cb) -> ajax \DELETE, "bans/#userID", cb
    modMute: (userID, cb) -> ajax \POST, "mutes/add", userID: userID, duration: API.MUTE.SHORT, reason: 1, cb
    modUnmute: (userID, cb) -> ajax \DELETE, "mutes/#userID", cb
    chatDelete: (chatID, cb) -> ajax \DELETE, "chat/#chatID", cb
    kick: (userID, cb) ->
        <- ban userID
        <- sleep 1_000ms
        unban userID, cb

    getUserData: (user, cb) !->
        if typeof user != \number
            user = getUser user
        cb ||= (data) -> console.log "[userdata]", data, (if data.level >= 5 then "https://plug.dj/@/#{encodeURI data.slug}")
        return $.get "/_/users/#user"
            .then ({[data]:data}:arg) ->
                return data
            .fail ->
                console.warn "couldn't get slug for user with id '#{id}'"

    $djButton: $ \#dj-button
    mute: ->
        return $ '.icon-volume-half, .icon-volume-on' .click! .length
    muteonce: ->
        return $ \.snooze .click! .length
    unmute: ->
        return $ '.playback-controls.snoozed .refresh, .icon-volume-off, .icon-volume-mute-once'.click! .length
    join: ->
        if $djButton.hasClass \is-wait
            $djButton.click!
            return true
        else
            return false
    leave: ->
        if $djButton.hasClass \is-leave
            $djButton.click!
            return true
        else
            return false


    mediaLookup: ({format, id, cid}:url, cb) ->
        if typeof cb == \function
            success = cb
        else
            if typeof cb == \object
                {success, fail} = cb if cb
            success ||= (data) -> console.info "[mediaLookup] #{<[yt sc]>[format - 1]}:#cid", data
        fail ||= (err) -> console.error "[mediaLookup] couldn't look up", cid, url, cb, err

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
            return $.getJSON "https://gdata.youtube.com/feeds/api/videos/#cid?v=2&alt=json"
                .fail fail
                .success (d) ->
                    cid = d.entry.id.$t.substr(27)
                    window.mediaLookup.lastData =
                        format:       1
                        data:         d
                        cid:          cid
                        uploader:
                            name:     d.entry.author.0.name.$t
                            id:       d.entry.media$group.yt$uploaderId.$t
                        image:        "https://i.ytimg.com/vi/#cid/0.jpg"
                        title:        d.entry.title.$t
                        uploadDate:   d.entry.published.$t
                        url:          "https://youtube.com/watch?v=#cid"
                        description:  d.entry.media$group.media$description.$t
                        duration:     d.entry.media$group.yt$duration.seconds
                    success window.mediaLookup.lastData
        else if format == 2
            if cid
                req = $.getJSON "https://api.soundcloud.com/tracks/#cid.json", do
                    client_id: p0ne.SOUNDCLOUD_KEY
            else
                req = $.getJSON "https://api.soundcloud.com/resolve/", do
                    url: url
                    client_id: p0ne.SOUNDCLOUD_KEY
            return req
                .fail fail
                .success (d) ->
                    window.mediaLookup.lastData =
                        format:         2
                        data:           d
                        cid:            cid
                        uploader:
                            id:         d.user.id
                            name:       d.user.username
                            image:      d.user.avatar_url
                        image:          d.artwork_url
                        title:          d.title
                        uploadDate:     d.created_at
                        url:            d.permalink_url
                        description:    d.description
                        duration:       d.duration # in s

                        download:       d.download_url + "?client_id=#{p0ne.SOUNDCLOUD_KEY}"
                        downloadSize:   d.original_content_size
                        downloadFormat: d.original_format
                    success window.mediaLookup.lastData
        else
            return $.Deferred()
                .fail fail
                .rejectWith"unsupported format"

    mediaDownload: (media, cb) ->
        media ||= API.getMedia!
        {format, cid, id} = media
        if typeof media == \function or media.success or media.fail
            cb = media; media = false
        media ||= API.getMedia!
        if typeof cb == \function
            success = cb
        else if cb
            {success, fail} = cb
        success ||= logger \mediaDownload # success(downloadURL, downloadSize)
        error ||= logger \mediaDownloadError

        cid ||= id
        if format == 1 # youtube
            $.ajax do
                url: p0ne.proxy "https://www.youtube.com/get_video_info?video_id=#cid"
                fail: fail
                success: (d) ->
                    if d.match(/url_encoded_fmt_stream_map=.*url%3D(.*?)%26/)
                        success? unescape(unescape(that.1))
                    else
                        fail? "unkown error"
        else if format == 2
            mediaLookup media
                .then (d) ->
                    success? d.download, d.downloadSize, downloadFormat
                .fail ->
                    fail? ...

    mediaSearch: (query) ->
        $ '#playlist-button .icon-playlist'
            .click! # will silently fail if playlist is already open
        $ \#search-input-field
            .val query
            .trigger do
                type: \keyup
                which: 13 # Enter
        /*app.footer.playlist.onBarClick!
        app.footer.playlist.playlist.search.searchInput.value = query
        app.footer.playlist.playlist.search.onSubmitSearch!
        */

    httpsify: (url) ->
        if url.startsWith("http:")
            return p0ne.proxy url
        else
            return url

    getChatText: (cid) ->
        return $! if not cid
        # if cid is undefined, it will return the last .cid-undefined (e.g. on .moderations, etc)
        return $cm! .find ".cid-#cid" .last!
    getChat: (cid) ->
        return getChatText cid .parent! .parent!
    #ToDo test this
    getMentions: (data) ->
        names = []; l=0
        users = API.getUsers!
        msgLength = data.message.length
        data.message.replace /@/g, (_, offset) ->
            offset++
            possibleMatches = users
            i = 0
            while possibleMatches.length and i < msgLength
                possibleMatches2 = []; l3 = 0
                for m in possibleMatches when m.username[i] == data.message[offset + i]
                    console.log ">", data.message.substr(offset, 5), i, "#{m.username .substr(0,i)}#{m.username[i].toUpperCase!}#{m.username .substr i+1}"
                    if m.username.length == i + 1
                        res = m
                        console.log ">>>", m.username
                    else
                        possibleMatches2[l3++] = m
                possibleMatches = possibleMatches2
                i++
            if res and names.indexOf(res) == -1
                names[l++] = res.username

        names = [data.un] if not names.length
        names.toString = -> return humanList this
        return names


    htmlEscapeMap: {sp: 32, blank: 32, excl: 33, quot: 34, num: 35, dollar: 36, percnt: 37, amp: 38, apos: 39, lpar: 40, rpar: 41, ast: 42, plus: 43, comma: 44, hyphen: 45, dash: 45, period: 46, sol: 47, colon: 58, semi: 59, lt: 60, equals: 61, gt: 62, quest: 63, commat: 64, lsqb: 91, bsol: 92, rsqb: 93, caret: 94, lowbar: 95, lcub: 123, verbar: 124, rcub: 125, tilde: 126, sim: 126, nbsp: 160, iexcl: 161, cent: 162, pound: 163, curren: 164, yen: 165, brkbar: 166, sect: 167, uml: 168, die: 168, copy: 169, ordf: 170, laquo: 171, not: 172, shy: 173, reg: 174, hibar: 175, deg: 176, plusmn: 177, sup2: 178, sup3: 179, acute: 180, micro: 181, para: 182, middot: 183, cedil: 184, sup1: 185, ordm: 186, raquo: 187, frac14: 188, half: 189, frac34: 190, iquest: 191}
    htmlEscape: (str) ->
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

    formatPlainText: (text) -> # used for song-notif and song-info
        lvl = 0
        text .= replace /([\s\S]*?)($|https?:(?:\([^\s\]\)]*\)|\[[^\s\)\]]*\]|[^\s\)\]]+))+([\.\?\!\,])?/g, (,pre,url,post) ->
            pre = pre
                .replace /(\s)(".*?")(\s)/g, "$1<i class='song-description-string'>$2</i>$3"
                .replace /(\s)(\*\w+\*)(\s)/g, "$1<b>$2</b>$3"
                .replace /(lyrics|download|original|re-?upload)/gi, "<b>$1</b>"
                .replace /(\s)((?:0x|#)[0-9a-fA-F]+|\d+)(\w*|%|\+)?(\s)/g, "$1<b class='song-description-number'>$2</b><i class='song-description-comment'>$3</i>$4"
                .replace /^={5,}$/mg, "<hr class='song-description-hr-double' />"
                .replace /^[\-~_]{5,}$/mg, "<hr class='song-description-hr' />"
                .replace /^[\[\-=~_]+.*?[\-=~_\]]+$/mg, "<b class='song-description-heading'>$&</b>"
                .replace /(.?)([\(\)])(.?)/g, (x,a,b,c) ->
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


    colorKeywords: do ->
        <[ %undefined% black silver gray white maroon red purple fuchsia green lime olive yellow navy blue teal aqua orange aliceblue antiquewhite aquamarine azure beige bisque blanchedalmond blueviolet brown burlywood cadetblue chartreuse chocolate coral cornflowerblue cornsilk crimson darkblue darkcyan darkgoldenrod darkgray darkgreen darkgrey darkkhaki darkmagenta darkolivegreen darkorange darkorchid darkred darksalmon darkseagreen darkslateblue darkslategray darkslategrey darkturquoise darkviolet deeppink deepskyblue dimgray dimgrey dodgerblue firebrick floralwhite forestgreen gainsboro ghostwhite gold goldenrod greenyellow grey honeydew hotpink indianred indigo ivory khaki lavender lavenderblush lawngreen lemonchiffon lightblue lightcoral lightcyan lightgoldenrodyellow lightgray lightgreen lightgrey lightpink lightsalmon lightseagreen lightskyblue lightslategray lightslategrey lightsteelblue lightyellow limegreen linen mediumaquamarine mediumblue mediumorchid mediumpurple mediumseagreen mediumslateblue mediumspringgreen mediumturquoise mediumvioletred midnightblue mintcream mistyrose moccasin navajowhite oldlace olivedrab orangered orchid palegoldenrod palegreen paleturquoise palevioletred papayawhip peachpuff peru pink plum powderblue rosybrown royalblue saddlebrown salmon sandybrown seagreen seashell sienna skyblue slateblue slategray slategrey snow springgreen steelblue tan thistle tomato turquoise violet wheat whitesmoke yellowgreen rebeccapurple ]>
            ..0 = void
            return ..
    isColor: (str) ->
        str = (~~str).toString(16) if typeof str == \number
        return false if typeof str != \string
        str .= trim!
        tmp = /^(?:#(?:[a-fA-F0-9]{6}|[a-fA-F0-9]{3})|(?:rgb|hsl)a?\([\d,]+\)|currentColor|(\w+))$/.exec(str)
        if tmp and tmp.1 in window.colorKeywords
            return str
        else
            return false

    isURL: (str) ->
        return false if typeof str != \string
        str.trim!
        if parseURL(str).host != location.host
            return str
        else
            return false


    mention: (list) ->
        if not list?.length
            return ""
        else if list.0.username
            return humanList ["@#{list[i].username}" for ,i in list]
        else if list.0.attributes?.username
            return humanList ["@#{list[i].get \username}" for ,i in list]
        else
            return humanList ["@#{list[i]}" for ,i in list]
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
    getISOTime: (t = new Date)->
        return t.toISOString! .replace(/T|\..+/g, " ")
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
            size += x.length / 524288to_mb # x.length * 16bits / 8to_b / 1024to_kb / 1024to_mb
        return size
    formatMB: ->
        return "#{it.toFixed(2)}MB"

    getRank: (user) -> # returns the name of a rank of a user
        user = getUser(user)
        if not user or (role = user.role || user.get?(\role)) == -1
            return \ghost
        else if user.gRole || user.get?(\gRole)
            if that == 5
                return \admin
            else
                return \BA
        else
            return <[ none rdj bouncer manager cohost host ]>[role || 0]

    parseURL: (href) ->
        $dummy.0.href = href
        return $dummy.0{hash, host, hostname, href, pathname, port, protocol, search}




    # variables
    disabled: false
    userID: API?.getUser!.id
    user: API?.getUser! # for usage with things that should not change, like userID, joindate, …
    getRoomSlug: ->
        return room?.get?(\slug) || decodeURIComponent location.pathname.substr(1)





/*####################################
#          REQUIRE MODULES           #
####################################*/
#= _$context =
requireHelper \_$context, (._events?['chat:receive']), do
    fallback: {_events: {}}
    onfail: ->
        console.error "[p0ne require] couldn't load '_$context'. Some modules might not work"
window._$context.onEarly = (type, callback, context) ->
    this._events[][type] .unshift({callback, context, ctx: context || this})
        # ctx:  used for .trigger in Backbone
        # context:  used for .off in Backbone
    return this

#= app =
window.app = null if window.app?.nodeType
<-   (cb) ->
    return cb! if window.app

    requireHelper \App, (.::?.el == \body)
    if App
        App::animate = let animate_ = App::animate then !->
            console.log "[p0ne] got `app`"
            export p0ne.app = this
            App::animate = animate_ # restore App::animate
            animate_ ...
            cb!
    else
        cb!

# continue only after `app` was loaded
#= room =
requireHelper \user_, (.canModChat) #(._events?.'change:username')
window.users = user_.collection if user_

requireHelper \room, (.attributes?.hostID?)
requireHelper \Curate, (.::?execute?.toString!.has("/media/insert"))
requireHelper \playlists, (.activeMedia)
requireHelper \auxiliaries, (.deserializeMedia)
requireHelper \database, (.settings)
requireHelper \socketEvents, (.ack)
requireHelper \permissions, (.canModChat)
requireHelper \Playback, (.::?id == \playback)
requireHelper \PopoutView, (\_window of)
requireHelper \MediaPanel, (.::?onPlaylistVisible)
requireHelper \PlugAjax, (.::?.hasOwnProperty \permissionAlert)
requireHelper \backbone, (.Events), id: \backbone
requireHelper \roomLoader, (.onVideoResize)
requireHelper \Layout, (.getSize)
requireHelper \RoomUserRow, (.::?.vote)
requireHelper \DialogAlert, (.::?id == \dialog-alert)
requireHelper \popMenu, (.className == \pop-menu)
requireHelper \ActivateEvent, (.ACTIVATE)

requireHelper \emoticons, (.emojify)
emoticons.reverseMap = {[v, k] for k,v of emoticons.map} if window.emoticons

requireHelper \FriendsList, (.::?className == \friends)
window.friendsList = app.room.friends


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
        chat.lastID = -1 # avoid message merging above the appended div
        return div

        #playChatSound isMention

    chatIsAtBottom: ->
        cm = $cm!
        return cm.scrollTop! > cm.0 .scrollHeight - cm.height! - 20
    chatScrollDown: ->
        cm = $cm!
        cm.scrollTop( cm.0 .scrollHeight )


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
var rR_
onLoaded = ->
    console.info "[p0ne] plugCubed detected"
    rR_ = Math.randomRange

    # wait for plugCubed to finish loading
    requestAnimationFrame waiting = ->
        if window.plugCubed and not window.plugCubed.plug_p0ne
            API.trigger \plugCubedLoaded, window.plugCubed
            $body .addClass \plugCubed
            replace plugCubed, \close, (close_) -> return !->
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
onLoaded = ->
    console.info "[p0ne] plugplug detected"
    API.trigger \plugplugLoaded, window.plugplug
    sleep 5_000ms, -> ppStop = onLoaded
if window.ppSaved
    onLoaded!
else
    export ppStop = onLoaded

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
    else # plug³ alpha
        v = requireHelper \plugCubedVersion, (.major)
        return v if v

        # alternative methode (40x slower)
        $ \plugcubed .click!
        v = $ \#p3-settings
            .stop!
            .css left: -500px
            .find \.version .text!


    if typeof v == \string
        if v .match /^(\d+)\.(\d+)\.(\d+)(?:-(\w+))?(_min)? \(Build (\d+)\)$/
            v := that{major, minor, patch, prerelease, minified, build}
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
        if window.chrome
            console.log "%c\u200B", "color: transparent; font-size: #{(+customHeight || img.height)*0.854}px !important;
                background: url(#src);display:block;
                border-right: #{+customWidth || img.width}px solid transparent
            "
        else
            console.log "%c", "background: url(#src) no-repeat; display: block;
                width: #{customWidth || img.width}px; height: #{customHeight || img.height}px;
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
        img = new Image
            ..onload = logImgLoader
            ..onerror = ->
                #if(logImg.pending && logImg.pending.constructor == Array)
                #   logImg.pending.splice(pendingPos-1, 1)
                console.log "[couldn't load image %s]", src
            ..src = src

    return promise