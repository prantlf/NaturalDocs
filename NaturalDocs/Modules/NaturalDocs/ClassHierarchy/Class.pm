###############################################################################
#
#   Class: NaturalDocs::ClassHierarchy::Class
#
###############################################################################
#
#   An object that stores information about a class in the hierarchy.  It does not store its name; it assumes that it will be
#   stored in a hashref where the key is the name.
#
#   Topic: Architecture
#
#   This class is designed to handle multiple definitions of classes, even though that shouldn't be typical.  Some language may
#   allow a package to be defined in one file and continued in another.  It's also possible that a class may be predeclared
#   somewhere, or there is an interface/header declaration and a later source definition.
#
#   The end result is that all of these definitions are coalesced into one simply by adding each's parents
#   to the list.  This is why the functions <AddParent()> and <DeleteParent()> return whether they resulted in an actual change
#   to the list of parents.  The answer is not always yes.  The class will handle all of the parent definitions internally.
#
#   However, the same is _not_ true for the children.  Since every language defines the hierarchy via each class declaring its
#   parents, that's where all the internal management is focused.  Doing the same for the children would be redundant and can
#   be avoided if the calling code handles everything correctly.
#
#   *Important:* The calling code is responsible for detecting when <AddParent()> and <DeleteParent()> return true, and
#   adjusting the parent's children list accordingly.  The parent will _not_ keep track of how many times it is declared the parent
#   of the child.
#
#   Note that it's possible for these objects to exist, and even have children, without any definitions defined.  This is because
#   a class may be found to have a parent before that parent has been found in the source.  Also, it's possible that some
#   parents simply won't be in the documentation, such as those inherent to the language or in frameworks not documented
#   with Natural Docs.
#
###############################################################################

# This file is part of Natural Docs, which is Copyright © 2004 Greg Valure
# Natural Docs is licensed under the GPL

use strict;
use integer;

package NaturalDocs::ClassHierarchy::Class;


#
#   Constants: Members
#
#   The class is implemented as a blessed arrayref.  The keys are the constants below.
#
#   DEFINITIONS - An existence hashref of all the files which define this class.  Undef if none.
#   PARENTS - A hashref of parents this class has.  The keys are the names, and the values are existence hashrefs of all the
#                   files that define this class as having the parent.  Undef if none.
#   CHILDREN - An existence hashref of children this class has.  Undef if none.  It does *not* keep track of all the files which
#                     define this relationship.  It is up to <NaturalDocs::ClassHierarchy> to manage this when adding or deleting
#                     the child's parents.
#
use NaturalDocs::DefineMembers 'DEFINITIONS', 'PARENTS', 'CHILDREN';
# Dependency: New() depends on the order of these constants, as well as the class not being derived from any other.


###############################################################################
# Group: Modification Functions


#
#   Function: New
#
#   Creates and returns a new class.
#
sub New
    {
    # Dependency: This function depends on the order of the constants, as well as the class not being derived from any other.
    my ($package, $definitionFile) = @_;

    my $object = [ undef, undef, undef ];
    bless $object, $package;

    return $object;
    };

#
#   Function: AddDefinition
#   Adds a rew file that defines this class.
#
sub AddDefinition #(file)
    {
    my ($self, $file) = @_;

    if (!defined $self->[DEFINITIONS])
        {  $self->[DEFINITIONS] = { };  };

    $self->[DEFINITIONS]->{$file} = 1;
    };

#
#   Function: DeleteDefinition
#   Removes the file definition of this class and returns true if there are no more definitions.  Note that if there are no more
#   definitions, you may still want to keep the object around if <HasChildren()> returns true.
#
sub DeleteDefinition #(file)
    {
    my ($self, $file) = @_;

    if (defined $self->[DEFINITIONS])
        {
        delete $self->[DEFINITIONS]->{$file};

        if (!scalar keys %{$self->[DEFINITIONS]})
            {
            $self->[DEFINITIONS] = undef;
            return 1;
            };
        };

    return undef;
    };

