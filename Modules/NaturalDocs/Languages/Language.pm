###############################################################################
#
#   Class: NaturalDocs::Languages::Language
#
###############################################################################
#
#   A class containing the characteristics of a particular programming language.  Also serves as a base class for languages
#   that break from general conventions, such as not having parameter lists use parenthesis and commas.
#
###############################################################################

# This file is part of Natural Docs, which is Copyright © 2003 Greg Valure
# Natural Docs is licensed under the GPL

use strict;
use integer;

package NaturalDocs::Languages::Language;


#############################################################################
# Group: Implementation

#
#   Constants: Members
#
#   The class is implemented as a blessed arrayref.  The following constants are used as indexes.
#
#   NAME                             - The name of the language.
#   LINE_COMMENT_SYMBOLS         - An arrayref of symbols that start a single line comment.  Undef if none.
#   OPENING_COMMENT_SYMBOLS  - An arrayref of symbols that start a multi-line comment.  Undef if none.
#   CLOSING_COMMENT_SYMBOLS  - An arrayref of symbols that ends a multi-line comment.  Undef if none.
#   FUNCTION_ENDERS        - An arrayref of symbols that can end a function prototype.  Undef if not applicable.
#   VARIABLE_ENDERS         - An arrayref of symbols that can end a variable declaration.  Undef if not applicable.
#   LINE_EXTENDER             - The symbol to extend a line of code past a line break.  Undef if not applicable.
#

# DEPENDENCY: New() depends on its parameter list being in the same order as these constants.  If the order changes, New()
# needs to be changed.
use constant NAME => 0;
use constant LINE_COMMENT_SYMBOLS => 1;
use constant OPENING_COMMENT_SYMBOLS => 2;
use constant CLOSING_COMMENT_SYMBOLS => 3;
use constant FUNCTION_ENDERS => 4;
use constant VARIABLE_ENDERS => 5;
use constant LINE_EXTENDER => 6;


#############################################################################
# Group: Functions

#
#   Function: New
#
#   Returns a new language object.
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
    my ($package, $name, $extensions, $shebangStrings, $lineCommentSymbols, $openingCommentSymbols,
           $closingCommentSymbols, $functionEnders, $variableEnders, $lineExtender) = @_;

    # Since these function calls are the most likely piece of code to be changed by people unfamiliar with Perl, do some extra
    # checking.

    if (scalar @_ != 10)
        {
        die "You didn't pass the correct number of parameters to NaturalDocs::Languages::Language->New().  "
           . "Check your code against the documentation and try again.\n";
        };


    # Convert everything to arrayrefs.

    foreach my $parameterRef (\$extensions, \$shebangStrings, \$lineCommentSymbols, \$openingCommentSymbols,
                                             \$closingCommentSymbols, \$functionEnders, \$variableEnders)
        {
        if (!ref($$parameterRef) && defined $$parameterRef)
            {  $$parameterRef = [ $$parameterRef ];  };
        };


    # DEPENDENCY:  This line is dependent on the order of the constants.  If they change, this needs to change.

    my $object = [ $name, $lineCommentSymbols, $openingCommentSymbols, $closingCommentSymbols,
                          $functionEnders, $variableEnders, $lineExtender ];
    bless $object, $package;

    NaturalDocs::Languages::Register($object, $extensions, $shebangStrings);


    return $object;
    };


# Function: Name
# Returns the name of the language.
sub Name
    {  return $_[0]->[NAME];  };

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


#
#   Function: StripLineCommentSymbol
#
#   Determines if the line starts with a line comment symbol, and if so, replaces it with spaces.  This only happens if the only
#   thing before it on the line is whitespace.
#
#   Parameters:
#
#       lineRef - A reference to the line to check.
#
#   Returns:
#
#       If the line starts with a line comment symbol, it will replace it in the line with spaces and return the symbol.  If the line
#       doesn't, it will leave the line alone and return undef.
#
sub StripLineCommentSymbol #(lineRef)
    {
    my ($self, $lineRef) = @_;
    return $self->StripCommentSymbol($lineRef, $self->LineCommentSymbols());
    };


#
#   Function: StripOpeningCommentSymbol
#
#   Determines if the line starts with an opening multiline comment symbol, and if so, replaces it with spaces.  This only happens
#   if the only thing before it on the line is whitespace.
#
#   Parameters:
#
#       lineRef - A reference to the line to check.
#
#   Returns:
#
#       If the line starts with an opening multiline comment symbol, it will replace it in the line with spaces and return the symbol.
#       If the line doesn't, it will leave the line alone and return undef.
#
sub StripOpeningCommentSymbol #(lineRef)
    {
    my ($self, $lineRef) = @_;
    return $self->StripCommentSymbol($lineRef, $self->OpeningCommentSymbols());
    };


