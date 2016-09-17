/**
 * BetterPonymotes - a script add ponymotes to the chat on plug.dj
 * based on BetterPonymotes https://ponymotes.net/bpm/
 * for a ponymote tutorial see:
 * http://www.reddit.com/r/mylittlepony/comments/177z8f/how_to_use_default_emotes_like_a_pro_works_for/
 *
 * @author jtbrinkmann aka. Brinkie Pie
 * @license MIT License
 * @copyright (c) 2015 J.-T. Brinkmann
 */
console.log "~~~~~~~ p0ne.bpm ~~~~~~~"


/*####################################
#          BETTER PONYMOTES          #
####################################*/
module \bpm, do
    require: <[ chatPlugin ]>
    disabled: true
    displayName: 'Better Ponymotes'
    settings: \pony
    _settings:
        showNSFW: false
    module: (str) !->
        return @bpm str

    setup: ({addListener, $create, addCommand}, {_settings}) !->
        host = window.p0ne?.host or "https://cdn.p0ne.com"

        /*== external sources ==*/
        if not window.emote_map
            window.emote_map = {}
            $.getScript "#host/scripts/bpm-resources.js"
                .then !->
                    API .trigger \p0ne_emotes_map
                .fail !~>
                    API.chatLog "Better Ponymotes failed to load ponimote data"
                    @disable!
        else
            <- requestAnimationFrame
            API .trigger \p0ne_emotes_map

        $create "
            <div id='bpm-resources'>
                <link rel='stylesheet' href='#host/css/bpmotes.css' type='text/css'>
                <link rel='stylesheet' href='#host/css/emote-classes.css' type='text/css'>
                <link rel='stylesheet' href='#host/css/combiners-nsfw.css' type='text/css'>
                <link rel='stylesheet' href='#host/css/gif-animotes.css' type='text/css'>
                #{if \webkitAnimation of document.body.style
                    "<link rel='stylesheet' href='#host/css/extracss-webkit.css' type='text/css'>"
                else
                    "<link rel='stylesheet' href='#host/css/extracss-pure.css' type='text/css'>"
                }
            </div>
        "
            .appendTo $body
        /*
                <style>
                \#chat-suggestion-items .bpm-emote {
                    max-width: 27px;
                    max-height: 27px
                }
                </style>
        */

        /*== constants ==*/
        _FLAG_NSFW = 1
        _FLAG_REDIRECT = 2

        /*
         * As a note, this regexp is a little forgiving in some respects and strict in
         * others. It will not permit text in the [] portion, but alt-text quotes don't
         * have to match each other.
         */
        /*                 [](/  <   emote   >   <     alt-text    >  )*/
        EMOTE_REGEXP = /\[\]\(\/([\w:!#\/\-]+)\s*(?:&#3[49];([^"]*)&#3[49];)?\)/g


        /*== auxiliaries ==*/
        /*
         * Escapes an emote name (or similar) to match the CSS classes.
         *
         * Must be kept in sync with other copies, and the Python code.
         */
        sanitize_map =
            \! : \_excl_
            \: : \_colon_
            \# : \_hash_
            \/ : \_slash_
        function sanitize_emote s
            return s.toLowerCase!.replace /[!:#\/]/g, (c) !-> return sanitize_map[c]

        function lookup_core_emote name, altText
            # Refer to bpgen.py:encode() for the details of this encoding
            data = emote_map["/"+name]
            return null if not data

            nameWithSlash = name
            parts = data.split ','
            flag_data = parts.0
            tag_data = parts.1

            flags = parseInt(flag_data.slice(0, 1), 16)     # Hexadecimal
            source_id = parseInt(flag_data.slice(1, 3), 16) # Hexadecimal
            #size = parseInt(flag_data.slice(3, 7), 16)     # Hexadecimal
            is_nsfw = (flags .&. _FLAG_NSFW)
            is_redirect = (flags .&. _FLAG_REDIRECT)

            /*tags = []
            start = 0
            while (str = tag_data.slice(start, start+2)) != ""
                tags.push(parseInt(str, 16)) # Hexadecimal
                start += 2

            if is_redirect
                base = parts.2
            else
                base = name*/

            return
                name: nameWithSlash,
                is_nsfw: !!is_nsfw
                source_id: source_id
                source_name: sr_id2name[source_id]
                #max_size: size

                #tags: tags

                css_class: "bpmote-#{sanitize_emote name}"
                #base: base

                altText: altText

        function convert_emote_element info, parts, _
            title = "#{info.name} from #{info.source_name}".replace /"/g, ''
            flags = ""
            for flag,i in parts when i>0
                /* Normalize case, and forbid things that don't look exactly as we expect */
                flag = sanitize_emote flag.toLowerCase!
                flags += " bpflag-#flag" if not /\W/.test flag

            if info.is_nsfw
                if _settings.showNSFW
                    title = "[NSFW] #title"
                    flags += " bpm-nsfw"
                else
                    console.warn "[bpm] nsfw emote (disabled)", name
                    return "<span class='bpm-nsfw' title='NSFW emote'>#_</span>"

            return "<span class='bpflag-in bpm-emote #{info.css_class} #flags' title='#title'>#{info.altText || ''}</span>"
            # data-bpm_emotename='#{info.name}'
            # data-bpm_srname='#{info.source_name}'


            /*
            # in case it is required to avoid replacing in HTML tags
            # usually though, there shouldn't be ponymotes in links / inline images / converted ponymotes
            if str .has("[](/")
                # avoid replacing emotes in HTML tags
                return "#str" .replace /(.*?)(?:<.*?>)?/, (,nonHTML, html) !~>
                    nonHTML .= replace EMOTE_REGEXP, (_, parts, altText) !->
                        parts .= split '-'
                        name = parts.0
                        info = lookup_core_emote name, altText
                        if not info
                            return _
                        else
                            return convert_emote_element info, parts
                    return "#nonHTML#html"
            else
                return str
            */

        #== main BPM plugin ==
        @bpm = (str) !->
            return str .replace EMOTE_REGEXP, (all, parts, altText) !->
                parts .= split '-'
                name = parts.0
                info = lookup_core_emote name, altText
                if not info
                    return all
                else
                    return convert_emote_element info, parts, all

        #== integration ==
        addListener (window._$context || API), \p0ne:chat:plugin, (msg) !->
            msg.message = bpm(msg.message)

        addListener \once, API, \p0ne_emotes_map, !->
            console.info "[bpm] loaded"

            #== ponify old messages ==
            get$cms! .find \.text .html !->
                return bpm @innerHTML

            #== Autocomplete integration ==
            /* add autocomplete if/when plug_p0ne and plug_p0ne.autocomplete are loaded */
            cb = !->
                AUTOCOMPLETE_REGEX = /^\[\]\(\/([\w#\\!\:\/]+)(\s*["'][^"']*["'])?(\))?/
                addAutocompletion? do
                    name: "Ponymotes"
                    data: Object.keys(emote_map)
                    pre: "[]"
                    check: (str, pos) !->
                        if !str[pos+2] or str[pos+2] == "(" and (!str[pos+3] or str[pos+3] == "(/")
                            temp = AUTOCOMPLETE_REGEX.exec(str.substr(pos))
                            if temp
                                @data = temp.2 || ''
                                return true
                        return false
                    display: (items) !->
                        return [{value: "[](/#emote)", image: bpm("[](/#emote)")} for emote in items]
                    insert: (suggestion) !->
                        return "#{suggestion.substr(0, suggestion.length - 1)}#{@data})"
            if window.addAutocompletion
                cb!
            else
                addListener \once, API, \p0ne:autocomplete, cb

        # add /Chat Commands
        addCommand \bpm, do
            aliases: <[ ponymote ]>
            parameters: " emotename or [](/emotename)"
            description: "checks if the emote exists and sends it if so"
            callback: (str) !->
                if str = /^\/bpm (?:^\/\[\]\(\/(.*?)(-.*?)?\)|(.*)(-.*?)?)/i .exec str
                    if str.1
                        emote = str.1
                        str = "#emote#{str.2}"
                    else
                        emote = str.3
                        str = "#emote#{str.4}"
                    if emote of emote_map
                        API.sendChat bpm("[](/#str)")
        addCommand \reloadBPM, do
            description: "reloads the BPM database."
            callback: (str) !->
                if str = /^\/bpm (?:^\/\[\]\(\/(.*?)(-.*?)?\)|(.*)(-.*?)?)/i .exec str
                    if str.1
                        emote = str.1
                        str = "#emote#{str.2}"
                    else
                        emote = str.3
                        str = "#emote#{str.4}"
                    if emote of emote_map
                        API.sendChat bpm("[](/#str)")


    disable: (revertPonimotes) !->
        if revertPonimotes
            get$cms! .find \.bpm-emote .replaceWith !->
                flags = ""
                for class_ in this.classList || this.className.split(/s+/)
                    if class_.startsWith \bpmote-
                        emote = class_.substr(7)
                    else if class_.startsWith(\bpflag-) and class_ != \bpflag-in
                        flags += class_.substr(6)
                if emote
                    return document.createTextNode "[](/#emote#flags)"
                else
                    console.warn "[bpm] cannot convert back", this