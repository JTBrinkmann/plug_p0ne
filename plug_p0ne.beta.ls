/*=====================*\
|*      plug_p0ne      *|
\*=====================*/

/*@source p0ne.head.ls */
/**
 * plug_p0ne - a modern script collection to improve plug.dj
 * adds a variety of new functions, bugfixes, tweaks and developer tools/functions
 *
 * This script collection is written in LiveScript (a CoffeeScript descendend which compiles to JavaScript). If you are reading this in JavaScript, you might want to check out the LiveScript file instead for a better documented and formatted source; just replace the .js with .ls in the URL of this file
 * @author jtbrinkmann aka. Brinkie Pie
 * @version 1.2.3
 * @license MIT License
 * @copyright (c) 2014 J.-T. Brinkmann
*/

console.info "~~~~~~~~~~~~ plug_p0ne loading ~~~~~~~~~~~~"
window.p0ne =
    version: \1.5.2
    lastCompatibleVersion: \1.5.0 /* see below */
    host: 'https://cdn.p0ne.com'
    SOUNDCLOUD_KEY: \aff458e0e87cfbc1a2cde2f8aeb98759
    YOUTUBE_KEY: \AI39si6XYixXiaG51p_o0WahXtdRYFCpMJbgHVRKMKCph2FiJz9UCVaLdzfltg1DXtmEREQVFpkTHx_0O_dSpHR5w0PTVea4Lw
    proxy: (url) -> return "https://jsonp.nodejitsu.com/?raw=true&url=#{escape url}" # for cross site requests
    #proxy: (url) -> return "https://query.yahooapis.com/v1/public/yql?format=json&q=select%20*%20from%20json%20where%20url%3D"#{escape url}"
    started: new Date()
    lsBound: {}
    lsBound_num: {}
    modules: p0ne?.modules || {}
    dependencies: {}
    close: ->
        for m in @modules
            m.disable?!
console.info "plug_p0ne v#{p0ne.version}"

try
    /* save data of previous p0ne instances */
    saveData?!

/*####################################
#           COMPATIBILITY            #
####################################*/
/* check if last run p0ne version is incompatible with current and needs to be migrated */
window.compareVersions = (a, b) -> /* returns whether `a` is greater-or-equal to `b`; e.g. "1.2.0" is greater than "1.1.4.9" */
    a .= split \.
    b .= split \.
    for ,i in a when a[i] != b[i]
        return a[i] > b[i]
    return b.length > a.length


<-      (fn_) ->
    if console and typeof (console.group || console.groupCollapsed) == \function
        fn = ->
            if console.groupCollapsed
                console.groupCollapsed "[p0ne] initializing… (click on this message to expand/collapse the group)"
            else
                console.group "[p0ne] initializing…"

            errors = warnings = 0
            error_ = console.error; console.error = -> errors++; error_ ...
            warn_ = console.warn; console.warn = -> warnings++; warn_ ...

            fn_!

            console.groupEnd!
            console.info "[p0ne] initialized!"
            console.error = error_; console.warn = warn_
            console.error "[p0ne] There have been #errors errors" if errors
            console.warn "[p0ne] There have been #warnings warnings" if warnings
    else
        fn = fn_
    if not (v = localStorage.p0neVersion)
        # no previous version of p0ne found, looks like we're good to go
        return fn!

    if compareVersions(v, p0ne.lastCompatibleVersion)
        # no migration required, continue
        fn!
    else
        # incompatible, load migration script and continue when it's done
        console.warn "[p0ne] obsolete p0ne version detected (#v), loading migration script…"
        API.off \p0ne_migrated
        API.once \p0ne_migrated, onMigrated = (newVersion) ->
            if newVersion == p0ne.lastCompatibleVersion
                fn!
            else
                API.once \p0ne_migrated, onMigrated # did you mean "recursion"?
        $.getScript "#{p0ne.host}/script/plug_p0ne.migrate.#{v.substr(0,v.indexOf(\.))}.js?from=#v&to=#{p0ne.version}"

p0ne = window.p0ne # so that modules always refer to their initial `p0ne` object, unless explicitly referring to `window.p0ne`
localStorage.p0neVersion = p0ne.version

``
/*@source lambda.js */
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


/*@source lz-string.js */
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
/*@source p0ne.auxiliaries.ls */
/**
 * Auxiliary-functions for plug_p0ne
 * @author jtbrinkmann aka. Brinkie Pie
 * @version 1.0
 * @license MIT License
 * @copyright (c) 2014 J.-T. Brinkmann
*/

export $window = $ window
export $body = $ document.body


/*####################################
#         PROTOTYPE FUNCTIONS        #
####################################*/
# helper for defining non-enumerable functions via Object.defineProperty
let (d = (property, value) -> if @[property] != value then Object.defineProperty this, property, {-enumerable, +writable, +configurable, value})
    d.call Object::, \define, d
Object::define \defineGetter, (property, get) -> if @[property] != get then Object.defineProperty this, property, {-enumerable, +configurable, get}

Array::define \remove, (i) -> return @splice i, 1
Array::define \removeItem, (el) ->
    if -1 != (i = @indexOf(el))
        @splice i, 1
    return this
Array::define \random, -> return this[~~(Math.random! * @length)]
Array::define \unique, ->
    res = []; l=0
    for el, i in this
        for o til i
            break if @[o] == el
        else
            res[l++] = el
    return res
String::define \reverse, ->
    res = ""
    i = @length
    while i--
        res += @[i]
    return res
String::define \startsWith, (str) ->
    i=0
    while char = str[i]
        return false if char != this[i++]
    return true
String::define \endsWith, (str) ->
    return this.lastIndexOf == @length - str.length
for Constr in [String, Array]
    Constr::define \has, (needle) -> return -1 != @indexOf needle
    Constr::define \hasAny, (needles) ->
        for needle in needles when -1 != @indexOf needle
            return true
        return false

Number::defineGetter \min, ->   return this * 60_000min_to_ms
Number::defineGetter \s, ->     return this * 1_000min_to_ms


jQuery.fn <<<<
    indexOf: (selector) ->
        /* selector may be a String jQuery Selector or an HTMLElement */
        if @length and selector not instanceof HTMLElement
            i = [].indexOf.call this, selector
            return i if i != -1
        for el, i in this when jQuery(el).is selector
            return i
        return -1

    concat: (arr2) ->
        l = @length
        return this if not arr2 or not arr2.length
        return arr2 if not l
        for el, i in arr2
            @[i+l] = el
        @length += arr2.length
        return this
    fixSize: -> #… only used in saveChat so far
        for el in this
            el.style .width = "#{el.width}px"
            el.style .height = "#{el.height}px"
        return this

/*####################################
#            DATA MANAGER            #
####################################*/
if window.dataSave
    window.dataSave!
    $window .off \beforeunload, window.dataSave.cb
    clearInterval window.dataSave.interval

if window.chrome
    window{compress, decompress} = LZString
else
    window{compressToUTF16:compress, decompressFromUTF16:decompress} = LZString
window.dataLoad = (name, defaultVal={}) ->
    return p0ne.lsBound[name] if p0ne.lsBound[name]
    if localStorage[name]
        if decompress(localStorage[name])
            return p0ne.lsBound[name] = JSON.parse(that)
        else
            name_ = Date.now!
            console.warn "failed to load '#name' from localStorage, it seems to be corrupted! made a backup to '#name_' and continued with default value"
            localStorage[name_] = localStorage[name]
    p0ne.lsBound_num[name] = (p0ne.lsBound_num[name] ||0) + 1
    return p0ne.lsBound[name] = defaultVal
window.dataUnload = (name) !->
    if p0ne.lsBound_num[name]
        p0ne.lsBound_num[name]--
    if p0ne.lsBound_num[name] == 0
        delete p0ne.lsBound[name]
window.dataSave = !->
    err = ""
    for k,v of p0ne.lsBound
        try
            localStorage[k] = compress(v.toJSON?! || JSON.stringify(v))
        catch
            err += "failed to store '#k' to localStorage\n"
    if err
        alert err
    else
        console.log "[Data Manager] saved data"
$window .on \beforeunload, dataSave.cb = dataSave
dataSave.interval = setInterval dataSave, 15.min


