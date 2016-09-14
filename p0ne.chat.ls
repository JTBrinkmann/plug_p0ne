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


chatWidth = 328px
roles = <[ none dj bouncer manager cohost host ambassador ambassador ambassador admin ]>


window.imgError = (elem) ->
    console.warn "[inline-img] converting image back to link", elem.alt, elem, elem.outerHTML
    $ elem .parent!
        ..text ..attr \href
        ..addClass \p0ne_img_failed


module \p0ne_chat_input, do
    require: <[ chat user ]>
    optional: <[ user_ _$context PopoutListener ]>
    displayName: "Better Chat Input"
    settings: true
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

            .autoresize_helper {
                display: none;
                white-space: pre-wrap;
                word-wrap: break-word;
            }

            #chat-input-field, .autoresize_helper {
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
            /*fix chat-messages size*/
            #chat-messages {
                height: auto !important;
                bottom: 45px;
            }
        '

        var $form, $name, $autoresize_helper, chat
        chat = PopoutView.chat || window.chat

        # back up elements that are to be removed
        @cIF_ = chat.$chatInputField.0


        # fix permanent focus class
        chat.$chatInput.removeClass \focused

        # use $name's width to add proper indent to the input field
        @fixIndent = -> requestAnimationFrame -> # wait an animation frame so $name is properly added to the DOM
            indent = 6px + $name.width!
            chat.$chatInputField .css textIndent: indent
            $autoresize_helper   .css textIndent: indent

        # add new input text-area
        addListener API, \popout:open, patchInput = ~>

            chat := PopoutView.chat || window.chat
            $form := chat.$chatInputField.parent!
            chat.$chatInputField.remove!
            chat.$chatInputField.0 = chat.chatInput = $create "<textarea id='chat-input-field' maxlength=256>"
                .prop \tabIndex, 1
                # add DOM event Listeners from original input field (not using .bind to allow custom chat.onKey* functions)
                .on \keydown, (e) ->
                    chat.onKeyDown e
                .on \keyup, (e) ->
                    chat.onKeyUp e
                #.on \focus, _.bind(chat.onFocus, chat)
                #.on \blur, _.bind(chat.onBlur, chat)

                # add event listeners for autoresizing
                .on 'input', ->
                    content = chat.$chatInputField .val!
                    if (content2 = content.replace(/\n/g, "")) != content
                        chat.$chatInputField .val (content=content2)
                    $autoresize_helper.html(content + \<br>)
                    oldHeight = chat.$chatInputField .height!
                    newHeight = $autoresize_helper .height!
                    return if oldHeight == newHeight
                    console.log "[chat input] adjusting height"
                    scrollTop = chat.$chatMessages.scrollTop!
                    chat.$chatInputField
                        .css height: newHeight
                    chat.$chatMessages
                        .css bottom: newHeight + 30px
                        .scrollTop scrollTop + newHeight - oldHeight
                .appendTo $form
                .after do
                    $autoresize_helper := $create \<div> .addClass \autoresize_helper
                .0

            # username field
            $name := $create \<span>
                .addClass \chat-input-name
                .text "#{user.username} "
                .insertAfter chat.$chatInputField

            @fixIndent!

        patchInput!
        sleep 2s *s_to_ms, @fixIndent

        if _$context
            addListener _$context, \chat:send, ->
                chat.$chatInputField .trigger \input

        if user_?
            addListener user_, \change:username, @fixIndent


    disable: ->
        chat.$chatInputField = $ @cIF_
            .appendTo $cm!.parent!.find \.chat-input-form

module \chatPlugin, do
    require: <[ _$context ]>
    setup: ->
        p0ne.chatMessagePlugins ||= []
        p0ne.chatLinkPlugins ||= []
        _$context .onEarly \chat:receive, @cb
    disable: ->
        _$context .off \chat:receive, @cb
    cb: (msg) -> # run plugins that modify chat msgs
        msg.wasAtBottom ?= chatIsAtBottom! # p0ne.saveChat also sets this

        _$context .trigger \chat:plugin, msg
        API .trigger \chat:plugin, msg

        for plugin in p0ne.chatMessagePlugins
            try
                msg.message = that if plugin(msg.message, msg)
            catch err
                console.error "[p0ne] error while processing chat link plugin", plugin, err

        # p0ne.chatLinkPlugins
        if msg.wasAtBottom
            onload = 'onload="chatScrollDown()"'
        else
            onload = ''
        msg.message .= replace /<a (.+?)>((https?:\/\/)(?:www\.)?(([^\/]+).+?))<\/a>/, (all,pre,completeURL,protocol,domain,url)->
            &6 = onload
            &7 = msg
            for plugin in p0ne.chatLinkPlugins
                try
                    return that if plugin ...
                catch err
                    console.error "[p0ne] error while processing chat link plugin", plugin, err
            return all


