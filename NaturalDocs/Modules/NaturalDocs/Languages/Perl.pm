###############################################################################
#
#   Class: NaturalDocs::Languages::Perl
#
###############################################################################
#
#   A subclass to handle the language variations of Perl.
#
###############################################################################

# This file is part of Natural Docs, which is Copyright © 2003-2004 Greg Valure
# Natural Docs is licensed under the GPL

use strict;
use integer;

package NaturalDocs::Languages::Perl;


#
#   Topic: Inherits
#
#   <NaturalDocs::Languages::Advanced>
#
use base 'NaturalDocs::Languages::Advanced';


###############################################################################
# Group: Information Functions


# Function: Name
# Returns the language's name.
sub Name
    {  return 'Perl';  };

# Function: Extensions
# Returns an arrayref of the extensions of the language's files.
sub Extensions
    {  return [ 'pm', 'pl' ];  };

# Function: ShebangStrings
# Returns an arrayref of the strings that can appear in the language's shebang string.
sub ShebangStrings
    {  return [ 'perl' ];  };



###############################################################################
# Group: Interface Functions


#
#   Function: ParseFile
#
#   Parses the passed source file, sending comments acceptable for documentation to <NaturalDocs::Parser->OnComment()>.
#
#   Parameters:
#
#       sourceFile - The name of the source file to parse.
#       topicList - A reference to the list of <NaturalDocs::Parser::ParsedTopics> being built by the file.
#
sub ParseFile #(sourceFile, topicsList)
    {
    my ($self, $sourceFile, $topicsList) = @_;

    $self->ParseForCommentsAndTokens($sourceFile, [ '#' ], undef, undef);

    my $tokens = $self->Tokens();
    my $index = 0;
    my $lineNumber = 1;

    while ($index < scalar @$tokens)
        {
        if ($self->TryToSkipWhitespace(\$index, \$lineNumber) ||
            $self->TryToGetPackage(\$index, \$lineNumber) ||
            $self->TryToGetFunction(\$index, \$lineNumber) ||
            $self->TryToGetVariable(\$index, \$lineNumber) )
            {
            # The functions above will handle everything.
            }

        elsif ($tokens->[$index] eq '{')
            {
            $self->StartScope('}', $lineNumber, undef, undef, undef);
            $index++;
            }

        elsif ($tokens->[$index] eq '}')
            {
            if ($self->ScopeSymbol() eq '}')
                {  $self->EndScope($lineNumber);  };

            $index++;
            }

        elsif (lc($tokens->[$index]) eq 'eval')
            {
            # We want to skip the token in this case instead of letting it fall to SkipRestOfStatement.  This allows evals with braces
            # to be treated like normal floating braces.
            $index++;
            }

        else
            {
            $self->SkipRestOfStatement(\$index, \$lineNumber);
            };
        };


    # Don't need to keep these around.
    $self->ClearTokens();

    $self->HandleAutoTopics($topicsList);
    };


#
#   Function: MakeSortableSymbol
#
#   Perl's variables start with symbols: $ for scalars, @ for arrays, and % for hashes.  This function strips them
#   off for sorting.
#
sub MakeSortableSymbol #(name, type)
    {
    my ($self, $name, $type) = @_;

    if ($type == ::TOPIC_VARIABLE())
        {
        $name =~ s/^[\$\@\%]//;
        };

    return $name;
    };



###############################################################################
# Group: Statement Parsing Functions
# All functions here assume that the current position is at the beginning of a statement.
#
# Note for developers: I am well aware that the code in these functions do not check if we're past the end of the tokens as
# often as it should.  We're making use of the fact that Perl will always return undef in these cases to keep the code simpler.


