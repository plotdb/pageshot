# pageshot

simple express server and APIs powered by puppeteer for following purpose:

 - web page screenshot
 - web page to pdf
 - pdf merge


## Security Note

Puppeteer runs headless browser which can access content within intranet, and thus might be vulnerable to [SSRF](https://en.wikipedia.org/wiki/Server-side_request_forgery) exploit. To accept arbitrary user input, try running pageshot server in a container with proper network configuration.



## Usage

install:

    npm install --save @plotdb/pageshot


run api server:

    npx pageshot -p <port>

this will start a screenshot server listening to specific port.


To take a screenshot, send a POST request to `<domain>/api/screenshot` with a payload in below format:

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


There are 3 api curently available:

 - POST `/api/screenshot` - taking screenshot in png format. 
 - POST `/api/print` - taking screenshot in pdf format. input similar to `/api/screenshot`.
 - POST `/api/merge` - merge multiple document into one pdf. payload format:
   - `list`: a list of documents to merge. Each is an object with following format:
     - `html`: html code to print and merge.
     - `url`: url for web page to print and merge. omitted when `html` is available
     - `pdffile`: file path for pdf file to merge.
     - `pdflink`: url for pdf file to merge.
       - note: `pdffile` and `pdflink` only work in nodeJS API when calling with `trust-input` set to true. see `API`.

## API

`@plotdb/pageshot` also provides JS api for those http api counterpart. To use JS api, first init a `pageshot` page mananger:

    require! <[pageshot]>
    ss = new pageshot( opt )

options:

 * count - size of page pool. default 4, max 20.


screenshot object API:

 * init - initialize page manager. must be called before used.
 * shot(payload) - take a screenshot, return Buffer of the image in PNG format.
 * get - get a page handler. must free it after using. return an object as:
   - busy - is this page occupied
   - page - the page object. check puppeteer for more information. sample usage:
     - page.setContent "some html code", {waitUntil, "domcontentloaded"}
     - page.goto "some-url"
 * free(obj) - free this page.
 * print({url, html}): print specific document.
 * screenshot({url, html}): screenshot specific document.
 * merge(payload, trustInput): merge multiple document.
   - `payload`: as described in previous section.
   - `trustInput`: default false. when set to true, `pdffile` and `pdflink` options are enabled.


Sample usage:

    lc = {}
    ps = new pageshot!
    ps.init!
      # take a screenshot of google.com through ps.screenshot API
      .then -> ps.screenshot url: "https://google.com"
      .then -> fs.write-file-sync "out.png", it

      # ... or, manually operate the page instance
      .then -> ps.get!
      .then (obj) ->
        lc.obj = obj
        # either one of following
        # obj.page.setContent html, {waitUntil: "domcontentloaded"}
        # obj.page.goto url
      .then -> lc.obj.page.screenshot!
      .then -> ps.free lc.obj


## PDF Merge

PDF merging is provided by `easy-pdf-merge`, which in turn depends on related `java` package. Java is needed for using this functionality, and can be installed via following commands:


    wget -qO - https://adoptopenjdk.jfrog.io/adoptopenjdk/api/gpg/key/public | sudo apt-key add -
    sudo apt-get install software-properties-common
    sudo add-apt-repository --yes https://adoptopenjdk.jfrog.io/adoptopenjdk/deb/
    sudo apt-get update && sudo apt-get install adoptopenjdk-8-hotspot


## License

MIT
