# screenshot

simple express server that accepts URL or html code and respond with screenshot. powered by puppeteer.


## Usage

install required modules by `npm install`, then run `npm start`. this will start a screenshot server listening to specific port configured in config.json.

to take a screenshot, send a POST request to `<domain>/api` with a payload in below format:

    { url: "url-to-screenshot"}

or

    { html: "code-to-render" }

For example:

    payload = {url: "https://google.com"}
    ld$.fetch "http://localhost:9010/api/", {method: \POST}, {json: payload}
      .then -> it.arrayBuffer!
      .then -> URL.createObjectURL(new Blob([new Uint8Array(it, 0, it.length)], {type: "image/png"}))
      .then (url) ->
        img = new Image!
        img.src = url


## API

    require! <[screenshot]>
    ss = new screenshot opt
    lc = {}
    ss.init!
      .then -> ss.get!
      .then (obj) ->
        lc.obj = obj
        # either one of following
        # obj.page.setContent html, {waitUntil: "domcontentloaded"}
        # obj.page.goto url
      .then -> lc.obj.page.screenshot!
      .then -> ss.free lc.obj


## Configuration

edit config.json for changing listening port. default 9010


## License

MIT
