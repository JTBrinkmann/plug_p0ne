/**
 * performance enhancements for plug.dj
 * the perfEmojify module also adds custom emoticons
 *
 * @author jtbrinkmann aka. Brinkie Pie
 * @license MIT License
 * @copyright (c) 2015 J.-T. Brinkmann
 */
module \jQueryPerf, do
    setup: ({replace}) !->
        # improve performance by making $.fn.addClass, .removeClass and .hasClass
        # use the element's classList instead of the className attribute
        core_rnotwhite = /\S+/g
        if \classList of document.body #ToDo is document.body.classList more performant?
            replace jQuery.fn, \addClass, !-> return (value) !->
                if jQuery.isFunction(value)
                    for j in this
                        jQuery(this).addClass value.call(this, j, this.className)

                else if typeof value == \string and value
                    classes = value.match(core_rnotwhite) || []

                    i = 0
                    while elem = this[i++] when elem.nodeType == 1
                        j = 0
                        while clazz = classes[j++]
                            elem.classList.add clazz
                return this

            replace jQuery.fn, \removeClass, !-> return (value) !->
                if jQuery.isFunction(value)
                    for j in this
                        jQuery(this).removeClass value.call(this, j, this.className)

                else if value ~= null
                    i = 0
                    while elem = this[i++] when elem.nodeType == 1
                        j = elem.classList .length
                        while clazz = elem.classList[--j]
                            elem.classList.remove clazz
                else if typeof value == \string and value
                    classes = value.match(core_rnotwhite) || []

                    i = 0
                    while elem = this[i++] when elem.nodeType == 1
                        j = 0
                        while clazz = classes[j++]
                            elem.classList.remove clazz
                return this

            replace jQuery.fn, \hasClass, !-> return (className) !->
                i = 0
                while elem = this[i++] when elem.classList.contains(className)
                    return true
                return false


module \perfEmojify, do
    require: <[ emoticons ]>
    setup: ({replace}) !->
        # new .emojify is ca. 100x faster https://i.imgur.com/iBNICkX.png
        #= prepare replacement =

        escapeReg = (e) !->
            return e .replace /([\\\.\+\*\?\[\^\]\$\(\)\{\}\=\!\<\>\|\:])/g, "\\$1"

        # list of emotices that will be automatically converted
        # (without being surrounded by colons)
        # this is the original, unmodified map from plug.dj
        emoticons.autoEmoteMap =
            /*NOTE: since plug_p0ne v1.6.3, emoticons are case-sensitive */
            ">:(" : \angry
            ">XD" : \astonished
            ":DX" : \bowtie
            "</3" : \broken_heart
            ":$"  : \confused
            "X$"  : \confounded
            ":~(" : \cry
            ":["  : \disappointed
            ":~[" : \disappointed_relieved
            "XO"  : \dizzy_face
            ":|"  : \expressionless
            "8|"  : \flushed
            ":("  : \frowning
            ":#"  : \grimacing
            ":D"  : \grinning
            "<3"  : \heart
            "<3)" : \heart_eyes
            "O:)" : \innocent
            ":~)" : \joy
            ":*"  : \kissing
            ":<3" : \kissing_heart
            "X<3" : \kissing_closed_eyes
            "XD"  : \laughing
            ":O"  : \open_mouth
            "Z:|" : \sleeping
            ":)"  : \smiley
            ":/"  : \smirk
            "T_T" : \sob
            ":P"  : \stuck_out_tongue
            "X-P" : \stuck_out_tongue_closed_eyes
            ";P"  : \stuck_out_tongue_winking_eye
            "B-)" : \sunglasses
            "~:(" : \sweat
            "~:)" : \sweat_smile
            "XC"  : \tired_face
            ">:/" : \unamused
            ";)"  : \wink

        # update function, to create caches and regexps for improved performance
        # call this everytime the autoEmoteMap is updated
        emoticons.update = !->
            # create reverse emoticon map
            @reverseMap = {}

            # create trie (aka. prefix tree)
            @trie = {}
            for k,v of @map
                continue if @reverseMap[v]
                @reverseMap[v] = k
                h = @trie
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

            # fix autoEmote (so we don't have to replace it in the input text every time)
            for k,v of @autoEmoteMap when k != (tmp = k .replace(/</g, "&lt;") .replace(/>/g, "&gt;"))
                @autoEmoteMap[tmp] = v
                delete @autoEmoteMap[k]

            # create regexp for autoEmote
            @regAutoEmote = //(^|\s|&nbsp;)(#{Object.keys(@autoEmoteMap) .map(escapeReg) .join "|"})(?=\s|$)//g

        emoticons.update!

        # replace plug.dj functions
        replace emoticons, \emojify, !-> return (str) !->
            lastWasEmote = false
            return str
                .replace /:(.*?)(?=:)|:(.*)$/g, (_, emote, post) !~>
                    if (p = typeof post != \string) and not lastWasEmote and @map[emote]
                        lastWasEmote := true
                        return "<span class='emoji-glow'><span class='emoji emoji-#{@map[emote]}'></span></span>"
                    else
                        lastWasEmote_ = lastWasEmote
                        lastWasEmote := false
                        return "#{if lastWasEmote_ then '' else ':'}#{if p then emote else post}"
                .replace @regAutoEmote, (,pre,emote) !~> return "#pre:#{@autoEmoteMap[emote]}:"

        replace emoticons, \lookup, !-> return (str) !->
            # walk through the trie, letter by letter of the input
            h = @trie
            var res
            for letter, i in str
                h = h[letter]
                switch typeof h
                | \undefined
                    # no match was found
                    return []
                | \string
                    # if only one result is left, check if the input differs
                    for i from i+1 til str.length when str[i] != h[i]
                        return []
                    # if it doesn't differ, return the only result
                    return [h]
            # return the list of results
            return h._list