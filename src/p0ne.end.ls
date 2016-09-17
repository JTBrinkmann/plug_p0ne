_.defer !->
    remaining = 1
    for name, m of p0ne.modules when m.loading
        remaining++
        m.loading .always moduleLoaded
    moduleLoaded!
    console.info "#{getTime!} [p0ne] #{plural remaining, 'module'} still loading" if remaining

    function moduleLoaded m
        if --remaining == 0
            console.error = error_; console.warn = warn_
            console.groupEnd!
            console.info "[p0ne] initialized!"
            console.error "[p0ne] There have been #errors errors" if errors
            console.warn "[p0ne] There have been #warnings warnings" if warnings

            # show disabled warnings
            noCollapsedGroup = true
            for name, m of p0ne.modules when m.disabled and not m.settings and not (m.moderator and user.isStaff)
                if noCollapsedGroup
                    console.groupCollapsed "[p0ne] there are disabled modules which are hidden from the settings"
                    noCollapsedGroup = false
                console.warn "\t#name", m
            console.groupEnd! if not noCollapsedGroup

            appendChat? "<div class='cm p0ne-notif p0ne-notif-loaded'>plug_p0ne v#{p0ne.version} loaded #{getTimestamp?!}</div>"
            console.timeEnd "[p0ne] completly loaded"
            _$context?.trigger \p0ne:loaded, p0ne
            API.trigger \p0ne:loaded, p0ne