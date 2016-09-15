/**
 * Tutorial and help GUI for plug_p0ne
 *
 * @author jtbrinkmann aka. Brinkie Pie
 * @license MIT License
 * @copyright (c) 2015 J.-T. Brinkmann
 */

module \p0neHelp, do
    optional: <[ currentMedia ]>
    setup: ({$create, css}) ->
        #== create CSS ==
        #ToDo move this to plug_p0ne.css
        css "
            .p0ne-cloak {
                opacity: 0.8;
            }
            .p0ne-cloak-part {
                position: absolute;
                top: 0;
                left: 0;
                width: 100%;
                height: 100%;

                background: #222;
            }

            .p0ne-help-title-reveal {
                display: inline-block;
                width: 0;
                transition: width 1s ease-in 1s;
            }
        "

        #== create DOM elements ==
        @cloak = $create '
                <div class=p0ne-cloak-part></div>
                <div class=p0ne-cloak-part></div>
                <div class=p0ne-cloak-part style="right:0"></div>
                <div class=p0ne-cloak-part style="bottom:0"></div>
            '
        @text = $create '<div class=p0ne-help>'
            .on \click, \.p0ne-help-button, ->
                $this = $ this
                $this .trigger "button-#{$this.index!} button-#{$this.text!}"

        #== show help screens ==
        i = -1
        screens = [
            ~> # welcome
                helpScreen do
                    "welcome to"
                    "<div>
                        p
                        <div class=p0ne-help-title-reveal>lug_p</div>
                        <span class=plug-help-title-0>0</span>
                        <div class=p0ne-help-title-reveal>0ne</div>
                    </div>"
                    ,[
                        * label: "skip", callback: ->
                            p0neHelp .disable!
                        * label: "continue >", callback: nextScreen
                    ]
                @text .find \.p0ne-help-title-reveal .addClass \revealed

            ~> # settings icon
                helpScreen do
                    "Settings"
                    "
                        To open/close the plug_p0ne settings, click the p0 icon in the top right

                        <div class=p0ne-help-waitforclick>click the icon now</div>
                    "
                    [
                        * label: "skip", callback: nextScreen
                    ]
                addListener \on, $('#p0ne-menu .p0ne-icon'), \click, cb = ~>
                    if not p0neSettings.groupToggles.p0neSettings
                        @text .find \.p0ne-help-waitforclick .text "Good! now click it again to open it up again"
                        addListener \once, $('#p0ne-menu .p0ne-icon'), \click, cb
                    else
                        @text .find \.p0ne-help-waitforclick .text "Alright, let's move on"
                        @text .find \.p0ne-help-buttons .append do
                            $ '<button class=p0ne-help-button>'
                                .text "continue >"
                                .click ->
                                    $ '#p0ne-menu .p0ne-icon' .off \click, cb
                                    nextScreen!

            ~> # dblclick2mention
                helpScreen do
                    "dblclick2mention"
                    "
                        <p>
                            Most of plug_p0ne's awesome features are not immediately obvious.<br>
                            Let's try out some, to see what we can do with plug_p0ne.
                        </p>
                        <p>
                            One of best is the so called \"DblClick username to Mention\", which let's you @mention others simply by double clicking their usernames (e.g. in their chat messages or join/leave notifications, but it works just about everywhere).
                        </p>
                        <p>
                            <img src='...'>
                        </p>
                    "
                    [
                        * label: "skip", callback: nextScreen
                    ]

            ~> # Stream Settings
                helpScreen do
                    "Stream Settings"
                    "
                        <p>
                            plug_p0ne adds a new audio-only mode to Youtube videos and let's you quickly switch between Video, Audio-Only and Stream-Off (no video/sound) by using the buttons on the so-called \"Playback Area\".
                        </p>
                        <p>
                            Move your cursor over the Playback Area (where the videos are playing) to see them.
                        </p>
                    "
                    [
                        * label: "skip", callback: nextScreen
                    ]
                addListener \once, $(\#playback), \mouseOver, -> sleep 500ms ->
                    $streamSettingsBtn = $ '#playback .hd' .p0neFx \p0ne-fx-boxblink
                    helpScreen do
                        "Stream Settings"
                        "
                            <p>
                                Great!<br>
                                Now you can see the buttons to switch between the different modes.
                            </p>
                        "
                        [
                            * label: "continue", callback: nextScreen
                        ]

            ~> # Automute
                var m
                helpScreen do
                    "Automute"
                    "
                        <p>
                            You can also <b>automute</b> songs you really dislike. This way, they will automatically get muted whenever they get played.
                        </p>
                        <p>
                            To add a song to automute, do the following:
                            <ol>
                                <li>Move your cursor over the Playback area to see the controls.</li>
                                <li>Click on \"Snooze\" to snooze the current song (if it's playing)</li>
                                <li>When snoozed, the snooze button will turn into an automute -add or -remove button</li>
                            </ol>
                        </p>
                        <p>
                            Let's try it out!
                        </p>
                    "
                    [
                        * label: "skip", callback: endNyan
                    ]

                cloakPlaybackControls!
                if currentMedia?
                    do addListener API, \advance, !->
                        if not m := currentMedia.get \media
                            currentMedia .set new Backbone.Model do
                                cid: \wZZ7oFKsKzY
                                format: 1
                                author: "plug_p0ne test"
                                title: "Nyan Cat 1h"
                                duration: 36001
                                image: "https://i.ytimg.com/vi/wZZ7oFKsKzY/default.jpg"

                addListener \once, $('#playback-controls .snooze'), \click, -> sleep 500ms explainAutomuteBtn
                if isSnoozed!
                    explainAutomuteBtn!

                !function explainAutomuteBtn
                    helpScreen do
                        "Automute"
                        "
                            <p>
                                You can now use the automute button
                            </p>
                            <p>
                                That said, if there is an automuted song you would like to stop automuting, either use the song-list in the automute settings, or -if the song is playing-  snooze it and click \"remove from automute\".
                            </p>
                        "
                        [
                            * label: "end", callback: endNyan
                        ]
                !function endNyan
                    if m
                        currentMedia.set \media, m
                    nextScreen!
            ~> # End
                var m
                helpScreen do
                    "End"
                    "
                        <p>
                            Alright that's it!<br>
                            Hopefully you'll have some fun with plug_p0ne :3
                        </p>
                        <p>
                            Just play around with the settings to find some more great features ;)
                        </p>
                    "

            /**  other interesting things to show:
             * avoid history-play
             * song-notif
             * user-history
             *
             * moderator-only stuff
             *      - AFK Timer
             */
        ]

        var requiredModule
        $requiredModuleWarning = $ '<div class=p0ne-help-warning>'
            .text 'But first we need to enable the module'

        !function ensureModule moduleName
            if not m = window[moduleName]
                console.error "[p0neHelp] couldn't find expected module '#moduleName'"
                nextScreen!
            else
                $requiredModuleWarning
                    .insertBefore @text .find \.p0ne-help-buttons
                if m.disabled
                    showEnableModuleWarning(m)

        !function cloakPlaybackControls
            cloak \#playback
            addListener $(\#playback), \mouseOver, -> sleep 500ms ->
                cloak '#playback-controls .snooze'
            if $ \#playback-controls .css \display == \block
                cloak '#playback-controls .snooze'
            addListener $(\#playback), \mouseOut, -> sleep 500ms ->
                cloak \#playback

        showEnableModuleWarning = addListener API, \p0ne:moduleDisabled, (module_) ~>
            if module_.name == requiredModule
                $requiredModuleWarning .show!
                # open settings groups
                if not p0neSettings.groupToggles[module_.settings]
                    p0neSettings.groups[module_.settings] .find \.p0ne-settings-summary .click!
                # highlight module._$setting
                ...

        #hideEnableModuleWarning ... ~>
        #   if module_.name == requiredModule
        #       $requiredModuleWarning .hide!
        #       highlight original focus element again
        nextScreen!
        function nextScreen
            screens[++i]!

    helpScreen: (title, body, buttons, $el) ->
        #= title & body =
        @text
            .hide!
            .html "
                <h2>#title</h2>
                <p>#body</p>
            "

        #= buttons =
        $btns = '<div class=p0ne-help-buttons>'
        for btn in buttons
            $btns .append do
                $ '<button class=p0ne-help-button>'
                    .text btn.label
                    .click btn.callback
        @text
            .append $btns
            .fadeIn!

        #= cloak =
        if $el
            pos = $el .offset!
            @cloak pos.x - 5px, pos.y - 5px, $el.width! + 10px, $el.height! + 10px
        else
            @cloak 0, 0, 0, 0

    cloak: (x, y, w, h) ->
        @cloak.eq(0).css do # top
            height: y
        @cloak.eq(1).css do # left
            width: x
        @cloak.eq(2).css do # right
            left: x + w
        @cloak.eq(3).css do # bottom
            top: y + h

        @cloak
            .css display: \block
            .animate do
                opacity: 1

    uncloak: (cb) ->
        @cloak.animate do
                opacity: 0
                ,400ms
                ,cb
