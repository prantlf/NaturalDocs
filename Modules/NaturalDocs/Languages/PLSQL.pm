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
#   Oracle 8.1's object oriented extensions allow functions and variables to end with a comma or a closing parenthesis.
#
#   (start code)
#
#   CREATE OR REPLACE TYPE obj_Test AS OBJECT (
#       dummy NUMBER,
#       dummy2 VARCHAR2,
#       MEMBER FUNCTION test( p_lala IN NUMBER ) RETURN NUMBER,
#       MEMBER FUNCTION test_2 RETURN NUMBER,
#       MEMBER PROCEDURE test_3( p_lala IN NUMBER, p_lala2 IN NUMBER, p_lala3 OUT VARCHAR2 )
#   ) NOT FINAL;
#
#   (end code)
#
#   Both symbols are included as enders.  We need to generate false positives for commas that appear within parenthesis, as
#   well as for the closing parenthesis if an opening one is present.
#
#   Microsoft's SQL specifies parameters as shown below.
#
#   > CREATE PROCEDURE Test @as int, @foo int AS ...
#
#   Having a parameter @is or @as is perfectly valid even though those words are also used to end the prototype.  We need to
#   generate false positives created by this.  Also note that it does not have parenthesis for variable lists.  We generate false
#   positives for all commas if the prototype doesn't have parenthesis but does have @ characters.
#
sub EndOfPrototype #(type, stringRef, falsePositives)
    {
    my ($self, $type, $stringRef) = @_;  # Passed falsePositives is ignored.

    my $falsePositives;

    if ($type == ::TOPIC_FUNCTION())
        {
        $falsePositives = { };


        # Generate false positives for @keyword enders.

        foreach my $ender (@{$self->FunctionEnders()})
            {
            if ($ender =~ /^[a-z]/i)
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
            };


        # Generate a false positive for the closing parenthesis if there is an opening one.

        my $openingParenthesis = index($$stringRef, '(');

        if ($openingParenthesis != -1)
            {
            my $closingParenthesis = index($$stringRef, ')', $openingParenthesis);

            if ($closingParenthesis != -1)
                {  $falsePositives->{$closingParenthesis} = 1;  };


            # Also generate false positives for all commas appearing inside the parenthesis.

            my $index = $openingParenthesis;

            for (;;)
                {
                $index = index($$stringRef, ',', $index + 1);

                if ($index == -1 || ($closingParenthesis != -1 && $index > $closingParenthesis))
                    {  last;  };

                $falsePositives->{$index} = 1;
                };
            }

        # If there are no parenthesis and the prototype contains an @ character, all commas are false positives.
        elsif (index($$stringRef, '@') != -1)
            {
            my $index = index($$stringRef, ',');

            while ($index != -1)
                {
                $falsePositives->{$index} = 1;
                $index = index($$stringRef, ',', $index + 1);
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
