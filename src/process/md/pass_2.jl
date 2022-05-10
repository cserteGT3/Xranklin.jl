"""
    process_md_file_pass_2

[threaded] iHTML to HTML. Resolve layout, DBB, pagination.
"""
function process_md_file_pass_2(
            lc::LocalContext,
            opath::String,
            final::Bool
        )::Nothing

        ihtml = getvar(lc, :_generated_ihtml, "")
        odir  = dirname(opath)
        cleanup_paginated(odir)

        # XXX TODO XXX
        # skeleton_path = path(:folder) / getvar(lc, :layout_skeleton, "")
        # if isfile(skeleton_path)
        # end

        # ---------------------------------------------------------------------

        pgfoot_path = path(:folder) / getvar(lc, :layout_page_foot, "")
        page_foot   = isfile(pgfoot_path) ? read(pgfoot_path, String) : ""

        c_tag   = getvar(lc, :content_tag,   "")
        c_class = getvar(lc, :content_class, "")
        c_id    = getvar(lc, :content_id,    "")
        body    = ""
        if !isempty(c_tag)
            body = """
                <$(c_tag) $(attr(:class, c_class)) $(attr(:id, c_id))>
                  $ihtml
                  $page_foot
                </$(c_tag)>
                """
        else
            body = """
                $ihtml
                $page_foot
                """
        end

        head_path  = path(:folder) / getvar(lc.glob, :layout_head, "")::String
        full_page  = isfile(head_path) ? read(head_path, String) : ""
        full_page *= body
        foot_path  = path(:folder) / getvar(lc.glob, :layout_foot, "")::String
        full_page *= isfile(foot_path) ? read(foot_path, String) : ""

        # ---------------------------------------------------------------------

        converted_html = html2(full_page, lc)

        open(opath, "w") do outf
            write(outf, converted_html)
        end

        #
        # PAGINATION
        # > if there is pagination, we take the file at `opath` and
        # rewrite it (to resolve PAGINATOR_TOKEN) n+1 time where n is
        # the number of pages.
        # For instance if there's a pagination with effectively 3 pages,
        # then 4 pages will be written (the base page, then pages 1,2,3).
        #
        paginator_name = getvar(lc, :_paginator_name)
        if isempty(paginator_name)
            process_not_paginated(lc.glob, lc.rpath, odir, final)
        else
            process_paginated(lc, opath, paginator_name, final)
        end

    return
end



"""
    cleanup_paginated(odir)

Remove all `odir/k/` dirs to avoid ever having spurious such dirs.
Re-creating these dirs and the file in it takes negligible time.
"""
function cleanup_paginated(
            odir::String
        )::Nothing

    # remove all pagination folders from odir
    # we're looking for folders that look like '/1/', '/2/' etc.
    # so their name is all numeric, does not start with 0 and
    # it's a directory --> remove
    for e in readdir(odir)
        if all(isnumeric, e) && first(e) != '0'
            dp = odir / e
            isdir(dp) && rm(dp, recursive=true)
        end
    end
    return
end


"""
    process_not_paginated(gc, rpath, odir)

Handles the non-paginated case. Checks if the page was previously paginated,
if it wasn't, do nothing. Otherwise, update `gc.paginated` to reflect that
it's not paginated anymore.
"""
function process_not_paginated(
            gc::GlobalContext,
            rpath::String,
            odir::String,
            final::Bool
        )::Nothing

    rpath in gc.paginated || return
    setdiff!(gc.paginated, rpath)
    adjust_base_url(gc, rpath, opath; final)
    return
end


"""
    process_paginated(gc, rpath, opath, paginator_name)

Handles the paginated case. It takes the base file `odir/index.html` and
rewrites it to match the `/1/` case by replacing the `PAGINATOR_TOKEN`
(so `odir/index.html` and `odir/1/index.html` are identical). It then
goes on to write the other pages as needed.
"""
function process_paginated(
            lc::LocalContext,
            opath::String,
            paginator_name::String,
            final::Bool
        )::Nothing

    iter = getvar(lc, Symbol(paginator_name)) |> collect
    npp  = getvar(lc, :_paginator_npp, 10)
    odir = dirname(opath)

    # how many pages?
    niter = length(iter)
    npg   = ceil(Int, niter / npp)

    # base content (contains the PAGINATOR_TOKEN)
    ctt = read(opath, String)
    ctt = html2(ctt, lc; only=[:paginate])

    # repeatedly write the content replacing the PAGINATOR_TOKEN
    for pgi = 1:npg

        # range of items we should put on page 'pgi'
        sta_i = (pgi - 1) * npp + 1
        end_i = min(sta_i + npp - 1, niter)
        rge_i = sta_i:end_i

        # form the insertion
        ins_i = prod(String(e) for e in iter[rge_i])

        # file destination
        dst = mkpath(odir / string(pgi)) / "index.html"

        # process it in the local context
        ins_i = html(ins_i, set_recursive!(lc))

        # adjust lc
        setvar!(lc, :_relative_url, get_rurl(get_ropath(gc, dst)))

        # form the page with inserted content
        ctt_i = replace(ctt, PAGINATOR_TOKEN => ins_i)

        # write the file
        open(dst, "w") do f
            write(f, ctt_i)
        end
        adjust_base_url(gc, rpath, opath; final)
    end

    # Copy /1/ which must exists to a base (overwrite it so it has the proper inclusion)
    cp(
        odir / "1" / "index.html",
        odir / "index.html",
        force=true
    )
    return
end
