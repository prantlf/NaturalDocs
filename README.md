Extended Natural Docs
=====================

*Latest version*: 07-07-2013 (1.52 base) aka 1.52.2

This is a fork of Natural Docs adding more functionality, namely:

* Additional text styles: italic, strikethrough and monospaced text
* Improved JavaScript language support
* Input file paths maintained across operating systems

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


Input file paths on diffrent operating systems
----------------------------------------------

If you specify more than one input directory, input files will be stored in the project (in Menu.txt) with their absolute paths.  The original Natural Docs looks for file entries matching the actual input directory cotent and is able to racover when you build the documentation in a different directory then you saved the project in.  However, if you create the project on Windows and them build on UNIX or vice versa, the format of the paths will be very different, which makes the Natural Docs fail matching them.  All files in input directories will be considered "new" and all files from the project "missing", thus to be removed.  Removing all files will make all groups empty, thus to be removed too.  The new files will be added, but you'll lose all group structure.

Let's say that you compile a project on Windows specifying input directories `../doc` and `../src`. Menu.txt will contain the following file paths:

    File: Overview  (D:\Dev\csui\doc\overview.txt)
    
    Group: REST API  {
       File: URLs  (D:\Dev\csui\doc\urls.txt)
       File: API   (D:\Dev\csui\src\api.js)
       }  # Group: REST API
    
After compiling on UNIX, your group structure is lost and the file order may end up different too:

    File: Overview  (/home/prantlf/Sources/csui/doc/overview.txt)
    File: URLs  (/home/prantlf/Sources/csui/doc/urls.txt)
    File: API   (/home/prantlf/Sources/csui/src/api.js)

This extension makes file paths stored in Menu.txt compatible with the OS which NaturalDocs is currently running on, before thay are processed further.  Also, files in the project are compared with the actual ones using their relative paths to the input directories and if they match, the current file path is written to the project.  This prevents removing and re-adding the files to the project and preserves the group structure.

Now after compiling on UNIX, your group structure is preserved and just the file paths updated:

    File: Overview  (/home/prantlf/Sources/csui/doc/overview.txt)
    
    Group: REST API  {
       File: URLs  (/home/prantlf/Sources/csui/doc/urls.txt)
       File: API   (/home/prantlf/Sources/csui/src/api.js)
       }  # Group: REST API
