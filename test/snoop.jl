using SnoopCompile

tinf = @snoopi_deep include("runtests.jl")
itrigs = inference_triggers(tinf)

# As of Jan 17, this should be 4 [and only in Base]
