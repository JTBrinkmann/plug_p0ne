/**
 * Base plug_p0ne modules
 *
 * @author jtbrinkmann aka. Brinkie Pie
 * @license MIT License
 * @copyright (c) 2015 J.-T. Brinkmann
 */


/*####################################
#           DISABLE/STATUS           #
####################################*/
module \disableCommand, do
    modules: <[ autojoin ]> # autorespond
    setup: ({addListener}) ->
        addListener API, \chat, (data) ~>
            if data.message.has("!disable") and data.message.has("@#{user.username}") and API.hasPermission(data.uid, API.ROLE.BOUNCER)
                console.warn "[DISABLE] '#{status}'"
                enabledModules = []; disabledModules = []
                for m in @modules when module = window[m]
                    if module and not module.disabled
                        enabledModules[*] = module.displayName || module.name
                        module.disable!
                    else
                        disabledModules[*] = module.displayName || module.name
                response = "#{data.un} - "
                if enabledModules.length
                    response += "disabled #{humanList enabledModules}."
                if disabledModules.length
                    response += " #{humanList disabledModules} #{if disabledModules.length then 'was' else 'were'} already disabled."
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
#         08/15 PLUG SCRIPTS         #
####################################*/
module \autojoin, do
    settings: \base
    disabled: true
    setup: ({addListener}) ->
        addListener API, \advance, (d) ->
            # this way, if you get removed from the waitlist by staff, autojoin will not trigger
            if d.dj?.id == userID
                addListener \once, API, \advance, ->
                    if join!
                        console.log "#{getTime!} [autojoin] joined waitlist"
                    else
                        console.error "#{getTime!} [autojoin] failed to join waitlist"
        console.log "#{getTime!} [autojoin] init: joined waitlist" if join!




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
            if d.media
                $ \#now-playing-media .prop \title, "#{d.media.author} - #{d.media.title}"
            else
                $ \#now-playing-media .prop \title, null


/*####################################
#       MORE ICON IN USERLIST        #
####################################*/
module \userlistIcons, do
    require: <[ RoomUserRow ]>
    _settings:
        forceMehIcon: false
    setup: ({replace})  ->
        settings = @_settings
        replace RoomUserRow::, \vote, -> return ->
            dj = API.getDJ!
            if @model.id == dj
                @$icon.addClass \icon-woot
            if @model.get \grab
                vote = \grab
            else
                vote = @model.get \vote
                vote = 0 if vote == -1 and (user = API.getUser!).role == user.gRole == 0
            if dj and @model.id == dj.id
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

                if vote == -1 and API.getUser!.role > 0 or settings.forceMehIcon
                    # i think RDJs should be able to see mehs as well
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

            # fix username
            if chatPolyfixEmoji?.fixedUsernames[@model.id]
                @$el .find \.name .html that



