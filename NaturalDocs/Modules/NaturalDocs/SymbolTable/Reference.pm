###############################################################################
#
#   Package: NaturalDocs::SymbolTable::Reference
#
###############################################################################
#
#   A class representing a symbol or a potential symbol.
#
###############################################################################

# This file is part of Natural Docs, which is Copyright © 2003-2004 Greg Valure
# Natural Docs is licensed under the GPL

use strict;
use integer;

package NaturalDocs::SymbolTable::Reference;


###############################################################################
# Group: Implementation

#
#   Constants: Members
#
#   The class is implemented as a blessed arrayref.  The following constants are its members.
#
#       DEFINITIONS                        - An existence hashref of the files that define this reference.
#       INTERPRETATIONS                - A hashref of the possible interpretations of this reference.  The keys are the symbol
#                                                    strings, and the values are their scores.
#       CURRENT_INTERPRETATION  - The interpretation currently used as the reference target.  It will be the interpretation with
#                                                     the highest score that is actually defined.  If none are defined, this item will be undef.
#

# DEPENDENCY: New() depends on the order of these constants.  If they change, New() has to be updated.
use constant DEFINITIONS => 0;
use constant INTERPRETATIONS => 1;
use constant CURRENT_INTERPRETATION => 2;


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
        {  die "You can't pass values to NaturalDocs::SymbolTable::Reference->New()\n";  };

    # DEPENDENCY: This code depends on the order of the member constants.
    my $object = [ { }, { }, undef ];
    bless $object, $package;

    return $object;
    };


#
#   Function: AddDefinition
#
#   Adds a reference definition.
#
#   Parameters:
#
#       file   - The file that defines the reference.
#
sub AddDefinition #(file)
    {
    my ($self, $file) = @_;

    $self->[DEFINITIONS]{$file} = 1;
    };


#
#   Function: DeleteDefinition
#
#   Removes a reference definition.
#
#   Parameters:
#
#       file - The definition to delete.
#
sub DeleteDefinition #(file)
    {
    my ($self, $file) = @_;

    delete $self->[DEFINITIONS]{$file};
    };


#
#   Function: AddInterpretation
#
#   Adds a symbol that this reference can be interpreted as.
#
#   Parameters:
#
#       symbolString - The string of the symbol.
#       score            - The score of this interpretation.
#
sub AddInterpretation #(referenceString, score)
    {
    my ($self, $referenceString, $score) = @_;

    $self->[INTERPRETATIONS]{$referenceString} = $score;
    };


#
#   Function: DeleteInterpretation
#
#   Deletes a symbol that this reference can be interpreted as.
#
#   Parameters:
#
#       symbolString - The string of the symbol to delete.
#
sub DeleteInterpretation #(symbolString)
    {
    my ($self, $symbolString) = @_;

    delete $self->[INTERPRETATIONS]{$symbolString};
    };


#
#   Function: DeleteAllInterpretationsButCurrent
#
#   Deletes all interpretations except for the current one.
#
sub DeleteAllInterpretationsButCurrent
    {
    my $self = shift;

    if ($self->HasCurrentInterpretation())
        {
        my $score = $self->CurrentScore();

        # Fastest way to clear a hash except for one item?  Make a new hash with just that item.
        %{$self->[INTERPRETATIONS]} = ( $self->[CURRENT_INTERPRETATION] => $score );
        };
    };


#
#   Function: SetCurrentInterpretation
#
#   Changes the current interpretation.  The new one must already have been added via <AddInterpretation()>.
#
#   Parameters:
#
#       symbolString - The string of the symbol to make the current interpretation.  Can be set to undef to clear it.
#
sub SetCurrentInterpretation #(symbolString)
    {
    my ($self, $symbolString) = @_;

    $self->[CURRENT_INTERPRETATION] = $symbolString;
    };


###############################################################################
# Group: Information Functions


#
#   Function: Definitions
#
#   Returns an array of all the files that define this reference.  If none do, returns an empty array.
#
sub Definitions
    {
    return keys %{$_[0]->[DEFINITIONS]};
    };


#
#   Function: IsDefined
#
#   Returns whether the reference has any definitions or not.
#
sub IsDefined
    {
    return scalar keys %{$_[0]->[DEFINITIONS]};
    };


#
#   Function: IsDefinedIn
#
#   Returns whether the reference is defined in the passed file.
#
sub IsDefinedIn #(file)
    {
    my ($self, $file) = @_;

    return exists $self->[DEFINITIONS]{$file};
    };


#
#   Function: Interpretations
#
#   Returns an array of all the symbol strings that this reference can be interpreted as.  If none, returns an empty array.
#
sub Interpretations
    {
    return keys %{$_[0]->[INTERPRETATIONS]};
    };


#
#   Function: InterpretationsAndScores
#
#   Returns a hash of all the symbol strings that this reference can be interpreted as and their scores.  The keys are the symbol
#   strings, and the values are the scores.  If none, returns an empty hash.
#
sub InterpretationsAndScores
    {
    return %{$_[0]->[INTERPRETATIONS]};
    };


#
#   Function: HasCurrentInterpretation
#
#   Returns whether the reference has a current interpretation or not.
#
sub HasCurrentInterpretation
    {
    return defined $_[0]->[CURRENT_INTERPRETATION];
    };


#
#   Function: CurrentInterpretation
#
#   Returns the symbol string of the current interpretation, or undef if none.
#
sub CurrentInterpretation
    {
    return $_[0]->[CURRENT_INTERPRETATION];
    };


#
#   Function: CurrentScore
#
#   Returns the score of the current interpretation, or undef if none.
#
sub CurrentScore
    {
    my $self = shift;

    if (defined $self->[CURRENT_INTERPRETATION])
        {
        return $self->[INTERPRETATIONS]{ $self->[CURRENT_INTERPRETATION] };
        }
    else
        {  return undef;  };
    };


1;
