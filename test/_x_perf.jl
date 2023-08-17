using FranklinParser
using BenchmarkTools
using TimerOutputs

TimerOutputs.enable_debug_timings(FranklinParser)

txt = read(joinpath(@__DIR__, "..", "src", "_precompile", "expages", "real1.md"), String) *
      read(joinpath(@__DIR__, "..", "src", "_precompile", "expages", "real3.md"), String) *
      read(joinpath(@__DIR__, "..", "src", "_precompile", "expages", "real4.md"), String)

# last run: aug 17, ~ 2.75ms; show(TIMER) gives
#
#     - tokenizer:  ~1.6ms
#     - blockifier: ~0.7ms
#     - partition:  ~0.6ms
#
@btime FranklinParser.md_partition($txt);

# NOTE: One thing that could still be attempted
# and may have an impact, is to come back to TextBlock encapsulating the
# inner-tokens in their span so that we don't have to do lots of
# re-tokenization bearing in mind that it's a significant effort.
