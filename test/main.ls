require! <[fs ../lib/screenshot]>
ss = new screenshot!
ss.init!
  .then -> ss.shot url: "https://google.com"
  .then -> fs.write-file-sync "google.png", it
  .then -> process.exit 0
