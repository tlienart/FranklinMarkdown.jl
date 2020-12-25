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
    * [ ] check specific token are at start of line (`+++`, `###`, `@def`, hrules)
    * [ ] validate emoji
    * [ ] validate footnote
  * [x] find markdown definitions (needs indented lines)
  * [ ] markdown blocks
    * [x] basic
    * [ ] double brace blocks, headers, ...
    * [ ] math parsing
  * [ ] html tokenization
  * [ ] html blocks
  * [ ] latex-like elements
    * [ ] dedent definitions
* [ ] context of errors / warnings (would be caught)
* get intermediate markdown representation
  * [ ] resolve as much as possible to CM-MD
  * [ ] placeholder for lxcom, code, raw html, hfun
* get intermediate output (html/latex) using CM
* return intermediate output + auxiliary information for Franklin to use in `convert` function

**Warning**

* [ ] what if user writes a line with `## abc ## def`; the second block should be ignored (this should be done at the re-processing of the content of the first block, should deactivate finding extra headers in it)

## Workflow

* input MD, return output lowered MD + remaining special blocks to treat by Franklin (e.g. code)

In Franklin:

```julia
import CommonMark
const CM = CommonMark
# ----------------------------------------
# Disable the parsing of indented blocks
# see https://github.com/MichaelHatherly/CommonMark.jl/issues/1#issuecomment-735990126)
struct SkipIndented end
block_rule(::SkipIndented) = CM.Rule((p, c) -> 0, 8, "")
cm_parser = CM.enable!(CM.disable!(CM.Parser(), CM.IndentedCodeBlockRule()), SkipIndented())
# ----------------------------------------
```

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

# RULES

## CommonMark basics

* Bold, Italic
  * [ ] tests
* Images
  * [ ] tests (notes: check different types of links)
* Tables
  * [ ] tests (notes: check nesting with commands inside)

## Franklin specials -- basics

* Comments
  * [ ] parsing
  * [ ] processing
  * [ ] tests
* Raw HTML
  * [ ] parsing
  * [ ] processing
  * [ ] tests
* Headers
  * [ ] parsing
  * [ ] processing
  * [ ] tests
* Footnotes
  * [ ] parsing
  * [ ] processing
  * [ ] tests
* Entities
  * [ ] parsing
  * [ ] processing
  * [ ] tests
* Emojis
  * [ ] parsing
  * [ ] processing
  * [ ] tests
* Div blocks
  * [ ] parsing
  * [ ] processing
  * [ ] tests

## Franklin specials -- code blocks
