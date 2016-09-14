/**
 * Base plug_p0ne modules
 * @author jtbrinkmann aka. Brinkie Pie
 * @version 1.0
 * @license MIT License
 * @copyright (c) 2014 J.-T. Brinkmann
 */


/*####################################
#           DISABLE/STATUS           #
####################################*/
module \disableCommand, do
    modules: <[ autojoin ]> # autorespond 
    setup: ({addListener}) ->
        addListener API, \chat, (data) ~>
            if data.message.has("!disable") and data.message.has("@#{user.username}") and API.hasPermission(data.uid, API.ROLE.BOUNCER)
                console.warn "[DISABLE] '#status'"
                enabledModules = []
                for m in @modules
                    if window[m] and not window[m].disabled
                        enabledModules[*] = m
                        window[m].disable!
                    else
                        disabledModules[*] = m
                response = "#{data.un} - "
                if enabledModules.length
                    response += "disabled #{humanList enabledModules}."
                if disabledModules.length
                    response += " #{humanList enabledModules} were already disabled."
                API.sendChat response

module \getStatus, do
    module: ->
        status = "Running plug_p0ne v#{p0ne.version}"
        status += " (incl. chat script)" if window.p0ne_chat
        status += "\tand plug³ v#{getPlugCubedVersion!}" if window.plugCubed
        status += "\tand plugplug #{window.getVersionShort!}" if window.ppSaved
        status += ".\tStarted #{ago p0ne.started}."
        modules = [m for m in disableCommand.modules when window[m] and not window[m].disabled]
        status += ".\t#{humanList} are enabled" if modules

module \statusCommand, do
    timeout: false
    setup: ({addListener}) ->
        addListener API, \chat, (data) ~> if not @timeout
            if data.message.has( \!status ) and data.message.has("@#{user.username}") and API.hasPermission(data.uid, API.ROLE.BOUNCER)
                @timeout = true
                status = "#{getStatus!}"
                console.info "[AUTORESPOND] status: '#status'", data.uid, data.un
                API.sendChat status, data
                sleep 30min *60_000to_ms, ->
                    @timeout = false
                    console.info "[status] timeout reset"


/*####################################
#             YELLOW MOD             #
####################################*/
module \yellowMod, do
    settings: \chat
    displayName: 'Have yellow name as mod'
    setup: ({css}) ->
        id = API.getUser! .id
        css \yellowMod, "
            \#chat .fromID-#id .un,
            .user[data-uid='#id'] .name > span {
                color: \#ffdd6f !important;
            }
        "
            # \#chat .from-#id .from,
            # \#chat .fromID-#id .from,


/*####################################
#         08/15 PLUG SCRIPTS         #
####################################*/
module \autojoin, do
    settings: \base
    disabled: true
    setup: ({addListener}) ->
        do addListener API, \advance, ->
            if join!
                console.log "#{getTime!} [autojoin] joined waitlist"




# adds a user-rollover to the FriendsList when clicking someone's name
module \friendslistUserPopup, do
    require: <[ friendsList FriendsList chat ]>
    setup: ({addListener}) ->
        addListener $(\.friends), \click, '.name, .image', (e) ->
            id = friendsList.rows[$ this.closest \.row .index!] ?.model.id
            user = users.get(id) if id
            data = x: $body.width! - 353px, y: e.screenY - 90px
            if user
                chat.onShowChatUser user, data
            else if id
                chat.getExternalUser id, data, (user) ->
                    chat.onShowChatUser user, data
        #replace friendsList, \drawBind, -> return _.bind friendsList.drawRow, friendsList
# adds a user-rollover to the FriendsList when clicking someone's name
module \waitlistUserPopup, do
    require: <[ WaitlistRow ]>
    setup: ({replace}) ->
        replace WaitlistRow::, "render", (r_) -> return ->
            r_ ...
            @$ '.name, .image' .click @clickBind

