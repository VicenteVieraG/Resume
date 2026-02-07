param(
    [string] $in = "resume.md",
    [string] $out = "VicenteViera.pdf"
);

$templatePath = Join-Path -Path "." -ChildPath "template.tex"
$filterPath = Join-Path -Path "." -ChildPath "filter.lua"

& pandoc $in --template $templatePath --lua-filter $filterPath -s -o $out