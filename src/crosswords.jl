module Crosswords

using ..PuzzleTools.Search: dfs

export block_crossword, generate_fills

struct LetterMask
    data::UInt

end

LetterMask(char::Char) = LetterMask(1 << (char - 'a'))

function LetterMask(chars::AbstractVector{Char})
    reduce((x, y) -> x | LetterMask(y), chars, init=LetterMask(0))
end

# Clever math trick via https://stackoverflow.com/a/51094793/641846
exactly_one_bit_set(x::Integer) = !iszero(x) && iszero(x & (x - 1))
exactly_one_bit_set(m::LetterMask) = exactly_one_bit_set(m.data)

function Base.only(mask::LetterMask)
    exactly_one_bit_set(mask.data) || throw(ArgumentError("Mask must contain exactly one element"))
    sizeof(mask.data) << 3 - leading_zeros(mask.data) - 1 + 'a'
end

function Base.length(mask::LetterMask)
    data = mask.data
    result = 0
    while true
        if iszero(data)
            return result
        end
        result += data & 1
        data >>= 1
    end
end

Base.:&(m1::LetterMask, m2::LetterMask) = LetterMask(m1.data & m2.data)
Base.:|(m1::LetterMask, m2::LetterMask) = LetterMask(m1.data | m2.data)

function Base.iterate(mask::LetterMask, state = (mask.data, 1))
    shifted_data, index = state
    while !iszero(shifted_data)
        found = !iszero(shifted_data & 1)
        shifted_data >>= 1
        index += 1
        if found
            return 'a' + index - 2, (shifted_data, index)
        end
    end
end
Base.eltype(::Type{LetterMask}) = Char
Base.IteratorSize(::Type{LetterMask}) = Base.SizeUnknown()

Base.isempty(mask::LetterMask) = iszero(mask.data)

Base.in(char::Char, mask::LetterMask) = !isempty(LetterMask(char) & mask)

struct WordGrid
    # Size: num_entries.
    # Each entry is a vector of linear indices in the grid
    entries::Vector{Vector{Int}}

    # Size: num_cells.
    # For each cell, gives the list of (entry index, index within entry) for all entries that include that cell
    intersections::Vector{Vector{Tuple{Int, Int}}}

    function WordGrid(num_cells::Integer, entries::AbstractVector{<:AbstractVector{<:Integer}})
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
    WordGrid(length(cells), entries)
end

num_entries(grid::WordGrid) = length(grid.entries)
num_cells(grid::WordGrid) = length(grid.intersections)

struct CellState
    mask::LetterMask
    num_options::Int8

    CellState(mask::LetterMask) = new(mask, length(mask))
end

CellState(char::Char) = CellState(LetterMask(char))
CellState(chars::AbstractVector{Char}) = CellState(LetterMask(chars))

num_options(state::CellState) = state.num_options
Base.only(state::CellState) = only(state.mask)

struct GridState
    cells::Vector{CellState}
    entry_options::Vector{Vector{Int}}
    corpus::Vector{Vector{Char}}
end


function GridState(grid::WordGrid, unfiltered_corpus)
    corpus = collect.(unfiltered_corpus)
    entry_lengths = Set(length.(grid.entries))
    filter!(corpus) do word
        length(word) in entry_lengths
    end
    sort!(corpus)

    options = Vector{Vector{Int}}()
    sizehint!(options, num_entries(grid))

    for entry in grid.entries
        push!(options, filter(1:length(corpus)) do word_index
            length(corpus[word_index]) == length(entry)
        end)
    end

    cells = [CellState(LetterMask('~')) for _ in 1:num_cells(grid)]
    for entry in grid.entries
        for cell_id in entry
            cells[cell_id] = CellState(LetterMask('a':'z'))
        end
    end

    GridState(cells, options, corpus)
end