#
#   Function: TryToGetPackage
#
#   Determines whether the position is at a package declaration statement, and if so, generates a topic for it, skips it, and
#   returns true.
#
sub TryToGetPackage #(indexRef, lineNumberRef)
    {
    my ($self, $indexRef, $lineNumberRef) = @_;
    my $tokens = $self->Tokens();

    if (lc($tokens->[$$indexRef]) eq 'package')
        {
        my $index = $$indexRef + 1;
        my $lineNumber = $$lineNumberRef;

        if (!$self->TryToSkipWhitespace(\$index, \$lineNumber))
            {  return undef;  };

        my $name;

        while ($tokens->[$index] =~ /^[a-z_\:]/i)
            {
            $name .= $tokens->[$index];
            $index++;
            };

        if (!defined $name)
            {  return undef;  };

        $self->AddAutoTopic(NaturalDocs::Parser::ParsedTopic->New(::TOPIC_CLASS(), $name,
                                                                                                   undef, $name,
                                                                                                   undef,
                                                                                                   undef, undef, $$lineNumberRef));
        $self->SetPackage($name, $$lineNumberRef);

        $$indexRef = $index;
        $$lineNumberRef = $lineNumber;
        $self->SkipRestOfStatement($indexRef, $lineNumberRef);

        return 1;
        };

    return undef;
    };


#
#   Function: TryToGetFunction
#
#   Determines whether the position is at a function declaration statement, and if so, generates a topic for it, skips it, and
#   returns true.
#
sub TryToGetFunction #(indexRef, lineNumberRef)
    {
    my ($self, $indexRef, $lineNumberRef) = @_;
    my $tokens = $self->Tokens();

    if ( lc($tokens->[$$indexRef]) eq 'sub')
        {
        my $prototypeStart = $$indexRef;
        my $prototypeStartLine = $$lineNumberRef;
        my $prototypeEnd = $$indexRef + 1;
        my $prototypeEndLine = $$lineNumberRef;

        if ( !$self->TryToSkipWhitespace(\$prototypeEnd, \$prototypeEndLine) ||
             $tokens->[$prototypeEnd] !~ /^[a-z_]/i )
            {  return undef;  };

        my $name = $tokens->[$prototypeEnd];
        $prototypeEnd++;

        # We parsed 'sub [name]'.  Now keep going until we find a semicolon or a brace.

        for (;;)
            {
            if ($prototypeEnd >= scalar @$tokens)
                {  return undef;  }

            # End if we find a semicolon, since it means we found a predeclaration rather than an actual function.
            elsif ($tokens->[$prototypeEnd] eq ';')
                {  return undef;  }

            elsif ($tokens->[$prototypeEnd] eq '{')
                {
                # Found it!

                $self->AddAutoTopic(NaturalDocs::Parser::ParsedTopic->New(::TOPIC_FUNCTION(), $name,
                                                                                                          $self->CurrentScope(), $self->CurrentScope(),
                                                                                                          $self->CreateString($prototypeStart, $prototypeEnd),
                                                                                                          undef, undef, $prototypeStartLine));

                $$indexRef = $prototypeEnd;
                $$lineNumberRef = $prototypeEndLine;

                $self->SkipRestOfStatement($indexRef, $lineNumberRef);

                return 1;
                }

            else
                {  $self->GenericSkip(\$prototypeEnd, \$prototypeEndLine);  };
            };
        }
    else
        {  return undef;  };
    };


