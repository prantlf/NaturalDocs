###############################################################################
#
#   Class: NaturalDocs::Languages::Ada
#
###############################################################################
#
#   A subclass to handle the language variations of Pascal and Delphi.
#
###############################################################################

# This file is part of Natural Docs, which is Copyright © 2003 Greg Valure
# Natural Docs is licensed under the GPL

use strict;
use integer;

package NaturalDocs::Languages::Ada;

use base 'NaturalDocs::Languages::Language';


#
#   Topic: Inherits
#
#   <NaturalDocs::Languages::Language>
#


#
#   Function: EndOfFunction
#
#   Returns the index of the end of the function prototype in a string.
#
#   Parameters:
#
#       stringRef  - A reference to the string.
#       falsePositives  - Ignored.  For consistency only.
#
#   Returns:
#
#       The zero-based offset into the string of the end of the prototype, or -1 if the string doesn't contain a symbol from
#       <FunctionEnders()>.
#
#   Language Issue:
#
#       Ada's syntax uses the semicolons and commas parameter style shown below, yet also uses semicolons to end
#       function prototypes.
#
#       > function MyFunction( param1: type; param2, param3: type; param4: type);
#
#       This function creates the false positives necessary to support this.
#
sub EndOfFunction #(stringRef, falsePositives)
    {
    my ($self, $stringRef) = @_;  # Passed falsePositives is ignored.

    my $falsePositives = $self->FalsePositivesForSemicolonsInParenthesis($stringRef);

    return $self->SUPER::EndOfFunction($stringRef, $falsePositives);
    };


1;