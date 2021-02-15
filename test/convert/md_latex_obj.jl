@testset "command - basic" begin
    s = raw"""
        \newcommand{\foo}{bar}
        \foo\foo
        """ |> html
    @test s // "<p>barbar</p>"
    s = raw"""
        \newcommand{\foo}[1]{bar:#1}
        \foo{hello}
        """ |> html
    @test s // "<p>bar:hello</p>"
    s = raw"""
        \newcommand{\foo}[2]{bar:#1#2}
        \foo{hello}{!}
        """ |> html
    @test s // "<p>bar:hello!</p>"
end

@testset "command - nesting" begin
    s = raw"""
        \newcommand{\foo}[2]{bar:#1#2}
        \newcommand{\ext}[1]{
            \foo{hello}{#1}
        }
        \ext{!}
        """
    sh = s |> html
    @test sh // "<p>bar:hello!</p>"
    sl = s |> latex
    @test sl // "bar:hello!\\par"
end

@testset "environment - basic" begin
    s = raw"""
        \newenvironment{foo}{bar:}{:baz}
        \begin{foo}
        abc
        \end{foo}
        ABC
        """ |> html
    @test s // "bar:abc:baz<p>ABC</p>"
    s = raw"""
        \newenvironment{foo}[2]{bar/#1/}{/#2/baz}
        \begin{foo}{A}{B}
        abc
        \end{foo}
        """ |> html
    @test s // "bar/A/abc/B/baz"
end

@testset "environment - nesting" begin
    s = raw"""
        \newenvironment{foo}{bar-}{-baz}
        \newenvironment{fooz}{zar-}{-zaz}
        \begin{foo}
            abc
            \begin{fooz}
                def
            \end{fooz}
            ghi
        \end{foo}
        """
    sh = s |> html
    @test sh // "<p>bar-abc</p>\nzar-def-zaz<p>ghi-baz</p>"
    sl = s |> latex
    @test sl // "bar-abc\\par\nzar-def-zaz\\par\nghi-baz\\par"
end
