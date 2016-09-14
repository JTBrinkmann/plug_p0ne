/**
 * Module script for loading disable-able chunks of code
 * @author jtbrinkmann aka. Brinkie Pie
 * @version 1.0
 * @license MIT License
 * @copyright (c) 2014 J.-T. Brinkmann
 */
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
        {name, require, optional, callback,  setup, update, persistent, enable, disable, module, settings, displayName} = data
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
                console.warn "[#name] TypeError when initializing. `module` needs to be either an Object or a Function but is #{typeof module}"
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
                    return target.on .apply target, args
                else if not target.onEarly
                    console.warn "[#name] cannot use .onEarly on", target
                else
                    return target.onEarly .apply target, args

            replace: (target, attr, repl) ->
                cbs.[]replacements[*] = [target, attr, repl]
                target["#{attr}_"] ||= target[attr]
                target[attr] = repl(target["#{attr}_"])

            replace_$Listener: (type, callback) ->
                if not window._$context
                    console.error "[ERROR] unable to replace listener in _$context._events['#type'] (no _$context)"
                    return false
                if not evts = _$context._events[type]
                    console.error "[ERROR] unable to replace listener in _$context._events['#type'] (no such event)"
                    return false
                for e in evts when e.context?.cid
                    return @replace e, \callback, callback

                console.error "[ERROR] unable to replace listener in _$context._events['#type'] (no vanilla callback found)"
                return false

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
                return if p0neCSS.$el.filter "[href='#url']" .length
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
                setup?.call module, helperFNs, module, data, module_
                API.trigger \p0neModuleEnabled, module
                console.info "[#name] enabled"
            disable: (newModule) ->
                return if module.disabled
                try
                    module.disabled = true
                    disable?.call module, helperFNs, newModule, data
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
                    for m in p0ne.dependencies[name] ||[]
                        m.disable!
                    for $el in cbs.$elements ||[]
                        $el .remove!
                    if not newModule
                        for $el in cbs.$elementsPersistent ||[]
                            $el .remove!
                        API.trigger \p0neModuleDisabled, module
                        console.info "[#name] disabled"
                    delete [cbs.listeners, cbs.replacements, cbs.adds, cbs.css, cbs.loadedStyles, cbs.$elements]
                catch err
                    console.error "[module] failed to disable '#name' cleanly", err.stack
                    delete window[name]
                delete p0ne.dependencies[name]

        module.disable = helperFNs.disable
        module.enable = helperFNs.enable
        if module_ = window[name]
            if persistent
                for k in persistent ||[]
                    module[k] = module_[k]
            module_.disable? module
        failedRequirements = []; l=0
        for r in require ||[]
            if !r
                failedRequirements[l++] = r
            else if (typeof r == \string and not window[r])
                p0ne.dependencies[][r][*] = this
                failedRequirements[l++] = r
        if failedRequirements.length
            console.error "[#name] didn't initialize (#{humanList failedRequirements} #{if failedRequirements.length > 1 then 'are' else 'is'} required)"
            return module
        optionalRequirements = [r for r in optional ||[] when !r or (typeof r == \string and not window[r])]
        if optionalRequirements.length
            console.warn "[#name] couldn't load optional requirement#{optionalRequirements.length>1 && 's' || ''}: #{humanList optionalRequirements}. This module may only run with limited functionality"

        try
            window[name] = module

            # set up Help and Settings
            module.help? .= replace /\n/g, "<br>\n"

            # initialize module
            if not module.disabled
                setup?.call module, helperFNs, module, data, module_

            p0ne.modules[*] = module
            if module_
                API.trigger \p0neModuleUpdated, module
                console.info "[#name] updated"
            else
                API.trigger \p0neModuleLoaded, module
                console.info "[#name] initialized"
        catch e
            console.error "[#name] error initializing", e.stack

        return module
    catch e
        console.error "[module] error initializing '#name':", e.message