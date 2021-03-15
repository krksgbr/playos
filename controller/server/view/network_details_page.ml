open Connman.Service
open Tyxml.Html

let proxy_id service_id =
  "proxy-" ^ service_id

let proxy_label service_id =
  div
    ~a:[ a_class [ "d-Network__Label" ] ]
    [ label
        ~a:[ a_label_for (proxy_id service_id) ]
        [ txt "Proxy" ]
    ]

let proxy_input ?proxy service_id =
  input
    ~a:[ a_input_type `Text
    ; a_id (proxy_id service_id)
    ; a_class [ "d-Input"; "d-Network__Input" ]
    ; a_name "proxy"
    ; a_value (Option.value ~default:"" proxy)
    ]
    ()

let proxy_form_note =
  p
    ~a:[ a_class [ "d-Network__Note" ] ]
    [ txt "URL in the form "
    ; em ~a:[ a_class [ "d-Code" ] ] [ txt "http://host:port" ]
    ; txt " or "
    ; em ~a:[ a_class [ "d-Code" ] ] [ txt "http://user:password@host:port" ]
    ; txt "."
    ]

let not_connected_form service =
  let passphrase_id = "passphrase-" ^ service.id in
  form
      ~a:[ a_action ("/network/" ^ service.id ^ "/connect")
      ; a_method `Post
      ; a_class [ "d-Network__Form" ]
      ]
      [ div
          ~a:[ a_class [ "d-Network__Label" ] ]
          [ label
              ~a:[ a_label_for passphrase_id ]
              [ txt "Passphrase" ]
          ]
      ; input
          ~a:[ a_input_type `Text
          ; a_class [ "d-Input";  "d-Network__Input" ]
          ; a_id passphrase_id
          ; a_name "passphrase"
          ]
          ()
      ; details
          (summary [ txt "Proxy Settings" ])
          [ div
              ~a:[ a_class [ "d-Network__AdvancedSettingsTitle" ] ]
              [ proxy_label service.id
              ; proxy_input service.id
              ; proxy_form_note
              ]
          ]
      ; input
          ~a:[ a_input_type `Submit
          ; a_class [ "d-Button"; "d-Network__Button" ]
          ; a_value "Connect"
          ]
          ()
      ]

let disable_proxy_form service =
  form
      ~a:[ a_action ("/network/" ^ service.id ^ "/proxy/remove")
      ; a_method `Post
      ]
      [ input
          ~a:[ a_input_type `Submit
          ; a_class [ "d-Button" ]
          ; a_value "Disable proxy"
          ]
          ()
      ]

(* Regex pattern to validate IP addresses
 * From: https://stackoverflow.com/a/36760050 *)
let ip_address_regex_pattern =
  "^((25[0-5]|(2[0-4]|1[0-9]|[1-9]|)[0-9])(\\.(?!$)|$)){4}$"

let nameservers_form service =
  let nameserver_remove_form nameserver =
    form ~a:[ a_action ("/network/" ^ service.id ^ "/nameservers/" ^ nameserver ^ "/remove")
            ; a_method `Post
            ; a_class [ "d-NameserverRemoveForm" ]
            ]
      [ div ~a: [ a_class [ "d-TabularNums"; "d-NameserverRemoveForm__Nameserver" ] ] [ txt nameserver ]
      ; input ~a:[ a_input_type `Submit
                 ; a_class [ "d-Button" ]
                 ; a_value "Remove"
                 ] ()
      ]
  in
  let nameserver_add_form =
    form
      ~a:[ a_action ("/network/" ^ service.id ^ "/nameservers/add")
         ; a_method `Post
         ; a_class []
         ]
      [ input ~a:[ a_class [ "d-Input"; "d-Network__Input" ]
                 ; a_input_type `Text
                 ; a_name "nameserver"
                 ; a_required ()
                 ; a_pattern ip_address_regex_pattern
                 ] ()
      ; input
          ~a:[ a_input_type `Submit
             ; a_class [ "d-Button" ]
             ; a_value "Add"
             ]
          ()
      ]
  in
  div ~a:[ a_class [ "d-Network__Form" ] ]
    ((service.nameservers |> List.map nameserver_remove_form) @ [ nameserver_add_form ])

let connected_form service =
  div
    [ form
        ~a:[ a_action ("/network/" ^ service.id ^ "/remove")
        ; a_method `Post
        ; a_class [ "d-Network__Form" ]
        ]
        [ input
            ~a:[ a_input_type `Submit
            ; a_class [ "d-Button"; "d-Network__Button" ]
            ; a_value "Remove"
            ]
            ()
        ]
    ; details
        (summary [ txt "Proxy Settings" ])
        [ div
            ~a:[ a_class [ "d-Network__Form" ] ]
            [ proxy_label service.id
            ; div
                ~a:[ a_class [ "d-Network__ProxyForm" ] ]
                [ form
                    ~a:[ a_action ("/network/" ^ service.id ^ "/proxy/update")
                    ; a_method `Post
                    ; a_class [ "d-Network__ProxyUpdate" ]
                    ]
                    [ proxy_input ?proxy:service.proxy service.id
                    ; input
                        ~a:[ a_input_type `Submit
                        ; a_class [ "d-Button" ]
                        ; a_value "Update"
                        ]
                        ()
                    ]
                ; (if Option.is_some service.proxy then
                    disable_proxy_form service
                  else
                    txt "")
                ]
            ; proxy_form_note
            ]
        ]
    ; details (summary [ txt "Nameservers" ])
      [ nameservers_form service ]
    ]

let html service =
  let strength =
    match service.strength with
    | Some s ->
        div
            ~a:[ a_class [ "d-Network__SignalStrength" ] ]
            [ Signal_strength.html s ]
    | None ->
        div []
  in
  let properties = service
    |> sexp_of_t
    |> Sexplib.Sexp.to_string_hum
  in
  Page.html ~current_page:Page.Network (
    div
      [ a ~a:[
          a_class [ "d-BackLink" ]
          ; a_href "/network"
          ]
          [ txt "Back to networks" ]
      ; div
          ~a:[ a_class [ "d-Title" ] ]
          [ div
              ~a:[ a_class [ "d-Network__Title" ] ]
              [ h1 [ txt service.name ]
              ; strength
              ]
          ]
      ; div
          ~a:[ a_class [ "d-Network__Properties" ] ]
          [ pre
              ~a:[ a_class [ "d-Preformatted" ] ]
              [ txt properties ]
          ]
      ; if Connman.Service.is_connected service then
          connected_form service
        else
          not_connected_form service
      ]
  )