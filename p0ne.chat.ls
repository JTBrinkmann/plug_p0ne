/*@author jtbrinkmann aka. Brinkie Pie */
/*@license https://creativecommons.org/licenses/by-nc/4.0/ */
p0ne = window.p0ne
d = new Date
dayISO = d.toISOString! .substr(0, 10)
timezoneISO = -d.getTimezoneOffset!
timezoneISO = "#{Math.floor(timezoneISO / 60)}:#{timezoneISO % 60}"

chatWidth = 328px
requireHelper do
    name: \database
    test: (.settings)
    fallback:
        settings: chatTS: 24h
requireHelper do
    name: \lang
    test: (.welcome?.title)
    fallback:
        chat:
            delete: "Delete"

requireHelper do
    name: \Chat
    test: ((it) -> it::?.onDeleteClick and not it::scrollToBottom)
    fallback: window.app?.room?.chat.constructor
/*
requireHelper do
    name: \ChatPopup
    test: (.::?.scrollToBottom)
*/
requireHelper do
    name: \ChatHelper
    test: (it) -> return it.sendChat and it != window.API
requireHelper do
    name: \Spinner
    id: \de369/d86c0/bf208/e0fc2 # 2014-09-03
    test: (.::?className == \spinner)
    #ToDo fallback


window.imgError = (elem) ->
    console.warn "[inline-img] converting image back to link", elem.alt, elem, elem.outerHTML
    $ elem .parent!
        ..text ..attr \href
        ..addClass \p0ne_img_failed

p0ne.pendingMessages ||= []
p0ne.failedMessages ||= []
p0ne.chatPlugins ||= []

roles = <[ none dj bouncer manager cohost host _ volunteer ambassador leader admin ]>

module \chatShowPending, do
    require: <[ ChatHelper user Spinner ]>
    setup: ({replace}) ->
        replace ChatHelper, \sendChat, -> chatShowPending.sendChat ...

        # every 5min, remove pending messages older than 5min
        repeat 300_000ms, -> # 5min
            d = Date.now! - 300_000ms
            for i from (p0ne.pendingMessages.length - 1) to 0 by -1 when p0ne.pendingMessages[i].timestamp < d
                p0ne.pendingMessages[i].el?.remove!
                p0ne.pendingMessages.remove i
    update: ->
        ChatHelper.sendChat = -> chatShowPending.sendChat ...

    sendChat: (e) ->
        console.log "[sendChat]"
        return if @chatCommand e
        e = e.replace(/</g, "&lt;").replace(/>/g, "&gt;") # b.cleanTypedString() for the poor
        _$context.trigger \chat:send, e
        d = new Date
        if {'/me ': true, '/em ': true}[e.substr 0, 4]
            e .= substr 4
            type = "emote pending"
        else
            type = "message pending"

        e .= replace(/\b(https?:\/\/[^\s\)\]]+)([\.,\?\!"']?)/g, '<a href="$1" target="_blank">$1</a>$2')
        p0ne_chat do
            message: e
            type: type
            un: user.username
            uid: user.id
            timestamp: "#{d.getHours!}:#{d.getMinutes!}"
            pending: true
        return true


module \p0ne_chat_input, do
    require: <[ chat ]>
    setup: ->
        # clean up
        $ \.textarea_autoresize_helper .remove!
        $ \.chat-input-name .remove!

        css \p0ne_chat_input, '
            #chat-input {
                bottom: 7px;
                height: auto;
                background: none;
                min-height: 30px;
            }
            #chat-input-field {
                position: static;
                resize: none;
                overflow: hidden;
                margin-left: 8px;
                color: #eee;
                background: rgba(0, 24, 33, .7);
                box-shadow: inset 0 0 0 1px transparent;
                transition: box-shadow .2s ease-out;
                height: 16px; /* default before first resize */
            }
            #chat-input-field:focus {
                box-shadow: inset 0 0 0 1px #009cdd !important;
            }
            .muted .chat-input-name {
                display: none;
            }

            .textarea_autoresize_helper {
                display: none;
                white-space: pre-wrap;
                word-wrap: break-word;
            }

            #chat-input-field, .textarea_autoresize_helper {
                width: 295px;
                padding: 8px 10px 5px 10px;
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
        '

        chat.$chatInput.removeClass \focused
        $form = chat.$chatInputField.parent!
        chat.$chatInputField.remove!
        chat.$chatInputField.0 = chat.chatInput = $ "<textarea id='chat-input-field' maxlength=256>"
            .on \keydown, (e) ->
                chat.onKeyDown e
            .on \keyup, _.bind(chat.onKeyUp, chat)
            #.on \focus, _.bind(chat.onFocus, chat)
            #.on \blur, _.bind(chat.onBlur, chat)
            .on \input, ->
                content = chat.$chatInputField .val!
                content = content.replace(/\n/g, \<br>)
                textarea_autoresize_helper.html(content + \<br>)
                oldHeight = chat.$chatInputField .height!
                newHeight = textarea_autoresize_helper .height!
                return if oldHeight == newHeight
                console.log "[chat input] adjusting height"
                scrollTop = chat.$chatMessages.scrollTop!
                chat.$chatInputField
                    .css height: newHeight
                chat.$chatMessages
                    .css height: chat.$chatMessages.height! - newHeight + oldHeight
                    .scrollTop scrollTop + newHeight - oldHeight
            .appendTo $form
            .after do
                textarea_autoresize_helper = $ \<div> .addClass \textarea_autoresize_helper
            .0
        $name = $ \<span>
            .addClass \chat-input-name
            .text "#{user.username} "
            .insertAfter chat.$chatInputField

        <- requestAnimationFrame
        indent = 6px + $name.width!
        chat.$chatInputField       .css textIndent: indent
        textarea_autoresize_helper .css textIndent: indent

