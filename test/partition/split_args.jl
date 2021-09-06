@testset "args" begin
    s = """
        a "bc def ghi" kl 1
        """
    args = FP.split_args(s)
    args[1] // "a"
    args[2] // "\"bc def ghi\""
    args[3] // "kl"
    args[4] // "1"

    a = "abc def" |> FP.split_args
    a[1] // "abc"
    a[2] // "def"

    a = "" |> FP.split_args
    isempty(a)

    a = "abc" |> FP.split_args
    a[1] // "abc"

    a = "\"abc\"" |> FP.split_args
    a[1] // "\"abc\""

    a = "abc \"def\" \"\"\"ghi\"\"\" klm" |> FP.split_args
    a[1] // "abc"
    a[2] // "def"
    a[3] // "\"ghi\""
    a[4] // "klm"
end
