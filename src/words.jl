module Words

using ..PuzzleTools: Corpus

read_dictionary(file) = Corpus(replace.(strip.(lowercase.(filter(line -> !(startswith(line, '#')), open(readlines, file)))), Ref(r"[ -'_]" => "")))

UKACD() = read_dictionary(joinpath(dirname(@__FILE__), "..", "data", "UKACD.txt"))
sowpods() = read_dictionary(joinpath(dirname(@__FILE__), "..", "data", "sowpods.txt"))
twl06() = read_dictionary(joinpath(dirname(@__FILE__), "..", "data", "twl06.txt"))
unixwords() = read_dictionary("/usr/share/dict/words")

end