#
#   Function: TryToGetVariable
#
#   Determines if the position is at a variable declaration statement, and if so, generates a topic for it, skips it, and returns
#   true.
#
sub TryToGetVariable #(indexRef, lineNumberRef)
    {
    my ($self, $indexRef, $lineNumberRef) = @_;
    my $tokens = $self->Tokens();

    my $firstToken = lc( $tokens->[$$indexRef] );

    if ($firstToken eq 'my' || $firstToken eq 'our' || $firstToken eq 'local')
        {
        my $prototypeStart = $$indexRef;
        my $prototypeStartLine = $$lineNumberRef;
        my $prototypeEnd = $$indexRef + 1;
        my $prototypeEndLine = $$lineNumberRef;

        if (!$self->TryToSkipWhitespace(\$prototypeEnd, \$prototypeEndLine))
            {  return undef;  };


        # Get the type if present.

        my $type;

        if ($tokens->[$prototypeEnd] =~ /^[a-z\:]/i)
            {
            do
                {
                $type .= $tokens->[$prototypeEnd];
                $prototypeEnd++;
                }
            while ($tokens->[$prototypeEnd] =~ /^[a-z\:]/i);

            if (!$self->TryToSkipWhitespace(\$prototypeEnd, \$prototypeEndLine))
                {  return undef;  };
            };


        # Get the name, or possibly names.

        if ($tokens->[$prototypeEnd] eq '(')
            {
            # If there's multiple variables, we'll need to build a custom prototype for each one.  $firstToken already has the
            # declaring word.  We're going to store each name in @names, and we're going to use $prototypeStart and
            # $prototypeEnd to capture any properties appearing after the list.

            my $name;
            my @names;

            $prototypeStart = $prototypeEnd + 1;
            $prototypeStartLine = $prototypeEndLine;

            for (;;)
                {
                $self->TryToSkipWhitespace(\$prototypeStart, \$prototypeStartLine);

                $name = $self->TryToGetVariableName(\$prototypeStart, \$prototypeStartLine);

                if (!defined $name)
                    {  return undef;  };

                push @names, $name;

                $self->TryToSkipWhitespace(\$prototypeStart, \$prototypeStartLine);

                if ($tokens->[$prototypeStart] eq ')')
                    {
                    $prototypeStart++;
                    last;
                    }
                elsif ($tokens->[$prototypeStart] eq ',')
                    {  $prototypeStart++;  }
                else
                    {  return undef;  };
                };


            # Now find the end of the prototype.

            $prototypeEnd = $prototypeStart;
            $prototypeEndLine = $prototypeStartLine;

            while ($prototypeEnd < scalar @$tokens &&
                     $tokens->[$prototypeEnd] !~ /^[\;\=]/)
                {
                $prototypeEnd++;
                };


            my $prototypePrefix = $firstToken . ' ';
            if (defined $type)
                {  $prototypePrefix .= $type . ' ';  };

            my $prototypeSuffix = ' ' . $self->CreateString($prototypeStart, $prototypeEnd);

            foreach $name (@names)
                {
                $self->AddAutoTopic(NaturalDocs::Parser::ParsedTopic->New(::TOPIC_VARIABLE(), $name,
                                                                                                           $self->CurrentScope(), $self->CurrentScope(),
                                                                                                           $prototypePrefix . $name . $prototypeSuffix,
                                                                                                           undef, undef, $prototypeStartLine));
                };

            $self->SkipRestOfStatement(\$prototypeEnd, \$prototypeEndLine);

            $$indexRef = $prototypeEnd;
            $$lineNumberRef = $prototypeEndLine;
            }

        else # no parenthesis
            {
            my $name = $self->TryToGetVariableName(\$prototypeEnd, \$prototypeEndLine);

            if (!defined $name)
                {  return undef;  };

            while ($prototypeEnd < scalar @$tokens &&
                     $tokens->[$prototypeEnd] !~ /^[\;\=]/)
                {
                $prototypeEnd++;
                };

            $self->AddAutoTopic(NaturalDocs::Parser::ParsedTopic->New(::TOPIC_VARIABLE(), $name,
                                                                                                       $self->CurrentScope(), $self->CurrentScope(),
                                                                                                       $self->CreateString($prototypeStart, $prototypeEnd),
                                                                                                       undef, undef, $prototypeStartLine));

            $self->SkipRestOfStatement(\$prototypeEnd, \$prototypeEndLine);

            $$indexRef = $prototypeEnd;
            $$lineNumberRef = $prototypeEndLine;
            };

        return 1;
        }
    else
        {  return undef;  };
    };


#
#   Function: TryToGetVariableName
#
#   Determines if the position is at a variable name, and if so, skips it and returns the name.
#
sub TryToGetVariableName #(indexRef, lineNumberRef)
    {
    my ($self, $indexRef, $lineNumberRef) = @_;
    my $tokens = $self->Tokens();

    my $name;

    if ($tokens->[$$indexRef] =~ /^[\$\@\%\*]/)
        {
        $name .= $tokens->[$$indexRef];
        $$indexRef++;

        $self->TryToSkipWhitespace($indexRef, $lineNumberRef);

        if ($tokens->[$$indexRef] =~ /^[a-z_]/i)
            {
            $name .= $tokens->[$$indexRef];
            $$indexRef++;
            }
        else
            {  return undef;  };
        };

    return $name;
    };


