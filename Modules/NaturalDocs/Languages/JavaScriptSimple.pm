###############################################################################
#
#   Class: NaturalDocs::Languages::JavaScriptSimple
#
###############################################################################
#
#   A subclass to handle the language variations of JavaScript.
#
###############################################################################

# This file is part of Natural Docs, which is Copyright © 2003-2010 Greg Valure
# Natural Docs is licensed under version 3 of the GNU Affero General Public License (AGPL)
# Refer to License.txt for the complete details

use strict;
use integer;

package NaturalDocs::Languages::JavaScriptSimple;

use base 'NaturalDocs::Languages::Simple';


#
#   Function: NormalizePrototype
#
#   Normalizes a prototype.  Specifically, condenses spaces, tabs, and line
#   breaks into single spaces and removes leading and trailing ones.
#   It may also unify the syntax depending on the related topic type.
#
#   Parameters:
#
#       prototype - The original prototype string.
#       type      - The type of the related topic.
#       name      - The function name if the prototype lacks it.
#
#   Returns:
#
#       The normalized prototype.
#
sub NormalizePrototype #(prototype, type, name)
    {
    my ($self, $prototype, $type, $name) = @_;

    $prototype =~ tr/ \t\r\n/ /s;
    $prototype =~ s/^ //;
    $prototype =~ s/ $//;
    if ($prototype =~ /^[\w\$]+$/)
        {
        if ($type == ::TOPIC_VARIABLE())
            {
            $prototype = 'var ' . $prototype;
            }
        elsif ($type == ::TOPIC_FUNCTION())
            {
            $prototype = 'function ' . $prototype . '()';
            }
        }
    else
        {
        $prototype =~ s/(var\s*)?([\w\$\.]+)\s*=\s*function\s*\(/function $2(/;
        $prototype =~ s/([\w\$]+)\s*:\s*function\s*\(/function $1(/;
        $prototype =~ s/function\s*([\w\$]+\.)*([\w\$]+)\s*\(/function $2(/;
        }

    return $prototype;
    };


1;
