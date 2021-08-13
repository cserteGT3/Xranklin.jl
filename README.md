# Structure


[![CI Actions Status](https://github.com/tlienart/Xranklin.jl/workflows/CI/badge.svg)](https://github.com/tlienart/Xranklin.jl/actions)
[![codecov](https://codecov.io/gh/tlienart/Xranklin.jl/branch/main/graph/badge.svg?token=7gUn1zIEXw)](https://codecov.io/gh/tlienart/Xranklin.jl)

## Ongoing

* set of pages with one global context, test children contexts, pruning etc,
* continuous update, check proper updating triggers, no delays
* code blocks (also add native python if PyCall is imported)
  * use `output_path` / `code_out`
* tags
* utils
* list of all warning messages and explaination / what to do

* mode where can "test" only a subset of pages
* `MIME"text/html"` as base type is ok but not for latex output where it should be `MIME"text/latex"` which, for instance, is supported by DataFrames. This should be carried from context (unfortunately). This can be worked on later but basically you'd want a different representation based on whether you're outputting to HTML or LaTeX. For images in both cases you'd want to save the pictures to a location and include them. // note LaTeX output has to be a full path from scratch because of this MIME stuff... unless there's no picture. But this can't be guaranteed...

## More tests

* header rules
* md definitions
* code blocks
* 🔺🔺🔺 dependencies (pagevar/defs/reprocessing) + do we need `@delay` anymore?

## Goals

* use FranklinParser.jl
* remove dependency on HTTP
* use concrete types and inferrable in-out relations where possible
* remove deps on Literate, make it optional, same as Pluto

## Todo

* [ ] need to check whether the CommonMark footnote rule is sufficient, if it is then we should remove the relevant block from FranklinParser as it's not useful.
* [ ] ordering of parsing, when are `{{...}}` resolved, see issue
* [ ] test rule overriding in utils (`Xranklin.html_hk`...)
* [ ] when recursing, ignore mddefs

## Important Notes

* command names and environment names should be distinct. Cannot have `\newcommand{\foo}{...}` and `\newenvironment{foo}{...}{...}`; only the last one will be picked up.
* requires Julia >= 1.5

--

## Context

* when a page gets processed, the global context deps should be updated. So at the end of the page processing, there should be a list of global variables accessed on that page currently that should then query the global context, update it (so that if a page does or does not depend on some variables anymore, gc gets updated...)

## Conversion MD > (HTML, LaTeX)

Add 🌴 for the ones that are explicitly tested
Add ✅ for the ones that are also in one of the test md pages.
Add 🚨 for the ones that are thoroughly tested (including potential errors / ambiguities).

* text
  * [x] bold, italic 🌴 ✅ 🚨
  * [x] line break 🌴 ✅
  * [x] horizontal rules 🌴 ✅
  * [x] comment 🌴 ✅
  * [x] header 🌴 ✅
  * [x] html entities 🌴 ✅
  * [x] escaped chars `{ }` etc 🌴 ✅
  * [x] emoji (pasted and coded)🌴 ✅
  * [x] links ✅
  * [ ] footnotes
  * [ ] images
  * lists
    * [x] unordered ✅
    * [x] ordered ✅
    * [x] nested ✅
    * [ ] list item with injection
  * [x] div 🌴 ✅
  * [x] raw HTML ✅
* md-definition
  * [ ] toml block
  * [ ] `@def`
* tables
  * [ ] basic
  * [ ] cell item with injection
* hfun
  * [ ] double brace injection
  * [ ] function
* code
  * [x] inline ✅
  * [x] block plain ✅
  * [x] block lang ✅
  * [ ] block executed
* maths
  * [x] inline ✅
  * [x] display ✅  (**note**: we number by default for `$$` and `\[...\]`).
  * [ ] env
    * [ ] `equation`
    * [ ] `align`,
    * [ ] `equation*`,
    * [ ] `align*`
* latex
  * newcommand
    * [x] basic one ✅
    * [x] test nargs ✅
    * [ ] test dedent (e.g. can have an indented def)
    * [ ] test problems
  * newenv
    * [x] very basic one
    * [x] test nargs
    * [ ] test problems
  * commands
    * [x] basic one with args ✅
    * [x] nesting
    * [ ] basic one with args in maths env
    * [ ] test problems
  * environments
    * [x] basic one with args
    * [x] nesting
    * [ ] test problems
  * special commands
    * [ ] toc

## Parts from Franklin

### Functions ported

### Files considered

* [ ] include("build.jl") # check if user has Node/minify
* [ ] include("regexes.jl")

* [ ] include("utils/warnings.jl")
* [ ] include("utils/errors.jl")
* [ ] include("utils/paths.jl")
* [ ] include("utils/vars.jl")
* [ ] include("utils/misc.jl")
* [ ] include("utils/html.jl")

* [ ] include("parser/tokens.jl")
* [ ] include("parser/ocblocks.jl")

* [ ] include("parser/markdown/tokens.jl")
* [ ] include("parser/markdown/indent.jl")
* [ ] include("parser/markdown/validate.jl")

* [ ] include("parser/latex/tokens.jl")
* [ ] include("parser/latex/blocks.jl")

* [ ] include("parser/html/tokens.jl")
* [ ] include("parser/html/blocks.jl")

* [ ] include("eval/module.jl")
* [ ] include("eval/run.jl")
* [ ] include("eval/codeblock.jl")
* [ ] include("eval/io.jl")
* [ ] include("eval/literate.jl")

* [ ] include("converter/markdown/blocks.jl")
* [ ] include("converter/markdown/utils.jl")
* [ ] include("converter/markdown/mddefs.jl")
* [ ] include("converter/markdown/tags.jl")
* [ ] include("converter/markdown/md.jl")

* [ ] include("converter/latex/latex.jl")
* [ ] include("converter/latex/objects.jl")
* [ ] include("converter/latex/hyperrefs.jl")
* [ ] include("converter/latex/io.jl")

* [ ] include("converter/html/functions.jl")
* [ ] include("converter/html/html.jl")
* [ ] include("converter/html/blocks.jl")
* [ ] include("converter/html/link_fixer.jl")
* [ ] include("converter/html/prerender.jl")

* [ ] include("manager/rss_generator.jl")
* [ ] include("manager/sitemap_generator.jl")
* [ ] include("manager/robots_generator.jl")
* [ ] include("manager/write_page.jl")
* [ ] **include("manager/dir_utils.jl")**
  * [x] TrackedFiles
  * [x] scan_input_dir!
  * [x] add_if_new_file
  * [x] should_ignore
  * [ ] prepare output dir
  * [x] form output path
  * [x] out path
  * [x] keep path
  * [ ] form custom output path
* [ ] **include("manager/file_utils.jl")**
  * [x] process_config
  * [-] include external config _not necessary, use process_config_
  * [ ] process_utils
  * [ ] process_file
  * [ ] process_file_err
  * [x] change_ext
  * [x] get_rpath
  * [ ] set_cur_rpath _maybe not necessary_
* [ ] include("manager/franklin.jl")
* [ ] include("manager/extras.jl")
* [ ] include("manager/post_processing.jl")
