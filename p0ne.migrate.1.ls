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
    var vArr
    lastCompatibleVersion = \1.2.0
    migrated = (v) ->
        API.trigger "p0ne_migrated_#v"
        localStorage.p0neVersion = v

    if not (v = localStorage.p0neVersion)
        # no previous version of p0ne found, looks like we're good to go
        return migrated!

    switch
    | compareVersions v, \1.2.0 =>
        console.info "[p0ne migrate] updating user settings to plug_p0ne v1.2.0 (new compression)"
        for key in <[ requireIDs playlistData songData ]> when localStorage[key]
            console.info "\tcompressing #key"
            localStorage[key] = LZString.compress(localStorage[key])

        migrated \1.2.0
        fallthrough
    #| compareVersions v, \1.3.0 =>
    #    ...
    #    migrated \1.3.0
    #    fallthrough

    migrated!