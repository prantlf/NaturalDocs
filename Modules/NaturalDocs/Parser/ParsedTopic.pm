###############################################################################
#
#   Package: NaturalDocs::Parser::ParsedTopic
#
###############################################################################
#
#   A class for parsed topics of source files.
#
###############################################################################

# This file is part of Natural Docs, which is Copyright © 2003-2004 Greg Valure
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
#       TYPE           - The type of the topic.  Will be one of the <Topic Types>.
#       NAME          - The name of the topic.
#       CLASS        - The class of the topic, if any.  This applies to Name only.  Will be undef if global.
#       SCOPE        - The scope the topic's body appears in.  This may be different from Class.  Will be undef if global.
#       PROTOTYPE - The prototype, if it exists and is applicable.
#       SUMMARY    - The summary, if it exists.
#       BODY          - The body of the topic, formatted in <NDMarkup>.  Some topics may not have bodies, and if not, this
#                           will be undef.
#       LINE_NUMBER  - The line number the topic appears at in the file.
#
use NaturalDocs::DefineMembers 'TYPE', 'NAME', 'CLASS', 'SCOPE', 'PROTOTYPE', 'SUMMARY', 'BODY', 'LINE_NUMBER';
# DEPENDENCY: New() depends on the order of these constants, and that this class is not inheriting any members.


###############################################################################
# Group: Functions

#
#   Function: New
#
#   Creates a new object.
#
#   Parameters:
#
#       type          - The type of the topic.  Will be one of the <Topic Types>.
#       name        - The name of the topic.
#       class         - The class of the topic's _name_, if any.  Set to undef if global.
#       scope        - The scope the topic's _body_ appears in.  This may be different from class.  Set to undef if global.
#       prototype  - If the type is <TOPIC_FUNCTION> or <TOPIC_VARIABLE>, the prototype, if it exists.  Otherwise set to undef.
#       summary  - The summary of the topic, if any.
#       body         - The body of the topic, formatted in <NDMarkup>.  May be undef, as some topics may not have bodies.
#       lineNumber - The line number the topic appears at in the file.
#
#   Returns:
#
#       The new object.
#
sub New #(type, name, class, scope, prototype, summary, body, lineNumber)
    {
    # DEPENDENCY: This depends on the order of the parameter list being the same as the constants, and that there are no
    # members inherited from a base class.

    my $package = shift;

    my $object = [ @_ ];
    bless $object, $package;

    return $object;
    };


# Function: Type
# Returns the type of the topic.  Will be one of <Topic Types>.
sub Type
    {  return $_[0]->[TYPE];  };

# Function: Name
# Returns the name of the topic.
sub Name
    {  return $_[0]->[NAME];  };

# Function: Class
# Returns the class of the topic.  Applies to <Name()> only.  Will be undef if global.
sub Class
    {  return $_[0]->[CLASS];  };

# Function: Scope
# Returns the scope the topic appears in.  Applies to <Body()> only.  Will be undef if global.
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
# Returns the topic summary, if it exists, formatted in <NDMarkup>.
sub Summary
    {  return $_[0]->[SUMMARY];  };

# Function: Body
# Returns the topic's body, formatted in <NDMarkup>.  May be undef.
sub Body
    {  return $_[0]->[BODY];  };

# Function: SetBody
# Replaces the topic's body, formatted in <NDMarkup>.  May be undef.
sub SetBody #(body)
    {
    my ($self, $body) = @_;
    $self->[BODY] = $body;
    };

# Function: LineNumber
# Returns the line the topic appears at in the file.
sub LineNumber
    {  return $_[0]->[LINE_NUMBER];  };


1;
