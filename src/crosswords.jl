module Crosswords

using ..PuzzleTools.Search: dfs
using ..PuzzleTools.Bitsets

export block_crossword, generate_fills

struct LetterSet <: AbstractBitmaskSet{Char}
    data::UInt32

    LetterSet(data::Integer) = new(data)
end

LetterSet(c::Char) = LetterSet(1 << (c - 'a'))

Bitsets.data(m::LetterSet) = m.data
Bitsets.alphabet(::Type{LetterSet}) = 'a':'z'

struct Crowssword
    # Size: num_entries.
    # Each entry is a vector of linear indices in the grid
    entries::Vector{Vector{Int}}

    # Size: num_cells.
    # For each cell, gives the list of (entry index, index within entry) for all entries that include that cell
    intersections::Vector{Vector{Tuple{Int, Int}}}

    function Crowssword(num_cells::Integer, entries::AbstractVector{<:AbstractVector{<:Integer}})
        intersections = [Vector{Tuple{Int, Int}}() for _ in 1:num_cells]
        for (entry_index, entry) in enumerate(entries)
            for (cell_index_in_entry, cell_id) in enumerate(entry)
                @assert 1 <= cell_id <= num_cells
                push!(intersections[cell_id], (entry_index, cell_index_in_entry))
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
    Crowssword(length(cells), entries)
end

num_entries(grid::Crowssword) = length(grid.entries)
num_cells(grid::Crowssword) = length(grid.intersections)

struct GridState
    cells::Vector{LetterSet}
    entry_options::Vector{Vector{Int}}
    corpus::Vector{Vector{LetterSet}}
end


function GridState(grid::Crowssword, unfiltered_corpus)
    entry_lengths = Set(length.(grid.entries))
    corpus = sort!(collect.(
        filter(w -> length(w) in entry_lengths && all(isascii, w),
               unfiltered_corpus)))

    options = Vector{Vector{Int}}()
    sizehint!(options, num_entries(grid))

    for entry in grid.entries
        push!(options, filter(1:length(corpus)) do word_index
            length(corpus[word_index]) == length(entry)
        end)
    end

    cells = [LetterSet('~') for _ in 1:num_cells(grid)]
    for entry in grid.entries
        for cell_id in entry
            cells[cell_id] = LetterSet('a':'z')
        end
    end

    corpus_masks = [LetterSet.(word) for word in corpus]
    @assert issorted(corpus_masks)

    GridState(cells, options, corpus_masks)
end

function propagate_entry!(state::GridState, grid::Crowssword, entry_id::Integer, cells_to_process; prevent_duplicate_entries=true)
    for (index_in_entry, cell_id) in enumerate(grid.entries[entry_id])
        new_mask = LetterSet(0)
        for word_id in state.entry_options[entry_id]
            new_mask |= state.corpus[word_id][index_in_entry]
        end
        new_mask &= state.cells[cell_id]
        if new_mask != state.cells[cell_id]
            state.cells[cell_id] = new_mask
            if isempty(state.cells[cell_id])
                return false
            end
            push!(cells_to_process, cell_id)
        end
    end

    return true
end

function propagate_cell!(state::GridState, grid::Crowssword, cell_id::Integer, cells_to_process; prevent_duplicate_entries::Bool=true)

    cell_mask = state.cells[cell_id]
    for (entry_id, index_in_entry) in grid.intersections[cell_id]
        prev_size = length(state.entry_options[entry_id])
        filter!(state.entry_options[entry_id]) do word_id
            !isempty(state.corpus[word_id][index_in_entry] & state.cells[cell_id])
        end
        new_size = length(state.entry_options[entry_id])
        if new_size == 0
            return false
        end
        if new_size != prev_size
            propagate_entry!(state, grid, entry_id, cells_to_process; prevent_duplicate_entries) || return false

            if prevent_duplicate_entries && new_size == 1
                word = @view(state.cells[grid.entries[entry_id]])
                word_id = searchsortedfirst(state.corpus, word)
                @assert state.corpus[word_id] == word
                for other_entry_id in 1:num_entries(grid)
                    if other_entry_id == entry_id
                        continue
                    end
                    @assert !isempty(state.entry_options[other_entry_id])
                    i = searchsortedfirst(state.entry_options[other_entry_id], word_id)
                    if i > length(state.entry_options[other_entry_id])
                        continue
                    end
                    if state.entry_options[other_entry_id][i] == word_id
                        deleteat!(state.entry_options[other_entry_id], i:i)
                        propagate_entry!(state, grid, other_entry_id, cells_to_process; prevent_duplicate_entries) || return false
                    end
                end
            end
        end
    end
    return true
end

function propagate_constraints!(state::GridState, grid::Crowssword, cell_id::Integer; prevent_duplicate_entries=true)
    cells_to_process = Set{Int}()
    push!(cells_to_process, cell_id)

    while !isempty(cells_to_process)
        cell_id = pop!(cells_to_process)
        propagate_cell!(state, grid, cell_id, cells_to_process; prevent_duplicate_entries) || return false
    end
    return true
end

function apply(state::GridState, grid::Crowssword, cell_id::Integer, letter::Char; prevent_duplicate_entries=true)

    cells = copy(state.cells)
    cells[cell_id] = LetterSet(letter)
    options = copy.(state.entry_options)
    state = GridState(cells, options, state.corpus)
    propagate_constraints!(state, grid, cell_id; prevent_duplicate_entries)
    state
end

function children(nodes, grid; prevent_duplicate_entries=true)
    state = last(nodes)
    num_options, most_constrained_cell = findmin(state.cells) do cell
        num_options = length(cell)
        num_options == 1 ? typemax(typeof(num_options)) : num_options
    end
    if num_options == 0
        return nothing
    end
    @assert num_options != typemax(Int)
    (apply(state, grid, most_constrained_cell, letter; prevent_duplicate_entries) for letter in state.cells[most_constrained_cell])
end

function evaluate(nodes, grid, validate)
    state = last(nodes)
    fully_constrained = true
    for (cell_id, cell) in enumerate(state.cells)
        if isempty(grid.intersections[cell_id])
            continue
        end
        if isempty(cell)
            return :bad
        elseif !exactly_one_element(cell)
            fully_constrained = false
        end
    end
    if any(i -> length(state.entry_options[i]) == 0, 1:num_entries(grid))
        return :bad
    end
    if !validate(state)
        return :bad
    end
    if fully_constrained
        return :good
    end
    return :partial
end

function generate_fills(grid::Crowssword,
                        state::GridState;
                            validate = state -> true,
                            prevent_duplicate_entries = true)
    # for entry_id in 1:num_entries(grid)
    #     propagate_entry!(state, grid, entry_id; prevent_duplicate_entries)
    # end

    for cell_id in 1:num_cells(grid)
        propagate_constraints!(state, grid, cell_id; prevent_duplicate_entries)
    end

    search = dfs(state, nodes -> children(nodes, grid; prevent_duplicate_entries),
                 nodes -> evaluate(nodes, grid, validate))
    Iterators.map(search) do nodes
        state = last(nodes)
        map(1:num_cells(grid)) do cell_id
            if !isempty(grid.intersections[cell_id])
                only(state.cells[cell_id])
            else
                '█'
            end
        end
    end
end

function generate_fills(grid::Crowssword, corpus;
        validate = state -> true,
        prevent_duplicate_entries = true)
    generate_fills(grid, GridState(grid, corpus); validate, prevent_duplicate_entries)
end

end
