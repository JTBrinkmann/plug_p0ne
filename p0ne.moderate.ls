/**
 * plug_p0ne modules to help moderators do their job
 * @author jtbrinkmann aka. Brinkie Pie
 * @version 1.0
 * @license MIT License
 * @copyright (c) 2014 J.-T. Brinkmann
 */

module \enableModeratorModules, do
    require: <[ user_ ]>
    setup: ({addListener}) ->
        prevRole = user_.attributes.role
        addListener user_, \change:role, (user, newRole) ->
            if newRole > 1 and prevRole < 2
                for m in p0ne.modules when m.modDisabled
                    m.enable!
                    m.modDisabled = false
            else
                for m in p0ne.modules when m.moderator and not m.modDisabled
                    m.modDisabled = true
                    m.disable!

module \warnOnHistory, do
    moderator: true
    setup: ({addListener}) ->
        addListener API, \advance, (d) ~>
            return if not d.media
            hist = API.getHistory!
            inHistory = 0; skipped = 0; lastTime = 0
            for m, i in hist when m.id == d.id and d.historyID != m.historyID
                inHistory++
                m.i = i
                lastPlay ||= m
                skipped++ if m.skipped
            if inHistory
                msg = "Song is in history"
                if inHistory > 1
                    msg += " (#inHistory times) one:"
                msg += " #{ago PARSESOMEHOW lastPlay.datetime} (#{i+1}/#{hist.length})"
                if skipped == inHistory
                    msg = " but was skipped last time"
                if skipped > 1
                    msg = " it was skipped #skipped/#inHistory times"
                API.chatLog msg, true
                API.trigger \p0ne_songInHistory # should this be p0ne:songInHistory?



/*####################################
#      DISABLE MESSAGE DELETE        #
####################################*/
module \disableChatDelete, do
    require: <[ _$context user_ ]>
    optional: <[ socketListeners ]>
    settings: \chat
    displayName: 'Show deleted messages'
    moderator: true
    setup: ({replace_$Listener, addListener, $createPersistent, css}) ->
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

        $body .addClass \p0ne_showDeletedMessages


        addListener _$context, \socket:chatDelete, ({{c,mi}:p}) ->
            markAsDeleted(c, users.get(mi)?.get(\username) || mi)
        #addListener \early, _$context, \chat:delete, -> return (cid) ->
        replace_$Listener \chat:delete, -> (cid) ->
            markAsDeleted(cid) if not socketListeners

        function markAsDeleted cid, moderator
            $msg = getChat cid
            #ToDo add scroll down
            console.log "[Chat Delete]", cid, $msg.text!
            t  = getISOTime!
            t += " by #moderator" if moderator
            try
                $msg
                    .removeClass \deletable
                    .addClass \deleted
                d = $createPersistent \<time>
                    .addClass \deleted-message
                    .attr \datetime, t
                    .text t
                    .appendTo $msg
                cm = $cm!
                cm.scrollTop cm.scrollTop! + d.height!

    disable: ->
        $body .removeClass \p0ne_showDeletedMessages



/*####################################
#           MESSAGE CLASSES          #
####################################*/
module \chatDeleteOwnMessages, do
    moderator: true
    setup: ({addListener}) ->
        $cm! .find "fromID-#{userID}"
            .addClass \deletable
            .append '<div class="delete-button">Delete</div>'
        addListener API, \chat, ({cid, uid}:message) -> if uid == userID
            getChat(cid)
                .addClass \deletable
                .append '<div class="delete-button">Delete</div>'


/*####################################
#            WARN ON MEHER           #
####################################*/
module \warnOnMehers, do
    users: {}
    moderator: true
    _settings:
        instantWarn: false
        maxMehs: 3
    setup: ({addListener},,, m_) ->
        if m_
            @users = m_.users
        users = @users

        current = {}
        addListener API, \voteUpdate, (d) ~>
            current[d.user.id] = d.vote
            if @_settings.instantWarn and d.vote == -1
                API.chatLog "#{d.user.username} (lvl #{d.user.level}) meh'd this song", true

        lastAdvance = 0
        addListener API, \advance, (d) ~>
            d = Date.now!
            for k,v of current
                if v == -1
                    users[k] ||= 0
                    if ++users[k] > @_settings.maxMehs
                        API.chatLog "#{d.dj.username} (lvl #{d.dj.level}) meh'd the past #{users[k]} songs!", true
                else if d > lastAdvance + 10_000ms and d.lastPlay?.dj.id != k
                    delete users[k]
            current := {}
            lastAdvance := d


module \afkTimer, do
    require: <[ RoomUserRow WaitlistRow ]>
    optional: <[ socketListeners app userList _$context ]>
    moderator: true
    lastActivity: {}
    _settings:
        highlightOver: 45.min
    setup: ({addListener},,,m_) ->
        # initialize users
        settings = @_settings
        @start = start = m_?.start || Date.now!
        if m_
            @lastActivity = m_.lastActivity
        else
            for user in API.getUsers!
                @lastActivity[user.id] = start
        lastActivity = @lastActivity

        # set up event listeners to update the lastActivity time
        addListener API, 'socket:skip socket:grab', (id) -> updateUser id
        addListener API, 'userJoin socket:nameChanged', (u) -> updateUser u.id
        addListener API, 'chat', (u) -> updateUser u.uid
        addListener API, 'socket:gifted', (e) -> updateUser e.s
        addListener API, 'socket:modAddDJ socket:modBan socket:modMoveDJ socket:modRemoveDJ socket:modSkip socket:modStaff', (u) -> updateUser u.mid
        addListener API, 'userLeave', (u) -> delete lastActivity[u.id]

        var timer
        if _$context? and (app? or userList?)
            addListener _$context, 'show:users show:waitlist', ->
                timer := repeat 60_000ms, forceRerender
            addListener _$context, \show:chat, ->
                clearInterval timer

        # UI
        d = 0
        var noActivityYet
        for Constr, fn in [RoomUserRow, WaitlistRow]
            replace Constr::, \render, (r_) -> return (isUpdate) ->
                r_ ...
                if not d
                    d := Date.now!
                    requestAnimationFrame -> d := 0; noActivityYet := null
                ago = d - lastActivity[@model.id]
                if lastActivity[@model.id] == start
                    time = noActivityYet ||= ">#{humanTime(ago, true)}"
                else if ago < 60_000ms
                    time = "<1m"
                else if ago < 120_000ms
                    time = "<2m"
                else
                    time = humanTime(ago, true)
                $span = $ '<span class=p0ne-last-activity>' .text time
                $span .addClass \p0ne-last-activity-warn if ago > settings.highlightOver
                $span .addClass \p0ne-last-activity-update if isUpdate
                @$el .append $span
                if isUpdate
                    requestAnimationFrame -> $span .removeClass \p0ne-last-activity-update



        function updateUser uid
            lastActivity[uid] = Date.now!
            # waitlist.rows defaults to [], so no need to ||[]
            for r in userList?.listView?.rows || app?.room.waitlist.rows when r.model.id == uid
                console.log "updated #{r.model.username}'s row", r
                r.render true

        # update current rows (it should not be possible, that the waitlist and userlist are populated at the same time)
        function forceRerender
            for r in app?.room.waitlist.rows || userList?.listView?.rows ||[]
                console.log "rerendering #{r.model.username}'s row", r
                r.render!

        forceRerender!