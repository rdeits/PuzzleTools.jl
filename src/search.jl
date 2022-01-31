module Search

using Graphs: AbstractGraph, outneighbors, SimpleGraph, add_edge!

export dfs

struct LazyDFS{T, FC <: Function, FE <: Function}
    start::T
    children::FC
    evaluate::FE
end

struct PausedIterator{I, S}
    iterator::I
    state::S

    PausedIterator(iterator::I, state::S) where {I, S} = new{I, S}(iterator, state)
    PausedIterator{I,S}() where {I, S} = new{I, S}()
end

function Base.iterate(dfs::LazyDFS)
    neighbors = dfs.children([dfs.start])
    if neighbors === nothing
        return nothing
    end
    itr = iterate(neighbors)
    if itr === nothing
        return nothing
    end
    _, state = itr
    iterate(dfs,
        ([dfs.start], [PausedIterator{typeof(neighbors), typeof(state)}()]))
end

function maybe_push!(x::AbstractVector{T}, y::T) where {T}
    push!(x, y)
    x
end

function maybe_push!(x::AbstractVector{T1}, y::T2) where {T1, T2}
    dest = similar(x, Base.promote_typejoin(T1, T2), length(x) + 1)
    copyto!(dest, x)
    dest[end] = y
    dest
end

function backtrack!(path, metadata)
    while !isempty(path)
        pop!(path)
        meta = pop!(metadata)
        if !isempty(path)
            itr = iterate(meta.iterator, meta.state)
            if itr !== nothing
                node, state = itr
                push!(path, node)
                metadata = maybe_push!(metadata, PausedIterator(meta.iterator, state))
                return path, metadata
            end
        end
    end
    return path, metadata
end

function next_node(dfs::LazyDFS, (path, metadata))
    # First, see if we can explore deeper
    child_iterator = dfs.children(path)
    if child_iterator !== nothing
        itr = iterate(child_iterator)
        if itr !== nothing
            child, child_state = itr
            push!(path, child)
            metadata = maybe_push!(metadata, PausedIterator(child_iterator, child_state))
            return (path, metadata)
        end
    end
    return backtrack!(path, metadata)
end

function Base.iterate(dfs::LazyDFS, (path, metadata))
    while !isempty(path)
        result = dfs.evaluate(path)
        if result == :good
            output = copy(path)
            path, metadata = backtrack!(path, metadata)
            return output, (path, metadata)
        elseif result == :good_and_partial
            output = copy(path)
            path, metadata = next_node(dfs, (path, metadata))
            return output, (path, metadata)
        elseif result == :bad
            path, metadata = backtrack!(path, metadata)
        elseif result == :partial
            path, metadata = next_node(dfs, (path, metadata))
        end
    end
    return nothing
end

Base.IteratorSize(::Type{<:LazyDFS}) = Base.SizeUnknown()
Base.eltype(::Type{<:LazyDFS{T}}) where {T} = Vector{T}

"""
Depth-first search starting at `start`. Exploration is controlled by two functions:

    children(path) -> Return an iterable collection of child nodes. May also return `nothing` if no children exist.

    evaluate(path) -> Return a Symbol describing the given path in the search. Returns one of:

    * :good -> This path is done (i.e. has reached the goal set and should not be explored further)
    * :good_and_partial -> This path has reached the goal set, but should be explored further too.
    * :bad -> This path is impossible, and no children should be explored
    * :partial -> This path is not known to be bad, so we should explore its children

The results of the search will be the set of paths which were rated as `:good` or `:good_and_partial`.

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

"""
Depth-first search over the given graph.
"""
function Search.dfs(graph::AbstractGraph, start, evaluate; allow_cycles=true)
    if allow_cycles
        children = path -> outneighbors(graph, last(path))
    else
        children = path -> (i for i in outneighbors(graph, last(path))
            if i ∉ path)
    end
    dfs(start, children, evaluate)
end


"""
Create a graph corresponding to a rectangular grid with the given dimensions, including diagonal connections. See `Graphs.grid` from `Graphs.jl` for the non-diagonal variant.
"""
function grid_with_diagonals(dims::NTuple{N}) where {N}
    graph = SimpleGraph(prod(dims))
    L = LinearIndices(dims)
    for I in CartesianIndices(dims)
        indices = Tuple(I)
        ranges = UnitRange.(max.(1, indices .- 1), min.(indices .+ 1, dims))
        for other in Iterators.product(ranges...)
            add_edge!(graph, L[I], L[other...])
        end
    end
    graph
end

end