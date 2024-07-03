;; extends

; ppx_rapper sql injection
(
 (extension
   (attribute_id) @_attribute_id
   (attribute_payload
    (expression_item
     (application_expression
       function: (_) @_attribute_fn
       argument: (quoted_string (quoted_string_content) @injection.content)))))

 (#eq? @_attribute_id "rapper")
 (#contains? @_attribute_fn "execute" "get_one" "get_opt" "get_many")
 (#set! injection.language "rapper")
 (#set! injection.include-children true))

; graphql injection
(
 (extension
   (attribute_id) @_attribute_id
   (attribute_payload
    (expression_item
     (quoted_string
      (quoted_string_content) @injection.content))))

 (#contains? @_attribute_id "graphql" "relay")
 (#set! injection.language "graphql")
 (#set! injection.include-children true))

; javascript injection
((extension
   (attribute_id) @_attribute_id
   (attribute_payload
    (expression_item
     (quoted_string
      (quoted_string_content) @injection.content))))

 (#contains? @_attribute_id "raw" "bs.raw" "melange.raw")
 (#set! injection.language "javascript")
 (#set! injection.include-children true))

((item_extension
   (attribute_id) @_attribute_id
   (attribute_payload
    (expression_item
     (quoted_string
      (quoted_string_content) @injection.content))))

 (#contains? @_attribute_id "raw" "bs.raw" "melange.raw")
 (#set! injection.language "javascript")
 (#set! injection.include-children true))


  ;(value_definition ; [82, 0] - [83, 60]
  ;  (attribute_id) ; [82, 4] - [82, 9]
  ;  (let_binding ; [82, 10] - [83, 60]
  ;    pattern: (package_pattern ; [82, 10] - [82, 30]
  ;      (module_name)) ; [82, 18] - [82, 29]
  ;    body: (string ; [83, 2] - [83, 60]
  ;      (string_content)))) ; [83, 3] - [83, 59]
((value_definition
  (attribute_id) @_attribute_id
  (let_binding
    body: (string (string_content) @injection.content)))
 (#contains? @_attribute_id "query")
 (#set! injection.language "sql"))

((value_definition
  (attribute_id) @_attribute_id
  (let_binding
    body: (quoted_string (quoted_string_content) @injection.content)))
 (#contains? @_attribute_id "query")
 (#set! injection.language "sql"))
