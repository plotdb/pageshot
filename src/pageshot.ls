require! <[fs puppeteer easy-pdf-merge node-cleanup tmp request]>

tmpfn = ->
  (res, rej) <- new Promise _
  tmp.file (err, path, fd, cb) ->
    if err => return rej err
    res {fn: path, clean: cb}

Pageshot = (opt = {}) ->
  @opt = opt
  @count = ((opt.count or 4) <? 10000)
  @retry-count = 5
  @queue = []

  node-cleanup (ec, signal) ~> @destroy!; node-cleanup.uninstall!; return false

  @

Pageshot.prototype = Object.create(Object.prototype) <<< do
  exec: (cb) ->
    lc = {trial: 0}
    _ = ~>
      @get!
        .then (obj) -> lc.obj = obj
        .then -> cb(lc.obj.page)
        .then -> lc.ret = it
        .catch ~>
          if (lc.trial++) > @retry-count => return Promise.reject(new Error! <<< {id: 0, name: \lderror})
          console.error "[pageshot] command failed, will retry ( #{lc.trial} ): ", it
          @respawn lc.obj .then -> _!
        .then ~> @free lc.obj
        .then -> return lc.ret
    _!

  screenshot: (payload = {}) -> @exec (page) ->
    p = if payload.html => page.setContent payload.html, {waitUntil: "domcontentloaded"}
    else if payload.url => page.goto payload.url
    else Promise.reject(new Error! <<< {id: 1015, name: \lderror, msg: "missing url or html"})
    p.then -> page.screenshot!

  print: (payload = {}) -> @exec (page) ->
    p = if payload.html => page.setContent payload.html, {waitUntil: "networkidle0"}
    else if payload.url => page.goto payload.url
    else Promise.reject(new lderror(1015))
    p.then ->
      ret = page.pdf format: \A4
      return ret

  # list: [{html, url, pdffile, pdflink}, ... ]
  merge: (payload = {}, trust-input = false) ->
    promises = payload.list.map (item) ~>
      if !trust-input =>
        if item.url and !/^https:\/\//.exec(item.url) => return null
        if item.pdflink and !/^https:\/\//.exec(item.pdflink) => return null
        if item.pdffile => return null
      if item.html or item.url =>
        @print(item{html, url}).then (buf) -> tmpfn!then ({fn}) ->
          (res, rej) <- new Promise _
          (e) <- fs.write-file fn, buf, _
          if e => return rej new Error(e)
          res fn
      else if item.pdffile => return Promise.resolve(item.pdffile)
      else if item.pdflink =>
        (res, rej) <- new Promise _
        (e,r,b) <- request {url: item.pdflink, method: \GET, encoding: null}, _
        if e => return rej new Error(e)
        ({fn}) <- tmpfn!then _
        (e) <- fs.write-file fn, b, _
        if e => rej new Error(e)
        res fn

    Promise.all promises.filter(->it)
      .then (files) ->
        ({fn}) <- tmpfn!then _
        (res, rej) <- new Promise _
        (e) <- easy-pdf-merge files, fn, _
        if e => return rej e
        (e, buf) <- fs.read-file fn, _
        if e => return rej e
        res buf

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
    if Pageshot.browser => that.close!

  init: ->
    (if Pageshot.browser => Promise.resolve(that) else puppeteer.launch({headless: true, args: <[--no-sandbox]>}))
      .then (browser) ~>
        Pageshot.browser = browser
        Promise.all (for i from 0 til @count => browser.newPage!then(-> {busy: false, page: it}))
      .then ~> @pages = it

  respawn: (obj) ->
    Promise.resolve!
      .then -> if !(obj.page.isClosed!) => page.close!
      .catch -> # failed to close. anyway, just ignore it and create a new page.
      .then -> Pageshot.browser.newPage!
      .then (page) ~> obj.page = page

module.exports = Pageshot
