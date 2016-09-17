/**
 * Base plug_p0ne modules
 *
 * @author jtbrinkmann aka. Brinkie Pie
 * @license MIT License
 * @copyright (c) 2015 J.-T. Brinkmann
 */
console.log "~~~~~~~ p0ne.base ~~~~~~~"


/*####################################
#           DISABLE/STATUS           #
####################################*/
module \disableCommand, do
    setup: ({addListener}) !->
        addListener API, \chat, (msg) !~>
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
                else if disabledModules.length
                    response += " #{humanList disabledModules} #{if disabledModules.length == 1 then 'was' else 'were'} weren't enabled."
                API.sendChat response

module \getStatus, do
    module: !->
        status = "Running plug_p0ne v#{p0ne.version}"
        status += "\tand plug³ v#{that}" if getPlugCubedVersion!
        status += "\tand plugplug #{window.getVersionShort!}" if window.ppSaved
        status += ".\tStarted #{ago p0ne.started}"
        modules = [m for ,m of p0ne.modules when m.disableCommand and not m.disabled]
        status += ".\t#{humanList modules} enabled" if modules.length

module \statusCommand, do
    timeout: false
    setup: ({addListener}) !->
        addListener API, \chat, (data) !~> if not @timeout
            if data.message.has( \!status ) and isMention(data) and API.hasPermission(data.uid, API.ROLE.BOUNCER)
                @timeout = true
                status = "#{getStatus!}"
                console.info "[AR] status: '#status'", data.uid, data.un
                API.sendChat status, data
                sleep 30min *60_000to_ms, !->
                    @timeout = false
                    console.info "[status] timeout reset"




/*####################################
#             AUTOJOIN               #
####################################*/
module \autojoin, do
    displayName: "Autojoin"
    help: '''
        Automatically join the waitlist again after you DJ'd or if the waitlist gets unlocked.
        It will disable itself, if you got removed from the waitlist by a moderator.
    '''
    settings: \base
    settingsVip: true
    settingsSimple: true
    disabled: true
    disableCommand: true
    optional: <[ _$context booth socketListeners ]>
    setup: ({addListener}) !->
        # initial autojoin
        join! if API.getDJ!?.id != userID and API.getWaitListPosition! == -1

        # autojoin on DJ advances, Waitlist changes and reconnects
        addListener API, 'advance waitListUpdate ws:reconnected sjs:reconnected p0ne:reconnected', (d) !->
            if API.getDJ!?.id != userID and API.getWaitListPosition! == -1
                if join!
                    console.log "#{getTime!} [autojoin] joined waitlist"
                else
                    console.error "#{getTime!} [autojoin] failed to join waitlist"
                    API.once \advance, @autojoin, this

        # when DJ Wait List gets unlocked
        wasLocked = $djButton.hasClass \is-locked
        addListener _$context, \djButton:update, !~>
            isLocked = $djButton.hasClass \is-locked
            join! if wasLocked and not isLocked
            wasLocked := isLocked

        # disable when user gets removed by a moderator
        addListener API, \socket:modRemoveDJ, (e) !~> if e.t == API.getUser!.rawun
            @disable!


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
    settingsSimple: true
    disabled: true
    disableCommand: true
    optional: <[ chatDomEvents ]>
    _settings:
        warnOnMehs: true
    setup: ({addListener}) !->
        var timer, timer2
        lastScore = API.getHistory!.1.score
        hasMehWarning = false

        # on each song
        addListener API, \advance, (d) !->
            if d.media
                lastScore = d.lastPlay.score
                clearTimeout timer
                # wait between 1 to 4 seconds (to avoid flooding plug.dj servers)
                timer := sleep 1.s  +  3.s * Math.random!, !->
                    if not API.getUser!.vote # only woot if user didn't vote already
                        console.log "#{getTime!} [autowoot] autowooting"
                        woot!
            if hasMehWarning
                clearTimeout(timer2)
                get$cms! .find \.p0ne-autowoot-meh-btn .closest \.cm .remove!
                hasMehWarning := false

        # warn if user is blocking a voteskip
        addListener API, \voteUpdate, (d) !~>
            score = API.getScore!
            # some number magic
            if @_settings.warnOnMehs and (score.negative > 2 * score.positive and score.negative > (lastScore.positive + lastScore.negative) / 4 and score.negative >= 5) and not hasMehWarning and API.getTimeRemaining! > 30s
                timer2 := sleep 5_000ms, !->
                    chatWarn "Many users meh'd this song, you may be preventing a voteskip. <span class=p0ne-autowoot-meh-btn>Click here to meh</span> if you dislike the song", "Autowoot", true
                    playChatSound!
                hasMehWarning := true

        # make the meh button meh
        addListener chatDomEvents, \click, \.p0ne-autowoot-meh-btn, !->
            meh!
            $ this .closest \.cm .remove!


