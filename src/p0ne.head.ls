/**
 * plug_p0ne - a modern script collection to improve plug.dj
 * adds a variety of new functions, bugfixes, tweaks and developer tools/functions
 *
 * This script collection is written in LiveScript (a CoffeeScript descendend which compiles to JavaScript). If you are reading this in JavaScript, you might want to check out the LiveScript file instead for a better documented and formatted source; just replace the .js with .ls in the URL of this file
 *
 * @author jtbrinkmann aka. Brinkie Pie
 * @license MIT License
 * @copyright (c) 2014-2015 J.-T. Brinkmann
 *
 * further credits go to
 *     the plugCubed Team - for coining a standard for the "Custom Room Settings"
 *     all the beta testers! <3
 *     plug.dj - for it's horribly broken implementation of everything.
 *               "If it wasn't THAT broken, I wouldn't have had as much fun in coding plug_p0ne"
 *                   --Brinkie Pie (2015)
 *
 * The following 3rd party scripts are used:
 *     - pieroxy's      lz-string    https://github.com/pieroxy/lz-string (DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE)
 *     - Mozilla's      localforage  https://github.com/mozilla/localforage (Apache License v2.0)
 *     - Stefan Petre's Color Picker http://www.eyecon.ro/colorpicker/ (Dual licensed under the MIT and GPL licenses)
 *
 * The following are not used by plug_p0ne, but provided for usage in the console, for easier debugging
 *     - Oliver Steele's lambda.js https://github.com/fschaefer/Lambda.js (MIT License)
 *     - SteamDev's      zClip     http://steamdev.com/zclip/ (MIT license)
 *         - using Marcus Handa & Isaac Durazo's ZeroClipboard http://zeroclipboard.org/ (MIT License)
 *
 * Not happy with plug_p0ne? contact me (the developer) at brinkiepie@gmail.com
 * great alternative plug.dj scripts are
 *     - RCS       (best alternative I could recommend - https://radiant.dj/rcs )
 *     - TastyPlug (relatively lightweight but does a good job - https://fungustime.pw/tastyplug/ )
 *     - plugCubed (does a lot of things, but breaks often and doesn't seem to be actively developed anymore - https://plugcubed.net/ )
 *     - plugplug  (lightweight as heck - https://bitbucket.org/mateon1/plugplug/ )
 */

console.info "~~~~~~~~~~~~ plug_p0ne loading ~~~~~~~~~~~~"
console.time? "[p0ne] completly loaded"
p0ne_ = window.p0ne
window.p0ne =
    #== Constants ==
    version: \1.9.0
    lastCompatibleVersion: \1.8.8.2 /* see below */
    host: 'https://cdn.p0ne.com'
    SOUNDCLOUD_KEY: \aff458e0e87cfbc1a2cde2f8aeb98759
    YOUTUBE_V3_KEY: \AIzaSyDaWL9emnR9R_qBWlDAYl-Z_h4ZPYBDjzk
    FIMSTATS_KEY: \4983a7f2-b253-4300-8b18-6e7c57db5e2e

    # for cross site requests
    proxy: (url) !-> return "https://cors-anywhere.herokuapp.com/#{url .replace /^.*\/\//, ''}"
    #proxy: (url) !-> return "https://jsonp.nodejitsu.com/?raw=true&url=#{escape url}"
    #https://blog.5apps.com/2013/03/02/new-service-cors-ssl-proxy.html

    started: new Date()
    autosave: {}
    autosave_num: {}
    modules: p0ne?.modules || {}
    dependencies: {}
    reload: !->
        return $.getScript "#{@host}/scripts/plug_p0ne.beta.js"
    close: !->
        console.groupCollapsed "[p0ne] closing"
        for ,m of @modules
            m.settingsSave?!
            m.disable(true)
        if typeof window.dataSave == \function
            window.dataSave!
            $window .off \beforeunload, window.dataSave
            clearInterval window.dataSave.interval
        console.groupEnd "[p0ne] closing"
console.info "plug_p0ne v#{p0ne.version}"

try
    window.dataSave?! /* save data of previous p0ne instances */


