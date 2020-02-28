require! <[fs express body-parser colors ./screenshot]>

server = do
  init: (opt) ->
    ss = new screenshot opt
    ss.init!
      .then ->
        app = express!
        cwd = process.cwd!
        app.use body-parser.json({limit: '1mb'})
        app.use (req, res, next) ->
          res.header \Access-Control-Allow-Origin, "*"
          res.header \Access-Control-Allow-Headers, "Origin, X-Requested-With, Content-Type, Accept"
          next!
        app.post \/api/, (req, res) ->
          lc = {}
          payload = if req.body.url => {url: req.body.url} else {html: req.body.html or ""}
          ss.shot payload
            .then ->
              res.contentType \image/png
              res.send it
            .catch -> res.status 500 .send!

        console.log "[Server] Express Initialized in #{app.get \env} Mode".green
        server = app.listen opt.port, ->
          delta = if opt.start-time => "( takes #{Date.now! - opt.start-time}ms )" else ''
          console.log "[SERVER] listening on port #{server.address!port} #delta".cyan

module.exports = server
if require.main == module => server.init JSON.parse(fs.read-file-sync('config.json').toString!)
