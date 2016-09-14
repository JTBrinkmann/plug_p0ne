/**
 * plug_p0ne dev
 * a set of plug_p0ne modules for usage in the console
 * They are not used by any other module
 * @author jtbrinkmann aka. Brinkie Pie
 * @version 1.0
 * @license MIT License
 * @copyright (c) 2014 J.-T. Brinkmann
 */
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


# DEBUGGING
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
        if typeof test == \string and window.l
            test = l(test)
        res = []
        for id, module of require.s.contexts._.defined when module
            if test module, id
                module.id ||= id
                console.log "[findModule]", id, module
                res[*] = module
        return res

    validateUsername: (username, cb) !->
        if not cb
            cb = (slug, err) -> console[err && \error || \log] "username '#username': ", err || slug

        if length < 2
            cb(false, "too short")
        else if length >= 25
            cb(false, "too long")
        else if username.indexOf("/") != -1
            cb(false, "forward slashes are not allowed")
        else if username.indexOf("\n") != -1
            cb(false, "line breaks are not allowed")
        else
            (d) <- $.getJSON "https://plug.dj/_/users/validate/#{encodeURIComponent username}"
            cb(d && d.data.0?.slug)

    getRequireArg: (haystack, needle) ->
        # this is a helper function to be used in the console to quickly find a module ID corresponding to a parameter and vice versa in the head of a javascript requirejs.define call
        # e.g. getRequireArg('define( "da676/a5d9e/a7e5a/a3e8f/fa06c", [ "jquery", "underscore", "backbone", "da676/df0c1/fe7d6", "da676/ae6e4/a99ef", "da676/d8c3f/ed854", "da676/cba08/ba3a9", "da676/cba08/ee33b", "da676/cba08/f7bde", "da676/cba08/d0509", "da676/eb13a/b058e/c6c93", "da676/eb13a/b058e/c5cd2", "da676/eb13a/f86ef/bff93", "da676/b0e2b/f053f", "da676/b0e2b/e9c55", "da676/a5d9e/d6ba6/f3211", "hbs!templates/room/header/RoomInfo", "lang/Lang" ], function( e, t, n, r, i, s, o, u, a, f, l, c, h, p, d, v, m, g ) {', 'u') ==> "da676/cba08/ee33b"
        b = haystack.split "], function( "
        a = b.0.substr(b.0.indexOf('"')).split('", "')
        b = b.1.substr(0, b.1.indexOf(' )')).split(', ')
        return b[a.indexOf(needle)] || a[b.indexOf(needle)]

    logOnce: (base, event) ->
        if not event
            event = base
            if -1 != event.indexOf \:
                base = _$context
            else
                base = API
        base.once \event, (...args) ->
            console.log "[#{event .toUpperCase!}]", args

module \renameUser, do
    require: <[ users ]>
    module: (idOrName, newName) ->
        u = users.get(idOrName)
        if not u
            idOrName .= toLowerCase!
            for user in users.models when user.attributes.username.toLowerCase! == idOrName
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

