###############################################################################
#
#   Class: NaturalDocs::Languages::Pascal
#
###############################################################################
#
#   A subclass to handle the language variations of Pascal and Delphi.
#
###############################################################################

# This file is part of Natural Docs, which is Copyright © 2003-2004 Greg Valure
# Natural Docs is licensed under the GPL

use strict;
use integer;

package NaturalDocs::Languages::Pascal;

use base 'NaturalDocs::Languages::Simple';


#
#   hash: prototypeDirectives
#
#   An existence hash of all the directives that can appear after a function prototype and will be included.  The keys are the all
#   lowercase keywords.
#
my %prototypeDirectives = ( 'overload' => 1,
                                           'override' => 1,
                                           'virtual' => 1,
                                           'abstract' => 1,
                                           'reintroduce' => 1,
                                           'export' => 1,
                                           'public' => 1,
                                           'interrupt' => 1,
                                           'register' => 1,
                                           'pascal' => 1,
                                           'cdecl' => 1,
                                           'stdcall' => 1,
                                           'popstack' => 1,
                                           'saveregisters' => 1,
                                           'inline' => 1,
                                           'safecall' => 1 );

#
#   hash: longPrototypeDirectives
#
#   An existence hash of all the directives with parameters that can appear after a function prototype and will be included.  The
#   keys are the all lowercase keywords.
#
my %longPrototypeDirectives = ( 'alias' => 1,
                                                 'external' => 1 );

#
#   Function: EndOfPrototype
#
#   Pascal's syntax uses the semicolons and commas parameter style shown below, yet also uses semicolons to end
#   function prototypes.
#
#   > function MyFunction( param1: type; param2, param3: type; param4: type);
#
#   There are also directives after the prototype that should be included.
#
#   > function MyFunction ( param1: type ); virtual; abstract;
#
#   This function accounts for all of this.
#
sub EndOfPrototype #(type, stringRef, falsePositives)
    {
    my ($self, $type, $stringRef) = @_;  # Passed falsePositives is ignored.

    my $falsePositives;
    if ($type == ::TOPIC_FUNCTION())
        {  $falsePositives = $self->FalsePositivesForSemicolonsInParenthesis($stringRef);  };

    my $endOfPrototype = $self->SUPER::EndOfPrototype($type, $stringRef, $falsePositives);

    if ($type == ::TOPIC_FUNCTION() && $endOfPrototype != -1)
        {
        my $pastPrototype = substr($$stringRef, $endOfPrototype);

        use constant NEEDSEMICOLON => 1;
        use constant TRYKEYWORD => 2;
        use constant ACCEPTUNTILSEMICOLON => 3;
        use constant FINISHED => 4;

        my $state = NEEDSEMICOLON;
        my $endOfDirectives;

        while ($state != FINISHED && $pastPrototype =~ /(;|[a-z]+|.)[ \t\n]*/ig)
            {
            if ($state == NEEDSEMICOLON)
                {
                if ($1 eq ';')
                    {
                    $endOfDirectives = $-[1];
                    $state = TRYKEYWORD;
                    }
                else
                    {  $state = FINISHED;  };
                }
            elsif ($state == TRYKEYWORD)
                {
                if (exists $prototypeDirectives{lc($1)})
                    {  $state = NEEDSEMICOLON;  }
                elsif (exists $longPrototypeDirectives{lc($1)})
                    {  $state = ACCEPTUNTILSEMICOLON;  }
                else
                    {  $state = FINISHED;  };
                }
            elsif ($state == ACCEPTUNTILSEMICOLON)
                {
                if ($1 eq ';')
                    {
                    $endOfDirectives = $-[1];
                    $state = TRYKEYWORD;
                    };
                };
            };

        if ($state == FINISHED || $state == TRYKEYWORD)
            {  $endOfPrototype += $endOfDirectives;  }
        else
            {  $endOfPrototype = -1;  };
        };

    return $endOfPrototype;
    };


#
#   Function: FormatPrototype
#
#   Pascal's syntax allows directives after the prototype, separated by semicolons.
#
#   > function MyFunction ( param1: type); virtual;
#
#   The default formatter would put the first semicolon with the post parameter section.  It will format better if it's part of the
#   closing parameter symbol.
#
sub FormatPrototype #(type, prototype)
    {
    my ($self, $type, $prototype) = @_;

    my ($pre, $open, $params, $close, $post) = $self->SUPER::FormatPrototype($type, $prototype);

    if ($type == ::TOPIC_FUNCTION() && $post =~ /^[ \t\n]*;/)
        {
        $close .= '; ';
        $post =~ s/[ \t\n]*;[ \t\n]*//;
        };

    return ($pre, $open, $params, $close, $post);
    };


1;
