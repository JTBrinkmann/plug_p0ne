/**
 * Settings pane for plug_p0ne
 * @author jtbrinkmann aka. Brinkie Pie
 * @version 1.0
 * @license MIT License
 * @copyright (c) 2014 J.-T. Brinkmann
 */
module \p0neSettings, do
    setup: ({$create, addListener},,,oldModule) ->
        @$create = $create

        # create DOM elements
        @$ppM = $create "<div id=p0ne_menu>"
            .insertAfter \#app-menu
        @$ppI = $create "<div class=p0ne_icon>p<div class=p0ne_icon_sub>0</div></div>"
            .appendTo @$ppM
        @$ppS = $create "<div class=p0ne_settings>"
            .appendTo do
                $ "<div class=p0ne_settings_wrapper>"
                    .appendTo @$ppM
            .slideUp 1ms
        @$ppP = $ppP = $create "<div class=p0ne_settings_popup>"
            .appendTo @$ppS
            .fadeOut 0

        # add toggles for existing modules
        for module in p0ne.modules
            @addModule module

        # migrate modules from previous p0ne instance
        if oldModule and oldModule.p0ne != p0ne
            for module in oldModule.p0ne.modules when window[module.name] == module
                @addModule module
        @p0ne = p0ne

        # add DOM event listeners
        @$ppI .click @$ppS.~slideToggle
        addListener @$ppS, \click, \.checkbox, ->
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
        addListener @$ppS, \mouseover, \.p0ne_settings_has_more, ->
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
            h = $ppP .height!
            t = $this .offset! .top - 50px
            tt = t - h/2 >? 0px
            $ppP
                .css top: tt
                .stop!.fadeIn!
            if tt == 0px
                $ppP .find \.p0ne_settings_popup_triangle
                    .css top: t
        addListener @$ppS, \mouseout, \.p0ne_settings_has_more, ->
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
            addListener _$context 'show:user show:history show:dashboard dashboard:disable', @$ppS.~slideUp

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

            @groups[module.settings] ||= $ \<details>
                .append do
                    $ \<summary> .text module.settings.toUpperCase!
                .appendTo @$ppS

            @groups[module.settings] .append do
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