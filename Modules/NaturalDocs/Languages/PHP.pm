###############################################################################
#
#   Class: NaturalDocs::Languages::PHP
#
###############################################################################
#
#   A subclass to handle the language variations of PHP.
#
###############################################################################

# This file is part of Natural Docs, which is Copyright © 2003 Greg Valure
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


#
#   About: Escapement
#
#   Okay, so Natural Docs has escapement detection now, so why isn't it implemented for PHP?  Well, I actually do have some
#   (untested) code that does just that, but I didn't include it because PHP ignores closing escapement characters (like ?>) when
#   they're in a multiline comment or a string.  Since I don't have the architecture in place for _that_ kind of specificity yet, I'd
#   rather not include it at all yet.  It will have to wait for full code documentation when we can deal with that.
#
#   Still, why not include it anyway?  Because right now, everything, including the HTML, is treated as PHP code.  This has the risk
#   of HTML looking like PHP comments with Natural Docs content and being interpreted as such.  With the existing escapement
#   code, you have the risk of ending escapement prematurely, which would cause legitimate PHP code, and possibly
#   documentation, to be ignored.  I see this scenario as much more probable than the HTML one, plus the result of including
#   something inappropriate is much more benign than the result of excluding something appropriate.
#



1;
