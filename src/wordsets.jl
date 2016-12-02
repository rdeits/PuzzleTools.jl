module Wordsets

typealias Wordset Set{String}

cleanup_phrase(phrase) = replace(lowercase(phrase), r"[^a-z ]", "")

module Wikipedia

import Wordsets: Wordset, cleanup_phrase
using Wiki

cleanup_wiki_title(title) = replace(title, r"\([^\)]*\)", "")

function wordset(title)
    titles = links(WikiPage(title))
    Wordset(cleanup_phrase.(cleanup_wiki_title.(titles)))
end

end

end
