/*
 * Lambda.js: String based lambdas for Node.js and the browser.
 * edited by JTBrinkmann to support some CoffeeScript like shorthands (e.g. :: for prototype)
 *
 * Copyright (c) 2007 Oliver Steele (steele@osteele.com)
 * Released under MIT license.
 *
 * Version: 1.0.2
 *
 */
(function (root, factory) {
    if (typeof exports === 'object') {
        module.exports = factory();
    } else {
        root.lambda = factory();
    }
})(this, function () {

    var
        split = 'ab'.split(/a*/).length > 1 ? String.prototype.split : function (separator) {
                var result = this.split.apply(this, arguments),
                    re = RegExp(separator),
                    savedIndex = re.lastIndex,
                    match = re.exec(this);
                if (match && match.index === 0) {
                    result.unshift('');
                }
                re.lastIndex = savedIndex;
                return result;
            },
        indexOf = Array.prototype.indexOf || function (element) {
                for (var i = 0, e; e = this[i]; i++) {
                    if (e === element) {
                        return i;
                    }
                }
                return -1;
            };

    function lambda(expression, vars) {
        if (!vars || !vars.length)
            vars = []
        expression = expression.replace(/^\s+/, '').replace(/\s+$/, '') // jtb edit
        var parameters = [],
            sections = split.call(expression, /\s*->\s*/m);
        if (sections.length > 1) {
            while (sections.length) {
                expression = sections.pop();
                parameters = sections.pop().replace(/^\s*(.*)\s*$/, '$1').split(/\s*,\s*|\s+/m);
                sections.length && sections.push('(function('+parameters+'){return ('+expression+')})');
            }
        } else if (expression.match(/\b_\b/)) {
            parameters = '_';
        } else {
            var leftSection = expression.match(/^(?:[+*\/%&|\^\.=<>]|!=|::)/m),
                rightSection = expression.match(/[+\-*\/%&|\^\.=<>!]$/m);
            if (leftSection || rightSection) {
                if (leftSection) {
                    parameters.push('$1');
                    expression = '$1' + expression;
                }
                if (rightSection) {
                    parameters.push('$2');
                    if (rightSection[0] == '.')
                        expression = expression.substr(0, expression.length-1) + '[$2]' // jtb edit
                    else
                        expression = expression + '$2';
                }
            } else {
                var variables = expression
                    .replace(/(?:\b[A-Z]|\.[a-zA-Z_$])[a-zA-Z_$\d]*|[a-zA-Z_$][a-zA-Z_$\d]*\s*:|true|false|null|undefined|this|arguments|'(?:[^'\\]|\\.)*'|"(?:[^"\\]|\\.)*"/g, '')
                    .match(/([a-z_$][a-z_$\d]*)/gi) || [];
                for (var i = 0, v; v = variables[i++];) {
                    if (parameters.indexOf(v) == -1 && vars.indexOf(v) == -1)
                        parameters.push(v);
                }
            }
        }
        if (vars.length)
            vars = 'var '+vars.join(',')+'; '
        else
            vars = ''

        try {
            return new Function(parameters, vars+'return (' + expression + ')');
        } catch(e) {
            e.message += ' in function('+parameters+'){'+vars+'return (' + expression + ')}'
            throw e
        }
    }

    return lambda;
});

window.l = window.l_ = function(expression) {
    var vars = [], refs = 0
    var replacedNCO = true
    expression = expression
        // :: for prototype
        .replace(/([\w$]*)\.?::(\?)?\.?([\w$])?/g, function(_, pre, nullCoalescingOp, post, i) {
            return (pre ? pre+'.' : i == 0 ? '.' : '') + 'prototype' + (nullCoalescingOp||'') + (post ? '.'+post : '')
        })
        // @ for this
        .replace(/@(\?)?\.?([\w$])?/g, function(_, nullCoalescingOp, post, i) {
            return 'this' + (nullCoalescingOp||'') + (post ? '.'+post : '')
        })
    // ?. for Null Coalescing Operator
    while (replacedNCO) {
        replacedNCO = false
        expression = expression.replace(/([\w\.\$]+)\?([\w\.\$]|\[)/, function(_, pre, post) {
            replacedNCO = true
            vars[refs++] = 'ref'+refs+'$'
            return '(ref'+refs+'$ = '+(pre[0]=='.'?'it':'')+pre+') != null && ref'+refs+'$'+(post[0]=="."||post[0]=="[" ? "" : ".")+post
        })
    }
    return lambda(expression, vars)
}
