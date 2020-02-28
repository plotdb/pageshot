require! <[fs express body-parser puppeteer colors]>

locale = {}

screenshot = (opt = {}) ->
  @opt = opt
  @count = ((opt.count or 4) <? 20)
  @queue = []
  @

screenshot.prototype = Object.create(Object.prototype) <<< do
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
