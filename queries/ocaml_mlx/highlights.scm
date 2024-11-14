; inherits: ocaml
; extends

(jsx_prop
  (jsx_prop_name) @tag.attribute)

(jsx_element_opening
  (jsx_tag (value_name)) @tag.builtin)

(jsx_element_closing
  (jsx_tag (value_name)) @tag.builtin)

(jsx_element_self_closing
  (jsx_tag (value_name)) @tag.builtin)

(jsx_expression
  (jsx_element_opening
    [
      "<"
      ">"]
    @tag.delimiter))

(jsx_expression
  (jsx_element_closing
    [
      "</"
      ">"]
    @tag.delimiter))

(jsx_expression
  (jsx_element_self_closing
    [
      "<"
      "/>"]
    @tag.delimiter))
