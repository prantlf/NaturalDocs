###############################################################################
#
#   Title: NaturalDocs::Constants
#
###############################################################################
#
#   Constants that are used throughout the script.  All are exported by default.
#
###############################################################################

# This file is part of Natural Docs, which is Copyright © 2003 Greg Valure
# Natural Docs is licensed under the GPL

use strict;
use integer;

package NaturalDocs::Constants;

use vars qw(@EXPORT @ISA);
require Exporter;
@ISA = qw(Exporter);

@EXPORT = ('TOPIC_CLASS', 'TOPIC_SECTION', 'TOPIC_FILE', 'TOPIC_GROUP', 'TOPIC_FUNCTION', 'TOPIC_VARIABLE',
                   'TOPIC_GENERIC', 'TOPIC_CLASS_LIST', 'TOPIC_FILE_LIST', 'TOPIC_FUNCTION_LIST', 'TOPIC_VARIABLE_LIST',
                   'TOPIC_GENERIC_LIST', 'TopicIsList', 'TopicIsListOf', 'TOPIC_TYPE', 'TOPIC_TYPE_LIST', 'TOPIC_CONSTANT',
                   'TOPIC_CONSTANT_LIST',

                   'MENU_TITLE', 'MENU_SUBTITLE', 'MENU_FILE', 'MENU_GROUP', 'MENU_TEXT', 'MENU_LINK', 'MENU_FOOTER',
                   'MENU_INDEX', 'MENU_FORMAT', 'MENU_ENDOFORIGINAL',

                   'MENU_FILE_NOAUTOTITLE', 'MENU_GROUP_UPDATETITLES', 'MENU_GROUP_UPDATESTRUCTURE',
                   'MENU_GROUP_UPDATEORDER', 'MENU_GROUP_HASENDOFORIGINAL',
                   'MENU_GROUP_UNSORTED', 'MENU_GROUP_FILESSORTED',
                   'MENU_GROUP_FILESANDGROUPSSORTED', 'MENU_GROUP_EVERYTHINGSORTED',
                   'MENU_GROUP_ISINDEXGROUP',

                   'FILE_NEW', 'FILE_CHANGED', 'FILE_SAME', 'FILE_DOESNTEXIST',

                   'BINARY_FORMAT');

#
#   Note: Assumptions
#
#   No constant here will ever be zero.
#

#
#   Constants: Topic Types
#
#   Constants representing all the types of Natural Docs sections.
#
#       TOPIC_CLASS      - A class.  All topics until the next class or section become its members.
#       TOPIC_SECTION  - A main section of code or text.  Formats like a class but doesn't provide scope.  Also ends the
#                                    scope of a class.
#       TOPIC_FILE          - A file.  Is always referenced as a global, but does not end a class scope.
#       TOPIC_GROUP      - A subdivider for long lists.
#       TOPIC_FUNCTION - A function.  The code immediately afterwards will be used as the prototype if it matches the name.
#       TOPIC_VARIABLE  - A variable.  The code immediately afterwards will be used as the prototype if it matches the name.
#       TOPIC_GENERIC   - A generic topic.
#
#       TOPIC_CONSTANT - A constant.  Same as generic, but distinguished for indexing.
#       TOPIC_TYPE          - A type.  Same as generic, but distinguished for indexing.
#
#       TOPIC_CLASS_LIST        - A list of classes.  Will not have scope.
#       TOPIC_FILE_LIST            - A list of files.
#       TOPIC_FUNCTION_LIST  - A list of functions.  Will not have prototypes.
#       TOPIC_VARIABLE_LIST   - A list of variables.  Will not have prototypes.
#       TOPIC_GENERIC_LIST    - A list of generic topics.
#
#       TOPIC_CONSTANT_LIST - A list of constants.
#       TOPIC_TYPE_LIST - A list of types.
#
#   Dependency:
#
#       <NaturalDocs.m> depends on these values all being able to fint into a UInt8, i.e. <= 255.
#
use constant TOPIC_CLASS => 1;
use constant TOPIC_SECTION => 2;
use constant TOPIC_FILE => 3;
use constant TOPIC_GROUP => 4;
use constant TOPIC_FUNCTION => 5;
use constant TOPIC_VARIABLE => 6;
use constant TOPIC_GENERIC => 7;
use constant TOPIC_TYPE => 8;
use constant TOPIC_CONSTANT => 9;

use constant TOPIC_LIST_BASE => 100;  # To accomodate for future expansion without changing the actual values.

use constant TOPIC_CLASS_LIST => (TOPIC_CLASS + TOPIC_LIST_BASE);
use constant TOPIC_FILE_LIST => (TOPIC_FILE + TOPIC_LIST_BASE);
use constant TOPIC_FUNCTION_LIST => (TOPIC_FUNCTION + TOPIC_LIST_BASE);
use constant TOPIC_VARIABLE_LIST => (TOPIC_VARIABLE + TOPIC_LIST_BASE);
use constant TOPIC_GENERIC_LIST => (TOPIC_GENERIC + TOPIC_LIST_BASE);
use constant TOPIC_TYPE_LIST => (TOPIC_TYPE + TOPIC_LIST_BASE);
use constant TOPIC_CONSTANT_LIST => (TOPIC_CONSTANT + TOPIC_LIST_BASE);


