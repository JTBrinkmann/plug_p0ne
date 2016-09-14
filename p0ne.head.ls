/**
 * plug_p0ne - a modern script collection to improve plug.dj
 * adds a variety of new functions, bugfixes, tweaks and developer tools/functions
 *
 * This script collection is written in LiveScript (a CoffeeScript descendend which compiles to JavaScript). If you are reading this in JavaScript, you might want to check out the LiveScript file instead for a better documented and formatted source; just replace the .js with .ls in the URL of this file
 *
 * @author jtbrinkmann aka. Brinkie Pie
 * @license MIT License
 * @copyright (c) 2015 J.-T. Brinkmann
 *
 * further credits go to
 *     the plugCubed Team - for coining a standard for the "Room Settings"
 *     Christian Petersen - for the toggle boxes in the settings menu http://codepen.io/cbp/pen/FLdjI/
 *     all the beta testers! <3
 *     plug.dj - for it's horribly broken implementation of everything.
 *               "If it wasn't THAT broken, i wouldn't have as much fun in coding plug_p0ne"
 *                   --Brinkie Pie (2015)
 *
 * Not happy with plug_p0ne? contact me (the developer) at brinkiepie^gmail.com
 * great alternative plug.dj scripts are
 *     - TastyPlug (relatively lightweight but does a great job - https://fungustime.pw/tastyplug/)
 *     - RCS (Radiant Community Script - https://radiant.dj/rcs)
 *     - plugCubed (https://plugcubed.net/)
 *     - plugplug (lightweight as heck - https://bitbucket.org/mateon1/plugplug/)
 */

console.info "~~~~~~~~~~~~ plug_p0ne loading ~~~~~~~~~~~~"
p0ne_ = window.p0ne
window.p0ne =
    #== Constants ==
    version: \1.6.5
    lastCompatibleVersion: \1.6.5 /* see below */
    host: 'https://cdn.p0ne.com'
    SOUNDCLOUD_KEY: \aff458e0e87cfbc1a2cde2f8aeb98759
    YOUTUBE_KEY: \AI39si6XYixXiaG51p_o0WahXtdRYFCpMJbgHVRKMKCph2FiJz9UCVaLdzfltg1DXtmEREQVFpkTHx_0O_dSpHR5w0PTVea4Lw
    YOUTUBE_KEY_V3: \AIzaSyDaWL9emnR9R_qBWlDAYl-Z_h4ZPYBDjzk

    # for cross site requests
    proxy: (url) -> return "https://cors-anywhere.herokuapp.com/#{url .replace /^.*\/\//, ''}"

    #https://blog.5apps.com/2013/03/02/new-service-cors-ssl-proxy.html
    #proxy: (url) -> return "https://jsonp.nodejitsu.com/?raw=true&url=#{escape url}"
    #proxy: (url) -> return "https://query.yahooapis.com/v1/public/yql?format=json&q=select%20*%20from%20json%20where%20url%3D"#{escape url}"
    started: new Date()
    lsBound: {}
    lsBound_num: {}
    modules: p0ne?.modules || {}
    dependencies: {}
    reload: ->
        return $.getScript "#{@host}/script/plug_p0ne.beta.js"
    close: ->
        for m in @modules
            m.disable?!
console.info "plug_p0ne v#{p0ne.version}"

try
    saveData?! /* save data of previous p0ne instances */

/*####################################
#           COMPATIBILITY            #
####################################*/
/* check if last run p0ne version is incompatible with current and needs to be migrated */
window.compareVersions = (a, b) -> /* returns whether `a` is greater-or-equal to `b`; e.g. "1.2.0" is greater than "1.1.4.9" */
    a .= split \.
    b .= split \.
    for ,i in a when a[i] != b[i]
        return a[i] > b[i]
    return b.length >= a.length


<-      (fn_) ->
    if window.P0NE_UPDATE
        window.P0NE_UPDATE = false
        if p0ne_?.version == window.p0ne.version
            return
        else
            chatWarn? "automatically updated to v#{p0ne.version}", 'plug_p0ne'

    console.group ||= $.noop
    console.groupEnd ||= $.noop
    fn = ->
        if console.groupCollapsed
            console.groupCollapsed "[p0ne] initializing… (click on this message to expand/collapse the group)"
        else
            console.groupCollapsed = console.group
            console.group "[p0ne] initializing…"

        errors = warnings = 0
        error_ = console.error; console.error = -> errors++; error_ ...
        warn_ = console.warn; console.warn = -> warnings++; warn_ ...

        try
            fn_!
            console.groupEnd!
            console.info "[p0ne] initialized!"
            console.error = error_; console.warn = warn_
        catch err
            console.groupEnd!
            console.error "[p0ne] FATAL ERROR!", err.stack
        console.error "[p0ne] There have been #errors errors" if errors
        console.warn "[p0ne] There have been #warnings warnings" if warnings

        # show disabled warnings
        showWarning = true
        for name, m of p0ne.modules when m.disabled and not m.settings and not (m.moderator and user.isStaff)
            if showWarning
                console.groupCollapsed "[p0ne] there are disabled modules which are hidden from the settings"
                showWarning = false
            console.warn "\t#name", m
        console.groupEnd! if not showWarning

        appendChat? "<div class='cm p0ne-notif p0ne-notif-loaded'>plug_p0ne v#{p0ne.version} loaded #{getTimestamp?!}</div>"

    if not (v = localStorage.p0neVersion)
        # no previous version of p0ne found, looks like we're good to go
        return fn!

    if compareVersions(v, p0ne.lastCompatibleVersion)
        # no migration required, continue
        fn!
    else
        # incompatible, load migration script and continue when it's done
        console.warn "[p0ne] obsolete p0ne version detected (#v < #{p0ne.lastCompatibleVersion}), loading migration script…"
        API.off \p0ne_migrated
        API.once \p0ne_migrated, onMigrated = (newVersion) ->
            if newVersion == p0ne.lastCompatibleVersion
                fn!
            else
                API.once \p0ne_migrated, onMigrated # did you mean "recursion"?
        $.getScript "#{p0ne.host}/script/plug_p0ne.migrate.#{v.substr(0,v.indexOf(\.))}.js?from=#v&to=#{p0ne.version}"

p0ne = window.p0ne # so that modules always refer to their initial `p0ne` object, unless explicitly referring to `window.p0ne`
localStorage.p0neVersion = p0ne.version

#== Auto-Update ==
# check for a new version every 30min
/*setInterval do
    ->
        window.P0NE_UPDATE = true
        p0ne.reload!
            .then ->
                setTimeout do
                    -> window.P0NE_UPDATE = false
                    10_000ms
    30 * 60_000ms*/