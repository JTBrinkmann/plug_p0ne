/**
 * chat-related plug_p0ne modules
 *
 * @author jtbrinkmann aka. Brinkie Pie
 * @license MIT License
 * @copyright (c) 2015 J.-T. Brinkmann
 */

/* ToDo:
 * add missing chat inline image plugins:
 * Derpibooru
 * imgur.com/a/
 * tumblr
 * deviantart
 * gfycat.com
 * cloud-4.steampowered.com … .resizedimage
 */


MAX_IMAGE_HEIGHT = 300px # should be kept in sync with p0ne.css





/*####################################
#         BETTER CHAT INPUT          #
####################################*/
module \betterChatInput, do
    require: <[ chat user ]>
    optional: <[ user_ _$context PopoutListener Lang ]>
    displayName: "Better Chat Input"
    settings: \chat
    help: '''
        Replaces the default chat input field with a multiline textfield.
        This allows you to more accurately see how your message will actually look when send
    '''
    setup: ({addListener, replace, revert, css, $create}) ->
        # apply styles
        css \p0ne_chat_input, '
            #chat-input {
                bottom: 7px;
                height: auto;
                background: transparent !important;
                min-height: 30px;
            }
            #chat-input-field {
                position: static;
                resize: none;
                height: 16px;
                overflow: hidden;
                margin-left: 8px;
                color: #eee;
                background: rgba(0, 24, 33, .7);
                box-shadow: inset 0 0 0 1px transparent;
                transition: box-shadow .2s ease-out;
            }
            .popout #chat-input-field {
                box-sizing: content-box;
            }
            #chat-input-field:focus {
                box-shadow: inset 0 0 0 1px #009cdd !important;
            }

            .autoresize-helper {
                display: none;
                white-space: pre-wrap;
                word-wrap: break-word;
            }

            #chat-input-field, .autoresize-helper {
                width: 295px;
                padding: 8px 10px 5px 10px;
                min-height: 16px;
                font-weight: 400;
                font-size: 12px;
                font-family: Roboto,sans-serif;
            }

            /* emote */
            .p0ne-better-chat-emote {
                font-style: italic;
            }

            /*fix chat-messages size*/
            #chat-messages {
                height: auto !important;
                bottom: 45px;
            }
        '

        var $autoresize_helper, oldHeight
        chat = window.chat

        # back up elements
        @cIF_ = chat.$chatInputField.0
        @$form = chat.$chatInputField.parent!

        focused = chat.$chatInputField .hasClass \focused
        #val = chat.$chatInputField .val!
        chat.$chatInput .removeClass \focused # fix permanent focus class


        # add new input text-area
        init = addListener API, \popout:open, (,PopoutView) ~>
            chat := PopoutView.chat
            @popoutcIF_ = chat.$chatInputField.0
            @$popoutForm = chat.$chatInputField.parent!
            val = window.chat.$chatInputField .val!
            focused = window.chat.$chatInputField .is \:focus
            #oldHeight := chat.$chatInputField .height!
            chat.$chatInputField .detach!
            chat.$chatInputField.0 = chat.chatInput = $create "<textarea id='chat-input-field' maxlength=256>"
                .attr \tabIndex, 1
                .val val
                .focus! # who doesn't want to have the chat focused?
                .attr \placeholder, Lang?.chat.placeholder || "Chat"
                # add DOM event Listeners from original input field (not using .bind to allow custom chat.onKey* functions)
                .on \keydown, (e) ->
                    chat.onKeyDown e
                .on \keyup, (e) ->
                    chat.onKeyUp e
                #.on \focus, _.bind(chat.onFocus, chat)
                #.on \blur, _.bind(chat.onBlur, chat)

                # add event listeners for autoresizing
                .on \input, onInput
                .on \keydown, checkForMsgSend
                .appendTo @$popoutForm
                .after do
                    $autoresize_helper := $create \<div> .addClass \autoresize-helper
                .0


        # init for onpage chat
        init(null, {chat: window.chat})
        $onpage_autoresize_helper = $autoresize_helper

        # init for current popout, if any
        init(null, PopoutView) if PopoutView._window

        addListener API, \popout:close, ~>
            window.chat.$chatInputField .val(chat.$chatInputField .val!)
            chat := window.chat
            $autoresize_helper := $onpage_autoresize_helper


        chatHidden = $cm!.parent!.css(\display) == \none


        wasEmote = false
        function onInput
            content = chat.$chatInputField .val!
            if content != (content = content.replace(/\n/g, "")) #.replace(/\s+/g, " "))
                chat.$chatInputField .val content
            if content.0 == \/ and (content.1 == \m and content.2 == \e or content.1 == \e and content.2 == \m)
                if not wasEmote
                    wasEmote := true
                    chat.$chatInputField .addClass \p0ne-better-chat-emote
                    $autoresize_helper   .addClass \p0ne-better-chat-emote
            else if wasEmote
                wasEmote := false
                chat.$chatInputField .removeClass \p0ne-better-chat-emote
                $autoresize_helper   .removeClass \p0ne-better-chat-emote

            $autoresize_helper.text(content)
            newHeight = $autoresize_helper .height!
            return if oldHeight == newHeight
            #console.log "[chat input] adjusting height"
            scrollTop = chat.$chatMessages.scrollTop!
            chat.$chatInputField
                .css height: newHeight
            chat.$chatMessages
                .css bottom: newHeight + 30px
                .scrollTop scrollTop + newHeight - oldHeight
            oldHeight := newHeight

        function checkForMsgSend e
            if (e and (e.which || e.keyCode)) == 13 # ENTER
                requestAnimationFrame(onInput)


    disable: ->
        if @cIF_
            chat.$chatInputField = $ (chat.chatInput = @cIF_)
                .val chat.$chatInputField.val!
                .appendTo @$form
        else
            console.warn "#{getTime!} [betterChatInput] ~~~~ disabling ~~~~", @cIF_, @$form

        if PopoutView._window and @popoutcIF_
            PopoutView.chat.$chatInputField = $ (PopoutView.chat.chatInput = @popoutcIF_)
                .val PopoutView.chat.$chatInputField.val!
                .appendTo @$popoutForm




