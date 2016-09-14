/**
 * plug_p0ne modules to help moderators do their job
 * @author jtbrinkmann aka. Brinkie Pie
 * @version 1.0
 * @license MIT License
 * @copyright (c) 2014 J.-T. Brinkmann
 */

module \warnOnHistory, do
	setup: ({addListener}) ->
		addListener API, \advance, (d) ~>
			return if not d.media
			hist = API.getHistory!
			inHistory = 0; skipped = 0; lastTime = 0
			for m, i in hist when m.id == d.id and d.historyID != m.historyID
				inHistory++
				m.i = i
				lastPlay ||= m
				skipped++ if m.skipped
			if inHistory
				msg = "Song is in history"
				if inHistory > 1
					msg += " (#inHistory times) one:"
				place += " #{ago PARSESOMEHOW lastPlay.datetime} (#{i+1}/#{hist.length})"
				if skipped == inHistory
					place = " but was skipped last time"
				if skipped > 1
					place = " it was skipped #skipped/#inHistory times"
				API.chatLog msg, true
				API.trigger \p0ne_songInHistory # should this be p0ne:songInHistory?