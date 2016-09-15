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
    setup: ({addListener}) ->
        addListener API, \chat, (msg) ~>
            if msg.message.has("!disable") and API.hasPermission(msg.uid, API.ROLE.BOUNCER) and isMention(msg)
                console.warn "[DISABLE] '#{status}'"
                enabledModules = []; disabledModules = []
                for ,m of p0ne.modules when m.disableCommand
                    if not m.disabled
                        enabledModules[*] = m.displayName || m.name
                        m.disable!
                    else
                        disabledModules[*] = m.displayName || m.name
                response = "@#{msg.un} "
                if enabledModules.length
                    response += "disabled #{humanList enabledModules}."
                if disabledModules.length
                    response += " #{humanList disabledModules} #{if disabledModules.length == 1 then 'was' else 'were'} already disabled."
                API.sendChat response

module \getStatus, do
    module: ->
        status = "Running plug_p0ne v#{p0ne.version}"
        status += " (incl. chat script)" if window.p0ne_chat
        status += "\tand plug³ v#{that}" if getPlugCubedVersion!
        status += "\tand plugplug #{window.getVersionShort!}" if window.ppSaved
        status += ".\tStarted #{ago p0ne.started}"
        modules = [m for m in disableCommand.modules when window[m] and not window[m].disabled]
        status += ".\t#{humanList modules} are enabled" if modules.length

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
#             AUTOJOIN               #
####################################*/
module \autojoin, do
    displayName: "Autojoin"
    help: '''
        Automatically join the waitlist again after you DJ'd or if the waitlist gets unlocked.
        It will not automatically join if you got removed from the waitlist by a moderator.
    '''
    settings: \base
    settingsVip: true
    disabled: true
    disableCommand: true
    optional: <[ _$context booth ]>
    setup: ({addListener}) ->
        wlPos = API.getWaitListPosition!
        if wlPos == -1
            @autojoin!
        else if API.getDJ!?.id == userID
            API.once \advance, @autojoin, this

        # regular autojoin
        addListener API, \advance, ~>
            if API.getDJ!?.id == userID # if user is the current DJ, delay autojoin until next advance
                API.once \advance, @autojoin, this

        # autojoin on reconnect
        addListener API, \p0ne:reconnected, ~>
            if wlPos != -1 # make sure we were actually in the waitlist before autojoining
                @autojoin!

        $djButton = $ \#dj-button
        if _$context?
            # when joining a room
            addListener _$context, \room:joined, @autojoin, this

            # when DJ booth gets unlocked
            wasLocked = $djButton.hasClass \is-locked
            addListener _$context, \djButton:update, ~>
                isLocked = $djButton.hasClass \is-locked
                @autojoin! if wasLocked and not isLocked
                wasLocked := isLocked

        #DEBUG
        # compare if old logic would have autojoined
        addListener API, \advance, (d) ~>
            wlPos := API.getWaitListPosition!
            if d and d.id != userID and wlPos == -1
                sleep 5_000ms, ~> if API.getDJ!.id != userID and API.getWaitListPosition! == -1
                    chatWarn "old algorithm would have autojoined now. Please report about this in the beta tester Skype chat", "plug_p0ne autojoin"

    autojoin: ->
        if API.getWaitListPosition! == -1 # if user is not in the waitlist yet
            if join!
                console.log "#{getTime!} [autojoin] joined waitlist"
            else
                console.error "#{getTime!} [autojoin] failed to join waitlist"
                API.once \advance, @autojoin, this
        #else # user is already in the waitlsit
        #    console.log "#{getTime!} [autojoin] already in waitlist"

    disable: ->
        API.off \advance, @autojoin


