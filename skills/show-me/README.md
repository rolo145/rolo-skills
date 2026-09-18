# show-me

Answer a question about code with a picture of it instead of a paragraph about it —
pseudocode, a call tree, a component tree, a file tree, an ASCII sequence figure, a diff,
or one focused HTML page.

The skill is not "add a diagram". It picks the one smallest view that makes the point and
lets it carry the answer, so the prose around it shrinks to a caption.

## Prerequisites

None. The text forms render in any client. In a terminal, Mermaid and HTML do not render
inside the reply, so the skill draws ASCII there and writes Mermaid only into an HTML page
it opens for you.

## Use it

Run `/show-me`, or ask to be shown rather than told — "draw it", "sketch the flow",
"what does the structure look like". It is never volunteered on its own.