/*####################################
#            CHAT PLUGIN             #
####################################*/
module \chatPlugin, do
    require: <[ _$context ]>
    setup: ({addListener}) ->
        p0ne.chatLinkPlugins ||= []
        onerror = 'onerror="chatPlugin.imgError(this)"'
        addListener \early, _$context, \chat:receive, (msg) -> # run plugins that modify chat msgs
            msg.wasAtBottom ?= chatIsAtBottom! # p0ne.saveChat also sets this
            msg.classes = {}; msg.addClass = addClass; msg.removeClass = removeClass

            _$context .trigger \chat:plugin, msg
            API .trigger \chat:plugin, msg


            # p0ne.chatLinkPlugins
            if msg.wasAtBottom
                onload = 'onload="chatScrollDown()"'
            else
                onload = ''
            msg.message .= replace /<a (.+?)>((https?:\/\/)(?:www\.)?(([^\/]+).+?))<\/a>/gi, (all,pre,completeURL,protocol,url, domain, offset)->
                domain .= toLowerCase!
                for ctx in [_$context, API] when ctx._events[\chat:image]
                    for plugin in ctx._events[\chat:image]
                        try
                            if plugin.callback.call plugin.ctx, {all,pre,completeURL,protocol,domain,url, offset,  onload,onerror,msg}
                                return that
                                #= experimental image loader =
                                #$ that
                                #    .data cid, msg.cid
                                #    .data originalURL
                                #    .appendTo $imgLoader
                                #return '<div class="p0ne-img-placeholder"><div class="p0ne-img-placeholder-text">loading…</div><div class="p0ne-img-placeholder-fancy"></div></div>'
                        catch err
                            console.error "[p0ne] error while processing chat link plugin", plugin, err.stack
                return all

        addListener _$context, \chat:receive, (e) ->
            getChat(e) .addClass Object.keys(e.classes ||{}).join(' ')

        function addClass classes
            if typeof classes == \string
                for className in classes.split /\s+/g when className
                    @classes[className] = true
        function removeClass classes
            if typeof classes == \string
                for className in classes.split /\s+/g
                    delete @classes[className]
    imgError: (elem) ->
        console.warn "[inline-img] converting image back to link", elem.alt, elem, elem.outerHTML
        $ elem .parent!
            ..text ..attr \href
            ..addClass \p0ne-img-failed


