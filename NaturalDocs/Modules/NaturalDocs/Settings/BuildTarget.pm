###############################################################################
#
#   Class: NaturalDocs::Settings::BuildTarget
#
###############################################################################
#
#   A class that stores information about a build target.
#
###############################################################################

# This file is part of Natural Docs, which is Copyright © 2003-2004 Greg Valure
# Natural Docs is licensed under the GPL

use strict;
use integer;

package NaturalDocs::Settings::BuildTarget;


###############################################################################
# Group: Implementation


#
#   Constants: Members
#
#   The class is implemented as a blessed arrayref with the members below.
#
#       NAME           - The name of the target.
#       BUILDER      - The <NaturalDocs::Builder> sub-object for the target's output format.
#       DIRECTORY - The output directory of the target.
#       STYLE          - The style of the target.  If the target is HTML-based, it's the CSS style.
#
use constant NAME => 0;
use constant BUILDER => 1;
use constant DIRECTORY => 2;
use constant STYLE => 3;
# New depends on the order of these constants.


###############################################################################
# Group: Functions

#
#   Function: New
#
#   Creates and returns a new object.
#
#   Parameters:
#
#       name - The name of the target.
#       builder - The <NaturalDocs::Builder> sub-object for the target's output format.
#       directory - The directory to place the output files in.
#       style - The style of the target.  If it's HTML-based, it's the CSS style.
#
sub New #(name, builder, directory, style)
    {
    my $package = shift;

    # This depends on the order of the parameters matching the order of the constants.
    my $object = [ @_ ];
    bless $object, $package;

    return $object;
    };


# Function: Name
# Returns the target's name.
sub Name
    {  return $_[0]->[NAME];  };

# Function: SetName
# Changes the target's name.
sub SetName #(name)
    {  $_[0]->[NAME] = $_[1];  };

# Function: Builder
# Returns the <NaturalDocs::Builder> sub-object for the target's output format.
sub Builder
    {  return $_[0]->[BUILDER];  };

# Function: Directory
# Returns the directory for the traget's output files.
sub Directory
    {  return $_[0]->[DIRECTORY];  };

# Function: Style
# Returns the target's style, CSS if it's HTML based.  Returns undef otherwise.
sub Style
    {  return $_[0]->[STYLE];  };


1;
