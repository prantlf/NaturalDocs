###############################################################################
#
#   Class: NaturalDocs::Languages::Simple
#
###############################################################################
#
#   A class containing the characteristics of a particular programming language for basic support within Natural Docs.
#   Also serves as a base class for languages that break from general conventions, such as not having parameter lists use
#   parenthesis and commas.
#
###############################################################################

# This file is part of Natural Docs, which is Copyright © 2003-2004 Greg Valure
# Natural Docs is licensed under the GPL

use strict;
use integer;

package NaturalDocs::Languages::Simple;

use base 'NaturalDocs::Languages::Base';


#############################################################################
# Group: Implementation

#
#   Constants: Members
#
#   The class is implemented as a blessed arrayref.  The following constants are used as indexes.
#
#   NAME                             - The name of the language.
#   EXTENSIONS                  - An arrayref of the all-lowercase extensions of the language's files.
#   SHEBANG_STRINGS        - An arrayref of the all-lowercase strings that can appear in the language's shebang lines.
#   LINE_COMMENT_SYMBOLS         - An arrayref of symbols that start a single line comment.  Undef if none.
#   OPENING_COMMENT_SYMBOLS  - An arrayref of symbols that start a multi-line comment.  Undef if none.
#   CLOSING_COMMENT_SYMBOLS  - An arrayref of symbols that ends a multi-line comment.  Undef if none.
#   FUNCTION_ENDERS        - An arrayref of symbols that can end a function prototype.  Undef if not applicable.
#   VARIABLE_ENDERS         - An arrayref of symbols that can end a variable declaration.  Undef if not applicable.
#   LINE_EXTENDER             - The symbol to extend a line of code past a line break.  Undef if not applicable.
#

use NaturalDocs::DefineMembers 'NAME', 'EXTENSIONS', 'SHEBANG_STRINGS',
                                                 'LINE_COMMENT_SYMBOLS', 'OPENING_COMMENT_SYMBOLS', 'CLOSING_COMMENT_SYMBOLS',
                                                 'FUNCTION_ENDERS', 'VARIABLE_ENDERS', 'LINE_EXTENDER';


#############################################################################
# Group: Creation Functions

#
#   Function: New
#
#   Returns a new language object and adds it to <NaturalDocs::Languages>.
#
#   Parameters:
#
#       name                - The name of the language.
#       extensions         - The extensions of the language's files.  A string or an arrayref of strings.
#       shebangStrings  - The strings to search for in the #! line of the language's files.  Only used when the file has a .cgi
#                                 extension or no extension at all.  A string, an arrayref of strings, or undef if not applicable.
#       lineCommentSymbols        - The symbols that start a single-line comment.  A string, an arrayref of strings, or undef if none.
#       openingCommentSymbols  - The symbols that start a multi-line comment.  A string, an arrayref of strings, or undef if none.
#       closingCommentSymbols   - The symbols that end a multi-line comment.  A string, an arrayref of strings, or undef if none.
#       functionEnders   - The symbols that can end a function prototype.  A string, an arrayref of strings, or undef if not applicable.
#       variableEnders   - The symbols that can end a variable declaration.  A string, an arrayref of strings, or undef if not applicable.
#       lineExtender      - The symbel to extend a line of code past a line break.  A string or undef if not applicable.
#
#       Note that if neither opening/closingCommentSymbols or lineCommentSymbols are specified, the file will be interpreted
#       as one big comment.
#
sub New #(name, extensions, shebangStrings, lineCommentSymbols, openingCommentSymbols, closingCommentSymbols, functionEnders, variableEnders, lineExtender)
    {
    my ($self, $name, $extensions, $shebangStrings, $lineCommentSymbols, $openingCommentSymbols,
           $closingCommentSymbols, $functionEnders, $variableEnders, $lineExtender) = @_;

    # Since these function calls are the most likely piece of code to be changed by people unfamiliar with Perl, do some extra
    # checking.

    if (scalar @_ != 10)
        {
        die "You didn't pass the correct number of parameters to " . $self . "->New().  "
           . "Check your code against the documentation and try again.\n";
        };


    # Convert everything to arrayrefs.

    foreach my $parameterRef (\$extensions, \$shebangStrings, \$lineCommentSymbols, \$openingCommentSymbols,
                                             \$closingCommentSymbols, \$functionEnders, \$variableEnders)
        {
        if (!ref($$parameterRef) && defined $$parameterRef)
            {  $$parameterRef = [ $$parameterRef ];  };
        };


    # Convert extensions and shebang strings to lowercase.

    if (defined $extensions)
        {
        for (my $i = 0; $i < scalar @$extensions; $i++)
            {  $extensions->[$i] = lc( $extensions->[$i] );  };
        };

    if (defined $shebangStrings)
        {
        for (my $i = 0; $i < scalar @$shebangStrings; $i++)
            {  $shebangStrings->[$i] = lc( $shebangStrings->[$i] );  };
        };


    my $object = $self->SUPER::New();

    $object->[NAME] = $name;
    $object->[EXTENSIONS] = $extensions;
    $object->[SHEBANG_STRINGS] = $shebangStrings;
    $object->[LINE_COMMENT_SYMBOLS] = $lineCommentSymbols;
    $object->[OPENING_COMMENT_SYMBOLS] = $openingCommentSymbols;
    $object->[CLOSING_COMMENT_SYMBOLS] = $closingCommentSymbols;
    $object->[FUNCTION_ENDERS] = $functionEnders;
    $object->[VARIABLE_ENDERS] = $variableEnders;
    $object->[LINE_EXTENDER] = $lineExtender;

    NaturalDocs::Languages->Add($object);

    return $object;
    };



