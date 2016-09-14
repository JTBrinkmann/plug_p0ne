/*@author jtbrinkmann aka. Brinkie Pie */
/*@license https://creativecommons.org/licenses/by-nc/4.0/ */
window.module = (name, data) -> # data = {name, require, optional, callback, callbacks, setup, update, dontOverride, enable, disable, module}
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
        data.dontOverride ||= {}
        {name, require, optional, callback, callbacks, setup, update, dontOverride, enable, disable, module} = data
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


        module.displayName = name
        dataName = name
            .replace(/^[A-Z]/, (.toLowerCase!))
            .replace(/^[^a-z]/,"_$&")
            .replace(/(\w)?\W+(\w)?/g, (,a,b) -> return "#{a||''}#{(b||'').toUpperCase!}")
        cbs = module._cbs =
            listeners: []
            _$context: []
            replacements: []
            adds: []

        arrEqual = (a, b) ->
            return false if not a or not b or a.length != b.length
            for ,i in a
                return false if a[i] != b[i]
            return true
        objEqual = (a, b) ->
            return true if a == b
            return false if !a or !b or not arrEqual Object.keys(a), Object.keys(b)
            for k of a
                return false if a[k] != b[k]
            return true
        onOff = (fn, d) ->
            if d.length
                [target, event, ...args, callback] = d
            else
                {target, event, args, callback} = d
            if args
                target[fn].apply target, [event] ++ args ++ [callback]
            else
                target[fn] event, callback
            return callback

        helperFNs =
            addListener: ({target, event, bound, args, callback}:d) ->
                cbs.listeners[*] = d
                callback = module[callback] if typeof callback == \string
                if not typeof callback == \function
                    console.error "[#name] can't add listener", callback, "for '#event' on", target, " (callback must be a function)"
                if bound
                    d = ^^d
                    d.callback = callback.bound or (callback.bound = callback .bind module)
                return onOff \on, d
            removeListener: ({/*target, args,*/ event, bound, callback:cbName}:d) ->
                d.callback = cbName.bound if typeof cbName == \function and bound
                for listener, i in cbs.listeners when objEqual d, listener
                    cbs.listeners .remove i
                    return onOff \off, arguments
                if typeof cbName == \string
                    d.callback = module[cbName]
                    return removeListener d
                console.error "[#name] couldn't remove listener '#cbName' for '#{event}' from", d.target, "(not found)"
                return false

            replace: (target, attr, repl) ->
                cbs.replacements[*] = [target, attr, repl]
                target["#{attr}_"] ||= target[attr]
                repl = module[repl] if typeof repl == \string and module[repl]
                if typeof repl == \function
                    target[attr] = repl(target["#{attr}_"])
                else
                    target[attr] = repl
            replace_$Listener: ->
                cbs._$context[*] = window.replace_$Listener ...

            add: (target, callback, options) ->
                d = [target, callback, options]
                callback .= bind module if options?.bound
                d.index = target.length # not part of the Array, so arrEqual ignores it
                target[d.index] = callback
                cbs.adds[*] = d
            remove: (target, callback, {bound}) ->
                # note: when adding the same callback to the same target multiple times,
                # remove() will always remove the first one in the target
                callback .= bind module if bound
                for d, i in cbs.adds when arrEqual d, arguments
                    target .remove d.index if d.index != -1
                    cbs.adds .remove i
                    return true
                console.error "[#name] can't find callback '#callback' in", target

            disable: ->
                return console.warn "[#name] already disabled" if module.disabled
                module.disabled = true
                disable?.call module, helperFNs, module, data
                for d in cbs.listeners
                    onOff \off, d
                for listener in cbs._$context
                    listener.disable!
                for [target, attr /*, repl*/] in cbs.replacements
                    target[attr] = target["#{attr}_"]
                for [target /*, callback, options*/]:d in cbs.adds
                    target .remove d.index
                    d.index = -1
                console.info "[#name] disabled"
            enable: ->
                return console.warn "[#name] already enabled" if not module.disabled
                module.disabled = false
                enable?.call module, helperFNs, module, data
                for d in cbs.listeners
                    if bound
                        d.callback = callback.bound or (callback.bound = callback .bind module)
                    onOff \on, d
                for listener in cbs._$context
                    listener.enable!
                for [target, attr, repl] in cbs.replacements
                    target[attr] = repl
                for [target, callback, options].d in cbs.adds
                    d.index = target.length
                    callback = module[callback]
                    callback .= bind module if options?.bound
                    target[d.index] = callback
                console.info "[#name] enabled"
            update: (module_) ->
                return if not module_
                cbs = module_._cbs

                # disable old listeners
                i = cbs.listeners.length
                while (d_ = cbs.listeners[--i])
                    if d_.isModuleCallback
                        cbs.listeners .remove i
                        onOff \off, d_
                    else if d_.bound
                        onOff \off, d_
                        d = ^^d_
                        d.callback = d.callback.bound = d.callback .bind module
                        onOff \on, d

                # update old listeners
                # update new listeners
                for cbName, {callback}:d of callbacks
                    d.isModuleCallback = true
                    d.callback = module[callback] if typeof callback == \string
                    helperFNs.addListener d

                # update cbs.adds
                for [target, obj, options]:d, i in cbs.adds
                    obj .= bind module if options?.bound
                    target[d.index] = obj if d.index != -1


                # update module
                window[dataName] = module
                for k of module_ when not module[k] and not dontOverride[k]
                    module[k] = module_[k]

        module.disable = helperFNs.disable
        module.enable = helperFNs.enable
        if not window[dataName]
            failedRequirements = [r for r in require||[] when !r or (typeof r == \string and not window[r])]
            if failedRequirements.length
                console.error "[#name] didn't initialize (#{humanList failedRequirements} #{if failedRequirements.length > 1 then 'are' else 'is'} required)"
                return module
            optionalRequirements = [r for r in optional||[] when !r or (typeof r == \string and not window[r])]
            if optionalRequirements.length
                console.warn "[#name] couldn't load optional requirement#{optionalRequirements.length>1 && 's' || ''}: #{humanList optionalRequirements}. This module may only run with limited functionality"
            module.disabled = false
            try
                window[dataName] = module
                for cbName, d of callbacks
                    d.isModuleCallback = true
                    helperFNs.addListener d
                setup?.call module, helperFNs, module, data
                console.info "[#name] initialized"
            catch e
                console.error "[#name] error initializing", e.stack
        else # if module is already initialized => update it
            module_ = window[dataName]
            helperFNs.update module_
            update?.call module, helperFNs, module, data, module_

            console.info "[#name] updated"
        return module
    catch e
        console.error "[module] error initializing/updating '#name':", e.message
