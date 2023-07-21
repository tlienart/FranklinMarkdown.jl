#
# See also `partition`
#
const INLINE_BLOCKS = [
    :TEXT,
    :COMMENT,                                 # <!-- ... -->
    :RAW, :RAW_HTML, :RAW_LATEX,              # ???...???, ~~~...~~~, %%%...%%%
    :EMPH_EM, :EMPH_STRONG, :EMPH_EM_STRONG,  # * ** ***, _ __ ____
    :LINEBREAK,                               # \\
    #
    :CODE_INLINE,                             # `...`
    :MATH_INLINE,                             # $...$
    #
    :AUTOLINK,                                # <...>
    :LINK_A, :LINK_AB, :LINK_AR,              # ![...] ![...](...) ![...][...]
    :IMG_A, :IMG_AB, :IMG_AR,                 # [...] [...](...) [...][...]
    #
    :CU_BRACKETS, :LX_COMMAND,
    :LX_NEWENVIRONMENT, :LX_NEWCOMMAND,
    :DBB,
    # derived by reconstructing commands (Franklin)
    :RAW_INLINE
]

# these are blocks which, if present in a paragraph, necessarily make that
# paragraph a paragraph. Here are some examples:
#
#   [:TEXT][:RAW_HTML][:TEXT] --> if the [:TEXT] are non-empty, it's
#                                 necessarily a paragraph
#
#   [:RAW_HTML] --> not a paragraph because it's on it's own
#
#   [:TEXT][:RAW_HTML] -> not a paragraph if the stripped text is empty
#
const INLINE_BLOCKS_CHECKP = [
    :COMMENT,
    :RAW, :RAW_HTML, :RAW_LATEX,
    :LINEBREAK,
    :CU_BRACKETS, :LX_COMMAND,
    :LX_NEWENVIRONMENT, :LX_NEWCOMMAND,
    :DBB
]
