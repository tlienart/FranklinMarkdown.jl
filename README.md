# Franklin Markdown

[![CI Actions Status](https://github.com/tlienart/FranklinMarkdown.jl/workflows/CI/badge.svg)](https://github.com/tlienart/FranklinMarkdown.jl/actions)
[![codecov](https://codecov.io/gh/tlienart/FranklinParser.jl/branch/main/graph/badge.svg?token=mNry6r2aIn)](https://codecov.io/gh/tlienart/FranklinParser.jl)

## Workflow

provide a few key functions like

* get all tokens and all blocks
  * [x] markdown tokenization
  * [ ] find markdown definitions (needs indented lines)
  * [ ] markdown blocks with tree structure and warnings rather than error for failure (send signal no update)
  * [ ] html tokenization
  * [ ] html blocks
* get intermediate markdown representation
  * [ ] resolve as much as possible to CM-MD
  * [ ] placeholder for lxcom, code, raw html, hfun
* get intermediate output (html/latex) using CM
* return intermediate output + auxiliary information for Franklin to use in `convert` function

## Note

if successful could also consider extracting the code evaluation as a module like `FranklinCodeEvaluation.jl`


## Notes on changes

* [x] AbstractBlock -> Span
* [x] Token
* [x] `str` -> `parent_str`
* [ ] from, to

## Check

* [ ] if need to do our own  stuff with links and footnote ref

### More serious

* [ ] context (needs to be overhauled quite a bit... idea is good)

### Tests

* should be able to  parse ```` ```! ```` (seems like it's  failing in Franklin now)
