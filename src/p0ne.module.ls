/**
 * Module script for loading disable-able chunks of code
 *
 * @author jtbrinkmann aka. Brinkie Pie
 * @license MIT License
 * @copyright (c) 2015 J.-T. Brinkmann
 */
window.module = (name, data) !->
    try
        # setup(helperFNs, module, args)
        # update(helperFNs, module, args, oldModule)
        # disable(helperFNs, module, args)
        if typeof name == \string
            data.name = name
        else
            data = name
            name = data.name if data

        if typeof data == \function
            setup = data
        else
            {require, optional, setup, update, persistent, disable, disableLate, module, settings, displayName, disabled, _settings, settingsPerCommunity, moderator} = data

        if module
            if typeof module == \function
                fn = module
                module = !->
                    return fn.apply module, arguments
                module <<<< data
                # what what, functions apparently don't like the .name property
                Object.defineProperty module, \name, do
                    get: !-> return name
                    #set: (newName) !-> name := newName
            else if typeof module == \object
                module <<<< data
            else
                console.warn "#{getTime!} [#name] TypeError when initializing. `module` needs to be either an Object or a Function but is #{typeof module}"
                module = data
        else
            module = data


        module.displayName = displayName || name
        # sanitize module name (to alphanum-only camel case)
        # UPDATE: the developers should be able to do this for themselves >_>
        #dataName = name
        #    .replace(/^[A-Z]/, (.toLowerCase!)) # first letter is to be lowercase
        #    .replace(/^[^a-z_]/,"_$&") # first letter is to be a letter or a lowdash
        #    .replace(/(\w)?\W+(\w)?/g, (,a,b) !-> return "#{a||''}#{(b||'').toUpperCase!}")

        cbs = module._cbs = {}

        arrEqual = (a, b) !->
            return false if not a or not b or a.length != b.length
            for ,i in a
                return false if a[i] != b[i]
            return true
        objEqual = (a, b) !->
            return true if a == b
            return false if !a or !b #or not arrEqual Object.keys(a), Object.keys(b)
            for k of a
                return false if a[k] != b[k]
            return true

        helperFNs =
            addListener: (target, ...args) !->
                if target == \early
                    [target, ...args] = args
                    if target.onEarly
                        target.onEarly .apply target, args
                    else
                        console.warn "#{getTime!} [#name] cannot use .onEarly on", target
                else if target in <[ once one ]>
                    [target, ...args] = args
                    if target.once or target.one
                        that .apply target, args
                    else
                        console.warn "#{getTime!} [#name] cannot use .once / .one on", target
                else
                    target.on .apply target, args
                cbs.[]listeners[*] = {target, args}
                return args[*-1] # return callback so one can do `do addListener(…)` to initially trigger the callback

            replace: (target, attr, repl) !->
                if attr of target
                    orig = target[attr]
                    # for debugging, not really required
                    target["#{attr}_"] = orig if "#{attr}_" not of target
                else
                    target["#{attr}_"] = null
                target[attr] = replacement = repl(target[attr])
                cbs.[]replacements[*] = [target, attr, replacement, orig]
                return replacement
            revert: (target_, attr_) !->
                return false if not cbs.replacements
                didReplace = false
                if attr_
                    # replace ONE
                    for [target, attr , replacement, orig] in cbs.replacements
                        if target == target_ and attr_ == attr and target[attr] == replacement
                            target[attr] = orig #target["#{attr}_"]
                            cbs.replacements
                            return true
                else if target_
                    # replace ALL for target
                    for [target, attr, replacement, orig] in cbs.replacements when target == target_ and target[attr] == replacement
                            target[attr] = orig #target["#{attr}_"]
                            didReplace = true
                else
                    # replace ALL
                    for [target, attr , replacement, orig] in cbs.replacements when target == target_
                            target[attr] = orig #target["#{attr}_"]
                            didReplace = true
                return didReplace

            replaceListener: (emitter, event, ctx, callback) !->
                if not evts = emitter?._events?[event]
                    console.error "#{getTime!} [ERROR] unable to replace listener of type '#event' (no such event for event emitter specified)", emitter, ctx
                    return false
                if callback
                    for e in evts when e.ctx == ctx  or  typeof ctx == \function and e.ctx instanceof ctx
                        return @replace e, \callback, callback
                else
                    callback = ctx
                    for e in evts when e.ctx.cid
                        return @replace e, \callback, callback

                console.error "#{getTime!} [ERROR] unable to replace listener of type '#event' (no appropriate callback found)", emitter, ctx
                return false

            replace_$Listener: (event, constructor, callback) !->
                if not _$context?
                    console.error "#{getTime!} [ERROR] unable to replace listener in _$context._events['#event'] (no _$context)"
                    return false
                if arguments.length == 2
                    callback = constructor
                    constructor = _$context
                helperFNs.replaceListener _$context, event, constructor, callback

            add: (target, callback, options) !->
                d = [target, callback, options]
                callback .= bind module if options?.bound
                d.index = target.length # not part of the Array, so arrEqual ignores it
                target[d.index] = callback
                cbs.[]adds[*] = d

            addCommand: (commandName, data) !->
                helperFNs.replace chatCommands.commands, commandName, !-> return data
                chatCommands.updateCommands!

            $create: (html) !->
                return cbs.[]$elements[*] = $ html
            $createPersistent: (html) !->
                return cbs.[]$elementsPersistent[*] = $ html
            css: (name, str) !->
                p0neCSS.css name, str
                cbs.{}css[name] = str
            loadStyle: (url) !->
                p0neCSS.loadStyle url
                cbs.{}loadedStyles[url] = true

            toggle: !->
                if @disabled
                    @enable!
                    return true
                else
                    @disable!
                    return false
            enable: !->
                return if not @disabled
                @disabled = false
                disabledModules[name] = false if not module.modDisabled
                try
                    setup.call module, helperFNs, module
                    trigger \moduleEnabled
                    console.info "#{getTime!} [#name] enabled", setup != null
                catch err
                    console.error "#{getTime!} [#name] error while re-enabling", err.messageAndStack
                return this

            disable: (temp) !->
                # if `temp` is true-ish, module will not be disabled in the settings
                # `temp` can also be the new instance of the module, in case it gets updated
                return this if module.disabled
                newModule = temp if temp and temp != true
                try
                    module.disabled = true
                    hasChatCommands = chatCommands?.commands?
                    disable.call module, helperFNs, newModule if typeof disable == \function
                    for {target, args} in cbs.listeners ||[]
                        target.off .apply target, args
                    for [target, attr , replacement, orig] in cbs.replacements ||[]
                        if target[attr] == replacement
                            target[attr] = orig #target["#{attr}_"]
                            if hasChatCommands and target == chatCommands.commands
                                delete chatCommands.commands.roomsettings if not orig
                                chatCommands.updateCommands!
                    for [target /*, callback, options*/]:d in cbs.adds ||[]
                        target .remove d.index
                        d.index = -1
                    for style of cbs.css
                        p0neCSS.css style, "/* disabled */"
                    for url of cbs.loadedStyles
                        p0neCSS.unloadStyle url
                    for $el in cbs.$elements ||[]
                        $el .remove!
                    for m in p0ne.dependencies[name] ||[]
                        m.disable!

                    @_$settingsPanel?.wrapper.remove!
                    delete @_$settingsPanel

                    disabledModules[name] = true if not module.modDisabled and not temp
                    if not newModule
                        for $el in cbs.$elementsPersistent ||[]
                            $el .remove!
                        trigger \moduleDisabled
                        console.info "#{getTime!} [#name] disabled"
                        dataUnload "p0ne/#name"
                    delete [cbs.listeners, cbs.replacements, cbs.adds, cbs.css, cbs.loadedStyles, cbs.$elements]
                    disableLate.call module, helperFNs, newModule if typeof disableLate == \function
                catch err
                    console.error "#{getTime!} [module] failed to disable '#name' cleanly", err.messageAndStack
                    delete window[name]
                delete p0ne.dependencies[name]
                return this
        module.trigger ||= (target, ...args) !-> # FOR DEBUGGING
            for listener in cbs.listeners ||[] when listener.target == target
                #console.log "\thas same target"
                isMatch = true
                l = listener.args.length - 1
                for arg, i in listener.args
                    #console.log "\t\ti = #i", if typeof arg != \function then arg else '[function]'
                    if arg != args[i] and not (typeof arg == \string and arg.split(/\s+/).has(args[i]))
                        if i + 1 < args.length and i != l
                            #console.log "\t\tfound different argument", arg, args[i]
                            isMatch = false
                        break
                if isMatch
                    fn = listener.args[*-1]
                    #console.log "\t\tfound match", (typeof fn == \function), i, args.slice i
                    if typeof fn == \function
                        fn args.slice i

        module.disable = helperFNs.disable
        module.enable = helperFNs.enable

        # if there's an old instance of the module
        if module_ = window[name]
            for k in persistent ||[]
                module[k] = module_[k]
            if not module_.disabled
                try
                    module_.disable? module
                catch err
                    console.error "#{getTime!} [module] failed to disable '#name' cleanly", err.messageAndStack


        # checking dependencies (required modules)
        dependenciesLoading = 1
        failedRequirements = []; l=0
        for r in require ||[]
            if !r
                failedRequirements[l++] = r
            else if (typeof r == \string and not window[r])
                p0ne.dependencies[][r][*] = this
                failedRequirements[l++] = r
            else if l == 0 and r.loading or typeof r == \string and window[r]?.loading
                # add modules to loading queue
                dependenciesLoading++
                that
                    .done loadingDone
                    .fail loadingFailed
        if l
            console.error "#{getTime!} [#name] didn't initialize (#{humanList failedRequirements} #{if failedRequirements.length > 1 then 'are' else 'is'} required)"
            return module

        # checking optional requirements
        optionalRequirements = [r for r in optional ||[] when !r or (typeof r == \string and not window[r])]
        if optionalRequirements.length
            console.warn "#{getTime!} [#name] couldn't load optional requirement#{optionalRequirements.length>1 && 's' || ''}: #{humanList optionalRequirements}. This module may only run with limited functionality"

        # set up Help
        module.help? .= replace /\n/g, "<br>\n"

        if settingsPerCommunity
            roomSlug = getRoomSlug!
            disabledModules = p0ne.disabledModules._rooms[roomSlug]
            module._updateRoom = !->
                module.disable!
                roomSlug = getRoomSlug!
                module_ = module
                disabledModules = p0ne.disabledModules._rooms[roomSlug]
                module.disabled = disabledModules[name]
                def = $.Deferred!
                module.loading = def.promise!

                settingsKey = "p0ne__#{roomSlug}_#name"
                dataLoad settingsKey, _settings, (err, module._settings) !->
                    if err
                        # play it cool (defaulting is magic)
                        console.warn "[p0ne] error loading room settings for #name", err

                    def.resolve module # resolve module.loading
                    delete module.loading

                    # trigger events
                    console.info "#{getTime!} [#name] new room settings loaded"
        else
            disabledModules = p0ne.disabledModules

        # checks if module is disabled
        if name of disabledModules
            module.disabled = disabledModules[name]
        else
            module.disabled = disabledModules[name] = !!disabled

        # disable staff-only modules if user is not staff
        if moderator and not user.isStaff and not module.disabled
            module.modDisabled = module.disabled = true

        # load settings (if any)
        if module_?._settings # use _settings from previous module
            module._settings = module_._settings
        else if _settings
            settingsKey = if settingsPerCommunity then "p0ne__#{roomSlug}_#name" else "p0ne_#name"
            dependenciesLoading++
            dataLoad settingsKey, _settings, (err, module._settings) !->
                if err
                    # play it cool (defaulting is magic)
                    console.warn "[p0ne] error loading settings for #name", err
                loadingDone!

        window[name] = p0ne.modules[name] = module

        # create a Promise, if module is loading
        # so that other modules which require this module can attach callbacks
        if dependenciesLoading > 1
            def = $.Deferred()
            module.loading = def.promise!
        loadingDone!



    catch e
        console.error "#{getTime!} [p0ne module] error initializing '#name':", e.messageAndStack
    return module

    function loadingDone
        # callback when a requirement is loaded (doesn't matter which)
        # check if all requirements are loaded.
        # abort if there are failed requirements
        #   (because attached callbacks to other required modules
        #   before noticing a missing/failed requirement)
        if --dependenciesLoading == 0 == failedRequirements.length
            # run setup
            delete module.loading
            if module.disabled
                if module.modDisabled
                    wasDisabled = ", %cbut is for moderators only"
                else
                    wasDisabled = ", %cbut is (still) disabled"
                def?.reject module # resolve module.loading
            else
                wasDisabled = "%c"
                try # run module's setup function
                    setup?.call module, helperFNs, module, module_
                    def?.resolve module # resolve module.loading
                catch e # in case there was an oopsie
                    console.error "#{getTime!} [#name] error initializing", e.messageAndStack
                    module.disable(true) # try to disable it. (internally wrapped in a try-catch)
                    def?.reject module # reject module.loading

            # trigger events
            if module_
                trigger \moduleUpdated
                console.info "#{getTime!} [#name] updated#wasDisabled", "color: orange"
            else
                trigger \moduleLoaded
                console.info "#{getTime!} [#name] initialized#wasDisabled", "color: orange"

            if not module.disabled
                trigger \moduleEnabled

    function loadingFailed
        # if any dependency fails to load
        def?.reject module # reject module.loading
        delete module.loading
        delete window[name]

    function trigger type
        if _$context?
            _$context.trigger "p0ne:#type", module, module_
            #_$context.trigger "p0ne:#type:#name", module, module_
        API.trigger "p0ne:#type", module, module_
        #API.trigger "p0ne:#type:#name", module, module_

window.loadModule = (moduleName, url) !->
    def = $.Deferred!
    if p0ne.modules[moduleName]
        if p0ne.modules[moduleName].loading
            console.log "[loadModule] module loading", moduleName, url
            p0ne.modules[moduleName].loading .then def.resolve
        else
            console.log "[loadModule] module already loaded", moduleName, url
            return def.resolve(p0ne.modules[moduleName])

    window[moduleName] = p0ne.modules[moduleName] =
        loading: def
        disable: (,m) !-> _.defer !->
            if m?.loading
                console.log "[loadModule] module loading", moduleName, url
                p0ne.modules[moduleName].loading .then def.resolve
            else if m
                console.log "[loadModule] module initialized", moduleName, url
                def.resolve(m)
            else
                def.reject!

    console.log "[loadModule] loading", moduleName, url
    $.getScript url
        .then !->
            console.log "[loadModule] script loaded", moduleName, url
        .fail !->
            console.warn "[loadModule] script failed to load", moduleName, url
            def.reject
    return def