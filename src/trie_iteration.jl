using DataStructures: Trie

struct TrieNodes{T}
    trie::Trie{T}
    prefix::String
end

struct TrieNodeIterationState{T}
    path::Vector{Tuple{Trie{T}, Int}}
    prefix::String
end


function Base.iterate(t::TrieNodes{T}) where {T}
    (t.prefix, t.trie), TrieNodeIterationState{T}([(t.trie, 0)], t.prefix)
end

function backtrack!(state::TrieNodeIterationState{T}) where {T}
    path = state.path
    prefix = state.prefix
    while length(path) > 1
        _, state = pop!(path)
        prefix = prefix[1:prevind(prefix, end)]
        itr = iterate(last(path)[1].children, state)
        if itr !== nothing
            (char, child), state = itr
            push!(path, (child, state))
            prefix = string(prefix, char)
            return (prefix, child), TrieNodeIterationState{T}(path, prefix)
        end
    end
    return nothing
end

function Base.iterate(t::TrieNodes{T}, state::TrieNodeIterationState{T}) where {T}
    itr = iterate(last(state.path)[1].children)
    if itr === nothing
        return backtrack!(state)
    else
        (char, child), child_iter_state = itr
        path = state.path
        push!(path, (child, child_iter_state))
        prefix = string(state.prefix, char)
        return (prefix, child), TrieNodeIterationState{T}(path, prefix)
    end

end

Base.IteratorSize(::Type{TrieNodes{T}}) where {T} = Base.SizeUnknown()

Base.eltype(::Type{TrieNodes{T}}) where {T} = Tuple{String, Trie{T}}

function iterable_nodes(t::Trie, prefix::AbstractString="")
    TrieNodes(t, prefix)
end

function iterable_keys(t::Trie, prefix::AbstractString="")
    Iterators.map(first,
        Iterators.filter(
            ((prefix, node),) -> node.is_key,
            iterable_nodes(t, prefix)))
end
