const BLOCKQUOTE_ACC = union((:BLOCKQUOTE_LINE,), INLINE_BLOCKS)
const ITEM_ACC       = union((:ITEM_U_CAND, :ITEM_O_CAND), INLINE_BLOCKS)
const TABLE_ACC      = union((:TABLE_ROW_CAND,), INLINE_BLOCKS)

function aggregate!(blocks::Vector{Block}, items::Vector{Symbol},
                    acc::Vector{Symbol}, case::Symbol)
    i = 1
    j = 1
    ps = parent_string(first(blocks))
    while i ≤ length(blocks)
        bi = blocks[i]
        if bi.name in items
            bi.ss
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
end

form_blockquotes!(blocks::Vector{Block}) =
    aggregate!(blocks, [:BLOCKQUOTE_LINE], BLOCKQUOTE_ACC, :BLOCKQUOTE)

form_lists!(blocks::Vector{Block}) =
    aggregate!(blocks, [:ITEM_U_CAND, :ITEM_O_CAND], ITEM_ACC, :LIST)

form_tables!(blocks::Vector{Block}) =
    aggregate!(blocks, [:TABLE_ROW_CAND], TABLE_ACC, :TABLE)
