"""
    process_file(a...; kw...)

Take a file (markdown, html, ...) and process it appropriately:

* copy it "as is" in `__site`
* generate a derived file into `__site`

## Paths

    * md file
        -> process_md_file
         -> process_md_file_io!
          -> _process_md_file_html  < OR >  _process_md_file_latex

    * html file
        -> process_html_file
         -> process_html_file_io!

    * other file
        -> copy the file over

"""
function process_file(
            gc::GlobalContext,
            fpair::Pair{String,String},
            case::Symbol,
            t::Float64=0.0;             # compare modif time
            skip_files::Vector{Pair{String, String}}=Pair{String, String}[],
            initial_pass::Bool=false,
            final::Bool=false,
            reproc::Bool=false,
            allow_skip::Bool=false
        )::Nothing

    crumbs(@fname, "$(fpair.first) => $(fpair.second)")

    # Form the full path to the file being considered
    fpath = joinpath(fpair...)

    # Check whether the file should be ignored
    # -> if it's a layout or rss file it gets processed separately
    # -> if it's marked as "to be skipped"
    skip = startswith(fpath, path(:layout)) ||  # no copy
           startswith(fpath, path(:rss))    ||  # no copy
           fpair in skip_files                  # skip
    skip && return

    # Now that we know the file should not be ignored, form the output path
    # i.e. the path where it's expected the file will be written or copied
    opath = get_opath(gc, fpair, case)
    #
    # There are now two processing cases:
    # 1. the file is a MD or HTML file, it should be processed by Franklin to
    #    resolve Franklin-specific commands
    # 2. the file is something else (e.g. an image) then Franklin will just
    #   copy it over to the appropriate location
    #
    off = ifelse(reproc, "... ", "")
    if case in (:md, :html)
        rpath = get_rpath(gc, fpath)
        lc    = get(gc.children_contexts, rpath, DefaultLocalContext(gc; rpath))

        if case == :md
            # process the file and write the result at 'opath'
# XXX            process_md_file(
#                gc, fpath, opath;
#                initial_pass, allow_skip
#            )
            process_md_file(lc, fpath, opath, skip_files, allow_skip, final)

            #
            # # recover the context associated with that page and check if the
            # # output path needs to be corrected to take a 'slug' into account
            # # and *copy* that file over to an additional location matching
            # # the slug. The original output path is kept (a few things rely
            # # on this such as the possibility to skip files early).
            # lc    = gc.children_contexts[rpath]
            # opath = check_slug(lc, opath)
            # # adjust the meta parameters associated with that context so
            # # that if, for instance, a hfun requests the relative URL,
            # # it points to the appropriate new one.
            # set_meta_parameters(lc, fpath, opath)
            #
            # #
            # # If we're not in the initial pass, we need to reprocess all pages
            # # that depend upon definitions from this page which may have
            # # changed now that we just re-processed it.
            # #
            # if !initial_pass
            #     for pg in lc.to_trigger
            #         reprocess(pg, gc; skip_files, msg="(depends on updated vars)")
            #     end
            # end
            #
            # adjust_base_url(gc, rpath, opath; final)
            #
            # if !isempty(getvar(lc, :_paginator_name, ""))
            #     # copy the `odir/1/index.html` (which must exist) to odir/index.html
            #     odir = dirname(opath)
            #     cp(odir / "1" / "index.html", odir / "index.html", force=true)
            # end

        elseif case == :html
            process_html_file(lc, fpath, opath, final)
            # process_html_file(gc, fpath, opath)
            # adjust_base_url(gc, rpath, opath; final)

        end

    else
        # copy the file over if
        # (A) it's not already there
        # (B) it's there but we have a more recent version that's not identical
        if !isfile(opath) || (mtime(opath) < t && !filecmp(fpath, opath))
            cp(fpath, opath, force=true)
        end
    end
    return
end

process_file(fpair::Pair{String,String}, case::Symbol, t::Float64=0.0; kw...) =
    process_file(cur_gc(), fpair, case, t; kw...)


function set_meta_parameters(lc::LocalContext, fpath::String, opath::String)
    rpath  = get_rpath(lc.glob, fpath)
    ropath = get_ropath(lc.glob, opath)
    s = stat(fpath)
    setvar!(lc, :_output_path, opath)
    setvar!(lc, :_relative_path, rpath)
    setvar!(lc, :_relative_url, unixify(ropath))
    setvar!(lc, :_creation_time, s.ctime)
    setvar!(lc, :_modification_time, s.mtime)
end


# ------------ #
# REPROCESSING #
# ------------ #

"""
    reprocess(rpath, gc; skip_files, msg)

Re-process a md file at 'rpath'. This happens, for instance, when a page 'A.md'
has just been processed and a page 'B.md' depends upon definitions or anchors
from 'A.md'.
"""
function reprocess(
            rpath::String, gc::GlobalContext;
            skip_files::Vector{Pair{String, String}}=Pair{String,String}[],
            msg::String="",
            final::Bool=false
            )::Nothing
    # check if the file was marked as 'to be skipped'
    fpair = path(:folder) => rpath
    fpair in skip_files && return

    # check if the file still exists (it might have been removed e.g. in the case
    # of rm_tag_page)
    isfile(joinpath(fpair...)) || return

    # otherwise reprocess the file
    case = ifelse(splitext(rpath)[2] == ".html", :html, :md)
    start = time(); @info """
        ⌛ [reprocess] $(hl(str_fmt(rpath), :cyan)) $msg
        """
    process_file(gc, fpair, case; final, reproc=true)
    δt = time() - start; @info """
        ... ✔ [reprocess] $(hl(time_fmt(δt)))
        """
    return
end


# --------------- #
# ADJUST BASE URL #
# --------------- #
