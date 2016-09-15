/**
 * ponify chat - a script to ponify some words in the chat on plug.dj
 * Text ponification based on http://pterocorn.blogspot.dk/2011/10/ponify.html
 *
 * @author jtbrinkmann aka. Brinkie Pie
 * @license MIT License
 * @copyright (c) 2015 J.-T. Brinkmann
 */

/*####################################
#            PONIFY CHAT             #
####################################*/
module \ponify, do
    optional: <[ emoticons ]>
    displayName: 'Ponify Chat'
    settings: \pony
    help: '''
        Ponify the chat! (replace words like "anyone" with "anypony")
        Replaced words will be underlined. Move your cursor over the word to see it's original.

        It also replaces some of the emoticons with pony emoticons.
    '''
    disabled: true

    /*== TEXT ==*/
    map:
        # "america":    "amareica" # this one was driving me CRAZY
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
        "disappoint":   "disappony"
        "disappointed": "disappony"
        "disappointment": "disapponyment"
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
        #"human":        "pony"
        #"humans":       "ponies"
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
        "null":         "nullpony"
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


    ponifyMsg: (msg) !->
        msg.message .= replaceSansHTML @regexp, (_, pronoun, s, possessive, i) !~>
            w = @map[s.toLowerCase!]
            r = ""

            /*preserve upper/lower case*/
            lastUpperCaseLetters = 0
            l = s.length <? w.length
            for o from 0 til l
                if s[o].toLowerCase! != s[o]
                    r += w[o].toUpperCase!
                    lastUpperCaseLetters++
                else
                    r += w[o]
                    lastUpperCaseLetters = 0
            if w.length >= s.length and lastUpperCaseLetters >= 3
                r += w.substr(l) .toUpperCase!
            else
                r += w.substr(l)

            r = "<abbr class=ponified title='#s'>#r</abbr>"

            if pronoun
                if "aeioujyh".has(w.0)
                    r = "an #r"
                else
                    r = "a #r"

            if possessive
                if "szx".has(w[*-1])
                    r += "' "
                else
                    r += "'s "

            console.log "replaced '#s' with '#r'", msg.cid
            return r


    /*== EMOTICONS ==*/
    /* images from bronyland.com (reuploaded to imgur to not spam the console with warnings, because bronyland.com doesn't support HTTPS) */
    autoEmotiponies:
        '8)': name: \rainbowdetermined2, url: "https://i.imgur.com/WFa3vKA.png"
        ':(': name: \fluttershysad     , url: "https://i.imgur.com/6L0bpWd.png"
        ':)': name: \twilightsmile     , url: "https://i.imgur.com/LDoxwfg.png"
        ':?': name: \rainbowhuh        , url: "https://i.imgur.com/te0Mnih.png"
        ':B': name: \twistnerd         , url: "https://i.imgur.com/57VFd38.png"
        ':D': name: \pinkiehappy       , url: "https://i.imgur.com/uFwZib6.png"
        ':S': name: \unsuresweetie     , url: "https://i.imgur.com/EATu0iu.png"
        ':O': name: \pinkiegasp        , url: "https://i.imgur.com/b9G2kaz.png"
        ':X': name: \fluttershybad     , url: "https://i.imgur.com/mnJHnsv.png"
        ':|': name: \ajbemused         , url: "https://i.imgur.com/8SLymiw.png"
        ';)': name: \raritywink        , url: "https://i.imgur.com/9fo7ZW3.png"
        '<3': name: \heart             , url: "https://i.imgur.com/aPBXLob.png"
        'B)': name: \coolphoto         , url: "https://i.imgur.com/QDgMyIZ.png"
        'D:': name: \raritydespair     , url: "https://i.imgur.com/og1FoWN.png"
        #'???': name: \applejackconfused, url: "https://i.imgur.com/c4moR6o.png"

    emotiponies:
        aj:             "https://i.imgur.com/nnYMw87.png"
        applebloom:     "https://i.imgur.com/vAdPBJj.png"
        applejack:      "https://i.imgur.com/nnYMw87.png"
        blush:          "https://i.imgur.com/IpxwJ5c.png"
        cool:           "https://i.imgur.com/WFa3vKA.png"
        cry:            "https://i.imgur.com/fkYW4BG.png"
        derp:           "https://i.imgur.com/Y00vqcH.png"
        derpy:          "https://i.imgur.com/h6GdxHo.png"
        eek:            "https://i.imgur.com/mnJHnsv.png"
        evil:           "https://i.imgur.com/I8CNeRx.png"
        fluttershy:     "https://i.imgur.com/6L0bpWd.png"
        fs:             "https://i.imgur.com/6L0bpWd.png"
        idea:           "https://i.imgur.com/aitjp1R.png"
        lol:            "https://i.imgur.com/XVy41jX.png"
        loveme:         "https://i.imgur.com/H81S9x0.png"
        mad:            "https://i.imgur.com/taFXcWV.png"
        mrgreen:        "https://i.imgur.com/IkInelN.png"
        oops:           "https://i.imgur.com/IpxwJ5c.png"
        photofinish:    "https://i.imgur.com/QDgMyIZ.png"
        pinkie:         "https://i.imgur.com/tpQZaW4.png"
        pinkiepie:      "https://i.imgur.com/tpQZaW4.png"
        rage:           "https://i.imgur.com/H81S9x0.png"
        rainbowdash:    "https://i.imgur.com/xglySrD.png"
        rarity:         "https://i.imgur.com/9fo7ZW3.png"
        razz:           "https://i.imgur.com/f8SgNBw.png"
        rd:             "https://i.imgur.com/xglySrD.png"
        roll:           "https://i.imgur.com/JogpKQo.png"
        sad:            "https://i.imgur.com/6L0bpWd.png"
        scootaloo:      "https://i.imgur.com/9zVXkyg.png"
        shock:          "https://i.imgur.com/b9G2kaz.png"
        sweetie:        "https://i.imgur.com/EATu0iu.png"
        sweetiebelle:   "https://i.imgur.com/EATu0iu.png"
        trixie:         "https://i.imgur.com/2QEmT8y.png"
        trixie2:        "https://i.imgur.com/HWW2D6b.png"
        trixieleft:     "https://i.imgur.com/HWW2D6b.png"
        twi:            "https://i.imgur.com/LDoxwfg.png"
        twilight:       "https://i.imgur.com/LDoxwfg.png"
        twist:          "https://i.imgur.com/57VFd38.png"
        twisted:        "https://i.imgur.com/I8CNeRx.png"
        wink:           "https://i.imgur.com/9fo7ZW3.png"


    setup: ({addListener, replace, css}) !->
        @regexp = //
            \b(an?\s+)?(#{Object.keys @map .join '|' .replace(/\s+/g,'\\s*')})('s?)?\b
        //gi
        addListener API, \chat:plugin, @~ponifyMsg
        if emoticons?
            aEM = {}<<<<emoticons.autoEmoteMap
            for emote, {name, url} of @autoEmotiponies
                aEM[emote] = name
                @emotiponies[name] = url
            replace emoticons, \autoEmoteMap, !-> return aEM

            m = ^^emoticons.map
            ponyCSS = """
                .ponimoticon { width: 27px; height: 27px }
                .chat-suggestion-item .ponimoticon { margin-left: -5px }
                .emoji-glow { width: auto; height: auto }
                .emoji { position: static; display: inline-block }

            """
            reversedMap = {}
            for emote, url of @emotiponies
                if reversedMap[url]
                    m[emote] = "#{reversedMap[url]} ponimoticon" # hax to add .ponimoticon class
                else
                    reversedMap[url] = emote
                    m[emote] = "#emote ponimoticon" # hax to add .ponimoticon class
                ponyCSS += ".emoji-#emote { background: url(#url) }\n"
            css \ponify, ponyCSS
            replace emoticons, \map, !-> return m
            emoticons.update?!
    disable: !->
        emoticons.update?!



module \ponifiedLang, do
    require: <[ Lang ]>
    disabled: true
    displayName: "Ponified Text"
    settings: \pony
    setup: ({replace, css}) !->
        # ponies
        replaceMap =
            people: 'ponies'
            People: 'Ponies'
            user: 'pony'
            Nobody: 'Nopony'
            woots: "Squees"
            Woot: "Squee"
            Points: "Bits"

            "Resident DJs": 'Horse Famous'
            "Resident DJ": 'Horse Famous'
            Bouncer: 'Royal Guard'
            Manager: 'Royal Guard Captain'
            "Co-Host": 'Alicorn'
            Host: 'Alicorn Princess'
            staff: 'VIP Pony List'
        regx = //\b(#{Object.keys replaceMap .join '|'})(s?|)\b//g
        console.groupCollapsed "[ponifiedLang] dynamically replacing words"
        for ,group of Lang
            for k,v of group when k[*-1] != "_" and v
                v2 = v.replace regx, (,a, b) !->
                    return replaceMap[a]+b
                if v != v2
                    replace group, k, !-> return v2
                    console.log "\treplacing '#v' with '#{group[k]}'"
        console.groupEnd!

        # roles
        replace Lang.roles, \none, !-> return "Mudpony"
        #replace Lang.roles, \dj, !-> return "Horse Famous"
        #replace Lang.roles, \bouncer, !-> return "Royal Guard"
        #replace Lang.roles, \manager, !-> return "Royal Guard Captain"
        #replace Lang.roles, \cohost, !-> return "Alicorn"
        #replace Lang.roles, \host, !-> return "Alicorn Princess"
        #replace Lang.moderation, \staffNone, !-> return "removed %NAME% from the VIP Pony List."
        replace Lang.moderation, \staffDJ, !-> return "made %NAME% Horse Famous."
        replace Lang.moderation, \staffBouncer, !-> return "hired %NAME% as a Royal Guard."
        replace Lang.moderation, \staffManager, !-> return "hired %NAME% as a Royal Guard Captain."
        replace Lang.moderation, \staffCohost, !-> return "transformed %NAME% into an Alicorn."
        replace Lang.moderation, \staffHost, !-> return "transformed %NAME% into an Alicorn Princess."
        replace Lang.permissions, \dj, !-> return "Set Horse Famous Ponies" # custom due to length
        replace Lang.permissions, \bouncers, !-> return "Hire Royal Guard"
        replace Lang.permissions, \managers, !-> return "Hire Royal Guard Captains"
        #replace Lang.permissions, \cohosts, !-> return "Add/Remove Alicorns"

        # brony slang
        replace Lang.moderation, \ban, !-> return "sent %NAME% to the moon for a thousand years."
        replace Lang.userSettings, \videoOnly, !-> return "Video Only (no dancing horses)"
        replace Lang.userMeta, \profileURL, !-> return "Hoofbook Profile URL"
        replace Lang.userFriends, \profile, !-> return "Hoofbook Profile"
        replace Lang.userList, \staffTitle, !-> return replaceMap.staff
        replace Lang.tooltips, \profile, !-> return "Edit your Hoofbook Profile"
        replace Lang.userSettings, \nsfw, !-> return "Show Clopper Communities (NSFW)"
        replace Lang.alerts, \sessionExpired, !-> return "Horseapples!"
        replace $('#woot .label').0, \textContent, !-> return "Squee!"


        # Bot Commands
        replace Lang.chat, \help, !-> return "
            <strong>Chat Commands:</strong><br/>/em &nbsp; <em>Emote</em><br/>/me &nbsp; <em>Emote</em><br/>/clear &nbsp; <em>Clear Chat History</em><hr>
            <strong>Bot Commands:</strong><br>
            !randgame &nbsp; <em>Pony Adventure</em><br/>
            !power &nbsp; <em>Random Power</em><br/>
            !hug (@user) &nbsp; <em>hug somepony</em><br/>
            !1v1 (@user) &nbsp; <em>1v1 somepony</em><br/>
            !rule <number> &nbsp; <em>List a Rule</em><br/>
            !songinfo &nbsp; <em>Songstats</em><br/>
            !dc &nbsp; <em>be put back if you dc'd</em><br/>
            !eta &nbsp; <em>ETA til you dj</em><br/>
            !weird &nbsp; <em>Is it weirdday?</em><br/>
        "

        # misc
        replace Lang.search, \youtube, !-> return "Search YouTube for ponies"
        replace Lang.search, \soundcloud, !-> return "Search SoundCloud for ponies"

        # adjust CSS to fit longer text
        css \ponifiedLang, '
            #dialog-user-role .role-menu,
            #dialog-user-role .role-menu .selected {
                width: 205px;
            }
        '