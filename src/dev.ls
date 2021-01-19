t1 = Date.now!
require! <[fs path template yargs express open ./server]>

argv = yargs
  .option \root, do
    alias: \r
    description: "root directory"
    type: \string
  .option \port, do
    alias: \p
    description: "port to listen"
    type: \number
  .option \open, do
    alias: \o
    description: "open browser on startup"
    type: \bool
  .help \help
  .alias \help, \h
  .check (argv, options) -> return true
  .argv

root = argv.r
do-open = argv.o
port = argv.p or process.env.PORT

opt = {start-time: t1, port: port}

if root => process.chdir root
server.init opt
  .then ({server,app}) -> 
    if do-open => open "http://localhost:#{server.address!port}"
    app.use \/, express.static \static
template.watch.init opt

