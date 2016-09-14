/**
 * performance enhancements for plug.dj
 * the perfEmojify module also adds custom emoticons
 * @author jtbrinkmann aka. Brinkie Pie
 * @version 1.0
 * @license MIT License
 * @copyright (c) 2014 J.-T. Brinkmann
 */
module \jQueryPerf, do
    setup: ({replace}) ->
        core_rnotwhite = /\S+/g
        if \classList of document.body #ToDo is document.body.classList more performant?
            replace jQuery.fn, \addClass, -> return (value) ->
                /* performance improvements */
                if jQuery.isFunction(value)
                    for j in this
                        jQuery(this).addClass value.call(this, j, this.className)

                else if typeof value == \string and value
                    classes = value.match(core_rnotwhite) || []

                    i = 0
                    while elem = this[i++] when (not elem && console.error(\missingElem, \addClass, this) || !0) and elem.nodeType == 1
                        j = 0
                        while clazz = classes[j++]
                            elem.classList.add clazz
                return this

            replace jQuery.fn, \removeClass, -> return (value) ->
                /* performance improvements */
                if jQuery.isFunction(value)
                    for j in this
                        jQuery(this).removeClass value.call(this, j, this.className)

                else if value ~= null
                    i = 0
                    while elem = this[i++] when (not elem && console.error(\missingElem, \removeClass, this) || !0) and elem.nodeType == 1
                        j = elem.classList .length
                        while clazz = elem.classList[--j]
                            elem.classList.remove clazz
                else if typeof value == \string and value
                    classes = value.match(core_rnotwhite) || []

                    i = 0
                    while elem = this[i++] when (not elem && console.error(\missingElem, \removeClass, this) || !0) and elem.nodeType == 1
                        j = 0
                        while clazz = classes[j++]
                            elem.classList.remove clazz
                return this

            replace jQuery.fn, \hasClass, -> return (className) ->
                /* performance improvements */
                i = 0
                while elem = this[i++] when (not elem && console.error(\missingElem, \hasClass, this) || !0) and elem.nodeType == 1 and elem.classList.contains className
                        return true
                return false


module \perfEmojify,
    require: <[ emoticons ]>
    setup: ({replace}) ->
        # improves .emojify performance by 135% https://i.imgur.com/iBNICkX.png
        escapeReg = (e) ->
            return e .replace /([\\\.\+\*\?\[\^\]\$\(\)\{\}\=\!\<\>\|\:])/g, "\\$1"

        autoEmoteMap =
            \>:( : \angry
            \>XD : \astonished
            \:DX : \bowtie
            \</3 : \broken_heart
            \:$ : \confused
            X$: \confounded
            \:~( : \cry
            \:[ : \disappointed
            \:~[ : \disappointed_relieved
            XO: \dizzy_face
            \:| : \expressionless
            \8| : \flushed
            \:( : \frowning
            \:# : \grimacing
            \:D : \grinning
            \<3 : \heart
            "<3)": \heart_eyes
            "O:)": \innocent
            ":~)": \joy
            \:* : \kissing
            \:<3 : \kissing_heart
            \X<3 : \kissing_closed_eyes
            XD: \laughing
            \:O : \open_mouth
            \Z:| : \sleeping
            ":)": \smiley
            \:/ : \smirk
            T_T: \sob
            \:P : \stuck_out_tongue
            \X-P : \stuck_out_tongue_closed_eyes
            \;P : \stuck_out_tongue_winking_eye
            "B-)": \sunglasses
            \~:( : \sweat
            "~:)": \sweat_smile
            XC: \tired_face
            \>:/ : \unamused
            ";)": \wink
        autoEmoteMap <<<< emoticons.autoEmoteMap
        emoticons.autoEmoteMap = autoEmoteMap

        emoticons.update = ->
            # create reverse emoticon map
            @reverseMap = {}

            # create hashes (ternary tree)
            @hashes = {}
            for k,v of @map
                continue if @reverseMap[v]
                @reverseMap[v] = k
                h = @hashes
                for letter, i in k
                    l = h[letter]
                    if typeof h[letter] == \string
                        h[letter] = {_list: [l]}
                        h[letter][l[i+1]] = l if l.length > i
                    if l
                        h[letter] ||= {_list: []}
                    else
                        h[letter] = k
                        break
                    h[letter]._list = (h[letter]._list ++ k).sort!
                    h = h[letter]

            # fix autoEmote
            for k,v of @autoEmoteMap
                tmp = k .replace "<", "&LT;" .replace ">", "&GT;"
                if tmp != k
                    @autoEmoteMap[tmp] = v
                    delete @autoEmoteMap[k]

            # create regexp for autoEmote
            @regAutoEmote = //(^|\s|&nbsp;)(#{Object.keys(@autoEmoteMap) .map escapeReg .join "|"})(?=\s|$)//gi

        emoticons.update!
        replace emoticons, \emojify, -> return (str) ->
            return str
                .replace @regAutoEmote, (,pre,emote) ~> return "#pre:#{@autoEmoteMap[emote .toUpperCase!]}:"
                .replace /:(.*?):/g, (_, emote) ~>
                    if @map[emote]
                        return "<span class='emoji-glow'><span class='emoji emoji-#{@map[emote]}'></span></span>"
                    else
                        return _
        replace emoticons, \lookup, -> return (str) ->
            h = @hashes
            var res
            for letter, i in str
                h = h[letter]
                switch typeof h
                | \undefined
                    return []
                | \string
                    for i from i+1 til str.length when str[i] != h[i]
                        return []
                    return [h]
            return h._list