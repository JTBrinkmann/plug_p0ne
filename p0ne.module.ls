/**
 * Module script for loading disable-able chunks of code
 * @author jtbrinkmann aka. Brinkie Pie
 * @version 1.0
 * @license MIT License
 * @copyright (c) 2014 J.-T. Brinkmann
 */
window.module = (name, data) -> # data = {name, require, optional, callback, callbacks, setup, update, persistent, enable, disable, module}
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
        data.callbacks ||= []
        data.persistent ||= {}
        {name, require, optional, callback, callbacks, setup, update, persistent, enable, disable, module, settings, displayName} = data
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
        apply_ = Function::apply
        toggle = (fn, d) ->
            if d.length
                [target, event, ...args, callback] = d
            else
                {target, event, args, callback} = d
            if args
                apply_.apply target[fn], d
            else
                target[fn] event, callback
            return callback

        helperFNs =
            addListener: (/*target, event, ...args, callback*/) ->
                return toggle \on, (cbs.[]listeners[*] = [] <<<< arguments)

            replace: (target, attr, repl) ->
                cbs.[]replacements[*] = [target, attr, repl]
                target["#{attr}_"] ||= target[attr]
                repl = module[repl] if typeof repl == \string and module[repl]
                if typeof repl == \function
                    target[attr] = repl(target["#{attr}_"])
                else
                    target[attr] = repl
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

            $create: (str) ->
                return cbs.[]$elements[*] = $ str

            disable: ->
                return if module.disabled
                module.disabled = true
                disable?.call module, helperFNs, module, data
                for d in cbs.listeners ||[]
                    toggle \off, d
                for [target, attr /*, repl*/] in cbs.replacements ||[]
                    target[attr] = target["#{attr}_"]
                for [target /*, callback, options*/]:d in cbs.adds ||[]
                    target .remove d.index
                    d.index = -1
                for $el in cbs.$elements ||[]
                    $el .remove!
                for m in p0ne.dependencies[name] ||[]
                    m.disable!
                delete! p0ne.dependencies[name]

        module.disable = helperFNs.disable
        if module_ = window[name]
            if persistent
                for k in persistent ||[]
                    module[k] = module_[k]
            module_.disable!
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
            for cbName, d of callbacks
                d.isModuleCallback = true
                helperFNs.addListener d
            setup?.call module, helperFNs, module, data, module_

            API.trigger \p0neModuleLoaded, module
            if module_
                console.info "[#name] updated"
            else
                console.info "[#name] initialized"
        catch e
            console.error "[#name] error initializing", e.stack

        return module
    catch e
        console.error "[module] error initializing '#name':", e.message