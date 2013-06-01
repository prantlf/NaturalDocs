Extended Natural Docs
=====================

This is a fork of Natural Docs adding more functionality, namely:

* Additional text styles: italic, strikethrough and monospaced text
* The full JavaScript language support

Quoting the author from the [original project pages]
(https://sourceforge.net/projects/naturaldocs):
> [Natural Docs](http://www.naturaldocs.org) is an open-source documentation
> generator for multiple programming languages.  You document your code in a
> natural syntax that reads like plain English.  Natural Docs then scans your
> code and builds high-quality HTML documentation from it.

Formatting and Layout
---------------------

The [original Formatting and Layout](http://naturaldocs.org/documenting/reference.html#FormattingAndLayout) is fully supported. The following section describes the extensions.

### Italic, Strikethrough and Monotype

You can make a portion of text italic by surrounding it with plus signs.  You can make a portion of text struck-through by surrounding it with tildas instead.  If you put tildas instead of *every* space inside the text part too, they will be replaced with spaces.

> Some +italic text+ and some ~struck-through text~
> and yet ~more~struck-through~text~.

Some *italic text* and some ~struck-through text~ and yet ~more struck through text~.
