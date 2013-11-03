+function() {
Pusher.log = function(message) {
    if (window.console && window.console.log) {
        window.console.log(message);
    }
};

function make_pusher(room) {
    var pusher = new Pusher(PUSHER_KEY());
    var channel = pusher.subscribe("room_" + room);

    return channel
}

function make_message(name, text) {
    return E_("tr", {},
              E_("td", {},
                 E_("span", {style: "font-weight:bold"}, name, "> "),
                 E_("span", {}, text)))
}

function message_adder(container) {
    var last_table

    return function(ent) {
        if (! last_table) {
            var tbl = E_("table", {class: "table"})(document)
            var panel = E_("div", {class: "row"},
                           E_("div", {class: "col-md-12"},
                              E_("div", {class: "panel panel-default"},
                                 tbl
                                )))
            $(container).append(panel(document))
            last_table = tbl
        }
        $(last_table).append(make_message(ent.name, ent.text)(document))
    }
}

function match_and_append_message(msg, add_message) {
    // console.log(msg)
    var M = xmlmatch.M
    var C = xmlmatch.C

    var sp = function(x) {return x.nodeType == 3 && x.textContent.match(/\s*/)}

    var last_index = -1

    var m = M("xxx",
              C(M("entries",
                  C(sp,
                    M("entry",
                      function(node) {
                          var ent = {}
                          var index = node.getAttribute("index")
                          // console.log("index", index)
                          if (index != null && +index > last_index) {
                              last_index = +index
                              var res = C(sp,
                                          M("user-id", function(x){
                                              ent.user_id = x.textContent
                                              return true}),
                                          M("thread-id", function(x){
                                              ent.thread_id = x.textContent
                                              return true}),
                                          M("content",
                                            C(sp,
                                              M("screen-name", function(x){
                                                  ent.name = x.textContent
                                                  return true
                                              }),
                                              M("text", function(x){
                                                  ent.text = x.textContent
                                                  return true
                                              })))
                                         )(node)
                              add_message(ent)
                              return res
                          } else {
                              // console.log("end", node, index, last_index)
                              return false
                          }
                      }),
                    M("error", function(x){console.log(x); return true})
                   ))))
    var e = document.createElement("xxx")
    e.innerHTML = msg
    // console.log(e)
    var result = m(e)
    // console.log(result)
    // console.log(last_index)

    return last_index
}

function message_form(room, onsubmit) {
    return E_("div", {class: "row"},
              E_("div", {class: "col-md-12"},
                 function(doc) {
                     var textarea
                     var name_input
                     var e = E_("form", {role: "form"},
                                E_("div", {class: "form-group"},
                                   E_("label", {for: "name_textinput"},
                                      "Your Name"),
                                   function(doc) {
                                       var e = E_("input",
                                                  {class: "form-control",
                                                   type: "text",
                                                   id: "name_textinput"}, "")
                                       var ele = e(doc)
                                       name_input = ele
                                       return ele
                                   }),
                                E_("div", {class: "form-group"},
                                   E_("label", {for: "message_body_textarea"},
                                      "Message"),
                                   function(doc) {
                                       var e = E_("textarea",
                                                  {class: "form-control",
                                                   id: "message_body_textarea",
                                                   rows: 2}, "")
                                       var ele = e(doc)
                                       textarea = ele
                                       return ele
                                   }),
                                E_("button", {type: "submit", class: "btn btn-primary"},
                                   "Submit"))
                     var ele = e(doc)

                     ele.onsubmit = function() {
                         if (textarea.value.match(/^\s*$/)) {
                             return false
                         }
                         if (name_input.value.match(/^\s*$/)) {
                             return false
                         }

                         console.log("submit!", textarea.value)
                         var text = textarea.value
                         var screen_name = name_input.value
                         textarea.value = ""
                         var content_xml = E_("xxx", {},
                                              E_("content", {},
                                                 E_("screen-name", {}, screen_name),
                                                 E_("text", {}, text)))(doc).innerHTML
                         console.log(content_xml)
                         $.post("/1/push", {
                             room: room,
                             "user-id": 123,
                             "thread-id": 0,
                             content: content_xml,
                         }, console.log.bind(console))

                         onsubmit()
                         return false
                     }

                     return ele
                 }))
}

function navbar(room) {
    return E_("nav", {class: "navbar navbar-default navbar-fixed-top",
                      role: "navigation"},
              E_("div", {class: "navbar-header"},
                 E_("button", {type: "button", class: "navbar-toggle",
                               "data-toggle": "collapse",
                               "data-target": ".navbar-ex1-collapse"},
                    E_("span", {class: "sr-only"}, "Toggle navigation"),
                    E_("span", {class: "icon-bar"}, ""),
                    E_("span", {class: "icon-bar"}, ""),
                    E_("span", {class: "icon-bar"}, "")),
                 E_("a", {class: "navbar-brand", href: "#"}, room)
                ))
}

var ChatBoard = function(room) {
    var self = this

    self.interval = 1000
    self.timeout_id
    self.room = room
    self.container

    self.make_container()

    self.add_message = message_adder(self.container)

    var last_index = 0
    $.get("/1/pull", {room: self.room},
          function(msg) {
              last_index = match_and_append_message(msg, self.add_message)
              setTimeout(function() {
                  var body = $(document.body)
                  var scrollto = Math.max(0, body.height() - $(window).height())
                  body.animate({scrollTop: scrollto}, function() {
                      console.log("scroll complete")
                  })
              }, 10)
          })

    var badge = 0
    var title = document.title = self.room + " - chat"
    self.reload = function() {
        $.get("/1/pull", {room: self.room, after: last_index},
              function(msg) {
                  var idx = match_and_append_message(msg, self.add_message)
                  if (idx > last_index) {
                      if (! document.hasFocus()) {
                          badge += (idx - last_index)
                          document.title = "[" + badge + "]" + title
                          $(window).focus(function() {
                              document.title = title
                              badge = 0
                          })
                      }

                      last_index = idx
                      self.interval = 1000

                      var body = $(document.body)
                      if (body.height() - (body.scrollTop() + $(window).height()) < 70) {
                          body.scrollTop(body.height() - $(window).height())
                      }

                  } else {
                      // double the interval (up to 1 minite) if no message received
                      self.interval = Math.min(self.interval * 2, 60 * 1000)
                  }
                  self.timeout_id = setTimeout(self.reload, self.interval)
                  // console.log("self.interval", self.interval)
              })
            .fail(function() {
                if (self.timeout_id) clearTimeout(self.timeout_id)
                self.timeout_id = null
                console.log("Failed")
            })
    }
    self.timeout_id = setTimeout(self.reload, self.interval)

    var pusher_channel = make_pusher(self.room)
    pusher_channel.bind('update', function(data) {
        if (data.index > last_index) {
            if (self.timeout_id) clearTimeout(self.timeout_id)
            self.timeout_id = null
            self.reload()
            // console.log(data);
        }
    });
}

ChatBoard.prototype.make_container = function() {
    var self = this

    var e = E_("div", {class: "container", style: "padding-top: 70px; padding-bottom: 20px"},
               function(doc) {
                   var e = E_("div", {id: "messages"})(doc)
                   self.container = e
                   return e
               },
               message_form(self.room, function() {
                   if (self.timeout_id) clearTimeout(self.timeout_id)
                   self.timeout_id = null
                   self.reload()
               }))

    $(document.body)
        .append(navbar(self.room)(document))
        .append(e(document))
}

$(document).ready(function(){
    var board = new ChatBoard("elepaio")
})

}()
