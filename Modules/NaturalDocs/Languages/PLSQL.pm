###############################################################################
#
#   Class: NaturalDocs::Languages::PLSQL
#
###############################################################################
#
#   A subclass to handle the language variations of PL/SQL.
#
###############################################################################

# This file is part of Natural Docs, which is Copyright © 2003 Greg Valure
# Natural Docs is licensed under the GPL

use strict;
use integer;

package NaturalDocs::Languages::PLSQL;

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
#       Microsoft's SQL specifies parameters as shown below.
#
#       > CREATE PROCEDURE Test @as int, @foo int AS ...
#
#       Having a parameter @is or @as is perfectly valid even though those words are also used to end the prototype.  Note any
#       false positives created by this.
#
sub EndOfFunction #(stringRef, falsePositives)
    {
    my ($self, $stringRef) = @_;  # Passed falsePositives is ignored.

    my %falsePositives;

    foreach my $ender (@{$self->FunctionEnders()})
        {
        my $index = 0;

        for (;;)
            {
            $index = index($$stringRef, '@' . $ender, $index);

            if ($index == -1)
                {  last;  };

            # +1 because the positive will be after the @ symbol.
            $falsePositives{$index + 1} = 1;
            $index++;
            };
        };

    return $self->SUPER::EndOfFunction($stringRef, \%falsePositives);
    };


1;