module Wordsets

using DelimitedFiles: readdlm

cleanup_phrase(phrase) = replace(lowercase(phrase), r"[^a-z ]" => "")

read_dictionary(file) = Set{String}(cleanup_phrase.(vec(readdlm(file, '\t', String))))

UKACD() = read_dictionary(joinpath(dirname(@__FILE__), "..", "data", "UKACD.txt"))
sowpods() = read_dictionary(joinpath(dirname(@__FILE__), "..", "data", "sowpods.txt"))
unixwords() = Set{String}(cleanup_phrase.(vec(readdlm("/usr/share/dict/words", '\t', String, use_mmap=false))))

end
