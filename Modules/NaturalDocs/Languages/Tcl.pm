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
#   bool: pastFirstBrace
#
#   Whether we've past the first brace in a function prototype or not.
#
my $pastFirstBrace;


#
#   Function: OnCode
#
#   This is just overridden to reset <pastFirstBrace>.
#
sub OnCode #(...)
    {
    my ($self, @params) = @_;

    $pastFirstBrace = 0;

    return $self->SUPER::OnCode(@params);
    };


#
#   Function: OnPrototypeEnd
#
#   Tcl's function syntax is shown below.
#
#   > proc [name] { [params] } { [code] }
#
#   The opening brace is one of the prototype enders.  We need to allow the first opening brace because it contains the
#   parameters.
#
#   Also, the parameters may have braces within them.  I've seen one that used { seconds 20 } as a parameter.
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

    if ($type eq ::TOPIC_FUNCTION() && $ender eq '{' && !$pastFirstBrace)
        {
        $pastFirstBrace = 1;
        return ::ENDER_IGNORE();
        }
    else
        {  return ::ENDER_ACCEPT();  };
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

    if ($type eq ::TOPIC_FUNCTION() && $prototype =~ /^([^\{\}]+)\{(.*)\}([^\{\}]*)$/)
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
