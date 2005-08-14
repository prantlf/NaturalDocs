###############################################################################
#
#   Package: NaturalDocs::Parser::JavaDoc
#
###############################################################################
#
#   A package for translating JavaDoc topics or Natural Docs topics in JavaDoc comments into Natural Docs.
#
###############################################################################

# This file is part of Natural Docs, which is Copyright (C) 2003-2005 Greg Valure
# Natural Docs is licensed under the GPL

use strict;
use integer;

package NaturalDocs::Parser::JavaDoc;


##
#   - If the comment starts with a Natural Docs topic line, it leaves it unaltered.
#
#   - If the comment doesn't start with a Natural Docs topic line but has JavaDoc @ tags, it translates it from JavaDoc to Natural
#   Docs and adds a "<format:headerless>" line at the beginning.
#
#   - If the comment doesn't start with a Natural Docs topic line or have JavaDoc @ tags, it just adds a "<format:headerless>" line
#   at the beginning.
#
#   Parameters:
#
#       commentLines - An arrayref of the comment lines.  All tabs should be converted to spaces.  *The original memory will
#                               be changed.*
#
sub TranslateComment #(string[] commentLines)
    {
    my ($self, $commentLines) = @_;

    # Skip to the first line with content.
    while (scalar @$commentLines && $commentLines->[0] =~ /^[ \t]*$/)
        {  shift @$commentLines;  };

    if (!NaturalDocs::Parser::Native->ParseHeaderLine($commentLines->[0]))
        {
        unshift @$commentLines, '<format:headerless>';
        };
    };


package poo;

# Function: Yo
sub Yo { };

1;