/*####################################
#           COMPATIBILITY            #
####################################*/
/* check if last run p0ne version is incompatible with current and needs to be migrated */
window.compareVersions = (a, b) !-> /* returns whether `a` is greater-or-equal to `b`; e.g. "1.2.0" is greater than "1.1.4.9" */
    a .= split \.
    b .= split \.
    for ,i in a when a[i] != b[i]
        return a[i] > b[i]
    return b.length >= a.length


errors = warnings = 0
error_ = console.error; console.error = !-> errors++; error_ ...
warn_ = console.warn; console.warn = !-> warnings++; warn_ ...

API?.enabled = true # to make plug_p0ne work for guests
<-      (fn__) !->
    if window.P0NE_UPDATE
        window.P0NE_UPDATE = false
        if p0ne_?.version == window.p0ne.version
            return
        else
            chatWarn? "automatically updated to v#{p0ne.version}", 'plug_p0ne'

    if not console.group
        console.group = console.log
        console.groupEnd = $.noop
    fn_ = !->
        try
            fn__!
        catch err
            console.error = error_; console.warn = warn_
            console.groupEnd!;console.groupEnd!;console.groupEnd!
            console.error "[plug_p0ne fatal error]" err
            console.error "[p0ne] There have been #errors (other) errors" if errors
            console.warn "[p0ne] There have been #warnings warnings" if warnings

            API.chatLog("failed to load plug_p0ne: fatal error")
            #ToDo upload error stack to pastebin
            #ToDo auto bug reporting
    fn = !->
        #== fix LocalForage ==
        # In Firefox' private mode, indexedDB will fail, and thus localforage will also fail silently
        # See https://github.com/mozilla/localForage/issues/195
        # To fix this, we test if indexedDB works and fall back to localStorage if not.
        # In my test this took ~30ms on Google Chrome and ~250ms on Firefox (working) and ~2ms on Firefox in private mode (failing);
        # once the database is created, it took ~1ms on Google Chrome and ~5ms on Firefox (working) on successive tries (after page reloads)
        try
            if (window.indexedDB || window.webkitIndexedDB || window.mozIndexedDB || window.OIndexedDB || window.msIndexedDB)
                that .open \_localforage_spec_test, 1
                    ..onsuccess = !->
                        fn_!
                    ..onerror = ..onblocked = ..onupgradeneeded = (err) !->
                        # fall back to localStorage
                        delete! [window.indexedDB, window.webkitIndexedDB, window.mozIndexedDB, window.OIndexedDB, window.msIndexedDB]
                        console.error "[p0ne] indexDB doesn't work, falling back to localStorage", err
                        fn_!
            else
                fn_!
        catch err
            # change to localStorage
            console.error "[p0ne] indexDB doesn't work, falling back to localStorage", err
            delete! [window.indexedDB, window.webkitIndexedDB, window.mozIndexedDB, window.OIndexedDB, window.msIndexedDB]
            fn_!

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
        API.on \p0ne_migrated, onMigrated = (newVersion) !->
            if newVersion == p0ne.lastCompatibleVersion
                API.off \p0ne_migrated, onMigrated
                fn!
        $.getScript "#{p0ne.host}/scripts/plug_p0ne.migrate.#{v.substr(0,v.indexOf(\.))}.js?from=#v&to=#{p0ne.version}"

/* start of fn_ */
/* if needed, this function is called once plug_p0ne successfully migrated. Otherwise it gets called right away */

if console.groupCollapsed
    console.groupCollapsed "[p0ne] initializing… (click on this message to expand/collapse the group)"
else
    console.groupCollapsed = console.group
    console.group "[p0ne] initializing…"

p0ne = window.p0ne # so that modules always refer to their initial `p0ne` object, unless explicitly referring to `window.p0ne`
localStorage.p0neVersion = p0ne.version

#== Auto-Update ==
# check for a new version every 30min
/*setInterval do
    !->
        window.P0NE_UPDATE = true
        p0ne.reload!
            .then !->
                setTimeout do
                    !-> window.P0NE_UPDATE = false
                    10_000ms
    30 * 60_000ms*/

#== fix problems with requireJS ==
requirejs.define = window.define
window.require = window.define = window.module = false