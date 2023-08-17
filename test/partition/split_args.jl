@testset "args" begin
    s = """
        a "bc def ghi" kl 1
        """
    args = FP.split_args(s)
    @test args[1] // "a"
    @test args[2] // "\"bc def ghi\""
    @test args[3] // "kl"
    @test args[4] // "1"

    a = "abc def" |> FP.split_args
    @test a[1] // "abc"
    @test a[2] // "def"

    a = "" |> FP.split_args
    @test isempty(a)

    a = "abc" |> FP.split_args
    @test a[1] // "abc"

    a = "\"abc\"" |> FP.split_args
    @test a[1] // "\"abc\""

    a = "abc \"def\" \"\"\"ghi\"\"\" klm" |> FP.split_args
    @test a[1] // "abc"
    @test a[2] // "\"def\""
    @test a[3] // "\"ghi\""
    @test a[4] // "klm"
end
