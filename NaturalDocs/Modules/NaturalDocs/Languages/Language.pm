###############################################################################
#
#   Class: NaturalDocs::Languages::Language
#
###############################################################################
#
#   A class containing the characteristics of a particular programming language.
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
#   LINE_COMMENT              - The symbol that starts a single line comment.  Undef if none.
#   START_COMMENT           - The symbol that starts a multi-line comment.  Undef if none.
#   END_COMMENT              - The symbol that ends a multi-line comment.  Undef if none.
#   FUNCTION_ENDERS        - An arrayref of symbols that can end a function prototype.  Undef if not applicable.
#   VARIABLE_ENDERS         - An arrayref of symbols that can end a variable declaration.  Undef if not applicable.
#   LINE_EXTENDER             - The symbol to extend a line of code past a line break.  Undef if not applicable.
#

# DEPENDENCY: New() depends on its parameter list being in the same order as these constants.  If the order changes, New()
# needs to be changed.
use constant LINE_COMMENT => 0;
use constant START_COMMENT => 1;
use constant END_COMMENT => 2;
use constant FUNCTION_ENDERS => 3;
use constant VARIABLE_ENDERS => 4;
use constant LINE_EXTENDER => 5;


#############################################################################
# Group: Functions

#
#   Function: New
#
#   Returns a new language object.
#
#   Parameters:
#
#       lineComment             - The symbol that starts a single-line comment.  Undef if none.
#       startComment            - The symbol that starts a multi-line comment.  Undef if none.
#       endComment             - The symbol that starts a multi-line comment.  Undef if none.
#       functionEnders           - An arrayref of symbols that can end a function prototype.  Undef if not applicable.
#       variableEnders           - An arrayref of symbols that can end a variable declaration.  Undef if not applicable.
#       lineExtender               - The symbel to extend a line of code past a line break.  Undef if not applicable.
#
sub New #(lineComment, startComment, endComment, functionEnders, variableEnders, lineExtender)
    {
    # DEPENDENCY: This function depends on its parameter list being in the same order as the member constants.  If the order
    # changes, this function needs to be changed.

    my $object = [ @_ ];
    bless $object;

    return $object;
    };


# Function: LineComment
# Returns the symbol used to start a single line comment, or undef if none.
sub LineComment
    { return $_[0]->[LINE_COMMENT];  };

# Function: StartComment
# Returns the symbol used to start a multi-line comment, or undef if none.
sub StartComment
    {  return $_[0]->[START_COMMENT];  };

# Function: EndComment
# Returns the symbol used to end a multi-line comment, or undef if none.
sub EndComment
    {  return $_[0]->[END_COMMENT];  };

# Function: FileIsComment
# Returns whether the entire file should be treated as one big comment.
sub FileIsComment
    {
    my $self = $_[0];
     return (!defined $self->LineComment() && !defined $self->StartComment() );
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
#   Function: EndOfFunction
#
#   Returns the index of the end of the function prototype in a string.
#
#   Parameters:
#
#       stringRef        - A reference to the string.
#       startingIndex  - Optional.  The starting index.  If not specified, starts at the beginning of the string.
#
#   Returns:
#
#       The zero-based offset into the string of the end of the prototype, or -1 if the string doesn't contain a symbol from
#       <FunctionEnders()>.
#
sub EndOfFunction #(stringRef, startingIndex optional)
    {
    my ($self, $stringRef, $startingIndex) = @_;

    if (defined $self->FunctionEnders())
        {  return $self->EndOfPrototype($stringRef, $startingIndex, $self->FunctionEnders());  }
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
#       stringRef        - A reference to the string.
#       startingIndex  - Optional.  The starting index.  If not specified, starts at the beginning of the string.
#
#   Returns:
#
#       The zero-based offset into the string of the end of the declaration, or -1 if the string doesn't contain a symbol from
#       <VariableEnders()>.
#
sub EndOfVariable #(stringRef, startingIndex optional)
    {
    my ($self, $stringRef, $startingIndex) = @_;

    if (defined $self->VariableEnders())
        {  return $self->EndOfPrototype($stringRef, $startingIndex, $self->VariableEnders());  }
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
#   Function: EndOfPrototype
#
#   Returns the index of the end of an arbitrary prototype in a string.
#
#   Parameters:
#
#       stringRef        - A reference to the string.
#       startingIndex  - The starting index.  If undef, starts at the beginning of the string.
#       symbols         - An arrayref of the symbols that can end the prototype.
#
#   Returns:
#
#       The zero-based offset into the string of the end of the prototype, or -1 if the string doesn't contain a symbol from the
#       arrayref.
#
sub EndOfPrototype #(stringRef, startingIndex, symbols)
    {
    my ($self, $stringRef, $startingIndex, $symbols) = @_;
    if (!defined $startingIndex)
        {  $startingIndex = 0;  };

    my $enderIndex = -1;

    foreach my $ender (@$symbols)
        {
        my $testIndex;

        if ($ender eq "\n" && defined $self->LineExtender())
            {
            my $newStartingIndex = $startingIndex;

            for (;;)
                {
                $testIndex = index($$stringRef, $ender, $newStartingIndex);

                if ($testIndex == -1)
                    {  last;  };

                my $extenderIndex = rindex($$stringRef, $self->LineExtender(), $testIndex);

                if ($extenderIndex == -1 ||
                    substr( $$stringRef, $extenderIndex + length($self->LineExtender()),
                               $testIndex - $extenderIndex - length($self->LineExtender()) ) =~ /[^ \t]/)
                    {
                    last;
                    };

                $newStartingIndex = $testIndex + 1;
                };
            }
        else
            {  $testIndex = index($$stringRef, $ender, $startingIndex);  };


        if ($testIndex != -1 && ($enderIndex == -1 || $testIndex < $enderIndex))
            {  $enderIndex = $testIndex;  };
        };

    return $enderIndex;
    };



1;