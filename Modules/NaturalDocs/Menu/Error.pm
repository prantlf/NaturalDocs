###############################################################################
#
#   Package: NaturalDocs::Menu::Error
#
###############################################################################
#
#   A class representing an error in the menu.
#
###############################################################################

# This file is part of Natural Docs, which is Copyright © 2003 Greg Valure
# Natural Docs is licensed under the GPL

use strict;
use integer;

package NaturalDocs::Menu::Error;


###############################################################################
# Group: Implementation

#
#   Constants: Members
#
#   The object is implemented as a blessed arrayref with the indexes below.
#
#       LINE  - The line number the error appears on.
#       DESCRIPTION  - The error description.
#
use constant LINE => 0;
use constant DESCRIPTION => 1;
# DEPENDENCY: New() depends on the order of these constants.


###############################################################################
# Group: Functions

#
#   Function: New
#
#   Creates and returns a new object.
#
#   Parameters:
#
#       line - The line number the error appears on.
#       description - The description of the error.
#
sub New #(line, description)
    {
    # DEPENDENCY: This gode depends on the order of the constants.

    my $package = shift;

    my $object = [ @_ ];
    bless $object, $package;

    return $object;
    };


#
#   Function: Line
#
#   Returns the line number of the error
#
sub Line
    {  return $_[0]->[LINE];  };


#
#   Function: Description
#
#   Returns the description of the error.
#
sub Description
    {
    return $_[0]->[DESCRIPTION];
    };


1;