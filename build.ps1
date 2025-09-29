param(
    [string] $in = "resume.md",
    [string] $out = "VicenteViera.pdf"
);

& pandoc.exe $in --template .\template.tex --lua-filter .\filter.lua -s -o $out;