#=

Page at rpath
-------------

1. does not define tags
    1. the page did not previously define tags  --> do nothing
    2. the page *used* to define [tag_id, ...]
        --> remove [tag_id, ...] from lc (automatic)
        --> for each [tag_id, ...] remove from gc: setdiff!(gc.tags[tag_id].locs, rpath)
        --> if consequently a gc.tags[tag_id].locs is empty, remove the tag page

2. does define tags
    0. check new tags / removed tags
    1. add new tags
    2. remove removed tags

Tag page calls {{taglist $tag}} and user can overwrite it.
=#

"""
    add_tag(gc, id, name, rpath)

Add a tag `id => name` for page at `rpath` in gc. Then (re)write the
corresponding tag page.
"""
function add_tag(
            gc::GlobalContext,
            id::String,         # e.g.: foo_bar
            name::String,       # e.g.: Foo Bar
            rpath::String
            )::Nothing
    crumbs("add_tag", "$id (from $rpath)")

    if id in keys(gc.tags)
        union!(gc.tags[id].locs, [rpath])
    else
        gc.tags[id] = Tag(id, name, rpath)
    end
    write_tag_page(gc, id)
    return
end


"""
    rm_tag(gc, id, rpath)

Remove a tag `id` from page at `rpath` within global context `gc`.
Then either remove or rewrite the corresponding tag page.
"""
function rm_tag(gc::GlobalContext, id::String, rpath::String)::String
    crumbs("rm_tag", "$id (from $rpath)")
    # this check should be superfluous
    id in keys(gc.tags) || return
    # remove the location from GC
    setdiff!(gc.tags[id].locs, rpath)
    # check if there's no locations --> remove the page
    if isempty(gc.tags[id].locs)
        delete!(gc.tags, id)
        rm_tag_page(gc, id)
    else
        write_tag_page(gc, id)
    end
    return
end


"""
    tag_path(gc, id)

Return the path to the tag page corresponding to the tag `id`.
"""
tag_path(gc::GlobalContext, id::String) =
    path(:site) / getvar(gc, :tags_prefix, "tags") / id / "index.html"


"""
    write_tag_page(gc, id)

Write a new (or re-write) a tag page.
"""
function write_tag_page(gc::GlobalContext, id::String)::Nothing
    tp = tag_path(gc, id)
    mkpath(splitdir(tp)[1])
    ct = """
        <!doctype html>
        <html lang="en">
        <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <title>Tag: {{fill tag_name}}</title>
        </head>
        <body>
          <div class="tagpage">
            {{taglist}}
          </div>
        </body>
        </html>
        """
    # check if a tag layout is not given explicitly
    tt = getvar(gc, :layout_tag, "_layout/tag.html")
    if isfile(tt)
        ct = read(tt, String)
    end

    # convert tag layout and write to file
    base = getvar(gc, :tags_prefix, "tags")
    lc   = DefaultLocalContext(gc; rpath="/$base/$id")
    setvar!(lc, :tag_id, id)
    setvar!(lc, :tag_name, gc.tags[id].name)
    open(tp, "w") do f
        write(f, html2(ct, lc))
    end
    return
end


"""
    rm_tag_page(gc, id)

Remove the tag page corresponding to `id` if it exists.
"""
function rm_tag_page(gc::GlobalContext, id::String)::Nothing
    tp = tag_path(gc, id)
    # force=true means it won't fail if the page doesn't exist
    rm(tp, force=true)
    return
end


"""
    get_page_tags(lc=cur_lc())

Return the dictionary of `{id => name}` for the tags on the current page.

## Note

This is exported so that users can leverage it in their Utils module.
"""
function get_page_tags(lc::LocalContext)::LittleDict{String,String}
    tags = getvar(lc, :tags, String[])
    return get_tags_dict(tags)
end
function get_page_tags()::LittleDict{String,String}
    lc = cur_lc()
    lc === nothing && return LittleDict{String,String}()
    return get_page_tags(lc)
end


"""
    get_tags_dict(tags)

Form the `{id => name}` out of the list of tag names.
"""
function get_tags_dict(tags::Vector{String})::LittleDict{String,String}
    tags_dict = LittleDict{String, String}()
    for t in tags
        id = string_to_anchor(t)
        if id ∉ keys(tags_dict)
            tags_dict[id] = t
        end
    end
    return tags_dict
end
