module Sudokus

struct Sudoku
    # size: num_entries
    entries::Vector{Vector{Int}}

    # size: num_cells
    intersections::Vector{Int}
end

num_cells(s::Sudoku) = length(s.intersections)
num_entries(s::Sudoku) = length(s.entries)

struct SudokuState




end
