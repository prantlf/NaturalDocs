###############################################################################
#
#   Package: NaturalDocs::Parser
#
###############################################################################
#
#   A package that parses the input file either for symbols or to send to <NaturalDocs::Builder>.
#
#   Usage and Dependencies:
#
#       - Prior to use, <NaturalDocs::Settings>, <NaturalDocs::Languages>, <NaturalDocs::Project>, and
#         <NaturalDocs::SymbolTable> must be initialized.  <NaturalDocs::SymbolTable> does not have to be fully resolved.
#
#       - Aside from that, the package is ready to use right away.  It does not have its own initialization function.
#
###############################################################################

# This file is part of Natural Docs, which is Copyright © 2003 Greg Valure
# Natural Docs is licensed under the GPL


use NaturalDocs::Parser::ParsedTopic;

use strict;
use integer;

package NaturalDocs::Parser;


###############################################################################
# Group: Variables


# Return values of TagType().  Not documented here.
use constant POSSIBLE_OPENING_TAG => 1;
use constant POSSIBLE_CLOSING_TAG => 2;
use constant NOT_A_TAG => 3;


#   Hash: synonyms
#
#   A hash of the text synonyms for the tokens.  For example, "procedure", "routine", and "function" all map to
#   <TOPIC_FUNCTION>.  The keys are the synonyms in all lowercase, and the values are one of the <Topic Types>.
#
my %synonyms = (

                            'class'         => ::TOPIC_CLASS(),
                            'structure'   => ::TOPIC_CLASS(),
                            'struct'        => ::TOPIC_CLASS(),
                            'package'    => ::TOPIC_CLASS(),

                            'classes'       => ::TOPIC_CLASS_LIST(),
                            'structures'   => ::TOPIC_CLASS_LIST(),
                            'structs'        => ::TOPIC_CLASS_LIST(),
                            'packages'   => ::TOPIC_CLASS_LIST(),

                            'section'      => ::TOPIC_SECTION(),
                            'title'           => ::TOPIC_SECTION(),

                            'file'            => ::TOPIC_FILE(),
                            'program'    => ::TOPIC_FILE(),
                            'script'         => ::TOPIC_FILE(),
                            'module'      => ::TOPIC_FILE(),
                            'document'  => ::TOPIC_FILE(),
                            'doc'           => ::TOPIC_FILE(),
                            'header'      => ::TOPIC_FILE(),

                            'files'            => ::TOPIC_FILE_LIST(),
                            'programs'    => ::TOPIC_FILE_LIST(),
                            'scripts'         => ::TOPIC_FILE_LIST(),
                            'modules'      => ::TOPIC_FILE_LIST(),
                            'documents'  => ::TOPIC_FILE_LIST(),
                            'docs'           => ::TOPIC_FILE_LIST(),
                            'headers'      => ::TOPIC_FILE_LIST(),

                            'group'        => ::TOPIC_GROUP(),

                            'function'     => ::TOPIC_FUNCTION(),
                            'func'          => ::TOPIC_FUNCTION(),
                            'procedure'  => ::TOPIC_FUNCTION(),
                            'proc'          => ::TOPIC_FUNCTION(),
                            'routine'      => ::TOPIC_FUNCTION(),
                            'subroutine' => ::TOPIC_FUNCTION(),
                            'sub'           => ::TOPIC_FUNCTION(),
                            'callback'     => ::TOPIC_FUNCTION(),

                            'functions'     => ::TOPIC_FUNCTION_LIST(),
                            'funcs'          => ::TOPIC_FUNCTION_LIST(),
                            'procedures'  => ::TOPIC_FUNCTION_LIST(),
                            'procs'          => ::TOPIC_FUNCTION_LIST(),
                            'routines'      => ::TOPIC_FUNCTION_LIST(),
                            'subroutines' => ::TOPIC_FUNCTION_LIST(),
                            'subs'           => ::TOPIC_FUNCTION_LIST(),
                            'callbacks'     => ::TOPIC_FUNCTION_LIST(),

                            'variable'    => ::TOPIC_VARIABLE(),
                            'var'           => ::TOPIC_VARIABLE(),
                            'integer'     => ::TOPIC_VARIABLE(),
                            'int'           => ::TOPIC_VARIABLE(),
                            'float'        => ::TOPIC_VARIABLE(),
                            'long'        => ::TOPIC_VARIABLE(),
                            'double'     => ::TOPIC_VARIABLE(),
                            'scalar'      => ::TOPIC_VARIABLE(),
                            'array'       => ::TOPIC_VARIABLE(),
                            'arrayref'   => ::TOPIC_VARIABLE(),
                            'hash'        => ::TOPIC_VARIABLE(),
                            'hashref'    => ::TOPIC_VARIABLE(),
                            'bool'         => ::TOPIC_VARIABLE(),
                            'boolean'    => ::TOPIC_VARIABLE(),
                            'flag'          => ::TOPIC_VARIABLE(),
                            'bit'            => ::TOPIC_VARIABLE(),
                            'bitfield'      => ::TOPIC_VARIABLE(),
                            'field'         => ::TOPIC_VARIABLE(),
                            'pointer'     => ::TOPIC_VARIABLE(),
                            'ptr'           => ::TOPIC_VARIABLE(),
                            'reference' => ::TOPIC_VARIABLE(),
                            'ref'           => ::TOPIC_VARIABLE(),
                            'object'      => ::TOPIC_VARIABLE(),
                            'obj'           => ::TOPIC_VARIABLE(),
                            'character'  => ::TOPIC_VARIABLE(),
                            'char'         => ::TOPIC_VARIABLE(),
                            'string'       => ::TOPIC_VARIABLE(),
                            'str'           => ::TOPIC_VARIABLE(),

                            'variables'   => ::TOPIC_VARIABLE_LIST(),
                            'vars'          => ::TOPIC_VARIABLE_LIST(),
                            'integers'    => ::TOPIC_VARIABLE_LIST(),
                            'ints'          => ::TOPIC_VARIABLE_LIST(),
                            'floats'       => ::TOPIC_VARIABLE_LIST(),
                            'longs'       => ::TOPIC_VARIABLE_LIST(),
                            'doubles'    => ::TOPIC_VARIABLE_LIST(),
                            'scalars'     => ::TOPIC_VARIABLE_LIST(),
                            'arrays'      => ::TOPIC_VARIABLE_LIST(),
                            'arrayrefs'  => ::TOPIC_VARIABLE_LIST(),
                            'hashes'      => ::TOPIC_VARIABLE_LIST(),
                            'hashrefs'   => ::TOPIC_VARIABLE_LIST(),
                            'bools'        => ::TOPIC_VARIABLE_LIST(),
                            'booleans'   => ::TOPIC_VARIABLE_LIST(),
                            'flags'         => ::TOPIC_VARIABLE_LIST(),
                            'bits'           => ::TOPIC_VARIABLE_LIST(),
                            'bitfields'     => ::TOPIC_VARIABLE_LIST(),
                            'fields'        => ::TOPIC_VARIABLE_LIST(),
                            'pointers'    => ::TOPIC_VARIABLE_LIST(),
                            'ptrs'          => ::TOPIC_VARIABLE_LIST(),
                            'references'=> ::TOPIC_VARIABLE_LIST(),
                            'refs'          => ::TOPIC_VARIABLE_LIST(),
                            'objects'     => ::TOPIC_VARIABLE_LIST(),
                            'objs'          => ::TOPIC_VARIABLE_LIST(),
                            'characters' => ::TOPIC_VARIABLE_LIST(),
                            'chars'        => ::TOPIC_VARIABLE_LIST(),
                            'strings'      => ::TOPIC_VARIABLE_LIST(),
                            'strs'          => ::TOPIC_VARIABLE_LIST(),

                            'topic'        => ::TOPIC_GENERIC(),
                            'about'       => ::TOPIC_GENERIC(),
                            'note'         => ::TOPIC_GENERIC(),

                            'item'         => ::TOPIC_GENERIC(),
                            'option'      => ::TOPIC_GENERIC(),
                            'symbol'     => ::TOPIC_GENERIC(),
                            'sym'         => ::TOPIC_GENERIC(),
                            'type'         => ::TOPIC_GENERIC(),
                            'typedef'    => ::TOPIC_GENERIC(),
                            'constant'   => ::TOPIC_GENERIC(),
                            'const'       => ::TOPIC_GENERIC(),
                            'definition'   => ::TOPIC_GENERIC(),
                            'define'       => ::TOPIC_GENERIC(),
                            'def'           => ::TOPIC_GENERIC(),
                            'macro'      => ::TOPIC_GENERIC(),
                            'format'      => ::TOPIC_GENERIC(),
                            'style'        => ::TOPIC_GENERIC(),

                            'list'                => ::TOPIC_GENERIC_LIST(),
                            'enumeration'  => ::TOPIC_GENERIC_LIST(),
                            'enum'            => ::TOPIC_GENERIC_LIST(),

                            'items'        => ::TOPIC_GENERIC_LIST(),
                            'options'      => ::TOPIC_GENERIC_LIST(),
                            'symbols'     => ::TOPIC_GENERIC_LIST(),
                            'syms'         => ::TOPIC_GENERIC_LIST(),
                            'types'         => ::TOPIC_GENERIC_LIST(),
                            'typedefs'    => ::TOPIC_GENERIC_LIST(),
                            'constants'   => ::TOPIC_GENERIC_LIST(),
                            'consts'       => ::TOPIC_GENERIC_LIST(),
                            'definitions'   => ::TOPIC_GENERIC_LIST(),
                            'defines'       => ::TOPIC_GENERIC_LIST(),
                            'defs'           => ::TOPIC_GENERIC_LIST(),
                            'macros'      => ::TOPIC_GENERIC_LIST(),
                            'formats'      => ::TOPIC_GENERIC_LIST(),
                            'styles'        => ::TOPIC_GENERIC_LIST()

                            );

