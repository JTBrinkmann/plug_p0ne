/**
 * ponify chat - a script to ponify some words in the chat on plug.dj
 * Text ponification based on http://pterocorn.blogspot.dk/2011/10/ponify.html
 * @author jtbrinkmann aka. Brinkie Pie
 * @version 1.0
 * @license MIT License
 * @copyright (c) 2014 J.-T. Brinkmann
 */

/*####################################
#            PONIFY CHAT             #
####################################*/
module ||= (name, {setup, require}) ->
    # module() for the poor
    if not window[name]
        target.on event, -> window[name] ...
    window[name] = callback
requireHelper ||= ({id, test, fallback}:a) ->
    if typeof a == \function
        test = a
    module = require.s.contexts._.defined[id] if id
    if module and test module
        module.id ||= id
        return module
    else
        for id, module of require.s.contexts._.defined when module
            if test module, id
                module.id ?= id
                console.warn "[requireHelper] module '#{module.name}' updated to ID '#id'"
                return module
        return fallback

requireHelper do
    name: \emoticons
    test: (.emojify)

module \ponify, do
    optional: <[ emoticons ]>
    /*== TEXT ==*/
    map:
        # "america":    "amareica"
        "anybody":      "anypony"
        "anyone":       "anypony"
        "ass":          "flank"
        "asses":        "flanks"
        "boner":        "wingboner"
        "boy":          "colt"
        "boyfriend":    "coltfriend"
        "boyfriends":   "coltfriends"
        "boys":         "colts"
        "bro fist":     "brohoof"
        "bro-fist":     "brohoof"
        "butt":         "flank"
        "butthurt":     "saddle-sore"
        "butts":        "flanks"
        "child":        "foal"
        "children":     "foals"
        "cowboy":       "cowpony"
        "cowboys":      "cowponies"
        "cowgirl":      "cowpony"
        "cowgirls":     "cowponies"
        "doctor who":   "doctor whooves"
        "dr who":       "dr whooves"
        "dr. who":      "dr. whooves"
        "everybody":    "everypony"
        "everyone":     "everypony"
        "fap":          "clop"
        "faps":         "clops"
        "foot":         "hoof"
        "feet":         "hooves"
        "folks":        "foalks"
        "fool":         "foal"
        "foolish":      "foalish"
        "germany":      "germaneigh"
        "gentleman":    "gentlecolt"
        "gentlemen":    "gentlecolts"
        "girl":         "filly"
        "girls":        "fillies"
        "girlfriend":   "fillyfriend"
        "girlfriends":  "fillyfriends"
        "halloween":    "nightmare night"
        "hand":         "hoof"
        "hands":        "hooves"
        "handed":       "hoofed"
        "handedly":     "hoofedly"
        "handers":      "hoofers"
        "handmade":     "hoofmade"
        "hey":          "hay"
        "high-five":    "hoof-five"
        "highfive":     "hoof-five"
        "human":        "pony"
        "humans":       "ponies"
        "ladies":       "fillies"
        # "lobby":      "shed"
        "main":         "mane"
        "man":          "stallion"
        "men":          "stallions"
        "manhattan":    "manehattan"
        "marathon":     "mareathon"
        "miracle":      "mareacle"
        "miracles":     "mareacles"
        "money":        "bits"
        "naysayer":     "neighsayer"
        "no one else":  "nopony else"
        "no-one else":  "nopony else"
        "noone else":   "nopony else"
        "nobody":       "nopony"
        "nottingham":   "trottingham"
        "old-timer":    "old-trotter"
        "people":       "ponies"
        "person":       "pony"
        "persons":      "ponies"
        "philadelphia": "fillydelphia"
        "somebody":     "somepony"
        "someone":      "somepony"
        "stalingrad":   "stalliongrad"
        "sure as hell": "sure as hay"
        "tattoo":       "cutie mark"
        "tattoos":      "cutie mark"
        "da heck":      "da hay"
        "the heck":     "the hay"
        "the hell":     "the hay"
        "troll":        "parasprite"
        "trolls":       "parasprites"
        "trolled":      "parasprited"
        "trolling":     "paraspriting"
        "trollable":    "paraspritable"
        "woman":        "mare"
        "women":        "mares"
        "confound those dover boys":    "confound these ponies"


    ponifyNode: (node) ->
        #console.log "ponifying", node
        if node.nodeType != 3
            for n in node.childNodes || []
                @ponifyNode n

        else
            str = node.nodeValue
            hasReplacement = false
            replacement = null
            lastPos = 0
            str.replace @regexp, (s, i) ->
                w = @map[s.toLowerCase!]
                r = ""

                if not replacement
                    replacement := document.createElement \span

                /*preserve upper/lower case*/
                l = s.length <? w.length
                for o from 0 til l
                    if s[o].toLowerCase! != s[o]
                        r += w[o].toUpperCase!
                    else
                        r += w[o]

                r += w.substr l

                if str.substring(lastPos, i)
                    replacement.appendChild document.createTextNode that
                document.createElement \abbr
                    ..textContent = "#r"
                    ..classList.add \ponified
                    ..title = s
                    replacement.appendChild ..

                lastPos := i + s.length
                console.log "replaced '#s' with '#r'", node

            if replacement
                replacement.appendChild document.createTextNode str.substr(lastPos)
                node.parentNode?.replaceChild replacement, node

    /*== EMOTICONS ==*/
    autoEmotiponies:
        "8)": "http://www.bronyland.com/wp-includes/images/smilies/emotiponies/rainbowdetermined2.png"
        ":(": "http://www.bronyland.com/wp-includes/images/smilies/emotiponies/fluttershysad.png"
        ":)": "http://www.bronyland.com/wp-includes/images/smilies/emotiponies/twilightsmile.png"
        ":?": "http://www.bronyland.com/wp-includes/images/smilies/emotiponies/rainbowhuh.png"
        ":B": "http://www.bronyland.com/wp-includes/images/smilies/emotiponies/twistnerd.png"
        ":D": "http://www.bronyland.com/wp-includes/images/smilies/emotiponies/pinkiehappy.png"
        ":S": "http://www.bronyland.com/wp-includes/images/smilies/emotiponies/unsuresweetie.png"
        ":o": "http://www.bronyland.com/wp-includes/images/smilies/emotiponies/pinkiegasp.png"
        ":x": "http://www.bronyland.com/wp-includes/images/smilies/emotiponies/fluttershbad.png"
        ":|": "http://www.bronyland.com/wp-includes/images/smilies/emotiponies/ajbemused.png"
        ";)": "http://www.bronyland.com/wp-includes/images/smilies/emotiponies/raritywink.png"
        "<3": "http://www.bronyland.com/wp-includes/images/smilies/emotiponies/heart.png"
        "B)": "http://www.bronyland.com/wp-includes/images/smilies/emotiponies/coolphoto.png"
        "D:": "http://www.bronyland.com/wp-includes/images/smilies/emotiponies/raritydespair.png"
    emotiponies:
        "???": "http://www.bronyland.com/wp-includes/images/smilies/emotiponies/applejackconfused.png"
        aj: "http://www.bronyland.com/wp-includes/images/smilies/emotiponies/ajsmug.png"
        applebloom: "http://www.bronyland.com/wp-includes/images/smilies/emotiponies/applecry.png"
        applejack: "http://www.bronyland.com/wp-includes/images/smilies/emotiponies/ajsmug.png"
        blush: "http://www.bronyland.com/wp-includes/images/smilies/emotiponies/twilightblush.png"
        cool: "http://www.bronyland.com/wp-includes/images/smilies/emotiponies/rainbowdetermined2.png"
        cry: "http://www.bronyland.com/wp-includes/images/smilies/emotiponies/raritycry.png"
        derp: "http://www.bronyland.com/wp-includes/images/smilies/emotiponies/derpyderp2.png"
        derpy: "http://www.bronyland.com/wp-includes/images/smilies/emotiponies/derpytongue2.png"
        eek: "http://www.bronyland.com/wp-includes/images/smilies/emotiponies/fluttershbad.png"
        evil: "http://www.bronyland.com/wp-includes/images/smilies/emotiponies/pinkiecrazy.png"
        fluttershy: "http://www.bronyland.com/wp-includes/images/smilies/emotiponies/fluttershysad.png"
        fs: "http://www.bronyland.com/wp-includes/images/smilies/emotiponies/fluttershysad.png"
        idea: "http://www.bronyland.com/wp-includes/images/smilies/emotiponies/raritystarry.png"
        lol: "http://www.bronyland.com/wp-includes/images/smilies/emotiponies/rainbowlaugh.png"
        loveme: "http://www.bronyland.com/wp-includes/images/smilies/emotiponies/flutterrage.png"
        mad: "http://www.bronyland.com/wp-includes/images/smilies/emotiponies/twilightangry2.png"
        mrgreen: "http://www.bronyland.com/wp-includes/images/smilies/emotiponies/pinkiesick.png"
        oops: "http://www.bronyland.com/wp-includes/images/smilies/emotiponies/twilightblush.png"
        photofinish: "http://www.bronyland.com/wp-includes/images/smilies/emotiponies/coolphoto.png"
        pinkie: "http://www.bronyland.com/wp-includes/images/smilies/emotiponies/pinkiesmile.png"
        pinkiepie: "http://www.bronyland.com/wp-includes/images/smilies/emotiponies/pinkiesmile.png"
        rage: "http://www.bronyland.com/wp-includes/images/smilies/emotiponies/flutterrage.png"
        rainbowdash: "http://www.bronyland.com/wp-includes/images/smilies/emotiponies/rainbowkiss.png"
        rarity: "http://www.bronyland.com/wp-includes/images/smilies/emotiponies/raritywink.png"
        razz: "http://www.bronyland.com/wp-includes/images/smilies/emotiponies/rainbowwild.png"
        rd: "http://www.bronyland.com/wp-includes/images/smilies/emotiponies/rainbowkiss.png"
        roll: "http://www.bronyland.com/wp-includes/images/smilies/emotiponies/applejackunsure.png"
        sad: "http://www.bronyland.com/wp-includes/images/smilies/emotiponies/fluttershysad.png"
        scootaloo: "http://www.bronyland.com/wp-includes/images/smilies/emotiponies/scootangel.png"
        shock: "http://www.bronyland.com/wp-includes/images/smilies/emotiponies/pinkiegasp.png"
        sweetie: "http://www.bronyland.com/wp-includes/images/smilies/emotiponies/unsuresweetie.png"
        sweetiebelle: "http://www.bronyland.com/wp-includes/images/smilies/emotiponies/unsuresweetie.png"
        trixie: "http://www.bronyland.com/wp-includes/images/smilies/emotiponies/trixieshiftright.png"
        trixie2: "http://www.bronyland.com/wp-includes/images/smilies/emotiponies/trixieshiftleft.png"
        trixieleft: "http://www.bronyland.com/wp-includes/images/smilies/emotiponies/trixieshiftleft.png"
        twi: "http://www.bronyland.com/wp-includes/images/smilies/emotiponies/twilightsmile.png"
        twilight: "http://www.bronyland.com/wp-includes/images/smilies/emotiponies/twilightsmile.png"
        twist: "http://www.bronyland.com/wp-includes/images/smilies/emotiponies/twistnerd.png"
        twisted: "http://www.bronyland.com/wp-includes/images/smilies/emotiponies/pinkiecrazy.png"
        wink: "http://www.bronyland.com/wp-includes/images/smilies/emotiponies/raritywink.png"


    setup: ({addListener, replace}) ->
        @regexp = new RegExp "\\b(?:#{Object.keys @map .join '|' .replace(/\s+/g,'\\s*')})\\b", \gi
        addListener do
            target: API
            event: \chat
            callback: ({cid}) ~>
                @ponifyNode $("\#chat-messages > .message[data-cid=#{cid}] .text").0
        if emoticons?
            aEM = ^^emoticons.autoEmoteMap #|| {}
            for emote, url of @autoEmotiponies
                key = url .replace /.*\/(\w+)\..+/, '$1'
                aEM[emote] = key
                @emotiponies[key] = url
            replace emoticons, \autoEmoteMap, aEM

            m = ^^emoticons.map
            ponyCSS = """
                .ponimoticon { width: 27px; height: 27px }
                .chat-suggestion-item .ponimoticon { margin-left: -5px }
                .emoji-glow { width: auto; height: auto }
                .emoji { position: static; display: inline-block }
            \n"""
            reversedMap = {}
            for emote, url of @emotiponies
                if reversedMap[url]
                    m[emote] = "#{reversedMap[url]} ponimoticon" # hax to add .ponimoticon class
                else
                    reversedMap[url] = emote
                    m[emote] = "#emote ponimoticon" # hax to add .ponimoticon class
                ponyCSS += ".emoji-#emote { background: url(#url) }\n"
            css \ponify, ponyCSS
            replace emoticons, \map, m
            emoticons.update?!
    disable: ->
        emoticons.update?!
