###############################################################################
#
#   Class: NaturalDocs::Languages::Tcl
#
###############################################################################
#
#   A subclass to handle the language variations of Tcl.
#
###############################################################################

# This file is part of Natural Docs, which is Copyright © 2003 Greg Valure
# Natural Docs is licensed under the GPL

use strict;
use integer;

package NaturalDocs::Languages::Tcl;

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
#       Tcl's function syntax is shown below.
#
#       > proc [name] { [params] } { [code] }
#
#       This function creates a false positive to skip the first opening brace.  If there are no parameters, empty braces are usually
#       used, although I don't know if that's a hard requirement.
#
#       Also, the parameters may have braces within them.  I've seen one that used { seconds 20 } as a parameter.
#
sub EndOfFunction #(stringRef, falsePositives)
    {
    my ($self, $stringRef) = @_;  # Passed falsePositives is ignored.

    my $falsePositives = { };

    my $level = 0;
    my $stringIndex = 0;

    while ($$stringRef =~ /(\{|\}|[^\{\}]+)/g)
        {
        my $segment = $1;

        if ($segment eq '{')
            {
            $level++;
            $falsePositives->{$stringIndex} = 1;
            $stringIndex++;
            }
        elsif ($segment eq '}')
            {
            # End if we got out of the first top level brace group we were in.
            if ($level == 1)
                {  last;  };

            $level--;;
            $stringIndex--;
            }
        else
            {
            $stringIndex += length($segment);
            };
        };

    return $self->SUPER::EndOfFunction($stringRef, $falsePositives);
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
#       Tcl specifies parameters as a space-separated list in braces.  It's also possible to nest braces in the parameters.
#
#       > proc name { param1 param2 { seconds 20 } }
#
#       This function makes sure the parameters format correctly.
#
sub FormatPrototype #(prototype)
    {
    my ($self, $prototype) = @_;

    if ($prototype =~ /^([^\{\}]+)\{(.*)\}([^\{\}]*)$/)
        {
        my ($pre, $paramString, $post) = ($1, $2, $3);

        $paramString =~ tr/\t /  /s;
        $paramString =~ s/^ //;
        $paramString =~ s/ $//;

        my $params = [ ];

        my $nest = 0;

        while ($paramString =~ /(\{|\}|\ |[^\{\}\ ]+)/g)
            {
            my $segment = $1;

            if ($segment eq '{')
                {
                if ($nest > 0)
                    {  $params->[-1] .= '{';  }
                else
                    {  push @$params, '{';  };

                $nest++;
                }
            elsif ($segment eq '}')
                {
                if ($nest > 0)
                    {  $nest--;  };

                $params->[-1] .= '}';
                }
            elsif ($segment eq ' ')
                {
                if ($nest > 0)
                    {  $params->[-1] .= ' ';  };
                }
            else
                {
                if ($nest > 0)
                    {  $params->[-1] .= $segment;  }
                else
                    {  push @$params, $segment;  };
                };
            };

        return ( $pre, ' {', $params, '} ', $post );
        }

    else
        {  return $self->SUPER::FormatPrototype($prototype);  }
    };


1;