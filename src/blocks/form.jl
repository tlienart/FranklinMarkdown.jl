const BLOCKQUOTE_ACC = union((:BLOCKQUOTE_LINE,), INLINE_BLOCKS)
const LIST_ACC       = union((:ITEM_U_CAND, :ITEM_O_CAND), INLINE_BLOCKS)
const TABLE_ACC      = union((:TABLE_ROW_CAND,), [b for b in INLINE_BLOCKS if b != :TEXT])

"""
    aggregate!(blocks, items, acc, case)

Merge a bunch of blocks into a parent block. For instance at this point there
may be multiple BLOCKQUOTE_LINE, this function will aggregate them into one
BLOCKQUOTE block.

## Arguments

    * blocks: the current vector of blocks we're working with
    * items:  list of names of blocks that would trigger the aggregation
    * acc:    list of names of blocks that would be taken in the aggregation
    * case:   name of the block resulting from the aggregation
"""
function aggregate!(
            blocks::Vector{Block},
            items::Vector{Symbol},
            acc::Vector{Symbol},
            case::Symbol
        )::Nothing

    i = 1
    j = 1
    ps = parent_string(first(blocks))
    @inbounds while i ≤ length(blocks)
        bi = blocks[i]
        if bi.name in items
            # look ahead
            j = i + 1
            while j ≤ length(blocks)
                if blocks[j].name ∉ acc
                    break
                end
                j += 1
            end
            blocks[i] = Block(
                case,
                subs(ps, from(bi), to(blocks[j-1]))
            )
        end
        i = max(j, i + 1)
    end
    return
end

form_blockquotes!(blocks::Vector{Block}) =
    aggregate!(blocks, [:BLOCKQUOTE_LINE], BLOCKQUOTE_ACC, :BLOCKQUOTE)

form_lists!(blocks::Vector{Block}) =
    aggregate!(blocks, [:ITEM_U_CAND, :ITEM_O_CAND], LIST_ACC, :LIST)

form_tables!(blocks::Vector{Block}) =
    aggregate!(blocks, [:TABLE_ROW_CAND], TABLE_ACC, :TABLE)

form_refs!(blocks::Vector{Block}) =
    aggregate!(blocks, [:REF], INLINE_BLOCKS, :REF)
