/*@author jtbrinkmann aka. Brinkie Pie */
/*@license https://creativecommons.org/licenses/by-nc-sa/4.0/ */
#ToDo add Listener to changed active playlist
if not auxiliaries
    window.auxiliaries = requireHelper do
        name: \auxiliaries
        test: (.deserializeMedia)

if auxiliaries
    window.ajax2 = (command, url,  body, cb) ->
        if typeof body == \function
            cb = body
            body = null
        cb_ = (error, body, cb) ->
            if error
                console.error "[#command]", error, body
            else
                console.log "[#command]", body
            cb? ...
        return $.ajax do
                type: \POST
                url: "//plug.dj/_/#url"
                contentType: \application/json
                data: body && JSON.stringify(body)
                success: (d) ->
                    cb_(d.body)

    toPlaylist = (pl) ->
        | pl instanceof Playlist =>
            return pl
        | typeof pl == \object =>
            | pl.id && pl.name or pl.attributes && pl.attributes.id && pl.attributes.name
                return new Playlist(pl)
        | if +pl and playlists[pl]
            return playlists[pl]
    toMedia = (m) ->
        | m instanceof Media =>
            return m
        | typeof m == \object =>
            | m.id && m.cid or m.attributes && m.attributes.id && m.attributes.cid
                return new Media(m)
        | if isID(m)
            for ,pl of playlists when (i = pl.indexOf pl) != -1
                return pl[i]
    isIndex = (i) -> return isFinite(i) and i < 200
    isID = (id) -> return isFinite(id) and id >= 1000

    ytToMedia = (cid) ->
        d = $.Deferred!
        $.ajax do
            url: "//gdata.youtube.com/feeds/api/videos/#cid?v=2&alt=json"
            success: (data) ->
                duration = +data.entry.media$group.yt$duration.seconds
                image = data.entry.media$group.media$thumbnail.0.url
                ytTitle = data.entry.media$group.media$title.$t
                ytAuthor = data.entry.media$group.media$credit.0.$t

                i = ytTitle.indexOf("-") or ytTitle.substr(1).indexOf("-") + 1 # `or` will check if the first result is 0
                if i != -1
                    title = $.trim ytTitle.substr(0, i - 1)
                    author = $.trim ytTitle.substr(i + 1)
                else
                    title = $.trim ytTitle
                    author = $.trim ytAuthor
                window.m = res = new Media({cid, author, title, image, duration, format: 1})
                d.resolveWith this, [res]
            fail: ->
                d.rejectWith ...
        return d

    playlists =
        getPlaylists: (cb) ->
            playlists = this
            d = $.Deferred!
            return ajax2( \GET, "playlists", cb )
                .then ({pls:data}) ->
                    for pl in pls
                        playlists[pl.id] = new Playlist(pl)
                    d.resolveWith playlists
                .fail (err) ->
                    d.rejectWith err


        create: (name, media, cb) ->
            if typeof media == \function
                cb = media; media = null
            data =
                name: name
                media: if media && media.length then auxiliaries.serializeMediaItems( media ) else media
            d = $.Deferred!
            ajax2( \POST, "playlists", data, cb )
                .then ({[pl]:data}) ->
                    playlists[pl.id] = new Playlist(pl)
                    d.resolveWith playlists[pl.id]
                .fail (err) ->
                    d.rejectWith err

        # search in all playlists
        search: (e, cb) ->
            data = e
            return ajax2( \GET, "playlists/media?q=#{encodeURIComponent data}", cb )

        updateActive: (playlist) ->
            @activePlaylist.active = false
            @activePlaylist = playlist
            playlist.active = true

    class Playlist extends Array
        ({@id, @name, @active=false /*, @count=0, @syncing=false, @visible=false*/}) ~>
            @load!

        loaded: false
        _media: []

        setActive: (cb) ->
            playlist = this
            return ajax2( \PUT, "playlists/#{@id}/activate", cb )
                .then ->
                    playlists.updateActive playlist


        remove: (cb) ->
            return ajax2( \DELETE, "playlists/#{@id}", cb )
                .then ->
                    #ToDo update
                    ...


        load: (cb) ->
            playlist = this
            return ajax2( \GET, "playlists/#{@id}/media", cb )
                .then ({media:data}) ->
                    for m in media
                        playlist[m.id] = new Media(m, playlist)
                    playlist.loaded = true
                    d.resolveWith playlist
                .fail (err) ->
                    d.rejectWith err


        insert: (t, append, cb) ->
            for m,i in t when m instanceof Media and @indexOf(m) == -1
                t[i] = new Media(m, this)

            data =
                media: auxiliaries.serializeMediaItems( t )
                append: append
            return ajax2( \POST, "playlists/#{@id}/media/insert", data, cb )
                .then ->
                    #ToDo update
                    ...


        shuffle: (cb) ->
            return ajax2( \PUT, "playlists/#{@id}/shuffle", cb )
                .then ->
                    #ToDo update
                    ...

        rename: (t, cb) ->
            data =
                name: t
            return ajax2( \PUT, "playlists/#{@id}/rename", data, cb )
                .then ->
                    #ToDo update
                    ...

        indexOf: (m) ->
            | m == -1 =>
                if @length
                    return @length - 1
            | isIndex(m) =>
                return m <? @length
            | isID(m) =>
                for m_, i in this when m_.id == m
                    return i
            | m instanceof Media =>
                for m_, i in this when m_.id == m.id
                    return i
            return -1
        get: (m) ->
            return this[@indexOf(m)] || null
        set: (i, m, cb) ->
            playlist = this
            i = @indexOf(i)
            m = toMedia(m)
            throw new TypeError "unsupported type for Media" if not m
            mOld = this[i]

            if playlist.indexOf(m) == -1
                playlist.insert m, afterInsert
            else
                afterInsert!
            function afterInsert
                m.move i
                playlist[i].remove ->


    class Media
        ({@id, @author, @cid, @duration, @format, @image, @title}, @playlist) ~>
        playlist: null

        remove: (t, cb) ->
            data =
                ids: t
            return ajax2( \POST, "playlists/#{@playlist.id}/media/delete", data, cb )
                .then ->
                    #ToDo update
                    ...


        move: (t, r, cb) ->
            m = this
            d = $.Deferred!
            if r == -1
                <- m.remove!
                <- m.playlist.insert m, true
                d.resolveWith m
            else if r < 200
                r = @playlist[r].id
            data =
                ids: auxiliaries.serializeMediaItems( t )
                beforeID: r
            return ajax2( \PUT, "playlists/#{@playlist.id}/media/move", data, cb )
                .then ->
                    #ToDo update
                    ...


        update: (t, n, r, cb) ->
            data =
                id: t
                author: n
                title: r
            return ajax2( \PUT, "playlists/#{@playlist.id}/media/update", data, cb )
                .then ->
                    #ToDo update
                    ...


        moveToPlaylist: (playlist, cb) ->
            media = this
            playlist = toPlaylist playlist

            return playlist .insert media
                .then ->
                    media .remove!
                    cb!

        copy: ->
            return new Media(this, null)