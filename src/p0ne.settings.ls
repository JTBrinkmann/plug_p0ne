/**
 * Settings pane for plug_p0ne
 *
 * @author jtbrinkmann aka. Brinkie Pie
 * @license MIT License
 * @copyright (c) 2015 J.-T. Brinkmann
 */
console.log "~~~~~~~ p0ne.settings ~~~~~~~"

/*####################################
#              SETTINGS              #
####################################*/
module \p0neSettings, do
    _settings:
        open: false
        openGroup: \base
        expert: false
        largeSettingsPanel: true
    setup: ({$create, addListener}, p0neSettings, oldModule) !->
        #= create DOM elements =
        $ppM = $create "<div id=p0ne-menu>" # (only the root needs to be created with $create)
            .insertAfter \#app-menu
        $ppI = $ "<div class=p0ne-icon>p<div class=p0ne-icon-sub>0</div></div>"
            .appendTo $ppM
        $ppW = @$ppW = $ "<div class=p0ne-settings-wrapper>"
            .appendTo $ppM
        $ppS = $ "<div class='p0ne-settings noselect'>"
            .appendTo $ppW
        $ppP = $ "<div class=p0ne-settings-popup>"
            .appendTo $ppM
            .hide!

        #= add "simple" settings =
        @$vip = $ "<div class=p0ne-settings-vip>" .appendTo $ppS
        @$vip.items = @$vip

        #= settings footer =
        @$ppInfo = $ "
            <div class=p0ne-settings-footer>
                <div class=p0ne-icon>p<div class=p0ne-icon-sub>0</div></div>
                <div class=p0ne-settings-version>v#{p0ne.version}</div>
                <div class=p0ne-settings-help-btn>help</div>
            </div>"
            #   <div class=p0ne-settings-expert-toggle>show all options</div>
            .on \click, \.p0ne-settings-help-btn, !->
                p0ne.modules.p0neHelp?.enable!
            .appendTo $ppS

        /*@$expertToggle = @$ppInfo .find \.p0ne-settings-expert-toggle
            .click @~expertToggle*/

        #= add toggles for existing modules =
        for ,module of p0ne.modules when not module.loading
            @addModule module
            module._$settingsPanel?.wrapper .appendTo $ppM


        #= add DOM event listeners =
        # slide settings-menu in/out
        @_settings.open = not @_settings.open
        @_settings.largeSettingsPanel = not @_settings.largeSettingsPanel
        $ppI
            .click !~>
                if @toggleMenu!
                    if @_settings.largeSettingsPanel = not @_settings.largeSettingsPanel
                        $ppW .addClass 'p0ne-settings-large p0ne-settings-expert'
                        $ppI .children! .text '2'
                        $ppP .appendTo $ppW
                        if not @_settings.openGroup
                            p0neSettings.openGroup \base
                    else
                        $ppW .removeClass \p0ne-settings-large
                        $ppI .children! .text '0'
                        $ppP .appendTo $ppM
                        #@toggleExpert(@_settings.expert)
            .click!

        #if @_settings.expert
        $ppW .addClass \p0ne-settings-expert




        # toggle groups
        $ppW.on \click, \.p0ne-settings-summary, throttle 200ms, (e) !->
            group = $ this .parent! .data \group
            if p0neSettings._settings.openGroup != group
                p0neSettings.openGroup group
            else if not p0neSettings._settings.largeSettingsPanel
                p0neSettings.closeGroup group
            e.preventDefault!

        $ppW.on \click, \.checkbox, throttle 200ms, !->
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
        panelIconTimeout = 0
        $ppW.on \click, \.p0ne-settings-panel-icon, (e) !->
            e.stopImmediatePropagation!
            e.preventDefault!

            # throttle
            return if panelIconTimeout
            panelIconTimeout := sleep 200ms, ->
                panelIconTimeout := 0

            $this = $ this
            module = $this .closest \.p0ne-settings-item .data \module
            console.log "[p0ne-settings-panel-icon] clicked", panelIconTimeout, !!module._$settingsPanel, module._$settingsPanel?.open, module._$settingsPanel?.wrapper
            if not module._$settingsPanel
                module._$settingsPanel =
                    open: false
                    wrapper: $ '<div class=p0ne-settings-panel-wrapper>' .appendTo $ppM
                    $el: $ "<div class='p0ne-settings-panel p0ne-settings-panel-#{module.moduleName .toLowerCase!}'>"
                module._$settingsPanel.$el .appendTo module._$settingsPanel.wrapper
                module.settingsPanel(module._$settingsPanel.$el, module)

            offsetLeft = $ppW.width!
            if module._$settingsPanel.open # close panel
                module._$settingsPanel.wrapper
                    .animate do
                        left: offsetLeft - module._$settingsPanel.$el.width!
                        -> module._$settingsPanel.wrapper .hide!
                module._$settingsPanel.open = false
                $this .find \.icon
                    .removeClass \icon-settings-white
                    .addClass \icon-settings-grey
            else # open panel
                module._$settingsPanel.wrapper
                    .show!
                    .css left: offsetLeft - module._$settingsPanel.$el.width!
                    .animate left: offsetLeft
                module._$settingsPanel.open = true
                $this .find \.icon
                    .addClass \icon-settings-white
                    .removeClass \icon-settings-grey

        $ppW.on \mouseover, '.p0ne-settings-item, .p0ne-settings-extra', (e) !->
            if p0neSettings._settings.largeSettingsPanel or $ e.target .is \.p0ne-settings-help
                $module = $ this
                module = $module .data \module
                return if not module.help and not module.screenshot
                $ppP .html "
                        <div class=p0ne-settings-popup-triangle></div>
                        <h3>#{module.displayName}</h3>
                        #{module.help ||''}
                        #{if!   module.screenshot   then'' else
                            '<img src='+module.screenshot+'>'
                        }
                    "
                l = $ppW.width!
                maxT = $ppM .height!
                h = $ppP .height!
                t = $module .offset! .top - 50px
                tt = t - h/2 >? 0px
                diff = tt - (maxT - h - 30px)
                if diff > 0
                    t += diff + 10px - tt
                    tt -= diff
                else if tt != 0
                    t = \50%
                $ppP
                    .css top: tt, left: l
                if p0neSettings._settings.largeSettingsPanel
                    $ppP .show!
                else
                    $ppP .stop! .fadeIn!
                $ppP .find \.p0ne-settings-popup-triangle
                    .css top: 14px >? t
        $ppM.on \mouseout, '.p0ne-settings-has-more, .p0ne-settings-popup', !->
                if p0neSettings._settings.largeSettingsPanel
                    $ppP .hide!
                else
                    $ppP .stop! .fadeOut!
        $ppP.on \mouseover, !->
                if p0neSettings._settings.largeSettingsPanel
                    $ppP .show!
                else
                    $ppP .stop! .fadeIn!

        # add p0ne.module listeners
        #= module INITALIZED =
        addListener API, \p0ne:moduleLoaded, (module) !~> @addModule module

        #= module ENABLED =
        addListener API, \p0ne:moduleEnabled, (module, isUpdate) !~>
            module._$settings?
                .addClass \p0ne-settings-item-enabled
                .find \.checkbox .0 .checked=true
            if not isUpdate
                @loadSettingsExtra true, module

        #= module UPDATED =
        addListener API, \p0ne:moduleUpdated, (module, module_) !~>
            module_._$settingsExtra? .remove!
            module_._$settingsPanel? .remove!
            if module.settings
                @addModule module, module_
            else if module_.settings
                module_._$settings .remove!
                /* # i think this is a highly neglectable edge case
                if module.help != module_.help and module._$settings?.is \:hover
                    # force update .p0ne-settings-popup (which displays the module.help)
                    module._$settings .mouseover!*/

        #= module DISABLES =
        addListener API, \p0ne:moduleDisabled, (module_) !~> if module_._$settings
            module_._$settings
                .removeClass \p0ne-settings-item-enabled
                .find \.checkbox
                    .attr \checked, false
            module_._$settingsExtra?
                .stop!
                .slideUp !->
                    module_._$settingsExtra .remove!

        addListener $body, \click, \#app-menu, !~> @toggleMenu false
        if _$context?
            addListener _$context, 'show:user show:history show:dashboard dashboard:disable', !~> @toggleMenu false

        # plugCubed compatibility
        addListener $body, \click, \#plugcubed, !~>
            @toggleMenu false

        # Firefox compatibility
        # When Firefox calculates the width of .p0ne-settings, it doesn't add the width of the scrollbar (if any)
        # This causes a second, horizontal scrollbar to be displayed
        # and/or the module icons to be overlayed by the scrollbar
        # to fix this, we add a padding to the .p0ne-settings-wrapper width the size of the scrollbar
        # it looks ugly, but it does the job
        _.defer !->
            d = $ \<div>
                .css do
                    height: 100px, width: 100px, overflow: \auto
                .append do
                    $ \<div> .css height: 102px, width: 100px
                .appendTo \body
            if \scrollLeftMax of d.0
                scrollLeftMax = d.0.scrollLeftMax
            else
                d.0.scrollLeft = Number.POSITIVE_INFINITY
                scrollLeftMax = d.0.scrollLeft
            if scrollLeftMax != 0px # on proper browsers, it should be 0
                # on some browsers, `scrollLeftMax` should be the width of the scrollbar
                $ppW .css paddingRight: scrollLeftMax
            d.remove!

        # toggle expert mode
    toggleExpert: (state) !->
        @$expertToggle .text do
            if state ?= @_settings.expert
                "show less options"
            else
                "show all options"
        $ppW .toggleClass \p0ne-settings-expert, state
        @_settings.expert = state

    toggleMenu: (state) !->
        if state ?= not @_settings.open
            @$ppW.css maxHeight: \100%
        else
            @$ppW.css maxHeight: 0
            for ,module of p0ne.modules when module._$settingsPanel?.open # close panel
                    module._$settingsPanel.wrapper
                        .animate do
                            left: @$ppW.width! - module._$settingsPanel.$el.width!
                            -> $(this).hide!
                    module._$settingsPanel.open = false
        return @_settings.open = state


    groups: {}
    groupEmpty: {}
    moderationGroup: $!

    openGroup: (group) !->
        console.info "[openGroup]", group
        if @_settings.openGroup
            @closeGroup @_settings.openGroup

        @_settings.openGroup = group
        $s = @groups[group]
            .removeClass \closed
            .addClass \open
        if @_settings.largeSettingsPanel
            $s .css height: \auto
        else
            requestAnimationFrame !~>
                $s .css height: $s.0.scrollHeight
                sleep 500ms, !~> if @_settings.openGroup == group
                    $s .css height: \auto


    closeGroup: (group) !->
        console.info "[closeGroup]", group, @groups[group], @groups[group]?.0?.scrollHeight
        @_settings.openGroup = false
        $s = @groups[group]
            .removeClass \open
        if @_settings.largeSettingsPanel
            $s
                .css height: 30px
                .addClass \closed
        else
            $s .css height: $s.0.scrollHeight
            requestAnimationFrame !~>
                $s .css height: 30px
                sleep 500ms, !~> if @_settings.openGroup != group
                    $s .addClass \closed

    addModule: (module, module_) !->
        if module.settings
            # prepare extra icons to be added to the module's settings element
            itemClasses = \p0ne-settings-item
            icons = ""
            for k in <[ help screenshot ]> when module[k]
                icons += "<div class=p0ne-settings-#k></div>"
            if module.settingsPanel
                icons += "<div class=p0ne-settings-panel-icon><i class='icon icon-settings-white'></i></div>"
            if icons.length
                icons = "<div class=p0ne-settings-icons>#icons</div>"
                itemClasses += ' p0ne-settings-has-more'
            itemClasses += ' p0ne-settings-has-extra' if module.settingsExtra
            itemClasses += ' p0ne-settings-item-enabled' if not module.disabled
            itemClasses += ' p0ne-settings-item-expert' if not module.settingsSimple

            if module.settingsVip
                # VIP settings get their special place
                $s = @$vip
                itemClasses += ' p0ne-settings-is-vip'
            else if not $s = @groups[module.settings]
                # create settings group if not yet existing
                $s = @groups[module.settings] = $ '<div class=p0ne-settings-group>'
                    .data \group, module.settings
                    .append do
                        $ '<div class=p0ne-settings-summary>' .text module.settings #.toUpperCase!
                    .insertBefore @$ppInfo
                $s.items = $ '<div class=p0ne-settings-items>' .appendTo $s

                if module.settings == \moderation
                    $s .addClass \p0ne-settings-group-moderation

                if @_settings.openGroup == module.settings
                    @openGroup module.settings
                else
                    $s
                        .addClass \closed
                        .css height: 30px

            # otherwise we already created the settings group

            if not module.settingsVip and not @groupEmpty[module.settings] and (@groupEmpty[module.settings] = module.settingsSimple)
                $s .addClass \p0ne-settings-has-simple
            # create the module's settings element and append it to the settings group
            # note: $create doesn't have to be used, because the resulting elements are appended to a $create'd element
            module._$settings = $ "
                    <label class='#itemClasses'>
                        <input type=checkbox class=checkbox #{if module.disabled then '' else \checked} />
                        <div class=togglebox></div>
                        #{module.displayName}
                        #icons
                    </label>
                "
                .data \module, module

            if module_?._$settings?.parent!.parent! .is $s
                module._$settings
                    .addClass \updated
                    .insertAfter module_._$settings
                sleep 2_000ms, !->
                    module._$settings .removeClass \updated
            else
                module._$settings .appendTo $s.items

            # render extra settings element if module is enabled
            @loadSettingsExtra false, module if not module.disabled

            if module_
                module_._$settings? .remove!




    loadSettingsExtra: (autofocus, module) !->
        try
            if module.settingsExtra
                module.settingsExtra do
                    module._$settingsExtra = $ "<div class=p0ne-settings-extra>"
                        .data \module, module
                        .insertAfter module._$settings
                # using rAF because otherwise jQuery calculates the height incorrectly
                $group = @groups[module.settings]
                if autofocus and @_settings.openGroup == module.settings

                    module._$settingsExtra .css height: 0px
                    requestAnimationFrame !->
                        module._$settingsExtra .css height: module._$settingsExtra.0.scrollHeight
                        sleep 250ms, !->
                            module._$settingsExtra .css height: \auto
                    module._$settingsExtra .find \input .focus!
        catch err
            console.error "[#{module.moduleName}] error while processing settingsExtra", err.stack
            module._$settingsExtra?
                .remove!