###############################################################################
# Group: Information Functions


# Function: Name
# Returns the name of the language.
sub Name
    {  return $_[0]->[NAME];  };

# Function: Extensions
# Returns all the possible extensions of the language's files as an arrayref.  Each one is in all lowercase.
sub Extensions
    {  return $_[0]->[EXTENSIONS];  };

# Function: ShebangStrings
# Returns all the possible strings that can appear in a shebang line (#!) of the language's files.  It is returned as an arrayref,
# or undef if not applicable, and all the strings are in all lowercase.
sub ShebangStrings
    {  return $_[0]->[SHEBANG_STRINGS];  };

# Function: LineCommentSymbols
# Returns an arrayref of symbols used to start a single line comment, or undef if none.
sub LineCommentSymbols
    { return $_[0]->[LINE_COMMENT_SYMBOLS];  };

# Function: OpeningCommentSymbols
# Returns an arrayref of symbols used to start a multi-line comment, or undef if none.
sub OpeningCommentSymbols
    {  return $_[0]->[OPENING_COMMENT_SYMBOLS];  };

# Function: ClosingCommentSymbols
# Returns an arrayref of symbols used to end a multi-line comment, or undef if none.
sub ClosingCommentSymbols
    {  return $_[0]->[CLOSING_COMMENT_SYMBOLS];  };

# Function: FileIsComment
# Returns whether the entire file should be treated as one big comment.
sub FileIsComment
    {
    my $self = $_[0];
    return (!defined $self->LineCommentSymbols() && !defined $self->OpeningCommentSymbols() );
    };

# Function: FunctionEnders
# Returns an arrayref of the symbols that end a function prototype, or undef if not applicable.
sub FunctionEnders
    {  return $_[0]->[FUNCTION_ENDERS];  };

# Function: VariableEnders
# Returns an arrayref of the symbols that end a variable declaration, or undef if not applicable.
sub VariableEnders
    {  return $_[0]->[VARIABLE_ENDERS];  };

# Function: LineExtender
# Returns the symbol used to extend a line of code past a line break, or undef if not applicable.
sub LineExtender
    {  return $_[0]->[LINE_EXTENDER];  };



###############################################################################
# Group: Parsing Functions


