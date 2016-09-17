/**
 * Tutorial and help GUI for plug_p0ne
 *
 * @author jtbrinkmann aka. Brinkie Pie
 * @license MIT License
 * @copyright (c) 2015 J.-T. Brinkmann
 */

module \p0neHelp, do
    optional: <[ currentMedia ]>
    require: <[ automute p0neSettings ]>
    setup: ({$create, css}) ->
        #== create CSS ==
        #ToDo move this to plug_p0ne.css
        #css \p0neHelp, ""

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
                    <button class=wt-p0-next>skip</button>
                </div>

                <div class='step fade-in wt-p0-dblclick2mention' data-screen=dblclick2mention>
                    <h1>dblclick2mention</h1>
                    <p>
                        Most of plug_p0ne's awesome features are not immediately obvious.<br>
                        Let's try out some, to see what we can do with plug_p<span class=wt-p0-0>0</span>ne.
                    </p>
                    <p>
                        One of best is the so called \"DblClick username to Mention\", which let's you @mention others simply by double clicking their usernames (e.g. in their chat messages or join/leave notifications, but it works just about everywhere).<br>
                        This is great to quickly greet friends, for example.
                    </p>
                    <p>
                        [insert image]<!-- <img src='...'> -->
                    </p>

                    <button class='wt-p0-next continue'>next</button>
                </div>

                <div class='step fade-in wt-p0-stream-settings' data-screen=stream-settings>
                    <h1>Stream Settings</h1>
                    <p>
                        plug_p0ne adds a new audio-only mode to videos and let's you quickly switch between<br><i class='icon icon-stream-video'></i> Video,<br><i class='icon icon-stream-audio'></i> Audio-Only and<br><i class='icon icon-stream-off'></i> Stream-Off (no video/sound).
                    </p>
                    <p>
                        You can click the icons in the top-middle to change between the modes.
                    </p>

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

                    <button class=wt-p0-next>skip</button>
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

                    <button class='wt-p0-next continue'>finish</button>
                </div>

                <div class=nav>
                    <i class=selected></i><i></i><i></i><i></i><i></i><i></i><i></i>
                    <button class='wt-p0-skip wt-p0-next'>skip walkthrough</button
                </div>
            </div>
        "
            .on \click, \.wt-p0-button, ->
                $this = $ this
                $this .trigger "button-#{$this.index!} button-#{$this.text!}"
            .on \click, \.wt-p0-skip, !~>
                @disable!
                return false
            .on \click, \.wt-p0-next, !-> nextScreen(i+1)
            .on \click, '.nav i', !->
                nextScreen $(this).index!
            .appendTo $app
        $app .addClass \is-wt-p0


        #== show help screens ==
        #ToDo @screenClose(), accomplished(), step(num)
        screens = [
            ~> # welcome
                $screen .removeClass \revealed
                $nextBtn_ = $nextBtn
                p0neSettings.toggleMenu(false)
                sleep 2_000ms ~>
                    $screen .addClass \revealed
                    sleep 3_000ms, !-> if i == 0
                        $nextBtn_
                            .text "continue"

            ~> # settings icon
                $divClosed = $el .find \.wt-p0-settings-closed
                $divOpen = $el .find \.wt-p0-settings-open
                $ppI.on \click, cb = ~>
                    if not p0neSettings.groupToggles.p0neSettings
                        $divClosed .show!; $divOpen .hide!
                        $screen .css left: ""
                        blinking($ppI)
                    else
                        blinking!
                        $divClosed .hide!; $divOpen .show!
                        if $pp0.text! == \2 #DEBUG
                            $screen .css left: 160px, top: 100px
                        else
                            $screen .css left: $ppW.width! + 20px
                        blinking $nextBtn
                        accomplished!
                cb!

                @screenClose = ~>
                    $ppI .off \click, cb
                    p0neSettings.toggleMenu(false)

            ~> # dblclick2mention

            ~> # Stream Settings
                $playback = $ \#playback
                blinking $hdButton

            ~> # Automute
                var m
                if currentMedia?
                    API.on \advance, cb1 = !->
                        if not m := currentMedia.get \media
                            currentMedia .set new Backbone.Model do
                                cid: \wZZ7oFKsKzY
                                format: 1
                                author: "plug_p0ne test"
                                title: "Nyan Cat 1h"
                                duration: 36001
                                image: "https://i.ytimg.com/vi/wZZ7oFKsKzY/default.jpg"
                        else
                            step(if isSnoozed! then 2 else 1)
                    cb1!

                API.on \p0ne:changeMode, cb2 = (m) !~>
                    step(if m == \off then 2 else 1)
                if isSnoozed!
                    step(2)

                $snoozeBtn
                    .on \click, cb3 = !~>
                        console.log "smooze [sic]", automute.songlist[API.getMedia!.cid]
                        if automute.songlist[API.getMedia!.cid]
                            accomplished!

                blinking $snoozeBtn

                @screenClose = !->
                    if m
                        currentMedia.set \media, m
                    API
                        .off \advance, cb1
                        .off \p0ne:changeMode, cb2
                    $snoozeBtn .off \click, cb3

            ~> # Automute (remove)
                $spI = automute._$settings.find '.p0ne-settings-panel-icon .icon'
                $summary = p0neSettings.groups[automute.settings].find \.p0ne-settings-summary
                export test = -> $spI
                # step 1
                blinking $ppI
                $ppI.on \click, cb1 = !~>
                    if not p0neSettings.groupToggles.p0neSettings
                        step(1)
                        $screen .css left: ""
                    else
                        step(2)
                        if $pp0.text! == \2 #DEBUG
                            $screen .css left: 160px, top: 150px
                        else
                            $screen .css left: $ppW.width! + 20px
                        blinking $summary
                        cb2!

                # step 2
                $summary .on \click, cb2 = !~> requestAnimationFrame !~>
                    if not p0neSettings.groupToggles[automute.settings]
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
                automute._$settings .on \click, \.p0ne-settings-panel-icon, cb3 = !~> requestAnimationFrame !~>
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
                        if $pp0.text! == \2 #DEBUG
                            $screen .css left: 100px
                        else
                            $screen .css left: $ppW.width! + 520px
                        if settingsPanel != automute._$settingsPanel
                            if settingsPanel
                                settingsPanel .off \click, \.song-remove, accomplished
                            #ToDo add dummy song to automute list, if it's empty
                            settingsPanel := automute._$settingsPanel
                                .wrapper .on \click, \.icon-clear-input, accomplished
                        blinking!

                cb1!

                @screenClose = ~>
                    $ppI .off \click, cb1
                    $summary .off \click, cb2
                    automute._$settings? .off \click, cb3
                    $spI? .css boxShadow: '', borderRadius: ''
                    settingsPanel?.off \click, \.icon-clear-input, accomplished
                    p0neSettings.toggleMenu(false)

            ~> # End
            @~disable

        ]
        /**  other interesting things to show:
         * avoid history-play
         * song-notif
         * user-history
         *
         * moderator-only stuff
         *      - AFK Timer
         */


        var $nextBtn, $steps
        $screen = $()
        $screens = $el .find \.step
        $navDots = $el .find '.nav i'
        $el .find '.wt-p0-steps li:first' .addClass \selected

        $el .find \.snooze-btn
            .css background: $app.find('#playback .snooze').css(\background)
            .click !->
                # using alerts is disencouraged, but it's kinda a quick fix.
                alert "No you doozie!\nclick the REAL snooze button above ;)"

        nextScreen(0)

        !~function nextScreen num
            @screenClose!
            $navDots.eq(i) .removeClass \selected
            blinking!

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

    disable: !->
        $app
            .removeClass "wt-p0-screen-#{@screenClass}"
            .removeClass \is-wt-p0
        @screenClose!
