###############################################################################
#
#   Class: NaturalDocs::SymbolTable::IndexElement
#
###############################################################################
#
#   A class representing part of an indexed symbol.
#
###############################################################################

# This file is part of Natural Docs, which is Copyright © 2003 Greg Valure
# Natural Docs is licensed under the GPL

use strict;
use integer;


package NaturalDocs::SymbolTable::IndexElement;


#
#   Topic: How IndexElements Work
#
#   This is a little tricky, so make sure you understand this.  Indexes are sorted by symbol, then class, then file.  If there is only
#   one class for a symbol, or one file definition for a class/symbol, they are added inline to the entry.  However, if there are
#   multiple classes or definitions, the function for it returns an arrayref of IndexElements instead.  Which members are defined
#   and undefined should follow common sense.  For example, if a symbol is defined in multiple classes, the symbol's IndexElement
#   will not define <File()>, <Type()>, or <Prototype()>; those will be defined in child elements.  Similarly, the child elements will
#   not define <Symbol()> since it's redundant.
#
#   Diagrams may be clearer.  If a member isn't listed for an element, it isn't defined.
#
#   A symbol that only has one class and definiton:
#
#   > [Element]
#   > - Symbol
#   > - Class
#   > - File
#   > - Type
#   > - Prototype
#   > - Summary
#
#   A symbol that is defined by multiple classes, each with only one definition:
#   > [Element]
#   > - Symbol
#   > - Class
#   >     [Element]
#   >     - Class
#   >     - File
#   >     - Type
#   >     - Prototype
#   >     - Summary
#   >     [Element]
#   >     - ...
#
#   A symbol that is defined by one class, but has multiple definitions:
#   > [Element]
#   > - Symbol
#   > - Class
#   > - File
#   >    [Element]
#   >    - File
#   >    - Type
#   >    - Protype
#   >    - Summary
#   >    [Element]
#   >    - ...
#
#   A symbol that is defined by multiple classes which have multiple definitions:
#   > [Element]
#   > - Symbol
#   > - Class
#   >    [Element]
#   >    - Class
#   >    - File
#   >      [Element]
#   >      - File
#   >      - Type
#   >      - Prototype
#   >      - Summary
#   >      [Element]
#   >      - ...
#   >    [Element]
#   >    - ...
#
#   Why is it done this way?:
#
#   Because it makes it easier to generate nice indexes since all the splitting and combining is done for you.  If a
#   symbol has only one class, you just want to link to it, you don't want to break out a subindex for just one class.  However, if
#   it has multiple classes, you do want the subindex and to link to each one individually.  Whether <Class()> or <File()> returns
#   an array or not determines whether you need to add a subindex for it.
#


###############################################################################
# Group: Implementation

#
#   Constants: Members
#
#   The class is implemented as a blessed arrayref.  The following constants are its members.
#
#   SYMBOL  - The name of the symbol.
#   CLASS  - The class of the symbol.  Will be that class name, undef for global, or an arrayref of
#                 <NaturalDocs::SymbolTable::IndexElement> objects if multiple classes define the symbol.
#   FILE  - The file the class/symbol is defined in.  Will be the file name or an arrayref of
#             <NaturalDocs::SymbolTable::IndexElements> if multiple files define the class/symbol.
#   TYPE  - The class/symbol/file type.  Will be one of the <Topic Types>.
#   PROTOTYPE  - The class/symbol/file prototype, or undef if not applicable.
#   SUMMARY     - The class/symbol/file summary, or undef if not applicable.
#
use constant SYMBOL => 0;
use constant CLASS => 1;
use constant FILE => 2;
use constant TYPE => 3;
use constant PROTOTYPE => 4;
use constant SUMMARY => 5;
# DEPENDENCY: New() depends on the order of these constants.


###############################################################################
# Group: Modification Functions

#
#   Function: New
#
#   Returns a new object.
#
#   This should only be used for creating an entirely new symbol.  You should *not* pass arrayrefs as class or file parameters
#   if you are calling this externally.  Use <Merge()> instead.
#
#   Parameters:
#
#       symbol  - The symbol's name.
#       class  - The symbol's class, or undef for global.
#       file  - The symbol's definition file.
#       type  - The symbol's type.  One of the <Topic Types>.
#       prototype  - The symbol's prototype, if applicable.
#       summary  - The symbol's summary, if applicable.
#
sub New #(symbol, class, file, type, prototype, summary)
    {
    # DEPENDENCY: This depends on the parameter list being in the same order as the constants.

    my $object = [ @_ ];
    bless $object;

    return $object;
    };


