###############################################################################
#
#   Class: NaturalDocs::Languages::PLSQL
#
###############################################################################
#
#   A subclass to handle the language variations of PL/SQL.
#
###############################################################################

# This file is part of Natural Docs, which is Copyright © 2003 Greg Valure
# Natural Docs is licensed under the GPL

use strict;
use integer;

package NaturalDocs::Languages::PLSQL;

use base 'NaturalDocs::Languages::Language';


#
#   Topic: Inherits
#
#   <NaturalDocs::Languages::Language>
#


#
#   Function: EndOfFunction
#
#   Returns the index of the end of the function prototype in a string.
#
#   Parameters:
#
#       stringRef  - A reference to the string.
#       falsePositives  - Ignored.  For consistency only.
#
#   Returns:
#
#       The zero-based offset into the string of the end of the prototype, or -1 if the string doesn't contain a symbol from
#       <FunctionEnders()>.
#
#   Language Issue:
#
#       Microsoft's SQL specifies parameters as shown below.
#
#       > CREATE PROCEDURE Test @as int, @foo int AS ...
#
#       Having a parameter @is or @as is perfectly valid even though those words are also used to end the prototype.  Note any
#       false positives created by this.
#
sub EndOfFunction #(stringRef, falsePositives)
    {
    my ($self, $stringRef) = @_;  # Passed falsePositives is ignored.

    my %falsePositives;

    foreach my $ender (@{$self->FunctionEnders()})
        {
        my $index = 0;

        for (;;)
            {
            $index = index($$stringRef, '@' . $ender, $index);

            if ($index == -1)
                {  last;  };

            # +1 because the positive will be after the @ symbol.
            $falsePositives{$index + 1} = 1;
            $index++;
            };
        };

    return $self->SUPER::EndOfFunction($stringRef, \%falsePositives);
    };


#
#   Function: FormatPrototype
#
#   Parses a prototype so that it can be formatted nicely in the output.  By default, this function assumes the parameter list is
#   enclosed in parenthesis and parameters are separated by commas and semicolons.
#
#   Parameters:
#
#       prototype - The text prototype.
#
#   Returns:
#
#       The array ( preParam, opening, params, closing, postParam ).
#
#       pre - The part of the prototype prior to the parameter list.
#       open - The opening symbol to the parameter list, such as parenthesis.  If there is none, it will be a space.
#       params - An arrayref of parameters, one per entry.  Will be undef if none.
#       close - The closing symbol to the parameter list, such as parenthesis.  If there is none, it will be space.
#       post - The part of the prototype after the parameter list, or undef if none.
#
#   Language Issue:
#
#       Microsoft's SQL implementation doesn't require parenthesis.  Instead, parameters are specified with the @ symbol as
#       below:
#
#       > CREATE PROCEDURE Test @as int, @foo int AS ...
#
#       If the prototype doesn't have parenthesis but does have @text, it makes sure it is still formatted correctly.
#
sub FormatPrototype #(prototype)
    {
    my ($self, $prototype) = @_;

    if ($prototype !~ /\(/ && $prototype =~ /@/)
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
        {  return $self->SUPER::FormatPrototype($prototype);  };
    };


1;
