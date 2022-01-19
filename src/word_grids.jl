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
    # For each cell, gives the indices of entries which include it
    intersections::Vector{Vector{Int}}

    function WordGrid(entries::AbstractVector{<:AbstractVector{<:Integer}})
        max_cell_index = maximum(Iterators.flatten(entries))
        intersections = [Vector{Int}() for _ in 1:max_cell_index]
        for (entry_index, entry) in enumerate(entries)
            for cell in entry
                push!(intersections[cell], entry_index)
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

# function num_options(corpus, entry::AbstractVector)
#     count(w -> true, possible_assignments(corpus, entry))
# end

function WordGridState(grid::WordGrid, corpus)
    cells = fill(Char(0), num_cells(grid))
    options = Union{Vector{Int}, Nothing}[Vector{Int}() for _ in 1:num_entries(grid)]
    for (i, entry) in enumerate(grid.entries)
        options[i] = filter(1:length(corpus)) do word_index
            fits_in(corpus[word_index], @view(cells[entry]))
        end
    end

    WordGridState(cells, options)
end

Base.copy(state::WordGridState) = WordGridState(copy(state.cells), (x -> x === nothing ? x : copy(x)).(state.options))

function apply!(state::WordGridState, grid::WordGrid, corpus, entry_index::Integer, word::Stringy)
    for (i, c) in zip(grid.entries[entry_index], word)
        state.cells[i] = c
    end

    state.options[entry_index] = nothing

    for cell_index in grid.entries[entry_index]
        for intersecting_entry_index in grid.intersections[cell_index]
            if intersecting_entry_index == entry_index
                continue
            end
            if state.options[intersecting_entry_index] === nothing
                continue
            end
            filter!(state.options[intersecting_entry_index]) do word_index
                fits_in(corpus[word_index], @inbounds(@view(state.cells[grid.entries[intersecting_entry_index]])))
            end
        end
    end
    state
end

function generate_fills(grid::WordGrid, corpus)
    collected_words = sort(collect.(corpus.sorted_entries))

    function children(nodes)
        state = last(nodes)
        num_options, most_constrained_entry = findmin(x -> x === nothing ? typemax(Int) : length(x), state.options)
        if num_options == 0
            return nothing
        end
        (apply!(copy(state), grid, collected_words, most_constrained_entry, corpus[word_index]) for word_index in state.options[most_constrained_entry])
    end

    function evaluate(nodes)
        state = last(nodes)
        if all(x -> x === nothing, state.options)
            :good
        else
            :partial
        end
    end

    dfs(WordGridState(grid, collected_words), children, evaluate)
end


end
