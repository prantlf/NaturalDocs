###############################################################################
#
#   Class: NaturalDocs::Languages::Base
#
###############################################################################
#
#   A base class for all programming language parsers.
#
###############################################################################

# This file is part of Natural Docs, which is Copyright © 2003-2004 Greg Valure
# Natural Docs is licensed under the GPL

use strict;
use integer;

package NaturalDocs::Languages::Base;


#
#   Topic: Implementation
#
#   The class is implemented as a blessed arrayref.  There are no members in this base class, however.
#

#
#   Handle: SOURCEFILEHANDLE
#
#   The handle of the source file currently being parsed.
#

#
#   Function: New
#
#   Creates and returns a new object.
#
sub New
    {
    my ($package) = @_;

    my $object = [ ];
    bless $object, $package;

    return $object;
    };


###############################################################################
# Group: Information Functions


# Function: Name
# Returns the name of the language.  This *must* be defined by a subclass.

# Function: Extensions
# Returns all the possible extensions of the language's files as an arrayref.  Each one must be in all lowercase.  This function
# *must* be defined by a subclass.

# Function: ShebangStrings
# Returns all the possible strings that can appear in a shebang line (#!) of the language's files.  It is returned as an arrayref,
# or undef if not applicable, and all the strings must be in all lowercase.
#
# The default implementation returns undef.
sub ShebangStrings
    {  return undef;  };



###############################################################################
# Group: Parsing Functions


#
#   Function: ParseFile
#
#   Parses the passed source file, sending comments acceptable for documentation to <NaturalDocs::Parser->OnComment()>.
#   This *must* be defined by a subclass.
#
#   Parameters:
#
#       sourceFile - The name of the source file to parse.
#       topicList - A reference to the list of <NaturalDocs::Parser::ParsedTopics> being built by the file.
#
#   Returns:
#
#       The array ( autoTopics, scopeRecord ).
#
#       autoTopics - An arrayref of automatically generated topics from the file, or undef if none.
#       scopeRecord - An arrayref of <NaturalDocs::Languages::Advanced::ScopeChanges>, or undef if none.
#


#
#   Function: FormatPrototype
#
#   Parses a prototype so that it can be formatted nicely in the output.  By default, it formats function prototypes assuming the
#   parameter list is enclosed in parenthesis and parameters are separated by commas and semicolons.  It leaves all other
#   prototypes alone.
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
#       preParam - The part of the prototype prior to the parameter list.  If there is no parameter list, this is the only part of the
#                        array that will be defined.
#       open - The opening symbol to the parameter list, such as parenthesis.  If there is none but there are parameters, it will be
#                 a space.
#       params - An arrayref of parameters, one per entry.  Will be undef if none.
#       close - The closing symbol to the parameter list, such as parenthesis.  If there is none but there are parameters, it will be
#                 a space.
#       postParam - The part of the prototype after the parameter list, or undef if none.
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
#   would want to sort on "var" so that all scalar variables don't get dumped into the symbols category in the indexes.  By
#   default, this function returns the original symbol.
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
#   Function: StripOpeningSymbol
#
#   Determines if the line starts with any of the passed symbols, and if so, replaces it with spaces.  This only happens
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
sub StripOpeningSymbol #(lineRef, symbols)
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
#   Function: StripClosingSymbol
#
#   Determines if the line contains a symbol, and if so, truncates it just before the symbol.
#
#   Parameters:
#
#       lineRef - A reference to the line to check.
#       symbols - An arrayref of the symbols to check for.
#
#   Returns:
#
#       The array ( symbol, lineRemainder ), or undef if the symbol was not found.
#
#       symbol - The symbol that was found.
#       lineRemainder - Everything on the line following the symbol.
#
sub StripClosingSymbol #(lineRef, symbols)
    {
    my ($self, $lineRef, $symbols) = @_;

    my $index = -1;
    my $symbol;

    foreach my $testSymbol (@$symbols)
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


1;
