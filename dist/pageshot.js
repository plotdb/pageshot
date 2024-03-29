var fs, puppeteer, easyPdfMerge, nodeCleanup, tmp, request, tmpfn, Pageshot;
fs = require('fs');
puppeteer = require('puppeteer');
easyPdfMerge = require('easy-pdf-merge');
nodeCleanup = require('node-cleanup');
tmp = require('tmp');
request = require('request');
tmpfn = function(){
  return new Promise(function(res, rej){
    return tmp.file(function(err, path, fd, cb){
      if (err) {
        return rej(err);
      }
      return res({
        fn: path,
        clean: cb
      });
    });
  });
};
Pageshot = function(opt){
  var ref$, this$ = this;
  opt == null && (opt = {});
  this.opt = opt;
  this.count = (ref$ = opt.count || 4) < 10000 ? ref$ : 10000;
  this.retryCount = 5;
  this.queue = [];
  nodeCleanup(function(ec, signal){
    this$.destroy();
    nodeCleanup.uninstall();
    return false;
  });
  return this;
};
Pageshot.prototype = import$(Object.create(Object.prototype), {
  exec: function(cb){
    var lc, _, this$ = this;
    lc = {
      trial: 0
    };
    _ = function(){
      return this$.get().then(function(obj){
        return lc.obj = obj;
      }).then(function(){
        return cb(lc.obj.page);
      }).then(function(it){
        return lc.ret = it;
      })['catch'](function(it){
        var ref$;
        if ((lc.trial++) > this$.retryCount) {
          return Promise.reject((ref$ = new Error(), ref$.id = 0, ref$.name = 'lderror', ref$));
        }
        console.error("[pageshot] command failed, will retry ( " + lc.trial + " ): ", it);
        return this$.respawn(lc.obj).then(function(){
          return _();
        });
      }).then(function(){
        return this$.free(lc.obj);
      }).then(function(){
        return lc.ret;
      });
    };
    return _();
  },
  screenshot: function(payload){
    payload == null && (payload = {});
    return this.exec(function(page){
      var p, ref$;
      p = payload.html
        ? page.setContent(payload.html, {
          waitUntil: "domcontentloaded"
        })
        : payload.url
          ? page.goto(payload.url)
          : Promise.reject((ref$ = new Error(), ref$.id = 1015, ref$.name = 'lderror', ref$.msg = "missing url or html", ref$));
      return p.then(function(){
        return page.screenshot();
      });
    });
  },
  print: function(payload){
    payload == null && (payload = {});
    return this.exec(function(page){
      var p;
      p = payload.html
        ? page.setContent(payload.html, {
          waitUntil: "networkidle0"
        })
        : payload.url
          ? page.goto(payload.url)
          : Promise.reject(new lderror(1015));
      return p.then(function(){
        var ret;
        ret = page.pdf({
          format: 'A4'
        });
        return ret;
      });
    });
  },
  merge: function(payload, trustInput){
    var promises, this$ = this;
    payload == null && (payload = {});
    trustInput == null && (trustInput = false);
    promises = payload.list.map(function(item){
      if (!trustInput) {
        if (item.url && !/^https:\/\//.exec(item.url)) {
          return null;
        }
        if (item.pdflink && !/^https:\/\//.exec(item.pdflink)) {
          return null;
        }
        if (item.pdffile) {
          return null;
        }
      }
      if (item.html || item.url) {
        return this$.print({
          html: item.html,
          url: item.url
        }).then(function(buf){
          return tmpfn().then(function(arg$){
            var fn;
            fn = arg$.fn;
            return new Promise(function(res, rej){
              return fs.writeFile(fn, buf, function(e){
                if (e) {
                  return rej(new Error(e));
                }
                return res(fn);
              });
            });
          });
        });
      } else if (item.pdffile) {
        return Promise.resolve(item.pdffile);
      } else if (item.pdflink) {
        return new Promise(function(res, rej){
          return request({
            url: item.pdflink,
            method: 'GET',
            encoding: null
          }, function(e, r, b){
            if (e) {
              return rej(new Error(e));
            }
            return tmpfn().then(function(arg$){
              var fn;
              fn = arg$.fn;
              return fs.writeFile(fn, b, function(e){
                if (e) {
                  rej(new Error(e));
                }
                return res(fn);
              });
            });
          });
        });
      }
    });
    return Promise.all(promises.filter(function(it){
      return it;
    })).then(function(files){
      return tmpfn().then(function(arg$){
        var fn;
        fn = arg$.fn;
        return new Promise(function(res, rej){
          return easyPdfMerge(files, fn, function(e){
            if (e) {
              return rej(e);
            }
            return fs.readFile(fn, function(e, buf){
              if (e) {
                return rej(e);
              }
              return res(buf);
            });
          });
        });
      });
    });
  },
  get: function(){
    var this$ = this;
    return new Promise(function(res, rej){
      var i$, to$, i;
      for (i$ = 0, to$ = this$.pages.length; i$ < to$; ++i$) {
        i = i$;
        if (!this$.pages[i].busy) {
          this$.pages[i].busy = true;
          return res(this$.pages[i]);
        }
      }
      return this$.queue.push({
        res: res,
        rej: rej
      });
    });
  },
  free: function(obj){
    var ret;
    if (this.queue.length) {
      ret = this.queue.splice(0, 1)[0];
      return ret.res(obj);
    } else {
      return obj.busy = false;
    }
  },
  destroy: function(){
    var that;
    this.pages.map(function(arg$){
      var page;
      page = arg$.page;
      return page.close();
    });
    if (that = Pageshot.browser) {
      return that.close();
    }
  },
  init: function(){
    var that, this$ = this;
    return ((that = Pageshot.browser)
      ? Promise.resolve(that)
      : puppeteer.launch({
        headless: true,
        args: ['--no-sandbox']
      })).then(function(browser){
      var i;
      Pageshot.browser = browser;
      return Promise.all((function(){
        var i$, to$, results$ = [];
        for (i$ = 0, to$ = this.count; i$ < to$; ++i$) {
          i = i$;
          results$.push(browser.newPage().then(fn$));
        }
        return results$;
        function fn$(it){
          return {
            busy: false,
            page: it
          };
        }
      }.call(this$)));
    }).then(function(it){
      return this$.pages = it;
    });
  },
  respawn: function(obj){
    return Promise.resolve().then(function(){
      if (!obj.page.isClosed()) {
        return page.close();
      }
    })['catch'](function(){}).then(function(){
      return Pageshot.browser.newPage();
    }).then(function(page){
      return obj.page = page;
    });
  }
});
module.exports = Pageshot;
function import$(obj, src){
  var own = {}.hasOwnProperty;
  for (var key in src) if (own.call(src, key)) obj[key] = src[key];
  return obj;
}
