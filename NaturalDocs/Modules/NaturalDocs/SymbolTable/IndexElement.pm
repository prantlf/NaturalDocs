###############################################################################
#
#   Class: NaturalDocs::SymbolTable::IndexElement
#
###############################################################################
#
#   A class representing part of an indexed symbol.
#
###############################################################################

# This file is part of Natural Docs, which is Copyright © 2003-2004 Greg Valure
# Natural Docs is licensed under the GPL

use strict;
use integer;


package NaturalDocs::SymbolTable::IndexElement;


#
#   Topic: How IndexElements Work
#
#   This is a little tricky, so make sure you understand this.  Indexes are sorted by symbol, then packages, then file.  If there is only
#   one package for a symbol, or one file definition for a package/symbol, they are added inline to the entry.  However, if there are
#   multiple packages or files, the function for it returns an arrayref of IndexElements instead.  Which members are defined and
#   undefined should follow common sense.  For example, if a symbol is defined in multiple packages, the symbol's IndexElement
#   will not define <File()>, <Type()>, or <Prototype()>; those will be defined in child elements.  Similarly, the child elements will
#   not define <Symbol()> since it's redundant.
#
#   Diagrams may be clearer.  If a member isn't listed for an element, it isn't defined.
#
#   A symbol that only has one package and file:
#   > [Element]
#   > - Symbol
#   > - Package
#   > - File
#   > - Type
#   > - Prototype
#   > - Summary
#
#   A symbol that is defined by multiple packages, each with only one file:
#   > [Element]
#   > - Symbol
#   > - Package
#   >     [Element]
#   >     - Package
#   >     - File
#   >     - Type
#   >     - Prototype
#   >     - Summary
#   >     [Element]
#   >     - ...
#
#   A symbol that is defined by one package, but has multiple files
#   > [Element]
#   > - Symbol
#   > - Package
#   > - File
#   >    [Element]
#   >    - File
#   >    - Type
#   >    - Protype
#   >    - Summary
#   >    [Element]
#   >    - ...
#
#   A symbol that is defined by multiple packages which have multiple files:
#   > [Element]
#   > - Symbol
#   > - Package
#   >    [Element]
#   >    - Package
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
#   Because it makes it easier to generate nice indexes since all the splitting and combining is done for you.  If a symbol
#   has only one package, you just want to link to it, you don't want to break out a subindex for just one package.  However, if
#   it has multiple package, you do want the subindex and to link to each one individually.  Use <HasMultiplePackages()> and
#   <HasMultipleFiles()> to determine whether you need to add a subindex for it.
#


###############################################################################
# Group: Implementation

#
#   Constants: Members
#
#   The class is implemented as a blessed arrayref.  The following constants are its members.
#
#   SYMBOL  - The <SymbolString> without the package portion.
#   PACKAGE  - The package <SymbolString>.  Will be a package <SymbolString>, undef for global, or an arrayref of
#                      <NaturalDocs::SymbolTable::IndexElement> objects if multiple packages define the symbol.
#   FILE  - The <FileName> the package/symbol is defined in.  Will be the file name or an arrayref of
#             <NaturalDocs::SymbolTable::IndexElements> if multiple files define the package/symbol.
#   TYPE  - The package/symbol/file <TopicType>.
#   PROTOTYPE  - The package/symbol/file prototype, or undef if not applicable.
#   SUMMARY     - The package/symbol/file summary, or undef if not applicable.
#
use constant SYMBOL => 0;
use constant PACKAGE => 1;
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
#   This should only be used for creating an entirely new symbol.  You should *not* pass arrayrefs as package or file parameters
#   if you are calling this externally.  Use <Merge()> instead.
#
#   Parameters:
#
#       symbol  - The <SymbolString> without the package portion.
#       package - The package <SymbolString>, or undef for global.
#       file  - The symbol's definition file.
#       type  - The symbol's <TopicType>.
#       prototype  - The symbol's prototype, if applicable.
#       summary  - The symbol's summary, if applicable.
#
sub New #(symbol, package, file, type, prototype, summary)
    {
    # DEPENDENCY: This depends on the parameter list being in the same order as the constants.

    my $self = shift;

    my $object = [ @_ ];
    bless $object, $self;

    return $object;
    };


