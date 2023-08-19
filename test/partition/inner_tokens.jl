@testset "inner tokens textblock" begin
    p = """
        abc &amp; def \\@ 000
        ```
        code
        ```
        and \\# 111 &amp; 000
        """ |> FP.md_partition

        for part in (p[1], p[3])
            ta = filter(t -> t.name ∉ (:SOS, :EOS), collect(part.inner_tokens))
            tb = filter(t -> t.name ∉ (:SOS, :EOS), collect(FP.default_md_tokenizer(part.ss)))
            
            for (tai, tbi) in zip(ta, tb)
                @test tai.name == tbi.name
            end
        end
end