#
#   Function: AddParent
#   Adds a parent definition to the class.  Returns whether this was the first definition of that parent.
#
sub AddParent #(file, parent)
    {
    my ($self, $file, $parent) = @_;

    if (!defined $self->[PARENTS])
        {  $self->[PARENTS] = { };  };

    if (!exists $self->[PARENTS]->{$parent})
        {
        $self->[PARENTS]->{$parent} = { $file => 1 };
        return 1;
        }
    else
        {
        $self->[PARENTS]->{$parent}->{$file} = 1;
        return undef;
        };
    };

#
#   Function: DeleteParent
#   Deletes a parent definition from the class.  Returns if this deleted the last definition of that parent.
#
sub DeleteParent #(file, parent)
    {
    my ($self, $file, $parent) = @_;

    if (defined $self->[PARENTS] && exists $self->[PARENTS]->{$parent})
        {
        delete $self->[PARENTS]->{$parent}->{$file};

        if (!scalar keys %{$self->[PARENTS]->{$parent}})
            {
            delete $self->[PARENTS]->{$parent};

            if (!scalar keys %{$self->[PARENTS]})
                {  $self->[PARENTS] = undef;  };

            return 1;
            };
        };

    return undef;
    };

#
#   Function: AddChild
#   Adds a child to the class.  This only keeps track of if it has the child, not of the definitions.  See <Architecture>.
#
sub AddChild #(child)
    {
    my ($self, $child) = @_;

    if (!defined $self->[CHILDREN])
        {  $self->[CHILDREN] = { };  };

    $self->[CHILDREN]->{$child} = 1;
    };

#
#   Function: DeleteChild
#   Deletes a child from the class.  This only keeps track of if it has the child, not of the definitions.  See <Architecture>.
#
sub DeleteChild #(child)
    {
    my ($self, $child) = @_;

    if (defined $self->[CHILDREN])
        {
        delete $self->[CHILDREN]->{$child};

        if (!scalar keys %{$self->[CHILDREN]})
            {  $self->[CHILDREN] = undef;  };
        };

    return undef;
    };


###############################################################################
# Group: Information Functions


#
#   Function: Parents
#   Returns an array of the parent classes, or an empty array if none.
#
sub Parents
    {
    my ($self) = @_;

    if (defined $self->[PARENTS])
        {  return keys %{$self->[PARENTS]};  }
    else
        {  return ( );  };
    };

#
#   Function: HasParents
#   Returns whether any parent classes are defined.
#
sub HasParents
    {
    my ($self) = @_;
    return defined $self->[PARENTS];
    };

#
#   Function: ParentDefinitions
#   Returns an array of all the files that define the parent as part of the class, or an empty array if none.
#
sub ParentDefinitions #(parent)
    {
    my ($self, $parent) = @_;

    if (defined $self->[PARENTS] && exists $self->[PARENTS]->{$parent})
        {  return keys %{$self->[PARENTS]->{$parent}};  }
    else
        {  return ( );  };
    };

#
#   Function: Children
#   Returns an array of the child classes, or an empty array if none.
#
sub Children
    {
    my ($self) = @_;

    if (defined $self->[CHILDREN])
        {  return keys %{$self->[CHILDREN]};  }
    else
        {  return ( );  };
    };

#
#   Function: HasChildren
#   Returns whether any child classes are defined.
#
sub HasChildren
    {
    my ($self) = @_;
    return defined $self->[CHILDREN];
    };

#
#   Function: Definitions
#   Returns an array of the files that define this class, or an empty array if none.
#
sub Definitions
    {
    my ($self) = @_;

    if (defined $self->[DEFINITIONS])
        {  return keys %{$self->[DEFINITIONS]};  }
    else
        {  return ( );  };
    };

#
#   Function: IsDefinedIn
#   Returns whether the class is defined in the passed file.
#
sub IsDefinedIn #(file)
    {
    my ($self, $file) = @_;

    if (defined $self->[DEFINITIONS])
        {  return exists $self->[DEFINITIONS]->{$file};  }
    else
        {  return 0;  };
    };

#
#   Function: IsDefined
#   Returns whether the class is defined in any files.
#
sub IsDefined
    {
    my ($self) = @_;
    return defined $self->[DEFINITIONS];
    };


1;