module \titleCurrentSong, do
    disable: ->
        $ \#now-playing-media .prop \title, ""
    setup: ({addListener}) ->
        addListener API, \advance, (d) ->
            if d
                $ \#now-playing-media .prop \title, "#{d.media.author} - #{d.media.title}"
            else
                $ \#now-playing-media .prop \title, null


/*####################################
#       MEH-ICON IN USERLIST         #
####################################*/
module \userlistIcons, do
    require: <[ RoomUserRow ]>
    setup: ({replace})  ->
        replace RoomUserRow::, \vote, -> return ->
            if @model.id == API.getDJ!
                @$icon.addClass \icon-woot
            if @model.get \grab
                vote = \grab
            else
                vote = @model.get \vote
                vote = 0 if vote == -1 and (user = API.getUser!).role == user.gRole == 0
            if @model.id == API.getDJ!.id
                if vote # stupid haxxy edge-cases… well to be fair, I don't see many other people but me abuse that >3>
                    if not @$djIcon
                        @$djIcon = $ '<i class="icon icon-current-dj" style="right: 35px">'
                            .appendTo @$el
                        API.once \advance, ~>
                            @$djIcon .remove!
                            delete @$djIcon
                else
                    vote = \dj
            if vote != 0
                @$icon ||= $ \<i>
                @$icon
                    .removeClass!
                    .addClass \icon
                    .appendTo @$el

                if vote == -1
                    @$icon.addClass \icon-meh
                else if vote == \grab
                    @$icon.addClass \icon-grab
                else if vote == \dj
                    @$icon.addClass \icon-current-dj
                else
                    @$icon.addClass \icon-woot
            else if @$icon
                @$icon .remove!
                delete @$icon


/*####################################
#      DISABLE MESSAGE DELETE        #
####################################*/
module \disableChatDelete, do
    require: <[ _$context ]>
    optional: <[ socketListeners ]>
    settings: \chat
    displayName: 'Show deleted messages'
    setup: ({replace_$Listener, addListener, $create, css}) ->
        $body .addClass \p0ne_showDeletedMessages
        css \disableChatDelete, '
            .deleted {
                border-left: 2px solid red;
                display: none;
            }
            .p0ne_showDeletedMessages .deleted {
                display: block;
            }
            .deleted-message {
                display: block;
                text-align: right;
                color: red;
                font-family: monospace;
            }
        '

        addListener _$context, \socket:chatDelete, ({{c,mi}:p}) ->
            markAsDeleted(c, users.get(mi)?.get(\username) || mi)
        addListener \early, _$context, \chat:delete, -> return (cid) ->
            markAsDeleted(cid) if not socketListeners

        function markAsDeleted cid, moderator
            $msg = getChat cid
            #ToDo add scroll down
            console.log "[Chat Delete]", cid, $msg.text!
            t  = getISOTime!
            t += " by #moderator" if moderator
            try
                wasAtBottom = isChatAtBottom?!
                $msg
                    .removeClass \deletable
                    .addClass \deleted
                d = $create \<time>
                    .addClass \deleted-message
                    .attr \datetime, t
                    .text t
                    .appendTo $msg
                #cm = $cm!
                #cm.scrollTop cm.scrollTop! + d.height!
                scrollChatDown?! if wasAtBottom

    disable: ->
        $body .removeClass \p0ne_showDeletedMessages



/*####################################
#        DBLCLICK to @MENTION        #
####################################*/
module \chatDblclick2Mention, do
    require: <[ chat ]>
    #optional: <[ PopoutListener ]>
    settings: \chat
    displayName: 'DblClick username to Mention'
    setup: ({replace, addListener}) ->
        newFromClick = (e) ~>
            if not @timer # single click
                @timer = sleep 200ms, ~> if @timer
                    @timer = 0
                    chat.onFromClick e
            else # double click
                clearTimeout @timer
                @timer = 0
                chat.onInputMention e.target.textContent
            e .stopPropagation!; e .preventDefault!

        replace chat, \fromClick, (@fC_) ~> return newFromClick
        replace chat, \fromClickBind, -> return newFromClick

        # patch event listeners on old messages
        $cm! .find \.un
            .off \click, @fC_
            .on \click, newFromClick

        addListener chatDomEvents, \click, \.un, newFromClick
    disable: -> if @fC_
        cm = $cm!
        cm  .find \.un
            .off \click, newFromClick
        cm  .find '.mention .un, .message .un' # note: here we actually have to pay attention as to what to re-enable
            .on \click, @fC_



