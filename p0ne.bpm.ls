/**
 * BetterPonymotes - a script add ponymotes to the chat on plug.dj
 * based on BetterPonymotes https://ponymotes.net/bpm/
 * for a ponymote tutorial see: http://www.reddit.com/r/mylittlepony/comments/177z8f/how_to_use_default_emotes_like_a_pro_works_for/
 * @author jtbrinkmann aka. Brinkie Pie
 * @version 1.0
 * @license MIT License
 * @copyright (c) 2014 J.-T. Brinkmann
 */
do ->
    window.bpm?.disable!
    window.emote_map ||= {}
    host = window.p0ne?.host or "https://dl.dropboxusercontent.com/u/4217628/plug_p0ne"

    /*== external sources ==*/
    $.getScript "#host/script/bpm-resources.js" .then ->
        API .trigger \p0ne_emotes_map

    $ \body .append "
        <div id='bpm-resources'>
            <link rel='stylesheet' href='#host/css/bpmotes.css' type='text/css'>
            <link rel='stylesheet' href='#host/css/emote-classes.css' type='text/css'>
            <link rel='stylesheet' href='#host/css/combiners-nsfw.css' type='text/css'>
            <link rel='stylesheet' href='#host/css/gif-animotes.css' type='text/css'>
            <link rel='stylesheet' href='#host/css/extracss-pure.css' type='text/css'>
        </div>
    "
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
    emote_regexp = /\[\]\(\/([\w:!#\/\-]+)\s*(?:["']([^"]*)["'])?\)/g


    /*== auxiliaries ==*/
    /*
     * Escapes an emote name (or similar) to match the CSS classes.
     *
     * Must be kept in sync with other copies, and the Python code.
     */
    sanitize_emote = (s) ->
        return s.toLowerCase!.replace("!", "_excl_").replace(":", "_colon_").replace("#", "_hash_").replace("/", "_slash_")


    #== main BPM plugin ==
    lookup_core_emote = (name, altText) ->
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

    convert_emote_element = (info, parts) ->
        title = "#{info.name} from #{info.source_name}".replace /"/g, ''
        flags = ""
        for flag,i in parts when i>0
            /* Normalize case, and forbid things that don't look exactly as we expect */
            flag = sanitize_emote flag.toLowerCase!
            flags += " bpflag-#flag" if not /\W/.test flag

        if info.is_nsfw
            title = "[NSFW] #title"
            flags += " bpm-nsfw"

        return "<span class='bpflag-in bpm-emote #{info.css_class} #flags' title='#title'>#{info.altText || ''}</span>"
        # data-bpm_emotename='#{info.name}'
        # data-bpm_srname='#{info.source_name}'


    window.bpm = (str) ->
        return str .replace emote_regexp, (_, parts, altText) ->
            parts .= split '-'
            name = parts.0
            info = lookup_core_emote name, altText
            if not info
                return _
            else
                return convert_emote_element info, parts
    window.bpm.disable = (revertPonimotes) ->
        $ \#bpm-resources .remove!
        if revertPonimotes
            $ \.bpm-emote .replaceAll ->
                return document.createTextNode do
                    this.className
                        .replace /bpflag-in|bpm-emote|^\s+|\s+$/g, ''
                        .replace /\s+/g, '-'
            if window.bpm.callback
                for e, i in window._$context._events.\chat:receive when e == window.bpm.callback
                        window._$context._events.\chat:receive
                            .splice i, 1
                        break
        /*
        # in case it is required to avoid replacing in HTML tags
        # usually though, there shouldn't be ponymotes in links / inline images / converted ponymotes
        if str .has("[](/")
            # avoid replacing emotes in HTML tags
            return "#str" .replace /(.*?)(?:<.*?>)?/, (,nonHTML, html) ->
                nonHTML .= replace emote_regexp, (_, parts, altText) ->
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

    if window.p0ne?.chatMessagePlugins
        /* add BPM as a p0ne chat plugin */
        window.p0ne.chatMessagePlugins[*] = window.bpm
    else do ->
        /* add BPM as a standalone script */
        if not window._$context
            module = window.require.s.contexts._.defined[\b1b5f/b8d75/c3237] /* ID as of 2014-09-03 */
            if module and module._events?[\chat:receive]
                window._$context = module
            else
                for id, module of require.s.contexts._.defined when module and module._events?[\chat:receive]
                    window._$context = module
                    break

        window._$context._events.\chat:receive .unshift do
            window.bpm.callback = callback: (d) !->
                d.message = bpm(d.message)

    API .once \p0ne_emotes_map, ->
        console.info "[bpm] loaded"
        /* ponify old messages */
        $ '#chat .text' .html ->
            return window.bpm this.innerHTML

        /* add autocomplete if/when plug_p0ne and plug_p0ne.autocomplete are loaded */
        cb = ->
            addAutocompletion? do
                name: "Ponymotes"
                data: Object.keys(emote_map)
                pre: "[]"
                check: (str, pos) ->
                    if !str[pos+2] or str[pos+2] == "(" and (!str[pos+3] or str[pos+3] == "(/")
                        temp = /^\[\]\(\/([\w#\\!\:\/]+)(\s*["'][^"']*["'])?(\))?/.exec(str.substr(pos))
                        if temp
                            @data = temp.2 || ''
                            return true
                    return false
                display: (items) ->
                    return [{value: "[](/#emote)", image: bpm("[](/#emote)")} for emote in items]
                insert: (suggestion) ->
                    return "#{suggestion.substr(0, suggestion.length - 1)}#{@data})"
        if window.addAutocompletion
            cb!
        else
            $(window) .one \p0ne_autocomplete, cb