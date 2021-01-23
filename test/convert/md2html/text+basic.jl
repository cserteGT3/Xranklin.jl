@testset "text" begin
    s = """
        A *B* _C_ **D**
        """ |> html
    @test s // "<p>A <em>B</em> <em>C</em> <strong>D</strong></p>"
end

@testset "text+indent" begin
    s = """
        ABC

            DEF

        GHI
        """ |> html
    @test isapproxstr(s, "<p>ABC</p><p>DEF</p><p>GHI</p>")
end

@testset "text+div" begin
    s = """
        A @@b C @@ @@d,e F@@ G
        """ |> html
    @test isapproxstr(s, """
        <p>A</p>
        <div class="b">
          <p>C</p>
        </div>
        <div class="d e">
          <p>F</p>
        </div>
        <p>G</p>
        """)
    isbalanced(s)
end

@testset "text+div+indent" begin
    s = raw"""
        ABC

            @@DEF

                \* \\ \{

            @@

        GHI
        """ |> html
    @test isapproxstr(s, """
        <p>ABC</p>
        <div class="DEF">
          <p>&amp;#42; &lt;br&gt; &amp;#123;</p>
        </div>
        <p>GHI</p>
        """)
end

@testset "nesting divs" begin
    s = """
        A
        @@B
          C D @@E F@@ G
        @@
        """ |> html
    @test isapproxstr(s, """
        <p>A</p>
        <div class="B">
          <p>C D</p>
          <div class="E">
            <p>F</p>
          </div>
          <p>G</p>
        </div>
        """)
    isbalanced(s)
end

# @testset "br and hr" begin
#     s = raw"""
#         A \\ B --- C
#         """ |> html
#     @test isapproxstr(s, """
#         <p>A</p>
#         <br><p>B</p>
# <hr><p>C</p>
# ")
# end
