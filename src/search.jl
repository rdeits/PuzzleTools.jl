module Search

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
        ([dfs.start], [(PausedIterator{typeof(neighbors), typeof(state)}(), false)]))
end

function Base.iterate(dfs::LazyDFS, (path, metadata))
    while !isempty(path)
        meta, explored = pop!(metadata)
        if !explored
            result = dfs.evaluate(path)
            if result == :good
                push!(metadata, (meta, true))
                return copy(path), (path, metadata)
            elseif result == :partial
                child_iterator = dfs.children(path)
                if child_iterator === nothing
                    pop!(path)
                else
                    itr = iterate(child_iterator)
                    if itr !== nothing
                        child, child_state = itr
                        push!(metadata, (meta, true))
                        push!(path, child)
                        new_metadata = (PausedIterator(child_iterator, child_state), false)
                        if typeof(new_metadata) <: eltype(metadata)
                            push!(metadata, new_metadata)
                        else
                            metadata = vcat(metadata, new_metadata)
                        end
                        continue
                    else
                        pop!(path)
                    end
                end
            else
                pop!(path)
            end
        else
            pop!(path)
        end
        @assert length(path) == length(metadata)
        if !isempty(path)
            itr = iterate(meta.iterator, meta.state)
            if itr !== nothing
                node, state = itr
                push!(path, node)
                push!(metadata, (PausedIterator(meta.iterator, state), false))
            end
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

    * :good -> This path is done (i.e. has reached the goal set)
    * :bad -> This path is impossible, and no children should be explored
    * :partial -> This path is not known to be bad, so we should explore its children

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