/**
 * Module script for loading disable-able chunks of code
 * @author jtbrinkmann aka. Brinkie Pie
 * @version 1.0
 * @license MIT License
 * @copyright (c) 2014 J.-T. Brinkmann
 */
p0ne.moduleSettings = dataLoad \p0ne_moduleSettings, {}
window.module = (name, data) ->
    try
        # setup(helperFNs, module, args)
        # update(helperFNs, module, args, oldModule)
        # disable(helperFNs, module, args)
        if typeof name != \string
            data = name
        else
            data.name = name
        data = {setup: data} if typeof data == \function

        # set defaults here so that modifying their local variables will also modify them inside `module`
        data.persistent ||= {}
        {name, require, optional, callback,  setup, update, persistent, disable, module, settings, displayName, disabled, _settings, moderator} = data
        data.callbacks[*] = callback if callback
        if module
            if typeof module == \function
                fn = module
                module = ->
                    fn.apply module, arguments
                module <<<< data
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
        #    .replace(/(\w)?\W+(\w)?/g, (,a,b) -> return "#{a||''}#{(b||'').toUpperCase!}")

        cbs = module._cbs = {}

        arrEqual = (a, b) ->
            return false if not a or not b or a.length != b.length
            for ,i in a
                return false if a[i] != b[i]
            return true
        objEqual = (a, b) ->
            return true if a == b
            return false if !a or !b #or not arrEqual Object.keys(a), Object.keys(b)
            for k of a
                return false if a[k] != b[k]
            return true

        helperFNs =
            addListener: (target, ...args) ->
                if target == \early
                    early = true
                    [target, ...args] = args
                cbs.[]listeners[*] = {target, args}
                if not early
                    target.on .apply target, args
                else if not target.onEarly
                    console.warn "#{getTime!} [#name] cannot use .onEarly on", target
                else
                    target.onEarly .apply target, args
                return args[*-1] # return callback so one can do `do addListener(…)` to initially trigger the callback

            replace: (target, attr, repl) ->
                cbs.[]replacements[*] = [target, attr, repl]
                if attr of target
                    target["#{attr}_"] ?= target[attr]
                else
                    target["#{attr}_"] = false
                target[attr] = repl(target["#{attr}_"])

            replaceListener: (emitter, event, ctx, callback) ->
                if not evts = emitter?._events?[event]
                    console.error "#{getTime!} [ERROR] unable to replace listener of type '#event' (no such event for event emitter specified)", emitter, ctx
                    return false
                if callback
                    for e in evts when e.ctx@@ == ctx
                        return @replace e, \callback, callback
                else
                    callback = ctx
                    for e in evts when e.ctx.cid
                        return @replace e, \callback, callback

                console.error "#{getTime!} [ERROR] unable to replace listener of type '#event' (no appropriate callback found)", emitter, ctx
                return false

            replace_$Listener: (event, constructor, callback) ->
                if not _$context?
                    console.error "#{getTime!} [ERROR] unable to replace listener in _$context._events['#event'] (no _$context)"
                    return false
                helperFNs.replaceListener _$context, event, constructor, callback

            add: (target, callback, options) ->
                d = [target, callback, options]
                callback .= bind module if options?.bound
                d.index = target.length # not part of the Array, so arrEqual ignores it
                target[d.index] = callback
                cbs.[]adds[*] = d

            $create: (html) ->
                return cbs.[]$elements[*] = $ html
            $createPersistent: (html) ->
                return cbs.[]$elementsPersistent[*] = $ html
            css: (name, str) ->
                p0neCSS.css name, str
                cbs.{}css[name] = str
            loadStyle: (url) ->
                p0neCSS.loadStyle url
                cbs.{}loadedStyles[url] = true

            toggle: ->
                if @disabled
                    @enable!
                    return true
                else
                    @disable!
                    return false
            enable: ->
                return if not @disabled
                @disabled = false
                moduleSettings.disabled = false if not module.modDisabled
                try
                    setup.call module, helperFNs, module, data, module
                    API.trigger \p0neModuleEnabled, module
                    console.info "#{getTime!} [#name] enabled", setup != null
                catch err
                    console.error "#{getTime!} [#name] error while re-enabling", err.stack
                return this
            disable: (newModule) ->
                return if module.disabled
                try
                    module.disabled = true
                    disable.call module, helperFNs, newModule, data if typeof disable == \function
                    for {target, args} in cbs.listeners ||[]
                        target.off .apply target, args
                    for [target, attr /*, repl*/] in cbs.replacements ||[]
                        target[attr] = target["#{attr}_"]
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
                    if not newModule
                        moduleSettings.disabled = true if not module.modDisabled
                        for $el in cbs.$elementsPersistent ||[]
                            $el .remove!
                        API.trigger \p0neModuleDisabled, module
                        console.info "#{getTime!} [#name] disabled"
                        dataUnload "p0ne/#name"
                    delete [cbs.listeners, cbs.replacements, cbs.adds, cbs.css, cbs.loadedStyles, cbs.$elements]
                catch err
                    console.error "#{getTime!} [module] failed to disable '#name' cleanly", err.stack
                    delete window[name]
                delete p0ne.dependencies[name]
                return this

        module.disable = helperFNs.disable
        module.enable = helperFNs.enable
        if module_ = window[name]
            if persistent
                for k in persistent ||[]
                    module[k] = module_[k]
            module._$settings = module_._$settings
            _settings_ = module_._settings
            module_.disable? module



        failedRequirements = []; l=0
        for r in require ||[]
            if !r
                failedRequirements[l++] = r
            else if (typeof r == \string and not window[r])
                p0ne.dependencies[][r][*] = this
                failedRequirements[l++] = r
        if failedRequirements.length
            console.error "#{getTime!} [#name] didn't initialize (#{humanList failedRequirements} #{if failedRequirements.length > 1 then 'are' else 'is'} required)"
            return module
        optionalRequirements = [r for r in optional ||[] when !r or (typeof r == \string and not window[r])]
        if optionalRequirements.length
            console.warn "#{getTime!} [#name] couldn't load optional requirement#{optionalRequirements.length>1 && 's' || ''}: #{humanList optionalRequirements}. This module may only run with limited functionality"

        try
            window[name] = module

            # set up Help and Settings
            module.help? .= replace /\n/g, "<br>\n"

            moduleSettings = p0ne.moduleSettings[name]
            if moduleSettings
                module.disabled = moduleSettings.disabled
            else
                moduleSettings = p0ne.moduleSettings[name] = {disabled: !!disabled}
            @moduleSettings = moduleSettings

            if moderator and API.getUser!.role < 2 and not module.disabled
                module.modDisabled = true
                module.disabled = true

            # initialize module
            if not module.disabled
                module._settings = _settings_ || dataLoad "p0ne_#name", _settings if _settings
                setup?.call module, helperFNs, module, data, module_

            p0ne.modules[name] = module
            if module_
                API.trigger \p0neModuleUpdated, module
                console.info "#{getTime!} [#name] updated"
            else
                API.trigger \p0neModuleLoaded, module
                console.info "#{getTime!} [#name] initialized"
        catch e
            console.error "#{getTime!} [#name] error initializing", e.stack

        return module
    catch e
        console.error "#{getTime!} [module] error initializing '#name':", e.message