#
#   string: file
#
#   The file currently being parsed.
#
my $file;

#
#   object: language
#
#   The language of the file currently being parsed.  Is a <NaturalDocs::Languages::Language> object.
#
my $language;

#
#   enum: mode
#
#   What mode the parser is currently in.
#
#      PARSE_FOR_INFORMATION  - The parser was called with <ParseForInformation()>.  It will go through the file and extract
#                                                  symbol definitions and references for <NaturalDocs::SymbolTable> and information about the
#                                                  file for <NaturalDocs::Project>.
#
#      PARSE_FOR_BUILD  - The parser was called with <ParseForBuild()>.  It will go through the file and generate
#                                      <NaturalDocs::Parser::ParsedTopic> objects to be used in generating output.
#
my $mode;

    use constant PARSE_FOR_INFORMATION => 1;
    use constant PARSE_FOR_BUILD => 2;

#
#   var: scope
#
#   The scope at the current point in the file.  This is a package variable because it needs to be preserved between function
#   calls.
#
my $scope;

#
#   bool: hasContent
#
#   Whether the current file has Natural Docs content or not.
#
my $hasContent;

#
#   var: defaultMenuTitle
#
#   The default menu title of the current file.  Will be the file name if a suitable one cannot be found.
#
my $defaultMenuTitle;

#
#   enum: menuTitleState
#
#   The state of the default menu title, since it can be determined different ways.
#
#   States:
#
#       INDEFINITE            - The title has a value, but will be changed by any content.
#       DEFINITE               - The title has been determined conclusively.
#       DEFINITE_IF_ONLY - The title will keep its current value only if is no more content in the file.
#
my $defaultMenuTitleState;

    use constant INDEFINITE => 0;
    use constant DEFINITE => 1;
    use constant DEFINITE_IF_ONLY => 2;

#
#   Array: parsedFile
#
#   An array of <NaturalDocs::Parser::ParsedTopic> objects.
#
my @parsedFile;


###############################################################################
# Group: Functions

#
#   Function: ParseForInformation
#
#   Parses the input file for information.  Will update the information about the file in <NaturalDocs::SymbolTable> and
#   <NaturalDocs::Project>.
#
#   Parameters:
#
#       file - The name of the file to parse.
#
sub ParseForInformation #(file)
    {
    $file = shift;
    $mode = PARSE_FOR_INFORMATION;

    # Have the symbol table watch this parse so we detect any changes.
    NaturalDocs::SymbolTable::WatchFileForChanges($file);

    Parse();

    # Handle any changes to the file.
    NaturalDocs::SymbolTable::AnalyzeChanges();

    # Update project on the file's characteristics.
    NaturalDocs::Project::SetHasContent($file, $hasContent);
    if ($hasContent)
        {  NaturalDocs::Project::SetDefaultMenuTitle($file, $defaultMenuTitle);  };
    };


#
#   Function: ParseForBuild
#
#   Parses the input file for building, returning it as a <NaturalDocs::Parser::ParsedTopic> arrayref.
#
#   Note that all new and changed files should be parsed for symbols via <ParseForInformation()> before calling this function on
#   *any* file.  The reason is that <NaturalDocs::SymbolTable> needs to know about all the symbol definitions and references to
#   resolve them properly.
#
#   Parameters:
#
#       file - The name of the file to parse for building.
#
#   Returns:
#
#       An arrayref of the source file as <NaturalDocs::Parser::ParsedTopic> objects.
#
sub ParseForBuild #(filename)
    {
    $file = shift;
    $mode = PARSE_FOR_BUILD;

    Parse();

    # If the title ended up being the file name, add a leading section for it.
    if ($defaultMenuTitle eq $file && $parsedFile[0]->Name() ne $file)
        {
        unshift @parsedFile, NaturalDocs::Parser::ParsedTopic::New(::TOPIC_SECTION(), $file, undef, undef, undef, undef);
        };

    return \@parsedFile;
    };


