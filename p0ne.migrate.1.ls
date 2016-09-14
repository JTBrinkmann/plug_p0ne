/**
 * plug_p0ne migration plugin (for version 1.*)
 * migrates settings and ensures already running plug_p0ne modules can be updated properly
 * @author jtbrinkmann aka. Brinkie Pie
 * @version 1.0
 * @license MIT License
 * @copyright (c) 2014 J.-T. Brinkmann
*/

/* this script is expected to run AFTER plug_p0ne.head attempted to load
 * so it is expected, that window.compareVersions is defined
 */
do ->
    /* lastCompatibleVersion = \1.3.3 */
    var vArr
    migrated = (v) ->
        API.trigger \p0ne_migrated, v
        localStorage.p0neVersion = v

    if not (v = localStorage.p0neVersion)
        # no previous version of p0ne found, looks like we're good to go
        # p0ne.migrate should not be run if there's no previous version to migrate from
        return

    console.info "[p0ne migrate] migrating p0ne…"
    switch false
    | compareVersions v, \1.2.0 =>
        console.info "[p0ne migrate] updating user settings to plug_p0ne v1.2.0 (new compression)"
        # settings
        for key in <[ requireIDs playlistData songData ]> when localStorage[key]
            console.info "\tcompressing #key"
            localStorage[key] = LZString.compress(localStorage[key])

        # runtime

        migrated \1.2.0
        fallthrough
    | compareVersions v, \1.3.3 =>
        console.info "[p0ne migrate] updating user settings to plug_p0ne v1.3.2 (fixed settings compression; changed p0ne.modules from Array to Object)"
        # settings
        if not window.chrome
            for k,v of localStorage when k not in <[ amplitude_lastEventId amplitude_lastEventTime amplitude_unsent length p0neVersion vanillaAvatarID ]>
                try
                    localStorage[k] = v |> LZString.decompress |> LZString.compressToUTF16
                catch err
                    if k in <[ automute moduleSettings requireIDs ]>
                        console.warn "could not migrate #v"

        # runtime
        if p0ne?.modules?.length
            p0ne.modules = {[m.name, m] for m in p0ne.modules}

        migrated \1.3.3
        fallthrough
    | compareVersions v, \1.3.9 =>
        console.info "[p0ne migrate] updating user settings to plug_p0ne v1.3.9 (renamed attributes in localStorage)"

        # settings
        for k, v of localStorage when k.substr(0,5) == "p0ne/"
            localStorage["p0ne_#{k.substr(5)}"] = localStorage[k]
            delete localStorage[k]
        for k in <[ requireIDs automute moduleSettings ]> when k of localStorage
            localStorage["p0ne_#k"] = localStorage[k]
            delete localStorage[k]

        # runtime

        migrated \1.3.9
        fallthrough
    #| compareVersions v, \1.4.0 =>
    #    ...
    #    migrated \1.4.0
    #    fallthrough