#
#   Function: Merge
#
#   Adds another definition of the same symbol.  Perhaps it has a different package or defining file.
#
#   Parameters:
#
#       package - The package <SymbolString>, or undef for global.
#       file  - The symbol's definition file.
#       type  - The symbol's <TopicType>.
#       prototype  - The symbol's protoype if applicable.
#       summary  - The symbol's summary if applicable.
#
sub Merge #(package, file, type, prototype, summary)
    {
    my ($self, $package, $file, $type, $prototype, $summary) = @_;

    # If there's only one package...
    if (!$self->HasMultiplePackages())
        {
        # If there's one package and it's the same as the new one...
        if ($package eq $self->Package())
            {
            $self->MergeFile($file, $type, $prototype, $summary);
            }

        # If there's one package and the new one is different...
        else
            {
            my $selfDefinition = NaturalDocs::SymbolTable::IndexElement->New(undef, $self->Package(), $self->File(),
                                                                                                                 $self->Type(), $self->Prototype(),
                                                                                                                 $self->Summary());
            my $newDefinition = NaturalDocs::SymbolTable::IndexElement->New(undef, $package, $file, $type, $prototype,
                                                                                                                  $summary);

            $self->[PACKAGE] = [ $selfDefinition, $newDefinition ];
            $self->[FILE] = undef;
            $self->[TYPE] = undef;
            $self->[PROTOTYPE] = undef;
            $self->[SUMMARY] = undef;
            };
        }

    # If there's more than one package...
    else
        {
        # See if the new package is one of them.
        my $selfPackages = $self->Package();
        my $matchingPackage;

        foreach my $testPackage (@$selfPackages)
            {
            if ($package eq $testPackage->Package())
                {
                $testPackage->MergeFile($file, $type, $prototype, $summary);;
                return;
                };
            };

        push @{$self->[PACKAGE]},
                NaturalDocs::SymbolTable::IndexElement->New(undef, $package, $file, $type, $prototype, $summary);
        };
    };


#
#   Function: Sort
#
#   Sorts the package and file lists of the symbol.
#
sub Sort
    {
    my $self = shift;

    if ($self->HasMultipleFiles())
        {
        @{$self->[FILE]} = sort { ::StringCompare($a->File(), $b->File()) } @{$self->File()};
        }

    elsif ($self->HasMultiplePackages())
        {
        @{$self->[PACKAGE]} = sort { ::StringCompare( $a->Package(), $b->Package()) } @{$self->[PACKAGE]};

        foreach my $packageElement ( @{$self->[PACKAGE]} )
            {
            if ($packageElement->HasMultipleFiles())
                {  $packageElement->Sort();  };
            };
        };
    };


###############################################################################
# Group: Information Functions


#   Function: Symbol
#   Returns the <SymbolString> without the package portion.
sub Symbol
    {  return $_[0]->[SYMBOL];  };

#
#   Function: Package
#   If <HasMultiplePackages()> is true, returns an arrayref of <NaturalDocs::SymbolTable::IndexElement> objects.  Otherwise
#   returns the package <SymbolString>, or undef if global.
#
sub Package
    {  return $_[0]->[PACKAGE];  };

#   Function: HasMultiplePackages
#   Returns whether <Packages()> is broken out into more elements.
sub HasMultiplePackages
    {  return ref($_[0]->[PACKAGE]);  };

#   Function: File
#   If <HasMultipleFiles()> is true, returns an arrayref of <NaturalDocs::SymbolTable::IndexElement> objects.  Otherwise returns
#   the name of the definition file.
sub File
    {  return $_[0]->[FILE];  };

#   Function: HasMultipleFiles
#   Returns whether <File()> is broken out into more elements.
sub HasMultipleFiles
    {  return ref($_[0]->[FILE]);  };

#   Function: Type
#   Returns the <TopicType> of the package/symbol/file, if applicable.
sub Type
    {  return $_[0]->[TYPE];  };

#   Function: Prototype
#   Returns the prototype of the package/symbol/file, if applicable.
sub Prototype
    {  return $_[0]->[PROTOTYPE];  };

#   Function: Summary
#   Returns the summary of the package/symbol/file, if applicable.
sub Summary
    {  return $_[0]->[SUMMARY];  };


###############################################################################
# Group: Support Functions

#
#   Function: MergeFile
#
#   Adds another definition of the same package/symbol.  Perhaps the file is different.
#
#   Parameters:
#
#       file  - The package/symbol's definition file.
#       type  - The package/symbol's <TopicType>.
#       prototype  - The package/symbol's protoype if applicable.
#       summary  - The package/symbol's summary if applicable.
#
sub MergeFile #(file, type, prototype, summary)
    {
    my ($self, $file, $type, $prototype, $summary) = @_;

    # If there's only one file...
    if (!$self->HasMultipleFiles())
        {
        # If there's one file and it's the different from the new one...
        if ($file ne $self->File())
            {
            my $selfDefinition = NaturalDocs::SymbolTable::IndexElement->New(undef, undef, $self->File(), $self->Type(),
                                                                                                                $self->Prototype(), $self->Summary());
            my $newDefinition = NaturalDocs::SymbolTable::IndexElement->New(undef, undef, $file, $type, $prototype, $summary);

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
        my $files = $self->File();

        foreach my $testElement (@$files)
            {
            if ($testElement->File() eq $file)
                {
                # If the new file's already in the index, ignore the duplicate.
                return;
                };
            };

        push @{$self->[FILE]}, NaturalDocs::SymbolTable::IndexElement->New(undef, undef, $file, $type, $prototype, $summary);
        };
    };


1;
