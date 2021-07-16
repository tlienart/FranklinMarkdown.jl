using SnoopCompile

tinf = @snoopi_deep include("runtests.jl")
itrigs = inference_triggers(tinf)

fitrigs = filter(itrig -> itrig.callerframes[end].linfo.def.module === FranklinParser, itrigs)

# Jan 30, 3 triggers, can probably ignore.
# July 16: itrigs has 4 elements for Base._* (probably irrelevant)
#          fitrigs has 0 elements
