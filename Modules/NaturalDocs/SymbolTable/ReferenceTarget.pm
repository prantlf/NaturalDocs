###############################################################################
#
#   Class: NaturalDocs::SymbolTable::ReferenceTarget
#
###############################################################################
#
#   A class for storing information about a reference target.
#
###############################################################################

# This file is part of Natural Docs, which is Copyright © 2003 Greg Valure
# Natural Docs is licensed under the GPL

use strict;
use integer;

package NaturalDocs::SymbolTable::ReferenceTarget;


###############################################################################
# Group: Implementation

#
#   Constants: Members
#
#   The class is implemented as a blessed arrayref.  The following constants are its members.
#
#       CLASS    - The target class, or undef if global.
#       SYMBOL  - The target symbol.
#       FILE        - The file the target is defined as.
#       TYPE       - The target type.  Will be one of the <Topic Types>.
#       PROTOTYPE - The target's prototype, or undef if none.
#       SUMMARY    - The target's summary, or undef if none.
#

# DEPENDENCY: New() depends on the order of these constants.  If they change, New() has to be updated.
use constant CLASS => 0;
use constant SYMBOL => 1;
use constant FILE => 2;
use constant TYPE => 3;
use constant PROTOTYPE => 4;
use constant SUMMARY => 5;

###############################################################################
# Group: Functions


#
#   Function: New
#
#   Creates and returns a new object.
#
#   Parameters:
#
#       class    - The target class, or undef if global.
#       symbol - The target symbol.
#       file       - The file the target is defined in.
#       type     - The type of the target symbol.  Will be one of the <Topic Types>.
#       prototype - The target's prototype.  Set to undef if not defined or not applicable.
#       summary - The target's summary.  Set to undef if not defined or not applicable.
#
sub New #(class, symbol, file, type, prototype, summary)
    {
    # DEPENDENCY: This code depends on the order of the member constants.

    my $package = shift;

    my $object = [ @_ ];
    bless $object, $package;

    return $object;
    };


# Function: Class
# Returns the target's class, or undef if it's global.
sub Class
    {  return $_[0]->[CLASS];  };

# Function: Symbol
# Returns the target's symbol.
sub Symbol
    {  return $_[0]->[SYMBOL];  };

# Function: File
# Returns the file the target is defined in.
sub File
    {  return $_[0]->[FILE];  };

# Function: Type
# Returns the target's type.  Will be one of the <Topic Types>.
sub Type
    {  return $_[0]->[TYPE];  };

# Function: Prototype
# Returns the target's prototype, or undef if not defined or not applicable.
sub Prototype
    {  return $_[0]->[PROTOTYPE];  };

# Function: Summary
# Returns the target's summary, or undef if not defined or not applicable.
sub Summary
    {  return $_[0]->[SUMMARY];  };

1;