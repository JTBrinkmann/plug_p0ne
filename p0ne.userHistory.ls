
requireHelper \userRollover, (.id == \user-rollover)
requireHelper \RoomHistory, ((it) -> it::?listClass == \history and it::hasOwnProperty \listClass) #((it) -> it.onPointsChange && it._events?.reset)
#HistoryItem = RoomHistory::collection.model if RoomHistory

ObjWrap = (obj) ->
    obj.get = (name) -> return this[name]
    return obj

module \userHistory, do
    require: <[ userRollover RoomHistory ]>
    help: '''
        Shows another user's song history when clicking on their username in the user-rollover.

        Due to technical restrictions, only Youtube songs can be shown.
    '''
    setup: ({addListener, replace, css}) ->
        css \userHistory, '#user-rollover .username { cursor: pointer }'
        addListener $(\body), \click, '#user-rollover .username', ->
            $ '#history-button.selected' .click! # hide history if already open
            user = userRollover.user
            userID = user.id
            username = user.get \username
            userlevel = user.get \level
            userslug = user.get \slug
            if userlevel < 5
                userRollover.$level .text "#{userlevel} (user-history requires >4!)"
                return
            console.log "#{getTime!} [userHistory] loading #username's history"
            if not userslug
                getUserData userID .then (d) ->
                    user.set \slug, d.slug
                    loadUserHistory user
            else
                loadUserHistory user

        function loadUserHistory user
            $.get "https://plug.dj/@/#{user.get \slug}"
                .fail ->
                    console.error "! couldn't load user's history"
                .then (d) ->
                    userRollover.cleanup!
                    songs = new backbone.Collection()
                    d.replace /<div class="row">\s*<img src="(.*)"\/>\s*<div class="meta">\s*<span class="author">(.*?)<\/span>\s*<span class="name">(.*?)<\/span>[\s\S]*?positive"><\/i><span>(\d+)<\/span>[\s\S]*?grabs"><\/i><span>(\d+)<\/span>[\s\S]*?negative"><\/i><span>(\d+)<\/span>[\s\S]*?listeners"><\/i><span>(\d+)<\/span>/g, (,img, author, roomName, positive, grabs, negative, listeners) ->
                        if cid = /\/vi\/(.{11})\//.exec(img)
                            cid = cid.1
                            [title, author] = author.split " - "
                            songs.add new ObjWrap do
                                user: {id: user.id, username: "in #roomName"}
                                room: {name: roomName}
                                score:
                                    positive: positive
                                    grabs: grabs
                                    negative: negative
                                    listeners: listeners
                                    skipped: 0
                                media: new ObjWrap do
                                    format: 1
                                    cid: cid
                                    author: author
                                    title: title
                                    image: httpsify(img)
                    console.info "#{getTime!} [userHistory] loaded history for #{user.get \username}", songs
                    export songs, d
                    replace RoomHistory::, \collection, -> return songs
                    _$context.trigger \show:history
                    _.defer ->
                        RoomHistory::.collection = RoomHistory::.collection_
                        console.log "#{getTime!} [userHistory] restoring room's proper history"