/*####################################
#             AUTOWOOT               #
####################################*/
module \autowoot, do
    displayName: 'Autowoot'
    help: '''
        automatically woot all songs (you can still manually meh)
    '''
    settings: \base
    settingsVip: true
    disabled: true
    disableCommand: true
    optional: <[ chatDomEvents ]>
    _settings:
        warnOnMehs: true
    setup: ({addListener}) ->
        var timer
        lastScore = API.getHistory!.1.score
        hasMehWarning = false

        # on each song
        addListener API, \advance, (d) ->
            if d.media
                lastScore = d.lastPlay.score
                clearTimeout timer
                # wait between 1 to 4 seconds (to avoid flooding plug.dj servers)
                timer := sleep 1.s  +  3.s * Math.random!, ->
                    if not API.getUser!.vote # only woot if user didn't meh already
                        woot!
            if hasMehWarning
                $cms! .find \.p0ne-autowoot-meh-btn .remove!
                hasMehWarning := false

        # warn if user is blocking a voteskip
        addListener API, \voteUpdate, (d) ->
            score = API.getScore!
            # some number magic
            if score.negative > 2 * score.positive and score.negative > (lastScore.positive + lastScore.negative) / 4 and score.negative >= 5 and not hasMehWarning
                chatWarn "Many users meh'd this song, you may be stopping a voteskip. <span class=p0ne-autowoot-meh-btn>Click here to meh</span>", "Autowoot", true
                playChatSound!
                hasMehWarning := true

        # make the meh button meh
        if chatDomEvents
            addListener chatDomEvents, \click, \.p0ne-autowoot-meh-btn, ->
                meh!
                $ this .closest \.cm .remove!


/*####################################
#              AUTOMUTE              #
####################################*/
module \automute, do
    optional: <[ streamSettings ]>
    _settings:
        songlist: {}
    module: (media, isAdd) ->
        # add/remove/toggle `media` to/from/in list of automuted songs
        # and show a notification in chat

        # (isAdd)
        if typeof media == \boolean
            isAdd = media; media = false

        # (media, isAdd) and (media)
        if media
            if media.toJSON
                media = media.toJSON!
            if not media.cid or not \author of media
                throw new TypeError "invalid arguments for automute(media, isAdd=)"
        else
            # default `media` to current media
            media = API.getMedia!

        if isAdd == \toggle or not isAdd? # default to toggle
            isAdd = not @songlist[media.cid]

        $msg = $ "<div class='p0ne-automute-notif'>"
        if isAdd # add to automute list
            @songlist[media.cid] = media
            $msg
                .text "+ automute #{media.author} - #{media.title}"
                .addClass \p0ne-automute-added
        else # remove from automute list
            delete @songlist[media.cid]
            $msg
                .text "- automute #{media.author} - #{media.title}'"
                .addClass \p0ne-automute-removed
        $msg .append getTimestamp!
        appendChat $msg
        if media.cid == API.getMedia!?.cid
            @updateBtn!

    setup: ({addListener}, automute) ->
        @songlist = @_settings.songlist
        media = API.getMedia!
        addListener API, \advance, (d) ~>
            media := d.media
            if media and @songlist[media.cid]
                #muteonce!
                snooze!

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
#          AFK AUTORESPOND           #
####################################*/
module \afkAutorespond, do
    displayName: 'AFK Autorespond'
    settings: \base
    settingsVip: true
    _settings:
        message: "I'm AFK at the moment"
        timeout: 1.min
    disabled: true
    disableCommand: true

    DEFAULT_MSG: "I'm AFK at the moment"
    setup: ({addListener, $create}) ->
        var timeout
        addListener API, \chat, (msg) ~>
            if msg.uid and msg.uid != userID and isMention(msg, true) and not timeout and not msg.message.has \!disable
                API.sendChat "[AFK] #{@_settings.message || @DEFAULT_MSG}"
                timeout := true
                sleep @_settings.timeout, -> timeout := false
        $create '<div class=p0ne-afk-button>'
            .text "Disable #{@displayName}"
            .click ~> @disable! # we cannot just `.click(@disable)` because `disable` should be called without any arguments
            .appendTo \#footer-user

    settingsExtra: ($el) ->
        $input = $ "<input class=p0ne-settings-input placeholder=\"#{@DEFAULT_MSG}\">"
            .val @_settings.message
            .on \input, ~>
                @_settings.message = $input.val!
            .appendTo $el


