###############################################################################
#
#   Package: NaturalDocs::StringSort
#
###############################################################################
#
#   A package that does proper string sorting.  A proper sort orders the characters as follows.
#
#   - End of string.
#   - Whitespace.  Line break-tab-space.
#   - Symbols, which is anything not included in the other entries.
#   - Numbers, 0-9.
#   - Letters, case insensitive except to break ties.
#
#   Normal string sorting would place certain symbols between letters and numbers instead of having them all grouped together.
#   Also, you would have to choose between case sensitivity or complete case insensitivity, in which ties are broken arbitrarily.
#
#   This is one more package I wish I didn't have to write.  Sigh.
#
###############################################################################

# This file is part of Natural Docs, which is Copyright © 2003 Greg Valure
# Natural Docs is licensed under the GPL

use strict;
use integer;

package NaturalDocs::StringSort;


#
#   Function: Compare
#
#   Compares two strings.  Returns zero if A and B are equal, a positive value if A is greater than B, and a negative value if A is
#   less than B.
#
sub Compare #(a, b)
    {
    my ($a, $b) = @_;

    if (!defined $a)
        {
        if (!defined $b)
            {  return 0;  }
        else
            {  return -1;  };
        }
    elsif (!defined $b)
        {
        return 1;
        };

    my $limit = length $a;
    if (length $b < $limit)
        {  $limit = length $b;  };

    my $index = 0;
    my $ordA;
    my $ordB;

    while ($index < $limit)
        {
        $ordA = SortOrdinal(substr($a, $index, 1));
        $ordB = SortOrdinal(substr($b, $index, 1));

        if ($ordA != $ordB)
            {  return $ordA - $ordB;  };

        $index++;
        };

    if (length $a == length $b)
        {  return BreakTie($a, $b);  }
    else
        {  return length($a) - length($b);  };
    };


###############################################################################
# Group: Support Functions

#
#   Function: SortOrdinal
#
#   Returns an ordinal value for a character that can be used for sorting.  Note that the value is completely case insensitive;
#   capital and lowercase letters return the same value.
#
sub SortOrdinal #(character)
    {
    my $character = shift;

    # Here's the result:
    # Undef - 0
    # \n - 1
    # \r - 2
    # \t - 3
    # space - 4
    # symbols - ordinal + 4
    # numbers - relative to '0' plus 60000, which puts it beyond Unicode
    # letters - relative to 'a' or 'A' plus 60010, which puts it beyond Unicode and the numbers

    # The order of these tests is optimized so the most common ones come first, with the exception of undef and symbols, which
    # have to be first and last.  This is going to be slow enough as it is.

    if (!defined $character)
        {  return 0;  }

    elsif (ord(lc($character)) >= ord('a') && ord(lc($character)) <= ord('z'))
        {
        return ( ((ord(lc($character)) - ord('a')) << 1) + 60010 );
        }

    elsif ($character eq " ")
        {  return 4;  }

    elsif (ord($character) >= ord('0') && ord($character) <= ord('9'))
        {
        return ( (ord($character) - ord('0')) + 60000 );
        }

    elsif ($character eq "\n")
        {  return 1;  }
    elsif ($character eq "\r")
        {  return 2;  }
    elsif ($character eq "\t")
        {  return 3;  }

    else
        {
        return (ord($character) + 4);
        };
    };


#
#   Function: BreakTie
#
#   Compares two strings that are completely the same when compared in a case-insensitive manner.  Lower case letters come
#   first.
#
sub BreakTie #(a, b)
    {
    my ($a, $b) = @_;

    # Just to keep everything theoretically kosher, even though in practice we don't need this.
    if (ord('A') > ord('a'))
        {  return ($a cmp $b);  }
    else
        {  return ($b cmp $a);  };
    };

1;