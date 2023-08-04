using FranklinParser
using BenchmarkTools

ct = read(joinpath(@__DIR__, "..", "src", "_precompile", "expages", "real1.md"), String)

# last run: aug 4, ~ 0.5ms, this is ok but
# ideally would eventually go down somewhat.
@btime FranklinParser.md_partition($ct);

# last run: aug 4, ~0.02ms, this is fine
parts = FranklinParser.md_partition(ct)
@btime FranklinParser.md_grouper($parts);
