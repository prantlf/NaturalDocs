###############################################################################
#
#   Class: NaturalDocs::ClassHierarchy::File
#
###############################################################################
#
#   An object that stores information about what hierarchy information is present in a file.  It does not store its name; it assumes
#   that it will be stored in a hashref where the key is the name.
#
###############################################################################

# This file is part of Natural Docs, which is Copyright © 2004 Greg Valure
# Natural Docs is licensed under the GPL

use strict;
use integer;

package NaturalDocs::ClassHierarchy::File;


#
#   Topic: Implementation
#
#   Since there's only one member in the class, and it's a hashref, the class is simply the hashref itself blessed as a class.
#   The keys are the classes that are defined in the file, and the values are existence hashrefs of each class' parents.
#


###############################################################################
# Group: Modification Functions


#
#   Function: New
#
#   Creates and returns a new class.
#
sub New
    {
    my ($package) = @_;

    my $object = { };
    bless $object, $package;

    return $object;
    };

#
#   Function: AddClass
#   Adds a rew class to the file.
#
sub AddClass #(class)
    {
    my ($self, $class) = @_;

    if (!exists $self->{$class})
        {  $self->{$class} = undef;  };
    };

#
#   Function: DeleteClass
#   Deletes a class from the file.
#
sub DeleteClass #(class)
    {
    my ($self, $class) = @_;
    delete $self->{$class};
    };

#
#   Function: AddParent
#   Adds a parent to a class.
#
sub AddParent #(class, parent)
    {
    my ($self, $class, $parent) = @_;

    if (!exists $self->{$class} || !defined $self->{$class})
        {  $self->{$class} = { };  };

    $self->{$class}->{$parent} = 1;
    };

#
#   Function: DeleteParent
#   Deletes a parent from a class.
#
sub DeleteParent #(class, parent)
    {
    my ($self, $class, $parent) = @_;

    if (exists $self->{$class})
        {
        delete $self->{$class}->{$parent};

        if (!scalar keys %{$self->{$class}})
            {  $self->{$class} = undef;  };
        };
    };



###############################################################################
# Group: Information Functions


#
#   Function: Classes
#   Returns an array of the classes that are defined by this file, or an empty array if none.
#
sub Classes
    {
    my ($self) = @_;
    return keys %{$self};
    };

#
#   Function: HasClass
#   Returns whether the file defines the passed class.
#
sub HasClass #(class)
    {
    my ($self, $class) = @_;
    return exists $self->{$class};
    };

#
#   Function: ParentsOf
#   Returns an array of the parents that are defined by the class, or an empty array if none.
#
sub ParentsOf #(class)
    {
    my ($self, $class) = @_;

    if (!exists $self->{$class} || !defined $self->{$class})
        {  return ( );  }
    else
        {  return keys %{$self->{$class}};  };
    };

#
#   Function: HasParent
#   Returns whether the file defines the passed class and parent.
#
sub HasParent #(class, parent)
    {
    my ($self, $class, $parent) = @_;

    if (!$self->HasClass($class))
        {  return undef;  };

    return exists $self->{$class}->{$parent};
    };


1;
