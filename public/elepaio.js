+function() {
function make_message(name, text) {
    return E_("div", {class: "row"},
              E_("div", {class: "col-md-12"},
                 E_("div", {class: "panel panel-default"},
                    E_("div", {class: "panel-heading"}, name),
                    E_("div", {class: "panel-body"}, text))))
}

function match_and_append_message(msg, container) {
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
                          console.debug("ent", ent)
                          $(container).append(make_message(ent.name,
                                                           ent.text)(document))
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
                         // interval = 500
                         // clearTimeout(timeout_id)
                         // timeout_id = setTimeout(reload, interval)
                         return false
                     }

                     return ele
                 }))
}

$(document).ready(function(){
    var room = "elepaio"
    var interval = 1000
    var timeout_id
    var container
    var e = E_("div", {class: "container"},
               E_("h1", {}, room),
               function(doc) {
                   var e = E_("div", {id: "messages"})(doc)
                   container = e
                   return e
               },
               message_form(room, function() {
                   interval = 500
                   clearTimeout(timeout_id)
                   timeout_id = setTimeout(reload, interval)
               })
               // E_("div", {class: "row"},
               //    E_("div", {class: "col-md-12"},
               //       function(doc) {
               //           var textarea
               //           var e = E_("form", {role: "form"},
               //                      E_("div", {class: "form-group"},
               //                         function(doc) {
               //                             var e =
               //                                 E_("textarea", {class: "form-control", rows: 3})
               //                             var ele = e(doc)
               //                             textarea = ele
               //                             return ele
               //                         }),
               //                      E_("button", {type: "submit", class: "btn btn-primary"},
               //                         "Submit"))
               //           var ele = e(doc)

               //           ele.onsubmit = function() {
               //               // if (textarea.value.match(/^\s*$/))
               //               //     return false

               //               console.log("submit!", textarea.value)
               //               var text = textarea.value
               //               var screen_name = "とおる。"
               //               textarea.value = ""
               //               var content_xml = E_("xxx", {},
               //                                    E_("content", {},
               //                                       E_("screen-name", {}, screen_name),
               //                                       E_("text", {}, text)))(doc).innerHTML
               //               console.log(content_xml)
               //               $.post("push.cgi", {
               //                       room: room,
               //                       "user-id": 123,
               //                       "thread-id": 0,
               //                       content: content_xml,
               //               }, console.log.bind(console))

               //               interval = 500
               //               clearTimeout(timeout_id)
               //               timeout_id = setTimeout(reload, interval)
               //               return false
               //           }

               //           return ele
               //       }))
              )

    $(document.body).append(e(document))

    var last_index = 0
    $.get("pull.cgi", {room: room},
          function(msg) {
              last_index = match_and_append_message(msg, container)
          })

    var reload = function() {
        $.get("pull.cgi", {room: room, after: last_index},
              function(msg) {
                  var idx = Math.max(last_index,
                                        match_and_append_message(msg, container))
                  if (idx > last_index) {
                      last_index = idx
                      interval = 500
                  } else {
                      // double the interval (up to 1 minite) if no message received
                      interval = Math.min(interval * 2, 60 * 1000)
                  }
                  setTimeout(reload, interval)
              })
            .fail(function() {
                console.log("Failed")
            })
    }
    timeout_id = setTimeout(reload, interval)
    // $(container).append(make_message("やまや", "やまやまや")(document))
    // $(container).append(make_message("まや", "やまや")(document))
})

}()