#
#   Function: Merge
#
#   Adds another definition of the same symbol.  Perhaps it has a different class or defining file.
#
#   Parameters:
#
#       class - The symbol's class, or undef for global.
#       file  - The symbol's definition file.
#       type  - The symbol's type.  One of the <Topic Types>.
#       prototype  - The symbol's protoype if applicable.
#       summary  - The symbol's summary if applicable.
#
sub Merge #(class, file, type, prototype, summary)
    {
    my ($self, $class, $file, $type, $prototype, $summary) = @_;

    # If there's only one class...
    if (!ref $self->Class())
        {
        # If there's one class and it's the same as the new one...
        if ($class eq $self->Class())
            {
            $self->MergeFile($file, $type, $prototype, $summary);
            }

        # If there's one class and the new one is different...
        else
            {
            my $selfDefinition = NaturalDocs::SymbolTable::IndexElement::New(undef, $self->Class(), $self->File(),
                                                                                                                $self->Type(), $self->Prototype(),
                                                                                                                $self->Summary());
            my $newDefinition = NaturalDocs::SymbolTable::IndexElement::New(undef, $class, $file, $type, $prototype, $summary);

            $self->[CLASS] = [ $selfDefinition, $newDefinition ];
            $self->[FILE] = undef;
            $self->[TYPE] = undef;
            $self->[PROTOTYPE] = undef;
            $self->[SUMMARY] = undef;
            };
        }

    # If there's more than one class...
    else
        {
        # See if the new class is one of them.
        my $classElement;

        foreach my $testElement (@{$self->Class()})
            {
            if ($testElement->Class() eq $class)
                {
                $classElement = $testElement;
                last;
                };
            };

        # If there's more than one class and the new class is one of them...
        if (defined $classElement)
            {
            $classElement->MergeFile($file, $type, $prototype, $summary);
            }

        # If there's more than one class and the new class is not one of them...
        else
            {
            push @{$self->Class()},
                    NaturalDocs::SymbolTable::IndexElement::New(undef, $class, $file, $type, $prototype, $summary);
            };
        };
    };


#
#   Function: Sort
#
#   Sorts the class and file lists of the symbol.
#
sub Sort
    {
    my $self = shift;

    if (ref $self->File())
        {
        @{$self->[FILE]} = sort { ::StringCompare($a->File(), $b->File()) } @{$self->[FILE]};
        };

    if (ref $self->Class())
        {
        @{$self->[CLASS]} = sort { ::StringCompare($a->Class(), $b->Class()) } @{$self->[CLASS]};

        foreach my $classElement ( @{$self->Class()} )
            {
            if (ref $classElement->File())
                {
                @{$classElement->[FILE]} =
                    sort { ::StringCompare($a->File(), $b->File()) } @{$classElement->[FILE]};
                };
            };
        };
    };


###############################################################################
# Group: Information Functions


#   Function: Symbol
#   Returns the symbol name if applicable.
sub Symbol
    {  return $_[0]->[SYMBOL];  };

#   Function: Class
#   Returns the class of the symbol, if applicable.  Will be undef for global, the name if there's one definiton, or an arrayref of
#   <NaturalDocs::SymbolTable::IndexElement> objects if there are multiple classes that define the symbol.
sub Class
    {  return $_[0]->[CLASS];  };

#   Function: File
#   Returns the file the class/symbol is defined in, if applicable.  Will be the name if there's one definition, or an arrayref of
#   <NaturalDocs::SymbolTable::IndexElement> objects if there are multiple files that define the class/symbol.
sub File
    {  return $_[0]->[FILE];  };

#   Function: Type
#   Returns the type of the class/symbol/file, if applicable.  Will be one of the <Topic Types>.
sub Type
    {  return $_[0]->[TYPE];  };

#   Function: Prototype
#   Returns the prototype of the class/symbol/file, if applicable.
sub Prototype
    {  return $_[0]->[PROTOTYPE];  };

#   Function: Summary
#   Returns the summary of the class/symbol/file, if applicable.
sub Summary
    {  return $_[0]->[SUMMARY];  };


###############################################################################
# Group: Support Functions

#
#   Function: MergeFile
#
#   Adds another definition of the same class/symbol.  Perhaps the file is different.
#
#   Parameters:
#
#       file  - The class/symbol's definition file.
#       type  - The class/symbol's type.  One of the <Topic Types>.
#       prototype  - The class/symbol's protoype if applicable.
#       summary  - The class/symbol's summary if applicable.
#
sub MergeFile #(file, type, prototype, summary)
    {
    my ($self, $file, $type, $prototype, $summary) = @_;

    # If there's only one file...
    if (!ref $self->File())
        {
        # If there's one file and it's the different from the new one...
        if ($file ne $self->File())
            {
            my $selfDefinition = NaturalDocs::SymbolTable::IndexElement::New(undef, undef, $self->File(), $self->Type(),
                                                                                                                $self->Prototype(), $self->Summary());
            my $newDefinition = NaturalDocs::SymbolTable::IndexElement::New(undef, undef, $file, $type, $prototype, $summary);

            $self->[FILE] = [ $selfDefinition, $newDefinition ];
            $self->[TYPE] = undef;
            $self->[PROTOTYPE] = undef;
            $self->[SUMMARY] = undef;
            }

        # If the file was the same, just ignore the duplicate in the index.
        }

    # If there's more than one file...
    else
        {
        # See if the new file is one of them.
        foreach my $testElement (@{$self->File()})
            {
            if ($testElement->File() eq $file)
                {
                # If the new file's already in the index, ignore the duplicate.
                return;
                };
            };

        push @{$self->File()}, NaturalDocs::SymbolTable::IndexElement::New(undef, undef, $file, $type, $prototype, $summary);
        };
    };


1;