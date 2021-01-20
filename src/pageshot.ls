require! <[puppeteer easy-pdf-merge node-cleanup]>

BrowserPool = (opt = {}) ->
  @opt = opt
  @count = ((opt.count or 4) <? 10000)
  @retry-count = 5
  @queue = []

  node-cleanup (ec, signal) ~> @destroy!; node-cleanup.uninstall!; return false

  @

BrowserPool.prototype = Object.create(Object.prototype) <<< do
  exec: (cb) ->
    lc = {trial: 0}
    _ = ~>
      @get!
        .then (obj) -> lc.obj = obj
        .then -> cb(lc.obj.page)
        .then -> lc.ret = it
        .catch ~>
          if (lc.trial++) > @retry-count => return Promise.reject(new Error! <<< {id: 0, name: \ldError})
          console.error "[pageshot] command failed, will retry ( #{lc.trial} ): ", it
          @respawn lc.obj .then -> _!
        .then ~> @free lc.obj
        .then -> return lc.ret
    _!

  screenshot: (payload = {}) -> @exec (page) ->
    p = if payload.html => page.setContent payload.html, {waitUntil: "domcontentloaded"}
    else if payload.url => page.goto payload.url
    else Promise.reject(new Error! <<< {id: 1015, name: \ldError, msg: "missing url or html"})
    p.then -> page.screenshot!

  print: (payload = {}) -> @exec (page) ->
    p = if payload.html => page.setContent payload.html, {waitUntil: "networkidle0"}
    else if payload.url => page.goto payload.url
    else Promise.reject(new ldError(1015))
    p.then ->
      ret = page.pdf format: \A4
      return ret

  merge: (payload = {}) ->
    Promise.resolve!
      .then ~>
        if !payload.html => return null
        @print {html: payload.html} .then (buf) ->
          tmpfn!then ({fn}) ->
            (res, rej) <- new Promise _
            (e) <- fs.write-file fn, buf, _
            if e => return rej new Error(e)
            res fn
      .then (html-fn) ->
        if !payload.files or payload.files.length < 1 or (payload.files.length == 1 and !html-fn) =>
          return Promise.reject(new lderror(400))
        (res, rej) <- new Promise _
        (e) <- easy-pdf-merge ((if html-fn => [html-fn] else []) ++ payload.files), payload.outfile, _
        if e => return rej e
        res payload.outfile

  get: -> new Promise (res, rej) ~>
    for i from 0 til @pages.length =>
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

  destroy: ->
    @pages.map ({page}) -> page.close!
    if BrowserPool.browser => that.close!

  init: ->
    (if BrowserPool.browser => Promise.resolve(that) else puppeteer.launch({headless: true, args: <[--no-sandbox]>}))
      .then (browser) ~>
        BrowserPool.browser = browser
        Promise.all (for i from 0 til @count => browser.newPage!then(-> {busy: false, page: it}))
      .then ~> @pages = it

  respawn: (obj) ->
    Promise.resolve!
      .then -> if !(obj.page.isClosed!) => page.close!
      .catch -> # failed to close. anyway, just ignore it and create a new page.
      .then -> BrowserPool.browser.newPage!
      .then (page) ~> obj.page = page

module.exports = BrowserPool
