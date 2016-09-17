/**
 * Tutorial and help GUI for plug_p0ne
 *
 * @author jtbrinkmann aka. Brinkie Pie
 * @license MIT License
 * @copyright (c) 2015 J.-T. Brinkmann
 */
console.log "~~~~~~~ p0ne.help ~~~~~~~"

module \p0neHelp, do
    optional: <[ currentMedia ]>
    require: <[ automute p0neSettings ]>
    setup: ({$create, loadStyle}:aux) !->
        #== create CSS ==
        #ToDo move this to plug_p0ne.css
        loadStyle "#{p0ne.host}/css/walkthrough.css"

        automute = p0ne.modules.automute
        var i
        steps = {}
        @screenClose = $.noop

        p0neSettings = p0ne.modules.p0neSettings
        automute = p0ne.modules.automute
        $ppW = p0neSettings.$ppW
        $ppI = $ppW.parent! .find '.p0ne-icon:first'
        $pp0 = $ppI .find \.p0ne-icon-sub
        $hdButton = $ '#playback .hd'
        $snoozeBtn = $ '#playback .snooze'
        $bar = $ \#now-playing-bar
        $songInfo = $ \.p0ne-song-info
        $footerUser = $ \#footer-user
        $footerInfo = $footerUser.find \.info

        #== create DOM elements ==
        $el = $create "
            <div class=wt-cover></div>
            <div class='container wt-p0' id=walkthrough>
                <div class='step fade-in wt-p0-welcome' data-screen=welcome>
                    <h2>Welcome to</h2>
                    <div class=wt-p0-title>
                        <div class=wt-p0-title-p>p</div>
                        <div class=wt-p0-title-lug_p>lug_p</div>
                        <div class='wt-p0-0 wt-p0-title-0'>0</div>
                        <div class=wt-p0-title-ne>ne</div>
                    </div>

                    <button class='wt-p0-next continue'>&nbsp;</button>
                </div>

                <div class='step fade-in wt-p0-settings' data-screen=settings>
                    <h1>Settings</h1>
                    <p>
                        To open/close the plug_p0ne settings, click the <div class=p0ne-icon>p<div class=p0ne-icon-sub>0</div></div> icon in the top left
                    </p>

                    <p class=wt-p0-settings-closed>
                        click the icon now!
                    </p>
                    <p class=wt-p0-settings-open>
                        Good job! Let's move on.
                    </p>
                    <button class='wt-p0-back'>back</button>
                    <button class=wt-p0-next>skip</button>
                </div>

                <div class='step fade-in wt-p0-dblclick2mention' data-screen=dblclick2mention>
                    <h1>dblclick2mention</h1>
                    <p>
                        One of most often used p0 features is the so called \"DblClick username to Mention\".<br>
                        Just <b>double click</b> their name to <em>@mention</em> them. This is great to quickly greet friends, for example.<br>
                        <small>(it works on username in chat, join notifications and just about EVERYWHERE)</small>
                    </p>
                    <img src='http://i.imgur.com/e5JVTqU.gif' alt='screenrecording of dblclick2mention' width=350 height=185 />

                    <button class='wt-p0-back'>back</button>
                    <button class='wt-p0-next continue'>next</button>
                </div>

                <div class='step fade-in wt-p0-stream-settings' data-screen=stream-settings>
                    <h1>Stream Settings</h1>
                    <p>
                        plug_p0ne adds a new audio-only mode to videos and let's you quickly switch between<br>
                            <i class='icon icon-stream-video'></i> Video<br>
                            <i class='icon icon-stream-audio'></i> Audio-Only<br>
                            <i class='icon icon-stream-off'></i> Stream-Off (no video/sound)
                    </p>
                    <p>
                        You can click the icons in the top-middle to change between the modes.
                    </p>

                    <button class='wt-p0-back'>back</button>
                    <button class='wt-p0-next continue'>next</button>
                </div>

                <div class='step fade-in wt-p0-automute' data-screen=automute>
                    <h1>Automute</h1>
                    <p>
                        You can also <b>automute</b> songs you really dislike. This way, they will automatically get muted whenever they are played.
                    </p>
                    <p>
                        To add a song to automute, do the following:
                        <ol class=wt-p0-steps>
                            <li>Click on <b class=snooze-btn><i class='icon icon-stream-off'></i> Snooze</b> to snooze the current song (stop the video/song)</li>
                            <li>When snoozed, the snooze button will turn into an automute -add or -remove button</li>
                        </ol>
                    </p>
                    <p>
                        Let's try it out!<br>
                        (don't worry, we can undo it right away)
                    </p>

                    <button class='wt-p0-back'>back</button>
                    <button class=wt-p0-next>skip</button>
                </div>

                <div class='step fade-in wt-p0-automute2' data-screen=automute2>
                    <h1>Automute</h1>
                    <p>
                        Removing songs from the automute list is also easy:
                        <ol class=wt-p0-steps>
                            <li>open the settings panel. (<div class=p0ne-icon>p<div class=p0ne-icon-sub>0</div></div>)</li>
                            <li>open the group \"#{automute.settings}\"</li>
                            <li>click on the <i class='icon icon-settings-white'></i>icon next to \"automute\"</li>
                            <li>move your mouse over any song in the list and click the <i class='icon icon-clear-input'></i> icon on the song you want to remove from the list</li>
                        </ol>
                    </p>

                    <button class='wt-p0-back'>back</button>
                    <button class=wt-p0-next>skip</button>
                </div>

                <div class='step fade-in wt-p0-songinfo' data-screen=songinfo>
                    <h1>Song-Info</h1>
                    <p>
                        Want to find out more about the current song?
                    </p>
                    <p class=wt-p0-songinfo-closed>
                        Click the song title above!
                    </p>
                    <div class=wt-p0-songinfo-open>
                        In the top middle you can see two rows.
                        <img src='//i.imgur.com/clwk2QL.png' alt='top row shows author - title as seen on plug.dj, second row shows channel name and upload title as seen on Youtube/Soundcloud' width=338 height=66 />
                        <ul>
                            <li>Click on the author or title to search for them on plug.dj.</li>
                            <li>Click on the channel or song name to open them in a new tab.</li>
                        </ul>
                    </div>

                    <button class='wt-p0-back'>back</button>
                    <button class='wt-p0-next continue'>next</button>
                </div>

                <div class='step fade-in wt-p0-info-footer' data-screen=info-footer>
                    <h1>Info Footer</h1>
                    <p>
                        One last thing, plug_p0ne replaces the footer (the section below the chat) with something more useful.<br>
                        To get to the Settings, the Shop or your Inventory, simply click anywhere on the footer.
                    </p>
                    <p>
                        The Info Footer only will work for logged in users, though.
                    </p>

                    <button class='wt-p0-back'>back</button>
                    <button class='wt-p0-next continue'>next</button>
                </div>

                <div class='step fade-in wt-p0-end' data-screen=end>
                    <h1>END!</h1>
                    <p>
                        Alright that's it!<br>
                        Hopefully you'll have some fun with plug_p0ne!
                    </p>
                    <p>
                        Just play around with the settings to find some more great features. :3
                    </p>

                    <button class='wt-p0-back'>back</button>
                    <button class='wt-p0-next continue'>finish</button>
                </div>

                <div class=nav>
                    <i class=selected></i> <i></i> <i></i> <i></i> <i></i> <i></i> <i></i> <i></i> <i></i>
                    <button class='wt-p0-skip'>skip walkthrough</button
                </div>
            </div>
        "
            .on \click, \.wt-p0-button, !->
                $this = $ this
                $this .trigger "button-#{$this.index!} button-#{$this.text!}"
            .on \click, \.wt-p0-skip, !~>
                @disable!
                return false
            .on \click, \.wt-p0-next, !-> nextScreen(i+1)
            .on \click, \.wt-p0-back, !-> nextScreen(i-1)
            .on \click, '.nav i', !->
                nextScreen $(this).index!
            .appendTo $app
        $app .addClass \is-wt-p0
        $pSettingsClosed = $el .find \.wt-p0-settings-closed
        $pSettingsOpen = $el .find \.wt-p0-settings-open
        $pSongInfoClosed = $el .find \.wt-p0-songinfo-closed
        $pSongInfoOpen = $el .find \.wt-p0-songinfo-open

        DUMMY_VIDEO =
            cid: \wZZ7oFKsKzY
            format: 1
            author: "plug_p0ne test"
            title: "Nyan Cat 1h"
            duration: 36001
            image: "https://i.ytimg.com/vi/wZZ7oFKsKzY/default.jpg"


        #== show help screens ==
        #ToDo @screenClose(), accomplished(), step(num)
        screens = [
            !~> # welcome
                $screen .removeClass \revealed
                $nextBtn_ = $nextBtn
                p0neSettings.toggleMenu(false)
                sleep 2_000ms !~>
                    $screen .addClass \revealed
                    sleep 3_000ms, !-> if i == 0
                        $nextBtn_
                            .text "next"

            !~> # settings icon
                do addListener $ppI, \click, !~>
                    if not p0neSettings._settings.open
                        $pSettingsClosed .show!; $pSettingsOpen .hide!
                        $screen .css left: '', top: ''
                        blinking($ppI)
                    else
                        blinking!
                        $pSettingsClosed .hide!; $pSettingsOpen .show!
                        if $pp0.text! == \2 #DEBUG
                            $screen .css left: 160px, top: 100px
                        else
                            $screen .css left: $ppW.width! + 60px, top: ''
                        blinking $nextBtn
                        accomplished!

                @screenClose = !~>
                    p0neSettings.toggleMenu(false)

            !~> # dblclick2mention
                $playback = $ \#playback
                blinking $hdButton

            !~> # Stream Settings
                $playback = $ \#playback
                blinking $hdButton

            !~> # Automute
                var m
                if currentMedia?
                    do addListener API,  \advance, !->
                        if not m := currentMedia.get \media
                            currentMedia .set new Backbone.Model DUMMY_VIDEO
                        else
                            step(if isSnoozed! then 2 else 1)

                do addListener API, \p0ne:changeMode, (m) !~>
                    step(if m == \off then 2 else 1)
                if isSnoozed!
                    step(2)

                do addListener $snoozeBtn, \click, !~>
                        console.log "smooze [sic]", automute.songlist[API.getMedia!.cid]
                        if automute.songlist[API.getMedia!.cid]
                            accomplished!

                blinking $snoozeBtn

                @screenClose = !->
                    currentMedia.set \media, m if m

            !~> # Automute (remove)
                $spI = automute._$settings.find '.p0ne-settings-panel-icon .icon'
                $summary = p0neSettings.groups[automute.settings].find \.p0ne-settings-summary
                # step 1
                blinking $ppI
                addListener $ppI, \click, cb1 = !~>
                    if not p0neSettings._settings.open
                        step(1)
                        $screen .css left: "", top: ''
                    else
                        step(2)
                        if $pp0.text! == \2 #DEBUG
                            $screen .css left: 160px, top: 150px
                        else
                            $screen .css left: $ppW.width! + 20px, top: ''
                        blinking $summary
                        cb2!

                # step 2
                addListener $summary, \click, cb2 = !~> requestAnimationFrame !~>
                    if p0neSettings._settings.openGroup != automute.settings
                        step(2)
                        $spI .css boxShadow: '', borderRadius: ''
                        blinking $summary
                    else
                        step(3)
                        if $pp0.text! == \2 #DEBUG
                            $screen .css left: 580px
                        blinking!
                        $spI .css do
                                boxShadow: '0 0 25px white'
                                borderRadius: \50%
                        cb3!

                # step 3
                var settingsPanel
                addListener automute._$settings, \click, \.p0ne-settings-panel-icon, cb3 = !~> requestAnimationFrame !~>
                    if not automute._$settingsPanel?.open
                        step(3)
                        $spI .css do
                            boxShadow: '0 0 25px white'
                            borderRadius: \50%
                        if $pp0.text! == \2 #DEBUG
                            $screen .css left: 580px
                    else
                        step(4)
                        $spI .css boxShadow: '', borderRadius: ''


                        # step 4
                        # add a dummy song to automute if automute list is empty
                        for k of automute.songlist
                            break
                        else
                            automute.songlist[DUMMY_VIDEO.cid] = DUMMY_VIDEO
                            automute.createRow DUMMY_VIDEO.cid

                        if $pp0.text! == \2 #DEBUG
                            $screen .css left: 100px
                        else
                            $screen .css left: $ppW.width! + 520px
                        if automute._$settingsPanel and settingsPanel != automute._$settingsPanel.wrapper
                            if settingsPanel
                                settingsPanel .off \click, \.song-remove, accomplished
                            #ToDo add dummy song to automute list, if it's empty
                            settingsPanel := automute._$settingsPanel.wrapper
                            addListener settingsPanel, \click, \.icon-clear-input, accomplished
                        blinking!

                cb1!

                @screenClose = !~>
                    $spI? .css boxShadow: '', borderRadius: ''
                    p0neSettings.toggleMenu(false)
                    if automute.songlist[DUMMY_VIDEO.cid]
                        delete automute.songlist[DUMMY_VIDEO.cid]
                        automute.rows[DUMMY_VIDEO.cid] .remove!

            !~> # Song Info
                do addListener $bar, \click, !->
                    if b = $songInfo .hasClass \expanded
                        blinking $bar
                        $screen .css top: 220px
                        $pSongInfoClosed .hide!; $pSongInfoOpen .show!
                        accomplished!
                    else
                        blinking $songInfo.find(\.p0ne-song-info-meta)
                        $screen .css top: ""
                        $pSongInfoClosed .show!; $pSongInfoOpen .hide!
                @screenClose = !~>
                    if $songInfo .hasClass \expanded
                        $bar .click!
                    p0neSettings.toggleMenu(false)
                    $ '#playlist-button .icon-arrow-down'
                        .click! # will silently fail if playlist is already open, which is desired

            !~> # Info Footer
                addListener $footerInfo, \click, cb = !->
                    $screen .css right: 20px
                    $body.one \click, !->
                        $screen .css right: -330px
                if $footerUser.hasClass \menu
                    cb!

            !~> # End
            @disable # already bound
        ]
        /**  other interesting things to show:
         * avoid history-play
         * song-notif
         * user-history
         *
         * moderator-only stuff
         *      - AFK Timer
         */


        $screen = $()
        $screens = $el .find \.step
        $navDots = $el .find '.nav i'
        $el .find '.wt-p0-steps li:first' .addClass \selected

        $el .find \.snooze-btn
            .css background: $app.find('#playback .snooze').css(\background)
            .click !->
                # using alerts is disencouraged, but it's kinda a quick fix.
                alert "No you doozie!\nclick the REAL snooze button above ;)"


        aux.addListener $ppI, \click, !~> #DEBUG
            $app
                .removeClass "wt-p0-settings-mode-0 wt-p0-settings-mode-1 wt-p0-settings-mode-2"
                .addClass "wt-p0-settings-mode-#{$pp0.text!}"


        var $nextBtn, $steps
        !~function nextScreen num
            @screenClose!
            $navDots.eq(i) .removeClass \selected
            blinking!
            for [target, args] in listeners
                target.off .apply target, args

            i := num
            $screen  := $screens.eq(i)
            $nextBtn := $screen .find \.wt-p0-next
            $steps   := $screen .find '.wt-p0-steps li'
            $navDots.eq(i) .addClass \selected

            $app
                .removeClass "wt-p0-screen-#{@screenClass}"
                .addClass    "wt-p0-screen-#{@screenClass = $screen.data \screen}"
            steps[i] || = 1
            @screenClose = $.noop
            screens[i]!

        !function step num
            $screen
                .removeClass "wt-p0-step-#{steps[i]}"
                .addClass    "wt-p0-step-#{num}"
            $steps.eq(steps[i] - 1) .removeClass \selected
            $steps.eq(num - 1)      .addClass    \selected
            steps[i] := num
        !function accomplished
            $steps.eq(steps[i] - 1) .removeClass \selected
            $nextBtn
                .text "continue"
                .addClass \continue

        var blinkingInterval, $blinkingEl
        !function blinking $el
            clearInterval(blinkingInterval)
            if $blinkingEl := $el
                blinkingInterval := setInterval(blinkingCB, 3_000ms)
        !function blinkingCB
            $blinkingEl .p0neFx \blink

        listeners = []
        !function addListener target, ...args
            target.on .apply target, args
            listeners[*] = [target, args]
            return args[*-1]

        nextScreen(0)


    disable: !->
        $app .removeClass "is-wt-p0 wt-p0-settings-mode-0 wt-p0-settings-mode-1 wt-p0-settings-mode-2 wt-p0-screen-#{@screenClass}"
        @screenClose!
