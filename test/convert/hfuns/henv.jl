include(joinpath(@__DIR__, "..", "..", "utils.jl"))

@testset "if basic" begin
    lc = X.DefaultLocalContext()
    s = raw"""
        +++
        a = true
        b = false
        +++
        {{if a}}
        foo
        {{end}}
        {{if e"$a && true"}}
        bar
        {{end}}
        {{if e"!$b"}}
        baz
        {{end}}
        {{if b}}
        not baz
        {{end}}
        """
    h = html(s, lc, nop=true)
    @test isapproxstr(h, """
        foo
        bar
        baz
        """)
end


@testset "if branch" begin
    s = raw"""
        +++
        a = true
        b = false
        +++
        {{if b}}
        foo
        {{elseif a}}
        bar
        {{end}}
        """
    h = html(s, nop=true)
    @test isapproxstr(h, "bar")
end

@testset "if nesting" begin
    s = raw"""
        +++
        a = true
        b = false
        +++
        {{if a}}
          {{if b}}
          foo
          {{else}}
          bar
          {{end}}
        {{end}}
        """
    h = html(s, nop=true)
    @test isapproxstr(h, "bar")
end

@testset "if > ifdef" begin
    lc = X.DefaultLocalContext()
    s = raw"""
        +++
        a = "hello"
        c = true
        +++

        {{isdef a}}yes{{else}}no{{end}}
        {{isdef b}}yes{{else}}no{{end}}
        {{isndef b}}yes{{else}}no{{end}}
        {{isndef a}}yes{{elseif c}}foo{{else}}no{{end}}
        """
    h = html(s, lc; nop=true)
    @test isapproxstr(h, "yes no yes foo")
end

@testset "if > isempty" begin
    lc = X.DefaultLocalContext()
    s = raw"""
        +++
        using Dates
        a = ""
        b = nothing
        c = Dates.Date(1)
        d = Dates.today()
        +++
        {{isempty a}}yes{{end}}
        {{isempty b}}yes{{end}}
        {{isempty c}}yes{{end}}
        {{isnotempty d}}yes{{end}}
        """
    h = html(s, lc; nop=true)
    @test isapproxstr(h, "yes yes yes yes")
end

# =============================================
@testset "for basic" begin
    s = raw"""
        +++
        a = [1,2,3]
        +++
        {{for x in a}}
            {{fill x}}
        {{end}}
        """
    h = html(s, nop=true)
    @test isapproxstr(h, """1 2 3""")
    s = raw"""
        +++
        a = [1,2,3]
        b = [3,4,5]
        z = zip(a, b)
        +++
        {{for (title, y) in z}}
            {{title}} - {{y}}
        {{end}}
        """
    h = html(s, nop=true)
    @test isapproxstr(h, """1 - 3 2 - 4 3 - 5""")
end

@testset "for scope" begin
    s = """
        +++
        i = 5
        a = [1,2,3]
        +++
        {{for i in a}} {{i}} {{end}}
        final: {{i}}
        """
    h = html(s, nop=true)
    @test isapproxstr(h, """
        1 2 3 final: 5
        """)
end

@testset "for estr" begin
    s = raw"""
        +++
        a = [1, 2, 3]
        b = ['a', 'b', 'c']
        +++
        {{for (a, b) in e"zip($a, $b)"}} {{a}} : {{b}} ; {{end}}
        """
    h = html(s, nop=true)
    @test isapproxstr(h, """
        1 : a ; 2 : b ; 3 : c ;
        """)
end