###############################################################################
# Group: Parser Stages
#
# Do not call these functions directly, as they are stages in the parsing process.  Rather, call <ParseForInformation()> or
# <ParseForBuild()>.

#
#   Function: Parse
#
#   Begins the parsing process.  Do not call directly; rather, call <ParseForInformation()> or <ParseForBuild()>.  <file> and
#   <mode> should be set prior to calling; it will set everything else itself.
#
sub Parse
    {
    $language = NaturalDocs::Languages::LanguageOf($file);
    $scope = undef;
    $hasContent = undef;
    @parsedFile = ( );

    # The menu title is the file name by default, but that will be changed by any content.
    $defaultMenuTitle = $file;
    $defaultMenuTitleState = INDEFINITE;


    # Read the entire file into memory.

    my $fileHandle;
    my $fileContent;

    my $fileName = NaturalDocs::File::JoinPath( NaturalDocs::Settings::InputDirectory(), $file );

    open($fileHandle, '<' . $fileName)
        or die "Couldn't open input file " . $fileName . "\n";
    read($fileHandle, $fileContent, -s $fileHandle);
    close($fileHandle);


    # Parse the content for comments.

    if ($language->FileIsComment())
        {  CleanComment($fileContent, undef, undef);  }
    else
        {  ExtractComments($fileContent);  };
    };

#
#   Function: ExtractComments
#
#   Extracts comments from the passed content and sends them individually to <CleanComment()>.
#
#   Parameters:
#
#       content - The file content.
#
sub ExtractComments #(content)
    {
    my $content = shift;
    my $length = length($content);


    # First do multiline comments

    if (defined $language->StartComment())
        {
        my $startIndex;
        my $endIndex = 0;
        my $prototypeStart;
        my $functionPrototype;
        my $variablePrototype;

        do
            {
            # Find the next multi-line comment.
            $startIndex = index($content, $language->StartComment(), $startIndex);

            if ($startIndex == -1)
                {
                # If there aren't any more, search the remainder of the content for single line comments.
                ExtractLineComments(substr($content, $endIndex));

                # Guess what?  "do" isn't a real loop structure in Perl!  So I have to use goto instead of last!  Of course this was
                # plainly obvious and would never cause any sort of obscure errors.  God I love Perl!
                goto OutOfLoop;
                }
            else
                {
                # Search everything between the last find and this one for single line comments.
                ExtractLineComments(substr($content, $endIndex, $startIndex - $endIndex));

                # Find the start and end of the comment, not including the symbols.
                $startIndex += length($language->StartComment());

                $endIndex = index($content, $language->EndComment(), $startIndex);
                if ($endIndex == -1)
                    {  $endIndex = $length - $startIndex;  };

                # Find the prototype if necessary.
                if (defined $language->FunctionEnders() || defined $language->VariableEnders())
                    {
                    # Put the start of the potential prototype past all completely blank lines.
                    $prototypeStart = $endIndex + length($language->EndComment());

                    while ($prototypeStart < length($content))
                        {
                        my $nextLineBreak = index($content, "\n", $prototypeStart);
                        if ($nextLineBreak != -1)
                            {  last;  };

                        if (substr($content, $prototypeStart, $nextLineBreak - $prototypeStart) =~ /[^ \t\n\r]/)
                            {  last;  }
                        else
                            {  $prototypeStart = $nextLineBreak + length("\n");  };
                        };

                    if ($prototypeStart < length($content))
                        {
                        # The end is either the end of the file or one of the ender symbols, whichever comes first.

                        if (defined $language->FunctionEnders())
                            {
                            my $functionEnd = $language->EndOfFunction(\$content, $prototypeStart);
                            if ($functionEnd == -1)
                                {  $functionEnd = $length  };

                            $functionPrototype = substr($content, $prototypeStart, $functionEnd - $prototypeStart);
                            };

                        if (defined $language->VariableEnders())
                            {
                            my $variableEnd = $language->EndOfFunction(\$content, $prototypeStart);
                            if ($variableEnd == -1)
                                {  $variableEnd = $length  };

                            $variablePrototype = substr($content, $prototypeStart, $variableEnd - $prototypeStart);
                            };
                        };
                    };

                CleanComment(substr($content, $startIndex, $endIndex - $startIndex), $functionPrototype, $variablePrototype);

                $endIndex += length($language->EndComment());
                $functionPrototype = undef;
                $variablePrototype = undef;
                };
            }
        while ($endIndex < $length);

        # See above comments on why Perl is the most awesome language ever!
        OutOfLoop:
        }

    # If the code format doesn't have multiline comments...
    else
        {
        ExtractLineComments($content);
        };
    };


