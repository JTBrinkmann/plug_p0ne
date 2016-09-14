/*@author jtbrinkmann aka. Brinkie Pie */
/*@license https://creativecommons.org/licenses/by-nc/4.0/ */
p0ne = window.p0ne

/*
- load plug_dj.compress.js
- create chunk for messages
- pre
    - substitute chat.$chatMessages
- post
    - save messages to LS (uncompressed)
    - check if chunk is full
        => create new one
        => hide old chunks (only show 2 at the same time)

loadChat
- put chat from before loading this script in chunks
- load and decompress saved chunks
- dynamically load chunks when scrolling to the top/bottom
- overlay visible old chunks, so that ~3 messages of current chat are always visible
- add toolbar buttons
    - calendar widget
*/

module \saveChat, do
    require: <[ chat ]>
    optional: <[ _$contextUpdateEvent ]>
    _chunkSize: 128messages # note: this needs to be <= 512 to prevent vanilla plug from removing messages

    $c_: $ \#chat
    $cm_: $ \#chat-messages
    $cm: null
    playSound_: null
    $dummy: null
    chunks: []
    $cChunk: null
    cChunkI: null # index of chunkID in @chunks
    cChunkID: null
    cChunkData: []
    visibleChunk1: null #chunkID of upper visible chunk (if any)
    $visibleChunk1: null
    visibleChunk2: null #chunkID of lower visible chunk
    $visibleChunk2: null

    cbPreWrapper: null
    cbPostWrapper: null
    cbScrollWrapper: null
    scrolling: false

    setup: ({addListener}) ->
        # set up variables
        @update!
        @$cm = chat.$chatMessages
        playSound_ = chat.playSound
        @$dummy = $!
        @$cChunk = @$dummy

        msgs = @$cm .children!

        # load plug_dj.compress.js
        loadScript \decompressorLoaded, window.compressor, "plug_dj.compress.js"
            .then ~>
                console.info "[saveChat] compressor loaded"
                @loadChat
            #.timeout 10s *1_000to_ms ->
            #   ... #ToDo notify user that plug_p0ne is still loading old chatlogs

        # setup listeners
        @setupEvents!
        addListener do
            target: _$context, event: \context:update, bound: true
            callback: (d) -> if d.ctx != this and d.event == \chat:receive
                @disable!; @enable!

        # set up HTML
        @$loadingTop = $ \<span> .text "loading…" .css(\visibility, \hidden) .appendTo @$cm_
        @$loadingBottom = @$loadingTop .clone! .appendTo @$cm_

        # create Chunk
        @$visibleChunk1 = @$visibleChunk2 = $!
        @createChunk!

        # p³ fix
        plugCubedLoaded .then ->
            replace require(\plugCubed/Utils), \chatLog, (chatLog_) -> return (type, message, color) ->
                return if (!message)
                chatLog_ ...
                appendChat saveChat.$cm.children!.last!

        # move old messages in the chunk
        l = 0
        for msg in msgs
            $msg = $ msg
            @cChunkData[l++] =
                cid: $msg.data \cid
                message: $msg.find \.text .html!
                timestamp: $msg.find \.timestamp .text!
                type: msg.className
                un: $msg.find \.from .text!
                uid: $msg.find \.from .data \uid
            @$cChunk .append msg
            if l >= @_chunkSize
                @closeCChunk JSON.stringify(@cChunkData)
                l = 0



    update: ->
        saveChat = this
        @cbPreWrapper = (message) -> saveChat.cbPre this, message
        @cbPostWrapper = (message) -> saveChat.cbPost this, message
        @cbScrollWrapper = -> saveChat.cbScroll this
    setupEvents: ->
        _$context.onEarly \chat:receive, @cbPreWrapper
        _$context.on \chat:receive, @cbPostWrapper
        @$cm_ .on \scroll, @cbScrollWrapper
    enable: ->
        @setupEvents!
    disable: ->
        _$context.off \chat:receive, @cbPreWrapper
        _$context.off \chat:receive, @cbPostWrapper
        @$cm_ .off \scroll, @cbScrollWrapper


    cbPre: (chat, message) !-> # run first when receiving a message
        if message.emulate
            chat.$chatMessages = @$dummy
            chat.playSound = ->
        else
            if chat.$chatMessages != @$cChunk and chat.$chatMessages # update $chatMessages (e.g. after switching from regular to popout view or vice versa)
                console.log "[saveChat] updating $cm", chat.$chatMessages
                @$cm = chat.$chatMessages
                # @$cChunk = @$cm.find @cChunkID
                chat.$chatMessages = @$cChunk
            message.time = Date.now!
            message.wasAtBottom = chatIsAtBottom! # p0ne.chat also sets this, but usualyl p0ne.saveChat should be run BEFORE p0ne.chat


    cbPost: (chat, message) !->
        #console.log "[saveChat] post", message
        if message.emulate # run after displaying a received message
            message.html = @$dummy.html!
            message.$el = @$dummy.children!
            message.el = message.$el.0
            @$dummy.html ""
            chat.playSound = @playSound_
            #chat.$chatMessages = @$cChunk done in cbPre
        else
            # scroll chat down, if necessary
            if message.wasAtBottom
                chatScrollDown!
            # save messages to LS (uncompressed)
            l = @cChunkData.length
            @cChunkData[l] = message
            try
                data = JSON.stringify @cChunkData
            catch
                console.warn "[saveChat] first attempt to serialize message failed", message, @cChunkData
                @cChunkData[l] = {[k,v] for k,v of message when typeof v != \object}
                data = JSON.stringify @cChunkData

            # check if chunk is full
            if l < @_chunkSize # if chunk isn't full
                localStorage.setItem \p0ne_chunk_current, data
            else # if chunk is full
                @closeCChunk data

    cbScroll: ->
        return if @scrolling
        @scrolling = true
        <~ requestAnimationFrame
        @scrolling = false
        sT =  @$cm.0.scrollTop
        if sT < 150px and @visibleChunk1 != @chunks.0 and @visibleChunk1
            # load preceding chunk
            newChunkID = @chunks[@chunks.indexOf(@visibleChunk1) - 1]
            console.info "[saveChat] loading preceding chunk #newChunkID"
            @$loadingTop .css \visibility, \visible
            newChunk = @loadChunk(newChunkID)
                .insertBefore @$visibleChunk1
            @$cm.0.scrollTop += newChunk.height!
            @$visibleChunk2.remove! if not @visibleChunk2 == @cChunkID
            @visibleChunk2 = @visibleChunk1; @$visibleChunk2 = @$visibleChunk1
            @visibleChunk1 = newChunkID; @$visibleChunk1 = newChunk
            @$loadingTop .css \visibility, \hidden

        else if @cChunkID != @visibleChunk2 and sT + @$c_.0.scrollHeight + 150px > @$cm.0.scrollHeight
            # load subsequent chunk
            newChunkID = @chunks[@chunks.indexOf(@visibleChunk2) + 1]
            return if newChunkID == @cChunkID
            console.info "[saveChat] loading subsequent chunk #newChunkID"
            @$loadingBottom .css \visibility, \visible
            newChunk = @loadChunk(newChunkID)
                .insertAfter @$visibleChunk2
            @$visibleChunk1.remove!
            @visibleChunk1 = @visibleChunk2; @$visibleChunk1 = @$visibleChunk2
            @visibleChunk2 = newChunkID; @$visibleChunk2 = newChunk
            #ToDo scroll up, if necessary
            @$loadingBottom .css \visibility, \hidden


    createChunk: ->
        @cChunkTime = new Date
        @$cChunk.removeClass \p0ne_chunk_current
        @chunkI = @chunks.length
        @cChunkID = "p0ne_chunk_(#{@chunkI})_#{@cChunkTime.toISOString!}" #ToDo remove the "(#{@chunkI})". It is only for debugging.
        @$cChunk = $ "<div class='p0ne_chunk p0ne_chunk_current' id='#{@cChunkID}'>" .insertBefore @$loadingBottom
        chat.$chatMessages = @$cChunk
        @cChunkData = []
        @chunks[@chunkI] = @cChunkID
        @$cChunk.scrollTop = (d) -> return if d then this else 0 # for performance gain when vanilla chat.onReceive wants to scroll down

    loadChunk: (chunkID) ->
        chunk = $ "<div class='p0ne_chunk' id='#chunkID'>"

        chat.$chatMessages = chunk
        chat.playSound = ->
        d = JSON.parse(decompress(localStorage.getItem chunkID))
        console.info "[saveChat] loadChunk", d
        for msg in d
            chat.onReceived msg
        chat.$chatMessages = @$cChunk
        chat.playSound = @playSound_

        return chunk

    closeCChunk: (data) ->
        oldChunkID = @cChunkID

        # save compressed chunk
        localStorage.setItem @cChunkID, compress(data)
        @cChunkData = []

        # create new chunk
        @createChunk!
        console.info "[saveChat] current chunk is full '#oldChunkID'. created new one '#{@cChunkID}' (", not @visibleChunk1, ") or", oldChunkID == @visibleChunk2, " and ", @getChunkInView! == @visibleChunk1, ")"
        if not @visibleChunk1 or (oldChunkID == @visibleChunk2 and @getChunkInView! != @visibleChunk1)
            if @visibleChunk1
                # hide old chunk (only show 2 at the same time)
                @$visibleChunk1 .remove!
            @visibleChunk1 = @visibleChunk2; @$visibleChunk1 = @$visibleChunk2
            @visibleChunk2 = @cChunkID; @$visibleChunk2 = @$cChunk

    getChunkInView: ->
        if not @visibleChunk1 or @$cm.0.scrollTop > @$visibleChunk1.0.scrollHeight
            return @visibleChunk2
        else
            return @visibleChunk1

    loadChat: ->
        #ToDo check if compress is REALLY loaded

/*
function(type, message, color) {
    var $chat, b, $message, $text;
    if (!message) return;
    if (typeof message !== 'string') message = message.html();

    message = this.cleanHTML(message);
    $chat = saveChat.$cChunk
    b = chatIsAtBottom() //$chat.scrollTop() > $chat[0].scrollHeight - $chat.height() - 20;
    $message = $('<div>').addClass(type ? type : 'update');
    $text = $('<span>').addClass('text').html(message);

    if (type === 'system') {
        $message.append('<i class="icon icon-chat-system"></i>');
    } else {
        $text.css('color', this.toRGB(color && this.isRGB(color) ? color : 'd1d1d1'));
    }
    $chat.append($message.append($text));
    b && chatScrollDown() //$chat.scrollTop($chat[0].scrollHeight);
}
*/