#
#   Function: TopicIsList
#
#   Returns whether the topic is a list topic.
#
sub TopicIsList #(topic)
    {
    return ($_[0] >= TOPIC_LIST_BASE);
    };

#
#   Function: TopicIsListOf
#
#   Returns what type the list topic is a list of.  Assumes the topic is a list topic.
#
sub TopicIsListOf #(topic)
    {
    return ($_[0] - TOPIC_LIST_BASE);
    };



#
#   Constants: Menu Entry Types
#
#   Constants representing all the types of sections that can appear in the menu file.
#
#       MENU_TITLE         - The title of the menu.
#       MENU_SUBTITLE   - The sub-title of the menu.
#       MENU_FILE           - A source file, relative to the source directory.
#       MENU_GROUP       - A group.
#       MENU_TEXT          - Arbitrary text.
#       MENU_LINK           - A web link.
#       MENU_FOOTER      - Footer text.
#       MENU_INDEX        - An index.
#       MENU_FORMAT     - The version of Natural Docs the menu file was generated with.
#       MENU_ENDOFORIGINAL - A dummy entry that marks where the original group content ends.  This is used when automatically
#                                           changing the groups so that the alphabetization or lack thereof can be detected without being
#                                           affected by new entries tacked on to the end.
#
#   Dependency:
#
#       <NaturalDocs.m> depends on these values all being able to fit into a UInt8, i.e. <= 255.
#
use constant MENU_TITLE => 1;
use constant MENU_SUBTITLE => 2;
use constant MENU_FILE => 3;
use constant MENU_GROUP => 4;
use constant MENU_TEXT => 5;
use constant MENU_LINK => 6;
use constant MENU_FOOTER => 7;
use constant MENU_INDEX => 8;
use constant MENU_FORMAT => 9;
use constant MENU_ENDOFORIGINAL => 10;


#
#   Constants: Menu Entry Flags
#
#   The various flags that can apply to a menu entry.  You cannot mix flags of different types, since they may overlap.
#
#   File Flags:
#
#       MENU_FILE_NOAUTOTITLE - Whether the file is auto-titled or not.
#
#   Group Flags:
#
#       MENU_GROUP_UPDATETITLES - The group should have its auto-titles regenerated.
#       MENU_GROUP_UPDATESTRUCTURE - The group should be checked for structural changes, such as being removed or being
#                                                             split into subgroups.
#       MENU_GROUP_UPDATEORDER - The group should be resorted.
#
#       MENU_GROUP_HASENDOFORIGINAL - Whether the group contains a dummy <MENU_ENDOFORIGINAL> entry.
#       MENU_GROUP_ISINDEXGROUP - Whether the group is used primarily for <MENU_INDEX> entries.  <MENU_TEXT> entries
#                                                       are tolerated.
#
#       MENU_GROUP_UNSORTED - The group's contents are not sorted.
#       MENU_GROUP_FILESSORTED - The group's files are sorted alphabetically.
#       MENU_GROUP_FILESANDGROUPSSORTED - The group's files and sub-groups are sorted alphabetically.
#       MENU_GROUP_EVERYTHINGSORTED - All entries in the group are sorted alphabetically.
#
use constant MENU_FILE_NOAUTOTITLE => 0x0001;

use constant MENU_GROUP_UPDATETITLES => 0x0001;
use constant MENU_GROUP_UPDATESTRUCTURE => 0x0002;
use constant MENU_GROUP_UPDATEORDER => 0x0004;
use constant MENU_GROUP_HASENDOFORIGINAL => 0x0008;

# This could really be a two-bit field instead of four flags, but it's not worth the effort since it's only used internally.
use constant MENU_GROUP_UNSORTED => 0x0010;
use constant MENU_GROUP_FILESSORTED => 0x0020;
use constant MENU_GROUP_FILESANDGROUPSSORTED => 0x0040;
use constant MENU_GROUP_EVERYTHINGSORTED => 0x0080;

use constant MENU_GROUP_ISINDEXGROUP => 0x0100;


#
#   Constants: File Status Constants
#
#       FILE_NEW                - The file has been added since the last run.
#       FILE_CHANGED        - The file has been modified since the last run.
#       FILE_SAME               - The file hasn't been modified since the last run.
#       FILE_DOESNTEXIST  - The file doesn't exist, or was deleted.
#
use constant FILE_NEW => 1;
use constant FILE_CHANGED => 2;
use constant FILE_SAME => 3;
use constant FILE_DOESNTEXIST => 4;

#
#   Constant: BINARY_FORMAT
#
#   An 8-bit constant that's used as the first byte of binary data files.  This is used so that you can easily distinguish between
#   binary and old-style text data files.  It's not a character that would appear in plain text files.
#
use constant BINARY_FORMAT => pack('C', 0x06);
# Which is ACK or acknowledge in ASCII.  Is the cool spade character in DOS displays.

1;
