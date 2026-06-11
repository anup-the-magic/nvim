; extends

; Inject bash into run = "..." (single-line) in [tasks.*] sections
(table
  (dotted_key
    . (bare_key) @_section
    (#any-of? @_section "tasks" "task_templates"))
  (pair
    (bare_key) @_key
    (#eq? @_key "run")
    (string) @injection.content
    (#not-match? @injection.content "^\"\"\"")
    (#offset! @injection.content 0 1 0 -1)
    (#try-detect-shebang! @injection.content)))

; Inject bash into run = """...""" (multiline) in [tasks.*] sections
(table
  (dotted_key
    . (bare_key) @_section
    (#any-of? @_section "tasks" "task_templates"))
  (pair
    (bare_key) @_key
    (#eq? @_key "run")
    (string) @injection.content
    (#match? @injection.content "^\"\"\"")
    (#offset! @injection.content 0 3 0 -3)
    (#try-detect-shebang! @injection.content)))

; Inject bash into run = ["...", "..."] (array) in [tasks.*] sections
(table
  (dotted_key
    . (bare_key) @_section
    (#any-of? @_section "tasks" "task_templates"))
  (pair
    (bare_key) @_key
    (#eq? @_key "run")
    (array
      (string) @injection.content
      (#offset! @injection.content 0 1 0 -1)
      (#try-detect-shebang! @injection.content))))
