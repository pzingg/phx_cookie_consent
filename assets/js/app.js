// We import the CSS which is extracted to its own file by esbuild.
// Remove this line if you add a your own CSS build pipeline (e.g postcss).

// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "./vendor/some-package.js"
//
// Alternatively, you can `npm install some-package` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"
import Alpine from "../vendor/alpine"

// From live_beats
let nowSeconds = () => Math.round(Date.now() / 1000)
let rand = (min, max) => Math.floor(Math.random() * (max - min) + min)
let isVisible = (el) => !!(el.offsetWidth || el.offsetHeight || el.getClientRects().length > 0)

let execJS = (selector, attr) => {
  document.querySelectorAll(selector).forEach(el => liveSocket.execJS(el, el.getAttribute(attr)))
}

// Accessible focus handling from live_beats
let Focus = {
  focusMain(){
    let target = document.querySelector("main h1") || document.querySelector("main")
    if(target){
      let origTabIndex = target.tabIndex
      target.tabIndex = -1
      target.focus()
      target.tabIndex = origTabIndex
    }
  },
  // Subject to the W3C Software License at https://www.w3.org/Consortium/Legal/2015/copyright-software-and-document
  isFocusable(el){
    if(el.tabIndex > 0 || (el.tabIndex === 0 && el.getAttribute("tabIndex") !== null)){ return true }
    if(el.disabled){ return false }

    switch(el.nodeName) {
      case "A":
        return !!el.href && el.rel !== "ignore"
      case "INPUT":
        return el.type != "hidden" && el.type !== "file"
      case "BUTTON":
      case "SELECT":
      case "TEXTAREA":
        return true
      default:
        return false
    }
  },
  // Subject to the W3C Software License at https://www.w3.org/Consortium/Legal/2015/copyright-software-and-document
  attemptFocus(el){
    if(!el){ return }
    if(!this.isFocusable(el)){ return false }
    try {
      el.focus()
    } catch(e){}

    return document.activeElement === el
  },
  // Subject to the W3C Software License at https://www.w3.org/Consortium/Legal/2015/copyright-software-and-document
  focusFirstDescendant(el){
    for(let i = 0; i < el.childNodes.length; i++){
      let child = el.childNodes[i]
      if(this.attemptFocus(child) || this.focusFirstDescendant(child)){
        return true
      }
    }
    return false
  },
  // Subject to the W3C Software License at https://www.w3.org/Consortium/Legal/2015/copyright-software-and-document
  focusLastDescendant(element){
    for(let i = element.childNodes.length - 1; i >= 0; i--){
      let child = element.childNodes[i]
      if(this.attemptFocus(child) || this.focusLastDescendant(child)){
        return true
      }
    }
    return false
  },
}

let Hooks = {}

// Accessible focus wrapping from live_beats
Hooks.FocusWrap = {
  mounted(){
    this.content = document.querySelector(this.el.getAttribute("data-content"))
    this.focusStart = this.el.querySelector(`#${this.el.id}-start`)
    this.focusEnd = this.el.querySelector(`#${this.el.id}-end`)
    this.focusStart.addEventListener("focus", () => Focus.focusLastDescendant(this.content))
    this.focusEnd.addEventListener("focus", () => Focus.focusFirstDescendant(this.content))
    this.content.addEventListener("phx:show-end", () => this.content.focus())
    if(window.getComputedStyle(this.content).display !== "none"){
      Focus.focusFirstDescendant(this.content)
    }
  },
}

window.Alpine = Alpine
Alpine.start()

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
// From live_beats
let liveSocket = new LiveSocket("/live", Socket, {
  hooks: Hooks,
  params: {_csrf_token: csrfToken},
  dom: {
    onBeforeElUpdated(from, to){
      if (window.Alpine && from._x_dataStack){
        window.Alpine.clone(from, to)
      }
      return true
    },
    onNodeAdded(node){
      if(node instanceof HTMLElement && node.autofocus){
        node.focus()
      }
    }
  }
})

let routeUpdated = ({kind}) => {
  Focus.focusMain()
}

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", info => topbar.show())
window.addEventListener("phx:page-loading-stop", info => topbar.hide())

// Accessible routing from live_beats
window.addEventListener("phx:page-loading-stop", e => routeUpdated(e.detail))

window.addEventListener("js:exec", e => e.target[e.detail.call](...e.detail.args))
window.addEventListener("js:focus", e => {
  let parent = document.querySelector(e.detail.parent)
  if(parent && isVisible(parent)){ e.target.focus() }
})
window.addEventListener("js:focus-closest", e => {
  let el = e.target
  let sibling = el.nextElementSibling
  while(sibling){
    if(isVisible(sibling) && Focus.attemptFocus(sibling)){ return }
    sibling = sibling.nextElementSibling
  }
  sibling = el.previousElementSibling
  while(sibling){
    if(isVisible(sibling) && Focus.attemptFocus(sibling)){ return }
    sibling = sibling.previousElementSibling
  }
  Focus.attemptFocus(el.parent) || Focus.focusMain()
})
window.addEventListener("phx:remove-el", e => document.getElementById(e.detail.id).remove())

// connect if there are any LiveViews on the page
liveSocket.getSocket().onOpen(() => execJS("#connection-status", "js-hide"))
liveSocket.getSocket().onError(() => execJS("#connection-status", "js-show"))

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket
