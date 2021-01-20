t1 = Date.now!
require! <[fs path template express body-parser colors yargs]>

lib = path.dirname fs.realpathSync(__filename.replace(/\(.+\)$/,''))
pageshot = require "#lib/pageshot"

server = do
  init: (opt) ->
    ss = new pageshot opt
    ss.init!
      .then ->
        app = express!
        cwd = process.cwd!
        app.use body-parser.json({limit: '1mb'})
        app.use (req, res, next) ->
          res.header \Access-Control-Allow-Origin, "*"
          res.header \Access-Control-Allow-Headers, "Origin, X-Requested-With, Content-Type, Accept"
          next!

        app.post \/api/screenshot, (req, res) ->
          lc = {}
          payload = if req.body.url => {url: req.body.url} else {html: req.body.html or ""}
          ss.screenshot payload
            .then ->
              res.contentType \image/png
              res.send it
            .catch ->
              console.log it
              res.status 500 .send!

        app.post \/api/print, (req, res) ->
          lc = {}
          payload = if req.body.url => {url: req.body.url} else {html: req.body.html or ""}
          ss.print payload
            .then ->
              res.contentType \application/pdf
              res.send it
            .catch ->
              console.log it
              res.status 500 .send!

        app.post \/api/merge, (req, res) ->
          lc = {}
          payload = {list: req.body.list or []}
          ss.merge payload
            .then ->
              res.contentType \application/pdf
              res.send it
            .catch ->
              console.log it
              res.status 500 .send!

        console.log "[Server] Express Initialized in #{app.get \env} Mode".green
        (res, rej) <- new Promise _
        server = app.listen opt.port, ->
          delta = if opt.start-time => "( takes #{Date.now! - opt.start-time}ms )" else ''
          console.log "[SERVER] listening on port #{server.address!port} #delta".cyan
          res {server, app}

module.exports = server
if require.main == module =>
  argv = yargs
    .option \port, do
      alias: \p
      description: "port to listen"
      type: \number
    .help \help
    .alias \help, \h
    .check (argv, options) -> return true
    .argv
  port = argv.p or process.env.PORT
  server.init {start-time: t1, port: port}
