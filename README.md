# Franklin Markdown

[![CI Actions Status](https://github.com/tlienart/FranklinMarkdown.jl/workflows/CI/badge.svg)](https://github.com/tlienart/FranklinMarkdown.jl/actions)
[![codecov](https://codecov.io/gh/tlienart/FranklinParser.jl/branch/main/graph/badge.svg?token=mNry6r2aIn)](https://codecov.io/gh/tlienart/FranklinParser.jl)

## Ovv Markdown

* get tokens
* form blocks (possibly via tree)
* reduce blocks to their special parts (raw HTML input)

WIP

* get all tokens and all blocks
  * [x] markdown tokenization
    * [x] posthoc tokenization for `{{`, `}}` `LR_INDENT` etc
    * [x] add validator for emoji, footnote (e.g. `abc]:]:`)
  * [x] find markdown definitions (needs indented lines)
  * [ ] markdown blocks
    * [x] basic
    * [ ] double brace blocks, headers, ...
  * [ ] html tokenization
  * [ ] html blocks
  * [ ] latex-like elements
* [ ] context of errors / warnings (would be caught)
* get intermediate markdown representation
  * [ ] resolve as much as possible to CM-MD
  * [ ] placeholder for lxcom, code, raw html, hfun
* get intermediate output (html/latex) using CM
* return intermediate output + auxiliary information for Franklin to use in `convert` function

**Warning**

* [ ] what if user writes a line with `## abc ## def`; the second block should be ignored (this should be done at the re-processing of the content of the first block, should deactivate finding extra headers in it)

## Workflow

provide a few key functions like

## Note

if successful could also consider extracting the code evaluation as a module like `FranklinCodeEvaluation.jl`


## Notes on changes

* [x] AbstractBlock -> Span
* [x] Token
* [x] `str` -> `parent_str`
* [ ] from, to
* [ ] indented code blocks are explicitly not allowed
* [ ] indentation in a `@def` is any line that starts with a space

## Check

* [ ] if need to do our own  stuff with links and footnote ref

### More serious

* [ ] context (needs to be overhauled quite a bit... idea is good)

### Tests

* should be able to  parse ```` ```! ```` (seems like it's  failing in Franklin now)
