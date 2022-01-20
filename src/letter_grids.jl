module LetterGrids

using ..PuzzleTools.Search: dfs

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

function Base.Char(mask::LetterMask)
    if !exactly_one_bit_set(mask.data)
        return Char(0)
    end
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

    function WordGrid(entries::AbstractVector{<:AbstractVector{<:Integer}})
        if !isempty(entries)
            max_cell_index = maximum(Iterators.flatten(entries))
        else
            max_cell_index = 0
        end
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

struct CellState
    mask::LetterMask
    num_options::Int8

    CellState(mask::LetterMask) = new(mask, length(mask))
end

num_options(state::CellState) = state.num_options

struct GridState
    cells::Vector{CellState}
    entry_options::Vector{Vector{Int}}
end


function GridState(grid::WordGrid, corpus)
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

    state = GridState(cells, options)

    for entry_id in 1:num_entries(grid)
        propagate_entry!(state, grid, corpus, entry_id)
    end

    # cells = Vector{CellState}()
    # sizehint!(cells, num_cells(grid))
    # for cell_index in 1:num_cells(grid)
    #     if isempty(grid.intersections[cell_index])
    #         push!(cells, CellState(LetterMask(0)))
    #         continue
    #     end
    #     mask = LetterMask('a':'z')
    #     for (entry, index_in_entry) in grid.intersections[cell_index]
    #         entry_mask = LetterMask(0)
    #         for word_index in options[entry]
    #             entry_mask |= LetterMask(corpus[word_index][index_in_entry])
    #         end
    #         mask &= entry_mask
    #     end
    #     push!(cells, CellState(mask))
    # end

    GridState(cells, options)
end

function propagate_entry!(state::GridState, grid::WordGrid, corpus, entry_id::Integer)
    for (index_in_entry, cell_id) in enumerate(grid.entries[entry_id])
        new_mask = LetterMask(0)
        for word_id in state.entry_options[entry_id]
            new_mask |= LetterMask(corpus[word_id][index_in_entry])
        end
        new_mask &= state.cells[cell_id].mask
        if new_mask != state.cells[cell_id].mask
            state.cells[cell_id] = CellState(new_mask)
            propagate_cell!(state, grid, corpus, cell_id)
        end
    end
end

function propagate_cell!(state::GridState, grid::WordGrid, corpus, cell_id::Integer)
    cell_mask = state.cells[cell_id].mask
    for (entry_id, index_in_entry) in grid.intersections[cell_id]
        prev_size = length(state.entry_options[entry_id])
        filter!(state.entry_options[entry_id]) do word_id
            corpus[word_id][index_in_entry] in cell_mask
        end
        new_size = length(state.entry_options[entry_id])
        if length(state.entry_options[entry_id]) != prev_size
            # push!(changed_entry_ids, entry_id)
            propagate_entry!(state::GridState, grid::WordGrid, corpus, entry_id)
        end
    end
end

function apply(state::GridState, grid::WordGrid, corpus, cell_id::Integer, letter::Char)

    cells = copy(state.cells)
    cells[cell_id] = CellState(LetterMask(letter))
    options = copy.(state.entry_options)
    state = GridState(cells, options)
    propagate_cell!(state, grid, corpus, cell_id)
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
        num_options, most_constrained_cell = findmin(c -> c.num_options == 1 ? typemax(typeof(c.num_options)) : c.num_options, state.cells)
        if num_options == 0
            return nothing
        end
        @assert num_options != typemax(Int)
        (apply(state, grid, corpus, most_constrained_cell, letter) for letter in state.cells[most_constrained_cell].mask)
    end

    function evaluate(nodes)
        state = last(nodes)
        if all(c -> c.num_options == 1, state.cells)
            # for entry in grid.entries
            #     @assert [only(state.cells[i].mask) for i in entry] in corpus
            # end
            :good
        elseif any(c -> c.num_options == 0, state.cells)
            :bad
        else
            :partial
        end
    end

    dfs(GridState(grid, corpus), children, evaluate)
end

end
