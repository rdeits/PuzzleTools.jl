module Wiki

export WikiPage,
       links,
       content,
       title

using Requests, JSON, PuzzleTools.Caching

type MediaWiki
    url::String
end

wikipedia = MediaWiki("https://en.wikipedia.org/w/api.php")

function wiki_request(query_params, wiki::MediaWiki=wikipedia)
    query = Dict(
        "format" => "json",
        "action" => "query",
        query_params...
    )
    Requests.json(get(
        wiki.url,
        query=query
    ))
end

type WikiPage
    title::String
    wiki::MediaWiki
    links::Nullable{Vector{String}}
    content::Nullable{String}

    WikiPage(title, wiki=wikipedia) = new(title,
        wiki,
        Nullable{Vector{String}}(),
        Nullable{String}()
    )
end


"""
Based on https://www.mediawiki.org/wiki/API:Query#Continuing_queries
"""
function continued_query(page::WikiPage, query_params)
    continuation = Dict{String, String}()
    prop = query_params["prop"]
    results = []

    while true
        response = wiki_request(Dict(
            "titles" => page.title,
            continuation...,
            query_params...
        ), page.wiki)
        for (page_id, page_data) in response["query"]["pages"]
            append!(results, page_data[prop])
        end
        if "continue" in keys(response)
            continuation = response["continue"]
        else
            break
        end
    end
    results
end

function search(query, wiki::MediaWiki=wikipedia;
                results::Integer=10)
    result = wiki_request(Dict(
        "list" => "search",
        "srprop" => "",
        "srlimit" => results,
        "limit" => results,
        "srsearch" => query
    ), wiki)
    String[d["title"] for d in result["query"]["search"]]
end

function suggest(query, wiki::MediaWiki=wikipedia)
    result = wiki_request(Dict(
        "list" => "search",
        "srinfo" => "suggestion",
        "srprop" => "",
        "srsearch" => query,
    ), wiki)
    if "searchinfo" in keys(result["query"])
        result["query"]["searchinfo"]["suggestion"]
    else
        ""
    end
end

title(page::WikiPage) = page.title

@cached function links(page::WikiPage)
    raw_links = continued_query(page, Dict(
        "prop" => "links",
        "plnamespace" => 0,
        "pllimit" => "max",
    ))
    String[d["title"] for d in raw_links]
end

@cached function content(page::WikiPage)
    continued_query(page, Dict(
        "prop" => "revisions",
        "rvprop" => "content"
    ))[1]["*"]::String
end

end
