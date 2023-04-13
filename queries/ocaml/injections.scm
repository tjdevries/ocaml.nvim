;; extends

(
 (extension
   (attribute_id) @_attribute_id
   (attribute_payload
    (expression_item
     (application_expression
       function: (_) @_attribute_fn
       argument: (quoted_string (quoted_string_content) @injection.content)))))

 (#eq? @_attribute_id "rapper")
 (#eq? @_attribute_fn "get_opt")
 (#set! injection.language "rapper")
 (#set! injection.include-children true))
