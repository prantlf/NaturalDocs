###############################################################################
#
#   Package: NaturalDocs::SymbolTable::File
#
###############################################################################
#
#   A class representing a file, keeping track of what symbols and references are defined in it.
#
###############################################################################

# This file is part of Natural Docs, which is Copyright © 2003 Greg Valure
# Natural Docs is licensed under the GPL

use strict;
use integer;

package NaturalDocs::SymbolTable::File;


###############################################################################
# Group: Implementation

#
#   Constants: Members
#
#   The class is implemented as a blessed arrayref.  The following constants are its members.
#
#       SYMBOLS       - An existence hashref of all the symbols it defines.
#       REFERENCES  - An existence hashref of all the references in the file.
#

# DEPENDENCY: New() depends on the order of these constants.  If they change, New() has to be updated.
use constant SYMBOLS => 0;
use constant REFERENCES => 1;


###############################################################################
# Group: Modification Functions


#
#   Function: New
#
#   Creates and returns a new object.
#
sub New
    {
    my $package = shift;

    # Let's make it safe, since normally you can pass values to New.  Having them just be ignored would be an obscure error.
    if (scalar @_)
        {  die "You can't pass values to NaturalDocs::SymbolTable::File->New()\n";  };

    # DEPENDENCY: This code depends on the order of the member constants.
    my $object = [ { }, { } ];
    bless $object, $package;

    return $object;
    };


#
#   Function: AddSymbol
#
#   Adds a symbol definition.
#
#   Parameters:
#
#       symbolString - The symbol string being added.
#
sub AddSymbol #(symbolString)
    {
    my ($self, $symbolString) = @_;
    $self->[SYMBOLS]{$symbolString} = 1;
    };


#
#   Function: DeleteSymbol
#
#   Removes a symbol definition.
#
#   Parameters:
#
#       symbolString - The symbol to delete.
#
sub DeleteSymbol #(symbolString)
    {
    my ($self, $symbolString) = @_;
    delete $self->[SYMBOLS]{$symbolString};
    };


#
#   Function: AddReference
#
#   Adds a reference definition.
#
#   Parameters:
#
#       referenceString - The reference string being added.
#
sub AddReference #(referenceString)
    {
    my ($self, $referenceString) = @_;
    $self->[REFERENCES]{$referenceString} = 1;
    };


#
#   Function: DeleteReference
#
#   Removes a reference definition.
#
#   Parameters:
#
#       referenceString - The reference to delete.
#
sub DeleteReference #(referenceString)
    {
    my ($self, $referenceString) = @_;
    delete $self->[REFERENCES]{$referenceString};
    };



###############################################################################
# Group: Information Functions


#
#   Function: HasAnything
#
#   Returns whether the file has any symbol or reference definitions at all.
#
sub HasAnything
    {
    return (scalar keys %{$_[0]->[SYMBOLS]} || scalar keys %{$_[0]->[REFERENCES]});
    };

#
#   Function: Symbols
#
#   Returns an array of all the symbols defined in this file.  If none, returns an empty array.
#
sub Symbols
    {
    return keys %{$_[0]->[SYMBOLS]};
    };


#
#   Function: References
#
#   Returns an array of all the references defined in this file.  If none, returns an empty array.
#
sub References
    {
    return keys %{$_[0]->[REFERENCES]};
    };


#
#   Function: DefinesSymbol
#
#   Returns whether the file defines the passed symbol or not.
#
sub DefinesSymbol #(symbolString)
    {
    my ($self, $symbolString) = @_;
    return exists $self->[SYMBOLS]{$symbolString};
    };


#
#   Function: DefinesReference
#
#   Returns whether the file defines the passed reference or not.
#
sub DefinesReference #(referenceString)
    {
    my ($self, $referenceString) = @_;
    return exists $self->[REFERENCES]{$referenceString};
    };

1;
