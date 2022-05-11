"""
    {{toc min max}}

H-Function for the table of contents, where `min` and `max` control the
minimum level and maximum level of  the table of content.
"""
function hfun_toc(
            lc::LocalContext,
            p::VS;
            tohtml=true
        )::String

    # check parameters
    c = _hfun_check_nargs(:toc, p; k=2)
    isempty(c) || return c

    # retrieve the headings of the local context
    # (type PageHeadings = Dict{String, Tuple{Int, Int}})
    headings = lc.headings
    isempty(headings) && return ""

    # try to parse min-max level
    min = 0
    max = 100
    try
        min = parse(Int, p[1])
        max = parse(Int, p[2])
    catch
        @warn """
            {{toc ...}}
            Toc should get two integers, couldn't parse the args to int.
            """
        return hfun_failed("toc", p)
    end

    # trim the headings corresponding to min/max, each header is (id => (nocc, lvl))
    headings = [
        (; id, level, text)
        for (id, (_, level, text)) in headings
        if min ≤ level ≤ max
    ]
    base_level = minimum(h.level for h in headings) - 1
    cur_level  = base_level

    io = IOBuffer()
    for h in headings
        if h.level ≤ cur_level
            # close previous list item
            write(io, "</li>")
            # close additional sublists for each level eliminated
            for i in cur_level-1:-1:h.level
                write(io, "</ol></li>")
            end
            # reopen for this list item
            write(io, "<li>")

        elseif h.level > cur_level
            # open additional sublists for each level added
            for i in cur_level+1:h.level
                write(io, "<ol><li>")
            end
        end
        write(io, "<a href=\"#$(h.id)\">$(h.text)</a>")
        cur_level = h.level
    end

    # Close remaining lists, as if going down to the base level
    for i = cur_level-1:-1:base_level
        write(io, "</li></ol>")
    end

    return html_div(
            String(take!(io));
            class=getvar(lc, :toc_class, "toc")
        )
end


"""
    {{eqref id}}

Reference to an equation, processed as hfun to allow forward references.
Necessarily in html context (this is generated by `\\eqref`).
"""
function hfun_eqref(
            lc::LocalContext,
            p::VS;
            tohtml=true
        )::String

    # no check needed as generated
    id      = p[1]
    eqrefs_ = eqrefs(lc)
    id ∈ keys(eqrefs_) || return "<b>??</b>"
    text  = eqrefs_[id] |> string
    class = getvar(lc.glob, :eqref_class, "eqref")
    return html_a(text; href="#$(id)", class)
end


"""
    {{cite id}}

Reference to a bib anchor. Necessarily in html context (generated by `\\cite`,
`\\citet` and `\\citep`).
"""
function hfun_cite(
            lc::LocalContext,
            p::VS;
            tohtml=true
        )::String

    # no check needed as generated
    id       = p[1]
    bibrefs_ = bibrefs()
    id ∈ keys(bibrefs_) || return "<b>??</b>"
    text  = bibrefs_[id]
    class = getvar(lc.glob, :bibref_class, "bibref")
    return html_a(text; href="#$(id)", class)
end


"""
    {{reflink id}}

Global reference to an id that might be on any page (see anchor).
This should not be used directly by a user. It should only be used
via a `##` link in markdown such as `[a link](## some id)`.
"""
function hfun_reflink(
            lc::LocalContext,
            p::VS;
            tohtml=true
        )::String

    # should not really need to check but anyway
    c = _hfun_check_nargs(:reflink, p; k=1)
    isempty(c) || return c

    target = get_anchor(lc.glob, p[1], lc.rpath)
    # if the target is on the landing page, it will start with /index/
    # which we don't want, so we apply a quick replacement
    return replace(target, r"^\/index\/" => "/")
end


"""
    {{link_a ref title}}

Insert a link if the reference exists otherwise just insert `[title]`.
"""
function hfun_link_a(
            lc::LocalContext,
            p::VS;
            tohtml=true
        )::String

    ref, title = p
    title      = sstrip(title, '\"')
    refrefs_   = merge(refrefs(cur_gc()), refrefs(lc))
    keysrefs   = keys(refrefs_)
    ref ∈ keysrefs || return "[$title]"

    # footnote case
    if first(ref) == '^'
        i       = get(getvar(lc, :_fnrefs, Dict{String, Int}()), ref, 0)
        id      = chop(ref, head=1, tail=0)
        id_to   = "#fn_$id"
        id_from = "fnref_$id"
        return """
            <sup>$(html_a("[$i]"; href=id_to))</sup>
            <a id="$id_from"></a>
            """
    end
    return html_a(title; href="$(refrefs_[ref])")
end

"""
    {{img_a ref title}}

Insert an img if the reference exists otherwise just insert `![title]`.
"""
function hfun_img_a(
            lc::LocalContext,
            p::VS;
            tohtml=true
        )::String

    ref, alt = p
    alt      = strip(alt, '\"') |> string
    refrefs_ = merge(refrefs(cur_gc()), refrefs(lc))
    ref ∈ keys(refrefs_) || return "![$alt]"
    return html_img(refrefs_[ref]; alt)
end

"""
    {{footnotes}}
"""
function hfun_footnotes(
            lc::LocalContext;
            tohtml=true
        )::String

    refs  = refrefs(lc)
    fns   = [k for k in keys(refs) if first(k) == '^']
    fn_io = IOBuffer()
    if !isempty(fns)
        write(fn_io, """
            <div id=\"fn-defs\">
            """)
        write(fn_io, """
              <a id="fn-defs"></a>
              """)
        fnt = getvar(lc, :fn_title, "")
        if !isempty(fnt)
            write(fn_io, """
              <div class="fn-title">$fnt</div>
              """)
        end
        write(fn_io, "<ol>")
        for fn in fns
            id = chop(fn, head=1, tail=0)
            # see hfun_link_a
            write(fn_io, """
              <li>
                <a id="fn_$(id)"></a>
                <a href="#fnref_$(id)" class="fn-hook-btn">&ldca;</a>
                $(refs[fn])
              </li>
              """)
        end
        write(fn_io, """
              </ol>
            </div>
            """)
    end
    return String(take!(fn_io))
end
