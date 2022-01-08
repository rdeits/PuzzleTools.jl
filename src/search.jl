module Search

export search,
       BreadthFirst,
       DepthFirst

struct BreadthFirst end
struct DepthFirst end

function search(start::T,
        transitions,
        method,
        iscomplete,
        ispartial = x -> true) where {T}
    results = Vector{Vector{T}}()
    active_set = [[start]]
    while !isempty(active_set)
        candidate = select!(active_set, method)
        # @show candidate
        if iscomplete(candidate)
            push!(results, candidate)
        elseif ispartial(candidate)
            for child in transitions(candidate)
                push!(active_set, vcat(candidate, child))
            end
        end
    end
    results
end

select!(active_set, ::BreadthFirst) = popfirst!(active_set)
select!(active_set, ::DepthFirst) = pop!(active_set)

end