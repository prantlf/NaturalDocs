###############################################################################
#
#   Class: NaturalDocs::Languages::Tcl
#
###############################################################################
#
#   A subclass to handle the language variations of Tcl.
#
###############################################################################

# This file is part of Natural Docs, which is Copyright © 2003-2004 Greg Valure
# Natural Docs is licensed under the GPL

use strict;
use integer;

package NaturalDocs::Languages::Tcl;

use base 'NaturalDocs::Languages::Simple';


#
#   Function: EndOfPrototype
#
#   Tcl's function syntax is shown below.
#
#   > proc [name] { [params] } { [code] }
#
#   This function creates a false positive to skip the first opening brace.  If there are no parameters, empty braces are usually
#   used, although I don't know if that's a hard requirement.
#
#   Also, the parameters may have braces within them.  I've seen one that used { seconds 20 } as a parameter.
#
sub EndOfPrototype #(type, stringRef, falsePositives)
    {
    my ($self, $type, $stringRef) = @_;  # Passed falsePositives is ignored.

    my $falsePositives;

    if ($type == ::TOPIC_FUNCTION())
        {
        $falsePositives = { };

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

        if (!scalar keys %$falsePositives)
            {  $falsePositives = undef;  };
        };

    return $self->SUPER::EndOfPrototype($type, $stringRef, $falsePositives);
    };


#
#   Function: FormatPrototype
#
#   Tcl specifies parameters as a space-separated list in braces.  It's also possible to nest braces in the parameters.
#
#   > proc name { param1 param2 { seconds 20 } }
#
#   This function makes sure the parameters format correctly.
#
sub FormatPrototype #(type, prototype)
    {
    my ($self, $type, $prototype) = @_;

    if ($type == ::TOPIC_FUNCTION() && $prototype =~ /^([^\{\}]+)\{(.*)\}([^\{\}]*)$/)
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
        {  return $self->SUPER::FormatPrototype($type, $prototype);  }
    };


1;
