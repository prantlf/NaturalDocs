###############################################################################
#
#   Class: NaturalDocs::Languages::Perl
#
###############################################################################
#
#   A subclass to handle the language variations of Perl.
#
###############################################################################

# This file is part of Natural Docs, which is Copyright � 2003-2004 Greg Valure
# Natural Docs is licensed under the GPL

use strict;
use integer;

package NaturalDocs::Languages::Perl;

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
#   Returns:
#
#       The array ( autoTopics, scopeRecord ).
#
#       autoTopics - An arrayref of automatically generated topics from the file, or undef if none.
#       scopeRecord - An arrayref of <NaturalDocs::Languages::Advanced::ScopeChanges>, or undef if none.
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
            $self->TryToGetBase(\$index, \$lineNumber) ||
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


    my $autoTopics = $self->AutoTopics();

    my $scopeRecord = $self->ScopeRecord();
    if (defined $scopeRecord && !scalar @$scopeRecord)
        {  $scopeRecord = undef;  };

    return ( $autoTopics, $scopeRecord );
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
        NaturalDocs::Parser->OnClass($name);

        $self->SetPackage($name, $$lineNumberRef);

        $$indexRef = $index;
        $$lineNumberRef = $lineNumber;
        $self->SkipRestOfStatement($indexRef, $lineNumberRef);

        return 1;
        };

    return undef;
    };


