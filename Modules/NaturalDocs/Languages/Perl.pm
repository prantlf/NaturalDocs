###############################################################################
#
#   Class: NaturalDocs::Languages::Perl
#
###############################################################################
#
#   A subclass to handle the language variations of Perl.
#
###############################################################################

# This file is part of Natural Docs, which is Copyright © 2003-2004 Greg Valure
# Natural Docs is licensed under the GPL

use strict;
use integer;

package NaturalDocs::Languages::Perl;

use base 'NaturalDocs::Languages::Language';


#
#   Topic: Inherits
#
#   <NaturalDocs::Languages::Language>
#


#
#   Function: MakeSortableSymbol
#
#   Perl's variables start with symbols: $ for scalars, @ for arrays, and % for hashes.  This function strips them
#   off for sorting.
#
sub MakeSortableSymbol #(name, type)
    {
    my ($self, $name, $type) = @_;

    if ($type == ::TOPIC_VARIABLE())
        {
        $name =~ s/^[\$\@\%]//;
        };

    return $name;
    };


1;
