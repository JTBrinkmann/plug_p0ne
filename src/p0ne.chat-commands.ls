/**
 * plug_p0ne ChatCommands
 * Basic chat commands are defined here. Trigger them on plug.dj by writing "/commandname" in the chat
 * e.g. "/move @Brinkie Pie 2" to move the user "Brinkie Pie" to the 2nd position in the waitlist
 *
 * @author jtbrinkmann aka. Brinkie Pie
 * @license MIT License
 * @copyright (c) 2015 J.-T. Brinkmann
 */

/*####################################
#           CHAT COMMANDS            #
####################################*/
module \chatCommands, do
    optional: <[ currentMedia ]>
    setup: ({addListener},,cC_) !->
        addListener API, \chatCommand, (c) !~>
            if (cmd=@_commands[/^\/(\w+)/.exec(c)?.1 .toLowerCase!])
                console.log "/chatCommand", cmd, cmd.moderation
                if (not cmd.moderation or user.gRole or cmd.moderation == true and user.isStaff or user.role >= cmd.moderation)
                    try
                        cmd.callback(c)
                    catch err
                        chatWarn "<div>#{err.message}</div>", "error while executing #c", true
                        console.error "[chatCommand] #c"
                        throw err
                else
                    chatWarn "You need to be #{if cmd.moderation === true then 'staff' else 'at least '+getRank(role: cmd.moderation)}", c
        if cC_
            for k,v of cC_.commands when k not of @commands
                @commands[k] = v
        @updateCommands!

    updateCommands: !->
        return if @updating
        @updating = true
        requestAnimationFrame ~>
            @updating = false
            @_commands = {}
            for k,v of @commands when v
                @_commands[k] = v
                for k in v.aliases ||[]
                    @_commands[k] = v
    parseUserArg: (str) !->
        if /[\s\d]+/.test str # list of user IDs
            return  [+id for id in str .split /\s+/ when +id]
        else
            return [user.id for user in getMentions str]
    commands:
        commands:
            description: "show this list of commands"
            callback: !->
                user = API.getUser!
                res = "<div class='msg text'>"
                for k,command of chatCommands.commands when command and (not command.moderation or user.gRole or (if command.moderation == true then user.role > 2 else user.role >= command.moderation))
                    descr = "#{command.parameters ||''} - #{command.description}"
                    title = "/#k #descr"
                    if command.aliases?.length
                        title += "\n#{plural command.aliases.length, 'alias', 'aliases'}: #{humanList command.aliases}"
                    res += "<div class=p0ne-help-command title='#title'><b>/#k</b> #descr</div>"
                res += "</div>"
                appendChat($ "<div class='cm update p0ne-help'>" .html res)


        woot:
            description: "woot the current song"
            callback: woot

        meh:
            description: "meh the current song"
            callback: meh

        grab:
            aliases: <[ curate ]>
            parameters: " (playlist)"
            description: "grab the current song into a playlist (default is current playlist)"
            callback: (c) !->
                if c.replace(/^\/\w+\s*/, '')
                    grabMedia(that)
                else
                    grabMedia!
        /*away:
            aliases: <[ afk ]>
            description: "change your status to <b>away</b>"
            callback: !->
                API.setStatus 1
        busy:
            aliases: <[ work working ]>
            description: "change your status to <b>busy</b>"
            callback:  !->
                API.setStatus 2
        gaming:
            aliases: <[ game ingame ]>
            description: "change your status to <b>gaming</b>"
            callback:  !->
                API.setStatus 3*/

        join:
            description: "join the waitlist"
            callback: join
        leave:
            description: "leave the waitlist"
            callback: leave

        stream:
            parameters: " [on|off]"
            description: "enable/disable the stream (just '/stream' toggles it)"
            callback: (c) !->
                if currentMedia?
                    # depending on the parameter, this return true ("on"), false ("off") and defaults to "toggle"
                    stream c.has \on || not (c.has(\off) || \toggle)
                else
                    chatWarn "couldn't load required module for enabling/disabling the stream."

        snooze:
            description: "snoozes the current song"
            callback: snooze
        mute:
            aliases: <[ stfu silence ]>
            parameters: "[[duration] @username(s)]"
            description: "if no parameters then mute the audio, \notherwise mute the specified user(s)"
            callback: (user) !->
                user .= replace(/^\/\w+\s*/, '').trim!
                if not user
                    mute!
                else
                    if durArg = /\w+/.exec user
                        duration = {
                            s: \s, short:  \s, 15: \s, \15min : \s,
                            m: \m, middle: \m, 30: \m, \30min : \m
                            l: \l, long:   \l, 45: \l, \45min : \l
                        }[durArg.1]
                        if duration
                            user .= substr durArg.1.length
                        else if getUser(durArg.1)
                            duration = \s
                    else
                        duration = \s

                    if not duration or user in <[ h -h help --help ? hlep ]>
                        chatWarn '<div class=p0ne-help-command>
                            possible durations are:<br>
                            - <b>s</b> (<em>15min</em>, <em>short</em>)<br>
                            - <b>m</b> (<em>30min</em>, <em>middle</em>)<br>
                            - <b>l</b> (<em>45min</em>, <em>long</em>)<br>
                            If left out, defaults to 15 minutes.<br>
                            You can also use /mute to extend/reduce the mute time.
                        </div>', '/mute [[duration] @username(s)]', true /*HTML*/
                    else
                        for id in chatCommands.parseUserArg user
                            API.moderateMuteUser id, duration, 1 #ToDo check this
        unmute:
            parameters: "[@username(s)]"
            description: "unmutes the audio or specified user(s)"
            callback: (user) !->
                user .= replace(/^\/\w+\s*/, '').trim!
                if not user
                    unmute!
                else
                    for id in chatCommands.parseUserArg user
                        API.moderateUnmuteUser id, duration, 1 #ToDo check this

        muteonce:
            aliases: <[ muteone ]>
            description: "mutes the current song"
            callback: muteonce

        automute:
            parameters: " [add|remove]"
            description: "adds/removes this song from the automute list"
            callback:  !->
                muteonce! if API.getVolume! != 0
                if automute?
                    # see note for /stream
                    automute(c.hasAny \add || not(c.hasAny \remove || \toggle))
                else
                    chatWarn "automute is not yet implemented"

        volume:
            parameters: " (0 - 100)"
            description: "sets the volume to the specified percentage"
            callback: (vol) !->
                vol .= replace(/^\/\w+\s*|%/, '').trim!
                API.setVolume +vol

        popout:
            aliases: <[ popup ]>
            description: "opens/closes the chat popout window"
            callback: !->
                if PopoutView?
                    if PopoutView._window
                        PopoutView.close!
                    else
                        PopoutView.show!
                else
                    chatWarn "sorry, the command currently doesn't work"

        reconnect:
            aliases: <[ reconnectSocket forceReconnect ]>
            description: "forces the socket to reconnect. This might solve chat issues"
            callback: !->
                _$context?.once \sjs:reconnected, !->
                    chatWarn "socket reconnected", '/reconnect'
                reconnectSocket!
        rejoin:
            aliases: <[ rejoinRoom ]>
            description: "forces a rejoin to the room (to fix issues)"
            callback: !->
                _$context?.once \room:joined, !->
                    chatWarn "room rejoined", '/rejoin'
                rejoinRoom!

        intercom:
            aliases: <[ messages ]>
            description: "Show Intercom messages"
            callback: !->
                Intercom("showMessages")

        #== moderator commands ==
        #        addListener API, 'socket:modAddDJ socket:modBan socket:modMoveDJ socket:modRemoveDJ socket:modSkip socket:modStaff', (u) !-> updateUser u.mi
        ban:
            aliases: <[ gtfo rekt abuse ]>
            parameters: "[duration] @username(s)"
            description: "bans the specified user(s). use `/ban help` for more info"
            moderation: true
            callback: (user) !->
                user .= replace(/^\/\w+\s*/, '').trim!
                if not user or user in <[ h -h help --help ? hlep ]>
                    chatWarn '<div class=p0ne-help-command>
                        possible durations are:<br>
                        - <b>s</b> (<em>15min</em>, <em>short</em>)<br>
                        - <b>h</b> (<em>1h</em>, <em>hour</em>, <em>long</em>)<br>
                        - <b>f</b> (<em>forever</em>, <em>p</em>, <em>perma</em>)<br>
                        If left out, defaults to 15 minutes.<br>
                        You can also use /ban to extend the ban time.
                    </div>', '/ban [duration] @username(s)', true /*HTML*/
                for id in chatCommands.parseUserArg user
                    API.modBan id, \s, 1 #ToDo check this
        unban:
            aliases: <[ pardon revive ]>
            parameters: " @username(s)"
            description: "unbans the specified user(s)"
            moderation: true
            callback: (user) !->
                for id in chatCommands.parseUserArg user.replace(/^\/\w+\s*/, '')
                    API.moderateUnbanUser id
                else
                    chatWarn "couldn't find any user", '/unban'

        move:
            parameters: " @username position"
            description: "moves a user to the pos. in the waitlist"
            moderation: true
            callback: (c) !->
                wl = API.getWaitList!
                var pos
                c .= replace /(\d+)\s*$/, (,d) !->
                    pos := +d
                    return ''
                if 0 < pos < 51
                    if users = chatCommands.parseUserArg(c.replace(/^\/\w+\s*/, ''))
                        if not (id = users.0) or not getUser(id)
                            chatWarn "The user doesn't seem to be in the room"
                        else
                            moveDJ id, pos
                        return
                    else
                        error = "requires you to specify a user to be moved"
                else
                    error = "requires a position to move the user to"
                chatWarn "#error<br>e.g. /move @#{API.getUsers!.random!.rawun} #{~~(Math.random! * wl.length) + 1}", '/move', true
        moveTop:
            aliases: <[ push ]>
            parameters: " @username(s)"
            description: "moves the specified user(s) to the top of the waitlist"
            moderation: true
            callback: (c) !->
                users = chatCommands.parseUserArg c.replace(/^\/\w+\s*/, '')
                # iterating over the loop in reverse, so that the first name will be the first, second will be second, …
                for i from users.length - 1 to 0
                    moveDJ i, 1
                else
                    chatWarn "couldn't find any user", '/moveTop'
        /*moveUp:
            aliases: <[  ]>
            parameters: " @username(s) (how much)"
            description: "moves the specified user(s) up in the waitlist"
            moderation: true
            callback: (user) !->
                res = []; djsToAdd = []; l=0
                wl = API.getWaitList!
                # iterating over the loop in reverse, so that the first name will be the first, second will be second, …
                for id in chatCommands.parseUserArg user.replace(/^\/\w+\s*(?:)/, '')
                    for u, pos in wl when u.id == id
                        if pos == 0
                            skipFirst = true
                        else
                            res[pos - 1] = u.id
                        break
                    else
                        djsToAdd[l++] = id
                console.log "[/move] starting to move…", res, djsToAdd
                pos = -1; l = res.length
                do helper = !->
                    id = res[++pos]
                    if id
                        if not skipFirst
                            console.log "[/move]\tmoving #id to #{pos + 1}/#{wl.length}"
                            moveDJ id, pos
                                .then helper
                                .fail !->
                                    chatWarn "couldn't /moveup #{if getUser(id) then that.username else id}"
                                    helper!
                        else
                            helper!
                    else if pos < l
                        skipFirst := false
                        helper!
                    else
                        for id in djsToAdd
                            addDJ id
                        console.log "[/move] done"
        moveDown:
            aliases: <[  ]>
            parameters: " @username(s) (how much)"
            description: "moves the specified user(s) down in the waitlist"
            moderation: true
            callback: !->
                ...
        */

        addDJ:
            aliases: <[ add ]>
            parameters: " @username(s)"
            description: "adds the specified user(s) to the waitlist"
            moderation: true
            callback: (c) !->
                users = chatCommands.parseUserArg c.replace(/^\/\w+\s*/, '')
                i = 0
                if users.length
                    do helper = !->
                        if users[i]
                            addDJ users[i++], helper
                else
                    chatWarn "couldn't find any user", '/addDJ'
        removeDJ:
            aliases: <[ remove ]>
            parameters: " @username(s)"
            description: "removes the specified user(s) from the waitlist / DJ booth"
            moderation: true
            callback: (c) !->
                for id in chatCommands.parseUserArg c.replace(/^\/\w+\s*/, '')
                    API.moderateRemoveDJ id
                else
                    chatWarn "couldn't find any user", '/removeDJ'
        skip:
            aliases: <[ forceSkip s ]>
            description: "skips the current song"
            moderation: true
            callback: ->
                if API.getTimeElapsed! > 2s
                    API.moderateForceSkip!
                else
                    chatWarn "
                        The song just changed, are you sure you want to skip?<br>
                        <button class=p0ne-btn onclick='API.moderateForceSkip()'>skip</button>\xa0
                        <button class=p0ne-btn onclick='$(this).closest(\".cm\").remove()'>cancel</button>
                    ", '/skip', true

        promote:
            parameters: " @username(s)"
            description: "promotes the specified user(s) to the next rank"
            moderation: 3
            callback: (c) !->
                for id in chatCommands.parseUserArg c.replace(/^\/\w+\s*/, '')
                    if getUser(id)
                        API.moderateSetRole(id, that.role + 1)
        demote:
            parameters: " @username(s)"
            description: "demotes the specified user(s) to the lower rank"
            moderation: 3
            callback: (c) !->
                for id in chatCommands.parseUserArg c.replace(/^\/\w+\s*/, '')
                    user = getUser(id)
                    if user?.role > 0
                        API.moderateSetRole(id, user.role - 1)
        destaff:
            parameters: " @username(s)"
            description: "removes the specified user(s) from the staff"
            moderation: 3
            callback: (c) !->
                for id in chatCommands.parseUserArg c.replace(/^\/\w+\s*/, '')
                    user = getUser(id)
                    if user?.role > 0
                        API.moderateSetRole(id, 0)
        rdj:
            aliases: <[ resident residentDJ dj ]>
            parameters: " @username(s)"
            description: "makes the specified user(s) resident DJ"
            moderation: 3
            callback: (c) !->
                for id in chatCommands.parseUserArg c.replace(/^\/\w+\s*/, '')
                    user = getUser(id)
                    if user?.role > 0
                        API.moderateSetRole(id, 1)
        bouncer:
            aliases: <[ helper temp staff ]>
            parameters: " @username(s)"
            description: "makes the specified user(s) bouncer"
            moderation: 3
            callback: (c) !->
                for id in chatCommands.parseUserArg c.replace(/^\/\w+\s*/, '')
                    user = getUser(id)
                    if user?.role > 0
                        API.moderateSetRole(id, 2)
        manager:
            parameters: " @username(s)"
            description: "makes the specified user(s) manager"
            moderation: 4
            callback: (c) !->
                for id in chatCommands.parseUserArg c.replace(/^\/\w+\s*/, '')
                    user = getUser(id)
                    if user?.role > 0
                        API.moderateSetRole(id, 3)
        cohost:
            aliases: <[ co-host co ]>
            parameters: " @username(s)"
            description: "makes the specified user(s) co-host"
            moderation: 5
            callback: (c) !->
                for id in chatCommands.parseUserArg c.replace(/^\/\w+\s*/, '')
                    user = getUser(id)
                    if user?.role > 0
                        API.moderateSetRole(id, 4)
        host:
            parameters: " @username"
            description: "makes the specified user the communities's host (USE WITH CAUTION!)"
            moderation: 5
            callback: (c) !->
                user = getUser(chatCommands.parseUserArg c.replace(/^\/\w+\s*/, ''))
                if user?.role > 0
                    API.moderateSetRole(id, 5)
