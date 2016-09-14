/**
 * propagate Socket Events to the API Event Emitter for custom event listeners
 * @author jtbrinkmann aka. Brinkie Pie
 * @version 1.0
 * @license MIT License
 * @copyright (c) 2014 J.-T. Brinkmann
 */
#== patch socket ==
module \socketListeners, do
    require: <[ socketEvents SockJS ]>
    optional: <[ _$context auxiliaries ]>
    setup: ({replace}) ->
        return if window.socket?._base_url == "https://shalamar.plug.dj:443/socket" # 2015-01-25
        onRoomJoinQueue2 = []
        for let event in <[ send dispatchEvent ]>
            replace SockJS::, event, (e_) -> return ->
                e_ ...

                if window.socket != this and this._base_url == "https://shalamar.plug.dj:443/socket"
                    # patch
                    replace window, \socket, ~> return this
                    replace this, \onmessage, (msg_) -> return (t) ->
                        for el in t.data || []
                            _$context.trigger "socket:#{el.a}", el
                            API.trigger "socket:#{el.a}", el

                        type = t.data?.0?.a
                        console.warn "[SOCKET:WARNING] socket message format changed", t if not type

                        msg_ ...
                    _$context .on \room:joined, ->
                        while onRoomJoinQueue2.length
                            forEach onRoomJoinQueue2.shift!

                    socket.emit = (e, t, n) ->
                        #if e != \chat
                        #   console.log "[socket:#e]", t, n || ""
                        socket.send JSON.stringify do
                            a: e
                            p: t
                            t: auxiliaries?.getServerEpoch!
                            d: n

                    console.info "[Socket] socket patched (using .#event)", this



        function onMessage  t
            if room.get \joined
                forEach( t.data )
            else
                n = []; r = []
                for e in t.data
                    if e.s == \dashboard
                        n[*] = e
                    else
                        r[*] = e
                forEach( n )
                onRoomJoinQueue2.push( r )

        function forEach  t
            for el in t || []
                if socketEvents[ el.a ]
                    try
                        socketEvents[ el.a ]( el.p )
                    catch err
                        console.error "#{getTime!} [Socket] failed triggering '#{el.a}'", err.stack
                _$context.trigger "socket:#{el.a}", el
                API.trigger "socket:#{el.a}", el

/*
# from app.8cf130d413df133d47c418a818ee8cd60e05a2a0.js (2014-11-25)
# with minor improvements
define \plug_p0ne/socket, [ "underscore", "sockjs", "da676/df0c1/b4fa4", "da676/df0c1/fe7d6", "da676/ae6e4/a8215", "da676/ae6e4/fee3c", "da676/ae6e4/ac243", "da676/cba08/ee33b", "da676/cba08/f7bde", "da676/e0fc4/b75b7", "da676/eb13a/cd12f/d3fee", "da676/b0e2b/e9c55", "lang/Lang" ], ( _, SockJS,, context, AlertEvent, RoomEvent, UserEvent, room, user, socketEvents, AuthReq, auxiliaries, lang ) ->
        var socketURL, retries, sessionWasKilled, socket, onRoomJoinQueue
        if window._sjs
            init window._sjs
            context.on \socket:connect, connectedOrTimeout
        # window._sjs = undefined
        # delete window._sjs

        function init  e
            socketURL := e
            retries := 0
            sessionWasKilled := false
            context
                .on \chat:send, sendChat
                .on \room:joined, roomJoined
                .on \session:kill, sessionKilled

        function connectedOrTimeout
            if not socket
                context.off \socket:connect, connectedOrTimeout
            #socketEvents := _.clone socketEvents
            else
                socket.onopen = socket.onclose = socket.onmessage = socket := void
            debugLog \connecting, socketURL
            window.socket = socket := new SockJS( socketURL )
                ..onopen = connected
                ..onclose = disconnected
                ..onmessage = onMessage
            onRoomJoinQueue := []

        function connected
            debugLog \connected
            retries := 0
            if window._jm
                emit \auth, window._jm
                #delete window._jm
            else
                new AuthReq
                    .on \success, authenticated
                    .on \error, authenFailed


        function authenticated  e
            context
                .trigger \sjs:reconnected
                .on \ack, ->
                    context.off \ack
                        .dispatch new UserEvent( UserEvent.ME )
                    if room.get \joined
                        context.dispatch new RoomEvent( RoomEvent.STATE, room.get \slug )
            emit \auth, e

        function sessionKilled
            debugLog( \kill )
            sessionWasKilled := true

        function disconnected  t
            debugLog \disconnect, t
            if t?.wasClean and sessionWasKilled
                authenFailed!
            else
                if ++retries >= 0xFF #5
                    dcAlertEvent lang.alerts.connectionError, lang.alerts.connectionErrorMessage
                else
                    debugLog \reconnect, retries
                    context.trigger \sjs:reconnecting
                    _.delay connectedOrTimeout, Math.pow( 2, retries ) * 1_000ms

        function sendChat  e
            emit \chat, e

        function emit e, t, n
            if e != \chat
                debugLog \send, e, t, n || ""
            socket.send JSON.stringify do
                a: e
                p: t
                t: auxiliaries.getServerEpoch!
                d: n

        function onMessage  t
            if room.get \joined
                forEach( t.data )
            else
                n = _.filter t.data, (e) ->
                    return e.s == \dashboard
                r = _.filter t.data, ( e ) ->
                    return e.s != \dashboard
                forEach( n )
                onRoomJoinQueue.push( r )

        function forEach  t
            return if not t or not _.isArray( t )
            n = t.length
            for user in t
                if user.s != \dashboard and user.s != room.get \slug
                    debugLog "mismatch :: slug=#{room.get \slug}, message=", user
                    return
                i = user.a
                s = user.socketURL
                if i != \chat
                    debugLog i, s
                if socketEvents[ i ]
                    try
                        socketEvents[ i ]( s )

        function roomJoined
            while onRoomJoinQueue.length
                forEach onRoomJoinQueue.shift!

        function authenFailed
            context.dispatch( new AlertEvent( AlertEvent.ALERT, lang.alerts.sessionExpired, lang.alerts.sessionExpiredMessage, auxiliaries.forceRefresh, auxiliaries ), true )

        function debugLog
            if 5 == user.get \gRole # if client is admin
                e = <[ [sjs] ]>
                for arg, i in arguments
                    e[i] = arg
                console.info.apply ...e
*/
