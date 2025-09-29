# Resume Generator
Vicente Javier Viera Guizar

## Overview
This project implements a pipeline to build and mantain a *Software Engineering* competitive CV with ease. This pipeline uses Markdown flavoured with YAML frontmatter parameters, alongside with Lua scripting to compile the source Markdown into LaTeX and then into a pdf file.

The porpouse of this project is to avoid mantaining a pure-LaTeX CV, using instead comprehensive Markdown.

The document's format and general layout is completely opinionated, so if you want to create your own design, you will need to modify the source files.

## Parameters
### Frontmatter
The frontmatter accepts custom parameters to add content directly into the document as well as modifying some layouts and format variables.

- __name__: Adds your name as the document's title.
- __headline__: Adds your proffesional title below the title.
- __location__: A string representing your current location.
- __contacts__: A list of means to contact you. Each item is represented as a pair of *label-url* fields.
  - __Label__: Text to be displayed.
  - __url__: Link to your mean of contact.
- __fontsize__: General font size for the document.
- __linespread__: Controls the line height in all the document.
- __section_font_size__: Section's heading font size.
- __margin_x__: General document's margin in x side (top, bottom, right, left).

### Build Script
- __in__: Markdown source file path.
- __out__: PDF output file name.
## Sintax
The document's header is handeled through YAML frontmatter variables. This makes the use of #, ##, ###... header selectors useless for vanilla Markdown to LaTeX conversion with pandoc. Because of this, the Markdown source is focused in the body of the document and its sections. The Markdown headers compile into section headings in the body. The following Markdown elements have been modified to achieve this section-focus sintax:

- __#__: Section's header with dividing line below.
- __##__: Section's subtitle. This can represent an entry in the section.
- __###__: Introduction to your entry element.
- __>__: Entry's date span. This needs to be used ritght after __##__ heading. It positions the text to the right side of the subtitle's line.
- __####__: Used to set a conclusion to the entry.

These are the only special compiled elements. The rest of Markdown sintax remains the same as vanilla. You can find examples of these here, in this repository's file: [resume.md](./resume.md).

## Dependencies
- [Pandoc](https://pandoc.org/)
- [pdflatex (Via MiKTeX or any other Tex distribution)](https://miktex.org/)
- [Lua](https://www.lua.org/)
- [PowerShell (optional)](https://learn.microsoft.com/en-us/powershell/)