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

# This file is part of Natural Docs, which is Copyright © 2003-2004 Greg Valure
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
#
#   Constant: LAST_MEMBER
#
#   The last index in the arrayref used by this package.  When deriving from this package, start your constants at
#
#   > __PACKAGE__->SUPER::LAST_MEMBER() + 1
#
#   and continue incrementing.  Remember to define your own LAST_MEMBER to be the same as the last one.
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

use constant LAST_MEMBER => 6;


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

    NaturalDocs::Languages->Add($object, $extensions, $shebangStrings);


    return $object;
    };



###############################################################################
# Group: Information Functions


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



###############################################################################
# Group: Parsing Functions


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
#   Function: FormatPrototype
#
#   Parses a prototype so that it can be formatted nicely in the output.  By default, this function assumes the parameter list is
#   enclosed in parenthesis and parameters are separated by commas and semicolons.
#
#   Parameters:
#
#       type - The topic type.
#       prototype - The text prototype.
#
#   Returns:
#
#       The array ( preParam, opening, params, closing, postParam ).
#
#       pre - The part of the prototype prior to the parameter list.
#       open - The opening symbol to the parameter list, such as parenthesis.  If there is none, it will be a space.
#       params - An arrayref of parameters, one per entry.  Will be undef if none.
#       close - The closing symbol to the parameter list, such as parenthesis.  If there is none, it will be space.
#       post - The part of the prototype after the parameter list, or undef if none.
#
sub FormatPrototype #(type, prototype)
    {
    my ($self, $type, $prototype) = @_;

    $prototype =~ tr/\t\n /   /s;
    $prototype =~ s/^ //;
    $prototype =~ s/ $//;

    # Cut out early if it's not a function.
    if ($type != ::TOPIC_FUNCTION())
        {  return ( $prototype, undef, undef, undef, undef );  };

    # The parsing routine needs to be able to find the parameters no matter how many parenthesis there are.  For example, look
    # at this VB function declaration:
    #
    # <WebMethod()> Public Function RetrieveTable(ByRef Msg As Integer, ByVal Key As String) As String()

    my @segments = split(/([\(\)])/, $prototype);
    my ($pre, $open, $paramString, $params, $close, $post);
    my $nest = 0;

    while (scalar @segments)
        {
        my $segment = shift @segments;

        if ($nest == 0)
            {  $pre .= $segment;  }

        elsif ($nest == 1 && $segment eq ')')
            {
            if ($paramString =~ /[,;]/)
                {
                $post = join('', $segment, @segments);
                last;
                }
            else
                {
                $pre .= $paramString . $segment;
                $paramString = undef;
                };
            }

        else
            {  $paramString .= $segment;  };

        if ($segment eq '(')
            {  $nest++;  }
        elsif ($segment eq ')' && $nest > 0)
            {  $nest--;  };
        };

    # If there wasn't closing parenthesis...
    if ($paramString && !defined $post)
        {
        $pre .= $paramString;
        $paramString = undef;
        };


    if (!defined $paramString)
        {
        return ( $pre, undef, undef, undef, undef );
        }
    else
        {
        if ($pre =~ /( ?\()$/)
            {
            $open = $1;
            $pre =~ s/ ?\($//;
            };

        if ($post=~ /^(\) ?)/)
            {
            $close = $1;
            $post =~ s/^\) ?//;

            if (!length $post)
                {  $post = undef;  };
            };

        my $params = [ ];

        while ($paramString =~ /([^,;]+[,;]?) ?/g)
            {  push @$params, $1;  };

        return ( $pre, $open, $params, $close, $post );
        };
    };


#
#   Function: MakeSortableSymbol
#
#   Returns the symbol that should be used for sorting.  For example, in Perl, a scalar variable would be "$var".  However, we
#   would want to sort on "var" so that all scalar variables don't get dumped into the symbols category in the indexes.
#
#   Parameters:
#
#       name - The name of the symbol.
#       type  - The symbol's type.  One of the <Topic Types>.
#
#   Returns:
#
#       The symbol to sort on.  If the symbol doesn't need to be altered, just return name.
#
sub MakeSortableSymbol #(name, type)
    {
    my ($self, $name, $type) = @_;
    return $name;
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