#
#   Function: ExtractLineComments
#
#   Parses the passed content for single line comments.  Merges adjacent ones and sends them to <CleanComment()>.
#
#   Parameters:
#
#       content - The content to be searched for single line comments.
#
sub ExtractLineComments #(content)
    {
    my $content = shift;

    if (defined $language->LineComment())
        {

        # Parse line comments that start a line only, and join multiple consecutive ones into one comment.

        my $comment;
        my $functionPrototype;
        my $variablePrototype;
        my $functionPrototypeDone;
        my $variablePrototypeDone;

        use constant FIND_COMMENT => 0;  # Looking for the start of the next comment.
        use constant GET_COMMENT => 1;   # Retrieving the comment.
        use constant FIND_PROTOTYPE => 2;  # Looking for the start of the prototype.
        use constant GET_PROTOTYPE => 3;  # Retrieving the prototypes.

        my $state = FIND_COMMENT;

        my @contentLines = split(/\n/, $content);
        $content = undef;

        my $line = shift @contentLines;

        while (defined $line)
            {
            $line =~ s/^\s+//;
            $line .= "\n";

            # If the line begins with the comment symbol...
            if ( substr($line, 0, length($language->LineComment())) eq $language->LineComment())
                {
                if ($state == FIND_COMMENT)
                    {
                    $comment = substr($line, length($language->LineComment()));
                    $state = GET_COMMENT;
                    }
                elsif ($state == GET_COMMENT)
                    {
                    $comment .= substr($line, length($language->LineComment()));
                    }
                else # ($state == FIND/GET_PROTOTYPE)
                    {
                    CleanComment($comment, $functionPrototype, $variablePrototype);
                    $functionPrototype = undef;
                    $variablePrototype = undef;
                    $comment = substr($line, length($language->LineComment()));
                    $state = GET_COMMENT;
                    }
                }

            # If the line isn't a comment...
            else
                {
                # Note that these are sequential ifs.  These are not if-elsifs.
                if ($state == GET_COMMENT)
                    {
                    if (defined $language->FunctionEnders() || defined $language->VariableEnders())
                        {
                        $state = FIND_PROTOTYPE;

                        $functionPrototypeDone = (!defined $language->FunctionEnders());
                        $variablePrototypeDone = (!defined $language->VariableEnders());

                        # Continues to FIND_PROTOTYPE...
                        }
                    else
                        {
                        CleanComment($comment, undef, undef);
                        $comment = undef;
                        $state = FIND_COMMENT;
                        };
                    };

                if ($state == FIND_PROTOTYPE)
                    {
                    # All whitespace would have been cleared.
                    if ($line ne "\n")
                        {
                        $state = GET_PROTOTYPE;
                        # Continues to GET_PROTOTYPE...
                        };
                    };

                if ($state == GET_PROTOTYPE)
                    {
                    if (!$functionPrototypeDone)
                        {
                        my $endOfFunction = $language->EndOfFunction(\$line);

                        if ($endOfFunction != -1)
                            {
                            $functionPrototype .= substr($line, 0, $endOfFunction);
                            $functionPrototypeDone = 1;
                            }
                        else
                            {
                            $functionPrototype .= $line;
                            };
                        };

                    if (!$variablePrototypeDone)
                        {
                        my $endOfVariable = $language->EndOfVariable(\$line);

                        if ($endOfVariable != -1)
                            {
                            $variablePrototype .= substr($line, 0, $endOfVariable);
                            $variablePrototypeDone = 1;
                            }
                        else
                            {
                            $variablePrototype .= $line;
                            };
                        };

                    if ($functionPrototypeDone && $variablePrototypeDone)
                        {
                        CleanComment($comment, $functionPrototype, $variablePrototype);
                        $comment = undef;
                        $functionPrototype = undef;
                        $variablePrototype = undef;
                        $state = FIND_COMMENT;
                        };
                    };

                # Do nothing if state is FIND_COMMENT
                };

            $line = shift @contentLines;
            };


        # Tie up loose ends if we ran out of file.
        if ($state ne FIND_COMMENT)
            {  CleanComment($comment, $functionPrototype, $variablePrototype);  };

        };
    };


#
#   Function: CleanComment
#
#   Removes any extraneous formatting or whitespace from the comment and sends it to <ExtractTopics()>.  Eliminates comment
#   boxes, horizontal lines, leading and trailing line breaks, leading and trailing whitespace from lines, and more than two line
#   breaks in a row.
#
#   Parameters:
#
#       comment  - The comment to clean.
#       functionPrototype - The potential function prototype appearing after it.  Undef if none or not applicable.
#       variablePrototype - The potential variable prototype appearing after it.  Undef if none or not applicable.
#
sub CleanComment #(comment, functionPrototype, variablePrototype)
    {
    my ($comment, $functionPrototype, $variablePrototype) = @_;

    my @lines = split(/\n/, $comment);
    $comment = undef;

    use constant DONT_KNOW => 0;
    use constant IS_UNIFORM => 1;
    use constant IS_UNIFORM_IF_AT_END => 2;
    use constant IS_NOT_UNIFORM => 3;

    my $leftSide = DONT_KNOW;
    my $rightSide = DONT_KNOW;
    my $leftSideChar;
    my $rightSideChar;

    my $line = shift @lines;
    my $cleanComment;

    while (defined $line)
        {
        # Strip leading and trailing whitespace.

        $line =~ s/^[ \t]+//;
        $line =~ s/[ \t]+$//;

        # If the line is blank...
        if (!length($line))
            {
            $cleanComment .= "\n";

            # If we have a potential vertical line, this only acceptable if it's at the end of the comment.
            if ($leftSide == IS_UNIFORM)
                {  $leftSide = IS_UNIFORM_IF_AT_END;  };
            if ($rightSide == IS_UNIFORM)
                {  $rightSide = IS_UNIFORM_IF_AT_END;  };
            }

        # If there's at least four symbols in a row, it's a horizontal line.  The second regex supports differing edge characters.  It
        # doesn't matter if any of this matches the left and right side symbols.
        elsif ($line =~ /^([^a-zA-Z0-9 \t])\1{3,}$/ ||
                $line =~ /^([^a-zA-Z0-9 \t])\1*([^a-zA-Z0-9 \t])\2{3,}([^a-zA-Z0-9 \t])\3*$/)
            {
            # Add a blank line to the output, since that's what it should be treated as.
            $cleanComment .= "\n";

            # This has no effect on the vertical line detection.
            }

        # If the line is not blank or a horizontal line...
        else
            {
            # More content means any previous blank lines are no longer tolerated in vertical line detection.  They are only
            # acceptable at the end of the comment.

            if ($leftSide == IS_UNIFORM_IF_AT_END)
                {  $leftSide = IS_NOT_UNIFORM;  };
            if ($rightSide == IS_UNIFORM_IF_AT_END)
                {  $rightSide = IS_NOT_UNIFORM;  };


            # Detect vertical lines.  Lines are only lines if they are followed by whitespace or a connected horizontal line.
            # Otherwise we may accidentally detect lines from short comments that just happen to have every first or last
            # character the same.

            if ($leftSide != IS_NOT_UNIFORM)
                {
                if ($line =~ /^([^a-zA-Z0-9])\1*(?:[ \t]|$)/)
                    {
                    if ($leftSide == DONT_KNOW)
                        {
                        $leftSide = IS_UNIFORM;
                        $leftSideChar = $1;
                        }
                    else # ($leftSide == IS_UNIFORM)  Other choices already ruled out.
                        {
                        if ($leftSideChar ne $1)
                            {  $leftSide = IS_NOT_UNIFORM;  };
                        };
                    }
                else
                    {
                    $leftSide = IS_NOT_UNIFORM;
                    };
                };

            if ($rightSide != IS_NOT_UNIFORM)
                {
                if ($line =~ /[ \t]([^a-zA-Z0-9])\1*$/)
                    {
                    if ($rightSide == DONT_KNOW)
                        {
                        $rightSide = IS_UNIFORM;
                        $rightSideChar = $1;
                        }
                    else # ($rightSide == IS_UNIFORM)  Other choices already ruled out.
                        {
                        if ($rightSideChar ne $1)
                            {  $rightSide = IS_NOT_UNIFORM;  };
                        };
                    }
                else
                    {
                    $rightSide = IS_NOT_UNIFORM;
                    };
                };


            # Add the line to the content.  We'll remove vertical lines later if they're uniform throughout the entire comment.

            $cleanComment .= $line . "\n";
            };


        $line = shift @lines;
        };


    if ($leftSide == IS_UNIFORM_IF_AT_END)
        {  $leftSide = IS_UNIFORM;  };
    if ($rightSide == IS_UNIFORM_IF_AT_END)
        {  $rightSide = IS_UNIFORM;  };


    # Clear vertical lines.

    if ($leftSide == IS_UNIFORM)
        {
        # This works because every line should either start this way or be blank.
        $cleanComment =~ s/^([^a-zA-Z0-9])\1*[ \t]*//gm;
        };

    if ($rightSide == IS_UNIFORM)
        {
        $cleanComment =~ s/[ \t]*([^a-zA-Z0-9])\1*$//gm;
        };


    # Clear horizontal lines again if there were vertical lines.  This catches lines that were separated from the verticals by
    # whitespace.  We couldn't do this in the loop because that would make the regexes over-tolerant.

    if ($leftSide == IS_UNIFORM || $rightSide == IS_UNIFORM)
        {
        $cleanComment =~ s/^([^a-zA-Z0-9 \t])\1{3,}$//gm;
        $cleanComment =~ s/^([^a-zA-Z0-9 \t])\1*([^a-zA-Z0-9 \t])\2{3,}([^a-zA-Z0-9 \t])\3*$//gm;
        };


    # Condense line breaks and strip edge ones.

    $cleanComment =~ s/^\n+//;
    $cleanComment =~ s/\n+$//;
    $cleanComment =~ s/\n{3,}/\n\n/g;


    ExtractTopics($cleanComment, $functionPrototype, $variablePrototype);
    };


