/*
 * Lambda.js: String based lambdas for Node.js and the browser.
 * edited by JTBrinkmann to support a slightly more CoffeeScript like syntax
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

window.l = function(expression) {
    vars = []
    expression = expression
        // :: for prototype
        .replace(/([\w$]*)\.?::(\?)?\.?([\w$])?/g,
            lambda("_, pre, nullCoalescingOp, post, i ->"+
                "(pre ? pre+'.' : i == 0 ? '.' : '') + 'prototype' + (nullCoalescingOp||'') + (post ? '.'+post : '')"
        ))
        // @ for this
        .replace(/@(\?)?\.?([\w$])?/g,
            lambda("_, nullCoalescingOp, post, i ->"+
                "'this' + (nullCoalescingOp||'') + (post ? '.'+post : '')"
        ))
        // ?. for Null Coalescing Operator
        .replace(/([\w$\.]+)\?([\w$\.]+|\[.*?\])/g, lambda("_, pre, post ->"+
                "vars=['ref$'], '((ref$ = '+(pre[0]=='.'?'$1':'')+pre+') != null && ref$'+post+')'"
        ))
    return lambda(expression, vars)
}
/*
    // ~> bound functions
    // "String #Interpolation"
    lvl = []; l = -1
    boundLvls = []; lb = -1
    bound = false; hasBound = false
    expression = expression
        // (preventBS is to prevent escaped opening/closing brackets/quotes from being treated as regular ones)
        // QS = quotes
        //        <    pre  preventBS   >  (< opening><quotes>         <closing >)
        .replace(/((?:[^\\]|(?:\\\\)+)*?)(?:([\(\{\[])|(["'])|(#)|(~>)|([\]\}\)]))/g, function(_, pre, opening, quotes, numberSign, wavyArrow, closing, i) {
            //                       for interpolated strings-<^> < ^>-for bound functions
            //TODO compile from LiveScript to JavaScript
            //TODO add ~> bound functions to this madness
            if lvl[l] == \# and opening != \{
                #ToDo interpolate within pre
                lvl.pop!

            switch true
            | quotes =>
                switch lvl[l]
                | quotes => # leave string
                    lvl.pop!
                | "'", '"' => # ignore (we are inside a string)
                    void # ignore
                | otherwise => # enter string
                    lvl[++l] = quotes
            | true =>
                if bound
                    pre.replace(/\bthis\b/g, 'this$') #ToDo check if this is accurate (what about e.g. ```{this: "fun"}```?)
                fallthrough
            | numberSign =>
                if lvl[l] == '"'
                    lvl[++l] = '#'
            | opening =>
                lvl[++l] = opening
            | closing =>
                if lvl[l] == closing
                    #if closing == \} and lvl[l] == \#
                        #ToDo interpolate within pre
                    if boundLvls[lb] == l
                        pre += ")"
                    if bound == l # range of bound function ends
                        bound := false
                    lvl.pop!
                else
                    throw new TypeError "unmatched bracket '#closing' at #i"
            | wavyArrow =>
                hasBound := true
                opening = "(var this$=this, ->"
                boundLvls[++lb] = l
                bound := l if bound == false
            return _
        })
    if (hasBound) vars.push("this$")
*/
