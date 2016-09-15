#== fix problems with requireJS ==
requirejs.define = window.define
window.require = window.define = window.module = false
window.module = false