module \p0ne_chat_new_message_notification, require: <[ _$context ]>, callback:
    target: _$context
    event: \chat:receive
    callback: ->
        message.wasAtBottom ?= chatIsAtBottom!
        if not message.wasAtBottom
            $cm! .addClass \has-unread-message
            message.type += " unread"

module \p0ne_chat_plugins, do
    require: <[ _$context ]>
    setup: -> @enable!
    enable: ->
        _$context.onEarly \chat:receive, @cb
    disable: ->
        _$context.off \chat:receive, @cb
    cb: (message) -> # run plugins that modify chat messages
        message.wasAtBottom ?= chatIsAtBottom! # p0ne.saveChat also sets this

        # p0ne.chatPlugins
        for plugin in p0ne.chatPlugins
            message = plugin(message, t) || message

        # p0ne.chatLinkPlugins
        onload = ''
        onload = 'onload="chatScrollDown()"' if message.wasAtBottom
        message .= replace /<a (.+?)>((https?:\/\/)(?:www\.)?(([^\/]+).+?))<\/a>/, (all,pre,completeURL,protocol,domain,url)->
            &6 = onload
            for plugin in p0ne.chatLinkPlugins
                return that if plugin ...
            return all

# inline chat images & YT preview
chatWidth = 500px
module \chatInlineImages, do
    setup: ({add}) ->
        add p0ne.chatLinkPlugins, @plugin, {bound: true}
    plugin: (all,pre,completeURL,protocol,domain,url, onload) ->
        # images
        if @imgRegx[domain]
            [rgx, repl] = that
            img = url.replace(rgx, repl)
            if img != url
                console.log "[inline-img]", "[#plugin] #protocol#url ==> #protocol#img"
                return "<a #pre><img src='#protocol#img' class=p0ne_img #onload onerror='imgError(this)'></a>"

        # direct images
        if url.test /^[^\#\?]+(?:\.(?:jpg|jpeg|gif|png|webp|apng)(?:@\dx)?|image\.php)(?:\?.*|\#.*)?$/
            console.log "[inline-img]", "[direct] #url"
            return "<a #pre><img src='#url' class=p0ne_img #onload onerror='imgError(this)'></a>"

        console.log "[inline-img]", "NO MATCH FOR #url (probably isn't an image)"
        return false

    imgRegx:
        \imgur.com :       [/^imgur.com\/(?:r\/\w+\/)?(\w\w\w+)/g, "i.imgur.com/$1.gif"]
        \prntscrn.com :    [/^(prntscr.com\/\w+)(?:\/direct\/)?/g, "$1/direct"]
        \gyazo.com :       [/^gyazo.com\/\w+/g, "i.$&/direct"]
        \dropbox.com :     [/^dropbox.com(\/s\/[a-z0-9]*?\/[^\/\?#]*\.(?:jpg|jpeg|gif|png|webp|apng))/g, "dl.dropboxusercontent.com$1"]
        \pbs.twitter.com : [/^(pbs.twimg.com\/media\/\w+\.(?:jpg|jpeg|gif|png|webp|apng))(?:\:large|\:small)?/g, "$1:small"]
        \googleImg.com :   [/^google\.com\/imgres\?imgurl=(.+?)(?:&|$)/g, (,src) -> return decodeURIComponent url]
        \imageshack.com :  [/^imageshack\.com\/[fi]\/(\w\w)(\w+?)(\w)(?:\W|$)/, -> chatInlineImages.imageshackPlugin ...]
        \imageshack.us :   [/^imageshack\.us\/[fi]\/(\w\w)(\w+?)(\w)(?:\W|$)/, -> chatInlineImages.imageshackPlugin ...]

    imageshackPlugin: (,host,img,ext) ->
        ext = {j: \jpg, p: \png, g: \gif, b: \bmp, t: \tiff}[ext]
        return "https://imagizer.imageshack.us/a/img#{parseInt(host,36)}/#{~~(Math.random!*1000)}/#img.#ext"


/* image plugins using plugCubed API (credits go to TATDK / plugCubed) */
module \chatInlineImages_plugCubedAPI, do
    require: <[ chatInlineImages ]>
    setup: ->
        chatInlineImages.imgRegx <<<< @imgRegx
    imgRegx:
        \deviantart.com :    [/^[\w\-\.]+\.deviantart.com\/(?:art\/|[\w:\-]+#\/)[\w:\-]+/, "https://api.plugCubed.net/redirect/da/$&"]
        \fav.me :            [/^fav.me\/[\w:\-]+/, "https://api.plugCubed.net/redirect/da/$&"]
        \sta.sh :            [/^sta.sh\/[\w:\-]+/, "https://api.plugCubed.net/redirect/da/$&"]
        \gfycat.com :        [/^gfycat.com\/(.+)/, "https://api.plugCubed.net/redirect/gfycat/$1"]

/* meme-plugins inspired by http://userscripts.org/scripts/show/154915.html (mirror: http://userscripts-mirror.org/scripts/show/154915.html while userscripts.org is down) */
module \chatInlineImages_memes, do
    require: <[ chatInlineImages ]>
    setup: ->
        chatInlineImages.imgRegx <<<< @imgRegx
    imgRegx:
        \quickmeme.com :     [/^(?:m\.)?quickmeme\.com\/meme\/(\w+)/, "i.qkme.me/$1.jpg"]
        \qkme.me :           [/^(?:m\.)?qkme\.me\/(\w+)/, "i.qkme.me/$1.jpg"]
        \memegenerator.net : [/^memegenerator\.net\/instance\/(\d+)/, "http://cdn.memegenerator.net/instances/#{chatWidth}x/$1.jpg"]
        \imageflip.com :     [/^imgflip.com\/i\/(.+)/, "i.imgflip.com/$1.jpg"]
        \livememe.com :      [/^livememe.com\/(\w+)/, "i.lvme.me/$1.jpg"]
        \memedad.com :       [/^memedad.com\/meme\/(\d+)/, "memedad.com/memes/$1.jpg"]
        \makeameme.org :     [/^makeameme.org\/meme\/(.+)/, "makeameme.org/media/created/$1.jpg"]


module \chatYoutubeThumbnails, do
    setup: ({add}) ->
        add p0ne.chatLinkPlugins, @plugin
        @animate .= bind this
        @animate.isbound = true
    update: ->
        @animate .= bind this if not @animate.isbound
    plugin: (all,pre,completeURL,protocol,domain,url, onload) ->
        yt = /https?:\/\/(?:www\.)?(?:youtube(?:-nocookie)?\.com\/(?:[^\/]+\/.+\/|(?:v|embed|e)\/|.*(?:\?|&amp;)v=)|youtu\.be\/)([^"&?\/<>\s]{11})(?:&.*?|#.*?|)$/i
            .exec(url)
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
    callback:
        target: $ \#chat
        event: 'mouseenter mouseleave'
        args: [ \.p0ne_yt_img ]
        bound: true
        callback: (e) ->
            clearInterval @interval
            # assuming that `e.target` always refers to the .p0ne_yt_img
            id = e.parentElement.dataset.ytCid
            img = e.target
            if e.type == \mouseenter
                if id != @lastID
                    @frame = 1
                    @lastID = id
                img.style.backgroundImage = "url(http://i.ytimg.com/vi/#id/#{@frame}.jpg)"
                @interval = repeat 1_000ms, @animate
                console.log "[p0ne_yt_preview]", "started", e, id, @interval
                #ToDo show YT-options (grab, open, preview, [automute])
            else
                img.style.backgroundImage = "url(http://i.ytimg.com/vi/#id/0.jpg)"
                console.log "[p0ne_yt_preview]", "stopped"
                #ToDo hide YT-options
    animate: ->
        console.log "[p0ne_yt_preview]", "showing 'http://i.ytimg.com/vi/#id/#{@frame}.jpg'"
        @frame = (@frame % 3) + 1
        img.style.backgroundImage = "url(http://i.ytimg.com/vi/#id/#{@frame}.jpg)"