#
#   Function: ExtractTopics
#
#   Takes the comment and extracts any Natural Docs topics in it.
#
#   Parameters:
#
#       comment  - The comment to interpret
#       functionPrototype  - The potential function prototype.  Undef if none or not applicable.
#       variablePrototype - The potential variable prototype.  Undef if none or not applicable.
#
sub ExtractTopics #(comment, functionPrototype, variablePrototype)
    {
    my ($comment, $functionPrototype, $variablePrototype) = @_;

    my @commentLines = split(/\n/, $comment);
    $comment = undef;

    my $prevLineBlank = 1;

    # Class applies to the name, and scope applies to the body.  They may be completely different.  For example, with a class
    # entry, the class itself is global but its body is within its scope so it can reference members locally.  Also, a file is always
    # global, but its body uses whatever scope it appears in.
    my $class;
    my $name;
    my $type;
    #my $scope;  # package variable.
    my $body;

    my $line = shift @commentLines;

    while (defined $line)
        {
        # Leading and trailing whitespace was removed by CleanComment().

        # If the line is empty...
        if (length $line == 0)
            {
            # CleanComment() made sure there weren't multiple blank lines in a row or at the beginning/end of the comment.
            $body .= "\n";
            $prevLineBlank = 1;
            }

        # If the line has a recognized header and the previous line is blank...
        elsif ($prevLineBlank && $line =~ /^([^:]+):\s+(\S.*)$/ && exists $synonyms{lc($1)})
            {
            my $newType = $synonyms{lc($1)};
            my $newName = $2;

            # Process the previous one, if any.

            if (defined $type)
                {
                $body = FormatBody($body, $type);
                InterpretTopic($name, $class, $type, $body, undef, undef);
                };

            $type = $newType;
            $name = $newName;

            $hasContent = 1;
            $body = undef;


            if ($type == ::TOPIC_SECTION())
                {
                $scope = undef;
                $class = undef;
                }
            elsif ($type == ::TOPIC_CLASS())
                {
                $scope = $name;
                $class = undef;
                }
            elsif ($type == ::TOPIC_CLASS_LIST())
                {
                $scope = undef;
                $class = undef;
                }
            elsif ($type == ::TOPIC_FILE() || $type == ::TOPIC_FILE_LIST())
                {
                # Scope stays the same.
                $class = undef;
                }
            else
                {
                # Scope stays the same.
                $class = $scope;
                };


            # Set the menu title, if necessary.

            if ($defaultMenuTitleState == INDEFINITE)
                {
                # If the file starts off with a section, file, or class, that's the menu title no matter what.
                if ($type == ::TOPIC_SECTION() || $type == ::TOPIC_FILE() || $type == ::TOPIC_CLASS())
                    {
                    $defaultMenuTitle = $name;
                    $defaultMenuTitleState = DEFINITE;
                    }

                # If it starts with something else, that's the menu title only if that's the only thing in the file.
                else
                    {
                    $defaultMenuTitle = $name;
                    $defaultMenuTitleState = DEFINITE_IF_ONLY;
                    };
                }
            elsif ($defaultMenuTitleState eq DEFINITE_IF_ONLY)
                {
                # If there was a second header after starting the file with something other than a section, file, or class,
                # the menu title becomes the file name.

                $defaultMenuTitle = $file;
                $defaultMenuTitleState = DEFINITE;
                };


            $prevLineBlank = 0;
            }


        # Line without recognized header
        else
            {
            if (defined $type)
                {  $body .= $line . "\n";  };

            $prevLineBlank = 0;
            };


        $line = shift @commentLines;
        };


    # Last one, if any.  This is the only one that gets the prototypes.
    if (defined $type)
        {
        $body = FormatBody($body, $type);
        InterpretTopic($name, $class, $type, $body, $functionPrototype, $variablePrototype);
        };
    };


#
#   Function: InterpretTopic
#
#   Handles the parsed topic as appropriate for the parser mode.  If we're parsing for build, it adds it to <parsedFile>.  If
#   we're parsing for symbols, it adds all symbol definitions and references to <NaturalDocs::SymbolTable>.  Scope is gotten from
#   the package variable <scope> instead of from the parameters.
#
#   Parameters:
#
#       name       - The name of the section.
#       class        - The class of the section.
#       type         - The section type.
#       body        - The section's body in <NDMarkup>.
#       functionPrototype - The potential function prototype.
#       variablePrototype - The potential variable prototype.
#
sub InterpretTopic #(name, class, type, body, functionPrototype, variablePrototype)
    {
    my ($name, $class, $type, $body, $functionPrototype, $variablePrototype) = @_;
    # $scope is a package variable.

    # Make sure the potential prototype is applicable and contains the name before including.
    my $prototype;

    if ($type == ::TOPIC_FUNCTION())
        {  $prototype = $functionPrototype;  }
    elsif ($type == ::TOPIC_VARIABLE())
        {  $prototype = $variablePrototype;  };
    # else no prototype for you!

    if (defined $prototype && index($prototype, $name) == -1)
        {  $prototype = undef;  }
    else
        {
        $prototype =~ s/\n/ /g;
        $prototype =~ s/ +$//;
        };


    if ($mode == PARSE_FOR_INFORMATION)
        {
        NaturalDocs::SymbolTable::AddSymbol($class, $name, $file, $type, $prototype);

        if (::TopicIsList($type))
            {
            my $listType = ::TopicIsListOf($type);

            while ($body =~ /<ds>([^<]+)<\/ds>/g)
                {
                NaturalDocs::SymbolTable::AddSymbol($scope, NaturalDocs::NDMarkup::RestoreAmpChars($1), $file,
                                                                          $listType, undef);
                };
            };

        while ($body =~ /<link>([^<]+)<\/link>/g)
            {  NaturalDocs::SymbolTable::AddReference($scope, NaturalDocs::NDMarkup::RestoreAmpChars($1), $file);  };
        }

    else # ($mode == PARSE_FOR_BUILD)
        {
        push @parsedFile, NaturalDocs::Parser::ParsedTopic::New($type, $name, $class, $scope, $prototype, $body);
        };
    };


