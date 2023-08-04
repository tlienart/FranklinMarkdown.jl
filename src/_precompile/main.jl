PrecompileTools.@setup_workload begin
    pgs = [
        read(joinpath(@__DIR__, "expages", pg), String)
        for pg in readdir(joinpath(@__DIR__, "expages"))
    ]
    PrecompileTools.@compile_workload begin
        for p in pgs
            md_partition(p) |> md_grouper
        end
    end
end


