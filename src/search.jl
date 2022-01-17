module Search

export dfs

# struct BreadthFirst end
# struct DepthFirst end

# function search(start::T,
#         transitions,
#         method,
#         iscomplete,
#         ispartial = x -> true) where {T}
#     results = Vector{Vector{T}}()
#     active_set = [[start]]
#     while !isempty(active_set)
#         candidate = select!(active_set, method)
#         # @show candidate
#         if iscomplete(candidate)
#             push!(results, candidate)
#         elseif ispartial(candidate)
#             for child in transitions(candidate)
#                 push!(active_set, vcat(candidate, child))
#             end
#         end
#     end
#     results
# end

# select!(active_set, ::BreadthFirst) = popfirst!(active_set)
# select!(active_set, ::DepthFirst) = pop!(active_set)


# function backtrack!(path)
#     while !isempty(path)
#         (node, state, iterator) = pop!(path)
#         iter_result = iterate(iterator, state)
#         if iter_result != nothing
#             push!(path, (iter_result..., iterator))
#             return
#         end
#     end
# end

# nodes(path) = getindex.(path, 1)

# function lazy_dfs(start, children, evaluate)
#     Channel{Vector{typeof(start)}}() do channel
#         iterator = children(start)
#         itr = iterate(iterator)
#         if itr === nothing
#             return
#         end
#         path = [(itr..., iterator)]
#         while !isempty(path)
#             node, state, iterator = path[end]
#             result = evaluate(node)
#             if result == :done
#                 put!(channel, nodes(path))
#                 backtrack!(path)
#             elseif result == :bad
#                 backtrack!(path)
#             else
#                 neighbors = children(node)
#                 itr = iterate(neighbors)
#                 if itr !== nothing
#                     push!(path, (itr..., neighbors))
#                 else
#                     backtrack!(path)
#                 end
#             end
#         end
#     end
# end

struct LazyDFS{T, FC <: Function, FE <: Function}
    start::T
    children::FC
    evaluate::FE
end

struct PathEntry{T, S, I}
    node::T
    state::S
    iterator::I

    PathEntry{T, S, I}(node::T) where {T, S, I} = new{T, S, I}(node)
    PathEntry(node::T, state::S, iterator::I) where {T, S, I} = new{T, S, I}(node, state, iterator)
end

function Base.iterate(dfs::LazyDFS)
    neighbors = dfs.children(dfs.start)
    itr = iterate(neighbors)
    if itr === nothing
        return nothing
    end
    _, state = itr
    path = [(PathEntry{typeof(dfs.start), typeof(state), typeof(neighbors)}(dfs.start), false)]
    return iterate(dfs, path)
end

function Base.iterate(dfs::LazyDFS, path)
    while !isempty(path)
        entry, explored = pop!(path)
        if !explored
            result = dfs.evaluate(entry.node)
            if result == :good
                push!(path, (entry, true))
                return vcat(map(e -> e[1].node, path), entry.node), path
            end
            if result == :partial
                iterator = dfs.children(entry.node)
                itr = iterate(iterator)
                if itr !== nothing
                    child, child_state = itr
                    push!(path, (entry, true))
                    push!(path, (PathEntry(child, child_state, iterator), false))
                    continue
                end
            end
        end
        if !isempty(path)
            itr = iterate(entry.iterator, entry.state)
            if itr !== nothing
                node, state = itr
                push!(path, (PathEntry(node, state, entry.iterator), false))
            end
        end
    end
    return nothing
end

Base.IteratorSize(::Type{<:LazyDFS}) = Base.SizeUnknown()
Base.eltype(::Type{<:LazyDFS{T}}) where {T} = Vector{T}

"""
Depth-first search starting at `start`. Exploration is controlled by two functions:

    children(node) -> Return an iterable collection of child nodes.

    evaluate(node) -> Return a Symbol describing the given node in the search. Returns one of:

    * :good -> This node is done (i.e. has reached the goal set)
    * :bad -> This node is impossible, and no children should be explored
    * :partial -> This node is not known to be bad, so we should explore its children

Returns an iterator which performs the search lazily on demand. To get a single result, you can do:

    first(search(start, children, evaluate))

Or you can iterate over results:

    for result in search(start, children, evaluate)
        ...
    end

Or to get all results in a vector, you can do:

    collect(search(start, children, evaluate))
"""
function dfs(start::S, children::FC, evaluate::FE) where {S, FC, FE}
    return LazyDFS{S, FC, FE}(start, children, evaluate)
end

end