###############################################################################
#
#   Package: NaturalDocs::Parser::ParsedTopic
#
###############################################################################
#
#   A class for parsed topics of source files.
#
###############################################################################

# This file is part of Natural Docs, which is Copyright © 2003 Greg Valure
# Natural Docs is licensed under the GPL

use strict;
use integer;

package NaturalDocs::Parser::ParsedTopic;


###############################################################################
# Group: Implementation

#
#   Constants: Members
#
#   The object is a blessed arrayref with the following indexes.
#
#       TYPE           - The type of the section.  Will be one of the <Topic Types>.
#       NAME          - The name of the section.
#       CLASS        - The class of the section, if any.  This applies to Name only.  Will be undef if global.
#       SCOPE        - The scope the section's body appears in.  This may be different from Class.  Will be undef if global.
#       PROTOTYPE - The prototype, if it exists and is applicable.
#       SUMMARY    - The summary, if it exists.
#       BODY          - The body of the section, formatted in <NDMarkup>.  Some sections may not have bodies, and if not, this
#                           will be undef.
#
use constant TYPE => 0;
use constant NAME => 1;
use constant CLASS => 2;
use constant SCOPE => 3;
use constant PROTOTYPE => 4;
use constant SUMMARY => 5;
use constant BODY => 6;
# DEPENDENCY: New() depends on the order in which these are defined.


###############################################################################
# Group: Functions

#
#   Function: New
#
#   Creates a new object.
#
#   Parameters:
#
#       type          - The type of the section.  Will be one of the <Topic Types>.
#       name        - The name of the section.
#       class         - The class of the section's _name_, if any.  Set to undef if global.
#       scope        - The scope the section's _body_ appears in.  This may be different from class.  Set to undef if global.
#       prototype  - If the type is <TOPIC_FUNCTION> or <TOPIC_VARIABLE>, the prototype, if it exists.  Otherwise set to undef.
#       summary  - The summary of the section, if any.
#       body         - The body of the section, formatted in <NDMarkup>.  May be undef, as some sections may not have bodies.
#
#   Returns:
#
#       The new object.
#
sub New #(type, name, class, scope, prototype, summary, body)
    {
    # DEPENDENCY: This depends on the order of the parameter list being the same as the constants.

    my $package = shift;

    my $object = [ @_ ];
    bless $object, $package;

    return $object;
    };


# Function: Type
# Returns the type of the section.  Will be one of <Topic Types>.
sub Type
    {  return $_[0]->[TYPE];  };

# Function: Name
# Returns the name of the section.
sub Name
    {  return $_[0]->[NAME];  };

# Function: Class
# Returns the class of the section.  Applies to <Name()> only.  Will be undef if global.
sub Class
    {  return $_[0]->[CLASS];  };

# Function: Scope
# Returns the scope the section appears in.  Applies to <Body()> only.  Will be undef if global.
sub Scope
    {  return $_[0]->[SCOPE];  };

# Function: Prototype
# Returns the prototype if <Type()> is <TOPIC_FUNCTION> or <TOPIC_VARIABLE> and one is defined.  Will be undef otherwise.
sub Prototype
    {  return $_[0]->[PROTOTYPE];  };

# Function: SetPrototype
# Replaces the function or variable prototype.
sub SetPrototype #(prototype)
    {
    my ($self, $prototype) = @_;
    $self->[PROTOTYPE] = $prototype;
    };

# Function: Summary
# Returns the section summary, if it exists, formatted in <NDMarkup>.
sub Summary
    {  return $_[0]->[SUMMARY];  };

# Function: Body
# Returns the section's body, formatted in <NDMarkup>.  May be undef.
sub Body
    {  return $_[0]->[BODY];  };


1;
