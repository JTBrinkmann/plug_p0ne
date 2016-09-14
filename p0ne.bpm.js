/*@author jtbrinkmann aka. Brinkie Pie aka. Brinkie Pumpkin */
/*@source plug_p0ne.bpm.ls */
/*
    based on BetterPonymotes https://ponymotes.net/bpm/
    note: even though this is part of the plug_p0ne script, it can also run on it's own with no dependencies 
    only the autocomplete feature will be missing without plug_p0ne

    for a ponymote tutorial see: http://www.reddit.com/r/mylittlepony/comments/177z8f/how_to_use_default_emotes_like_a_pro_works_for/
*/
var host, ref$, _FLAG_NSFW, _FLAG_REDIRECT, emote_regexp, sanitize_emote, lookup_core_emote, convert_emote_element, ref1$, test, module, _$context, id;
host = ((ref$ = window.p0ne) != null ? ref$.host : void 8) || "https://dl.dropboxusercontent.com/u/4217628/plug_p0ne";
window.emote_map = {};


/*== external sources ==*/
$.getScript(host + "/bpm-resources.js");
$('body').append("<link rel=\"stylesheet\" href=\"" + host + "/css/bpmotes.css\" type=\"text/css\">\n<link rel=\"stylesheet\" href=\"" + host + "/css/emote-classes.css\" type=\"text/css\">\n<link rel=\"stylesheet\" href=\"" + host + "/css/combiners-nsfw.css\" type=\"text/css\">\n<link rel=\"stylesheet\" href=\"" + host + "/css/gif-animotes.css\" type=\"text/css\">\n<link rel=\"stylesheet\" href=\"" + host + "/css/extracss-pure.css\" type=\"text/css\">\n<style>\n#chat-suggestion-items .bpm-emote {\n    max-width: 27px;\n    max-height: 27px\n}\n</style>");


/*== constants ==*/
_FLAG_NSFW = 1;
_FLAG_REDIRECT = 2;


/*
 * As a note, this regexp is a little forgiving in some respects and strict in
 * others. It will not permit text in the [] portion, but alt-text quotes don't
 * have to match each other.
 */
/*                 [](/   <    emote   >   <    alt-text   >  )*/
emote_regexp = /\[\]\(\/([\w:!#\/\-]+)\s*(?:["']([^"]*)["'])?\)/g;


/*== auxiliaries ==*/
/*
 * Escapes an emote name (or similar) to match the CSS classes.
 *
 * Must be kept in sync with other copies, and the Python code.
 */
sanitize_emote = function(s){
  return s.toLowerCase().replace("!", "_excl_").replace(":", "_colon_").replace("#", "_hash_").replace("/", "_slash_");
};
lookup_core_emote = function(name, altText){
  var data, nameWithSlash, parts, flag_data, tag_data, flags, source_id, size, is_nsfw, is_redirect, tags, start, str, base;
  data = emote_map[name];
  if (!data) {
    return null;
  }
  nameWithSlash = "/" + name;
  parts = data.split('|');
  flag_data = parts[0];
  tag_data = parts[1];
  flags = parseInt(flag_data.slice(0, 1), 16);
  source_id = parseInt(flag_data.slice(1, 3), 16);
  size = parseInt(flag_data.slice(3, 7), 16);
  is_nsfw = flags & _FLAG_NSFW;
  is_redirect = flags & _FLAG_REDIRECT;
  tags = [];
  start = 0;
  while ((str = tag_data.slice(start, start + 2)) !== "") {
    tags.push(parseInt(str, 16));
    start += 2;
  }
  if (is_redirect) {
    base = parts[2];
  } else {
    base = name;
  }
  return {
    name: nameWithSlash,
    is_nsfw: !!is_nsfw,
    source_id: source_id,
    source_name: sr[source_id],
    max_size: size,
    tags: tags,
    css_class: "bpmote-" + sanitize_emote(name),
    base: base,
    altText: altText
  };
};
convert_emote_element = function(info, parts){
  var title, flags, i$, len$, i, flag;
  title = (info.name + " from " + info.source_name).replace(/"/g, '');
  flags = "";
  for (i$ = 0, len$ = parts.length; i$ < len$; ++i$) {
    i = i$;
    flag = parts[i$];
    if (i > 0) {
      /* Normalize case, and forbid things that don't look exactly as we expect */
      flag = sanitize_emote(flag.toLowerCase());
      if (!/\W/.test(flag)) {
        flags += " bpflag-" + flag;
      }
    }
  }
  if (info.is_nsfw) {
    if (info.is_nsfw) {
      title = "[NSFW] " + title;
    }
    flags += " bpm-nsfw";
  }
  return "<span class='bpflag-in bpm-emote " + info.css_class + " " + flags + "' title='" + title + "' data-bpm_emotename='" + info.name + "'>" + (info.altText || '') + "</span>";
};


window.bpm = function(str){
  return str.replace(emote_regexp, function(_, parts, altText){
    var name, info;
    parts = parts.split('-');
    name = parts[0];
    info = lookup_core_emote(name, altText);
    if (!info) {
      return _;
    } else {
      return convert_emote_element(info, parts);
    }
  });
};


if (window.p0ne) {
  /* add BPM as a p0ne chat plugin */
  if ((ref$ = window.p0ne) != null) {
    if ((ref1$ = ref$.chatPlugins) != null) {
      ref1$[ref1$.length] = window.bpm;
    }
  }
} else {
  /* add BPM as a standalone script */
  if (!window._$context) {
    test = function(it){
      var ref$;
      return (ref$ = it._events) != null ? ref$['chat:receive'] : void 8;
    };
    module = window.require.s.contexts._.defined['b1b5f/b8d75/c3237'];
    if (module && test(module)) {
      _$context = module;
    } else {
      for (id in ref$ = require.s.contexts._.defined) {
        module = ref$[id];
        if (module && test(module, id)) {
          _$context = module;
          break;
        }
      }
    }
  }
  _$context._events['chat:receive'].unshift({
    callback: function(d){
      d.message = bpm(d.message);
    }
  });
}
$(window).one('p0ne_emotes_map', function(){
  var cb;
  console.log("== Ponymotes loaded ==");
  /* add autocomplete if/when plug_p0ne and plug_p0ne.autocomplete are loaded */
  cb = function(){
    return typeof addAutocompletion === 'function' ? addAutocompletion({
      name: "Ponymotes",
      data: Object.keys(emote_map),
      pre: "[]",
      check: function(str, pos){
        var temp;
        if (!str[pos + 2] || str[pos + 2] === "(" && (!str[pos + 3] || str[pos + 3] === "(/")) {
          temp = /^\[\]\(\/([\w#\\!\:\/]+)(\s*["'][^"']*["'])?(\))?/.exec(str.substr(pos));
          if (temp) {
            this.data = temp[2] || '';
            return true;
          }
        }
        return false;
      },
      display: function(items){
        var emote;
        return (function(){
          var i$, ref$, len$, results$ = [];
          for (i$ = 0, len$ = (ref$ = items).length; i$ < len$; ++i$) {
            emote = ref$[i$];
            results$.push({
              value: "[](/" + emote + ")",
              image: bpm("[](/" + emote + ")")
            });
          }
          return results$;
        }());
      },
      insert: function(suggestion){
        return suggestion.substr(0, suggestion.length - 1) + "" + this.data + ")";
      }
    }) : void 8;
  };
  if (window.addAutocompletion) {
    return cb();
  } else {
    return $(window).one('p0ne_autocomplete', cb);
  }
});