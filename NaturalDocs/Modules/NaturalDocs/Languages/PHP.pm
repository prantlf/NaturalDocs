###############################################################################
#
#   Class: NaturalDocs::Languages::PHP
#
###############################################################################
#
#   A subclass to handle the language variations of PHP.
#
###############################################################################

# This file is part of Natural Docs, which is Copyright © 2003-2004 Greg Valure
# Natural Docs is licensed under the GPL

use strict;
use integer;

package NaturalDocs::Languages::PHP;

use base 'NaturalDocs::Languages::Language';


#
#   Topic: Inherits
#
#   <NaturalDocs::Languages::Language>
#


#
#   Function: MakeSortableSymbol
#
#   PHP's variables start with dollar signs.  This function strips them off for sorting.
#
sub MakeSortableSymbol #(name, type)
    {
    my ($self, $name, $type) = @_;

    if ($type == ::TOPIC_VARIABLE())
        {
        $name =~ s/^\$//;
        };

    return $name;
    };


1;