###############################################################################
# Group: Support Functions


#
#   Function: FormatBody
#
#   Converts the section body to <NDMarkup>.
#
#   Parameters:
#
#       body - The body itself.
#       type - The type of the section.
#
#   Returns:
#
#       The body formatted in <NDMarkup>.
#
sub FormatBody #(body, type)
    {
    my $body = shift;
    my $type = shift;

    use constant TAG_NONE => 1;
    use constant TAG_PARAGRAPH => 2;
    use constant TAG_BULLETLIST => 3;
    use constant TAG_DESCRIPTIONLIST => 4;
    use constant TAG_HEADING => 5;
    use constant TAG_CODE => 6;

    my %tagEnders = ( TAG_NONE() => '',
                                 TAG_PARAGRAPH() => '</p>',
                                 TAG_BULLETLIST() => '</li></ul>',
                                 TAG_DESCRIPTIONLIST() => '</dd></dl>',
                                 TAG_HEADING() => '</h>',
                                 TAG_CODE() => '</code>' );

    my $topLevelTag = TAG_NONE;

    my $output;
    my $textBlock;
    my $prevLineBlank = 1;

    my $codeBlock;
    my $prevCodeLineBlank = 1;
    my $removedCodeSpaces;

    my @bodyLines = split(/\n/, $body);
    $body = undef;


    foreach my $line (@bodyLines)
        {
        # If the line starts with a code designator...
        if ($line =~ /^[>:|]([ \t]*)((?:[^ \t].*)?)$/)
            {
            my $spaces = $1;
            my $code = $2;

            $spaces =~ s/\t/   /g;
            $code =~ s/[ \t]*$//;

            if ($topLevelTag == TAG_CODE)
                {
                if (length $code)
                    {
                    # Make sure we have the minimum amount of spaces to the left possible.
                    if (length($spaces) != $removedCodeSpaces)
                        {
                        my $spaceDifference = abs( length($spaces) - $removedCodeSpaces );
                        my $spacesToAdd;

                        while ($spaceDifference)
                            {
                            $spacesToAdd .= ' ';
                            $spaceDifference--;
                            };

                        if (length($spaces) > $removedCodeSpaces)
                            {
                            $codeBlock .= $spacesToAdd;
                            }
                        else
                            {
                            $codeBlock =~ s/^(.)/$spacesToAdd . $1/gme;
                            $removedCodeSpaces = length($spaces);
                            };
                        };

                    $codeBlock .= $code . "\n";
                    $prevCodeLineBlank = undef;
                    }
                else # (!length $code)
                    {
                    if (!$prevCodeLineBlank)
                        {
                        $codeBlock .= "\n";
                        $prevCodeLineBlank = 1;
                        };
                    };

                $prevLineBlank = undef;
                }
            else # $topLevelTag != TAG_CODE
                {
                if (defined $textBlock)
                    {
                    $output .= RichFormatTextBlock($textBlock) . $tagEnders{$topLevelTag};
                    $textBlock = undef;
                    };

                if (defined $code)
                    {
                    $topLevelTag = TAG_CODE;
                    $output .= '<code>';
                    $codeBlock = $code . "\n";
                    $removedCodeSpaces = length($spaces);
                    $prevCodeLineBlank = undef;
                    }
                else
                    {
                    # Ignore leading blank lines and empty code sections.
                    $topLevelTag = TAG_NONE;
                    };

                $prevLineBlank = undef;
                };
            }

        # If the line doesn't start with a code designator...
        else
            {
            # If we were in a code section...
            if ($topLevelTag == TAG_CODE)
                {
                $codeBlock =~ s/\n+$//;
                $output .= NaturalDocs::NDMarkup::ConvertAmpChars($codeBlock) . '</code>';
                $codeBlock = undef;
                $topLevelTag = TAG_NONE;
                };


            # If the line is blank...
            if (!length $line)
                {
                # End a paragraph.  Everything else ignores it for now.
                if ($topLevelTag == TAG_PARAGRAPH)
                    {
                    $output .= RichFormatTextBlock($textBlock) . '</p>';
                    $textBlock = undef;
                    $topLevelTag = TAG_NONE;
                    };

                $prevLineBlank = 1;
                }

            # If the line starts with a bullet...
            elsif ($line =~ /^[-\*o+]\s+(\S.*)$/)
                {
                my $bulletedText = $1;

                if (defined $textBlock)
                    {  $output .= RichFormatTextBlock($textBlock);  };

                if ($topLevelTag == TAG_BULLETLIST)
                    {
                    $output .= '</li><li>';
                    }
                else #($topLevelTag != TAG_BULLETLIST)
                    {
                    $output .= $tagEnders{$topLevelTag} . '<ul><li>';
                    $topLevelTag = TAG_BULLETLIST;
                    };

                $textBlock = $bulletedText . ' ';

                $prevLineBlank = undef;
                }

            # If the line looks like a description list entry...
            elsif ($line =~ /^(.+?)\s+-\s+(.+)$/)
                {
                my $entry = $1;
                my $description = $2;

                if (defined $textBlock)
                    {  $output .= RichFormatTextBlock($textBlock);  };

                if ($topLevelTag == TAG_DESCRIPTIONLIST)
                    {
                    $output .= '</dd>';
                    }
                else #($topLevelTag != TAG_DESCRIPTIONLIST)
                    {
                    $output .= $tagEnders{$topLevelTag} . '<dl>';
                    $topLevelTag = TAG_DESCRIPTIONLIST;
                    };

                if (::TopicIsList($type))
                    {
                    $output .= '<ds>' . NaturalDocs::NDMarkup::ConvertAmpChars($entry) . '</ds><dd>';
                    }
                else
                    {
                    $output .= '<de>' . NaturalDocs::NDMarkup::ConvertAmpChars($entry) . '</de><dd>';
                    };

                $textBlock = $description . ' ';

                $prevLineBlank = undef;
                }

            # If the line could be a header...
            elsif ($prevLineBlank && $line =~ /^(.*)([^ \t]):$/)
                {
                my $headerText = $1 . $2;

                if (defined $textBlock)
                    {
                    $output .= RichFormatTextBlock($textBlock);
                    $textBlock = undef;
                    }

                $output .= $tagEnders{$topLevelTag};
                $topLevelTag = TAG_NONE;

                $output .= '<h>' . RichFormatTextBlock($headerText) . '</h>';

                $prevLineBlank = undef;
                }

            # If the line isn't any of those, we consider it normal text.
            else
                {
                # A blank line followed by normal text ends lists.  We don't handle this when we detect if the line's blank because
                # we don't want blank lines between list items to break the list.
                if ($prevLineBlank && ($topLevelTag == TAG_BULLETLIST || $topLevelTag == TAG_DESCRIPTIONLIST))
                    {
                    $output .= RichFormatTextBlock($textBlock) . $tagEnders{$topLevelTag} . '<p>';

                    $topLevelTag = TAG_PARAGRAPH;
                    $textBlock = undef;
                    }

                elsif ($topLevelTag == TAG_NONE)
                    {
                    $output .= '<p>';
                    $topLevelTag = TAG_PARAGRAPH;
                    # textBlock will already be undef.
                    };

                $textBlock .= $line . ' ';

                $prevLineBlank = undef;
                };

            };
        };

    # Clean up anything left dangling.
    if (defined $textBlock)
        {
        $output .= RichFormatTextBlock($textBlock) . $tagEnders{$topLevelTag};
        }
    elsif (defined $codeBlock)
        {
        $codeBlock =~ s/\n+$//;
        $output .= NaturalDocs::NDMarkup::ConvertAmpChars($codeBlock) . '</code>';
        };

    return $output;
    };


