+function() {
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

    var last_index = 0

    var m = M("xxx",
              C(M("entries",
                  C(sp,
                    M("entry",
                      function(node) {
                          var ent = {}
                          var index = node.getAttribute("index")
                          last_index = Math.max(last_index, index)
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
                      }),
                    M("error", function(x){console.log(x); return true})
                   ))))
    var e = document.createElement("xxx")
    e.innerHTML = msg
    console.log(e)
    var result = m(e)
    console.log(result)
    console.log(last_index)

    return last_index
}

function message_form(room, onsubmit) {
    return E_("div", {class: "row"},
              E_("div", {class: "col-md-12"},
                 function(doc) {
                     var textarea
                     var e = E_("form", {role: "form"},
                                E_("div", {class: "form-group"},
                                   function(doc) {
                                       var e =
                                           E_("textarea", {class: "form-control", rows: 3})
                                       var ele = e(doc)
                                       textarea = ele
                                       return ele
                                   }),
                                E_("button", {type: "submit", class: "btn btn-primary"},
                                   "Submit"))
                     var ele = e(doc)

                     ele.onsubmit = function() {
                         // if (textarea.value.match(/^\s*$/))
                         //     return false

                         console.log("submit!", textarea.value)
                         var text = textarea.value
                         var screen_name = "とおる。"
                         textarea.value = ""
                         var content_xml = E_("xxx", {},
                                              E_("content", {},
                                                 E_("screen-name", {}, screen_name),
                                                 E_("text", {}, text)))(doc).innerHTML
                         console.log(content_xml)
                         $.post("push.cgi", {
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

$(document).ready(function(){
    var room = "elepaio"
    var interval = 1000
    var timeout_id
    var container
    var e = E_("div", {class: "container", style: "padding-top: 70px"},
               function(doc) {
                   var e = E_("div", {id: "messages"})(doc)
                   container = e
                   return e
               },
               message_form(room, function() {
                   interval = 500
                   clearTimeout(timeout_id)
                   timeout_id = setTimeout(reload, interval)
               }))

    $(document.body)
        .append(navbar(room)(document))
        .append(e(document))

    var add_message = message_adder(container)

    var last_index = 0
    $.get("pull.cgi", {room: room},
          function(msg) {
              last_index = match_and_append_message(msg, add_message)
          })

    var reload = function() {
        $.get("pull.cgi", {room: room, after: last_index},
              function(msg) {
                  var idx = match_and_append_message(msg, add_message)
                  if (idx > last_index) {
                      last_index = idx
                      interval = 500
                  } else {
                      // double the interval (up to 1 minite) if no message received
                      interval = Math.min(interval * 2, 60 * 1000)
                  }
                  timeout_id = setTimeout(reload, interval)
                  console.log("interval", interval)
              })
            .fail(function() {
                clearTimeout(timeout_id)
                console.log("Failed")
            })
    }
    timeout_id = setTimeout(reload, interval)
})

}()
