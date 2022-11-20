using Tally
using Documenter

DocMeta.setdocmeta!(Tally, :DocTestSetup, :(using Tally); recursive=true)

makedocs(;
    modules=[Tally],
    authors="Tommy Hofmann <thofma@gmail.com> and contributors",
    repo="https://github.com/Tommy Hofmann/Tally.jl/blob/{commit}{path}#{line}",
    sitename="Tally.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://Tommy Hofmann.github.io/Tally.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/Tommy Hofmann/Tally.jl",
    devbranch="main",
)
