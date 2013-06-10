Extended Natural Docs
=====================

This is a fork of Natural Docs adding more functionality, namely:

* Additional text styles: italic, strikethrough and monospaced text
* Improved JavaScript language support

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

    Some +italic text+ and some ~struck-through text~
    and yet ~more~struck-through~text~.

Some *italic text* and some ~~struck-through text~~ and yet ~~more struck through text~~.


JavaScript Language Support
---------------------------

The original simple support has been enhanced to normalize variable and function prototypes so that they are formatted consistently.  The full support has been added.

### Simple Support

There is a new pakage `JavaScriptSimple` extending the simple parser.  For example, the following variable declarations will be documented by the prototype `var variable`:

```javascript
var variable = 1;
Parent.variable = 1.
Parent.prototype.variable = 1.
{ variable: 1 }
```

Similarly, the following function declarations will be documented by the prototype `function func()`:

```javascript
function func() {}
var func = function () {};
Parent.func = function () {};
Parent.prototype.func = function () {};
{ func: function () {} }
```

### Full Support

There is a new pakage `JavaScriptFull` extending the advanced parser.  You can turn it on by modifying this section in `Languages.txt`:

    Language: JavaScript

       Extension: js
       Line Comment: //
       Block Comment: /* */
       Enum Values: Under type
       Function Prototype Ender: {
       Variable Prototype Enders: ; = , }
       Perl Package: NaturalDocs::Languages::JavaScriptSimple

to make it looking like this:

    Language: JavaScript

       Extension: js
       Full Language Support: NaturalDocs::Languages::JavaScriptFull

Variables and functions will be recognized automatically. There is no support for function objects, prototypes, methods and properties yet. The full support works well if your code consists in variables and functions only. If you use function objects and/or prototypes you should leave the simple support enabled, which is done by default.