/*####################################
#      JOIN/LEAVE NOTIFICATION       #
####################################*/
module \joinLeaveNotif, do
    optional: <[ chatDomEvents chat auxiliaries database ]>
    settings: \base
    settingsVip: true
    displayName: 'Join/Leave Notifications'
    help: '''
        Shows notifications for when users join/leave the room in the chat.
        Note: the country flags indicate the user's plug.dj language settings, they don't necessarily have to match where they are from.

        Icons explained:
        + user joined
        - user left
        \u21ba user reconnected (left and joined again)
        \u21c4 user joined and left again
    '''
    _settings:
        mergeSameUser: true
    setup: ({addListener, css}, joinLeaveNotif,,update) ->
        if update
            lastMsg = $cm! .children! .last!
            if lastMsg .hasClass \p0ne-notif-joinleave
                $lastNotif = lastMsg

        CHAT_TYPE = \p0ne-notif-joinleave
        lastUsers = {}

        #usersInRoom = {}
        cssClasses =
            userJoin: \join
            userLeave: \leave
            refresh: \refresh
            instaLeave: \instaleave
        for let event_ in <[ userJoin userLeave ]>
            addListener API, event_, (u) ->
                event = event_
                if not reuseNotif = (chat?.lastType == CHAT_TYPE and $lastNotif)
                    lastUsers := {}


                title = ''
                if reuseNotif and lastUsers[u.id] and joinLeaveNotif._settings.mergeSameUser
                    if event == \userJoin != lastUsers[u.id].event
                        event = \refresh
                        title = "title='reconnected'"
                    else if event == \userLeave != lastUsers[u.id].event
                        event = \instaLeave
                        title = "title='joined and left again'"

                $msg = $ "
                    <div class=p0ne-notif-#{cssClasses[event]} data-uid=#{u.id} #title>
                        #{formatUserHTML u, user.isStaff, false}
                        #{getTimestamp!}
                    </div>
                    "

                # cache users in this notification
                if event == event_
                    lastUsers[u.id] =
                        event: event
                        $el: $msg

                if reuseNotif
                    isAtBottom = chatIsAtBottom!
                    if event != event_
                        lastUsers[u.id].$el .replaceWith $msg
                        delete lastUsers[u.id]
                    else
                        $lastNotif .append $msg
                    chatScrollDown! if isAtBottom
                else
                    $lastNotif := $ "<div class='cm update p0ne-notif p0ne-notif-joinleave'>"
                        .append $msg
                    appendChat $lastNotif
                    if chat?
                        chat.lastType = CHAT_TYPE
 
        addListener API, 'popout:open popout:close', ->
            $lastNotif = $cm! .find \.p0ne-notif-joinleave:last





/*####################################
#     CURRENT SONG TITLE TOOLTIP     #
####################################*/
# add a tooltip (alt attr.) to the song title (in the header above the playback container)
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
    require: <[ users RoomUserRow ]>
    _settings:
        forceMehIcon: false
    setup: ({replace})  ->
        settings = @_settings
        replace RoomUserRow::, \vote, -> return ->
            if @model.id == API.getDJ!?.id
                /* fixed in Febuary 2015 http://tech.plug.dj/2015/02/18/version-1-2-7-6478/
                if vote # stupid haxxy edge-cases… well to be fair, I don't see many other people but me abuse that >3>
                    if not @$djIcon
                        @$djIcon = $ '<i class="icon icon-current-dj" style="right: 35px">'
                            .appendTo @$el
                        API.once \advance, ~>
                            @$djIcon .remove!
                            delete @$djIcon
                else*/
                vote = \dj
            else if @model.get \grab
                vote = \grab
            else
                vote = @model.get \vote
                vote = 0 if vote == -1 and not user.isStaff and not settings.forceMehIcon # don't show mehs to non-staff
                # personally, i think RDJs should be able to see mehs as well
            if vote != 0
                if @$icon
                    @$icon .removeClass!
                else
                    @$icon = $ \<i>
                        .appendTo @$el
                @$icon
                    .addClass \icon

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

            # fix username
            if chatPolyfixEmoji?.fixedUsernames[@model.id]
                @$el .find \.name .html that

        @updateEvents!

    updateEvents: ->
        for u in users.models when u._events
            for event in u._events[\change:vote] ||[] when event.ctx instanceof RoomUserRow
                event.callback = RoomUserRow::vote
            for event in u._events[\change:grab] ||[] when event.ctx instanceof RoomUserRow
                event.callback = RoomUserRow::vote

    disableLate: ->
        @updateEvents!


