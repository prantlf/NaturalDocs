###############################################################################
#
#   Title: Constants
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
                   'TOPIC_GENERIC_LIST', 'TopicIsList', 'TopicIsListOf',
                   'MENU_TITLE', 'MENU_SUBTITLE', 'MENU_FILE', 'MENU_GROUP', 'MENU_TEXT', 'MENU_LINK', 'MENU_FOOTER',
                   'FILE_NEW', 'FILE_CHANGED', 'FILE_SAME', 'FILE_DOESNTEXIST');

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
#       TOPIC_CLASS_LIST        - A list of classes where it's not worth giving each its own entry.  Will not have scope.
#       TOPIC_FILE_LIST            - A list of files where it's not worth giving each its own entry.
#       TOPIC_FUNCTION_LIST  - A list of functions where it's not worth giving each its own entry.  Will not have prototypes.
#       TOPIC_VARIABLE_LIST   - A list of variables where it's not worth giving each its own entry.  Will not have prototypes.
#       TOPIC_GENERIC_LIST    - A list of generic topics where it's not worth giving each its own entry, such as constants.
#
use constant TOPIC_CLASS => 1;
use constant TOPIC_SECTION => 2;
use constant TOPIC_FILE => 3;
use constant TOPIC_GROUP => 4;
use constant TOPIC_FUNCTION => 5;
use constant TOPIC_VARIABLE => 6;
use constant TOPIC_GENERIC => 7;

use constant TOPIC_LIST_BASE => 100;  # To accomodate for future expansion without changing the actual values.

use constant TOPIC_CLASS_LIST => (TOPIC_CLASS + TOPIC_LIST_BASE);
use constant TOPIC_FILE_LIST => (TOPIC_FILE + TOPIC_LIST_BASE);
use constant TOPIC_FUNCTION_LIST => (TOPIC_FUNCTION + TOPIC_LIST_BASE);
use constant TOPIC_VARIABLE_LIST => (TOPIC_VARIABLE + TOPIC_LIST_BASE);
use constant TOPIC_GENERIC_LIST => (TOPIC_GENERIC + TOPIC_LIST_BASE);


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
#   Constants: Menu Item Types
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
#
use constant MENU_TITLE => 1;
use constant MENU_SUBTITLE => 2;
use constant MENU_FILE => 3;
use constant MENU_GROUP => 4;
use constant MENU_TEXT => 5;
use constant MENU_LINK => 6;
use constant MENU_FOOTER => 7;

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


1;