/*####################################
#           MESSAGE CLASSES          #
####################################*/
module \chatMessageClasses, do
    optional: <[ users ]>
    require: <[ chatPlugin ]>
    setup: ({addListener}) ->
        try
            $cm! .children! .each ->
                if uid = this.dataset.cid
                    uid .= substr(0, 7)
                    return if not uid
                    $this = $ this
                    if fromUser = users.get uid
                        role = getRank(fromUser)
                        #if role != \ghost
                        fromRole = "from-#role"
                        if role == \regular
                            fromRole = \from-you if uid == userID
                        else
                            fromRole += " from-staff"
                        /*else # stupid p3. who would abuse the class `from` instead of using something sensible instead?!
                            fromRole += " from"
                        */
                        fromRole += " from-friend" if fromUser.friend
                    else
                        for r in ($this .find \.icon .prop(\className) ||"").split " " when r.startsWith \icon-chat-
                            fromRole = "from-#{r.substr 10}"
                        else
                            fromRole = \from-regular
                    if $ this .find \.subscriber
                        fromRole += " from-subscriber"
                    $this .addClass "fromID-#{uid} #fromRole"
        catch err
            console.error "[chatMessageClasses] couldn't convert old messages", err.stack

        addListener (window._$context || API), \chat:plugin, ({type, uid}:message) -> if uid
            message.addClass "fromID-#uid"


            if message.user = getUser(uid)
                rank = getRank message.user
                if uid == userID
                    message.addClass \from-you
                    also = \-also
                else
                    message.addClass "from-#rank"
                message.addClass \from-staff if message.user.role > 1 or message.user.gRole
                if rank == \regular
                    message.addClass \from-subscriber if message.user.sub
                    message.addClass \from-friend if message.user.friend




/*####################################
#      UNREAD CHAT NOTIFICAITON      #
####################################*/
module \unreadChatNotif, do
    require: <[ _$context chatDomEvents chatPlugin ]>
    bottomMsg: $!
    settings: \chat
    displayName: 'Mark Unread Chat'
    setup: ({addListener}) ->
        unreadCount = 0
        $chatButton = $ \#chat-button
            .append $unreadCount = $ '<div class=p0ne-toolbar-count>'
        @bottomMsg = $cm! .children! .last!
        addListener _$context, \chat:plugin, (message) ->
            message.wasAtBottom ?= chatIsAtBottom!
            if not $chatButton.hasClass \selected and not PopoutView?.chat?
                $chatButton.addClass \p0ne-toolbar-highlight
                $unreadCount .text (unreadCount + 1)
            else if message.wasAtBottom
                @bottomMsg = message.cid
                return

            delete @bottomMsg
            $cm! .addClass \has-unread
            message.unread = true
            message.addClass \unread
            unreadCount++
        @throttled = false
        addListener chatDomEvents, \scroll, updateUnread
        addListener $chatButton, \click, updateUnread

        # reduce deleted messages from unreadCount
        addListener \early _$context, \chat:delete, (cid) ->
            $msg = getChat(cid)
            if $msg.length and $msg.hasClass(\unread)
                $msg.removeClass \unread # this is to avoid problems with disableChatDelete
                unreadCount--

        ~function updateUnread
            return if @throttled
            @throttled := true
            sleep 200ms, ~>
                try
                    cm = $cm!
                    cmHeight = cm .height!
                    lastMsg = msg = @bottomMsg
                    $readMsgs = $!; l=0
                    while ( msg .=next! ).length
                        if msg .position!.top > cmHeight
                            @bottomMsg = lastMsg
                            break
                        else if msg.hasClass \unread
                            $readMsgs[l++] = msg.0
                        lastMsg = msg
                    if l
                        unread = cm.find \.unread
                        sleep 1_500ms, ~>
                            $readMsgs.removeClass \unread
                            if (unread .= filter \.unread) .length
                                @bottomMsg = unread .removeClass \unread .last!
                    if not msg.length
                        cm .removeClass \has-unread
                        $chatButton .removeClass \p0ne-toolbar-highlight
                        unreadCount := 0
                @throttled := false
    fix: ->
        @throttled = false
        cm = $cm!
        cm
            .removeClass \has-unread
            .find \.unread .removeClass \unread
        @bottomMsg = cm.children!.last!
    disable: ->
        $cm!
            .removeClass \has-unread
            .find \.unread .removeClass \unread


