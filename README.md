# Franklin Parser

[![CI Actions Status](https://github.com/tlienart/FranklinParser.jl/workflows/CI/badge.svg)](https://github.com/tlienart/FranklinParser.jl/actions)
[![codecov](https://codecov.io/gh/tlienart/FranklinParser.jl/branch/main/graph/badge.svg?token=mNry6r2aIn)](https://codecov.io/gh/tlienart/FranklinParser.jl)

## Warning notes

* [ ] no requirements for `#+` to be at the beginning of a line, it will be taken as a header until the current end of line. The reason for this is so that we can avoid having to dedent `div` contents to check whether `#+` are at the beginning of the line at the div indentation level. Users who want to introduce `#+` "as is" should use `\#`.

## Workflow (MD)

### Default init (original MD string -> first level partition)

1. input text `s::String`
1. call `default_md_partition(s)`
1. obtain a partition of `s` formed of `Text` or `Block` elements

1. input text `s` (either `String` or `SubString`)
1. call `partition(s, t)` where `t` is optionally given as the vector of tokens for `s` if it had been obtained from a previous pass
1. a partition of `s` is returned as a vector of `Text` or `Block` objects

The recursion would happen upon treatment of `Block` objects where the `partition_md` can be called again.

---------------------------------------

## Work in progress

WIP

* get all tokens and all blocks
  * [x] markdown tokenization
    * [ ] add validator for emoji, footnote (e.g. `abc]:]:`)
      * [ ] validate emoji
      * [ ] validate footnote
    * [ ] check specific token are at start of line (`+++`, `###`, `@def`, hrules) (this would be done after dedent)
    * [ ] mark empty lines between two indented lines as indented (see footnote definition, and https://www.markdownguide.org/extended-syntax/#footnotes)
  * [x] find markdown definitions (needs indented lines)
  * [ ] markdown blocks
    * [x] basic
    * [x] double brace blocks, headers, ...
    * [ ] math parsing
    * [ ] footnote definitions over multiple lines
  * [ ] html tokenization
  * [ ] html blocks
  * [ ] latex-like elements
    * [ ] dedent definitions
* [ ] context of errors / warnings (would be caught)

DOCSTRINGS

* [ ] add documentation for partition

RULES

* [ ] rule factory (in / out, context etc)
* [ ] allow passing rules dictionary for special blocks (test this in tests with CommonMark dependency)
* [ ] find a way to enable/disable rules etc. so that users can reuse the rules they want and disable or re-define the ones they don't want.


INTEGRATION

* [ ]

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
