/**
 * Settings pane for plug_p0ne
 * @author jtbrinkmann aka. Brinkie Pie
 * @version 1.0
 * @license MIT License
 * @copyright (c) 2014 J.-T. Brinkmann
 */
module \p0neSettings, do
    _settings:
        groupToggles: {p0neSettings: true, base: true}
    setup: ({$create, addListener},,,oldModule) ->
        @$create = $create

        groupToggles = @groupToggles = @_settings.groupToggles

        # ToDo: add a little plug_p0ne banner saying the version

        # create DOM elements
        $ppM = $create "<div id=p0ne_menu>"
            .insertAfter \#app-menu
        $ppI = $create "<div class=p0ne_icon>p<div class=p0ne_icon_sub>0</div></div>"
            .appendTo $ppM
        $ppS = @$ppS = $create "<div class=p0ne_settings>"
            .appendTo do
                $ "<div class=p0ne_settings_wrapper>"
                    .appendTo $ppM
        $ppP = $create "<div class=p0ne_settings_popup>"
            .appendTo $ppM
            .fadeOut 0

        #debug
        #@<<<<{$ppP, $ppM, $ppI}
        @toggleMenu groupToggles.p0neSettings

        # add toggles for existing modules
        for ,module of p0ne.modules
            @addModule module


        ## add DOM event listeners
        # slide settings-menu in/out
        $ppI .click ~> @toggleMenu!

        # toggle groups
        addListener $body, \click, \.p0ne_settings_summary, (e) ->
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
                .stop! .animate height: $s.children!.length * 44px, \slow /* magic number, height of a .p0ne_settings_item*/
            groupToggles[$s.data \group] = true
          e.preventDefault!

        addListener $ppS, \click, \.checkbox, ->
            # note: this gets triggered when anything in the <label> is clicked
            $this = $ this
            enable = this .checked
            $el = $this .closest \.p0ne_settings_item
            module = $el.data \module
            console.log "[p0neSettings] toggle", module.displayName, "=>", enable
            if enable
                module.enable!
            else
                module.disable!

        addListener $ppS, \mouseover, \.p0ne_settings_has_more, ->
            $this = $ this
            module = $this .data \module
            $ppP
                .html "
                    <div class=p0ne_settings_popup_triangle></div>
                    <h3>#{module.displayName}</h3>
                    #{if!   module.screenshot   then'' else
                        '<img src='+module.screenshot+'>'
                    }
                    #{module.help}
                "
            l = $ppS.width!
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
            $ppP .find \.p0ne_settings_popup_triangle
                .css top: t
        addListener $ppS, \mouseout, \.p0ne_settings_has_more, ->
            $ppP .stop!.fadeOut!
        addListener $ppP, \mouseover, ->
            $ppP .stop!.fadeIn!
        addListener $ppP, \mouseout, ->
            $ppP .stop!.fadeOut!

        # add p0ne.module listeners
        addListener API, \p0neModuleLoaded, (module) ~> @addModule module
        addListener API, \p0neModuleDisabled, (module) ~>
            module._$settings? .find \.checkbox .0 .checked=false
        addListener API, \p0neModuleEnabled, (module) ~>
            module._$settings? .find \.checkbox .0 .checked=true
        addListener API, \p0neModuleUpdated, (module) ~>
            if module._$settings
                module._$settings .find \.checkbox .0 .checked=true
                module._$settings .addClass \updated
                sleep 2_000ms, ->
                    module._$settings .removeClass \updated
            else if module.settings
                @addModule module

        if _$context?
            addListener _$context, 'show:user show:history show:dashboard dashboard:disable', ~> @toggleMenu false

        # plugCubed compatibility
        addListener $body, \click, \#plugcubed, ~>
            @toggleMenu false

    toggleMenu: (state) ->
        if state ?= not @groupToggles.p0neSettings
            @$ppS.slideDown!
        else
            @$ppS.slideUp!
        @groupToggles.p0neSettings = state

    groups: {}
    addModule: (module) !->
        if module.settings
            module.more = typeof module.settings == \function
            itemClasses = \p0ne_settings_item
            icons = ""
            for k in <[ more help screenshot ]> when module[k]
                icons += "<div class=p0ne_settings_#k></div>"
            if icons.length
                icons = "<div class=p0ne_settings_icons>#icons</div>"
                itemClasses += ' p0ne_settings_has_more'

            if not $s = @groups[module.settings]
                $s = @groups[module.settings] = $ '<div class=p0ne_settings_group>'
                    .data \group, module.settings
                    .append do
                        $ '<div class=p0ne_settings_summary>' .text module.settings.toUpperCase!
                    .appendTo @$ppS
                if @_settings.groupToggles[module.settings]
                    $s
                        .data \open, true
                        .addClass \open

            $s .append do
                # $create doesn't have to be used, because the resulting elements are appended to a $create'd element
                module._$settings = $ "
                        <label class='#itemClasses'>
                            <input type=checkbox class=checkbox #{if module.disabled then '' else \checked} />
                            <div class=togglebox><div class=knob></div></div>
                            #{module.displayName}
                            #icons
                        </label>
                    "
                    .data \module, module
            if @_settings.groupToggles[module.settings]
                $s .stop! .animate height: $s.children!.length * 44px, \slow
    updateSettings: (m) ->
        @$ppS .html ""
        for module in p0ne.modules
            @addModule module
    /*
    updateSettingsThrottled: (m) ->
        return if throttled or not m.settings
        @throttled = true
        requestAnimationFrame ~>
            @updateSettings!
            @throttled = false
    */