#
#   Function: TryToGetBase
#
#   Determines whether the position is at a package base declaration statement, and if so, calls
#   <NaturalDocs::Parser->OnParent()>.
#
#   Supported Syntaxes:
#
#   > use base [list of strings]
#   > @ISA = [list of strings]
#   > @[package]::ISA = [list of strings]
#   > our @ISA = [list of strings]
#
sub TryToGetBase #(indexRef, lineNumberRef)
    {
    my ($self, $indexRef, $lineNumberRef) = @_;
    my $tokens = $self->Tokens();

    my ($index, $lineNumber, $class, $parents);

    if (lc($tokens->[$$indexRef]) eq 'use')
        {
        $index = $$indexRef + 1;
        $lineNumber = $$lineNumberRef;

        if (!$self->TryToSkipWhitespace(\$index, \$lineNumber) ||
           lc($tokens->[$index]) ne 'base')
            {  return undef;  }

        $index++;
        $self->TryToSkipWhitespace(\$index, \$lineNumber);

        $parents = $self->TryToGetListOfStrings(\$index, \$lineNumber);
        }

    else
        {
        $index = $$indexRef;
        $lineNumber = $$lineNumberRef;

        if (lc($tokens->[$index]) eq 'our')
            {
            $index++;
            $self->TryToSkipWhitespace(\$index, \$lineNumber);
            };

        if ($tokens->[$index] eq '@')
            {
            $index++;

            while ($index < scalar @$tokens)
                {
                if ($tokens->[$index] eq 'ISA')
                    {
                    $index++;
                    $self->TryToSkipWhitespace(\$index, \$lineNumber);

                    if ($tokens->[$index] eq '=')
                        {
                        $index++;
                        $self->TryToSkipWhitespace(\$index, \$lineNumber);

                        $parents = $self->TryToGetListOfStrings(\$index, \$lineNumber);
                        }
                    else
                        {  last;  };
                    }

                # If token isn't ISA...
                elsif ($tokens->[$index] =~ /^[a-z0-9_:]/i)
                    {
                    $class .= $tokens->[$index];
                    $index++;
                    }
                else
                    {  last;  };
                };
            };
        };

    if (defined $parents)
        {
        if (defined $class)
            {  $class =~ s/::$//;  }
        else
            {  $class = $self->CurrentScope();  };

        foreach my $parent (@$parents)
            {  NaturalDocs::Parser->OnClassParent($class, $parent, undef);  };

        $$indexRef = $index;
        $$lineNumberRef = $lineNumber;
        $self->SkipRestOfStatement($indexRef, $lineNumberRef);

        return 1;
        }
    else
        {  return undef;  };
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
#   Supported Syntaxes:
#
#   - Supports variables declared with "my", "our", and "local".
#   - Supports multiple declarations in one statement, such as "my ($x, $y);".
#   - Supports types and attributes.
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


#
#   Function: TryToGetListOfStrings
#
#   Attempts to retrieve a list of strings from the current position.  Returns an arrayref of them if any are found, or undef if none.
#   It stops the moment it reaches a non-string, so "string1, variable, string2" will only return string1.
#
#   Supported Syntaxes:
#
#   - Supports parenthesis.
#   - Supports all string forms supported by <TryToSkipString()>.
#   - Supports qw() string arrays.
#
sub TryToGetListOfStrings #(indexRef, lineNumberRef)
    {
    my ($self, $indexRef, $lineNumberRef) = @_;
    my $tokens = $self->Tokens();

    my $parenthesis = 0;
    my $strings;

    while ($$indexRef < scalar @$tokens)
        {
        # We'll tolerate parenthesis.
        if ($tokens->[$$indexRef] eq '(')
            {
            $$indexRef++;
            $parenthesis++;
            }
        elsif ($tokens->[$$indexRef] eq ')')
            {
            if ($parenthesis == 0)
                {  last;  };

            $$indexRef++;
            $parenthesis--;
            }
        elsif ($tokens->[$$indexRef] eq ',')
            {
            $$indexRef++;
            }
        else
            {
            my ($startContent, $endContent);
            my $symbolIndex = $$indexRef;

            if ($self->TryToSkipString($indexRef, $lineNumberRef, \$startContent, \$endContent))
                {
                my $content = $self->CreateString($startContent, $endContent);

                if (!defined $strings)
                    {  $strings = [ ];  };

                if (lc($tokens->[$symbolIndex]) eq 'qw')
                    {
                    push @$strings, split(/[ \t]+/, $content);
                    }
                else
                    {
                    push @$strings, $content;
                    };
                }
            else
                {  last;  };
            };

        $self->TryToSkipWhitespace($indexRef, $lineNumberRef);
        };

    return $strings;
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
#   - If the position is on a regexp or quote-like operator, it will skip it completely.
#   - If the position is on a backslash, it will skip it and the following token.
#   - If the position is on whitespace (including comments), it will skip it completely.
#   - Otherwise it skips one token.
#
#   Parameters:
#
#       indexRef - A reference to the current index.
#       lineNumberRef - A reference to the current line number.
#       noRegExps - If set, does not test for regular expressions.
#
sub GenericSkip #(indexRef, lineNumberRef, noRegExps)
    {
    my ($self, $indexRef, $lineNumberRef, $noRegExps) = @_;
    my $tokens = $self->Tokens();

    if ($tokens->[$$indexRef] eq "\\" && $$indexRef + 1 < scalar @$tokens && $tokens->[$$indexRef+1] ne "\n")
        {  $$indexRef += 2;  }

    # Note that we don't want to count backslashed ()[]{} since they could be in regexps.  Also, ()[] are valid variable names
    # when preceded by a string.

    # We can ignore the scope stack because we're just skipping everything without parsing, and we need recursion anyway.
    elsif ($tokens->[$$indexRef] eq '{' && !$self->IsBackslashed($$indexRef))
        {
        $$indexRef++;
        $self->GenericSkipUntilAfter($indexRef, $lineNumberRef, '}', $noRegExps);
        }
    elsif ($tokens->[$$indexRef] eq '(' && !$self->IsBackslashed($$indexRef) && !$self->IsStringed($$indexRef))
        {
        $$indexRef++;

        do
            {  $self->GenericSkipUntilAfter($indexRef, $lineNumberRef, ')', $noRegExps);  }
        while ($$indexRef < scalar @$tokens && $self->IsStringed($$indexRef - 1));
        }
    elsif ($tokens->[$$indexRef] eq '[' && !$self->IsBackslashed($$indexRef) && !$self->IsStringed($$indexRef))
        {
        $$indexRef++;

        do
            {  $self->GenericSkipUntilAfter($indexRef, $lineNumberRef, ']', $noRegExps);  }
        while ($$indexRef < scalar @$tokens && $self->IsStringed($$indexRef - 1));
        }

    elsif ($self->TryToSkipWhitespace($indexRef, $lineNumberRef) ||
            $self->TryToSkipString($indexRef, $lineNumberRef) ||
            (!$noRegExps && $self->TryToSkipRegexp($indexRef, $lineNumberRef) ) )
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
sub GenericSkipUntilAfter #(indexRef, lineNumberRef, token, noRegExps)
    {
    my ($self, $indexRef, $lineNumberRef, $token, $noRegExps) = @_;
    my $tokens = $self->Tokens();

    while ($$indexRef < scalar @$tokens && $tokens->[$$indexRef] ne $token)
        {  $self->GenericSkip($indexRef, $lineNumberRef, $noRegExps);  };

    if ($tokens->[$$indexRef] eq "\n")
        {  $$lineNumberRef++;  };
    $$indexRef++;
    };


#
#   Function: GenericRegexpSkip
#
#   Advances the position one place through regexp code.
#
#   - If the position is on an opening symbol, it will skip until the past the closing symbol.
#   - If the position is on a backslash, it will skip it and the following token.
#   - If the position is on whitespace (not including comments), it will skip it completely.
#   - Otherwise it skips one token.
#
#   Also differs from <GenericSkip()> in that the parenthesis in $( and $) do count against the scope, where they wouldn't
#   normally.
#
#   Parameters:
#
#       indexRef - A reference to the current index.
#       lineNumberRef - A reference to the current line number.
#       inBrackets - Whether we're in brackets or not.  If true, we don't care about matching braces and parenthesis.
#
sub GenericRegexpSkip #(indexRef, lineNumberRef, inBrackets)
    {
    my ($self, $indexRef, $lineNumberRef, $inBrackets) = @_;
    my $tokens = $self->Tokens();

    if ($tokens->[$$indexRef] eq "\\" && $$indexRef + 1 < scalar @$tokens && $tokens->[$$indexRef+1] ne "\n")
        {  $$indexRef += 2;  }

    # We can ignore the scope stack because we're just skipping everything without parsing, and we need recursion anyway.
    elsif ($tokens->[$$indexRef] eq '{' && !$self->IsBackslashed($$indexRef) && !$inBrackets)
        {
        $$indexRef++;
        $self->GenericRegexpSkipUntilAfter($indexRef, $lineNumberRef, '}');
        }
    elsif ($tokens->[$$indexRef] eq '(' && !$self->IsBackslashed($$indexRef) && !$inBrackets)
        {
        $$indexRef++;
        $self->GenericRegexpSkipUntilAfter($indexRef, $lineNumberRef, ')');
        }
    elsif ($tokens->[$$indexRef] eq '[' && !$self->IsBackslashed($$indexRef) && !$self->IsStringed($$indexRef))
        {
        $$indexRef++;

        do
            {  $self->GenericRegexpSkipUntilAfter($indexRef, $lineNumberRef, ']');  }
        while ($$indexRef < scalar @$tokens && $self->IsStringed($$indexRef - 1));
        }

    elsif ($tokens->[$$indexRef] eq "\n")
        {
        $$lineNumberRef++;
        $$indexRef++;
        }

    else
        {  $$indexRef++;  };
    };


#
#   Function: GenericRegexpSkipUntilAfter
#
#   Advances the position via <GenericRegexpSkip()> until a specific token is reached and passed.
#
sub GenericRegexpSkipUntilAfter #(indexRef, lineNumberRef, token)
    {
    my ($self, $indexRef, $lineNumberRef, $token) = @_;
    my $tokens = $self->Tokens();

    my $inBrackets = ( $token eq ']' );

    while ($$indexRef < scalar @$tokens && $tokens->[$$indexRef] ne $token)
        {  $self->GenericRegexpSkip($indexRef, $lineNumberRef, $inBrackets);  };

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
#   If the current position is on a whitespace token, line break token, or comment, it skips them and returns true.  If there are
#   a number of these in a row, it skips them all.
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
#   Parameters:
#
#       indexRef - A reference to the index of the position to start at.
#       lineNumberRef - A reference to the line number of the position.
#       startContentIndexRef - A reference to the variable in which to store the index of the first content token.  May be undef.
#       endContentIndexRef - A reference to the variable in which to store the index of the end of the content, which is one past
#                                        the last content token.  may be undef.
#
#   Returns:
#
#       Whether the position was at a string.  The index, line number, and content index variabls will only be changed if true.
#
#   Syntax Support:
#
#       - Supports quotes, apostrophes, backticks, q(), qq(), qx(), and qw().
#       - All symbols are supported for the letter forms.
#
sub TryToSkipString #(indexRef, lineNumberRef, startContentIndexRef, endContentIndexRef)
    {
    my ($self, $indexRef, $lineNumberRef, $startContentIndexRef, $endContentIndexRef) = @_;
    my $tokens = $self->Tokens();

    # The three string delimiters.  All three are Perl variables when preceded by a dollar sign.
    if (!$self->IsStringed($$indexRef) &&
        ( $self->SUPER::TryToSkipString($indexRef, $lineNumberRef, '\'', '\'', $startContentIndexRef, $endContentIndexRef) ||
          $self->SUPER::TryToSkipString($indexRef, $lineNumberRef, '"', '"', $startContentIndexRef, $endContentIndexRef) ||
          $self->SUPER::TryToSkipString($indexRef, $lineNumberRef, '`', '`', $startContentIndexRef, $endContentIndexRef) ) )
        {
        return 1;
        }
    elsif ($tokens->[$$indexRef] =~ /^(?:q|qq|qx|qw)$/i &&
            ($$indexRef == 0 || $tokens->[$$indexRef - 1] !~ /^[\$\%\@\*]$/))
        {
        $$indexRef++;

        $self->TryToSkipWhitespace($indexRef, $lineNumberRef);

        my $openingSymbol = $tokens->[$$indexRef];
        my $closingSymbol;

        if ($openingSymbol eq '{')
            {  $closingSymbol = '}';  }
        elsif ($openingSymbol eq '(')
            {  $closingSymbol = ')';  }
        elsif ($openingSymbol eq '[')
            {  $closingSymbol = ']';  }
        elsif ($openingSymbol eq '<')
            {  $closingSymbol = '>';  }
        else
            {  $closingSymbol = $openingSymbol;  };

        $self->SUPER::TryToSkipString($indexRef, $lineNumberRef, $openingSymbol, $closingSymbol,
                                                      $startContentIndexRef, $endContentIndexRef);

        return 1;
        }
    else
        {  return undef;  };
    };


#
#   Function: TryToSkipRegexp
#   If the current position is on a regular expression or a quote-like operator, skip past it and return true.
#
#   Syntax Support:
#
#       - Supports //, ??, m//, qr//, s///, tr///, and y///.
#       - All symbols are supported for the letter forms.
#
sub TryToSkipRegexp #(indexRef, lineNumberRef)
    {
    my ($self, $indexRef, $lineNumberRef) = @_;
    my $tokens = $self->Tokens();

    my $isRegexp;

    if ($tokens->[$$indexRef] =~ /^(?:m|qr|s|tr|y|)$/i &&
         ($$indexRef == 0 || $tokens->[$$indexRef - 1] !~ /^[\$\%\@\*\-]$/) )
        {  $isRegexp = 1;  }
    elsif ($tokens->[$$indexRef] eq '/' || $tokens->[$$indexRef] eq '?')
        {
        my $index = $$indexRef - 1;

        while ($index >= 0 && $tokens->[$index] =~ /^(?: |\t|\n)/)
            {  $index--;  };

        if ($index < 0 || $tokens->[$index] !~ /^[a-zA-Z0-9_\)\]\}\'\"\`]/)
            {  $isRegexp = 1;  };
        };

    if ($isRegexp)
        {
        my $operator = lc($tokens->[$$indexRef]);
        my $index = $$indexRef;
        my $lineNumber = $$lineNumberRef;

        if ($operator =~ /^[\?\/]/)
            {  $operator = 'm';  }
        else
            {
            $index++;
            $self->TryToSkipWhitespace(\$index, \$lineNumber);
            };

        if ($tokens->[$index] =~ /^\w/)
            {  return undef;  };

        my $openingSymbol = $tokens->[$index];
        my $closingSymbol;

        if ($openingSymbol eq '{')
            {  $closingSymbol = '}';  }
        elsif ($openingSymbol eq '(')
            {  $closingSymbol = ')';  }
        elsif ($openingSymbol eq '[')
            {  $closingSymbol = ']';  }
        elsif ($openingSymbol eq '<')
            {  $closingSymbol = '>';  }
        else
            {  $closingSymbol = $openingSymbol;  };

        $index++;

        $self->GenericRegexpSkipUntilAfter(\$index, \$lineNumber, $closingSymbol);

        $$indexRef = $index;
        $$lineNumberRef = $lineNumber;

        if ($operator =~ /^(?:s|tr|y)$/)
            {
            if ($openingSymbol ne $closingSymbol)
                {
                $self->TryToSkipWhitespace($indexRef, $lineNumberRef);

                $openingSymbol = $tokens->[$index];

                if ($openingSymbol eq '{')
                    {  $closingSymbol = '}';  }
                elsif ($openingSymbol eq '(')
                    {  $closingSymbol = ')';  }
                elsif ($openingSymbol eq '[')
                    {  $closingSymbol = ']';  }
                elsif ($openingSymbol eq '<')
                    {  $closingSymbol = '>';  }
                else
                    {  $closingSymbol = $openingSymbol;  };

                $$indexRef++;
                };

            if ($operator eq 's')
                {
                $self->GenericSkipUntilAfter($indexRef, $lineNumberRef, $closingSymbol, 1);
                }
            else # ($operator eq 'tr' || $operator eq 'y')
                {
                while ($$indexRef < scalar @$tokens &&
                          ($tokens->[$$indexRef] ne $closingSymbol || $self->IsBackslashed($$indexRef)) )
                    {
                    if ($tokens->[$$indexRef] eq "\n")
                        {  $$lineNumberRef++;  };
                    $$indexRef++;
                    };

                $$indexRef++;
                };
            };

        return 1;
        };

    return undef;
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
