###############################################################################
#
#   Class: NaturalDocs::Project::File
#
###############################################################################
#
#   A simple information class about project files.
#
###############################################################################

# This file is part of Natural Docs, which is Copyright © 2003 Greg Valure
# Natural Docs is licensed under the GPL

use strict;
use integer;

package NaturalDocs::Project::File;



###############################################################################
# Group: Implementation

#
#   Constants: Members
#
#   The class is implemented as a blessed arrayref.  The following constants are used as indexes.
#
#       HAS_CONTENT             - Whether the file contains Natural Docs content or not.
#       LAST_MODIFIED           - The integer timestamp of when the file was last modified.
#       STATUS                       - Status since the last build.  One of the <File Status Constants>.
#       DEFAULT_MENU_TITLE  - The file's default title in the menu.
#

# DEPENDENCY: New() depends on its parameter list being in the same order as these constants.  If the order changes, New()
# needs to be changed.
use constant HAS_CONTENT => 0;
use constant LAST_MODIFIED => 1;
use constant STATUS => 2;
use constant DEFAULT_MENU_TITLE => 3;


###############################################################################
# Group: Functions

#
#   Function: New
#
#   Creates and returns a new file object.
#
#   Parameters:
#
#       hasContent         - Whether the file contains Natural Docs content or not.
#       lastModified         - The integer timestamp of when the file was last modified.
#       status                 - The file's status since the last build.  One of the <File Status Constants>.
#       defaultMenuTitle  - The file's title in the menu.
#
#   Returns:
#
#       A reference to the new object.
#
sub New #(hasContent, lastModified, status, defaultMenuTitle)
    {
    # DEPENDENCY: This function depends on its parameter list being in the same order as the member constants.  If either order
    # changes, this function needs to be changed.

    my $package = shift;

    my $object = [ @_ ];
    bless $object, $package;

    return $object;
    };

# Function: HasContent
# Returns whether the file contains Natural Docs content or not.
sub HasContent
    {  return $_[0]->[HAS_CONTENT];  };

# Function: LastModified
# Returns the integer timestamp of when the file was last modified.
sub LastModified
    {  return $_[0]->[LAST_MODIFIED];  };

# Function: Status
# Returns the status of the file since the last build.  Will be one of the <File Status Constants>.
sub Status
    {  return $_[0]->[STATUS];  };

# Function: DefaultMenuTitle
# Returns the file's default title on the menu.
sub DefaultMenuTitle
    {  return $_[0]->[DEFAULT_MENU_TITLE];  };

# Function: SetHasContent
# Sets whether the file contains Natural Docs content or not.
sub SetHasContent #(hasContent)
    {  $_[0]->[HAS_CONTENT] = $_[1];  };

# Function: SetLastModified
# Sets the file's last modification timestamp.
sub SetLastModified #(lastModified)
    {  $_[0]->[LAST_MODIFIED] = $_[1];  };

# Function: SetStatus
# Sets the file's status since the last build.
sub SetStatus #(status)
    {  $_[0]->[STATUS] = $_[1];  };

# Function: SetDefaultMenuTitle
# Sets the file's default title on the menu.
sub SetDefaultMenuTitle #(menuTitle)
    {  $_[0]->[DEFAULT_MENU_TITLE] = $_[1];  };


1;