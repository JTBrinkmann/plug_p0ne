/**
 * small module to show a user's song history on plug.dj
 * fetches the song history from the user's /@/profile page
 *
 * @author jtbrinkmann aka. Brinkie Pie
 * @license MIT License
 * @copyright (c) 2015 J.-T. Brinkmann
*/
console.log "~~~~~~~ p0ne.userHistory ~~~~~~~"
#HistoryItem = RoomHistory::collection.model if RoomHistory


/*####################################
#            USER HISTORY            #
####################################*/
module \userHistory, do
    require: <[ userRollover RoomHistory backbone chat ]>
    help: '''
        Shows another user's song history when clicking on their username in the user-rollover.

        Due to technical restrictions, only Youtube songs can be shown.
    '''
    setup: ({addListener, replace, css, $create}) !->
        css \userHistory, '#user-rollover .username { cursor: pointer }'

        #== UI ==
        userRollover.$histBtn = $create "<i class='icon icon-history-white p0ne-user-history-btn'></i>"
        replace userRollover, \showModal, (sM_) !-> return !->
          @$histBtn.appendTo @$meta
          sM_ .call(this)

        addListener $body, \click, '.p0ne-user-history-btn', !->
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
                getUserData userID .then (d) !->
                    user.set \slug, d.slug
                    loadUserHistory user
            else
                loadUserHistory user

        /*
        P0neHistHeader = _.extend(SearchHeader, {
          template: SearchHeader.prototype.template.replace("icon-search", "icon-search icon-history-white")
        })
         */

        #== Handler ==
        function loadUserHistory user
            $.get "https://plug.dj/@/#{user.get \slug}"
                .fail !->
                    console.error "! couldn't load user's history"
                .then (d) !->
                    userRollover.cleanup!
                    songs = new backbone.Collection()
                    d.replace /<div class="row">\s*<img src="(.*)"\/>\s*<div class="meta">\s*<span class="author">(.*?)<\/span>\s*<a.+?><span class="name">(.*?)<\/span><\/a>[\s\S]*?positive"><\/i><span>(\d+)<\/span>[\s\S]*?grabs"><\/i><span>(\d+)<\/span>[\s\S]*?negative"><\/i><span>(\d+)<\/span>[\s\S]*?listeners"><\/i><span>(\d+)<\/span>/g, (,img, author, roomName, positive, grabs, negative, listeners) !->
                        if cid = /\/vi\/(.{11})\//.exec(img)
                            cid = cid.1
                            [title, author] = author.split " - "
                            songs.add do /*new backbone.Model do
                                user: {id: user.id, username: "in #roomName"}
                                room: {name: roomName}
                                score:
                                    positive: positive
                                    grabs: grabs
                                    negative: negative
                                    listeners: listeners
                                    skipped: 0
                                media: new backbone.Model do*/
                                    format: 1
                                    cid: cid
                                    author: author
                                    title: title
                                    image: httpsify(img)
                    console.info "#{getTime!} [userHistory] loaded history for #{user.get \username}", songs

                    #= show song list in playlist drawer =
                    # open playlist drawer
                    $ '#playlist-button .icon-playlist'
                        .click! # will silently fail if playlist is already open, which is desired

                    mediaListShow "#{user.get \username}'s history", songs