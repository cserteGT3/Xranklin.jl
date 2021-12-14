include(joinpath(@__DIR__, "..", "..", "utils.jl"))

@testset "nb-code" begin
    gc = X.DefaultGlobalContext()
    lc = X.DefaultLocalContext(gc; rpath="foo")
    nb = lc.nb_code
    @test isa(nb, X.CodeNotebook)
    c = """
        a = 5
        a^2
        """
    X.eval_code_cell!(lc, X.subs(c), cell_name="abc")
    @test X.counter(nb) == 2
    @test length(nb) == 1
    @test nb.code_pairs[1].repr.html == "<pre><code class=\"code-result\">25</code></pre>"
    @test nb.code_pairs[1].repr.latex == "25"

    # - simulating modification of the samecell
    X.reset_counter!(nb)
    X.eval_code_cell!(lc, X.subs(c * ";"), cell_name="abc")
    @test length(nb) == 1
    @test nb.code_pairs[1].repr.html === ""
    @test nb.code_map["abc"] == 1

    X.eval_code_cell!(lc, X.subs("a^3"), cell_name="def")
    @test X.counter(nb) == 3
    @test length(nb) == 2
    @test nb.code_pairs[2].repr.html == "<pre><code class=\"code-result\">125</code></pre>"
    @test nb.code_map["def"] == 2

    X.eval_code_cell!(lc, X.subs("@show a"), cell_name="sss")
    @test X.counter(nb) == 4
    @test length(nb) == 3
    @test nb.code_pairs[3].repr.html === "<pre><code class=\"code-stdout\">a = 5\n</code></pre>"
    @test nb.code_map["sss"] == 3
end
