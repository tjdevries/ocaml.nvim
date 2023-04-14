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

 (#eq? @_attribute_id "graphql")
 (#set! injection.language "graphql")
 (#set! injection.include-children true))
