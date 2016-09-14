/*@author jtbrinkmann aka. Brinkie Pie */
/*@license https://creativecommons.org/licenses/by-nc/4.0/ */

/*
 * missing chat inline image plugins:
 * Derpibooru
 * imgur.com/a/
 * tumblr
 * deviantart
 * e621.net
 * paheal.net
 * gfycat.com
 * cloud-4.steampowered.com … .resizedimage
 */


CHAT_WIDTH = 328px
MAX_IMAGE_HEIGHT = 300px # should be kept in sync with p0ne.css
roles = <[ none dj bouncer manager cohost host ambassador ambassador ambassador admin ]>


window.imgError = (elem) ->
    console.warn "[inline-img] converting image back to link", elem.alt, elem, elem.outerHTML
    $ elem .parent!
        ..text ..attr \href
        ..addClass \p0ne_img_failed


/*####################################
#      UNREAD CHAT NOTIFICAITON      #
####################################*/
module \unreadChatNotif, do
    require: <[ _$context chatDomEvents ]>
    bottomMsg: $!
    setup: ({addListener}) ->
        $chatButton = $ \#chat-button
        @bottomMsg = $cm! .children! .last!
        addListener \early, _$context, \chat:receive, (message) ->
            message.wasAtBottom ?= chatIsAtBottom!
            if not $chatButton.hasClass \selected
                $chatButton.addClass \has-unread
            else if message.wasAtBottom
                @bottomMsg = message.cid
                return

            delete @bottomMsg
            $cm! .addClass \has-unread
            message.unread = true
            message.addClass \unread
        @throttled = false
        addListener chatDomEvents, \scroll, updateUnread
        addListener $chatButton, \click, ->
            updateUnread
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
                        $chatButton .removeClass \has-unread
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
#         BETTER CHAT INPUT          #
####################################*/
module \p0neChatInput, do
    require: <[ chat user ]>
    optional: <[ user_ _$context PopoutListener Lang ]>
    displayName: "Better Chat Input"
    settings: \chat
    help: '''
        Replaces the default chat input field with a multiline textfield.
        This allows you to more accurately see how your message will actually look when send
    '''
    setup: ({addListener, css, $create}) ->
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
            #chat-input-field:focus {
                box-shadow: inset 0 0 0 1px #009cdd !important;
            }
            .muted .chat-input-name {
                display: none;
            }

            .autoresize_helper {
                display: none;
                white-space: pre-wrap;
                word-wrap: break-word;
            }

            #chat-input-field, .autoresize_helper {
                width: 295px;
                padding: 8px 10px 5px 10px;
                min-height: 16px;
                font-weight: 400;
                font-size: 12px;
                font-family: Roboto,sans-serif;
            }
            .chat-input-name {
                position: absolute;
                top: 8px;
                left: 18px;
                font-weight: 700;
                font-size: 12px;
                font-family: Roboto,sans-serif;
                color: #666;
                transition: color .2s ease-out;
                pointer-events:none;
            }
            #chat-input-field:focus + .chat-input-name {
                color: #ffdd6f !important;
            }
            /*fix chat-messages size*/
            #chat-messages {
                height: auto !important;
                bottom: 45px;
            }
        '

        var $name, $autoresize_helper, chat
        chat = PopoutView.chat || window.chat

        # back up elements that are to be removed
        @cIF_ = chat.$chatInputField.0


        # fix permanent focus class
        chat.$chatInput .removeClass \focused
        val = chat.$chatInputField .val!

        # use $name's width to add proper indent to the input field
        @fixIndent = -> requestAnimationFrame -> # wait an animation frame so $name is properly added to the DOM
            indent = 6px + $name.width!
            chat.$chatInputField .css textIndent: indent
            $autoresize_helper   .css textIndent: indent

        # add new input text-area
        oldHeight = 0
        do addListener API, \popout:open, ~>
            chat := PopoutView.chat || window.chat
            @$form = chat.$chatInputField.parent!

            chat.$chatInputField .detach!
            oldHeight := chat.$chatInputField .height!
            chat.$chatInputField.0 = chat.chatInput = $create "<textarea id='chat-input-field' maxlength=256>"
                .attr \tabIndex, 1
                .val val
                .attr \placeholder, Lang?.chat.placeholder
                # add DOM event Listeners from original input field (not using .bind to allow custom chat.onKey* functions)
                .on \keydown, (e) ->
                    chat.onKeyDown e
                .on \keyup, (e) ->
                    chat.onKeyUp e
                #.on \focus, _.bind(chat.onFocus, chat)
                #.on \blur, _.bind(chat.onBlur, chat)

                # add event listeners for autoresizing
                .on 'input', onInput
                .appendTo @$form
                .after do
                    $autoresize_helper := $create \<div> .addClass \autoresize_helper
                .0

            # username field
            $name := $create \<span>
                .addClass \chat-input-name
                .text "#{user.username} "
                .insertAfter chat.$chatInputField

            @fixIndent!

        sleep 2_000ms, @fixIndent

        if _$context
            addListener _$context, \chat:send, -> requestAnimationFrame ->
                chat.$chatInputField .trigger \input

        if user_?
            addListener user_, \change:username, @fixIndent

        function onInput
            content = chat.$chatInputField .val!
            if (content2 = content.replace(/\n/g, "")) != content
                chat.$chatInputField .val (content=content2)
            $autoresize_helper.text("#content")
            newHeight = $autoresize_helper .height!
            return if oldHeight == newHeight
            console.log "[chat input] adjusting height"
            scrollTop = chat.$chatMessages.scrollTop!
            chat.$chatInputField
                .css height: newHeight
            chat.$chatMessages
                .css bottom: newHeight + 30px
                .scrollTop scrollTop + newHeight - oldHeight
            oldHeight := newHeight


    disable: ->
        if @cIF_
            chat.$chatInputField = $ (chat.chatInput = @cIF_)
                .val chat.$chatInputField.val!
                .appendTo @$form



