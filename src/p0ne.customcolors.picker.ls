/*
    user data format
    user = {
        uid: 00000000
        color: "#AABBCC"
        font: {b: true, i: false, u: null /*fallthrough* /}
        icon: {
            url: ""
            x: 0px
            y: 0px
        } <OR> "icon-chat-bouncer"
        badge: {
            url: ""
            x: 0px
            y: 0px
        } <OR> "bdg-raveb-s04"
    }
*/
module \customColorsPicker, do
    iconCache: {}
    rows: {}
    setup: ({addListener, css, loadStyle, $create}, ccp) !->
        #=== Left Pane ===
        #== Setup ==
        @cc = cc = p0ne.modules.customColors
        $el = cc?._$settingsPanel?.wrapper
        return if not cc or not $el
        @rows = {}

        @lang = Lang.roles with
            friend: Lang.userList.friend
            subscriber: Lang.userStatus.subscriber
            regular: 'Regular'
            you: 'You'



        #== Render UI ==
        loadStyle "#{p0ne.host}/css/customcolors.css"
        $el
            .addClass \p0ne-cc-settings
            .css left: $(\.p0ne-settings).width!
            .html "
                <h3>Custom Colours</h3>
                <div class=p0ne-cc-buttons>
                    <button class='p0ne-cc-reset-order-btn' disabled>reset order</button>
                    <button class='p0ne-cc-reset-all-btn'>reset everything</button>
                </div>
                <div class='p0ne-cc-roles'></div>
                <div class='p0ne-cc-users'>
                    <div class=p0ne-cc-user-add>
                        <i class='icon icon-add p0ne-cc-user-add-icon'></i>
                        <input class='p0ne-settings-input p0ne-cc-user-input' placeholder='new custom user style' />
                        <ul class=p0ne-cc-user-suggestion-list></ul>
                    </div>
                </div>
            "
        $roles  = $el .find \.p0ne-cc-roles
        @$add = $el .find \.p0ne-cc-user-add
        $input = @$add .find \.p0ne-cc-user-input



        #== load data ==
        # load roles UI and CSS
        for roleName in cc._settings.rolesOrder
            # get icon and cache icon-position
            /*icon = false
            for scope in cc.scopeOrderRole when cc.scopes[scope][roleName]?.icon
                icon = cc.scopes[scope][roleName].icon
                break*/
            icon = cc.roles[roleName].icon || cc.roles.regular.icon
            if typeof icon == \string
                @iconCache[icon] ||= getIcon(icon, true)

            $  "<div class='p0ne-cc-row p0ne-cc-name p0ne-name #roleName' data-scope=globalCustomRole data-key=#roleName>
                    <i class='icon icon-drag-handle p0ne-cc-drag-handle'></i>
                    #{@createIcon icon}
                    <span class=name>#{@lang[roleName] || roleName}</span>
                    <i class='icon icon-clear-input p0ne-cc-clear-icon'></i>
                </div>"
                .appendTo $roles
                # => .from-#roleName; <icon>; <name>

        # load custom user UI and CSS
        d = Date.now!
        for scopeName in cc.scopeOrderUser
            for uid of cc.scopes[scopeName]
                @createUser uid, false, d


        #== UI Interaction ==
        # attach UI event listeners
        $el
            .on \click, \.p0ne-cc-reset-all-btn, (e) !~> #DEBUG
                e.preventDefault!
                objectsToClear =
                    * cc.scopes.globalCustomUser
                    * cc.scopes.globalCustomRole
                    * cc._settings.users
                    * cc._settings.perRoom
                for obj in objectsToClear
                    for key of obj
                        delete obj[key]
                ccp.disable!
                cc
                    .disable!
                    .enable!
                    ._$settings .find \.p0ne-settings-panel-icon
                        .click!

            .on \click, \.p0ne-cc-row, (e) !->
                $el.find \.p0ne-cc-row.selected .removeClass \selected
                $row = $ this
                    .addClass \selected
                scope = $row.data(\scope)
                row_key = $row.data(\key)
                if not style = cc.scopes[scope][row_key]
                    style = cc.scopes[scope][row_key] = {}
                #scope = if style.uid then cc.scopes.globalCustomUser else cc.scopes.globalCustomRole
                ccp.save! if key
                ccp.loadData scope, row_key, $row
                e.stopImmediatePropagation!
            .on \click, '.p0ne-cc-clear-icon', (e) !->
                $row = $ this .closest \.p0ne-cc-row
                scope = $row.data(\scope)
                row_key = $row.data(\key)
                delete cc.scopes[scope][row_key]
                if scope == \globalCustomUser
                    removeUserCache = true
                    for scopeName in cc.scopeOrderUser when row_key of cc.scopes[scopeName]
                        removeUserCache = false
                        break
                    if removeUserCache
                        delete cc.users[row_key]
                        $row.remove!
                    #ToDo show notification that row didn't get removed because user is still in roomTheme
                if key == row_key
                    ccp.close!
                cc.updateCSS!
                e.stopImmediatePropagation!

        # new user input field
        $input
            .on \keydown, (e) !~>
                t = e.which || e.keyCode
                if ((t === 13 || t === 9) && @sugg.suggestions.length > 0)
                    @sugg.trigger \submitSuggestion
                else if ((t === 40 || t === 38) && @sugg.suggestions.length > 0)
                    @sugg.upDown(t)
                else
                    return
                e.preventDefault!
                e.stopImmediatePropagation!

            .on \keyup, (e) !->
                # add custom user / apply user change
                # load user into colorpicker
                ccp.sugg.check("@#{@value}", @value.length+1)
                ccp.sugg.updateSuggestions!
        export @sugg = new SuggestionView()
        @sugg.$el.appendTo @$add
        @sugg
            .render!
            .on \refocus, !->
                $input .focus!
            .on \submitSuggestion, !~>
                user = getUser(@sugg.getSelected!)
                if not user
                    return
                $input .val ""
                scope = cc.scopes.globalCustomUser
                if scope[user.id]
                    @rows[user.id] .click!
                else
                    scope[user.id] = {}
                    @createUser user.id
                        .click!



        #== Keep user-data UpToDate ==
        #...



        #== finish up ==
        # apply custom CSS
        cc.updateCSS!



        #== auxiliaries ==
        var drag_cb, drag_pos, imageDragInitPos
        export function onDrag target, cb, onMouseDown
            cc.addListener $el, \mousedown, target, (e) ->
                drag_cb := cb
                drag_pos := $(this) .offset!
                if onMouseDown
                    onMouseDown.call(this, e, drag_pos)
                drag_mousemove.call(this, e)
                $body
                    .on \mouseup, drag_mouseup
                    .on \mousemove, drag_mousemove
                e .preventDefault!

        function drag_mouseup
            $body
                .off \mouseup, drag_mouseup
                .off \mousemove, drag_mousemove

        function drag_mousemove e
            drag_cb.call this, (e.pageX - drag_pos.left), (e.pageY - drag_pos.top), e
            e .preventDefault!





























        #=== Right Pane ===
        $el .append @$cp = $cp = $ '
            <div class=colorpicker>
                <div class="p0ne-ccp-tabbar">
                    <div class="p0ne-ccp-tab-name">Name</div>
                    <div class="p0ne-ccp-tab-icon p0ne-ccp-tab-selected">Icon</div>
                    <div class="p0ne-ccp-tab-badge">Badge</div>
                </div>
                <div class="p0ne-ccp-content-name">
                    <div class="p0ne-ccp-group p0ne-ccp-group-custom-toggle">
                        <button class="p0ne-ccp-btn-toggle" data-mode=default>default</button>
                        <button class="p0ne-ccp-btn-toggle" data-mode=custom>custom</button>
                    </div>
                    <div class="p0ne-ccp-group p0ne-ccp-group-picker">
                        <div class="p0ne-ccp-color">
                            <div class="p0ne-cpp-color-overlay">
                                <div class="p0ne-ccp-crosshair"></div>
                            </div>
                        </div>
                        <div class="p0ne-ccp-hue" style="background: url(https://dl.dropboxusercontent.com/u/4217628/plug_p0ne/vendor/colorpicker/images/slider.png); background-size: contain; background-repeat: no-repeat; background-position: center; ">
                            <div class="p0ne-ccp-hue-pointer"></div>
                        </div>
                    </div>
                    <div class="p0ne-ccp-group p0ne-ccp-group-hex">
                        <div class="p0ne-ccp-new-color">new</div>
                        <div class="p0ne-ccp-current-color">previous</div>
                        <div class="p0ne-ccp-field p0ne-ccp-hex">
                            <input type=text maxlength=6 />
                        </div>
                    </div>
                    <div class="p0ne-ccp-group p0ne-ccp-group-rgb">
                        <div class="p0ne-ccp-field p0ne-ccp-r">
                            <input type=text maxlength=3 />
                        </div>
                        <div class="p0ne-ccp-field p0ne-ccp-g">
                            <input type=text maxlength=3 />
                        </div>
                        <div class="p0ne-ccp-field p0ne-ccp-b">
                            <input type=text maxlength=3 />
                        </div>
                    </div>
                    <div class="p0ne-ccp-group p0ne-ccp-group-hsv">
                        <div class="p0ne-ccp-field p0ne-ccp-h">
                            <input type=text maxlength=3 />
                        </div>
                        <div class="p0ne-ccp-field p0ne-ccp-s">
                            <input type=text maxlength=3 />
                        </div>
                        <div class="p0ne-ccp-field p0ne-ccp-v">
                            <input type=text maxlength=3 />
                        </div>
                    </div>
                    <div class="p0ne-ccp-group p0ne-ccp-group-btns">
                        <button class="p0ne-ccp-btn-b">b</button>
                        <button class="p0ne-ccp-btn-i">i</button>
                        <button class="p0ne-ccp-btn-u">u</button>
                        <button class="p0ne-ccp-btn-reset">reset</button>
                        <button class="p0ne-ccp-btn-save">save</button>
                    </div>
                </div>
                <div class="p0ne-ccp-content-image">
                    <div class="p0ne-ccp-group p0ne-ccp-group-custom-toggle">
                        <button class="p0ne-ccp-btn-toggle" data-mode=none>none</button>
                        <button class="p0ne-ccp-btn-toggle" data-mode=default>default</button>
                        <button class="p0ne-ccp-btn-toggle" data-mode=custom>custom</button>
                        <br>
                        <label><input type=checkbox class="checkbox p0ne-ccp-snaptogrid" /> snap to grid</label>
                    </div>
                    <div class="p0ne-ccp-group p0ne-ccp-group-image-picker">
                        <div class="p0ne-ccp-image-preview">
                            <div class="p0ne-ccp-cloak-tl"></div>
                            <div class="p0ne-ccp-cloak-tr"></div>
                            <div class="p0ne-ccp-cloak-bl"></div>
                            <div class="p0ne-ccp-cloak-br"></div>
                        </div>
                        <div class="p0ne-ccp-image-overview">
                            <div class="p0ne-ccp-image-rect"></div>
                        </div>
                    </div>
                    <div class="p0ne-ccp-group p0ne-ccp-group-image">
                        <div class="p0ne-ccp-field p0ne-ccp-image-url">
                            <input type=text placeholder="plug.dj default" />
                        </div>
                        <button class="p0ne-ccp-btn-reset">reset</button>
                        <div class="p0ne-ccp-field p0ne-ccp-image-x">
                            <input type=number />
                        </div>
                        <div class="p0ne-ccp-field p0ne-ccp-image-y">
                            <input type=number />
                        </div>
                    </div>
                    <button class="p0ne-ccp-btn-save">save</button>
                    <div class="p0ne-ccp-group p0ne-ccp-group-badge">
                        <div class="p0ne-ccp-field p0ne-ccp-image-w">
                            <input type=number />
                        </div>
                        <div class="p0ne-ccp-field p0ne-ccp-image-h">
                            <input type=number />
                        </div>
                    </div>
                </div>
            </div>'

        # we create another <style> element to avoid lags when changing the CSS
        # of the universal plug_p0ne one
        var image
        $css = $create \<style> .appendTo \head
        tmpCSS = true
        defaultIconURL = getIcon('', true).url

        #=== general ===
        $cp = $ \.colorpicker
        $cpp = $cp .find \.p0ne-ccp-color
        $un = $ '.p0ne-cc-user .name:last'
        #uid = $ \.p0ne-cc-userid:last .text!
        $contentName  = $cp .find \.p0ne-ccp-content-name
        $contentImage = $cp .find \.p0ne-ccp-content-image

        #= Tabs =
        addListener $cp, \click, '.p0ne-ccp-tab-name, .p0ne-ccp-tab-icon, .p0ne-ccp-tab-badge', (e) ->
            $this = $ this
            $this
                .addClass \p0ne-ccp-tab-selected
                .siblings! .removeClass \p0ne-ccp-tab-selected
            if $this .hasClass \p0ne-ccp-tab-name
                $contentName .show!
                $contentImage .hide!
            else
                $contentName .hide!
                $contentImage .show!
                if $this .hasClass \p0ne-ccp-tab-icon
                    setImageMode \icon
                else #if $this.hasClass \p0ne-ccp-tab-badge
                    setImageMode \badge
            e .preventDefault!

        addListener $cp, \click, '.p0ne-ccp-btn-save', !-> ccp.save!

        #=== page: name ===
        #== DOM elements ==
        $nameCustomToggles = $contentName .find \.p0ne-ccp-btn-toggle
        $newColor = $cp .find \.p0ne-ccp-new-color
        $currentColor = $cp .find \.p0ne-ccp-current-color
        $crosshair = $cp .find \.p0ne-ccp-crosshair
        $huePointer = $cp .find \.p0ne-ccp-hue-pointer

        #= input fields =
        $hex = $cp .find ".p0ne-ccp-hex input"
        $rgb =
            r: $cp .find ".p0ne-ccp-r input"
            g: $cp .find ".p0ne-ccp-g input"
            b: $cp .find ".p0ne-ccp-b input"
        $hsv =
            h: $cp .find ".p0ne-ccp-h input"
            s: $cp .find ".p0ne-ccp-s input"
            v: $cp .find ".p0ne-ccp-v input"
        $font =
            b: $cp .find \.p0ne-ccp-btn-b
            i: $cp .find \.p0ne-ccp-btn-i
            u: $cp .find \.p0ne-ccp-btn-u

        #== values ==
        var currentColor, customColor, color, colorHSV, font, nameCustomMode
        /*color =
            r: 0 #+$rgb.r .val!
            g: 0 #+$rgb.g .val!
            b: 0 #+$rgb.b .val!
        colorHSV =
            h: 0 #+$hsv.h .val!
            s: 0 #+$hsv.s .val!
            v: 0 #+$hsv.v .val!
        font =
            b: false #$font.b .hasClass \p0ne-ccp-btn-selected
            i: false #$font.i .hasClass \p0ne-ccp-btn-selected
            u: false #$font.u .hasClass \p0ne-ccp-btn-selected
        */

        #== event listeners ==
        #= customMode =
        addListener $nameCustomToggles, \click, ->
            $this = $ this
            if not $this .hasClass \selected
                $nameCustomToggles .removeClass \selected
                $this .addClass \selected
                switch $(this).data(\mode)
                | \default =>
                    customColor := getHex!
                    $hex
                        .val currentColor
                        .trigger \input
                    nameCustomMode := \default # change nameCustomMode afterwards to make the input listener not reset it immediately
                | \custom =>
                    nameCustomMode := \custom # change nameCustomMode before to make the input listener not reset it immediately
                    $hex
                        .val customColor
                        .trigger \input
                updateCSS!
        #= color picker =
        onDrag \.p0ne-ccp-color, (x, y) ->
            $hsv.s .val Math.round((0px >? x <? 150px) * 100perc / 150px)
            $hsv.v .val 100perc - Math.round((0px >? y <? 150px) * 100perc / 150px)
            inputHSV!

        #= hue picker =
        onDrag \.p0ne-ccp-hue, (,y) ->
            $hsv.h .val colorHSV.h=360deg - Math.round((0px >? y <? 150px) * 360deg / 150px)
            inputHSV!

        #= input fields =
        addListener $cp, \input, '.p0ne-ccp-hex input', inputHex
        addListener $cp, \blur, '.p0ne-ccp-hex input', updateUI

        addListener $cp, \input, '.p0ne-ccp-group-rgb input', ->
            checkNameCustomMode!
            color.r = +$rgb.r.val!
            color.g = +$rgb.g.val!
            color.b = +$rgb.b.val!
            inputRGB!
        addListener $cp, \input, '.p0ne-ccp-group-hsv input', ->
            colorHSV.h = +$hsv.h.val!
            colorHSV.s = +$hsv.s.val!
            colorHSV.v = +$hsv.v.val!
            inputHSV!
        addListener $cp, \click, '.p0ne-ccp-group-btns button', (e) ->
            $this = $ this
            btn = do
                if      $this .hasClass \p0ne-ccp-btn-b then \b
                else if $this .hasClass \p0ne-ccp-btn-i then \i
                else if $this .hasClass \p0ne-ccp-btn-u then \u
            return if not btn

            if $this.hasClass \p0ne-ccp-btn-selected
                # set to false
                font[btn] = false
                $this .removeClass 'p0ne-ccp-btn-selected p0ne-ccp-btn-default p0ne-ccp-btn-default-selected'
            else if font[btn] = not $this.hasClass \p0ne-ccp-btn-default
                # set to default
                delete font[btn]
                $this .addClass \p0ne-ccp-btn-selected
                if font[btn] # default value is in font.__proto__[btn]
                    $this .addClass \p0ne-ccp-btn-default-selected
            else
                # set to true
                font[btn] = true
                $this .addClass \p0ne-ccp-btn-selected
            updateUI!
            e.preventDefault!


        addListener $cp, \click, '.p0ne-ccp-content-name .p0ne-ccp-btn-reset', (e) ->
            $hex .val currentColor
            inputHex!

            delete [font.b, font.i, font.u]
            for btn, state of font
                if state
                    $font[btn] .addClass \p0ne-ccp-btn-selected
                else
                    $font[btn] .removeClass \p0ne-ccp-btn-selected

            e.preventDefault!

        #== update values ==
        function inputHSV
            checkNameCustomMode!
            colorHSV :=
                h: ~~($hsv.h .val!)
                s: ~~($hsv.s .val!)
                v: ~~($hsv.v .val!)
            color := hsvToRgb(colorHSV)
            $rgb.r .val color.r
            $rgb.g .val color.g
            $rgb.b .val color.b
            updateUI true
        function inputRGB
            checkNameCustomMode!
            color :=
                r: ~~($rgb.r .val!)
                g: ~~($rgb.g .val!)
                b: ~~($rgb.b .val!)
            colorHSV := rgbToHsv(color)
            $hsv.h .val colorHSV.h
            $hsv.s .val colorHSV.s
            $hsv.v .val colorHSV.v
            updateUI true
        function inputHex
            checkNameCustomMode!
            val_ = $.trim $hex.val!
            val = [parseInt(val_[char], 16) for char from (if val_.0 == \# then 1 else 0) til val_.length]
            var r,g,b
            switch val.length
            # assume gray
            | 1 => r=g=b=16*val+ +val #AAAAAA
            | 2 => r=g=b=val #ABABAB
            # short hex form
            | 3 => r=16*val.0+ +val.0; g=16*val.1+ +val.1; b=16*val.2+ +val.2 #AABBCC
            # assume incomplete
            | 4 => r=16*val.0+ +val.1; g=16*val.2+ +val.3; b=0 #ABCD00
            | 5 => r=16*val.0+ +val.1; g=16*val.2+ +val.3; b=16*val.4 #ABCDE0
            # truncate to first 6 chars
            | _ => r=16*val.0+ +val.1; g=16*val.2+ +val.3; b=16*val.4+ +val.5
            color := {r, g, b}
            $rgb.r .val r
            $rgb.g .val g
            $rgb.b .val b
            colorHSV := rgbToHsv(color)
            $hsv.h .val colorHSV.h
            $hsv.s .val colorHSV.s
            $hsv.v .val colorHSV.v
            updateUI false

        function getHex
            return "
                #{padHex color.r.toString(16)}
                #{padHex color.g.toString(16)}
                #{padHex color.b.toString(16)}
            "

        function updateUI(updateHex)
            hexVal = getHex!
            if updateHex
                $hex.val hexVal.toUpperCase!
            hexVal = "##hexVal"
            $crosshair .css do
                left: colorHSV.s * 150px / 100perc
                top: 150px - colorHSV.v * 150px / 100perc
            $huePointer .css top: 150px - colorHSV.h * 150px / 360deg
            $cpp .css background: "hsl(#{colorHSV.h}, 100%, 50%)"
            $newColor .css background: hexVal
            updateCSS!

        function checkNameCustomMode
            if nameCustomMode == \default
                nameCustomMode := \custom
                $nameCustomToggles
                    .removeClass \selected
                    .filter '[data-mode=custom]' .addClass \selected


        #=== page: icon/badge ===
        #== DOM elements ==
        $imageCustomToggles = $contentImage .find \.p0ne-ccp-btn-toggle
        $snapToGrid = $contentImage .find \.p0ne-ccp-snaptogrid
        $badgeGroup = $cp .find \.p0ne-ccp-group-badge
        $imagePicker =
            preview: $cp .find \.p0ne-ccp-image-preview
            overview: $cp .find \.p0ne-ccp-image-overview
            rect: $cp .find \.p0ne-ccp-image-rect
        $cloak =
            tl: $cp .find \.p0ne-ccp-cloak-tl
            tr: $cp .find \.p0ne-ccp-cloak-tr
            bl: $cp .find \.p0ne-ccp-cloak-bl
            br: $cp .find \.p0ne-ccp-cloak-br

        $image =
            url: $cp .find ".p0ne-ccp-image-url input"
            x: $cp .find ".p0ne-ccp-image-x input"
            y: $cp .find ".p0ne-ccp-image-y input"
            w: $cp .find ".p0ne-ccp-image-w input"
            h: $cp .find ".p0ne-ccp-image-h input"

        #== values ==
        var badge, scale, imageMode #, icon
        snapToGrid =
            w_2: 5px
            h_2: 5px

        imageCustomMode = {}
        imagePicker =
            marginLeft: 0px
            marginTop:  0px
        imageEl = new Image
        imageEl.onload = updateImage
        imageEl.onerror = updateImageOnError

        #== event listeners ==
        #= customMode =
        addListener $imageCustomToggles, \click, ->
            $this = $ this
            if not $this .hasClass \selected
                $imageCustomToggles .removeClass \selected
                $this .addClass \selected
                switch imageCustomMode[imageMode] := $(this).data(\mode)
                | \none =>
                    $contentImage .addClass \disabled
                    $contentImage .find \input .attr \disabled, true
                | \default =>
                    $contentImage .removeClass \disabled
                    $contentImage .find \input .attr \disabled, null
                    setImageMode \default
                | \custom =>
                    $contentImage .removeClass \disabled
                    $contentImage .find \input .attr \disabled, null
                    setImageMode \custom

        #= snap to grid =
        addListener $snapToGrid, \click, !->
            console.log "snapToGrid", @checked
            snapToGrid := if @checked
                w_2: ~~(image.w / 2  /  5px) * 5px
                h_2: ~~(image.h / 2  /  5px) * 5px
            else
                false

        #= image picker =
        onDrag \.p0ne-ccp-image-overview, (x,y,e) ->
            return if checkImageCustomMode!
            x = ~~((x - imagePicker.marginLeft)/scale) - image.w/2
            y = ~~((y - imagePicker.marginTop)/scale) - image.h/2
            if snapToGrid
                x = Math.round(x / snapToGrid.w_2) * snapToGrid.w_2
                y = Math.round(y / snapToGrid.h_2) * snapToGrid.h_2
            updateImagePos x, y
            updateImageVal!

        #= image preview =
        onDrag \.p0ne-ccp-image-preview,
            (x, y, e) !-> # onMouseMove
                return if checkImageCustomMode!
                if snapToGrid
                    x = Math.round(x / snapToGrid.w_2) * snapToGrid.w_2
                    y = Math.round(y / snapToGrid.h_2) * snapToGrid.h_2
                updateImagePos -x, -y
                updateImageVal!
            (e,drag_pos) !-> # onMouseDown
                drag_pos.left = e.pageX + image.x
                drag_pos.top  = e.pageY + image.y

        var urlUpdateTimeout
        addListener $cp, \input, '.p0ne-ccp-group-image input', ->
            return if checkImageCustomMode!
            console.log "input", this, @value
            if $ this .parent! .hasClass \p0ne-ccp-image-url
                clearTimeout urlUpdateTimeout
                console.log ">", @value
                urlUpdateTimeout := sleep 500ms, ~>
                    console.log ">>", @value
                    loadImage @value
            else
                x = +$image.x.val!
                y = +$image.y.val!
                if isFinite(x) and isFinite(y)
                    updateImagePos x, y

        addListener $cp, \input, '.p0ne-ccp-group-badge input', ->
            return if checkImageCustomMode!
            w = ~~$image.w.val!
            h = ~~$image.h.val!
            if w > 0 and h > 0
                updateImageSize w, h

        addListener $cp, \click, '.p0ne-ccp-content-image .p0ne-ccp-btn-reset', (e) ->
            if imageCustomMode[imageMode] == \custom
                for k of image
                    delete image[k]
                if image == icon
                    setImageMode \icon
                else
                    setImageMode \badge
            e.preventDefault!


        function updateImagePos x, y
            if image.srcW
                x = 0 >? ~~x <? image.srcW - image.w
                y = 0 >? ~~y <? image.srcH - image.h
            x2 = x / imagePicker.scale -  50px + image.w / (2 * imagePicker.scale)
            y2 = y / imagePicker.scale - 100px + image.h / (2 * imagePicker.scale)
            $imagePicker.preview .css do
                backgroundPosition: "#{-x2}px #{-y2}px"
            $imagePicker.rect .css do
                left: (x2 * scale + imagePicker.marginLeft) * imagePicker.scale
                top:  (y2 * scale + imagePicker.marginTop) * imagePicker.scale
            image.x = x; image.y = y
            updateCSS!

        function updateImageVal
            $image.x .val image.x
            $image.y .val image.y
            if image == badge
                $image.w .val image.w
                $image.h .val image.h

        function updateImageSize w, h
            image.w = w; image.h = h
            $image.w.val w
            $image.h.val h
            imagePicker.scale = Math.ceil((w >? h) / 100px)
            w_2 = ~~(image.w / (imagePicker.scale * 2))
            h_2 = ~~(image.h / (imagePicker.scale * 2))
            console.log "updating size", w, h, "#{imagePicker.scale}x"

            # preview rect
            imagePicker.rectW = 100px * scale * imagePicker.scale
            imagePicker.rectH = 200px * scale * imagePicker.scale

            if snapToGrid
                snapToGrid :=
                    w_2: ~~(w / 2  /  5px) * 5px
                    h_2: ~~(h / 2  /  5px) * 5px

            # update cloak
            w_px = +(image.w /  imagePicker.scale % 2 == 1) # extra pixel
            h_px = +(image.h /  imagePicker.scale % 2 == 1) # extra pixel
            $cloak.tl .css width: 50px + w_2 + w_px, height: 99px - h_2
            $cloak.tr .css width: 49px - w_2, height: 100px + h_2 + h_px, left: 50px + w_2 + w_px
            $cloak.bl .css width: 49px - w_2, height: 100px + h_2, top: 100px - h_2
            $cloak.br .css width: 50px + w_2, height:  99px - h_2, top: 100px + h_2 + h_px, left: 50px - w_2

            # update image preview position
            updateImagePicker! if image.srcW
            updateImagePos image.x, image.y

            updateCSS!

        function updateImagePicker
            console.log "[updateImagePicker]", imagePicker.rectW, imagePicker.rectH
            $imagePicker.preview .css do
                backgroundSize: "#{image.srcW / imagePicker.scale}px #{image.srcH / imagePicker.scale}px"
            $imagePicker.rect .css do
                width:  imagePicker.rectW
                height: imagePicker.rectH

        function setImageMode mode
            switch mode
            | \icon =>
                imageMode := \icon
                image := icon
                $badgeGroup .hide!
            | \badge =>
                imageMode := \badge
                image := badge
                $badgeGroup .show!
            | \default => if image.default
                imageCustomMode[imageMode] := \default
                image := image.default
            | \custom => if image.custom
                imageCustomMode[imageMode] := \custom
                image := image.custom
            console.log "set image mode", mode, image
            if imageCustomMode[imageMode] == \none
                $contentImage .addClass \disabled
            else
                $contentImage .removeClass \disabled

            $imageCustomToggles
                .removeClass \selected
                .filter "[data-mode=#{imageCustomMode[imageMode]}]" .addClass \selected


            loadImage image.url
            updateImageVal!
            updateCSS!

        function loadImage url
            if not url
                console.error "invalid image URL: #{url}"
            else
                console.log "loading image #{url}"
                image.url = url
                if url != imageEl.src
                    $image.url .val image.url || defaultIconURL
                    imageEl.isLoaded = false
                    imageEl.src = url
                    return true
                else
                    updateImage.call imageEl
                    return false

        function updateImage
            image.isLoaded = true
            image.src_ = image.src
            image.srcW = @width
            image.srcH = @height
            if image.src == $image.url.val!
                $image.url .removeClass \error
            scale := 100px / @width <? 200px / @height
            imagePicker :=
                rectW: 100px * scale
                rectH: 200px * scale
                marginLeft: 50px - @width*scale / 2
                marginTop: 100px - @height*scale / 2
            #updateImagePicker!
            updateImagePos image.x, image.y
            updateImageSize image.w, image.h
            $imagePicker.preview .css do
                backgroundImage: "url(#{@src})"
            $imagePicker.overview .css do
                backgroundImage: "url(#{@src})"
            updateCSS!

        function updateImageOnError
            if image.src != ''
                $image.url .addClass \error
                console.warn "error loading image", image.src
                #delete image.src_ if image.src == image.src_
                #loadImage image.src_ || ''

        function checkImageCustomMode
            if imageCustomMode[imageMode] == \default
                image := image.custom <<< image
                imageCustomMode[imageMode] = \custom
                $imageCustomToggles
                    .removeClass \selected
                    .filter '[data-mode=custom]' .addClass \selected
            else if imageCustomMode[imageMode] == \none
                return true


        #== TODO ==
        #save button
        #store native plug icons/badges as CSS classes instead of URL,x,y
        #image loading animation
        #badge page (using icon page but replacing images)
        #width/height for badge
        #recolor? rotate?
        # => resized/recolored image upload to imgur?
        #show image load time
        #warn on long loading time (slow host, large GIF, …)
        var scope, key, $row #, uid
        @loadData = loadData = (scopeName, key_, $row_) !->
            /* note: the reason we clone$ the variables (font, icon, badge)
             * is so that the initial values are stored in the prototype of the
             * variables, not the in variables themselves
             * this way the reset button can delete the custom properties
             * which will than default back to the initial values
             */
            @key = key := key_
            scope := cc.scopes[scopeName]
            data = scope[key]
            $row := $row_
            console.log "loading data", scopeName, key, data
            if key of cc.roles
                uid := 0
                $cp .addClass \p0ne-ccp-nobadge
                if imageMode == \badge
                    $cp .find \.p0ne-ccp-tab-icon
                        .addClass \p0ne-ccp-tab-selected
                        .siblings! .removeClass \p0ne-ccp-tab-selected
            else
                uid := key
                $cp .removeClass \p0ne-ccp-nobadge


            delete scope[key] # removing temporarily
            try
                # try catch to avoid permanently losing scope[key]
                if uid
                    styleDefault = customColors.getUserStyle(key, true)
                else
                    styleDefault = customColors.getRoleStyle(key, true)
                console.log "styleDefault", styleDefault

                #= ICON =
                iconTemplate = ->
                switch typeof styleDefault.icon
                | \string =>
                    imageCustomMode.icon = \default
                    iconTemplate::default = getIcon(styleDefault.icon, true)
                | \object =>
                    imageCustomMode.icon = \default
                    iconTemplate::default = styleDefault.icon
                | otherwise =>
                    imageCustomMode.icon = \none
                    iconTemplate::default = # white heart
                        url: defaultIconURL
                        x: 105px
                        y: 350px

                #= BADGE =
                badgeTemplate = ->
                if uid
                    switch typeof styleDefault.badge
                    | \string =>
                        imageCustomMode.badge = \default
                        badgeTemplate::default = getIcon("bdg bdg-#{styleDefault.badge} #{styleDefault.badge[*-1]}", true)
                        badgeTemplate::default.w = badgeTemplate::default.h = 30px
                    | \object =>
                        imageCustomMode.badge = \default
                        badgeTemplate::default = styleDefault.badge
                    | otherwise =>
                        imageCustomMode.badge = \none
                        badgeTemplate::default =
                            default: true
                            disabled: true
                            w: 30px
                            h: 30px
                else
                    imageCustomMode.badge = \none
                    badgeTemplate::default = {}
            catch err
                console.error "failed to create icon or badge template", err.messageAndStack
            # restore custom settings
            scope[key] = data

            #NAME
            if data.color
                nameCustomMode := \custom
                $hex .val currentColor:=data.color.substr(1)
            else
                nameCustomMode := \default
                $hex .val currentColor:=styleDefault.color?.substr(1)
            customColor := currentColor

            font := {+b, -i, -u}
            for btn, state of data.font
                if font[btn] = state
                    $font[btn] .addClass \p0ne-ccp-btn-selected
                else
                    $font[btn] .removeClass \p0ne-ccp-btn-selected
            font := ^^font


            #= ICON =
            console.log "typeof data.icon", typeof data.icon
            switch typeof data.icon
            | \boolean => # false
                imageCustomMode.icon = \none
                fallthrough
            | \undefined =>
                iconTemplate ::= iconTemplate::default
            | \string =>
                imageCustomMode.icon = \custom
                iconTemplate ::= getIcon(data.icon, true)
            | \object =>
                imageCustomMode.icon = \custom
                iconTemplate ::= data.icon
            iconTemplate::w = iconTemplate::h = iconTemplate::default.w = iconTemplate::default.h = 15px
            icon := iconTemplate::default.custom = new iconTemplate
            if imageCustomMode.icon != \custom
                icon := icon.default


            #= BADGE =
            console.log "typeof data.badge", typeof data.badge
            switch typeof data.badge
            | \boolean => # false
                imageCustomMode.badge = \custom
                fallthrough
            | \undefined =>
                badgeTemplate ::= badgeTemplate::default
                /*console.log "[customColors] no badge specified, loading user data", data.uid, data.name, d
                getUserData data.uid, (d) ->
                    console.log "[customColors] loaded user data", data.uid, data.name, d
                    badgeTemplate:: = getIcon("bdg bdg-#{d.badge} #{d.badge[d.badge.length - 1]}", true)
                    badgeTemplate::default = true
                    badgeTemplate::w = badgeTemplate::h = 30px*/
            | \string =>
                imageCustomMode.badge = \custom
                badgeTemplate ::= getIcon("bdg bdg-#{data.badge} #{data.badge[*-1]}", true)
                badgeTemplate::w = badgeTemplate::h = 30px
            | \object =>
                imageCustomMode.badge = \custom
                badgeTemplate ::= data.badge
            badge := badgeTemplate::default.custom = new badgeTemplate
            if imageCustomMode.badge != \custom
                badge := badge.default
            #badge := data.badge || {default: true, url: "", x: 0px, y: 0px, w: 30px, h: 30px}

            if $cp .find \.p0ne-ccp-tab-icon .hasClass \p0ne-ccp-tab-selected
                setImageMode \icon
            else if $cp .find \.p0ne-ccp-tab-badge .hasClass \p0ne-ccp-tab-selected
                setImageMode \badge

            console.log "imageCustomMode", imageCustomMode.icon, imageCustomMode.badge

            # UI
            $nameCustomToggles
                .removeClass \selected
                .filter "[data-mode=#nameCustomMode]" .addClass \selected
            inputHex!
            $currentColor .css background: "##{getHex!}"

            $snapToGrid
                .attr \checked, false
                .click!

            $cp.show!



        #== auxiliaries ==
        function rgbToHsv rgb
            hsv = h: 0, s: 0, v: 0
            min = rgb.r <? rgb.g <? rgb.b
            max = rgb.r >? rgb.g >? rgb.b
            delta = max - min
            hsv.v = max
            hsv.s = if max != 0 then 255 * delta / max else 0
            if hsv.s != 0
                if rgb.r == max
                    hsv.h = (rgb.g - rgb.b) / delta
                else if rgb.g == max
                    hsv.h = 2 + (rgb.b - rgb.r) / delta
                else
                    hsv.h = 4 + (rgb.r - rgb.g) / delta
            else
                hsv.h = -1
            hsv.h = ~~(hsv.h*60deg)
            if hsv.h < 0
                hsv.h += 360deg
            hsv.s = ~~(hsv.s*100perc/255)
            hsv.v = ~~(hsv.v*100perc/255)
            return hsv
        /*
        very boredom, such fancy code, wow
        function rgbToHsvDoge(rgb) {
            var hsv, min, max, delta
            hsv = {h: 0- -0, s: 0*0+~~-0-~~+0*0, v: 0+ +0}
            min = (min = rgb.r < rgb.g ? rgb.r : rgb.g) < rgb.b ? min : rgb.b
            max = (max = rgb.r > rgb.g ? rgb.r : rgb.g) > rgb.b ? max : rgb.b
            delta = max - min
            hsv.v = max
            hsv.s = max != 1- - -1 ? - -~-(2<<9>>2) * delta / max : 1+ - +1
            if (0-~~-0 == hsv.s == 0<0>0) {
                if (rgb.r == max)
                    hsv.h = ~-2 - -     (rgb.g -~~- - -~~- rgb.b) / delta - ~-2
                else if (rgb.g == max)
                    hsv.h = ~-4 - - (rgb.b - -~~- - - - -~~- - rgb.r) / delta - ~-~-3
                else
                    hsv.h = ~-5 - -     (rgb.r -~~- - -~~- rgb.g) / delta - ~-1
            } else {
                hsv.h = 0 +-~~-~~-+1+-~~-~~-+ 0
            }
            hsv.h *= 0 +-~~-+ 60 +-~~-+ 0
            if (hsv.h < 0+~~+0)
                hsv.h += (3<<10>>3) - (3<<6>>3)
            hsv.s *= (0 -~100 + + ~ + + 001-~ 0) / - -~-(4<<10>>4)
            hsv.v *= (0 -~100 - - ~ - - 001-~ 0) / - -~-(8>>3<<8)
            return hsv
        }
         */

        function hsvToRgb hsv
            rgb = {}
            h = hsv.h
            s = hsv.s * 255 / 100perc
            v = hsv.v * 255 / 100perc
            if s == 0
                rgb.r = rgb.g = rgb.b = v
            else
                t1 = v
                t2 = (255 - s) * v / 255
                t3 = (t1 - t2) * (h % 60deg) / 60deg
                if h == 360deg
                    h = 0deg
                if h < 60deg then rgb.r = ~~t1; rgb.b = ~~t2; rgb.g = ~~(t2+t3)
                else if h < 120deg then rgb.g = ~~t1; rgb.b = ~~t2; rgb.r = ~~(t1 - t3)
                else if h < 180deg then rgb.g = ~~t1; rgb.r = ~~t2; rgb.b = ~~(t2 + t3)
                else if h < 240deg then rgb.b = ~~t1; rgb.r = ~~t2; rgb.g = ~~(t1 - t3)
                else if h < 300deg then rgb.b = ~~t1; rgb.g = ~~t2; rgb.r = ~~(t2 + t3)
                else if h < 360deg then rgb.r = ~~t1; rgb.g = ~~t2; rgb.b = ~~(t1 - t3)
                else rgb.r=0; rgb.g=0; rgb.b=0
            return rgb

        var updateCSSTimeout
        updateCSS = ->
            clearTimeout updateCSSTimeout
            updateCSSTimeout := sleep 200ms, ->
                badge_ = badge[imageCustomMode.badge] || badge
                if \srcW not of badge_
                    badge_ = void
                style = cc[if uid then \calcCSSUser else \calcCSSRole] do
                    key
                    color: "##{getHex!}"
                    font: font
                    icon: icon[imageCustomMode.icon] || icon
                    badge: badge_

                $css .text style
                /*TODO add icon for non-staff */
                /*TODO add .bdg for those without */
        @close = !->
            $css .text ""
            $cp .hide!

        @save = !-> if key
            try
                style = scope[key]

                hex = getHex!
                if hex != currentColor
                    style.color = "##hex"
                else
                    delete style.color

                style.font = {+b, -i, -u}
                for k in <[ b i u ]> when font.hasOwnProperty k
                    hasCustomFont = true
                    style.font[k] = font[k]
                if not hasCustomFont
                    delete style.font

                switch imageCustomMode.icon
                | \custom =>
                    icon_ = icon[imageCustomMode.icon] || icon
                    for k in <[ url x y ]> when icon_.hasOwnProperty k
                        hasCustomIcon = true
                        style.icon = icon_{url, x, y}
                        break
                    if not hasCustomIcon
                        delete style.icon
                | \default =>
                    delete style.icon
                | \none => if uid or cc.roles[key].icon
                    style.icon = false

                switch uid && imageCustomMode.badge
                | \custom =>
                    badge_ = badge[imageCustomMode.badge] || badge
                    for k in <[ url x y w h ]> when badge_.hasOwnProperty k
                        hasCustomBadge = true
                        style.badge = badge_{url, x, y, w, h, srcW, srcH}
                        break
                    if not hasCustomBadge
                        delete style.badge
                | \default =>
                    delete style.badge
                | \none =>
                    style.badge = false

                /*$row .html "<div class=p0ne-cc-row>
                        #{createBadge style.badge}
                        <div class=p0ne-cc-name>
                            #{createIcon style.icon}
                            #{createName style, style.name}
                            <i class='icon icon-clear-input p0ne-cc-clear-icon'></i>
                            <div class=p0ne-cc-userid>#{style.uid}</div>
                        </div>
                    </div>"*/
                $css .text ""

                if uid
                    cc.users[uid].css = cc.calcCSSUser(uid)
                else
                    cc.roles[key].css = cc.calcCSSRole(key)

                cc.updateCSS!
                tmpCSS := true
                /*if not tmpCSS
                    tmpCSS := true
                    $css .text ""
                    css \customColors_test, $css.text!*/
            catch err
                console.error "Error while saving custom colors for #key", err.messageAndStack
        export test = ->
            return {image, defaultIconURL, currentColor, customColor, color, colorHSV, font, nameCustomMode, icon, badge, scale, imageMode, imageCustomMode, imagePicker, imageEl, scope, key, uid, snapToGrid}

        # SAMPLE DATA
        /*
        loadData {}, do
            name: "MᗣD Pᗣᗧ•••MᗣN"
            uid: 3947647 # MᗣD Pᗣᗧ•••MᗣN
            #uid: 4103672 # The Sensational Stallion
            roles: <[ manager ]>
            badge:
                url: "http://png-2.findicons.com/files/icons/1187/pickin_time/32/eggplant.png"
                x:  0px
                y:  0px
                w: 30px
                h: 30px
                srcW: 30px
                srcH: 30px
            color: \#D35w
            font: {+b, -i, +u}
            icon:
                url: "https://cdn.plug.dj/_/static/images/icons.d8b5eb442b3acb5ccfbbe2541b9db0756e45beba.png" # DUMMY
                x:  15px
                y: 365px
            badge:
                url: "https://a.thumbs.redditmedia.com/H-RxCNGKM9YqzbW-5SVWcEn7Fvjy4rlo9cAZXVuv718.png" # ponies
                x: 140px
                y: 210px
                w:  70px
                h:  70px
                srcW: 280px
                srcH: 700px
            */


        export loadData
        $el .find \.p0ne-cc-row.selected .click!


    createIcon: (icon) !->
        return do
            if typeof icon == \string
                "<i class='icon #icon'></i>"
            else
                "<i class='icon p0ne-icon-placeholder'></i>"
    createBadge: (badge) !->
        return do
            if typeof badge == \string
                "<div class=badge-box><i class='bdg bdg-#badge #{badge[*-1]}'></i></div>"
            else
                "<div class=badge-box></div>"

    # note: `!->` would add an extra function wrapper, so we should stick to `->` here
    # returns a sorted list of roles that apply for the specified user


    createUser: (uid, user, currTimestamp) !->
        var icon
        if user ||= getUser(uid)
            rank = getRank(that)
            username = that.username
            @cc._settings.users[uid] = that{username, gRole, sub, friend, defaultBadge: badge}
            @cc._settings.users[uid].roles = []
            @cc.room.userRole[uid] = that.role
            l=0
            for role in @cc._settings.rolesOrder when @cc.roles[role].test(that)
                if not @cc.roles[role].perRoom
                    @cc._settings.users[uid].roles[l++] = role
                if @cc.roles[role].icon and not icon?
                    icon = @cc.roles[role].icon
        else if user = @cc._settings.users[uid]
            username = that.username
            if @cc._settings.users[uid].gRole
                rank = getRank(@cc._settings.users[uid])
            else if @cc.room.userRole[uid]
                rank = getRank(@cc.room.userRole[uid])
            else
                rank = ""
            icon = @cc.roles[rank]?.icon
        else
            throw new TypeError "createUser: User #uid is not found, and no data was passed"

        @cc.users[uid] ||= {}
        @cc.users[uid].css = @cc.calcCSSUser(uid)

        @cc._settings.users[uid].lastUsed = currTimestamp || Date.now()
        rank += " subscriber" if user.sub
        rank += " friend" if user.friend

        console.log "[customColors] >createUser", uid, username
        # find where to insert row
        #   get some initual value
        for id of @rows
            insertBeforeUID = id; insertBeforeName = @cc._settings.users[id].username
            break
        if insertBeforeUID
            #   find best match
            for id of @rows when insertBeforeName > @cc._settings.users[id].username > username
                insertBeforeUID = id
                insertBeforeName = @cc._settings.users[id].username

        $inserBeforeEl = if insertBeforeUID and @cc._settings.users[insertBeforeUID].username < username
            @rows[insertBeforeUID]
        else
            @$add
        console.log "[customColors] >createUser", uid, rank, icon, insertBeforeUID, $inserBeforeEl
        return @rows[uid] =
            $ "<div class='p0ne-cc-row p0ne-uid-#uid' data-scope=globalCustomUser data-key=#uid>
                    #{@createBadge @cc._settings.users[uid].defaultBadge}
                    <div class='p0ne-cc-name p0ne-name #rank'>
                        #{@createIcon icon}
                        <span class=name>#{username}</span>
                        <i class='icon icon-clear-input p0ne-cc-clear-icon'></i>
                        <div class=p0ne-cc-userid>#uid</div>
                    </div>
                </div>"
                # => .from-#role.from-…; <badge>; <icon>; <name>; <uid>
            .insertBefore $inserBeforeEl

    disable: !->
        @cc?._$settingsPanel?.wrapper?.html ""