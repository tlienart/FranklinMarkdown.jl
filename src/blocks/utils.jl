function blocks_dict(v::Vector{BlockTemplate})
    return LittleDict{Symbol,BlockTemplate}(e.opening => e for e in v)
end
