using FranklinParser
using BenchmarkTools
using TimerOutputs

# TimerOutputs.disable_debug_timings(FranklinParser)
TimerOutputs.enable_debug_timings(FranklinParser)

txt = read(joinpath(@__DIR__, "..", "src", "_precompile", "expages", "real1.md"), String) *
      read(joinpath(@__DIR__, "..", "src", "_precompile", "expages", "real3.md"), String) *
      read(joinpath(@__DIR__, "..", "src", "_precompile", "expages", "real4.md"), String)

# aug 20, ~ 3.8ms (after adding inner tokens stuff...)
#
#     - tokenizer: ~1.8ms   (+)
#     - blockifier: ~1.12ms (+++)
#     - partition: ~0.6ms   (=)
#
# (regression maybe due to subvector stuff and non typestable stuff?)
# - 
# aug 17, ~ 2.75ms; show(TIMER) gives
#
#     - tokenizer:  ~1.6ms
#     - blockifier: ~0.7ms
#     - partition:  ~0.6ms
#


FranklinParser.reset_timer!(FranklinParser.TIMER)

@btime FranklinParser.default_md_tokenizer($txt);

TimerOutputs.complement!(FranklinParser.TIMER)




@btime FranklinParser.md_partition($txt);

# NOTE: One thing that could still be attempted
# and may have an impact, is to come back to TextBlock encapsulating the
# inner-tokens in their span so that we don't have to do lots of
# re-tokenization bearing in mind that it's a significant effort.
