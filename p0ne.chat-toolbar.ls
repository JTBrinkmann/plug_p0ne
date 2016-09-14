/*@author jtbrinkmann aka. Brinkie Pie */
/*@license https://creativecommons.org/licenses/by-nc/4.0/ */
/*
Comments on chat-toolbar
- when the user selects a submenu from the #chat-toolbar:
	- if the chat dialog is at top, then scroll the chat below the submenu (add a padding to the top)
	- else, overlay the upper part of the chat without scrolling
- #chat-time-selector is a bar-chart when "year", and otherwise a calender with "bubbles for each item,
	who's size (radius) is determined by their amount of messages, relatively"

Comments on p0ne_chat in general
- save which images failed in the archive
- save previews of the image (load into canvas, make smaller, export to compressed PNG, compress, save to localstorage)
- make Youtube thumbnails drag'n'drop-able for playlists
- add Youtube thumbnails to song-stats
- when dragging "youtube thumbnails" (or SC links), show the list-list above the grab-button
	- put "add as next song here" in the bottom (where the next song in playlist is shown)
		- warn about history plays 
	- make the list-list above the grab-button larger, fix scrolling
*/
toolbar = "
	<div id='chat-toolbar'>
		<i id='chat-toolbar-alert' /> #{/* toggles between "off", "@mention", "all" and "custom" */}
		<i id='chat-toolbar-time' />
		<i id='chat-toolbar-stream' /> #{/* toggles between "on", "off" and "audio-only" */}
		<i id='chat-toolbar-galery' /> #{/* allow filtering for "links" (all), "pictures", "videos" or "files" */}
		<i id='chat-toolbar-options' />
		<i id='chat-toolbar-popup' />
	</div>
"

customAlert = "
	<div id='chat-alert'>
		<checkbox id='chat-alert-onmention' />

		<label>custom chat-alert trigger words:</label>
		<input id='chat-alert-triggerwords' />
	</div>
"
options = "
	<div id='chat-options'> #{/* have little questionmark icons *before each element */}
		<checkbox id='chat-options-emoticons' />
		<checkbox id='chat-options-ponymotes' />
		<checkbox id='chat-options-militarytime' />
		<checkbox id='chat-options-messageinputpreview' /> #{/* styles the chat-input so the message looks like it will when send */}
		<checkbox id='chat-options-showflags' />
		<checkbox id='chat-options-showdeletedchat' />

		<checkbox id='chat-options-images' />
		<div id='chat-images-options'>
			<label>Filter tags:</label>
			<input id='chat-images-tags' /> #{/* show tags in badges (kinda like on DA searches, but actually usefull) */}
		</div>
		<checkbox id='chat-options-youtube' /> #{/* embed Youtube videos */}

		<div id='chat-custom-emotes'>
			<label>Custom emotes:</label>
			<input class='chat-custom-emote' value=':eyeroll:'/><input class='chat-custom-emote-value' value='¬_¬'/><button class='chat-custom-emote-remove'/><br>
			<input class='chat-custom-emote' value=':tableflip:'/><input class='chat-custom-emote-value' value='(ノ ゜Д゜)ノ ︵⊥⊥'/><button class='chat-custom-emote-remove'/><br>
			…
			<button class='chat-custom-emote-add'>
		</div>

		<checkbox id='chat-options-colors' /> #{/* custom chat colors */}
		<div id='chat-colors'>
			<checkbox id='chat-colors-self-override' />
			<input type='color' id='chat-colors-self'>
			<input type='color' id='chat-colors-default'>
			<input type='color' id='chat-colors-resident-dj'>
			<input type='color' id='chat-colors-bouncer'>
			<input type='color' id='chat-colors-manager'>
			<input type='color' id='chat-colors-co-host'>
			<input type='color' id='chat-colors-host'>
			<input type='color' id='chat-colors-brand-ambassadors'>
			<input type='color' id='chat-colors-admins'>
			<checkbox id='chat-colors-remove-other-types' /> #{/* looking at you, plug³ >_> */}
		</div>

		<dl><dt>plug_p0ne modules</dt>
			<dd>
				#{
					res = ""
					for module in plug_p0ne.modules
						name = module.name
						if module.options
							hasOptions = "p0ne-module-hasOptions"
						else
							hasOptions = ""
						res += "<checkbox class='p0ne-module #hasOptions' data-name='#name' />"

						if module.options
							...
				}
			</dd>
		</dl>

	</div>
"
time = "
	<div id='chat-time'>
		<div id='chat-time-topbar' class='p0ne_tabbar'>
			<div id='chat-tab-day'>Day</div>
			<div id='chat-tab-month'>Month</div>
			<div id='chat-tab-year'>Year</div>
		</div>
		<div id='chat-time-selector' />
		<div id='chat-time-histogram' />
	</div>
"

renderChatTimeSelector (type) ->
	res = $ \<div>
	if empty
		return res .text "no messages yet"

	switch type
	| \year =>
		years = ...
		max = 1
		for y, data of years
			max >?= data.messages.length
		for y, data of years
			res .append do
				$ \<div>
					.addClass \chat-histogram-year
					.text y
					.css \width, toPercent(data.messages.length / max)
	| \month =>
		months = ...
		max = 1
		for m, data of months
			max >?= data.messages.length
		max /= 4
		for m, data of months
			res .append do
				$ \<div>
					.appClass \chat-histogram-month
					.text m.substr(0, 3)
					.css \width, toPercent(data.messages.length / max)