#
#   Function: RichFormatTextBlock
#
#   Applies rich <NDMarkup> formatting to a chunk of text.  This includes both amp chars, formatting tags, and link tags.
#
#   Parameters:
#
#       text    - The block of text to format.
#
#   Returns:
#
#       The formatted text block.
#
sub RichFormatTextBlock #(text)
    {
    my $text = shift;
    my $output;


    # Split the text from the potential tags.

    my @tempTextBlocks = split(/([\*_<>])/, $text);

    # Since the symbols are considered dividers, empty strings could appear between two in a row or at the beginning/end of the
    # array.  This could seriously screw up TagType(), so we need to get rid of them.
    my @textBlocks;

    while (scalar @tempTextBlocks)
        {
        my $tempTextBlock = shift @tempTextBlocks;

        if (length $tempTextBlock)
            {  push @textBlocks, $tempTextBlock;  };
        };


    my $bold;
    my $underline;
    my $underlineHasWhitespace;

    my $index = 0;

    while ($index < scalar @textBlocks)
        {
        if ($textBlocks[$index] eq '<' && TagType(\@textBlocks, $index) == POSSIBLE_OPENING_TAG)
            {
            my $endingIndex = ClosingTag(\@textBlocks, $index, undef);

            if ($endingIndex != -1)
                {
                my $linkText;
                $index++;

                while ($index < $endingIndex)
                    {
                    $linkText .= $textBlocks[$index];
                    $index++;
                    };
                # Index will be incremented again at the end of the loop.

                if ($linkText =~ /^(?:[a-z0-9\-_]+\.)*[a-z0-9\-_]+@(?:[a-z0-9\-]+\.)+[a-z0-9]{2,4}$/i)
                    {  $output .= '<email>' . NaturalDocs::NDMarkup::ConvertAmpChars($linkText) . '</email>';  }
                elsif ($linkText =~ /^(?:http|https|ftp|news|file)\:[a-z0-9\-\~\@\#\%\&\_\+\/\?\.\,]+$/i)
                    {  $output .= '<url>' . NaturalDocs::NDMarkup::ConvertAmpChars($linkText ). '</url>';  }
                else
                    {  $output .= '<link>' . NaturalDocs::NDMarkup::ConvertAmpChars($linkText) . '</link>';  };
                }

            else # it's not a link.
                {
                $output .= '&lt;';
                };
            }

        elsif ($textBlocks[$index] eq '*')
            {
            my $tagType = TagType(\@textBlocks, $index);

            if ($tagType == POSSIBLE_OPENING_TAG && ClosingTag(\@textBlocks, $index, undef) != -1)
                {
                # ClosingTag() makes sure tags aren't opened multiple times in a row.
                $bold = 1;
                $output .= '<b>';
                }
            elsif ($bold && $tagType == POSSIBLE_CLOSING_TAG)
                {
                $bold = undef;
                $output .= '</b>';
                }
            else
                {
                $output .= '*';
                };
            }

        elsif ($textBlocks[$index] eq '_')
            {
            my $tagType = TagType(\@textBlocks, $index);

             if ($tagType == POSSIBLE_OPENING_TAG && ClosingTag(\@textBlocks, $index, \$underlineHasWhitespace) != -1)
                {
                # ClosingTag() makes sure tags aren't opened multiple times in a row.
                $underline = 1;
                #underlineHasWhitespace is set by ClosingTag().
                $output .= '<u>';
                }
            elsif ($underline && $tagType == POSSIBLE_CLOSING_TAG)
                {
                $underline = undef;
                #underlineHasWhitespace will be reset by the next opening underline.
                $output .= '</u>';
                }
            elsif ($underline && !$underlineHasWhitespace)
                {
                # If there's no whitespace between underline tags, all underscores are replaced by spaces so
                # _some_underlined_text_ becomes <u>some underlined text</u>.  The standard _some underlined text_
                # will work too.
                $output .= ' ';
                }
            else
                {
                $output .= '_';
                };
            }

        else # plain text or a > that isn't part of a link
            {
            my $text = NaturalDocs::NDMarkup::ConvertAmpChars($textBlocks[$index]);

            $text =~ s{   # Begin capture
                                (

                                # The user portion.  Alphanumeric and - _.  Dots can appear between, but not at the edges or more than
                                # one in a row.
                                (?:  [a-z0-9\-_]+  \.  )*   [a-z0-9\-_]+

                                @

                                # The domain.  Alphanumeric and -.  Dots same as above, however, there must be at least two sections
                                # and the last one must be two to four alphanumeric characters (.com, .uk, .info, .203 for IP addresses)
                                (?:  [a-z0-9\-]+  \.  )+  [a-z0-9]{2,4}

                                # End capture.
                                )

                                # The next character can't be an alphanumeric, which should prevent .abcde from matching the two to
                                # for character requirement.
                                (?!  [a-z0-9]  )

                                }

                           {<email>$1<\/email>}igx;

            $text =~ s{
                                # The previous character can't be an alphanumeric.
                                (?<!  [a-z0-9]  )

                                # Begin capture.
                                (

                                # URL must start with one of the acceptable protocols.
                                (?:http|https|ftp|news|file)\:

                                # The acceptable URL characters as far as I know.
                                [a-z0-9\-\~\@\#\%\&\_\+\/\?\.\,]*

                                # The URL characters minus period, comma, and question mark.  If it ends on them, they're probably
                                # intended as punctuation.
                                [a-z0-9\-\~\@\#\%\&\_\+\/]

                                # End capture.
                                )

                                # The next character must not be an acceptable character.  This will prevent the URL from ending early just
                                # to get a match.
                                (?!  [a-z0-9\-\~\@\#\%\&\_\+\/]  )

                                }
                               {<url>$1<\/url>}igx;

            $output .= $text;
            };

        $index++;
        };

    return $output;
    };


#
#   Function: TagType
#
#   Returns whether the tag is a possible opening or closing tag, or neither.  "Possible" because it doesn't check if an opening tag is
#   closed or a closing tag is opened, just whether the surrounding characters allow it to be a candidate for a tag.  For example, in
#   "A _B" the underscore is a possible opening underline tag, but in "A_B" it is not.  Support function for <RichFormatTextBlock()>.
#
#   Parameters:
#
#       textBlocks  - A reference to an array of text blocks.
#       index         - The index of the tag.
#
#   Returns:
#
#       POSSIBLE_OPENING_TAG, POSSIBLE_CLOSING_TAG, or NOT_A_TAG.
#
sub TagType #(textBlocks, index)
    {
    my ($textBlocks, $index) = @_;


    # Possible opening tags

    if ( ( $textBlocks->[$index] =~ /^[\*_<]$/ ) &&

        # Before it must be whitespace, the beginning of the text, or ({["'.
        ( $index == 0 || $textBlocks->[$index-1] =~ /[\ \t\n\(\{\[\"\']$/ ) &&

        # After it must be non-whitespace.
        ( $index + 1 < scalar @$textBlocks && $textBlocks->[$index+1] !~ /^[\ \t\n]/) &&

        # Make sure we don't accept <<, <=, <-, or *= as opening tags
        ( $textBlocks->[$index] ne '<' || $textBlocks->[$index+1] !~ /^[<=-]/ ) &&
        ( $textBlocks->[$index] ne '*' || $textBlocks->[$index+1] !~ /^\=/ ) )
        {
        return POSSIBLE_OPENING_TAG;
        }


    # Possible closing tags

    elsif ( ( $textBlocks->[$index] =~ /^[\*_>]$/) &&

            # After it must be whitespace, the end of the text, or )}].,!?"';:.
            ( $index + 1 == scalar @$textBlocks || $textBlocks->[$index+1] =~ /^[ \t\n\)\]\}\.\,\!\?\"\'\;\:]/ ||
              # Also allow link plurals, like <link>s, <linx>es, and <link>'s.
              ( $textBlocks->[$index] eq '>' && $textBlocks->[$index+1] =~ /^(?:es|s|\'s)/ ) ) &&

            # Before it must be non-whitespace.
            ( $index != 0 && $textBlocks->[$index-1] !~ /[ \t\n]$/ ) &&

            # Make sure we don't accept >>, ->, or => as closing tags.  >= is already taken care of.
            ( $textBlocks->[$index] ne '>' || $textBlocks->[$index-1] !~ /[>=-]$/ ) )
        {
        return POSSIBLE_CLOSING_TAG;
        }

    else
        {
        return NOT_A_TAG;
        };

    };


#
#   Function: ClosingTag
#
#   Returns whether a tag is closed or not, where it's closed if it is, and optionally whether there is any whitespace between the
#   tags.  Support function for <RichFormatTextBlock()>.
#
#   The results of this function are in full context, meaning that if it says a tag is closed, it can be interpreted as that tag in the
#   final output.  It takes into account any spoiling factors, like there being two opening tags in a row.
#
#   Parameters:
#
#       textBlocks             - A reference to an array of text blocks.
#       index                    - The index of the opening tag.
#       hasWhitespaceRef  - A reference to the variable that will hold whether there is whitespace between the tags or not.  If
#                                     undef, the function will not check.  If the tag is not closed, the variable will not be changed.
#
#   Returns:
#
#       If the tag is closed, it returns the index of the closing tag and puts whether there was whitespace between the tags in
#       hasWhitespaceRef if it was specified.  If the tag is not closed, it returns -1 and doesn't touch the variable pointed to by
#       hasWhitespaceRef.
#
sub ClosingTag #(textBlocks, index, hasWhitespace)
    {
    my ($textBlocks, $index, $hasWhitespaceRef) = @_;

    my $hasWhitespace;
    my $closingTag;

    if ($textBlocks->[$index] eq '*' || $textBlocks->[$index] eq '_')
        {  $closingTag = $textBlocks->[$index];  }
    elsif ($textBlocks->[$index] eq '<')
        {  $closingTag = '>';  }
    else
        {  return -1;  };

    my $beginningIndex = $index;
    $index++;

    while ($index < scalar @$textBlocks)
        {
        if ($textBlocks->[$index] eq '<' && TagType($textBlocks, $index) == POSSIBLE_OPENING_TAG)
            {
            # If we hit a < and we're checking whether a link is closed, it's not.  The first < becomes literal and the second one
            # becomes the new link opening.
            if ($closingTag eq '>')
                {
                return -1;
                }

            # If we're not searching for the end of a link, we have to skip the link because formatting tags cannot appear within
            # them.  That's of course provided it's closed.
            else
                {
                my $linkHasWhitespace;

                my $endIndex = ClosingTag($textBlocks, $index,
                                                          ($hasWhitespaceRef && !$hasWhitespace ? \$linkHasWhitespace : undef) );

                if ($endIndex != -1)
                    {
                    if ($linkHasWhitespace)
                        {  $hasWhitespace = 1;  };

                    # index will be incremented again at the end of the loop, which will bring us past the link's >.
                    $index = $endIndex;
                    };
                };
            }

        elsif ($textBlocks->[$index] eq $closingTag)
            {
            my $tagType = TagType($textBlocks, $index);

            if ($tagType == POSSIBLE_CLOSING_TAG)
                {
                # There needs to be something between the tags for them to count.
                if ($index == $beginningIndex + 1)
                    {  return -1;  }
                else
                    {
                    # Success!

                    if ($hasWhitespaceRef)
                        {  $$hasWhitespaceRef = $hasWhitespace;  };

                    return $index;
                    };
                }

            # If there are two opening tags of the same type, the first becomes literal and the next becomes part of a tag.
            elsif ($tagType == POSSIBLE_OPENING_TAG)
                {  return -1;  }
            }

        elsif ($hasWhitespaceRef && !$hasWhitespace)
            {
            if ($textBlocks->[$index] =~ /[ \t\n]/)
                {  $hasWhitespace = 1;  };
            };

        $index++;
        };

    # Hit the end of the text blocks if we're here.
    return -1;
    };


1;