function propagate_entry!(state::GridState, grid::WordGrid, entry_id::Integer; prevent_duplicate_entries=true)
    for (index_in_entry, cell_id) in enumerate(grid.entries[entry_id])
        new_mask = LetterMask(0)
        for word_id in state.entry_options[entry_id]
            new_mask |= LetterMask(state.corpus[word_id][index_in_entry])
        end
        new_mask &= state.cells[cell_id].mask
        if new_mask != state.cells[cell_id].mask
            state.cells[cell_id] = CellState(new_mask)
            if num_options(state.cells[cell_id]) == 0
                return false
            end
            propagate_cell!(state, grid, cell_id; prevent_duplicate_entries) || return false
        end
    end
    return true
end

function propagate_cell!(state::GridState, grid::WordGrid, cell_id::Integer; prevent_duplicate_entries::Bool=true)

    cell_mask = state.cells[cell_id].mask
    for (entry_id, index_in_entry) in grid.intersections[cell_id]
        prev_size = length(state.entry_options[entry_id])
        filter!(state.entry_options[entry_id]) do word_id
            state.corpus[word_id][index_in_entry] in cell_mask
        end
        new_size = length(state.entry_options[entry_id])
        if new_size == 0
            return false
        end
        if length(state.entry_options[entry_id]) != prev_size
            # push!(changed_entry_ids, entry_id)
            propagate_entry!(state::GridState, grid::WordGrid, entry_id; prevent_duplicate_entries) || return false
        end
    end

    if prevent_duplicate_entries && num_options(state.cells[cell_id]) == 1
        for (entry_id, _) in grid.intersections[cell_id]
            entry_complete = all(grid.entries[entry_id]) do cell_id
                num_options(state.cells[cell_id]) == 1
            end
            if entry_complete
                word = only.(@view(state.cells[grid.entries[entry_id]]))
                word_id = searchsortedfirst(state.corpus, word)
                if state.corpus[word_id] != word
                    return false
                end
                for other_entry_id in 1:num_entries(grid)
                    if other_entry_id == entry_id
                        continue
                    end
                    if isempty(state.entry_options[other_entry_id])
                        continue
                    end
                    i = searchsortedfirst(state.entry_options[other_entry_id], word_id)
                    if i > length(state.entry_options[other_entry_id])
                        continue
                    end
                    if state.entry_options[other_entry_id][i] == word_id
                        deleteat!(state.entry_options[other_entry_id], i:i)
                        propagate_entry!(state, grid, other_entry_id; prevent_duplicate_entries) || return false
                    end
                end
            end
        end
    end
    return true
end

function apply(state::GridState, grid::WordGrid, cell_id::Integer, letter::Char; prevent_duplicate_entries=true)

    cells = copy(state.cells)
    cells[cell_id] = CellState(LetterMask(letter))
    options = copy.(state.entry_options)
    state = GridState(cells, options, state.corpus)
    propagate_cell!(state, grid, cell_id; prevent_duplicate_entries)
    state
end

function children(nodes, grid; prevent_duplicate_entries=true)
    state = last(nodes)
    num_options, most_constrained_cell = findmin(c -> c.num_options == 1 ? typemax(typeof(c.num_options)) : c.num_options, state.cells)
    if num_options == 0
        return nothing
    end
    @assert num_options != typemax(Int)
    (apply(state, grid, most_constrained_cell, letter; prevent_duplicate_entries) for letter in state.cells[most_constrained_cell].mask)
end

function evaluate(nodes, grid, validate)
    state = last(nodes)
    fully_constrained = true
    for (cell_id, cell) in enumerate(state.cells)
        if isempty(grid.intersections[cell_id])
            continue
        end
        if cell.num_options == 0
            return :bad
        end
        if cell.num_options > 1
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

function generate_fills(grid::WordGrid,
                        state::GridState;
                            validate = state -> true,
                            prevent_duplicate_entries = true)
    for entry_id in 1:num_entries(grid)
        propagate_entry!(state, grid, entry_id; prevent_duplicate_entries)
    end

    for cell_id in 1:num_cells(grid)
        propagate_cell!(state, grid, cell_id; prevent_duplicate_entries)
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

function generate_fills(grid::WordGrid, corpus;
        validate = state -> true,
        prevent_duplicate_entries = true)
    generate_fills(grid, GridState(grid, corpus); validate, prevent_duplicate_entries)
end

end
