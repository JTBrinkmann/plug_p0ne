#== chat autocomplete ==
#recentEmotes = []
Chat ||= requireHelper do
    name: \Chat
    id: \de369/d86c0/e7368/eaad6/b2e50 #2014-09-04
    test: (.::?id == \chat)
    fallback: window.app?.room?.chat.constructor
SuggestionView = requireHelper do
    name: \SuggestionView
    id: \de369/d86c0/e7368/eaad6/fe9c4 #2014-09-04
    test: (.::?id == \chat-suggestion)
if Chat and SuggestionView
    /* userDB = requireHelper do
        id: \a09a0/ba40c/f0ffe #2014-08-27
        test: ((it) -> it.hash and it.lookup)
        fallback:
            lookup: (substr) ->
                l = substr.length
                return [user for user in API.getUsers! when user.username.substr(0,l) == substr]
    */
    userDB = lookup: (name) ->
        res = []
        l = 0
        for user in API.getUsers! when not name or user.username.substr(0,name.length) == name
            res[l++] = {value: user.username, image: "<div class='thumb small'><i class='avi avi-#{user.avatarID}'></i></div>"}
        return res

    emoticons = requireHelper do
        name: \emoticons
        id: \de369/a7486/e3035 #2014-09-04
        test: (.emojify)
        fallback: -> return []

    require [\hbs!templates/room/chat/ChatSuggestionItem], ->
    ChatSuggestionItem = require \hbs!templates/room/chat/ChatSuggestionItem #ToDo change to requireHelper or at least have a fallback

    css \autocomplete, '
        .chat-suggestion-item.selected,
        .chat-suggestion-item:hover {
            background: #2d313a;
        }
    '


    Chat::submitSuggestion = ->
        e = this.getMentionRange!
        t = this.chatInput.value.substr(0, e.0)
        n = this.chatInput.value.substr(e.1)
        sv = this.suggestionView
        d = sv.getSelected!
        recent = sv.autocompletor.recent
        i = recent.indexOf(d)
        if sv.autocompletor.input
            r = that d
        else if d?.value
            r = that
        else
            r = d
        this.chatInput.value = "#t#r #n"
        this.chatInput.setSelectionRange(e.0 + r.length + 1, e.0 + r.length + 1)
        recent.splice(i,0) if i != -1
        recent.unshift d
        recent.pop! if recent.length > 10
        sv.reset!
        sv.updateSuggestions!
    Chat::getMentionRange = !->
        e = this.getCaratPosition!
        if e > 0 and this.suggestionView.suggestions.length
            return [this.chatInput.value.substr( 0, e ).lastIndexOf( @suggestionView.autocompletor.pre ) + @suggestionView.autocompletor.pre.length, e]

    /* SuggestionView::upDown = (keyCode) -> # vanilla
            if @suggestions.length > 1
                if keyCode == 40
                    ++@index
                else
                    --@index
                if @index == -1
                    @index = @suggestions.length - 1
                else if @index == @suggestions.length
                    @index = 0
                @updateSelectedSuggestion!
    */
    SuggestionView:: <<<<
        range: 0
        reset: ->
            @index = -1; @suggestions = []; @suggestionsFull = []; @range = 0; @data = null
        getSelected: ->
            switch typeof @autocompletor.input
            | \string =>
                return @autocompletor.input.replace(/°/g, @suggestions[@index].value)
            | \function =>
                return @autocompletor.input @suggestions[@index]
            | otherwise =>
                return @suggestions[@index].value
        upDown: (keyCode) ->
            return if @suggestions.length <= 1

            if keyCode == 40 # up key
                ++@index
            else # down key
                --@index
            if @index == @range - 1
                if @index == -1
                    @index = @suggestionsFull.length - 1
                    @updateSelectedSuggestion!
                else
                    @changeRange -1
            else if @index == @range + @maxShownSuggestions
                if @index == @suggestionsFull.length
                    @index = 0
                    @updateSelectedSuggestion!
                else
                    @changeRange +1
            else
                @updateSelectedSuggestion!

        changeRange: (change) ->
            console.log "[autocomplete] updating range @range #{if change >= 0 then '+' else ''}#change"
            @range += change * @maxShownSuggestions
            @suggestions = @suggestionsFull.slice(@range, @maxShownSuggestions)
            @updateSelectedSuggestion!

        updateSuggestions: ->
            n = @suggestions.length
            @$itemContainer.html ""
            console.log "[autocomplete] updating. #n suggestions", this
            if not n
                @$el.hide!
                @$el .off \click, \.chat-suggestion-item, @pressBind
            else
                @$el .on \click, \.chat-suggestion-item, @pressBind
                switch typeof @autocompletor.display
                | \string =>
                    vals = []
                    l = 0
                    for d in @suggestions
                        if typeof d == \object
                            val = d.value
                        else
                            val = d
                        vals[d] = { value: @autocompletor.display.replace(/°/g, d) }
                | \function =>
                    vals = @autocompletor.display @suggestions
                | otherwise =>
                    console.warn "[autocomplete] no autocompletor.display", @autocompletor
                    vals = @suggestions

                for val, i in vals
                    $ ChatSuggestionItem(value: val.value, index: i, image: val.image)
                        .appendTo @$itemContainer
                        #.mousedown @pressBind
                        #.mouseenter @overBind

                @updateSelectedSuggestion!
                @$el.height n * 38px #ToDo is this necessary?
                @show!
                #setTimeout @showBind, 10ms
                #setTimeout @showBind, 15ms
                @$document.on \mousedown, @documentClickBind
                @oldSuggestions = @suggestions

        updateSelectedSuggestion: ->
            $ \.chat-mention-suggestion-item
                .removeClass \selected
                .eq(@index - @range)
                    .addClass \selected


        check: (e, t) ->
            oldIndex = @index
            @reset!

            /*
                # autocomplete ponymotes
                n = e.lastIndexOf "[]"
                if n != -1
                    if !e[n+2] or e[n+2] == "(" and (!e[n+3] or e[n+3] == "(/")
                        temp = /^\[\]\(\/([\w#\\!\:\/]+)(\s*["'][^"']*["'])?(\))?/.exec(e.substr(n))
                        if temp
                            if not temp.3 and temp.1.length > 2
                                input = temp.1 .toLowerCase!
                                alttext = temp.2 || ''
                                l = 0
                                for emote in emotesCache[input]
                                        @suggestionsFull[l++] = {username: "[](/#{emote}#{alttext})"}
                        else
                            #@suggestionsFull = allEmotes
                            #ToDo add recentEmotes
                # autocomplete @mentions
                n = e.lastIndexOf "@"
                if n != -1
                    @suggestionsFull = s.lookup e.substr( n + 1, t ) # n + "@".length
            */
            for obj in autocompletions
                lastIndex = e.lastIndexOf obj.pre
                continue if lastIndex == -1
                substr = e.substr(lastIndex + obj.pre.length, t)
                if obj.check
                    temp = obj.check?(substr, t, e, lastIndex)
                    continue if not temp

                if temp?.length?
                    @suggestionsFull = temp
                else if obj.data
                    @suggestionsFull = obj.cache[substr]
                else
                    continue

                @autocompletor = obj
                console.log "[autocomplete]", obj.name, "(#{@suggestionsFull?.length} results)", "\"#substr\""

                if @suggestionsFull.length
                    if @oldSuggestions
                        @index = 0 >? @suggestionsFull.indexOf(@oldSuggestions[@index])
                    else
                        @index = 0
                    @range = ~~(@index / @maxShownSuggestions)
                    @changeRange 0

                return #ToDo: allow multiple autocompletors simultaneously


    window.autocompletions = []
    window.addAutocompletion = ({name, data, pre, check, display, input}:autocompletor) ->
        # `data` should be an Array of Strings
        # `check` will be called with the parameters (substr, pos, str, lastIndex)
        # `display` will be called with an Array of the elements that are about to be displayed.
        #   it should return an Array of equal size, which maps the input Array to objects with a "value" and "image" attribute
        #   e.g. [{value: ':cat:', image: '<i class="cat"></i>'}, …]
        if data
            autocompletor.cache = {}
            for d in data
                # not using `autocompletor.add(d)` for performance reasons
                for i from 1 to d.length
                    autocompletor.cache[][d.substr(0, i)][*] = d
            autocompletor.add = (d) ->
                for i from 1 to d.length
                    @cache[][d.substr(0, i)][*] = d

        autocompletions[*] = autocompletor
        console.warn "[autocomplete] loaded autocomplete hook '#name'"
        return autocompletor

    # default autocompletors
    addAutocompletion do
        name: "@mention"
        pre: "@"
        check: (substr) -> return userDB.lookup substr
        input: "@°"
    addAutocompletion do
        name: ":emoji:"
        pre: ":"
        check: (substr) -> return emoticons.lookup substr
        display: (emojis) ->
            res = []
            l = 0
            for d in emojis
                res[l++] =
                    value: ":#d:"
                    image: "<span class='emoji-glow'><span class='emoji emoji-#{emoticons.map[d]}'></span></span>"
            return res

