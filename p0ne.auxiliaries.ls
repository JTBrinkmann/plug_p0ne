/**
 * Auxiliary-functions for plug_p0ne
 * @author jtbrinkmann aka. Brinkie Pie
 * @version 1.0
 * @license MIT License
 * @copyright (c) 2014 J.-T. Brinkmann
*/

export $window = $ window
export $body = $ document.body


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
    return res
String::define \reverse, ->
    res = ""
    i = @length
    while i--
        res += @[i]
    return res
String::define \startsWith, (str) ->
    i=0
    while char = str[i]
        return false if char != this[i++]
    return true
String::define \endsWith, (str) ->
    return this.lastIndexOf == @length - str.length
for Constr in [String, Array]
    Constr::define \has, (needle) -> return -1 != @indexOf needle
    Constr::define \hasAny, (needles) ->
        for needle in needles when -1 != @indexOf needle
            return true
        return false

Number::defineGetter \min, ->   return this * 60_000min_to_ms
Number::defineGetter \s, ->     return this * 1_000min_to_ms


jQuery.fn <<<<
    indexOf: (selector) ->
        /* selector may be a String jQuery Selector or an HTMLElement */
        if @length and selector not instanceof HTMLElement
            i = [].indexOf.call this, selector
            return i if i != -1
        for el, i in this when jQuery(el).is selector
            return i
        return -1

    concat: (arr2) ->
        l = @length
        return this if not arr2 or not arr2.length
        return arr2 if not l
        for el, i in arr2
            @[i+l] = el
        @length += arr2.length
        return this
    fixSize: -> #… only used in saveChat so far
        for el in this
            el.style .width = "#{el.width}px"
            el.style .height = "#{el.height}px"
        return this

/*####################################
#            DATA MANAGER            #
####################################*/
if window.dataSave
    window.dataSave!
    $window .off \beforeunload, window.dataSave.cb
    clearInterval window.dataSave.interval

if window.chrome
    window{compress, decompress} = LZString
else
    window{compressToUTF16:compress, decompressFromUTF16:decompress} = LZString
window.dataLoad = (name, defaultVal={}) ->
    return p0ne.lsBound[name] if p0ne.lsBound[name]
    if localStorage[name]
        if decompress(localStorage[name])
            return p0ne.lsBound[name] = JSON.parse(that)
        else
            name_ = Date.now!
            console.warn "failed to load '#name' from localStorage, it seems to be corrupted! made a backup to '#name_' and continued with default value"
            localStorage[name_] = localStorage[name]
    p0ne.lsBound_num[name] = (p0ne.lsBound_num[name] ||0) + 1
    return p0ne.lsBound[name] = defaultVal