#
#   Function: StripClosingCommentSymbol
#
#   Determines if the line contains a closing multiline comment symbol, and if so, truncates it just before the symbol.
#
#   Parameters:
#
#       lineRef - A reference to the line to check.
#
#   Returns:
#
#       The array ( symbol, lineRemainder ), or undef if the symbol was not found.
#
#       symbol - The symbol that was found.
#       lineRemainder - Everything on the line following the symbol.
#
sub StripClosingCommentSymbol #(lineRef)
    {
    my ($self, $lineRef) = @_;

    my $index = -1;
    my $symbol;

    foreach my $testSymbol (@{$self->ClosingCommentSymbols()})
        {
        my $testIndex = index($$lineRef, $testSymbol);

        if ($testIndex != -1 && ($index == -1 || $testIndex < $index))
            {
            $index = $testIndex;
            $symbol = $testSymbol;
            };
        };

    if ($index != -1)
        {
        my $lineRemainder = substr($$lineRef, $index + length($symbol));
        $$lineRef = substr($$lineRef, 0, $index);

        return ($symbol, $lineRemainder);
        }
    else
        {  return undef;  };
    };


#
#   Function: EndOfFunction
#
#   Returns the index of the end of the function prototype in a string.
#
#   Parameters:
#
#       stringRef  - A reference to the string.
#
#   Returns:
#
#       The zero-based offset into the string of the end of the prototype, or -1 if the string doesn't contain a symbol from
#       <FunctionEnders()>.
#
sub EndOfFunction #(stringRef)
    {
    my ($self, $stringRef) = @_;

    if (defined $self->FunctionEnders())
        {  return $self->EndOfPrototype($stringRef, $self->FunctionEnders());  }
    else
        {  return -1;  };
    };


#
#   Function: EndOfVariable
#
#   Returns the index of the end of the variable declaration in a string.
#
#   Parameters:
#
#       stringRef  - A reference to the string.
#
#   Returns:
#
#       The zero-based offset into the string of the end of the declaration, or -1 if the string doesn't contain a symbol from
#       <VariableEnders()>.
#
sub EndOfVariable #(stringRef)
    {
    my ($self, $stringRef) = @_;

    if (defined $self->VariableEnders())
        {  return $self->EndOfPrototype($stringRef, $self->VariableEnders());  }
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


###############################################################################
# Group: Support Functions


#
#   Function: StripCommentSymbol
#
#   Determines if the line starts with any of the passed comment symbols, and if so, replaces it with spaces.  This only happens
#   if the only thing before it on the line is whitespace.
#
#   Parameters:
#
#       lineRef - A reference to the line to check.
#       symbols - An arrayref of the symbols to check for.
#
#   Returns:
#
#       If the line starts with any of the passed comment symbols, it will replace it in the line with spaces and return the symbol.
#       If the line doesn't, it will leave the line alone and return undef.
#
sub StripCommentSymbol #(lineRef, symbols)
    {
    my ($self, $lineRef, $symbols) = @_;

    if (!defined $symbols)
        {  return undef;  };

    foreach my $symbol (@$symbols)
        {
        my $index = index($$lineRef, $symbol);

        if ($index != -1 && substr($$lineRef, 0, $index) =~ /^[ \t]*$/)
            {
            return substr($$lineRef, $index, length($symbol), ' ' x length($symbol));
            };
        };

    return undef;
    };


#
#   Function: EndOfPrototype
#
#   Returns the index of the end of an arbitrary prototype in a string.
#
#   Parameters:
#
#       stringRef        - A reference to the string.
#       symbols         - An arrayref of the symbols that can end the prototype.
#
#   Returns:
#
#       The zero-based offset into the string of the end of the prototype, or -1 if the string doesn't contain a symbol from the
#       arrayref.
#
sub EndOfPrototype #(stringRef, symbols)
    {
    my ($self, $stringRef, $symbols) = @_;

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
                    substr( $$stringRef, $extenderIndex + length($self->LineExtender()),
                               $testIndex - $extenderIndex - length($self->LineExtender()) ) =~ /[^ \t]/)
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
                     substr($$stringRef, $testIndex + length($ender), 1) !~ /^[a-z0-9_]$/i )
                    {
                    if ($self->Name() eq 'PL/SQL' && (lc($ender) eq 'is' || lc($ender) eq 'as') &&
                        $testIndex != 0 && substr($$stringRef, $testIndex - 1, 1) eq '@')
                        {
                        # An exception for PL/SQL.  Microsoft's syntax specifies parameters as @param, @param so it's valid to have
                        # parameters named @is or @as.  We don't want to count those as matches.
                        }
                    else
                        {  last;  };
                    };

                $startingIndex = $testIndex + 1;
                };
            }

        else # ender is a symbol or a line break with no defined line extender.
            {
            $testIndex = index($$stringRef, $ender);

            # An exception for Pascal.  Semicolons are used both to end functions and to separate parameters.  Parenthesis are
            # required if you want parameters, but parameters are not required themselves.
            if ($self->Name() eq 'Pascal' && $ender eq ';' && $testIndex != -1)
                {
                my $openParenIndex = index($$stringRef, '(');

                if ($openParenIndex != -1 && $openParenIndex < $testIndex)
                    {
                    my $closedParenIndex = index($$stringRef, ')', $openParenIndex);

                    if ($closedParenIndex == -1)
                        {  $testIndex = -1;  }
                    else
                        {  $testIndex = index($$stringRef, ';', $closedParenIndex);  };
                    };
                };
            };


        if ($testIndex != -1 && ($enderIndex == -1 || $testIndex < $enderIndex))
            {  $enderIndex = $testIndex;  };
        };

    return $enderIndex;
    };


1;