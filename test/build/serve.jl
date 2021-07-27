include(joinpath(@__DIR__, "..", "utils.jl"))

@testset "fullpass" begin
    d = mktempdir()
    write(d/"config.md", "")
    mkdir(d/"_layout")
    write(d/"_layout"/"head.html", "HEAD")
    write(d/"_layout"/"foot.html", "FOOT")
    write(d/"index.md", """
        # index
        Foo **bar**
        """)
    write(d/"page.md", """
        # page
        some markdown
        """)

    X.set_paths(d)
    gc = X.DefaultGlobalContext()
    wf = X.find_files_to_watch(d)
    X.full_pass(wf; gc=gc)

    @test isfile(d/"__site"/"index.html")
    @test isfile(d/"__site"/"page"/"index.html")

    s = read(d/"__site"/"index.html", String)
    @test isapproxstr(s, """
        HEAD
        <div class="franklin-content">
          <h1 id="index"><a href="#index">index</a></h1>
          <p>Foo <strong>bar</strong></p>
        </div>
        FOOT
        """)
    s = read(d/"__site"/"page"/"index.html", String)
    @test isapproxstr(s, """
        HEAD
        <div class="franklin-content">
          <h1 id="page"><a href="#page">page</a></h1>
          <p>some markdown</p>
        </div>
        FOOT
        """)
end
