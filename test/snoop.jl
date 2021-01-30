using SnoopCompile

tinf = @snoopi_deep include("runtests.jl")
itrigs = inference_triggers(tinf)

fitrigs = filter(itrig -> itrig.callerframes[end].linfo.def.module === FranklinParser, itrigs)

# Jan 30, 3 triggers, can probably ignore.