/*####################################
#         GENERAL AUXILIARIES        #
####################################*/
$dummy = $ \<a>
window <<<<
    YT_REGEX: /https?:\/\/(?:www\.)?(?:youtube(?:-nocookie)?\.com\/(?:[^\/]+\/.+\/|(?:v|embed|e)\/|.*(?:\?|&amp;)v=)|youtu\.be\/)([^"&?\/<>\s]{11})(?:&.*?|#.*?|)$/i
    repeat: (timeout, fn) -> return setInterval (-> fn ... if not disabled), timeout
    sleep: (timeout, fn) -> return setTimeout fn, timeout
    pad: (num, digits) ->
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

    generateID: -> return (~~(Math.random!*0xFFFFFF)) .toString(16).toUpperCase!



    getUser: (user) !->
        return if not user
        if typeof user == \object
            return that if user.id and getUser(user.id)
            if user.username
                return user
            else if user.attributes and user.toJSON
                return user.toJSON!
            else if user.username || user.dj || user.user
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
            users.get user
        else if typeof user == \string
            for u in users.models when u.get(\username) == user
                return u
            user .= toLowerCase!
            for u in users.models when u.get(\username) .toLowerCase! == user
                return u
        else
            console.warn "unknown user format", user

    logger: (loggerName, fn) ->
        if typeof fn == \function
            return ->
                console.log "[#loggerName]", arguments
                return fn ...
        else
            return -> console.log "[#loggerName]", arguments

    replace: (context, attribute, cb) ->
        context["#{attribute}_"] ||= context[attribute]
        context[attribute] = cb(context["#{attribute}_"])

    loadScript: (loadedEvent, data, file, callback) ->
        d = $.Deferred!
        d.then callback if callback

        if data
            d.resolve!
        else
            $.getScript "#{p0ne.host}/#file"
            $ window .one loadedEvent, d.resolve #Note: .resolve() is always bound to the Deferred
        return d.promise!

    requireIDs: dataLoad \p0ne_requireIDs, {}
    requireHelper: (name, test, {id, onfail, fallback}=0) ->
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
    requireAll: (test) ->
        return [m for id, m of require.s.contexts._.defined when m and test(m, id)]


    /* callback gets called with the arguments cb(errorCode, response, event) */
    floodAPI_counter: 0
    ajax: (type, url, data, cb) ->
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

        options = do
                type: type
                url: "https://plug.dj/_/#url"
                success: ({data}) ->
                    console.info "[#url]", data if not silent
                    success? data
                error: (err) ->
                    console.error "[#url]", data if not silent
                    error? data

        if data
            silent = data.silent
            delete data.type
            delete data.silent
            if Object.keys(data).length
                options.contentType = \application/json
                options.data = JSON.stringify(data)
        def = $.Deferred!
        do delay = ->
            if window.floodAPI_counter >= 15 /* 20 requests / 10s will trigger socket:floodAPI. This should leave us enough buffer in any case */
                sleep 1_000ms, delay
            else
                window.floodAPI_counter++; sleep 10_000ms, -> window.floodAPI_counter--
                return $.ajax options
                    .then def.resolve, def.reject, def.progress
        return def

    befriend: (userID, cb) -> ajax \POST, "friends", id: userID, cb
    ban: (userID, cb) -> ajax \POST, "bans/add", userID: userID, duration: API.BAN.HOUR, reason: 1, cb
    banPerma: (userID, cb) -> ajax \POST, "bans/add", userID: userID, duration: API.BAN.PERMA, reason: 1, cb
    unban: (userID, cb) -> ajax \DELETE, "bans/#userID", cb
    modMute: (userID, cb) -> ajax \POST, "mutes/add", userID: userID, duration: API.MUTE.SHORT, reason: 1, cb
    modUnmute: (userID, cb) -> ajax \DELETE, "mutes/#userID", cb
    chatDelete: (chatID, cb) -> ajax \DELETE, "chat/#chatID", cb
    kick: (userID, cb) ->
        <- ban userID
        <- sleep 1_000ms
        unban userID, cb

    getUserData: (user, cb) !->
        if typeof user != \number
            user = getUser user
        cb ||= (data) -> console.log "[userdata]", data, (if data.level >= 5 then "https://plug.dj/@/#{encodeURI data.slug}")
        return $.get "/_/users/#user"
            .then ({[data]:data}:arg) ->
                return data
            .fail ->
                console.warn "couldn't get slug for user with id '#{id}'"

    $djButton: $ \#dj-button
    mute: ->
        return $ '#volume .icon-volume-half, #volume .icon-volume-on' .click! .length
    muteonce: ->
        mute!
        muteonce.last = API.getMedia!.id
        API.once \advance, ->
            unmute! if API.getMedia!.id != muteonce.last
    unmute: ->
        return $ '#playback .snoozed .refresh, #volume .icon-volume-off, #volume .icon-volume-mute-once'.click! .length
    snooze: ->
        return $ '#playback .snooze' .click! .length
    refresh: ->
        return $ '#playback .refresh' .click! .length
    stream: (val) ->
        if not currentMedia
            console.error "[p0ne /stream] cannot change stream - failed to require() the module 'currentMedia'"
        else
            currentMedia?.set \streamDisabled, (val != true and (val == false or currentMedia.get(\streamDisabled)))
    join: ->
        # for this, performance might be essential
        # return $ '#dj-button.is-wait' .click! .length != 0
        if $djButton.hasClass \is-wait
            $djButton.click!
            return true
        else
            return false
    leave: ->
        return $ '#dj-button.is-leave' .click! .length != 0

    ytItags: do ->
        resolutions = [ 72p, 144p, 240p,  360p, 480p, 720p, 1080p, 1440p, 2160p, 3072p ]
        list =
            # DASH-only content is commented out, as it is not yet required
            * ext: \flv, minRes: 240p, itags: <[ 5 ]>
            * ext: \3gp, minRes: 144p, itags:  <[ 17 36 ]>
            * ext: \mp4, minRes: 240p, itags:  <[ 83 18,82 _ 22,84 85 ]>
            #* ext: \mp4, minRes: 240p, itags:  <[ 133 134 135 136 13 138 160 264 ]>, type: \video
            #* ext: \mp4, minRes: 720p, itags:  <[ 298 299 ]>, fps: 60, type: \video
            #* ext: \mp4, minRes: 128kbps, itags:  <[ 140 ]>, type: \audio
            * ext: \webm, minRes: 360p, itags:  <[ 43,100 ]>
            #* ext: \webm, minRes: 240p, itags:  <[ 242 243 244 247 248 271 272 ]>, type: \video
            #* ext: \webm, minRes: 720p, itags:  <[ 302 303 ]>, fps: 60, type: \video
            #* ext: \webm, minRes: 144p, itags:  <[ 278 ]>, type: \video
            #* ext: \webm, minRes: 128kbps, itags:  <[ 171 ]>, type: \audio
            * ext: \ts, minRes: 240p, itags:  <[ 151 132,92 93 94 95 96 ]> # used for live streaming
        res = {}
        for format in list
            for itags, i in format.itags when itag != \_
                # formats with type: \audio not taken into account ignored here
                startI = resolutions.indexOf format.minRes
                for itag in itags.split ","
                    res[itag] =
                        ext: format.ext
                        resolution: resolutions[startI + i]
        return res

    mediaSearch: (query) ->
        $ '#playlist-button .icon-playlist'
            .click! # will silently fail if playlist is already open
        $ \#search-input-field
            .val query
            .trigger do
                type: \keyup
                which: 13 # Enter
    mediaLookup: ({format, id, cid}:url, cb) ->
        if typeof cb == \function
            success = cb
        else
            if typeof cb == \object
                {success, fail} = cb if cb
            success ||= (data) -> console.info "[mediaLookup] #{<[yt sc]>[format - 1]}:#cid", data
        fail ||= (err) -> console.error "[mediaLookup] couldn't look up", cid, url, cb, err

        if typeof url == \string
            if cid = YT_REGEX .exec(url)?.1
                format = 1
            else if parseURL url .hostname in <[ soundcloud.com  i1.sndcdn.com ]>
                format = 2
        else
            cid ||= id

        if window.mediaLookup.lastID == (cid || url) and window.mediaLookup.lastData
            success window.mediaLookup.lastData
        else
            window.mediaLookup.lastID = cid || url
            window.mediaLookup.lastData = null
        if format == 1 # youtube
            return $.getJSON "https://gdata.youtube.com/feeds/api/videos/#cid?v=2&alt=json"
                .fail fail
                .success (d) ->
                    cid = d.entry.id.$t.substr(27)
                    success do
                        window.mediaLookup.lastData =
                            format:       1
                            data:         d
                            cid:          cid
                            uploader:
                                name:     d.entry.author.0.name.$t
                                id:       d.entry.media$group.yt$uploaderId.$t
                            image:        "https://i.ytimg.com/vi/#cid/0.jpg"
                            title:        d.entry.title.$t
                            uploadDate:   d.entry.published.$t
                            url:          "https://youtube.com/watch?v=#cid"
                            description:  d.entry.media$group.media$description.$t
                            duration:     d.entry.media$group.yt$duration.seconds # in s
        else if format == 2
            if cid
                req = $.getJSON "https://api.soundcloud.com/tracks/#cid.json", do
                    client_id: p0ne.SOUNDCLOUD_KEY
            else
                req = $.getJSON "https://api.soundcloud.com/resolve/", do
                    url: url
                    client_id: p0ne.SOUNDCLOUD_KEY
            return req
                .fail fail
                .success (d) ->
                    success do
                        window.mediaLookup.lastData =
                            format:         2
                            data:           d
                            cid:            cid
                            uploader:
                                id:         d.user.id
                                name:       d.user.username
                                image:      d.user.avatar_url
                            image:          d.artwork_url
                            title:          d.title
                            uploadDate:     d.created_at
                            url:            d.permalink_url
                            description:    d.description
                            duration:       d.duration / 1000ms_to_s # in s

                            download:       d.download_url + "?client_id=#{p0ne.SOUNDCLOUD_KEY}"
                            downloadSize:   d.original_content_size
                            downloadFormat: d.original_format
        else
            return $.Deferred()
                .fail fail
                .reject "unsupported format"

    mediaDownload: (media, audioOnly, cb) ->
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
            {format, cid, id} = media.attributes
        else
            media ||= API.getMedia!
            {format, cid, id} = media


        res =  $.Deferred()
        res
            .then success || logger \mediaDownload
            .fail error || logger \mediaDownloadError
            .fail (err) ->
                if audioOnly or format == 2
                    media.downloadAudioError = err
                else
                    media.downloadError = err

        if audioOnly or format == 2
            return res.resolve media.downloadAudio if media.downloadAudio
            return res.reject media.downloadAudioError if media.downloadAudioError
        else
            return res.resolve media.download if media.download
            return res.reject media.downloadError if media.downloadError

        cid ||= id
        if format == 1 # youtube
            url = p0ne.proxy "https://www.youtube.com/get_video_info?video_id=#cid"
            console.info "[mediaDownload] YT lookup", url
            $.ajax do
                url: url
                error: res.reject
                success: (d) ->
                    /*== Parser ==
                    # useful for debugging
                    parse = (d) ->
                      if d.startsWith "http"
                        return d
                      else if d.has(",")
                        return d.split(",").map(parse)
                      else if d.has "&"
                        res = {}
                        for a in d.split "&"
                          a .= split "="
                          if res[a.0]
                            res[a.0] = [res[a.0]] if not $.isArray res[a.0]
                            res[a.0][*] = parse unescape(a.1)
                          else
                            res[a.0] = parse unescape(a.1)
                        return res
                      else if not isNaN(d)
                        return +d
                      else if d in <[ True False ]>
                        return d == \True
                      else
                        return d
                    parse(d)
                    */
                    basename = d.match(/title=(.*?)(?:&|$)/)?.1 || cid
                    basename = unescape(basename).replace /\++/g, ' '
                    files = {}
                    bestVideo = null
                    bestVideoSize = 0
                    if not audioOnly
                        if d.match(/adaptive_fmts=(.*?)(?:&|$)/)
                            for file in unescape(that.1) .split ","
                                url = unescape that.1 if file.match(/url=(.*?)(?:&|$)/)
                                if file.match(/type=(.*?)%3B/)
                                    mimeType = unescape that.1
                                    filename = "#basename.#{mimeType.substr 6}"
                                    if file.match(/size=(.*?)(?:&|$)/)
                                        resolution = unescape(that.1)
                                        size = resolution.split \x
                                        size = size.0 * size.1
                                        (files[resolution] ||= [])[*] = video = {url, size, mimeType, filename, resolution}
                                        if size > bestVideoSize
                                            bestVideo = video
                                            bestVideoSize = size
                        else if d.match(/url_encoded_fmt_stream_map=(.*?)(?:&|$)/)
                            console.warn "[mediaDownload] only a low quality stream could be found for", cid
                            for file in unescape(that.1) .split ","
                                url = that.1 if d.match(/url=(.*?)(?:&|$)/)
                                if ytItags[d.match(/itag=(.*?);/)?.1]
                                    (files[that.ext] ||= [])[*] = video =
                                        file: "#basename.#{that.ext}"
                                        url: httpsify $baseurl.text!
                                        mimeType: "#{that.type}/#{that.ext}"
                                        resolution: that.resolution
                                    if that.resolution > bestVideoSize
                                        bestVideo = video
                                        bestVideoSize = that.resolution

                        files.preferredDownload = bestVideo
                        console.log "[mediaDownload] resolving", files
                        res.resolve media.download = files

                    # audioOnly
                    else if d.match(/dashmpd=(http.+?)(?:&|$)/)
                        url = p0ne.proxy(unescape that.1 /*parse(d).dashmpd*/)
                        console.info "[mediaDownload] DASHMPD lookup", url
                        $.get url
                            .then (dashmpd) ->
                                $dash = $ $.parseXML dashmpd
                                bestVideo = size: 0
                                $dash .find \AdaptationSet .each ->
                                    $set = $ this
                                    mimeType = $set .attr \mimeType
                                    type = mimeType.substr(0,5) # => \audio or \video
                                    return if type != \audio #and audioOnly
                                    files[mimeType] = []; l=0
                                    $set .find \BaseURL .each ->
                                        $baseurl = $ this
                                        $representation = $baseurl .parent!
                                        #height = $representation .attr \height
                                        files[mimeType][l++] = m =
                                            file: "#basename.#{mimeType.substr 6}"
                                            url: httpsify $baseurl.text!
                                            mimeType: mimeType
                                            size: $baseurl.attr(\yt:contentLength) / 1_000_000B_to_MB
                                            samplingRate: "#{$representation .attr \audioSamplingRate}Hz"
                                            #height: height
                                            #width: height && $representation .attr \width
                                            #resolution: height && "#{height}p"
                                        if audioOnly and ~~m.size > ~~bestVideo.size and (window.chrome or mimeType != \audio/webm)
                                                bestVideo := m
                                files.preferredDownload = bestVideo
                                console.log "[mediaDownload] resolving", files
                                res.resolve media.downloadAudio = files

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
                .then (d) ->
                    if d.download
                        d =
                            "#{d.downloadFormat}":
                                url: d.download
                                size: d.downloadSize
                        res.resolve media.downloadAudio = d
                    else
                        res.reject "download disabled"
                .fail res.reject
        else
            console.error "[mediaDownload] unknown format", media
            res.reject "unknown format"

        return res.promise!

    proxify: (url) ->
        if url.startsWith("http:")
            return p0ne.proxy url
        else
            return url
    httpsify: (url) ->
        if url.startsWith("http:")
            return "https://#{url.substr 7}"
        else
            return url

    getChatText: (cid) ->
        if not cid
            return $!
        else
            res = $cm! .find ".cid-#cid" .last!
            if not res.hasClass \.text
                res .= find \.text .last!
            return res
    getChat: (cid) ->
        return getChatText cid .parent! .parent!
    #ToDo test this
    getMentions: (data, safeOffsets) ->
        if safeOffsets
            attr = \mentionsWithOffsets
        else
            attr = \mentions
        return that if data[attr]
        mentions = []; l=0
        users = API.getUsers!
        msgLength = data.message.length
        data.message.replace /@/g, (_, offset) ->
            offset++
            possibleMatches = users
            i = 0
            while possibleMatches.length and i < msgLength
                possibleMatches2 = []; l3 = 0
                for m in possibleMatches when m.username[i] == data.message[offset + i]
                    #console.log ">", data.message.substr(offset, 5), i, "#{m.username .substr(0,i)}#{m.username[i].toUpperCase!}#{m.username .substr i+1}"
                    if m.username.length == i + 1
                        res = m
                        #console.log ">>>", m.username
                    else
                        possibleMatches2[l3++] = m
                possibleMatches = possibleMatches2
                i++
            if res
                if safeOffsets
                    mentions[l++] = res with offset: offset - 1
                else if not mentions.has(res)
                    mentions[l++] = res

        mentions = [getUser(data)] if not mentions.length and not safeOffsets
        mentions.toString = ->
            res = ["@#{user.username}" for user in this]
            return humanList res # both lines seperate for performance optimization
        data[attr] = mentions
        return mentions


    htmlEscapeMap: {sp: 32, blank: 32, excl: 33, quot: 34, num: 35, dollar: 36, percnt: 37, amp: 38, apos: 39, lpar: 40, rpar: 41, ast: 42, plus: 43, comma: 44, hyphen: 45, dash: 45, period: 46, sol: 47, colon: 58, semi: 59, lt: 60, equals: 61, gt: 62, quest: 63, commat: 64, lsqb: 91, bsol: 92, rsqb: 93, caret: 94, lowbar: 95, lcub: 123, verbar: 124, rcub: 125, tilde: 126, sim: 126, nbsp: 160, iexcl: 161, cent: 162, pound: 163, curren: 164, yen: 165, brkbar: 166, sect: 167, uml: 168, die: 168, copy: 169, ordf: 170, laquo: 171, not: 172, shy: 173, reg: 174, hibar: 175, deg: 176, plusmn: 177, sup2: 178, sup3: 179, acute: 180, micro: 181, para: 182, middot: 183, cedil: 184, sup1: 185, ordm: 186, raquo: 187, frac14: 188, half: 189, frac34: 190, iquest: 191}
    htmlEscape: (str) ->
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
        return str.replace //#{window.htmlEscapeRegexp .join "|"}//g, (c) -> return "&#{window.htmlEscapeMap_reversed[c.charCodeAt 0]};"
        */

    htmlUnescape: (html) ->
        return html.replace /&(\w+);|&#(\d+);|&#x([a-fA-F0-9]+);/g, (_,a,b,c) ->
            return String.fromCharCode(+b or htmlEscapeMap[a] or parseInt(c, 16)) or _
    stripHTML: (msg) ->
        return msg .replace(/<.*?>/g, '')
    unemotify: (str) ->
        map = window.emoticons?.map
        return str if not map
        str .replace /<span class="emoji-glow"><span class="emoji emoji-(\w+)"><\/span><\/span>/g, (_, emoteID) ->
            if emoticons.reversedMap[emoteID]
                return ":#that:"
            else
                return _

    #== RTL emulator ==
    # str = "abc\u202edef\u202dghi"
    # [str, resolveRTL(str)]
    resolveRTL: (str, dontJoin) ->
        a = b = ""
        isRTLoverridden = false
        "#str\u202d".replace /(.*?)(\u202e|\u202d)/g, (_,pre,c) ->
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

    collapseWhitespace: (str) ->
        return str.replace /\s+/g, ' '
    cleanMessage: (str) -> return str |> unemotify |> stripHTML |> htmlUnescape |> resolveRTL |> collapseWhitespace

    formatPlainText: (text) -> # used for song-notif and song-info
        lvl = 0
        text .= replace /([\s\S]*?)($|https?:(?:\([^\s\]\)]*\)|\[[^\s\)\]]*\]|[^\s\)\]]+))+([\.\?\!\,])?/g, (,pre,url,post) ->
            pre = pre
                .replace /(\s)(".*?")(\s)/g, "$1<i class='song-description-string'>$2</i>$3"
                .replace /(\s)(\*\w+\*)(\s)/g, "$1<b>$2</b>$3"
                .replace /(lyrics|download|original|re-?upload)/gi, "<b>$1</b>"
                .replace /(\s)((?:0x|#)[0-9a-fA-F]+|\d+)(\w*|%|\+)?(\s)/g, "$1<b class='song-description-number'>$2</b><i class='song-description-comment'>$3</i>$4"
                .replace /^={5,}$/mg, "<hr class='song-description-hr-double' />"
                .replace /^[\-~_]{5,}$/mg, "<hr class='song-description-hr' />"
                .replace /^[\[\-=~_]+.*?[\-=~_\]]+$/mg, "<b class='song-description-heading'>$&</b>"
                .replace /(.?)([\(\)])(.?)/g, (x,a,b,c) ->
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


    /*colorKeywords: do ->
        <[ %undefined% black silver gray white maroon red purple fuchsia green lime olive yellow navy blue teal aqua orange aliceblue antiquewhite aquamarine azure beige bisque blanchedalmond blueviolet brown burlywood cadetblue chartreuse chocolate coral cornflowerblue cornsilk crimson darkblue darkcyan darkgoldenrod darkgray darkgreen darkgrey darkkhaki darkmagenta darkolivegreen darkorange darkorchid darkred darksalmon darkseagreen darkslateblue darkslategray darkslategrey darkturquoise darkviolet deeppink deepskyblue dimgray dimgrey dodgerblue firebrick floralwhite forestgreen gainsboro ghostwhite gold goldenrod greenyellow grey honeydew hotpink indianred indigo ivory khaki lavender lavenderblush lawngreen lemonchiffon lightblue lightcoral lightcyan lightgoldenrodyellow lightgray lightgreen lightgrey lightpink lightsalmon lightseagreen lightskyblue lightslategray lightslategrey lightsteelblue lightyellow limegreen linen mediumaquamarine mediumblue mediumorchid mediumpurple mediumseagreen mediumslateblue mediumspringgreen mediumturquoise mediumvioletred midnightblue mintcream mistyrose moccasin navajowhite oldlace olivedrab orangered orchid palegoldenrod palegreen paleturquoise palevioletred papayawhip peachpuff peru pink plum powderblue rosybrown royalblue saddlebrown salmon sandybrown seagreen seashell sienna skyblue slateblue slategray slategrey snow springgreen steelblue tan thistle tomato turquoise violet wheat whitesmoke yellowgreen rebeccapurple ]>
            ..0 = void
            return ..
    isColor: (str) ->
        str = (~~str).toString(16) if typeof str == \number
        return false if typeof str != \string
        str .= trim!
        tmp = /^(?:#(?:[a-fA-F0-9]{6}|[a-fA-F0-9]{3})|(?:rgb|hsl)a?\([\d,]+\)|currentColor|(\w+))$/.exec(str)
        if tmp and tmp.1 in window.colorKeywords
            return str
        else
            return false*/
    isColor: (str) ->
        $dummy.0 .style.color = ""
        $dummy.0 .style.color = str
        return $dummy.0 .style.color == ""

    isURL: (str) ->
        return false if typeof str != \string
        str .= trim! .replace /\\\//g, '/'
        if parseURL(str).host != location.host
            return str
        else
            return false


    mention: (list) ->
        if not list?.length
            return ""
        else if list.0.username
            return humanList ["@#{list[i].username}" for ,i in list]
        else if list.0.attributes?.username
            return humanList ["@#{list[i].get \username}" for ,i in list]
        else
            return humanList ["@#{list[i]}" for ,i in list]
    humanList: (arr) ->
        return "" if not arr.length
        arr = []<<<<arr
        if arr.length > 1
            arr[*-2] += " and\xa0#{arr.pop!}" # \xa0 is NBSP
        return arr.join ", "

    plural: (num, singular, plural=singular+'s') ->
        # for further functionality, see
        # * http://unicode.org/repos/cldr-tmp/trunk/diff/supplemental/language_plural_rules.html
        # * http://www.unicode.org/cldr/charts/latest/supplemental/language_plural_rules.html
        # * https://developer.mozilla.org/en-US/docs/Localization_and_Plurals
        if num == 1 # note: 0 will cause an s at the end, too
            return "#num\xa0#singular" # \xa0 is NBSP
        else
            return "#num\xa0#plural"


    # formatting
    getTime: (t = new Date) ->
        return t.toISOString! .replace(/.+?T|\..+/g, '')
    getISOTime: (t = new Date)->
        return t.toISOString! .replace(/T|\..+/g, " ")
    # show a timespan (in ms) in a human friendly format (e.g. "2 hours")
    humanTime: (diff, short) ->
        return "-#{humanTime -diff}" if diff < 0
        b=[60to_min, 60to_h, 24to_days, 360.25to_years]; c=0
        diff /= 1000to_s
        while diff > 2*b[c] then diff /= b[c++]
        if short
            return "#{~~diff}#{<[ s m h d ]>[c]}"
        else
            return plural ~~diff, <[ second minute hour day ]>[c]
    # show a timespan (in s) in a format like "mm:ss" or "hh:mm:ss" etc
    mediaTime: (~~dur) ->
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
    ago: (d) ->
        return "#{humanTime (Date.now! - d)} ago"

    lssize: (sizeWhenDecompressed) ->
        size = 0mb
        for k,v of localStorage when k != \length
            if sizeWhenDecompressed
                try v = decompress v
            size += v.length / 524288to_mb # x.length * 16bits / 8to_b / 1024to_kb / 1024to_mb
        return size
    formatMB: ->
        return "#{it.toFixed(2)}MB"

    getRank: (user) -> # returns the name of a rank of a user
        user = getUser(user)
        if not user or (role = user.role || user.get?(\role)) == -1
            return \ghost
        else if user.gRole || user.get?(\gRole)
            if that == 5
                return \admin
            else
                return \BA
        else
            return <[ none rdj bouncer manager cohost host ]>[role || 0]

    parseURL: (href) ->
        $dummy.0.href = href
        return $dummy.0{hash, host, hostname, href, pathname, port, protocol, search}

    getIcon: do ->
        # note: this function doesn't cache results, as it's expected to not be used often (only in module setups)
        # if you plan to use it over and over again, use fn.enableCaching()
        $icon = $ '<i class=icon>'
                .css visibility: \hidden
                .appendTo \body
        fn = (className) ->
            $icon.addClass className
            res =
                background: $icon .css \background
                image:      $icon .css \background-image
                position:   $icon .css \background-position
            $icon.removeClass className
            return res
        fn.enableCaching = -> res = _.memoize(fn); res.enableCaching = $.noop; window.getIcon = res
        return fn




    # variables
    disabled: false
    userID: API?.getUser!.id # API.getUser! will fail when used on the Dashboard if no room has been visited before
    user: API?.getUser! # for usage with things that should not change, like userID, joindate, …
    getRoomSlug: ->
        return room?.get?(\slug) || decodeURIComponent location.pathname.substr(1)





/*####################################
#          REQUIRE MODULES           #
####################################*/
#= _$context =
requireHelper \_$context, (._events?['chat:receive']), do
    onfail: ->
        console.error "[p0ne require] couldn't load '_$context'. Quite a alot modules rely on this and thus might not work"
window._$context?.onEarly = (type, callback, context) ->
    this._events[][type] .unshift({callback, context, ctx: context || this})
        # ctx:  used for .trigger in Backbone
        # context:  used for .off in Backbone
    return this



# continue only after `app` was loaded
#= require plug.dj modules  =
requireHelper \user_, (.canModChat) #(._events?.'change:username')

if user_
    window.users = user_.collection
    if not userID
        user = user_.toJSON!
        userID = user.id


window.Lang = require \lang/Lang
requireHelper \Curate, (.::?.execute?.toString!.has("/media/insert"))
requireHelper \playlists, (.activeMedia)
requireHelper \auxiliaries, (.deserializeMedia)
requireHelper \database, (.settings)
requireHelper \socketEvents, (.ack)
requireHelper \permissions, (.canModChat)
requireHelper \Playback, (.::?.id == \playback)
requireHelper \PopoutView, (\_window of)
requireHelper \MediaPanel, (.::?.onPlaylistVisible)
requireHelper \PlugAjax, (.::?.hasOwnProperty \permissionAlert)
requireHelper \backbone, (.Events), id: \backbone
requireHelper \roomLoader, (.onVideoResize)
requireHelper \Layout, (.getSize)
requireHelper \DialogAlert, (.::?.id == \dialog-alert)
requireHelper \popMenu, (.className == \pop-menu)
requireHelper \ActivateEvent, (.ACTIVATE)
requireHelper \votes, (.attributes?.grabbers)
requireHelper \tracker, (.identify)
requireHelper \currentMedia, (.updateElapsedBind)
requireHelper \settings, (.settings)
requireHelper \soundcloud, (.sc)
requireHelper \userList, (.id == \user-lists)
requireHelper \FriendsList, (.::?.className == \friends)
requireHelper \RoomUserRow, (.::?.vote)
requireHelper \WaitlistRow, (.::?.onAvatar)
requireHelper \PlaylistItemRow, (.::?.listClass == \playlist-media)
requireHelper \room, (.attributes?.hostID?)

requireHelper \emoticons, (.emojify)
emoticons.reversedMap = {[v, k] for k,v of emoticons.map} if window.emoticons


# `app` is like the ultimate root object on plug.dj, just about everything is somewhere in there! great for debugging
for cb in (room._events[\change:name] || _$context?._events[\show:room] || Layout?._events[\resize] ||[]) when cb.ctx.room
    export app = cb.ctx
    export friendsList = app.room.friends
    break




# chat
if app and not window.chat = app.room.chat
    for e in _$context?._events[\chat:receive] ||[] when e.context?.cid
        window.chat = e.context
        break

if chat
    window <<<<
        $cm: ->
            if window.saveChat
                return saveChat.$cm
            else
                return chat.$chatMessages

        playChatSound: (isMention) ->
            if isMention
                chat.playSound \mention
            else if $ \.icon-chat-sound-on .length > 0
                chat.playSound \chat
else
    cm = $ \#chat-messages
    window <<<<
        $cm: ->
            return cm
        playChatSound: (isMention) ->

window <<<<
    appendChat: (div, wasAtBottom) ->
        wasAtBottom ?= chatIsAtBottom!
        if window.saveChat
            window.saveChat.$cChunk.append div
        else
            $cm!.append div
        chatScrollDown! if wasAtBottom
        chat.lastID = -1 # avoid message merging above the appended div
        return div

        #playChatSound isMention

    chatIsAtBottom: ->
        cm = $cm!
        return cm.scrollTop! > cm.0 .scrollHeight - cm.height! - 20
    chatScrollDown: ->
        cm = $cm!
        cm.scrollTop( cm.0 .scrollHeight )

    chatInput: (msg, append) ->
        $input = chat?.$chatInputField || $ \#chat-input-field
        if append and $input.text!
            msg = "#that #msg"
        $input
            .val msg
            .trigger \input
            .focus!



/*####################################
#           extend jQuery            #
####################################*/
# add .timeout(time, fn) to Deferreds and Promises
replace jQuery, \Deferred, (Deferred_) -> return ->
    var timeStarted
    res = Deferred_ ...
    res.timeout = timeout
    promise_ = res.promise
    res.promise = ->
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
            sleep timeStarted + time - now, ~>
                callback.call this, this if @state! == \pending



/*####################################
#     Listener for other Scripts     #
####################################*/
# plug³
var rR_
onLoaded = ->
    console.info "[p0ne] plugCubed detected"
    rR_ = Math.randomRange

    # wait for plugCubed to finish loading
    requestAnimationFrame waiting = ->
        if window.plugCubed and not window.plugCubed.plug_p0ne
            API.trigger \plugCubedLoaded, window.plugCubed
            $body .addClass \plugCubed
            replace plugCubed, \close, (close_) -> return !->
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
onLoaded = ->
    console.info "[p0ne] plugplug detected"
    API.trigger \plugplugLoaded, window.plugplug
    sleep 5_000ms, -> ppStop = onLoaded
if window.ppSaved
    onLoaded!
else
    export ppStop = onLoaded

/*####################################
#          GET PLUG³ VERSION         #
####################################*/
window.getPlugCubedVersion = ->
    if not plugCubed?.init
        return null
    else if plugCubed.version
        return plugCubed.version
    else if v = $ '#p3-settings .version' .text!
        void
    else # plug³ alpha
        v = requireHelper \plugCubedVersion, (.major)
        return v if v

        # alternative methode (40x slower)
        $ \plugcubed .click!
        v = $ \#p3-settings
            .stop!
            .css left: -500px
            .find \.version .text!


    if typeof v == \string
        if v .match /^(\d+)\.(\d+)\.(\d+)(?:-(\w+))?(_min)? \(Build (\d+)\)$/
            v := that{major, minor, patch, prerelease, minified, build}
            v.toString = ->
                return "#{@major}.#{@minor}.#{@patch}#{@prerelease && '-'+@prerelease}#{@minified && '_min' || ''} (Build #{@build})"
    return plugCubed.version = v



# draws an image in the log
# `src` can be any url, that is valid in CSS (thus data urls etc, too)
# the optional parameter `customWidth` and `customHeight` need to be in px (of the type Number; e.g. `316` for 316px)
#note: if either the width or the height is not defined, the console.log entry will be asynchron because the image has to be loaded first to get the image's width and height
# returns a promise, so you can attach a callback for asynchronious loading with `console.logImg(...).then(function (img){ ...callback... } )`
# an HTML img-node with the picture will be passed to the callback(s)
#var pending = console && console.logImg && console.logImg.pending
console.logImg = (src, customWidth, customHeight) ->
    promise = do
        then: (cb) ->
            this._callbacksAfter ++= cb
            return this

        before: ->
            this._callbacksBefore ++= cb
            return this
        _callbacksAfter: []
        _callbacksBefore: []
        abort: ->
            this._aborted = true
            this.before = this.then = ->
            return this
        _aborted: false

    var img
    logImg = arguments.callee
    logImgLoader = ->
        if promise._aborted
            return

        if promise._callbacksBefore.length
            for cb in promise._callbacksBefore
                cb img
        promise.before = -> it img

        #console.log("height: "+(+customHeight || img.height)+"px; ", "width: "+(+customWidth || img.width)+"px")
        if window.chrome
            console.log "%c\u200B", "color: transparent; font-size: #{(+customHeight || img.height)*0.854}px !important;
                background: url(#src);display:block;
                border-right: #{+customWidth || img.width}px solid transparent
            "
        else
            console.log "%c", "background: url(#src) no-repeat; display: block;
                width: #{customWidth || img.width}px; height: #{customHeight || img.height}px;
            "
        if promise._callbacksAfter.length
            for cb in promise._callbacksAfter
                cb img
        promise.before = promise.then = -> it img

    if +customWidth && +customHeight
        logImgLoader!
    else
        #logImg.pending = logImg.pending || []
        #pendingPos = logImg.pending.push({src: src, customWidth: +customWidth, +customHeight: customHeight, time: new Date(), _aborted: false})
        img = new Image
            ..onload = logImgLoader
            ..onerror = ->
                #if(logImg.pending && logImg.pending.constructor == Array)
                #   logImg.pending.splice(pendingPos-1, 1)
                console.log "[couldn't load image %s]", src
            ..src = src

    return promise

/*@source p0ne.module.ls */
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


/*@source p0ne.auxiliary-modules.ls */
/**
 * Auxiliary plug_p0ne modules
 * @author jtbrinkmann aka. Brinkie Pie
 * @version 1.0
 * @license MIT License
 * @copyright (c) 2014 J.-T. Brinkmann
 */


/*####################################
#            AUXILIARIES             #
####################################*/
module \getActivePlaylist, do
    require: <[ playlists ]>
    module: ->
        return playlists.findWhere active: true
module \_API_, do
    optional: <[]>
    setup: ->
        for k,v of API when not @[k]
            @[k] = v
    chatLog: API.chatLog
    on: API.on
    once: API.once
    off: API.off
    _events: API.{}_events
    getAdmins: -> ...
    getAmbassadors: -> ...
    getAudience: -> ...
    getBannedUsers: -> ...
    getDJ: -> ...
    getHistory: -> return roomHistory
    getHost: -> ...
    getMedia: -> ...
    getNextMedia: -> ...
    getUser: -> return user_
    getUsers: -> return users
    getPlaylists: -> ...
    getStaff: -> ...
    getWaitList: -> ...
module \updateUserData, do
    require: <[ user_ users _$context ]>
    setup: ({addListener}) ->
        addListener window.user_, \change:username, ->
            user.username = window.user_.get \username
        addListener _$context, \user:join, ({id}) ->
            users.get(id).set \joinedRoom, Date.now!
        for user in users.models
            user.set \joinedRoom, -1
module \throttleOnFloodAPI, do
    setup: ({addListener}) ->
        addListener API, \socket:floodAPI, ->
            /* all AJAX and Socket functions should check if the counter is AT LEAST below 20 */
            window.floodAPI_counter += 20
            sleep 15_000ms, ->
                /* it is assumed, that the API counter resets every 10 seconds. 15s is to provide enough buffer */
                window.floodAPI_counter -= 20

module \PopoutListener, do
    require: <[ PopoutView ]>
    optional: <[ _$context chat ]>
    setup: ({replace}) ->
        # also works with chatDomEvents.on \click, \.un, -> example!
        # even thought cb.callback becomes \.un and cb.context becomes -> example!
        replace PopoutView, \render, (r_) -> return ->
            r_ ...
            _$context?.trigger \popout:open, PopoutView._window, PopoutView
            API.trigger \popout:open, PopoutView._window, PopoutView
        replace PopoutView, \close, (c_) -> return ->
            c_ ...
            _$context?.trigger \popout:close, PopoutView._window, PopoutView
            API.trigger \popout:close, PopoutView._window, PopoutView

module \chatDomEvents, do
    require: <[ backbone ]>
    optional: <[ PopoutView PopoutListener ]>
    persistent: <[ _events ]>
    setup: ({addListener}) ->
        @ <<<< backbone.Events
        @one = @once # because jQuery uses .one instead of .once
        cm = $cm!
        on_ = @on; @on = ->
            on_ ...
            cm.on .apply cm, arguments
        off_ = @off; @off = ->
            off_ ...
            cm.off .apply cm, arguments

        patchCM = ~>
            cm = PopoutView.chat
            for event, callbacks of @_events
                for cb in callbacks
                    #cm .off event, cb.callback, cb.context #ToDo test if this is necessary
                    cm .on event, cb.callback, cb.context
        addListener API, \popout:open, patchCM

module \grabMedia, do
    require: <[ playlists auxiliaries ]>
    optional: <[ _$context ]>
    module: (playlistIDOrName, media, appendToEnd) ->
        currentPlaylist = playlists.get(playlists.getActiveID!)
        # get playlist
        if typeof playlistIDOrName == \string and not playlistIDOrName .startsWith \http
            for pl in playlists.models when playlistIDOrName == pl.get \name
                playlist = pl; break
        else if not playlist = playlists.get(playlistIDOrName)
            playlist = currentPlaylist # default to current playlist
            appendToEnd = media; media = playlistIDOrName

        if not playlist
            console.error "[grabMedia] could not find playlist", arguments
            return

        # get media
        if not media # default to current song
            addMedia API.getMedia!
        else if media.id
            addMedia media
        else
            mediaLookup media, do
                success: addMedia
                fail: (err) ->
                    console.error "[grabMedia] couldn't grab", err

        # add media to playlist
        function addMedia media
            console.log "[grabMedia] add '#{media.author} - #{media.title}' to playlist:", playlist
            playlist.set \syncing, true
            media.get = l("it -> this[it]")
            ajax \POST, "playlists/#{playlist.id}/media/insert", media: auxiliaries.serializeMediaItems([media]), append: !!appendToEnd
                .then ({[e]:data}) ->
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
                .fail ->
                    console.error "[grabMedia] error adding song to the playlist"



/*####################################
#             CUSTOM CSS             #
####################################*/
module \p0neCSS, do
    optional: <[ PopoutListener PopoutView ]>
    $popoutEl: $!
    styles: {}
    urlMap: {}
    persistent: <[ styles ]>
    setup: ({addListener, $create}) ->
        @$el = $create \<style> .appendTo \head
        {$el, $popoutEl, styles, urlMap} = this
        addListener API, \popout:open, (_window) ->
            $popoutEl := $el .clone! .appendTo _window.document.head
        PopoutView.render! if PopoutView?._window

        export @getCustomCSS = (inclExternal) ->
            if inclExternal
                return [el.outerHTML for el in $el] .join '\n'
            else
                return $el .first! .text!

        throttled = false
        export @css = (name, css) ->
            return styles[name] if not css?

            styles[name] = css

            if not throttled
                throttled := true
                requestAnimationFrame ->
                    throttled := false
                    res = ""
                    for n,css of styles
                        res += "/* #n */\n#css\n\n"
                    $el       .first! .text res
                    $popoutEl .first! .text res

        export @loadStyle = (url) ->
            console.log "[loadStyle] %c#url", "color: #009cdd"
            if urlMap[url]
                return urlMap[url]++
            else
                urlMap[url] = 1
            s = $ "<link rel='stylesheet' >"
                #.attr \href, "#url?p0=#{p0ne.version}" /* ?p0 to force redownload instead of using obsolete cached versions */
                .attr \href, url /* ?p0 to force redownload instead of using obsolete cached versions */
                .appendTo document.head
            $el       .push s.0

            if PopoutView?._window
                $popoutEl .push do
                    s.clone!
                        .appendTo PopoutView?._window.document.head

        export @unloadStyle = (url) ->
            if urlMap[url] > 0
                urlMap[url]--
            if urlMap[url] == 0
                console.log "[loadStyle] unload %c#url", "color: #009cdd"
                delete urlMap[url]
                if -1 != i = $el       .indexOf "[href='#url']"
                    $el.eq(i).remove!
                    $el.splice(i, 1)
                if -1 != i = $popoutEl .indexOf "[href='#url']"
                    $popoutEl.eq(i).remove!
                    $popoutEl.splice(i, 1)
        @disable = ->
            $el       .remove!
            $popoutEl .remove!


module \_$contextUpdateEvent, do
    require: <[ _$context ]>
    setup: ({replace}) ->
        for fn in <[ on off onEarly ]>
            replace _$context, fn,  (fn_) -> return (type, cb, context) ->
                fn_ ...
                _$context .trigger \context:update, type, cb, context



module \login, do
    persistent: <[ showLogin ]>
    module: ->
        if @showLogin
            @showLogin!
        else if not @loading
            @loading = true
            $.getScript "#{p0ne.host}/plug_p0ne.login.js"

/*@source p0ne.perf.ls */
/**
 * performance enhancements for plug.dj
 * the perfEmojify module also adds custom emoticons
 * @author jtbrinkmann aka. Brinkie Pie
 * @version 1.0
 * @license MIT License
 * @copyright (c) 2014 J.-T. Brinkmann
 */
module \jQueryPerf, do
    setup: ({replace}) ->
        core_rnotwhite = /\S+/g
        if \classList of document.body #ToDo is document.body.classList more performant?
            replace jQuery.fn, \addClass, -> return (value) ->
                /* performance improvements */
                if jQuery.isFunction(value)
                    for j in this
                        jQuery(this).addClass value.call(this, j, this.className)

                else if typeof value == \string and value
                    classes = value.match(core_rnotwhite) || []

                    i = 0
                    while elem = this[i++] when (not elem && console.error(\missingElem, \addClass, this) || !0) and elem.nodeType == 1
                        j = 0
                        while clazz = classes[j++]
                            elem.classList.add clazz
                return this

            replace jQuery.fn, \removeClass, -> return (value) ->
                /* performance improvements */
                if jQuery.isFunction(value)
                    for j in this
                        jQuery(this).removeClass value.call(this, j, this.className)

                else if value ~= null
                    i = 0
                    while elem = this[i++] when (not elem && console.error(\missingElem, \removeClass, this) || !0) and elem.nodeType == 1
                        j = elem.classList .length
                        while clazz = elem.classList[--j]
                            elem.classList.remove clazz
                else if typeof value == \string and value
                    classes = value.match(core_rnotwhite) || []

                    i = 0
                    while elem = this[i++] when (not elem && console.error(\missingElem, \removeClass, this) || !0) and elem.nodeType == 1
                        j = 0
                        while clazz = classes[j++]
                            elem.classList.remove clazz
                return this

            replace jQuery.fn, \hasClass, -> return (className) ->
                /* performance improvements */
                i = 0
                while elem = this[i++] when (not elem && console.error(\missingElem, \hasClass, this) || !0) and elem.nodeType == 1 and elem.classList.contains className
                        return true
                return false


module \perfEmojify, do
    require: <[ emoticons ]>
    setup: ({replace}) ->
        # improves .emojify performance by 135% https://i.imgur.com/iBNICkX.png
        escapeReg = (e) ->
            return e .replace /([\\\.\+\*\?\[\^\]\$\(\)\{\}\=\!\<\>\|\:])/g, "\\$1"

        autoEmoteMap =
            /*NOTE: the keys (emoticons) HAVE to be uppercase! */
            \>:( : \angry
            \>XD : \astonished
            \:DX : \bowtie
            \</3 : \broken_heart
            \:$ : \confused
            X$: \confounded
            \:~( : \cry
            \:[ : \disappointed
            \:~[ : \disappointed_relieved
            XO: \dizzy_face
            \:| : \expressionless
            \8| : \flushed
            \:( : \frowning
            \:# : \grimacing
            \:D : \grinning
            \<3 : \heart
            "<3)": \heart_eyes
            "O:)": \innocent
            ":~)": \joy
            \:* : \kissing
            \:<3 : \kissing_heart
            \X<3 : \kissing_closed_eyes
            XD: \laughing
            \:O : \open_mouth
            \Z:| : \sleeping
            ":)": \smiley
            \:/ : \smirk
            T_T: \sob
            \:P : \stuck_out_tongue
            \X-P : \stuck_out_tongue_closed_eyes
            \;P : \stuck_out_tongue_winking_eye
            "B-)": \sunglasses
            \~:( : \sweat
            "~:)": \sweat_smile
            XC: \tired_face
            \>:/ : \unamused
            ";)": \wink
        autoEmoteMap <<<< emoticons.autoEmoteMap
        emoticons.autoEmoteMap = autoEmoteMap

        emoticons.update = ->
            # create reverse emoticon map
            @reverseMap = {}

            # create hashes (ternary tree)
            @hashes = {}
            for k,v of @map
                continue if @reverseMap[v]
                @reverseMap[v] = k
                h = @hashes
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

            # fix autoEmote
            for k,v of @autoEmoteMap
                tmp = k .replace "<", "&LT;" .replace ">", "&GT;"
                if tmp != k
                    @autoEmoteMap[tmp] = v
                    delete @autoEmoteMap[k]

            # create regexp for autoEmote
            @regAutoEmote = //(^|\s|&nbsp;)(#{Object.keys(@autoEmoteMap) .map escapeReg .join "|"})(?=\s|$)//gi

        emoticons.update!
        replace emoticons, \emojify, -> return (str) ->
            return str
                .replace @regAutoEmote, (,pre,emote) ~> return "#pre:#{@autoEmoteMap[emote .toUpperCase!]}:"
                .replace /:(.*?):/g, (_, emote) ~>
                    if @map[emote]
                        return "<span class='emoji-glow'><span class='emoji emoji-#{@map[emote]}'></span></span>"
                    else
                        return _
        replace emoticons, \lookup, -> return (str) ->
            h = @hashes
            var res
            for letter, i in str
                h = h[letter]
                switch typeof h
                | \undefined
                    return []
                | \string
                    for i from i+1 til str.length when str[i] != h[i]
                        return []
                    return [h]
            return h._list

/*@source p0ne.sjs.ls */
/**
 * propagate Socket Events to the API Event Emitter for custom event listeners
 * @author jtbrinkmann aka. Brinkie Pie
 * @version 1.0
 * @license MIT License
 * @copyright (c) 2014 J.-T. Brinkmann
 */
#== patch socket ==
module \socketListeners, do
    require: <[ socketEvents SockJS ]>
    optional: <[ _$context auxiliaries ]>
    setup: ({replace}) ->
        return if window.socket?._base_url == "https://shalamar.plug.dj:443/socket" # 2015-01-25
        onRoomJoinQueue2 = []
        for let event in <[ send dispatchEvent ]>
            replace SockJS::, event, (e_) -> return ->
                e_ ...

                if window.socket != this and this._base_url == "https://shalamar.plug.dj:443/socket"
                    # patch
                    replace window, \socket, ~> return this
                    replace this, \onmessage, (msg_) -> return (t) ->
                        for el in t.data || []
                            _$context.trigger "socket:#{el.a}", el
                            API.trigger "socket:#{el.a}", el

                        type = t.data?.0?.a
                        console.warn "[SOCKET:WARNING] socket message format changed", t if not type

                        msg_ ...
                    _$context .on \room:joined, ->
                        while onRoomJoinQueue2.length
                            forEach onRoomJoinQueue2.shift!

                    socket.emit = (e, t, n) ->
                        #if e != \chat
                        #   console.log "[socket:#e]", t, n || ""
                        socket.send JSON.stringify do
                            a: e
                            p: t
                            t: auxiliaries?.getServerEpoch!
                            d: n

                    console.info "[Socket] socket patched (using .#event)", this



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

/*
# from app.8cf130d413df133d47c418a818ee8cd60e05a2a0.js (2014-11-25)
# with minor improvements
define \plug_p0ne/socket, [ "underscore", "sockjs", "da676/df0c1/b4fa4", "da676/df0c1/fe7d6", "da676/ae6e4/a8215", "da676/ae6e4/fee3c", "da676/ae6e4/ac243", "da676/cba08/ee33b", "da676/cba08/f7bde", "da676/e0fc4/b75b7", "da676/eb13a/cd12f/d3fee", "da676/b0e2b/e9c55", "lang/Lang" ], ( _, SockJS,, context, AlertEvent, RoomEvent, UserEvent, room, user, socketEvents, AuthReq, auxiliaries, lang ) ->
        var socketURL, retries, sessionWasKilled, socket, onRoomJoinQueue
        if window._sjs
            init window._sjs
            context.on \socket:connect, connectedOrTimeout
        # window._sjs = undefined
        # delete window._sjs

        function init  e
            socketURL := e
            retries := 0
            sessionWasKilled := false
            context
                .on \chat:send, sendChat
                .on \room:joined, roomJoined
                .on \session:kill, sessionKilled

        function connectedOrTimeout
            if not socket
                context.off \socket:connect, connectedOrTimeout
            #socketEvents := _.clone socketEvents
            else
                socket.onopen = socket.onclose = socket.onmessage = socket := void
            debugLog \connecting, socketURL
            window.socket = socket := new SockJS( socketURL )
                ..onopen = connected
                ..onclose = disconnected
                ..onmessage = onMessage
            onRoomJoinQueue := []

        function connected
            debugLog \connected
            retries := 0
            if window._jm
                emit \auth, window._jm
                #delete window._jm
            else
                new AuthReq
                    .on \success, authenticated
                    .on \error, authenFailed


        function authenticated  e
            context
                .trigger \sjs:reconnected
                .on \ack, ->
                    context.off \ack
                        .dispatch new UserEvent( UserEvent.ME )
                    if room.get \joined
                        context.dispatch new RoomEvent( RoomEvent.STATE, room.get \slug )
            emit \auth, e

        function sessionKilled
            debugLog( \kill )
            sessionWasKilled := true

        function disconnected  t
            debugLog \disconnect, t
            if t?.wasClean and sessionWasKilled
                authenFailed!
            else
                if ++retries >= 0xFF #5
                    dcAlertEvent lang.alerts.connectionError, lang.alerts.connectionErrorMessage
                else
                    debugLog \reconnect, retries
                    context.trigger \sjs:reconnecting
                    _.delay connectedOrTimeout, Math.pow( 2, retries ) * 1_000ms

        function sendChat  e
            emit \chat, e

        function emit e, t, n
            if e != \chat
                debugLog \send, e, t, n || ""
            socket.send JSON.stringify do
                a: e
                p: t
                t: auxiliaries.getServerEpoch!
                d: n

        function onMessage  t
            if room.get \joined
                forEach( t.data )
            else
                n = _.filter t.data, (e) ->
                    return e.s == \dashboard
                r = _.filter t.data, ( e ) ->
                    return e.s != \dashboard
                forEach( n )
                onRoomJoinQueue.push( r )

        function forEach  t
            return if not t or not _.isArray( t )
            n = t.length
            for user in t
                if user.s != \dashboard and user.s != room.get \slug
                    debugLog "mismatch :: slug=#{room.get \slug}, message=", user
                    return
                i = user.a
                s = user.socketURL
                if i != \chat
                    debugLog i, s
                if socketEvents[ i ]
                    try
                        socketEvents[ i ]( s )

        function roomJoined
            while onRoomJoinQueue.length
                forEach onRoomJoinQueue.shift!

        function authenFailed
            context.dispatch( new AlertEvent( AlertEvent.ALERT, lang.alerts.sessionExpired, lang.alerts.sessionExpiredMessage, auxiliaries.forceRefresh, auxiliaries ), true )

        function debugLog
            if 5 == user.get \gRole # if client is admin
                e = <[ [sjs] ]>
                for arg, i in arguments
                    e[i] = arg
                console.info.apply ...e
*/


/*@source p0ne.fixes.ls */
/**
 * Fixes for plug.dj bugs
 * @author jtbrinkmann aka. Brinkie Pie
 * @version 1.0
 * @license MIT License
 * @copyright (c) 2014 J.-T. Brinkmann
 */


/*####################################
#                FIXES               #
####################################*/
module \simpleFixes, do
    setup: ({replace}) ->
        # hide social-menu (because personally, i only accidentally click on it. it's just badly positioned)
        @scm = $ '#twitter-menu, #facebook-menu' .detach! # not using .social-menu in case other scripts use this class to easily add buttons

        # add tab-index to chat-input
        replace $(\#chat-input-field).0, \tabIndex, -> return 1
    disable: ->
        @scm .insertAfter \#playlist-panel

module \fixMediaThumbnails, do
    require: <[ auxiliaries ]>
    help: '''
        Plug.dj changed the Soundcloud thumbnail file location several times, but never updated the paths in their song database, so many songs have broken thumbnail images.
        This module fixes this issue.
    '''
    setup: ({replace, $create}) ->
        replace auxiliaries, \deserializeMedia, -> return (e) !->
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
    optional: <[ login ]>
    settings: \fixes
    settingsMore: -> return $ '<toggle val=warnings>Show Warnings</toggle>'
    help: '''
        Plug.dj sometimes marks you internally as "not in any room" even though you still are. This is also called "ghosting" because you can chat in a room that technically you are not in anymore. While ghosting you can still chat, but not join the waitlist or moderate. If others want to @mention you, you don't show up in the autocomplete.

        tl;dr this module automatically rejoins the room when you are ghosting
    '''
    _settings:
        warnings: true
    setup: ({replace, addListener}) ->
        _settings = @_settings
        rejoining = false
        queue = []

        addListener API, \socket:userLeave, ({p}) -> if p == userID
            rejoinRoom 'you left the room'

        replace PlugAjax::, \onError, (oE_) -> return (status, data) ->
            if status == \notInRoom
                #or status == \notFound # note: notFound is only returned for valid URLs, actually requesting not existing files returns a 404 error instead; update: TOO RISKY!
                queue[*] = this
                rejoinRoom "got 'notInRoom' error from plug", true
            else
                oE_ ...

        export rejoinRoom = (reason, throttled) ->
                if rejoining and throttled
                    console.warn "[fixGhosting] You are still ghosting, retrying to connect."
                else
                    console.warn "[fixGhosting] You are ghosting!", "Reason: #reason"
                    rejoining := true
                    ajax \POST, \rooms/join, slug: getRoomSlug!, do
                        success: (data) ~>
                            if data.responseText?.0 == "<" # indicator for IP/user ban
                                if data.responseText .has "You have been permanently banned from plug.dj"
                                    # for whatever reason this responds with a status code 200
                                    API.chatLog "your account got permanently banned. RIP", true
                                else
                                    API.chatLog "[fixGhosting] cannot rejoin the room. Plug is acting weird, maybe it is in maintenance mode or you got IP banned?", true
                            else
                                API.chatLog "[fixGhosting] reconnected to the room", true if _settings.warnings
                                for req in queue
                                    req.execute! # re-attempt whatever ajax requests just failed
                                rejoining := false
                                _$context?.trigger \p0ne:reconnected
                                API.trigger \p0ne:reconnected
                        error: ({statusCode, responseJSON}:data) ~>
                            status = responseJSON?.status
                            switch status
                            | \ban =>
                                API.chatLog "you are banned from this community", true
                            | \roomCapacity =>
                                API.chatLog "the room capacity is reached :/", true
                            | \notAuthorized =>
                                API.chatLog "you got logged out", true
                                login?!
                            | otherwise =>
                                switch statusCode
                                | 401 =>
                                    API.chatLog "[fixGhosting] unexpected permission error while rejoining the room.", true
                                    #ToDo is an IP ban responding with status 401?
                                | 503 =>
                                    API.chatLog "plug.dj is in mainenance mode. nothing we can do here"
                                | 521, 522, 524 =>
                                    API.chatLog "plug.dj is currently completly down"
                                | otherwise =>
                                    API.chatLog "[fixGhosting] cannot rejoin the room, unexpected error #{statusCode} (#{datastatus})", true
                            # don't try again for the next 10min
                            sleep 10.min, ->
                                rejoining := false

module \fixOthersGhosting, do
    require: <[ users socketEvents ]>
    displayName: "Fix Other Users Ghosting"
    settings: \fixes
    settingsMore: -> return $ '<toggle val=warnings>Show Warnings</toggle>'
    help: '''
        Sometimes plug.dj does not properly emit join notifications, so that clients don't know another user joined a room. Thus they appear as "ghosts", as if they were not in the room but still can chat

        This module detects "ghost" users and force-adds them to the room.
    '''
    _settings:
        warnings: true
    setup: ({addListener, css}) ->
        addListener API, \chat, (d) ~> if d.uid and not users.get(d.uid)
            console.info "[fixOthersGhosting] seems like '#{d.un}' (#{d.uid}) is ghosting"

            #ajax \GET, "users/#{d.uid}", (status, data) ~>
            ajax \GET, "rooms/state"
                .then (data) ~>
                    # "manually" trigger socket event for DJ advance
                    for u, i in data.0.users when not users.get(u.id)
                        socketEvents.userJoin u
                        API.chatLog "[p0ne] force-joined ##i #{d.un} (#{d.uid}) to the room", true if @_settings.warnings
                    else
                        ajax \GET "users/#{d.uid}", (data) ~>
                            data.role = -1
                            socketEvents.userJoin data
                            API.chatLog "[p0ne] #{d.un} (#{d.uid}) is ghosting", true if @_settings.warnings
                .fail ->
                    console.error "[fixOthersGhosting] cannot load room data:", status, data
                    console.error "[fixOthersGhosting] cannot load user data:", status, data

module \fixStuckDJ, do
    require: <[ socketEvents ]>
    optional: <[ votes ]>
    displayName: "Fix Stuck Advance"
    settings: \fixes
    settingsMore: -> return $ '<toggle val=warnings>Show Warnings</toggle>'
    help: '''
        Sometimes plug.dj does not automatically start playing the next song. Usually you would have to reload the page to fix this bug.

        This module detects stuck advances and automatically force-loads the next song.
    '''
    _settings:
        warnings: true
    setup: ({replace, addListener}) ->
        _settings = @_settings
        fixStuckDJ = this
        @timer := sleep 5_000ms, fixStuckDJ if API.getTimeRemaining! == 0s and API.getMedia!

        addListener API, \advance, (d) ~>
            console.log "#{getTime!} [API.advance]"
            clearTimeout @timer
            if d.media
                @timer = sleep d.media.duration*1_000s_to_ms + 2_000ms, fixStuckDJ
    module: ->
        # no new song played yet (otherwise this change:media would have cancelled this)
        fixStuckDJ = this
        if showWarning = API.getTimeRemaining! == 0s
            console.warn "[fixNoAdvance] song seems to be stuck, trying to fix…"
        ajax \GET, \rooms/state, do
            error: (data) ~>
                console.error "[fixNoAdvance] cannot load room data:", status, data
                @timer := sleep 5_000ms, fixStuckDJ
            success: (data) ~>
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
                API.chatLog "[p0ne] fixed DJ not advancing", true if @_settings.warnings and showWarning

/*
module \fixNoPlaylistCycle, do
    require: <[ _$context ActivateEvent ]>
    displayName: "Fix No Playlist Cycle"
    settings: \fixes
    settingsMore: -> return $ '<toggle val=warnings>Show Warnings</toggle>'
    help: '''
        Sometimes after DJing, plug.dj does not move the played song to the bottom of the playlist.

        This module automatically detects this bug and moves the song to the bottom.
    '''
    _settings:
        warnings: true
    setup: ({addListener}) ->
        addListener API, \socket:reconnected, ->
            _$context.dispatch new LoadEvent(LoadEvent.LOAD)
            _$context.dispatch new ActivateEvent(ActivateEvent.ACTIVATE)
        / *
        # manual check
        addListener API, \advance, ({dj, lastPlay}) ~>
            #ToDo check if spelling is correctly
            #ToDo get currentPlaylist
            if dj?.id == userID and lastPlay.media.id == currentPlaylist.song.id
                #_$context .trigger \MediaMoveEvent:move
                ajax \PUT, "playlists/#{currentPlaylist.id}/media/move", ids: [lastPlay.media.id], beforeID: 0
                API.chatLog "[p0ne] fixed playlist not cycling", true if @_settings.warnings
        * /
*/



module \zalgoFix, do
    settings: \fixes
    displayName: 'Fix Zalgo Messages'
    help: '''
        This avoids messages' text bleeding out of the message, as it is the case with so called "Zalgo" messages.
        Enable this if you are dealing with spammers in the chat who use Zalgo.
    '''
    setup: ({css}) ->
        css \zalgoFix, '
            .message {
                overflow: hidden;
            }
        '

module \fixWinterThumbnails, do
    setup: ({css}) ->
        avis = [".thumb .avi-2014winter#{pad i}" for i from 1 to 10].join(', ')
        css \fixWinterThumbnails, "
            #{avis} {
                background-position-y: 0 !important;
            }
        "

module \warnOnAdblockPopoutBlock, do
    require: <[ PopoutView ]>
    setup: ({replace}) ->
        warningShown = false
        replace PopoutView, \resizeBind, (r_) -> return ->
            try
                r_ ...
            catch e
                window.e = e
                console.log "[PopoutView:resize] error", e.stack
                if not this._window and not warningShown
                    API.chatLog "[p0ne] your adblocker is preventing plug.dj from opening the popout chat. You have to make an exception for plug.dj or disable your adblocker. Adblock Plus is known for causing this", true
                    warningShown = true
                    sleep 10_000ms, ->
                        warningShown = false

module \disableIntercomTracking, do
    require: <[ tracker ]>
    disabled: true
    settings: \dev
    displayName: 'Disable Tracking'
    setup: ({replace}) ->
        for k,v of tracker when typeof v == \function
            replace tracker, k, -> return -> return $.noop
        replace tracker, \event, -> return -> return this

/*@source p0ne.base.ls */
/**
 * Base plug_p0ne modules
 * @author jtbrinkmann aka. Brinkie Pie
 * @version 1.0
 * @license MIT License
 * @copyright (c) 2014 J.-T. Brinkmann
 */


/*####################################
#           DISABLE/STATUS           #
####################################*/
module \disableCommand, do
    modules: <[ autojoin ]> # autorespond 
    setup: ({addListener}) ->
        addListener API, \chat, (data) ~>
            if data.message.has("!disable") and data.message.has("@#{user.username}") and API.hasPermission(data.uid, API.ROLE.BOUNCER)
                console.warn "[DISABLE] '#status'"
                enabledModules = []
                for m in @modules
                    if window[m] and not window[m].disabled
                        enabledModules[*] = m
                        window[m].disable!
                    else
                        disabledModules[*] = m
                response = "#{data.un} - "
                if enabledModules.length
                    response += "disabled #{humanList enabledModules}."
                if disabledModules.length
                    response += " #{humanList enabledModules} were already disabled."
                API.sendChat response

module \getStatus, do
    module: ->
        status = "Running plug_p0ne v#{p0ne.version}"
        status += " (incl. chat script)" if window.p0ne_chat
        status += "\tand plug³ v#{getPlugCubedVersion!}" if window.plugCubed
        status += "\tand plugplug #{window.getVersionShort!}" if window.ppSaved
        status += ".\tStarted #{ago p0ne.started}."
        modules = [m for m in disableCommand.modules when window[m] and not window[m].disabled]
        status += ".\t#{humanList} are enabled" if modules

module \statusCommand, do
    timeout: false
    setup: ({addListener}) ->
        addListener API, \chat, (data) ~> if not @timeout
            if data.message.has( \!status ) and data.message.has("@#{user.username}") and API.hasPermission(data.uid, API.ROLE.BOUNCER)
                @timeout = true
                status = "#{getStatus!}"
                console.info "[AUTORESPOND] status: '#status'", data.uid, data.un
                API.sendChat status, data
                sleep 30min *60_000to_ms, ->
                    @timeout = false
                    console.info "[status] timeout reset"


/*####################################
#             YELLOW MOD             #
####################################*/
module \yellowMod, do
    settings: \chat
    displayName: 'Have yellow name as mod'
    setup: ({css}) ->
        id = API.getUser! .id
        css \yellowMod, "
            \#chat .fromID-#id .un,
            .user[data-uid='#id'] .name > span {
                color: \#ffdd6f !important;
            }
        "
            # \#chat .from-#id .from,
            # \#chat .fromID-#id .from,


/*####################################
#         08/15 PLUG SCRIPTS         #
####################################*/
module \autojoin, do
    settings: \base
    disabled: true
    setup: ({addListener}) ->
        do addListener API, \advance, ->
            if join!
                console.log "#{getTime!} [autojoin] joined waitlist"




# adds a user-rollover to the FriendsList when clicking someone's name
module \friendslistUserPopup, do
    require: <[ friendsList FriendsList chat ]>
    setup: ({addListener}) ->
        addListener $(\.friends), \click, '.name, .image', (e) ->
            id = friendsList.rows[$ this.closest \.row .index!] ?.model.id
            user = users.get(id) if id
            data = x: $body.width! - 353px, y: e.screenY - 90px
            if user
                chat.onShowChatUser user, data
            else if id
                chat.getExternalUser id, data, (user) ->
                    chat.onShowChatUser user, data
        #replace friendsList, \drawBind, -> return _.bind friendsList.drawRow, friendsList
# adds a user-rollover to the FriendsList when clicking someone's name
module \waitlistUserPopup, do
    require: <[ WaitlistRow ]>
    setup: ({replace}) ->
        replace WaitlistRow::, "render", (r_) -> return ->
            r_ ...
            @$ '.name, .image' .click @clickBind

module \titleCurrentSong, do
    disable: ->
        $ \#now-playing-media .prop \title, ""
    setup: ({addListener}) ->
        addListener API, \advance, (d) ->
            if d
                $ \#now-playing-media .prop \title, "#{d.media.author} - #{d.media.title}"
            else
                $ \#now-playing-media .prop \title, null


/*####################################
#       MORE ICON IN USERLIST        #
####################################*/
module \userlistIcons, do
    require: <[ RoomUserRow ]>
    _settings:
        forceMehIcon: false
    setup: ({replace})  ->
        settings = @_settings
        replace RoomUserRow::, \vote, -> return ->
            if @model.id == API.getDJ!
                @$icon.addClass \icon-woot
            if @model.get \grab
                vote = \grab
            else
                vote = @model.get \vote
                vote = 0 if vote == -1 and (user = API.getUser!).role == user.gRole == 0
            if @model.id == API.getDJ!.id
                if vote # stupid haxxy edge-cases… well to be fair, I don't see many other people but me abuse that >3>
                    if not @$djIcon
                        @$djIcon = $ '<i class="icon icon-current-dj" style="right: 35px">'
                            .appendTo @$el
                        API.once \advance, ~>
                            @$djIcon .remove!
                            delete @$djIcon
                else
                    vote = \dj
            if vote != 0
                @$icon ||= $ \<i>
                @$icon
                    .removeClass!
                    .addClass \icon
                    .appendTo @$el

                if vote == -1 and API.getUser!.role > 0 or settings.forceMehIcon
                    # i think RDJs should be able to see mehs as well
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



/*####################################
#        DBLCLICK to @MENTION        #
####################################*/
module \chatDblclick2Mention, do
    require: <[ chat ]>
    #optional: <[ PopoutListener ]>
    settings: \chat
    displayName: 'DblClick username to Mention'
    setup: ({replace, addListener}) ->
        module = this
        newFromClick = (e) ->
            if not module.timer # single click
                module.timer = sleep 200ms, ~> if module.timer
                    try
                        module.timer = 0
                        $this = $ this
                        if r = ($this .closest \.cm .children \.badge-box .data \uid) || (i = getUserInternal $this.text!).id
                            pos =
                                x: chat.getPosX!
                                y: $this .offset!.top
                            if i = getUserInternal(r)
                                chat.onShowChatUser i, pos
                            else
                                chat.getExternalUser r, pos, chat.showChatUserBind
                        else
                            console.warn "[DblCLick username to Mention] couldn't get userID", this
                    catch err
                        console.error err.stack
            else # double click
                clearTimeout module.timer
                module.timer = 0
                chat.onInputMention e.target.textContent
            e .stopPropagation!; e .preventDefault!

        replace chat, \fromClick, (@fC_) ~> return newFromClick
        replace chat, \fromClickBind, -> return newFromClick

        # patch event listeners on old messages
        $cm! .find \.un
            .off \click, @fC_
            .on \click, newFromClick

        addListener chatDomEvents, \click, \.un, newFromClick
    disable: -> if @fC_
        cm = $cm!
        cm  .find \.un
            .off \click, newFromClick
        cm  .find '.mention .un, .message .un' # note: here we actually have to pay attention as to what to re-enable
            .on \click, @fC_


/*####################################
#           CHAT COMMANDS            #
####################################*/
module \chatCommands, do
    optional: <[ currentMedia ]>
    setup: ({addListener}) ->
        addListener API, \chatCommand, (c) ~>
            @_commands[/^\/(\w+)/.exec(c)?.1]?(c)
        @updateCommands!

    updateCommands: ->
        @_commands = {}
        for k,v of @commands
            @_commands[k] = v.callback
            for k in v.aliases ||[]
                @_commands[k] = v.callback
    commands:
        help:
            aliases: <[ commands ]>
            description: "show this list of commands"
            callback: ->
                res = ""
                for k,command of chatCommands.commands
                    if command.aliases?.length
                        aliases = "aliases: #{humanList command.aliases}"
                    else
                        aliases = ''
                    res += "<div class='p0ne-help-command' alt='#aliases'><b>/#k</b> #{command.params ||''} - #{command.description}</div>"
                appendChat($ "<div class=p0ne-help>" .html res)
        available:
            aliases: <[ avail ]>
            description: "change your status to <b>available</b>"
            callback: ->
                API.setStatus 0

        away:
            aliases: <[ afk ]>
            description: "change your status to <b>away</b>"
            callback: ->
                API.setStatus 1

        busy:
            aliases: <[ work working ]>
            description: "change your status to <b>busy</b>"
            callback:  ->
                API.setStatus 2

        gaming:
            aliases: <[ game ingame ]>
            description: "change your status to <b>gaming</b>"
            callback:  ->
                API.setStatus 3

        join:
            description: "join the waitlist"
            callback: join
        leave:
            description: "leave the waitlist"
            callback: leave

        stream:
            parameters: " [on|off]"
            description: "enable/disable the stream (just '/stream' toggles it)"
            callback: ->
                if currentMedia?
                    stream c.has \on || not (c.has \off || \toggle)
                else
                    API.chatLog "couldn't load required module for enabling/disabling the stream.", true

        snooze:
            description: "snoozes the current song"
            callback: snooze
        mute:
            description: "mutes the audio"
            callback: mute
        unmute:
            description: "unmutes the audio"
            callback: unmute

        muteonce:
            aliases: <[ muteonce ]>
            description: "mutes the current song"
            callback: muteonce

        automute:
            description: "adds/removes this song from the automute list"
            callback:  ->
                muteonce!
                if automute?
                    automute!
                else
                    API.chatLog "automute is not yet implemented", true

/*####################################
#              AUTOMUTE              #
####################################*/
module \automute, do
    songlist: dataLoad \p0ne_automute, {}
    module: (media) ->
        media ||= API.getMedia!
        if @songlist[media.id]
            delete @songlist[media.id]
            API.chat "'#{media.author} - #{media.title}' removed from the automute list."
        else
            @songlist[media.id] = true
            API.chat "'#{media.author} - #{media.title}' added to automute list."
    setup: ({addListener}) ->
        addListener API, \advance, ({media}) ~>
            if media and @songlist[media.id]
                muteonce!



/*####################################
#      JOIN/LEAVE NOTIFICATION       #
####################################*/
module \joinLeaveNotif, do
    optional: <[ chatDomEvents chat auxiliaries database ]>
    settings: \base
    displayName: 'Join/Leave Notifications'
    help: '''
        Shows notifications for when users join/leave the room in the chat.
    '''
    setup: ({addListener, css},,,update) ->
        if update
            lastMsg = $cm! .children! .last!
            if lastMsg .hasClass \p0ne-joinLeave-notif
                $lastNotif = lastMsg

        verbRefreshed = 'refreshed'
        usersInRoom = {}
        for let event, verb_ of {userJoin: 'joined', userLeave: 'left'}
            addListener API, event, (user) ->
                verb = verb_
                if event == \userJoin
                    if usersInRoom[user.id]
                        verb = verbRefreshed
                    else
                        usersInRoom[user.id] = Date.now!
                else
                    delete usersInRoom[user.id]


                $msg = $ "
                    <span data-uid=#{user.id}>
                        #{if event == \userJoin then '+ ' else '- '}
                        <span class=un>#{resolveRTL user.username}</span> #verb the room
                        #{if not (auxiliaries? and database?) then '' else
                            '<div class=timestamp>' + auxiliaries.getChatTimestamp(database.settings.chatTS == 24) + '</div>'
                        }
                    </span>
                    "
                if false #chat?.lastType == \joinLeave
                    $lastNotif .append $msg
                else
                    $lastNotif := $ "<div class='cm update p0ne-joinLeave-notif'></div>"
                        .append $msg
                    appendChat $lastNotif
                    if chat?
                        $lastNotif .= find \.message
                        chat.lastType = \joinLeave
        if chat? and chatDomEvents?
            addListener chatDomEvents, \click, '.p0ne-join-notif, .p0ne-leave-notif', (e) ->
                chat.fromClick e

        if not update
            d = Date.now!
            for user in API.getUsers!
                usersInRoom[user.id] = -1





/*@source p0ne.chat.ls */
/*@author jtbrinkmann aka. Brinkie Pie */
/*@license https://creativecommons.org/licenses/by-nc/4.0/ */

/*
 * missing chat inline image plugins:
 * Derpibooru
 * imgur.com/a/
 * tumblr
 * deviantart
 * e621.net
 * paheal.net
 * gfycat.com
 * cloud-4.steampowered.com … .resizedimage
 */


CHAT_WIDTH = 328px
MAX_IMAGE_HEIGHT = 300px # should be kept in sync with p0ne.css
roles = <[ none dj bouncer manager cohost host ambassador ambassador ambassador admin ]>



/*####################################
#      UNREAD CHAT NOTIFICAITON      #
####################################*/
module \unreadChatNotif, do
    require: <[ _$context chatDomEvents ]>
    bottomMsg: $!
    settings: \chat
    displayName: 'Mark Unread Chat'
    setup: ({addListener}) ->
        $chatButton = $ \#chat-button
        @bottomMsg = $cm! .children! .last!
        addListener \early, _$context, \chat:receive, (message) ->
            message.wasAtBottom ?= chatIsAtBottom!
            if not $chatButton.hasClass \selected
                $chatButton.addClass \has-unread
            else if message.wasAtBottom
                @bottomMsg = message.cid
                return

            delete @bottomMsg
            $cm! .addClass \has-unread
            message.unread = true
            message.addClass \unread
        @throttled = false
        addListener chatDomEvents, \scroll, updateUnread
        addListener $chatButton, \click, updateUnread
        ~function updateUnread
            return if @throttled
            @throttled := true
            sleep 200ms, ~>
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
                        sleep 1_500ms, ~>
                            $readMsgs.removeClass \unread
                            if (unread .= filter \.unread) .length
                                @bottomMsg = unread .removeClass \unread .last!
                    if not msg.length
                        cm .removeClass \has-unread
                        $chatButton .removeClass \has-unread
                @throttled := false
    fix: ->
        @throttled = false
        cm = $cm!
        cm
            .removeClass \has-unread
            .find \.unread .removeClass \unread
        @bottomMsg = cm.children!.last!
    disable: ->
        $cm!
            .removeClass \has-unread
            .find \.unread .removeClass \unread





/*####################################
#         BETTER CHAT INPUT          #
####################################*/
module \p0neChatInput, do
    require: <[ chat user ]>
    optional: <[ user_ _$context PopoutListener Lang ]>
    displayName: "Better Chat Input"
    settings: \chat
    help: '''
        Replaces the default chat input field with a multiline textfield.
        This allows you to more accurately see how your message will actually look when send
    '''
    setup: ({addListener, css, $create}) ->
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
            #chat-input-field:focus {
                box-shadow: inset 0 0 0 1px #009cdd !important;
            }
            .muted .chat-input-name {
                display: none;
            }

            .autoresize_helper {
                display: none;
                white-space: pre-wrap;
                word-wrap: break-word;
            }

            #chat-input-field, .autoresize_helper {
                width: 295px;
                padding: 8px 10px 5px 10px;
                min-height: 16px;
                font-weight: 400;
                font-size: 12px;
                font-family: Roboto,sans-serif;
            }
            .chat-input-name {
                position: absolute;
                top: 8px;
                left: 18px;
                font-weight: 700;
                font-size: 12px;
                font-family: Roboto,sans-serif;
                color: #666;
                transition: color .2s ease-out;
                pointer-events:none;
            }
            #chat-input-field:focus + .chat-input-name {
                color: #ffdd6f !important;
            }
            /*fix chat-messages size*/
            #chat-messages {
                height: auto !important;
                bottom: 45px;
            }
        '

        var $name, $autoresize_helper, chat
        chat = PopoutView.chat || window.chat

        # back up elements that are to be removed
        @cIF_ = chat.$chatInputField.0


        # fix permanent focus class
        chat.$chatInput .removeClass \focused
        val = chat.$chatInputField .val!

        # use $name's width to add proper indent to the input field
        @fixIndent = -> requestAnimationFrame -> # wait an animation frame so $name is properly added to the DOM
            indent = 6px + $name.width!
            chat.$chatInputField .css textIndent: indent
            $autoresize_helper   .css textIndent: indent

        # add new input text-area
        oldHeight = 0
        do addListener API, \popout:open, ~>
            chat := PopoutView.chat || window.chat
            @$form = chat.$chatInputField.parent!

            chat.$chatInputField .detach!
            oldHeight := chat.$chatInputField .height!
            chat.$chatInputField.0 = chat.chatInput = $create "<textarea id='chat-input-field' maxlength=256>"
                .attr \tabIndex, 1
                .val val
                .attr \placeholder, Lang?.chat.placeholder
                # add DOM event Listeners from original input field (not using .bind to allow custom chat.onKey* functions)
                .on \keydown, (e) ->
                    chat.onKeyDown e
                .on \keyup, (e) ->
                    chat.onKeyUp e
                #.on \focus, _.bind(chat.onFocus, chat)
                #.on \blur, _.bind(chat.onBlur, chat)

                # add event listeners for autoresizing
                .on 'input', onInput
                .appendTo @$form
                .after do
                    $autoresize_helper := $create \<div> .addClass \autoresize_helper
                .0

            # username field
            $name := $create \<span>
                .addClass \chat-input-name
                .text "#{user.username} "
                .insertAfter chat.$chatInputField

            @fixIndent!

        sleep 2_000ms, @fixIndent

        chatHidden = $cm!.parent!.css(\display) == \none
        if _$context
            addListener _$context, \chat:send, -> requestAnimationFrame ->
                chat.$chatInputField .trigger \input
            if chatHidden
                _$context.once \show:chat, @fixIndent
        else if chatHidden
            $ \#chat-button .one \click, @fixIndent

        if user_?
            addListener user_, \change:username, @fixIndent


        function onInput
            content = chat.$chatInputField .val!
            if (content2 = content.replace(/\n/g, "")) != content
                chat.$chatInputField .val (content=content2)
            $autoresize_helper.text("#content")
            newHeight = $autoresize_helper .height!
            return if oldHeight == newHeight
            console.log "[chat input] adjusting height"
            scrollTop = chat.$chatMessages.scrollTop!
            chat.$chatInputField
                .css height: newHeight
            chat.$chatMessages
                .css bottom: newHeight + 30px
                .scrollTop scrollTop + newHeight - oldHeight
            oldHeight := newHeight


    disable: ->
        if @cIF_
            chat.$chatInputField = $ (chat.chatInput = @cIF_)
                .val chat.$chatInputField.val!
                .appendTo @$form



module \chatPlugin, do
    require: <[ _$context ]>
    setup: ({addListener}) ->
        p0ne.chatLinkPlugins ||= []
        addListener \early, _$context, \chat:receive, (msg) -> # run plugins that modify chat msgs
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
                            return that if plugin.callback.call plugin.ctx, {all,pre,completeURL,protocol,domain,url, offset,  onload,msg}
                        catch err
                            console.error "[p0ne] error while processing chat link plugin", plugin, err.stack
                return all

        addListener _$context, \chat:receive, (e) ->
            getChat(e.cid) .addClass Object.keys(e.classes).join(' ')

        function addClass classes
            if typeof classes == \string
                for className in classes.split /\s+/g when className
                    @classes[className] = true
        function removeClass classes
            if typeof classes == \string
                for className in classes.split /\s+/g
                    delete @classes[className]
    imgError: (elem) ->
        console.warn "[inline-img] converting image back to link", elem.alt, elem, elem.outerHTML
        $ elem .parent!
            ..text ..attr \href
            ..addClass \p0ne_img_failed


/*####################################
#           MESSAGE CLASSES          #
####################################*/
module \chatMessageClasses, do
    optional: <[ users ]>
    require: <[ chatPlugin ]>
    setup: ({addListener}) ->
        try
            $cm! .children! .each ->
                if uid = this.dataset.cid
                    uid .= substr(0, 7)
                    return if not uid
                    $this = $ this
                    if fromUser = users.get uid
                        role = getRank(fromUser)
                        if role != -1
                            fromRole = "from-#{roles[role]}"
                            if role == 0
                                fromRole += " from"
                                # stupid p3. who would abuse the class `from` instead of using something sensible instead?!
                            else
                                fromRole += " from-staff"
                    if not fromRole
                        for r in ($this .find \.icon .prop(\className) ||"").split " " when r.startsWith \icon-chat-
                            fromRole = "from-#{r.substr 10}"
                        else
                            fromRole = \from-none
                    $this .addClass "fromID-#{uid} #fromRole"
        catch err
            console.error "[chatMessageClasses] couldn't convert old messages", err.stack

        addListener (window._$context || API), \chat:plugin, ({type, uid}:message) -> if uid
            message.user = user = getUser(uid)
            message.addClass "fromID-#{uid}"
            message.addClass "from-#{getRank user}"
            message.addClass \from-staff if user?.role > 1

/*####################################
#          OTHERS' @MENTIONS         #
####################################*/
module \chatOthersMentions, do
    optional: <[ users ]>
    require: <[ chatPlugin ]>
    settings: \chat
    displayName: 'Highlight @mentions for others'
    setup: ({addListener}) ->
        sleep 0, ->
            $cm! .children! .each ->

        addListener _$context, \chat:plugin, ({type, uid}:message) -> if uid
            res = ""; lastI = 0
            for mention in getMentions(message, true) when mention.id != userID or type == \mention
                res += "
                    #{message.message .substring(lastI, mention.offset)}
                    <span class='mention-other mentionID-#{mention.id} mention-#{getRank(mention)} #{if! (mention.role||mention.gRole) then '' else \mention-staff}'>
                        @#{mention.username}
                    </span>
                "
                lastI = mention.offset + 1 + mention.username.length
            else
                return

            message.message = res + message.message.substr(lastI)

/*####################################
#           INLINE  IMAGES           #
#             YT PREVIEW             #
####################################*/
CHAT_WIDTH = 500px
module \chatInlineImages, do
    require: <[ chatPlugin ]>
    settings: \chat
    displayName: 'Inline Images'
    help: '''
        Converts image links to images in the chat, so you can see a preview
    '''
    setup: ({addListener}) ->
        addListener API, \chat:image, ({all,pre,completeURL,protocol,domain,url, onload, msg, offset}) ~>
            return if msg.message.hasAny <[ nsfw no-inline noinline ]> or msg.message[offset + all.length] == ";"
            # images
            if @plugins[domain] || @plugins[domain .= substr(1 + domain.indexOf(\.))]
                [rgx, repl, forceProtocol] = that
                img = url.replace(rgx, repl)
                if img != url
                    console.log "[inline-img]", "#completeURL ==> #protocol#img"
                    return "<a #pre><img src='#{forceProtocol||protocol}#img' class=p0ne_img #onload onerror='chatInlineImages.imgError(this)'></a>"

            # direct images (the revision suffix is required for some blogspot images; e.g. http://vignette2.wikia.nocookie.net/moth-ponies/images/d/d4/MOTHPONIORIGIN.png/revision/latest?cb=20131206071408)
            #   <URL stuff><        image suffix           >< image.php>< hires ><  revision suffix >< query/hash >
            if /^[^\#\?]+(?:\.(?:jpg|jpeg|gif|png|webp|apng)|image\.php)(?:@\dx)?(?:\/revision\/\w+)?(?:\?.*|\#.*)?$/i .test url
                if domain in @forceHTTPSDomains
                    completeURL .= replace /^.+\/\//, 'https://'
                console.log "[inline-img]", "[direct] #completeURL"
                return "<a #pre><img src='#completeURL' class=p0ne_img #onload onerror='chatInlineImages.imgError(this)'></a>"

            console.log "[inline-img]", "NO MATCH FOR #completeURL (probably isn't an image)"
            return false

    forceHTTPSDomains: <[ i.imgur.com ]>
    plugins:
        \imgur.com :       [/^imgur.com\/(?:r\/\w+\/)?(\w\w\w+)/g, "i.imgur.com/$1.gif"]
        \prntscrn.com :    [/^(prntscr.com\/\w+)(?:\/direct\/)?/g, "$1/direct"]
        \gyazo.com :       [/^gyazo.com\/\w+/g, "i.$&/direct"]
        \dropbox.com :     [/^dropbox.com(\/s\/[a-z0-9]*?\/[^\/\?#]*\.(?:jpg|jpeg|gif|png|webp|apng))/g, "dl.dropboxusercontent.com$1"]
        \pbs.twitter.com : [/^(pbs.twimg.com\/media\/\w+\.(?:jpg|jpeg|gif|png|webp|apng))(?:\:large|\:small)?/g, "$1:small"]
        \googleimg.com :   [/^google\.com\/imgres\?imgurl=(.+?)(?:&|$)/g, (,src) -> return decodeURIComponent url]
        \imageshack.com :  [/^imageshack\.com\/[fi]\/(\w\w)(\w+?)(\w)(?:\W|$)/, -> chatInlineImages.imageshackPlugin ...]
        \imageshack.us :   [/^imageshack\.us\/[fi]\/(\w\w)(\w+?)(\w)(?:\W|$)/, -> chatInlineImages.imageshackPlugin ...]

        /* meme-plugins based on http://userscripts.org/scripts/show/154915.html (mirror: http://userscripts-mirror.org/scripts/show/154915.html ) */
        \quickmeme.com :     [/^(?:m\.)?quickmeme\.com\/meme\/(\w+)/, "i.qkme.me/$1.jpg"]
        \qkme.me :           [/^(?:m\.)?qkme\.me\/(\w+)/, "i.qkme.me/$1.jpg"]
        \memegenerator.net : [/^memegenerator\.net\/instance\/(\d+)/, "http://cdn.memegenerator.net/instances/#{CHAT_WIDTH}x/$1.jpg"]
        \imageflip.com :     [/^imgflip.com\/i\/(.+)/, "i.imgflip.com/$1.jpg"]
        \livememe.com :      [/^livememe.com\/(\w+)/, "i.lvme.me/$1.jpg"]
        \memedad.com :       [/^memedad.com\/meme\/(\d+)/, "memedad.com/memes/$1.jpg"]
        \makeameme.org :     [/^makeameme.org\/meme\/(.+)/, "makeameme.org/media/created/$1.jpg"]

    imageshackPlugin: (,host,img,ext) ->
        ext = {j: \jpg, p: \png, g: \gif, b: \bmp, t: \tiff}[ext]
        return "https://imagizer.imageshack.us/a/img#{parseInt(host,36)}/1337/#img.#ext"

    pluginsAsync:
        \deviantart.com
        \fav.me
        \sta.sh
    deviantartPlugin: (replaceLink, url) ->
        $.getJSON "http://backend.deviantart.com/oembed?format=json&url=#url", (d) ->
            if d.height <= MAX_IMAGE_HEIGHT
                replaceLink d.url
            else
                replaceLink d.thumbnail_url

module \imageLightbox, do
    require: <[ chatInlineImages chatDomEvents ]>
    setup: ({addListener, $createPersistent}) ->
        var $img
        PADDING = 20px
        $app = $ \#app #TEMP
        $container = $ \#dialog-container
        var lastSrc
        @$el = $el = $createPersistent '<img class=p0ne_img_large>' .appendTo $body
            .css do #TEMP
                position: \absolute
                zIndex: 6
                cursor: \pointer
            .hide!
        addListener $container, \click, \.p0ne_img_large, ->
            dialog.close!
            return false

        @dialog = dialog =
            on: (,,@container) ->
            off: $.noop
            containerOnClose: $.noop
            destroy: $.noop

            $el: $el

            render: ->
                # calculating image size
                $el .css do
                    width: \auto
                    height: \auto
                <- requestAnimationFrame
                offset = $img.offset!
                appW = $app.width!
                appH = $app.height!
                w = $el.width!
                h = $el.height!
                ratio = 1   <?   (appW - 345px - PADDING) / w   <?   (appH - PADDING) / h
                w *= ratio
                h *= ratio
                console.log "[lightbox] rendering", {w, h, oW: $el.css(\width), oH: $el.css(\height), ratio}
                $el
                    .show!
                    .css do
                        left: offset.left
                        top: offset.top
                        width: $img.width!
                        height: $img.height!
                    .animate do
                        left: ($app.width! - w - 345px) / 2
                        top: ($app.height! - h) / 2
                        width: w
                        height: h
                $img.css visibility: \hidden

            close: (cb) ->
                $img_ = $img
                $el_ = $el
                @isOpen = false
                offset = $img.offset!
                $el.animate do
                    left: offset.left
                    top: offset.top
                    width: $img.width!
                    height: $img.height!
                    ~>
                        $img_.css visibility: \visible
                        $el_.hide!
                        @container.onClose!
                        cb?!
        dialog.closeBind = dialog~close

        addListener chatDomEvents, \click, \.p0ne_img, (e) ->
            console.info "[lightbox] showing", this, this.src
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
                    $el .0 .onload = ->
                        _$context .trigger \ShowDialogEvent:show, {dialog}, true
                    $el .attr \src, src
                else
                    _$context .trigger \ShowDialogEvent:show, {dialog}, true
    disable: ->
        if @dialog.isOpen
            <~ @dialog.close
            @$el .remove!
        else
            @$el .remove!

# /* image plugins using plugCubed API (credits go to TATDK / plugCubed) */
# module \chatInlineImages_plugCubedAPI, do
#    require: <[ chatInlineImages ]>
#    setup: ->
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
    setup: ({add, addListener}) ->
        addListener chatDomEvents, \mouseenter, \.p0ne_yt_img, (e) ~>
            clearInterval @interval
            img = this
            id = this.parentElement

            if id != @lastID
                @frame = 1
                @lastID = id
            img.style.backgroundImage = "url(http://i.ytimg.com/vi/#id/#{@frame}.jpg)"
            @interval = repeat 1_000ms, ~>
                console.log "[p0ne_yt_preview]", "showing 'http://i.ytimg.com/vi/#id/#{@frame}.jpg'"
                @frame = (@frame % 3) + 1
                img.style.backgroundImage = "url(http://i.ytimg.com/vi/#id/#{@frame}.jpg)"
            console.log "[p0ne_yt_preview]", "started", e, id, @interval
            #ToDo show YT-options (grab, open, preview, [automute])

        addListener chatDomEvents, \mouseleave, \.p0ne_yt_img, (e) ~>
            clearInterval @interval
            img = this
            id = this.parentElement.dataset.ytCid
            img.style.backgroundImage = "url(http://i.ytimg.com/vi/#id/0.jpg)"
            console.log "[p0ne_yt_preview]", "stopped"
            #ToDo hide YT-options

        addListener API, \chat:image, ({pre, url, onload}) ->
        yt = YT_REGEX .exec(url)
        if yt and (yt = yt.1)
            console.log "[inline-img]", "[YouTube #yt] #url ==> http://i.ytimg.com/vi/#yt/0.jpg"
            return "
                <a class=p0ne_yt data-yt-cid='#yt' #pre>
                    <div class=p0ne_yt_icon></div>
                    <div class=p0ne_yt_img #onload style='background-image:url(http://i.ytimg.com/vi/#yt/0.jpg)'></div>
                    #url
                </a>
            " # no `onerror` on purpose # when updating the HTML, check if it breaks the animation callback
            # default.jpg for smaller thumbnail; 0.jpg for big thumbnail; 1.jpg, 2.jpg, 3.jpg for previews
        return false
    interval: -1
    frame: 1
    lastID: ''
*/

/*@source p0ne.look-and-feel.ls */
/**
 * plug_p0ne modules to add styles.
 * This needs to be kept in sync with plug_pony.css
 * @author jtbrinkmann aka. Brinkie Pie
 * @version 1.0
 * @license MIT License
 * @copyright (c) 2014 J.-T. Brinkmann
 */


module \p0neStylesheet, do
    setup: ({loadStyle}) ->
        loadStyle "#{p0ne.host}/css/plug_p0ne.css?r=35"

/*
window.moduleStyle = (name, d) ->
    options =
        settings: true
        module: -> @toggle!
    if typeof d == \string
        if isURL(d) # load external CSS
            options.setup = ({loadStyle}) ->
                loadStyle d
        else if d.0 == "." # toggle class
            options.setup = ->
                $body .addClass d
            options.disable = ->
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
    setup: ({loadStyle}) ->
        loadStyle "#{p0ne.host}/css/fimplug.css?r=19"

/*####################################
#          ANIMATED DIALOGS          #
####################################*/
module \animatedUI, do
    require: <[ DialogAlert ]>
    setup: ({replace}) ->
        $ \.dialog .addClass \opaque
        # animate dialogs
        Dialog = DialogAlert.__super__

        replace Dialog, \render, -> return ->
            @show!
            sleep 0ms, ~> @$el.addClass \opaque
            return this

        replace Dialog, \close, (close_) -> return ->
            @$el.removeClass \opaque
            sleep 200ms, ~> close_.call this
            return this


/*####################################
#         PLAYLIST ICON VIEW         #
####################################*/
# fix drag'n'drop styles for playlist icon view
module \playlistIconView, do
    displayName: "Playlist Icon View"
    settings: \look&feel
    help: '''
        Shows songs in the playlist and history panel in an icon view instead of the default list view.
    '''
    setup: ({addListener, replace, $create}, playlistIconView) ->
        $body .addClass \playlist-icon-view
        $hovered = $!
        $mediaPanel = $ \#media-panel
        addListener $mediaPanel , \mouseover, \.row, ->
            $hovered := $ this
            $hovered.removeClass \hover
            $hovered.addClass \hover if not $hovered.hasClass \selected
        addListener $mediaPanel, \mouseout, \.hover, ->
            $hovered.removeClass \hover

        /*replace MediaPanel::, \show, (s_) -> return ->
            s_ ...
            @header.$el .append do
                $create '<div class="button playlist-view-button"><i class="icon icon-playlist"></i></div>'
                    .on \click, playlistIconView
        */

        # usually, when you drag a song (row) plug checks whether you drag it BELOW or ABOVE the currently hovered row
        # however with icons, we would rather want to move them LEFT or RIGHT of the hovered song (icon)
        # sadly the easiest way that's not TOO haxy requires us to redefine the whole function just to change two words
        # also some lines are commented out, because the vanilla $dragRowLine is not used anymore, we use a pure CSS solution
        replace PlaylistItemRow::, \onDragUpdate, -> return (e) ->
            @@@__super__.onDragUpdate .call this, e
            #t = @$el.offset!.top
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
                        #r = s - t + n + @currentDragRow.$el.height!
                        @targetDropIndex =
                            if i === @lastClickedIndex - 1
                                @lastClickedIndex
                            else
                                @targetDropIndex = i + 1
                    else
                        @$el .removeClass \p0ne-drop-right
                        #r = s - t + n
                        @targetDropIndex =
                            if i === @lastClickedIndex + 1
                                @lastClickedIndex
                            else
                                @targetDropIndex = i
                    #@$dragRowLine.css \top, r
                else if i === 0
                    #r = @currentDragRow.$el.offset!.top - t + n + @currentDragRow.$el.height!
                    @targetDropIndex = 1
                    #@$dragRowLine.css \top, r

            o = @onCheckListScroll!
            /*
            if @withinBounds
                if o > -10 and (not @lockFirstItem || i > 0)
                    @$dragRowLine.css \top, o
                @$dragRowLine.show!
            else
                @$dragRowLine.hide!
            */

    disable: ->
        $body .removeClass \playlist-icon-view


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
    setup: ({addListener}) ->
        #== add video thumbnail to #playback ==
        $playbackImg = $ \#playback-container
        addListener API, \advance, updatePic
        updatePic media: API.getMedia!
        function updatePic d
            if not d.media
                console.log "[Video Placeholder Image] hide", d
                $playbackImg .css backgroundColor: \transparent, backgroundImage: \none
            else if d.media.format == 1  # YouTube
                console.log "[Video Placeholder Image] https://i.ytimg.com/vi/#{d.media.cid}/0.jpg", d
                $playbackImg .css backgroundColor: \#000, backgroundImage: "url(https://i.ytimg.com/vi/#{d.media.cid}/0.jpg)"
            else # SoundCloud
                console.log "[Video Placeholder Image] #{d.media.image}", d
                $playbackImg .css backgroundColor: \#000, backgroundImage: "url(#{d.media.image})"
    disable: ->
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
    setup: ({addListener}) ->
        $body .addClass \legacy-chat
        $cb = $ \#chat-button
        addListener $cb, \dblclick, (e) ~>
            @toggle!
            e.preventDefault!
        addListener chatDomEvents, \dblclick, '.popout .icon-chat', (e) ~>
            @toggle!
            e.preventDefault!
    disable: ->
        $body .removeClass \legacy-chat


module \djIconChat, do
    require: <[ chatPlugin ]>
    settings: \look&feel
    displayName: "Current-DJ-icon in Chat"
    setup: ({addListener, css}) ->
        icon = getIcon \icon-current-dj
        css \djIconChat, "
            \#chat .from-current-dj .un::before {
                background-image: #{icon.image};
                background-position: #{icon.position};
            }
        "
        addListener _$context, \chat:plugin, (message) ->
            if message.uid and message.uid == API.getDJ!?.id
                message.addClass \from-current-dj

module \censor, do
    displayName: "Censor"
    settings: \dev
    help: '''
        blurs some information like playlist names, counts, EP and Plug Notes.
        Great for taking screenshots
    '''
    disabled: true
    setup: ({css}) ->
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
    disable: ->
        $body .removeClass \censored

/*@source p0ne.room-theme.ls */
/**
 * Room Settings module for plug_p0ne
 * made to be compatible with plugCubes Room Settings
 * so room hosts don't have to bother with mutliple formats
 * that also means, that a lot of inspiration came from and credits go to the PlugCubed team ♥
 * @author jtbrinkmann aka. Brinkie Pie
 * @license MIT License
 * @copyright (c) 2014 J.-T. Brinkmann
*/

module \roomSettings, do
    require: <[ room ]>
    optional: <[ _$context ]>
    persistent: <[ _data _room ]>
    setup: ({addListener}) ->
        @_update!
        if _$context?
            addListener _$context, \room:joining, @~_clear
            addListener _$context, \room:joined, @~_update
    _update: ->
        @_listeners = []

        roomslug = getRoomSlug!
        return if @_data and roomslug == @_room

        if not roomDescription = room.get \description #$ '#room-info .description .value' .text!
            console.warn "[p0ne] no p³ compatible Room Settings found"
        else if url = /@p3=(.*)/i .exec roomDescription
            console.log "[p0ne] p³ compatible Room Settings found", url.1
            $.getJSON proxify(url.1)
                .then (@_data) ~>
                    console.log "#{getTime!} [p0ne] loaded p³ compatible Room Settings"
                    @_room = roomslug
                    @_trigger!
                .fail ->
                    API.chatLog "[p0ne] cannot load Room Settings", true
    _trigger: ->
        for fn in @_listeners
            fn @_data
    _clear: ->
        @_data = null
        @_trigger
    on: (,fn) ->
        @_listeners[*] = fn
        if @_data
            fn @_data
    off: (,fn) ->
        if -1 != (i = @_listeners .indexOf fn)
            @_listeners .splice i, 1
            return true
        else
            return false

module \roomTheme, do
    displayName: "Room Theme"
    require: <[ roomSettings ]>
    optional: <[ roomLoader ]>
    settings: \look&feel
    help: '''
        Applies the room theme, if this room has one.
        Room Settings and thus a Room Theme can be added by (co-) hosts of the room.
    '''
    setup: ({addListener, replace, css, loadStyle}) ->
        roles = <[ residentdj bouncer manager cohost host ambassador admin ]> #TODO
        @$playbackBackground = $ '#playback .background img'
        @playbackBackgroundVanilla = @$playbackBackground .attr(\src)

        console.log "#{getTime!} [roomTheme] initializing"
        addListener roomSettings, \loaded, (d) ~>
            console.log "#{getTime!} [roomTheme] loading theme"
            return if not d or @currentRoom == (roomslug = getRoomSlug!)
            @currentRoom = roomslug
            @clear!
            styles = ""

            /*== colors ==*/
            if d.colors
                styles += "\n/*== colors ==*/\n"
                for role, color of d.colors.chat when /*role in roles and*/ isColor(color)
                    styles += """
                    /* #role => #color */
                    \#user-panel:not(.is-none) .user > .icon-chat-#role + .name, \#user-lists .user > .icon-chat-#role + .name, .cm.from-#role .from
                    \#waitlist .icon-chat-#role + span, \#user-rollover .icon-chat-cohost + span {
                            color: #color !important;
                    }\n"""
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
                        ..onload = ~>
                            @$playbackBackground .attr \src, d.images.playback
                            replace roomLoader, \frameHeight,   -> return ..height - 10px
                            replace roomLoader, \frameWidth,    -> return ..width  - 18px
                            roomLoader.onVideoResize Layout.getSize!
                            console.log "#{getTime!} [roomTheme] loaded playback frame"
                        ..onerror = ->
                            console.error "#{getTime!} [roomTheme] failed to load playback frame"
                        ..src = d.images.playback
                    replace roomLoader, \src, -> return d.images.playback
                if isURL(d.images.booth)
                    styles += """
                        /* custom booth */
                        \#avatars-container::before {
                            background-image: url(#{d.images.booth});
                        }\n"""
                for role, url of d.images.icons when role in roles
                    styles += """
                        .icon-chat-#role {
                            background-image: url(#url);
                            background-position: 0 0;
                        }\n"""

            /*== text ==*/
            if d.text
                for key, text of d.text.plugDJ
                    for lang of Lang[key]
                        replace Lang[key], lang, -> return text

            css \roomTheme, styles
            @styles = styles

    clear: (skipDisables) ->
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
        @$playbackBackground
            .one \load ->
                roomLoader?.onVideoResize Layout.getSize! if Layout?
            .attr \src, @playbackBackgroundVanilla

    disable: -> @clear true


/*@source p0ne.bpm.ls */
/**
 * BetterPonymotes - a script add ponymotes to the chat on plug.dj
 * based on BetterPonymotes https://ponymotes.net/bpm/
 * for a ponymote tutorial see: http://www.reddit.com/r/mylittlepony/comments/177z8f/how_to_use_default_emotes_like_a_pro_works_for/
 * @author jtbrinkmann aka. Brinkie Pie
 * @version 1.0
 * @license MIT License
 * @copyright (c) 2014 J.-T. Brinkmann
 */
do ->
    window.bpm?.disable!
    window.emote_map ||= {}
    host = window.p0ne?.host or "https://cdn.p0ne.com"

    /*== external sources ==*/
    $.getScript "#host/script/bpm-resources.js" .then ->
        API .trigger \p0ne_emotes_map

    $ \body .append "
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
    emote_regexp = /\[\]\(\/([\w:!#\/\-]+)\s*(?:["']([^"]*)["'])?\)/g


    /*== auxiliaries ==*/
    /*
     * Escapes an emote name (or similar) to match the CSS classes.
     *
     * Must be kept in sync with other copies, and the Python code.
     */
    sanitize_emote = (s) ->
        return s.toLowerCase!.replace("!", "_excl_").replace(":", "_colon_").replace("#", "_hash_").replace("/", "_slash_")


    #== main BPM plugin ==
    lookup_core_emote = (name, altText) ->
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

    convert_emote_element = (info, parts) ->
        title = "#{info.name} from #{info.source_name}".replace /"/g, ''
        flags = ""
        for flag,i in parts when i>0
            /* Normalize case, and forbid things that don't look exactly as we expect */
            flag = sanitize_emote flag.toLowerCase!
            flags += " bpflag-#flag" if not /\W/.test flag

        if info.is_nsfw
            title = "[NSFW] #title"
            flags += " bpm-nsfw"

        return "<span class='bpflag-in bpm-emote #{info.css_class} #flags' title='#title'>#{info.altText || ''}</span>"
        # data-bpm_emotename='#{info.name}'
        # data-bpm_srname='#{info.source_name}'


    window.bpm = (str) ->
        return str .replace emote_regexp, (_, parts, altText) ->
            parts .= split '-'
            name = parts.0
            info = lookup_core_emote name, altText
            if not info
                return _
            else
                return convert_emote_element info, parts
    window.bpm.disable = (revertPonimotes) ->
        $ \#bpm-resources .remove!
        if revertPonimotes
            $ \.bpm-emote .replaceAll ->
                return document.createTextNode do
                    this.className
                        .replace /bpflag-in|bpm-emote|^\s+|\s+$/g, ''
                        .replace /\s+/g, '-'
            if window.bpm.callback
                for e, i in window._$context._events.\chat:receive when e == window.bpm.callback
                        window._$context._events.\chat:receive
                            .splice i, 1
                        break
        /*
        # in case it is required to avoid replacing in HTML tags
        # usually though, there shouldn't be ponymotes in links / inline images / converted ponymotes
        if str .has("[](/")
            # avoid replacing emotes in HTML tags
            return "#str" .replace /(.*?)(?:<.*?>)?/, (,nonHTML, html) ->
                nonHTML .= replace emote_regexp, (_, parts, altText) ->
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

    if window.p0ne?.chatMessagePlugins
        /* add BPM as a p0ne chat plugin */
        window.p0ne.chatMessagePlugins[*] = window.bpm
    else do ->
        /* add BPM as a standalone script */
        if not window._$context
            module = window.require.s.contexts._.defined[\b1b5f/b8d75/c3237] /* ID as of 2014-09-03 */
            if module and module._events?[\chat:receive]
                window._$context = module
            else
                for id, module of require.s.contexts._.defined when module and module._events?[\chat:receive]
                    window._$context = module
                    break

        window._$context._events.\chat:receive .unshift do
            window.bpm.callback = callback: (d) !->
                d.message = bpm(d.message)

    API .once \p0ne_emotes_map, ->
        console.info "[bpm] loaded"
        /* ponify old messages */
        $ '#chat .text' .html ->
            return window.bpm this.innerHTML

        /* add autocomplete if/when plug_p0ne and plug_p0ne.autocomplete are loaded */
        cb = ->
            addAutocompletion? do
                name: "Ponymotes"
                data: Object.keys(emote_map)
                pre: "[]"
                check: (str, pos) ->
                    if !str[pos+2] or str[pos+2] == "(" and (!str[pos+3] or str[pos+3] == "(/")
                        temp = /^\[\]\(\/([\w#\\!\:\/]+)(\s*["'][^"']*["'])?(\))?/.exec(str.substr(pos))
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
            $(window) .one \p0ne_autocomplete, cb

/*@source p0ne.song-notif.ls */
/**
 * get fancy song notifications in the chat (with preview thumbnail, description, buttons, …)
 * @author jtbrinkmann aka. Brinkie Pie
 * @version 1.0
 * @license MIT License
 * @copyright (c) 2014 J.-T. Brinkmann
 */

#ToDo add proper SoundCloud Support
#   $.ajax url: "https://api.soundcloud.com/tracks/#cid.json?client_id=#{p0ne.SOUNDCLOUD_KEY}"
#   => {permalink_url, artwork_url, description, downloadable}

module \songNotif, do
    require: <[ chatDomEvents ]>
    optional: <[ _$context database auxiliaries app popMenu ]>
    settings: \base
    help: '''
        Shows notifications for playing songs in the chat.
        Besides the songs' name, it also features a thumbnail and some extra buttons.

        By clicking on the song's or author's name, a search on plug.dj for that name will be started, to easily find similar tracks.

        By hovering the notification and clicking "description" the songs description will be loaded.
        You can click anywhere on it to close it again.
    '''
    setup: ({addListener, $create, $createPersistent, css},,,module_) ->
        var lastMedia
        @callback = (d) ~>
            try
                skipped = false #ToDo
                skipper = reason = "" #ToDo

                media = d.media
                if not media or media.id == lastMedia
                    return
                lastMedia := media.id

                $div = $createPersistent "<div class='update song-notif' data-id='#{media.id}' data-cid='#{media.cid}' data-format='#{media.format}'>"
                html = ""
                time = getTime!
                if media.format == 1  # YouTube
                    mediaURL = "http://youtube.com/watch?v=#{media.cid}"
                else # if media.format == 2 # SoundCloud
                    # note: this gets replaced by a proper link as soon as data is available
                    mediaURL = "https://soundcloud.com/search?q=#{encodeURIComponent media.author+' - '+media.title}"

                duration = mediaTime media.duration
                console.logImg media.image.replace(/^\/\//, 'https://') .then ->
                    console.log "#time [DV_ADVANCE] #{d.dj.username} is playing '#{media.author} - #{media.title}' (#duration)", d

                if window.auxiliaries and window.database
                    timestamp = "<div class='timestamp'>#{auxiliaries.getChatTimestamp(database.settings.chatTS == 24)}</div>"
                else
                    timestamp = ""
                html += "
                    <div class='song-thumb-wrapper'>
                        <img class='song-thumb' src='#{media.image}' />
                        <span class='song-duration'>#duration</span>
                        <div class='song-add btn'><i class='icon icon-add'></i></div>
                        <a class='song-open btn' href='#mediaURL' target='_blank'><i class='icon icon-chat-popout'></i></a>
                        <!-- <div class='song-skip btn right'><i class='icon icon-skip'></i></div> -->
                        <!-- <div class='song-download btn right'><i class='icon icon-###'></i></div> -->
                    </div>
                    #timestamp
                    <div class='song-dj un'></div>
                    <b class='song-title'></b>
                    <span class='song-author'></span>
                    <div class='song-description-btn'>Description</div>
                "
                $div.html html
                $div .find \.song-dj .text d.dj.username
                $div .find \.song-title .text d.media.title .prop \title, d.media.title
                $div .find \.song-author .text d.media.author

                if media.format == 2sc and p0ne.SOUNDCLOUD_KEY # SoundCloud
                    $div .addClass \loading
                    #$.ajax url: "https://api.soundcloud.com/tracks/#{media.id}.json?client_id=#{p0ne.SOUNDCLOUD_KEY}"
                    mediaLookup media, then: (d) ->
                        .then (d) ->
                            $div
                                .removeClass \loading
                                .data \description, d.description
                                .find \.song-open .attr \href, d.url
                            if d.download
                                $div
                                    .addClass \downloadable
                                    .find \.song-download
                                        .attr \href, d.download
                                        .attr \title, "#{formatMB(d.downloadSize / 1_000_000to_mb)} #{if d.downloadFormat then '(.'+that+')' else ''}"

                appendChat $div
            catch e
                console.error "[p0ne.notif]" e

        #$create \<div>
        #    .addClass \playback-thumb
        #    .insertBefore $ '#playback .background'

        addListener API, \advance, @callback
        if _$context
            addListener _$context, \room:joined, ~>
                @callback media: API.getMedia!, dj: API.getDJ!

        #== apply stylesheets ==
        loadStyle "#{p0ne.host}/css/p0ne.notif.css?r=14"


        #== show current song ==
        if not module_ and API.getMedia!
            @callback media: that, dj: API.getDJ!

        # hide non-playable videos
        addListener _$context, \RestrictedSearchEvent:search, ->
            snooze!

        #== Grab Songs ==
        if popMenu?
            addListener chatDomEvents, \click, \.song-add, ->
                $el = $ this
                $notif = $el.closest \.song-notif
                id = $notif.data \id
                format = $notif.data \format
                console.log "[add from notif]", $notif, id, format

                msgOffset = $notif .offset!
                $el.offset = -> # to fix position
                    return { left: msgOffset.left + 17px, top: msgOffset.top + 18px }

                obj = { id: id, format: 1yt }
                obj.get = (name) ->
                    return this[name]
                obj.media = obj

                popMenu.isShowing = false
                popMenu.show $el, [obj]
        else
            css \songNotificationsAdd, '.song-add {display:none}'

        #== fimplug ruleskip ==
        addListener chatDomEvents, \click, \.song-add, ->
            showDescription $(this).closest(".song-notif"), """
                <span class='ruleskip'>!ruleskip 1 - nonpony</span>
                <span class='ruleskip'>!ruleskip 2 - </span>
                <span class='ruleskip'>!ruleskip 3 - </span>
                <span class='ruleskip'>!ruleskip 4 - </span>
                <span class='ruleskip'>!ruleskip  - </span>
                <span class='ruleskip'>!ruleskip  - </span>
                <span class='ruleskip'>!ruleskip  - </span>
                <span class='ruleskip'>!ruleskip  - </span>
            """

        #== search for author ==
        addListener chatDomEvents, \click, \.song-author, ->
            mediaSearch @textContent

        #== description ==
        # disable previous listeners (for debugging)
        #$ \#chat-messages .off \click, \.song-description-btn
        #$ \#chat-messages .off \click, \.song-description
        var $description
        addListener chatDomEvents, \click, \.song-description-btn, (e) ->
            try
                if $description
                    hideDescription! # close already open description

                #== Show Description ==
                $description := $ this
                $notif = $description .closest \.song-notif
                cid    = $notif .data \cid
                format = $notif .data \format
                console.log "[song-notif] showing description", cid, $notif

                if $description .data \description
                    showDescription $notif, that
                else
                    # load description from Youtube
                    console.log "looking up", {cid, format}, do
                        mediaLookup {cid, format}, do
                            success: (data) ->
                                text = formatPlainText data.description # let's get fancy
                                $description .data \description, text
                                showDescription $notif, text
                            fail: ->
                                $description
                                    .text "Failed to load"
                                    .addClass \.song-description-failed

                        .timeout 200ms, ->
                            $description
                                .text "Description loading…"
                                .addClass \loading
            catch e
                console.error "[song-notif]", e


        addListener chatDomEvents, \click, \.song-description, (e) ->
            if not e.target.href
                hideDescription!

        function showDescription $notif, text
                # create description element
                $description.removeClass 'song-description-btn loading'
                    .css opacity: 0, position: \absolute
                    .addClass \song-description
                    .html "#text <i class='icon icon-clear-input'></i>"
                    .appendTo $notif

                # show description (animated)
                h = $description.height!
                $description
                    .css height: 0px, position: \static
                    .animate do
                        opacity: 1
                        height: h
                        -> $description .css height: \auto

                # smooth scroll
                cm = $cm!
                offsetTop = $notif.offset!?.top - 100px
                ch = cm .height!
                if offsetTop + h > ch
                    $cm.animate do
                        scrollTop: cm .scrollTop! + Math.min(offsetTop + h - ch + 100px, offsetTop)
                        # 100px is height of .song-notif without .song-description

        function hideDescription
            #== Hide Description ==
            return if not $description
            console.log "[song-notif] closing description", $description
            $notif = $description .closest \.song-notif
            $description.animate do
                opacity: 0
                height: 0px
                ->
                    $ this
                        .css opacity: 1, height: \auto
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

    disable: ->
        @hideDescription?!

/*@source p0ne.song-info.ls */
/**
 * plug_p0ne songInfo
 * adds a dropdown with the currently playing song's description when clicking on the now-playing-bar (in the top-center of the page)
 * @author jtbrinkmann aka. Brinkie Pie
 * @version 1.0
 * @license MIT License
 * @copyright (c) 2014 J.-T. Brinkmann
 */
# maybe add "other videos by artist", which loads a list of other uploads by the uploader?
# http://gdata.youtube.com/feeds/api/users/#{channel}/uploads?alt=json&max-results=10
module \songInfo, do
    optional: <[ _$context ]>
    settings: \base
    displayName: 'Song-Info Dropdown'
    help: '''
        A panel with the song's description and links to the artist and song.
        Click on the now-playing-bar (in the top-center of the page) to open it.
    '''
    setup: ({addListener, $create, css}) ->
        @$create = $create
        @$el = $create \<div> .addClass \p0ne-song-info .appendTo \body
        @loadBind = @~load
        addListener $(\#now-playing-bar), \click, (e) ~>
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
        css \songInfo, '
            #now-playing-bar {
                cursor: pointer;
            }
        '

        return if not _$context
        addListener _$context,  'show:user show:history show:dashboard dashboard:disable', ~> if @visible
            @$el .removeClass \expanded
            API.off \advance, @loadBind
    load: ({media}, isRetry) ->
        console.log "[song-info]", media
        if @lastMediaID == media.id
            @showInfo media
        else
            @lastMediaID = media.id
            @mediaData = null
            mediaLookup media, do
                fail: (err) ~>
                    console.error "[song-info]", err
                    if isRetry
                        @$el .html "error loading, retrying…"
                        load {media}, true
                    else
                        @$el .html "Couldn't load song info, sorry =("
                success: (@mediaData) ~>
                    console.log "[song-info] got data", @mediaData
                    @showInfo media
            API.once \advance, @loadBind
    showInfo: (media) ->
        return if @lastMediaID != media.id or @disabled # skip if another song is already playing
        d = @mediaData

        @$el .html ""
        $meta = @$create \<div>  .addClass \p0ne-song-info-meta        .appendTo @$el
        $parts = {}

        $ \<span> .addClass \p0ne-song-info-author      .appendTo $meta
            .click -> mediaSearch media.author
            .attr \title, "search for '#{media.author}'"
            .text media.author
        $ \<span> .addClass \p0ne-song-info-title       .appendTo $meta
            .click -> mediaSearch media.title
            .attr \title, "search for '#{media.title}'"
            .text media.title
        $ \<br>                                         .appendTo $meta
        $ \<a> .addClass \p0ne-song-info-uploader       .appendTo $meta
            .attr \href, "https://www.youtube.com/channel/#{d.uploader.id}"
            .attr \target, \_blank
            .attr \title, "open channel of '#{d.uploader.name}'"
            .text d.uploader.name
        $ \<a> .addClass \p0ne-song-info-ytTitle        .appendTo $meta
            .attr \href, "http://youtube.com/watch?v=#{media.cid}"
            .attr \target, \_blank
            .attr \title, "open video on Youtube"
            .text d.title
        $ \<br>                                         .appendTo $meta
        $ \<span> .addClass \p0ne-song-info-date        .appendTo $meta
            .text getISOTime new Date(d.uploadDate)
        $ \<span> .addClass \p0ne-song-info-duration    .appendTo $meta
            .text mediaTime +d.duration
        if media.format == 1
            for r in d.data.entry.media$group.media$restriction ||[]
                $ \<span> .addClass \p0ne-song-info-blocked     .appendTo @$el
                    .text "blocked (#{r.type}): #{r.$t}"
        #$ \<div> .addClass \p0ne-song-info-songStats   #ToDo
        #$ \<div> .addClass \p0ne-song-info-songStats   #ToDo
        #$ \<div> .addClass \p0ne-song-info-tags    #ToDo
        $ \<div> .addClass \p0ne-song-info-description  .appendTo @$el
            .html formatPlainText(d.description)
        #$ \<ul> .addClass \p0ne-song-info-remixes      #ToDo
    disable: ->
        @$el .remove!

/*@source p0ne.avatars.ls */
/**
 * plug_p0ne Custom Avatars
 * adds custom avatars to plug.dj when connected to a plug_p0ne Custom Avatar Server (ppCAS)
 *
 * @author jtbrinkmann aka. Brinkie Pie
 * @version 1.0
 * @license MIT License
 * @copyright (c) 2014 J.-T. Brinkmann
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

# users
requireHelper \users, (it) ->
    return it.models?.0?.attributes.avatarID
        and \isTheUserPlaying not of it
        and \lastFilter not of it
window.userID ||= API.getUser!.id
window.user_ ||= users.get(userID) if users?
#=======================


# auxiliaries
window.sleep ||= (delay, fn) -> return setTimeout fn, delay

requireHelper \avatarAuxiliaries, (.getAvatarUrl)
requireHelper \Avatar, (.AUDIENCE)
requireHelper \AvatarList, (._byId?.admin01)
requireHelper \myAvatars, (.comparator == \id) # (_) -> _.comparator == \id and _._events?.reset and (!_.length || _.models[0].attributes.type == \avatar)
requireHelper \InventoryDropdown, (.selected)

window.Lang = require \lang/Lang

window.Cells = requireAll (m) -> m::?.className == \cell and m::getBlinkFrame

module \customAvatars, do
    require: <[ users Lang avatarAuxiliaries Avatar myAvatars ]>
    displayName: 'Custom Avatars'
    settings: \base
    help: '''
        This adds a few custom avatars to plug.dj

        You can select them like any other avatar, by clicking on your username (below the chat) and then clicking "My Stuff".
        Click on the Dropdown field in the top-left to select another category.

        Everyone who uses plug_p0ne sees you with your custom avatar.
    '''
    persistent: <[ socket ]>
    setup: ({addListener, replace, css}) ->
        @replace = replace
        console.info "[p0ne avatars] initializing"

        p0ne._avatars = {}

        user = API.getUser!
        hasNewAvatar = localStorage.vanillaAvatarID and localStorage.vanillaAvatarID == user.avatarID
        localStorage.vanillaAvatarID = user.avatarID

        # - display custom avatars
        replace avatarAuxiliaries, \getAvatarUrl, (gAU_) -> return (avatarID, type) ->
            return p0ne._avatars[avatarID]?[type] || gAU_(avatarID, type)
        getAvatarUrl_ = avatarAuxiliaries.getAvatarUrl_
        #replace avatarAuxiliaries, \getHitSlot, (gHS_) -> return (avatarID) ->
        #    return customAvatarManifest.getHitSlot(avatarID) || gHS_(avatarID)
        #ToDo


        # - set avatarID to custom value
        _internal_addAvatar = (d) ->
            # d =~ {category, thumbOffsetTop, thumbOffsetLeft, base_url, anim, dj, b, permissions}
            #   soon also {h, w, standingLength, standingDuration, standingFn, dancingLength, dancingFn}
            avatarID = d.avatarID
            if p0ne._avatars[avatarID]
                console.info "[p0ne avatars] updating '#avatarID'", d
            else if not d.isVanilla
                console.info "[p0ne avatars] adding '#avatarID'", d

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
            if not updateAvatarStore.loading
                updateAvatarStore.loading = true
                requestAnimationFrame -> # throttle to avoid updating every time when avatars get added in bulk
                    updateAvatarStore!
                    updateAvatarStore.loading = false

        export @addAvatar = (avatarID, d) ->
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
        export @removeAvatar = (avatarID, replace) ->
            for u in users.models
                if u.get(\avatarID) == avatarID
                    u.set(\avatarID, u.get(\avatarID_))
            delete p0ne._avatars[avatarID]



        # - set avatarID to custom value
        export @changeAvatar = (userID, avatarID) ->
            avatar = p0ne._avatars[avatarID]
            if not avatar
                console.warn "[p0ne avatars] can't load avatar: '#{avatarID}'"
                return

            return if not user = users.get userID

            if not avatar.permissions or API.hasPermissions(userID, avatar.permissions)
                user.attributes.avatarID_ ||= user.get \avatarID
                user.set \avatarID, avatarID
            else
                console.warn "user with ID #userID doesn't have permissions for avatar '#{avatarID}'"

            if userID == user_.id
                customAvatars.socket? .emit \changeAvatarID, avatarID
                localStorage.avatarID = avatarID

        export @updateAvatarStore = ->
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
            console.log "[p0ne avatars] avatar inventory updated"
            return true
        addListener myAvatars, \reset, (vanillaTrigger) ->
            updateAvatarStore! if vanillaTrigger

        #== patch avatar inventory view ==
        replace InventoryDropdown::, \draw, (d_) -> return ->
            html = ""
            categories = {}

            for avi in myAvatars.models
                categories[avi.get \category] = true

            for category of categories
                html += """
                    <div class="row" data-value="#category"><span>#{Lang.userAvatars[category]}</span></div>
                """

            @$el.html """
                <dl class="dropdown">
                    <dt><span></span><i class="icon icon-arrow-down-grey"></i><i class="icon icon-arrow-up-grey"></i></dt>
                    <dd>#html</dd>
                </dl>
            """

            $ \dt   .on \click, (e) ~> @onBaseClick e
            $ \.row .on \click, (e) ~> @onRowClick  e
            @select InventoryDropdown.selected

            @$el.show!


        Lang.userAvatars.p0ne = "Custom Avatars"

        # - add vanilla avatars
        for {id:avatarID, attributes:{category}} in AvatarList.models
            _internal_addAvatar do
                avatarID: avatarID
                isVanilla: true
                category: category
                #category: avatarID.replace /\d+$/, ''
                #category: avatarID.substr(0,avatarID.length-2) damn you "tastycat"
        console.log "[p0ne avatars] added internal avatars", p0ne._avatars
        # - fix Avatar selection -
        for Cell in window.Cells
            replace Cell::, \onClick, (oC_) -> return ->
                console.log "[p0ne avatars] Avatar Cell click", this
                avatarID = this.model.get("id")
                if /*not this.$el.closest \.inventory .length or*/ p0ne._avatars[avatarID].isVanilla and p0ne._avatars[avatarID].inInventory
                    # if avatatar is in the Inventory or not bought, properly select it
                    oC_ ...
                else
                    # if not, hax-apply it
                    changeAvatar(userID, avatarID)
                    this.onSelected!
        # - get avatars in inventory -
        $.ajax do
            url: '/_/store/inventory/avatars'
            success: (d) ->
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
                updateAvatarStore!
                /*requireAll (m) ->
                    return if not m._models or not m._events?.reset
                    m_avatarIDs = ""
                    for el, i in m._models
                        return if avatarIDs[i] != el
                */

        if not hasNewAvatar and localStorage.avatarID
            changeAvatar(userID, that)




        /*####################################
        #         ppCAS Integration          #
        ####################################*/
        @oldBlurb = API.getUser!.blurb
        @blurbIsChanged = false

        urlParser = document.createElement \a
        addListener API, \chatCommand, (str) ~>
            #str = "/ppcas https://p0ne.com/_" if str == "//" # FOR TESTING ONLY
            if 0 == str .toLowerCase! .indexOf "/ppcas"
                server = $.trim str.substr(6)
                if server == "<url>"
                    API.chatLog "hahaha, no. You have to replace '<url>' with an actual URL of a ppCAS server, otherwise it won't work.", true
                else if server == "."
                    # Veteran avatars
                    base_url = "https://dl.dropboxusercontent.com/u/4217628/plug.dj/customAvatars/"
                    helper = (fn) ->
                        fn = window[fn]
                        for avatarID in <[ su01 su02 space03 space04 space05 space06 ]>
                            fn avatarID, do
                                category: "Veteran"
                                base_url: base_url
                                thumbOffsetTop: -5px
                        fn \animal12, do
                            category: "Veteran"
                            base_url: base_url
                            thumbOffsetTop: -19px
                            thumbOffsetLeft: -16px
                        for avatarID in <[ animal01 animal02 animal03 animal04 animal05 animal06 animal07 animal08 animal09 animal10 animal11 animal12 animal13 animal14 lucha01 lucha02 lucha03 lucha04 lucha05 lucha06 lucha07 lucha08 monster01 monster02 monster03 monster04 monster05 _tastycat _tastycat02 warrior01 warrior02 warrior03 warrior04 ]>
                            fn avatarID, do
                                category: "Veteran"
                                base_url: base_url
                                thumbOffsetTop: -10px

                    @socket = close: ->
                        helper \removeAvatar
                        delete @socket
                    helper \addAvatar
                urlParser.href = server
                if urlParser.host != location.host
                    console.log "[p0ne avatars] connecting to", server
                    @connect server
                else
                    console.warn "[p0ne avatars] invalid ppCAS server"

        @connect 'https://p0ne.com/_'

    connect: (url, reconnecting, reconnectWarning) ->
        if not reconnecting and @socket
            return if url == @socket.url and @socket.readyState == 1
            @socket.close!
        console.log "[p0ne avatars] using socket as ppCAS avatar server"
        reconnect = true
        connectAttemps = 1

        if reconnectWarning
            setTimeout (-> if connectAttemps==0 then API.chatLog "[p0ne avatars] lost connection to avatar server \xa0 =("), 10_000ms

        @socket = new SockJS(url)
        @socket.url = url
        @socket.on = @socket.addEventListener
        @socket.off = @socket.removeEventListener
        @socket.once = (type, callback) -> @on type, -> @off type, callback; callback ...

        @socket.emit = (type, ...data) ->
            console.log "[ppCAS] > [#type]", data
            this.send JSON.stringify {type, data}

        @socket.trigger = (type, args) ->
            args = [args] if typeof args != \object or not args?.length
            listeners = @_listeners[type]
            if listeners
                for fn in listeners
                    fn .apply this, args
            else
                console.error "[ppCAS] unknown event '#type'"

        @socket.onmessage = ({data: message}) ~>
            try
                {type, data} = JSON.parse(message)
                console.log "[ppCAS] < [#type]", data
            catch e
                console.warn "[ppCAS] invalid message received", message, e
                return

            @socket.trigger type, data

        @replace @socket, close, (close_) ~> return ->
                @trigger close
                close_ ...

        # replace old authTokens
        do ->
            user = API.getUser!
            oldBlurb = user.blurb || ""
            newBlurb = oldBlurb .replace /🐎\w{4}/g, '' # THIS SHOULD BE KEPT IN SYNC WITH ppCAS' AUTH_TOKEN GENERATION
            if oldBlurb != newBlurb
                @changeBlurb newBlurb, do
                    success: ~>
                        console.info "[ppCAS] removed old authToken from user blurb"

        @socket.on \authToken, (authToken) ~>
            user = API.getUser!
            @oldBlurb = user.blurb || ""
            if not user.blurb # user.blurb is actually `null` by default, not ""
                newBlurb = authToken
            else if user.blurb.length >= 72
                newBlurb = "#{user.blurb.substr(0, 71)}… 🐎#authToken"
            else
                newBlurb = "#{user.blurb} #authToken"

            @blurbIsChanged = true
            @changeBlurb newBlurb, do
                success: ~>
                    @blurbIsChanged = false
                    @socket.emit \auth, userID
                error: ~>
                    console.error "[ppCAS] failed to authenticate by changing the blurb."
                    @changeBlurb @oldBlurb, success: ->
                        console.info "[ppCAS] blurb reset."

        @socket.on \authAccepted, ~>
            connectAttemps := 0
            reconnecting := false
            @changeBlurb @oldBlurb, do
                success: ~>
                    @blurbIsChanged = false
                error: ~>
                    API.chatLog "[p0ne avatars] failed to authenticate to avatar server, maybe plug.dj is down or changed it's API?"
                    @changeBlurb @oldBlurb, error: ->
                        console.error "[ppCAS] failed to reset the blurb."
        @socket.on \authDenied, ~>
            console.warn "[ppCAS] authDenied"
            API.chatLog "[p0ne avatars] authentification failed"
            @changeBlurb @oldBlurb, do
                success: ~>
                    @blurbIsChanged = false
                error: ~>
                    @changeBlurb @oldBlurb, error: ->
                        console.error "[ppCAS] failed to reset the blurb."
            API.chatLog "[p0ne avatars] Failed to authenticate with user id '#userID'", true

        @socket.on \avatars, (avatars) ~>
            user = API.getUser!
            @socket.avatars = avatars
            requestAnimationFrame initUsers if @socket.users
            for avatarID, avatar of avatars
                addAvatar avatarID, avatar
            if localStorage.avatarID of avatars
                changeAvatar userID, localStorage.avatarID
            else if user.avatarID of avatars
                @socket.emit \changeAvatarID, user.avatarID

        @socket.on \users, (users) ~>
            @socket.users = users
            requestAnimationFrame initUsers if @socket.avatars

        # initUsers() is used by @socket.on \users and @socket.on \avatars
        ~function initUsers avatarID
            for userID, avatarID of @socket.users
                console.log "[ppCAS] change other's avatar", userID, "(#{users.get userID ?.get \username})", avatarID
                @changeAvatar userID, avatarID
            #API.chatLog "[p0ne avatars] connected to ppCAS"
            if reconnecting
                API.chatLog "[p0ne avatars] reconnected"
            _$context.trigger \ppCAS:connected
            API.trigger \ppCAS:connected
            #else
            #    API.chatLog "[p0ne avatars] avatars loaded. Click on your name in the bottom right corner and then 'Avatars' to become a :horse: pony!"
        @socket.on \changeAvatarID, (userID, avatarID) ->
            console.log "[ppCAS] change other's avatar:", userID, avatarID

            users.get userID ?.set \avatarID, avatarID

        @socket.on \disconnect, (userID) ~>
            console.log "[ppCAS] user disconnected:", userID
            @changeAvatarID userID, avatarID

        @socket.on \disconnected, (reason) ~>
            @socket.trigger \close, reason
        @socket.on \close, (reason) ->
            console.warn "[ppCAS] connection closed", reason
            reconnect := false
        @socket.onclose = (e) ~>
            console.warn "[ppCAS] DISCONNECTED", e
            _$context.trigger \ppCAS:disconnected
            API.trigger \ppCAS:disconnected
            if e.wasClean
                reconnect := false
            else if reconnect
                if connectAttemps==0
                    console.log "[ppCAS] reconnecting…"; @connect(url, true, true)
                else
                    sleep (5_000ms + Math.random!*5_000ms)*connectAttemps, ~>
                        console.log "[ppCAS] reconnecting…"
                        connectAttemps++
                        @connect(url, true, false)
                        _$context.trigger \ppCAS:connecting
                        API.trigger \ppCAS:connecting
        _$context.trigger \ppCAS:connecting
        API.trigger \ppCAS:connecting


    changeBlurb: (newBlurb, options={}) ->
        $.ajax do
            method: \PUT
            url: '/_/profile/blurb'
            contentType: \application/json
            data: JSON.stringify(blurb: newBlurb)
            success: options.success
            error: options.error

        #setTimeout (-> @socket.emit \reqAuthToken if connectAttemps), 5_000ms

    disable: ->
        @changeBlurb @oldBlurb if @blurbIsChanged
        @socket? .close!
        for avatarID, avi of p0ne._avatars
            avi.inInventory = false
        @updateAvatarStore!
        for ,user of users.models when user.attributes.avatarID_
            user.set \avatarID, that
    #API.chatLog "[ppCAS] custom avatar script loaded. type '/ppCAS <url>' into chat to connect to an avatar server :horse:"

/*@source p0ne.stream.ls */
/**
 * Modules for Audio-Only stream and stream settings for plug_p0ne
 * @author jtbrinkmann aka. Brinkie Pie
 * @license MIT License
 * @copyright (c) 2015 J.-T. Brinkmann
*/

module \streamSettings, do
    require: <[ app currentMedia _$context ]>
    optional: <[ database ]>
    audioOnly: false
    setup: ({addListener, replace, replaceListener, $create, css}, streamSettings,,m_) ->
        $playback = $ \#playback
        $el = $create '<div class=p0ne-stream-select>'

        # keep audio-only on update
        if m_
            @audioOnly = m_.audioOnly

        # replace HD button
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
        replace Playback::, \onHDClick, -> return $.noop
        $btn = $ '#playback .hd'
            .addClass \p0ne-stream-select
            .html '
                <div class="box">
                    <span id=p0ne-stream-label>Stream: Video</span>
                    <div class="p0ne-stream-buttons">
                        <i class="icon icon-stream-video"></i> <i class="icon icon-stream-audio"></i> <i class="icon icon-stream-off"></i> <div class="p0ne-stream-fancy"></div>
                    </div>
                </div>
            '
        @$label = $btn.find \#p0ne-stream-label

        addListener $btn.find(\.icon-stream-video), \click, ~> @changeStream \video
        addListener $btn.find(\.icon-stream-audio), \click, ~> @changeStream \audio
        addListener $btn.find(\.icon-stream-off),   \click, ~> @changeStream \off

        @changeStream!

        @audio = audio = new Audio!
        export audio # TEST
        audio.volume = currentMedia.get(\volume) / 100perc
        HDsettings = database?.settings || {hd720: true}
        audio.addEventListener \canplay, ->
            console.log "[audioStream] finished buffering"
            if currentMedia.get(\media) == audio.media
                if audio.init
                    audio.init = false
                    seek!
                else
                    audio.play!
                    console.log "[audioStream] audio.play()"
            else
                console.warn "[audioStream] next song already started"

        replace Playback::, \onVolumeChange, (oVC_) -> return ->
            audio.volume = currentMedia.get(\volume) / 100perc
            oVC_ ...

        replace Playback::, \onMediaChange, -> return ->
            @reset!
            @$controls.removeClass \snoozed
            media = currentMedia.get \media
            audio.src = null
            audio.media = {}
            if media
                @$noDJ.hide!
                return if currentMedia.get \streamDisabled

                @ignoreComplete = true
                console.log "[audioStream] B"
                sleep 1_000ms, ~> @resetIgnoreComplete!
                if media.get(\format) == 1 # youtube
                    console.log "[audioStream] C"
                    if streamSettings.audioOnly and not audio.failed
                        /*== audio only streaming ==*/
                        console.log "[audioStream] looking for URL"
                        if media.id == audio.media.id
                            seek!
                        else
                            audio.init = true
                            mediaDownload media, true
                                .then (d) ->
                                    console.log "[audioStream] found url", d
                                    media.src = d.preferredDownload.url

                                    audio.media = media
                                    audio.src = media.src
                                    seek!
                                    audio.load!
                                .fail (err) ->
                                    console.error "[audioStream] couldn't get audio stream", err
                                    audio.failed := true
                                    refresh!
                                    API.once \advance, ->
                                        audio.failed = false
                    else
                        console.log "[audioStream] loading video stream"
                        startTime = currentMedia.get \elapsed
                        @buffering = false
                        @yto =
                            id: media.get \cid
                            volume: currentMedia.get \volume
                            seek: if startTime < 4s then 0s else startTime
                            quality: if HDsettings.hdVideo then \hd720 else ""

                        a = \yt5
                        if window.location.host != \plug.dj
                            a += if window.location.host == \localhost then \local else \staging
                        @$container.append do
                            $ "<iframe id=yt-frame frameborder=0 src='#{window.location.protocol}//plgyte.appspot.com/#a.html'>"
                                .load @ytFrameLoadedBind
                else if media.get(\format) == 2 # soundcloud
                    console.log "[audioStream] loading Soundcloud"
                    if soundcloud.r
                        if soundcloud.sc
                            @$container.empty!.append do
                                $ "<iframe id=yt-frame frameborder=0 src='#{@visualizers[@random.integer(0, 1)]}'></iframe>"
                            soundcloud.sc.whenStreamingReady ~>
                                if currentMedia.get \media == media # SC DOUBLE PLAY FIX
                                    startTime = currentMedia.get \elapsed
                                    @player = soundcloud.sc.stream media.get(\cid), do
                                        autoPlay: true
                                        volume: currentMedia.get \volume
                                        position: if startTime < 4s then 0s else startTime * 1_000ms
                                        onload: @scOnLoadBind
                                        whileloading: @scLoadingBind
                                        onfinish: @playbackCompleteBind
                                        ontimeout: @scTimeoutBind
                        else
                            @$container.append do
                                $ '<img src="https://soundcloud-support.s3.amazonaws.com/images/downtime.png" height="271"/>'
                                    .css do
                                        position: \absolute
                                        left: 46px
                else
                    console.log "[audioStream] wut", media.get(\format), typeof media.get(\format)
                    _$context.on \sc:ready, @onSCReady, this
            else
                @$noDJ.show!
                @$controls.hide!

        replace Playback::, \stop, (s_) -> return ->
            audio.pause!
            s_ ...

        replaceListener currentMedia, \change:media, Playback, -> return app.room.playback~onMediaChange
        replaceListener currentMedia, \change:streamDisabled, Playback, -> return app.room.playback~onMediaChange
        replaceListener currentMedia, \change:volume, Playback, -> return app.room.playback~onVolumeChange

        if streamSettings.audioOnly
            refresh!

        function seek
            startTime = currentMedia.get \elapsed
            audio.currentTime = if startTime < 4s then 0s else startTime
    changeStream: (mode) ->
        prevMode =
            if currentMedia.get \streamDisabled
                \off
            else if streamSettings.audioOnly
                \audio
            else
                \video
        if mode != prevMode
            mode ||= prevMode
            console.log "[streamSettings] stream-#mode"
            @$label .text "Stream: #mode"
            streamSettings.audioOnly = (mode == \audio)
            stream(mode != \off)
            $body
                .removeClass "p0ne-stream-#prevMode"
                .addClass "p0ne-stream-#mode"
            refresh!

    disable: ->
        @audio.src = null
        sleep 0, ->
            if streamSettings.audioOnly
                refresh!
        $body
            .removeClass \p0ne-stream-video
            .removeClass \p0ne-stream-audio
            .removeClass \p0ne-stream-off

/*@source p0ne.settings.ls */
/**
 * Settings pane for plug_p0ne
 * @author jtbrinkmann aka. Brinkie Pie
 * @version 1.0
 * @license MIT License
 * @copyright (c) 2014 J.-T. Brinkmann
 */
module \p0neSettings, do
    _settings:
        groupToggles: {p0neSettings: true, base: true}
    setup: ({$create, addListener},,,oldModule) ->
        @$create = $create

        groupToggles = @groupToggles = @_settings.groupToggles

        # ToDo: add a little plug_p0ne banner saying the version

        # create DOM elements
        $ppM = $create "<div id=p0ne_menu>"
            .insertAfter \#app-menu
        $ppI = $create "<div class=p0ne_icon>p<div class=p0ne_icon_sub>0</div></div>"
            .appendTo $ppM
        $ppS = @$ppS = $create "<div class=p0ne_settings>"
            .appendTo do
                $ "<div class=p0ne_settings_wrapper>"
                    .appendTo $ppM
        $ppP = $create "<div class=p0ne_settings_popup>"
            .appendTo $ppM
            .fadeOut 0

        #debug
        #@<<<<{$ppP, $ppM, $ppI}
        @toggleMenu groupToggles.p0neSettings

        # add toggles for existing modules
        for ,module of p0ne.modules
            @addModule module


        ## add DOM event listeners
        # slide settings-menu in/out
        $ppI .click ~> @toggleMenu!

        # toggle groups
        addListener $body, \click, \.p0ne_settings_summary, (e) ->
          $s = $ this .parent!
          if $s.data \open # close
            $s
                .data \open, false
                .removeClass \open
                .stop! .animate height: 40px, \slow /* magic number, height of the summary element */
            groupToggles[$s.data \group] = false
          else
            $s
                .data \open, true
                .addClass \open
                .stop! .animate height: $s.children!.length * 44px, \slow /* magic number, height of a .p0ne_settings_item*/
            groupToggles[$s.data \group] = true
          e.preventDefault!

        addListener $ppS, \click, \.checkbox, ->
            # note: this gets triggered when anything in the <label> is clicked
            $this = $ this
            enable = this .checked
            $el = $this .closest \.p0ne_settings_item
            module = $el.data \module
            console.log "[p0neSettings] toggle", module.displayName, "=>", enable
            if enable
                module.enable!
            else
                module.disable!

        addListener $ppS, \mouseover, \.p0ne_settings_has_more, ->
            $this = $ this
            module = $this .data \module
            $ppP
                .html "
                    <div class=p0ne_settings_popup_triangle></div>
                    <h3>#{module.displayName}</h3>
                    #{if!   module.screenshot   then'' else
                        '<img src='+module.screenshot+'>'
                    }
                    #{module.help}
                "
            l = $ppS.width!
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
            $ppP .find \.p0ne_settings_popup_triangle
                .css top: t
        addListener $ppS, \mouseout, \.p0ne_settings_has_more, ->
            $ppP .stop!.fadeOut!
        addListener $ppP, \mouseover, ->
            $ppP .stop!.fadeIn!
        addListener $ppP, \mouseout, ->
            $ppP .stop!.fadeOut!

        # add p0ne.module listeners
        addListener API, \p0neModuleLoaded, (module) ~> @addModule module
        addListener API, \p0neModuleDisabled, (module) ~>
            module._$settings? .find \.checkbox .0 .checked=false
        addListener API, \p0neModuleEnabled, (module) ~>
            module._$settings? .find \.checkbox .0 .checked=true
        addListener API, \p0neModuleUpdated, (module) ~>
            if module._$settings
                module._$settings .find \.checkbox .0 .checked=true
                module._$settings .addClass \updated
                sleep 2_000ms, ->
                    module._$settings .removeClass \updated
            else if module.settings
                @addModule module

        if _$context?
            addListener _$context, 'show:user show:history show:dashboard dashboard:disable', ~> @toggleMenu false

        # plugCubed compatibility
        addListener $body, \click, \#plugcubed, ~>
            @toggleMenu false

    toggleMenu: (state) ->
        if state ?= not @groupToggles.p0neSettings
            @$ppS.slideDown!
        else
            @$ppS.slideUp!
        @groupToggles.p0neSettings = state

    groups: {}
    addModule: (module) !->
        if module.settings
            module.more = typeof module.settings == \function
            itemClasses = \p0ne_settings_item
            icons = ""
            for k in <[ more help screenshot ]> when module[k]
                icons += "<div class=p0ne_settings_#k></div>"
            if icons.length
                icons = "<div class=p0ne_settings_icons>#icons</div>"
                itemClasses += ' p0ne_settings_has_more'

            if not $s = @groups[module.settings]
                $s = @groups[module.settings] = $ '<div class=p0ne_settings_group>'
                    .data \group, module.settings
                    .append do
                        $ '<div class=p0ne_settings_summary>' .text module.settings.toUpperCase!
                    .appendTo @$ppS
                if @_settings.groupToggles[module.settings]
                    $s
                        .data \open, true
                        .addClass \open

            $s .append do
                # $create doesn't have to be used, because the resulting elements are appended to a $create'd element
                module._$settings = $ "
                        <label class='#itemClasses'>
                            <input type=checkbox class=checkbox #{if module.disabled then '' else \checked} />
                            <div class=togglebox><div class=knob></div></div>
                            #{module.displayName}
                            #icons
                        </label>
                    "
                    .data \module, module
            if @_settings.groupToggles[module.settings]
                $s .stop! .animate height: $s.children!.length * 44px, \slow
    updateSettings: (m) ->
        @$ppS .html ""
        for module in p0ne.modules
            @addModule module
    /*
    updateSettingsThrottled: (m) ->
        return if throttled or not m.settings
        @throttled = true
        requestAnimationFrame ~>
            @updateSettings!
            @throttled = false
    */

/*@source p0ne.moderate.ls */
/**
 * plug_p0ne modules to help moderators do their job
 * @author jtbrinkmann aka. Brinkie Pie
 * @version 1.0
 * @license MIT License
 * @copyright (c) 2014 J.-T. Brinkmann
 */

module \enableModeratorModules, do
    require: <[ user_ ]>
    setup: ({addListener}) ->
        prevRole = user_.attributes.role
        addListener user_, \change:role, (user, newRole) ->
            if newRole > 1 and prevRole < 2
                for m in p0ne.modules when m.modDisabled
                    m.enable!
                    m.modDisabled = false
            else
                for m in p0ne.modules when m.moderator and not m.modDisabled
                    m.modDisabled = true
                    m.disable!

module \warnOnHistory, do
    moderator: true
    setup: ({addListener}) ->
        addListener API, \advance, (d) ~>
            return if not d.media
            hist = API.getHistory!
            inHistory = 0; skipped = 0; lastTime = 0
            for m, i in hist when m.id == d.id and d.historyID != m.historyID
                inHistory++
                m.i = i
                lastPlay ||= m
                skipped++ if m.skipped
            if inHistory
                msg = "Song is in history"
                if inHistory > 1
                    msg += " (#inHistory times) one:"
                msg += " #{ago PARSESOMEHOW lastPlay.datetime} (#{i+1}/#{hist.length})"
                if skipped == inHistory
                    msg = " but was skipped last time"
                if skipped > 1
                    msg = " it was skipped #skipped/#inHistory times"
                API.chatLog msg, true
                API.trigger \p0ne_songInHistory # should this be p0ne:songInHistory?



/*####################################
#      DISABLE MESSAGE DELETE        #
####################################*/
module \disableChatDelete, do
    require: <[ _$context user_ ]>
    optional: <[ socketListeners ]>
    settings: \chat
    displayName: 'Show deleted messages'
    moderator: true
    setup: ({replace_$Listener, addListener, $createPersistent, css}) ->
        css \disableChatDelete, '
            .deleted {
                border-left: 2px solid red;
                display: none;
            }
            .p0ne_showDeletedMessages .deleted {
                display: block;
            }
            .deleted-message {
                display: block;
                text-align: right;
                color: red;
                font-family: monospace;
            }
        '

        $body .addClass \p0ne_showDeletedMessages


        addListener _$context, \socket:chatDelete, ({{c,mi}:p}) ->
            markAsDeleted(c, users.get(mi)?.get(\username) || mi)
        #addListener \early, _$context, \chat:delete, -> return (cid) ->
        replace_$Listener \chat:delete, -> (cid) ->
            markAsDeleted(cid) if not socketListeners

        function markAsDeleted cid, moderator
            $msg = getChat cid
            #ToDo add scroll down
            console.log "[Chat Delete]", cid, $msg.text!
            t  = getISOTime!
            t += " by #moderator" if moderator
            try
                $msg
                    .removeClass \deletable
                    .addClass \deleted
                d = $createPersistent \<time>
                    .addClass \deleted-message
                    .attr \datetime, t
                    .text t
                    .appendTo $msg
                cm = $cm!
                cm.scrollTop cm.scrollTop! + d.height!

    disable: ->
        $body .removeClass \p0ne_showDeletedMessages



/*####################################
#           MESSAGE CLASSES          #
####################################*/
module \chatDeleteOwnMessages, do
    moderator: true
    setup: ({addListener}) ->
        $cm! .find "fromID-#{userID}"
            .addClass \deletable
            .append '<div class="delete-button">Delete</div>'
        addListener API, \chat, ({cid, uid}:message) -> if uid == userID
            getChat(cid)
                .addClass \deletable
                .append '<div class="delete-button">Delete</div>'


/*####################################
#            WARN ON MEHER           #
####################################*/
module \warnOnMehers, do
    users: {}
    moderator: true
    _settings:
        instantWarn: false
        maxMehs: 3
    setup: ({addListener},,, m_) ->
        if m_
            @users = m_.users
        users = @users

        current = {}
        addListener API, \voteUpdate, (d) ~>
            current[d.user.id] = d.vote
            if @_settings.instantWarn and d.vote == -1
                API.chatLog "#{d.user.username} (lvl #{d.user.level}) meh'd this song", true

        lastAdvance = 0
        addListener API, \advance, (d) ~>
            d = Date.now!
            for k,v of current
                if v == -1
                    users[k] ||= 0
                    if ++users[k] > @_settings.maxMehs
                        API.chatLog "#{d.dj.username} (lvl #{d.dj.level}) meh'd the past #{users[k]} songs!", true
                else if d > lastAdvance + 10_000ms and d.lastPlay?.dj.id != k
                    delete users[k]
            current := {}
            lastAdvance := d


module \afkTimer, do
    require: <[ RoomUserRow WaitlistRow ]>
    optional: <[ socketListeners app userList _$context ]>
    moderator: true
    lastActivity: {}
    _settings:
        highlightOver: 45.min
    setup: ({addListener},,,m_) ->
        # initialize users
        settings = @_settings
        @start = start = m_?.start || Date.now!
        if m_
            @lastActivity = m_.lastActivity
        else
            for user in API.getUsers!
                @lastActivity[user.id] = start
        lastActivity = @lastActivity

        # set up event listeners to update the lastActivity time
        addListener API, 'socket:skip socket:grab', (id) -> updateUser id
        addListener API, 'userJoin socket:nameChanged', (u) -> updateUser u.id
        addListener API, 'chat', (u) -> updateUser u.uid
        addListener API, 'socket:gifted', (e) -> updateUser e.s
        addListener API, 'socket:modAddDJ socket:modBan socket:modMoveDJ socket:modRemoveDJ socket:modSkip socket:modStaff', (u) -> updateUser u.mid
        addListener API, 'userLeave', (u) -> delete lastActivity[u.id]

        var timer
        if _$context? and (app? or userList?)
            addListener _$context, 'show:users show:waitlist', ->
                timer := repeat 60_000ms, forceRerender
            addListener _$context, \show:chat, ->
                clearInterval timer

        # UI
        d = 0
        var noActivityYet
        for Constr, fn in [RoomUserRow, WaitlistRow]
            replace Constr::, \render, (r_) -> return (isUpdate) ->
                r_ ...
                if not d
                    d := Date.now!
                    requestAnimationFrame -> d := 0; noActivityYet := null
                ago = d - lastActivity[@model.id]
                if lastActivity[@model.id] == start
                    time = noActivityYet ||= ">#{humanTime(ago, true)}"
                else if ago < 60_000ms
                    time = "<1m"
                else if ago < 120_000ms
                    time = "<2m"
                else
                    time = humanTime(ago, true)
                $span = $ '<span class=p0ne-last-activity>' .text time
                $span .addClass \p0ne-last-activity-warn if ago > settings.highlightOver
                $span .addClass \p0ne-last-activity-update if isUpdate
                @$el .append $span
                if isUpdate
                    requestAnimationFrame -> $span .removeClass \p0ne-last-activity-update



        function updateUser uid
            lastActivity[uid] = Date.now!
            # waitlist.rows defaults to [], so no need to ||[]
            for r in userList?.listView?.rows || app?.room.waitlist.rows when r.model.id == uid
                console.log "updated #{r.model.username}'s row", r
                r.render true

        # update current rows (it should not be possible, that the waitlist and userlist are populated at the same time)
        function forceRerender
            for r in app?.room.waitlist.rows || userList?.listView?.rows ||[]
                console.log "rerendering #{r.model.username}'s row", r
                r.render!

        forceRerender!

/*@source p0ne.dev.ls */
/**
 * plug_p0ne dev
 * a set of plug_p0ne modules for usage in the console
 * They are not used by any other module
 * @author jtbrinkmann aka. Brinkie Pie
 * @version 1.0
 * @license MIT License
 * @copyright (c) 2014 J.-T. Brinkmann
 */
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
    setup: ({addListener, replace}) ->
        logEventsToConsole = this
        addListener API, \chat, (data) ->
            message = cleanMessage data.message
            if data.un
                name = data.un .replace(/\u202e/g, '\\u202e') |> collapseWhitespace
                name = " " * (24 - name.length) + name
                if data.type == \emote
                    console.log "#{getTime!} [CHAT] #name: %c#message", "font-style: italic;"
                else
                    console.log "#{getTime!} [CHAT] #name: #message"
            else if data.type.has \system
                console.info "#{getTime!} [CHAT] [system] %c#message", "font-size: 1.2em; color: red; font-weight: bold"
            else
                console.log "#{getTime!} [CHAT] %c#message", 'color: #36F'

        addListener API, \userJoin, (data) ->
            name = htmlUnescape(data.username) .replace(/\u202e/g, '\\u202e')
            console.log "#{getTime!} + [JOIN]", data.id, name, "(#{getRank data})", data
        addListener API, \userLeave, (data) ->
            name = htmlUnescape(data.username) .replace(/\u202e/g, '\\u202e')
            console.log "#{getTime!} - [LEAVE]", data.id, name, "(#{getRank data})", data

        return if not window._$context
        addListener _$context, \PlayMediaEvent:play, (data) ->
            #data looks like {type: "PlayMediaEvent:play", media: n.hasOwnProperty.i, startTime: "1415645873000,0000954135", playlistID: 5270414, historyID: "d38eeaec-2d26-4d76-8029-f64e3d080463"}

            console.log "#{getTime!} [SongInfo]", "playlist:",data.playlistID, "historyID:",data.historyID

        #= log (nearly) all _$context events
        replace _$context, \trigger, (trigger_) -> return (type) ->
            group = type.substr(0, type.indexOf ":")
            if group not in <[ socket tooltip djButton chat sio playback playlist notify drag audience anim HistorySyncEvent user ShowUserRolloverEvent ]> and type not in <[ ChatFacadeEvent:muteUpdate PlayMediaEvent:play userPlaying:update context:update ]> or logEventsToConsole.logAll
                console.log "#{getTime!} [#type]", getArgs?! || arguments
            else if group == \socket and type not in <[ socket:chat socket:vote socket:grab socket:earn ]>
                console.log "#{getTime!} [#type]", [].slice.call(arguments, 1)
            /*else if type == "chat:receive"
                data = &1
                console.log "#{getTime!} [CHAT]", "#{data.from.id}:\t", data.text, {data}*/
            try
                return trigger_ ...
            catch e
                console.error "[_$context] Error when triggering '#type'", (export e).stack

        #= try-catch API event listeners =
        replace API, \trigger, (trigger_) -> return (type) ->
            try
                return trigger_ ...
            catch e
                console.error "[API] Error when triggering '#type'", (export e).stack


/*####################################
#             DEV TOOLS              #
####################################*/
module \downloadLink, do
    setup: ({css}) ->
        icon = getIcon \icon-arrow-down
        css \downloadLink, "
            .p0ne_downloadlink::before {
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
    module: (name, filename, dataOrURL) ->
        if not dataOrURL
            dataOrURL = filename; filename = name
        if dataOrURL and not isURL(dataOrURL)
            dataOrURL = JSON.stringify dataOrURL if typeof dataOrURL != \string
            dataOrURL = URL.createObjectURL new Blob( [dataOrURL], type: \text/plain )
        filename .= replace /[\/\\\?%\*\:\|\"\<\>\.]/g, '' # https://en.wikipedia.org/wiki/Filename#Reserved_characters_and_words
        return appendChat "
                <div class='message p0ne_downloadlink'>
                    <i class='icon'></i>
                    <span class='text'>
                        <a href='#{dataOrURL}' download='#{filename}'>#{name}</a>
                    </span>
                </div>
            "


# DEBUGGING
window <<<<
    roomState: !-> ajax \GET, \rooms/state
    export_: (name) -> return (data) !-> console.log "[export] #name =",data; window[name] = data
    searchEvents: (regx) ->
        regx = new RegExp(regx, \i) if regx not instanceof RegExp
        return [k for k of _$context?._events when regx.test k]


    listUsers: ->
        res = ""
        for u in API.getUsers!
            res += "#{u.id}\t#{u.username}\n"
        console.log res
    listUsersByAge: ->
        a = API.getUsers! .sort (a,b) ->
            a = +a.dateJoined.replace(/\D/g,'')
            b = +b.dateJoined.replace(/\D/g,'')
            return (a > b && 1) || (a == b && 0) || -1

        for u in a
            console.log u.dateJoined.replace(/T|\..+/g, ' '), u.username
    joinRoom: (slug) ->
        ajax \POST, \rooms/join, {slug}


    findModule: (test) ->
        if typeof test == \string and window.l
            test = l(test)
        res = []
        for id, module of require.s.contexts._.defined when module
            if test module, id
                module.requireID ||= id
                console.log "[findModule]", id, module
                res[*] = module
        return res

    requireHelperHelper: (module) ->
        if typeof module == \string
            module = require(module)
        return false if not module

        for k,v of module
            keys = 0
            keysExact = 0
            isNotObj = typeof v not in <[ object function ]>
            for id, m2 of require.s.contexts._.defined when m2 and m2[k] and k not in <[ requireID cid id ]>
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
            cb = (slug, err) -> console[err && \error || \log] "username '#username': ", err || slug

        if not ignoreWarnings
            if length < 2
                cb(false, "too short")
            else if length >= 25
                cb(false, "too long")
            else if username.has("/")
                cb(false, "forward slashes are not allowed")
            else if username.has("\n")
                cb(false, "line breaks are not allowed")
            else
                ignoreWarnings = true
        if ignoreWarnings
            return $.getJSON "https://plug.dj/_/users/validate/#{encodeURIComponent username}", (d) ->
                cb(d && d.data.0?.slug)

    getRequireArg: (haystack, needle) ->
        # this is a helper function to be used in the console to quickly find a module ID corresponding to a parameter and vice versa in the head of a javascript requirejs.define call
        # e.g. getRequireArg('define( "da676/a5d9e/a7e5a/a3e8f/fa06c", [ "jquery", "underscore", "backbone", "da676/df0c1/fe7d6", "da676/ae6e4/a99ef", "da676/d8c3f/ed854", "da676/cba08/ba3a9", "da676/cba08/ee33b", "da676/cba08/f7bde", "da676/cba08/d0509", "da676/eb13a/b058e/c6c93", "da676/eb13a/b058e/c5cd2", "da676/eb13a/f86ef/bff93", "da676/b0e2b/f053f", "da676/b0e2b/e9c55", "da676/a5d9e/d6ba6/f3211", "hbs!templates/room/header/RoomInfo", "lang/Lang" ], function( e, t, n, r, i, s, o, u, a, f, l, c, h, p, d, v, m, g ) {', 'u') ==> "da676/cba08/ee33b"
        [a, b] = haystack.split "], function("
        a .= substr(a.indexOf('"')).split('", "')
        b .= substr(0, b.indexOf(')')).split(', ')
        if b[a.indexOf(needle)]
            try window[that] = require needle
            return that
        else if a[b.indexOf(needle)]
            try window[needle] = require that
            return that



    logOnce: (base, event) ->
        if not event
            event = base
            if -1 != event.indexOf \:
                base = _$context
            else
                base = API
        base.once \event, logger(event)

    usernameToSlug: (un) ->
        /* note: this is NOT really accurate! */
        lastCharWasLetter = false
        res = ""
        for char in htmlEscape(un)
            if (lc = char.toLowerCase!) != char.toUpperCase!
                if /\w/ .test lc
                    res += char.toLowerCase!
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

    reconnectSocket: ->
        _$context .trigger \force:reconnect
    ghost: ->
        $.get '/'


    getAvatars: ->
        API.once \p0ne:avatarsloaded, logger \AVATARS
        $.get $("script[src^='https://cdn.plug.dj/_/static/js/avatars.']").attr(\src) .then (d) ->
          if d.match /manifest.*/
            API.trigger \p0ne:avatarsloaded, JSON.parse that[0].substr(11, that[0].length-12)


module \renameUser, do
    require: <[ users ]>
    module: (idOrName, newName) ->
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


do ->
    window._$events =
        _update: ->
            for k,v of _$context?._events
                @[k.replace(/:/g,'_')] = v
    _$events._update!


module \export_, do
    require: <[ downloadLink ]>
    exportRCS: ->
        # $ '.p0ne_downloadlink' .remove!
        for k,v of localStorage
            downloadLink "plugDjChat '#k'", k.replace(/plugDjChat-(.*?)T(\d+):(\d+):(\d+)\.\d+Z/, "$1 $2.$3.$4.html"), v

    exportPlaylists: ->
        # $ '.p0ne_downloadlink' .remove!
        for let pl in playlists
            $.get "/_/playlists/#{pl.id}/media" .then (data) ->
                downloadLink "playlist '#{pl.name}'",  "#{pl.name}.txt", data



window.copyChat = (copy) ->
    $ '#chat-messages img' .fixSize!
    host = p0ne.host
    res = """
        <head>
        <title>plug.dj Chatlog #{getTime!} - #{getRoomSlug!} (#{API.getUser!.username})</title>
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

/*@source p0ne.userHistory.ls */

requireHelper \userRollover, (.id == \user-rollover)
requireHelper \RoomHistory, ((it) -> it::?listClass == \history and it::hasOwnProperty \listClass) #((it) -> it.onPointsChange && it._events?.reset)
#HistoryItem = RoomHistory::collection.model if RoomHistory

ObjWrap = (obj) ->
    obj.get = (name) -> return this[name]
    return obj

module \userHistory, do
    require: <[ userRollover RoomHistory ]>
    help: '''
        Shows another user's song history when clicking on their username in the user-rollover.

        Due to technical restrictions, only Youtube songs can be shown.
    '''
    setup: ({addListener, replace, css}) ->
        css \userHistory, '#user-rollover .username { cursor: pointer }'
        addListener $(\body), \click, '#user-rollover .username', ->
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
                getUserData userID .then (d) ->
                    user.set \slug, d.slug
                    loadUserHistory user
            else
                loadUserHistory user

        function loadUserHistory user
            $.get "https://plug.dj/@/#{user.get \slug}"
                .fail ->
                    console.error "! couldn't load user's history"
                .then (d) ->
                    userRollover.cleanup!
                    songs = new backbone.Collection()
                    d.replace /<div class="row">\s*<img src="(.*)"\/>\s*<div class="meta">\s*<span class="author">(.*?)<\/span>\s*<span class="name">(.*?)<\/span>[\s\S]*?positive"><\/i><span>(\d+)<\/span>[\s\S]*?grabs"><\/i><span>(\d+)<\/span>[\s\S]*?negative"><\/i><span>(\d+)<\/span>[\s\S]*?listeners"><\/i><span>(\d+)<\/span>/g, (,img, author, roomName, positive, grabs, negative, listeners) ->
                        if cid = /\/vi\/(.{11})\//.exec(img)
                            cid = cid.1
                            [title, author] = author.split " - "
                            songs.add new ObjWrap do
                                user: {id: user.id, username: "in #roomName"}
                                room: {name: roomName}
                                score:
                                    positive: positive
                                    grabs: grabs
                                    negative: negative
                                    listeners: listeners
                                    skipped: 0
                                media: new ObjWrap do
                                    format: 1
                                    cid: cid
                                    author: author
                                    title: title
                                    image: httpsify(img)
                    console.info "#{getTime!} [userHistory] loaded history for #{user.get \username}", songs
                    export songs, d
                    replace RoomHistory::, \collection, -> return songs
                    _$context.trigger \show:history
                    _.defer ->
                        RoomHistory::.collection = RoomHistory::.collection_
                        console.log "#{getTime!} [userHistory] restoring room's proper history"

/*@source p0ne.ponify.ls */
/**
 * ponify chat - a script to ponify some words in the chat on plug.dj
 * Text ponification based on http://pterocorn.blogspot.dk/2011/10/ponify.html
 * @author jtbrinkmann aka. Brinkie Pie
 * @version 1.0
 * @license MIT License
 * @copyright (c) 2014 J.-T. Brinkmann
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
        "human":        "pony"
        "humans":       "ponies"
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
        msg.message .= replace @regexp, (_, pre, s, post, i) ~>
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

            if pre
                if "aeioujyh".has(w.0)
                    r = "an #r"
                else
                    r = "a #r"

            if post
                if "szxß".has(w[*-1])
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
        '???': name: \applejackconfused, url: "https://i.imgur.com/c4moR6o.png"

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


    setup: ({addListener, replace, css}) ->
        @regexp = ///(?:^|https?:)(\b|an?\s+)(#{Object.keys @map .join '|' .replace(/\s+/g,'\\s*')})('s?)?\b//gi
        addListener _$context, \chat:plugin, (msg) ~> @ponifyMsg msg
        if emoticons?
            aEM = {}<<<<emoticons.autoEmoteMap
            for emote, {name, url} of @autoEmotiponies
                aEM[emote] = name
                @emotiponies[name] = url
            replace emoticons, \autoEmoteMap, -> return aEM

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
            replace emoticons, \map, -> return m
            emoticons.update?!
    disable: ->
        emoticons.update?!


/*@source p0ne.fimplug.ls */
/**
 * fimplug related modules
 * @author jtbrinkmann aka. Brinkie Pie
 * @version 1.0
 * @license MIT License
 * @copyright (c) 2014 J.-T. Brinkmann
 */

/*not really implemented yet*/
module \songNotifRuleskip, do
    require: <[ songNotif ]>
    setup: ({replace, addListener}) ->
        replace songNotif, \skip, -> return ($notif) ->
            songNotif.showDescription $notif, """
                <span class="ruleskip-btn ruleskip-1" data-rule=1>!ruleskip 1 MLP-related only</span>
                <span class="ruleskip-btn" data-rule=2>!ruleskip 2 Loops / Pictures</span>
                <span class="ruleskip-btn" data-rule=3>!ruleskip 3 low-efford mixes</span>
                <span class="ruleskip-btn" data-rule=4>!ruleskip 4 history</span>
                <span class="ruleskip-btn" data-rule=6>!ruleskip 6 &gt;10min</span>
                <span class="ruleskip-btn" data-rule=13>!ruleskip 13 clop/porn/gote</span>
                <span class="ruleskip-btn" data-rule=14>!ruleskip 14 episode / not music</span>
                <span class="ruleskip-btn" data-rule=23>!ruleskip 23 WD-only</span>
            """
        addListener chatDomEvents, \click, \.ruleskip-btn, (btn) ->
            songNotif.hideDescription!
            if num = $ btn .data \rule
                API.sendChat "!ruleskip #num"

module \fimstats, do
    setup: ({addListener, $create}) ->
        $el = $create '<span class=p0ne-last-played>' .appendTo \#now-playing-bar
        addListener API, \advance, @updateStats = (d) ->
            d ||= media: API.getMedia!
            if d.media
                $.getJSON "https://fimstats.anjanms.com/_/media/#{d.media.format}/#{d.media.cid}"
                    .then (d) ->
                        first = "#{d.data.0.firstPlay.user} #{ago d.data.0.firstPlay.time*1000}"
                        last = "#{d.data.0.lastPlay.user} #{ago d.data.0.lastPlay.time*1000}"
                        if first != last
                            $el.text "last played by #last \xa0 - \xa0 first played by #first"
                        else
                            $el.text "first&last played by #first"
                    .fail (,,status) ->
                        if status == "Not Found"
                            $el.text "first played just now!"
                        else
                            $el.text ""

            else
                $el.text ""
        @updateStats!

