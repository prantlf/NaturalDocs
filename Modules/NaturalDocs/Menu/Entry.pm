###############################################################################
#
#   Package: NaturalDocs::Menu::Entry
#
###############################################################################
#
#   A class representing an entry in the menu.
#
###############################################################################

# This file is part of Natural Docs, which is Copyright © 2003 Greg Valure
# Natural Docs is licensed under the GPL

use strict;
use integer;

package NaturalDocs::Menu::Entry;


###############################################################################
# Group: Implementation

#
#   Constants: Members
#
#   The object is implemented as a blessed arrayref with the indexes below.
#
#       TYPE      - The type of entry.  Will be one of the <Menu Item Types>.
#       TITLE     - The title of the entry.  If the type is <MENU_FILE>, undef means use the default menu title.  If the type is
#                      <MENU_LINK>, undef means generate it from the URL itself.
#       TARGET  - The target of the entry.  If the type is <MENU_FILE>, it will be the source file name.  If the type is <MENU_LINK>,
#                       it will be the URL.  If the type is <MENU_GROUP>, it will be an arrayref of <NaturalDocs::Menu::Entry>
#                       objects representing the group's content, or undef if there are none.
#
use constant TYPE => 0;
use constant TITLE => 1;
use constant TARGET => 2;
# DEPENDENCY: New() depends on the order of these constants.


###############################################################################
# Group: Functions

#
#   Function: New
#
#   Creates and returns a new object.
#
#   Parameters:
#
#       type     - The type of the entry.  Must be one of the <Menu Item Types>.
#       title      - The title of the entry.  If the type is <MENU_FILE>, set this to undef to use the default menu title.  If the type is
#                     <MENU_LINK>, set this to undef to generate it from the URL itself.
#       target   - The target of the entry, if applicable.  If the type is <MENU_FILE>, use the source file name.  If the type is
#                     <MENU_LINK>, use the URL.  Otherwise set it to undef.
#
sub New #(type, title, target)
    {
    # DEPENDENCY: This gode depends on the order of the constants.

    my $object = [ @_ ];
    bless $object;

    return $object;
    };


#
#   Function: Type
#
#   Returns the type of the entry.  Will be one of the <Menu Item Types>.
#
sub Type
    {  return $_[0]->[TYPE];  };


#
#   Function: Title
#
#   Returns the title of the entry.
#
#   The object will always return the correct title, so you don't have to worry about it being undef and applying the rules described
#   in <New()>'s parameters.
#
sub Title
    {
    my $self = shift;

    if (defined $self->[TITLE])
        {  return $self->[TITLE];  }
    elsif ($self->Type() == ::MENU_FILE())
        {  return NaturalDocs::Project::DefaultMenuTitleOf($self->Target());  }
    elsif ($self->Type() == ::MENU_LINK())
        {  return $self->Target();  };
    };


#
#   Function: Target
#
#   Returns the target of the entry, if applicable.  If the type is <MENU_FILE>, it returns the source file name.  If the type is
#   <MENU_LINK>, it returns the URL.  Otherwise it returns undef.
#
sub Target
    {
    my $self = shift;

    # Group entries are the only time when target won't be undef when it should be.
    if ($self->Type() == ::MENU_GROUP())
        {  return undef;  }
    else
        {  return $self->[TARGET];  };
    };


#
#   Function: SpecifiesTitle
#
#   Returns whether the <MENU_FILE> or <MENU_LINK> specifies a title.  Note that <Title()> will always return the correct value;
#   this is only for determining the setting.
#
sub SpecifiesTitle
    {
    return ( defined $_[0]->[TITLE] );
    };


###############################################################################
# Group: Group Functions
#
#   These functions all assume that the entry type is <MENU_GROUP>.  Do *not* call them without testing <Type()> first.
#

#
#   Function: GroupContent
#
#   Returns an arrayref of <NaturalDocs::Menu::Entry> objects representing the contents of the group, or undef if it is empty.
#   Do not change the arrayref; use <PushToGroup()> and <PopFromGroup()> instead.
#
sub GroupContent
    {
    return $_[0]->[TARGET];
    };


#
#   Function: GroupIsEmpty
#
#   Returns whether the group is empty.
#
sub GroupIsEmpty
    {  return (!defined $_[0]->[TARGET]);  };


#
#   Function: PushToGroup
#
#   Adds a new <NaturalDocs::Menu::Entry> object to the end of the group content.
#
#   Parameters:
#
#       item    - The <NaturalDocs::Menu::Entry> object to add to the group.
#
sub PushToGroup #(item)
    {
    my ($self, $item) = @_;

    if (!defined $self->[TARGET])
        {  $self->[TARGET] = [ ];  };

    push @{$self->[TARGET]}, $item;
    };


#
#   Function: PopFromGroup
#
#   Removes the last item from the group content.
#
sub PopFromGroup
    {
    my $self = shift;

    if (defined $self->[TARGET])
        {
        pop @{$self->[TARGET]};

        if (!scalar @{$self->[TARGET]})
            {  $self->[TARGET] = undef;  };
        };
    };


1;