#
#   Function: ParseFile
#
#   Parses the passed source file, sending comments acceptable for documentation to <NaturalDocs::Parser->OnComment()>
#   and all other sections to <OnCode()>.
#
#   Parameters:
#
#       sourceFile - The name of the source file to parse.
#       topicList - A reference to the list of <NaturalDocs::Parser::ParsedTopics> being built by the file.
#
#   Returns:
#
#       Since this class cannot automatically document the code or generate a scope record, it always returns ( undef, undef ).
#
sub ParseFile #(sourceFile, topicsList)
    {
    my ($self, $sourceFile, $topicsList) = @_;

    open(SOURCEFILEHANDLE, '<' . $sourceFile)
        or die "Couldn't open input file " . $sourceFile . "\n";

    my @commentLines;
    my @codeLines;
    my $lastCommentTopicCount = 0;

    if ($self->FileIsComment())
        {
        my $line;

        while ($line = <SOURCEFILEHANDLE>)
            {
            ::XChomp(\$line);
            push @commentLines, $line;
            };

        NaturalDocs::Parser->OnComment(\@commentLines, 1);
        }

    else
        {
        my $line = <SOURCEFILEHANDLE>;
        my $lineNumber = 1;

        while (defined $line)
            {
            ::XChomp(\$line);
            my $originalLine = $line;


            # Retrieve single line comments.  This leaves $line at the next line.

            if ($self->StripOpeningSymbol(\$line, $self->LineCommentSymbols()))
                {
                do
                    {
                    push @commentLines, $line;
                    $line = <SOURCEFILEHANDLE>;

                    if (!defined $line)
                        {  goto EndDo;  };

                    ::XChomp(\$line);
                    }
                while ($self->StripOpeningSymbol(\$line, $self->LineCommentSymbols()));

                EndDo:  # I hate Perl sometimes.
                }


            # Retrieve multiline comments.  This leaves $line at the next line.

            elsif ($self->StripOpeningSymbol(\$line, $self->OpeningCommentSymbols()))
                {
                # Note that it is possible for a multiline comment to start correctly but not end so.  We want those comments to stay in
                # the code.  For example, look at this prototype with this splint annotation:
                #
                # int get_array(integer_t id,
                #                    /*@out@*/ array_t array);
                #
                # The annotation starts correctly but doesn't end so because it is followed by code on the same line.

                my ($symbol, $lineRemainder);

                for (;;)
                    {
                    ($symbol, $lineRemainder) = $self->StripClosingSymbol(\$line, $self->ClosingCommentSymbols());

                    push @commentLines, $line;

                    #  If we found an end comment symbol...
                    if (defined $symbol)
                        {  last;  };

                    $line = <SOURCEFILEHANDLE>;

                    if (!defined $line)
                        {  last;  };

                    ::XChomp(\$line);
                    };

                if ($lineRemainder !~ /^[ \t]*$/)
                    {
                    # If there was something past the closing symbol this wasn't an acceptable comment, so move the lines to code.
                    push @codeLines, @commentLines;
                    @commentLines = ( );
                    };

                $line = <SOURCEFILEHANDLE>;
                }


            # Otherwise just add it to the code.

            else
                {
                push @codeLines, $line;
                $line = <SOURCEFILEHANDLE>;
                };


            # If there were comments, send them to Parser->OnComment().

            if (scalar @commentLines)
                {
                # First process any code lines before the comment.
                if (scalar @codeLines)
                    {
                    $self->OnCode(\@codeLines, $lineNumber, $topicsList, $lastCommentTopicCount);
                    $lineNumber += scalar @codeLines;
                    @codeLines = ( );
                    };

                $lastCommentTopicCount = NaturalDocs::Parser->OnComment(\@commentLines, $lineNumber);
                $lineNumber += scalar @commentLines;
                @commentLines = ( );
                };

            };  # while (defined $line)


        # Clean up any remaining code.
        if (scalar @codeLines)
            {
            $self->OnCode(\@codeLines, $lineNumber, $topicsList, $lastCommentTopicCount);
            @codeLines = ( );
            };

        };

    close(SOURCEFILEHANDLE);

    return ( undef, undef );
    };


