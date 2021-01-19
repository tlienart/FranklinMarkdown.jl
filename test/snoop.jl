using SnoopCompile

tinf = @snoopi_deep include("runtests.jl")
itrigs = inference_triggers(tinf)

fitrigs = filter(itrig -> itrig.callerframes[end].linfo.def.module === FranklinParser, itrigs)

# As of Jan 17, this should be 4 [and only in Base]
