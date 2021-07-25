module Search

function breadth_first(start::T,
        transitions,
        iscomplete = x -> true,
        ispartial = x -> true) where T
    paths = T[]
    active_set = T[start]
    while true
        new_active_set = T[]
        for element in active_set
            children = transitions(element)
            if isempty(children)
                if iscomplete(element)
                    push!(paths, element)
                end
            else
                append!(new_active_set, children)
            end
        end
        if isempty(new_active_set)
            break
        else
            active_set = new_active_set
        end
    end
    paths
end

function depth_first(start::T,
        transitions,
        iscomplete = x -> true,
        ispartial = x -> true;
        limit=Inf) where {T}
    active_set = T[start]
    paths = T[]
    while !isempty(active_set)
        element = pop!(active_set)
        for child in transitions(element)
            if iscomplete(child)
                push!(paths, child)
                if length(paths) >= limit
                    return paths
                end
            elseif ispartial(child)
                push!(active_set, child)
            end
        end
    end
    return paths
end

end