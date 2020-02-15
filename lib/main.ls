require! <[fs express body-parser puppeteer colors]>

server = do
  init: (opt) ->
    lc = {count: ((opt.count or 4) <? 20)}
    page-manager = do
      queue: []
      get: -> new Promise (res, rej) ->
        for i from 0 til lc.count =>
          if !lc.pages[i].busy =>
            lc.pages[i].busy = true
            return res lc.pages[i]
        page-manager.queue.push {res, rej}
      free: (page) ->
        if page-manager.queue.length =>
          ret = page-manager.queue.splice(0, 1).0
          ret.res page
        else
          page.busy = false
    puppeteer.launch!
      .then ->
        lc.browser = it
        list = []
        for i from 0 til lc.count =>
          list.push lc.browser.newPage!then -> {busy: false, page: it}
        Promise.all list
      .then ->
        lc.pages = it
        lc.app = app = express!
        cwd = process.cwd!

        app.use body-parser.json({limit: '1mb'})
        app.use (req, res, next) ->
          res.header \Access-Control-Allow-Origin, "*"
          res.header \Access-Control-Allow-Headers, "Origin, X-Requested-With, Content-Type, Accept"
          next!
        app.post \/api/, (req, res) ->
          api-lc = {}
          page-manager.get!
            .then ->
              api-lc <<< it
              promise = (
                if req.body.url => api-lc.page.goto req.body.url
                else if req.body.html => lc.page.setContent req.body.html, {waitUntil: "domcontentloaded"}
              )
            .then -> api-lc.page.screenshot!
            .then ->
              res.contentType \image/png
              res.send it
            .catch ->
              console.log it
              res.status 500 .send!
            .then ->
              page-manager.free api-lc

       
        console.log "[Server] Express Initialized in #{app.get \env} Mode".green
        server = app.listen opt.port, ->
          delta = if opt.start-time => "( takes #{Date.now! - opt.start-time}ms )" else ''
          console.log "[SERVER] listening on port #{server.address!port} #delta".cyan

module.exports = server
if require.main == module => server.init JSON.parse(fs.read-file-sync('config.json').toString!)