#
#   Function: OnCode
#
#   Called whenever a section of code is encountered by the parser.  Is used to find the prototype of the last topic created.
#
#   Parameters:
#
#       codeLines - The source code as an arrayref of lines.
#       codeLineNumber - The line number of the first line of code.
#       topicList - A reference to the list of <NaturalDocs::Parser::ParsedTopics> being built by the file.
#       lastCommentTopicCount - The number of Natural Docs topics that were created by the last comment.
#
sub OnCode #(codeLines, codeLineNumber, topicList, lastCommentTopicCount)
    {
    my ($self, $codeLines, $codeLineNumber, $topicList, $lastCommentTopicCount) = @_;

    if ($lastCommentTopicCount && $self->HasPrototype($topicList->[-1]->Type()))
        {
        my $index = 0;
        my $prototype;

        # Skip all blank lines before a prototype.
        while ($index < scalar @$codeLines && $codeLines->[$index] =~ /^[ \t]*$/)
            {  $index++;  };

        # Add prototype lines until we reach the end of the prototype or the end of the comment lines.
        while ($index < scalar @$codeLines)
            {
            # We need to add a line break because that may be a prototype ender.
            my $line = $codeLines->[$index] . "\n";

            my $endOfPrototype = $self->EndOfPrototype($topicList->[-1]->Type(), \$line, undef);

            if ($endOfPrototype == -1)
                {
                $prototype .= $line;
                $index++;
                }
            else
                {
                # We found it!
                $line = substr($line, 0, $endOfPrototype);
                $prototype .= $line;

                $self->RemoveExtenders(\$line);

                # Add it to the last topic.
                $topicList->[-1]->SetPrototype($prototype);

                return;
                };
            };

        # If we got out of that while loop by running out of lines, there was no prototype.
        };
    };



###############################################################################
# Group: Support Functions


#
#   Function: HasPrototype
#
#   Returns whether the language accepts prototypes from the passed <Topic Types>.
#
sub HasPrototype #(type)
    {
    my ($self, $type) = @_;

    if ($type == ::TOPIC_FUNCTION())
        {  return defined $self->FunctionEnders();  }
    elsif ($type == ::TOPIC_VARIABLE())
        {  return defined $self->VariableEnders();  }
    else
        {  return undef;  };
    };


#
#   Function: EndOfPrototype
#
#   Returns the index of the end of the prototype in a string.
#
#   Parameters:
#
#       type - The topic type of the prototype.
#       stringRef  - A reference to the string.
#       falsePositives  - An existence hashref of indexes into the string that would trigger false positives, and thus should be
#                              ignored.  This is for use by derived classes only, so set to undef.
#
#   Returns:
#
#       The zero-based offset into the string of the end of the prototype, or -1 if the string doesn't contain a symbol that would
#       end it.
#
sub EndOfPrototype #(type, stringRef, falsePositives)
    {
    my ($self, $type, $stringRef, $falsePositives) = @_;

    if ($type == ::TOPIC_FUNCTION() && defined $self->FunctionEnders())
        {  return $self->FindEndOfPrototype($stringRef, $falsePositives, $self->FunctionEnders());  }
    elsif ($type == ::TOPIC_VARIABLE() && defined $self->VariableEnders())
        {  return $self->FindEndOfPrototype($stringRef, $falsePositives, $self->VariableEnders());  }
    else
        {  return -1;  };
    };


#
#   Function: RemoveExtenders
#
#   Strips any <LineExtender()> symbols out of the prototype.
#
#   Parameters:
#
#       stringRef - A reference to the string.  It will be altered rather than a new one returned.
#
sub RemoveExtenders #(stringRef)
    {
    my ($self, $stringRef) = @_;

    if (defined $self->LineExtender())
        {
        my @lines = split(/\n/, $$stringRef);

        for (my $i = 0; $i < scalar @lines; $i++)
            {
            my $extenderIndex = rindex($lines[$i], $self->LineExtender());

            if ($extenderIndex != -1 && substr($lines[$i], $extenderIndex + length($self->LineExtender())) =~ /^[ \t]*$/)
                {  $lines[$i] = substr($lines[$i], 0, $extenderIndex);  };
            };

        $$stringRef = join(' ', @lines);
        };
    };