###############################################################################
# Group: Low Level Parsing Functions


#
#   Function: GenericSkip
#
#   Advances the position one place through general code.
#
#   - If the position is on a comment or string, it will skip it completely.
#   - If the position is on an opening symbol, it will skip until the past the closing symbol.
#   - If the position is on a backslash, it will skip it and the following token.
#   - If the position is on whitespace (including comments), it will skip it completely.
#   - Otherwise it skips one token.
#
#   Parameters:
#
#       indexRef - A reference to the current index.
#       lineNumberRef - A reference to the current line number.
#
sub GenericSkip #(indexRef, lineNumberRef)
    {
    my ($self, $indexRef, $lineNumberRef) = @_;
    my $tokens = $self->Tokens();

    "aoeu" =~ m//;

    if ($tokens->[$$indexRef] eq "\\" && $tokens + 1 < scalar @$tokens && $tokens->[$$indexRef+1] ne "\n")
        {  $$indexRef += 2;  }

    # Note that we don't want to count backslashed ()[]{} since they could be in regexps.  Also, ()[] are valid variable names
    # when preceded by a string.

    # We can ignore the scope stack because we're just skipping everything without parsing, and we need recursion anyway.
    elsif ($tokens->[$$indexRef] eq '{' && !$self->IsBackslashed($$indexRef))
        {
        $$indexRef++;
        $self->GenericSkipUntilAfter($indexRef, $lineNumberRef, '}');
        }
    elsif ($tokens->[$$indexRef] eq '(' && !$self->IsBackslashed($$indexRef) && !$self->IsStringed($$indexRef))
        {
        $$indexRef++;

        do
            {  $self->GenericSkipUntilAfter($indexRef, $lineNumberRef, ')');  }
        while ($$indexRef < scalar @$tokens && $self->IsStringed($$indexRef - 1));
        }
    elsif ($tokens->[$$indexRef] eq '[' && !$self->IsBackslashed($$indexRef) && !$self->IsStringed($$indexRef))
        {
        $$indexRef++;

        do
            {  $self->GenericSkipUntilAfter($indexRef, $lineNumberRef, ']');  }
        while ($$indexRef < scalar @$tokens && $self->IsStringed($$indexRef - 1));
        }

    elsif ($tokens->[$$indexRef] eq "\n")
        {
        $$lineNumberRef++;
        $$indexRef++;
        }

    elsif ($self->TryToSkipWhitespace($indexRef, $lineNumberRef) ||
            $self->TryToSkipString($indexRef, $lineNumberRef) )
        {
        }

    else
        {  $$indexRef++;  };
    };


#
#   Function: GenericSkipUntilAfter
#
#   Advances the position via <GenericSkip()> until a specific token is reached and passed.
#
sub GenericSkipUntilAfter #(indexRef, lineNumberRef, token)
    {
    my ($self, $indexRef, $lineNumberRef, $token) = @_;
    my $tokens = $self->Tokens();

    while ($$indexRef < scalar @$tokens && $tokens->[$$indexRef] ne $token)
        {  $self->GenericSkip($indexRef, $lineNumberRef);  };

    if ($tokens->[$$indexRef] eq "\n")
        {  $$lineNumberRef++;  };
    $$indexRef++;
    };


#
#   Function: SkipRestOfStatement
#
#   Advances the position via <GenericSkip()> until after the end of the current statement, which is defined as a semicolon or
#   a brace group.  Of course, either of those appearing inside parenthesis, a nested brace group, etc. don't count.
#
sub SkipRestOfStatement #(indexRef, lineNumberRef)
    {
    my ($self, $indexRef, $lineNumberRef) = @_;
    my $tokens = $self->Tokens();

    while ($$indexRef < scalar @$tokens &&
             $tokens->[$$indexRef] ne ';' &&
             !($tokens->[$$indexRef] eq '{' && !$self->IsStringed($$indexRef)) )
        {
        $self->GenericSkip($indexRef, $lineNumberRef);
        };

    if ($tokens->[$$indexRef] eq ';')
        {  $$indexRef++;  }
    elsif ($tokens->[$$indexRef] eq '{')
        {  $self->GenericSkip($indexRef, $lineNumberRef);  };
    };


