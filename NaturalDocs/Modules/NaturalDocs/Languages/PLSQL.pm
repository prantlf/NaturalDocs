###############################################################################
#
#   Class: NaturalDocs::Languages::PLSQL
#
###############################################################################
#
#   A subclass to handle the language variations of PL/SQL.
#
###############################################################################

# This file is part of Natural Docs, which is Copyright © 2003-2004 Greg Valure
# Natural Docs is licensed under the GPL

use strict;
use integer;

package NaturalDocs::Languages::PLSQL;

use base 'NaturalDocs::Languages::Simple';


#
#   Function: OnPrototypeEnd
#
#   Microsoft's SQL specifies parameters as shown below.
#
#   > CREATE PROCEDURE Test @as int, @foo int AS ...
#
#   Having a parameter @is or @as is perfectly valid even though those words are also used to end the prototype.  We need to
#   ignore text-based enders preceded by an at sign.  Also note that it does not have parenthesis for parameter lists.  We need to
#   skip all commas if the prototype doesn't have parenthesis but does have @ characters.
#
#   Parameters:
#
#       type - The <TopicType> of the prototype.
#       prototypeRef - A reference to the prototype so far, minus the ender in dispute.
#       ender - The ender symbol.
#
#   Returns:
#
#       ENDER_ACCEPT - The ender is accepted and the prototype is finished.
#       ENDER_IGNORE - The ender is rejected and parsing should continue.  Note that the prototype will be rejected as a whole
#                                  if all enders are ignored before reaching the end of the code.
#       ENDER_ACCEPT_AND_CONTINUE - The ender is accepted so the prototype may stand as is.  However, the prototype might
#                                                          also continue on so continue parsing.  If there is no accepted ender between here and
#                                                          the end of the code this version will be accepted instead.
#       ENDER_REVERT_TO_ACCEPTED - The expedition from ENDER_ACCEPT_AND_CONTINUE failed.  Use the last accepted
#                                                        version and end parsing.
#
sub OnPrototypeEnd #(type, prototypeRef, ender)
    {
    my ($self, $type, $prototypeRef, $ender) = @_;

    if ($ender =~ /^[a-z]+$/i && substr($$prototypeRef, -1) eq '@')
        {  return ::ENDER_IGNORE();  }

    elsif ($type eq ::TOPIC_FUNCTION() && $ender eq ',' &&
            index($$prototypeRef, '@') != -1 && index($$prototypeRef, '(') == -1)
        {  return ::ENDER_IGNORE();  }

    else
        {  return ::ENDER_ACCEPT();  };
    };


#
#   Function: FormatPrototype
#
#   Microsoft's SQL implementation doesn't require parenthesis.  Instead, parameters are specified with the @ symbol as
#   below:
#
#   > CREATE PROCEDURE Test @as int, @foo int AS ...
#
#   If the prototype doesn't have parenthesis but does have @text, it makes sure it is still formatted correctly.
#
sub FormatPrototype #(type, prototype)
    {
    my ($self, $type, $prototype) = @_;

    if ($type eq ::TOPIC_FUNCTION() && $prototype !~ /\(/ && $prototype =~ /@/)
        {
        $prototype =~ tr/\t\n /   /s;
        $prototype =~ s/^ //;
        $prototype =~ s/ $//;

        my $atIndex = index($prototype, '@');

        my $pre = substr($prototype, 0, $atIndex, '');
        $pre =~ s/ $//;

        my $params = [ ];

        while ($prototype =~ /(\@[^\@,]+,?) ?/g)
            {  push @$params, $1;  };

        return ( $pre, ' ', $params, ' ', undef );
        }
    else
        {  return $self->SUPER::FormatPrototype($type, $prototype);  };
    };


1;
