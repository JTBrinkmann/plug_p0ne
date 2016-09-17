/**
 * propagate Socket Events to the API Event Emitter for custom event listeners
 *
 * @author jtbrinkmann aka. Brinkie Pie
 * @license MIT License
 * @copyright (c) 2015 J.-T. Brinkmann
 */
console.log "~~~~~~~ p0ne.socket ~~~~~~~"
/*####################################
#          SOCKET LISTENERS          #
####################################*/
module \socketListeners, do
    require: <[ socketEvents ]>
    optional: <[ _$context auxiliaries ]>
    logUnmatched: false
    lastHandshake: 0
    setup: ({replace}, socketListeners) !->
        #== patch socket ==
        window.Socket ||= window.SockJS || window.WebSocket
        if Socket == window.SockJS
            base_url = "https://shalamar.plug.dj:443/socket" # 2015-01-25
        else
            base_url = "wss://godj.plug.dj/socket" # 2015-02-12
        #return if parseURL(window.socket?.url).host.endsWith \plug.dj
        return if window.socket?.url == base_url
        onRoomJoinQueue2 = []
        for let event in <[ send dispatchEvent close ]>
            #console.log "[socketListeners] injecting into Socket::#event"
            replace Socket::, event, (e_) !-> return !->
                try
                    e_ ...
                    url = @_base_url || @url
                    if window.socket != this and url == base_url #parseURL(url).host.endsWith \plug.dj
                        replace window, \socket, !~> return this
                        replace this, \onmessage, (msg_) !-> return (t) !->
                            socketListeners.lastHandshake = Date.now!
                            return if t.data == \h

                            if typeof t.data == \string
                                data = JSON.parse t.data
                            else
                                data = t.data ||[]

                            for el in data
                                _$context.trigger "socket:#{el.a}", el

                            type = data.0?.a
                            console.warn "[SOCKET:WARNING] socket message format changed", t if not type

                            msg_ ...

                            for el in data
                                API.trigger "socket:#{el.a}", el


                        _$context .on \room:joined, !->
                            while onRoomJoinQueue2.length
                                forEach onRoomJoinQueue2.shift!

                        socket.emit = (e, t, n) !->
                            #if e != \chat
                            #   console.log "[socket:#e]", t, n || ""
                            socket.send JSON.stringify do
                                a: e
                                p: t
                                t: auxiliaries?.getServerEpoch!
                                d: n

                        /*socketListeners.hoofcheck = repeat 1.min, !->
                            if Date.now! > socketListeners.lastHandshake + 2.min
                                console.warn "the socket seems to have silently disconnected, trying to reconnect. last message", ago(socketListeners.lastHandshake)
                                reconnectSocket!*/
                        console.info "[Socket] socket patched (using .#event)", this
                    else if socketListeners.logUnmatched and window.socket != this
                        console.warn "socket found, but url differs '#url'", this
                catch err
                    export err
                    console.error "error when patching socket", this, err.stack


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
    disable: !->
        clearInterval @hoofcheck