window.dataUnload = (name) !->
    if p0ne.lsBound_num[name]
        p0ne.lsBound_num[name]--
    if p0ne.lsBound_num[name] == 0
        delete p0ne.lsBound[name]
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
$window .on \beforeunload, dataSave.cb = dataSave
dataSave.interval = setInterval dataSave, 15.min


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
            return that if user.id and getUser(user.id)
            if user.username
                return user
            else if user.attributes and user.toJSON
                return user.toJSON!
            else if user.username || user.dj || user.user
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
            users.get user
        else if typeof user == \string
            for u in users.models when u.get(\username) == user
                return u
            user .= toLowerCase!
            for u in users.models when u.get(\username) .toLowerCase! == user
                return u
        else
            console.warn "unknown user format", user

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

    requireIDs: dataLoad \p0ne_requireIDs, {}
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
        return $ '#volume .icon-volume-half, #volume .icon-volume-on' .click! .length
    muteonce: ->
        mute!
        muteonce.last = API.getMedia!.id
        API.once \advance, ->
            unmute! if API.getMedia!.id != muteonce.last
    unmute: ->
        return $ '#playback .snoozed .refresh, #volume .icon-volume-off, #volume .icon-volume-mute-once'.click! .length
    snooze: ->
        return $ '#playback .snooze' .click! .length
    refresh: ->
        return $ '#playback .refresh' .click! .length
    stream: (val) ->
        if not currentMedia
            console.error "[p0ne /stream] cannot change stream - failed to require() the module 'currentMedia'"
        else
            currentMedia?.set \streamDisabled, (val != true and (val == false or currentMedia.get(\streamDisabled)))
    join: ->
        # for this, performance might be essential
        # return $ '#dj-button.is-wait' .click! .length != 0
        if $djButton.hasClass \is-wait
            $djButton.click!
            return true
        else
            return false
    leave: ->
        return $ '#dj-button.is-leave' .click! .length != 0

    ytItags: do ->
        resolutions = [ 72p, 144p, 240p,  360p, 480p, 720p, 1080p, 1440p, 2160p, 3072p ]
        list =
            # DASH-only content is commented out, as it is not yet required
            * ext: \flv, minRes: 240p, itags: <[ 5 ]>
            * ext: \3gp, minRes: 144p, itags:  <[ 17 36 ]>
            * ext: \mp4, minRes: 240p, itags:  <[ 83 18,82 _ 22,84 85 ]>
            #* ext: \mp4, minRes: 240p, itags:  <[ 133 134 135 136 13 138 160 264 ]>, type: \video
            #* ext: \mp4, minRes: 720p, itags:  <[ 298 299 ]>, fps: 60, type: \video
            #* ext: \mp4, minRes: 128kbps, itags:  <[ 140 ]>, type: \audio
            * ext: \webm, minRes: 360p, itags:  <[ 43,100 ]>
            #* ext: \webm, minRes: 240p, itags:  <[ 242 243 244 247 248 271 272 ]>, type: \video
            #* ext: \webm, minRes: 720p, itags:  <[ 302 303 ]>, fps: 60, type: \video
            #* ext: \webm, minRes: 144p, itags:  <[ 278 ]>, type: \video
            #* ext: \webm, minRes: 128kbps, itags:  <[ 171 ]>, type: \audio
            * ext: \ts, minRes: 240p, itags:  <[ 151 132,92 93 94 95 96 ]> # used for live streaming
        res = {}
        for format in list
            for itags, i in format.itags when itag != \_
                # formats with type: \audio not taken into account ignored here
                startI = resolutions.indexOf format.minRes
                for itag in itags.split ","
                    res[itag] =
                        ext: format.ext
                        resolution: resolutions[startI + i]
        return res

    mediaSearch: (query) ->
        $ '#playlist-button .icon-playlist'
            .click! # will silently fail if playlist is already open
        $ \#search-input-field
            .val query
            .trigger do
                type: \keyup
                which: 13 # Enter
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
                    success do
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
                            duration:     d.entry.media$group.yt$duration.seconds # in s
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
                    success do
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
                            duration:       d.duration / 1000ms_to_s # in s

                            download:       d.download_url + "?client_id=#{p0ne.SOUNDCLOUD_KEY}"
                            downloadSize:   d.original_content_size
                            downloadFormat: d.original_format
        else
            return $.Deferred()
                .fail fail
                .reject "unsupported format"

    mediaDownload: (media, audioOnly, cb) ->
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
            {format, cid, id} = media.attributes
        else
            media ||= API.getMedia!
            {format, cid, id} = media


        res =  $.Deferred()
        res
            .then success || logger \mediaDownload
            .fail error || logger \mediaDownloadError
            .fail (err) ->
                if audioOnly or format == 2
                    media.downloadAudioError = err
                else
                    media.downloadError = err

        if audioOnly or format == 2
            return res.resolve media.downloadAudio if media.downloadAudio
            return res.reject media.downloadAudioError if media.downloadAudioError
        else
            return res.resolve media.download if media.download
            return res.reject media.downloadError if media.downloadError

        cid ||= id
        if format == 1 # youtube
            url = p0ne.proxy "https://www.youtube.com/get_video_info?video_id=#cid"
            console.info "[mediaDownload] YT lookup", url
            $.ajax do
                url: url
                error: res.reject
                success: (d) ->
                    /*== Parser ==
                    # useful for debugging
                    parse = (d) ->
                      if d.startsWith "http"
                        return d
                      else if d.has(",")
                        return d.split(",").map(parse)
                      else if d.has "&"
                        res = {}
                        for a in d.split "&"
                          a .= split "="
                          if res[a.0]
                            res[a.0] = [res[a.0]] if not $.isArray res[a.0]
                            res[a.0][*] = parse unescape(a.1)
                          else
                            res[a.0] = parse unescape(a.1)
                        return res
                      else if not isNaN(d)
                        return +d
                      else if d in <[ True False ]>
                        return d == \True
                      else
                        return d
                    parse(d)
                    */
                    basename = d.match(/title=(.*?)(?:&|$)/)?.1 || cid
                    basename = unescape(basename).replace /\++/g, ' '
                    files = {}
                    bestVideo = null
                    bestVideoSize = 0
                    if not audioOnly
                        if d.match(/adaptive_fmts=(.*?)(?:&|$)/)
                            for file in unescape(that.1) .split ","
                                url = unescape that.1 if file.match(/url=(.*?)(?:&|$)/)
                                if file.match(/type=(.*?)%3B/)
                                    mimeType = unescape that.1
                                    filename = "#basename.#{mimeType.substr 6}"
                                    if file.match(/size=(.*?)(?:&|$)/)
                                        resolution = unescape(that.1)
                                        size = resolution.split \x
                                        size = size.0 * size.1
                                        (files[resolution] ||= [])[*] = video = {url, size, mimeType, filename, resolution}
                                        if size > bestVideoSize
                                            bestVideo = video
                                            bestVideoSize = size
                        else if d.match(/url_encoded_fmt_stream_map=(.*?)(?:&|$)/)
                            console.warn "[mediaDownload] only a low quality stream could be found for", cid
                            for file in unescape(that.1) .split ","
                                url = that.1 if d.match(/url=(.*?)(?:&|$)/)
                                if ytItags[d.match(/itag=(.*?);/)?.1]
                                    (files[that.ext] ||= [])[*] = video =
                                        file: "#basename.#{that.ext}"
                                        url: httpsify $baseurl.text!
                                        mimeType: "#{that.type}/#{that.ext}"
                                        resolution: that.resolution
                                    if that.resolution > bestVideoSize
                                        bestVideo = video
                                        bestVideoSize = that.resolution

                        files.preferredDownload = bestVideo
                        console.log "[mediaDownload] resolving", files
                        res.resolve media.download = files

                    # audioOnly
                    else if d.match(/dashmpd=(http.+?)(?:&|$)/)
                        url = p0ne.proxy(unescape that.1 /*parse(d).dashmpd*/)
                        console.info "[mediaDownload] DASHMPD lookup", url
                        $.get url
                            .then (dashmpd) ->
                                $dash = $ $.parseXML dashmpd
                                bestVideo = size: 0
                                $dash .find \AdaptationSet .each ->
                                    $set = $ this
                                    mimeType = $set .attr \mimeType
                                    type = mimeType.substr(0,5) # => \audio or \video
                                    return if type != \audio #and audioOnly
                                    files[mimeType] = []; l=0
                                    $set .find \BaseURL .each ->
                                        $baseurl = $ this
                                        $representation = $baseurl .parent!
                                        #height = $representation .attr \height
                                        files[mimeType][l++] = m =
                                            file: "#basename.#{mimeType.substr 6}"
                                            url: httpsify $baseurl.text!
                                            mimeType: mimeType
                                            size: $baseurl.attr(\yt:contentLength) / 1_000_000B_to_MB
                                            samplingRate: "#{$representation .attr \audioSamplingRate}Hz"
                                            #height: height
                                            #width: height && $representation .attr \width
                                            #resolution: height && "#{height}p"
                                        if audioOnly and ~~m.size > ~~bestVideo.size and (window.chrome or mimeType != \audio/webm)
                                                bestVideo := m
                                files.preferredDownload = bestVideo
                                console.log "[mediaDownload] resolving", files
                                res.resolve media.downloadAudio = files

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
                .then (d) ->
                    if d.download
                        d =
                            "#{d.downloadFormat}":
                                url: d.download
                                size: d.downloadSize
                        res.resolve media.downloadAudio = d
                    else
                        res.reject "download disabled"
                .fail res.reject
        else
            console.error "[mediaDownload] unknown format", media
            res.reject "unknown format"

        return res.promise!

    proxify: (url) ->
        if url.startsWith("http:")
            return p0ne.proxy url
        else
            return url
    httpsify: (url) ->
        if url.startsWith("http:")
            return "https://#{url.substr 7}"
        else
            return url

    getChatText: (cid) ->
        if not cid
            return $!
        else
            res = $cm! .find ".cid-#cid" .last!
            if not res.hasClass \.text
                res .= find \.text .last!
            return res
    getChat: (cid) ->
        return getChatText cid .parent! .parent!
    #ToDo test this
    getMentions: (data, safeOffsets) ->
        if safeOffsets
            attr = \mentionsWithOffsets
        else
            attr = \mentions
        return that if data[attr]
        mentions = []; l=0
        users = API.getUsers!
        msgLength = data.message.length
        data.message.replace /@/g, (_, offset) ->
            offset++
            possibleMatches = users
            i = 0
            while possibleMatches.length and i < msgLength
                possibleMatches2 = []; l3 = 0
                for m in possibleMatches when m.username[i] == data.message[offset + i]
                    #console.log ">", data.message.substr(offset, 5), i, "#{m.username .substr(0,i)}#{m.username[i].toUpperCase!}#{m.username .substr i+1}"
                    if m.username.length == i + 1
                        res = m
                        #console.log ">>>", m.username
                    else
                        possibleMatches2[l3++] = m
                possibleMatches = possibleMatches2
                i++
            if res
                if safeOffsets
                    mentions[l++] = res with offset: offset - 1
                else if not mentions.has(res)
                    mentions[l++] = res

        mentions = [getUser(data)] if not mentions.length and not safeOffsets
        mentions.toString = ->
            res = ["@#{user.username}" for user in this]
            return humanList res # both lines seperate for performance optimization
        data[attr] = mentions
        return mentions


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
            if emoticons.reversedMap[emoteID]
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

    collapseWhitespace: (str) ->
        return str.replace /\s+/g, ' '
    cleanMessage: (str) -> return str |> unemotify |> stripHTML |> htmlUnescape |> resolveRTL |> collapseWhitespace

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


    /*colorKeywords: do ->
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
            return false*/
    isColor: (str) ->
        $dummy.0 .style.color = ""
        $dummy.0 .style.color = str
        return $dummy.0 .style.color == ""

    isURL: (str) ->
        return false if typeof str != \string
        str .= trim! .replace /\\\//g, '/'
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
    xth: (i) ->
        ld = i % 10 # last digit
        switch true
        | (i%100 - ld == 10) => "#{i}th" # 11th, 12th, 13th, 2311th, …
        | (ld==1) => return "#{i}st"
        | (ld==2) => return "#{i}nd"
        | (ld==3) => return "#{i}rd"
        return "#{i}th"


    # formatting
    getTime: (t = new Date) ->
        return t.toISOString! .replace(/.+?T|\..+/g, '')
    getISOTime: (t = new Date)->
        return t.toISOString! .replace(/T|\..+/g, " ")
    # show a timespan (in ms) in a human friendly format (e.g. "2 hours")
    humanTime: (diff, short) ->
        return "-#{humanTime -diff}" if diff < 0
        b=[60to_min, 60to_h, 24to_days, 360.25to_years]; c=0
        diff /= 1000to_s
        while diff > 2*b[c] then diff /= b[c++]
        if short
            return "#{~~diff}#{<[ s m h d ]>[c]}"
        else
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
        for k,v of localStorage when k != \length
            if sizeWhenDecompressed
                try v = decompress v
            size += v.length / 524288to_mb # x.length * 16bits / 8to_b / 1024to_kb / 1024to_mb
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

    getIcon: do ->
        # note: this function doesn't cache results, as it's expected to not be used often (only in module setups)
        # if you plan to use it over and over again, use fn.enableCaching()
        $icon = $ '<i class=icon>'
                .css visibility: \hidden
                .appendTo \body
        fn = (className) ->
            $icon.addClass className
            res =
                background: $icon .css \background
                image:      $icon .css \background-image
                position:   $icon .css \background-position
            $icon.removeClass className
            return res
        fn.enableCaching = -> res = _.memoize(fn); res.enableCaching = $.noop; window.getIcon = res
        return fn




    # variables
    disabled: false
    userID: API?.getUser!.id # API.getUser! will fail when used on the Dashboard if no room has been visited before
    user: API?.getUser! # for usage with things that should not change, like userID, joindate, …
    getRoomSlug: ->
        return room?.get?(\slug) || decodeURIComponent location.pathname.substr(1)





