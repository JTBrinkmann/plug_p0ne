/**
 * get fancy song notifications in the chat (with preview thumbnail, description, buttons, …)
 *
 * @author jtbrinkmann aka. Brinkie Pie
 * @license MIT License
 * @copyright (c) 2015 J.-T. Brinkmann
 */

#ToDo add proper SoundCloud Support
#   $.ajax url: "https://api.soundcloud.com/tracks/#cid.json?client_id=#{p0ne.SOUNDCLOUD_KEY}"
#   => {permalink_url, artwork_url, description, downloadable}

module \songNotif, do
    require: <[ chatDomEvents ]>
    optional: <[ _$context chat  database auxiliaries app popMenu ]>
    settings: \base
    displayName: 'Song Notifications'
    help: '''
        Shows notifications for playing songs in the chat.
        Besides the songs' name, it also features a thumbnail and some extra buttons.

        By clicking on the song's or author's name, a search on plug.dj for that name will be started, to easily find similar tracks.

        By hovering the notification and clicking "description" the songs description will be loaded.
        You can click anywhere on it to close it again.
    '''
    setup: ({addListener, $create, $createPersistent, css},,,module_) ->
        var lastMedia
        @callback = (d) ~>
            try
                skipped = false #ToDo
                skipper = reason = "" #ToDo

                media = d.media
                if not media or media.id == lastMedia
                    return
                lastMedia := media.id
                chat?.lastType = \p0ne-song-notif

                $div = $createPersistent "<div class='update p0ne-song-notif' data-id='#{media.id}' data-cid='#{media.cid}' data-format='#{media.format}'>"
                html = ""
                time = getTime!
                if media.format == 1  # YouTube
                    mediaURL = "http://youtube.com/watch?v=#{media.cid}"
                else # if media.format == 2 # SoundCloud
                    # note: this gets replaced by a proper link as soon as data is available
                    mediaURL = "https://soundcloud.com/search?q=#{encodeURIComponent media.author+' - '+media.title}"

                duration = mediaTime media.duration
                console.logImg media.image.replace(/^\/\//, 'https://') .then ->
                    console.log "#time [DJ_ADVANCE] #{d.dj.username} is playing '#{media.author} - #{media.title}' (#duration)", d

                html += "
                    <div class='song-thumb-wrapper'>
                        <img class='song-thumb' src='#{media.image}' />
                        <span class='song-duration'>#duration</span>
                        <div class='song-add btn'><i class='icon icon-add'></i></div>
                        <a class='song-open btn' href='#mediaURL' target='_blank'><i class='icon icon-chat-popout'></i></a>
                        <!-- <div class='song-skip btn right'><i class='icon icon-skip'></i></div> -->
                        <!-- <div class='song-download btn right'><i class='icon icon-###'></i></div> -->
                    </div>
                    #{getTimestamp!}
                    <div class='song-dj un'></div>
                    <b class='song-title'></b>
                    <span class='song-author'></span>
                    <div class='song-description-btn'>Description</div>
                "
                $div.html html
                $div .find \.song-title .text d.media.title .prop \title, d.media.title
                $div .find \.song-author .text d.media.author
                $div .find \.song-dj
                    .text d.dj.username
                    .data \uid, d.dj.id

                if media.format == 2sc and p0ne.SOUNDCLOUD_KEY # SoundCloud
                    $div .addClass \loading
                    #$.ajax url: "https://api.soundcloud.com/tracks/#{media.id}.json?client_id=#{p0ne.SOUNDCLOUD_KEY}"
                    mediaLookup media, then: (d) ->
                        .then (d) ->
                            $div
                                .removeClass \loading
                                .data \description, d.description
                                .find \.song-open .attr \href, d.url
                            if d.download
                                $div
                                    .addClass \downloadable
                                    .find \.song-download
                                        .attr \href, d.download
                                        .attr \title, "#{formatMB(d.downloadSize / 1_000_000to_mb)} #{if d.downloadFormat then '(.'+that+')' else ''}"

                appendChat $div
            catch e
                console.error "[p0ne.notif]" e

        #$create \<div>
        #    .addClass \playback-thumb
        #    .insertBefore $ '#playback .background'

        addListener API, \advance, @callback
        if _$context
            addListener _$context, \room:joined, ~>
                @callback media: API.getMedia!, dj: API.getDJ!

        #== apply stylesheets ==
        loadStyle "#{p0ne.host}/css/p0ne.notif.css?r=16"


        #== show current song ==
        if not module_ and API.getMedia!
            that.image = httpsify that.image
            @callback media: that, dj: API.getDJ!

        # hide non-playable videos
        addListener _$context, \RestrictedSearchEvent:search, ->
            snooze!

        #== Grab Songs ==
        if popMenu?
            addListener chatDomEvents, \click, \.song-add, ->
                $el = $ this
                $notif = $el.closest \.p0ne-song-notif
                id = $notif.data \id
                format = $notif.data \format
                console.log "[add from notif]", $notif, id, format

                msgOffset = $notif .offset!
                $el.offset = -> # to fix position
                    return { left: msgOffset.left + 17px, top: msgOffset.top + 18px }

                obj = { id: id, format: 1yt }
                obj.get = (name) ->
                    return this[name]
                obj.media = obj

                popMenu.isShowing = false
                popMenu.show $el, [obj]
        else
            css \songNotificationsAdd, '.song-add {display:none}'

        #== fimplug ruleskip ==
        addListener chatDomEvents, \click, \.song-add, ->
            showDescription $(this).closest(\.p0ne-song-notif), """
                <span class='ruleskip'>!ruleskip 1 - nonpony</span>
                <span class='ruleskip'>!ruleskip 2 - </span>
                <span class='ruleskip'>!ruleskip 3 - </span>
                <span class='ruleskip'>!ruleskip 4 - </span>
                <span class='ruleskip'>!ruleskip  - </span>
                <span class='ruleskip'>!ruleskip  - </span>
                <span class='ruleskip'>!ruleskip  - </span>
                <span class='ruleskip'>!ruleskip  - </span>
            """

        #== search for author ==
        addListener chatDomEvents, \click, \.song-author, ->
            mediaSearch @textContent

        #== description ==
        # disable previous listeners (for debugging)
        #$ \#chat-messages .off \click, \.song-description-btn
        #$ \#chat-messages .off \click, \.song-description
        $description = $()
        addListener chatDomEvents, \click, \.song-description-btn, (e) ->
            try
                if $description
                    hideDescription! # close already open description

                #== Show Description ==
                $description := $ this
                $notif = $description .closest \.p0ne-song-notif
                cid    = $notif .data \cid
                format = $notif .data \format
                console.log "[song-notif] showing description", cid, $notif

                if $description .data \description
                    showDescription $notif, that
                else
                    # load description from Youtube
                    console.log "looking up", {cid, format}, do
                        mediaLookup {cid, format}, do
                            success: (data) ->
                                text = formatPlainText data.description # let's get fancy
                                $description .data \description, text
                                showDescription $notif, text
                            fail: ->
                                $description
                                    .text "Failed to load"
                                    .addClass \.song-description-failed

                        .timeout 200ms, ->
                            $description
                                .text "Description loading…"
                                .addClass \loading
            catch e
                console.error "[song-notif]", e


        addListener chatDomEvents, \click, \.song-description, (e) ->
            if not e.target.href
                hideDescription!

        function showDescription $notif, text
                # create description element
                $description.removeClass 'song-description-btn loading'
                    .css opacity: 0, position: \absolute
                    .addClass \song-description
                    .html "#text <i class='icon icon-clear-input'></i>"
                    .appendTo $notif

                # show description (animated)
                h = $description.height!
                $description
                    .css height: 0px, position: \static
                    .animate do
                        opacity: 1
                        height: h
                        -> $description .css height: \auto

                # smooth scroll
                cm = $cm!
                offsetTop = $notif.offset!?.top - 100px
                ch = cm .height!
                if offsetTop + h > ch
                    cm.animate do
                        scrollTop: cm .scrollTop! + Math.min(offsetTop + h - ch + 100px, offsetTop)
                        # 100px is height of .song-notif without .song-description

        function hideDescription
            #== Hide Description ==
            return if not $description
            console.log "[song-notif] closing description", $description
            $notif = $description .closest \.p0ne-song-notif
            $description.animate do
                opacity: 0
                height: 0px
                ->
                    $ this
                        .css opacity: '', height: \auto
                        .removeClass 'song-description text'
                        .addClass 'song-description-btn'
                        .text "Description"
                        .appendTo do
                            $notif .find \.song-notif-next
            $description := null

            # smooth scroll
            offsetTop = $notif.offset!?.top - 100px # 100 is # $(\.app-header).height! + $(\#chat-header).height
            if offsetTop < 0px
                cm = $cm!
                cm.animate do
                    scrollTop: cm .scrollTop! + offsetTop - 100px # -100px is so it doesn't stick to the very top

        @showDescription = showDescription
        @hideDescription = hideDescription

    disable: ->
        @hideDescription?!