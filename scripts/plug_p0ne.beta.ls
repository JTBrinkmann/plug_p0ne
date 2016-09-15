/*=====================*\
|* plug_p0ne.beta      *|
\*=====================*/

/*@source p0ne.head.ls */
/**
 * plug_p0ne - a modern script collection to improve plug.dj
 * adds a variety of new functions, bugfixes, tweaks and developer tools/functions
 *
 * This script collection is written in LiveScript (a CoffeeScript descendend which compiles to JavaScript). If you are reading this in JavaScript, you might want to check out the LiveScript file instead for a better documented and formatted source; just replace the .js with .ls in the URL of this file
 *
 * @author jtbrinkmann aka. Brinkie Pie
 * @license MIT License
 * @copyright (c) 2015 J.-T. Brinkmann
 *
 * further credits go to
 *     the plugCubed Team - for coining a standard for the "Custom Room Settings"
 *     Christian Petersen - for the toggle boxes in the settings menu http://codepen.io/cbp/pen/FLdjI/
 *     all the beta testers! <3
 *     plug.dj - for it's horribly broken implementation of everything.
 *               "If it wasn't THAT broken, I wouldn't have had as much fun in coding plug_p0ne"
 *                   --Brinkie Pie (2015)
 *
 * The following 3rd party scripts are used:
 *     - pieroxy's lz-string https://github.com/pieroxy/lz-string (DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE)
 *     - Mozilla's localforage.min.js https://github.com/mozilla/localforage (Apache License v2.0)
 *     - Stefan Petre's Color Picker http://www.eyecon.ro/colorpicker/ (Dual licensed under the MIT and GPL licenses)
 * The following are not used by plug_p0ne, but provided for usage in the console, for easier debugging
 *     - Oliver Steele's lambda.js https://github.com/fschaefer/Lambda.js (MIT License)
 *
 * Not happy with plug_p0ne? contact me (the developer) at brinkiepie@gmail.com
 * great alternative plug.dj scripts are
 *     - TastyPlug (relatively lightweight but does a good job - https://fungustime.pw/tastyplug/ )
 *     - RCS (best alternative I could recommend - https://radiant.dj/rcs )
 *     - plugCubed (does a lot of things, but breaks on plug.dj updates - https://plugcubed.net/ )
 *     - plugplug (lightweight as heck - https://bitbucket.org/mateon1/plugplug/ )
 */

console.info "~~~~~~~~~~~~ plug_p0ne loading ~~~~~~~~~~~~"
console.time? "[p0ne] completly loaded"
p0ne_ = window.p0ne
window.p0ne =
    #== Constants ==
    version: \1.8.0
    lastCompatibleVersion: \1.8.0 /* see below */
    host: 'https://cdn.p0ne.com'
    SOUNDCLOUD_KEY: \aff458e0e87cfbc1a2cde2f8aeb98759
    YOUTUBE_V3_KEY: \AIzaSyDaWL9emnR9R_qBWlDAYl-Z_h4ZPYBDjzk
    FIMSTATS_KEY: \4983a7f2-b253-4300-8b18-6e7c57db5e2e

    # for cross site requests
    proxy: (url) !-> return "https://cors-anywhere.herokuapp.com/#{url .replace /^.*\/\//, ''}"
    #proxy: (url) !-> return "https://jsonp.nodejitsu.com/?raw=true&url=#{escape url}"
    #https://blog.5apps.com/2013/03/02/new-service-cors-ssl-proxy.html

    started: new Date()
    autosave: {}
    autosave_num: {}
    modules: p0ne?.modules || {}
    dependencies: {}
    reload: !->
        return $.getScript "#{@host}/scripts/plug_p0ne.beta.js"
    close: !->
        console.groupCollapsed "[p0ne] closing"
        for ,m of @modules
            m.settingsSave?!
            m.disable(true)
        if typeof window.dataSave == \function
            window.dataSave!
            $window .off \beforeunload, window.dataSave
            clearInterval window.dataSave.interval
        console.groupEnd "[p0ne] closing"
console.info "plug_p0ne v#{p0ne.version}"

try
    window.dataSave?! /* save data of previous p0ne instances */


/*####################################
#           COMPATIBILITY            #
####################################*/
/* check if last run p0ne version is incompatible with current and needs to be migrated */
window.compareVersions = (a, b) !-> /* returns whether `a` is greater-or-equal to `b`; e.g. "1.2.0" is greater than "1.1.4.9" */
    a .= split \.
    b .= split \.
    for ,i in a when a[i] != b[i]
        return a[i] > b[i]
    return b.length >= a.length


<-      (fn_) !->
    if window.P0NE_UPDATE
        window.P0NE_UPDATE = false
        if p0ne_?.version == window.p0ne.version
            return
        else
            chatWarn? "automatically updated to v#{p0ne.version}", 'plug_p0ne'

    if not console.group
        console.group = console.log
        console.groupEnd = $.noop
    fn = !->
        #== fix LocalForage ==
        # In Firefox' private mode, indexedDB will fail, and thus localforage will also fail silently
        # See https://github.com/mozilla/localForage/issues/195
        # To fix this, we test if indexedDB works and fall back to localStorage if not.
        # In my test this took ~30ms on Google Chrome and ~250ms on Firefox (working) and ~2ms on Firefox in private mode (failing);
        # once the database is created, it took ~1ms on Google Chrome and ~5ms on Firefox (working) on successive tries (after page reloads)
        try
            if (window.indexedDB || window.webkitIndexedDB || window.mozIndexedDB || window.OIndexedDB || window.msIndexedDB)
                that .open \_localforage_spec_test, 1
                    ..onsuccess = !->
                        fn_!
                    ..onerror = ..onblocked = ..onupgradeneededd = (err) !->
                        # fall back to localStorage
                        delete! [window.indexedDB, window.webkitIndexedDB, window.mozIndexedDB, window.OIndexedDB, window.msIndexedDB]
                        console.error "[p0ne] indexDB doesn't work, falling back to localStorage", err
                        fn_!
            else
                fn_!
        catch err
            # change to localStorage
            console.error "[p0ne] indexDB doesn't work, falling back to localStorage", err
            delete! [window.indexedDB, window.webkitIndexedDB, window.mozIndexedDB, window.OIndexedDB, window.msIndexedDB]
            fn_!

    if not (v = localStorage.p0neVersion)
        # no previous version of p0ne found, looks like we're good to go
        return fn!

    if compareVersions(v, p0ne.lastCompatibleVersion)
        # no migration required, continue
        fn!
    else
        # incompatible, load migration script and continue when it's done
        console.warn "[p0ne] obsolete p0ne version detected (#v < #{p0ne.lastCompatibleVersion}), loading migration script…"
        API.off \p0ne_migrated
        API.once \p0ne_migrated, onMigrated = (newVersion) !->
            if newVersion == p0ne.lastCompatibleVersion
                fn!
            else
                API.once \p0ne_migrated, onMigrated # did you mean "recursion"?
        $.getScript "#{p0ne.host}/scripts/plug_p0ne.migrate.#{v.substr(0,v.indexOf(\.))}.js?from=#v&to=#{p0ne.version}"

/* start of fn_ */
/* if needed, this function is called once plug_p0ne successfully migrated. Otherwise it gets called right away */
errors = warnings = 0
error_ = console.error; console.error = !-> errors++; error_ ...
warn_ = console.warn; console.warn = !-> warnings++; warn_ ...

if console.groupCollapsed
    console.groupCollapsed "[p0ne] initializing… (click on this message to expand/collapse the group)"
else
    console.groupCollapsed = console.group
    console.group "[p0ne] initializing…"

p0ne = window.p0ne # so that modules always refer to their initial `p0ne` object, unless explicitly referring to `window.p0ne`
localStorage.p0neVersion = p0ne.version

#== Auto-Update ==
# check for a new version every 30min
/*setInterval do
    !->
        window.P0NE_UPDATE = true
        p0ne.reload!
            .then !->
                setTimeout do
                    !-> window.P0NE_UPDATE = false
                    10_000ms
    30 * 60_000ms*/

#== fix problems with requireJS ==
requirejs.define = window.define
window.require = window.define = window.module = false

/*@source lambda.js */
``
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

``


/*@source lz-string.js */
``
// Copyright (c) 2013 Pieroxy <pieroxy@pieroxy.net>
// This work is free. You can redistribute it and/or modify it
// under the terms of the WTFPL, Version 2
// For more information see LICENSE.txt or http://www.wtfpl.net/
//
// For more information, the home page:
// http://pieroxy.net/blog/pages/lz-string/testing.html
//
// LZ-based compression algorithm, version 1.3.6
var LZString = {
  
  
  // private property
  _keyStr : "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=",
  _f : String.fromCharCode,
  
  compressToBase64 : function (input) {
    if (input == null) return "";
    var output = "";
    var chr1, chr2, chr3, enc1, enc2, enc3, enc4;
    var i = 0;
    
    input = LZString.compress(input);
    
    while (i < input.length*2) {
      
      if (i%2==0) {
        chr1 = input.charCodeAt(i/2) >> 8;
        chr2 = input.charCodeAt(i/2) & 255;
        if (i/2+1 < input.length) 
          chr3 = input.charCodeAt(i/2+1) >> 8;
        else 
          chr3 = NaN;
      } else {
        chr1 = input.charCodeAt((i-1)/2) & 255;
        if ((i+1)/2 < input.length) {
          chr2 = input.charCodeAt((i+1)/2) >> 8;
          chr3 = input.charCodeAt((i+1)/2) & 255;
        } else 
          chr2=chr3=NaN;
      }
      i+=3;
      
      enc1 = chr1 >> 2;
      enc2 = ((chr1 & 3) << 4) | (chr2 >> 4);
      enc3 = ((chr2 & 15) << 2) | (chr3 >> 6);
      enc4 = chr3 & 63;
      
      if (isNaN(chr2)) {
        enc3 = enc4 = 64;
      } else if (isNaN(chr3)) {
        enc4 = 64;
      }
      
      output = output +
        LZString._keyStr.charAt(enc1) + LZString._keyStr.charAt(enc2) +
          LZString._keyStr.charAt(enc3) + LZString._keyStr.charAt(enc4);
      
    }
    
    return output;
  },
  
  decompressFromBase64 : function (input) {
    if (input == null) return "";
    var output = "",
        ol = 0, 
        output_,
        chr1, chr2, chr3,
        enc1, enc2, enc3, enc4,
        i = 0, f=LZString._f;
    
    input = input.replace(/[^A-Za-z0-9\+\/\=]/g, "");
    
    while (i < input.length) {
      
      enc1 = LZString._keyStr.indexOf(input.charAt(i++));
      enc2 = LZString._keyStr.indexOf(input.charAt(i++));
      enc3 = LZString._keyStr.indexOf(input.charAt(i++));
      enc4 = LZString._keyStr.indexOf(input.charAt(i++));
      
      chr1 = (enc1 << 2) | (enc2 >> 4);
      chr2 = ((enc2 & 15) << 4) | (enc3 >> 2);
      chr3 = ((enc3 & 3) << 6) | enc4;
      
      if (ol%2==0) {
        output_ = chr1 << 8;
        
        if (enc3 != 64) {
          output += f(output_ | chr2);
        }
        if (enc4 != 64) {
          output_ = chr3 << 8;
        }
      } else {
        output = output + f(output_ | chr1);
        
        if (enc3 != 64) {
          output_ = chr2 << 8;
        }
        if (enc4 != 64) {
          output += f(output_ | chr3);
        }
      }
      ol+=3;
    }
    
    return LZString.decompress(output);
    
  },

  compressToUTF16 : function (input) {
    if (input == null) return "";
    var output = "",
        i,c,
        current,
        status = 0,
        f = LZString._f;
    
    input = LZString.compress(input);
    
    for (i=0 ; i<input.length ; i++) {
      c = input.charCodeAt(i);
      switch (status++) {
        case 0:
          output += f((c >> 1)+32);
          current = (c & 1) << 14;
          break;
        case 1:
          output += f((current + (c >> 2))+32);
          current = (c & 3) << 13;
          break;
        case 2:
          output += f((current + (c >> 3))+32);
          current = (c & 7) << 12;
          break;
        case 3:
          output += f((current + (c >> 4))+32);
          current = (c & 15) << 11;
          break;
        case 4:
          output += f((current + (c >> 5))+32);
          current = (c & 31) << 10;
          break;
        case 5:
          output += f((current + (c >> 6))+32);
          current = (c & 63) << 9;
          break;
        case 6:
          output += f((current + (c >> 7))+32);
          current = (c & 127) << 8;
          break;
        case 7:
          output += f((current + (c >> 8))+32);
          current = (c & 255) << 7;
          break;
        case 8:
          output += f((current + (c >> 9))+32);
          current = (c & 511) << 6;
          break;
        case 9:
          output += f((current + (c >> 10))+32);
          current = (c & 1023) << 5;
          break;
        case 10:
          output += f((current + (c >> 11))+32);
          current = (c & 2047) << 4;
          break;
        case 11:
          output += f((current + (c >> 12))+32);
          current = (c & 4095) << 3;
          break;
        case 12:
          output += f((current + (c >> 13))+32);
          current = (c & 8191) << 2;
          break;
        case 13:
          output += f((current + (c >> 14))+32);
          current = (c & 16383) << 1;
          break;
        case 14:
          output += f((current + (c >> 15))+32, (c & 32767)+32);
          status = 0;
          break;
      }
    }
    
    return output + f(current + 32);
  },
  

  decompressFromUTF16 : function (input) {
    if (input == null) return "";
    var output = "",
        current,c,
        status=0,
        i = 0,
        f = LZString._f;
    
    while (i < input.length) {
      c = input.charCodeAt(i) - 32;
      
      switch (status++) {
        case 0:
          current = c << 1;
          break;
        case 1:
          output += f(current | (c >> 14));
          current = (c&16383) << 2;
          break;
        case 2:
          output += f(current | (c >> 13));
          current = (c&8191) << 3;
          break;
        case 3:
          output += f(current | (c >> 12));
          current = (c&4095) << 4;
          break;
        case 4:
          output += f(current | (c >> 11));
          current = (c&2047) << 5;
          break;
        case 5:
          output += f(current | (c >> 10));
          current = (c&1023) << 6;
          break;
        case 6:
          output += f(current | (c >> 9));
          current = (c&511) << 7;
          break;
        case 7:
          output += f(current | (c >> 8));
          current = (c&255) << 8;
          break;
        case 8:
          output += f(current | (c >> 7));
          current = (c&127) << 9;
          break;
        case 9:
          output += f(current | (c >> 6));
          current = (c&63) << 10;
          break;
        case 10:
          output += f(current | (c >> 5));
          current = (c&31) << 11;
          break;
        case 11:
          output += f(current | (c >> 4));
          current = (c&15) << 12;
          break;
        case 12:
          output += f(current | (c >> 3));
          current = (c&7) << 13;
          break;
        case 13:
          output += f(current | (c >> 2));
          current = (c&3) << 14;
          break;
        case 14:
          output += f(current | (c >> 1));
          current = (c&1) << 15;
          break;
        case 15:
          output += f(current | c);
          status=0;
          break;
      }
      
      
      i++;
    }
    
    return LZString.decompress(output);
    //return output;
    
  },


  //compress into uint8array (UCS-2 big endian format)
  compressToUint8Array: function (uncompressed) {

    var compressed = LZString.compress(uncompressed);
    var buf=new Uint8Array(compressed.length*2); // 2 bytes per character

    for (var i=0, TotalLen=compressed.length; i<TotalLen; i++) {
      var current_value = compressed.charCodeAt(i);
      buf[i*2] = current_value >>> 8;
      buf[i*2+1] = current_value % 256;
    }
    return buf;

  },

  //decompress from uint8array (UCS-2 big endian format)
  decompressFromUint8Array:function (compressed) {

    if (compressed===null || compressed===undefined){
        return LZString.decompress(compressed);
    } else {

        var buf=new Array(compressed.length/2); // 2 bytes per character

        for (var i=0, TotalLen=buf.length; i<TotalLen; i++) {
          buf[i]=compressed[i*2]*256+compressed[i*2+1];
        }

        return LZString.decompress(String.fromCharCode.apply(null, buf));

    }

  },

  //compress into a string that is already URI encoded
  compressToEncodedURIComponent: function (uncompressed) {
    return LZString.compressToBase64(uncompressed).replace(/=/g,"$").replace(/\//g,"-");
  },

  //decompress from an output of compressToEncodedURIComponent
  decompressFromEncodedURIComponent:function (compressed) {
    if (compressed) compressed = compressed.replace(/$/g,"=").replace(/-/g,"/");
    return LZString.decompressFromBase64(compressed);
  },


  compress: function (uncompressed) {
    if (uncompressed == null) return "";
    var i, value,
        context_dictionary= {},
        context_dictionaryToCreate= {},
        context_c="",
        context_wc="",
        context_w="",
        context_enlargeIn= 2, // Compensate for the first entry which should not count
        context_dictSize= 3,
        context_numBits= 2,
        context_data_string="", 
        context_data_val=0, 
        context_data_position=0,
        ii,
        f=LZString._f;
    
    for (ii = 0; ii < uncompressed.length; ii += 1) {
      context_c = uncompressed.charAt(ii);
      if (!Object.prototype.hasOwnProperty.call(context_dictionary,context_c)) {
        context_dictionary[context_c] = context_dictSize++;
        context_dictionaryToCreate[context_c] = true;
      }
      
      context_wc = context_w + context_c;
      if (Object.prototype.hasOwnProperty.call(context_dictionary,context_wc)) {
        context_w = context_wc;
      } else {
        if (Object.prototype.hasOwnProperty.call(context_dictionaryToCreate,context_w)) {
          if (context_w.charCodeAt(0)<256) {
            for (i=0 ; i<context_numBits ; i++) {
              context_data_val = (context_data_val << 1);
              if (context_data_position == 15) {
                context_data_position = 0;
                context_data_string += f(context_data_val);
                context_data_val = 0;
              } else {
                context_data_position++;
              }
            }
            value = context_w.charCodeAt(0);
            for (i=0 ; i<8 ; i++) {
              context_data_val = (context_data_val << 1) | (value&1);
              if (context_data_position == 15) {
                context_data_position = 0;
                context_data_string += f(context_data_val);
                context_data_val = 0;
              } else {
                context_data_position++;
              }
              value = value >> 1;
            }
          } else {
            value = 1;
            for (i=0 ; i<context_numBits ; i++) {
              context_data_val = (context_data_val << 1) | value;
              if (context_data_position == 15) {
                context_data_position = 0;
                context_data_string += f(context_data_val);
                context_data_val = 0;
              } else {
                context_data_position++;
              }
              value = 0;
            }
            value = context_w.charCodeAt(0);
            for (i=0 ; i<16 ; i++) {
              context_data_val = (context_data_val << 1) | (value&1);
              if (context_data_position == 15) {
                context_data_position = 0;
                context_data_string += f(context_data_val);
                context_data_val = 0;
              } else {
                context_data_position++;
              }
              value = value >> 1;
            }
          }
          context_enlargeIn--;
          if (context_enlargeIn == 0) {
            context_enlargeIn = Math.pow(2, context_numBits);
            context_numBits++;
          }
          delete context_dictionaryToCreate[context_w];
        } else {
          value = context_dictionary[context_w];
          for (i=0 ; i<context_numBits ; i++) {
            context_data_val = (context_data_val << 1) | (value&1);
            if (context_data_position == 15) {
              context_data_position = 0;
              context_data_string += f(context_data_val);
              context_data_val = 0;
            } else {
              context_data_position++;
            }
            value = value >> 1;
          }
          
          
        }
        context_enlargeIn--;
        if (context_enlargeIn == 0) {
          context_enlargeIn = Math.pow(2, context_numBits);
          context_numBits++;
        }
        // Add wc to the dictionary.
        context_dictionary[context_wc] = context_dictSize++;
        context_w = String(context_c);
      }
    }
    
    // Output the code for w.
    if (context_w !== "") {
      if (Object.prototype.hasOwnProperty.call(context_dictionaryToCreate,context_w)) {
        if (context_w.charCodeAt(0)<256) {
          for (i=0 ; i<context_numBits ; i++) {
            context_data_val = (context_data_val << 1);
            if (context_data_position == 15) {
              context_data_position = 0;
              context_data_string += f(context_data_val);
              context_data_val = 0;
            } else {
              context_data_position++;
            }
          }
          value = context_w.charCodeAt(0);
          for (i=0 ; i<8 ; i++) {
            context_data_val = (context_data_val << 1) | (value&1);
            if (context_data_position == 15) {
              context_data_position = 0;
              context_data_string += f(context_data_val);
              context_data_val = 0;
            } else {
              context_data_position++;
            }
            value = value >> 1;
          }
        } else {
          value = 1;
          for (i=0 ; i<context_numBits ; i++) {
            context_data_val = (context_data_val << 1) | value;
            if (context_data_position == 15) {
              context_data_position = 0;
              context_data_string += f(context_data_val);
              context_data_val = 0;
            } else {
              context_data_position++;
            }
            value = 0;
          }
          value = context_w.charCodeAt(0);
          for (i=0 ; i<16 ; i++) {
            context_data_val = (context_data_val << 1) | (value&1);
            if (context_data_position == 15) {
              context_data_position = 0;
              context_data_string += f(context_data_val);
              context_data_val = 0;
            } else {
              context_data_position++;
            }
            value = value >> 1;
          }
        }
        context_enlargeIn--;
        if (context_enlargeIn == 0) {
          context_enlargeIn = Math.pow(2, context_numBits);
          context_numBits++;
        }
        delete context_dictionaryToCreate[context_w];
      } else {
        value = context_dictionary[context_w];
        for (i=0 ; i<context_numBits ; i++) {
          context_data_val = (context_data_val << 1) | (value&1);
          if (context_data_position == 15) {
            context_data_position = 0;
            context_data_string += f(context_data_val);
            context_data_val = 0;
          } else {
            context_data_position++;
          }
          value = value >> 1;
        }
        
        
      }
      context_enlargeIn--;
      if (context_enlargeIn == 0) {
        context_enlargeIn = Math.pow(2, context_numBits);
        context_numBits++;
      }
    }
    
    // Mark the end of the stream
    value = 2;
    for (i=0 ; i<context_numBits ; i++) {
      context_data_val = (context_data_val << 1) | (value&1);
      if (context_data_position == 15) {
        context_data_position = 0;
        context_data_string += f(context_data_val);
        context_data_val = 0;
      } else {
        context_data_position++;
      }
      value = value >> 1;
    }
    
    // Flush the last char
    while (true) {
      context_data_val = (context_data_val << 1);
      if (context_data_position == 15) {
        context_data_string += f(context_data_val);
        break;
      }
      else context_data_position++;
    }
    return context_data_string;
  },
  
  decompress: function (compressed) {
    if (compressed == null) return "";
    if (compressed == "") return null;
    var dictionary = [],
        next,
        enlargeIn = 4,
        dictSize = 4,
        numBits = 3,
        entry = "",
        result = "",
        i,
        w,
        bits, resb, maxpower, power,
        c,
        f = LZString._f,
        data = {string:compressed, val:compressed.charCodeAt(0), position:32768, index:1};
    
    for (i = 0; i < 3; i += 1) {
      dictionary[i] = i;
    }
    
    bits = 0;
    maxpower = Math.pow(2,2);
    power=1;
    while (power!=maxpower) {
      resb = data.val & data.position;
      data.position >>= 1;
      if (data.position == 0) {
        data.position = 32768;
        data.val = data.string.charCodeAt(data.index++);
      }
      bits |= (resb>0 ? 1 : 0) * power;
      power <<= 1;
    }
    
    switch (next = bits) {
      case 0: 
          bits = 0;
          maxpower = Math.pow(2,8);
          power=1;
          while (power!=maxpower) {
            resb = data.val & data.position;
            data.position >>= 1;
            if (data.position == 0) {
              data.position = 32768;
              data.val = data.string.charCodeAt(data.index++);
            }
            bits |= (resb>0 ? 1 : 0) * power;
            power <<= 1;
          }
        c = f(bits);
        break;
      case 1: 
          bits = 0;
          maxpower = Math.pow(2,16);
          power=1;
          while (power!=maxpower) {
            resb = data.val & data.position;
            data.position >>= 1;
            if (data.position == 0) {
              data.position = 32768;
              data.val = data.string.charCodeAt(data.index++);
            }
            bits |= (resb>0 ? 1 : 0) * power;
            power <<= 1;
          }
        c = f(bits);
        break;
      case 2: 
        return "";
    }
    dictionary[3] = c;
    w = result = c;
    while (true) {
      if (data.index > data.string.length) {
        return "";
      }
      
      bits = 0;
      maxpower = Math.pow(2,numBits);
      power=1;
      while (power!=maxpower) {
        resb = data.val & data.position;
        data.position >>= 1;
        if (data.position == 0) {
          data.position = 32768;
          data.val = data.string.charCodeAt(data.index++);
        }
        bits |= (resb>0 ? 1 : 0) * power;
        power <<= 1;
      }

      switch (c = bits) {
        case 0: 
          bits = 0;
          maxpower = Math.pow(2,8);
          power=1;
          while (power!=maxpower) {
            resb = data.val & data.position;
            data.position >>= 1;
            if (data.position == 0) {
              data.position = 32768;
              data.val = data.string.charCodeAt(data.index++);
            }
            bits |= (resb>0 ? 1 : 0) * power;
            power <<= 1;
          }

          dictionary[dictSize++] = f(bits);
          c = dictSize-1;
          enlargeIn--;
          break;
        case 1: 
          bits = 0;
          maxpower = Math.pow(2,16);
          power=1;
          while (power!=maxpower) {
            resb = data.val & data.position;
            data.position >>= 1;
            if (data.position == 0) {
              data.position = 32768;
              data.val = data.string.charCodeAt(data.index++);
            }
            bits |= (resb>0 ? 1 : 0) * power;
            power <<= 1;
          }
          dictionary[dictSize++] = f(bits);
          c = dictSize-1;
          enlargeIn--;
          break;
        case 2: 
          return result;
      }
      
      if (enlargeIn == 0) {
        enlargeIn = Math.pow(2, numBits);
        numBits++;
      }
      
      if (dictionary[c]) {
        entry = dictionary[c];
      } else {
        if (c === dictSize) {
          entry = w + w.charAt(0);
        } else {
          return null;
        }
      }
      result += entry;
      
      // Add w+entry[0] to the dictionary.
      dictionary[dictSize++] = w + entry.charAt(0);
      enlargeIn--;
      
      w = entry;
      
      if (enlargeIn == 0) {
        enlargeIn = Math.pow(2, numBits);
        numBits++;
      }
      
    }
  }
};

if( typeof module !== 'undefined' && module != null ) {
  module.exports = LZString
}
``


/*@source localforage.min.js */
``
!function(){var a,b,c,d;!function(){var e={},f={};a=function(a,b,c){e[a]={deps:b,callback:c}},d=c=b=function(a){function c(b){if("."!==b.charAt(0))return b;for(var c=b.split("/"),d=a.split("/").slice(0,-1),e=0,f=c.length;f>e;e++){var g=c[e];if(".."===g)d.pop();else{if("."===g)continue;d.push(g)}}return d.join("/")}if(d._eak_seen=e,f[a])return f[a];if(f[a]={},!e[a])throw new Error("Could not find module "+a);for(var g,h=e[a],i=h.deps,j=h.callback,k=[],l=0,m=i.length;m>l;l++)k.push("exports"===i[l]?g={}:b(c(i[l])));var n=j.apply(this,k);return f[a]=g||n}}(),a("promise/all",["./utils","exports"],function(a,b){"use strict";function c(a){var b=this;if(!d(a))throw new TypeError("You must pass an array to all.");return new b(function(b,c){function d(a){return function(b){f(a,b)}}function f(a,c){h[a]=c,0===--i&&b(h)}var g,h=[],i=a.length;0===i&&b([]);for(var j=0;j<a.length;j++)g=a[j],g&&e(g.then)?g.then(d(j),c):f(j,g)})}var d=a.isArray,e=a.isFunction;b.all=c}),a("promise/asap",["exports"],function(a){"use strict";function b(){return function(){process.nextTick(e)}}function c(){var a=0,b=new i(e),c=document.createTextNode("");return b.observe(c,{characterData:!0}),function(){c.data=a=++a%2}}function d(){return function(){j.setTimeout(e,1)}}function e(){for(var a=0;a<k.length;a++){var b=k[a],c=b[0],d=b[1];c(d)}k=[]}function f(a,b){var c=k.push([a,b]);1===c&&g()}var g,h="undefined"!=typeof window?window:{},i=h.MutationObserver||h.WebKitMutationObserver,j="undefined"!=typeof global?global:void 0===this?window:this,k=[];g="undefined"!=typeof process&&"[object process]"==={}.toString.call(process)?b():i?c():d(),a.asap=f}),a("promise/config",["exports"],function(a){"use strict";function b(a,b){return 2!==arguments.length?c[a]:void(c[a]=b)}var c={instrument:!1};a.config=c,a.configure=b}),a("promise/polyfill",["./promise","./utils","exports"],function(a,b,c){"use strict";function d(){var a;a="undefined"!=typeof global?global:"undefined"!=typeof window&&window.document?window:self;var b="Promise"in a&&"resolve"in a.Promise&&"reject"in a.Promise&&"all"in a.Promise&&"race"in a.Promise&&function(){var b;return new a.Promise(function(a){b=a}),f(b)}();b||(a.Promise=e)}var e=a.Promise,f=b.isFunction;c.polyfill=d}),a("promise/promise",["./config","./utils","./all","./race","./resolve","./reject","./asap","exports"],function(a,b,c,d,e,f,g,h){"use strict";function i(a){if(!v(a))throw new TypeError("You must pass a resolver function as the first argument to the promise constructor");if(!(this instanceof i))throw new TypeError("Failed to construct 'Promise': Please use the 'new' operator, this object constructor cannot be called as a function.");this._subscribers=[],j(a,this)}function j(a,b){function c(a){o(b,a)}function d(a){q(b,a)}try{a(c,d)}catch(e){d(e)}}function k(a,b,c,d){var e,f,g,h,i=v(c);if(i)try{e=c(d),g=!0}catch(j){h=!0,f=j}else e=d,g=!0;n(b,e)||(i&&g?o(b,e):h?q(b,f):a===D?o(b,e):a===E&&q(b,e))}function l(a,b,c,d){var e=a._subscribers,f=e.length;e[f]=b,e[f+D]=c,e[f+E]=d}function m(a,b){for(var c,d,e=a._subscribers,f=a._detail,g=0;g<e.length;g+=3)c=e[g],d=e[g+b],k(b,c,d,f);a._subscribers=null}function n(a,b){var c,d=null;try{if(a===b)throw new TypeError("A promises callback cannot return that same promise.");if(u(b)&&(d=b.then,v(d)))return d.call(b,function(d){return c?!0:(c=!0,void(b!==d?o(a,d):p(a,d)))},function(b){return c?!0:(c=!0,void q(a,b))}),!0}catch(e){return c?!0:(q(a,e),!0)}return!1}function o(a,b){a===b?p(a,b):n(a,b)||p(a,b)}function p(a,b){a._state===B&&(a._state=C,a._detail=b,t.async(r,a))}function q(a,b){a._state===B&&(a._state=C,a._detail=b,t.async(s,a))}function r(a){m(a,a._state=D)}function s(a){m(a,a._state=E)}var t=a.config,u=(a.configure,b.objectOrFunction),v=b.isFunction,w=(b.now,c.all),x=d.race,y=e.resolve,z=f.reject,A=g.asap;t.async=A;var B=void 0,C=0,D=1,E=2;i.prototype={constructor:i,_state:void 0,_detail:void 0,_subscribers:void 0,then:function(a,b){var c=this,d=new this.constructor(function(){});if(this._state){var e=arguments;t.async(function(){k(c._state,d,e[c._state-1],c._detail)})}else l(this,d,a,b);return d},"catch":function(a){return this.then(null,a)}},i.all=w,i.race=x,i.resolve=y,i.reject=z,h.Promise=i}),a("promise/race",["./utils","exports"],function(a,b){"use strict";function c(a){var b=this;if(!d(a))throw new TypeError("You must pass an array to race.");return new b(function(b,c){for(var d,e=0;e<a.length;e++)d=a[e],d&&"function"==typeof d.then?d.then(b,c):b(d)})}var d=a.isArray;b.race=c}),a("promise/reject",["exports"],function(a){"use strict";function b(a){var b=this;return new b(function(b,c){c(a)})}a.reject=b}),a("promise/resolve",["exports"],function(a){"use strict";function b(a){if(a&&"object"==typeof a&&a.constructor===this)return a;var b=this;return new b(function(b){b(a)})}a.resolve=b}),a("promise/utils",["exports"],function(a){"use strict";function b(a){return c(a)||"object"==typeof a&&null!==a}function c(a){return"function"==typeof a}function d(a){return"[object Array]"===Object.prototype.toString.call(a)}var e=Date.now||function(){return(new Date).getTime()};a.objectOrFunction=b,a.isFunction=c,a.isArray=d,a.now=e}),b("promise/polyfill").polyfill()}(),function(){"use strict";function a(a){var b=this,c={db:null};if(a)for(var d in a)c[d]=a[d];return new m(function(a,d){var e=n.open(c.name,c.version);e.onerror=function(){d(e.error)},e.onupgradeneeded=function(){e.result.createObjectStore(c.storeName)},e.onsuccess=function(){c.db=e.result,b._dbInfo=c,a()}})}function b(a,b){var c=this;"string"!=typeof a&&(window.console.warn(a+" used as a key, but it is not a string."),a=String(a));var d=new m(function(b,d){c.ready().then(function(){var e=c._dbInfo,f=e.db.transaction(e.storeName,"readonly").objectStore(e.storeName),g=f.get(a);g.onsuccess=function(){var a=g.result;void 0===a&&(a=null),b(a)},g.onerror=function(){d(g.error)}})["catch"](d)});return k(d,b),d}function c(a,b){var c=this,d=new m(function(b,d){c.ready().then(function(){var e=c._dbInfo,f=e.db.transaction(e.storeName,"readonly").objectStore(e.storeName),g=f.openCursor();g.onsuccess=function(){var c=g.result;if(c){var d=a(c.value,c.key);void 0!==d?b(d):c["continue"]()}else b()},g.onerror=function(){d(g.error)}})["catch"](d)});return k(d,b),d}function d(a,b,c){var d=this;"string"!=typeof a&&(window.console.warn(a+" used as a key, but it is not a string."),a=String(a));var e=new m(function(c,e){d.ready().then(function(){var f=d._dbInfo,g=f.db.transaction(f.storeName,"readwrite").objectStore(f.storeName);null===b&&(b=void 0);var h=g.put(b,a);h.onsuccess=function(){void 0===b&&(b=null),c(b)},h.onerror=function(){e(h.error)}})["catch"](e)});return k(e,c),e}function e(a,b){var c=this;"string"!=typeof a&&(window.console.warn(a+" used as a key, but it is not a string."),a=String(a));var d=new m(function(b,d){c.ready().then(function(){var e=c._dbInfo,f=e.db.transaction(e.storeName,"readwrite").objectStore(e.storeName),g=f["delete"](a);g.onsuccess=function(){b()},g.onerror=function(){d(g.error)},g.onabort=function(a){var b=a.target.error;"QuotaExceededError"===b&&d(b)}})["catch"](d)});return k(d,b),d}function f(a){var b=this,c=new m(function(a,c){b.ready().then(function(){var d=b._dbInfo,e=d.db.transaction(d.storeName,"readwrite").objectStore(d.storeName),f=e.clear();f.onsuccess=function(){a()},f.onerror=function(){c(f.error)}})["catch"](c)});return k(c,a),c}function g(a){var b=this,c=new m(function(a,c){b.ready().then(function(){var d=b._dbInfo,e=d.db.transaction(d.storeName,"readonly").objectStore(d.storeName),f=e.count();f.onsuccess=function(){a(f.result)},f.onerror=function(){c(f.error)}})["catch"](c)});return j(c,a),c}function h(a,b){var c=this,d=new m(function(b,d){return 0>a?void b(null):void c.ready().then(function(){var e=c._dbInfo,f=e.db.transaction(e.storeName,"readonly").objectStore(e.storeName),g=!1,h=f.openCursor();h.onsuccess=function(){var c=h.result;return c?void(0===a?b(c.key):g?b(c.key):(g=!0,c.advance(a))):void b(null)},h.onerror=function(){d(h.error)}})["catch"](d)});return j(d,b),d}function i(a){var b=this,c=new m(function(a,c){b.ready().then(function(){var d=b._dbInfo,e=d.db.transaction(d.storeName,"readonly").objectStore(d.storeName),f=e.openCursor(),g=[];f.onsuccess=function(){var b=f.result;return b?(g.push(b.key),void b["continue"]()):void a(g)},f.onerror=function(){c(f.error)}})["catch"](c)});return j(c,a),c}function j(a,b){b&&a.then(function(a){b(null,a)},function(a){b(a)})}function k(a,b){b&&a.then(function(a){l(b,a)},function(a){b(a)})}function l(a,b){return a?setTimeout(function(){return a(null,b)},0):void 0}var m="undefined"!=typeof module&&module.exports?require("promise"):this.Promise,n=n||this.indexedDB||this.webkitIndexedDB||this.mozIndexedDB||this.OIndexedDB||this.msIndexedDB;if(n){var o={_driver:"asyncStorage",_initStorage:a,iterate:c,getItem:b,setItem:d,removeItem:e,clear:f,length:g,key:h,keys:i};"function"==typeof define&&define.amd?define("asyncStorage",function(){return o}):"undefined"!=typeof module&&module.exports?module.exports=o:this.asyncStorage=o}}.call(window),function(){"use strict";function a(a){var b=this,c={};if(a)for(var d in a)c[d]=a[d];return c.keyPrefix=c.name+"/",b._dbInfo=c,n.resolve()}function b(a){var b=this,c=new n(function(a,c){b.ready().then(function(){for(var c=b._dbInfo.keyPrefix,d=o.length-1;d>=0;d--){var e=o.key(d);0===e.indexOf(c)&&o.removeItem(e)}a()})["catch"](c)});return m(c,a),c}function c(a,b){var c=this;"string"!=typeof a&&(window.console.warn(a+" used as a key, but it is not a string."),a=String(a));var d=new n(function(b,d){c.ready().then(function(){try{var e=c._dbInfo,f=o.getItem(e.keyPrefix+a);f&&(f=i(f)),b(f)}catch(g){d(g)}})["catch"](d)});return m(d,b),d}function d(a,b){var c=this,d=new n(function(b,d){c.ready().then(function(){try{for(var e=c._dbInfo.keyPrefix,f=e.length,g=o.length,h=0;g>h;h++){var j=o.key(h),k=o.getItem(j);if(k&&(k=i(k)),k=a(k,j.substring(f)),void 0!==k)return void b(k)}b()}catch(l){d(l)}})["catch"](d)});return m(d,b),d}function e(a,b){var c=this,d=new n(function(b,d){c.ready().then(function(){var d,e=c._dbInfo;try{d=o.key(a)}catch(f){d=null}d&&(d=d.substring(e.keyPrefix.length)),b(d)})["catch"](d)});return m(d,b),d}function f(a){var b=this,c=new n(function(a,c){b.ready().then(function(){for(var c=b._dbInfo,d=o.length,e=[],f=0;d>f;f++)0===o.key(f).indexOf(c.keyPrefix)&&e.push(o.key(f).substring(c.keyPrefix.length));a(e)})["catch"](c)});return m(c,a),c}function g(a){var b=this,c=new n(function(a,c){b.keys().then(function(b){a(b.length)})["catch"](c)});return m(c,a),c}function h(a,b){var c=this;"string"!=typeof a&&(window.console.warn(a+" used as a key, but it is not a string."),a=String(a));var d=new n(function(b,d){c.ready().then(function(){var d=c._dbInfo;o.removeItem(d.keyPrefix+a),b()})["catch"](d)});return m(d,b),d}function i(a){if(a.substring(0,r)!==q)return JSON.parse(a);for(var b=a.substring(D),c=a.substring(r,D),d=new ArrayBuffer(2*b.length),e=new Uint16Array(d),f=b.length-1;f>=0;f--)e[f]=b.charCodeAt(f);switch(c){case s:return d;case t:return new Blob([d]);case u:return new Int8Array(d);case v:return new Uint8Array(d);case w:return new Uint8ClampedArray(d);case x:return new Int16Array(d);case z:return new Uint16Array(d);case y:return new Int32Array(d);case A:return new Uint32Array(d);case B:return new Float32Array(d);case C:return new Float64Array(d);default:throw new Error("Unkown type: "+c)}}function j(a){var b="",c=new Uint16Array(a);try{b=String.fromCharCode.apply(null,c)}catch(d){for(var e=0;e<c.length;e++)b+=String.fromCharCode(c[e])}return b}function k(a,b){var c="";if(a&&(c=a.toString()),a&&("[object ArrayBuffer]"===a.toString()||a.buffer&&"[object ArrayBuffer]"===a.buffer.toString())){var d,e=q;a instanceof ArrayBuffer?(d=a,e+=s):(d=a.buffer,"[object Int8Array]"===c?e+=u:"[object Uint8Array]"===c?e+=v:"[object Uint8ClampedArray]"===c?e+=w:"[object Int16Array]"===c?e+=x:"[object Uint16Array]"===c?e+=z:"[object Int32Array]"===c?e+=y:"[object Uint32Array]"===c?e+=A:"[object Float32Array]"===c?e+=B:"[object Float64Array]"===c?e+=C:b(new Error("Failed to get type for BinaryArray"))),b(e+j(d))}else if("[object Blob]"===c){var f=new FileReader;f.onload=function(){var a=j(this.result);b(q+t+a)},f.readAsArrayBuffer(a)}else try{b(JSON.stringify(a))}catch(g){window.console.error("Couldn't convert value into a JSON string: ",a),b(g)}}function l(a,b,c){var d=this;"string"!=typeof a&&(window.console.warn(a+" used as a key, but it is not a string."),a=String(a));var e=new n(function(c,e){d.ready().then(function(){void 0===b&&(b=null);var f=b;k(b,function(b,g){if(g)e(g);else{try{var h=d._dbInfo;o.setItem(h.keyPrefix+a,b)}catch(i){("QuotaExceededError"===i.name||"NS_ERROR_DOM_QUOTA_REACHED"===i.name)&&e(i)}c(f)}})})["catch"](e)});return m(e,c),e}function m(a,b){b&&a.then(function(a){b(null,a)},function(a){b(a)})}var n="undefined"!=typeof module&&module.exports?require("promise"):this.Promise,o=null;try{if(!(this.localStorage&&"setItem"in this.localStorage))return;o=this.localStorage}catch(p){return}var q="__lfsc__:",r=q.length,s="arbf",t="blob",u="si08",v="ui08",w="uic8",x="si16",y="si32",z="ur16",A="ui32",B="fl32",C="fl64",D=r+s.length,E={_driver:"localStorageWrapper",_initStorage:a,iterate:d,getItem:c,setItem:l,removeItem:h,clear:b,length:g,key:e,keys:f};"function"==typeof define&&define.amd?define("localStorageWrapper",function(){return E}):"undefined"!=typeof module&&module.exports?module.exports=E:this.localStorageWrapper=E}.call(window),function(){"use strict";function a(a){var b=this,c={db:null};if(a)for(var d in a)c[d]="string"!=typeof a[d]?a[d].toString():a[d];return new o(function(d,e){try{c.db=p(c.name,String(c.version),c.description,c.size)}catch(f){return b.setDriver("localStorageWrapper").then(function(){return b._initStorage(a)}).then(d)["catch"](e)}c.db.transaction(function(a){a.executeSql("CREATE TABLE IF NOT EXISTS "+c.storeName+" (id INTEGER PRIMARY KEY, key unique, value)",[],function(){b._dbInfo=c,d()},function(a,b){e(b)})})})}function b(a,b){var c=this;"string"!=typeof a&&(window.console.warn(a+" used as a key, but it is not a string."),a=String(a));var d=new o(function(b,d){c.ready().then(function(){var e=c._dbInfo;e.db.transaction(function(c){c.executeSql("SELECT * FROM "+e.storeName+" WHERE key = ? LIMIT 1",[a],function(a,c){var d=c.rows.length?c.rows.item(0).value:null;d&&(d=k(d)),b(d)},function(a,b){d(b)})})})["catch"](d)});return m(d,b),d}function c(a,b){var c=this,d=new o(function(b,d){c.ready().then(function(){var e=c._dbInfo;e.db.transaction(function(c){c.executeSql("SELECT * FROM "+e.storeName,[],function(c,d){for(var e=d.rows,f=e.length,g=0;f>g;g++){var h=e.item(g),i=h.value;if(i&&(i=k(i)),i=a(i,h.key),void 0!==i)return void b(i)}b()},function(a,b){d(b)})})})["catch"](d)});return m(d,b),d}function d(a,b,c){var d=this;"string"!=typeof a&&(window.console.warn(a+" used as a key, but it is not a string."),a=String(a));var e=new o(function(c,e){d.ready().then(function(){void 0===b&&(b=null);var f=b;l(b,function(b,g){if(g)e(g);else{var h=d._dbInfo;h.db.transaction(function(d){d.executeSql("INSERT OR REPLACE INTO "+h.storeName+" (key, value) VALUES (?, ?)",[a,b],function(){c(f)},function(a,b){e(b)})},function(a){a.code===a.QUOTA_ERR&&e(a)})}})})["catch"](e)});return m(e,c),e}function e(a,b){var c=this;"string"!=typeof a&&(window.console.warn(a+" used as a key, but it is not a string."),a=String(a));var d=new o(function(b,d){c.ready().then(function(){var e=c._dbInfo;e.db.transaction(function(c){c.executeSql("DELETE FROM "+e.storeName+" WHERE key = ?",[a],function(){b()},function(a,b){d(b)})})})["catch"](d)});return m(d,b),d}function f(a){var b=this,c=new o(function(a,c){b.ready().then(function(){var d=b._dbInfo;d.db.transaction(function(b){b.executeSql("DELETE FROM "+d.storeName,[],function(){a()},function(a,b){c(b)})})})["catch"](c)});return m(c,a),c}function g(a){var b=this,c=new o(function(a,c){b.ready().then(function(){var d=b._dbInfo;d.db.transaction(function(b){b.executeSql("SELECT COUNT(key) as c FROM "+d.storeName,[],function(b,c){var d=c.rows.item(0).c;a(d)},function(a,b){c(b)})})})["catch"](c)});return m(c,a),c}function h(a,b){var c=this,d=new o(function(b,d){c.ready().then(function(){var e=c._dbInfo;e.db.transaction(function(c){c.executeSql("SELECT key FROM "+e.storeName+" WHERE id = ? LIMIT 1",[a+1],function(a,c){var d=c.rows.length?c.rows.item(0).key:null;b(d)},function(a,b){d(b)})})})["catch"](d)});return m(d,b),d}function i(a){var b=this,c=new o(function(a,c){b.ready().then(function(){var d=b._dbInfo;d.db.transaction(function(b){b.executeSql("SELECT key FROM "+d.storeName,[],function(b,c){for(var d=[],e=0;e<c.rows.length;e++)d.push(c.rows.item(e).key);a(d)},function(a,b){c(b)})})})["catch"](c)});return m(c,a),c}function j(a){var b,c=new Uint8Array(a),d="";for(b=0;b<c.length;b+=3)d+=n[c[b]>>2],d+=n[(3&c[b])<<4|c[b+1]>>4],d+=n[(15&c[b+1])<<2|c[b+2]>>6],d+=n[63&c[b+2]];return c.length%3===2?d=d.substring(0,d.length-1)+"=":c.length%3===1&&(d=d.substring(0,d.length-2)+"=="),d}function k(a){if(a.substring(0,r)!==q)return JSON.parse(a);var b,c,d,e,f,g=a.substring(D),h=a.substring(r,D),i=.75*g.length,j=g.length,k=0;"="===g[g.length-1]&&(i--,"="===g[g.length-2]&&i--);var l=new ArrayBuffer(i),m=new Uint8Array(l);for(b=0;j>b;b+=4)c=n.indexOf(g[b]),d=n.indexOf(g[b+1]),e=n.indexOf(g[b+2]),f=n.indexOf(g[b+3]),m[k++]=c<<2|d>>4,m[k++]=(15&d)<<4|e>>2,m[k++]=(3&e)<<6|63&f;switch(h){case s:return l;case t:return new Blob([l]);case u:return new Int8Array(l);case v:return new Uint8Array(l);case w:return new Uint8ClampedArray(l);case x:return new Int16Array(l);case z:return new Uint16Array(l);case y:return new Int32Array(l);case A:return new Uint32Array(l);case B:return new Float32Array(l);case C:return new Float64Array(l);default:throw new Error("Unkown type: "+h)}}function l(a,b){var c="";if(a&&(c=a.toString()),a&&("[object ArrayBuffer]"===a.toString()||a.buffer&&"[object ArrayBuffer]"===a.buffer.toString())){var d,e=q;a instanceof ArrayBuffer?(d=a,e+=s):(d=a.buffer,"[object Int8Array]"===c?e+=u:"[object Uint8Array]"===c?e+=v:"[object Uint8ClampedArray]"===c?e+=w:"[object Int16Array]"===c?e+=x:"[object Uint16Array]"===c?e+=z:"[object Int32Array]"===c?e+=y:"[object Uint32Array]"===c?e+=A:"[object Float32Array]"===c?e+=B:"[object Float64Array]"===c?e+=C:b(new Error("Failed to get type for BinaryArray"))),b(e+j(d))}else if("[object Blob]"===c){var f=new FileReader;f.onload=function(){var a=j(this.result);b(q+t+a)},f.readAsArrayBuffer(a)}else try{b(JSON.stringify(a))}catch(g){window.console.error("Couldn't convert value into a JSON string: ",a),b(null,g)}}function m(a,b){b&&a.then(function(a){b(null,a)},function(a){b(a)})}var n="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/",o="undefined"!=typeof module&&module.exports?require("promise"):this.Promise,p=this.openDatabase,q="__lfsc__:",r=q.length,s="arbf",t="blob",u="si08",v="ui08",w="uic8",x="si16",y="si32",z="ur16",A="ui32",B="fl32",C="fl64",D=r+s.length;if(p){var E={_driver:"webSQLStorage",_initStorage:a,iterate:c,getItem:b,setItem:d,removeItem:e,clear:f,length:g,key:h,keys:i};"function"==typeof define&&define.amd?define("webSQLStorage",function(){return E}):"undefined"!=typeof module&&module.exports?module.exports=E:this.webSQLStorage=E}}.call(window),function(){"use strict";function a(a,b){a[b]=function(){var c=arguments;return a.ready().then(function(){return a[b].apply(a,c)})}}function b(){for(var a=1;a<arguments.length;a++){var b=arguments[a];if(b)for(var c in b)b.hasOwnProperty(c)&&(arguments[0][c]=n(b[c])?b[c].slice():b[c])}return arguments[0]}function c(a){for(var b in g)if(g.hasOwnProperty(b)&&g[b]===a)return!0;return!1}function d(c){this._config=b({},k,c),this._driverSet=null,this._ready=!1,this._dbInfo=null;for(var d=0;d<i.length;d++)a(this,i[d]);this.setDriver(this._config.driver)}var e="undefined"!=typeof module&&module.exports?require("promise"):this.Promise,f={},g={INDEXEDDB:"asyncStorage",LOCALSTORAGE:"localStorageWrapper",WEBSQL:"webSQLStorage"},h=[g.INDEXEDDB,g.WEBSQL,g.LOCALSTORAGE],i=["clear","getItem","iterate","key","keys","length","removeItem","setItem"],j={DEFINE:1,EXPORT:2,WINDOW:3},k={description:"",driver:h.slice(),name:"localforage",size:4980736,storeName:"keyvaluepairs",version:1},l=j.WINDOW;"function"==typeof define&&define.amd?l=j.DEFINE:"undefined"!=typeof module&&module.exports&&(l=j.EXPORT);var m=function(a){var b=b||a.indexedDB||a.webkitIndexedDB||a.mozIndexedDB||a.OIndexedDB||a.msIndexedDB,c={};return c[g.WEBSQL]=!!a.openDatabase,c[g.INDEXEDDB]=!!function(){if("undefined"!=typeof a.openDatabase&&a.navigator&&a.navigator.userAgent&&/Safari/.test(a.navigator.userAgent)&&!/Chrome/.test(a.navigator.userAgent))return!1;try{return b&&"function"==typeof b.open&&"undefined"!=typeof a.IDBKeyRange}catch(c){return!1}}(),c[g.LOCALSTORAGE]=!!function(){try{return a.localStorage&&"setItem"in a.localStorage&&a.localStorage.setItem}catch(b){return!1}}(),c}(this),n=Array.isArray||function(a){return"[object Array]"===Object.prototype.toString.call(a)},o=this;d.prototype.INDEXEDDB=g.INDEXEDDB,d.prototype.LOCALSTORAGE=g.LOCALSTORAGE,d.prototype.WEBSQL=g.WEBSQL,d.prototype.config=function(a){if("object"==typeof a){if(this._ready)return new Error("Can't call config() after localforage has been used.");for(var b in a)"storeName"===b&&(a[b]=a[b].replace(/\W/g,"_")),this._config[b]=a[b];return"driver"in a&&a.driver&&this.setDriver(this._config.driver),!0}return"string"==typeof a?this._config[a]:this._config},d.prototype.defineDriver=function(a,b,d){var g=new e(function(b,d){try{var g=a._driver,h=new Error("Custom driver not compliant; see https://mozilla.github.io/localForage/#definedriver"),j=new Error("Custom driver name already in use: "+a._driver);if(!a._driver)return void d(h);if(c(a._driver))return void d(j);for(var k=i.concat("_initStorage"),l=0;l<k.length;l++){var n=k[l];if(!n||!a[n]||"function"!=typeof a[n])return void d(h)}var o=e.resolve(!0);"_support"in a&&(o=a._support&&"function"==typeof a._support?a._support():e.resolve(!!a._support)),o.then(function(c){m[g]=c,f[g]=a,b()},d)}catch(p){d(p)}});return g.then(b,d),g},d.prototype.driver=function(){return this._driver||null},d.prototype.ready=function(a){var b=this,c=new e(function(a,c){b._driverSet.then(function(){null===b._ready&&(b._ready=b._initStorage(b._config)),b._ready.then(a,c)})["catch"](c)});return c.then(a,a),c},d.prototype.setDriver=function(a,b,d){function g(){h._config.driver=h.driver()}var h=this;return"string"==typeof a&&(a=[a]),this._driverSet=new e(function(b,d){var g=h._getFirstSupportedDriver(a),i=new Error("No available storage method found.");if(!g)return h._driverSet=e.reject(i),void d(i);if(h._dbInfo=null,h._ready=null,c(g)){if(l===j.DEFINE)return void require([g],function(a){h._extend(a),b()});if(l===j.EXPORT){var k;switch(g){case h.INDEXEDDB:k=require("./drivers/indexeddb");break;case h.LOCALSTORAGE:k=require("./drivers/localstorage");break;case h.WEBSQL:k=require("./drivers/websql")}h._extend(k)}else h._extend(o[g])}else{if(!f[g])return h._driverSet=e.reject(i),void d(i);h._extend(f[g])}b()}),this._driverSet.then(g,g),this._driverSet.then(b,d),this._driverSet},d.prototype.supports=function(a){return!!m[a]},d.prototype._extend=function(a){b(this,a)},d.prototype._getFirstSupportedDriver=function(a){if(a&&n(a))for(var b=0;b<a.length;b++){var c=a[b];if(this.supports(c))return c}return null},d.prototype.createInstance=function(a){return new d(a)};var p=new d;l===j.DEFINE?define("localforage",function(){return p}):l===j.EXPORT?module.exports=p:this.localforage=p}.call(window);
``


/*@source colorpicker.min.js */
``
/**!
 *
 * Color picker
 * Author: Stefan Petre www.eyecon.ro
 * 
 * Dual licensed under the MIT and GPL licenses
 * 
 */
(function(c){var h=function(){var h=65,H={eventName:"click",onShow:function(){},onBeforeShow:function(){},onHide:function(){},onChange:function(){},onSubmit:function(){},color:"ff0000",livePreview:!0,flat:!1},k=function(a,b){var d=q(a);c(b).data("colorpicker").fields.eq(1).val(d.r).end().eq(2).val(d.g).end().eq(3).val(d.b).end()},r=function(a,b){c(b).data("colorpicker").fields.eq(4).val(a.h).end().eq(5).val(a.s).end().eq(6).val(a.b).end()},m=function(a,b){c(b).data("colorpicker").fields.eq(0).val(l(a)).end()},
t=function(a,b){c(b).data("colorpicker").selector.css("backgroundColor","#"+l({h:a.h,s:100,b:100}));c(b).data("colorpicker").selectorIndic.css({left:parseInt(150*a.s/100,10),top:parseInt(150*(100-a.b)/100,10)})},u=function(a,b){c(b).data("colorpicker").hue.css("top",parseInt(150-150*a.h/360,10))},w=function(a,b){c(b).data("colorpicker").currentColor.css("backgroundColor","#"+l(a))},v=function(a,b){c(b).data("colorpicker").newColor.css("backgroundColor","#"+l(a))},I=function(a){a=a.charCode||a.keyCode||
-1;if(a>h&&90>=a||32==a)return!1;!0===c(this).parent().parent().data("colorpicker").livePreview&&n.apply(this)},n=function(a){var b=c(this).parent().parent(),d;if(0<this.parentNode.className.indexOf("_hex")){d=b.data("colorpicker");var f=this.value,e=6-f.length;if(0<e){for(var g=[],h=0;h<e;h++)g.push("0");g.push(f);f=g.join("")}f=p(x(f));d.color=d=f}else 0<this.parentNode.className.indexOf("_hsb")?b.data("colorpicker").color=d=y({h:parseInt(b.data("colorpicker").fields.eq(4).val(),10),s:parseInt(b.data("colorpicker").fields.eq(5).val(),
10),b:parseInt(b.data("colorpicker").fields.eq(6).val(),10)}):(d=b.data("colorpicker"),f=parseInt(b.data("colorpicker").fields.eq(1).val(),10),e=parseInt(b.data("colorpicker").fields.eq(2).val(),10),g=parseInt(b.data("colorpicker").fields.eq(3).val(),10),f={r:Math.min(255,Math.max(0,f)),g:Math.min(255,Math.max(0,e)),b:Math.min(255,Math.max(0,g))},d.color=d=p(f));a&&(k(d,b.get(0)),m(d,b.get(0)),r(d,b.get(0)));t(d,b.get(0));u(d,b.get(0));v(d,b.get(0));b.data("colorpicker").onChange.apply(b,[d,l(d),
q(d)])},J=function(a){c(this).parent().parent().data("colorpicker").fields.parent().removeClass("colorpicker_focus")},K=function(){h=0<this.parentNode.className.indexOf("_hex")?70:65;c(this).parent().parent().data("colorpicker").fields.parent().removeClass("colorpicker_focus");c(this).parent().addClass("colorpicker_focus")},L=function(a){var b=c(this).parent().find("input").focus();a={el:c(this).parent().addClass("colorpicker_slider"),max:0<this.parentNode.className.indexOf("_hsb_h")?360:0<this.parentNode.className.indexOf("_hsb")?
100:255,y:a.pageY,field:b,val:parseInt(b.val(),10),preview:c(this).parent().parent().data("colorpicker").livePreview};c(document).bind("mouseup",a,z);c(document).bind("mousemove",a,A)},A=function(a){a.data.field.val(Math.max(0,Math.min(a.data.max,parseInt(a.data.val+a.pageY-a.data.y,10))));a.data.preview&&n.apply(a.data.field.get(0),[!0]);return!1},z=function(a){n.apply(a.data.field.get(0),[!0]);a.data.el.removeClass("colorpicker_slider").find("input").focus();c(document).unbind("mouseup",z);c(document).unbind("mousemove",
A);return!1},M=function(a){a={cal:c(this).parent(),y:c(this).offset().top};a.preview=a.cal.data("colorpicker").livePreview;c(document).bind("mouseup",a,B);c(document).bind("mousemove",a,C)},C=function(a){n.apply(a.data.cal.data("colorpicker").fields.eq(4).val(parseInt(360*(150-Math.max(0,Math.min(150,a.pageY-a.data.y)))/150,10)).get(0),[a.data.preview]);return!1},B=function(a){k(a.data.cal.data("colorpicker").color,a.data.cal.get(0));m(a.data.cal.data("colorpicker").color,a.data.cal.get(0));c(document).unbind("mouseup",
B);c(document).unbind("mousemove",C);return!1},N=function(a){a={cal:c(this).parent(),pos:c(this).offset()};a.preview=a.cal.data("colorpicker").livePreview;c(document).bind("mouseup",a,D);c(document).bind("mousemove",a,E)},E=function(a){n.apply(a.data.cal.data("colorpicker").fields.eq(6).val(parseInt(100*(150-Math.max(0,Math.min(150,a.pageY-a.data.pos.top)))/150,10)).end().eq(5).val(parseInt(100*Math.max(0,Math.min(150,a.pageX-a.data.pos.left))/150,10)).get(0),[a.data.preview]);return!1},D=function(a){k(a.data.cal.data("colorpicker").color,
a.data.cal.get(0));m(a.data.cal.data("colorpicker").color,a.data.cal.get(0));c(document).unbind("mouseup",D);c(document).unbind("mousemove",E);return!1},O=function(a){c(this).addClass("colorpicker_focus")},P=function(a){c(this).removeClass("colorpicker_focus")},Q=function(a){a=c(this).parent();var b=a.data("colorpicker").color;a.data("colorpicker").origColor=b;w(b,a.get(0));a.data("colorpicker").onSubmit(b,l(b),q(b),a.data("colorpicker").el)},G=function(a){var b,d,f=c("#"+c(this).data("colorpickerId"));
f.data("colorpicker").onBeforeShow.apply(this,[f.get(0)]);var e=c(this).offset(),g="CSS1Compat"==document.compatMode;a=window.pageXOffset||(g?document.documentElement.scrollLeft:document.body.scrollLeft);b=window.pageYOffset||(g?document.documentElement.scrollTop:document.body.scrollTop);d=window.innerWidth||(g?document.documentElement.clientWidth:document.body.clientWidth);var h=e.top+this.offsetHeight,e=e.left;h+176>b+(window.innerHeight||(g?document.documentElement.clientHeight:document.body.clientHeight))&&
(h-=this.offsetHeight+176);e+356>a+d&&(e-=356);f.css({left:e+"px",top:h+"px"});0!=f.data("colorpicker").onShow.apply(this,[f.get(0)])&&f.show();c(document).bind("mousedown",{cal:f},F);return!1},F=function(a){R(a.data.cal.get(0),a.target,a.data.cal.get(0))||(0!=a.data.cal.data("colorpicker").onHide.apply(this,[a.data.cal.get(0)])&&a.data.cal.hide(),c(document).unbind("mousedown",F))},R=function(a,b,d){if(a==b)return!0;if(a.contains)return a.contains(b);if(a.compareDocumentPosition)return!!(a.compareDocumentPosition(b)&
16);for(b=b.parentNode;b&&b!=d;){if(b==a)return!0;b=b.parentNode}return!1},y=function(a){return{h:Math.min(360,Math.max(0,a.h)),s:Math.min(100,Math.max(0,a.s)),b:Math.min(100,Math.max(0,a.b))}},x=function(a){a=parseInt(-1<a.indexOf("#")?a.substring(1):a,16);return{r:a>>16,g:(a&65280)>>8,b:a&255}},p=function(a){var b={h:0,s:0,b:0},d=Math.min(a.r,a.g,a.b),c=Math.max(a.r,a.g,a.b),d=c-d;b.b=c;b.s=0!=c?255*d/c:0;b.h=0!=b.s?a.r==c?(a.g-a.b)/d:a.g==c?2+(a.b-a.r)/d:4+(a.r-a.g)/d:-1;b.h*=60;0>b.h&&(b.h+=360);
b.s*=100/255;b.b*=100/255;return b},q=function(a){var b,d,c;b=Math.round(a.h);var e=Math.round(255*a.s/100);a=Math.round(255*a.b/100);if(0==e)b=d=c=a;else{var e=(255-e)*a/255,g=b%60*(a-e)/60;360==b&&(b=0);60>b?(b=a,c=e,d=e+g):120>b?(d=a,c=e,b=a-g):180>b?(d=a,b=e,c=e+g):240>b?(c=a,b=e,d=a-g):300>b?(c=a,d=e,b=e+g):360>b?(b=a,d=e,c=a-g):c=d=b=0}return{r:Math.round(b),g:Math.round(d),b:Math.round(c)}},S=function(a){var b=[a.r.toString(16),a.g.toString(16),a.b.toString(16)];c.each(b,function(a,c){1==c.length&&
(b[a]="0"+c)});return b.join("")},l=function(a){return S(q(a))},T=function(){var a=c(this).parent(),b=a.data("colorpicker").origColor;a.data("colorpicker").color=b;k(b,a.get(0));m(b,a.get(0));r(b,a.get(0));t(b,a.get(0));u(b,a.get(0));v(b,a.get(0))};return{init:function(a){a=c.extend({},H,a||{});if("string"==typeof a.color)a.color=p(x(a.color));else if(void 0!=a.color.r&&void 0!=a.color.g&&void 0!=a.color.b)a.color=p(a.color);else if(void 0!=a.color.h&&void 0!=a.color.s&&void 0!=a.color.b)a.color=
y(a.color);else return this;return this.each(function(){if(!c(this).data("colorpickerId")){var b=c.extend({},a);b.origColor=a.color;var d="collorpicker_"+parseInt(1E3*Math.random());c(this).data("colorpickerId",d);d=c('<div class="colorpicker"><div class="colorpicker_color"><div><div></div></div></div><div class="colorpicker_hue"><div></div></div><div class="colorpicker_new_color"></div><div class="colorpicker_current_color"></div><div class="colorpicker_hex"><input type="text" maxlength="6" size="6" /></div><div class="colorpicker_rgb_r colorpicker_field"><input type="text" maxlength="3" size="3" /><span></span></div><div class="colorpicker_rgb_g colorpicker_field"><input type="text" maxlength="3" size="3" /><span></span></div><div class="colorpicker_rgb_b colorpicker_field"><input type="text" maxlength="3" size="3" /><span></span></div><div class="colorpicker_hsb_h colorpicker_field"><input type="text" maxlength="3" size="3" /><span></span></div><div class="colorpicker_hsb_s colorpicker_field"><input type="text" maxlength="3" size="3" /><span></span></div><div class="colorpicker_hsb_b colorpicker_field"><input type="text" maxlength="3" size="3" /><span></span></div><div class="colorpicker_submit"></div></div>').attr("id",
d);b.flat?d.appendTo(this).show():d.appendTo(document.body);b.fields=d.find("input").bind("keyup",I).bind("change",n).bind("blur",J).bind("focus",K);d.find("span").bind("mousedown",L).end().find(">div.colorpicker_current_color").bind("click",T);b.selector=d.find("div.colorpicker_color").bind("mousedown",N);b.selectorIndic=b.selector.find("div div");b.el=this;b.hue=d.find("div.colorpicker_hue div");d.find("div.colorpicker_hue").bind("mousedown",M);b.newColor=d.find("div.colorpicker_new_color");b.currentColor=
d.find("div.colorpicker_current_color");d.data("colorpicker",b);d.find("div.colorpicker_submit").bind("mouseenter",O).bind("mouseleave",P).bind("click",Q);k(b.color,d.get(0));r(b.color,d.get(0));m(b.color,d.get(0));u(b.color,d.get(0));t(b.color,d.get(0));w(b.color,d.get(0));v(b.color,d.get(0));b.flat?d.css({position:"relative",display:"block"}):c(this).bind(b.eventName,G)}})},showPicker:function(){return this.each(function(){c(this).data("colorpickerId")&&G.apply(this)})},hidePicker:function(){return this.each(function(){c(this).data("colorpickerId")&&
c("#"+c(this).data("colorpickerId")).hide()})},setColor:function(a){if("string"==typeof a)a=p(x(a));else if(void 0!=a.r&&void 0!=a.g&&void 0!=a.b)a=p(a);else if(void 0!=a.h&&void 0!=a.s&&void 0!=a.b)a=y(a);else return this;return this.each(function(){if(c(this).data("colorpickerId")){var b=c("#"+c(this).data("colorpickerId"));b.data("colorpicker").color=a;b.data("colorpicker").origColor=a;k(a,b.get(0));r(a,b.get(0));m(a,b.get(0));u(a,b.get(0));t(a,b.get(0));w(a,b.get(0));v(a,b.get(0))}})}}}();c.fn.extend({ColorPicker:h.init,
ColorPickerHide:h.hidePicker,ColorPickerShow:h.showPicker,ColorPickerSetColor:h.setColor})})(jQuery);

``


/*@source p0ne.auxiliaries.ls */
/**
 * Auxiliary-functions for plug_p0ne
 *
 * @author jtbrinkmann aka. Brinkie Pie
 * @license MIT License
 * @copyright (c) 2015 J.-T. Brinkmann
*/

export $window = $ window
export $body = $ document.body

/**/ # RequireJS fix
window.require = window.requirejs
window.define = window.requirejs.define

/*/ # no RequireJS fix
(localforage) <- require <[ localforage ]>
/**/
export localforage


/*####################################
#         PROTOTYPE FUNCTIONS        #
####################################*/
# helper for defining non-enumerable functions via Object.defineProperty
tmp = (property, value) !-> if @[property] != value then Object.defineProperty this, property, {-enumerable, +writable, +configurable, value}
tmp.call Object::, \define, tmp
Object::define \defineGetter, (property, get) !-> if @[property] != get then Object.defineProperty this, property, {-enumerable, +configurable, get}

Object::define \hasAttribute, (property) !-> return property of this

Array::define \remove, (i) !-> return @splice i, 1
Array::define \removeItem, (el) !->
    if -1 != (i = @indexOf(el))
        @splice i, 1
    return this
Array::define \random, !-> return this[~~(Math.random! * @length)]
Array::define \unique, !->
    res = []; l=0
    for el, i in this
        for o til i
            break if @[o] == el
        else
            res[l++] = el
    return res
Array::define \joinWrapped, (pre='', post='', between='') !->
    return "" if @length == 0
    res = "#pre#{@0}#post"
    for i from 1 til @length
        res += "#between#pre#{@[i]}#post"
    return res

String::define \reverse, !->
    res = ""
    i = @length
    while i--
        res += @[i]
    return res
String::define \startsWith, (str) !->
    i=str.length
    while i>0
        return false if str[--i] != this[i]
    return true
String::define \endsWith, (str) !->
    i=str.length; o=@length - i
    while i>0
        return false if str[--i] != this[o+i]
    return true
String::define \replaceSansHTML, (rgx, rpl) !->
    # this acts like .replace, but avoids HTML tags and their content
    return this .replace /(.*?)(<(?:br>|.*?>.*?<\/\w+>|.*?\/>)|$)/gi, (,pre, post) !->
        return "#{pre .replace(rgx, rpl)}#post"

for Constr in [String, Array]
    Constr::define \has, (needle) !-> return -1 != @indexOf needle
    Constr::define \hasAny, (needles) !->
        for needle in needles when -1 != @indexOf needle
            return true
        return false

Number::defineGetter \s,   !-> return this *     1_000s_to_ms
Number::defineGetter \min, !-> return this *    60_000min_to_ms
Number::defineGetter \h,   !-> return this * 3_600_000h_to_ms

if window.chrome
    Error::__defineGetter__ \messageAndStack !->
        return @stack
else
    Error::__defineGetter__ \messageAndStack !->
        return "#{@name}: #{@message}\n#{@stack}"


jQuery.fn <<<<
    indexOf: (selector) !->
        /* selector may be a String jQuery Selector or an HTMLElement */
        if @length and selector not instanceof HTMLElement
            i = [].indexOf.call this, selector
            return i if i != -1
        for el, i in this when jQuery(el).is selector
            return i
        return -1

    concat: (arr2) !->
        l = @length
        return this if not arr2 or not arr2.length
        return arr2 if not l
        for el, i in arr2
            @[i+l] = el
        @length += arr2.length
        return this
    fixSize: !-> #… only used in saveChat so far
        for el in this
            el.style .width = "#{el.width}px"
            el.style .height = "#{el.height}px"
        return this
    loadAll: (cb) !-> # adds an event listener for when all elements are loaded
        remaining = @length
        if not cb or not remaining
            _.defer cb!
        else
            @load !->
                if --remaining == 0
                    cb!
        return this
    binaryGuess: (checkFn) !->
        # returns element with index `n` for which:
        # if checkFn(element) for all elements in this from 0 to `n` all returns false,
        # and for all elements in this from `n` to the last one returns true
        # returns an empty jQuery object if there is no matching `n`
        # (i.e. checkFn(element) returns false for all elements, or this object is empty)
        # example use case: find the first item that is visible in a scrollable list

        step = @length
        if step == 0 or not checkFn @[step-1], step, @[step-1] # test this.length and last element
            return $!
        else if checkFn.call @0, 0, @0 # test first element
            return @first!

        i = @length - 1
        goingUp = true
        do
            step = ~~(step / 2)
            if checkFn.call @[i], i, @[i]
                goingUp = false
                i = Math.floor(i - step)
            else
                goingUp = true
                i = Math.ceil(i + step)
                console.log "going up to #i (#step)"
        while step > 0
        i++ if goingUp
        return @eq i

$.easing <<<<
    easeInQuad: (p) !->
        return p * p
    easeOutQuad: (p) !->
        return 1-(1-p)*(1-p)



/*####################################
#            DATA MANAGER            #
####################################*/
# compress to invalid UTF16 to save space, if supported by the browser. compress to valid UTF16 if not
if window.chrome
    window{compress, decompress} = LZString
else
    window{compressToUTF16:compress, decompressFromUTF16:decompress} = LZString

# function to load data using localforage, decompress it and parse it as JSON
window.dataLoad = (name, defaultVal={}, callback/*(err, data)*/) !->
    if p0ne.autosave[name]
        p0ne.autosave_num[name]++
        return callback(null, p0ne.autosave[name])
    p0ne.autosave_num[name] = 0

    #if localStorage[name]
    localforage.getItem name, (err, data) !->
        if err
            warning = "failed to load '#name' from localforage"
            errorCode = \localforage
        else if data
            p0ne.autosave[name] = data
            return callback err, data
            /*
            if decompress(data)
                try
                    p0ne.autosave[name]=JSON.parse(that)
                    return callback err, p0ne.autosave[name]
                catch err
                    warning = "failed to parse '#name' as JSON"
                    errorCode = \JSON
            else
                warning = "failed to decompress '#name' data"
                errorCode = \decompress
            */
        else
            p0ne.autosave[name]=defaultVal
            return callback err, defaultVal

        # if data failed to load
        name_ = "#{name}_#{getISOTime!}"
        console.warn "#{getTime!} [dataLoad] #warning, it seems to be corrupted! making a backup to '#name_' and continuing with default value", err
        #localStorage[name_]=localStorage[name]
        localforage.setItem name_, data
        p0ne.autosave[name] = defaultVal
        callback new TypeError("data corrupted (#errorCode)"), defaultVal

window.dataLoadAll = (defaults, callback/*(err, data)*/) !->
    /*defaults is to be in the format `{name: defaultVal, name2: defaultVal2, …}` where `name` is the name of the data to load */
    remaining = 0; for name of defaults then remaining++
    if remaining == 0
        callback(null, {})
    else
        errors = {}; hasError = false
        res = {}
        for let name, defaultVal of defaults
            dataLoad name, defaultVal, (err, data) !->
                if err
                    hasError := true
                    errors[name] = err
                res[name] = data
                if --remaining == 0
                    errors := null if not hasError
                    callback(errors, res)

window.dataUnload = (name) !->
    if p0ne.autosave_num[name]
        p0ne.autosave_num[name]--
    if p0ne.autosave_num[name] == 0
        delete p0ne.autosave[name]

$window .off \beforeunload, window.dataSave if window.dataSave
window.dataSave = !->
    err = ""
    for k,v of p0ne.autosave when v
        for _ of v # check if `v` is not an empty object
            try
                localforage.setItem k, v #compress(v.toJSON?! || JSON.stringify(v))
            catch
                err += "failed to store '#k' to localStorage\n"
            break
    if err
        alert err
    else
        console.log "[Data Manager] saved data"
$window .on \beforeunload, dataSave
dataSave.interval = setInterval dataSave, 15.min



/*####################################
#            DATA EMITTER            #
####################################*/
# a mix between a Promise and an EventEmitter
# initially, its data (`_data`) is not set (think of a Promise's state being "pending").
# Event listeners can be attached with `.on(type, fn, ctx?)` or the shorthands `.data(fn, ctx?)` and `.cleared(fn, ctx?)`.
# Everytime its data is set (using `.set(data)`) all "data" event listeners are executed with the data (similar to resolving a Promise),
# except if `.set(newData)` is called with the same data as already present (`oldData === newData`), then no event listener is executed.
# While its data is set, newly attached "data" handlers are immediately called with the data. (similar to resolved Promises)
# Unlike Promises' state, the data is not immutable, it can be changed again (using `.set(newData)` again).
# The data can be cleared (using `.clear()`), and if data was set before, all "cleared" event listeners are executed with `undefined`
# With event listeners attached with `.on("all", fn, ctx?)` will be executed on all "data" and "cleared" events.
# Note:
#   - The data can be set to another without clearing it first
#   - "cleared" event listeners will NOT be immediately triggered
#   - If you want to read the data from outside an event listener, use `._data`
#     Remember that `.data` is a shorthand for `.on("data", fn, ctx?)`!
#   - A DataEmitter can theoretically also have other events than "data" and "cleared".
#     Please keep in mind, that other scripts might not expect "all" to be triggered by other events
#
# An example for a DataEmitter is the roomSettings module with the data being the room's p3-compatible room settings (if any).
# The roomTheme module applies the room theme everytime the room's settings are loaded (e.g. after joining a room with them),
# so roomSettings is regarded like a Promise, waiting for when the data is loaded.
# If however the room settings are already loaded, the callback should be immediately executed.
# But if another room is joined (or the room's settings change), it should be executed again.
#
# To create a plug_p0ne module as a DataEmitter, use `module(moduleName, { module: new DataEmitter(moduleName), … })`
export class DataEmitter extends {prototype: Backbone.Events}
    (@_name) !->
    _name: 'unnamed DataEmitter'
    set: (newData) !->
        if @_data != newData
            @_data = newData
            @trigger \data, @_data
        return this
    clear: !->
        delete @_data
        @trigger \cleared
        return this

    on: (type, fn, context) !->
        super ...
        # immediately execute "data" and "all" events
        if @_data and type in <[ data all ]>
            try
                fn .call context||this, @_data
            catch e
                console.error "[#{@_name}] Error while triggering #type [#{@_listeners[type].length - 1}]", this, args, e.messageAndStack
        return this
    # shorthands
    data: (fn, context) !-> return @on \data, fn, context
    cleared: (fn, context) !-> return @on \cleared, fn, context

/*####################################
#         GENERAL AUXILIARIES        #
####################################*/
$dummy = $ \<a>
window <<<<
    YT_REGEX: /https?:\/\/(?:www\.)?(?:youtube(?:-nocookie)?\.com\/(?:[^\/]+\/.+\/|(?:v|embed|e)\/|.*(?:\?|&amp;)v=)|youtu\.be\/)([^"&?\/<>\s]{11})(?:&.*?|#.*?|)$/i
    repeat: (timeout, fn) !-> return setInterval (!-> fn ... if not disabled), timeout
    sleep: (timeout, fn) !-> return setTimeout fn, timeout
    throttle: (timeout, fn) !-> return _.throttle fn, timeout
    pad: (num, digits) !->
        if digits
            return "#num" if not isFinite num
            a = ~~num
            b = "#{num - a}"
            num = "#a"
            while num.length < digits
                num = "0#num"
            return "#num#{b .substr 1}"
        else
            return
                if 0 <= num < 10 then "0#num"
                else             then "#num"

    generateID: !-> return (~~(Math.random!*0xFFFFFF)) .toString(16).toUpperCase!



    getUser: (user) !->
        return if not user
        if typeof user == \object
            return that if user.id and getUser(user.id)
            if user.username
                return user
            else if user.attributes and user.toJSON
                return user.toJSON!
            else if user.username || user.dj || user.user || user.uid
                return getUser(that)
            return null
        userList = API.getUsers!
        if +user
            if users?.get? user
                return that .toJSON!
            else
                for u in userList when u.id == user
                    return u
        else if typeof user == \string
            for u in userList when u.username == user
                return u
            user .= toLowerCase!
            for u in userList when u.username .toLowerCase! == user
                return u
        else
            console.warn "unknown user format", user
    getUserInternal: (user) !->
        return if not user or not users
        if typeof user == \object
            return that if user.id and getUserInternal(user.id)
            if user.attributes
                return user
            else if user.username || user.dj || user.user || user.id
                return getUserInternal(that)
            return null

        if +user
            return users.get user
        else if typeof user == \string
            for u in users.models when u.get(\username) == user
                return u
            user .= toLowerCase!
            for u in users.models when u.get(\username) .toLowerCase! == user
                return u
        else
            console.warn "unknown user format", user

    logger: (loggerName, fn) !->
        if typeof fn == \function
            return !->
                console.log "[#loggerName]", arguments
                return fn ...
        else
            return !-> console.log "[#loggerName]", arguments

    replace: (context, attribute, cb) !->
        context["#{attribute}_"] ||= context[attribute]
        context[attribute] = cb(context["#{attribute}_"])

    loadScript: (loadedEvent, data, file, callback) !->
        d = $.Deferred!
        d.then callback if callback

        if data
            d.resolve!
        else
            $.getScript "#{p0ne.host}/#file"
            $ window .one loadedEvent, d.resolve #Note: .resolve() is always bound to the Deferred
        return d.promise!

    requireHelper: (name, test, {id, onfail, fallback}=0) !->
        if (module = window[name] || require.s.contexts._.defined[id]) and test module
            id = module.requireID
            res = module
        else if (id = requireIDs[name]) and (module = require.s.contexts._.defined[id]) and test module
            res = module
        else
            for id, module of require.s.contexts._.defined when module and test module, id
                console.warn "[requireHelper] module '#name' updated to ID '#id'"
                requireIDs[name] = id
                res = module
                break
        if res
            #p0ne.modules[name] = res
            res.requireID = id
            window[name] = res if name
            return res
        else
            console.error "[requireHelper] could not require '#name'"
            onfail?!
            window[name] = fallback if name
            return fallback
    requireAll: (test) !->
        return [m for id, m of require.s.contexts._.defined when m and test(m, id)]


    /* callback gets called with the arguments cb(errorCode, response, event) */
    floodAPI_counter: 0
    ajax: (type, url, data, cb) !->
        if typeof url != \string
            [url, data, cb] = [type, url, data]
            type = data?.type || \POST
        if typeof data == \function
            success = data; data = null
        else if typeof cb == \function
            success = cb
        else if data and (data.success or data.error)
            {success, error} = data
            delete data.success
            delete data.error
        else if typeof cb == \object
            {success, fail} = cb if cb

        if data
            silent = data.silent
            delete data.type
            delete data.silent
        # data ||= {}
        # data.key = p0ne.PLUG_KEY
        options = do
                type: type
                url: "https://plug.dj/_/#url"
                success: ({data}) !->
                    console.info "[#url]", data if not silent
                    success? data
                error: (err) !->
                    console.error "[#url]", data if not silent
                    error? data
        data = JSON.stringify(data)
        if data != "{}" and type not in <[ GET get ]>
            options.contentType = \application/json
            options.data = data

        def = $.Deferred!
        do delay = !->
            if window.floodAPI_counter >= 15 /* 20 requests in 10s will trigger socket:floodAPI. This should leave us enough buffer in any case */
                sleep 1_000ms, delay
            else
                window.floodAPI_counter++; sleep 10_000ms, !-> window.floodAPI_counter--
                req = $.ajax options
                    .then def.resolve, def.reject, def.progress
                def.abort = req.abort
        return def

    befriend: (userID, cb) !-> ajax \POST, "friends", id: userID, cb
    ban: (userID, cb) !-> ajax \POST, "bans/add", userID: userID, duration: API.BAN.HOUR, reason: 1, cb
    banPerma: (userID, cb) !-> ajax \POST, "bans/add", userID: userID, duration: API.BAN.PERMA, reason: 1, cb
    unban: (userID, cb) !-> ajax \DELETE, "bans/#userID", cb
    modMute: (userID, cb) !-> ajax \POST, "mutes/add", userID: userID, duration: API.MUTE.SHORT, reason: 1, cb
    modUnmute: (userID, cb) !-> ajax \DELETE, "mutes/#userID", cb
    chatDelete: (chatID, cb) !-> ajax \DELETE, "chat/#chatID", cb
    kick: (userID, cb) !->
        def = $.Deferred!
        ban userID
            .then !->
                unban userID, cb
                    .then def.resolve, def.reject
            .fail def.reject
    addDJ: (userID, cb) !->
        for u in API.getWaitList! when u.id == userID
            # specified user is in the waitlist
            cb \alreadyInWaitlist
            return $.Deferred! .resolve \alreadyInWaitlist
        else
            return ajax \POST, "booth/add", id: userID, cb
    moveDJ: (userID, position, cb) !->
        def = $.Deferred
        addDJ userID
            .then !->
                ajax \POST, "booth/move", userID: userID, position: position, cb
                    .then def.resolve, def.reject
            .fail def.reject
        return def .promise!

    joinRoom: (slug) !->
        return ajax \POST, \rooms/join, {slug}

    getUserData: (user, cb) !->
        if typeof user != \number
            user = getUser user
        return $.get "/_/users/#user"
            .then ({[data]:data}:arg) !->
                if cb
                    return data
                else
                    console.log "[userdata]", data, (if data.level >= 5 then "https://plug.dj/@/#{encodeURI data.slug}")
            .fail !->
                console.warn "couldn't get userdata for user with id '#{id}'"

    $djButton: $ \#dj-button
    mute: !->
        return $ '#volume .icon-volume-half, #volume .icon-volume-on' .click! .length
    muteonce: !->
        mute!
        muteonce.last = API.getMedia!.id
        API.once \advance, !->
            unmute! if API.getMedia!.id != muteonce.last
    unmute: !->
        return $ '#playback .snoozed .refresh, #volume .icon-volume-off, #volume .icon-volume-mute-once' .click! .length
    snooze: !->
        return $ '#playback .snooze' .click! .length
    isSnoozed: !-> return $ \#playback-container .children! .length == 0
    refresh: !->
        return $ '#playback .refresh' .click! .length
    stream: (val) !->
        if not currentMedia
            console.error "[p0ne /stream] cannot change stream - failed to require() the module 'currentMedia'"
        else
            return database?.settings.streamDisabled = (val != true and (val == false or currentMedia.get(\streamDisabled)))
    join: !->
        # for this, performance might be essential
        # return $ '#dj-button.is-wait' .click! .length != 0
        if $djButton.hasClass \is-wait
            $djButton.click!
            return true
        else
            return false
    forceJoin: !->
        ajax \POST, \booth
    leave: !->
        return $ '#dj-button.is-leave' .click! .length != 0

    $wootBtn: $ \#woot
    woot: !-> $wootBtn .click!
    $mehBtn: $ \#meh
    meh: !-> $mehBtn .click!

    ytItags: do !->
        resolutions = [ 72p, 144p, 240p,  360p, 480p, 720p, 1080p, 1440p, 2160p, 2304p, 3072p, 4320p ]
        list =
            # DASH-only content is commented out, as it is not yet required
            * ext: \flv, minRes: 240p, itags: <[ 5 ]>
            * ext: \3gp, minRes: 144p, itags:  <[ 17 36 ]>
            * ext: \mp4, minRes: 240p, itags:  <[ 83 18,82 _ 22,84 85 ]>
            #* ext: \mp4, minRes: 144p, itags:  <[ 160 133 134 135 136 137 264 138 ]>, type: \video-only
            #* ext: \mp4, minRes: 720p, itags:  <[ 298 299 ]>, fps: 60, type: \video-only
            #* ext: \mp4, minRes: 128kbps, itags:  <[ 140 ]>, type: \audio
            * ext: \webm, minRes: 360p, itags:  <[ 43,100 ]>
            #* ext: \webm, minRes: 240p, itags:  <[ 242 243 244 247 248 271 272 ]>, type: \video-only
            #* ext: \webm, minRes: 720p, itags:  <[ 302 303 ]>, fps: 60, type: \video-only
            #* ext: \webm, minRes: 144p, itags:  <[ 278 ]>, type: \video-only
            #* ext: \webm, minRes: 128kbps, itags:  <[ 171 ]>, type: \audio
            * ext: \ts, minRes: 240p, itags:  <[ 151 132,92 93 94 95 96 ]> # used for live streaming
        ytItags = {}
        for format in list
            for itags, i in format.itags when itags != \_
                # formats with type: \audio not taken into account ignored here
                startI = resolutions.indexOf format.minRes
                for itag in itags.split ","
                    if resolutions[startI + i] == 2304p
                        console.log itag
                    ytItags[itag] =
                        itag: itag
                        ext: format.ext
                        type: format.type || \video
                        resolution: resolutions[startI + i]
        return ytItags

    mediaSearch: (query) !->
        # open playlist drawer
        $ '#playlist-button .icon-playlist'
            .click! # will silently fail if playlist is already open, which is desired

        $ \#search-input-field
            .val query # enter search string
            .trigger do # start search
                type: \keyup
                which: 13 # Enter

    mediaParse: (media, cb) !->
        /* work in progress */
        cb ||= logger \
        if typeof media == \string
            if +media # assume SoundCloud CID
                cb {format: 2, cid: media}
            else if media.length == 11 # assume youtube CID
                cb {format: 1, cid: media}
            else if cid = YT_REGEX .exec(media)?.1
                cb {format: 1, cid}
            else if parseURL media .hostname in <[ soundcloud.com  i1.sndcdn.com ]>
                $.getJSON "https://api.soundcloud.com/resolve/", do
                    url: url
                    client_id: p0ne.SOUNDCLOUD_KEY
                    .then (d) !->
                        cb {format: 2, cid: d.id, data: d}
        else if typeof media == \object and media
            if media.toJSON
                cb media.toJSON!
            else if media.format
                cb media
        else if not media
            cb API.getMedia!
        cb!

    mediaLookupCache: {}
    mediaLookup: (songs, cb) !->
        if typeof cb == \function
            success = cb
        else
            if typeof cb == \object
                {success, fail} = cb if cb
            success ||= (data) !-> console.info "[mediaLookup] #{<[yt sc]>[format - 1]}:#cid", data
        fail ||= (err) !-> console.error "[mediaLookup] couldn't look up", cid, url, cb, err
        def = $.Deferred()
        def.then(success, fail)

        if not (isArray = $.isArray songs)
            songs = [songs]

        res = []; l=0
        duplicates = {}
        queries = 1: {}, 2: {}
        for media, i in songs
            format = false
            # only CID is given
            if +media # SoundCloud ID
                #note: this could also be a plug.dj ID, which is bad, as we can't parse that
                console.warn "[mediaLookup] warning, media only described by an ID, assuming SoundCloud ID. It is recommended to use {format: 2, cid: id} instead"
                format = 2; cid = +media
            else if typeof media == \string
                if media.length == 11 # Youtube ID
                    format = 1; cid = media

                # URL is given
                else if cid = YT_REGEX .exec(media)?.1 # Youtube URL
                    format = 1 #; cid = cid
                else if media.has \.com and parseURL media .hostname in <[ soundcloud.com  i1.sndcdn.com ]> # SoundCloud URL
                    format = 2; cid = media

            # Media Object is given
            else if typeof media == \object and media and media.cid
                if media.format == 1 or media.format == 2 # Youtube or SoundCloud
                    {format, cid} = media

            if not format
                console.warn "[mediaLookup] unknown format", media, "as ##i in", songs
                l++
                continue

            if cid of queries[format] # if already in a query
                console.log "[mediaLookup] #format : #cid appears multiple times in the same query"
                duplicates[l++] = queries[format][cid]

            else if window.mediaLookupCache[cid] # if already in cache
                console.log "[mediaLookup] #format : #cid fetched from cache"
                res[l] = window.mediaLookupCache[cid]
                clearTimeout res[l]._timeoutID
                res[l]._timeoutID = sleep 5.min, ->
                    delete window.mediaLookupCache[cid]
                l++

            else # otherwise add to query
                console.log "[mediaLookup] #format : #cid adding to query [#l]"
                queries[format][cid] = l++

        console.log "[mediaLookup] queries:", queries
        remaining = 0
        ytCids_ = Object.keys(queries.1)
        if ytCids_.length # Youtube (API v3)
            remaining += ytCids_.length
            if ytCids_.length > 50
                packs = []
                for i from 0 to ~~(ytCids_.length/50)
                    packs[i] = []
                for id, i in ytCids_
                    packs[~~(i / 50)][i % 50] = id
            else
                packs = [ytCids_]
            for ytCids in packs
                $.getJSON "https://www.googleapis.com/youtube/v3/videos
                    ?part=contentDetails,snippet
                    &fields=items(id,contentDetails/duration,contentDetails/regionRestriction,snippet/channelId,snippet/channelTitle,snippet/description,snippet/publishedAt,snippet/title)
                    &id=#{ytCids .join(',')}
                    &key=#{p0ne.YOUTUBE_V3_KEY}"
                    .fail fail
                    .success ({items}) !->
                        for d in items
                            duration = 0
                            if /PT(\d+)M(\d+)S/.exec d.contentDetails.duration
                                duration = +that.1 * 60 + +that.2
                            addResult queries.1[d.id], d.id, do
                                    format:       1
                                    data:         d
                                    cid:          d.id
                                    uploader:
                                        name:     d.snippet.channelTitle
                                        id:       d.snippet.channelId
                                        url:      "https://www.youtube.com/channel/#{d.snippet.channelId}"
                                    image:        "https://i.ytimg.com/vi/#{d.id}/0.jpg"
                                    title:        d.snippet.title
                                    uploadDate:   d.snippet.publishedAt
                                    url:          "https://youtube.com/watch?v=#{d.id}"
                                    description:  d.snippet.description
                                    duration:     duration # in s
                                    restriction:  d.contentDetails.regionRestriction
                                    _timeoutID: sleep 5.min, ->
                                        delete window.mediaLookupCache[d.id]

                        # add not-found results
                        for cid, l of queries.1 when not res[l]
                            console.warn "[mediaLookup] failed to look up Youtube video ##l", cid
                            addResult l, cid, do
                                _timeoutID: sleep 5.min, ->
                                    delete window.mediaLookupCache[cid]
                        doneLoading!


        for let cid, pos of queries.2
            remaining++
            if +cid
                req = $.getJSON "https://api.soundcloud.com/tracks/#cid.json", do
                    client_id: p0ne.SOUNDCLOUD_KEY
            else
                req = $.getJSON "https://api.soundcloud.com/resolve/", do
                    url: cid
                    client_id: p0ne.SOUNDCLOUD_KEY
            req
                .fail ->
                    console.warn "[mediaLookup] failed to look up soundcloud song", cid
                    addResult pos, cid, do
                        _timeoutID: sleep 5.min, ->
                            delete window.mediaLookupCache[cid]
                    doneLoading!
                .success (d) !->
                    addResult pos, d.id, data =
                        format:         2
                        data:           d
                        cid:            d.id
                        uploader:
                            id:         d.user.id
                            name:       d.user.username
                            image:      d.user.avatar_url
                            url:        d.user.permalink_url
                        image:          d.artwork_url
                        title:          d.title
                        uploadDate:     d.created_at
                        url:            d.permalink_url
                        description:    d.description
                        duration:       d.duration / 1000ms_to_s # in s

                        download:       if d.download_url then "#{d.download_url}?client_id=#{p0ne.SOUNDCLOUD_KEY}" else false
                        downloadSize:   d.original_content_size
                        downloadFormat: d.original_format

                    if typeof cid == \number
                        data._timeoutID = sleep 5.min, ->
                            delete window.mediaLookupCache[cid]
                    else
                        window.mediaLookupCache[data.cid] = data
                        data._timeoutID = sleep 5.min, ->
                            delete window.mediaLookupCache[data.cid]
                            delete window.mediaLookupCache[cid]
                    doneLoading!

        doneLoading!

        function addResult pos, cid, data
            console.log "[mediaLookup] looked up ##pos", cid, data
            window.mediaLookupCache[cid] = data
            res[pos] = data
            remaining--

        function doneLoading
            if remaining <= 0
                console.log "[mediaLookup] done, resolving…"
                if not isArray
                    res := res.0
                else
                    for k,v of duplicates
                        res[k] = res[v]
                def.resolve res

        return def.promise!

    # https://www.youtube.com/annotations_invideo?video_id=gkp9ohUPIuo
    # AD,AE,AF,AG,AI,AL,AM,AO,AQ,AR,AS,AT,AU,AW,AX,AZ,BA,BB,BD,BE,BF,BG,BH,BI,BJ,BL,BM,BN,BO,BQ,BR,BS,BT,BV,BW,BY,BZ,CA,CC,CD,CF,CG,CH,CI,CK,CL,CM,CN,CO,CR,CU,CV,CW,CX,CY,CZ,DE,DJ,DK,DM,DO,DZ,EC,EE,EG,EH,ER,ES,ET,FI,FJ,FK,FM,FO,FR,GA,GB,GD,GE,GF,GG,GH,GI,GL,GM,GN,GP,GQ,GR,GS,GT,GU,GW,GY,HK,HM,HN,HR,HT,HU,ID,IE,IL,IM,IN,IO,IQ,IR,IS,IT,JE,JM,JO,JP,KE,KG,KH,KI,KM,KN,KP,KR,KW,KY,KZ,LA,LB,LC,LI,LK,LR,LS,LT,LU,LV,LY,MA,MC,MD,ME,MF,MG,MH,MK,ML,MM,MN,MO,MP,MQ,MR,MS,MT,MU,MV,MW,MX,MY,MZ,NA,NC,NE,NF,NG,NI,NL,NO,NP,NR,NU,NZ,OM,PA,PE,PF,PG,PH,PK,PL,PM,PN,PR,PS,PT,PW,PY,QA,RE,RO,RS,RU,RW,SA,SB,SC,SD,SE,SG,SH,SI,SJ,SK,SL,SM,SN,SO,SR,SS,ST,SV,SX,SY,SZ,TC,TD,TF,TG,TH,TJ,TK,TL,TM,TN,TO,TR,TT,TV,TW,TZ,UA,UG,UM,US,UY,UZ,VA,VC,VE,VG,VI,VN,VU,WF,WS,YE,YT,ZA,ZM,ZW
    mediaDownload: do !->
        regexNormal = {}; regexUnblocked = {}
        for key in <[ title url_encoded_fmt_stream_map fmt_list dashmpd errorcode reason ]>
            regexNormal[key] = //#key=(.*?)(?:&|$)//
            regexUnblocked[key] = //"#key":"(.*?)"//
        for key in <[ url itag type fallback_host ]>
            regexNormal[key] = //#key=(.*?)(?:&|$)//
            regexUnblocked[key] = //#key=(.*?)(?:\\u0026|$)//
        return (media, audioOnly, cb) !->
            /* status codes:
                = success = (resolved)
                0 - downloads found

                = error = (rejected)
                1 - failed to receive video info
                2 - video info loaded, but no downloads found (video likely blocked)
                3 - (for audioOnly) dash.mpd found, but no downloads (basically like 2)

                note: itags are Youtube's code describing the data format
                    https://en.wikipedia.org/wiki/YouTube#Quality_and_formats
                    (click [show] in "Comparison of YouTube media encoding options" to see the whole table)
             */
            # arguments parsing
            if not media or typeof media == \boolean or typeof media == \function or media.success or media.error # if `media` is left out
                [media, audioOnly, cb] = [false, media, cb]
            else if typeof audioOnly != \boolean # if audioOnly is left out
                cb = audioOnly; audioOnly = false

            # parsing cb
            if typeof cb == \function
                success = cb
            else if cb
                {success, error} = cb

            # defaulting arguments
            if media?.attributes
                blocked = media.blocked
                media .= attributes
            else if not media
                media = API.getMedia!
                blocked = 0
            else
                blocked = media.blocked
            {format, cid, id} = media
            media.blocked = blocked = +blocked || 0


            if format == 2
                audioOnly = true


            res =  $.Deferred()
            res
                .then (data) !->
                    data.blocked = blocked
                    if audioOnly
                        return media.downloadAudio = data
                    else
                        return media.download = data
                .fail (err, status) !->
                    if status
                        err =
                            status: 1
                            message: "network error or request rejected"
                    err.blocked = blocked
                    if audioOnly
                        return media.downloadAudioError = err
                    else
                        return media.downloadError = err
                .then success || logger \mediaDownload
                .fail error || logger \mediaDownloadError

            if audioOnly
                return res.resolve media.downloadAudio if media.downloadAudio?.blocked == blocked
                return res.reject media.downloadAudioError if media.downloadAudioError
            else
                return res.resolve media.download if media.download
                return res.reject media.downloadError if media.downloadError?.blocked == blocked

            cid ||= id
            if format == 1 # youtube
                if blocked == 2
                    url = p0ne.proxy "http://vimow.com/watch?v=#cid"
                else if blocked
                    url = p0ne.proxy "https://www.youtube.com/watch?v=#cid"
                else
                    url = p0ne.proxy "https://www.youtube.com/get_video_info?video_id=#cid"
                console.info "[mediaDownload] YT lookup", url
                $.ajax do
                    url: url
                    error: res.reject
                    success: (d) !-> /* see parseYTGetVideoInfo in p0ne.dev for a proper parser of the data */
                        export d
                        file = d # for get()
                        files = {}
                        bestVideo = null
                        bestVideoSize = 0

                        if blocked == 2
                            # getting video proxy URL using vimow.com
                            if d.match /<title>(.*?) - vimow<\/title>/
                                title = htmlUnescape that.1
                            else
                                title = cid
                            files = {}
                            for file in d.match(/<source .*?>/g) ||[]
                                src = /src='(.*?)'/.exec(file)
                                resolution = /src='(.*?)'/.exec(file)
                                mimeType = /src='(\w+\/(\w+))'/.exec(file)
                                if src and resolution and mimeType
                                    (files[that.5] ||= [])[*] = video =
                                        url: src.1
                                        resolution: resolution.1
                                        mimeType: mimeType.1
                                        file: "basename.#{mimeType.2}"
                                    if that.2 > bestVideoSize
                                        bestVideo = video
                                        bestVideoSize = video.resolution

                            if bestVideo
                                files.preferredDownload = bestVideo
                                files.status = 0
                                console.log "[mediaDownload] resolving", files
                                res.resolve files
                            else
                                console.warn "[mediaDownload] vimow.com loaded, but no downloads found"
                                res.reject do
                                    status: 2
                                    message: 'no downloads found'
                            return


                        else if blocked
                            get = (key) !->
                                val = (file || d).match regexUnblocked[key]
                                if key in <[ url itag type fallback_host ]>
                                    return decodeURIComponent val.1
                                return val.1 if val
                            basename = get(\title) || cid
                        else
                            get = (key, unescape) !->
                                val = file.match regexNormal[key]
                                # "+" are not unescaped by default, as they only appear in the title and verticals
                                if val
                                    val = val.1 .replace(/\++/g, ' ') if unescape
                                    return decodeURIComponent val.1
                            basename = get(\title, true) || cid

                            if error = get \errorcode
                                reason = get(\reason, true)
                                switch +error
                                | 150 =>
                                    console.error "[mediaDownload] video_info error 150! Embedding not allowed on some websites"
                                | otherwise =>
                                    console.error "[mediaDownload] video_info error #error! unkown error code", reason

                        if not audioOnly
                            fmt_list_ = get \fmt_list
                            if get \url_encoded_fmt_stream_map
                                for file in that .split ","
                                    #file = unescape(file).replace(/\\u0026/g, '&')
                                    url = get \url
                                    fallback_host = unescape(that.1) if file.match(/fallback_host=(.*?)(?:\\u0026|$)/)
                                    itag = get \itag
                                    if ytItags[itag]
                                        format = that
                                    else
                                        if not fmt_list
                                            fmt_list = {}
                                            if fmt_list_
                                                for e in fmt_list_.split ','
                                                    e .= split '/'
                                                    fmt_list[e.0] = e.1 .split 'x' .1
                                            else
                                                console.warn "[mediaDownload] no fmt_list found"
                                        if fmt_list[itag] and get \type
                                            format =
                                                itag: itag
                                                type: that.1
                                                ext: that.2
                                                resolution: fmt_list[itag]
                                            console.warn "[mediaDownload] unknown itag found, found in fmt_list", itag
                                    if format
                                        original_url = url
                                        url = url
                                            .replace /^.*?googlevideo\.com/, do
                                                "https://#fallback_host" # hack to bypass restrictions
                                                    #.replace 'googlevideo.com', 'c.docs.google.com' # hack to allow HTTPS
                                        #url .= replace('googlevideo.com', 'c.docs.google.com') # supposedly unblocks some videos
                                        (files[format.ext] ||= [])[*] = video =
                                            file: "#basename.#{format.ext}"
                                            url: url
                                            original_url: original_url
                                            fallback_host: fallback_host
                                            #fallback_url: original_url.replace('googlevideo.com', fallback_host)
                                            mimeType: "#{format.type}/#{format.ext}"
                                            resolution: format.resolution
                                            itag: format.itag
                                        if format.resolution > bestVideoSize
                                            bestVideo = video
                                            bestVideoSize = video.resolution
                                    else
                                        console.warn "[mediaDownload] unknown itag found, not in fmt_list", itag

                            if bestVideo
                                files.preferredDownload = bestVideo
                                files.status = 0
                                console.log "[mediaDownload] resolving", files
                                res.resolve files
                            else
                                console.warn "[mediaDownload] no downloads found"
                                res.reject do
                                    status: 2
                                    message: 'no downloads found'

                        # audioOnly
                        else
                            if blocked and d.match(/"dashmpd":"(.*?)"/)
                                url = p0ne.proxy(that.1 .replace(/\\\//g, '/'))
                            else if d.match(/dashmpd=(http.+?)(?:&|$)/)
                                url = p0ne.proxy(unescape that.1 /*parse(d).dashmpd*/)

                            if url
                                console.info "[mediaDownload] DASHMPD lookup", url
                                $.get url
                                    .then (dashmpd) !->
                                        export dashmpd
                                        $dash = dashmpd |> $.parseXML |> jQuery
                                        bestVideo = size: 0
                                        $dash .find \AdaptationSet .each !->
                                            $set = $ this
                                            mimeType = $set .attr \mimeType
                                            type = mimeType.substr(0,5) # => \audio or \video
                                            return if type != \audio #and audioOnly
                                            if mimeType == \audio/mp4
                                                ext = \m4a # audio-only .mp4 files are commonly saved as .m4a
                                            else
                                                ext = mimeType.substr 6
                                            files[mimeType] = []; l=0
                                            $set .find \BaseURL .each !->
                                                $baseurl = $ this
                                                $representation = $baseurl .parent!
                                                #height = $representation .attr \height
                                                files[mimeType][l++] = m =
                                                    file: "#basename.#ext"
                                                    url: httpsify $baseurl.text!
                                                    mimeType: mimeType
                                                    size: $baseurl.attr(\yt:contentLength) / 1_000_000B_to_MB
                                                    samplingRate: "#{$representation .attr \audioSamplingRate}Hz"
                                                    #height: height
                                                    #width: height && $representation .attr \width
                                                    #resolution: height && "#{height}p"
                                                if audioOnly and ~~m.size > ~~bestVideo.size and (window.chrome or mimeType != \audio/webm)
                                                    bestVideo := m
                                        if bestVideo
                                            files.preferredDownload = bestVideo
                                            files.status = 0
                                            console.log "[mediaDownload] resolving", files
                                            res.resolve files
                                        else
                                            console.warn "[mediaDownload] dash.mpd found, but no downloads"
                                            res.reject do
                                                status: 3
                                                message: 'dash.mpd found, but no downloads'

                                        /*
                                        html = ""
                                        for mimeType, files of res
                                            html += "<h3 class=AdaptationSet>#mimeType</h3>"
                                            for f in files
                                                html += "<a href='#{$baseurl.text!}' download='#file' class='download"
                                                html += " preferred-download" if f.preferredDownload
                                                html += "'>#file</a> (#size; #{f.samplingRate || f.resolution})<br>"
                                        */
                                    .fail res.reject
                            else
                                console.error "[mediaDownload] no download found"
                                res.reject "no download found"
                            #window.open(htmlUnescape(/.+>(http.+?)<\/BaseURL>/i.exec(d)[1]))
            else if format == 2 # soundcloud
                audioOnly = true
                mediaLookup media
                    .then (d) !->
                        if d.download
                            res.resolve media.downloadAudio =
                                (d.downloadFormat):
                                    url: d.download
                                    size: d.downloadSize
                        else
                            res.reject "download disabled"
                    .fail res.reject
            else
                console.error "[mediaDownload] unknown format", media
                res.reject "unknown format"

            return res.promise!

    createPlaylist: (name, media) !->
        if not window.playlists
            throw new Error "createPlaylist(name, media) requires `window.playlists`"
        ajax \POST, \playlists, {name, media}
            .then (pl) !->
                playlists.push new Backbone.Model(pl.data.0)
                playlists.sort!
                console.log "added playlist #name [#{pl.id}]"
            .fail (err) !->
                console.error "failed to add playlist #name", err
    proxify: (url) !->
        if url.startsWith?("http:")
            return p0ne.proxy url
        else
            return url
    httpsify: (url) !->
        if url.startsWith?("http:")
            return "https://#{url.substr 7}"
        else
            return url

    getChatText: (cid) !->
        if not cid
            return $!
        else
            res = $cms! .find ".text.cid-#cid"
            return res
    getChat: (cid) !->
        if typeof cid == \object
            return cid.$el ||= getChat(cid.cid)
        else
            return getChatText cid .parent! .parent!
    isMention: (msg, nameMentionOnly) !->
        user = API.getUser!
        return msg.isMentionName ?= msg.message.has("@#{user.rawun}") if nameMentionOnly
        fromUser = msg.from ||= getUser(msg) ||{}
        return msg.isMention ?=
            msg.message.has("@#{user.rawun}")
            or fromUser.id != userID and do
                    (fromUser.gRole or fromUser.role >= 4) and msg.message.has("@everyone") # @everyone is co-host+
                    or (fromUser.gRole or fromUser.role >= 2) and do # all other special mentions are bouncer+
                        user.role > 1 and do # if the user is staff
                            msg.message.has("@staff")
                            or user.role == 1 and msg.message.has("@rdjs")
                            or user.role == 2 and msg.message.has("@bouncers")
                            or user.role == 3 and msg.message.has("@managers")
                            or user.role == 4 and msg.message.has("@hosts")
                        or msg.message.has("@djs") and API.getWaitListPosition! != -1 # if the user is in the waitlist
        /*
        // for those of you looking at the compiled Javascript, have some readable code:
        return (ref$ = msg.isMention) != null ? ref$ : msg.isMention =
            msg.message.has("@" + user.rawun)
            || fromUser.id !== userID && (
                (fromUser.gRole || fromUser.role >= 4) && msg.message.has("@everyone") // @everyone is co-host+
                || (fromUser.gRole || fromUser.role >= 2) && ( // all other special mentions are bouncer+
                    user.role > 1 && ( // if the user is staff
                        msg.message.has("@staff")
                        || user.role === 1 && msg.message.has("@rdjs")
                        || user.role === 2 && msg.message.has("@bouncers")
                        || user.role === 3 && msg.message.has("@managers")
                        || user.role === 4 && msg.message.has("@hosts")
                    ) || msg.message.has("@djs") && API.getWaitListPosition() !== -1 // if the user is in the waitlist
                )
            );
         */
    getMentions: (data, safeOffsets) !->
        if safeOffsets
            attr = \mentionsWithOffsets
        else
            attr = \mentions
        return that if data[attr]
        # cache properties
        roles = {everyone: 0, djs: 0, rdjs: 1, staff: 2, bouncers: 2, managers: 3, hosts: 4}
        users = API.getUsers!; msgLength = data.message.length

        checkGeneric ||= getUser(data)
        checkGeneric &&= if checkGeneric.gRole then 5 else checkGeneric.role

        # find all @mentions
        var user
        mentions = []; l=0
        data.message.replace /@/g, (_, offset) !->
            offset++
            possibleMatches = users
            i = 0

            # check for generic @mentions, such as @everyone
            if checkGeneric >= 3
                str = data.message.substr(offset, 8)
                for k, v of roles when str.startsWith k and (k != \everyone or checkGeneric >= 4)
                    genericMatch = {rawun: k, username: k, role: v, id: 0}
                    break

            # filter out the best matching name (e.g. "@foobar" would find @foo if @fo, @foo and @fooo are in the room)
            while possibleMatches.length and i < msgLength
                possibleMatches2 = []; l2 = 0
                for m in possibleMatches when m.rawun[i] == data.message[offset + i]
                    if m.rawun.length == i + 1
                        res = m
                    else
                        possibleMatches2[l2++] = m
                possibleMatches = possibleMatches2
                i++
            if res ||= genericMatch
                if safeOffsets
                    mentions[l++] = res with offset: offset - 1
                else if not mentions.has(res)
                    mentions[l++] = res

        mentions = [getUser(data)] if not mentions.length and not safeOffsets
        mentions.toString = !->
            res = ["@#{user.rawun}" for user in this]
            return humanList res # both lines seperate for performance optimization
        data[attr] = mentions
        return mentions

    isMessageVisible: ($msg) !->
        if typeof msg == \string
            $msg = getChat($msg)
        if $msg?.length
            return $cm!.height! > $msg .offset!.top > 101px
        else
            return false

    escapeRegExp: (str) ->
        return "#str".replace /[\\\.\+\*\?\[\^\]\$\(\)\{\}\=\!\<\>\|\:]/g, "\\$&"


    htmlEscapeMap: {sp: 32, blank: 32, excl: 33, quot: 34, num: 35, dollar: 36, percnt: 37, amp: 38, apos: 39, lpar: 40, rpar: 41, ast: 42, plus: 43, comma: 44, hyphen: 45, dash: 45, period: 46, sol: 47, colon: 58, semi: 59, lt: 60, equals: 61, gt: 62, quest: 63, commat: 64, lsqb: 91, bsol: 92, rsqb: 93, caret: 94, lowbar: 95, lcub: 123, verbar: 124, rcub: 125, tilde: 126, sim: 126, nbsp: 160, iexcl: 161, cent: 162, pound: 163, curren: 164, yen: 165, brkbar: 166, sect: 167, uml: 168, die: 168, copy: 169, ordf: 170, laquo: 171, not: 172, shy: 173, reg: 174, hibar: 175, deg: 176, plusmn: 177, sup2: 178, sup3: 179, acute: 180, micro: 181, para: 182, middot: 183, cedil: 184, sup1: 185, ordm: 186, raquo: 187, frac14: 188, half: 189, frac34: 190, iquest: 191}
    htmlEscape: (str) !->
        return $dummy .text str .html!
        /*
        if not window.htmlEscapeRegexp
            window.htmlEscapeRegexp = []; l=0; window.htmlEscapeMap_reversed = {}
            for k,v of htmlEscapeMap when v != 32 #spaces
                window.htmlEscapeMap_reversed[v] = k
                v .= toString 16
                if v.length <= 2
                    v = "0#v"
                window.htmlEscapeRegexp[l++] = "\\u0#v"
        return str.replace //#{window.htmlEscapeRegexp .join "|"}//g, (c) !-> return "&#{window.htmlEscapeMap_reversed[c.charCodeAt 0]};"
        */

    htmlUnescape: (html) !->
        return html.replace /&(\w+);|&#(\d+);|&#x([a-fA-F0-9]+);/g, (_,a,b,c) !->
            return String.fromCharCode(+b or htmlEscapeMap[a] or parseInt(c, 16)) or _
    stripHTML: (msg) !->
        return msg .replace(/<.*?>/g, '')
    unemojify: (str) !->
        map = window.emoticons?.map
        return str if not map
        return str .replace /(?:<span class="emoji-glow">)?<span class="emoji emoji-(\w+)"><\/span>(?:<\/span>)?/g, (_, emoteID) !->
            if emoticons.reversedMap[emoteID]
                return ":#that:"
            else
                return _

    #== RTL emulator ==
    # str = "abc\u202edef\u202dghi"
    # [str, resolveRTL(str)]
    resolveRTL: (str, dontJoin) !->
        a = b = ""
        isRTLoverridden = false
        "#str\u202d".replace /(.*?)(\u202e|\u202d)/g, (_,pre,c) !->
            if isRTLoverridden
                b += pre.reverse!
            else
                a += pre
            isRTLoverridden := (c == \\u202e)
            return _
        if dontJoin
            return [a,b]
        else
            return a+b

    collapseWhitespace: (str) !->
        return str.replace /\s+/g, ' '
    cleanMessage: (str) !-> return str |> unemojify |> stripHTML |> htmlUnescape |> resolveRTL |> collapseWhitespace

    formatPlainText: (text) !-> # used for song-notif and song-info
        lvl = 0
        text .= replace /([\s\S]*?)($|(?:https?:|www\.)(?:\([^\s\]\)]*\)|\[[^\s\)\]]*\]|[^\s\)\]]+))+([\.\?\!\,])?/g, (,pre,url,post) !->
            pre = pre
                .replace /(\s)(".*?")([\.,!\?\s])/g, "$1<i class='song-description-string'>$2</i>$3"
                .replace /(\s)(\*\w+\*)(\s)/g, "$1<b>$2</b>$3"
                .replace /(lyrics|download|original|re-?upload)/gi, "<b>$1</b>"
                .replace /(\s)(0x)([0-9a-fA-F]+)|(#)([\d\-]+)(\s)/g, "$1<i class='song-description-comment'>$2$4</i><b class='song-description-number'>$3$5</b>$6"
                .replace /(\s)(\d+)(\w*|%|\+)(\s)/g, "$1<b class='song-description-number'>$2</b><i class='song-description-comment'>$3</i>$4"
                .replace /(\s)(\d+)(\s)/g, "$1<b class='song-description-number'>$2</b>$3"
                .replace /^={5,}$/mg, "<hr class='song-description-hr-double' />"
                .replace /^[\-~_]{5,}$/mg, "<hr class='song-description-hr' />"
                .replace /^[\[\-=~_]+.*?[\-=~_\]]+$/mg, "<b class='song-description-heading'>$&</b>"
                .replace /(.?)([\(\)])(.?)/g, (x,a,b,c) !->
                    if "=^".indexOf(x) == -1 or a == ":"
                        return x
                    else if b == \(
                        lvl++
                        return "#a<i class='song-description-comment'>(#c" if lvl == 1
                    else if lvl
                            lvl--
                            return "#a)</i>#c" if lvl == 0
                    return x
            return pre if not url
            return "#pre<a href='#url' target=_blank>#url</a>#{post||''}"
        text += "</i>" if lvl
        return text .replace /\n/g, \<br>


    /*colorKeywords: do !->
        <[ %undefined% black silver gray white maroon red purple fuchsia green lime olive yellow navy blue teal aqua orange aliceblue antiquewhite aquamarine azure beige bisque blanchedalmond blueviolet brown burlywood cadetblue chartreuse chocolate coral cornflowerblue cornsilk crimson darkblue darkcyan darkgoldenrod darkgray darkgreen darkgrey darkkhaki darkmagenta darkolivegreen darkorange darkorchid darkred darksalmon darkseagreen darkslateblue darkslategray darkslategrey darkturquoise darkviolet deeppink deepskyblue dimgray dimgrey dodgerblue firebrick floralwhite forestgreen gainsboro ghostwhite gold goldenrod greenyellow grey honeydew hotpink indianred indigo ivory khaki lavender lavenderblush lawngreen lemonchiffon lightblue lightcoral lightcyan lightgoldenrodyellow lightgray lightgreen lightgrey lightpink lightsalmon lightseagreen lightskyblue lightslategray lightslategrey lightsteelblue lightyellow limegreen linen mediumaquamarine mediumblue mediumorchid mediumpurple mediumseagreen mediumslateblue mediumspringgreen mediumturquoise mediumvioletred midnightblue mintcream mistyrose moccasin navajowhite oldlace olivedrab orangered orchid palegoldenrod palegreen paleturquoise palevioletred papayawhip peachpuff peru pink plum powderblue rosybrown royalblue saddlebrown salmon sandybrown seagreen seashell sienna skyblue slateblue slategray slategrey snow springgreen steelblue tan thistle tomato turquoise violet wheat whitesmoke yellowgreen rebeccapurple ]>
            ..0 = void
            return ..
    isColor: (str) !->
        str = (~~str).toString(16) if typeof str == \number
        return false if typeof str != \string
        str .= trim!
        tmp = /^(?:#(?:[a-fA-F0-9]{6}|[a-fA-F0-9]{3})|(?:rgb|hsl)a?\([\d,]+\)|currentColor|(\w+))$/.exec(str)
        if tmp and tmp.1 in window.colorKeywords
            return str
        else
            return false*/
    isColor: (str) !->
        $dummy.0 .style.color = ""
        $dummy.0 .style.color = str
        return $dummy.0 .style.color != ""

    isURL: (str) !->
        return false if typeof str != \string
        str .= trim! .replace /\\\//g, '/'
        if parseURL(str).host != location.host
            return str
        else
            return false


    mention: (list) !->
        if not list?.length
            return ""
        else if list.0.username
            return humanList ["@#{list[i].username}" for ,i in list]
        else if list.0.attributes?.username
            return humanList ["@#{list[i].get \username}" for ,i in list]
        else
            return humanList ["@#{list[i]}" for ,i in list]
    humanList: (arr) !->
        return "" if not arr.length
        arr = []<<<<arr
        if arr.length > 1
            arr[*-2] += " and\xa0#{arr.pop!}" # \xa0 is NBSP
        return arr.join ", "

    plural: (num, singular, plural="#{singular}s") !->
        # for further functionality, see
        # * http://unicode.org/repos/cldr-tmp/trunk/diff/supplemental/language_plural_rules.html
        # * http://www.unicode.org/cldr/charts/latest/supplemental/language_plural_rules.html
        # * https://developer.mozilla.org/en-US/docs/Localization_and_Plurals
        if num == 1 # note: 0 will cause an s at the end, too
            return "#num\xa0#singular" # \xa0 is NBSP
        else
            return "#num\xa0#plural"
    xth: (i) !->
        ld = i % 10 # last digit
        switch true
        | (i%100 - ld == 10) => "#{i}th" # 11th, 12th, 13th, 2311th, …
        | (ld==1) => return "#{i}st"
        | (ld==2) => return "#{i}nd"
        | (ld==3) => return "#{i}rd"
        return "#{i}th"

    /*fromCodePoints: (str) !->
        res = ""
        for codePoint in str.split \-
            res += String.fromCodePoints(parseInt(codePoint, 16))
        return res
    */
    emojifyUnicode: (str) !->
        if typeof str != \string
            return str
        else
            return str.replace do
                # U+1F300 to  U+1F3FF | U+1F400 to  U+1F64F | U+1F680 to  U+1F6FF
                /\ud83c[\udf00-\udfff]|\ud83d[\udc00-\ude4f]|\ud83d[\ude80-\udeff]/g
                (emoji, all) !->
                    emoji = emoji.codePointAt(0).toString(16)
                    if emoticons.reversedMap[emoji]
                        # emoji is converted to a hexadecimal number, so no undesired HTML injection here
                        return emojifyUnicodeOne(emoji, true)
                    else
                        return all
    emojifyUnicodeOne: (key /*, isCodePoint*/) !->
        #if not isCodePoint
        #    key = emoticons.map[language]
        return "<span class=\"emoji emoji-#key\"></span>"
    flag: (language, unicode) !->
        /*@security HTML injection possible, if Lang.languages[language] is maliciously crafted*/
        if language.0 == \' or language.1 == \' # avoid HTML injection
            return ""
        else
            return "<span class='flag flag-#language' title='#{Lang?.languages[language]}'></span>"
        /*
        if window.emoticons
            language .= language if typeof language == \object
            language = \gb if language == \en
            if key = emoticons.map[language]
                if unicode
                    return key
                else
                    return emojifyOne(key)
        return language*/
    formatUser: (user, showModInfo) !->
        user .= toJSON! if user.toJSON
        info = getRank(user, true)
        if info == \regular
            info = ""
        else
            info = " #info"

        if showModInfo
            info += " lvl #{if user.gRole == 5 then '∞' else user.level}"
            if Date.now! - 48.h < d = parseISOTime(user.joined) # warn on accounts younger than 2 days
                info += " - created #{ago d}"

        return "#{user.username} (#{user.language}#info)"

    formatUserHTML: (user, showModInfo, fromClass) !->
        /*@security no HTML injection should be possible, unless user.rawun or .id is improperly modified*/
        user = getUser(user)
        if rank = getRankIcon(user)
            rank += " "

        if showModInfo
            info = " (lvl #{if user.gRole == 5 then '∞' else user.level}"
            if Date.now! - 48.h < d = parseISOTime(user.joined) # warn on accounts younger than 2 days
                info += " - created #{ago d}"
            info += ")"
        if fromClass
            fromClass = " #{getRank(user, true)}"
        else
            fromClass = ""

        # user.rawun should be HTML escaped, < and > are not allowed in usernames (checked serverside)
        return "#rank<span class='un p0ne-name#fromClass' data-uid='#{user.id}'>#{user.rawun}</span> #{flag user.language}#{info ||''}"

    formatUserSimple: (user) !->
        return "<span class=un data-uid='#{user.id}'>#{user.username}</span>"


    # formatting
    timezoneOffset: new Date().getTimezoneOffset!
    getTime: (t = Date.now!) !->
        return new Date(t - timezoneOffset *60_000min_to_ms).toISOString! .replace(/.+?T|\..+/g, '')
    getDateTime: (t = Date.now!) !->
        return new Date(t - timezoneOffset *60_000min_to_ms).toISOString! .replace(/T|\..+/g, ' ')
    getDate: (t = Date.now!) !->
        return new Date(t - timezoneOffset *60_000min_to_ms).toISOString! .replace(/T.+/g, '')
    getISOTime: (t = new Date)!->
        return t.toISOString! .replace(/T|\..+/g, " ")
    parseISOTime: (t) !->
        return new Date(t) - timezoneOffset *60_000min_to_ms

    # show a timespan (in ms) in a human friendly format (e.g. "2 hours")
    humanTime: (diff, shortFormat) !->
        if diff < 0
            return "-#{humanTime -diff}"
        else if not shortFormat and diff < 2_000ms # keep in sync with ago()
            return "just now"
        b=[60to_min, 60to_h, 24to_days, 360.25to_years]; c=0
        diff /= 1000to_s
        while diff > 2*b[c] then diff /= b[c++]
        if shortFormat
            return "#{~~diff}#{<[ s m h d y ]>[c]}"
        else
            return "#{~~diff} #{<[ seconds minutes hours days years ]>[c]}"
    # show a timespan (in s) in a format like "mm:ss" or "hh:mm:ss" etc
    mediaTime: (~~dur) !->
        return "-#{mediaTime -dur}" if dur < 0
        b=[60to_min, 60to_h, 24to_days, 360.25to_years]; c=0
        res = pad dur%60
        while dur = ~~(dur / b[c++])
            res = "#{pad dur % b[c]}:#res"
        if res.length == 2
            return "00:#res"
        else
            return res

    # create string saying how long ago a given timestamp (in ms since epoche) is
    ago: (d) !->
        d = Date.now! - d
        if d < 2_000ms # keep in sync with humanTime()
            return "just now"
        else
            return "#{humanTime(d)} ago"

    lssize: (sizeWhenDecompressed) !->
        size = 0mb
        for k,v of localStorage when k != \length
            if sizeWhenDecompressed
                try v = decompress v
            size += (v ||'').length / 524288to_mb # x.length * 16bits / 8to_b / 1024to_kb / 1024to_mb
        return size
    formatMB: !->
        return "#{it.toFixed(2)}MB"

    getRank: (user, defaultToGhost) !-> # returns the name of a rank of a user
        user = getUser(user)
        if not user or user.role == -1
            if defaultToGhost
                return \ghost
            else
                return \regular
        else if user.gRole
            if that == 5
                return \admin
            else
                return \ambassador
        else
            return <[ regular dj bouncer manager cohost host ]>[user.role ||0]
    getRankIcon: (user) !->
        rank = getRank(user, true)
        return rank != \regular && "<i class='icon icon-chat-#rank p0ne-icon-small'></i>" ||''

    parseURL: (href) !->
        href ||= "//"
        a = document.createElement \a
        a.href = href
        return a
        #$dummy.0{hash, host, hostname, href, pathname, port, protocol, search}

    getIcon: do !->
        /* note: this function doesn't cache results, as it's expected to not be used often (only in module setups)
         * if you plan to use it over and over again, use getIcon.enableCaching() */
        $icon = $ "<i class=icon><!-- this is used by plug_p0ne's getIcon() --></i>"
                .css visibility: \hidden
                .appendTo \body
        fn = (className, parsed) !->
            $icon.addClass className
            res =
                image:      $icon .css \background-image
                position:   $icon .css \background-position
            $icon.removeClass className if className
            if parsed
                res2 = x: 0, y: 0, url: res.image.substring(4, res.image.length - 1)
                if /-?(\d+)px\s+-?(\d+)px/.exec(res.position)
                    res2.x = +that.1; res2.y = +that.2
                return res2
            else
                res.background = "#{res.image} #{res.position}"
                return res
        fn.enableCaching = !-> res = _.memoize(fn); res.enableCaching = $.noop; window.getIcon = res
        return fn

    #= HTML Templates =
    htmlToggle: (checked, data) !->
        if data
            data = ""
            for k,v of data
                data += "data-#k='#v' "
        else
            data=''
        return "<input type=checkbox class=checkbox #data#{if checked then '' else \checked} />"




    #= variables =
    disabled: false
    user: API?.getUser! # preverably for usage with things that should not change, like userID, joindate, …
        # is kept uptodate in updateUserData in p0ne.auxiliary-modules
    getRoomSlug: !->
        return room?.get?(\slug) || decodeURIComponent location.pathname.substr(1)

window.woot.click = window.woot
window.meh.click = window.meh
window.unsnooze = window.refresh

# load cached requireIDs
(err, data) <- dataLoadAll {p0ne_requireIDs: {}, p0ne_disabledModules: {_rooms: {}}}

window.requireIDs = data.p0ne_requireIDs; p0ne.disabledModules = data.p0ne_disabledModules
if err
    console.warn "#{getTime!} [p0ne] the cached requireIDs seem to be corrupted" if err.p0ne_requireIDs
    console.warn "#{getTime!} [p0ne] the user's p0ne settings seem to be corrupted" if err.p0ne_disabledModules
console.info "[p0ne] main function body", p0ne.disabledModules.autojoin


/*####################################
#          REQUIRE MODULES           #
####################################*/
/* requireHelper(moduleName, testFn) */
requireHelper \users, (.onRole)
requireHelper \Curate, (.::?.execute?.toString!.has("/media/insert"))
requireHelper \playlists, (.activeMedia)
requireHelper \auxiliaries, (.deserializeMedia)
requireHelper \database, (.settings)
requireHelper \socketEvents, (.ack)
requireHelper \permissions, (.canModChat)
requireHelper \Playback, (.::?.id == \playback)
requireHelper \PopoutView, (\$document of)
requireHelper \MediaPanel, (.::?.onPlaylistVisible)
requireHelper \PlugAjax, (.::?.hasOwnProperty \permissionAlert)
requireHelper \backbone, (.Events), id: \backbone
requireHelper \roomLoader, (.onVideoResize)
requireHelper \Layout, (.getSize)
requireHelper \popMenu, (.className == \pop-menu)
requireHelper \ActivateEvent, (.ACTIVATE)
requireHelper \votes, (.attributes?.grabbers)
requireHelper \chatAuxiliaries, (.sendChat)
requireHelper \tracker, (.identify)
requireHelper \currentMedia, (.updateElapsedBind)
requireHelper \settings, (.settings)
requireHelper \soundcloud, (.sc)
requireHelper \searchAux, (.ytSearch)
requireHelper \searchManager, (._search)
requireHelper \SearchList, (.::?.listClass == \search)
requireHelper \YtSearchService, (.::?.onVideos)
requireHelper \AlertEvent, (._name == \AlertEvent)
requireHelper \userRollover, (.id == \user-rollover)
requireHelper \booth, (.attributes?.hasOwnProperty \shouldCycle)
requireHelper \currentPlaylistMedia, (\currentFilter of)
requireHelper \userList, (.id == \user-lists)
requireHelper \FriendsList, (.::?.className == \friends)
requireHelper \RoomUserRow, (.::?.vote)
requireHelper \WaitlistRow, (.::?.onAvatar)
requireHelper \room, (.attributes?.hostID)
requireHelper \RoomHistory, (it) !-> return it::?.listClass == \history and it::hasOwnProperty \listClass
requireHelper \avatarAuxiliaries, (.getAvatarUrl)
requireHelper \Avatar, (.AUDIENCE)
#requireHelper \AvatarList, (._byId?.admin01)

if requireHelper \emoticons, (.emojify)
    emoticons.reversedMap = {[v, k] for k,v of emoticons.map}

if requireHelper \PlaylistItemList, (.::?.listClass == \playlist-media)
    export PlaylistItemRow = PlaylistItemList::RowClass

if requireHelper \DialogAlert, (.::?.id == \dialog-alert)
    export Dialog = DialogAlert.__super__

if requireHelper \InventoryAvatarPage, ((a) -> a::?.className == 'avatars' && a::eventName)
    export InventoryDropdown = new InventoryAvatarPage().dropDown.constructor

#= _$context =
requireHelper \_$context, (._events?.\chat:receive), do
    onfail: !->
        console.error "[p0ne require] couldn't load '_$context'. A lot of modules will NOT load because of this"
for context in [ Backbone.Events, _$context, API ] when context
    context.onEarly = (type, callback, context) !->
        @_events[][type] .unshift({callback, context, ctx: context || this})
            # ctx:  used for .trigger in Backbone
            # context:  used for .off in Backbone
        return this


#= app =
/* `app` is like the ultimate root object on plug.dj, just about everything is somewhere in there! great for debugging :) */
for cb in (room?._events?[\change:name] || _$context?._events?[\show:room] || Layout?._events?[\resize] ||[]) when cb.ctx.room
    export app = cb.ctx
    export friendsList = app.room.friends
    export pl = app.footer.playlist.playlist.media
    break


#= user_ =
# the internal user-object
if requireHelper \user_, (.canModChat) #(._events?.'change:username')
    export user = user_.toJSON!
    for ev in user_?._events?[\change:avatarID] ||[] when ev.ctx.comparator == \id
        export myAvatars = ev.ctx
        break

if user ||= window.user
    # API.getUser! will fail when used on the Dashboard if no room has been visited before
    export userID = user.id
    user.isStaff = user.role>1 or user.gRole # this is kept up to date in enableModeratorModules in p0ne.moderate


#= underscore =
# this should already be global, but let's be sure to avoid stuff breaking
# (because apparently at some point it did)
export _ = require \underscore

#= Lang =
window.Lang = require \lang/Lang
# security fix to avoid HTML injection
for k,v of Lang?.languages when v.has \'
    Lang.languages[k] .= replace /\\?'/g, "\\'"

#= chat =
if app and not (window.chat = app.room.chat) and window._$context
    for e in _$context._events[\chat:receive] ||[] when e.context?.cid
        window.chat = e.context
        break

#======================
#== CHAT AUXILIARIES ==
#======================
cm = $ \#chat-messages
window <<<<
    $cm: !->
        return PopoutView?.chat?.$chatMessages || chat?.$chatMessages || cm
    $cms: !->
        cm = chat?.$chatMessages || cm
        if PopoutView?.chat?.$chatMessages
            return cm .add that
        else
            return cm

    playChatSound: throttle 200ms, (isMention) !->
        chat?.playSound!
        /*if isMention
            chat.playSound \mention
        else if $ \.icon-chat-sound-on .length > 0
            chat.playSound \chat
        */
    appendChat: (div, wasAtBottom) !->
        wasAtBottom ?= chatIsAtBottom!
        $div = $ div
        $cms!.append $div
        chatScrollDown! if wasAtBottom
        chat.lastType = null # avoid message merging above the appended div
        PopoutView?.chat?.lastType = null
        #playChatSound isMention
        return $div

    chatWarn: (message, /*optional*/ title, isHTML) !->
        return if not message
        if typeof title == \string
            title = $ '<span class=un>' .text title
        else
            isHTML = title
            title = null

        return appendChat do
            $ '<div class="cm p0ne-notif"><div class=badge-box><i class="icon icon-chat-system"></i></div></div>'
                .append do
                    $ '<div class=msg>'
                        .append do
                            $ '<div class=from>'
                                .append title
                                .append getTimestamp!
                        .append do
                            $('<div class=text>')[if isHTML then \html else \text] message

    chatIsAtBottom: !->
        cm = $cm!
        return cm.scrollTop! > cm.0 .scrollHeight - cm.height! - 20
    chatScrollDown: !->
        cm = $cm!
        cm.scrollTop( cm.0 .scrollHeight )

    chatInput: (msg, append) !->
        $input = chat?.$chatInputField || $ \#chat-input-field
        if append and $input.text!
            msg = "#that #msg"
        $input
            .val msg
            .trigger \input
            .focus!
    getTimestamp: (d=new Date) !->
        if auxiliaries?
            return "<time class='timestamp' datetime='#{d.toISOString!}'>#{auxiliaries.getChatTimestamp(database?.settings.chatTimestamps == 24h)}</time>"
        else
            return "<time class='timestamp' datetime='#{d.toISOString!}'>#{pad d.getHours!}:#{pad d.getMinutes!}</time>"



/*####################################
#          extend Deferreds          #
####################################*/
# add .timeout(time, fn) to Deferreds and Promises
replace jQuery, \Deferred, (Deferred_) !-> return !->
    var timeStarted
    res = Deferred_ ...
    res.timeout = timeout
    promise_ = res.promise
    res.promise = !->
        res = promise_ ...
        res.timeout = timeout; res.timeStarted = timeStarted
        return res
    return res

    function timeout time, callback
        now = Date.now!
        timeStarted ||= Date.now!
        if @state! != \pending
            #console.log "[timeout] already #{@state!}"
            return

        if timeStarted + time <= now
            #console.log "[timeout] running callback now (Deferred started #{ago timeStarted_})"
            callback.call this, this
        else
            #console.log "[timeout] running callback in #{humanTime(timeStarted + time - now)} / #{humanTime time}"
            sleep timeStarted + time - now, !~>
                callback.call this, this if @state! == \pending



/*####################################
#     Listener for other Scripts     #
####################################*/
# plug³
var rR_
onLoaded = !->
    console.info "[p0ne] plugCubed detected"
    rR_ = Math.randomRange

    # wait for plugCubed to finish loading
    requestAnimationFrame waiting = !->
        if window.plugCubed and not window.plugCubed.plug_p0ne
            API.trigger \plugCubedLoaded, window.plugCubed
            $body .addClass \plugCubed
            replace plugCubed, \close, (close_) !-> return !->
                $body .removeClass \plugCubed
                close_ ...
                if Math.randomRange != rR_
                    # plugCubed got reloaded
                    onLoaded!
                else
                    window.plugCubed = dummyP3
        else
            requestAnimationFrame waiting
dummyP3 = {close: onLoaded, plug_p0ne: true}
if window.plugCubed and not window.plugCubed.plug_p0ne
    onLoaded!
else
    window.plugCubed = dummyP3

# plugplug
onLoaded = !->
    console.info "[p0ne] plugplug detected"
    API.trigger \plugplugLoaded, window.plugplug
    sleep 5_000ms, !-> ppStop = onLoaded
if window.ppSaved
    onLoaded!
else
    export ppStop = onLoaded

/*####################################
#          GET PLUG³ VERSION         #
####################################*/
window.getPlugCubedVersion = !->
    if not plugCubed?.init # plugCubed is not initialized
        return null
    else if plugCubed.version # cached
        return plugCubed.version
    else if v = requireHelper \plugCubedVersion, test: (.major)
        # plug³ alpha
        return v
    else
        # read version from plugCubed settings menu
        if not v = $ '#p3-settings .version' .text!
            # alternative methode (40x slower)
            $ \plugcubed .click!
            v = $ \#p3-settings
                .stop!
                .css left: -500px
                .find \.version .text!
        if v .match /^(\d+)\.(\d+)\.(\d+)(?:-(\w+))?(_min)? \(Build (\d+)\)$/
            v = toString: !->
                return "#{@major}.#{@minor}.#{@patch}#{@prerelease && '-'+@prerelease}#{@minified && '_min' || ''} (Build #{@build})"
            for k,i in <[ major minor patch prerelease minified build ]>
                v[k] = that[i+1]

    return plugCubed.version = v



# draws an image to the console
# `src` can be any url, even data-URIs; relative to the current page
# the optional parameter `customWidth` and `customHeight` need to be in px (integers e.g. `316` for 316px)
# note: if either the width or the height is not defined, the console.log entry will be asynchronious,
# because the image has to be loaded first to get the image's width and height
# returns a promise, so you can attach a callback for asynchronious loading
# e.g. `console.logImg(...).then(function() { ...callback... } )`
#var pending = console && console.logImg && console.logImg.pending
console.logImg = (src, customWidth, customHeight) !->
    def = $.Deferred!
    drawImage = (w, h) !->
        if window.chrome
            console.log "%c\u200B", "color: transparent;
                font-size: #{h*0.854}px !important;
                background: url(#src);display:block;
                border-right: #{w}px solid transparent
            " # 0.854 seems to work perfectly. Kind of a magic number, I guess.
        else # apparently this once worked in Firefox
            console.log "%c", "background: url(#src) no-repeat; display: block;
                width: #{w}px; height: #{h}px;
            "
        def.resolve!
    if isFinite(customWidth) and isFinite(customHeight)
        drawImage(+customWidth, +customHeight)
    else
        new Image
            ..onload = !->
                drawImage(@width, @height)
            ..onerror = !->
                console.log "[couldn't load image %s]", src
                def.reject!
            ..src = src
    return def.promise!

/*@source p0ne.module.ls */
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
                return if module.disabled
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

/*@source p0ne.auxiliary-modules.ls */
/**
 * Auxiliary plug_p0ne modules
 *
 * @author jtbrinkmann aka. Brinkie Pie
 * @license MIT License
 * @copyright (c) 2015 J.-T. Brinkmann
 */


/*####################################
#            AUXILIARIES             #
####################################*/
module \getActivePlaylist, do
    require: <[ playlists ]>
    module: !->
        return playlists.findWhere active: true

module \updateUserData, do
    require: <[ user_ users _$context ]>
    setup: ({addListener}) !->
        addListener window.user_, \change:username, !->
            user.username = window.user_.get \username
        for user in users.models
            user.set \joinedRoom, -1
        addListener API, \userJoin, ({id}) !->
            users.get(id)? .set \joinedRoom, Date.now!

module \throttleOnFloodAPI, do
    setup: ({addListener}) !->
        addListener API, \socket:floodAPI, !->
            /* all AJAX and Socket functions should check if the counter is AT LEAST below 20 */
            window.floodAPI_counter += 20
            sleep 15_000ms, !->
                /* it is assumed, that the API counter resets every 10 seconds. 15s is to provide enough buffer */
                window.floodAPI_counter -= 20

module \PopoutListener, do
    require: <[ PopoutView ]>
    optional: <[ _$context ]>
    setup: ({replace}) !->
        # also works with chatDomEvents.on \click, \.un, !-> example!
        # even thought cb.callback becomes \.un and cb.context becomes !-> example!
        replace PopoutView, \render, (r_) !-> return !->
            r_ ...
            _$context?.trigger \popout:open, PopoutView._window, PopoutView
            API.trigger \popout:open, PopoutView._window, PopoutView
        replace PopoutView, \clear, (c_) !-> return !->
            console.log "[popout:clear]", this, this.clear_ == c_, c_
            if not @chat
                # silently fail
                #appendChat do
                #    $ "<div style='color:red'>" .text "[p0ne] Error closing the popout: no this.chat - blame adblock?"
                #        .on \click, !-> console.error new Error().stack
                return
            try
                c_ ...
            catch err
                appendChat do
                    $ "<div style='color:red'>" .text "[p0ne] Error closing the popout: #{err.message}"
                        .on \click, !-> console.error err.messageAndStack
                window.error = err
            _$context?.trigger \popout:close, PopoutView._window, PopoutView
            API.trigger \popout:close, PopoutView._window, PopoutView

module \chatDomEvents, do
    require: <[ backbone ]>
    optional: <[ chat PopoutView PopoutListener ]>
    persistent: <[ _events ]>
    _events: []
    setup: ({addListener}) !->
        cm = chat?.$chatMessages || $ \#chat-messages
        @on = !->
            @_events[*] = arguments
            cm .on.apply cm, arguments
            PopoutView.chat.$el .on.apply PopoutView.chat.$el, arguments if PopoutView.chat
        @off = !->
            isAnyMatch = false
            i = -1
            while cb = @_events[++i]
                for ,o in arguments when cb[o] != arguments[o]
                    break
                else
                    isAnyMatch = true
                    @_events.remove(i--)
            cm .off.apply cm, arguments if isAnyMatch
        @once = (type, callback) !-> @on type, !-> @off(type, callback); callback ...

        addListener API, \popout:open, !~>
            cm = PopoutView.chat.$el
            console.log "[chatDomEvents] popup opened", @_events
            for cb in @_events
                #cm .off event, cb.callback, cb.context #ToDo test if this is necessary
                console.log "[chatDomEvents] adding listener", cm, cb
                cm .on .apply cm, cb

module \grabMedia, do
    require: <[ playlists auxiliaries ]>
    optional: <[ _$context ]>
    module: (playlistIDOrName, media, appendToEnd) !->
        currentPlaylist = playlists.get(playlists.getActiveID!)
        def = $.Deferred!
        # get playlist
        if typeof playlistIDOrName == \string and not playlistIDOrName .startsWith \http
            for pl in playlists.models when playlistIDOrName == pl.get \name
                playlist = pl; break
        else if not playlist = playlists.get(playlistIDOrName)
            playlist = currentPlaylist # default to current playlist
            appendToEnd = media; media = playlistIDOrName

        #if not playlist
        #    console.error "[grabMedia] could not find playlist", arguments
        #    def.reject \playlistNotFound
        #    return def .promise!

        # get media
        if not media # default to current song
            addMedia API.getMedia!
        else if media.duration or media.id
            addMedia media
        else
            mediaLookup media, do
                success: addMedia
                fail: (err) !->
                    console.error "[grabMedia] couldn't grab", err
                    def.reject \lookupFailed, err
        return def .promise!

        # add media to playlist
        function addMedia media
            console.log "[grabMedia] add '#{media.author} - #{media.title}' to playlist:", playlist
            playlist.set \syncing, true
            media.get = (it) !-> this[it]
            ajax \POST, "playlists/#{playlist.id}/media/insert", media: auxiliaries.serializeMediaItems([media]), append: !!appendToEnd
                .then ({[e]:data}) !->
                    if playlist.id != e.id
                        console.warn "playlist mismatch", playlist.id, e.id
                        playlist.set \syncing, false
                        playlist := playlists.get(e.id) || playlist
                    playlist.set \count, e.count
                    if playlist.id == currentPlaylist.id
                        _$context? .trigger \PlaylistActionEvent:load, playlist.id, do
                            playlists.getActiveID! != playlists.getVisibleID! && playlist.toArray!
                    # update local playlist
                    playlist.set \syncing, false
                    console.info "[grabMedia] successfully added to playlist"
                    def.resolve playlist.toJSON!
                .fail (err) !->
                    console.error "[grabMedia] error adding song to the playlist"
                    def.reject \ajaxError, err



/*####################################
#            ROOM  HELPER            #
####################################*/
module \p0neModuleRoomSettingsLoader, do
    require: <[ _$context ]>
    setup: ({addListener}) !->
        addListener _$context, \room:joining, !->
            for ,m of p0ne.modules when m.settingsPerCommunity
                m._updateRoom!
        addListener _$context, \room:joined, !->
            for ,m of p0ne.modules when m.settingsPerCommunity and not m.disabled
                if m.loading
                    m.loading .then !->
                        m.enable!
                else
                    m.enable!

/*####################################
#             CUSTOM CSS             #
####################################*/
module \p0neCSS, do
    optional: <[ PopoutListener PopoutView ]>
    $popoutEl: $!
    styles: {}
    urlMap: {}
    persistent: <[ styles ]> # urlMap gets transferred in setup()
    setup: ({addListener, $create},,p0neCSS_) !->
        @$el = $create \<style> .appendTo \head
        {$el, $popoutEl, styles, urlMap} = this
        cb = addListener API, \popout:open, (_window, PopoutView) !->
            $popoutEl := $el .clone!
                .loadAll PopoutView.resizeBind
                .appendTo _window.document.head
        cb! if PopoutView?._window

        export @getCustomCSS = (inclExternal) !->
            if inclExternal
                return [el.outerHTML for el in $el] .join '\n'
            else
                return $el .first! .text!

        throttled = false
        export @css = (name, css) !->
            return styles[name] if not css?

            styles[name] = css

            if not throttled
                throttled := true
                requestAnimationFrame !->
                    throttled := false
                    res = ""
                    for n,css of styles
                        res += "/*== #n ==*/\n#css\n\n"
                    $el       .first! .text res
                    $popoutEl .first! .text res

        loadingStyles = 0
        export @loadStyle = (url) !->
            console.log "[loadStyle] %c#url", "color: #009cdd"
            if urlMap[url]
                return urlMap[url]++
            else
                urlMap[url] = 1
            loadingStyles++
            s = $ "<link rel='stylesheet' >"
                #.attr \href, "#url?p0=#{p0ne.version}" /* ?p0 to force redownload instead of using obsolete cached versions */
                .attr \href, url /* ?p0 to force redownload instead of using obsolete cached versions */
                .on 'load fail', !->
                    if --loadingStyles == 0
                        _$context?.trigger \p0ne:stylesLoaded
                        API.trigger \p0ne:stylesLoaded
                .appendTo document.head
            $el .push s.0
            Layout?.onResize!

            # Popout
            if PopoutView?._window
                $popoutEl .push do
                    s.clone!
                        .load PopoutView.resizeBind
                        .appendTo PopoutView._window.document.head

        export @unloadStyle = (url) !->
            if urlMap[url] > 0
                urlMap[url]--
            if urlMap[url] == 0
                console.log "[loadStyle] unload %c#url", "color: #009cdd"
                delete urlMap[url]

                # page
                if -1 != (i = $el       .indexOf "[href='#url']")
                    $el.eq(i).remove!
                    $el.splice(i, 1)
                    Layout?.onResize!

                # Popout
                if -1 != (i = $popoutEl .indexOf "[href='#url']")
                    $popoutEl.eq(i).remove!
                    $popoutEl.splice(i, 1)
                    PopoutView.resizeBind! if PopoutView?._window
        @disable = !->
            $el       .remove!
            $popoutEl .remove!
            Layout?.onResize!
            PopoutView.resizeBind! if PopoutView?._window

        if p0neCSS_
            res = ""
            for n,css of styles
                res += "/*== #n ==*/\n#css\n\n"
            if res
                $el       .first! .text res
                $popoutEl .first! .text res

            for url, i of p0neCSS_.urlMap
                @loadStyle url
                @urlMap[url] = i

/*@source p0ne.perf.ls */
/**
 * performance enhancements for plug.dj
 * the perfEmojify module also adds custom emoticons
 *
 * @author jtbrinkmann aka. Brinkie Pie
 * @license MIT License
 * @copyright (c) 2015 J.-T. Brinkmann
 */
module \jQueryPerf, do
    setup: ({replace}) !->
        # improve performance by making $.fn.addClass, .removeClass and .hasClass
        # use the element's classList instead of the className attribute
        core_rnotwhite = /\S+/g
        if \classList of document.body #ToDo is document.body.classList more performant?
            replace jQuery.fn, \addClass, !-> return (value) !->
                if jQuery.isFunction(value)
                    for j in this
                        jQuery(this).addClass value.call(this, j, this.className)

                else if typeof value == \string and value
                    classes = value.match(core_rnotwhite) || []

                    i = 0
                    while elem = this[i++] when elem.nodeType == 1
                        j = 0
                        while clazz = classes[j++]
                            elem.classList.add clazz
                return this

            replace jQuery.fn, \removeClass, !-> return (value) !->
                if jQuery.isFunction(value)
                    for j in this
                        jQuery(this).removeClass value.call(this, j, this.className)

                else if value ~= null
                    i = 0
                    while elem = this[i++] when elem.nodeType == 1
                        j = elem.classList .length
                        while clazz = elem.classList[--j]
                            elem.classList.remove clazz
                else if typeof value == \string and value
                    classes = value.match(core_rnotwhite) || []

                    i = 0
                    while elem = this[i++] when elem.nodeType == 1
                        j = 0
                        while clazz = classes[j++]
                            elem.classList.remove clazz
                return this

            replace jQuery.fn, \hasClass, !-> return (className) !->
                i = 0
                while elem = this[i++] when elem.classList.contains(className)
                    return true
                return false


module \perfEmojify, do
    require: <[ emoticons ]>
    setup: ({replace}) !->
        # new .emojify is ca. 100x faster https://i.imgur.com/iBNICkX.png
        #= prepare replacement =

        escapeReg = (e) !->
            return e .replace /([\\\.\+\*\?\[\^\]\$\(\)\{\}\=\!\<\>\|\:])/g, "\\$1"

        # list of emotices that will be automatically converted
        # (without being surrounded by colons)
        # this is the original, unmodified map from plug.dj
        emoticons.autoEmoteMap =
            /*NOTE: since plug_p0ne v1.6.3, emoticons are case-sensitive */
            ">:(" : \angry
            ">XD" : \astonished
            ":DX" : \bowtie
            "</3" : \broken_heart
            ":$"  : \confused
            "X$"  : \confounded
            ":~(" : \cry
            ":["  : \disappointed
            ":~[" : \disappointed_relieved
            "XO"  : \dizzy_face
            ":|"  : \expressionless
            "8|"  : \flushed
            ":("  : \frowning
            ":#"  : \grimacing
            ":D"  : \grinning
            "<3"  : \heart
            "<3)" : \heart_eyes
            "O:)" : \innocent
            ":~)" : \joy
            ":*"  : \kissing
            ":<3" : \kissing_heart
            "X<3" : \kissing_closed_eyes
            "XD"  : \laughing
            ":O"  : \open_mouth
            "Z:|" : \sleeping
            ":)"  : \smiley
            ":/"  : \smirk
            "T_T" : \sob
            ":P"  : \stuck_out_tongue
            "X-P" : \stuck_out_tongue_closed_eyes
            ";P"  : \stuck_out_tongue_winking_eye
            "B-)" : \sunglasses
            "~:(" : \sweat
            "~:)" : \sweat_smile
            "XC"  : \tired_face
            ">:/" : \unamused
            ";)"  : \wink

        # update function, to create caches and regexps for improved performance
        # call this everytime the autoEmoteMap is updated
        emoticons.update = !->
            # create reverse emoticon map
            @reverseMap = {}

            # create trie (aka. prefix tree)
            @trie = {}
            for k,v of @map
                continue if @reverseMap[v]
                @reverseMap[v] = k
                h = @trie
                for letter, i in k
                    l = h[letter]
                    if typeof h[letter] == \string
                        h[letter] = {_list: [l]}
                        h[letter][l[i+1]] = l if l.length > i
                    if l
                        h[letter] ||= {_list: []}
                    else
                        h[letter] = k
                        break
                    h[letter]._list = (h[letter]._list ++ k).sort!
                    h = h[letter]

            # fix autoEmote (so we don't have to replace it in the input text every time)
            for k,v of @autoEmoteMap when k != (tmp = k .replace(/</g, "&lt;") .replace(/>/g, "&gt;"))
                @autoEmoteMap[tmp] = v
                delete @autoEmoteMap[k]

            # create regexp for autoEmote
            @regAutoEmote = //(^|\s|&nbsp;)(#{Object.keys(@autoEmoteMap) .map(escapeReg) .join "|"})(?=\s|$)//g

        emoticons.update!

        # replace plug.dj functions
        replace emoticons, \emojify, !-> return (str) !->
            lastWasEmote = false
            return str
                .replace @regAutoEmote, (,pre,emote) !~> return "#pre:#{@autoEmoteMap[emote]}:"
                .replace /:(.*?)(?=:)|:(.*)$/g, (_, emote, post) !~>
                    if (p = typeof post != \string) and not lastWasEmote and @map[emote]
                        lastWasEmote := true
                        return "<span class='emoji-glow'><span class='emoji emoji-#{@map[emote]}'></span></span>"
                    else
                        lastWasEmote_ = lastWasEmote
                        lastWasEmote := false
                        return "#{if lastWasEmote_ then '' else ':'}#{if p then emote else post}"

        replace emoticons, \lookup, !-> return (str) !->
            # walk through the trie, letter by letter of the input
            h = @trie
            var res
            for letter, i in str
                h = h[letter]
                switch typeof h
                | \undefined
                    # no match was found
                    return []
                | \string
                    # if only one result is left, check if the input differs
                    for i from i+1 til str.length when str[i] != h[i]
                        return []
                    # if it doesn't differ, return the only result
                    return [h]
            # return the list of results
            return h._list

/*@source p0ne.sjs.ls */
/**
 * propagate Socket Events to the API Event Emitter for custom event listeners
 *
 * @author jtbrinkmann aka. Brinkie Pie
 * @license MIT License
 * @copyright (c) 2015 J.-T. Brinkmann
 */
/*####################################
#          SOCKET LISTENERS          #
####################################*/
module \socketListeners, do
    require: <[ socketEvents ]>
    optional: <[ _$context auxiliaries ]>
    logUnmatched: false
    lastHandshake: 0
    setup: ({replace}, socketListeners) !->
        #== patch socket ==
        window.Socket ||= window.SockJS || window.WebSocket
        if Socket == window.SockJS
            base_url = "https://shalamar.plug.dj:443/socket" # 2015-01-25
        else
            base_url = "wss://godj.plug.dj/socket" # 2015-02-12
        #return if parseURL(window.socket?.url).host.endsWith \plug.dj
        return if window.socket?.url == base_url
        onRoomJoinQueue2 = []
        for let event in <[ send dispatchEvent close ]>
            #console.log "[socketListeners] injecting into Socket::#event"
            replace Socket::, event, (e_) !-> return !->
                try
                    e_ ...
                    url = @_base_url || @url
                    if window.socket != this and url == base_url #parseURL(url).host.endsWith \plug.dj
                        replace window, \socket, !~> return this
                        replace this, \onmessage, (msg_) !-> return (t) !->
                            socketListeners.lastHandshake = Date.now!
                            return if t.data == \h

                            if typeof t.data == \string
                                data = JSON.parse t.data
                            else
                                data = t.data ||[]

                            for el in data
                                _$context.trigger "socket:#{el.a}", el

                            type = data.0?.a
                            console.warn "[SOCKET:WARNING] socket message format changed", t if not type

                            msg_ ...

                            for el in data
                                API.trigger "socket:#{el.a}", el


                        _$context .on \room:joined, !->
                            while onRoomJoinQueue2.length
                                forEach onRoomJoinQueue2.shift!

                        socket.emit = (e, t, n) !->
                            #if e != \chat
                            #   console.log "[socket:#e]", t, n || ""
                            socket.send JSON.stringify do
                                a: e
                                p: t
                                t: auxiliaries?.getServerEpoch!
                                d: n

                        /*socketListeners.hoofcheck = repeat 1.min, !->
                            if Date.now! > socketListeners.lastHandshake + 2.min
                                console.warn "the socket seems to have silently disconnected, trying to reconnect. last message", ago(socketListeners.lastHandshake)
                                reconnectSocket!*/
                        console.info "[Socket] socket patched (using .#event)", this
                    else if socketListeners.logUnmatched and window.socket != this
                        console.warn "socket found, but url differs '#url'", this
                catch err
                    export err
                    console.error "error when patching socket", this, err.stack


        function onMessage  t
            if room.get \joined
                forEach( t.data )
            else
                n = []; r = []
                for e in t.data
                    if e.s == \dashboard
                        n[*] = e
                    else
                        r[*] = e
                forEach( n )
                onRoomJoinQueue2.push( r )

        function forEach  t
            for el in t || []
                if socketEvents[ el.a ]
                    try
                        socketEvents[ el.a ]( el.p )
                    catch err
                        console.error "#{getTime!} [Socket] failed triggering '#{el.a}'", err.stack
                _$context.trigger "socket:#{el.a}", el
                API.trigger "socket:#{el.a}", el
    disable: !->
        clearInterval @hoofcheck


/*@source p0ne.fixes.ls */
/**
 * Fixes for plug.dj bugs
 *
 * @author jtbrinkmann aka. Brinkie Pie
 * @license MIT License
 * @copyright (c) 2015 J.-T. Brinkmann
 */


/*####################################
#                FIXES               #
####################################*/
module \simpleFixes, do
    setup: ({addListener, replace}) !->
        # hide social-menu (because personally, i only accidentally click on it. it's just badly positioned)
        @scm = $ '#twitter-menu, #facebook-menu, .shop-button' .detach! # not using .social-menu in case other scripts use this class to easily add buttons

        # add tab-index to chat-input
        replace $(\#chat-input-field).0, \tabIndex, !-> return 1

        # why would plug do a horrible thing such as cleaning the localStorage?! Q~Q
        replace localStorage, \clear, !-> return $.noop

        # clicking vote focuses the chat (again)
        addListener $(\#vote), \click, !-> $ \#chat-input-field .focus!

        # close Connection Error dialog when reconnected
        # otherwise the dialog FORCES you to refresh the page
        addListener API, \socket:reconnected, !->
            if app?.dialog.dialog?.options.title == Lang.alerts.connectionError
                app.dialog.$el.hide!

        # underscore.bind fix to allow `null` as first argument
        # this allows us performance optimizations (e.g. in chatDblclick2Mention)
        replace window._, \bind, (bind_) !-> return (func, context) !->
            if func
                return bind_ ...
            else
                return null
    disable: !->
        @scm? .insertAfter \#playlist-panel

/*####################################
#           USE P0 GAPI KEY          #
####################################*/
module \p0neGapiKey, do
    setup: ({replace}) !->
        gapi.client.key ||= \AIzaSyCXdCG_sDuHISSSFcbUmJatH70nS9NYnTs # plug.dj's key 2015-05-07
        gapi.client.keyProvider ||= \plug.dj
        replace gapi.client, \key, !-> return p0ne.YOUTUBE_V3_KEY
        replace gapi.client, \keyProvider, !-> return \plug_p0ne
        gapi.client.setApiKey(gapi.client.key)
    disableLate: !->
        gapi.client.setApiKey(gapi.client.key)

# This fixes the current media reloading on socket reconnects, even if the song didn't change
/* NOT WORKING
module \fixMediaReload, do
    require: <[ currentMedia ]>
    setup: ({replace}) !->
        replace currentMedia, \set, (s_) !-> return (a, b) !->
            if a.historyID and a.historyID == @get \historyID
                console.log "avoid force-reloading current song"
                return this
            else
                return s_.call this, a, b

replaced with:
*/
/*
module \fixPseudoAdvance, do
    require: <[ socketEvents ]>
    setup: ({replace}) !->
        var lastHistoryID
        replace socketEvents, \advance, (a_) !-> return (data) !->
            if lastHistoryID != data.h
                # only trigger `advance()` if the historyID differs from the current one
                lastHistoryID := data.h
                return a_.call(this, data)
*/


module \fixMediaThumbnails, do
    require: <[ auxiliaries ]>
    help: '''
        Plug.dj changed the Soundcloud thumbnail URL several times, but never updated the paths in their song database, so many songs have broken thumbnail images.
        This module fixes this issue.
    '''
    setup: ({replace, $create}) !->
        replace auxiliaries, \deserializeMedia, !-> return (e) !->
            e.author = this.h2t( e.author )
            e.title = this.h2t( e.title )
            if e.image
                if e.format == 2 # SoundCloud
                    if parseURL(e.image).host in <[ plug.dj cdn.plug.dj ]>
                        e.image = "https://i.imgur.com/41EAJBO.png"
                        #"https://cdn.plug.dj/_/static/images/soundcloud_thumbnail.c6d6487d52fe2e928a3a45514aa1340f4fed3032.png" # 2014-12-22
                else
                    if e.image.startsWith("http:") or e.image.startsWith("//")
                        e.image = "https:#{e.image.substr(e.image.indexOf('//'))}"
                    #if window.webkitURL # use webp on webkit browsers, for moar speed
                    #    not available on all videos
                    #    e.image = "https://i.ytimg.com/vi_webp/#{e.cid}/sddefault.webp


module \fixGhosting, do
    displayName: 'Fix Ghosting'
    require: <[ PlugAjax ]>
    settings: \fixes
    settingsMore: !-> return $ '<toggle val=warnings>Show Warnings</toggle>'
    help: '''
        Plug.dj sometimes considers you to be "not in any room" even though you still are. This is also called "ghosting" because you can chat in a room that technically you are not in anymore. While ghosting you can still chat, but not join the waitlist or moderate. If others want to @mention you, you don't show up in the autocomplete.

        tl;dr this module automatically rejoins the room when you are ghosting
    '''
    _settings:
        verbose: true
    setup: ({replace, addListener}) !->
        _settings = @_settings
        rejoining = false
        queue = []

        addListener API, \socket:userLeave, ({p}) !-> if p == userID
            sleep 200ms, !-> # to avoid problems, like auto-rejoining when closing the tab
                rejoinRoom 'you left the room'

        replace PlugAjax::, \onError, (oE_) !-> return (code, e) !->
            if e.status == \notInRoom
                #or status == \notFound # note: notFound is only returned for valid URLs, actually requesting not existing files returns a 404 error instead; update: TOO RISKY!
                queue[*] = this
                rejoinRoom "got 'notInRoom' error from plug", true
            else
                oE_.call(this, e)

        export rejoinRoom = (reason, throttled) !->
                if rejoining and throttled
                    console.warn "[fixGhosting] You are still ghosting, retrying to connect."
                else
                    console.warn "[fixGhosting] You are ghosting!", "Reason: #reason"
                    rejoining := true
                    ajax \POST, \rooms/join, slug: getRoomSlug!, do
                        success: (data) !->
                            if data.responseText?.0 == "<" # indicator for IP/user ban
                                if data.responseText .has "You have been permanently banned from plug.dj"
                                    # for whatever reason this responds with a status code 200
                                    chatWarn "your account got permanently banned. RIP", "fixGhosting"
                                else
                                    chatWarn "cannot rejoin the room. Plug is acting weird, maybe it is in maintenance mode or you got IP banned?", "fixGhosting"
                            else
                                chatWarn "reconnected to the room", "fixGhosting" if _settings.verbose
                                for req in queue
                                    req.execute! # re-attempt whatever ajax requests just failed
                                rejoining := false
                                _$context?.trigger \p0ne:reconnected
                                API.trigger \p0ne:reconnected
                        error: ({statusCode, responseJSON}:data) !~>
                            status = responseJSON?.status
                            switch status
                            | \ban =>
                                chatWarn "you are banned from this community", "fixGhosting"
                            | \roomCapacity =>
                                chatWarn "the room capacity is reached :/", "fixGhosting"
                            | \notAuthorized =>
                                chatWarn "you got logged out", "fixGhosting"
                                #login?!
                            | otherwise =>
                                switch statusCode
                                | 401 =>
                                    chatWarn "unexpected permission error while rejoining the room.", "fixGhosting"
                                    #ToDo is an IP ban responding with status 401?
                                | 503 =>
                                    chatWarn "plug.dj is in mainenance mode. nothing we can do here", "fixGhosting"
                                | 521, 522, 524 =>
                                    chatWarn "plug.dj is currently completly down", "fixGhosting"
                                | otherwise =>
                                    chatWarn "cannot rejoin the room, unexpected error #{statusCode} (#{datastatus})", "fixGhosting"
                            # don't try again for the next 10min
                            sleep 10.min, !->
                                rejoining := false


module \fixOthersGhosting, do
    require: <[ users socketEvents ]>
    displayName: "Fix Other Users Ghosting"
    settings: \fixes
    settingsMore: !-> return $ '<toggle val=warnings>Show Warnings</toggle>'
    help: '''
        Sometimes plug.dj does not properly emit join notifications, so that clients don't know another user joined a room. Thus they appear as "ghosts", as if they were not in the room but still can chat

        This module detects "ghost" users and force-adds them to the room.
    '''
    _settings:
        verbose: true
    setup: ({addListener, css}) !->
        addListener API, \chat, (d) !~> if d.uid and not users.get(d.uid)
            console.info "[fixOthersGhosting] seems like '#{d.un}' (#{d.uid}) is ghosting"

            #ajax \GET, "users/#{d.uid}", (status, data) !~>
            ajax \GET, "rooms/state"
                .then (data) !~>
                    # "manually" trigger socket event for DJ advance
                    for u, i in data.0.users when not users.get(u.id)
                        socketEvents.userJoin u
                        chatWarn "force-joined ##i #{d.un} (#{d.uid}) to the room", "p0ne" if @_settings.verbose
                    else
                        ajax \GET "users/#{d.uid}", (data) !~>
                            data.role = -1
                            socketEvents.userJoin data
                            chatWarn "#{d.un} (#{d.uid}) is ghosting", "p0ne" if @_settings.verbose
                .fail !->
                    console.error "[fixOthersGhosting] cannot load room data:", status, data
                    console.error "[fixOthersGhosting] cannot load user data:", status, data


module \fixStuckDJ, do
    require: <[ socketEvents ]>
    optional: <[ votes ]>
    displayName: "Fix Stuck Advance"
    settings: \fixes
    settingsMore: !-> return $ '<toggle val=warnings>Show Warnings</toggle>'
    help: '''
        Sometimes plug.dj does not automatically start playing the next song. Usually you would have to reload the page to fix this bug.

        This module detects stuck advances and automatically force-loads the next song.
    '''
    _settings:
        verbose: true
    setup: ({replace, addListener}, fixStuckDJ) !->
        @timer := sleep 5_000ms, fixStuckDJ if API.getTimeRemaining! == 0s and API.getMedia!

        addListener API, \advance, (d) !~>
            console.log "#{getTime!} [API.advance]"
            clearTimeout @timer
            if d.media
                @timer = sleep d.media.duration*1_000s_to_ms + 2_000ms, fixStuckDJ
    module: !->
        # no new song played yet (otherwise this change:media would have cancelled this)
        fixStuckDJ = this
        if showWarning = API.getTimeRemaining! == 0s
            console.warn "[fixNoAdvance] song seems to be stuck, trying to fix…"

        m = API.getMedia! ||{}
        ajax \GET, \rooms/state, do
            error: (data) !~>
                console.error "[fixNoAdvance] cannot load room data:", status, data
                @timer := sleep 10_000ms, fixStuckDJ
            success: (data) !~>
                data.0.playback ||= {}
                if m.id == data.0.playback?.media?.id
                    console.log "[fixNoAdvance] the same song is still playing."
                else
                    # "manually" trigger socket event for DJ advance
                    data.0.playback ||= {}
                    socketEvents.advance do
                        c: data.0.booth.currentDJ
                        d: data.0.booth.waitingDJs
                        h: data.0.playback.historyID
                        m: data.0.playback.media
                        t: data.0.playback.startTime
                        p: data.0.playback.playlistID

                    if votes?
                        for uid of data.0.grabs
                            votes.grab uid
                        for i,v of data.0.votes
                            votes.vote {i,v}
                    else
                        console.warn "[fixNoAdvance] cannot properly set votes, because optional requirement `votes` is missing"
                    chatWarn "fixed DJ not advancing", "p0ne" if @_settings.verbose and showWarning


/*
module \fixNoPlaylistCycle, do
    require: <[ _$context ActivateEvent ]>
    displayName: "Fix No Playlist Cycle"
    settings: \fixes
    settingsMore: !-> return $ '<toggle val=warnings>Show Warnings</toggle>'
    help: '''
        Sometimes after DJing, plug.dj does not move the played song to the bottom of the playlist.

        This module automatically detects this bug and moves the song to the bottom.
    '''
    _settings:
        verbose: true
    setup: ({addListener}) !->
        addListener API, \socket:reconnected, !->
            _$context.dispatch new LoadEvent(LoadEvent.LOAD)
            _$context.dispatch new ActivateEvent(ActivateEvent.ACTIVATE)
        / *
        # manual check
        addListener API, \advance, ({dj, lastPlay}) !~>
            #ToDo check if spelling is correctly
            #ToDo get currentPlaylist
            if dj?.id == userID and lastPlay.media.id == currentPlaylist.song.id
                #_$context .trigger \MediaMoveEvent:move
                ajax \PUT, "playlists/#{currentPlaylist.id}/media/move", ids: [lastPlay.media.id], beforeID: 0
                chatWarn "fixed playlist not cycling", "p0ne" if @_settings.verbose
        * /
*/

module \fixStuckDJButton, do
    settings: \fixes
    displayName: 'Fix Stuck DJ Button'
    require: <[ _$context ]>
    setup: ({addListener}) !->
        $djbtn = $ \#dj-button
        fixTimeout = false
        do addListener _$context, \djButton:update, !->
            spinning = $djbtn.find \.spinner .length == 0
            console.log "[djButton:update]", spinning, fixTimeout
            if fixTimeout and spinning
                clearTimeout fixTimeout
            else if not fixTimeout
                fixTimeout := sleep 5_000ms, !->
                    fixTimeout := false
                    if $djbtn.find \.spinner .length != 0
                        console.log "[djButton:update] force joining", true, fixTimeout
                        ajax \GET, \rooms/state, (d) !->
                            d = d.data.0
                            if (d.currentDJ == userID or d.waitingDJs .lastIndexOf(userID) != -1)
                                chatWarn "fixing stuck the DJ button", "fixStuckDJButton"
                                forceJoin!
                    else
                        console.log "[djButton:update] already fixed", false, fixTimeout


module \zalgoFix, do
    settings: \fixes
    displayName: 'Fix Zalgo Messages'
    help: '''
        This avoids messages' text bleeding out of the message, as it is the case with so called "Zalgo" messages.
        Enable this if you are dealing with spammers in the chat who use Zalgo.
    '''
    setup: ({css}) !->
        css \zalgoFix, '
            .message {
                overflow: hidden;
            }
        '



module \warnOnAdblockPopoutBlock, do
    require: <[ PopoutListener ]>
    setup: ({addListener}) !->
        isOpen = false
        warningShown = false
        addListener API, \popout:open, (_window, PopoutView) !->
            isOpen := true
            sleep 1_000ms, !-> isOpen := false
        addListener API, \popout:close, (_window, PopoutView) !->
            if isOpen and not warningShown
                chatWarn "Popout chat immediately closed again. This might be because of an adblocker. You'd have to make an exception for plug.dj or disable your adblocker. Specifically Adblock Plus is known for causing this problem", "p0ne"
                warningShown := true
                sleep 15.min, !->
                    warningShown := false


/*module \chatEmojiPolyfill, do
    require: <[ users ]>
    #optional: <[ chatPlugin socketEvents database ]> defined later
    _settings:
        verbose: true
    fixedUsernames: {}
    originalNames: {}
    setup: ({addListener, replace}) !-> _.defer !~>
        /*@security HTML injection should NOT be possible * /
        /* Emoji-support detection from Modernizr https://github.com/Modernizr/Modernizr/blob/master/feature-detects/emoji.js * /
        try
            pixelRatio = window.devicePixelRatio || 1; offset = 12 * pixelRatio
            document.createElement \canvas .getContext \2d
                ..fillStyle = \#f00
                ..textBaseline = \top
                ..font = '32px Arial'
                ..fillText '\ud83d\udc28', 0px, 0px # U+1F428 KOALA
                if ..getImageData(offset, offset, 1, 1).data[0] != 0
                    console.info "[chatPolyfixEmoji] emojicons appear to be natively supported. fix will not be applied"
                    @disable!
                else
                    console.info "[chatPolyfixEmoji] emojicons appear to NOT be natively supported. applying fix…"
                    css \chatPolyfixEmoji, '
                        .emoji {
                            position: relative;
                            display: inline-block;
                        }
                    '
                    # cache usernames that require fixing
                    # note: .rawun is used, because it's already HTML escaped
                    for u in users?.models ||[] when (tmp=emojifyUnicode u.get(\rawun)) != (original=u.get \rawun)
                        console.log "\t[chatPolyfixEmoji] fixed username from '#original' to '#{unemojify tmp}'" if @_settings.verbose
                        u.set \rawun, @fixedUsernames[u.id] = tmp
                        @originalNames[u.id] = original
                        # ooooh dangerous dangerous :0
                        # (not with regard to security, but breaking other scripts)
                        # (though .rawun should only be used for inserting HTML)
                        # i really hope this doesn't break anything :I
                        #                                   --Brinkie 2015
                    if @fixedUsernames[userID]
                        user.rawun = @fixedUsernames[userID]
                        userRegexp = //@#{user.rawun}//g


                    if _$context?
                        # fix joining users
                        addListener _$context, \user:join, (u) !~>
                            if  (tmp=emojifyUnicode u.get(\rawun)) != (original=u.get \rawun)
                                console.log "[chatPolyfixEmoji] fixed username '#original' => '#{unemojify tmp}'" if @_settings.verbose
                                u.set \rawun, @fixedUsernames[u.id] = tmp
                                @originalNames[u.id] = original

                        # prevent memory leak
                        addListener _$context, \user:leave, (u) !~>
                            delete @fixedUsernames[u.id]
                            delete @originalNames[u.id]

                        # fix incoming messages
                        addListener _$context, \chat:plugin, (msg) !~>
                            # fix the message body
                            if msg.uid and msg.message != (tmp = emojifyUnicode(msg.message))
                                console.log "\t[chatPolyfixEmoji] fixed message '#{msg.message}' to '#{unemojify tmp}'" if @_settings.verbose
                                msg.message = tmp

                                # fix the username
                                if @fixedUsernames[msg.uid]
                                    # usernames may not contain HTML, also .rawun is HTML escaped.
                                    # The HTML that's added by the emoji fix is considered safe
                                    # we modify it, so that the sender's name shows up fixed in the chat
                                    msg.un_ = msg.un
                                    msg.un = that

                                if userRegexp?
                                    userRegexp.lastIndex = 0
                                    if userRegexp.test msg.message
                                        console.log "\t[chatPolyfixEmoji] fix mention"
                                        msg.type = \mention
                                        msg.sound = \mention if database?.settings.chatSound
                                        msg.[]mentions.push "@#{user.rawun}"
                        # as soon as possible, we have to restore the sender's username again
                        # otherwise other modules might act weird, such as disableCommand
                        addListener \early, API, \chat, (msg) !->
                            if msg.un_
                                msg.un = msg.un_
                                delete msg.un_

                        # fix users on name changes
                        addListener _$context, \socket:userUpdate, (u) !~>
                            # note: this gets called BEFORE userUpdate is natively processed
                            # so changes to `u` will be applied
                            delete @fixedUsernames[u.id]
                            if (tmp=emojifyUnicode u.rawun) != u.rawun
                                console.log "[chatPolyfixEmoji] fixed username '#{u.rawun}' => '#{unemojify tmp}'" if @_settings.verbose
                                u.rawun = @fixedUsernames[u.id] = tmp
                                if u.id == userID
                                    user.rawun = @fixedUsernames[userID]
                                    userRegexp := //@#{user.rawun}//g
        catch err
            console.error "[chatPolyfixEmoji] error", err.stack
    disable: !->
        for uid, original of @originalNames
            getUserInternal(uid)? .set \rawun, original
        if @originalNames[userID]
            user.rawun = @originalNames[userID]
*/

module \stopSubscriberSpam, do
    displayName: "Stop Subscriber Spam"
    settings: \fixes
    require: <[ _$context ]>
    setup: ({replace_$Listener}) ->
        replace_$Listener \chat:nonsubimage, -> return $.noop


/*####################################
#          YT PAGED SEARCH           #
####################################*/
/* The paginated search was removed on plug.dj on purpose, because searches use up quite a lot of
 * the Youtube API quota that plug.dj has. Limiting the search results is to avoid running out of quota.
 * This is not an issue with plug_p0ne, because plug_p0ne replaces the API key with plug_p0ne's own,
 * so that the plug.dj quota won't be used up.
 */
module \ytPagedSearch, do
    displayName: "Paged YT Search"
    settings: \fixes
    require: <[ searchManager searchAux SearchList YtSearchService ]>
    optional: <[ pl ]>
    setup: ({replace}) !->
        replace SearchList::, \onScroll, !-> return !->
            #console.log "[onScroll]", @searching, @scrollPane.getPercentScrolledY!, @collection
            if not @searching and @collection.length < 200 and searchManager.lastCount > 0 and @scrollPane.getPercentScrolledY! > 0.97
                @searching = !0
                searchManager.collection = @collection
                if searchManager.more!
                    @showRowSpinner!
                else
                    @hideRowSpinner!

        pl?.list?.scrollBind = pl~onScroll

        replace searchManager, \more, !-> return !->
            #console.log("load more", this)
            if not @relatedSearch and @lastCount > 0 and @collection.length < 200
                ++@page
                if not @scFavoritesLookup and not @scTracksLookup
                    @_search!
                else if @scFavoritesLookup
                    @loadSCFavorites @page
                else if @scTracksLookup
                    @loadSCTracks @page
                return true
            else
                return false


        replace searchManager, \_search, !-> return !->
            limit = pl?.visibleRows >? 50 # will return 50 if +pl.visibleRows is NaN
            console.log "[_search]", @lastQuery, @page, limit
            if @lastFormat == 1
                searchAux.ytSearch(@lastQuery, @page, limit, @ytBind)
            else if @lastFormat == 2
                searchAux.scSearch(@lastQuery, @page, limit, @scBind)

        replace searchAux, \ytSearch, !-> return (query, page, limit, callback) !->
            #console.log("ytSearch", query, page, limit, callback)
            @ytSearchService ||= new YtSearchService
            @ytSearchService.load(query, page, limit, callback)

        replace YtSearchService::, \load, !-> return (query, page, limit, callback) !->
            @nextPage = page + 1; @lastQuery = query
            @callback = callback
            gapi.client.youtube.search.list do
                q: query,
                part: \snippet
                fields: 'nextPageToken,items(id/videoId,snippet/title,snippet/thumbnails,snippet/channelTitle)',
                maxResults: limit,
                pageToken: if page != 1 and query == @lastQuery then @nextPageToken else null,
                videoEmbeddable: not 0,
                videoDuration: \any
                type: \video
                safeSearch: \none
                videoSyndicated: "true"
            .then do
                (e) ~>
                      #console.log("youtube loaded", e)
                      @nextPageToken = e.result.nextPageToken
                      @onList(e)
                @errorBind
            #window.ga and window.ga("send", "event", "Search")

module \fixPopoutChatClose, do
    require: <[ PopoutListener ]>
    setup: ({addListener}) !->
        addListener API, \popout:open, (window_) !->
            window_.onbeforeunload = PopoutView~close

/*@source p0ne.stream.ls */
/**
 * Modules for Audio-Only stream and stream settings for plug_p0ne
 *
 * @author jtbrinkmann aka. Brinkie Pie
 * @license MIT License
 * @copyright (c) 2015 J.-T. Brinkmann
*/
/* This modules includes the following things:
    - audio steam
    - a stream-settings field in the playback-controls (replacing the HD-button)
    - a blocked-video-unblocker
   These are all conbined into this one module to avoid conflicts
   and due to them sharing a lot of code
*/
module \streamSettings, do
    #settings: \dev
    #displayName: 'Stream-Settings'
    require: <[ app Playback currentMedia database _$context ]>
    optional: <[ database ]>
    audioOnly: false
    _settings:
        audioOnly: false
    setup: ({addListener, replace, revert, replaceListener, $create, css}, streamSettings, m_) !->
        css \streamSettings "
            .icon-stream-video {
                background: #{getIcon \icon-chat-sound-on .background};
            }
            .icon-stream-audio {
                background: #{getIcon \icon-chat-room .background};
            }
            .icon-stream-off {
                background: #{getIcon \icon-chat-sound-off .background};
            }
        "

        $playback = $ \#playback
        $playbackContainer = $ \#playback-container
        $el = $create '<div class=p0ne-stream-select>'
        playback = {}

        if m_?._settings # keep audio-only setting on update
            @_settings.audioOnly = m_._settings.audioOnly


        # replace HD button
        $ \#playback-controls .removeClass 'no-hd snoozed'
        replace Playback::, \onHDClick, !-> return $.noop
        $btn = $ '#playback .hd'
            .addClass \p0ne-stream-select
        @$btn_ = $btn.children!
        $btn .html '
                <div class="box">
                    <span id=p0ne-stream-label></span>
                    <div class="p0ne-stream-buttons">
                        <i class="icon icon-stream-video enabled"></i> <i class="icon icon-stream-audio enabled"></i> <i class="icon icon-stream-off enabled"></i> <div class="p0ne-stream-fancy"></div>
                    </div>
                </div>
            '
        @$label = $label = $btn .find \#p0ne-stream-label
        $icons = $btn .find \.icon

        #= make buttons disable-able =
        disabledBtns = {}
        function disableBtn mode
            disabledBtns[mode] = true
            $icon = $btn.find ".icon-stream-#mode" .removeClass \enabled

        addListener API, \advance, (d) !~> if d.media
            for mode of disabledBtns
                $btn.find ".icon-stream-#mode" .addClass \enabled
                delete disabledBtns[mode]
            if d.media.format == 2
                disableBtn \video


        # not using addListener here, because we are working on module-created elements
        $btn.find \.icon-stream-video .on \click, !~> if not disabledBtns.video
            database.settings.streamDisabled = false
            @_settings.audioOnly = false
            changeStream \video
            refresh!
        $btn.find \.icon-stream-audio .on \click, !~> if not disabledBtns.audio
            database.settings.streamDisabled = false
            @_settings.audioOnly = true if 2 != currentMedia.get \media ? .get \format
            changeStream \audio
            refresh!
        $btn.find \.icon-stream-off   .on \click, !~>
            database.settings.streamDisabled = true
            changeStream \off
            refresh!


        #== Define Players ==
        Player =
            enable: !->
                console.log "[StreamSettings] loading #{@name} stream"
                media = currentMedia.get \media
                if @media == media and this == player
                    @start!
                else
                    @media = media
                    @getURL(media)
            /*getURL: !->
                ...
                @media.src = ...
                @start!*/
            start: !->
                @seek!
                @src = @media.src
                @load!
                @updateVolume(currentMedia.get \volume)
                $playbackContainer .append this
            disable: !->
                @src = "" # note: `null` would actually refer to https://plug.dj/null
                $playbackContainer .empty!
            seek: !->
                startTime = currentMedia.get \elapsed
                if player != this
                    return
                else if startTime > 4s and currentMedia.get(\remaining) > 4s
                    @seekTo(startTime)
                    console.log "[StreamSettings] #{@name} seeking…", mediaTime(startTime)
                else
                    @play!
            seekTo: (t) !->
                @currentTime = t
            updateVolume: (vol) !->
                @volume = vol / 100perc

        #= Audio and Video Players common core =
        audio = m_?.audio || new Audio()
        unblocker = m_?.audio || document.createElement \video # because why should `new Video` work >_>
        $ [unblocker, audio] .addClass \media



        for let k, p of {audio, unblocker}
            p <<<< Player
            p.addEventListener \canplay, !->
                console.log "[#k stream] finished buffering"
                if currentMedia.get(\media) == player.media and player == this
                    diff = currentMedia.get(\elapsed) - player.currentTime
                    if diff > 4s and currentMedia.get(\remaining) > 4s
                        #player.init = false
                        @seek!
                        #sleep 2_000ms, !-> if player.paused
                        #    console.warn "[#k stream] still not playing. forcing #k.play()"
                        #    player.play!
                    else
                        player.play!
                        console.log "[#k stream] playing song (diff #{humanTime(diff, true)})"
                else
                    console.warn "[#k stream] next song already started"

        #= Audio Player =
        audio.name = "Audio-Only"
        audio.mode = \audio
        audio.getURL = (media) !->
            #audio.init = true
            mediaDownload media, true
                .then (d) !~>
                    console.log "[audioStream] found url. Buffering…", d
                    audio.media = media
                    media.src = d.preferredDownload.url
                    @enable!

                .fail (err) !->
                    console.error "[audioStream] couldn't get audio-only stream", err
                    chatWarn "couldn't load audio-only stream, using video instead", "audioStream", true
                    media.audioFailed = true
                    refresh!
                    disableBtn \audio
                    $playback .addClass \p0ne-stream-audio-failed
                    API.once \advance, !->
                        $playback .addClass \p0ne-stream-audio-failed

        #= Unblocked Youtube Player =
        /*not working*/
        unblocker.name = "Youtube (unblocked)"
        unblocker.mode = \video
        unblocker.getURL = (media) !->
            console.log "[YT Unblocker] receiving video URL", media
            blocked = media.get \blocked
            mediaDownload media
                .then (d) !~>
                    media.src = d.preferredDownload.url
                    console.log "[YT Unblocker] got video URL", media.src
                    @start!
                .fail !->
                    if blocked == 1
                        chatWarn "failed, trying again…", "YT Unblocker"
                    else
                        chatWarn "failed to unblock video :(", "YT Unblocker"
                        disableBtn \video
                    media.set \blocked, blocked++
                    refresh!

        #= Vanilla Youtube Player =
        youtube = Player with
            name: "Video"
            mode: \video
            enable: (@media) !->
                console.log "[StreamSettings] loading Youtube stream"
                startTime = currentMedia.get \elapsed
                playback.buffering = false
                playback.yto =
                    id: media.get \cid
                    volume: currentMedia.get \volume
                    seek: if startTime < 4s then 0s else startTime
                    quality: if database.hdVideo then \hd720 else ""

                $ "<iframe id=yt-frame frameborder=0 src='//plgyte.appspot.com/yt5.html'>"
                    .load playback.ytFrameLoadedBind
                    .appendTo playback.$container
            disable: !->
                $playbackContainer .empty!
            updateVolume: (vol) !->
                playback.tx "setVolume=#vol"

        #= Vanilla Soundcloud Player =
        sc = Player with
            name: "SoundCloud"
            mode: \audio
            enable: (@media) !->
                console.log "[StreamSettings] loading Soundcloud audio stream"
                if soundcloud.r # soundcloud player is ready (loaded)
                    if soundcloud.sc
                        playback.$container
                            .empty!
                            .append "<iframe id=yt-frame frameborder=0 src='#{playback.visualizers.random!}'></iframe>"
                        b = setTimeout playback.scTimeoutBind, 5_000ms
                        soundcloud.sc.whenStreamingReady !->
                            d.sc.stream do
                                n.get \cid
                                autoPlay: true
                                !-> if media == currentMedia.get \media # SC DOUBLE PLAY FIX
                                    clearTimeout(b)
                                    playback.player = e
                                    e.seek(if startTime < 4_000ms then 0ms else startTime *1_000ms)
                                    e.setVolume(currentMedia.get \volume / 100)
                                    e._player.on \stateChange, playback.scStateBind
                    else
                        playback.$container.append do
                            $ '<img src="https://soundcloud-support.s3.amazonaws.com/images/downtime.png" height="271"/>'
                                .css do
                                    position: \absolute
                                    left: 46px
                else
                    _$context.off \sc:ready
                    _$context.once \sc:ready, !~>
                        soundcloud.updateVolume(currentMedia.get \volume)
                        if media == currentMedia.get \media
                            playback.onSCReady!
                        else
                            console.warn "[StreamSettings] Soundcloud: a different song already started playing"
            disable: !->
                playback.player?
                    .stop!
                playback.buffering = false
                $playbackContainer .empty!
            #seekTo: $.noop
            updateVolume: (vol) !->
                playback.player.setVolume vol

        # pseudo players
        DummyPlayer =
            enable: $.noop
            disable: $.noop
            updateVolume: $.noop

        noDJ = DummyPlayer with
            name: "No DJ"
            mode: \off
            enable: !->
                playback.$noDJ.show!
                playback.$controls.hide!
            disable: !->
                playback.$noDJ.hide!

        syncingPlayer = DummyPlayer with
            name: "waiting…"
            mode: \off
            enable: !->
                $playbackContainer
                    .html "<iframe id=yt-frame frameborder=0 src='#{m.syncing}'></iframe>"
            updateVolume: $.noop

        streamOff = DummyPlayer with
            name: "Stream: OFF"
            mode: \off
        snoozed = DummyPlayer with
            name: "Snoozed"
            mode: \off

        if m = currentMedia.get \media
            player = do
                if database.settings.streamDisabled
                    streamOff
                else if isSnoozed!
                    snoozed
                else
                    [youtube, sc][m .get(\format) - 1]
        else
            player = noDJ
        changeStream player




        replace Playback::, \onVolumeChange, !-> return (,vol) !->
            player.updateVolume vol

        replace Playback::, \onMediaChange, (oMC_) !-> return !->
            @reset!
            @$controls.removeClass \snoozed
            media = currentMedia.get \media
            if media
                if database.settings.streamDisabled
                    changeStream streamOff
                    return

                @ignoreComplete = true; sleep 1_000ms, !~> @resetIgnoreComplete!

                oldPlayer = player
                if media.get(\format) == 1 # youtube

                    /*== AudioOnly Stream (YT) ==*/
                    if streamSettings._settings.audioOnly and not media.audioFailed
                        player := audio

                    #== Unblocked YT ==
                    else if media.blocked == 3
                        player := syncingPlayer # cannot be unblocked
                    else if media.blocked
                        player := unblocker # use unblocker

                    #== regular YT ==
                    else
                        player := youtube


                #== SoundCloud ==
                else if media.get(\format) == 2
                    disableBtn \video
                    player := sc

            else
                player := noDJ

            #= update player =
            changeStream player

            player.enable(media)

        replace Playback::, \stop, !-> return !->
            player.disable!
        replace Playback::, \reset, (r_) !-> return !->
            if database.settings.streamDisabled
                changeStream streamOff
            player.disable!
            r_ ...


        #== unlock Youtube if blocekd ==
        replace Playback::, \onYTPlayerError, !-> return (e) !->
            console.log "[streamSettings] Youtube Playback Error", e
            if not database.settings.streamDisabled and not streamSettings._settings.audioOnly
                @unblockYT!

        #== force all buttons to be always shown ==
        replace Playback::, \onPlaybackEnter, !-> return !->
            if currentMedia.get(\media)
                @$controls .show!
        replace Playback::, \onSnoozeClick, !-> return !->
            if not isSnoozed!
                changeStream snoozed
                @reset!
        #window.snooze = !-> changeStream snoozed
        /*replace Playback::, \onRefreshClick, !-> return !->
            if currentMedia.get(\media) and restr = currentMedia.get \restricted
                currentMedia.set do
                    media: restr
                    restricted: void
            else
                @onMediaChange!*/


        if app?
            @playback = playback = app.room.playback
            onGotPlayback(playback)
        else
            replace Playback::, \onRemainingChange, (oMC) !~> return !~>
                # patch playback
                @playback = playback := this
                oMC ...
                onGotPlayback(playback)

        if @_settings.audioOnly
            refresh!


        function onGotPlayback playback
            revert Playback::, \onRemainingChange

            # update events with bound listeners
            window.snooze = playback~onSnoozeClick
            replaceListener _$context, \change:streamDisabled, Playback, !-> return playback~onMediaChange
            replaceListener currentMedia, \change:media, Playback, !-> return playback~onMediaChange
            replaceListener currentMedia, \change:volume, Playback, !-> return playback~onVolumeChange

            $playback
                .off \mouseenter .on \mouseenter, !-> playback.onPlaybackEnter!
            $playback .find \.snooze
                .off \click      .on \click,      !-> playback.onSnoozeClick!
            /*$playback .find \.refresh
                .off \click      .on \click,      !->
                    database.settings.streamDisabled = false # turn stream on
                    playback.onRefreshClick!*/

        function changeStream mode, name
            if typeof mode == \object
                {mode, name} = mode
            console.log "[streamSettings] => stream-#mode"
            $label .text (name || player.name)
            $playback
                .removeClass!
                .addClass "p0ne-stream-#mode"

            _$context?.trigger \p0ne:changeMode
            API.trigger \p0ne:changeMode, mode, name

        @unblockYT = !->
            currentMedia.get \media ? .blocked = true
            refresh!


    disable: !->
        window.removeEventListener \message, @onRestricted
        $playback = $ \#playback
            .removeClass!
        $ '#playback .hd'
            .removeClass \p0ne-stream-select
            .empty!
            .append @$btn_

        sleep 0, !~>
            # after module is properly reset
            refresh! if @_settings.audioOnly and not isSnoozed!
            if @Playback
                $playback
                    .off \mouseenter
                    .on \mouseenter, @playback~onPlaybackEnter

/*@source p0ne.chat-commands.ls */
/**
 * plug_p0ne ChatCommands
 * Basic chat commands are defined here. Trigger them on plug.dj by writing "/commandname" in the chat
 * e.g. "/move @Brinkie Pie 2" to move the user "Brinkie Pie" to the 2nd position in the waitlist
 *
 * @author jtbrinkmann aka. Brinkie Pie
 * @license MIT License
 * @copyright (c) 2015 J.-T. Brinkmann
 */

/*####################################
#           CHAT COMMANDS            #
####################################*/
module \chatCommands, do
    optional: <[ currentMedia ]>
    setup: ({addListener}) !->
        addListener API, \chatCommand, (c) !~>
            if (cmd=@_commands[/^\/(\w+)/.exec(c)?.1])
                console.log "/chatCommand", cmd, cmd.moderation
                if (not cmd.moderation or user.gRole or v.moderation == true and user.isStaff or user.role >= cmd.moderation)
                    cmd.callback(c)
                else
                    chatWarn "You need to be #{if cmd.moderation === true then 'staff' else 'at least '+getRank(role: cmd.moderation)}", c
        @updateCommands!

    updateCommands: !->
        return if @updating
        @updating = true
        requestAnimationFrame ~>
            @updating = false
            @_commands = {}
            for k,v of @commands when v
                @_commands[k] = v
                for k in v.aliases ||[]
                    @_commands[k] = v
    parseUserArg: (str) !->
        if /[\s\d]+/.test str # list of user IDs
            return  [+id for id in str .split /\s+/ when +id]
        else
            return [user.id for user in getMentions str]
    commands:
        commands:
            description: "show this list of commands"
            callback: !->
                user = API.getUser!
                res = "<div class='msg text'>"
                for k,command of chatCommands.commands when command and not command.moderation or user.gRole or (if command.moderation == true then user.role > 2 else user.role >= command.moderation)
                    if command.aliases?.length
                        aliases = "title='aliases: #{humanList command.aliases}'"
                    else
                        aliases = ''
                    res += "<div class=p0ne-help-command #aliases><b>/#k</b> #{command.parameters ||''} - #{command.description}</div>"
                res += "</div>"
                appendChat($ "<div class='cm update p0ne-help'>" .html res)


        woot:
            description: "woot the current song"
            callback: woot

        meh:
            description: "meh the current song"
            callback: meh

        grab:
            aliases: <[ curate ]>
            parameters: " (playlist)"
            description: "grab the current song into a playlist (default is current playlist)"
            callback: (c) !->
                if c.replace(/^\/\w+\s*/, '')
                    grabMedia(that)
                else
                    grabMedia!
        /*away:
            aliases: <[ afk ]>
            description: "change your status to <b>away</b>"
            callback: !->
                API.setStatus 1
        busy:
            aliases: <[ work working ]>
            description: "change your status to <b>busy</b>"
            callback:  !->
                API.setStatus 2
        gaming:
            aliases: <[ game ingame ]>
            description: "change your status to <b>gaming</b>"
            callback:  !->
                API.setStatus 3*/

        join:
            description: "join the waitlist"
            callback: join
        leave:
            description: "leave the waitlist"
            callback: leave

        stream:
            parameters: " [on|off]"
            description: "enable/disable the stream (just '/stream' toggles it)"
            callback: !->
                if currentMedia?
                    # depending on the parameter, this return true ("on"), false ("off") and defaults to "toggle"
                    stream c.has \on || not (c.has(\off) || \toggle)
                else
                    chatWarn "couldn't load required module for enabling/disabling the stream."

        snooze:
            description: "snoozes the current song"
            callback: snooze
        mute:
            aliases: <[ stfu silence ]>
            parameters: "[[duration] @username(s)]"
            description: "mutes the audio or the specified user(s)"
            callback: (user) !->
                user .= replace(/^\/\w+\s*/, '').trim!
                if not user
                    mute!
                else
                    if durArg = /\w+/.exec user
                        duration = {
                            s: \s, short:  \s, 15: \s, \15min : \s,
                            m: \m, middle: \m, 30: \m, \30min : \m
                            l: \l, long:   \l, 45: \l, \45min : \l
                        }[durArg.1]
                        if duration
                            user .= substr durArg.1.length
                        else if getUser(durArg.1)
                            duration = \s
                    else
                        duration = \s

                    if not duration or user in <[ h -h help --help ? hlep ]>
                        chatWarn '<div class=p0ne-help-command>
                            possible durations are:<br>
                            - <b>s</b> (<em>15min</em>, <em>short</em>)<br>
                            - <b>m</b> (<em>30min</em>, <em>middle</em>)<br>
                            - <b>l</b> (<em>45min</em>, <em>long</em>)<br>
                            If left out, defaults to 15 minutes.<br>
                            You can also use /mute to extend/reduce the mute time.
                        </div>', '/mute [[duration] @username(s)]', true /*HTML*/
                    else
                        for id in chatCommands.parseUserArg user
                            API.moderateMuteUser id, duration, 1 #ToDo check this
        unmute:
            parameters: "[@username(s)]"
            description: "unmutes the audio or specified user(s)"
            callback: (user) !->
                user .= replace(/^\/\w+\s*/, '').trim!
                if not user
                    unmute!
                else
                    for id in chatCommands.parseUserArg user
                        API.moderateUnmuteUser id, duration, 1 #ToDo check this

        muteonce:
            aliases: <[ muteone ]>
            description: "mutes the current song"
            callback: muteonce

        automute:
            parameters: " [add|remove]"
            description: "adds/removes this song from the automute list"
            callback:  !->
                muteonce! if API.getVolume! != 0
                if automute?
                    # see note for /stream
                    automute(c.hasAny \add || not(c.hasAny \remove || \toggle))
                else
                    chatWarn "automute is not yet implemented"

        volume:
            parameters: " (0 - 100)"
            description: "sets the volume to the specified percentage"
            callback: (vol) !->
                vol .= replace(/^\/\w+\s*|%/, '').trim!
                API.setVolume +vol

        popout:
            aliases: <[ popup ]>
            description: "opens/closes the chat popout window"
            callback: !->
                if PopoutView?
                    if PopoutView._window
                        PopoutView.close!
                    else
                        PopoutView.show!
                else
                    chatWarn "sorry, the command currently doesn't work"

        reconnect:
            aliases: <[ reconnectSocket forceReconnect ]>
            description: "forces the socket to reconnect. This might solve chat issues"
            callback: !->
                _$context?.once \sjs:reconnected, !->
                    chatWarn "socket reconnected", '/reconnect'
                reconnectSocket!
        rejoin:
            aliases: <[ rejoinRoom ]>
            description: "forces a rejoin to the room (to fix issues)"
            callback: !->
                _$context?.once \room:joined, !->
                    chatWarn "room rejoined", '/rejoin'
                rejoinRoom!

        intercom:
            aliases: <[ messages ]>
            description: "Show Intercom messages"
            callback: !->
                Intercom("showMessages")

        #== moderator commands ==
        #        addListener API, 'socket:modAddDJ socket:modBan socket:modMoveDJ socket:modRemoveDJ socket:modSkip socket:modStaff', (u) !-> updateUser u.mi
        ban:
            aliases: <[ gtfo rekt abuse ]>
            parameters: "[duration] @username(s)"
            description: "bans the specified user(s). use `/ban help` for more info"
            moderation: true
            callback: (user) !->
                user .= replace(/^\/\w+\s*/, '').trim!
                if not user or user in <[ h -h help --help ? hlep ]>
                    chatWarn '<div class=p0ne-help-command>
                        possible durations are:<br>
                        - <b>s</b> (<em>15min</em>, <em>short</em>)<br>
                        - <b>h</b> (<em>1h</em>, <em>hour</em>, <em>long</em>)<br>
                        - <b>f</b> (<em>forever</em>, <em>p</em>, <em>perma</em>)<br>
                        If left out, defaults to 15 minutes.<br>
                        You can also use /ban to extend the ban time.
                    </div>', '/ban [duration] @username(s)', true /*HTML*/
                for id in chatCommands.parseUserArg user
                    API.modBan id, \s, 1 #ToDo check this
        unban:
            aliases: <[ pardon revive ]>
            parameters: " @username(s)"
            description: "unbans the specified user(s)"
            moderation: true
            callback: (user) !->
                for id in chatCommands.parseUserArg user.replace(/^\/\w+\s*/, '')
                    API.moderateUnbanUser id
                else
                    chatWarn "couldn't find any user", '/unban'

        move:
            parameters: " @username position"
            description: "moves a user to the pos. in the waitlist"
            moderation: true
            callback: (c) !->
                wl = API.getWaitList!
                var pos
                c .= replace /(\d+)\s*$/, (,d) !->
                    pos := +d
                    return ''
                if 0 < pos < 51
                    if users = chatCommands.parseUserArg(c.replace(/^\/\w+\s*/, ''))
                        if not (id = users.0) or not getUser(id)
                            chatWarn "The user doesn't seem to be in the room"
                        else
                            moveDJ id, pos
                        return
                    else
                        error = "requires you to specify a user to be moved"
                else
                    error = "requires a position to move the user to"
                chatWarn "#error<br>e.g. /move @#{API.getUsers!.random!.rawun} #{~~(Math.random! * wl.length) + 1}", '/move', true
        moveTop:
            aliases: <[ push ]>
            parameters: " @username(s)"
            description: "moves the specified user(s) to the top of the waitlist"
            moderation: true
            callback: (c) !->
                users = chatCommands.parseUserArg c.replace(/^\/\w+\s*/, '')
                # iterating over the loop in reverse, so that the first name will be the first, second will be second, …
                for i from users.length - 1 to 0
                    moveDJ i, 1
                else
                    chatWarn "couldn't find any user", '/moveTop'
        /*moveUp:
            aliases: <[  ]>
            parameters: " @username(s) (how much)"
            description: "moves the specified user(s) up in the waitlist"
            moderation: true
            callback: (user) !->
                res = []; djsToAdd = []; l=0
                wl = API.getWaitList!
                # iterating over the loop in reverse, so that the first name will be the first, second will be second, …
                for id in chatCommands.parseUserArg user.replace(/^\/\w+\s*(?:)/, '')
                    for u, pos in wl when u.id == id
                        if pos == 0
                            skipFirst = true
                        else
                            res[pos - 1] = u.id
                        break
                    else
                        djsToAdd[l++] = id
                console.log "[/move] starting to move…", res, djsToAdd
                pos = -1; l = res.length
                do helper = !->
                    id = res[++pos]
                    if id
                        if not skipFirst
                            console.log "[/move]\tmoving #id to #{pos + 1}/#{wl.length}"
                            moveDJ id, pos
                                .then helper
                                .fail !->
                                    chatWarn "couldn't /moveup #{if getUser(id) then that.username else id}"
                                    helper!
                        else
                            helper!
                    else if pos < l
                        skipFirst := false
                        helper!
                    else
                        for id in djsToAdd
                            addDJ id
                        console.log "[/move] done"
        moveDown:
            aliases: <[  ]>
            parameters: " @username(s) (how much)"
            description: "moves the specified user(s) down in the waitlist"
            moderation: true
            callback: !->
                ...
        */

        addDJ:
            aliases: <[ add ]>
            parameters: " @username(s)"
            description: "adds the specified user(s) to the waitlist"
            moderation: true
            callback: (c) !->
                users = chatCommands.parseUserArg c.replace(/^\/\w+\s*/, '')
                i = 0
                if users.length
                    do helper = !->
                        if users[i]
                            addDJ users[i++], helper
                else
                    chatWarn "couldn't find any user", '/addDJ'
        removeDJ:
            aliases: <[ remove ]>
            parameters: " @username(s)"
            description: "removes the specified user(s) from the waitlist / DJ booth"
            moderation: true
            callback: (c) !->
                for id in chatCommands.parseUserArg c.replace(/^\/\w+\s*/, '')
                    API.moderateRemoveDJ id
                else
                    chatWarn "couldn't find any user", '/removeDJ'
        skip:
            aliases: <[ forceSkip s ]>
            description: "skips the current song"
            moderation: true
            callback: ->
                if API.getTimeElapsed! > 2s
                    API.moderateForceSkip!
                else
                    chatWarn "
                        The song just changed, are you sure you want to skip?<br>
                        <button class=p0ne-btn onclick='API.moderateForceSkip()'>skip</button>\xa0
                        <button class=p0ne-btn onclick='$(this).closest(\".cm\").remove()'>cancel</button>
                    ", '/skip', true

        promote:
            parameters: " @username(s)"
            description: "promotes the specified user(s) to the next rank"
            moderation: 3
            callback: (c) !->
                for id in chatCommands.parseUserArg c.replace(/^\/\w+\s*/, '')
                    if getUser(id)
                        API.moderateSetRole(id, that.role + 1)
        demote:
            parameters: " @username(s)"
            description: "demotes the specified user(s) to the lower rank"
            moderation: 3
            callback: (c) !->
                for id in chatCommands.parseUserArg c.replace(/^\/\w+\s*/, '')
                    user = getUser(id)
                    if user?.role > 0
                        API.moderateSetRole(id, user.role - 1)
        destaff:
            parameters: " @username(s)"
            description: "removes the specified user(s) from the staff"
            moderation: 3
            callback: (c) !->
                for id in chatCommands.parseUserArg c.replace(/^\/\w+\s*/, '')
                    user = getUser(id)
                    if user?.role > 0
                        API.moderateSetRole(id, 0)
        rdj:
            aliases: <[ resident residentDJ dj ]>
            parameters: " @username(s)"
            description: "makes the specified user(s) resident DJ"
            moderation: 3
            callback: (c) !->
                for id in chatCommands.parseUserArg c.replace(/^\/\w+\s*/, '')
                    user = getUser(id)
                    if user?.role > 0
                        API.moderateSetRole(id, 1)
        bouncer:
            aliases: <[ helper temp staff ]>
            parameters: " @username(s)"
            description: "makes the specified user(s) bouncer"
            moderation: 3
            callback: (c) !->
                for id in chatCommands.parseUserArg c.replace(/^\/\w+\s*/, '')
                    user = getUser(id)
                    if user?.role > 0
                        API.moderateSetRole(id, 2)
        manager:
            parameters: " @username(s)"
            description: "makes the specified user(s) manager"
            moderation: 4
            callback: (c) !->
                for id in chatCommands.parseUserArg c.replace(/^\/\w+\s*/, '')
                    user = getUser(id)
                    if user?.role > 0
                        API.moderateSetRole(id, 3)
        cohost:
            aliases: <[ co-host co ]>
            parameters: " @username(s)"
            description: "makes the specified user(s) co-host"
            moderation: 5
            callback: (c) !->
                for id in chatCommands.parseUserArg c.replace(/^\/\w+\s*/, '')
                    user = getUser(id)
                    if user?.role > 0
                        API.moderateSetRole(id, 4)
        host:
            parameters: " @username"
            description: "makes the specified user the communities's host (USE WITH CAUTION!)"
            moderation: 5
            callback: (c) !->
                user = getUser(chatCommands.parseUserArg c.replace(/^\/\w+\s*/, ''))
                if user?.role > 0
                    API.moderateSetRole(id, 5)


/*@source p0ne.base.ls */
/**
 * Base plug_p0ne modules
 *
 * @author jtbrinkmann aka. Brinkie Pie
 * @license MIT License
 * @copyright (c) 2015 J.-T. Brinkmann
 */


/*####################################
#           DISABLE/STATUS           #
####################################*/
module \disableCommand, do
    setup: ({addListener}) !->
        addListener API, \chat, (msg) !~>
            if msg.message.has("!disable") and API.hasPermission(msg.uid, API.ROLE.BOUNCER) and isMention(msg)
                console.warn "[DISABLE] '#{status}'"
                enabledModules = []; disabledModules = []
                for ,m of p0ne.modules when m.disableCommand
                    if not m.disabled
                        enabledModules[*] = m.displayName || m.name
                        m.disable!
                    else
                        disabledModules[*] = m.displayName || m.name
                response = "@#{msg.un} "
                if enabledModules.length
                    response += "disabled #{humanList enabledModules}."
                if disabledModules.length
                    response += " #{humanList disabledModules} #{if disabledModules.length == 1 then 'was' else 'were'} already disabled."
                API.sendChat response

module \getStatus, do
    module: !->
        status = "Running plug_p0ne v#{p0ne.version}"
        status += " (incl. chat script)" if window.p0ne_chat
        status += "\tand plug³ v#{that}" if getPlugCubedVersion!
        status += "\tand plugplug #{window.getVersionShort!}" if window.ppSaved
        status += ".\tStarted #{ago p0ne.started}"
        modules = [m for m in disableCommand.modules when window[m] and not window[m].disabled]
        status += ".\t#{humanList modules} are enabled" if modules.length

module \statusCommand, do
    timeout: false
    setup: ({addListener}) !->
        addListener API, \chat, (data) !~> if not @timeout
            if data.message.has( \!status ) and data.message.has("@#{user.username}") and API.hasPermission(data.uid, API.ROLE.BOUNCER)
                @timeout = true
                status = "#{getStatus!}"
                console.info "[AUTORESPOND] status: '#status'", data.uid, data.un
                API.sendChat status, data
                sleep 30min *60_000to_ms, !->
                    @timeout = false
                    console.info "[status] timeout reset"




/*####################################
#             AUTOJOIN               #
####################################*/
module \autojoin, do
    displayName: "Autojoin"
    help: '''
        Automatically join the waitlist again after you DJ'd or if the waitlist gets unlocked.
        It will disable itself, if you got removed from the waitlist by a moderator.
    '''
    settings: \base
    settingsVip: true
    disabled: true
    disableCommand: true
    optional: <[ _$context booth socketListeners ]>
    setup: ({addListener}) !->
        # initial autojoin
        join! if API.getDJ!?.id != userID and API.getWaitListPosition! == -1

        # autojoin on DJ advances, Waitlist changes and reconnects
        addListener API, 'advance waitListUpdate ws:reconnected sjs:reconnected p0ne:reconnected', (d) !->
            if API.getDJ!?.id != userID and API.getWaitListPosition! == -1
                if join!
                    console.log "#{getTime!} [autojoin] joined waitlist"
                else
                    console.error "#{getTime!} [autojoin] failed to join waitlist"
                    API.once \advance, @autojoin, this

        # when DJ Wait List gets unlocked
        wasLocked = $djButton.hasClass \is-locked
        addListener _$context, \djButton:update, !~>
            isLocked = $djButton.hasClass \is-locked
            join! if wasLocked and not isLocked
            wasLocked := isLocked

        # disable when user gets removed by a moderator
        addListener API, \socket:modRemoveDJ, (e) !~> if e.t == API.getUser!.rawun
            @disable!



/*module \autojoin, do
    displayName: "Autojoin"
    help: '''
        Automatically join the waitlist again after you DJ'd or if the waitlist gets unlocked.
        It will not automatically join if you got removed from the waitlist by a moderator.
    '''
    settings: \base
    settingsVip: true
    disabled: true
    disableCommand: true
    optional: <[ _$context booth ]>
    setup: ({addListener}) !->
        wlPos = API.getWaitListPosition!
        if wlPos == -1
            @autojoin!
        else if API.getDJ!?.id == userID
            API.once \advance, @autojoin, this

        # regular autojoin
        addListener API, \advance, !~>
            if API.getDJ!?.id == userID # if user is the current DJ, delay autojoin until next advance
                API.once \advance, @autojoin, this

        # autojoin on reconnect
        addListener API, \p0ne:reconnected, !~>
            if wlPos != -1 # make sure we were actually in the waitlist before autojoining
                @autojoin!

        $djButton = $ \#dj-button
        if _$context?
            # when joining a room
            addListener _$context, \room:joined, @autojoin, this

            # when DJ booth gets unlocked
            wasLocked = $djButton.hasClass \is-locked
            addListener _$context, \djButton:update, !~>
                isLocked = $djButton.hasClass \is-locked
                @autojoin! if wasLocked and not isLocked
                wasLocked := isLocked

        #DEBUG
        # compare if old logic would have autojoined
        addListener API, \advance, (d) !~>
            if d and d.id != userID and API.getWaitListPosition! == -1
                sleep 5_000ms, !~> if API.getDJ!.id != userID and API.getWaitListPosition! == -1
                    chatWarn "old algorithm would have autojoined now. Please report about this in the beta tester Skype chat", "plug_p0ne autojoin"

    autojoin: !->
        if API.getWaitListPosition! == -1 # if user is not in the waitlist yet
            if join!
                console.log "#{getTime!} [autojoin] joined waitlist"
            else
                console.error "#{getTime!} [autojoin] failed to join waitlist"
                API.once \advance, @autojoin, this
        #else # user is already in the waitlsit
        #    console.log "#{getTime!} [autojoin] already in waitlist"

    disable: !->
        API.off \advance, @autojoin
*/

/*####################################
#             AUTOWOOT               #
####################################*/
module \autowoot, do
    displayName: 'Autowoot'
    help: '''
        automatically woot all songs (you can still manually meh)
    '''
    settings: \base
    settingsVip: true
    disabled: true
    disableCommand: true
    optional: <[ chatDomEvents ]>
    _settings:
        warnOnMehs: true
    setup: ({addListener}) !->
        var timer, timer2
        lastScore = API.getHistory!.1.score
        hasMehWarning = false

        # on each song
        addListener API, \advance, (d) !->
            if d.media
                lastScore = d.lastPlay.score
                clearTimeout timer
                # wait between 1 to 4 seconds (to avoid flooding plug.dj servers)
                timer := sleep 1.s  +  3.s * Math.random!, !->
                    if not API.getUser!.vote # only woot if user didn't vote already
                        console.log "#{getTime!} [autowoot] autowooting"
                        woot!
            if hasMehWarning
                clearTimeout(timer2)
                $cms! .find \.p0ne-autowoot-meh-btn .closest \.cm .remove!
                hasMehWarning := false

        # warn if user is blocking a voteskip
        addListener API, \voteUpdate, (d) !~>
            score = API.getScore!
            # some number magic
            if @_settings.warnOnMehs and (score.negative > 2 * score.positive and score.negative > (lastScore.positive + lastScore.negative) / 4 and score.negative >= 5) and not hasMehWarning and API.getTimeRemaining! > 30s
                timer2 := sleep 5_000ms, !->
                    chatWarn "Many users meh'd this song, you may be preventing a voteskip. <span class=p0ne-autowoot-meh-btn>Click here to meh</span> if you dislike the song", "Autowoot", true
                    playChatSound!
                hasMehWarning := true

        # make the meh button meh
        addListener chatDomEvents, \click, \.p0ne-autowoot-meh-btn, !->
            meh!
            $ this .closest \.cm .remove!


/*####################################
#              AUTOMUTE              #
####################################*/
module \automute, do
    optional: <[ streamSettings ]>
    _settings:
        songlist: {}

    setup: ({addListener}, automute) !->
        @songlist = @_settings.songlist
        media = API.getMedia!
        addListener API, \advance, (d) !~>
            if (media := d.media) and @songlist[media.cid]
                console.info "[automute] '#{media.author} - #{media.title}' is in automute list. Automuting…"
                #muteonce!
                snooze!

        #== Turn SNOOZE button into add/remove AUTOMUTE button when media is snoozed ==
        $snoozeBtn = $ '#playback .snooze'
        @$box_ = $snoozeBtn .children!
        $box = $ "<div class='box'></div>"
        streamOff = isSnoozed!
        addListener API, \p0ne:changeMode, onModeChange = (mode) !~>
            newStreamOff = (mode == \off)
            <~ requestAnimationFrame
            if newStreamOff
                if not streamOff
                    $snoozeBtn
                        .empty!
                        .append $box
                if not media
                    # umm, this shouldn't happen. when there's no song playing, there shouldn't be playback-controls
                    console.warn "[automute] uw0tm8? how did the stream mode change if there's no song playing? well this could happen if you changed the room or something…"
                else if @songlist[media.cid] # btn "remove from automute"
                    console.log "[automute] change automute-btn to REMOVE"
                    $snoozeBtn .addClass 'p0ne-automute p0ne-automute-remove'
                    $box .html "remove from<br>automute"
                else # btn "add to automute"
                    console.log "[automute] change automute-btn to ADD"
                    $snoozeBtn .addClass 'p0ne-automute p0ne-automute-add'
                    $box .html "add to<br>automute"
            else if streamOff
                console.log "[automute] change automute-btn to SNOOZE"
                $snoozeBtn
                    .empty!
                    .append @$box_
                    .removeClass 'p0ne-automute p0ne-automute-remove p0ne-automute-add'
            streamOff := newStreamOff

        @updateBtn = (mode) !->
            onModeChange(streamOff && \off)

        addListener $snoozeBtn, \click, (e) !~>
            if streamOff
                console.info "[automute] snoozy", media.cid, @songlist[media.cid], streamOff
                automute!

    module: (media, isAdd) !->
        # add/remove/toggle `media` to/from/in list of automuted songs
        # and show a notification in chat

        # (isAdd)
        if typeof media == \boolean
            isAdd = media; media = false

        # (media, isAdd) and (media)
        if media
            if media.toJSON
                media = media.toJSON!
            if not media.cid or not \author of media
                throw new TypeError "invalid arguments for automute(media, isAdd=)"
        else
            # default `media` to current media
            media = API.getMedia!

        if isAdd == \toggle or not isAdd? # default to toggle
            isAdd = not @songlist[media.cid]

        $msg = $ "<div class='p0ne-automute-notif'>"
        if isAdd # add to automute list
            @songlist[media.cid] = media
            $msg
                .text "+ automute #{media.author} - #{media.title}"
                .addClass \p0ne-automute-added
        else # remove from automute list
            delete @songlist[media.cid]
            $msg
                .text "- automute #{media.author} - #{media.title}'"
                .addClass \p0ne-automute-removed
        $msg .append getTimestamp!
        appendChat $msg
        if media.cid == API.getMedia!?.cid
            @updateBtn!

    disable: !->
        $ '#playback .snooze'
            .empty!
            .append @$box_


/*####################################
#          AFK AUTORESPOND           #
####################################*/
module \afkAutorespond, do
    displayName: 'AFK Autorespond'
    settings: \base
    settingsVip: true
    _settings:
        message: "I'm AFK at the moment"
        timeout: 1.min
    disabled: true
    disableCommand: true

    DEFAULT_MSG: "I'm AFK at the moment"
    setup: ({addListener, $create}) !->
        timeout = true
        sleep @_settings.timeout, !-> timeout := false
        addListener API, \chat, (msg) !~>
            if msg.uid and msg.uid != userID and not timeout and isMention(msg, true) and not msg.message.has \!disable
                # it is neglected that a non-staff might send a @mentioning message with "!disable"
                API.sendChat "[AFK] #{@_settings.message || @DEFAULT_MSG}"
                timeout := true
                sleep @_settings.timeout, !-> timeout := false
            else if msg.uid == userID
                timeout := true
                sleep @_settings.timeout, !-> timeout := false
        $create '<div class=p0ne-afk-button>'
            .text "Disable #{@displayName}"
            .click !~> @disable! # we cannot just `.click(@disable)` because `disable` should be called without any arguments
            .appendTo \#footer-user

    settingsExtra: ($el) !->
        $input = $ "<input class=p0ne-settings-input placeholder=\"#{@DEFAULT_MSG}\">"
            .val @_settings.message
            .on \input, !~>
                @_settings.message = $input.val!
            .appendTo $el


/*####################################
#      JOIN/LEAVE NOTIFICATION       #
####################################*/
module \joinLeaveNotif, do
    optional: <[ chatDomEvents chat auxiliaries database ]>
    settings: \base
    settingsVip: true
    displayName: 'Join/Leave Notifications'
    help: '''
        Shows notifications for when users join/leave the room in the chat.
        Note: the country flags indicate the user's plug.dj language settings, they don't necessarily have to match where they are from.

        Icons explained:
        + user joined
        - user left
        \u21ba user reconnected (left and joined again)
        \u21c4 user joined and left again
    '''
    _settings:
        mergeSameUser: true
    setup: ({addListener, css}, joinLeaveNotif, update) !->
        if update
            lastMsg = $cm! .children! .last!
            if lastMsg .hasClass \p0ne-notif-joinleave
                $lastNotif = lastMsg

        CHAT_TYPE = \p0ne-notif-joinleave
        lastUsers = {}

        #usersInRoom = {}
        cssClasses =
            userJoin: \join
            userLeave: \leave
            refresh: \refresh
            instaLeave: \instaleave
        for let event_ in <[ userJoin userLeave ]>
            addListener API, event_, (u) !->
                event = event_
                if not reuseNotif = (chat?.lastType == CHAT_TYPE and $lastNotif)
                    lastUsers := {}


                title = ''
                if reuseNotif and lastUsers[u.id] and joinLeaveNotif._settings.mergeSameUser
                    if event == \userJoin != lastUsers[u.id].event
                        event = \refresh
                        title = "title='reconnected'"
                    else if event == \userLeave != lastUsers[u.id].event
                        event = \instaLeave
                        title = "title='joined and left again'"

                $msg = $ "
                    <div class=p0ne-notif-#{cssClasses[event]} data-uid=#{u.id} #title>
                        #{formatUserHTML u, user.isStaff, false}
                        #{getTimestamp!}
                    </div>
                    "

                # cache users in this notification
                if event == event_
                    lastUsers[u.id] =
                        event: event
                        $el: $msg

                if reuseNotif
                    isAtBottom = chatIsAtBottom!
                    if event != event_
                        lastUsers[u.id].$el .replaceWith $msg
                        delete lastUsers[u.id]
                    else
                        $lastNotif .append $msg
                    chatScrollDown! if isAtBottom
                else
                    $lastNotif := $ "<div class='cm update p0ne-notif p0ne-notif-joinleave'>"
                        .append $msg
                    appendChat $lastNotif
                    if chat?
                        chat.lastType = CHAT_TYPE
 
        addListener API, 'popout:open popout:close', !->
            $lastNotif = $cm! .find \.p0ne-notif-joinleave:last





/*####################################
#     CURRENT SONG TITLE TOOLTIP     #
####################################*/
# add a tooltip (alt attr.) to the song title (in the header above the playback container)
module \titleCurrentSong, do
    disable: !->
        $ \#now-playing-media .prop \title, ""
    setup: ({addListener}) !->
        addListener API, \advance, (d) !->
            if d.media
                $ \#now-playing-media .prop \title, "#{d.media.author} - #{d.media.title}"
            else
                $ \#now-playing-media .prop \title, null


/*####################################
#       MORE ICON IN USERLIST        #
####################################*/
module \userlistIcons, do
    require: <[ users RoomUserRow ]>
    _settings:
        forceMehIcon: false
    setup: ({replace})  !->
        settings = @_settings
        replace RoomUserRow::, \vote, !-> return !->
            if @model.id == API.getDJ!?.id
                /* fixed in Febuary 2015 http://tech.plug.dj/2015/02/18/version-1-2-7-6478/
                if vote # stupid haxxy edge-cases… well to be fair, I don't see many other people but me abuse that >3>
                    if not @$djIcon
                        @$djIcon = $ '<i class="icon icon-current-dj" style="right: 35px">'
                            .appendTo @$el
                        API.once \advance, !~>
                            @$djIcon .remove!
                            delete @$djIcon
                else*/
                vote = \dj
            else if @model.get \grab
                vote = \grab
            else
                vote = @model.get \vote
                vote = 0 if vote == -1 and not user.isStaff and not settings.forceMehIcon # don't show mehs to non-staff
                # personally, i think RDJs should be able to see mehs as well
            if vote != 0
                if @$icon
                    @$icon .removeClass!
                else
                    @$icon = $ \<i>
                        .appendTo @$el
                @$icon
                    .addClass \icon

                if vote == -1
                    @$icon.addClass \icon-meh
                else if vote == \grab
                    @$icon.addClass \icon-grab
                else if vote == \dj
                    @$icon.addClass \icon-current-dj
                else
                    @$icon.addClass \icon-woot
            else if @$icon
                @$icon .remove!
                delete @$icon

            # fix username
            if chatPolyfixEmoji?.fixedUsernames[@model.id]
                @$el .find \.name .html that

        @updateEvents!

    updateEvents: !->
        for u in users.models when u._events
            for event in u._events[\change:vote] ||[] when event.ctx instanceof RoomUserRow
                event.callback = RoomUserRow::vote
            for event in u._events[\change:grab] ||[] when event.ctx instanceof RoomUserRow
                event.callback = RoomUserRow::vote

    disableLate: !->
        @updateEvents!


/*####################################
#        DBLCLICK to @MENTION        #
####################################*/
/*note: this is also makes usernames clickable in many other parts of plug.dj & other plug_p0ne modules */
module \chatDblclick2Mention, do
    require: <[ chat simpleFixes ]>
    #optional: <[ PopoutListener ]>
    settings: \chat
    displayName: 'DblClick username to Mention'
    setup: ({replace, addListener}, chatDblclick2Mention) !->
        newFromClick = (e) !->
            # after a click, wait 0.2s
            # if the user clicks again, consider it a double click
            # otherwise fall back to default behaviour (show user rollover) 
            e .stopPropagation!; e .preventDefault!

            # single click
            if not chatDblclick2Mention.timer
                chatDblclick2Mention.timer = sleep 200ms, !~> if chatDblclick2Mention.timer
                    try
                        chatDblclick2Mention.timer = 0
                        $this = $ this
                        if r = ($this .closest \.cm .children \.badge-box .data \uid) || ($this .data \uid) || (i = getUserInternal $this.text!)?.id
                            pos =
                                x: chat.getPosX!
                                y: $this .offset!.top
                            if i ||= getUserInternal(r)
                                chat.onShowChatUser i, pos
                            else
                                chat.getExternalUser r, pos, chat.showChatUserBind
                        else
                            console.warn "[dblclick2Mention] couldn't get userID", this
                    catch err
                        console.error "[dblclick2Mention] error showing user rollover", err.stack

            # double click
            else
                clearTimeout chatDblclick2Mention.timer
                chatDblclick2Mention.timer = 0
                (PopoutView?.chat || chat).onInputMention e.target.textContent

        for [ctx, $el, attr, boundAttr] in [ [chat, $cms!, \onFromClick, \fromClickBind],  [WaitlistRow::, $(\#waitlist), \onDJClick, \clickBind],  [RoomUserRow::, $(\#user-lists), \onClick, \clickBind] ]
            # remove individual event listeners (we use a delegated event listener below)
            # setting them to `$.noop` will prevent .bind to break
            #replace ctx, attr, !-> return $.noop
            # setting them to `null` will make `.on("click", …)` in the vanilla code do nothing (this requires the underscore.bind fix)
            replace ctx, attr, noop
            if ctx[boundAttr]
                replace ctx, boundAttr, !-> noop

            # update DOM event listeners
            $el .off \click, ctx[boundAttr]


        # instead of individual event listeners, we use a delegated event (which offers better performance)
        addListener chatDomEvents, \click, \.un, newFromClick
        addListener $body, \click, '.p0ne-name, .app-right .name', newFromClick
        #                                                       , #history-panel .name

        function noop
            return null

    disableLate: !->
        # note: here we actually have to pay attention as to what to re-enable
        cm = $cms!
        for attr, [ctx, $el] of {fromClickBind: [chat, cm], onDJClick: [WaitlistRow::, $(\#waitlist)], onClick: [RoomUserRow::, $(\#user-lists)]}
            $el .find '.mention .un, .message .un, .name'
                .off \click, ctx[attr] # if for some reason it is already re-assigned
                .on \click, ctx[attr]


/*####################################
#             ETA  TIMER             #
####################################*/
module \etaTimer, do
    displayName: 'ETA Timer'
    settings: \base
    optional: <[ _$context ]>
    setup: ({css, addListener, $create}) !->
        css \etaTimer, '
            .p0ne-eta {
                position: absolute;
            }
            #your-next-media>span {
                width: auto !important;
                right: 50px;
            }
        '
        # we put ".p0ne-eta { position: absolute; }" in here instead of plug_p0ne.css so $eta's width is calculated correctly even while the stylesheets are loading
        sum = lastSongDur = tooltipIntervalID = 0
        showingTooltip = false
        $nextMediaLabel = $ '#your-next-media > span'
        $eta = $create '<div class=p0ne-eta>'
            .append $etaText = $ '<span class=p0ne-eta-text>ETA: </span>'
            .append $etaTime = $ '<span class=p0ne-eta-time></span>'
            .mouseover !->
                if _$context?
                    updateToolTip!
                    clearInterval tooltipIntervalID
                    tooltipIntervalID := repeat 1_000ms, updateToolTip

                function updateToolTip
                    # show ETA calc
                    p = API.getWaitListPosition!
                    p = API.getWaitList!.length if p == -1
                    avg = sum / l |> Math.round
                    rem = API.getTimeRemaining!
                    if p
                        _$context.trigger \tooltip:show, "#{mediaTime rem} remaining + #p × #{mediaTime avg} avg. song duration", $etaText
                    else if rem
                        _$context.trigger \tooltip:show, "#{mediaTime rem} remaining, the waitlist is empty", $etaText
                    else
                        _$context.trigger \tooltip:show, "Nobody is playing and the waitlist is empty", $etaText
            .mouseout !->
                if _$context?
                    clearInterval tooltipIntervalID
                    _$context.trigger \tooltip:hide
            .appendTo \#playlist-meta


        # note: the ETA timer cannot be shown while the room's history is 0
        # because you need to be in the waitlist to see the ETA timer


        # attach event listeners
        addListener API, \waitListUpdate, updateETA
        addListener API, \advance, (d) !->
            # update average song duration. This is to avoid having to loop through the whole song history on each update
            if d.media
                sum -= lastSongDur
                sum += d.media.duration
                lastSongDur := API.getHistory![l - 1].media.duration
            # note: we don't trigger updateETA() because each advance is accompanied with a waitListUpdate
        if _$context?
            addListener _$context, \room:joined, updateETA

        # initialize average song length
        # (this is AFTER the event listeners, because tinyhist() has to run after it)
        hist = API.getHistory!
        l = hist.length

        # handle the case that history length is < 50
        if l < 50 # the history seems to be sometimes up to 51 and sometimes up to 50 .-.
            #lastSongDur = 0
            do tinyhist = !->
                addListener \once, API, \advance, (d) !->
                    if d.media
                        lastSongDur := 0
                        l++
                    tinyhist! if l < 50
        else
            l = 50
            lastSongDur = hist[l - 1].media.duration
        for i from 0 til l
            sum += hist[i].media.duration

        # show the ETA timer
        updateETA!

        addListener API, \p0ne:stylesLoaded, !-> requestAnimationFrame !->
            console.info "[TEST stylesLoaded] $eta.width: #{$eta.width!}"
            $nextMediaLabel .css right: $eta.width! - 50px

        var lastETA
        ~function updateETA
            # update what the ETA timer says
            #clearTimeout @timer
            p = API.getWaitListPosition()
            if p == 0
                $etaText .text "you are next DJ!"
                $etaTime .text ''
                return
            else if p == -1
                if API.getDJ!?.id == userID
                    $etaText .text "you are DJ!"
                    $etaTime .text ''
                    return
                else
                    if 0 == (p = API.getWaitList! .length)
                        $etaText .text 'Join now to '
                        $etaTime .text "DJ instantly"
                        return
            # calculate average duration
            eta_ = (API.getTimeRemaining!  +  sum * p / l)
            eta = eta_ / 60 |> Math.round

            #console.log "[ETA] updated to (#eta min)"
            if lastETA != eta
                lastETA := eta
                $etaText .text "ETA ca. "
                if eta > 60min
                    $etaTime .text "#{~~(eta / 60)}h #{eta % 60}min"
                else
                    $etaTime .text "#eta min"
                $nextMediaLabel .css right: $eta.width! - 50px

                # setup timer to update ETA
                if eta_ > 0 # when disconnecting from the socket, it might be that API.getTimeRemaining! returns a negative number
                    clearTimeout @timer
                    @timer = sleep ((eta_ % 60s)+31s).s, updateETA
    disable: !->
        clearTimeout @timer


/*####################################
#              VOTELIST              #
####################################*/
module \votelist, do
    settings: \base
    displayName: 'Votelist'
    disabled: true
    help: '''
        Moving your mouse above the woot/grab/meh icon shows a list of users who have wooted, grabbed or meh'd respectively.
    '''
    setup: ({addListener, $create}) !->
        $tooltip = $ \#tooltip
        currentFilter = false
        $vote = $(\#vote)
        $vl = $create '<div class=p0ne-votelist>'
            .hide!
            .appendTo $vote

        addListener $(\#woot), \mouseenter, changeFilter 'left: 0', (userlist) !->
            for u in API.getAudience! when u.vote == +1
                userlist += "<div>#{formatUserHTML(u, false, true)}</div>"
            return userlist

        addListener $(\#grab), \mouseenter, changeFilter 'left: 50%; transform: translateX(-50%)', (userlist) !->
            for u in API.getAudience! when u.grab
                userlist += "<div>#{formatUserHTML(u, false, true)}</div>"
            return userlist

        addListener $(\#meh), \mouseenter, changeFilter 'right: 0', (userlist) !-> if user.isStaff
            for u in API.getAudience! when u.vote == -1
                userlist += "<div>#{formatUserHTML(u, false, true)}</div>"
            return userlist


        addListener $vote, \mouseleave, !->
            currentFilter := false
            $vl.hide!
            $tooltip .show!

        addListener API, \voteUpdate, updateVoteList

        function changeFilter styles, filter
            return !->
                currentFilter := filter
                css \votelist, ".p0ne-votelist { #{styles} }"
                updateVoteList!

        function updateVoteList
            if currentFilter
                # empty string as argument for code optimization
                userlist = currentFilter('')
                if userlist
                    $vl
                        .html userlist
                        .show!
                    if not $tooltip.length
                        $tooltip := $ \#tooltip
                    $tooltip .hide!
                else
                    $vl.hide!
                    $tooltip .show!


/*####################################
#             USER POPUP             #
####################################*/
# adds a user-rollover to the FriendsList when clicking someone's name
module \friendslistUserPopup, do
    require: <[ friendsList FriendsList chat ]>
    setup: ({addListener}) !->
        addListener $(\.friends), \click, '.name, .image', (e) !->
            id = friendsList.rows[$ this.closest \.row .index!] ?.model.id
            user = users.get(id) if id
            data = x: $body.width! - 353px, y: e.screenY - 90px
            if user
                chat.onShowChatUser user, data
            else if id
                chat.getExternalUser id, data, (user) !->
                    chat.onShowChatUser user, data
        #replace friendsList, \drawBind, !-> return _.bind friendsList.drawRow, friendsList
# adds a user-rollover to the WaitList when clicking someone's name
module \waitlistUserPopup, do
    require: <[ WaitlistRow ]>
    setup: ({replace}) !->
        replace WaitlistRow::, "render", (r_) !-> return !->
            r_ ...
            @$ '.name, .image' .click @clickBind



/*####################################
#            BOOTH  ALERT            #
####################################*/
module \boothAlert, do
    displayName: 'Booth Alert'
    settings: \base
    help: '''
        Play a notification sound before you are about to play
    '''
    _settings:
        warnOnPrevPlay: true # takes precedence
        warnXMinBefore: 2.min # note: when modifying this, please update `boothAlert.remainingStr`
    setup: ({addListener}, {_settings}, module_) !->
        var warnTimeout
        @remainingStr = humanTime _settings.warnXMinBefore
        isNext = false
        fn = addListener API, 'advance waitListUpdate ws:reconnected sjs:reconnected p0ne:reconnected', !->
            if API.getWaitListPosition! == 0
                if _settings.warnOnPrevPlay
                    if not isNext
                        isNext := true
                        sleep 3_000ms, !->
                            chatWarn "You are about to DJ next!", "Booth Alert"
                            playChatSound!
                else
                    clearTimeout warnTimeout
                    remaining = API.getTimeRemaining! *1000s_to_ms
                    warnTimeout := sleep remaining - _settings.warnXMinBefore, !->
                        if remaining > 0
                            chatWarn "You are about to DJ in #{humanTime remaining}!", "Booth Alert"
                        else
                            chatWarn "You are about to DJ in #remainingStr!", "Booth Alert"
                        playChatSound!
            else
                isNext := false
        fn! if not module_
    settingsExtra: ($el) !->
        boothAlert = this
        var resetTimer
        $ "<form>
                Show notification<br>
                <label><input type=radio name=booth-alert value=on #{if @_settings.warnOnPrevPlay then \checked else ''}> on preceding song</label><br>
                <label>
                    <input type=radio name=booth-alert value=off #{if @_settings.warnOnPrevPlay then '' else \checked}> <input type=number value='#{~~(@_settings.warnXMinBefore / 600) / 100}' class='p0ne-settings-input booth-alert'> minute(s)<br>
                    before your play
                </label>
            </form>"
            .append do
                $warning = $ '<div class=warning>'
            .on \click, \input:radio, !->
                if @checked
                    boothAlert._settings.warnOnPrevPlay = (@value == \on)
                    console.log "#{getTime!} [boothAlert] updated warnOnPrevPlay to #{boothAlert._settings.warnOnPrevPlay}"
            .on \input, \.booth-alert, !->
                if @value > 0 #  # note: returns false for non-number inputs
                    boothAlert._settings.warnXMinBefore = @value .min
                    if resetTimer
                        $warning .fadeOut!
                        clearTimeout resetTimer
                        resetTimer := 0
                    if boothAlert._settings.warnOnPrevPlay
                        $ this .parent! .click!
                    console.log "#{getTime!} [boothAlert] updated to #{@value}ms"
                else
                    $warning
                        .fadeIn!
                        .text "please enter a valid number >0"
                    resetTimer := sleep 2.min, !~>
                        @value = ~~(boothAlert._settings.warnXMinBefore * 60_000_00) / 100
                        resetTimer := 0
                    console.warn "#{getTime!} [boothAlert] invalid input for X min", @value
            .appendTo $el
        $el .css do
            paddingLeft: 15px


/*####################################
#         AVOID HISTORY PLAY         #
####################################*/
module \avoidHistoryPlay, do
    settings: \base
    displayName: '☢ Avoid History Plays'
    help: '''
        [WORK IN PROGRESS]

        This avoid playing songs that are already in history
    '''
    require: <[ app ]>
    setup: ({addListener}) !->
        #TODO make sure that `playlist` is actually the active playlist, not just the one the user is looking at
        # i.e. use another object which holds the next songs of the current playlist
        playlist = app.footer.playlist.playlist.media
        addListener API, \advance, (d) !->
            if d.media and d.dj?.id != userID
                if playlist.list?.rows?.0?.model.cid == d.media.cid  and  getActivePlaylist?
                    chatWarn 'moved down', '☢ Avoid History Plays'
                    ajax \PUT, "playlists/#{getActivePlaylist!.id}/media/move", do
                        beforeID: -1
                        ids: [id]
            else
                API.once \advance, checkOnNextAdv

        !function checkOnNextAdv d
            # assuming that the playlist did not already advance
            console.info "[Avoid History Plays]", playlist.list?.rows?.0?.model, playlist.list?.rows?.1?.model
            return if not (nextSong = playlist.list?.rows?.1?.nextSong) or not getActivePlaylist?
            for s in API.getHistory!
                if s.media.cid == nextSong.cid
                    chatWarn 'moved down', '☢ Avoid History Plays'
                    ajax \PUT, "playlists/#{getActivePlaylist!.id}/media/move", do
                        beforeID: -1
                        ids: [nextSong.id]
        do @checkOnNextAdv = checkOnNextAdv

/*####################################
#         WARN ON PAGE LEAVE         #
####################################*/
module \warnOnPageLeave, do
    displayName: "Warn on Leaving plug.dj"
    settings: \base
    setup: ({addListener}) !->
        addListener $window, \beforeunload, !~>
            #return "[plug_p0ne] Are you sure you want to leave the page?"
            # Chrome shows the text + "Are you sure you want to leave the page? [Leave this page] [Stay on this page]"
            # Firefox always shows "This page is asking you to confirm that you want to leave - data you have entered may not be saved. [Leave Page] [Stay on Page]"
            return "[plug_p0ne Warn on Leaving plug.dj] \n(you can disable this warning in the settings under #{@settings .toUpperCase!} > #{@displayName})"

/*@source p0ne.chat.ls */
/**
 * chat-related plug_p0ne modules
 *
 * @author jtbrinkmann aka. Brinkie Pie
 * @license MIT License
 * @copyright (c) 2015 J.-T. Brinkmann
 */

/* ToDo:
 * add missing chat inline image plugins:
 * Derpibooru
 * imgur.com/a/
 * tumblr
 * deviantart
 * gfycat.com
 * cloud-4.steampowered.com … .resizedimage
 */


MAX_IMAGE_HEIGHT = 300px # should be kept in sync with p0ne.css





/*####################################
#         BETTER CHAT INPUT          #
####################################*/
module \betterChatInput, do
    require: <[ chat user ]>
    optional: <[ user_ _$context PopoutListener Lang ]>
    displayName: "Better Chat Input"
    settings: \chat
    help: '''
        Replaces the default chat input field with a multiline textfield.
        This allows you to more accurately see how your message will actually look when send
    '''
    setup: ({addListener, replace, revert, css, $create}) !->
        # apply styles
        css \p0ne_chat_input, '
            #chat-input {
                bottom: 7px;
                height: auto;
                background: transparent !important;
                min-height: 30px;
            }
            #chat-input-field {
                position: static;
                resize: none;
                height: 16px;
                overflow: hidden;
                margin-left: 8px;
                color: #eee;
                background: rgba(0, 24, 33, .7);
                box-shadow: inset 0 0 0 1px transparent;
                transition: box-shadow .2s ease-out;
            }
            .popout #chat-input-field {
                box-sizing: content-box;
            }
            #chat-input-field:focus {
                box-shadow: inset 0 0 0 1px #009cdd !important;
            }

            .autoresize-helper {
                display: none;
                white-space: pre-wrap;
                word-wrap: break-word;
            }

            #chat-input-field, .autoresize-helper {
                width: 295px;
                padding: 8px 10px 5px 10px;
                min-height: 16px;
                font-weight: 400;
                font-size: 12px;
                font-family: Roboto,sans-serif;
            }

            /* emote */
            .p0ne-better-chat-emote {
                font-style: italic;
            }

            /*fix chat-messages size*/
            #chat-messages {
                height: auto !important;
                bottom: 45px;
            }
        '

        var $autoresize_helper, oldHeight
        chat = window.chat

        # back up elements
        @cIF_ = chat.$chatInputField.0
        @$form = chat.$chatInputField.parent!

        focused = chat.$chatInputField .hasClass \focused
        #val = chat.$chatInputField .val!
        chat.$chatInput .removeClass \focused # fix permanent focus class


        # add new input text-area
        init = addListener API, \popout:open, (,PopoutView) !~>
            chat := PopoutView.chat
            @popoutcIF_ = chat.$chatInputField.0
            @$popoutForm = chat.$chatInputField.parent!
            val = window.chat.$chatInputField .val!
            focused = window.chat.$chatInputField .is \:focus
            #oldHeight := chat.$chatInputField .height!
            chat.$chatInputField .detach!
            chat.$chatInputField.0 = chat.chatInput = $create "<textarea id='chat-input-field' maxlength=256>"
                .attr \tabIndex, 1
                .val val
                .focus! # who doesn't want to have the chat focused?
                .attr \placeholder, Lang?.chat.placeholder || "Chat"
                # add DOM event Listeners from original input field (not using .bind to allow custom chat.onKey* functions)
                .on \keydown, (e) !->
                    chat.onKeyDown e
                .on \keyup, (e) !->
                    chat.onKeyUp e
                #.on \focus, _.bind(chat.onFocus, chat)
                #.on \blur, _.bind(chat.onBlur, chat)

                # add event listeners for autoresizing
                .on \input, onInput
                .on \keydown, checkForMsgSend
                .appendTo @$popoutForm
                .after do
                    $autoresize_helper := $create \<div> .addClass \autoresize-helper
                .0


        # init for onpage chat
        init(null, {chat: window.chat})
        $onpage_autoresize_helper = $autoresize_helper

        # init for current popout, if any
        init(null, PopoutView) if PopoutView._window

        addListener API, \popout:close, !~>
            window.chat.$chatInputField .val(chat.$chatInputField .val!)
            chat := window.chat
            $autoresize_helper := $onpage_autoresize_helper


        chatHidden = $cm!.parent!.css(\display) == \none


        wasEmote = false
        function onInput
            content = chat.$chatInputField .val!
            if content != (content = content.replace(/\n/g, "")) #.replace(/\s+/g, " "))
                chat.$chatInputField .val content
            if content.0 == \/ and (content.1 == \m and content.2 == \e or content.1 == \e and content.2 == \m)
                if not wasEmote
                    wasEmote := true
                    chat.$chatInputField .addClass \p0ne-better-chat-emote
                    $autoresize_helper   .addClass \p0ne-better-chat-emote
            else if wasEmote
                wasEmote := false
                chat.$chatInputField .removeClass \p0ne-better-chat-emote
                $autoresize_helper   .removeClass \p0ne-better-chat-emote

            $autoresize_helper.text(content)
            newHeight = $autoresize_helper .height!
            return if oldHeight == newHeight
            #console.log "[chat input] adjusting height"
            scrollTop = chat.$chatMessages.scrollTop!
            chat.$chatInputField
                .css height: newHeight
            chat.$chatMessages
                .css bottom: newHeight + 30px
                .scrollTop scrollTop + newHeight - oldHeight
            oldHeight := newHeight

        function checkForMsgSend e
            if (e and (e.which || e.keyCode)) == 13 # ENTER
                requestAnimationFrame(onInput)


    disable: !->
        if @cIF_
            chat.$chatInputField = $ (chat.chatInput = @cIF_)
                .val chat.$chatInputField.val!
                .appendTo @$form
        else
            console.warn "#{getTime!} [betterChatInput] ~~~~ disabling ~~~~", @cIF_, @$form

        if PopoutView._window and @popoutcIF_
            PopoutView.chat.$chatInputField = $ (PopoutView.chat.chatInput = @popoutcIF_)
                .val PopoutView.chat.$chatInputField.val!
                .appendTo @$popoutForm




/*####################################
#            CHAT PLUGIN             #
####################################*/
module \chatPlugin, do
    require: <[ _$context ]>
    setup: ({addListener}) !->
        p0ne.chatLinkPlugins ||= []
        onerror = 'onerror="chatPlugin.imgError(this)"'
        addListener \early, _$context, \chat:receive, (msg) !-> # run plugins that modify chat msgs
            msg.wasAtBottom ?= chatIsAtBottom! # p0ne.saveChat also sets this
            msg.classes = {}; msg.addClass = addClass; msg.removeClass = removeClass

            _$context .trigger \chat:plugin, msg
            API .trigger \chat:plugin, msg


            # p0ne.chatLinkPlugins
            if msg.wasAtBottom
                onload = 'onload="chatScrollDown()"'
            else
                onload = ''
            msg.message .= replace /<a (.+?)>((https?:\/\/)(?:www\.)?(([^\/]+).+?))<\/a>/gi, (all,pre,completeURL,protocol,url, domain, offset)->
                domain .= toLowerCase!
                for ctx in [_$context, API] when ctx._events[\chat:image]
                    for plugin in ctx._events[\chat:image]
                        try
                            if plugin.callback.call plugin.ctx, {all,pre,completeURL,protocol,domain,url, offset,  onload,onerror,msg}
                                return that
                                #= experimental image loader =
                                #$ that
                                #    .data cid, msg.cid
                                #    .data originalURL
                                #    .appendTo $imgLoader
                                #return '<div class="p0ne-img-placeholder"><div class="p0ne-img-placeholder-text">loading…</div><div class="p0ne-img-placeholder-fancy"></div></div>'
                        catch err
                            console.error "[p0ne] error while processing chat link plugin", plugin, err.stack
                return all

        addListener _$context, \chat:receive, (e) !->
            getChat(e) .addClass Object.keys(e.classes ||{}).join(' ')
        addClassesCB = _$context._events[\chat:receive][*-1]

        addListener _$context, \popout:open, !->
            _$context._events[\chat:receive].removeItem(addClassesCB)
            _$context._events[\chat:receive].push(addClassesCB)

        !function addClass classes
            if typeof classes == \string
                for className in classes.split /\s+/g when className
                    @classes[className] = true
        !function removeClass classes
            if typeof classes == \string
                for className in classes.split /\s+/g
                    delete @classes[className]
    imgError: (elem) !->
        console.warn "[inline-img] converting image back to link", elem.alt, elem, elem.outerHTML
        $ elem .parent!
            ..text ..attr \href
            ..addClass \p0ne-img-failed


/*####################################
#           MESSAGE CLASSES          #
####################################*/
module \chatMessageClasses, do
    optional: <[ users ]>
    require: <[ chatPlugin ]>
    setup: ({addListener}) !->
        /* designed to be compatible with p³-compatible Room Themes */
        try
            $cms! .children! .each !->
                if uid = this.dataset.cid
                    uid .= substr(0, 7)
                    return if not uid
                    $this = $ this
                    if fromUser = users.get uid
                        role = getRank(fromUser, true)
                        #if role != \ghost
                        fromRole = "from-#role"
                        if role == \regular
                            fromRole = \from-you if uid == userID
                        else
                            fromRole += " from-staff"
                        /*else # stupid p³. who would abuse the class `from` instead of using something sensible instead?!
                            fromRole += " from"
                        */
                        fromRole += " from-friend" if fromUser.friend
                    else
                        for r in ($this .find \.icon .prop(\className) ||"").split " " when r.startsWith \icon-chat-
                            fromRole = "from-#{r.substr 10}"
                        else
                            fromRole = \from-regular
                    if $ this .find \.subscriber
                        fromRole += " from-subscriber"
                    $this .addClass "fromID-#{uid} #fromRole"
        catch err
            console.error "[chatMessageClasses] couldn't convert old messages", err.stack

        addListener (window._$context || API), \chat:plugin, ({type, uid}:message) !-> if uid
            message.addClass "fromID-#uid"


            if message.user = getUser(uid)
                rank = getRank(message.user, true)
                if uid == userID
                    message.addClass \from-you
                    also = \-also
                else
                    message.addClass "from-#rank"
                message.addClass \from-staff if message.user.role > 1 or message.user.gRole
                if rank == \regular
                    message.addClass \from-subscriber if message.user.sub
                    message.addClass \from-friend if message.user.friend


/*####################################
#      UNREAD CHAT NOTIFICAITON      #
####################################*/
module \unreadChatNotif, do
    require: <[ _$context chatDomEvents chatPlugin ]>
    bottomMsg: $!
    settings: \chat
    displayName: 'Mark Unread Chat'
    setup: ({addListener}) !->
        unreadCount = 0
        $chatButton = $ \#chat-button
            .append $unreadCount = $ '<div class=p0ne-toolbar-count>'
        @bottomMsg = $cm! .children! .last!
        addListener _$context, \chat:plugin, (message) !->
            message.wasAtBottom ?= chatIsAtBottom!
            if not $chatButton.hasClass \selected and not PopoutView?.chat?
                $chatButton.addClass \p0ne-toolbar-highlight
                $unreadCount .text (unreadCount + 1)
            else if message.wasAtBottom
                @bottomMsg = message.cid
                return

            delete @bottomMsg
            $cm! .addClass \has-unread
            message.unread = true
            message.addClass \unread
            unreadCount++
        @throttled = false
        addListener chatDomEvents, \scroll, updateUnread
        addListener $chatButton, \click, updateUnread

        # reduce deleted messages from unreadCount
        addListener \early, _$context, \chat:delete, (cid) !->
            $msg = getChat(cid)
            if $msg.length and $msg.hasClass(\unread)
                $msg.removeClass \unread # this is to avoid problems with disableChatDelete
                unreadCount--

        ~function updateUnread
            return if @throttled
            @throttled := true
            sleep 200ms, !~>
                try
                    cm = $cm!
                    cmHeight = cm .height!
                    lastMsg = msg = @bottomMsg
                    $readMsgs = $!; l=0
                    while ( msg .=next! ).length
                        if msg .position!.top > cmHeight
                            @bottomMsg = lastMsg
                            break
                        else if msg.hasClass \unread
                            $readMsgs[l++] = msg.0
                        lastMsg = msg
                    if l
                        unread = cm.find \.unread
                        sleep 1_500ms, !~>
                            $readMsgs.removeClass \unread
                            if (unread .= filter \.unread) .length
                                @bottomMsg = unread .removeClass \unread .last!
                    if not msg.length
                        cm .removeClass \has-unread
                        $chatButton .removeClass \p0ne-toolbar-highlight
                        unreadCount := 0
                @throttled := false
    fix: !->
        #DEBUG for testing
        @throttled = false
        cm = $cm!
        cm
            .removeClass \has-unread
            .find \.unread .removeClass \unread
        @bottomMsg = cm.children!.last!
    disable: !->
        $cm!
            .removeClass \has-unread
            .find \.unread .removeClass \unread


/*####################################
#          OTHERS' @MENTIONS         #
####################################*/
module \chatOthersMentions, do
    optional: <[ users ]>
    require: <[ chatPlugin ]>
    settings: \chat
    displayName: 'Highlight @mentions for others'
    setup: ({addListener}) !->
        addListener _$context, \chat:plugin, ({type, uid}:message) !-> if uid
            res = ""; lastI = 0
            for mention in getMentions(message, true) when mention.id != userID or type == \emote
                res += "
                    #{message.message .substring(lastI, mention.offset)}
                    <span class='mention-other mentionID-#{mention.id} mention-#{getRank(mention, false)} #{if (mention.role||mention.gRole) then \mention-staff else ''} #{if type == \emote and mention.id == userID then \mention-you else ''}'>
                        @#{mention.rawun}
                    </span>
                "
                lastI = mention.offset + 1 + mention.rawun.length
            if res
                message.message = res + message.message.substr(lastI)


/*####################################
#           INLINE  IMAGES           #
####################################*/
CHAT_WIDTH = 500px
module \chatInlineImages, do
    require: <[ chatPlugin ]>
    settings: \chat
    settingsVip: true
    displayName: 'Inline Images'
    help: '''
        Converts image links to images in the chat, so you can see a preview.

        When enabled, you can enter tags to filter images which should not be shown inline. These tags are case-insensitive and space-seperated.

        ☢ The taglist is subject to improvement
    '''
    _settings:
        filterTags: <[ nsfw suggestive gore spoiler questionable no-inline noinline ]>
    setup: ({addListener}) !->
        addListener API, \chat:image, ({all,pre,completeURL,protocol,domain,url, onload, onerror, msg, offset}) !~>
            # note: converting images with the domain plug.dj might allow some kind of exploit in the future
            if img = @inlineify ...
                if not msg.hasFilterWord?
                    msg.hasFilterWord = false
                    msgLC = msg.message.toLowerCase!
                    for tag in @_settings.filterTags when msgLC.has tag
                        msg.hasFilterWord = true
                        console.warn "[inline-img] message contains \"#tag\", images will not be converted"
                        break

                if msg.hasFilterWord or msg.message[offset + all.length] == ";" or domain == \plug.dj
                    console.info "[inline-img] filtered image", "#completeURL ==> #protocol#img"
                    if pre .has "class="
                        pre .= replace /class=('|")?(\S+)/i, (,q,cl) !->
                            return 'class='+(q||'\'')+'p0ne-img-filtered '+cl+(if q then '' else '\'')
                    else
                        pre = "class=p0ne-img-filtered #pre"
                    return "<a #pre src='#img'>#completeURL</a>"
                else
                    console.log "[inline-img]", "#completeURL ==> #img"
                    return "<a #pre><img src='#img' class=p0ne-img #onload #onerror></a>"
            else
                return false

    # (the revision suffix is required for some blogspot images; e.g. http://vignette2.wikia.nocookie.net/moth-ponies/images/d/d4/MOTHPONIORIGIN.png/revision/latest)
    #           <URL stuff><        image suffix           >< image.php>< hires ><  revision suffix >< query/hash >
    regDirect: /^[^\#\?]+(?:\.(?:jpg|jpeg|gif|png|webp|apng)|image\.php)(?:@\dx)?(?:\/revision\/\w+)?(?:\?.*|\#.*)?$/i
    inlineify: ({all,pre,completeURL,protocol,domain,url, onload, onerror, msg, offset}) !->
        #= images =
        if @plugins[domain] || @plugins[domain.substr(1 + domain.indexOf(\.))]
            [rgx, repl, forceProtocol] = that
            if rgx.test(url)
                return "#{forceProtocol||protocol}#{url.replace(rgx, repl)}"

        #= direct images =
        if @regDirect .test url
            if domain in @forceHTTPSDomains
                return completeURL .replace 'http://', 'https://'
            else
                return completeURL

        #= no match =
        return false

    settingsExtra: ($el) !->
        $ '<span class=p0ne-settings-input-label>'
            .text "filter tags:"
            .appendTo $el
        $input = $ '<input class="p0ne-settings-input">'
            .val @_settings.filterTags.join " "
            .on \input, !~>
                @_settings.filterTags = []; l=0; map={"":true}
                for tag in $input.val!.split " "
                    tag = $.trim(tag)
                    @_settings.filterTags[l++] = tag if not map[tag]
            .appendTo $el

    forceHTTPSDomains: <[ i.imgur.com deviantart.com ]>
    plugins:
        \imgur.com :       [/^(?:i\.|m\.|edge\.|www\.)*imgur\.com\/(?:r\/[\w]+\/)*(?!gallery)(?!removalrequest)(?!random)(?!memegen)([\w]{5,8})(?:#\d+)?[sbtmlh]?(?:\.(?:jpe?g|gif|png|gifv))?$/, "i.imgur.com/$1.gif", \https://] # from RedditEnhancementSuite
        \prntscrn.com :    [/^(prntscr.com\/\w+)(?:\/direct\/)?/, "$1/direct"]
        \gyazo.com :       [/^gyazo.com\/\w+/, "$&/raw"]
        \dropbox.com :     [/^dropbox.com(\/s\/[a-z0-9]*?\/[^\/\?#]*\.(?:jpg|jpeg|gif|png|webp|apng))/, "dl.dropboxusercontent.com$1"]
        \pbs.twitter.com : [/^(pbs.twimg.com\/media\/\w+\.(?:jpg|jpeg|gif|png|webp|apng))(?:\:large|\:small)?/, "$1:small"]
        \googleimg.com :   [/^google\.com\/imgres\?imgurl=(.+?)(?:&|$)/, (,src) !-> return decodeURIComponent url]
        \imageshack.com :  [/^imageshack\.com\/[fi]\/(\w\w)(\w+?)(\w)(?:\W|$)/, !-> return chatInlineImages.imageshackPlugin ...]
        \imageshack.us :   [/^imageshack\.us\/[fi]\/(\w\w)(\w+?)(\w)(?:\W|$)/, !-> return chatInlineImages.imageshackPlugin ...]

        # direct image URLs that are not automatically detected
        \gstatic.com : [/^https:\/\/encrypted-tbn\d.gstatic.com\/images/, "$&"]
        \i.chzbgr.com : [/(?:)/, ""]

        /* meme-plugins based on http://userscripts.org/scripts/show/154915.html (mirror: http://userscripts-mirror.org/scripts/show/154915.html ) */
        \quickmeme.com :     [/^(?:m\.)?quickmeme\.com\/meme\/(\w+)/, "i.qkme.me/$1.jpg"]
        \qkme.me :           [/^(?:m\.)?qkme\.me\/(\w+)/, "i.qkme.me/$1.jpg"]
        \memegenerator.net : [/^memegenerator\.net\/instance\/(\d+)/, "http://cdn.memegenerator.net/instances/#{CHAT_WIDTH}x/$1.jpg"]
        \imageflip.com :     [/^imgflip.com\/i\/(.+)/, "i.imgflip.com/$1.jpg"]
        \livememe.com :      [/^livememe.com\/(\w+)/, "i.lvme.me/$1.jpg"]
        \memedad.com :       [/^memedad.com\/meme\/(\d+)/, "memedad.com/memes/$1.jpg"]
        \makeameme.org :     [/^makeameme.org\/meme\/(.+)/, "makeameme.org/media/created/$1.jpg"]

    imageshackPlugin: (,host,img,ext) !->
        ext = {j: \jpg, p: \png, g: \gif, b: \bmp, t: \tiff}[ext]
        return "https://imagizer.imageshack.us/a/img#{parseInt(host,36)}/1337/#img.#ext"

    /*pluginsAsync:
        \deviantart.com
        \fav.me
        \sta.sh
    deviantartPlugin: (replaceLink, url) !->
        $.getJSON "http://backend.deviantart.com/oembed?format=json&url=#url", (d) !->
            if d.height <= MAX_IMAGE_HEIGHT
                replaceLink d.url
            else
                replaceLink d.thumbnail_url
    */


module \imageLightbox, do
    require: <[ chatInlineImages chatDomEvents ]>
    setup: ({addListener, $createPersistent}) !->
        var $img
        PADDING = 10px # padding on each side of the image
        $container = $ \#dialog-container
        var lastSrc
        @$el = $el = $createPersistent '<img class=p0ne-img-large>'
            .css do # TEMP
                position: \absolute
                zIndex: 6
                cursor: \pointer
                boxShadow: '0 0 35px black, 0 0 5px black'
            .hide!
            .load !->
                _$context .trigger \ShowDialogEvent:show, {dialog}, true
            .appendTo $body
        addListener $container, \click, \.p0ne-img-large, !->
            dialog.close!
            return false

        @dialog = dialog =
            on: (,,@container) !->
            off: $.noop
            containerOnClose: $.noop
            destroy: $.noop

            $el: $el

            render: !->
                # calculating image size
                /*
                $elImg .css do
                    width: \auto
                    height: \auto
                <- requestAnimationFrame
                appW = $app.width!
                appH = $app.height!
                ratio = 1   <?   (appW - 345px - PADDING) / w   <?   (appH - PADDING) / h
                w *= ratio
                h *= ratio
                */
                #w = $el.width!
                #h = $el.height!
                contW = $container.width!
                contH = $container.height!
                imgW = $img.width!
                imgH = $img.height!
                offset = $img.offset!
                console.log "[lightbox] rendering" #, {w, h, oW: $el.css(\width), oH: $el.css(\height), ratio}
                $el
                    .removeClass \p0ne-img-large-open
                    .css do # copy position and size of inline image (note: the -10px are to make up for the margin)
                        left:      "#{(offset.left + imgW/2) *100/contW}%"
                        top:       "#{(offset.top  + imgH/2) *100/contH}%"
                        maxWidth:  "#{               imgW    *100/contW}%"
                        maxHeight: "#{               imgH    *100/contH}%"
                    .show!
                $img.css visibility: \hidden # hide inline image
                requestAnimationFrame !->
                    $el
                        .addClass \p0ne-img-large-open # use CSS transition to move enlarge the image (if possible)
                        .css do
                            left: ''
                            top:  ''
                            maxWidth: ''
                            maxHeight: ''

            close: (cb) !->
                $img_ = $img
                $el_ = $el
                @isOpen = false
                contW = $container.width!
                contH = $container.height!
                imgW = $img.width!
                imgH = $img.height!
                offset = $img.offset!
                $el
                    .css do
                        left:      "#{(offset.left + imgW/2) *100/contW}%"
                        top:       "#{(offset.top  + imgH/2) *100/contH}%"
                        maxWidth:  "#{                 imgW  *100/contW}%"
                        maxHeight: "#{                 imgH  *100/contH}%"
                sleep 200ms, !~>
                    # let's hope this is somewhat sync with when the CSS transition ends
                    $el .removeClass \p0ne-img-large-open
                    $img_ .css visibility: \visible
                    @container.onClose!
                    cb?!
        dialog.closeBind = dialog~close

        addListener chatDomEvents, \click, '.p0ne-img, .p0ne-img-filtered', (e) !->
            $img_ = $ this
            e.preventDefault!

            if dialog.isOpen
                if $img_ .is $img
                    dialog.close!
                else
                    dialog.close helper
            else
                helper!
            function helper
                $img := $img_
                dialog.isOpen = true
                src = $img.attr \src
                if src != lastSrc
                    lastSrc := src
                    # not using jQuery event listeners to avoid having to directly replace old listener
                    # this way we don't have to .off \load .one \load, …
                    $el.0 .onload = !->
                        _$context .trigger \ShowDialogEvent:show, {dialog}, true
                    $el .attr \src, src
                else
                    _$context .trigger \ShowDialogEvent:show, {dialog}, true
    disable: !->
        if @dialog?.isOpen
            <~ @dialog.close
            @$el? .remove!
        else
            @$el? .remove!

# /* image plugins using plugCubed API (credits go to TATDK / plugCubed) */
# module \chatInlineImages_plugCubedAPI, do
#    require: <[ chatInlineImages ]>
#    setup: !->
#        chatInlineImages.plugins <<<< @plugins
#    plugins:
#        \deviantart.com :    [/^[\w\-\.]+\.deviantart.com\/(?:art\/|[\w:\-]+#\/)[\w:\-]+/, "https://api.plugCubed.net/redirect/da/$&"]
#        \fav.me :            [/^fav.me\/[\w:\-]+/, "https://api.plugCubed.net/redirect/da/$&"]
#        \sta.sh :            [/^sta.sh\/[\w:\-]+/, "https://api.plugCubed.net/redirect/da/$&"]
#        \gfycat.com :        [/^gfycat.com\/(.+)/, "https://api.plugCubed.net/redirect/gfycat/$1"]

/*
module \chatYoutubeThumbnails, do
    settings: \chat
    help: '''
        Convert show thumbnails of linked Youtube videos in the chat.
        When hovering the thumbnail, it will animate, alternating between three frames of the video.
    '''
    setup: ({add, addListener}) !->
        addListener chatDomEvents, \mouseenter, \.p0ne-yt-img, (e) !~>
            clearInterval @interval
            img = this
            id = this.parentElement

            if id != @lastID
                @frame = 1
                @lastID = id
            img.style.backgroundImage = "url(http://i.ytimg.com/vi/#id/#{@frame}.jpg)"
            @interval = repeat 1_000ms, !~>
                console.log "[p0ne_yt_preview]", "showing 'http://i.ytimg.com/vi/#id/#{@frame}.jpg'"
                @frame = (@frame % 3) + 1
                img.style.backgroundImage = "url(http://i.ytimg.com/vi/#id/#{@frame}.jpg)"
            console.log "[p0ne_yt_preview]", "started", e, id, @interval
            #ToDo show YT-options (grab, open, preview, [automute])

        addListener chatDomEvents, \mouseleave, \.p0ne-yt-img, (e) !~>
            clearInterval @interval
            img = this
            id = this.parentElement.dataset.ytCid
            img.style.backgroundImage = "url(http://i.ytimg.com/vi/#id/0.jpg)"
            console.log "[p0ne_yt_preview]", "stopped"
            #ToDo hide YT-options

        addListener API, \chat:image, ({pre, url, onload}) !->
        yt = YT_REGEX .exec(url)
        if yt and (yt = yt.1)
            console.log "[inline-img]", "[YouTube #yt] #url ==> http://i.ytimg.com/vi/#yt/0.jpg"
            return "
                <a class=p0ne-yt data-yt-cid='#yt' #pre>
                    <div class=p0ne-yt-icon></div>
                    <div class=p0ne-yt-img #onload style='background-image:url(http://i.ytimg.com/vi/#yt/0.jpg)'></div>
                    #url
                </a>
            " # no `onerror` on purpose # when updating the HTML, check if it breaks the animation callback
            # default.jpg for smaller thumbnail; 0.jpg for big thumbnail; 1.jpg, 2.jpg, 3.jpg for previews
        return false
    interval: -1
    frame: 1
    lastID: ''
*/


/*####################################
#    CUSTOM NOTIFICATION TRIGGERS    #
####################################*/
module \customChatNotificationTrigger, do
    displayName: 'Notification Trigger Words'
    settings: \chat
    _settings:
        triggerwords: if (tmp=user.username.split(' ')).length then tmp else []
    disabled: true
    require: <[ chatPlugin _$context ]>
    setup: ({addListener}) !->
        @test = addListener _$context, \chat:plugin, (d) !~> if d.cid and d.uid != userID and @_settings.triggerwords.length
            mentioned = false
            mentions = {}
            if @hasUsernameTrigger
                @usernameReg .lastIndex = 0
                while x = @usernameReg .exec d.message
                    mentions[x.index] = true
            d.message .= replaceSansHTML @regexp, (word, i) !~>
                for o of @usernameTriggers[word]
                    return word if mentions[i - o]
                mentioned := true
                return "<span class=p0ne-trigger-word>#word</span>"
            playChatSound! if mentioned
        if window.user_
            addListener window.user_, \change:username, @~updateRegexp
        @updateRegexp!

    updateRegexp: !->
        @regexp = //
            \b(?:#{@_settings.triggerwords .join '|' |> escapeRegExp})\b
        //gi
        @hasUsernameTrigger = false
        @usernameTriggers = {}
        API.getUser!.username .replace @regexp, (word, i) !~>
            @hasUsernameTrigger = true
            @usernameTriggers[word] ||= {}
            @usernameTriggers[word][i + 1] = true
        @usernameReg = //@#{API.getUser!.username}//g

    settingsExtra: ($el) !->
        $ '<span class=p0ne-settings-input-label>'
            .text "aliases (comma seperated):"
            .appendTo $el
        $input = $ '<input class="p0ne-settings-input">'
            .val @_settings.triggerwords.join ", "
            .on \input, !~>
                @_settings.triggerwords = []; l=0
                for word in $input.val!.split ","
                    @_settings.triggerwords[l++] = $.trim(word)
                @updateRegexp!
            .appendTo $el

/*@source p0ne.look-and-feel.ls */
/**
 * plug_p0ne modules to add styles.
 * This needs to be kept in sync with plug_pony.css
 *
 * @author jtbrinkmann aka. Brinkie Pie
 * @license MIT License
 * @copyright (c) 2015 J.-T. Brinkmann
 */


module \p0neStylesheet, do
    setup: ({loadStyle}) !->
        loadStyle "#{p0ne.host}/css/plug_p0ne.css?r=47"

/*
window.moduleStyle = (name, d) !->
    options =
        settings: true
        module: !-> @toggle!
    if typeof d == \string
        if isURL(d) # load external CSS
            options.setup = ({loadStyle}) !->
                loadStyle d
        else if d.0 == "." # toggle class
            options.setup = !->
                $body .addClass d
            options.disable = !->
                $body .removeClass d
    else if typeof d == \function
        options.setup = d
    module name, options
*/

/*####################################
#            FIMPLUG THEME           #
####################################*/
module \fimplugTheme, do
    settings: \look&feel
    displayName: "Brinkie's fimplug Theme"
    setup: ({loadStyle}) !->
        loadStyle "#{p0ne.host}/css/fimplug.css?r=28"


/*####################################
#          ANIMATED DIALOGS          #
####################################*/
module \animatedUI, do
    require: <[ Dialog ]>
    setup: ({addListener, replace}) !->
        $ \.dialog .addClass \opaque
        replace Dialog, \render, !-> return !->
            @show!
            sleep 0ms, !~> @$el.addClass \opaque
            return this

        addListener _$context, \ShowDialogEvent:show, (d) !->
                if d.dialog.options?.media?.format == 2
                    sleep 0ms, !~> @$el.addClass \opaque

        replace Dialog, \close, (close_) !-> return !->
            @$el.removeClass \opaque
            sleep 200ms, !~> close_.call this
            return this


/*####################################
#        FIX HIGH RESOLUTIONS        #
####################################*/
module \fixHiRes, do
    displayName: "☢ Fix high resolutions"
    settings: \fixes
    help: '''
        This will fix some odd looking things on larger screens
        NOTE: This is WORK IN PROGESS! Right now it doesn't help much.
    '''
    setup: ({}) !->
        $body .addClass \p0ne-fix-hires
    disable: !->
        $body .removeClass \p0ne-fix-hires


/*####################################
#         PLAYLIST ICON VIEW         #
####################################*/
# fix drag'n'drop styles for playlist icon view
module \playlistIconView, do
    displayName: "Playlist Grid View"
    settings: \look&feel
    help: '''
        Shows songs in the playlist and history panel in an icon view instead of the default list view.
    '''
    optional: <[ PlaylistItemList pl ]>
    setup: ({addListener, replace, replaceListener}, playlistIconView) !->
        $body .addClass \playlist-icon-view

        #= fix visiblerows calculation =
        if not PlaylistItemList?
            chatWarn playlistIconView.displayName, "this module couldn't fully load, it might not act 100% as expected. If you have problems, you might want to disable this."
            return
        const CELL_HEIGHT = 185px # keep in sync with plug_p0ne.css
        const CELL_WIDTH = 160px
        replace PlaylistItemList::, \onResize, !-> return !->
            @@@__super__.onResize .call this
            newCellsPerRow = ~~((@$el.width! - 10px) / CELL_WIDTH)
            newVisibleRows = Math.ceil(2rows + @$el.height!/CELL_HEIGHT) * newCellsPerRow
            if newVisibleRows != @visibleRows or newCellsPerRow != @cellsPerRow
                #console.log "[pIV resize]", newVisibleRows, newCellsPerRow
                @visibleRows = newVisibleRows
                @cellsPerRow = newCellsPerRow
                delete @currentRow
                @onScroll!

        replace PlaylistItemList::, \onScroll, (oS) !-> return !->
            if @scrollPane
                top = ~~(@scrollPane.scrollTop! / CELL_HEIGHT) - 1row >? 0
                @firstRow = top * @cellsPerRow
                lastRow = @firstRow + @visibleRows <? @collection.length
                if @currentRow != @firstRow
                    #console.log "[scroll]", @firstRow, lastRow, @visibleRows
                    @currentRow = @firstRow
                    @$firstRow.height top * CELL_HEIGHT
                    @$lastRow.height do
                        ~~((@collection.length - lastRow) / @cellsPerRow) * CELL_HEIGHT
                    @$container.empty!.append @$firstRow
                    for e from @firstRow to lastRow when row = @rows[e]
                        @$container.append row.$el
                        row.render!
                    @$container.append(@$lastRow)


        if pl?.list?.rows
            # onResize hook
            Layout
                .off \resize, pl.list.resizeBind
                .resize replace(pl.list, \resizeBind, !~> return pl.list~onResize)

            # onScroll hook
            pl.list.$el
                .off \jsp-scroll-y, pl.list.scrollBind
                .on \jsp-scroll-y, replace(pl.list, \scrollBind, !~> return pl.list~onScroll)

            # opening playlist drawer animation fix
            replaceListener _$context, \anim:playlist:progress, PlaylistItemList, !~> return !~>
                #pl.list.onResize! if pl.list.$el

            # to force rerender
            delete pl.list.currentRow
            pl.list.onResize Layout.getSize!
            pl.list.onScroll?!
        else
            console.warn "no pl"

        #= fix dragRowLine =
        # (The line that indicates when drag'n'dropping, where a song would be dropped)
        $hovered = $!
        $mediaPanel = $ \#media-panel
        addListener $mediaPanel, \mouseover, \.row, !->
            $hovered .removeClass \hover
            $hovered := $ this
            $hovered .addClass \hover if not $hovered.hasClass \selected
        addListener $mediaPanel, \mouseout, \.hovered, !->
            $hovered.removeClass \hover



        # usually, when you drag a song (row) plug checks whether you drag it BELOW or ABOVE the currently hovered row
        # however with icons, we would rather want to move them LEFT or RIGHT of the hovered song (icon)
        # sadly the easiest way that's not TOO haxy requires us to redefine the whole function just to change two words
        # also some lines are removed, because the vanilla $dragRowLine is not used anymore, we use a CSS-based solution
        replace PlaylistItemList::, \onDragUpdate, !-> return (e) !->
            @@@__super__.onDragUpdate .call this, e
            n = @scrollPane.scrollTop!
            if @currentDragRow && @currentDragRow.$el
                r = 0
                i = @currentDragRow.options.index
                if not @lockFirstItem or i > 0
                    @targetDropIndex = i
                    s = @currentDragRow.$el.offset!.left
                    # if @mouseY >= s + @currentDragRow.$el.height! / 2 # here we go, two words that NEED to be changed
                    if @mouseX >= s + @currentDragRow.$el.width! / 2
                        @$el .addClass \p0ne-drop-right
                        @targetDropIndex =
                            if i == @lastClickedIndex - 1
                                @lastClickedIndex
                            else
                                @targetDropIndex = i + 1
                    else
                        @$el .removeClass \p0ne-drop-right
                        @targetDropIndex =
                            if i == @lastClickedIndex + 1
                                @lastClickedIndex
                            else
                                @targetDropIndex = i
                else if i == 0
                    @targetDropIndex = 1

            o = @onCheckListScroll!

    disableLate: !->
        # using disableLate so that `pl.scrollBind` is already reset
        console.info "#{getTime!} [playlistIconView] disabling"
        $body .removeClass \playlist-icon-view
        pl?.list?.$el?
            .off \jsp-scroll-y
            .on \jsp-scroll-y, pl.list.scrollBind


        /*
        #= load all songs at once =
        replace PlaylistItemList::, \onScroll, !-> return $.noop
        replace PlaylistItemList::, \drawList, !-> return !->
            @@@__super__.drawList .call this
            if this.collection.length == 1
                this.$el.addClass \only-one
            else
                this.$el.removeClass \only-one
            for row in pl.rows
              row.$el.appendTo pl.$container
              row.render!
        */

        /*
        #= icon to toggle playlistIconView =
        replace MediaPanel::, \show, (s_) !-> return !->
            s_ ...
            @header.$el .append do
                $create '<div class="button playlist-view-button"><i class="icon icon-playlist"></i></div>'
                    .on \click, playlistIconView
        */






/*####################################
#          VIDEO PLACEHOLDER         #
####################################*/
module \videoPlaceholderImage, do
    displayName: "Video Placeholder Thumbnail"
    settings: \look&feel
    help: '''
        Shows a thumbnail in place of the video, if you snooze the video or turn off the stream.

        This is useful for knowing WHAT is playing, even when don't want to watch it.
    '''
    screenshot: 'https://i.imgur.com/TMHVsrN.gif'
    setup: ({addListener}) !->
        $room = $ \#room
        $playbackImg = $ \#playback-container
        addListener API, \advance, updatePic
        updatePic media: API.getMedia!

        function updatePic d
            if not d.media
                #console.log "[Video Placeholder Image] hide"
                $playbackImg .css backgroundColor: \transparent, backgroundImage: \none
            else if d.media.format == 1  # YouTube
                #console.log "[Video Placeholder Image] #img"
                $playbackImg .css backgroundColor: \#000, backgroundImage: "url(https://i.ytimg.com/vi/#{d.media.cid}/0.jpg)"
            else # SoundCloud
                #console.log "[Video Placeholder Image] #{d.media.image}"
                $playbackImg .css backgroundColor: \#000, backgroundImage: "url(#{d.media.image})"
    disable: !->
        $ \#playback-container .css backgroundColor: \transparent, backgroundImage: \none


/*####################################
#             LEGACY CHAT            #
####################################*/
module \legacyChat, do
    displayName: "Smaller Chat"
    settings: \chat
    help: '''
        Shows the chat in the old format, before badges were added to it in December 2014.
        Makes the messages smaller, so more fit on the screen
    '''
    disabled: true
    setup: ({addListener}) !->
        $body .addClass \legacy-chat
        $cb = $ \#chat-button
        addListener $cb, \dblclick, (e) !~>
            @toggle!
            e.preventDefault!
        addListener chatDomEvents, \dblclick, '.popout .icon-chat', (e) !~>
            @toggle!
            e.preventDefault!
    disable: !->
        $body .removeClass \legacy-chat


/*####################################
#            LEGACY FOOTER           #
####################################*/
module \legacyFooter, do
    displayName: "Info Footer"
    settings: \look&feel
    help: '''
        Restore the old look of the footer (the thing below the chat) and transform it into a more useful information panel.
        To get to the settings etc, click anywhere on the panel.
    '''
    disabled: true
    setup: ({addListener}) !->
        # most of this module's magic is in the CSS
        $body .addClass \legacy-footer

        # show the menu when the user clicks the footer
        $foo = $ \#footer-user
        addListener $foo.find(\.info), \click, !->
            $foo.addClass \menu
            <- _.delay
            $body.one \click, !-> $foo.removeClass \menu

        # make sure the "Back To Community" button text is loaded
        # it usually isn't if the user didn't open the playlist-/settings-drawer yet
        $foo .find '.back span:first'
            ..text Lang?.userMeta.backToCommunity || "Back To Community" if not /\S/.test ..text!

    disable: !->
        $body .removeClass \legacy-footer
        $ \#footer-user .removeClass \menu


/*####################################
#            CHAT DJ ICON            #
####################################*/
module \djIconChat, do
    require: <[ chatPlugin ]>
    settings: \look&feel
    displayName: "Current-DJ-icon in Chat"
    setup: ({addListener, css}) !->
        # get the DJ icon image URL and background-position
        icon = getIcon \icon-current-dj
        css \djIconChat, "\#chat .from-current-dj .timestamp::before { background: #{icon.background}; }"

        # add .from-current-dj class to messages from the current DJ
        addListener _$context, \chat:plugin, (message) !->
            if message.uid and message.uid == API.getDJ!?.id
                message.addClass \from-current-dj


/*####################################
#          DRAGGABLE DIALOG          #
####################################*/
module \draggableDialog, do
    require: <[ Dialog ]>
    displayName: '☢ Draggable Dialog'
    settings: \look&feel
    setup: ({addListener, replace, css}) !->
        # set up styles
        css \dialogDragNDrop, '
            .dialog-frame, .p0ne-lightsout-btn { cursor: pointer; }
            #dialog-container { width: 0; }
            #dialog-container.lightsout { width: auto; }
            #dialog-container.dragging .dialog-frame { cursor: move; }
            .dialog { position: absolute; }
            #dialog-container { transition: background .5s ease-out; }
            #dialog-container.dragging { background: rgba(0,0,0, 0); }
            .p0ne-lightsout-btn {
                top: 10px;
                left: 10px;
                opacity: .5;
            }
        '

        # set up event listener to initiate Drag'n'Drop
        var $dialog, startPos, startX, startY
        $dialogContainer = $ \#dialog-container
        addListener $dialogContainer, \mousedown, \.dialog-frame, (e) !->
            # set up drag'n'drop event listeners
            $body
                .on \mousemove, mousemove
                .on \mouseup, mouseup
            $dialog := $ this .closest \.dialog
                .addClass \dragging
            pos = $dialog .position!
            $dialog .css position: \absolute
            startX := e.clientX - pos.left; startY := e.clientY - pos.top
            #$dialogContainer .addClass \dragging

        #addListener $dialogContainer, \click, \.dialog-frame, (e) !->
        #    $dialogContainer .css \width, 0

        /* add lights-out button to dialogs */
        lightsout = true
        replace Dialog, \getHeader, !-> return (title) !->
            $  "<div class=dialog-frame>
                    <span class=title>#title</span>
                    <i class='icon icon-#{if lightsout then '' else 'un'}locked p0ne-lightsout-btn'></i>
                    <i class='icon icon-dialog-close'></i>
                </div>"
                ..find \.icon-dialog-close
                    .on \click, @~close
                return ..
        # if a dialog is already open
        $ \.dialog-frame:first .append "<i class='icon icon-#{if lightsout then '' else 'un'}locked p0ne-lightsout-btn'></i>"

        addListener _$context, \ShowDialogEvent:show, (d) !->
            $dialog := $dialogContainer .find \.dialog
                .css position: \static
            $dialogContainer .addClass \lightsout
            if pos = $dialog .position!
                pos.position = \absolute
                $dialog .css pos
            if not lightsout
                $dialogContainer .removeClass \lightsout

        addListener $dialogContainer, \mousedown, \.p0ne-lightsout-btn, (e) !->
            if lightsout
                $dialogContainer.removeClass \lightsout
                $ this .removeClass \icon-locked .addClass \icon-unlocked
            else
                $dialogContainer.addClass \lightsout
                $ this .addClass \icon-locked .removeClass \icon-unlocked
            lightsout := !lightsout

        # reset when the dialog is closed
        replace Dialog, \close, (c_) !-> return !->
            console.log "[dialogDragNDrop] closing dialog"
            stopDragging true
            c_ ...

        function mousemove e
            # move dialog
            $dialog .css do
                left: e.clientX - startX
                top: e.clientY - startY
            e.preventDefault!

        function mouseup e
            # end dragging mode (i.e. drop the dialog)
            stopDragging!

        @stopDragging = stopDragging = !->
            $dialog? .removeClass \dragging
            $body
                .off \mousemove, mousemove
                .off \mouseup, mouseup
    disable: !->
        @stopDragging?!
        $ '#dialog-container .dialog' .css position: \static
        $ '#dialog-container .p0ne-lightsout-btn' .remove!


/*####################################
#             EMOJI PACK             #
####################################*/
module \emojiPack, do
    displayName: '☢ Emoji Pack [Google]'
    settings: \look&feel
    disabled: true
    help: '''
        Replace all emojis with the one from Google (for Android Lollipop).

        Emojis are are the little images that show up e.g. when you write ":eggplant:" in the chat. <span class="emoji emoji-1f346"></span>

        <small>
        Note: :yellow_heart: <span class="emoji emoji-1f49b"></span> and :green_heart: <span class="emoji emoji-1f49a"></span> look neither yellow nor green with this emoji pack.
        </small>
    '''
    screenshot: 'https://i.imgur.com/Ef94Csn.png'
    _settings:
        pack: \google
        # note: as of now, only Google's emojicons (from Android Lollipop) are supported
        # possible future emoji packs are: Twitter's and EmojiOne's (and native browser)
        # by default, plug.dj uses Apple's emojipack
    setup: ({loadStyle}) !->
        loadStyle "#{p0ne.host}/css/temp.#{@_settings.pack}-emoji.css"


/*####################################
#               CENSOR               #
####################################*/
module \censor, do
    displayName: "Censor"
    settings: \dev
    help: '''
        blurs some information like playlist names, counts, EP and Plug Notes.
        Great for taking screenshots
    '''
    disabled: true
    setup: ({css}) !->
        $body .addClass \censored
        css '
            @font-face {
                font-family: "ThePrintedWord";
                src: url("http://letterror.com/wp-content/themes/nextltr/css/fonts/ThePrintedWord.eot");
                src: url("http://letterror.com/wp-content/themes/nextltr/css/fonts/ThePrintedWord.eot?") format("embedded-opentype"),
                     url("http://letterror.com/wp-content/themes/nextltr/css/fonts/ThePrintedWord.woff") format("woff"),
                     url("http://letterror.com/wp-content/themes/nextltr/css/fonts/ThePrintedWord.svg") format("svg"),
                     url("http://letterror.com/wp-content/themes/nextltr/css/fonts/ThePrintedWord.otf") format("opentype");
                font-style: normal;
                font-weight: 400;
                font-stretch: normal;
            }'
    disable: !->
        $body .removeClass \censored


/*@source p0ne.room-theme.ls */
/**
 * Room Settings module for plug_p0ne
 * made to be compatible with plugCubes Room Settings
 * so room hosts don't have to bother with mutliple formats
 * that also means, that a lot of inspiration came from and credits go to the PlugCubed team ♥
 *
 * for more information, see https://issue.plugcubed.net/wiki/Plug3%3ARS
 *
 * @author jtbrinkmann aka. Brinkie Pie
 * @license MIT License
 * @copyright (c) 2015 J.-T. Brinkmann
*/

/*####################################
#            ROOM SETTINGS           #
####################################*/
module \roomSettings, do
    require: <[ room ]>
    optional: <[ _$context socketListeners ]>
    persistent: <[ _data _room ]>
    module: new DataEmitter(\roomSettings)

    _room: \dashboard
    setup: ({addListener, addCommand}) !->
        @_update!
        addListener API, \socket:roomDescriptionUpdate, @_update, this
        if _$context?
            addListener _$context, \room:joining, @clear, this
            addListener _$context, \room:joined, @_update, this
        addCommand \roomsettings, do
            description: "reloads the p³ compatible Room Settings"
            callback: @~_update

    _update: !->
        roomslug = getRoomSlug!
        return if @_data and roomslug == @_room

        if not roomDescription = room.get \description #$ '#room-info .description .value' .text!
            console.warn "[p0ne] no p³ compatible Room Settings found"
        else if url = /@p3=(.*)/i .exec roomDescription
            console.log "[p0ne] p³ compatible Room Settings found", url.1
            $.getJSON proxify(url.1)
                .then (data) !~>
                    console.log "#{getTime!} [p0ne] loaded p³ compatible Room Settings"
                    @_room = roomslug
                    @set data
                .fail !->
                    chatWarn "cannot load Room Settings. run /roomsettings to try loading them again", "p0ne"





/*####################################
#             ROOM THEME             #
####################################*/
module \roomTheme, do
    displayName: "Room Theme"
    require: <[ roomSettings ]>
    optional: <[ roomLoader ]>
    settings: \look&feel
    help: '''
        Applies the room theme, if this room has one.
        Room Settings and thus a Room Theme can be added by (co-) hosts of the room.
    '''
    setup: ({addListener, replace, css, loadStyle}) !->
        @$playbackBackground = $ '#playback .background img'
        @playbackBackgroundVanilla = @$playbackBackground .attr \src

        addListener roomSettings, \data, @applyTheme = (d) !~>
            console.log "#{getTime!} [roomTheme] loading theme"
            @clear d.images.background, false
            @_data = d
            cc = customColors?.colors ||{}
            styles = ""

            /*== colors ==*/
            if d.colors
                styles += "\n/*== colors ==*/\n"
                for role, color of d.colors.chat when isColor(color)
                    if role in <[ rdj residentdj ]>
                        role = \dj
                        d.colors.chat.dj = color
                    styles += """
                    /* #role => #color */
                    \#user-lists .icon-chat-#role + .name,
                    .from-#role .from, \#waitlist .icon-chat-#role + span,
                    \#user-rollover .icon-chat-#role + span, .p0ne-name.#role {
                            color: #color !important;
                    }\n"""
                    #ToDo @mention other colours
                colorMap =
                    background: \.room-background
                    header: \.app-header
                    footer: \#footer
                for k, selector of colorMap when isColor(d.colors[k])
                    styles += "#selector { background-color: #{d.colors[k]} !important }\n"

            /*== CSS ==*/
            if d.css
                styles += "\n/*== custom CSS ==*/\n"
                for rule,attrs of d.css.rule
                    styles += "#rule {"
                    for k, v of attrs
                        styles += "\n\t#k: #v"
                        styles += ";" if not /;\s*$/.test v
                    styles += "\n}\n"
                for {name, url} in d.css.fonts ||[] when name and url
                    if $.isArray url
                        url = [].join.call(url, ", ")
                    styles += """
                    @font-face {
                        font-family: '#name';
                        src: '#url';
                    }\n"""
                for url in d.css.import ||[]
                    loadStyle url
                #for rank, color of d.colors?.chat ||{}
                #   ...

            /*== images ==*/
            if d.images
                styles += "\n/*== images ==*/\n"
                /* custom p0ne stuff */
                if isURL(d.images.backgroundScalable)
                    styles += "\#app { background-image: url(#{d.images.background}) fixed center center / cover }\n"

                    /* original plug³ stuff */
                else if isURL(d.images.background)
                    styles += ".room-background { background-image: url(#{d.images.background}) !important }\n"
                if isURL(d.images.playback) and roomLoader? and Layout?
                    new Image
                        ..onload = !~>
                            @$playbackBackground .attr \src, d.images.playback
                            replace roomLoader, \frameHeight,   !-> return ..height - 10px
                            replace roomLoader, \frameWidth,    !-> return ..width  - 18px
                            roomLoader.onVideoResize Layout.getSize!
                            console.log "#{getTime!} [roomTheme] loaded playback frame"
                        ..onerror = !->
                            console.error "#{getTime!} [roomTheme] failed to load playback frame"
                        ..src = d.images.playback
                    replace roomLoader, \src, !-> return d.images.playback
                if isURL(d.images.booth)
                    styles += """
                        /* custom booth */
                        \#avatars-container::before {
                            background-image: url(#{d.images.booth});
                        }\n"""
                for role, url of d.images.icons
                    styles += """
                        .icon-chat-#role {
                            background-image: url(#url);
                            background-position: 0 0;
                        }\n"""
                    if role == \cohost
                        styles += """
                            .from-cohost .icon-chat-host { /* cohost icon fix */
                                background-image: url(#url);
                                background-position: 0 0;
                            }\n"""

            /*== text ==*/
            if d.text
                for key, text of d.text.plugDJ
                    base = Lang
                    key .= split \.
                    endKey = key.pop!
                    for key in key
                        if not base = base[key]
                            break
                    if base
                        replace base, endKey, !-> return text

            css \roomTheme, styles
            @styles = styles

        addListener roomSettings, \cleared, @clear, this

    clear: (resetBackground, skipDisables) !->
        console.log "#{getTime!} [roomTheme] clearing RoomTheme"
        if not skipDisables
            # copied from p0ne.module
            for [target, attr /*, repl*/] in @_cbs.replacements ||[]
                target[attr] = target["#{attr}_"]
            for style of @_cbs.css
                p0neCSS.css style, "/* disabled */"
            for url of @_cbs.loadedStyles
                p0neCSS.unloadStyle url
            delete [@_cbs.replacements, @_cbs.css, @_cbs.loadedStyles]

        @currentRoom = null
        if resetBackground and @$playbackBackground
            @$playbackBackground
                .one \load !->
                    roomLoader?.onVideoResize Layout.getSize! if Layout?
                .attr \src, @playbackBackgroundVanilla

    disable: !->
        @clear true, true
        @_data = {}


/*@source p0ne.song-notif.ls */
/**
 * get fancy song notifications in the chat (with preview thumbnail, description, buttons, …)
 *
 * @author jtbrinkmann aka. Brinkie Pie
 * @license MIT License
 * @copyright (c) 2015 J.-T. Brinkmann
 */

#ToDo add proper SoundCloud Support
#   $.ajax url: "https://api.soundcloud.com/tracks/#cid.json?client_id=#{p0ne.SOUNDCLOUD_KEY}"
#   => {permalink_url, artwork_url, description, downloadable}

/*####################################
#             SONG NOTIF             #
####################################*/
module \songNotif, do
    require: <[ chatDomEvents ]>
    optional: <[ _$context chat users database auxiliaries app popMenu ]>
    settings: \base
    displayName: 'Song Notifications'
    help: '''
        Shows notifications for playing songs in the chat.
        Besides the songs' name, it also features a thumbnail and some extra buttons.

        By clicking on the song's or author's name, a search on plug.dj for that name will be started, to easily find similar tracks.

        By hovering the notification and clicking "description" the songs description will be loaded.
        You can click anywhere on it to close it again.
    '''
    persistent: <[ lastMedia $div ]>
    setup: ({addListener, $create, @$createPersistent, css},, module_) !->
        @$lastNotif = $!
        @$div ||= $cms! .find \.p0ne-song-notif:last

        #$create \<div>
        #    .addClass \playback-thumb
        #    .insertBefore $ '#playback .background'

        addListener API, \advance, @~callback
        if _$context
            addListener _$context, \room:joined, !~>
                @callback media: API.getMedia!, dj: API.getDJ!

        #== add skip listeners ==
        addListener API, \modSkip, (modUsername) !~>
            console.info "[API.modSkip]", modUsername
            if getUser(modUsername)
                modID = "data-uid='#{that.id}'"
            else
                modID = ""
            @$lastNotif .find \.timestamp
                .after do
                    $ "<div class='song-skipped un' #modID>"
                        .text modUsername

        #== apply stylesheets ==
        loadStyle "#{p0ne.host}/css/p0ne.notif.css?r=18"


        #== show current song ==
        if API.getMedia!
            that.image = httpsify that.image
            @callback media: that, dj: API.getDJ!

        # hide non-playable videos
        addListener _$context, \RestrictedSearchEvent:search, !->
            snooze!

        #== Grab Songs ==
        if popMenu?
            addListener chatDomEvents, \click, \.song-add, !->
                $el = $ this
                $notif = $el.closest \.p0ne-song-notif
                id = $notif.data \id
                format = $notif.data \format
                console.log "[add from notif]", $notif, id, format

                msgOffset = $notif .offset!
                $el.offset = !-> # to fix position
                    return { left: msgOffset.left + 17px, top: msgOffset.top + 18px }

                obj = { id: id, format: 1yt }
                obj.get = (name) !->
                    return this[name]
                obj.media = obj

                popMenu.isShowing = false
                popMenu.show $el, [obj]
        else
            css \songNotificationsAdd, '.song-add {display:none}'

        #== search for author ==
        addListener chatDomEvents, \click, \.song-author, !->
            mediaSearch @textContent

        #== description ==
        # disable previous listeners (for debugging)
        #$ \#chat-messages .off \click, \.song-description-btn
        #$ \#chat-messages .off \click, \.song-description
        $description = $()
        addListener chatDomEvents, \click, \.song-description-btn, (e) !->
            try
                if $description
                    hideDescription! # close already open description

                #== Show Description ==
                $description := $ this
                $notif = $description .closest \.p0ne-song-notif
                cid    = $notif .data \cid
                format = $notif .data \format
                console.log "[song-notif] showing description", cid, $notif

                if $description .data \description
                    showDescription $notif, that
                else
                    # load description from Youtube
                    console.log "looking up", {cid, format}, do
                        mediaLookup {cid, format}, do
                            success: (data) !->
                                text = formatPlainText data.description # let's get fancy
                                $description .data \description, text
                                showDescription $notif, text
                            fail: !->
                                $description
                                    .text "Failed to load"
                                    .addClass \.song-description-failed

                        .timeout 200ms, !->
                            $description
                                .text "Description loading…"
                                .addClass \loading
            catch e
                console.error "[song-notif]", e


        addListener chatDomEvents, \click, \.song-description, (e) !->
            if not e.target.href
                hideDescription!

        function showDescription $notif, text
                # create description element
                $notif
                    .addClass \song-notif-with-description
                    .append do
                        $description
                            .removeClass 'song-description-btn loading'
                            .css opacity: 0, position: \absolute
                            .addClass \song-description
                            .html "#text <i class='icon icon-clear-input'></i>"

                # show description (animated)
                h = $description.height!
                $description
                    .css height: 0px, position: \static
                    .animate do
                        opacity: 1
                        height: h
                        !-> $description .css height: \auto

                # smooth scroll
                cm = $cm!
                offsetTop = $notif.offset!?.top - 100px
                ch = cm .height!
                if offsetTop + h > ch
                    cm.animate do
                        scrollTop: cm .scrollTop! + Math.min(offsetTop + h - ch + 100px, offsetTop)
                        # 100px is height of .song-notif without .song-description

        function hideDescription
            #== Hide Description ==
            return if not $description
            console.log "[song-notif] closing description", $description
            $notif = $description .closest \.p0ne-song-notif
                .removeClass \song-notif-with-description
            $description.animate do
                opacity: 0
                height: 0px
                !->
                    $ this
                        .css opacity: '', height: \auto
                        .removeClass 'song-description text'
                        .addClass 'song-description-btn'
                        .text "Description"
                        .appendTo do
                            $notif .find \.song-notif-next
            $description := null

            # smooth scroll
            offsetTop = $notif.offset!?.top - 100px # 100 is # $(\.app-header).height! + $(\#chat-header).height
            if offsetTop < 0px
                cm = $cm!
                cm.animate do
                    scrollTop: cm .scrollTop! + offsetTop - 100px # -100px is so it doesn't stick to the very top

        @showDescription = showDescription
        @hideDescription = hideDescription


    callback: (d) !->
        media = d.media
        if media?.id != @lastMedia
            if @$div and score = d.lastPlay?.score
                /*@security HTML injection shouldn't be an issue, unless the score attributes are oddly manipulated */
                @$div
                    .removeClass \song-current
                    .find \.song-stats
                        .html "
                        <div class=score>
                            <div class='item positive'>
                                <i class='icon icon-history-positive'></i> #{score.positive}
                            </div>
                            <div class='item grabs'>
                                <i class='icon icon-history-grabs'></i> #{score.grabs}
                            </div>
                            <div class='item negative'>
                                <i class='icon icon-history-negative'></i> #{score.negative}
                            </div>
                            <div class='item listeners'>
                                <i class='icon icon-history-listeners'></i> #{users?.length || API.getUsers!.length}
                            </div>
                        </div>
                        "
                @lastMedia = null; @$lastNotif = @$div
        if not media
            return

        @lastMedia := media.id
        chat?.lastType = \p0ne-song-notif

        @$div := @$createPersistent "<div class='update p0ne-song-notif song-current' data-id='#{media.id}' data-cid='#{media.cid}' data-format='#{media.format}'>"
        html = ""
        author = htmlUnescape media.author
        title = htmlUnescape media.title
        if media.format == 1  # YouTube
            mediaURL = "http://youtube.com/watch?v=#{media.cid}"
        else # if media.format == 2 # SoundCloud
            # note: this gets replaced by a proper link as soon as data is available
            mediaURL = "https://soundcloud.com/search?q=#{encodeURIComponent author+' - '+title}"

        image = httpsify media.image
        duration = mediaTime media.duration
        console.logImg image, 120px, (if media.format == 1 then 90px else 120px)
            .then !->
                console.log "#{getTime!} [DJ_ADVANCE] #{d.dj.username} plays '#{author} - #{title}' (#duration)", d
        html += "
            <div class='song-thumb-wrapper'>
                <img class='song-thumb' src='#image' />
                <span class='song-duration'>#duration</span>
                <div class='song-add btn'><i class='icon icon-add'></i></div>
                <a class='song-open btn' href='#mediaURL' target='_blank'><i class='icon icon-chat-popout'></i></a>
                <!-- <div class='song-download btn right'><i class='icon icon-###'></i></div> -->
            </div>
            #{getTimestamp!}
            <div class='song-stats'></div>
            <div class='song-dj un'></div>
            <b class='song-title'></b>
            <span class='song-author'></span>
            <div class='song-description-btn'>Description</div>
        "
        @$div.html html
        @$div .find \.song-title .text title .prop \title, title
        @$div .find \.song-author .text author
        @$div .find \.song-dj
            .text d.dj.username
            .data \uid, d.dj.id

        appendChat @$div
        if media.format == 2 # SoundCloud
            @$div .addClass \loading
            mediaLookup media
                .then (d) !~>
                    @$div
                        .removeClass \loading
                        .data \description, d.description
                        .find \.song-open .attr \href, d.url
                    if d.download
                        @$div
                            .addClass \downloadable
                            .find \.song-download
                                .attr \href, d.download
                                .attr \title, "#{formatMB(d.downloadSize / 1_000_000to_mb)} #{if d.downloadFormat then '(.'+that+')' else ''}"


    disable: !->
        @hideDescription?!

chatCommands.commands.songinfo =
    description: "forces a song notification to be shown, even if the module is disabled"
    callback: !->
        if window.songNotif?.callback and API.getMedia!
            that.image = httpsify that.image
            window.songNotif.callback media: that, dj: API.getDJ!

/*@source p0ne.song-info.ls */
/**
 * plug_p0ne songInfo
 * adds a dropdown with the currently playing song's description when clicking on the now-playing-bar (in the top-center of the page)
 *
 * @author jtbrinkmann aka. Brinkie Pie
 * @license MIT License
 * @copyright (c) 2015 J.-T. Brinkmann
 */
# maybe add "other videos by artist", which loads a list of other uploads by the uploader?
# http://gdata.youtube.com/feeds/api/users/#{channel}/uploads?alt=json&max-results=10


/*####################################
#              SONG INFO             #
####################################*/
module \songInfo, do
    optional: <[ _$context ]>
    settings: \base
    displayName: 'Song-Info Dropdown'
    help: '''
        A panel with the song's description and links to the artist and song.
        Click on the now-playing-bar (in the top-center of the page) to open it.
    '''
    setup: ({addListener, $create, css}) !->
        @$create = $create
        css \songInfo, '
            #now-playing-bar {
                cursor: pointer;
            }
        '

        @$el = $create \<div> .addClass \p0ne-song-info .appendTo \body
        @loadBind = @~load
        addListener $(\#now-playing-bar), \click, (e) !~>
            $target = $ e.target
            return if  $target .closest \#history-button .length or $target .closest \#volume .length
            if not @visible # show
                media = API.getMedia!
                if not media
                    @$el .html "Cannot load information if No song playing!"
                else if @lastMediaID == media.id
                    API.once \advance, @loadBind
                else
                    @$el .html "loading…"
                    @load media: media
                @$el .addClass \expanded
            else # hide
                @$el .removeClass \expanded
                API.off \advance, @loadBind
            @visible = not @visible

        return if not _$context
        addListener _$context,  'show:user show:history show:dashboard dashboard:disable', !~> if @visible
            @visible = false
            @$el .removeClass \expanded
            API.off \advance, @loadBind
    load: ({media}, isRetry) !->
        console.log "[song-info]", media
        if @lastMediaID == media.id
            @showInfo media
        else
            @lastMediaID = media.id
            @mediaData = null
            mediaLookup media, do
                fail: (err) !~>
                    console.error "[song-info]", err
                    if isRetry
                        @$el .html "error loading, retrying…"
                        load {media}, true
                    else
                        @$el .html "Couldn't load song info, sorry =("
                success: (@mediaData) !~>
                    console.log "[song-info] got data", @mediaData
                    @showInfo media
            API.once \advance, @loadBind
    showInfo: (media) !->
        return if @lastMediaID != media.id or @disabled # skip if another song is already playing
        d = @mediaData

        @$el .html ""
        $meta = @$create \<div>  .addClass \p0ne-song-info-meta        .appendTo @$el
        $parts = {}

        if media.format == 1
            $meta.addClass \youtube
        else
            $meta.addClass \soundcloud

        $ \<span> .addClass \p0ne-song-info-author      .appendTo $meta
            .click !-> mediaSearch media.author
            .attr \title, "search for '#{media.author}'"
            .text media.author
        $ \<span> .addClass \p0ne-song-info-title       .appendTo $meta
            .click !-> mediaSearch media.title
            .attr \title, "search for '#{media.title}'"
            .text media.title
        $ \<br>                                         .appendTo $meta
        $ \<a> .addClass \p0ne-song-info-uploader       .appendTo $meta
            .attr \href, d.uploader.url
            .attr \target, \_blank
            .attr \title, "open channel of '#{d.uploader.name}'"
            .text d.uploader.name
        $ \<a> .addClass \p0ne-song-info-upload-title   .appendTo $meta
            .attr \href, d.url
            .attr \target, \_blank
            .attr \title, "#{if media.format == 1 then 'open video on YouTube' else 'open Song on SoundCloud'}"
            .text d.title
        $ \<br>                                         .appendTo $meta
        $ \<span> .addClass \p0ne-song-info-date        .appendTo $meta
            .text getDateTime new Date(d.uploadDate)
        $ \<span> .addClass \p0ne-song-info-duration    .appendTo $meta
            .text "duration #{mediaTime +d.duration}"
        if media.format == 1 and d.restriction
            if d.restriction.allowed
                $ \<span> .addClass \p0ne-song-info-blocked     .appendTo @$el
                    .text "exclusively for #{humanList d.restriction.allowed}#{if d.restriction.allowed.length > 100 then '('+d.restriction.allowed.length+'/249)' else ''}"
            if d.restriction.blocked
                $ \<span> .addClass \p0ne-song-info-blocked     .appendTo @$el
                    .text "blocked in #{humanList d.restriction.blocked}#{if d.restriction.blocked.length > 100 then '('+d.restriction.blocked.length+'/249)' else ''}"
        #$ \<div> .addClass \p0ne-song-info-songStats   #ToDo
        #$ \<div> .addClass \p0ne-song-info-songStats   #ToDo
        #$ \<div> .addClass \p0ne-song-info-tags    #ToDo
        $ \<div> .addClass \p0ne-song-info-description  .appendTo @$el
            .html formatPlainText(d.description)
        #$ \<ul> .addClass \p0ne-song-info-remixes      #ToDo
    disable: !->
        @$el? .remove!

/*@source p0ne.avatars.ls */
/**
 * plug_p0ne Custom Avatars
 * adds custom avatars to plug.dj when connected to a plug_p0ne Custom Avatar Server (ppCAS)
 *
 * @author jtbrinkmann aka. Brinkie Pie
 * @license MIT License
 * @copyright (c) 2015 J.-T. Brinkmann
 *
 * Developer's note: if you create your own custom avatar script or use a modified version of this,
 * you are hereby granted permission connect to this one's default avatar server.
 * However, please drop me an e-mail so I can keep an overview of things.
 * I remain the right to revoke this right anytime.
 */

/* THIS IS A TESTING VERSION! SOME THINGS ARE NOT IMPLEMENTED YET! */
/* (this includes things mentioned in the "notes" section below) */
#== custom Avatars ==
#ToDo:
# - check if the "lost connection to server" warning works as expected (only warn on previous successfull connection)
# - improve hitArea (e.g. audience.drawHitArea)
# - avatar creator / viewer
#   - https://github.com/buzzfeed/libgif-js

/*
Notes for Socket Servers:
- server-side:
    - push avatars using something like `socket.trigger('addAvatar', …)`
    - remember, you can offer specific avatars that are for moderators only
    - for people without a role, please do NOT allow avatars that might be confused with staff avatars (e.g. the (old) admin avatars)
        => to avoid confusion
    - dynamically loading avatars is possible
        - e.g. allow users customizing avatars and add them with addAvatar()
            with unique IDs and a URL to a PHP site that generates the avatar
        - WARNING: I HIGHLY discourage from allowing users to set their own images as avatars
            There's ALWAYS "this one guy" who abuses it.
            And most people don't want a bunch of dancing dicks on their screen
- client-side (custom scripts)
    - when listening to userJoins, please use API.on(API.USER_JOIN, …) to avoid conflicts
    - add avatars using addAvatar(…)
    - do not access p0ne._avatars directly, do avoid conflicts and bugs!
    - if you however STILL manually change something, you might need to do updateAvatarStore() to update it
*/

# Hotfix for missing SockJS
#ToDo set up a proper WebSocket ppCAS server xD
if not window.SockJS
    window.Socket = window.WebSocket
    require.config do
        paths:
            sockjs: "#{p0ne.host}/scripts/sockjs"
console.time("[p0ne custom avatars] loaded SockJS")
require <[ sockjs ]>, (SockJS) !->
    console.groupCollapsed "[p0ne custom avatars]"
    console.timeEnd "[p0ne custom avatars] loaded SockJS"
    # users
    if not window.p0ne
        requireHelper \users, (it) !->
            return it.models?.0?.attributes.avatarID
                and \isTheUserPlaying not of it
                and \lastFilter not of it
        window.userID ||= API.getUser!.id
        window.user_ ||= users.get(userID) if users?
        #=======================


        # auxiliaries
        window.sleep ||= (delay, fn) !-> return setTimeout fn, delay

        requireHelper \InventoryDropdown, (.selected)
        requireHelper \avatarAuxiliaries, (.getAvatarUrl)
        requireHelper \Avatar, (.AUDIENCE)
        #requireHelper \AvatarList, (._byId?.admin01)
        for ev in user_?._events?[\change:avatarID] ||[] when ev.ctx.comparator == \id
            window.myAvatars = ev.ctx
            break

        if requireHelper \InventoryAvatarPage, ((a) -> a::?.className == 'avatars' && a::eventName)
            window.InventoryDropdown = new InventoryAvatarPage().dropDown.constructor

    window.Lang = require \lang/Lang

    window.Cells = requireAll (m) !-> return m::?.className == \cell and m::getBlinkFrame


    /*####################################
    #           CUSTOM AVATARS           #
    ####################################*/
    user.avatarID = API.getUser!.avatarID
    module \customAvatars, do
        require: <[ users Lang avatarAuxiliaries Avatar myAvatars InventoryDropdown ]>
        optional: <[ user_ _$context ]>
        displayName: 'Custom Avatars'
        settings: \base
        disabled: true
        help: '''
            This adds a few custom avatars to plug.dj

            You can select them like any other avatar, by clicking on your username (below the chat) and then clicking "My Stuff".
            Click on the Dropdown field in the top-left to select another category.

            Everyone who uses plug_p0ne sees you with your custom avatar.
        '''
        persistent: <[ socket ]>
        _settings:
            vanillaAvatarID: user.avatarID
            avatarID: user.avatarID
        DEFAULT_SERVER: 'https://ppcas.p0ne.com/_'
        setup: ({addListener, @replace, revert, css}, customAvatars) !->
            console.info "[p0ne custom avatars] initializing"

            p0ne._avatars = {}

            avatarID = API.getUser!.avatarID
            hasNewAvatar = @_settings.vanillaAvatarID == avatarID

            # - display custom avatars
            replace avatarAuxiliaries, \getAvatarUrl, (gAU_) !-> return (avatarID, type) !->
                return p0ne._avatars[avatarID]?[type] || gAU_(avatarID, type)
            getAvatarUrl_ = avatarAuxiliaries.getAvatarUrl_
            #replace avatarAuxiliaries, \getHitSlot, (gHS_) !-> return (avatarID) !->
            #    return customAvatarManifest.getHitSlot(avatarID) || gHS_(avatarID)
            #ToDo


            #== AUXILIARIES ==
            # - set avatarID to custom value
            _internal_addAvatar = (d) !->
                # d =~ {category, thumbOffsetTop, thumbOffsetLeft, base_url, anim, dj, b, permissions}
                #   soon also {h, w, standingLength, standingDuration, standingFn, dancingLength, dancingFn}
                avatarID = d.avatarID
                if p0ne._avatars[avatarID]
                    console.info "[p0ne custom avatars] updating '#avatarID'", d
                else if not d.isVanilla
                    console.info "[p0ne custom avatars] adding '#avatarID'", d

                avatar =
                    inInventory: false
                    category: d.category || \p0ne
                    thumbOffsetTop: d.thumbOffsetTop
                    thumbOffsetLeft: d.thumbOffsetLeft
                    isVanilla: !!d.isVanilla
                    permissions: d.permissions || 0
                    #h: d.h || 150px
                    #w: d.w || 150px
                    #standingLength: d.standingLength || 4frames
                    #standingDuration: d.standingDuration || 20frames
                    #standingFn: if typeof d.standingFn == \function then d.standingFn
                    #dancingLength: d.dancingLength || 20frames
                    #dancingFn: if typeof d.dancingFn == \function then d.dancingFn

                #avatar.sw = avatar.w * (avatar.standingLength + avatar.dancingLength) # sw is SourceWidth
                if d.isVanilla
                    avatar."" = getAvatarUrl_(avatarID, "")
                    avatar.dj = getAvatarUrl_(avatarID, \dj)
                    avatar.b = getAvatarUrl_(avatarID, \b)
                else
                    base_url = d.base_url || ""
                    avatar."" = base_url + (d.anim || avatarID+'.png')
                    avatar.dj = base_url + (d.dj || avatarID+'dj.png')
                    avatar.b = base_url + (d.b || avatarID+'b.png')
                p0ne._avatars[avatarID] = avatar
                if avatar.category not of Lang.userAvatars
                    Lang.userAvatars[avatar.category] = avatar.category
                #p0ne._myAvatars[*] = avatar

                delete Avatar.IMAGES["#{avatarID}"] # delete image cache
                delete Avatar.IMAGES["#{avatarID}dj"] # delete image cache
                delete Avatar.IMAGES["#{avatarID}b"] # delete image cache
                #for avi in audience.images when avi.avatarID == avatarID
                #   #ToDo
                if not customAvatars.updateAvatarStore.loading
                    customAvatars.updateAvatarStore.loading = true
                    requestAnimationFrame !-> # throttle to avoid updating every time when avatars get added in bulk
                        customAvatars.updateAvatarStore!
                        customAvatars.updateAvatarStore.loading = false

            @addAvatar = (avatarID, d) !->
                # d =~ {h, w, standingLength, standingDuration, standingFn, dancingLength, dancingFn, url: {base_url, "", dj, b}}
                if typeof d == \object
                    avatar = d
                    d.avatarID = avatarID
                else if typeof avatarID == \object
                    avatar = avatarID
                else
                    throw new TypeError "invalid avatar data passed to addAvatar(avatarID*, data)"
                d.isVanilla = false
                return _internal_addAvatar d
            @removeAvatar = (avatarID, replace) !->
                for u in users.models
                    if u.get(\avatarID) == avatarID
                        u.set(\avatarID, u.get(\avatarID_))
                delete p0ne._avatars[avatarID]



            # - set avatarID to custom value
            @changeAvatar = (userID, avatarID) !~>
                avatar = p0ne._avatars[avatarID]
                if not avatar
                    console.warn "[p0ne custom avatars] can't load avatar: '#{avatarID}'"
                    return

                return if not user = users.get userID

                if not avatar.permissions or API.hasPermissions(userID, avatar.permissions)
                    user.attributes.avatarID_ ||= user.get \avatarID
                    user.set \avatarID, avatarID
                else
                    console.warn "user with ID #userID doesn't have permissions for avatar '#{avatarID}'"

                if userID == user_.id
                    @_settings.avatarID = avatarID

            @updateAvatarStore = !->
                # update thumbs
                styles = ""
                avatarIDs = []; l=0
                for avatarID, avi of p0ne._avatars when not avi.isVanilla
                    avatarIDs[l++] = avatarID
                    styles += "
                        .avi-#avatarID {
                            background-image: url('#{avi['']}');
                            background-position: #{avi.thumbOffsetLeft ||0}px #{avi.thumbOffsetTop ||0}px"
                    styles += "}\n"
                if l
                    css \p0ne_avatars, "
                        .avi {
                            background-repeat: no-repeat;
                        }\n
                        .thumb.small .avi-#{avatarIDs.join(', .thumb.small .avi-')} {
                            background-size: 1393px; /* = 836/15*24 thumbsWidth / thumbsCount * animCount*/
                        }\n
                        .thumb.medium .avi-#{avatarIDs.join(', .thumb.medium .avi-')} {
                            background-size: 1784px; /* = 1115/15*24 thumbsWidth / thumbsCount * animCount*/
                        }\n
                        #styles
                    "

                # update store
                vanilla = []; l=0
                categories = {}
                for avatarID, avi of p0ne._avatars when avi.inInventory /*TEMP FIX*/ or not avi.isVanilla
                    # the `or not avi.isVanilla` should be removed as soon as the server is fixed
                    if avi.isVanilla
                        # add vanilla avatars later to have custom avatars in the top
                        vanilla[l++] = new Avatar(id: avatarID, category: avi.category, type: \avatar)
                    else
                        categories[][avi.category][*] = avatarID
                myAvatars.models = [] #.splice 0 # empty it
                l = 0
                for category, avis of categories
                    for avatarID in avis
                        myAvatars.models[l++] = new Avatar(id: avatarID, category: category, type: \avatar)
                myAvatars.models ++= vanilla
                myAvatars.length = myAvatars.models.length
                myAvatars.trigger \reset, false
                console.log "[p0ne custom avatars] avatar inventory updated"
                return true

            #== Event Listeners ==
            addListener myAvatars, \reset, (vanillaTrigger) !~>
                @updateAvatarStore! if vanillaTrigger

            #== patch avatar inventory view ==
            replace InventoryDropdown::, \draw, (d_) !-> return !->
                html = ""
                categories = {}
                curAvatarID = API.getUser!.avatarID
                for avi in myAvatars.models
                    categories[avi.get \category] = true
                    if avi.id == curAvatarID
                        curCategory = avi.get \category
                curCategory ||= myAvatars.models.0?.get \category

                for category of categories
                    html += "
                        <div class=row data-value='#category'><span>#{Lang.userAvatars[category]}</span></div>
                    "

                @$el
                    .html "
                        <dl class=dropdown>
                            <dt><span></span><i class='icon icon-arrow-down-grey'></i><i class='icon icon-arrow-up-grey'></i></dt>
                            <dd>#html</dd>
                        </dl>
                    "
                    .on \click, \dt,   @~onBaseClick
                    .on \click, \.row, @~onRowClick
                InventoryDropdown.selected = curCategory if not categories[InventoryDropdown.selected]
                @select InventoryDropdown.selected

                @$el.show!


            Lang.userAvatars.p0ne = "Custom Avatars"

            #== add vanilla avatars ==
            /*for {id:avatarID, attributes:{category}} in AvatarList.models
                _internal_addAvatar do
                    avatarID: avatarID
                    isVanilla: true
                    category: category
                    #category: avatarID.replace /\d+$/, ''
                    #category: avatarID.substr(0,avatarID.length-2) damn you "tastycat"
            console.log "[p0ne custom avatars] added internal avatars", p0ne._avatars
            */

            #== patch Avatar Selection ==
            for Cell in window.Cells
                replace Cell::, \onClick, (oC_) !-> return !->
                    console.log "[p0ne custom avatars] Avatar Cell click", this
                    avatarID = this.model.get("id")
                    if /*not this.$el.closest \.inventory .length or*/ not p0ne._avatars[avatarID] or p0ne._avatars[avatarID].inInventory
                        # if avatatar is in the Inventory or not bought, properly select it
                        oC_ ...
                        customAvatars.socket? .emit \changeAvatarID, null
                    else
                        # if not, hax-apply it
                        customAvatars.socket? .emit \changeAvatarID, avatarID
                        customAvatars.changeAvatar(userID, avatarID)
                        @onSelected!
            # - get avatars in inventory -
            $.ajax do
                url: '/_/store/inventory/avatars'
                success: (d) !~>
                    avatarIDs = []; l=0
                    for avatar in d.data
                        avatarIDs[l++] = avatar.id
                        if not  p0ne._avatars[avatar.id]
                            _internal_addAvatar do
                                avatarID: avatar.id
                                isVanilla: true
                                category: avatar.category
                        p0ne._avatars[avatar.id] .inInventory = true
                            #..category = d.category
                    @updateAvatarStore!
                    /*requireAll (m) !->
                        return if not m._models or not m._events?.reset
                        m_avatarIDs = ""
                        for el, i in m._models
                            return if avatarIDs[i] != el
                    */

            if not hasNewAvatar and @_settings.avatarID
                @changeAvatar(userID, that)




            #== fix avatar after reset on socket reconnect ==
            # the order is usually the following:
            # sjs:reconnected, socket:ack, ack, UserEvent:me, RoomEvent:state, change:avatarID (and just about every other user attribute), UserEvent:friends, room:joined, CustomRoomEvent:custom
            # we patch the user_.set after the ack and revert it on the UserEvent:friends. Between those two, the avatar cannot be reverted to the vanilla one, as it's most likely plug automatically doing that
            if _$context? and user_?
                addListener _$context, \ack, !->
                    replace user_, \set, (s_) !-> return (obj, val) !->
                        if obj.avatarID and obj.avatarID == @.get \avatarID_
                            delete obj.avatarID
                        return s_.call this, obj, val
                addListener _$context, \UserEvent:friends, !->
                    revert user_, \set


            /*####################################
            #         ppCAS Integration          #
            ####################################*/
            @oldBlurb = API.getUser!.blurb
            @blurbIsChanged = false

            urlParser = document.createElement \a
            chatCommands.commands.ppcas = do
                description: 'changes the plug_p0ne Custom Avatar Server ("ppCAS")'
                callback: (str) !->
                    server = $.trim str.substr(6)
                    if server == "<url>"
                        chatWarn "hahaha, no. You have to replace '<url>' with an actual URL of a ppCAS server, otherwise it won't work.", "p0ne avatars"
                        return
                    else if server == "."
                        # Veteran avatars
                        # This is more or less for testing only
                        base_url = "https://dl.dropboxusercontent.com/u/4217628/plug.dj/customAvatars/"
                        helper = (fn) !-> # helper to add or remove veteran avatars
                            fn = customAvatars[fn]
                            for avatarID in <[ su01 su02 space03 space04 space05 space06 ]>
                                fn avatarID, do
                                    category: \Veteran
                                    base_url: base_url
                                    thumbOffsetTop: -5px
                            fn \animal12, do
                                category: \Veteran
                                base_url: base_url
                                thumbOffsetTop: -19px
                                thumbOffsetLeft: -16px
                            for avatarID in <[ animal01 animal02 animal03 animal04 animal05 animal06 animal07 animal08 animal09 animal10 animal11 animal12 animal13 animal14 lucha01 lucha02 lucha03 lucha04 lucha05 lucha06 lucha07 lucha08 monster01 monster02 monster03 monster04 monster05 _tastycat _tastycat02 warrior01 warrior02 warrior03 warrior04 ]>
                                fn avatarID, do
                                    category: \Veteran
                                    base_url: base_url
                                    thumbOffsetTop: -10px
                            # if only we had backups of the Halloween avatars :C
                            # if YOU have them, please contact me

                        @socket = close: !->
                            helper \removeAvatar #ToDo check if this is even required
                            delete @socket
                        helper \addAvatar
                        return
                    else if server == \default
                        server = 'https://ppcas.p0ne.com/_'
                    else if server.length == 0
                        chatWarn "Use `/ppCAS <url>` to connect to a plug_p0ne Custom Avatar Server. Use `/ppCAS default` to connect to the default server again.", "p0ne avatars"
                        return
                    urlParser.href = server
                    if urlParser.host != location.host
                        console.log "[p0ne custom avatars] connecting to", server
                        @connect server
                    else
                        console.warn "[p0ne custom avatars] invalid ppCAS server"
            chatCommands.updateCommands!

            @connect(@DEFAULT_SERVER)


        connectAttemps: 1
        connect: (url, reconnecting, reconnectWarning) !->
            if not reconnecting and @socket
                return if url == @socket.url and @socket.readyState == 1
                @socket.close!
            console.log "[p0ne custom avatars] using socket as ppCAS avatar server"
            reconnect = true

            if reconnectWarning
                sleep 10_000ms, !~> if @connectAttemps==0
                    chatWarn "lost connection to avatar server \xa0 =(", "p0ne avatars"

            @socket = new SockJS(url)
            @socket.url = url
            @socket.on = @socket.addEventListener
            @socket.off = @socket.removeEventListener
            @socket.once = (type, callback) !-> @on type, !-> @off(type, callback); callback ...
            @socket.emit = (type, ...data) !->
                console.log "[ppCAS] > [#type]", data
                @send JSON.stringify {type, data}

            @socket.trigger = (type, args) !->
                args = [args] if typeof args != \object or not args?.length
                listeners = @_listeners[type]
                if listeners
                    for fn in listeners
                        fn .apply this, args
                else
                    console.error "[ppCAS] unknown event '#type'"

            @socket.onmessage = ({data: message}) !~>
                try
                    {type, data} = JSON.parse(message)
                    console.log "[ppCAS] < [#type]", data
                catch e
                    console.warn "[ppCAS] invalid message received", message, e
                    return

                @socket.trigger type, data

            close_ = @socket.close
            @socket.close = !->
                @trigger \close
                close_ ...

            # replace old authTokens
            user = API.getUser!
            oldBlurb = user.blurb || ""
            newBlurb = oldBlurb .replace /🐎\w{6}/g, '' # THIS SHOULD BE KEPT IN SYNC WITH ppCAS' AUTH_TOKEN GENERATION
            if oldBlurb != newBlurb
                @changeBlurb newBlurb, do
                    success: !~>
                        console.info "[ppCAS] removed old authToken from user blurb"

            @socket.on \authToken, (authToken) !~>
                user = API.getUser!
                @oldBlurb = user.blurb || ""
                if not user.blurb # user.blurb is actually `null` by default, not ""
                    newBlurb = authToken
                else if user.blurb.length >= 72
                    newBlurb = "#{user.blurb.substr(0, 71)}… 🐎#authToken"
                else
                    newBlurb = "#{user.blurb} 🐎#authToken"

                @blurbIsChanged = true
                @changeBlurb newBlurb, do
                    success: !~>
                        @blurbIsChanged = false
                        @socket.emit \auth, userID
                    error: !~>
                        console.error "[ppCAS] failed to authenticate by changing the blurb."
                        @changeBlurb @oldBlurb, success: !->
                            console.info "[ppCAS] blurb reset."

            @socket.on \authAccepted, !~>
                @connectAttemps := 0
                reconnecting := false
                @changeBlurb @oldBlurb, do
                    success: !~>
                        @blurbIsChanged = false
                    error: !~>
                        chatWarn "failed to authenticate to avatar server, maybe plug.dj is down or changed it's API?", "p0ne avatars"
                        @changeBlurb @oldBlurb, error: !->
                            console.error "[ppCAS] failed to reset the blurb."
            @socket.on \authDenied, !~>
                console.warn "[ppCAS] authDenied"
                chatWarn "authentification failed", "p0ne avatars"
                @changeBlurb @oldBlurb, do
                    success: !~>
                        @blurbIsChanged = false
                    error: !~>
                        @changeBlurb @oldBlurb, error: !->
                            console.error "[ppCAS] failed to reset the blurb."
                chatWarn "Failed to authenticate with user id '#userID'", "p0ne avatars"

            @socket.on \avatars, (avatars) !~>
                user = API.getUser!
                @socket.avatars = avatars
                requestAnimationFrame initUsers if @socket.users
                for avatarID, avatar of avatars
                    @addAvatar avatarID, avatar
                if @_settings.avatarID of avatars
                    @changeAvatar userID, @_settings.avatarID
                else if user.avatarID of avatars
                    @socket.emit \changeAvatarID, user.avatarID

            @socket.on \users, (users) !~>
                @socket.users = users
                requestAnimationFrame initUsers if @socket.avatars

            # initUsers() is used by @socket.on \users and @socket.on \avatars
            ~function initUsers avatarID
                for userID, avatarID of @socket.users
                    console.log "[ppCAS] change other's avatar", userID, "(#{users.get userID ?.get \username})", avatarID
                    @changeAvatar userID, avatarID
                #chatWarn "connected to ppCAS", "p0ne avatars"
                if reconnecting
                    chatWarn "reconnected", "p0ne avatars"
                _$context.trigger \ppCAS:connected
                API.trigger \ppCAS:connected
                #else
                #    chatWarn "avatars loaded. Click on your name in the bottom right corner and then 'Avatars' to become a :horse: pony!", "p0ne avatars"
            @socket.on \changeAvatarID, (userID, avatarID) !->
                console.log "[ppCAS] change other's avatar:", userID, avatarID

                users.get userID ?.set \avatarID, avatarID

            @socket.on \disconnect, (userID) !~>
                console.log "[ppCAS] user disconnected:", userID
                @changeAvatarID userID, avatarID

            @socket.on \disconnected, (reason) !~>
                @socket.trigger \close, reason
            @socket.on \close, (reason) !->
                console.warn "[ppCAS] connection closed", reason
                reconnect := false
            @socket.onclose = (e) !~>
                console.warn "[ppCAS] DISCONNECTED", e
                _$context.trigger \ppCAS:disconnected
                API.trigger \ppCAS:disconnected
                if e.wasClean
                    reconnect := false
                else if reconnect and not @disabled
                    timeout = ~~((5_000ms + Math.random!*5_000ms)*@connectAttemps)
                    console.info "[ppCAS] reconnecting in #{humanTime timeout} (#{xth @connectAttemps} attempt)"
                    @reconnectTimer = sleep timeout, !~>
                        console.log "[ppCAS] reconnecting…"
                        @connectAttemps++
                        @connect(url, true, @connectAttemps==1)
                        _$context.trigger \ppCAS:connecting
                        API.trigger \ppCAS:connecting
            _$context.trigger \ppCAS:connecting
            API.trigger \ppCAS:connecting


        changeBlurb: (newBlurb, options={}) !->
            $.ajax do
                method: \PUT
                url: '/_/profile/blurb'
                contentType: \application/json
                data: JSON.stringify(blurb: newBlurb)
                success: options.success
                error: options.error

            #sleep 5_000ms, !-> if @connectAttemps
            #   @socket.emit \reqAuthToken

        disable: !->
            @changeBlurb @oldBlurb if @blurbIsChanged
            @socket? .close!
            clearTimeout @reconnectTimer
            for avatarID, avi of p0ne._avatars
                avi.inInventory = false
            @updateAvatarStore!
            for ,user of users.models when user.attributes.avatarID_
                user.set \avatarID, that
        #chatWarn "custom avatar script loaded. type '/ppCAS <url>' into chat to connect to an avatar server :horse:", "ppCAS"

    console.groupEnd "[p0ne custom avatars]"

/*@source p0ne.settings.ls */
/**
 * Settings pane for plug_p0ne
 *
 * @author jtbrinkmann aka. Brinkie Pie
 * @license MIT License
 * @copyright (c) 2015 J.-T. Brinkmann
 */

/*####################################
#              SETTINGS              #
####################################*/
module \p0neSettings, do
    _settings:
        groupToggles: {p0neSettings: true, base: true}
    setup: ({$create, addListener}, p0neSettings, oldModule) !->
        @$create = $create

        groupToggles = @groupToggles = @_settings.groupToggles ||= {p0neSettings: true, base: true}

        #= create DOM elements =
        $ppM = $create "<div id=p0ne-menu>" # (only the root needs to be created with $create)
            .insertAfter \#app-menu
        $ppI = $create "<div class=p0ne-icon>p<div class=p0ne-icon-sub>0</div></div>"
            .appendTo $ppM
        $ppW = @$ppW = $ "<div class=p0ne-settings-wrapper>"
            .appendTo $ppM
        $ppS = $create "<div class='p0ne-settings noselect'>"
            .appendTo $ppW
        $ppP = $create "<div class=p0ne-settings-popup>"
            .appendTo $ppM
            .fadeOut 0

        #debug
        #@<<<<{$ppP, $ppM, $ppI}

        #= add "simple" settings =
        @$vip = $ "<div class=p0ne-settings-vip>" .appendTo $ppS

        @toggleMenu groupToggles.p0neSettings

        #= settings footer =
        @$ppInfo = $ "
            <div class=p0ne-settings-footer>
                <div class=p0ne-icon>p<div class=p0ne-icon-sub>0</div></div>
                <div class=p0ne-settings-version>v#{p0ne.version}</div>
                <div class=p0ne-settings-help-btn>help</div>
                <div class=p0ne-settings-expert-toggle>show all options</div>
            </div>"
            .appendTo $ppS

        #= add toggles for existing modules =
        for ,module of p0ne.modules when not module.loading
            @addModule module


        do addListener API, \p0ne:stylesLoaded, !~> requestAnimationFrame !~>
            for group, $el of @groups when @_settings.groupToggles[group]
                $el .trigger \p0ne:resize



        #= add DOM event listeners =
        # slide settings-menu in/out
        $ppI .click !~> @toggleMenu!

        # toggle groups
        addListener $body, \click, \.p0ne-settings-summary, throttle 200ms, (e) !->
            $s = $ this .parent!
            if $s.hasClass \open # close
                groupToggles[$s.data \group] = false
                $s
                    .removeClass \open
                    .css height: 40px
                    #.stop! .animate height: 40px, \slow
            else
                groupToggles[$s.data \group] = true
                $s
                    .addClass \open
                    #.stop! .animate height: $s.children!.length * 44px, \slow /* magic number, height of a .p0ne-settings-item*/
                    .trigger \p0ne:resize
            e.preventDefault!

        addListener $body, \p0ne:resize, \.p0ne-settings-group, (e) !->
            $this = $ this
            if p0neSettings._settings.groupToggles[$this.data \group]
                $this .css height: 0 # reset scrollHeight
                $this .css height: @scrollHeight # make group as large as content
            $this .scrollTop 0

        addListener $ppW, \click, \.checkbox, throttle 200ms, !->
            # this gets triggered when anything in the <label> is clicked
            $this = $ this
            enable = this .checked
            $el = $this .closest \.p0ne-settings-item
            module = $el.data \module
            module = window[module] ||{} if typeof module == \string
            #console.log "[p0neSettings] toggle", module.displayName, "=>", enable
            if enable
                module.enable!
            else
                module.disable!
        addListener $ppW, \click, \.p0ne-settings-panel-icon, throttle 200ms, (e) !->
            $this = $ this .closest \.p0ne-settings-item
            module = $this .data \module
            if not module._$settingsPanel
                module._$settingsPanel =
                    open: false
                    wrapper: $ '<div class=p0ne-settings-panel-wrapper>' .appendTo $ppM
                    $el: $ '<div class=p0ne-settings-panel>'
                module._$settingsPanel.$el .appendTo module._$settingsPanel.wrapper
                module.settingsPanel(module._$settingsPanel.$el, module)

            offsetLeft = $ppW.width!
            if module._$settingsPanel.open # close panel
                module._$settingsPanel.wrapper
                    .animate do
                        left: offsetLeft - module._$settingsPanel.$el.width!
                        -> module._$settingsPanel.wrapper.hide!
            else # open panel
                module._$settingsPanel.wrapper
                    .show!
                    .css left: offsetLeft - module._$settingsPanel.$el.width!
                    .animate left: offsetLeft
            e.preventPropagation!

        addListener $ppW, \mouseover, \.p0ne-settings-has-more, !->
            $this = $ this
            module = $this .data \module
            $ppP .html "
                    <div class=p0ne-settings-popup-triangle></div>
                    <h3>#{module.displayName}</h3>
                    #{module.help}
                    #{if!   module.screenshot   then'' else
                        '<img src='+module.screenshot+'>'
                    }
                "
            l = $ppW.width!
            maxT = $ppM .height!
            h = $ppP .height!
            t = $this .offset! .top - 50px
            tt = t - h/2 >? 0px
            diff = tt - (maxT - h - 30px)
            if diff > 0
                t += diff + 10px - tt
                tt -= diff
            else if tt != 0
                t = \50%
            $ppP
                .css top: tt, left: l
                .stop!.fadeIn!
            $ppP .find \.p0ne-settings-popup-triangle
                .css top: 14px >? t
        addListener $ppW, \mouseout, \.p0ne-settings-has-more, !->
            $ppP .stop!.fadeOut!
        addListener $ppP, \mouseover, !->
            $ppP .stop!.fadeIn!
        addListener $ppP, \mouseout, !->
            $ppP .stop!.fadeOut!

        # add p0ne.module listeners
        #= module INITALIZED =
        addListener API, \p0ne:moduleLoaded, (module) !~> @addModule module

        #= module ENABLED =
        addListener API, \p0ne:moduleEnabled, (module) !~>
            module._$settings?
                .addClass \p0ne-settings-item-enabled
                .find \.checkbox .0 .checked=true
            @loadSettingsExtra true, module
            if @_settings.groupToggles[module.settings]
                requestAnimationFrame !~>
                    @groups[module.settings] .trigger \p0ne:resize

        #= module UPDATED =
        addListener API, \p0ne:moduleUpdated, (module, module_) !~>
            if module.settings
                @addModule module, module_
                if module.help != module_.help and module._$settings?.is \:hover
                    # force update .p0ne-settings-popup (which displays the module.help)
                    module._$settings .mouseover!

        #= module DISABLES =
        addListener API, \p0ne:moduleDisabled, (module_) !~>
            module_._$settings?
                .removeClass \p0ne-settings-item-enabled
                .find \.checkbox
                    .attr \checked, false
            module_._$settingsExtra?
                .stop!
                .slideUp !->
                    $ this
                        .trigger \p0ne:resize
                        .remove!

        addListener $body, \click, \#app-menu, !~> @toggleMenu false
        if _$context?
            addListener _$context, 'show:user show:history show:dashboard dashboard:disable', !~> @toggleMenu false

        # plugCubed compatibility
        addListener $body, \click, \#plugcubed, !~>
            @toggleMenu false

        # Firefox compatibility
        # When Firefox calculates the width of .p0ne-settings, it doesn't add the width of the scrollbar (if any)
        # This causes a second, horizontal scrollbar to be displayed
        # and/or the module icons to be overlayed by the scrollbar
        # to fix this, we add a padding to the .p0ne-settings-wrapper width the size of the scrollbar
        # it looks ugly, but it does the job
        _.defer !->
            d = $ \<div>
                .css do
                    height: 100px, width: 100px, overflow: \auto
                .append do
                    $ \<div> .css height: 102px, width: 100px
                .appendTo \body
            if \scrollLeftMax of d.0
                scrollLeftMax = d.0.scrollLeftMax
            else
                d.0.scrollLeft = Number.POSITIVE_INFINITY
                scrollLeftMax = d.0.scrollLeft
            if scrollLeftMax != 0px # on proper browsers, it should be 0
                # on some browsers, `scrollLeftMax` should be the width of the scrollbar
                $ppW .css paddingRight: scrollLeftMax
            d.remove!

    toggleMenu: (state) !->
        if state ?= not @groupToggles.p0neSettings
            @$ppW.slideDown!
        else
            @$ppW.slideUp!
        @groupToggles.p0neSettings = state


    groups: {}
    moderationGroup: $!
    addModule: (module, module_) !->
        if module.settings
            # prepare extra icons to be added to the module's settings element
            itemClasses = \p0ne-settings-item
            icons = ""
            for k in <[ help screenshot ]> when module[k]
                icons += "<div class=p0ne-settings-#k></div>"
            if module.settingsPanel
                icons += "<div class=p0ne-settings-panel-icon><i class='icon icon-settings-white'></i></div>"
            if icons.length
                icons = "<div class=p0ne-settings-icons>#icons</div>"
                itemClasses += ' p0ne-settings-has-more'
            itemClasses += ' p0ne-settings-has-extra' if module.settingsExtra
            itemClasses += ' p0ne-settings-item-enabled' if not module.disabled

            if module.settingsVip
                # VIP settings get their special place
                $s = @$vip
                itemClasses += ' p0ne-settings-is-vip'
            else if not $s = @groups[module.settings]
                # create settings group if not yet existing
                $s = @groups[module.settings] = $ '<div class=p0ne-settings-group>'
                    .data \group, module.settings
                    .append do
                        $ '<div class=p0ne-settings-summary>' .text module.settings.toUpperCase!
                    .insertBefore @$ppInfo
                if @_settings.groupToggles[module.settings]
                    $s .addClass \open
                else
                    $s .css height: 40px

                if module.settings == \moderation
                    $s .addClass \p0ne-settings-group-moderation

                # (animatedly) open the settings group
                if @_settings.groupToggles[module.settings]
                    #.stop! .animate height: $s.children!.length * 44px, \slow
                    $s .find \.p0ne-settings-summary .click!
            # otherwise we already created the settings group

            # create the module's settings element and append it to the settings group
            # note: $create doesn't have to be used, because the resulting elements are appended to a $create'd element
            module._$settings = $ "
                    <label class='#itemClasses'>
                        <input type=checkbox class=checkbox #{if module.disabled then '' else \checked} />
                        <div class=togglebox><div class=knob></div></div>
                        #{module.displayName}
                        #icons
                    </label>
                "
                .data \module, module

            if module_?._$settings?.parent! .is $s
                module_._$settings
                    .after do
                        module._$settings .addClass \updated
                    .remove!
                sleep 2_000ms, !->
                    module._$settings .removeClass \updated
                @loadSettingsExtra false, module, module_ if not module.disabled
            else
                module._$settings .appendTo $s

                # render extra settings element if module is enabled
                @loadSettingsExtra false, module if not module.disabled




    loadSettingsExtra: (autofocus, module, module_) !->
        try
            module_?._$settingsExtra? .remove!
            if module.settingsExtra
                module.settingsExtra do
                    module._$settingsExtra = $ "<div class=p0ne-settings-extra>"
                        .hide!
                        .insertAfter module._$settings
                # using rAF because otherwise jQuery calculates the height incorrectly
                requestAnimationFrame !~>
                    module._$settingsExtra
                        .slideDown ->
                            module._$settingsExtra .trigger \p0ne:resize
                    if autofocus
                        module._$settingsExtra .find \input .focus!
                    else
                        module._$settings .parent! .scrollTop 0
        catch err
            console.error "[#{module.name}] error while processing settingsExtra", err.stack
            module._$settingsExtra?
                .remove!
            @groups[module.settings] .trigger \p0ne:resize

/*@source p0ne.moderate.ls */
/**
 * plug_p0ne modules to help moderators do their job
 *
 * @author jtbrinkmann aka. Brinkie Pie
 * @license MIT License
 * @copyright (c) 2015 J.-T. Brinkmann
 */

/*####################################
#       BASE MODERATION MODULE       #
####################################*/
module \enableModeratorModules, do
    require: <[ user_ ]>
    setup: ({addListener}) !->
        prevRole = user_.get \role
        $body.addClass \user-is-staff if user.isStaff

        addListener user_, \change:role, (user_, newRole) !->
            console.log "[p0ne] change:role from #prevRole to #newRole"
            if newRole > 1 and prevRole < 2
                console.info "[p0ne] enabling moderator modules"
                for ,m of p0ne.modules when m.modDisabled
                    console.log "[p0ne moderator] enabling", m.name
                    m.enable!
                    m.modDisabled = false
                $body.addClass \user-is-staff
                user_.isStaff = true
            else if newRole < 2 and prevRole > 1
                console.info "[p0ne] disabling moderator modules"
                for ,m of p0ne.modules when m.moderator    and not m.disabled
                    console.log "[p0ne moderator] disabling", m.name
                    m.modDisabled = true
                    m.disable!
                $body.removeClass \user-is-staff
                user_.isStaff = false
            prevRole := newRole
    disable: !->
        $body.removeClass \user-is-staff



/*####################################
#       WARN ON HISTORY PLAYS        #
####################################*/
module \warnOnHistory, do
    displayName: 'Warn on History'
    moderator: true
    settings: \moderation
    setup: ({addListener}) !->
        addListener API, \advance, (d) !~> if d.media
            hist = API.getHistory!
            inHistory = 0; skipped = 0
            # note: the CIDs of YT and SC songs should not be able to cause conflicts
            for m, i in hist when m.media.cid == d.media.cid and i != 0
                lastPlayI ||= i
                lastPlay ||= m
                inHistory++
                skipped++ if m.skipped
            if inHistory
                msg = ""
                if inHistory > 1
                    msg += "#{inHistory}x "
                msg += "(#{lastPlayI + 1}/#{hist.length - 1}) "
                if skipped == inHistory
                    msg += "but was skipped last time "
                if skipped > 1
                    msg += "it was skipped #skipped/#inHistory times "
                chatWarn msg, 'Song is in History'
                API.trigger \p0ne:songInHistory


/*####################################
#      DISABLE MESSAGE DELETE        #
####################################*/
module \disableChatDelete, do
    require: <[ _$context user_ ]>
    optional: <[ socketListeners ]>
    moderator: true
    displayName: 'Show deleted messages'
    settings: \moderation
    setup: ({replace_$Listener, addListener, $createPersistent, css}) !->
        css \disableChatDelete, '
            .deleted {
                border-left: 2px solid red;
                display: none;
            }
            .p0ne-showDeletedMessages .deleted {
                display: block;
            }
            .deleted-message {
                display: block;
                text-align: right;
                color: red;
                font-family: monospace;
            }
        '

        $body .addClass \p0ne-showDeletedMessages

        lastDeletedCid = null
        addListener _$context, \socket:chatDelete, ({{c,mi}:p}) !->
            markAsDeleted(c, users.get(mi)?.get(\username) || mi)
            lastDeletedCid := c
        #addListener \early, _$context, \chat:delete, !-> return (cid) !->
        replace_$Listener \chat:delete, !-> return (cid) !->
            markAsDeleted(cid) if cid != lastDeletedCid

        function markAsDeleted cid, moderator
            if chat?.lastText?.hasClass "cid-#cid"
                $msg = chat.lastText .parent!.parent!
                isLast = true
            else
                $msg = getChat cid
            console.log "[Chat Delete]", cid, $msg.text!
            t  = getISOTime!
            try
                uid = cid.split(\-)?.0
                $msg .addClass \deleted if cid == uid or not getUser(uid)?.gRole
                d = $createPersistent getTimestamp!
                    .addClass \delete-timestamp
                    .removeClass \timestamp
                    .appendTo $msg
                d .text "deleted #{if moderator then 'by '+moderator else ''} #{d.text!}"
                cm = $cm!
                cm.scrollTop cm.scrollTop! + d.height!

                if isLast
                    chat.lastType = \p0ne-deleted

    disable: !->
        $body .removeClass \p0ne-showDeletedMessages


/*####################################
#         DELETE OWN MESSAGES        #
####################################*/
module \chatDeleteOwnMessages, do
    moderator: true
    #displayName: 'Delete Own Messages'
    #settings: \moderation
    setup: ({addListener}) !->
        $cm! .find "fromID-#{userID}"
            .addClass \deletable
            .append do
                $ '<div class="delete-button">Delete</div>'
                    .click delCb
        addListener API, \chat, ({cid, uid}:message) !-> if uid == userID
            getChat(cid)
                .addClass \deletable
                .append do
                    $ '<div class="delete-button">Delete</div>'
                        .click delCb
        function delCb
            $ this .closest \.cm .data \cid |> API.moderateDeleteChat


/*####################################
#            WARN ON MEHER           #
####################################*/
module \warnOnMehers, do
    users: {}
    moderator: true
    displayName: 'Warn on Mehers'
    settings: \moderation
    _settings:
        instantWarn: false
        maxMehs: 3
    setup: ({addListener},, m_) !->
        if m_
            @users = m_.users
        users = @users

        current = {}
        addListener API, \voteUpdate, (d) !~>
            current[d.user.id] = d.vote
            if d.vote == -1 and d.user.uid != userID
                console.error "#{formatUser d.user, true} meh'd this song"
                if @_settings.instantWarn
                    appendChat $ "
                        <div class='cm system'>
                            <div class=box><i class='icon icon-chat-system'></i></div>
                            <div class='msg text'>
                                #{formatUserHTML d.user, true} meh'd this song!
                            </div>
                        </div>"

        lastAdvance = 0
        addListener API, \advance, (d) !~>
            d = Date.now!
            for cid,v of current
                if v == -1
                    users[cid] ||= 0
                    if ++users[cid] > @_settings.maxMehs and troll = getUser(cid)
                        # note: the user (`troll`) may have left during this song
                        appendChat $ "
                            <div class='cm system'>
                                <div class=box><i class='icon icon-chat-system'></i></div>
                                <div class='msg text'>
                                    #{formatUserHTML troll} meh'd the past #{plural users[cid], 'song'}!
                                </div>
                            </div>"
                else if d > lastAdvance + 10_000ms
                    delete users[cid]
            if d > lastAdvance + 10_000ms
                for {cid} in API.getUsers! when not current[cid] and d.lastPlay?.dj.id != cid
                    delete users[cid]
            current := {}
            lastAdvance := d

    settingsExtra: ($el) !->
        warnOnMehers = this
        var resetTimer
        $ "
            <form>
                <label>
                    <input type=radio name=max-mehs value=on #{if @_settings.instantWarn then \checked else ''}> alert instantly
                </label><br>
                <label>
                    <input type=radio name=max-mehs value=off #{if @_settings.instantWarn then '' else \checked}> alert after <input type=number value='#{@_settings.maxMehs}' class='p0ne-settings-input max-mehs'> consequitive mehs
                </label>
            </form>"
            .append do
                $warning = $ '<div class=warning>'
            .on \click, \input:radio, !->
                if @checked
                    warnOnMehers._settings.instantWarn = (@value == \on)
                    console.log "#{getTime!} [warnOnMehers] updated instantWarn to #{warnOnMehers._settings.instantWarn}"
            .on \input, \.max-mehs, !->
                val = ~~@value # note: invalid numbers (NaN) get floored to 0
                if val > 1
                    warnOnMehers._settings.maxMehs = val
                    if resetTimer
                        $warning .fadeOut!
                        clearTimeout resetTimer
                        resetTimer := 0
                    if warnOnMehers._settings.instantWarn
                        $ this .parent! .click!
                    console.log "#{getTime!} [warnOnMehers] updated maxMehs to #val"
                else
                    $warning
                        .fadeIn!
                        .text "please enter a valid number >1"
                    resetTimer := sleep 2.min, !~>
                        @value = warnOnMehers._settings.maxMehs
                        resetTimer := 0
                    console.warn "#{getTime!} [warnOnMehers] invalid input for maxMehs", @value
            .appendTo $el
        $el .css do
            paddingLeft: 15px


/*####################################
#              AFK TIMER             #
####################################*/
module \afkTimer, do
    require: <[ RoomUserRow WaitlistRow ]>
    optional: <[ socketListeners app userList _$context ]>
    moderator: true
    settings: \moderation
    displayName: "Show Idle Time"
    help: '''
        This module shows how long users have been inactive in the User- and Waitlist-Panel.
        "Being active"
    '''
    _settings:
        lastActivity: {}
        highlightOver: 43.min

    setup: ({addListener, $create, replace},, m_) !->
        # initialize users
        settings = @_settings
        start = Date.now!
        if m_
            console.log "m_ =", m_
            @start = m_.start
            lastActivity = m_._settings.lastActivity ||{}
        else
            console.log "args", arguments
            @start = start
            if @_settings.lastActivity?.0 + 60_000ms > Date.now!
                lastActivity = @_settings.lastActivity
            else
                lastActivity = {}
        @lastActivity = lastActivity

        for user in API.getUsers!
            lastActivity[user.id] ||= start
        start = @start


        $waitlistBtn = $ \#waitlist-button
            .append $afkCount = $create '<div class=p0ne-toolbar-count>'

        # set up event listeners to update the lastActivity time
        addListener API, 'socket:skip socket:grab', (id) !-> updateUser id
        addListener API, 'userJoin socket:nameChanged', (u) !-> updateUser u.id
        addListener API, 'chat', (u) !-> if not /afk/i.test(u.message) then updateUser u.uid
        addListener API, 'socket:gifted', (e) !-> updateUser e.s/*ender*/
        addListener API, 'socket:modAddDJ socket:modBan socket:modMoveDJ socket:modRemoveDJ socket:modSkip socket:modStaff', (u) !-> updateUser u.mi
        addListener API, 'userLeave', (u) !-> delete lastActivity[u.id]

        chatHidden = $cm!.parent!.css(\display) == \none
        if _$context? and (app? or userList?)
            addListener _$context, 'show:users show:waitlist', !->
                chatHidden := true
            addListener _$context, \show:chat, !->
                chatHidden := false

        # regularly update the AFK list / count
        lastAfkCount = 0
        var afkCount
        @timer = repeat 60_000ms, fn=!->
            if chatHidden
                forceRerender!
            else
                # update AFK user count
                afkCount := 0
                d = Date.now!
                usersToCheck = API.getWaitList!
                usersToCheck[*] = that if API.getDJ!
                for u in usersToCheck when d - lastActivity[u.id] > settings.highlightOver
                    afkCount++
                #console.log "[afkTimer] afkCount", afkCount
                if afkCount != lastAfkCount
                    if afkCount
                        #$waitlistBtn .addClass \p0ne-toolbar-highlight if lastAfkCount == 0
                        $afkCount .text afkCount
                    else
                        #$waitlistBtn .removeClass \p0ne-toolbar-highlight
                        $afkCount .clear!
                    lastAfkCount := afkCount
        fn!

        # UI
        d = 0
        var noActivityYet
        for Constr, fn in [RoomUserRow, WaitlistRow]
            replace Constr::, \render, (r_) !-> return (isUpdate) !->
                r_ ...
                if not d
                    d := Date.now!
                    <-! requestAnimationFrame
                    d := 0; noActivityYet := null
                ago = d - lastActivity[@model.id]
                if lastActivity[@model.id] <= start
                    if ago < 120_000ms
                        time = noActivityYet ||= "? "
                    else
                        time = noActivityYet ||= ">#{humanTime(ago, true)}"
                else if ago < 60_000ms
                    time = "<1m"
                else if ago < 120_000ms
                    time = "<2m"
                else
                    time = humanTime(ago, true)

                if @$afk
                    @$afk .removeClass 'p0ne-last-activity-warn'
                else
                    @$afk = $ '<span class=p0ne-last-activity>'
                        .appendTo @$el
                @$afk .text time
                @$afk .addClass \p0ne-last-activity-warn if ago > settings.highlightOver
                if isUpdate
                    @$afk .addClass \p0ne-last-activity-update
                    <~! requestAnimationFrame
                    @$afk .removeClass \p0ne-last-activity-update



        function updateUser uid
            if Date.now! - lastActivity[uid] > settings.highlightOver
                afkCount--
                $afkCount .text afkCount
            lastActivity.0 = lastActivity[uid] = Date.now!
            # waitlist.rows defaults to [], so no need to ||[]
            for r in userList?.listView?.rows || app?.room.waitlist.rows when r.model.id == uid
                r.render true

        # update current rows (it should not be possible, that the waitlist and userlist are populated at the same time)
        function forceRerender
            for r in app?.room.waitlist.rows || userList?.listView?.rows ||[]
                r.render false

        forceRerender!

    disable: !->
        clearInterval @timer
        $ \#waitlist-button
            .removeClass \p0ne-toolbar-highlight
        #$ '.app-right .p0ne-last-activity' .remove!
    disableLate: !->
        for r in app?.room.waitlist.rows || userList?.listView?.rows ||[]
            r.render!


/*####################################
#           FORCE SKIP BTN           #
####################################*/
module \forceSkipButton, do
    moderator: true
    setup: ({$create}, m) !->
        @$btn = $create '<div class=p0ne-skip-btn><i class="icon icon-skip"></i></div>'
            .insertAfter \#playlist-panel
            .click @~onClick
    onClick: API.moderateForceSkip

/*@source p0ne.userHistory.ls */
/**
 * small module to show a user's song history on plug.dj
 * fetches the song history from the user's /@/profile page
 *
 * @author jtbrinkmann aka. Brinkie Pie
 * @license MIT License
 * @copyright (c) 2015 J.-T. Brinkmann
*/
#HistoryItem = RoomHistory::collection.model if RoomHistory


/*####################################
#            USER HISTORY            #
####################################*/
module \userHistory, do
    require: <[ userRollover RoomHistory backbone ]>
    help: '''
        Shows another user's song history when clicking on their username in the user-rollover.

        Due to technical restrictions, only Youtube songs can be shown.
    '''
    setup: ({addListener, replace, css}) !->
        css \userHistory, '#user-rollover .username { cursor: pointer }'

        addListener $(\body), \click, '#user-rollover .username', !->
            $ '#history-button.selected' .click! # hide history if already open
            user = userRollover.user
            userID = user.id
            username = user.get \username
            userlevel = user.get \level
            userslug = user.get \slug
            if userlevel < 5
                userRollover.$level .text "#{userlevel} (user-history requires >4!)"
                return
            console.log "#{getTime!} [userHistory] loading #username's history"
            if not userslug
                getUserData userID .then (d) !->
                    user.set \slug, d.slug
                    loadUserHistory user
            else
                loadUserHistory user

        function loadUserHistory user
            $.get "https://plug.dj/@/#{user.get \slug}"
                .fail !->
                    console.error "! couldn't load user's history"
                .then (d) !->
                    userRollover.cleanup!
                    songs = new backbone.Collection()
                    d.replace /<div class="row">\s*<img src="(.*)"\/>\s*<div class="meta">\s*<span class="author">(.*?)<\/span>\s*<span class="name">(.*?)<\/span>[\s\S]*?positive"><\/i><span>(\d+)<\/span>[\s\S]*?grabs"><\/i><span>(\d+)<\/span>[\s\S]*?negative"><\/i><span>(\d+)<\/span>[\s\S]*?listeners"><\/i><span>(\d+)<\/span>/g, (,img, author, roomName, positive, grabs, negative, listeners) !->
                        if cid = /\/vi\/(.{11})\//.exec(img)
                            cid = cid.1
                            [title, author] = author.split " - "
                            songs.add new backbone.Model do
                                user: {id: user.id, username: "in #roomName"}
                                room: {name: roomName}
                                score:
                                    positive: positive
                                    grabs: grabs
                                    negative: negative
                                    listeners: listeners
                                    skipped: 0
                                media: new backbone.Model do
                                    format: 1
                                    cid: cid
                                    author: author
                                    title: title
                                    image: httpsify(img)
                    console.info "#{getTime!} [userHistory] loaded history for #{user.get \username}", songs
                    export songs, d
                    replace RoomHistory::, \collection, !-> return songs
                    _$context.trigger \show:history
                    <-! requestAnimationFrame
                    RoomHistory::.collection = RoomHistory::.collection_
                    console.log "#{getTime!} [userHistory] restoring room's proper history"

/*@source p0ne.dev.ls */
/**
 * plug_p0ne dev
 * a set of plug_p0ne modules for usage in the console
 * They are not used by any other module
 *
 * @author jtbrinkmann aka. Brinkie Pie
 * @license MIT License
 * @copyright (c) 2015 J.-T. Brinkmann
 */

/*####################################
#        FIX CONSOLE SPAMMING        #
####################################*/
module \fixConsoleSpamming, do
    setup: ({replace}) !->
        /* this fixes a bug in plug.dj. Version 1.2.6.6390 (2015-02-15)
         * which spams the console with console.info(undefined)
         * everytime the socket receives a message.
         * On WebKit browsers it's ignored, on others (e.g. Firefox)
         * it will create many empty messages in the console
         * (https://i.imgur.com/VBzw2ek.png screenshot from Firefox' Web Console)
        */
        replace console, \info, (info_) !-> return !->
            info_ ... if arguments.length

/*####################################
#      SANDBOX BACKBONE EVENTS       #
####################################*/
module \sandboxBackboneEvents, do
    optional: <[ _$context ]>
    setup: ({replace}) !->
        #= wrap API/_$context event trigger in a try-catch =
        slice = Array::slice
        replace Backbone.Events, \trigger, !-> return (type) !->
            if @_events
                args = slice.call(arguments, 1); [a,b,c]=args
                while true # run once for the specified event and once for "all"
                    if (events = @_events[type]) and (l = events.length)
                        i = -1
                        while i < l
                            try
                                switch args.length
                                | 0 => (while ++i < l then (ev=events[i]).callback.call(ev.ctx))
                                | 1 => (while ++i < l then (ev=events[i]).callback.call(ev.ctx, a))
                                | 2 => (while ++i < l then (ev=events[i]).callback.call(ev.ctx, a, b))
                                | 3 => (while ++i < l then (ev=events[i]).callback.call(ev.ctx, a, b, c))
                                | _ => (while ++i < l then (ev=events[i]).callback.apply(ev.ctx, args))
                            catch e
                                console.error "[#{@_name || 'unnamed EventEmitter'}] Error while triggering '#type' [#i]", this, args, e.stack
                    return this if type == \all
                    args.unshift(type); [a,b,c]=args
                    type = \all

        replace API, \_name, !-> return \API
        replace API, \trigger, !-> return Backbone.Events.trigger
        if _$context?
            replace _$context, \_name, !-> return \_$context
            replace _$context, \trigger, !-> return Backbone.Events.trigger

/*####################################
#           LOG EVERYTHING           #
####################################*/
module \logEventsToConsole, do
    optional: <[ _$context  socketListeners ]>
    displayName: "Log Events to Console"
    settings: \dev
    help: '''
        This will log events to the JavaScript console.
        This is mainly for programmers. If you are none, keep this disabled for better performance.

        By default this will leave out some events to avoid completly spamming the console.
        You can force-enable logging ALL events by running `logEventsToConsole.logAll = true`
    '''
    disabledByDefault: true
    logAll: false
    setup: ({addListener}) !->
        logEventsToConsole = this
        if _$context?
            ctx = _$context
            chatEvnt = \chat:receive
        else
            ctx = API
            chatEvnt = \chat
        addListener \early, ctx, chatEvnt, (data) !->
            message = cleanMessage data.message
            if data.un
                name = data.un .replace(/\u202e/g, '\\u202e') |> collapseWhitespace
                name = " " * (24 - name.length) + name |> stripHTML
                if data.type == \emote
                    console.log "#{getTime!} [CHAT] %c#name: %c#message", "font-weight: bold", "font-style: italic"
                else
                    console.log "#{getTime!} [CHAT] %c#name: %c#message", "font-weight: bold", ""
            else if data.type.has \system
                console.info "#{getTime!} [CHAT] [system] %c#message", "font-size: 1.2em; color: red; font-weight: bold"
            else
                console.log "#{getTime!} [CHAT] %c#message", 'color: #36F'

        addListener API, \userJoin, (user) !->
            console.log "#{getTime!} + [JOIN]", user.id, formatUser(user, true), user
        addListener API, \userLeave, (user) !->
            name = htmlUnescape(user.username) .replace(/\u202e/g, '\\u202e')
            console.log "#{getTime!} - [LEAVE]", user.id, formatUser(user, true), user


        #= log (nearly) all _$context events
        return if not window._$context
        addListener _$context, \all, !-> return (type, args) !->
            group = type.substr(0, type.indexOf ":")
            if group not in <[ socket tooltip djButton chat sio playback playlist notify drag audience anim HistorySyncEvent user ShowUserRolloverEvent ]> and type not in <[ ChatFacadeEvent:muteUpdate PlayMediaEvent:play userPlaying:update context:update ]> or logEventsToConsole.logAll
                console.log "#{getTime!} [#type]", args
            else if group == \socket and type not in <[ socket:chat socket:vote socket:grab socket:earn ]>
                console.log "#{getTime!} [#type]", args

        addListener _$context, \PlayMediaEvent:play, (data) !->
            #data looks like {type: "PlayMediaEvent:play", media: n.hasOwnProperty.i, startTime: "1415645873000,0000954135", playlistID: 5270414, historyID: "d38eeaec-2d26-4d76-8029-f64e3d080463"}

            console.log "#{getTime!} [SongInfo]", "playlist: #{data.playlistID}", "historyID: #{data.historyID}"



/*####################################
#            LOG GRABBERS            #
####################################*/
module \logGrabbers, do
    require: <[ votes ]>
    setup: ({addListener, replace}) !->
        grabbers = {}
        hasGrabber = false
        replace votes, \grab, (g_) !-> return (uid) !->
            u = getUser(uid)
            console.info "#{getTime!} [logGrabbers] #{formatUser u, user.isStaff} grabbed this song"
            grabbers[uid] = u.username
            hasGrabber := true
            return g_.call(this, uid)
        addListener API, \advance, !->
            if grabbers
                console.log "[logGrabbers] the last song was grabbed by #{humanList [name for ,name of grabbers]}"
                grabbers := {}
            else
                hasGrabber := false

/*####################################
#             DEV TOOLS              #
####################################*/
module \InternalAPI, do
    optional: <[ users playlists user_ app  ]>
    setup: !->
        for k,v of API
            if not @[k]
                @[k] = v
            else if @[k] == \user
                let k=k
                    @[k] = !-> getUserInternal(API[k]!?.id)
        this <<<< Backbone.Events
    chatLog: API.chatLog
    getAdmins: !-> return users?.filter (.get(\gRole) == 5)
    getAmbassadors: !-> return users?.filter (u) !-> 0 < u.get(\gRole) < 5
    getAudience: users?.getAudience
    getBannedUsers: !-> ...
    getDJ: !-> return getUserInternal(API.getDJ!?.id)
    getHistory: !-> return roomHistory
    getHost: !-> return getUserInternal(API.getHost!?.id)
    getMedia: !-> return currentMedia?.get \media
    getNextMedia: !-> return playlists?.activeMedia.0
    getUser: !-> return user_
    getUsers: !-> return users
    getPlaylist: window.getActivePlaylist
    getPlaylists: !-> return playlists
    getStaff: !-> return users?.filter (u) !-> return u.get(\role) # > 1 or u.get(\gRole)
    getWaitList: !-> return app?.room.waitlist


/*####################################
#           DOWNLOAD LINK            #
####################################*/
module \downloadLink, do
    setup: ({css}) !->
        icon = getIcon \icon-arrow-down
        css \downloadLink, "
            .p0ne-downloadlink::before {
                content: ' ';
                position: absolute;
                margin-top: -6px;
                margin-left: -27px;
                width: 30px;
                height: 30px;
                background-position: #{icon.position};
                background-image: #{icon.image};
            }
        "
    module: (name, filename, dataOrURL) !->
        if not dataOrURL
            dataOrURL = filename; filename = name
        if dataOrURL and not isURL(dataOrURL)
            dataOrURL = JSON.stringify dataOrURL if typeof dataOrURL != \string
            dataOrURL = URL.createObjectURL new Blob( [dataOrURL], type: \text/plain )
        filename .= replace /[\/\\\?%\*\:\|\"\<\>\.]/g, '' # https://en.wikipedia.org/wiki/Filename#Reserved_characters_and_words
        return appendChat "
                <div class='message p0ne-downloadlink'>
                    <i class='icon'></i>
                    <span class='text'>
                        <a href='#{dataOrURL}' download='#{filename}'>#{name}</a>
                    </span>
                </div>
            "


/*####################################
#            AUXILIARIES             #
####################################*/
window <<<<
    roomState: !-> ajax \GET, \rooms/state
    export_: (name) !-> return (data) !-> console.log "[export] #name =",data; window[name] = data
    searchEvents: (regx) !->
        regx = new RegExp(regx, \i) if regx not instanceof RegExp
        return [k for k of _$context?._events when regx.test k]


    listUsers: !->
        res = ""
        for u in API.getUsers!
            res += "#{u.id}\t#{u.username}\n"
        console.log res
    listUsersByAge: !->
        a = API.getUsers! .sort (a,b) !->
            a = +a.joined.replace(/\D/g,'')
            b = +b.joined.replace(/\D/g,'')
            return (a > b && 1) || (a == b && 0) || -1

        res = ""
        for u in a
            res += "#{u.joined.replace(/T|\..+/g, ' ')}\t#{u.username}\n"
        console.log res


    findModule: (test) !->
        if typeof test == \string and window.l
            test = l(test)
        res = []
        for id, module of require.s.contexts._.defined when module
            if test module, id
                module.requireID ||= id
                console.log "[findModule]", id, module
                res[*] = module
        return res

    requireHelperHelper: (module) !->
        /* this function will try to find a nice requireHelper rule for the given plug.dj module
         * the output is a function shorthand in LiveScript */
        if typeof module == \string
            module = require(module)
        return false if not module

        for k,v of module
            keys = 0
            keysExact = 0
            isNotObj = typeof v not in <[ object function ]>
            for id, m2 of require.s.contexts._.defined when m2 and m2[k] and k not in <[ requireID cid id length ]>
                keys++
                keysExact++ if isNotObj and m2[k] == v

            if keys == 1
                return "(.#k)"
            else if keysExact == 1
                return "(.#k == #{JSON.stringify v})"

        for k,v of module::
            keys = 0
            keysExact = 0
            isNotObj = typeof v != \object
            for id, m2 of require.s.contexts._.defined when m2 and m2::?[k]
                keys++
                keysExact++ if isNotObj and m2[k] == v

            if keys == 1
                return "(.::?.#k)"
            else if keysExact == 1
                return "(.::?.#k == #{JSON.stringify v})"
        return false

    validateUsername: (username, ignoreWarnings, cb) !->
        if typeof ignoreWarnings == \function
            cb = ignoreWarnings; ignoreWarnings = false
        else if not cb
            cb = (slug, err) !-> console[err && \error || \log] "username '#username': ", err || slug

        if not ignoreWarnings
            if username.length < 2
                cb(false, "too short")
            else if username.length >= 25
                cb(false, "too long")
            else if username.has("/")
                cb(false, "forward slashes are not allowed")
            else if username.has("\n")
                cb(false, "line breaks are not allowed")
            else
                ignoreWarnings = true
        if ignoreWarnings
            return $.getJSON "https://plug.dj/_/users/validate/#{encodeURIComponent username}", (d) !->
                cb(d && d.data.0?.slug)

    getRequireArg: (haystack, needle) !->
        /* this is a helper function to be used in the console to quickly find a module ID corresponding to a parameter and vice versa in the head of a javascript requirejs.define call
         * e.g. getRequireArg('define( "da676/a5d9e/a7e5a/a3e8f/fa06c", [ "jquery", "underscore", "backbone", "da676/df0c1/fe7d6", "da676/ae6e4/a99ef", "da676/d8c3f/ed854", "da676/cba08/ba3a9", "da676/cba08/ee33b", "da676/cba08/f7bde", "da676/cba08/d0509", "da676/eb13a/b058e/c6c93", "da676/eb13a/b058e/c5cd2", "da676/eb13a/f86ef/bff93", "da676/b0e2b/f053f", "da676/b0e2b/e9c55", "da676/a5d9e/d6ba6/f3211", "hbs!templates/room/header/RoomInfo", "lang/Lang" ], function( e, t, n, r, i, s, o, u, a, f, l, c, h, p, d, v, m, g ) {', 'u') ==> "da676/cba08/ee33b"
        */
        [a, b] = haystack.split "], function("
        a .= substr(a.indexOf('"')).split('", "')
        b .= substr(0, b.indexOf(')')).split(', ')
        if b[a.indexOf(needle)]
            try window[that] = require needle
            return that
        else if a[b.indexOf(needle)]
            try window[needle] = require that
            return that



    logOnce: (base, event) !->
        if not event
            event = base
            if -1 != event.indexOf \:
                base = _$context
            else
                base = API
        base.once \event, logger(event)

    usernameToSlug: (un) !->
        /* note: this is NOT really accurate! */
        lastCharWasLetter = false
        res = ""
        for c in htmlEscape(un)
            if (lc = c.toLowerCase!) != c.toUpperCase!
                if /\w/ .test lc
                    res += c.toLowerCase!
                else
                    res += "\\u#{pad(lc.charCodeAt(0), 4)}"
                lastCharWasLetter = true
            else if lastCharWasLetter
                res += "-"
                lastCharWasLetter = false
        if not lastCharWasLetter
            res .= substr(0, res.length - 1)
        return res
        #htmlEscape(un).replace /[&;\s]+/g, '-'
        # some more characters get collapsed
        # some characters get converted to \u####

    reconnectSocket: !->
        _$context .trigger \force:reconnect
    ghost: !->
        return $.get '/'


    getAvatars: !->
        API.once \p0ne:avatarsloaded, logger \AVATARS
        $.get $("script[src^='https://cdn.plug.dj/_/static/js/avatars.']").attr(\src) .then (d) !->
            if d.match /manifest.*/
                API.trigger \p0ne:avatarsloaded, JSON.parse that[0].substr(11, that[0].length-12)

    parseYTGetVideoInfo: (d, onlyStripHTML) !->
        #== Parser ==
        # useful for debugging mediaDownload()
        if typeof d == \object
            for k,v of d
                d[k] = parseYTGetVideoInfo(v)
            return d
        else if typeof d != \string or d.startsWith "http"
            return d
        else if d.startsWith "<!DOCTYPE html>"
            d = JSON.parse(d.match(/ytplayer\.config = (\{[\s\S]*?\});/)?.1 ||null)
            if onlyStripHTML
                return d
            else
                return parseYTGetVideoInfo d
        else if d.has(",")
            return d.split(",").map(parseYTGetVideoInfo)
        else if d.has "&"
            res = {}
            for a in d.split "&"
                a .= split "="
                if res[a.0]
                    res[a.0] = [res[a.0]] if not $.isArray res[a.0]
                    res[a.0][*] = parseYTGetVideoInfo unescape(a.1)
                else
                    res[a.0] = parseYTGetVideoInfo unescape(a.1)
            return res
        else if not isNaN(d)
            return +d
        else if d in <[ True False ]>
            return d == \True
        else
            return d

if not window.chrome
    # little fix for non-WebKit browsers to allow copying data to the clipboard
    # on WebKit browsers like Google Chrome, you can use `copy("string")` in the console
    $.getScript "https://cdn.p0ne.com/script/zclip/jquery.zclip.min.js"
        .then !->
            window.copy = (str, title) !->
                appendChat $ "<button class='cm p0ne-notif'> copy #{title ||''}</button>"
                    .zclip do
                        path: "https://cdn.p0ne.com/script/zclip/ZeroClipboard.swf"
                        copy: str
                    #$ '<div class="cm p0ne-notif">'
                    #.append do
            console.info "[copy polyfill] loaded polyfill for copy() with zclip"
        .fail !->
            console.warn "[copy polyfill] failed to load zclip!"


/*####################################
#            RENAME USER             #
####################################*/
module \renameUser, do
    require: <[ users ]>
    module: (idOrName, newName) !->
        u = users.get(idOrName)
        if not u
            idOrName .= toLowerCase!
            for user in users.models when user.attributes.username.toLowerCase! == idOrName
                u = user; break
        if not u
            return console.error "[rename user] can't find user with ID or name '#idOrName'"
        u.set \username, newName
        id = u.id

        if not rup = window.p0ne.renameUserPlugin
            rup = window.p0ne.renameUserPlugin = (d) !->
                d.un = rup[d.fid] || d.un
            window.p0ne.chatPlugins?[*] = rup
        rup[id] = newName


do !->
    # for easily checking _$context events using your console's autocomplete
    # of course, with the recent WebKit update this isn't really necessary for WebKit users
    # https://i.imgur.com/GOeF0Ma.png
    window._$events =
        _update: !->
            for k,v of _$context?._events
                @[k.replace(/:/g,'_')] = v
    _$events._update!


/*####################################
#            EXPORT DATA             #
####################################*/
module \export_, do
    require: <[ downloadLink ]>
    exportPlaylists: !->
        # $ '.p0ne-downloadlink' .remove!
        for let pl in playlists
            $.get "/_/playlists/#{pl.id}/media" .then (data) !->
                downloadLink "playlist '#{pl.name}'",  "#{pl.name}.txt", data



/*####################################
#              COPY CHAT             #
####################################*/
window.copyChat = (copy) !->
    $ '#chat-messages img' .fixSize!
    host = p0ne.host
    res = """
        <!DOCTYPE HTML>
        <head>
        <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
        <title>plug.dj Chatlog #{getTime!} - #{getRoomSlug!} (#{API.getUser!.rawun})</title>
        <!-- basic chat styling -->
        #{ $ "head link[href^='https://cdn.plug.dj/_/static/css/app']" .0 .outerHTML }
        <link href='https://dl.dropboxusercontent.com/u/4217628/css/fimplugChatlog.css' rel='stylesheet' type='text/css'>
    """

    res += getCustomCSS true
    /*
    res += """\n
        <!-- p0ne song notifications -->
        <link rel='stylesheet' href='#host/css/p0ne.notif.css' type='text/css'>
    """ if window.songNotifications

    res += """\n
        <!-- better ponymotes -->
        <link rel='stylesheet' href='#host/css/bpmotes.css' type='text/css'>
        <link rel='stylesheet' href='#host/css/emote-classes.css' type='text/css'>
        <link rel='stylesheet' href='#host/css/combiners-nsfw.css' type='text/css'>
        <link rel='stylesheet' href='#host/css/gif-animotes.css' type='text/css'>
        <link rel='stylesheet' href='#host/css/extracss-pure.css' type='text/css'>
    """ if window.bpm or $cm! .find \.bpm-emote .length

    res += """\n
        <style>
        #{css \yellowMod}
        </style>
    """ if window.yellowMod
    */

    res += """\n
        </head>
        <body id="chatlog">
        #{$ \.app-right .html!
            .replace(/https:\/\/api\.plugCubed\.net\/proxy\//g, '')
            .replace(/src="\/\//g, 'src="https://')
        }
        </body>
    """
    copy res

/*
module \_$contextUpdateEvent, do
    require: <[ _$context ]>
    setup: ({replace}) !->
        for fn in <[ on off onEarly ]>
            replace _$context, fn,  (fn_) !-> return (type, cb, context) !->
                fn_ ...
                _$context .trigger \context:update, type, cb, context
                return this
*/

/*@source p0ne.ponify.ls */
/**
 * ponify chat - a script to ponify some words in the chat on plug.dj
 * Text ponification based on http://pterocorn.blogspot.dk/2011/10/ponify.html
 *
 * @author jtbrinkmann aka. Brinkie Pie
 * @license MIT License
 * @copyright (c) 2015 J.-T. Brinkmann
 */

/*####################################
#            PONIFY CHAT             #
####################################*/
module \ponify, do
    optional: <[ emoticons ]>
    displayName: 'Ponify Chat'
    settings: \pony
    help: '''
        Ponify the chat! (replace words like "anyone" with "anypony")
        Replaced words will be underlined. Move your cursor over the word to see it's original.

        It also replaces some of the emoticons with pony emoticons.
    '''
    disabled: true

    /*== TEXT ==*/
    map:
        # "america":    "amareica" # this one was driving me CRAZY
        "anybody":      "anypony"
        "anyone":       "anypony"
        "ass":          "flank"
        "asses":        "flanks"
        "boner":        "wingboner"
        "boy":          "colt"
        "boyfriend":    "coltfriend"
        "boyfriends":   "coltfriends"
        "boys":         "colts"
        "bro fist":     "brohoof"
        "bro-fist":     "brohoof"
        "butt":         "flank"
        "butthurt":     "saddle-sore"
        "butts":        "flanks"
        "child":        "foal"
        "children":     "foals"
        "cowboy":       "cowpony"
        "cowboys":      "cowponies"
        "cowgirl":      "cowpony"
        "cowgirls":     "cowponies"
        "disappoint":   "disappony"
        "disappointed": "disappony"
        "disappointment": "disapponyment"
        "doctor who":   "doctor whooves"
        "dr who":       "dr whooves"
        "dr. who":      "dr. whooves"
        "everybody":    "everypony"
        "everyone":     "everypony"
        "fap":          "clop"
        "faps":         "clops"
        "foot":         "hoof"
        "feet":         "hooves"
        "folks":        "foalks"
        "fool":         "foal"
        "foolish":      "foalish"
        "germany":      "germaneigh"
        "gentleman":    "gentlecolt"
        "gentlemen":    "gentlecolts"
        "girl":         "filly"
        "girls":        "fillies"
        "girlfriend":   "fillyfriend"
        "girlfriends":  "fillyfriends"
        "halloween":    "nightmare night"
        "hand":         "hoof"
        "hands":        "hooves"
        "handed":       "hoofed"
        "handedly":     "hoofedly"
        "handers":      "hoofers"
        "handmade":     "hoofmade"
        "hey":          "hay"
        "high-five":    "hoof-five"
        "highfive":     "hoof-five"
        #"human":        "pony"
        #"humans":       "ponies"
        "ladies":       "fillies"
        # "lobby":      "shed"
        "main":         "mane"
        "man":          "stallion"
        "men":          "stallions"
        "manhattan":    "manehattan"
        "marathon":     "mareathon"
        "miracle":      "mareacle"
        "miracles":     "mareacles"
        "money":        "bits"
        "naysayer":     "neighsayer"
        "no one else":  "nopony else"
        "no-one else":  "nopony else"
        "noone else":   "nopony else"
        "nobody":       "nopony"
        "nottingham":   "trottingham"
        "null":         "nullpony"
        "old-timer":    "old-trotter"
        "people":       "ponies"
        "person":       "pony"
        "persons":      "ponies"
        "philadelphia": "fillydelphia"
        "somebody":     "somepony"
        "someone":      "somepony"
        "stalingrad":   "stalliongrad"
        "sure as hell": "sure as hay"
        "tattoo":       "cutie mark"
        "tattoos":      "cutie mark"
        "da heck":      "da hay"
        "the heck":     "the hay"
        "the hell":     "the hay"
        "troll":        "parasprite"
        "trolls":       "parasprites"
        "trolled":      "parasprited"
        "trolling":     "paraspriting"
        "trollable":    "paraspritable"
        "woman":        "mare"
        "women":        "mares"
        "confound those dover boys":    "confound these ponies"


    ponifyMsg: (msg) !->
        msg.message .= replaceSansHTML @regexp, (_, pronoun, s, possessive, i) !~>
            w = @map[s.toLowerCase!]
            r = ""

            /*preserve upper/lower case*/
            lastUpperCaseLetters = 0
            l = s.length <? w.length
            for o from 0 til l
                if s[o].toLowerCase! != s[o]
                    r += w[o].toUpperCase!
                    lastUpperCaseLetters++
                else
                    r += w[o]
                    lastUpperCaseLetters = 0
            if w.length >= s.length and lastUpperCaseLetters >= 3
                r += w.substr(l) .toUpperCase!
            else
                r += w.substr(l)

            r = "<abbr class=ponified title='#s'>#r</abbr>"

            if pronoun
                if "aeioujyh".has(w.0)
                    r = "an #r"
                else
                    r = "a #r"

            if possessive
                if "szx".has(w[*-1])
                    r += "' "
                else
                    r += "'s "

            console.log "replaced '#s' with '#r'", msg.cid
            return r


    /*== EMOTICONS ==*/
    /* images from bronyland.com (reuploaded to imgur to not spam the console with warnings, because bronyland.com doesn't support HTTPS) */
    autoEmotiponies:
        '8)': name: \rainbowdetermined2, url: "https://i.imgur.com/WFa3vKA.png"
        ':(': name: \fluttershysad     , url: "https://i.imgur.com/6L0bpWd.png"
        ':)': name: \twilightsmile     , url: "https://i.imgur.com/LDoxwfg.png"
        ':?': name: \rainbowhuh        , url: "https://i.imgur.com/te0Mnih.png"
        ':B': name: \twistnerd         , url: "https://i.imgur.com/57VFd38.png"
        ':D': name: \pinkiehappy       , url: "https://i.imgur.com/uFwZib6.png"
        ':S': name: \unsuresweetie     , url: "https://i.imgur.com/EATu0iu.png"
        ':O': name: \pinkiegasp        , url: "https://i.imgur.com/b9G2kaz.png"
        ':X': name: \fluttershybad     , url: "https://i.imgur.com/mnJHnsv.png"
        ':|': name: \ajbemused         , url: "https://i.imgur.com/8SLymiw.png"
        ';)': name: \raritywink        , url: "https://i.imgur.com/9fo7ZW3.png"
        '<3': name: \heart             , url: "https://i.imgur.com/aPBXLob.png"
        'B)': name: \coolphoto         , url: "https://i.imgur.com/QDgMyIZ.png"
        'D:': name: \raritydespair     , url: "https://i.imgur.com/og1FoWN.png"
        #'???': name: \applejackconfused, url: "https://i.imgur.com/c4moR6o.png"

    emotiponies:
        aj:             "https://i.imgur.com/nnYMw87.png"
        applebloom:     "https://i.imgur.com/vAdPBJj.png"
        applejack:      "https://i.imgur.com/nnYMw87.png"
        blush:          "https://i.imgur.com/IpxwJ5c.png"
        cool:           "https://i.imgur.com/WFa3vKA.png"
        cry:            "https://i.imgur.com/fkYW4BG.png"
        derp:           "https://i.imgur.com/Y00vqcH.png"
        derpy:          "https://i.imgur.com/h6GdxHo.png"
        eek:            "https://i.imgur.com/mnJHnsv.png"
        evil:           "https://i.imgur.com/I8CNeRx.png"
        fluttershy:     "https://i.imgur.com/6L0bpWd.png"
        fs:             "https://i.imgur.com/6L0bpWd.png"
        idea:           "https://i.imgur.com/aitjp1R.png"
        lol:            "https://i.imgur.com/XVy41jX.png"
        loveme:         "https://i.imgur.com/H81S9x0.png"
        mad:            "https://i.imgur.com/taFXcWV.png"
        mrgreen:        "https://i.imgur.com/IkInelN.png"
        oops:           "https://i.imgur.com/IpxwJ5c.png"
        photofinish:    "https://i.imgur.com/QDgMyIZ.png"
        pinkie:         "https://i.imgur.com/tpQZaW4.png"
        pinkiepie:      "https://i.imgur.com/tpQZaW4.png"
        rage:           "https://i.imgur.com/H81S9x0.png"
        rainbowdash:    "https://i.imgur.com/xglySrD.png"
        rarity:         "https://i.imgur.com/9fo7ZW3.png"
        razz:           "https://i.imgur.com/f8SgNBw.png"
        rd:             "https://i.imgur.com/xglySrD.png"
        roll:           "https://i.imgur.com/JogpKQo.png"
        sad:            "https://i.imgur.com/6L0bpWd.png"
        scootaloo:      "https://i.imgur.com/9zVXkyg.png"
        shock:          "https://i.imgur.com/b9G2kaz.png"
        sweetie:        "https://i.imgur.com/EATu0iu.png"
        sweetiebelle:   "https://i.imgur.com/EATu0iu.png"
        trixie:         "https://i.imgur.com/2QEmT8y.png"
        trixie2:        "https://i.imgur.com/HWW2D6b.png"
        trixieleft:     "https://i.imgur.com/HWW2D6b.png"
        twi:            "https://i.imgur.com/LDoxwfg.png"
        twilight:       "https://i.imgur.com/LDoxwfg.png"
        twist:          "https://i.imgur.com/57VFd38.png"
        twisted:        "https://i.imgur.com/I8CNeRx.png"
        wink:           "https://i.imgur.com/9fo7ZW3.png"


    setup: ({addListener, replace, css}) !->
        @regexp = //
            \b(an?\s+)?(#{Object.keys @map .join '|' .replace(/\s+/g,'\\s*')})('s?)?\b
        //gi
        addListener API, \chat:plugin, @~ponifyMsg
        if emoticons?
            aEM = {}<<<<emoticons.autoEmoteMap
            for emote, {name, url} of @autoEmotiponies
                aEM[emote] = name
                @emotiponies[name] = url
            replace emoticons, \autoEmoteMap, !-> return aEM

            m = ^^emoticons.map
            ponyCSS = """
                .ponimoticon { width: 27px; height: 27px }
                .chat-suggestion-item .ponimoticon { margin-left: -5px }
                .emoji-glow { width: auto; height: auto }
                .emoji { position: static; display: inline-block }

            """
            reversedMap = {}
            for emote, url of @emotiponies
                if reversedMap[url]
                    m[emote] = "#{reversedMap[url]} ponimoticon" # hax to add .ponimoticon class
                else
                    reversedMap[url] = emote
                    m[emote] = "#emote ponimoticon" # hax to add .ponimoticon class
                ponyCSS += ".emoji-#emote { background: url(#url) }\n"
            css \ponify, ponyCSS
            replace emoticons, \map, !-> return m
            emoticons.update?!
    disable: !->
        emoticons.update?!


/*@source p0ne.fimplug.ls */
/**
 * fimplug related modules
 *
 * @author jtbrinkmann aka. Brinkie Pie
 * @license MIT License
 * @copyright (c) 2015 J.-T. Brinkmann
 */

/*####################################
#              RULESKIP              #
####################################*/
module \forceSkipButtonRuleskip, do
    displayName: "Ruleskip Button"
    settings: \pony
    description: """
        Makes the Skip button show a ruleskip list instead.
        (you can still instaskip)
    """
    screenshot: 'https://i.imgur.com/jGwYsn3.png'
    moderator: true
    setup: ({addListener, replace, $create, css}) !->
        #TODO add this http://pastebin.com/hgmHKzYC
        css \forceSkipButtonRuleskip, '
            .p0ne-skip-ruleskip {
                position: absolute;
                right: 0;
                bottom: 54px;
                width: 250px;
                list-style: none;
                line-height: 2em;
                display: none;
            }
            .p0ne-skip-ruleskip li {
                padding: 5px;
                background: #222;
            }
            .p0ne-skip-ruleskip li:hover {
                background: #444;
            }
        '
        var $rulelist
        visible = false
        fn = addListener API, \p0ne:moduleEnabled, (m) !-> if m.name == \forceSkipButton
            $rulelist := $create '
                <ul class=p0ne-skip-ruleskip>
                    <li data-rule=insta><b>insta skip</b></li>
                    <li data-rule=30><b>!ruleskip 30</b> (WD-only &gt; brony artist)</li>
                    <li data-rule=23><b>!ruleskip 23</b> (WD-only &gt; weird)</li>
                    <li data-rule=20><b>!ruleskip 20</b> (alts)</li>
                    <li data-rule=13><b>!ruleskip 13</b> (NSFW)</li>
                    <li  data-rule=5><b>!ruleskip  5</b> (too long)</li>
                    <li  data-rule=4><b>!ruleskip  4</b> (history)</li>
                    <li  data-rule=3><b>!ruleskip  3</b> (low effort mix)</li>
                    <li  data-rule=2><b>!ruleskip  2</b> (loop / slideshow)</li>
                    <li  data-rule=1><b>!ruleskip  1</b> (nonpony)</li>
                </ul>
            ' .appendTo m.$btn

            replace m, \onClick, !-> return (e) !->
                if visible
                    if num = $ e.target .closest \li .data \rule
                        if num == \insta
                            API.moderateForceSkip!
                        else
                            API.sendChat "!ruleskip #num"
                    m.$btn .find \.icon:first .addClass \icon-skip .removeClass \icon-arrow-down
                    $rulelist .fadeOut!
                    visible := false
                else if $ e.target .is '.p0ne-skip-btn, .p0ne-skip-btn>.icon'
                    m.$btn .find \.icon:first .removeClass \icon-skip .addClass \icon-arrow-down
                    $rulelist .fadeIn!
                    visible := true

            console.log "[forceSkipButton] 'fimplug !ruleskip list' patch applied"

        addListener \early, (window._$context || API), \advance, !-> if visible
            # trying to attach the lister as early as possible to prevent accidental double-skips
            visible := false
            $rulelist .fadeOut!
            $ \.p0ne-skip-btn>.icon:first .addClass \icon-skip .removeClass \icon-arrow-down

        if forceSkipButton?
            fn(forceSkipButton)


/*####################################
#              FIMSTATS              #
####################################*/
module \fimstats, do
    settings: \pony
    optional: <[ _$context app playlists ]>
    disabled: true
    _settings:
        highlightUnplayed: false
    CACHE_DURATION: 1.h
    setup: ({addListener, $create, replace}, fimstats) !->
        css \fimstats, '
            .p0ne-fimstats {
                position: absolute;
                left: 0;
                right: 345px;
                bottom: 54px;
                height: 1em;
                padding: 5px 0;
                font-size: .9em;
                color: #12A9E0;
                background: rgba(0,0,0, 0.4);
                text-align: center;
                z-index: 6;
                transition: opacity .2s ease-out;
            }
            .video-only .p0ne-fimstats {
                bottom: 116px;
                padding-top: 0px;
                background: rgba(0,0,0, 0.8);
            }

            .p0ne-fimstats-field {
                display: block;
                position: absolute;
                width: 100%;
                padding: 0 5px;
                box-sizing: border-box;
            }
            .p0ne-fimstats-last { text-align: left; }
            .p0ne-fimstats-plays, .p0ne-fimstats-once, .p0ne-fimstats-first-notyet { text-align: center; }
            .p0ne-fimstats-first { text-align: right; }

            .p0ne-fimstats-field::before, .p0ne-fimstats-field::after,
            .p0ne-fimstats-first-time, .p0ne-fimstats-last-time, .p0ne-fimstats-once-time {
                color: #ddd;
            }
            #dialog-container .p0ne-fimstats {
                position: fixed;
                bottom: 0;
                left: 0;
                right: 345px;
                background: rgba(0,0,0, 0.8);
            }
            #dialog-container .p0ne-fimstats-first-notyet::before { content: "not played yet!"; color: #12A9E0 }

            .p0ne-fimstats-first-notyet::before { content: "first played just now!"; color: #12A9E0 }
            .p0ne-fimstats-once::before { content: "once played by: "; }
            .p0ne-fimstats-last::before { content: "last played by: "; }
            .p0ne-fimstats-last-time::before,
            .p0ne-fimstats-first-time::before,
            .p0ne-fimstats-once-time::before { content: "("; }
            .p0ne-fimstats-last-time::after,
            .p0ne-fimstats-first-time::after,
            .p0ne-fimstats-once-time::after { content: ")"; }
            .p0ne-fimstats-plays::before { content: "played: "; }
            .p0ne-fimstats-plays::after { content: " times"; }
            .p0ne-fimstats-first::before { content: "first played by: "; }

            .p0ne-fimstats-first-time,
            .p0ne-fimstats-last-time,
            .p0ne-fimstats-once-time {
                font-size: 0.8em;
                display: inline;
                position: static;
                margin-left: 5px;
            }

            .p0ne-fimstats-unplayed {
                color: lime;
            }
        '
        $el = $create '<span class=p0ne-fimstats>' .appendTo \#room
        addListener API, \advance, @updateStats = (d=API.getMedia!) !~>
            if d?.lastPlay?.media
                delete @cache[id = "#{d.lastPlay.media.format}:#{d.lastPlay.media.cid}"]
            if d.media
                fimstats d.media
                    .then (res) !->
                        $el .html res.html
                    .fail (err) !->
                        $el .html err.html

            else
                $el.html ""
        if _$context?
            addListener _$context, \ShowDialogEvent:show, (d) !-> #\PreviewEvent:preview, (d) !->
                _.defer !-> if d.dialog.options?.media
                    console.log "[fimstats]", d.dialog.options.media
                    fimstats d.dialog.options.media
                        .then (d) !->
                            $ \#dialog-preview .after do
                                $create '<div class=p0ne-fimstats>' .html d.html
        if app?.dialog?.dialog?.options?.media
            console.log "[fimstats]", that
            fimstats that.toJSON!
                .then (d) !->
                    $ \#dialog-preview .after do
                        $create '<div class=p0ne-fimstats>' .html d.html

        # prevent the p0ne settings from overlaying the ETA
        console.info "[fimstats] prevent p0neSettings overlay", $(\#p0ne-menu).css bottom: 54px + 21px
        addListener API, 'p0ne:moduleEnabled p0ne:moduleUpdated', (m) !-> if m.name == \p0neSettings
            $ \#p0ne-menu .css bottom: 54px + 21px

        # show stats for next song in playlist
        if app? and playlists?
            $yourNextMedia = $ \#your-next-media

            @checkUnplayed = !->
                $yourNextMedia .removeClass \p0ne-fimstats-unplayed
                if fimstats._settings.highlightUnplayed and playlists.activeMedia.length > 0
                    console.log "[fimstats] checking next song", playlists.activeMedia.0
                    fimstats playlists.activeMedia.0 .then (d) !->
                        if d.unplayed
                            $yourNextMedia .addClass \p0ne-fimstats-unplayed

            replace app.footer.playlist, \updateMeta, (uM_) !-> return !->
                if playlists.activeMedia.length > 0
                    fimstats.checkUnplayed!
                    uM_ ...
                else
                    clearTimeout @updateMetaBind
            replace app.footer.playlist, \updateMetaBind, !-> return app.footer.playlist~updateMeta

            # apply immediately
            @checkUnplayed!
        else
            console.warn "[fimstats] failed to load requirements for checking next song. next song check disabled."

        # show stats for current song
        @updateStats!

    checkUnplayed: !-> # Dummy function in case we cannot get `playlists` (which is required)

    cache: {}
    module: (media=API.getMedia!) !->
        $ \#p0ne-menu .css bottom: 54px
        if media.attributes and media.toJSON
            media .= toJSON!

        # check if data is already cached
        if @cache[id = "#{media.format}:#{media.cid}"]
            clearTimeout @cache[id].timeoutID
            @cache[id].timeoutID = sleep @CACHE_DURATION, ~>
                delete @cache[id]
            return @cache[id]
        else
            # if not yet cached, create a Deferred
            def = $.Deferred!
            @cache[id] = def.promise!
            @cache[id].timeoutID = sleep @CACHE_DURATION, ~>
                delete @cache[id]

        # load data from fimstats
        $.getJSON "https://fimstats.anjanms.com/_/media/#{media.format}/#{media.cid}" #?key=#{p0ne.FIMSTATS_KEY}
            .then (d) !->
                d = d.data.0
                # note: `d.plays` (playcount) doesn't contain current play
                # we need to sanitize everything to avoid HTML injection (some songtitles are actually not HTMl escaped)
                for k,v of d
                    if typeof v == \string
                        d[k] = sanitize v
                    else
                        for k2,v2 of v when typeof v2 == \string
                            v[k2] = sanitize v2

                if d.firstPlay.time != d.lastPlay.time
                    d.text = "last played by #{d.lastPlay.user.username} \xa0 - (#{d.plays}x) - \xa0 first played by #{d.firstPlay.user.username}"
                    d.html = "
                        <span class='p0ne-fimstats-field p0ne-fimstats-last p0ne-name' data-uid=#{d.lastPlay.id}>#{d.lastPlay.user.username}
                            <span class=p0ne-fimstats-last-time>#{ago d.lastPlay.time*1000s_to_ms}</span>
                        </span>
                        <span class='p0ne-fimstats-field p0ne-fimstats-plays'>#{d.plays}</span>
                        <span class='p0ne-fimstats-field p0ne-fimstats-first p0ne-name' data-uid=#{d.firstPlay.id}>#{d.firstPlay.user.username}
                            <span class=p0ne-fimstats-first-time>#{ago d.firstPlay.time*1000s_to_ms}</span>
                        </span>
                    "
                else
                    d.text = "once played by #{d.firstPlay.user.username}"
                    d.html = "
                        <span class='p0ne-fimstats-field p0ne-fimstats-once'>#{d.firstPlay.user.username}
                            <span class=p0ne-fimstats-once-time>#{ago d.firstPlay.time*1000s_to_ms}</span>
                        </span>"
                def.resolve d
            .fail (d,,status) !->
                if status == "Not Found"
                    d.text = "first played just now!"
                    d.html = "<span class='p0ne-fimstats-field p0ne-fimstats-first-notyet'></span>"
                    d.unplayed = true
                    def.resolve d
                else
                    d.text = d.html = "error loading fimstats"
                    def.reject d
        return @cache[id]

        function sanitize str
            return str .replace(/</g, '&lt;') .replace(/>/g, '&gt;')

    settingsExtra: ($el) !->
        fimstats = this
        noReqMissing = app? or not playlists?
        $ "
            <form>
                <label>
                    <input type=checkbox class=p0ne-fimstats-unplayed-setting #{if @_settings.highlightUnplayed and noReqMissing then \checked else ''} #{if noReqMissing then '' else \disabled}> highlight next song if unplayed
                </label>
            </form>"
            .appendTo do
                $el .css paddingLeft: 15px
        if noReqMissing
            $el .on \click, \.p0ne-fimstats-unplayed-setting, !->
                console.log "#{getTime!} [fimstats] updated highlightUnplayed to #{@checked}"
                fimstats._settings.highlightUnplayed = @checked
                if @checked
                    fimstats.checkUnplayed!
                else
                    $ \#your-next-media .removeClass \p0ne-fimstats-unplayed

    disable: !->
        $ \#your-next-media .removeClass \p0ne-fimstats-unplayed


module \ponifiedLang, do
    require: <[ Lang ]>
    disabled: true
    displayName: "Ponified Text"
    setup: ({replace}) !->
        # roles
        replace Lang.roles, \host, !-> return "Alicorn Princess"
        replace Lang.roles, \cohost, !-> return "Alicorn"
        replace Lang.roles, \dj, !-> return "Horse Famous"
        replace Lang.permissions, \cohosts, !-> return "Add/Remove Alicorns"
        replace Lang.permissions, \dj, !-> return "Set Horse Famous Ponies"
        replace Lang.roles, \none, !-> return "Mudpony"
        replace Lang.moderation, \ban, !-> return "sent %NAME% to the moon for a thousand years."

        # ponies
        replace Lang.messages, \minChatLevel, !-> return "This community restricts chat to ponies who are level %LEVEL% and above."
        replace Lang.permissions, \ban, !-> return "Ban Ponies."
        replace Lang.permissions, \unban, !-> return "Unban Ponies."
        replace Lang.tooltips, \headersUsers, !-> return "Ponies"
        replace Lang.tooltips, \usersRoom, !-> return "Ponies who are here right now"
        replace Lang.tooltips, \usersBans, !-> return "Ponies who have been banned"
        replace Lang.tooltips, \usersIgnored, !-> return "Ponies who you have ignored"
        replace Lang.tooltips, \usersMutes, !-> return "Ponies who have been muted"
        replace Lang.tooltips, \chatLevel, !-> return "Restrict chat to ponies who are this level or above"
        replace Lang.userList, \roomTitle, !-> return "Ponies here now"

        # Bot Commands
        replace Lang.chat, \help, !-> return "<strong>Chat Commands:</strong><br/>/em &nbsp; <em>Emote</em><br/>/me &nbsp; <em>Emote</em><br/>/clear &nbsp; <em>Clear Chat History</em><hr>
            <strong>Bot Commands:</strong><br>
            !randgame &nbsp; <em>Pony Adventure</em><br/>
            !power &nbsp; <em>Random Power</em><br/>
            !hug (@user) &nbsp; <em>hug somepony</em><br/>
            !1v1 (@user) &nbsp; <em>1v1 somepony</em><br/>
            !rule <number> &nbsp; <em>List a Rule</em><br/>
            !songinfo &nbsp; <em>Songstats</em><br/>
            !dc &nbsp; <em>be put back if you dc'd</em><br/>
            !eta &nbsp; <em>ETA til you dj</em><br/>
            !weird &nbsp; <em>Is it weirdday?</em><br/>
            "

        # misc
        replace Lang.search, \youtube, !-> return "Search YouTube for ponies"
        replace Lang.search, \soundcloud, !-> return "Search SoundCloud for ponies"

/*@source p0ne.bpm.ls */
/**
 * BetterPonymotes - a script add ponymotes to the chat on plug.dj
 * based on BetterPonymotes https://ponymotes.net/bpm/
 * for a ponymote tutorial see:
 * http://www.reddit.com/r/mylittlepony/comments/177z8f/how_to_use_default_emotes_like_a_pro_works_for/
 *
 * @author jtbrinkmann aka. Brinkie Pie
 * @license MIT License
 * @copyright (c) 2015 J.-T. Brinkmann
 */


/*####################################
#          BETTER PONYMOTES          #
####################################*/
module \bpm, do
    require: <[ chatPlugin ]>
    displayName: 'Better Ponymotes'
    settings: \pony
    _settings:
        showNSFW: false
    module: (str) ->
        if not str
            console.error "bpm(null)"
        return @bpm str

    setup: ({addListener, $create}, {_settings}) ->
        host = window.p0ne?.host or "https://cdn.p0ne.com"

        /*== external sources ==*/
        if not window.emote_map
            window.emote_map = {}
            $.getScript "#host/scripts/bpm-resources.js" .then ->
                API .trigger \p0ne_emotes_map
        else
            <- requestAnimationFrame
            API .trigger \p0ne_emotes_map

        $create "
            <div id='bpm-resources'>
                <link rel='stylesheet' href='#host/css/bpmotes.css' type='text/css'>
                <link rel='stylesheet' href='#host/css/emote-classes.css' type='text/css'>
                <link rel='stylesheet' href='#host/css/combiners-nsfw.css' type='text/css'>
                <link rel='stylesheet' href='#host/css/gif-animotes.css' type='text/css'>
                #{if \webkitAnimation of document.body.style
                    "<link rel='stylesheet' href='#host/css/extracss-webkit.css' type='text/css'>"
                else
                    "<link rel='stylesheet' href='#host/css/extracss-pure.css' type='text/css'>"
                }
            </div>
        "
            .appendTo $body
        /*
                <style>
                \#chat-suggestion-items .bpm-emote {
                    max-width: 27px;
                    max-height: 27px
                }
                </style>
        */

        /*== constants ==*/
        _FLAG_NSFW = 1
        _FLAG_REDIRECT = 2

        /*
         * As a note, this regexp is a little forgiving in some respects and strict in
         * others. It will not permit text in the [] portion, but alt-text quotes don't
         * have to match each other.
         */
        /*                 [](/  <   emote   >   <     alt-text    >  )*/
        EMOTE_REGEXP = /\[\]\(\/([\w:!#\/\-]+)\s*(?:["']([^"]*)["'])?\)/g


        /*== auxiliaries ==*/
        /*
         * Escapes an emote name (or similar) to match the CSS classes.
         *
         * Must be kept in sync with other copies, and the Python code.
         */
        sanitize_map =
            \! : \_excl_
            \: : \_colon_
            \# : \_hash_
            \/ : \_slash_
        function sanitize_emote s
            return s.toLowerCase!.replace /[!:#\/]/g, (c) -> return sanitize_map[c]

        function lookup_core_emote name, altText
            # Refer to bpgen.py:encode() for the details of this encoding
            data = emote_map["/"+name]
            return null if not data

            nameWithSlash = name
            parts = data.split ','
            flag_data = parts.0
            tag_data = parts.1

            flags = parseInt(flag_data.slice(0, 1), 16)     # Hexadecimal
            source_id = parseInt(flag_data.slice(1, 3), 16) # Hexadecimal
            #size = parseInt(flag_data.slice(3, 7), 16)     # Hexadecimal
            is_nsfw = (flags .&. _FLAG_NSFW)
            is_redirect = (flags .&. _FLAG_REDIRECT)

            /*tags = []
            start = 0
            while (str = tag_data.slice(start, start+2)) != ""
                tags.push(parseInt(str, 16)) # Hexadecimal
                start += 2

            if is_redirect
                base = parts.2
            else
                base = name*/

            return
                name: nameWithSlash,
                is_nsfw: !!is_nsfw
                source_id: source_id
                source_name: sr_id2name[source_id]
                #max_size: size

                #tags: tags

                css_class: "bpmote-#{sanitize_emote name}"
                #base: base

                altText: altText

        function convert_emote_element info, parts, _
            title = "#{info.name} from #{info.source_name}".replace /"/g, ''
            flags = ""
            for flag,i in parts when i>0
                /* Normalize case, and forbid things that don't look exactly as we expect */
                flag = sanitize_emote flag.toLowerCase!
                flags += " bpflag-#flag" if not /\W/.test flag

            if info.is_nsfw
                if _settings.showNSFW
                    title = "[NSFW] #title"
                    flags += " bpm-nsfw"
                else
                    console.warn "[bpm] nsfw emote (disabled)", name
                    return "<span class='bpm-nsfw' title='NSFW emote'>#_</span>"

            return "<span class='bpflag-in bpm-emote #{info.css_class} #flags' title='#title'>#{info.altText || ''}</span>"
            # data-bpm_emotename='#{info.name}'
            # data-bpm_srname='#{info.source_name}'


            /*
            # in case it is required to avoid replacing in HTML tags
            # usually though, there shouldn't be ponymotes in links / inline images / converted ponymotes
            if str .has("[](/")
                # avoid replacing emotes in HTML tags
                return "#str" .replace /(.*?)(?:<.*?>)?/, (,nonHTML, html) ~>
                    nonHTML .= replace EMOTE_REGEXP, (_, parts, altText) ->
                        parts .= split '-'
                        name = parts.0
                        info = lookup_core_emote name, altText
                        if not info
                            return _
                        else
                            return convert_emote_element info, parts
                    return "#nonHTML#html"
            else
                return str
            */

        #== main BPM plugin ==
        @bpm = (str) ->
            console.error "bpm(null) [2]" if not str
            str .replace EMOTE_REGEXP, (all, parts, altText) ->
                parts .= split '-'
                name = parts.0
                info = lookup_core_emote name, altText
                if not info
                    return all
                else
                    return convert_emote_element info, parts, all

        #== integration ==
        addListener (window._$context || API), \chat:plugin, (msg) ->
            msg.message = bpm(msg.message)

        addListener \once, API, \p0ne_emotes_map, ->
            console.info "[bpm] loaded"

            #== ponify old messages ==
            $cms! .find '.text' .html ->
                return bpm @innerHTML

            #== Autocomplete integration ==
            /* add autocomplete if/when plug_p0ne and plug_p0ne.autocomplete are loaded */
            cb = ->
                AUTOCOMPLETE_REGEX = /^\[\]\(\/([\w#\\!\:\/]+)(\s*["'][^"']*["'])?(\))?/
                addAutocompletion? do
                    name: "Ponymotes"
                    data: Object.keys(emote_map)
                    pre: "[]"
                    check: (str, pos) ->
                        if !str[pos+2] or str[pos+2] == "(" and (!str[pos+3] or str[pos+3] == "(/")
                            temp = AUTOCOMPLETE_REGEX.exec(str.substr(pos))
                            if temp
                                @data = temp.2 || ''
                                return true
                        return false
                    display: (items) ->
                        return [{value: "[](/#emote)", image: bpm("[](/#emote)")} for emote in items]
                    insert: (suggestion) ->
                        return "#{suggestion.substr(0, suggestion.length - 1)}#{@data})"
            if window.addAutocompletion
                cb!
            else
                addListener \once, API, \p0ne:autocomplete, cb


    disable: (revertPonimotes) ->
        if revertPonimotes
            $cms! .find \.bpm-emote .replaceWith ->
                flags = ""
                for class_ in this.classList || this.className.split(/s+/)
                    if class_.startsWith \bpmote-
                        emote = class_.substr(7)
                    else if class_.startsWith(\bpflag-) and class_ != \bpflag-in
                        flags += class_.substr(6)
                if emote
                    return document.createTextNode "[](/#emote#flags)"
                else
                    console.warn "[bpm] cannot convert back", this

/*@source p0ne.end.ls */
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