/*####################################
#           CHAT COMMANDS            #
####################################*/
module \chatCommands, do
    setup: ({addListener}) ->
        addListener API, \chatCommand, (c) ->
            switch /\/\w+/.exec(c)?.0
            | \/avail, \/available =>
                API.setStatus 0
            | \/afk, \/away =>
                API.setStatus 1
            | \/work, \/busy =>
                API.setStatus 2
            | \/gaming, \/ingame, \/game =>
                API.setStatus 3
            | \/join =>
                join!
            | \/leave =>
                leave!
            | \/mute =>
                mute!
            | \/muteonce, \/onemute =>
                muteonce!
            | \/unmute =>
                unmute!
            | \/automute =>
                muteonce!
                if not automute?
                    API.chatLog "automute is not yet implemented", true
                else
                    automute!

/*####################################
#              AUTOMUTE              #
####################################*/
module \automute, do
    songlist: dataLoad \p0ne_automute, {}
    module: (media) ->
        media ||= API.getMedia!
        if @songlist[media.id]
            delete @songlist[media.id]
            API.chat "'#{media.author} - #{media.title}' removed from the automute list."
        else
            @songlist[media.id] = true
            API.chat "'#{media.author} - #{media.title}' added to automute list."
    setup: ({addListener}) ->
        isAutomuted = false
        addListener API, \advance, ({media}) ~>
            wasAutomuted = isAutomuted
            isAutomuted := false
            if media and media.id in @songlist
                isAutomuted := true
            if isAutomuted
                mute!
            else if wasAutomuted
                unmute!



/*####################################
#      JOIN/LEAVE NOTIFICATION       #
####################################*/
module \joinLeaveNotif, do
    optional: <[ chatDomEvents chat auxiliaries database ]>
    settings: \base
    displayName: 'Join/Leave Notifications'
    help: '''
        Shows notifications for when users join/leave the room in the chat.
    '''
    setup: ({addListener, css},,,update) ->
        if update
            lastMsg = $cm! .children! .last!
            if lastMsg .hasClass \p0ne-joinLeave-notif
                $lastNotif = lastMsg

        verbRefreshed = 'refreshed'
        usersInRoom = {}
        for let event, verb_ of {userJoin: 'joined', userLeave: 'left'}
            addListener API, event, (user) ->
                verb = verb_
                if event == \userJoin
                    if usersInRoom[user.id]
                        verb = verbRefreshed
                    else
                        usersInRoom[user.id] = Date.now!
                else
                    delete usersInRoom[user.id]


                $msg = $ "
                    <span data-uid=#{user.id}>
                        #{if event == \userJoin then '+ ' else '- '}
                        <span class=un>#{resolveRTL user.username}</span> #verb the room
                        #{if not (auxiliaries? and database?) then '' else
                            '<div class=timestamp>' + auxiliaries.getChatTimestamp(database.settings.chatTS == 24) + '</div>'
                        }
                    </span>
                    "
                if false #chat?.lastType == \joinLeave
                    $lastNotif .append $msg
                else
                    $lastNotif := $ "<div class='cm update p0ne-joinLeave-notif'></div>"
                        .append $msg
                    appendChat $lastNotif
                    if chat?
                        $lastNotif .= find \.message
                        chat.lastType = \joinLeave
        if chat? and chatDomEvents?
            addListener chatDomEvents, \click, '.p0ne-join-notif, .p0ne-leave-notif', (e) ->
                chat.fromClick e

        if not update
            d = Date.now!
            for user in API.getUsers!
                usersInRoom[user.id] = -1