/*####################################
#          REQUIRE MODULES           #
####################################*/
#= _$context =
requireHelper \_$context, (._events?['chat:receive']), do
    onfail: ->
        console.error "[p0ne require] couldn't load '_$context'. Quite a alot modules rely on this and thus might not work"
window._$context?.onEarly = (type, callback, context) ->
    this._events[][type] .unshift({callback, context, ctx: context || this})
        # ctx:  used for .trigger in Backbone
        # context:  used for .off in Backbone
    return this



# continue only after `app` was loaded
#= require plug.dj modules  =
requireHelper \user_, (.canModChat) #(._events?.'change:username')

if user_
    window.users = user_.collection
    if not userID
        user = user_.toJSON!
        userID = user.id


window.Lang = require \lang/Lang
requireHelper \Curate, (.::?.execute?.toString!.has("/media/insert"))
requireHelper \playlists, (.activeMedia)
requireHelper \auxiliaries, (.deserializeMedia)
requireHelper \database, (.settings)
requireHelper \socketEvents, (.ack)
requireHelper \permissions, (.canModChat)
requireHelper \Playback, (.::?.id == \playback)
requireHelper \PopoutView, (\_window of)
requireHelper \MediaPanel, (.::?.onPlaylistVisible)
requireHelper \PlugAjax, (.::?.hasOwnProperty \permissionAlert)
requireHelper \backbone, (.Events), id: \backbone
requireHelper \roomLoader, (.onVideoResize)
requireHelper \Layout, (.getSize)
requireHelper \DialogAlert, (.::?.id == \dialog-alert)
requireHelper \popMenu, (.className == \pop-menu)
requireHelper \ActivateEvent, (.ACTIVATE)
requireHelper \votes, (.attributes?.grabbers)
requireHelper \chatAuxiliaries, (.sendChat)
requireHelper \tracker, (.identify)
requireHelper \currentMedia, (.updateElapsedBind)
requireHelper \settings, (.settings)
requireHelper \soundcloud, (.sc)
requireHelper \userList, (.id == \user-lists)
requireHelper \FriendsList, (.::?.className == \friends)
requireHelper \RoomUserRow, (.::?.vote)
requireHelper \WaitlistRow, (.::?.onAvatar)
requireHelper \PlaylistItemRow, (.::?.listClass == \playlist-media)
requireHelper \room, (.attributes?.hostID?)

requireHelper \emoticons, (.emojify)
emoticons.reversedMap = {[v, k] for k,v of emoticons.map} if window.emoticons


# `app` is like the ultimate root object on plug.dj, just about everything is somewhere in there! great for debugging
for cb in (room._events[\change:name] || _$context?._events[\show:room] || Layout?._events[\resize] ||[]) when cb.ctx.room
    export app = cb.ctx
    export friendsList = app.room.friends
    break




# chat
if app and not window.chat = app.room.chat
    for e in _$context?._events[\chat:receive] ||[] when e.context?.cid
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

    chatInput: (msg, append) ->
        $input = chat?.$chatInputField || $ \#chat-input-field
        if append and $input.text!
            msg = "#that #msg"
        $input
            .val msg
            .trigger \input
            .focus!



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