module \chatPlugin, do
    require: <[ _$context ]>
    setup: ({addListener}) ->
        p0ne.chatLinkPlugins ||= []
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
            msg.message .= replace /<a (.+?)>((https?:\/\/)(?:www\.)?(([^\/]+).+?))<\/a>/gi, (all,pre,completeURL,protocol,domain,url)->
                [domain, url] = [url, domain]
                domain .= toLowerCase!
                &6 = onload
                &7 = msg
                for plugin in p0ne.chatLinkPlugins
                    try
                        return that if plugin ...
                    catch err
                        console.error "[p0ne] error while processing chat link plugin", plugin, err
                return all

        addListener _$context, \chat:receive, (e) ->
            getChat(e.cid) .addClass Object.keys(e.classes).join(' ')

        function addClass classes
            console.log "#{@cid} add class '#classes'"
            if typeof classes == \string
                for className in classes.split /\s+/g when className
                    console.log "\t- added class #className"
                    @classes[className] = true
        function removeClass classes
            if typeof classes == \string
                for className in classes.split /\s+/g
                    delete @classes[className]


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
                        if role != -1
                            fromRole = "from-#{roles[role]}"
                            fromRole += " from-staff" if role > 1 # RDJ
                    if not fromRole
                        for r in ($this .find \.icon .prop(\className) ||"").split " " when r.startsWith \icon-chat-
                            fromRole = "from-#{r.substr 10}"
                        else
                            fromRole = \from-none
                    $this .addClass "fromID-#{uid} #fromRole"
        catch err
            console.error "[chatMessageClasses] couldn't convert old messages", err.stack

        addListener (window._$context || API), \chat:plugin, ({type, uid}:message) -> if uid
            message.user = user = getUser(uid)
            message.addClass "fromID-#{uid}"
            message.addClass "from-#{getRank user}"
            message.addClass \from-staff if user?.role > 1

/*####################################
#          OTHERS' @MENTIONS         #
####################################*/
module \chatOthersMentions, do
    optional: <[ users ]>
    require: <[ chatPlugin ]>
    settings: \chat
    displayName: 'Highlight @mentions for others'
    setup: ({addListener}) ->
        sleep 0, ->
            $cm! .children! .each ->

        addListener _$context, \chat:plugin, ({type, uid}:message) -> if uid
            res = ""; lastI = 0
            for mention in getMentions(message, true) when mention.id != userID or type == \mention
                res += "
                    #{message.message .substring(lastI, mention.offset)}
                    <span class='mention-other mentionID-#{mention.id} mention-#{getRank(mention)} #{if! (mention.role||mention.gRole) then '' else \mention-staff}'>
                        @#{mention.username}
                    </span>
                "
                lastI = mention.offset + 1 + mention.username.length
            else
                return

            message.message = res + message.message.substr(lastI)

