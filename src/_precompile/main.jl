PrecompileTools.@setup_workload begin
    pgs = [
        read(joinpath(@__DIR__, "expages", pg), String)
        for pg in [
            "ksink.md",
            "real1.md",
            "real2.md"
        ]
    ]
    PrecompileTools.@compile_workload begin
        for p in pgs
            md_partition(p) |> md_grouper
        end
    end
end


