###############################################################################
#
#   Package: NaturalDocs::SymbolTable::SymbolDefinition
#
###############################################################################
#
#   A class representing a symbol definition.  This does not store the definition symbol, class, or file.
#
###############################################################################

# This file is part of Natural Docs, which is Copyright � 2003 Greg Valure
# Natural Docs is licensed under the GPL

use strict;
use integer;

package NaturalDocs::SymbolTable::SymbolDefinition;


###############################################################################
# Group: Implementation

#
#   Constants: Members
#
#   The class is implemented as a blessed arrayref.  The following constants are its members.
#
#       TYPE  - The symbol type.  Will be one of the <Topic Types>.
#       PROTOTYPE  - The symbol's prototype, if applicable.  Will be undef otherwise.
#
use constant TYPE => 0;
use constant PROTOTYPE => 1;
# New depends on the order of the constants.


###############################################################################
# Group: Modification Functions

#
#   Function: New
#
#   Creates and returns a new object.
#
#   Parameters:
#
#       type - The symbol type.  Should be one of the <Topic Types>.
#       prototype  - The symbol prototype, if applicable.  Undef otherwise.
#
sub New #(type, prototype)
    {
    # This depends on the parameter list being the same as the constant order.

    my $object = [ @_ ];
    bless $object;

    return $object;
    };


# Function: SetType
# Changes the type.
sub SetType #(type)
    {
    my ($self, $type) = @_;
    $self->[TYPE] = $type;
    };

# Function: SetPrototype
# Changes the prototype.
sub SetPrototype #(prototype)
    {
    my ($self, $prototype) = @_;
    $self->[PROTOTYPE] = $prototype;
    };


###############################################################################
# Group: Information Functions

#
#   Function: Type
#
#   Returns the definition's type.  Will be one of the <Topic Types>.
#
sub Type
    {  return $_[0]->[TYPE];  };


#
#   Function: Prototype
#
#   Returns the definition's prototype, or undef if it doesn't have one.
#
sub Prototype
    {  return $_[0]->[PROTOTYPE];  };


1;