/*####################################
#           INLINE  IMAGES           #
#             YT PREVIEW             #
####################################*/
CHAT_WIDTH = 500px
module \chatInlineImages, do
    require: <[ chatPlugin ]>
    settings: \chat
    displayName: 'Inline Images'
    help: '''
        Converts image links to images in the chat, so you can see a preview
    '''
    setup: ({add}) ->
        add p0ne.chatLinkPlugins, (all,pre,completeURL,protocol,domain,url, onload) ~>
            # images
            if @plugins[domain] || @plugins[domain .= substr(1 + domain.indexOf(\.))]
                [rgx, repl] = that
                img = url.replace(rgx, repl)
                if img != url
                    console.log "[inline-img]", "#completeURL ==> #protocol#img"
                    return "<a #pre><img src='#protocol#img' class=p0ne_img #onload onerror='imgError(this)'></a>"

            # direct images (the revision suffix si required for some blogspot images; e.g. http://vignette2.wikia.nocookie.net/moth-ponies/images/d/d4/MOTHPONIORIGIN.png/revision/latest?cb=20131206071408)
            #   <URL stuff><    image suffix                hires       image.php   revision suffix     query/hash
            if /^[^\#\?]+(?:\.(?:jpg|jpeg|gif|png|webp|apng)(?:@\dx)?|image\.php)(?:\/revision\/\w+)?(?:\?.*|\#.*)?$/i .test url
                console.log "[inline-img]", "[direct] #completeURL"
                return "<a #pre><img src='#completeURL' class=p0ne_img #onload onerror='imgError(this)'></a>"

            console.log "[inline-img]", "NO MATCH FOR #completeURL (probably isn't an image)"
            return false

    plugins:
        \imgur.com :       [/^imgur.com\/(?:r\/\w+\/)?(\w\w\w+)/g, "i.imgur.com/$1.gif"]
        \prntscrn.com :    [/^(prntscr.com\/\w+)(?:\/direct\/)?/g, "$1/direct"]
        \gyazo.com :       [/^gyazo.com\/\w+/g, "i.$&/direct"]
        \dropbox.com :     [/^dropbox.com(\/s\/[a-z0-9]*?\/[^\/\?#]*\.(?:jpg|jpeg|gif|png|webp|apng))/g, "dl.dropboxusercontent.com$1"]
        \pbs.twitter.com : [/^(pbs.twimg.com\/media\/\w+\.(?:jpg|jpeg|gif|png|webp|apng))(?:\:large|\:small)?/g, "$1:small"]
        \googleimg.com :   [/^google\.com\/imgres\?imgurl=(.+?)(?:&|$)/g, (,src) -> return decodeURIComponent url]
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
        PADDING = 20px
        $app = $ \#app #TEMP
        $container = $ \#dialog-container
        var lastSrc
        @$el = $el = $createPersistent '<img class=p0ne_img_large>' .appendTo $body
            .css do #TEMP
                position: \absolute
                zIndex: 6
                cursor: \pointer
            .hide!
        addListener $container, \click, \.p0ne_img_large, ->
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
                $el .css do
                    width: \auto
                    height: \auto
                <- requestAnimationFrame
                offset = $img.offset!
                appW = $app.width!
                appH = $app.height!
                w = $el.width!
                h = $el.height!
                ratio = 1   <?   (appW - 345px - PADDING) / w   <?   (appH - PADDING) / h
                w *= ratio
                h *= ratio
                console.log "[lightbox] rendering", {w, h, oW: $el.css(\width), oH: $el.css(\height), ratio}
                $el
                    .show!
                    .css do
                        left: offset.left
                        top: offset.top
                        width: $img.width!
                        height: $img.height!
                    .animate do
                        left: ($app.width! - w - 345px) / 2
                        top: ($app.height! - h) / 2
                        width: w
                        height: h
                $img.css visibility: \hidden

            close: (cb) ->
                $img_ = $img
                $el_ = $el
                @isOpen = false
                offset = $img.offset!
                $el.animate do
                    left: offset.left
                    top: offset.top
                    width: $img.width!
                    height: $img.height!
                    ~>
                        $img_.css visibility: \visible
                        $el_.hide!
                        @container.onClose!
                        cb?!
        dialog.closeBind = dialog~close

        addListener chatDomEvents, \click, \.p0ne_img, (e) ->
            console.info "[lightbox] showing", this, this.src
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
                    $el .0 .onload = ->
                        _$context .trigger \ShowDialogEvent:show, {dialog}, true
                    $el .attr \src, src
                else
                    _$context .trigger \ShowDialogEvent:show, {dialog}, true
    disable: ->
        if @dialog.isOpen
            <~ @dialog.close
            @$el .remove!
        else
            @$el .remove!

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


module \chatYoutubeThumbnails, do
    settings: \chat
    help: '''
        Convert show thumbnails of linked Youtube videos in the chat.
        When hovering the thumbnail, it will animate, alternating between three frames of the video.
    '''
    setup: ({add, addListener}) ->
        add p0ne.chatLinkPlugins, @plugin
        addListener $(\#chat), 'mouseenter mouseleave', \.p0ne_yt_img, (e) ~>
            clearInterval @interval
            # assuming that `e.target` always refers to the .p0ne_yt_img
            id = e.parentElement.dataset.ytCid
            img = e.target
            if e.type == \mouseenter
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
            else
                img.style.backgroundImage = "url(http://i.ytimg.com/vi/#id/0.jpg)"
                console.log "[p0ne_yt_preview]", "stopped"
                #ToDo hide YT-options
    plugin: (all,pre,completeURL,protocol,domain,url, onload) ->
        yt = YT_REGEX .exec(url)
        if yt and (yt = yt.1)
            console.log "[inline-img]", "[YouTube #yt] #url ==> http://i.ytimg.com/vi/#yt/0.jpg"
            return "
                <a class=p0ne_yt data-yt-cid='#yt' #pre>
                    <div class=p0ne_yt_icon></div>
                    <div class=p0ne_yt_img #onload style='background-image:url(http://i.ytimg.com/vi/#yt/0.jpg)'></div>
                    #url
                </a>
            " # no `onerror` on purpose # when updating the HTML, check if it breaks the animation callback
            # default.jpg for smaller thumbnail; 0.jpg for big thumbnail; 1.jpg, 2.jpg, 3.jpg for previews
        return false
    interval: -1
    frame: 1
    lastID: ''