/*####################################
#        DBLCLICK to @MENTION        #
####################################*/
/*note: this is also makes usernames clickable in many other parts of plug.dj & other plug_p0ne modules */
module \chatDblclick2Mention, do
    require: <[ chat simpleFixes ]>
    #optional: <[ PopoutListener ]>
    settings: \chat
    displayName: 'DblClick username to Mention'
    setup: ({replace, addListener}, chatDblclick2Mention) ->
        newFromClick = (e) ->
            # after a click, wait 0.2s
            # if the user clicks again, consider it a double click
            # otherwise fall back to default behaviour (show user rollover) 
            e .stopPropagation!; e .preventDefault!

            # single click
            if not chatDblclick2Mention.timer
                chatDblclick2Mention.timer = sleep 200ms, ~> if chatDblclick2Mention.timer
                    try
                        chatDblclick2Mention.timer = 0
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
                        console.error "[dblclick2Mention] error showing user rollover", err.stack

            # double click
            else
                clearTimeout chatDblclick2Mention.timer
                chatDblclick2Mention.timer = 0
                (PopoutView?.chat || chat).onInputMention e.target.textContent

        for [ctx, $el, attr, boundAttr] in [ [chat, $cms!, \onFromClick, \fromClickBind],  [WaitlistRow::, $(\#waitlist), \onDJClick, \clickBind],  [RoomUserRow::, $(\#user-lists), \onClick, \clickBind] ]
            # remove individual event listeners (we use a delegated event listener below)
            # setting them to `$.noop` will prevent .bind to break
            #replace ctx, attr, -> return $.noop
            # setting them to `null` will make `.on("click", …)` in the vanilla code do nothing (this requires the underscore.bind fix)
            replace ctx, attr, noop
            if ctx[boundAttr]
                replace ctx, boundAttr, -> noop

            # update DOM event listeners
            $el .off \click, ctx[boundAttr]


        # instead of individual event listeners, we use a delegated event (which offers better performance)
        addListener chatDomEvents, \click, \.un, newFromClick
        addListener $(\.app-right), \click, \.name, newFromClick

        function noop
            return null

    disableLate: ->
        # note: here we actually have to pay attention as to what to re-enable
        cm = $cms!
        for attr, [ctx, $el] of {fromClickBind: [chat, cm], onDJClick: [WaitlistRow::, $(\#waitlist)], onClick: [RoomUserRow::, $(\#user-lists)]}
            $el .find '.mention .un, .message .un, .name'
                .off \click, ctx[attr] # if for some reason it is already re-assigned
                .on \click, ctx[attr]


/*####################################
#             ETA  TIMER             #
####################################*/
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
            .mouseover ->
                # show ETA calc
                avg = (sum * p / l) / 60 |> Math.round
                p = API.getWaitListPosition!
                p = API.getWaitList!.length if p == -1
                rem = API.getTimeRemaining!
                if p
                    $eta .attr \title, "#{mediaTime rem} remaining + #p × #{mediaTime avg} ø song duration"
                else if rem
                    $eta .attr \title, "#{mediaTime rem} remaining, the waitlist is empty"
                else
                    $eta .attr \title, "Nobody is playing and the waitlist is empty"
            .mouseout ->
                $eta .attr \title, null
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
        hist = API.getHistory!
        l = hist.length

        # handle the case that history length is < 50
        if l < 50 # the history seems to be sometimes up to 51 and sometimes up to 50 .-.
            #lastSongDur = 0
            do tinyhist = ->
                addListener \once, API, \advance, (d) ->
                    if d.media
                        lastSongDur := 0
                        l++
                    tinyhist! if l < 51
        else
            l = 50
            lastSongDur = hist[l - 1].media.duration
        for i from 0 til l
            sum += hist[i].media.duration

        # show the ETA timer
        updateETA!
        API.once \p0ne:stylesLoaded, ->
            $nextMediaLabel .css right: $eta.width! - 50px

        ~function updateETA
            # update what the ETA timer says
            #clearTimeout @timer
            p = API.getWaitListPosition()
            if p == 0
                $etaText .text "you are next DJ!"
                $etaTime .text ''
                return
            else if p == -1
                if API.getDJ!?.id == userID
                    $etaText .text "you are DJ!"
                    $etaTime .text ''
                    return
                else
                    if 0 == (p = API.getWaitList! .length)
                        $etaText .text 'Join now to '
                        $etaTime .text "DJ instantly"
                        return
            # calculate average duration
            avg_ = (API.getTimeRemaining!  +  sum * p / l)
            avg = avg_ / 60 |> Math.round

            #console.log "[ETA] updated to (#avg min)"
            $etaText .text "ETA ca. "
            if avg > 60min
                $etaTime .text "#{~~(avg / 60min_to_h)}h #{avg % 60}min"
            else
                $etaTime .text "#avg min"

            $nextMediaLabel .css right: $eta.width! - 50px

            # setup timer to update ETA
            clearTimeout @timer
            @timer = sleep ((avg_ % 60s)+31s).s, updateETA
    disable: ->
        clearTimeout @timer


/*####################################
#              VOTELIST              #
####################################*/
module \votelist, do
    settings: \base
    displayName: 'Votelist'
    disabled: true
    help: '''
        Moving your mouse above the woot/grab/meh icon shows a list of users who have wooted, grabbed or meh'd respectively.
    '''
    setup: ({addListener, $create}) ->
        $tooltip = $ \#tooltip
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
            $tooltip .show!

        addListener API, \voteUpdate, updateVoteList

        function changeFilter styles, filter
            return ->
                currentFilter := filter
                css \votelist, ".p0ne-votelist { #{styles} }"
                updateVoteList!

        function updateVoteList
            if currentFilter
                # empty string as argument for code optimization
                userlist = currentFilter('')
                if userlist
                    $vl
                        .html userlist
                        .show!
                    if not $tooltip.length
                        $tooltip := $ \#tooltip
                    $tooltip .hide!
                else
                    $vl.hide!
                    $tooltip .show!


/*####################################
#             USER POPUP             #
####################################*/
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



/*####################################
#         AVOID HISTORY PLAY         #
####################################*/
module \avoidHistoryPlay, do
    settings: \base
    displayName: '☢ Avoid History Plays'
    help: '''
        [WORK IN PROGRESS]

        This avoid playing songs that are already in history
    '''
    require: <[ app ]>
    setup: ({addListener}) ->
        #TODO make sure that `playlist` is actually the active playlist, not just the one the user is looking at
        # i.e. use another object which holds the next songs of the current playlist
        playlist = app.footer.playlist.playlist.media
        addListener API, \advance, (d) ->
            if d.dj?.id != userID
                if playlist.list?.rows?.0?.model.cid == d.media.cid  and  getActivePlaylist?
                    chatWarn 'moved down', '☢ Avoid History Plays'
                    ajax \PUT, "playlists/#{getActivePlaylist!.id}/media/move", do
                        beforeID: -1
                        ids: [id]
            else
                API.once \advance, checkOnNextAdv

        function checkOnNextAdv d
            # assuming that the playlist did not already advance
            console.info "[Avoid History Plays]", playlist.list?.rows?.0?.model, playlist.list?.rows?.1?.model
            return if not (nextSong = playlist.list?.rows?.1?.nextSong) or not getActivePlaylist?
            for s in API.getHistory!
                if s.media.cid == nextSong.cid
                    chatWarn 'moved down', '☢ Avoid History Plays'
                    ajax \PUT, "playlists/#{getActivePlaylist!.id}/media/move", do
                        beforeID: -1
                        ids: [nextSong.id]
        do @checkOnNextAdv = checkOnNextAdv