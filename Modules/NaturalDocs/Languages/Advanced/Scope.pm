###############################################################################
#
#   Class: NaturalDocs::Languages::Advanced::Scope
#
###############################################################################
#
#   A class used to store a scope level.
#
###############################################################################

# This file is part of Natural Docs, which is Copyright © 2004 Greg Valure
# Natural Docs is licensed under the GPL

use strict;
use integer;

package NaturalDocs::Languages::Advanced::Scope;

#
#   Constants: Implementation
#
#   The object is implemented as a blessed arrayref.  The constants below are used as indexes.
#
#   SYMBOL - The closing symbol of the scope.
#   NAMESPACE - The namespace of the scope, if applicable.
#   PACKAGE - The package or class of the scope.
#   PROTECTION - The protection of the scope, such as public/private/protected.
#
use NaturalDocs::DefineMembers 'SYMBOL', 'NAMESPACE', 'PACKAGE', 'PROTECTION';
# Dependency: New() depends on the order of these constants as well as that there is no inherited members.


#
#   Function: New
#
#   Creates and returns a new object.
#
#   Parameters:
#
#       symbol - The closing symbol of the scope.
#       namespace - The namespace of the scope, if applicable.
#       package - The package or class of the scope.
#       protection - The protecetion of the scope, such as public/private/protected.
#
#       If either namespace, package, or protection are set to undef, it is assumed that it inherits the value of the previous
#       scope on the stack.
#
sub New #(symbol, namespace, package, protection)
    {
    # Dependency: This depends on the order of the parameters matching the constants, and that there are no inherited
    # members.
    my $package = shift;

    my $object = [ @_ ];
    bless $object, $package;

    return $object;
    };


# Function: Symbol
# Returns the closing symbol of the scope.
sub Symbol
    {  return $_[0]->[SYMBOL];  };

# Function: Namespace
# Returns the namespace of the scope, or undef if none.
sub Namespace
    {  return $_[0]->[NAMESPACE];  };

# Function: SetNamespace
# Sets the namespace of the scope.
sub SetNamespace #(namespace)
    {  $_[0]->[NAMESPACE] = $_[1];  };

# Function: Package
# Returns the package or class of the scope, or undef if none.
sub Package
    {  return $_[0]->[PACKAGE];  };

# Function: SetPackage
# Sets the package or class of the scope.
sub SetPackage #(package)
    {  $_[0]->[PACKAGE] = $_[1];  };

# Function: Protection
# Returns the protection of the scope, such as public/private/protected.
sub Protection
    {  return $_[0]->[PROTECTION];  };

# Function: SetProtection
# Sets the protection of the scope.
sub SetProtection #(protection)
    {  $_[0]->[PROTECTION] = $_[1];  };


1;