#
#   Function: TryToSkipWhitespace
#   If the current position is on a whitespace or line break token, skip all line breaks and whitespace and return true.
#
sub TryToSkipWhitespace #(indexRef, lineNumberRef)
    {
    my ($self, $indexRef, $lineNumberRef) = @_;
    my $tokens = $self->Tokens();

    my $result;

    while ($$indexRef < scalar @$tokens)
        {
        if ($tokens->[$$indexRef] =~ /^[ \t]/)
            {
            $$indexRef++;
            $result = 1;
            }
        elsif ($tokens->[$$indexRef] eq "\n")
            {
            $$indexRef++;
            $$lineNumberRef++;
            $result = 1;
            }
        elsif (!$self->TryToSkipComment($indexRef, $lineNumberRef))
            {  last;  };
        };

    return $result;
    };


#
#   Function: TryToSkipComment
#   If the current position is on a comment, skip past it and return true.
#
sub TryToSkipComment #(indexRef, lineNumberRef)
    {
    my ($self, $indexRef, $lineNumberRef) = @_;

    return ( $self->TryToSkipLineComment($indexRef, $lineNumberRef) ||
                $self->TryToSkipPODComment($indexRef, $lineNumberRef) );
    };


#
#   Function: TryToSkipLineComment
#   If the current position is on a line comment symbol, skip past it and return true.
#
sub TryToSkipLineComment #(indexRef, lineNumberRef)
    {
    my ($self, $indexRef, $lineNumberRef) = @_;
    my $tokens = $self->Tokens();

    # Note that $#var is not a comment.
    if ($tokens->[$$indexRef] eq '#' && !$self->IsStringed($$indexRef))
        {
        $self->SkipRestOfLine($indexRef, $lineNumberRef);
        return 1;
        }
    else
        {  return undef;  };
    };


#
#   Function: TryToSkipPODComment
#   If the current position is on a POD comment symbol, skip past it and return true.
#
sub TryToSkipPODComment #(indexRef, lineNumberRef)
    {
    my ($self, $indexRef, $lineNumberRef) = @_;
    my $tokens = $self->Tokens();

    # Note that whitespace is not allowed before the equals sign.  It must directly start a line.
    if ($tokens->[$$indexRef] eq '=' &&
        ( $$indexRef == 0 || $tokens->[$$indexRef - 1] eq "\n" ) &&
        $tokens->[$$indexRef + 1] =~ /^[a-z]/i )
        {
        # Skip until =cut.  Note that it's theoretically possible for =cut to appear without a prior POD directive.

        do
            {
            if ($tokens->[$$indexRef] eq '=' && lc( $tokens->[$$indexRef + 1] ) eq 'cut')
                {
                $self->SkipRestOfLine($indexRef, $lineNumberRef);
                last;
                }
            else
                {
                $self->SkipRestOfLine($indexRef, $lineNumberRef);
                };
            }
        while ($$indexRef < scalar @$tokens);

        return 1;
        }
    else
        {  return undef;  };
    };


#
#   Function: TryToSkipString
#   If the current position is on a string delimiter, skip past the string and return true.
#
sub TryToSkipString #(indexRef, lineNumberRef)
    {
    my ($self, $indexRef, $lineNumberRef) = @_;

    # All three characters are also Perl variables when following a dollar sign.
    return ( !$self->IsStringed($$indexRef) &&
                ( $self->SUPER::TryToSkipString($indexRef, $lineNumberRef, "\'") ||
                  $self->SUPER::TryToSkipString($indexRef, $lineNumberRef, "\"") ||
                  $self->SUPER::TryToSkipString($indexRef, $lineNumberRef, "\`") ) );
    };



###############################################################################
# Group: Support Functions


#
#   Function: IsStringed
#
#   Returns whether the position is after a string (dollar sign) character.
#
#   Parameters:
#
#       index - The index of the postition.
#
sub IsStringed #(index)
    {
    my ($self, $index) = @_;
    my $tokens = $self->Tokens();

    if ($index > 0 && $tokens->[$index - 1] eq '$')
        {  return 1;  }
    else
        {  return undef;  };
    };


1;
