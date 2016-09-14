/**
 * Settings pane for plug_p0ne
 * @author jtbrinkmann aka. Brinkie Pie
 * @version 1.0
 * @license MIT License
 * @copyright (c) 2014 J.-T. Brinkmann
 */
module \p0neSettings, do
	setup: ({$create, addListener}) ->
		ppM = $create "<div id=p0ne_menu>"
			.insertAfter \#app-menu
		ppI = $create "<div class=p0ne_icon>p<div class=0ne_icon_sub>0</div></div>"
			.appendTo ppM
		ppS = $create "<div class=p0ne_settings>"
			.appendTo ppM



		test = $create "
				<label class=p0ne_settings_item>
					<input type=checkbox class=checkbox />
					<div class=togglebox><div class=knob></div></div>
					Test Item
				</label>
			"
			.appendTo ppS

		throttled = false
		addListener API, \p0neModuleLoaded, @~updateSettingsThrottled

	updateSettings: ->
		html = ""
		for module in p0ne.modules
			switch module.settings
			\enableDisable =>
				html += ""
			\ =>
				...
	updateSettingsThrottled: (m) ->
					return if throttled or not m.settings
					throttled := true
					requestAnimationFrame ~>
						@updateSettings!
						throttled := false