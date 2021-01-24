using SnoopCompile

tinf = @snoopi_deep include("runtests.jl")
itrigs = inference_triggers(tinf)

fitrigs = filter(itrig -> itrig.callerframes[end].linfo.def.module === FranklinParser, itrigs)

# Jan 24, 0 trigger
