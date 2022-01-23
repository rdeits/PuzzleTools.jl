module Sudokus

using ..PuzzleTools.Bitsets: Bitsets, AbstractBitmaskSet, exactly_one_element
using ..PuzzleTools.Search: dfs
using ..PuzzleTools: PuzzleTools, generate_fills

export Sudoku, standard_sudoku, SudokuState, generate_fills

struct Sudoku
    # size: num_entries
    entries::Vector{Vector{Int}}

    # size: num_cells
    intersections::Vector{Vector{Int}}
end

function standard_sudoku()
    rows = 9
    cols = 9

    cell_ids = LinearIndices((rows, cols))
    entries = Vector{Vector{Int}}()
    for row in 1:rows
        push!(entries, @view cell_ids[row, :])
    end
    for col in 1:cols
        push!(entries, @view cell_ids[:, col])
    end
    for row in 1:3:rows
        for col in 1:3:cols
            push!(entries, vec(@view cell_ids[row:(row + 2), col:(col + 2)]))
        end
    end

    intersections = [Vector{Int}() for _ in 1:(rows * cols)]
    for (entry_id, entry) in enumerate(entries)
        for cell_id in entry
            push!(intersections[cell_id], entry_id)
        end
    end
    Sudoku(entries, intersections)
end

num_cells(s::Sudoku) = length(s.intersections)
num_entries(s::Sudoku) = length(s.entries)

struct DigitSet <: AbstractBitmaskSet{Int8}
    data::UInt16

    DigitSet() = new(0)
    DigitSet(digit::Integer) = new(1 << (digit - 1))
    DigitSet(data::UInt16) = new(data)
end

Bitsets.data(m::DigitSet) = m.data
Bitsets.alphabet(::Type{DigitSet}) = 1:9

struct SudokuState
    cells::Vector{DigitSet}
end

Base.copy(state::SudokuState) = SudokuState(copy(state.cells))

function SudokuState(puzzle::Sudoku)
    SudokuState([DigitSet(0:9) for _ in puzzle.intersections])
end

function propagate_cell!(state::SudokuState, puzzle::Sudoku, cell_id::Integer, cells_to_process)
    cell_state = state.cells[cell_id]
    if exactly_one_element(cell_state)
        for entry_id in puzzle.intersections[cell_id]
            for other_cell_id in puzzle.entries[entry_id]
                if other_cell_id == cell_id
                    continue
                end
                new_state = setdiff(state.cells[other_cell_id], cell_state)
                if new_state != state.cells[other_cell_id]
                    state.cells[other_cell_id] = new_state
                    push!(cells_to_process, other_cell_id)
                end
                if isempty(new_state)
                    return false
                end
            end
        end
    end
    return true
end

function propagate_constraints!(state::SudokuState, puzzle::Sudoku, cell_id::Integer)
    cells_to_process = Set{Int}()
    push!(cells_to_process, cell_id)

    while !isempty(cells_to_process)
        cell_id = pop!(cells_to_process)
        propagate_cell!(state, puzzle, cell_id, cells_to_process) || return false
    end
    return true
end

function apply!(state::SudokuState, puzzle::Sudoku, cell_id::Integer, value::Integer)
    state = copy(state)
    state.cells[cell_id] = DigitSet(value)
    propagate_constraints!(state, puzzle, cell_id)
    state
end

function children(nodes, grid)
    state = last(nodes)
    num_options, most_constrained_cell = findmin(state.cells) do cell
        num_options = length(cell)
        num_options == 1 ? typemax(typeof(num_options)) : num_options
    end
    if num_options == 0
        return nothing
    end
    @assert num_options != typemax(Int)
    (apply!(copy(state), grid, most_constrained_cell, assignment) for assignment in state.cells[most_constrained_cell])
end

function evaluate(nodes, grid)
    state = last(nodes)
    fully_constrained = true
    for (cell_id, cell) in enumerate(state.cells)
        if isempty(cell)
            return :bad
        elseif !exactly_one_element(cell)
            fully_constrained = false
        end
    end
    if fully_constrained
        return :good
    end
    return :partial
end

function PuzzleTools.generate_fills(puzzle::Sudoku, state::SudokuState)
    for cell_id in 1:num_cells(puzzle)
        propagate_constraints!(state, puzzle, cell_id)
    end

    search = dfs(state, nodes -> children(nodes, puzzle),
                 nodes -> evaluate(nodes, puzzle))
    Iterators.map(search) do nodes
        state = last(nodes)
        reshape(only.(state.cells), round(Int, sqrt(length(state.cells))), :)
    end
end

end
