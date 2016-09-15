/**
 * Settings pane for plug_p0ne
 *
 * @author jtbrinkmann aka. Brinkie Pie
 * @license MIT License
 * @copyright (c) 2015 J.-T. Brinkmann
 */

/*####################################
#              SETTINGS              #
####################################*/
module \p0neSettings, do
    _settings:
        groupToggles: {p0neSettings: true, base: true}
    setup: ({$create, addListener},,,oldModule) ->
        @$create = $create

        groupToggles = @groupToggles = @_settings.groupToggles ||= {p0neSettings: true, base: true}

        #= create DOM elements =
        $ppM = $create "<div id=p0ne-menu>" # (only the root needs to be created with $create)
            .insertAfter \#app-menu
        $ppI = $create "<div class=p0ne-icon>p<div class=p0ne-icon-sub>0</div></div>"
            .appendTo $ppM
        $ppW = @$ppW = $ "<div class=p0ne-settings-wrapper>"
            .appendTo $ppM
        $ppS = $create "<div class='p0ne-settings noselect'>"
            .appendTo $ppW
        $ppP = $create "<div class=p0ne-settings-popup>"
            .appendTo $ppM
            .fadeOut 0

        #debug
        #@<<<<{$ppP, $ppM, $ppI}

        #= add "simple" settings =
        @$vip = $ "<div class=p0ne-settings-vip>" .appendTo $ppS

        @toggleMenu groupToggles.p0neSettings

        #= settings footer =
        @$ppInfo = $ "
            <div class=p0ne-settings-footer>
                <div class=p0ne-icon>p<div class=p0ne-icon-sub>0</div></div>
                <div class=p0ne-settings-version>v#{p0ne.version}</div>
                <div class=p0ne-settings-help-btn>help</div>
                <div class=p0ne-settings-expert-toggle>show all options</div>
            </div>"
            .appendTo $ppS

        #= add toggles for existing modules =
        for ,module of p0ne.modules
            @addModule module


        #= add DOM event listeners =
        # slide settings-menu in/out
        $ppI .click ~> @toggleMenu!

        # toggle groups
        addListener $body, \click, \.p0ne-settings-summary, throttle 200ms, (e) ->
          $s = $ this .parent!
          if $s.data \open # close
            $s
                .data \open, false
                .removeClass \open
                .stop! .animate height: 40px, \slow /* magic number, height of the summary element */
            groupToggles[$s.data \group] = false
          else
            $s
                .data \open, true
                .addClass \open
                .stop! .animate height: $s.children!.length * 44px, \slow /* magic number, height of a .p0ne-settings-item*/
            groupToggles[$s.data \group] = true
          e.preventDefault!

        addListener $ppW, \click, \.checkbox, throttle 200ms, ->
            # this gets triggered when anything in the <label> is clicked
            $this = $ this
            enable = this .checked
            $el = $this .closest \.p0ne-settings-item
            module = $el.data \module
            module = window[module] ||{} if typeof module == \string
            #console.log "[p0neSettings] toggle", module.displayName, "=>", enable
            if enable
                module.enable!
            else
                module.disable!

        addListener $ppW, \mouseover, \.p0ne-settings-has-more, ->
            $this = $ this
            module = $this .data \module
            $ppP .html "
                    <div class=p0ne-settings-popup-triangle></div>
                    <h3>#{module.displayName}</h3>
                    #{module.help}
                    #{if!   module.screenshot   then'' else
                        '<img src='+module.screenshot+'>'
                    }
                "
            l = $ppW.width!
            maxT = $ppM .height!
            h = $ppP .height!
            t = $this .offset! .top - 50px
            tt = t - h/2 >? 0px
            diff = tt - (maxT - h - 30px)
            if diff > 0
                t += diff + 10px - tt
                tt -= diff
            else if tt != 0
                t = \50%
            $ppP
                .css top: tt, left: l
                .stop!.fadeIn!
            $ppP .find \.p0ne-settings-popup-triangle
                .css top: t
        addListener $ppW, \mouseout, \.p0ne-settings-has-more, ->
            $ppP .stop!.fadeOut!
        addListener $ppP, \mouseover, ->
            $ppP .stop!.fadeIn!
        addListener $ppP, \mouseout, ->
            $ppP .stop!.fadeOut!

        # add p0ne.module listeners
        addListener API, \p0ne:moduleLoaded, (module) ~> @addModule module
        addListener API, \p0ne:moduleDisabled, (module_) ~>
            module_._$settings?
                .removeClass \p0ne-settings-item-enabled
                .find \.checkbox
                    .attr \checked, false
            module_._$settingsExtra?
                .stop!
                .slideUp ->
                    $ this .remove!
            console.log "[p0neSettings:disabledModule]", module_.name
        addListener API, \p0ne:moduleEnabled, (module) ~>
            module._$settings?
                .addClass \p0ne-settings-item-enabled
                .find \.checkbox .0 .checked=true
            @settingsExtra true, module
            console.log "[p0neSettings:enabledModule]", module.name
        addListener API, \p0ne:moduleUpdated, (module, module_) ~>
            console.log "[p0neSettings:updatedModule]", module.name, module_.name
            if module.settings
                @addModule module, module_
                if module.help != module_.help and module._$settings?.is \:hover
                    # force update .p0ne-settings-popup (which displays the module.help)
                    module._$settings .mouseover!

        addListener $body, \click, \#app-menu, ~> @toggleMenu false
        if _$context?
            addListener _$context, 'show:user show:history show:dashboard dashboard:disable', ~> @toggleMenu false

        # plugCubed compatibility
        addListener $body, \click, \#plugcubed, ~>
            @toggleMenu false

        # Firefox compatibility
        # When Firefox calculates the width of .p0ne-settings, it doesn't add the width of the scrollbar (if any)
        # This causes a second, horizontal scrollbar to be displayed
        # and/or the module icons to be overlayed by the scrollbar
        # to fix this, we add a padding to the .p0ne-settings-wrapper width the size of the scrollbar
        # it looks ugly, but it does the job
        _.defer ->
            d = $ \<div>
                .css do
                    height: 100px, width: 100px, overflow: \auto
                .append do
                    $ \<div> .css height: 102px, width: 100px
                .appendTo \body
            if \scrollLeftMax of d.0
                scrollLeftMax = d.0.scrollLeftMax
            else
                d.0.scrollLeft = 999px
                scrollLeftMax = d.0.scrollLeft
            if scrollLeftMax != 0px # on proper browsers, it should be 0
                # on some browsers, `scrollLeftMax` should be the width of the scrollbar
                $ppW .css paddingRight: scrollLeftMax
            d.remove!

    toggleMenu: (state) ->
        if state ?= not @groupToggles.p0neSettings
            @$ppW.slideDown!
        else
            @$ppW.slideUp!
        @groupToggles.p0neSettings = state


    groups: {}
    moderationGroup: $!
    addModule: (module, module_) !->
        if module.settings
            # prepare extra icons to be added to the module's settings element
            itemClasses = \p0ne-settings-item
            icons = ""
            for k in <[ help screenshot ]> when module[k]
                icons += "<div class=p0ne-settings-#k></div>"
            if icons.length
                icons = "<div class=p0ne-settings-icons>#icons</div>"
                itemClasses += ' p0ne-settings-has-more'
            itemClasses += ' p0ne-settings-has-extra' if module.settingsExtra
            itemClasses += ' p0ne-settings-item-enabled' if not module.disabled

            if module.settingsVip
                # VIP settings get their special place
                $s = @$vip
                itemClasses += ' p0ne-settings-is-vip'
            else if not $s = @groups[module.settings]
                # create settings group if not yet existing
                $s = @groups[module.settings] = $ '<div class=p0ne-settings-group>'
                    .data \group, module.settings
                    .append do
                        $ '<div class=p0ne-settings-summary>' .text module.settings.toUpperCase!
                    .insertBefore @$ppInfo
                if @_settings.groupToggles[module.settings]
                    $s
                        .data \open, true
                        .addClass \open
                if module.settings == \moderation
                    $s .addClass \p0ne-settings-group-moderation
            # otherwise we already created the settings group

            # create the module's settings element and append it to the settings group
            # note: $create doesn't have to be used, because the resulting elements are appended to a $create'd element
            module._$settings = $ "
                    <label class='#itemClasses'>
                        <input type=checkbox class=checkbox #{if module.disabled then '' else \checked} />
                        <div class=togglebox><div class=knob></div></div>
                        #{module.displayName}
                        #icons
                    </label>
                "
                .data \module, module

            if module_?._$settings?.parent! .is $s
                module_._$settings
                    .after do
                        module._$settings
                            .addClass \updated
                    .remove!
                sleep 2_000ms, ->
                    module._$settings .removeClass \updated
                @settingsExtra false, module, module_
            else
                module._$settings .appendTo $s

            # (animatedly) open the settings group
            if @_settings.groupToggles[module.settings] and not module.settingsVip
                $s .stop! .animate height: $s.children!.length * 44px, \slow

            # render extra settings element if module is enabled
            if not module.disabled
                @settingsExtra false, module

    settingsExtra: (autofocus, module, module_) ->
        try
            module_?._$settingsExtra? .remove!
            if module.settingsExtra
                module.settingsExtra do
                    module._$settingsExtra = $ "<div class=p0ne-settings-extra>"
                        .hide!
                        .insertAfter module._$settings
                # using rAF because otherwise jQuery calculates the height incorrectly
                requestAnimationFrame ~>
                    module._$settingsExtra
                        .slideDown!
                    if autofocus
                        module._$settingsExtra .find \input .focus!
        catch err
            console.error "[#{module.name}] error while processing settingsExtra", err.stack
            module._$settingsExtra? .remove!