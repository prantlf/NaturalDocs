###############################################################################
#
#   Class: NaturalDocs::Languages::Ada
#
###############################################################################
#
#   A subclass to handle the language variations of Pascal and Delphi.
#
###############################################################################

# This file is part of Natural Docs, which is Copyright © 2003-2004 Greg Valure
# Natural Docs is licensed under the GPL

use strict;
use integer;

package NaturalDocs::Languages::Ada;

use base 'NaturalDocs::Languages::Simple';


#
#   Topic: Inherits
#
#   <NaturalDocs::Languages::Simple>
#


#
#   Function: EndOfPrototype
#
#   Ada's syntax uses the semicolons and commas parameter style shown below, yet also uses semicolons to end
#   function prototypes.
#
#   > function MyFunction( param1: type; param2, param3: type; param4: type);
#
#   This function creates the false positives necessary to support this.
#
sub EndOfPrototype #(type, stringRef, falsePositives)
    {
    my ($self, $type, $stringRef) = @_;  # Passed falsePositives is ignored.

    my $falsePositives;
    if ($type == ::TOPIC_FUNCTION())
        {  $falsePositives = $self->FalsePositivesForSemicolonsInParenthesis($stringRef);  };

    return $self->SUPER::EndOfPrototype($type, $stringRef, $falsePositives);
    };


1;
