module WordGrids

using ..PuzzleTools: is_valid_prefix, entries_with_prefix, Stringy
using ..PuzzleTools.Words: sowpods
using ..PuzzleTools.Search: dfs

function fits_in(word::Stringy, entry::AbstractVector)
    (length(word) == length(entry)) || return false
    @inbounds for i in 1:length(entry)
        if !(entry[i] == Char(0) || entry[i] == word[i])
            return false
        end
    end
    return true
end

function longest_prefix(entry)
    i = findfirst(==(Char(0)), entry)
    if i === nothing
        @view entry[1:end]
    else
        @view entry[1:(i - 1)]
    end
end

function possible_assignments(corpus, entry::AbstractVector)
    [word for word in entries_with_prefix(corpus, longest_prefix(entry)) if fits_in(word, entry)]
end

struct WordGrid
    # Size: num_entries.
    # Each entry is a vector of linear indices in the grid
    entries::Vector{Vector{Int}}

    # Size: num_cells.
    # For each cell, gives the list of (entry index, index within entry) for all entries that include that cell
    intersections::Vector{Vector{Tuple{Int, Int}}}

    function WordGrid(entries::AbstractVector{<:AbstractVector{<:Integer}})
        max_cell_index = maximum(Iterators.flatten(entries))
        intersections = [Vector{Tuple{Int, Int}}() for _ in 1:max_cell_index]
        for (entry_index, entry) in enumerate(entries)
            for (cell_index_in_entry, cell) in enumerate(entry)
                push!(intersections[cell], (entry_index, cell_index_in_entry))
            end
        end
        new(entries, intersections)
    end
end

function block_crossword(cells::AbstractMatrix{Bool}; min_length=3)
    entries = Vector{Vector{Int}}()
    for row in axes(cells, 1)
        for col in axes(cells, 2)
            if !cells[row, col]
                continue
            end
            if col == firstindex(cells, 2) || !cells[row, col - 1]
                new_entry = [LinearIndices(cells)[row, col]]
                for j in (col + 1):lastindex(cells, 2)
                    if cells[row, j]
                        push!(new_entry, LinearIndices(cells)[row, j])
                    else
                        break
                    end
                end
                if length(new_entry) >= min_length
                    push!(entries, new_entry)
                end
            end
            if row == firstindex(cells, 1) || !cells[row - 1, col]
                new_entry = [LinearIndices(cells)[row, col]]
                for i in (row + 1):lastindex(cells, 1)
                    if cells[i, col]
                        push!(new_entry, LinearIndices(cells)[i, col])
                    else
                        break
                    end
                end
                if length(new_entry) >= min_length
                    push!(entries, new_entry)
                end
            end
        end
    end
    WordGrid(entries)
end

num_entries(grid::WordGrid) = length(grid.entries)
num_cells(grid::WordGrid) = length(grid.intersections)

struct WordGridState
    # Size: num_cells
    cells::Vector{Char}

    # Size: num_entries
    # Indices of words which can still fit in the given entry
    options::Vector{Union{Vector{Int}, Nothing}}
end

function WordGridState(grid::WordGrid, corpus)
    cells = fill(Char(0), num_cells(grid))
    options = Union{Vector{Int}, Nothing}[Vector{Int}() for _ in 1:num_entries(grid)]

    # First, populate the options for each entry
    for (i, entry) in enumerate(grid.entries)
        options[i] = filter(1:length(corpus)) do word_index
            fits_in(corpus[word_index], @view(cells[entry]))
        end
    end

    # @time for (i, entry) in enumerate(grid.entries)
    #     filter!(options[i]) do word_index
    #         for (index_in_entry, cell) in enumerate(entry)
    #             for (neighbor, index_in_neighbor) in grid.intersections[cell]
    #                 if !any(w -> corpus[w][index_in_neighbor] == corpus[word_index][index_in_entry], options[neighbor])
    #                     return false
    #                 end
    #             end
    #         end
    #         return true
    #     end
    # end


    WordGridState(cells, options)
end

Base.copy(state::WordGridState) = WordGridState(copy(state.cells), (x -> x === nothing ? x : copy(x)).(state.options))

function apply!(state::WordGridState, grid::WordGrid, corpus, entry_index::Integer, word::Stringy)
    for (i, c) in zip(grid.entries[entry_index], word)
        state.cells[i] = c
    end

    state.options[entry_index] = nothing

    for cell_index in grid.entries[entry_index]
        for (first_neighbor, index_in_first_neighbor) in grid.intersections[cell_index]
            if first_neighbor == entry_index
                continue
            end
            if state.options[first_neighbor] === nothing
                continue
            end
            # First, let's prune out options for the other entry which contradict the word we've chosen
            filter!(state.options[first_neighbor]) do word_index
                corpus[word_index][index_in_first_neighbor] == state.cells[cell_index]
            end
            # Now let's do some more pruning. For each of the neighbors of `first_neighbor`, let's make sure they at least have one remaining possibile fill
            filter!(state.options[first_neighbor]) do word_index
                for (index_in_first_neighbor, cell) in enumerate(grid.entries[first_neighbor])
                    for (second_neighbor, index_in_second_neighbor) in grid.intersections[cell]
                        if state.options[second_neighbor] === nothing
                            continue
                        end
                        if !any(w -> corpus[w][index_in_second_neighbor] == corpus[word_index][index_in_first_neighbor], state.options[second_neighbor])
                            return false
                        end
                    end
                end
                return true
            end
        end
    end
    state
end

function generate_fills(grid::WordGrid, unfiltered_corpus)
    corpus = collect.(unfiltered_corpus)
    entry_lengths = Set(length.(grid.entries))
    filter!(corpus) do word
        length(word) in entry_lengths
    end
    sort!(corpus)

    function children(nodes)
        state = last(nodes)
        num_options, most_constrained_entry = findmin(x -> x === nothing ? typemax(Int) : length(x), state.options)
        if num_options == 0
            return nothing
        end
        (apply!(copy(state), grid, corpus, most_constrained_entry, corpus[word_index]) for word_index in state.options[most_constrained_entry])
    end

    function evaluate(nodes)
        state = last(nodes)
        if all(x -> x === nothing, state.options)
            :good
        else
            :partial
        end
    end

    dfs(WordGridState(grid, corpus), children, evaluate)
end


end
