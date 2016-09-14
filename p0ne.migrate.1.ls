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
    migrated = (v) ->
        API.trigger \p0ne_migrated, v
        localStorage.p0neVersion = v

    if not (v = localStorage.p0neVersion)
        # no previous version of p0ne found, looks like we're good to go
        # p0ne.migrate should not be run if there's no previous version to migrate from
        return


    if window.chrome
        window{compress, decompress} = LZString
    else
        window{compressToUTF16:compress, decompressFromUTF16:decompress} = LZString

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
    | compareVersions v, \1.5.0 =>
        console.info "[p0ne migrate] fixed a bug introduced by the plug.dj update on 2015-02-05 causing CSS classes to be incorrect added to the chat"
        # settings

        # runtime
        $ \#chat-messages .removeClass!
        PopoutView?.chat?.$el .removeClass!

        migrated \1.5.0
        fallthrough
    | compareVersions v, \1.6.1 =>
        console.info "[p0ne migrate] renamed a few modules and CSS classes"
        #= settings =
        # renamed modules
        editSettings \moduleSettings, (moduleSettings) ->
            renameMap =
                _API_: \InternalAPI
                p0neChatInput: \betterChatInput
            for oldModuleName, newModuleName of renameMap
                localStorage["p0ne_#newModuleName"] = localStorage["p0ne_#oldModuleName"]
                moduleSettings[newModuleName] = moduleSettings[oldModuleName]
                delete localStorage["p0ne_#oldModuleName"]
                delete moduleSettings[oldModuleName]

            # renamed settings.warnings => settings.verbose
            for module in <[ fixGhosting fixOthersGhosting fixNoPlaylistCycle ]>
                editSettings module, (settings) ->
                    settings.verbose = settings.warnings
                    delete settings.warnings

            # force-enable p0ne.stream
            moduleSettings.streamSettings.disabled = false

        #= runtime =
        renameMap =
            \p0ne-joinleave-notif : \p0ne-notif-joinleave
            \p0ne_img_failed : \p0ne-img-failed
            \p0ne_img : \p0ne-img
            \p0ne_img_large : \p0ne-img-large
            \p0ne_yt_img : \p0ne-yt-img
            \p0ne_yt : \p0ne-yt
            \song-notif : \p0ne-song-notif
        for oldClass, newClass of renameMap
            $(".#oldClass").removeClass(oldClass).addClass(newClass)
        # renamed events
        if API?._events?
            API._events[\p0ne:songInHistory] = API._events[\p0ne_songInHistory]
            delete API._events[\p0ne_songInHistory]

        migrated \1.6.1
        fallthrough
    | compareVersions v, \1.6.5 =>
        console.info "[p0ne migrate] added perCommunity settings, fixed a bunch of bugs"
        # settings
        perCommunityModules = <[ autojoin customAvatars fimstats ponify bpm ]>
        editSettings \moduleSettings, (moduleSettings) ->
            for module in perCommunityModules
                localStorage["p0ne__friendshipismagic_#module"] = localStorage["p0ne_#module"]
                delete moduleSettings[module].disabled if moduleSettings[module]

        # runtime

        migrated \1.6.5
        fallthrough
    #| compareVersions v, \1.6.0 =>
    #    ...
    #    migrated \1.4.0
    #    fallthrough
function editSettings moduleName, cb
    try
        return false if not settings = localStorage["p0ne_#moduleName"]
        settings = settings |> decompress |> JSON.parse
        cb settings
        localStorage["p0ne_#moduleName"] = settings |> JSON.stringify |> compress
        return true
    catch err
        console.error "[p0ne migrate] error while editing settings for '#moduleName'", err.stack
        return false