/*####################################
#              AUTOMUTE              #
####################################*/
module \automute, do
    displayName: "Automute"
    settings: \base
    settingsSimple: true
    optional: <[ streamSettings ]>
    help: '''
        automatically set songs from the "mute list" to silent, so you don't have to hear them when they get played. Useful for tracks that you don't like but that often get played.
    '''
    _settings:
        songlist: {}

    setup: ({addListener}, automute) !->
        @songlist = @_settings.songlist
        media = API.getMedia!
        addListener API, \advance, (d) !~>
            if (media := d.media) and @songlist[media.cid]
                console.info "[automute] '#{media.author} - #{media.title}' is in automute list. Automuting…"
                chatWarn "This song is automuted", \automute
                #muteonce!
                snooze!

        #== Turn SNOOZE button into add/remove AUTOMUTE button when media is snoozed ==
        $snoozeBtn = $ '#playback .snooze'
        @$box_ = $snoozeBtn .children!
        $box = $ "<div class='box'></div>"
        streamOff = isSnoozed!
        addListener API, \p0ne:changeMode, onModeChange = (mode) !~>
            newStreamOff = (mode == \off)
            <~! requestAnimationFrame
            if newStreamOff
                if media
                    $snoozeBtn
                        .empty!
                        .removeClass 'p0ne-automute-add p0ne-automute-remove'
                        .append $box
                    if @songlist[media.cid] # btn "remove from automute"
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
                    .removeClass 'p0ne-automute p0ne-automute-add p0ne-automute-remove'
                    .append @$box_
            streamOff := newStreamOff

        @updateBtn = (mode) !->
            onModeChange(streamOff && \off)

        addListener $snoozeBtn, \click, (e) !~>
            if streamOff
                console.info "[automute] snoozy", media.cid, @songlist[media.cid], streamOff
                automute!

    module: (media, isAdd) !->
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
                throw new TypeError "invalid arguments for automute(media, isAdd*)"
        else
            # default `media` to current media
            media = API.getMedia!

        if isAdd == \toggle or not isAdd? # default to toggle
            isAdd = not @songlist[media.cid]

        if isAdd # add to automute list
            @songlist[media.cid] = media
            @createRow media.cid
            chatWarnSmall 'p0ne-automute-notif p0ne-automute-added', "automute #{media.author} - #{media.title}'", \icon-volume-off
        else # remove from automute list
            delete @songlist[media.cid]
            chatWarnSmall 'p0ne-automute-notif p0ne-automute-removed', "un-automute #{media.author} - #{media.title}'", \icon-volume-half
            if $row = @$rows[media.cid]
                $row .css transform: 'scale(0)', height: 0px
                sleep 500ms, !->
                    $row .remove!
        if media.cid == API.getMedia!?.cid
            @updateBtn!

    $rows: {}
    settingsPanel: (@$el, automute) !->
        for cid of @songlist
            @createRow cid
        $el
            .on \mouseover, '.song-format-2 .load-sc', !->
                mediaLookup {format: 2, cid: $(this).closest(\row).data(\cid)} .then (d) !~>
                    $(this)
                        .attr \href, d.url
                        .removeClass \load-sc
            .on \click, \.song-remove, !->
                $row = $(this).closest \.row
                automute automute.songlist[$(this).closest(\.row).data(\cid)], false /*remove*/
            .parent! .css height: \100%
    createRow: (cid) !-> if @$el
        song = @songlist[cid]
        if song.format == 1  # YouTube
            mediaURL = "http://youtube.com/watch?v=#{song.cid}"
            loadSC = ""
        else # if media.format == 2 # SoundCloud
            mediaURL = "https://soundcloud.com/search?q=#{encodeURIComponent song.author+' - '+song.title}"
            loadSC = " load-sc"
        @$rows[cid] = $ "
            <div class='row song-format-#{song.format}' data-cid='#cid'>
                <div class=song-thumb-wrapper>
                    <img class=song-thumb src='#{song.image}'>
                    <span class=song-duration>#{mediaTime song.duration}</span>
                </div>
                <div class=meta>
                    <div class=author title='#{song.author}'>#{song.author}</div>
                    <div class=title title='#{song.title}'>#{song.title}</div>
                </div>
                <div class='song-remove btn'><i class='icon icon-clear-input'></i></div>
                <a class='song-open btn #loadSC' href='#mediaURL' target='_blank'><i class='icon icon-chat-popout'></i></a>
            </div>
        "
            .appendTo @$el

    disable: !->
        $ '#playback .snooze'
            .empty!
            .append @$box_


