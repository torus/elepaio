+function() {
function make_message(name, text) {
    return E_("div", {class: "row"},
              E_("div", {class: "col-md-12"},
                 E_("div", {class: "panel panel-default"},
                    E_("div", {class: "panel-heading"}, name),
                    E_("div", {class: "panel-body"}, text))))
}

$(document).ready(function(){
    var room = "elepaio"
    var container
    var e = E_("div", {class: "container"},
               function(doc) {
                   var e = E_("div", {id: "messages"})(doc)
                   container = e
                   return e
               },
               E_("div", {class: "row"},
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
                             if (textarea.value.match(/^\s*$/))
                                 return false

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
                             return false
                         }

                         return ele
                     })))

    $(document.body).append(e(document))

    $.get("pull.cgi", {room: room},
          function(msg) {
              console.log(msg)
          })
    // $(container).append(make_message("やまや", "やまやまや")(document))
    // $(container).append(make_message("まや", "やまや")(document))
})

}()