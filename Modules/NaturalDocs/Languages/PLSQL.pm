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
#   Function: EndOfPrototype
#
#   Microsoft's SQL specifies parameters as shown below.
#
#   > CREATE PROCEDURE Test @as int, @foo int AS ...
#
#   Having a parameter @is or @as is perfectly valid even though those words are also used to end the prototype.  Note any
#   false positives created by this.
#
sub EndOfPrototype #(type, stringRef, falsePositives)
    {
    my ($self, $type, $stringRef) = @_;  # Passed falsePositives is ignored.

    my $falsePositives;

    if ($type == ::TOPIC_FUNCTION())
        {
        $falsePositives = { };

        foreach my $ender (@{$self->FunctionEnders()})
            {
            my $index = 0;

            for (;;)
                {
                $index = index($$stringRef, '@' . $ender, $index);

                if ($index == -1)
                    {  last;  };

                # +1 because the positive will be after the @ symbol.
                $falsePositives->{$index + 1} = 1;
                $index++;
                };
            };

        if (!scalar keys %$falsePositives)
            {  $falsePositives = undef;  };
        };

    return $self->SUPER::EndOfPrototype($type, $stringRef, $falsePositives);
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

    if ($type == ::TOPIC_FUNCTION() && $prototype !~ /\(/ && $prototype =~ /@/)
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