/*####################################
#          MESSAGE CLASSES           #
####################################*/
module \chatMessageClasses, do
    optional: <[ users ]>
    require: <[ chatPlugin ]>
    setup: ({addListener}) ->
        $cm?! .children! .each ->
            if uid = this.dataset.cid
                uid .= substr(0, 7)
                if fromUser = getUser uid and fromUser.role != -1
                    fromRole = roles[if fromUser.gRole then fromUser.gRole * 5 else fromUser.role]
                else
                    fromRole = \ghost

                $ this
                    .addClass "fromID-#{uid}"
                    .addClass "from-#{fromRole}"

        addListener _$context, \chat:plugin, ({uid}:message) ->
            fromUser = getUser uid
            if fromUser
                fromRole = roles[if fromUser.gRole then fromUser.gRole * 5 else fromUser.role]
            else
                fromRole = \ghost
            message.type += " fromID-#{uid} from-#{fromRole}"

# inline chat images & YT preview
/*####################################
#           INLINE  IMAGES           #
#             YT PREVIEW             #
####################################*/
chatWidth = 500px
module \chatInlineImages, do
    require: <[ chatPlugin ]>
    setup: ({add}) ->
        add p0ne.chatLinkPlugins, (all,pre,completeURL,protocol,domain,url, onload) ~>
            # images
            if @imgRegx[domain]
                [rgx, repl] = that
                img = url.replace(rgx, repl)
                if img != url
                    console.log "[inline-img]", "[#plugin] #protocol#url ==> #protocol#img"
                    return "<a #pre><img src='#protocol#img' class=p0ne_img #onload onerror='imgError(this)'></a>"

            # direct images
            if /^[^\#\?]+(?:\.(?:jpg|jpeg|gif|png|webp|apng)(?:@\dx)?|image\.php)(?:\?.*|\#.*)?$/i .test url
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

        /* meme-plugins inspired by http://userscripts.org/scripts/show/154915.html (mirror: http://userscripts-mirror.org/scripts/show/154915.html while userscripts.org is down) */
        \quickmeme.com :     [/^(?:m\.)?quickmeme\.com\/meme\/(\w+)/, "i.qkme.me/$1.jpg"]
        \qkme.me :           [/^(?:m\.)?qkme\.me\/(\w+)/, "i.qkme.me/$1.jpg"]
        \memegenerator.net : [/^memegenerator\.net\/instance\/(\d+)/, "http://cdn.memegenerator.net/instances/#{chatWidth}x/$1.jpg"]
        \imageflip.com :     [/^imgflip.com\/i\/(.+)/, "i.imgflip.com/$1.jpg"]
        \livememe.com :      [/^livememe.com\/(\w+)/, "i.lvme.me/$1.jpg"]
        \memedad.com :       [/^memedad.com\/meme\/(\d+)/, "memedad.com/memes/$1.jpg"]
        \makeameme.org :     [/^makeameme.org\/meme\/(.+)/, "makeameme.org/media/created/$1.jpg"]

    imageshackPlugin: (,host,img,ext) ->
        ext = {j: \jpg, p: \png, g: \gif, b: \bmp, t: \tiff}[ext]
        return "https://imagizer.imageshack.us/a/img#{parseInt(host,36)}/#{~~(Math.random!*1000)}/#img.#ext"


# /* image plugins using plugCubed API (credits go to TATDK / plugCubed) */
# module \chatInlineImages_plugCubedAPI, do
#    require: <[ chatInlineImages ]>
#    setup: ->
#        chatInlineImages.imgRegx <<<< @imgRegx
#    imgRegx:
#        \deviantart.com :    [/^[\w\-\.]+\.deviantart.com\/(?:art\/|[\w:\-]+#\/)[\w:\-]+/, "https://api.plugCubed.net/redirect/da/$&"]
#        \fav.me :            [/^fav.me\/[\w:\-]+/, "https://api.plugCubed.net/redirect/da/$&"]
#        \sta.sh :            [/^sta.sh\/[\w:\-]+/, "https://api.plugCubed.net/redirect/da/$&"]
#        \gfycat.com :        [/^gfycat.com\/(.+)/, "https://api.plugCubed.net/redirect/gfycat/$1"]


module \chatYoutubeThumbnails, do
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