else
    window.addAutocompletion = ({name}) ->
        console.error "[autocomplete] can't add autocomplete for '#name' (SuggestionView couldn't be loaded)"
        return false

    console.warn "[autocomplete] failed to load SuggestionView"


#== custom autocompletes ==
#= vanilla /commands
commands = '''
    /help - returns a list of /commands
    /me - emote
    /em - emote
    /afk - change status to "AFK"
    /back - change status to "available"
    /ignore (username) - ignore all messages by the specified user
    /unignore (username) - stop ignoring the specified user
    /cap (number) - cap avatars at the specified number
    /clear - clear the chat (hide all messages)
'''
window.commandsAutocomplete = addAutocompletion do
    name: '/commands'
    pre: '/'
    data: commands.split '\n'
    input: (.split(" ").0.replace(/\(.*?\)\s*/g, ''))

#= plug³ /commands =
# from http://plugcubed.net/Commands
commands = ["/#command - #description" for command, description of require('plugCubed/Lang').commands.descriptions]
/*commands = '''
    /commands - Opens a window with all the commands
    /nick - Change Username
    /avail - Set status to 'Available'
    /afk - Set status to 'AFK'
    /work - Set status to 'Working'
    /sleep - Set status to 'Sleeping'
    /join - Join the DJ booth / Waitlist
    /leave - Leave the DJ booth / Waitlist
    /whoami - Brings up details of your own information
    /refresh - Refresh the video
    /version - Displays the version number
    /mute - Set volume to 0
    /link - Pastes in a link to plugCubed website in the chat
    /unmute - Sets volume back to last volume level
    /nextsong - Display next song in playlist and if it's in history
    /automute - Register currently playing song to automatically mute on future plays
    /alertson (word) - Play mention sound whenever word is written in chat
    /alertsoff (word) - Disables the mention sound for the word written in chat
    /getpos - Get current waitlist position
    /ignore (username) - Ignore all chat messages from user
    /whois - Brings up details of the users information
    /kick (username) - Kicks the user out of the room
    /add (username) - Adds the user to the DJ booth / Waitlist
    /remove (username) - Removes the user to the DJ booth / Waitlist
    /lock - Locks the DJ booth
    /unlock - Unlocks the DJ booth
'''*/
window.commandsAutocomplete = addAutocompletion do
    name: 'plugCubed /commands'
    pre: '/'
    data: commands #.split '\n'
    input: (.split(" - ").0)

