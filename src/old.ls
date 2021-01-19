require! <[fs express body-parser puppeteer colors]>

locale = {}

screenshot = (opt = {}) ->
  @opt = opt
  @count = ((opt.count or 4) <? 20)
  @queue = []
  @

screenshot.prototype = Object.create(Object.prototype) <<< do
  shot: (payload = {}) ->
    lc = {}
    @get!
      .then (obj) ->
        lc.obj = obj
        if payload.html => obj.page.setContent payload.html, {waitUntil: "domcontentloaded"}
        else if payload.url => obj.page.goto payload.url
        else return Promise.reject(new Error("missing url or html in screenshot.shot"))
      .then -> lc.obj.page.screenshot!
      .then -> lc.thumb = it
      .then ~> @free lc.obj
      .then -> return lc.thumb

  get: -> new Promise (res, rej) ~>
    for i from 0 til @count =>
      if !@pages[i].busy =>
        @pages[i].busy = true
        return res @pages[i]
    @queue.push {res, rej}

  free: (obj) ->
    if @queue.length =>
      ret = @queue.splice(0, 1).0
      ret.res obj
    else
      obj.busy = false

  init: ->
    (if locale.browser => Promise.resolve(that) else puppeteer.launch!)
      .then (browser) ~>
        locale.browser = browser
        Promise.all (for i from 0 til @count => browser.newPage!then(-> {busy: false, page: it}))
      .then ~> @pages = it

module.exports = screenshot