/*####################################
#        DBLCLICK to @MENTION        #
####################################*/
/*note: this is also makes usernames clickable in many other parts of plug.dj & other plug_p0ne modules */
module \chatDblclick2Mention, do
    require: <[ chat ]>
    #optional: <[ PopoutListener ]>
    settings: \chat
    displayName: 'DblClick username to Mention'
    setup: ({replace, addListener}) ->
        module = this
        newFromClick = (e) ->
            if not module.timer # single click
                module.timer = sleep 200ms, ~> if module.timer
                    try
                        module.timer = 0
                        $this = $ this
                        if r = ($this .closest \.cm .children \.badge-box .data \uid) || ($this .data \uid) || (i = getUserInternal $this.text!).id
                            pos =
                                x: chat.getPosX!
                                y: $this .offset!.top
                            if i ||= getUserInternal(r)
                                chat.onShowChatUser i, pos
                            else
                                chat.getExternalUser r, pos, chat.showChatUserBind
                        else
                            console.warn "[dblclick2Mention] couldn't get userID", this
                    catch err
                        console.error err.stack
            else # double click
                clearTimeout module.timer
                module.timer = 0
                (PopoutView?.chat? || chat).onInputMention e.target.textContent
            e .stopPropagation!; e .preventDefault!

        replace chat, \fromClick, (@fC_) ~> return newFromClick
        replace chat, \fromClickBind, -> return newFromClick

        # patch event listeners on old messages
        $cm! .find \.un
            .off \click, @fC_
            .on \click, newFromClick

        addListener chatDomEvents, \click, \.un, newFromClick
        addListener $(\#waitlist), \click, \.name, newFromClick
    disable: -> if @fC_
        cm = $cm!
        cm  .find \.un
            .off \click, newFromClick

        # note: here we actually have to pay attention as to what to re-enable
        cm  .find '.mention .un, .message .un'
            .on \click, @fC_


/*####################################
#              AUTOMUTE              #
####################################*/
module \automute, do
    optional: <[ streamSettings ]>
    songlist: dataLoad \p0ne_automute, {}
    module: (media, addRemove) ->
        if typeof media == \boolean
            addRemove = media; media = false
        media ||= API.getMedia!

        if not addRemove? # default to toggle
            addRemove = not @songlist[media.cid]

        $msg = $ "<div class='p0ne-automute-notif'>"
        if addRemove # add to automute list
            @songlist[media.cid] = media{title, author}
            $msg
                .text "+ '#{media.author} - #{media.title}' added to automute list."
                .addClass \p0ne-automute-added
        else # remove from automute list
            delete @songlist[media.cid]
            $msg
                .text "- '#{media.author} - #{media.title}' removed from the automute list."
                .addClass \p0ne-automute-removed
        $msg .append getTimestamp!
        appendChat $msg
        @updateBtn!

    setup: ({addListener}, automute) ->
        media = API.getMedia!
        addListener API, \advance, (d) ~>
            media := d.media
            if media and @songlist[media.cid]
                muteonce!

        #== Turn SNOOZE button into add/remove AUTOMUTE button when media is snoozed ==
        $snoozeBtn = $ '#playback .snooze'
        @$box_ = $snoozeBtn .children!
        $box = $ "<div class='box'></div>"
        streamOff = isSnoozed!
        addListener API, \p0ne:changeMode, onModeChange = (mode) ~>
            newStreamOff = (mode == \off)
            <~ requestAnimationFrame
            if newStreamOff
                if not streamOff
                    $snoozeBtn
                        .empty!
                        .append $box
                if not media
                    # umm, this shouldn't happen. when there's no song playing, there shouldn't be playback-controls
                    console.warn "[automute] uw0tm8?"
                else if @songlist[media.cid] # btn "remove from automute"
                    console.log "[automute] change automute-btn to REMOVE"
                    $snoozeBtn .addClass 'p0ne-automute p0ne-automute-remove'
                    $box .html "remove from<br>automute"
                else # btn "add to automute"
                    console.log "[automute] change automute-btn to ADD"
                    $snoozeBtn .addClass 'p0ne-automute p0ne-automute-add'
                    $box .html "add to<br>automute"
            else if streamOff
                console.log "[automute] change automute-btn to SNOOZE"
                $snoozeBtn
                    .empty!
                    .append @$box_
                    .removeClass 'p0ne-automute p0ne-automute-remove p0ne-automute-add'
            streamOff := newStreamOff

        @updateBtn = (mode) ->
            onModeChange(streamOff && \off)

        addListener $snoozeBtn, \click, (e) ~>
            if streamOff
                console.info "[automute] snoozy", media.cid, @songlist[media.cid], streamOff
                automute!

    disable: ->
        $ '#playback .snooze'
            .empty!
            .append @$box_




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
            if lastMsg .hasClass \p0ne-notif-joinleave
                $lastNotif = lastMsg

        verbRefreshed = 'refreshed'
        usersInRoom = {}
        for let event, verb_ of {userJoin: 'joined', userLeave: 'left'}
            addListener API, event, (u) ->
                verb = verb_
                if event == \userJoin
                    if usersInRoom[u.id]
                        verb = verbRefreshed
                    else
                        usersInRoom[u.id] = Date.now!
                else
                    delete usersInRoom[u.id]


                $msg = $ "
                    <div class=p0ne-notif-#{if event == \userJoin then \join else \leave} data-uid=#{u.id}>
                        #{if event == \userJoin then '+ ' else '- '}
                        #{formatUserHTML u, user.isStaff, false}
                        #{getTimestamp!}
                    </div>
                    "
                if chat?.lastType == \p0ne_joinLeave and $lastNotif
                    isAtBottom = chatIsAtBottom!
                    $lastNotif .append $msg
                    chatScrollDown! if isAtBottom
                else
                    $lastNotif := $ "<div class='cm update p0ne-notif p0ne-notif-joinleave'></div>"
                        .append $msg
                    appendChat $lastNotif
                    if chat?
                        chat.lastType = \p0ne-notif-joinleave
        addListener API, 'popout:open popout:close', (,PopoutView) ->
            $lastNotif = $cm! .find \.p0ne-notif-joinleave:last
        if not update
            d = Date.now!
            for u in API.getUsers!
                usersInRoom[u.id] = -1

        export get$lastNotif = ->
            return $lastNotif

# note: the avg. song duration seems to be off
#ToDo: on advance, check if historyID is different from the last play's
module \etaTimer, do
    displayName: 'ETA Timer'
    settings: \base
    setup: ({css, addListener, $create}) ->
        css \etaTimer, '
            #your-next-media>span {
                width: auto !important;
                right: 50px;
            }
        '
        sum = lastSongDur = 0
        $nextMediaLabel = $ '#your-next-media > span'
        $eta = $create '<div class=p0ne-eta>'
            .append $etaText = $ '<span class=p0ne-eta-text>ETA: </span>'
            .append $etaTime = $ '<span class=p0ne-eta-time></span>'
            .appendTo \#footer


        # note: the ETA timer cannot be shown while the room's history is 0
        # because you need to be in the waitlist to see the ETA timer


        # attach event listeners
        addListener API, \waitListUpdate, updateETA
        addListener API, \advance, (d) ->
            # update average song duration. This is to avoid having to loop through the whole song history on each update
            if d.media
                sum -= lastSongDur
                sum += d.media.duration
                lastSongDur := API.getHistory![l - 1].media.duration
            # note: we don't trigger updateETA() because each advance is accompanied with a waitListUpdate

        # initialize average song length
        # (this is AFTER the event listeners, because tinyhist() has to run after it)
        for m in hist = API.getHistory!
            sum += m.media.duration
        l = hist.length

        # handle the case that history length is < 50
        if l < 51 # 51 because it includes the currently playing song
            #lastSongDur = 0
            do tinyhist = ->
                addListener \once, API, \advance, (d) ->
                    if d.media
                        lastSongDur := 0
                        l++
                    tinyhist! if l < 51
        else
            lastSongDur = API.getHistory![l - 1].media.duration


        # show the ETA timer
        updateETA!

        export test = ->
            p = API.getWaitListPosition()
            avg_ = (API.getTimeRemaining!  +  sum * p / l)
            avg = avg_ / 60 |> Math.round
            return {l, avg, avg_, sum, p}

        ~function updateETA
            # update what the ETA timer says
            #clearTimeout @timer
            p = API.getWaitListPosition()
            if p == 0
                #console.log "[ETA] updated to 'you are next DJ!'"
                $etaText .text "you are next DJ!"
                $etaTime .text ''
                return
            else if p == -1
                if API.getDJ!?.id == userID
                    #console.log "[ETA] updated 'you are DJ'"
                    $etaText .text "you are DJ!"
                    $etaTime .text ''
                    return
                else
                    p = API.getWaitList!.length
            # calculate average duration
            avg_ = (API.getTimeRemaining!  +  sum * p / l)
            avg = avg_ / 60 |> Math.round

            #console.log "[ETA] updated to (#avg min)"
            $etaText .text "ETA ca. "
            if avg > 60min
                $etaTime .text "#{~~(avg / 60min_to_h)}h#{avg % 60}min"
            else
                $etaTime .text "#avg min"

            $nextMediaLabel .css right: $eta.width! - 50px

            # setup timer to update ETA
            clearTimeout @timer
            @timer = sleep ((avg_ % 60s)+31s).s, updateETA
    disable: ->
        clearTimeout @timer
/*

        lastSongDur = API.getHistory![*-1].media.duration
        nextSong = API.getMedia!
        # calculate average song duration
        sum = 0
        hist = API.getHistory!
        for i from 1 til hist.length
            sum += hist[i].media.duration
        l = hist.length - 1






                avg_ = API.getMedia!.duration + p * sum / l
*/

module \votelist, do
    settings: \base
    displayName: 'Votelist'
    disabled: true
    help: '''
        Moving your mouse above the woot/grab/meh icon shows a list of users who have wooted, grabbed or meh'd respectively.
    '''
    setup: ({addListener, $create}) ->
        currentFilter = false
        $vote = $(\#vote)
        $vl = $create '<div class=p0ne-votelist>'
            .hide!
            .appendTo $vote

        addListener $(\#woot), \mouseenter, changeFilter 'left: 0', (userlist) ->
            for u in API.getAudience! when u.vote == +1
                userlist += "<div>#{formatUserHTML(u, false, true)}</div>"
            return userlist

        addListener $(\#grab), \mouseenter, changeFilter 'left: 50%; transform: translateX(-50%)', (userlist) ->
            for u in API.getAudience! when u.grab
                userlist += "<div>#{formatUserHTML(u, false, true)}</div>"
            return userlist

        addListener $(\#meh), \mouseenter, changeFilter 'right: 0', (userlist) -> if user.isStaff
            for u in API.getAudience! when u.vote == -1
                userlist += "<div>#{formatUserHTML(u, false, true)}</div>"
            return userlist


        addListener $vote, \mouseleave, ->
            currentFilter := false
            $vl.hide!

        addListener API, \voteUpdate, updateVoteList

        function changeFilter styles, filter
            return ->
                currentFilter := filter
                css \votelist, ".p0ne-votelist { #{styles} }"
                updateVoteList!

        function updateVoteList
            if currentFilter
                userlist = currentFilter('')
                if userlist
                    $vl
                        .html userlist
                        .show!
                    $ \#tooltip .hide!
                else
                    $vl.hide!