/*####################################
#          AFK AUTORESPOND           #
####################################*/
module \afkAutorespond, do
    displayName: 'AFK Autorespond'
    settings: \base
    settingsSimple: true
    settingsVip: true
    _settings:
        message: "I'm AFK at the moment"
        timeout: 1.min
    disabled: true
    disableCommand: true

    DEFAULT_MSG: "I'm AFK at the moment"
    setup: ({addListener, $create}) !->
        timeout = true
        sleep @_settings.timeout, !-> timeout := false
        addListener API, \chat, (msg) !~>
            if msg.uid and msg.uid != userID and not timeout and isMention(msg, true) and not msg.message.has \!disable
                # it is neglected that a non-staff might send a @mentioning message with "!disable"
                API.sendChat "#{@_settings.emote || ''}[AFK] #{@_settings.message || @DEFAULT_MSG}"
                timeout := true
                sleep @_settings.timeout, !-> timeout := false
            else if msg.uid == userID
                timeout := true
                sleep @_settings.timeout, !-> timeout := false
        $create '<div class=p0ne-afk-button>'
            .text "Disable #{@displayName}"
            .click !~> @disable! # we cannot just `.click(@disable)` because `disable` should be called without any arguments
            .appendTo \#footer-user

    settingsExtra: ($el) !->
        afkAutorespond = this
        $input = $ "<input class=p0ne-settings-input placeholder=\"#{@DEFAULT_MSG}\">"
            .val @_settings.message
            .on \input, !->
                val = @value
                if val.startsWith "/me " or val.startsWith "/em "
                    afkAutorespond._settings.emote = val.substr(0,4)
                    val .= substr 4
                else
                    delete afkAutorespond._settings.emote
                afkAutorespond._settings.message = val
            .appendTo $el


/*####################################
#      JOIN/LEAVE NOTIFICATION       #
####################################*/
module \joinLeaveNotif, do
    optional: <[ chatDomEvents chat auxiliaries database ]>
    settings: \base
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
    setup: ({addListener, css}, joinLeaveNotif, update) !->
        if update
            lastMsg = get$cm! .children! .last!
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
            addListener API, event_, (u) !->
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
                        #{formatUserHTML u, true, {+lvl, +flag, +warning}}
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
 
        addListener API, 'popout:open popout:close', !->
            $lastNotif = get$cm! .find \.p0ne-notif-joinleave:last





