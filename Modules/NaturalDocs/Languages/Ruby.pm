###############################################################################
#
#   Class: NaturalDocs::Languages::Ruby
#
###############################################################################
#
#   A subclass to handle the language variations of Ruby.
#
###############################################################################

# This file is part of Natural Docs, which is Copyright © 2003-2004 Greg Valure
# Natural Docs is licensed under the GPL

use strict;
use integer;

package NaturalDocs::Languages::Ruby;

use base 'NaturalDocs::Languages::Simple';


#
#   Function: MakeSortableSymbol
#
#   Ruby's variables may start with symbols: none for local, $ for global, @ for instance, and @@ for class.  This function strips
#   them off for sorting.
#
sub MakeSortableSymbol #(name, type)
    {
    my ($self, $name, $type) = @_;

    if ($type == ::TOPIC_VARIABLE())
        {
        $name =~ s/^(?:\@\@|[\$\@])//;
        };

    return $name;
    };


1;
