###############################################################################
#
#   Package: NaturalDocs::Topics::Type
#
###############################################################################
#
#   A class storing information about a <TopicType>.
#
###############################################################################

use strict;
use integer;


package NaturalDocs::Topics::Type;

use NaturalDocs::DefineMembers 'NAME',                         'Name()',
                                                 'PLURAL_NAME',             'PluralName()',      'SetPluralName()',
                                                 'INDEX',                        'Index()',              'SetIndex()',
                                                 'AUTO_GROUP',             'AutoGroup()',        'SetAutoGroup()',
                                                 'SCOPE',                       'Scope()',              'SetScope()',
                                                 'PAGE_TITLE_IF_FIRST', 'PageTitleIfFirst()', 'SetPageTitleIfFirst()';

# Dependency: New() depends on the order of these and that there are no parent classes.

use base 'Exporter';
our @EXPORT = ('AUTO_GROUP_YES', 'AUTO_GROUP_NO', 'AUTO_GROUP_FULL_ONLY',
                         'SCOPE_NORMAL', 'SCOPE_START', 'SCOPE_END', 'SCOPE_ALWAYS_GLOBAL');

#
#   Constants: Members
#
#   The object is implemented as a blessed arrayref, with the following constants as its indexes.
#
#   NAME - The topic's name.
#   PLURAL_NAME - The topic's plural name.
#   INDEX - Whether the topic is indexed.
#   AUTO_GROUP - The topic's <AutoGroupType>.
#   SCOPE - The topic's <ScopeType>.
#   PAGE_TITLE_IF_FIRST - Whether the topic becomes the page title if it's first in a file.
#



###############################################################################
# Group: Types


#
#   Constants: AutoGroupType
#
#   The possible values for <AutoGroup()>.
#
#   AUTO_GROUP_NO - There is no auto-grouping on this topic.
#   AUTO_GROUP_YES - There is auto-grouping in basic and in full mode.
#   AUTO_GROUP_FULL_ONLY - There is auto-grouping in full mode only.
#
use constant AUTO_GROUP_NO => 1;
use constant AUTO_GROUP_YES => 2;
use constant AUTO_GROUP_FULL_ONLY => 3;

#
#   Constants: ScopeType
#
#   The possible values for <Scope()>.
#
#   SCOPE_NORMAL - The topic stays in the current scope without affecting it.
#   SCOPE_START - The topic starts a scope.
#   SCOPE_END - The topic ends a scope, returning it to global.
#   SCOPE_ALWAYS_GLOBAL - The topic is always global, but it doesn't affect the current scope.
#
use constant SCOPE_NORMAL => 1;
use constant SCOPE_START => 2;
use constant SCOPE_END => 3;
use constant SCOPE_ALWAYS_GLOBAL => 4;



###############################################################################
# Group: Functions


#
#   Function: New
#
#   Creates and returns a new object.
#
#   Parameters:
#
#       name - The topic name.
#       pluralName - The topic's plural name.
#       index - Whether the topic is indexed.
#       autoGroup - The topic's <AutoGroupType>.
#       scope - The topic's <ScopeType>.
#       pageTitleIfFirst - Whether the topic becomes the page title if it's the first one in a file.
#
sub New #(name, pluralName, index, autoGroup, scope, pageTitleIfFirst)
    {
    my ($self, @params) = @_;

    # Dependency: Depends on the parameter order matching the member order and that there are no parent classes.

    my $object = [ @params ];
    bless $object, $self;

    return $object;
    };


#
#   Functions: Accessors
#
#   Name - Returns the topic name.
#   PluralName - Returns the topic's plural name.
#   SetPluralName - Replaces the topic's plural name.
#   Index - Whether the topic is indexed.
#   SetIndex - Sets whether the topic is indexed.
#   AutoGroup - Returns the topic's <AutoGroupType>.
#   SetAutoGroup - Replaces the topic's <AutoGroupType>.
#   Scope - Returns the topic's <ScopeType>.
#   SetScope - Replaces the topic's <ScopeType>.
#   PageTitleIfFirst - Returns whether the topic becomes the page title if it's first in the file.
#   SetPageTitleIfFirst - Sets whether the topic becomes the page title if it's first in the file.
#


1;