#
#   Function: FindEndOfPrototype
#
#   Returns the index of the end of an arbitrary prototype in a string.
#
#   Parameters:
#
#       stringRef        - A reference to the string.
#       falsePositives  - An existence hashref of indexes into the string that would trigger false positives, and thus should be
#                              ignored.  Undef if none.
#       symbols         - An arrayref of the symbols that can end the prototype.
#
#   Returns:
#
#       The zero-based offset into the string of the end of the prototype, or -1 if the string doesn't contain a symbol from the
#       arrayref.
#
sub FindEndOfPrototype #(stringRef, falsePositives, symbols)
    {
    my ($self, $stringRef, $falsePositives, $symbols) = @_;

    if (!defined $falsePositives)
        {  $falsePositives = { };  };

    my $enderIndex = -1;

    foreach my $ender (@$symbols)
        {
        my $testIndex;

        if ($ender eq "\n" && defined $self->LineExtender())
            {
            my $startingIndex = 0;

            for (;;)
                {
                $testIndex = index($$stringRef, $ender, $startingIndex);

                if ($testIndex == -1)
                    {  last;  };

                my $extenderIndex = rindex($$stringRef, $self->LineExtender(), $testIndex);

                if ($extenderIndex == -1 ||
                    ( substr( $$stringRef, $extenderIndex + length($self->LineExtender()),
                                 $testIndex - $extenderIndex - length($self->LineExtender()) ) !~ /^[ \t]*$/ &&
                      !exists $falsePositives->{$testIndex}) )
                    {
                    last;
                    };

                $startingIndex = $testIndex + 1;
                };
            }

        elsif ($ender =~ /^[a-z]+$/i)
            {
            my $startingIndex = 0;

            for (;;)
                {
                $testIndex = index($$stringRef, $ender, $startingIndex);

                if ($testIndex == -1)
                    {  last;  };

                # If the ender is a text keyword, the next and previous character can't be alphanumeric.
                if ( ($testIndex == 0 || substr($$stringRef, $testIndex - 1, 1) !~ /^[a-z0-9_]$/i) &&
                     substr($$stringRef, $testIndex + length($ender), 1) !~ /^[a-z0-9_]$/i &&
                     !exists $falsePositives->{$testIndex} )
                    {
                    last;
                    };

                $startingIndex = $testIndex + 1;
                };
            }

        else # ender is a symbol or a line break with no defined line extender.
            {
            my $startingIndex = 0;

            for (;;)
                {
                $testIndex = index($$stringRef, $ender, $startingIndex);

                if ($testIndex == -1 || !exists $falsePositives->{$testIndex})
                    {  last;  };

                $startingIndex = $testIndex + 1;
                };
            };


        if ($testIndex != -1 && ($enderIndex == -1 || $testIndex < $enderIndex))
            {  $enderIndex = $testIndex;  };
        };

    return $enderIndex;
    };


#
#   Function: FalsePositivesForSemicolonsInParenthesis
#
#   Returns an existence hashref of potential false positives for languages that can end a function prototype with a semicolon
#   but also use them to separate parameters.  For example:
#
#   > function MyFunction( param1: type; param2, param3: type; param4: type);
#
#   It will create false positives for every semicolon appearing within parenthesis.
#
#   Parameters:
#
#       stringRef - The potential function prototype.
#
#   Returns:
#
#       An existence hashref of false positive indexes.  If none, will return an empty hashref.
#
sub FalsePositivesForSemicolonsInParenthesis #(stringRef)
    {
    my ($self, $stringRef) = @_;

    my $falsePositives = { };
    my $startingParenIndex = 0;

    for (;;)
        {
        my $openingParenIndex = index($$stringRef, '(', $startingParenIndex);

        if ($openingParenIndex == -1)
            {  last;  };

        my $closingParenIndex = index($$stringRef, ')', $openingParenIndex);
        my $startingSemicolonIndex = $openingParenIndex;

        for (;;)
            {
            my $semicolonIndex = index($$stringRef, ';', $startingSemicolonIndex);

            if ($semicolonIndex == -1 || ($closingParenIndex != -1 && $semicolonIndex > $closingParenIndex))
                {  last;  };

            $falsePositives->{$semicolonIndex} = 1;
            $startingSemicolonIndex = $semicolonIndex + 1;
            };

        if ($closingParenIndex == -1)
            {  last;  }
        else
            {  $startingParenIndex = $closingParenIndex + 1;  };
        };

    return $falsePositives;
    };


1;
