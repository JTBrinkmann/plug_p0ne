/**
 * plug_p0ne - a modern script collection to improve plug.dj
 * adds a variety of new functions, bugfixes, tweaks and developer tools/functions
 *
 * This script collection is written in LiveScript (a CoffeeScript descendend which compiles to JavaScript). If you are reading this in JavaScript, you might want to check out the LiveScript file instead for a better documented and formatted source; just replace the .js with .ls in the URL of this file
 * @author jtbrinkmann aka. Brinkie Pie
 * @version 1.2.3
 * @license MIT License
 * @copyright (c) 2014 J.-T. Brinkmann
*/

console.info "~~~~~~~~~~~~ plug_p0ne loading ~~~~~~~~~~~~"
p0ne_ = window.p0ne
window.p0ne =
    version: \1.5.7
    lastCompatibleVersion: \1.5.0 /* see below */
    host: 'https://cdn.p0ne.com'
    SOUNDCLOUD_KEY: \aff458e0e87cfbc1a2cde2f8aeb98759
    YOUTUBE_KEY: \AI39si6XYixXiaG51p_o0WahXtdRYFCpMJbgHVRKMKCph2FiJz9UCVaLdzfltg1DXtmEREQVFpkTHx_0O_dSpHR5w0PTVea4Lw
    proxy: (url) -> return "https://jsonp.nodejitsu.com/?raw=true&url=#{escape url}" # for cross site requests
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
    /* save data of previous p0ne instances */
    saveData?!

/*####################################
#           COMPATIBILITY            #
####################################*/
/* check if last run p0ne version is incompatible with current and needs to be migrated */
window.compareVersions = (a, b) -> /* returns whether `a` is greater-or-equal to `b`; e.g. "1.2.0" is greater than "1.1.4.9" */
    a .= split \.
    b .= split \.
    for ,i in a when a[i] != b[i]
        return a[i] > b[i]
    return b.length > a.length


<-      (fn_) ->
    if window.P0NE_UPDATE
        window.P0NE_UPDATE = false
        if p0ne_?.version == window.p0ne.version
            return
        else
            API.chatLog? "plug_p0ne automatically updated to v#{p0ne.version}", true

    if console and typeof (console.group || console.groupCollapsed) == \function
        fn = ->
            if console.groupCollapsed
                console.groupCollapsed "[p0ne] initializing… (click on this message to expand/collapse the group)"
            else
                console.group "[p0ne] initializing…"

            errors = warnings = 0
            error_ = console.error; console.error = -> errors++; error_ ...
            warn_ = console.warn; console.warn = -> warnings++; warn_ ...

            fn_!

            console.groupEnd!
            console.info "[p0ne] initialized!"
            console.error = error_; console.warn = warn_
            console.error "[p0ne] There have been #errors errors" if errors
            console.warn "[p0ne] There have been #warnings warnings" if warnings
    else
        fn = fn_
    if not (v = localStorage.p0neVersion)
        # no previous version of p0ne found, looks like we're good to go
        return fn!

    if compareVersions(v, p0ne.lastCompatibleVersion)
        # no migration required, continue
        fn!
    else
        # incompatible, load migration script and continue when it's done
        console.warn "[p0ne] obsolete p0ne version detected (#v), loading migration script…"
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