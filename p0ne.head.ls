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
window.p0ne =
    version: \1.2.3
    lastCompatibleVersion: \1.2.1 /* see below */
    host: 'https://cdn.p0ne.com'
    SOUNDCLOUD_KEY: \aff458e0e87cfbc1a2cde2f8aeb98759
    YOUTUBE_KEY: \AI39si6XYixXiaG51p_o0WahXtdRYFCpMJbgHVRKMKCph2FiJz9UCVaLdzfltg1DXtmEREQVFpkTHx_0O_dSpHR5w0PTVea4Lw
    proxy: (url) -> return "https://jsonp.nodejitsu.com/?raw=true&url=#url" # for cross site requests
    started: new Date()
    lsBound: {}
    modules: []
    dependencies: {}

/*####################################
#           COMPATIBILITY            #
####################################*/
/* check if last run p0ne version is incompatible with current and needs to be migrated */
window.compareVersions = (a, b) -> /* returns whether `a` is greater-or-equal to `b`; e.g. "1.2.0" is greater than "1.1.4.9" */
    a .= split \.
    b .= split \.
    for ,i in a
        if a[i] < b[i]
            return false
        else if a[i] > b[i]
            return true
    return true


<-      (fn) ->
    if not (v = localStorage.p0neVersion)
        # no previous version of p0ne found, looks like we're good to go
        return fn!

    if compareVersions(v, p0ne.lastCompatibleVersion)
        # no migration required, continue
        fn!
    else
        # incompatible, load migration script and continue when it's done
        console.warn "[p0ne] obsolete p0ne version detected (#v), migrating…"
        API.once "p0ne_migrated_#{p0ne.lastCompatibleVersion}", fn
        $.getScript "#{p0ne.host}/script/plug_p0ne.migrate.#{vArr.0}.js?from=#v&to=#{p0ne.version}"

p0ne = window.p0ne
localStorage.p0neVersion = p0ne.version