/*####################################
#          OTHERS' @MENTIONS         #
####################################*/
module \chatOthersMentions, do
    optional: <[ users ]>
    require: <[ chatPlugin ]>
    settings: \chat
    displayName: 'Highlight @mentions for others'
    setup: ({addListener}) ->
        /*sleep 0, ->
            $cm! .children! .each ->*/

        addListener _$context, \chat:plugin, ({type, uid}:message) -> if uid
            res = ""; lastI = 0
            for mention in getMentions(message, true) when mention.id != userID or type == \emote
                res += "
                    #{message.message .substring(lastI, mention.offset)}
                    <span class='mention-other mentionID-#{mention.id} mention-#{getRank(mention)} #{if! (mention.role||mention.gRole) then '' else \mention-staff}'>
                        @#{mention.rawun}
                    </span>
                "
                lastI = mention.offset + 1 + mention.rawun.length
            else
                return

            message.message = res + message.message.substr(lastI)


/*####################################
#           INLINE  IMAGES           #
####################################*/
CHAT_WIDTH = 500px
module \chatInlineImages, do
    require: <[ chatPlugin ]>
    settings: \chat
    settingsVip: true
    displayName: 'Inline Images'
    help: '''
        Converts image links to images in the chat, so you can see a preview.

        When enabled, you can enter tags to filter images which should not be shown inline. These tags are case-insensitive and space-seperated.

        ☢ The taglist is subject to improvement
    '''
    _settings:
        filterTags: <[ nsfw suggestive gore spoiler no-inline noinline ]>
    setup: ({addListener}) ->
        addListener API, \chat:image, ({all,pre,completeURL,protocol,domain,url, onload, onerror, msg, offset}) ~>
            # note: converting images with the domain plug.dj might allow some kind of exploit in the future
            if img = @inlineify ...
                msg.hasFilterWord ?= msg.message.toLowerCase!.hasAny @_settings.filterTags
                if msg.hasFilterWord or msg.message[offset + all.length] == ";" or domain == \plug.dj
                    console.info "[inline-img] filtered image", "#completeURL ==> #protocol#img"
                    return "<a #{pre .replace /class=('|")?(\S+)/i, (,q,cl) !->
                            return 'class='+(q||'\'')+'p0ne-img-filtered '+cl+(if q then '' else '\'')
                        } data-image-url='#img'>#completeURL</a>"
                else
                    console.log "[inline-img]", "#completeURL ==> #img"
                    return "<a #pre><img src='#img' class=p0ne-img #onload #onerror></a>"
            else
                return false

    # (the revision suffix is required for some blogspot images; e.g. http://vignette2.wikia.nocookie.net/moth-ponies/images/d/d4/MOTHPONIORIGIN.png/revision/latest)
    #           <URL stuff><        image suffix           >< image.php>< hires ><  revision suffix >< query/hash >
    regDirect: /^[^\#\?]+(?:\.(?:jpg|jpeg|gif|png|webp|apng)|image\.php)(?:@\dx)?(?:\/revision\/\w+)?(?:\?.*|\#.*)?$/i
    inlineify: ({all,pre,completeURL,protocol,domain,url, onload, onerror, msg, offset}) ->
            #= images =
            if @plugins[domain] || @plugins[domain.substr(1 + domain.indexOf(\.))]
                [rgx, repl, forceProtocol] = that
                if url != (img = url.replace(rgx, repl))
                    return "#{forceProtocol||protocol}#img"

            #= direct images =
            if @regDirect .test url
                if domain in @forceHTTPSDomains
                    return completeURL .replace 'http://', 'https://'
                else
                    return completeURL

            #= no match =
            return false

    settingsExtra: ($el) ->
        $ '<span class=p0ne-settings-input-label>'
            .text "filter tags:"
            .appendTo $el
        $input = $ '<input class="p0ne-settings-input">'
            .val @_settings.filterTags.join " "
            .on \input, ~>
                @_settings.filterTags = [$.trim(tag) for tag in $input.val!.split " "]
            .appendTo $el

    forceHTTPSDomains: <[ i.imgur.com deviantart.com ]>
    plugins:
        \imgur.com :       [/^(?:i\.|m\.|edge\.|www\.)*imgur\.com\/(?:r\/[\w]+\/)*(?!gallery)(?!removalrequest)(?!random)(?!memegen)([\w]{5,7}(?:[&,][\w]{5,7})*)(?:#\d+)?[sbtmlh]?(?:\.(?:jpe?g|gif|png|gifv))?$/, "i.imgur.com/$1.gif"] # from RedditEnhancementSuite
        \prntscrn.com :    [/^(prntscr.com\/\w+)(?:\/direct\/)?/, "$1/direct"]
        \gyazo.com :       [/^gyazo.com\/\w+/, "$&/raw"]
        \dropbox.com :     [/^dropbox.com(\/s\/[a-z0-9]*?\/[^\/\?#]*\.(?:jpg|jpeg|gif|png|webp|apng))/, "dl.dropboxusercontent.com$1"]
        \pbs.twitter.com : [/^(pbs.twimg.com\/media\/\w+\.(?:jpg|jpeg|gif|png|webp|apng))(?:\:large|\:small)?/, "$1:small"]
        \googleimg.com :   [/^google\.com\/imgres\?imgurl=(.+?)(?:&|$)/, (,src) -> return decodeURIComponent url]
        \imageshack.com :  [/^imageshack\.com\/[fi]\/(\w\w)(\w+?)(\w)(?:\W|$)/, -> chatInlineImages.imageshackPlugin ...]
        \imageshack.us :   [/^imageshack\.us\/[fi]\/(\w\w)(\w+?)(\w)(?:\W|$)/, -> chatInlineImages.imageshackPlugin ...]

        /* meme-plugins based on http://userscripts.org/scripts/show/154915.html (mirror: http://userscripts-mirror.org/scripts/show/154915.html ) */
        \quickmeme.com :     [/^(?:m\.)?quickmeme\.com\/meme\/(\w+)/, "i.qkme.me/$1.jpg"]
        \qkme.me :           [/^(?:m\.)?qkme\.me\/(\w+)/, "i.qkme.me/$1.jpg"]
        \memegenerator.net : [/^memegenerator\.net\/instance\/(\d+)/, "http://cdn.memegenerator.net/instances/#{CHAT_WIDTH}x/$1.jpg"]
        \imageflip.com :     [/^imgflip.com\/i\/(.+)/, "i.imgflip.com/$1.jpg"]
        \livememe.com :      [/^livememe.com\/(\w+)/, "i.lvme.me/$1.jpg"]
        \memedad.com :       [/^memedad.com\/meme\/(\d+)/, "memedad.com/memes/$1.jpg"]
        \makeameme.org :     [/^makeameme.org\/meme\/(.+)/, "makeameme.org/media/created/$1.jpg"]

    imageshackPlugin: (,host,img,ext) ->
        ext = {j: \jpg, p: \png, g: \gif, b: \bmp, t: \tiff}[ext]
        return "https://imagizer.imageshack.us/a/img#{parseInt(host,36)}/1337/#img.#ext"

    pluginsAsync:
        \deviantart.com
        \fav.me
        \sta.sh
    deviantartPlugin: (replaceLink, url) ->
        $.getJSON "http://backend.deviantart.com/oembed?format=json&url=#url", (d) ->
            if d.height <= MAX_IMAGE_HEIGHT
                replaceLink d.url
            else
                replaceLink d.thumbnail_url

module \imageLightbox, do
    require: <[ chatInlineImages chatDomEvents ]>
    setup: ({addListener, $createPersistent}) ->
        var $img
        PADDING = 10px # padding on each side of the image
        $container = $ \#dialog-container
        var lastSrc
        @$el = $el = $createPersistent '<img class=p0ne-img-large>'
            .css do # TEMP
                position: \absolute
                zIndex: 6
                cursor: \pointer
                boxShadow: '0 0 35px black, 0 0 5px black'
            .hide!
            .load ->
                _$context .trigger \ShowDialogEvent:show, {dialog}, true
            .appendTo $body
        addListener $container, \click, \.p0ne-img-large, ->
            dialog.close!
            return false

        @dialog = dialog =
            on: (,,@container) ->
            off: $.noop
            containerOnClose: $.noop
            destroy: $.noop

            $el: $el

            render: ->
                # calculating image size
                /*
                $elImg .css do
                    width: \auto
                    height: \auto
                <- requestAnimationFrame
                appW = $app.width!
                appH = $app.height!
                ratio = 1   <?   (appW - 345px - PADDING) / w   <?   (appH - PADDING) / h
                w *= ratio
                h *= ratio
                */
                #w = $el.width!
                #h = $el.height!
                contW = $container.width!
                contH = $container.height!
                imgW = $img.width!
                imgH = $img.height!
                offset = $img.offset!
                console.log "[lightbox] rendering" #, {w, h, oW: $el.css(\width), oH: $el.css(\height), ratio}
                $el
                    .removeClass \p0ne-img-large-open
                    .css do # copy position and size of inline image (note: the -10px are to make up for the margin)
                        left:      "#{(offset.left + imgW/2) *100/contW}%"
                        top:       "#{(offset.top  + imgH/2) *100/contH}%"
                        maxWidth:  "#{               imgW    *100/contW}%"
                        maxHeight: "#{               imgH    *100/contH}%"
                    .show!
                $img.css visibility: \hidden # hide inline image
                requestAnimationFrame ->
                    $el
                        .addClass \p0ne-img-large-open # use CSS transition to move enlarge the image (if possible)
                        .css do
                            left: ''
                            top:  ''
                            maxWidth: ''
                            maxHeight: ''

            close: (cb) ->
                $img_ = $img
                $el_ = $el
                @isOpen = false
                contW = $container.width!
                contH = $container.height!
                imgW = $img.width!
                imgH = $img.height!
                offset = $img.offset!
                $el
                    .css do
                        left:      "#{(offset.left + imgW/2) *100/contW}%"
                        top:       "#{(offset.top  + imgH/2) *100/contH}%"
                        maxWidth:  "#{                 imgW  *100/contW}%"
                        maxHeight: "#{                 imgH  *100/contH}%"
                sleep 200ms, ~>
                    # let's hope this is somewhat sync with when the CSS transition ends
                    $el .removeClass \p0ne-img-large-open
                    $img_ .css visibility: \visible
                    @container.onClose!
                    cb?!
        dialog.closeBind = dialog~close

        addListener chatDomEvents, \click, \.p0ne-img, (e) ->
            $img_ = $ this
            e.preventDefault!

            if dialog.isOpen
                if $img_ .is $img
                    dialog.close!
                else
                    dialog.close helper
            else
                helper!
            function helper
                $img := $img_
                dialog.isOpen = true
                src = $img.attr \src
                if src != lastSrc
                    lastSrc := src
                    # not using jQuery event listeners to avoid having to directly replace old listener
                    # this way we don't have to .off \load .one \load, …
                    $el.0 .onload = ->
                        _$context .trigger \ShowDialogEvent:show, {dialog}, true
                    $el .attr \src, src
                else
                    _$context .trigger \ShowDialogEvent:show, {dialog}, true
    disable: ->
        if @dialog?.isOpen
            <~ @dialog.close
            @$el? .remove!
        else
            @$el? .remove!

# /* image plugins using plugCubed API (credits go to TATDK / plugCubed) */
# module \chatInlineImages_plugCubedAPI, do
#    require: <[ chatInlineImages ]>
#    setup: ->
#        chatInlineImages.plugins <<<< @plugins
#    plugins:
#        \deviantart.com :    [/^[\w\-\.]+\.deviantart.com\/(?:art\/|[\w:\-]+#\/)[\w:\-]+/, "https://api.plugCubed.net/redirect/da/$&"]
#        \fav.me :            [/^fav.me\/[\w:\-]+/, "https://api.plugCubed.net/redirect/da/$&"]
#        \sta.sh :            [/^sta.sh\/[\w:\-]+/, "https://api.plugCubed.net/redirect/da/$&"]
#        \gfycat.com :        [/^gfycat.com\/(.+)/, "https://api.plugCubed.net/redirect/gfycat/$1"]

/*
module \chatYoutubeThumbnails, do
    settings: \chat
    help: '''
        Convert show thumbnails of linked Youtube videos in the chat.
        When hovering the thumbnail, it will animate, alternating between three frames of the video.
    '''
    setup: ({add, addListener}) ->
        addListener chatDomEvents, \mouseenter, \.p0ne-yt-img, (e) ~>
            clearInterval @interval
            img = this
            id = this.parentElement

            if id != @lastID
                @frame = 1
                @lastID = id
            img.style.backgroundImage = "url(http://i.ytimg.com/vi/#id/#{@frame}.jpg)"
            @interval = repeat 1_000ms, ~>
                console.log "[p0ne_yt_preview]", "showing 'http://i.ytimg.com/vi/#id/#{@frame}.jpg'"
                @frame = (@frame % 3) + 1
                img.style.backgroundImage = "url(http://i.ytimg.com/vi/#id/#{@frame}.jpg)"
            console.log "[p0ne_yt_preview]", "started", e, id, @interval
            #ToDo show YT-options (grab, open, preview, [automute])

        addListener chatDomEvents, \mouseleave, \.p0ne-yt-img, (e) ~>
            clearInterval @interval
            img = this
            id = this.parentElement.dataset.ytCid
            img.style.backgroundImage = "url(http://i.ytimg.com/vi/#id/0.jpg)"
            console.log "[p0ne_yt_preview]", "stopped"
            #ToDo hide YT-options

        addListener API, \chat:image, ({pre, url, onload}) ->
        yt = YT_REGEX .exec(url)
        if yt and (yt = yt.1)
            console.log "[inline-img]", "[YouTube #yt] #url ==> http://i.ytimg.com/vi/#yt/0.jpg"
            return "
                <a class=p0ne-yt data-yt-cid='#yt' #pre>
                    <div class=p0ne-yt-icon></div>
                    <div class=p0ne-yt-img #onload style='background-image:url(http://i.ytimg.com/vi/#yt/0.jpg)'></div>
                    #url
                </a>
            " # no `onerror` on purpose # when updating the HTML, check if it breaks the animation callback
            # default.jpg for smaller thumbnail; 0.jpg for big thumbnail; 1.jpg, 2.jpg, 3.jpg for previews
        return false
    interval: -1
    frame: 1
    lastID: ''
*/


/*####################################
#    CUSTOM NOTIFICATION TRIGGERS    #
####################################*/
module \customChatNotificationTrigger, do
    displayName: 'Notification Trigger Words'
    settings: \chat
    _settings:
        triggerwords: []
    require: <[ chatPlugin _$context ]>
    setup: ({addListener}) !->
        addListener _$context, \chat:plugin, (d) ~> if d.uid != userID
            mentioned = false
            d.message .= replaceSansHTML @regexp, (,word) ->
                mentioned := true
                return "<span class=p0ne-trigger-word>#word</span>"
            playChatSound! if mentioned
        @updateRegexp!

    updateRegexp: !->
        @regexp = //
            \b(#{@_settings.triggerwords .join '|'})\b
        //gi

    settingsExtra: ($el) !->
        $ '<span class=p0ne-settings-input-label>'
            .text "aliases (comma seperated):"
            .appendTo $el
        $input = $ '<input class="p0ne-settings-input">'
            .val @_settings.triggerwords.join ", "
            .on \input, ~>
                @_settings.triggerwords = []; l=0
                for word in $input.val!.split ","
                    @_settings.triggerwords[l++] = $.trim(word)
                @updateRegexp!
            .appendTo $el