#= @BOT !commands =
# from http://fimplug.net/bot/
commands = '''
    !drama - A link to a ‘Drama’ button will be retuned.
    !fans - A link to 3 pictures of fans will be returned.
    !hambanner - A link to a Runescape character holding a banner with a picture of ham on it will return.
    !hug - Bot will hug the issuer if no other user is @defined in multiple situations.
    !no+ - A link to the Noo! website will be returned.
    !ping - Pong will be returned to measure the ping between the user and Bot.
    !PlugPlug - A link to install PlugPlug will be returned.
    !random - A random number will be returned to the user.
    !randgame - A character from My Little Pony or a moderator from the community and a situation will be returned.
    !rule # - Where ‘#’ is a number between 1 and 27. A rule associated with # will be returned.
    !rules - A link to the ‘rules’ will be returned to the user.
    !site - A link to the community website will be returned.
    !weird - A link to the weird-day table will be returned.
    !ye+s - A link to the Yeess! website will be returned.
'''
addAutocompletion do
    name: '!botcommand'
    pre: '!'
    data: commands.split '\n'
    input: (.split(" ").0.replace(/(.)\+/g, "$1$1$1"))

#= plug_p0ne emoticons =
emoticons = '''
    ::mad - Ɔ:<
    ::eyeroll - ¬_¬
    ::tableflip - (ノ ゜Д゜)ノ ︵⊥⊥
    ::tableflipp?e?d - ㅠ ︵ /(.ㅁ. \\）
'''
addAutocompletion do
    name: 'plug_p0ne :emoticons:'
    pre: '::'
    data: emoticons.split '\n'
    input: (.split(" - ").0.replace(/\?/g, ''))


#= !disable =
addAutocompletion do
    name: 'plug_p0ne :emoticons:'
    pre: '!'
    data: ["!disable !joindisable"]
    check: (,,e) ->
        return -1 != e.indexOf "@"