/*####################################
#     CURRENT SONG TITLE TOOLTIP     #
####################################*/
# add a tooltip (alt attr.) to the song title (in the header above the playback container)
module \titleCurrentSong, do
    disable: !->
        $ \#now-playing-media .prop \title, ""
    setup: ({addListener}) !->
        addListener API, \advance, (d) !->
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
    setup: ({replace})  !->
        settings = @_settings
        replace RoomUserRow::, \vote, !-> return !->
            if @model.id == API.getDJ!?.id
                /* fixed in Febuary 2015 http://tech.plug.dj/2015/02/18/version-1-2-7-6478/
                if vote # stupid haxxy edge-cases… well to be fair, I don't see many other people but me abuse that >3>
                    if not @$djIcon
                        @$djIcon = $ '<i class="icon icon-current-dj" style="right: 35px">'
                            .appendTo @$el
                        API.once \advance, !~>
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

    updateEvents: !->
        for u in users.models when u._events
            for event in u._events[\change:vote] ||[] when event.ctx instanceof RoomUserRow
                event.callback = RoomUserRow::vote
            for event in u._events[\change:grab] ||[] when event.ctx instanceof RoomUserRow
                event.callback = RoomUserRow::vote

    disableLate: !->
        @updateEvents!


/*####################################
#        DBLCLICK to @MENTION        #
####################################*/
/*note: this also makes usernames clickable in many other parts of plug.dj & other plug_p0ne modules */
module \chatDblclick2Mention, do
    require: <[ chat simpleFixes ]>
    #optional: <[ PopoutListener ]>
    settings: \chat
    displayName: 'DblClick username to Mention'
    setup: ({replace, addListener}, chatDblclick2Mention) !->
        $appRight = $ \.app-right
        newFromClick = (e) !->
            # after a click, wait 0.2s
            # if the user clicks again, consider it a double click
            # otherwise fall back to default behaviour (show user rollover)
            e .stopPropagation!; e .preventDefault!

            # single click
            if not chatDblclick2Mention.timer
                chatDblclick2Mention.timer = sleep 200ms, !~> if chatDblclick2Mention.timer
                    try
                        chatDblclick2Mention.timer = 0
                        $this = $ this
                        if text = $this.find(\.name)
                            text = text.text!
                        else
                            text = $this.text!
                        if r = ($this .closest \.cm .children \.badge-box .data \uid) || ($this .data \uid) || (i = getUserInternal text)?.id
                            pos =
                                x: $appRight.offset!.left
                                y: $this .offset!.top >? 0
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
                name = this.textContent
                if name.0 == "@"
                    name .= substr 1
                (PopoutView?.chat || chat).onInputMention name

        $cms = get$cms!
        for [ctx, $el, attr, boundAttr] in [ [chat, $cms.find(\.un), \onFromClick, \fromClickBind],  [WaitlistRow::, $('#waitlist .user'), \onDJClick, \clickBind],  [RoomUserRow::, $('#user-lists .user'), \onClick, \clickBind] ]
            # remove individual event listeners (we use a delegated event listener below)
            # setting them to `$.noop` will prevent .bind to break
            #replace ctx, attr, !-> return $.noop
            # setting them to `null` will make `.on("click", …)` in the vanilla code do nothing (this requires the underscore.bind fix)
            replace ctx, attr, noop
            if ctx[boundAttr]
                replace ctx, boundAttr, noop

            # update DOM event listeners
            $el .off \click, ctx[boundAttr]

        replace WaitlistRow::, \draw, (d_) !-> return !->
            d_.call(this)
            @$el.data \uid, @model.id
        replace RoomUserRow::, \draw, (d_) !-> return !->
            d_.call(this)
            @$el.data \uid, @model.id

        # instead of individual event listeners, we use a delegated event (which offers better performance)
        addListener chatDomEvents, \click, \.un, newFromClick
        addListener $body, \click, '.p0ne-name, #user-lists .user, #waitlist .user, .friends .row', newFromClick
        #                                                       , #history-panel .name

        function noop
            return null

    disableLate: (,newModule) !->
        # note: here we actually have to pay attention as to what to re-enable
        for attr, [ctx, $el] of {fromClickBind: [chat, get$cms!], onDJClick: [WaitlistRow::, $(\#waitlist)], onClick: [RoomUserRow::, $(\#user-lists)]}
            $el .find '.mention .un, .message .un, .name'
                .off \click, ctx[attr] # if for some reason it is already re-assigned
                .on \click, ctx[attr]

        legacyChat = p0ne.modules.legacyChat
        if not newModule and legacyChat and legacyChat.disabled
            chatWarn "while #{legacyChat.displayName} is enabled, clicking usernames might not work without #{@displayName}", "plug_p0ne warning"


/*####################################
#             ETA  TIMER             #
####################################*/
module \etaTimer, do
    displayName: 'ETA Timer'
    settings: \base
    optional: <[ _$context ]>
    setup: ({css, addListener, $create}) !->
        css \etaTimer, '
            .p0ne-eta {
                position: absolute;
            }
            #your-next-media>span {
                width: auto !important;
                right: 50px;
            }
        '
        # we put ".p0ne-eta { position: absolute; }" in here instead of plug_p0ne.css so $eta's width is calculated correctly even while the stylesheets are loading
        sum = lastSongDur = tooltipIntervalID = 0
        showingTooltip = false
        $nextMediaLabel = $ '#your-next-media > span'
        $eta = $create '<div class=p0ne-eta>'
            .append $etaText = $ '<span class=p0ne-eta-text>ETA: </span>'
            .append $etaTime = $ '<span class=p0ne-eta-time></span>'
            .mouseover !->
                if _$context?
                    updateToolTip!
                    clearInterval tooltipIntervalID
                    tooltipIntervalID := repeat 1_000ms, updateToolTip

                function updateToolTip
                    # show ETA calc
                    p = API.getWaitListPosition!
                    p = API.getWaitList!.length if p == -1
                    avg = sum / l |> Math.round
                    rem = API.getTimeRemaining!
                    if p
                        _$context.trigger \tooltip:show, "#{mediaTime rem} remaining + #p × #{mediaTime avg} avg. song duration", $etaText
                    else if rem
                        _$context.trigger \tooltip:show, "#{mediaTime rem} remaining, the waitlist is empty", $etaText
                    else
                        _$context.trigger \tooltip:show, "Nobody is playing and the waitlist is empty", $etaText
            .mouseout !->
                if _$context?
                    clearInterval tooltipIntervalID
                    _$context.trigger \tooltip:hide
            .appendTo \#playlist-meta


        # note: the ETA timer cannot be shown while the room's history is 0
        # because you need to be in the waitlist to see the ETA timer


        # attach event listeners
        addListener API, \waitListUpdate, updateETA
        addListener API, \advance, (d) !->
            # update average song duration. This is to avoid having to loop through the whole song history on each update
            if d.media
                sum -= lastSongDur
                sum += d.media.duration
                lastSongDur := API.getHistory![l - 1].media.duration

            if API.getWaitList!.length == 0
                updateETA!
                # note: we otherwise don't trigger updateETA() because usually each advance is accompanied with a waitListUpdate
        if _$context?
            addListener _$context, \room:joined, updateETA

        # initialize average song length
        # (this is AFTER the event listeners, because tinyhist() has to run after it)
        hist = API.getHistory!
        l = hist.length

        # handle the case that history length is < 50
        if l < 50 # the history seems to be sometimes up to 51 and sometimes up to 50 .-.
            #lastSongDur = 0
            do tinyhist = !->
                addListener \once, API, \advance, (d) !->
                    if d.media
                        lastSongDur := 0
                        l++
                    tinyhist! if l < 50
        else
            l = 50
            lastSongDur = hist[l - 1].media.duration
        for i from 0 til l
            sum += hist[i].media.duration

        # show the ETA timer
        updateETA!

        addListener API, \p0ne:stylesLoaded, !-> requestAnimationFrame !->
            $nextMediaLabel .css right: $eta.width! - 50px

        var lastETA
        ~function updateETA
            # update what the ETA timer says
            #clearTimeout @timer
            skipCalcETA = false
            p = API.getWaitListPosition()
            if p == 0
                $etaText .text "you are next DJ!"
                $etaTime .text ''
                skipCalcETA = true
            else if p == -1
                if API.getDJ!?.id == userID
                    $etaText .text "you are DJ!"
                    $etaTime .text ''
                    skipCalcETA = true
                else
                    if 0 == (p = API.getWaitList! .length)
                        $etaText .text 'Join now to '
                        $etaTime .text "DJ instantly"
                        skipCalcETA = true
            if skipCalcETA
                $nextMediaLabel .css right: $eta.width! - 50px
                return

            # calculate average duration
            eta_ = (API.getTimeRemaining!  +  sum * p / l)
            eta = eta_ / 60 |> Math.round

            #console.log "[ETA] updated to (#eta min)"
            if lastETA != eta
                lastETA := eta
                $etaText .text "ETA ca. "
                if eta > 60min
                    $etaTime .text "#{~~(eta / 60)}h #{eta % 60}min"
                else
                    $etaTime .text "#eta min"
                forceSkipBtnWidth = if p0ne.modules.forceSkipButton?.disabled then 50px else 0px
                $nextMediaLabel .css right: $eta.width! - forceSkipBtnWidth

                # setup timer to update ETA
                if eta_ > 0 # when disconnecting from the socket, it might be that API.getTimeRemaining! returns a negative number
                    clearTimeout @timer
                    @timer = sleep ((eta_ % 60s)+31s).s, updateETA
    disable: !->
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
        (note: seeing who has meh'd is for staff-only)
    ''' #ToDo insert reference link, explaining why seeing mehs are staff-only
    setup: ({addListener, $create}) !->
        $tooltip = $ \#tooltip
        currentFilter = false
        $vote = $(\#vote)
        $vl = $create '<div class=p0ne-votelist>'
            .hide!
            .appendTo $vote
        $rows = {}
        MAX_ROWS = 30

        addListener $(\#woot), \mouseenter, changeFilter 'left: 0', (userlist) !->
            audience = API.getAudience!
            i = 0
            for u in audience when u.vote == +1
                userlist += "<div>#{formatUserHTML u, true, {+flag}}</div>"
                if ++i == MAX_ROWS and audience.length > MAX_ROWS + 1
                    userlist += "<i title='use the userlist to see all'>and #{audience.length - MAX_ROWS} more</i>"
                    break
            return userlist

        addListener $(\#grab), \mouseenter, changeFilter 'left: 50%; transform: translateX(-50%)', (userlist) !->
            audience = API.getAudience!
            i=0
            for u in audience when u.grab
                userlist += "<div>#{formatUserHTML u, true, {+flag}}</div>"
                if ++i == MAX_ROWS and audience.length > MAX_ROWS + 1
                    userlist += "<i title='use the userlist to see all'>and #{audience.length - MAX_ROWS} more</i>"
                    break
            return userlist

        addListener $(\#meh), \mouseenter, changeFilter 'right: 0', (userlist) !-> if user.isStaff
            audience = API.getAudience!
            i = 0
            for u in audience when u.vote == -1
                userlist += "<div>#{formatUserHTML u, true, {+flag}}</div>"
                if ++i == MAX_ROWS and audience.length > MAX_ROWS + 1
                    userlist += "<i title='use the userlist to see all'>and #{audience.length - MAX_ROWS} more</i>"
                    break
            return userlist


        addListener $vote, \mouseleave, !->
            currentFilter := false
            $vl.hide!
            $tooltip .show!

        var timeout
        addListener API, \voteUpdate, !-> # throttle
            clearTimeout timeout
            timeout := sleep 200ms, updateVoteList

        function changeFilter styles, filter
            return !->
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
    setup: ({addListener}) !->
        addListener $(\.friends), \click, '.name, .image', (e) !->
            id = friendsList.rows[$ this.closest \.row .index!] ?.model.id
            user = users.get(id) if id
            data = x: $body.width! - 353px, y: e.screenY - 90px
            if user
                chat.onShowChatUser user, data
            else if id
                chat.getExternalUser id, data, (user) !->
                    chat.onShowChatUser user, data
        #replace friendsList, \drawBind, !-> return _.bind friendsList.drawRow, friendsList
# adds a user-rollover to the WaitList when clicking someone's name
module \waitlistUserPopup, do
    require: <[ WaitlistRow ]>
    setup: ({replace}) !->
        replace WaitlistRow::, "render", (r_) !-> return !->
            r_ ...
            @$ '.name, .image' .click @clickBind


/*####################################
#            BOOTH  ALERT            #
####################################*/
module \boothAlert, do
    displayName: 'Booth Alert'
    settings: \base
    settingsSimple: true
    help: '''
        Play a notification sound before you are about to play
    '''
    setup: ({addListener}, {_settings}, module_) !->
        isNext = false
        fn = addListener API, 'advance waitListUpdate ws:reconnected sjs:reconnected p0ne:reconnected', !->
            if API.getWaitListPosition! == 0
                if not isNext
                    isNext := true
                    sleep 3_000ms, !->
                        chatWarn "You are about to DJ next!", "Booth Alert"
                        playChatSound!
            else
                isNext := false
        fn! if not module_


/*####################################
#          NOTFIY ON GRABBER         #
####################################*/
module \notifyOnGrabbers, do
    require: <[ grabEvent ]>
    persistent: <[ grabs notifs ]>
    displayName: "Notify on Grabs"
    settings: \base
    grabs: {}
    notifs: {}
    setup: ({addListener, replace}) !->
        addListener API, \advance, !~>
            @grabs = {}
            @notifs = {}
        addListener API, \p0ne:vote:grab, (u) !~>
            if not @grabs[u.id]
                @notifs[u.id] = chatWarnSmall \p0ne-grab-notif, formatUserHTML(u, true), \icon-grab, true
                @grabs[u.id] = 1
            else
                if @grabs[u.id] == 1
                    @notifs[u.id] = $ '<span class=p0ne-grab-notif-count>'
                        .appendTo @notifs[u.id]
                @notifs[u.id] .text(++@grabs[u.id])


/*####################################
#         AVOID HISTORY PLAY         #
####################################*/
/*
module \avoidHistoryPlay, do
    settings: \base
    displayName: '☢ Avoid History Plays'
    help: '''
        [WORK IN PROGRESS]

        This avoid playing songs that are already in history
    '''
    require: <[ app ]>
    setup: ({addListener}) !->
        #TODO make sure that `playlist` is actually the active playlist, not just the one the user is looking at
        # i.e. use another object which holds the next songs of the current playlist
        playlist = app.footer.playlist.playlist.media
        addListener API, \advance, (d) !->
            if d.media and d.dj?.id != userID
                if playlist.list?.rows?.0?.model.cid == d.media.cid  and  getActivePlaylist?
                    chatWarn 'moved down', '☢ Avoid History Plays'
                    ajax \PUT, "playlists/#{getActivePlaylist!.id}/media/move", do
                        beforeID: -1
                        ids: [id]
            else
                API.once \advance, checkOnNextAdv

        !function checkOnNextAdv d
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
*/


/*####################################
#         WARN ON PAGE LEAVE         #
####################################*/
module \warnOnPageLeave, do
    displayName: "Warn on Leaving plug.dj"
    settings: \base
    setup: ({addListener}) !->
        addListener $window, \beforeunload, !~>
            #return "[plug_p0ne] Are you sure you want to leave the page?"
            # Chrome shows the text + "Are you sure you want to leave the page? [Leave this page] [Stay on this page]"
            # Firefox always shows "This page is asking you to confirm that you want to leave - data you have entered may not be saved. [Leave Page] [Stay on Page]"
            return "[plug_p0ne Warn on Leaving plug.dj] \n(you can disable this warning in the settings under #{@settings .toUpperCase!} > #{@displayName})"


/*####################################
#          NOTIFY ON LVL UP          #
####################################*/
module \notifyOnLevelUp, do
    displayName: "Show Friends' Level-Ups"
    settings: \base
    require: <[ socketListeners ]>
    setup: ({addListener}) !->
        addListener API, \socket:userUpdate, ({p}) !->
            if p.level and (u = getUser(p.i))?.friend
                chatWarn "<b>#{formatUserSimple u}</b> just reached level #{p.level}!", "Friend Level-Up", true


/*####################################
#        MAINTENANCE COUNTDOWN       #
####################################*/
module \maintenanceCountdown, do
    require: <[ socketListeners ]>
    setup: ({addListener}) !->
        @timer = 0
        addListener API, \socket:plugMaintenanceAlert, ({p:remainingMinutes}) !~>
            @$el = $ '#footer-user .name' .css color: \orange
            @$bck = @$el.children!
            clearInterval @timer
            @timer = repeat 60_000ms, updateRemaining
            do ~!function updateRemaining
                if remainingMinutes > 1
                    @$el .text "plug.dj going down in ca. #{remainingMinutes--} min"
                else
                    @$el .text "plug.dj going down in soonish"
                    clearInterval @timer
                    @timer = 0
                    sleep 5.min, !~> if not @timer
                            @$el
                                .html ""
                                .append @$bck
    disable: !->
        clearInterval @timer
        @$el?
            .css color: ''
            .html ""
            .append $bck


/*####################################
#         PLAYLIST HIGHLIGHT         #
####################################*/
module \grabMenuHighlight, do
    require: <[ popMenu playlistCachePatch ]>
    setup: ({replace}) !->
        replace popMenu, \show, (s_) !-> return (t,n,r) !->
            @media = n
            if @isShowing
                @draw!
            s_.call(this, t,n,r)

        replace popMenu, \drawRow, (dR_) !-> return (e) !->
            row = dR_.call(this, e)
            matches = 0
            if playlistCache._data.1.p[e.id]?.items[@media.0.get \cid] # we don't use .get() for performance reasons
                row.$el.addClass \p0ne-pl-has-media
            if playlists?.get(e.id).get(\count) == 200
                row.$el.addClass \p0ne-pl-is-full

        replace popMenu, \drawRowBind, !-> return popMenu~drawRow

module \playlistMenuHighlight, do
    require: <[ pl playlists PlaylistListRow PlaylistMediaList playlistMenu playlistCacheEvent ]>
    setup: ({addListener, replace}) !->
        replace PlaylistListRow::, \render, (r_) !-> return !->
            r_.call this
            if playlistCache._data.1.p[@model.id]
                @inCache = true
                @$el.addClass \p0ne-pl-cached

        replace PlaylistMediaList::, \onCheckThreshold, (oCT_) !-> return (n) !->
            oCT_.call this, n
            if @isDragging # when dragging starts
                for row in playlistMenu.rows
                    hasAllMedia = true
                    for cid of @selectedRows when not playlistCache._data.1.p[row.model.id].items[cid]
                        hasAllMedia = false
                        break
                    if hasAllMedia
                        row.$el.addClass \p0ne-pl-has-media
                    if row.model.get(\count) == 200
                        row.$el.addClass \p0ne-pl-is-full
        if pl?.list?
            replace pl.list, \thresholdBind, !-> return _.bind(pl.list.onCheckThreshold, pl.list)
        replace PlaylistMediaList::, \resetDrag, (rD_) !-> return !->
            if @isDragging
                for row in playlistMenu.rows
                    row.$el.removeClass 'p0ne-pl-has-media p0ne-pl-is-full'
            rD_.call this


        addListener API, \p0ne:playlistCache:update, (playlistID) !->
            for row in playlistMenu.rows when row.model.id == playlistID
                if not row.inCache
                    row.inCache = true
                    row.$el.addClass \p0ne-pl-cached
                break

        playlists.sort! # force re-rendering

    disableLate: !->
        for row in playlistMenu.rows when playlistCache._data.1.p[row.model.id]
            delete row.inCache
            row.$el.removeClass \p0ne-pl-cached


/*####################################
#          SKIP WALKTHROUGH          #
####################################*/
# skip walkthrough button
# plug_p0ne users are expected to have used plug at least once
$ '#walkthrough:not(.wt-p0) .next a' .click!