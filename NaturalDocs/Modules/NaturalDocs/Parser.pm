###############################################################################
#
#   Package: NaturalDocs::Parser
#
###############################################################################
#
#   A package that parses the input file either for symbols or to send to <NaturalDocs::Builder>.
#
#   Usage and Dependencies:
#
#       - Prior to use, <NaturalDocs::Settings>, <NaturalDocs::Languages>, <NaturalDocs::Project>, and
#         <NaturalDocs::SymbolTable> must be initialized.  <NaturalDocs::SymbolTable> does not have to be fully resolved.
#
#       - Aside from that, the package is ready to use right away.  It does not have its own initialization function.
#
###############################################################################

# This file is part of Natural Docs, which is Copyright © 2003 Greg Valure
# Natural Docs is licensed under the GPL


use NaturalDocs::Parser::ParsedTopic;

use strict;
use integer;

package NaturalDocs::Parser;


###############################################################################
# Group: Variables


# Return values of TagType().  Not documented here.
use constant POSSIBLE_OPENING_TAG => 1;
use constant POSSIBLE_CLOSING_TAG => 2;
use constant NOT_A_TAG => 3;


#
#   Handle: SOURCEFILEHANDLE
#
#   The handle of the source file currently being parsed.
#

#
#   object: language
#
#   The language of the file currently being parsed.  Is a <NaturalDocs::Languages::Language> object.
#
my $language;

#
#   var: scope
#
#   The scope at the current point in the file.  This is a package variable because it needs to be preserved between function
#   calls.
#
my $scope;

#
#   var: defaultMenuTitle
#
#   The default menu title of the current file.  Will be the file name if a suitable one cannot be found.
#
my $defaultMenuTitle;

#
#   Array: parsedFile
#
#   An array of <NaturalDocs::Parser::ParsedTopic> objects.
#
my @parsedFile;


###############################################################################
# Group: Functions

#
#   Function: ParseForInformation
#
#   Parses the input file for information.  Will update the information about the file in <NaturalDocs::SymbolTable> and
#   <NaturalDocs::Project>.
#
#   Parameters:
#
#       file - The name of the file to parse.
#
sub ParseForInformation #(file)
    {
    my ($self, $file) = @_;

    # Have the symbol table watch this parse so we detect any changes.
    NaturalDocs::SymbolTable->WatchFileForChanges($file);

    $self->Parse($file);

    foreach my $topic (@parsedFile)
        {
        # Add a symbol for the topic.

        NaturalDocs::SymbolTable->AddSymbol($topic->Class(), $topic->Name(), $file, $topic->Type(),
                                                                  $topic->Prototype(), $topic->Summary());


        # You can't put the function call directly in a while with a regex.  It has to sit in a variable to work.
        my $body = $topic->Body();


        # If it's a list topic, add a symbol for each description list entry.

        if (NaturalDocs::Topics->IsList($topic->Type()))
            {
            my $listType = NaturalDocs::Topics->IsListOf($topic->Type());

            while ($body =~ /<ds>([^<]+)<\/ds><dd>(.*?)<\/dd>/g)
                {
                my ($listSymbol, $listSummary) = ($1, $2);

                $listSummary =~ /^(.*?)($|[\.\!\?](?:[\)\}\'\ ]|&quot;|&gt;))/;
                $listSummary = $1 . $2;

                NaturalDocs::SymbolTable->AddSymbol($topic->Scope(), NaturalDocs::NDMarkup->RestoreAmpChars($listSymbol),
                                                                          $file, $listType, undef, $listSummary);
                };
            };


        # Add references in the topic.

        while ($body =~ /<link>([^<]+)<\/link>/g)
            {  NaturalDocs::SymbolTable->AddReference($topic->Scope(), NaturalDocs::NDMarkup->RestoreAmpChars($1), $file);  };
        };

    # Handle any changes to the file.
    NaturalDocs::SymbolTable->AnalyzeChanges();

    # Update project on the file's characteristics.
    my $hasContent = (scalar @parsedFile > 0);

    NaturalDocs::Project->SetHasContent($file, $hasContent);
    if ($hasContent)
        {  NaturalDocs::Project->SetDefaultMenuTitle($file, $defaultMenuTitle);  };

    # We don't need to keep this around.
    @parsedFile = ( );
    };


#
#   Function: ParseForBuild
#
#   Parses the input file for building, returning it as a <NaturalDocs::Parser::ParsedTopic> arrayref.
#
#   Note that all new and changed files should be parsed for symbols via <ParseForInformation()> before calling this function on
#   *any* file.  The reason is that <NaturalDocs::SymbolTable> needs to know about all the symbol definitions and references to
#   resolve them properly.
#
#   Parameters:
#
#       file - The name of the file to parse for building.
#
#   Returns:
#
#       An arrayref of the source file as <NaturalDocs::Parser::ParsedTopic> objects.
#
sub ParseForBuild #(file)
    {
    my ($self, $file) = @_;

    $self->Parse($file);

    # If the title ended up being the file name, add a leading section for it.
    if ($defaultMenuTitle eq $file && $parsedFile[0]->Name() ne $file)
        {
        unshift @parsedFile, NaturalDocs::Parser::ParsedTopic->New(::TOPIC_SECTION(), $file, undef, undef, undef, undef);
        };

    return \@parsedFile;
    };


###############################################################################
# Group: Parser Stages
#
# Do not call these functions directly, as they are stages in the parsing process.  Rather, call <ParseForInformation()> or
# <ParseForBuild()>.


#   Function: Parse
#
#   Opens <SOURCEFILEHANDLE> and begins the parsing process.  Do not call directly; rather, call <ParseForInformation()> or
#   <ParseForBuild()>.  It will close <SOURCEFILEHANDLE> before returning, but it will be open during the other parser stages.
#
#   Parameters:
#
#       file - The name of the file to parse.
#
sub Parse #(file)
    {
    my ($self, $file) = @_;

    $language = NaturalDocs::Languages->LanguageOf($file);
    $scope = undef;
    @parsedFile = ( );

    my $fileName = NaturalDocs::File->JoinPath( NaturalDocs::Settings->InputDirectory(), $file );

    open(SOURCEFILEHANDLE, '<' . $fileName)
        or die "Couldn't open input file " . $fileName . "\n";

    # Parse the content for comments.
    $self->ExtractComments();

    close(SOURCEFILEHANDLE);


    # Set the menu title.

    $defaultMenuTitle = $file;

    if (scalar @parsedFile)
        {
        my $firstType = $parsedFile[0]->Type();

        # If there's only one topic, it's title overrides the file name.  If there's more than one topic but the first one is a section, file,
        # or class, it's title overrides the file name as well.
        if (scalar @parsedFile == 1 ||
            $firstType == ::TOPIC_SECTION() || $firstType == ::TOPIC_FILE() || $firstType == ::TOPIC_CLASS())
            {
            $defaultMenuTitle = $parsedFile[0]->Name();
            };

        # We only want to call the hook if it has content.
        NaturalDocs::Extensions->AfterFileParsed($file, \@parsedFile);
        };
    };


#
#   Function: ExtractComments
#
#   Extracts comments from <SOURCEFILEHANDLE> and sends them individually to <CleanComment()>.
#
sub ExtractComments
    {
    my ($self) = @_;

    my @commentLines;

    if ($language->FileIsComment())
        {
        @commentLines = <SOURCEFILEHANDLE>;

        foreach my $commentLine (@commentLines)
            {  chomp($commentLine);  };

        $self->CleanComment(\@commentLines);
        }

    else
        {
        my $line = <SOURCEFILEHANDLE>;

        my $prototype;
        my $prototypeType;

        while (defined $line)
            {
            chomp $line;

            # Retrieve single line comments.  This leaves $line at the next line.

            if ($language->StripLineCommentSymbol(\$line))
                {
                # If we couldn't find a prototype ender, we couldn't find a prototype.
                $prototype = undef;
                $prototypeType = undef;

                do
                    {
                    push @commentLines, $line;
                    $line = <SOURCEFILEHANDLE>;

                    if (!defined $line)
                        {  last;  };

                    chomp($line);
                    }
                while ($language->StripLineCommentSymbol(\$line));
                }

            # Retrieve multiline comments.  This leaves $line with whatever followed the closing comment symbol.

            elsif ($language->StripOpeningCommentSymbol(\$line))
                {
                # If we couldn't find a prototype ender, we couldn't find a prototype.
                $prototype = undef;
                $prototypeType = undef;

                my ($symbol, $lineRemainder);

                for (;;)
                    {
                    ($symbol, $lineRemainder) = $language->StripClosingCommentSymbol(\$line);

                    push @commentLines, $line;

                    #  If we found an end comment symbol...
                    if (defined $symbol)
                        {
                        $line = $lineRemainder;
                        last;
                        };

                    $line = <SOURCEFILEHANDLE>;

                    if (!defined $line)
                        {  last;  };

                    chomp($line);
                    };
                }

            # Try to retrieve the protoype, if necessary.  This leaves $line at the next line.

            elsif (defined $prototypeType)
                {
                $prototype .= $line . "\n";

                my $endOfPrototype = $language->EndOfPrototype($prototypeType, \$prototype);

                if ($endOfPrototype != -1)
                    {
                    $prototype = substr($prototype, 0, $endOfPrototype);
                    $language->RemoveExtenders(\$prototype);

                    # Tabs and line breaks to spaces.
                    $prototype =~ tr/\t\n\r/   /;

                    if (index($prototype, $parsedFile[-1]->Name()) != -1)
                        {
                        $parsedFile[-1]->SetPrototype($prototype);
                        };

                    $prototype = undef;
                    $prototypeType = undef;
                    };

                $line = <SOURCEFILEHANDLE>;
                }

            # Otherwise just put $line on the next line.

            else
                {  $line = <SOURCEFILEHANDLE>;  };



            # If there were comments, send them to CleanComment() and determine if we need to find a prototype.

            if (scalar @commentLines)
                {
                my $previousTopics = scalar @parsedFile;

                $self->CleanComment(\@commentLines);
                @commentLines = ( );

                # If there were topics created from the last comments...
                if (scalar @parsedFile > $previousTopics)
                    {
                    # Start searching for a prototype if necessary.

                    $prototypeType = $parsedFile[-1]->Type();

                    if (!$language->HasPrototype($prototypeType))
                        {  $prototypeType = undef;  }
                    else
                        {
                        # Skip all completely blank lines before the prototype.  This is important because a line break may be a symbol
                        # that can end it.  Note that the current line in $line has already been chomped.

                        while (defined $line && $line =~ /^[ \t\n]*$/)
                            {  $line = <SOURCEFILEHANDLE>;  };
                        };
                    };
                };

            };  # while (defined $line)
        };
    };


#
#   Function: CleanComment
#
#   Removes any extraneous formatting or whitespace from the comment and sends it to <ExtractTopics()>.  Eliminates comment
#   boxes, horizontal lines, leading and trailing line breaks, leading and trailing whitespace from lines, more than two line
#   breaks in a row, and expands all tab characters.
#
#   Parameters:
#
#       commentLines  - An arrayref of the comment lines to clean.  *The original memory will be changed.*  Lines should not have
#                                the trailing line break.
#
sub CleanComment #(commentLines)
    {
    my ($self, $commentLines) = @_;

    use constant DONT_KNOW => 0;
    use constant IS_UNIFORM => 1;
    use constant IS_UNIFORM_IF_AT_END => 2;
    use constant IS_NOT_UNIFORM => 3;

    my $leftSide = DONT_KNOW;
    my $rightSide = DONT_KNOW;
    my $leftSideChar;
    my $rightSideChar;

    my $index = 0;
    my $tabLength = NaturalDocs::Settings->TabLength();

    while ($index < scalar @$commentLines)
        {
        # Expand tabs.  This method is almost six times faster than Text::Tabs' method.

        my $tabIndex = index($commentLines->[$index], "\t");

        while ($tabIndex != -1)
            {
            substr( $commentLines->[$index], $tabIndex, 1, ' ' x ($tabLength - ($tabIndex % $tabLength)) );
            $tabIndex = index($commentLines->[$index], "\t", $tabIndex);
            };


        # Strip leading and trailing whitespace.  This has to be done after tabs are expanded because stripping indentation could
        # change how far tabs are expanded.

        $commentLines->[$index] =~ s/^ +//;
        $commentLines->[$index] =~ s/ +$//;

        # If the line is blank...
        if (!length($commentLines->[$index]))
            {
            # If we have a potential vertical line, this only acceptable if it's at the end of the comment.
            if ($leftSide == IS_UNIFORM)
                {  $leftSide = IS_UNIFORM_IF_AT_END;  };
            if ($rightSide == IS_UNIFORM)
                {  $rightSide = IS_UNIFORM_IF_AT_END;  };
            }

        # If there's at least four symbols in a row, it's a horizontal line.  The second regex supports differing edge characters.  It
        # doesn't matter if any of this matches the left and right side symbols.
        elsif ($commentLines->[$index] =~ /^([^a-zA-Z0-9 ])\1{3,}$/ ||
                $commentLines->[$index] =~ /^([^a-zA-Z0-9 ])\1*([^a-zA-Z0-9 ])\2{3,}([^a-zA-Z0-9 ])\3*$/)
            {
            # Convert it to a blank line.
            $commentLines->[$index] = '';

            # This has no effect on the vertical line detection.
            }

        # If the line is not blank or a horizontal line...
        else
            {
            # More content means any previous blank lines are no longer tolerated in vertical line detection.  They are only
            # acceptable at the end of the comment.

            if ($leftSide == IS_UNIFORM_IF_AT_END)
                {  $leftSide = IS_NOT_UNIFORM;  };
            if ($rightSide == IS_UNIFORM_IF_AT_END)
                {  $rightSide = IS_NOT_UNIFORM;  };


            # Detect vertical lines.  Lines are only lines if they are followed by whitespace or a connected horizontal line.
            # Otherwise we may accidentally detect lines from short comments that just happen to have every first or last
            # character the same.

            if ($leftSide != IS_NOT_UNIFORM)
                {
                if ($commentLines->[$index] =~ /^([^a-zA-Z0-9])\1*(?: |$)/)
                    {
                    if ($leftSide == DONT_KNOW)
                        {
                        $leftSide = IS_UNIFORM;
                        $leftSideChar = $1;
                        }
                    else # ($leftSide == IS_UNIFORM)  Other choices already ruled out.
                        {
                        if ($leftSideChar ne $1)
                            {  $leftSide = IS_NOT_UNIFORM;  };
                        };
                    }
                else
                    {
                    $leftSide = IS_NOT_UNIFORM;
                    };
                };

            if ($rightSide != IS_NOT_UNIFORM)
                {
                if ($commentLines->[$index] =~ / ([^a-zA-Z0-9])\1*$/)
                    {
                    if ($rightSide == DONT_KNOW)
                        {
                        $rightSide = IS_UNIFORM;
                        $rightSideChar = $1;
                        }
                    else # ($rightSide == IS_UNIFORM)  Other choices already ruled out.
                        {
                        if ($rightSideChar ne $1)
                            {  $rightSide = IS_NOT_UNIFORM;  };
                        };
                    }
                else
                    {
                    $rightSide = IS_NOT_UNIFORM;
                    };
                };

            # We'll remove vertical lines later if they're uniform throughout the entire comment.
            };

        $index++;
        };


    if ($leftSide == IS_UNIFORM_IF_AT_END)
        {  $leftSide = IS_UNIFORM;  };
    if ($rightSide == IS_UNIFORM_IF_AT_END)
        {  $rightSide = IS_UNIFORM;  };


    $index = 0;
    my $prevLineBlank = 1;

    while ($index < scalar @$commentLines)
        {
        # Clear vertical lines.

        if ($leftSide == IS_UNIFORM)
            {
            # This works because every line should either start this way or be blank.
            $commentLines->[$index] =~ s/^([^a-zA-Z0-9])\1* *//;
            };

        if ($rightSide == IS_UNIFORM)
            {
            $commentLines->[$index] =~ s/ *([^a-zA-Z0-9])\1*$//;
            };


        # Clear horizontal lines again if there were vertical lines.  This catches lines that were separated from the verticals by
        # whitespace.  We couldn't do this in the first loop because that would make the regexes over-tolerant.

        if ($leftSide == IS_UNIFORM || $rightSide == IS_UNIFORM)
            {
            $commentLines->[$index] =~ s/^([^a-zA-Z0-9 ])\1{3,}$//;
            $commentLines->[$index] =~ s/^([^a-zA-Z0-9 ])\1*([^a-zA-Z0-9 ])\2{3,}([^a-zA-Z0-9 ])\3*$//;
            };


        # Condense line breaks.  This also strips leading ones since prevLineBlank defaults to set.

        if (!length($commentLines->[$index]))
            {
            if ($prevLineBlank)
                {
                splice(@$commentLines, $index, 1);
                }
            else
                {
                $prevLineBlank = 1;
                $index++;
                };
            }

        else # the line isn't blank
            {
            $prevLineBlank = 0;
            $index++;
            };
        };


    # Strip trailing blank lines.

    while ($index > 0 && !length( $commentLines->[$index - 1] ))
        {  $index--;  };

    splice(@$commentLines, $index);


    $self->ExtractTopics($commentLines);
    };


#
#   Function: ExtractTopics
#
#   Takes the comment and extracts any Natural Docs topics in it.
#
#   Parameters:
#
#       commentLines  - An arrayref of comment lines.
#
sub ExtractTopics #(commentLines)
    {
    my ($self, $commentLines) = @_;

    my $prevLineBlank = 1;

    # Class applies to the name, and scope applies to the body.  They may be completely different.  For example, with a class
    # entry, the class itself is global but its body is within its scope so it can reference members locally.  Also, a file is always
    # global, but its body uses whatever scope it appears in.
    my $class;
    my $name;
    my $type;
    #my $scope;  # package variable.

    my $index = 0;

    my $bodyStart = 0;
    my $bodyEnd = 0;  # Not inclusive.

    while ($index < scalar @$commentLines)
        {
        # Leading and trailing whitespace was removed by CleanComment().

        # If the line is empty...
        if (!length($commentLines->[$index]))
            {
            # CleanComment() made sure there weren't multiple blank lines in a row or at the beginning/end of the comment.
            $prevLineBlank = 1;

            # If this is the beginning of a body, make sure the leading blank is excluded.
            if ($bodyStart == $index)
                {
                $bodyStart = $index + 1;
                $bodyEnd = $index + 1;
                };
            # If this isn't the beginning of a body, we ignore it completely.  It will be included if there is any content after it when
            # bodyEnd is advanced for that content.
            }

        # If the line has a recognized header and the previous line is blank...
        elsif ($prevLineBlank &&
                $commentLines->[$index] =~ /^([^:]+): +([^ ].*)$/ &&
                defined NaturalDocs::Topics->ConstantOf($1))
            {
            my $newType = NaturalDocs::Topics->ConstantOf($1);
            my $newName = $2;

            # Process the previous one, if any.

            if (defined $type)
                {
                my $body = $self->FormatBody($commentLines, $bodyStart, $bodyEnd, $type);
                $self->AddToParsedFile($name, $class, $type, $body);
                };

            $type = $newType;
            $name = $newName;

            $bodyStart = $index + 1;
            $bodyEnd = $index + 1;


            if ($type == ::TOPIC_SECTION())
                {
                $scope = undef;
                $class = undef;
                }
            elsif ($type == ::TOPIC_CLASS())
                {
                $scope = $name;
                $class = undef;
                }
            elsif ($type == ::TOPIC_CLASS_LIST())
                {
                $scope = undef;
                $class = undef;
                }
            elsif ($type == ::TOPIC_FILE() || $type == ::TOPIC_FILE_LIST())
                {
                # Scope stays the same.
                $class = undef;
                }
            else
                {
                # Scope stays the same.
                $class = $scope;
                };

            $prevLineBlank = 0;
            }


        # Line without recognized header
        else
            {
            $prevLineBlank = 0;
            $bodyEnd = $index + 1;
            };


        $index++;
        };


    # Last one, if any.  This is the only one that gets the prototypes.
    if (defined $type)
        {
        my $body = $self->FormatBody($commentLines, $bodyStart, $bodyEnd, $type);
        $self->AddToParsedFile($name, $class, $type, $body);
        };
    };


#
#   Function: AddToParsedFile
#
#   Creates a <NaturalDocs::Parser::ParsedTopic> object and adds it to <parsedFile>.  Scope is gotten from
#   the package variable <scope> instead of from the parameters.  The summary is generated from the body.
#
#   Parameters:
#
#       name       - The name of the section.
#       class        - The class of the section.
#       type         - The section type.
#       body        - The section's body in <NDMarkup>.
#
sub AddToParsedFile #(name, class, type, body)
    {
    my ($self, $name, $class, $type, $body) = @_;
    # $scope is a package variable.

    my $summary;

    if (defined $body)
        {
        # Extract the first sentence from the leading paragraph, if any.  We'll tolerate a single header beforehand, but nothing else.

        if ($body =~ /^(?:<h>[^<]*<\/h>)?<p>(.*?)(<\/p>|[\.\!\?](?:[\)\}\'\ ]|&quot;|&gt;))/x)
            {
            $summary = $1;
            if ($2 ne '</p>')
                {  $summary .= $2;  };
            };
        };


    push @parsedFile, NaturalDocs::Parser::ParsedTopic->New($type, $name, $class, $scope, undef, $summary, $body);
    };


###############################################################################
# Group: Support Functions


#
#   Function: FormatBody
#
#   Converts the section body to <NDMarkup>.
#
#   Parameters:
#
#       commentLines - The arrayref of comment lines.
#       startingIndex  - The starting index of the body to format.
#       endingIndex   - The ending index of the body to format, *not* inclusive.
#       type               - The type of the section.
#
#   Returns:
#
#       The body formatted in <NDMarkup>.
#
sub FormatBody #(commentLines, startingIndex, endingIndex, type)
    {
    my ($self, $commentLines, $startingIndex, $endingIndex, $type) = @_;

    use constant TAG_NONE => 1;
    use constant TAG_PARAGRAPH => 2;
    use constant TAG_BULLETLIST => 3;
    use constant TAG_DESCRIPTIONLIST => 4;
    use constant TAG_HEADING => 5;
    use constant TAG_CODE => 6;

    my %tagEnders = ( TAG_NONE() => '',
                                 TAG_PARAGRAPH() => '</p>',
                                 TAG_BULLETLIST() => '</li></ul>',
                                 TAG_DESCRIPTIONLIST() => '</dd></dl>',
                                 TAG_HEADING() => '</h>',
                                 TAG_CODE() => '</code>' );

    my $topLevelTag = TAG_NONE;

    my $output;
    my $textBlock;
    my $prevLineBlank = 1;

    my $codeBlock;
    my $prevCodeLineBlank = 1;
    my $removedCodeSpaces;

    my $index = $startingIndex;

    while ($index < $endingIndex)
        {
        # If the line starts with a code designator...
        if ($commentLines->[$index] =~ /^[>:|]( *)((?:[^ ].*)?)$/)
            {
            my $spaces = $1;
            my $code = $2;

            if ($topLevelTag == TAG_CODE)
                {
                if (length $code)
                    {
                    # Make sure we have the minimum amount of spaces to the left possible.
                    if (length($spaces) != $removedCodeSpaces)
                        {
                        my $spaceDifference = abs( length($spaces) - $removedCodeSpaces );
                        my $spacesToAdd = ' ' x $spaceDifference;

                        if (length($spaces) > $removedCodeSpaces)
                            {
                            $codeBlock .= $spacesToAdd;
                            }
                        else
                            {
                            $codeBlock =~ s/^(.)/$spacesToAdd . $1/gme;
                            $removedCodeSpaces = length($spaces);
                            };
                        };

                    $codeBlock .= $code . "\n";
                    $prevCodeLineBlank = undef;
                    }
                else # (!length $code)
                    {
                    if (!$prevCodeLineBlank)
                        {
                        $codeBlock .= "\n";
                        $prevCodeLineBlank = 1;
                        };
                    };

                $prevLineBlank = undef;
                }
            else # $topLevelTag != TAG_CODE
                {
                if (defined $textBlock)
                    {
                    $output .= $self->RichFormatTextBlock($textBlock) . $tagEnders{$topLevelTag};
                    $textBlock = undef;
                    };

                if (defined $code)
                    {
                    $topLevelTag = TAG_CODE;
                    $output .= '<code>';
                    $codeBlock = $code . "\n";
                    $removedCodeSpaces = length($spaces);
                    $prevCodeLineBlank = undef;
                    }
                else
                    {
                    # Ignore leading blank lines and empty code sections.
                    $topLevelTag = TAG_NONE;
                    };

                $prevLineBlank = undef;
                };
            }

        # If the line doesn't start with a code designator...
        else
            {
            # If we were in a code section...
            if ($topLevelTag == TAG_CODE)
                {
                $codeBlock =~ s/\n+$//;
                $output .= NaturalDocs::NDMarkup->ConvertAmpChars($codeBlock) . '</code>';
                $codeBlock = undef;
                $topLevelTag = TAG_NONE;
                };


            # If the line is blank...
            if (!length($commentLines->[$index]))
                {
                # End a paragraph.  Everything else ignores it for now.
                if ($topLevelTag == TAG_PARAGRAPH)
                    {
                    $output .= $self->RichFormatTextBlock($textBlock) . '</p>';
                    $textBlock = undef;
                    $topLevelTag = TAG_NONE;
                    };

                $prevLineBlank = 1;
                }

            # If the line starts with a bullet...
            elsif ($commentLines->[$index] =~ /^[-\*o+] +([^ ].*)$/)
                {
                my $bulletedText = $1;

                if (defined $textBlock)
                    {  $output .= $self->RichFormatTextBlock($textBlock);  };

                if ($topLevelTag == TAG_BULLETLIST)
                    {
                    $output .= '</li><li>';
                    }
                else #($topLevelTag != TAG_BULLETLIST)
                    {
                    $output .= $tagEnders{$topLevelTag} . '<ul><li>';
                    $topLevelTag = TAG_BULLETLIST;
                    };

                $textBlock = $bulletedText;

                $prevLineBlank = undef;
                }

            # If the line looks like a description list entry...
            elsif ($commentLines->[$index] =~ /^(.+?) +- +([^ ].*)$/)
                {
                my $entry = $1;
                my $description = $2;

                if (defined $textBlock)
                    {  $output .= $self->RichFormatTextBlock($textBlock);  };

                if ($topLevelTag == TAG_DESCRIPTIONLIST)
                    {
                    $output .= '</dd>';
                    }
                else #($topLevelTag != TAG_DESCRIPTIONLIST)
                    {
                    $output .= $tagEnders{$topLevelTag} . '<dl>';
                    $topLevelTag = TAG_DESCRIPTIONLIST;
                    };

                if (NaturalDocs::Topics->IsList($type))
                    {
                    $output .= '<ds>' . NaturalDocs::NDMarkup->ConvertAmpChars($entry) . '</ds><dd>';
                    }
                else
                    {
                    $output .= '<de>' . NaturalDocs::NDMarkup->ConvertAmpChars($entry) . '</de><dd>';
                    };

                $textBlock = $description;

                $prevLineBlank = undef;
                }

            # If the line could be a header...
            elsif ($prevLineBlank && $commentLines->[$index] =~ /^(.*)([^ ]):$/)
                {
                my $headerText = $1 . $2;

                if (defined $textBlock)
                    {
                    $output .= $self->RichFormatTextBlock($textBlock);
                    $textBlock = undef;
                    }

                $output .= $tagEnders{$topLevelTag};
                $topLevelTag = TAG_NONE;

                $output .= '<h>' . $self->RichFormatTextBlock($headerText) . '</h>';

                $prevLineBlank = undef;
                }

            # If the line isn't any of those, we consider it normal text.
            else
                {
                # A blank line followed by normal text ends lists.  We don't handle this when we detect if the line's blank because
                # we don't want blank lines between list items to break the list.
                if ($prevLineBlank && ($topLevelTag == TAG_BULLETLIST || $topLevelTag == TAG_DESCRIPTIONLIST))
                    {
                    $output .= $self->RichFormatTextBlock($textBlock) . $tagEnders{$topLevelTag} . '<p>';

                    $topLevelTag = TAG_PARAGRAPH;
                    $textBlock = undef;
                    }

                elsif ($topLevelTag == TAG_NONE)
                    {
                    $output .= '<p>';
                    $topLevelTag = TAG_PARAGRAPH;
                    # textBlock will already be undef.
                    };

                if (defined $textBlock)
                    {  $textBlock .= ' ';  };

                $textBlock .= $commentLines->[$index];

                $prevLineBlank = undef;
                };
            };

        $index++;
        };

    # Clean up anything left dangling.
    if (defined $textBlock)
        {
        $output .= $self->RichFormatTextBlock($textBlock) . $tagEnders{$topLevelTag};
        }
    elsif (defined $codeBlock)
        {
        $codeBlock =~ s/\n+$//;
        $output .= NaturalDocs::NDMarkup->ConvertAmpChars($codeBlock) . '</code>';
        };

    return $output;
    };


#
#   Function: RichFormatTextBlock
#
#   Applies rich <NDMarkup> formatting to a chunk of text.  This includes both amp chars, formatting tags, and link tags.
#
#   Parameters:
#
#       text    - The block of text to format.
#
#   Returns:
#
#       The formatted text block.
#
sub RichFormatTextBlock #(text)
    {
    my ($self, $text) = @_;
    my $output;


    # Split the text from the potential tags.

    my @tempTextBlocks = split(/([\*_<>])/, $text);

    # Since the symbols are considered dividers, empty strings could appear between two in a row or at the beginning/end of the
    # array.  This could seriously screw up TagType(), so we need to get rid of them.
    my @textBlocks;

    while (scalar @tempTextBlocks)
        {
        my $tempTextBlock = shift @tempTextBlocks;

        if (length $tempTextBlock)
            {  push @textBlocks, $tempTextBlock;  };
        };


    my $bold;
    my $underline;
    my $underlineHasWhitespace;

    my $index = 0;

    while ($index < scalar @textBlocks)
        {
        if ($textBlocks[$index] eq '<' && $self->TagType(\@textBlocks, $index) == POSSIBLE_OPENING_TAG)
            {
            my $endingIndex = $self->ClosingTag(\@textBlocks, $index, undef);

            if ($endingIndex != -1)
                {
                my $linkText;
                $index++;

                while ($index < $endingIndex)
                    {
                    $linkText .= $textBlocks[$index];
                    $index++;
                    };
                # Index will be incremented again at the end of the loop.

                if ($linkText =~ /^(?:mailto\:)?((?:[a-z0-9\-_]+\.)*[a-z0-9\-_]+@(?:[a-z0-9\-]+\.)+[a-z]{2,4})$/i)
                    {  $output .= '<email>' . NaturalDocs::NDMarkup->ConvertAmpChars($1) . '</email>';  }
                elsif ($linkText =~ /^(?:http|https|ftp|news|file)\:[a-z0-9\-\=\~\@\#\%\&\_\+\/\?\.\,]+$/i)
                    {  $output .= '<url>' . NaturalDocs::NDMarkup->ConvertAmpChars($linkText ). '</url>';  }
                else
                    {  $output .= '<link>' . NaturalDocs::NDMarkup->ConvertAmpChars($linkText) . '</link>';  };
                }

            else # it's not a link.
                {
                $output .= '&lt;';
                };
            }

        elsif ($textBlocks[$index] eq '*')
            {
            my $tagType = $self->TagType(\@textBlocks, $index);

            if ($tagType == POSSIBLE_OPENING_TAG && $self->ClosingTag(\@textBlocks, $index, undef) != -1)
                {
                # ClosingTag() makes sure tags aren't opened multiple times in a row.
                $bold = 1;
                $output .= '<b>';
                }
            elsif ($bold && $tagType == POSSIBLE_CLOSING_TAG)
                {
                $bold = undef;
                $output .= '</b>';
                }
            else
                {
                $output .= '*';
                };
            }

        elsif ($textBlocks[$index] eq '_')
            {
            my $tagType = $self->TagType(\@textBlocks, $index);

             if ($tagType == POSSIBLE_OPENING_TAG && $self->ClosingTag(\@textBlocks, $index, \$underlineHasWhitespace) != -1)
                {
                # ClosingTag() makes sure tags aren't opened multiple times in a row.
                $underline = 1;
                #underlineHasWhitespace is set by ClosingTag().
                $output .= '<u>';
                }
            elsif ($underline && $tagType == POSSIBLE_CLOSING_TAG)
                {
                $underline = undef;
                #underlineHasWhitespace will be reset by the next opening underline.
                $output .= '</u>';
                }
            elsif ($underline && !$underlineHasWhitespace)
                {
                # If there's no whitespace between underline tags, all underscores are replaced by spaces so
                # _some_underlined_text_ becomes <u>some underlined text</u>.  The standard _some underlined text_
                # will work too.
                $output .= ' ';
                }
            else
                {
                $output .= '_';
                };
            }

        else # plain text or a > that isn't part of a link
            {
            my $text = NaturalDocs::NDMarkup->ConvertAmpChars($textBlocks[$index]);

            $text =~ s{
                                # The previous character can't be an alphanumeric.
                                (?<!  [a-z0-9]  )

                                # Optional mailto:.  Ignored in output.
                                (?:mailto\:)?

                                # Begin capture
                                (

                                # The user portion.  Alphanumeric and - _.  Dots can appear between, but not at the edges or more than
                                # one in a row.
                                (?:  [a-z0-9\-_]+  \.  )*   [a-z0-9\-_]+

                                @

                                # The domain.  Alphanumeric and -.  Dots same as above, however, there must be at least two sections
                                # and the last one must be two to four alphanumeric characters (.com, .uk, .info, .203 for IP addresses)
                                (?:  [a-z0-9\-]+  \.  )+  [a-z]{2,4}

                                # End capture.
                                )

                                # The next character can't be an alphanumeric, which should prevent .abcde from matching the two to
                                # four character requirement.
                                (?!  [a-z0-9]  )

                                }

                           {<email>$1<\/email>}igx;

            $text =~ s{
                                # The previous character can't be an alphanumeric.
                                (?<!  [a-z0-9]  )

                                # Begin capture.
                                (

                                # URL must start with one of the acceptable protocols.
                                (?:http|https|ftp|news|file)\:

                                # The acceptable URL characters as far as I know.
                                [a-z0-9\-\=\~\@\#\%\&\_\+\/\?\.\,]*

                                # The URL characters minus period, comma, and question mark.  If it ends on them, they're probably
                                # intended as punctuation.
                                [a-z0-9\-\~\@\#\%\&\_\+\/]

                                # End capture.
                                )

                                # The next character must not be an acceptable character.  This will prevent the URL from ending early just
                                # to get a match.
                                (?!  [a-z0-9\-\~\@\#\%\&\_\+\/]  )

                                }
                               {<url>$1<\/url>}igx;

            $output .= $text;
            };

        $index++;
        };

    return $output;
    };


#
#   Function: TagType
#
#   Returns whether the tag is a possible opening or closing tag, or neither.  "Possible" because it doesn't check if an opening tag is
#   closed or a closing tag is opened, just whether the surrounding characters allow it to be a candidate for a tag.  For example, in
#   "A _B" the underscore is a possible opening underline tag, but in "A_B" it is not.  Support function for <RichFormatTextBlock()>.
#
#   Parameters:
#
#       textBlocks  - A reference to an array of text blocks.
#       index         - The index of the tag.
#
#   Returns:
#
#       POSSIBLE_OPENING_TAG, POSSIBLE_CLOSING_TAG, or NOT_A_TAG.
#
sub TagType #(textBlocks, index)
    {
    my ($self, $textBlocks, $index) = @_;


    # Possible opening tags

    if ( ( $textBlocks->[$index] =~ /^[\*_<]$/ ) &&

        # Before it must be whitespace, the beginning of the text, or ({["'-/.
        ( $index == 0 || $textBlocks->[$index-1] =~ /[\ \t\n\(\{\[\"\'\-\/]$/ )&&

        # After it must be non-whitespace.
        ( $index + 1 < scalar @$textBlocks && $textBlocks->[$index+1] !~ /^[\ \t\n]/) &&

        # Make sure we don't accept <<, <=, <-, or *= as opening tags
        ( $textBlocks->[$index] ne '<' || $textBlocks->[$index+1] !~ /^[<=-]/ ) &&
        ( $textBlocks->[$index] ne '*' || $textBlocks->[$index+1] !~ /^\=/ ) )
        {
        return POSSIBLE_OPENING_TAG;
        }


    # Possible closing tags

    elsif ( ( $textBlocks->[$index] =~ /^[\*_>]$/) &&

            # After it must be whitespace, the end of the text, or )}].,!?"';:-/.
            ( $index + 1 == scalar @$textBlocks || $textBlocks->[$index+1] =~ /^[ \t\n\)\]\}\.\,\!\?\"\'\;\:\-\/]/ ||
              # Links also get plurals, like <link>s, <linx>es, <link>'s, and <links>'.
              ( $textBlocks->[$index] eq '>' && $textBlocks->[$index+1] =~ /^(?:es|s|\')/ ) ) &&

            # Before it must be non-whitespace.
            ( $index != 0 && $textBlocks->[$index-1] !~ /[ \t\n]$/ ) &&

            # Make sure we don't accept >>, ->, or => as closing tags.  >= is already taken care of.
            ( $textBlocks->[$index] ne '>' || $textBlocks->[$index-1] !~ /[>=-]$/ ) )
        {
        return POSSIBLE_CLOSING_TAG;
        }

    else
        {
        return NOT_A_TAG;
        };

    };


#
#   Function: ClosingTag
#
#   Returns whether a tag is closed or not, where it's closed if it is, and optionally whether there is any whitespace between the
#   tags.  Support function for <RichFormatTextBlock()>.
#
#   The results of this function are in full context, meaning that if it says a tag is closed, it can be interpreted as that tag in the
#   final output.  It takes into account any spoiling factors, like there being two opening tags in a row.
#
#   Parameters:
#
#       textBlocks             - A reference to an array of text blocks.
#       index                    - The index of the opening tag.
#       hasWhitespaceRef  - A reference to the variable that will hold whether there is whitespace between the tags or not.  If
#                                     undef, the function will not check.  If the tag is not closed, the variable will not be changed.
#
#   Returns:
#
#       If the tag is closed, it returns the index of the closing tag and puts whether there was whitespace between the tags in
#       hasWhitespaceRef if it was specified.  If the tag is not closed, it returns -1 and doesn't touch the variable pointed to by
#       hasWhitespaceRef.
#
sub ClosingTag #(textBlocks, index, hasWhitespace)
    {
    my ($self, $textBlocks, $index, $hasWhitespaceRef) = @_;

    my $hasWhitespace;
    my $closingTag;

    if ($textBlocks->[$index] eq '*' || $textBlocks->[$index] eq '_')
        {  $closingTag = $textBlocks->[$index];  }
    elsif ($textBlocks->[$index] eq '<')
        {  $closingTag = '>';  }
    else
        {  return -1;  };

    my $beginningIndex = $index;
    $index++;

    while ($index < scalar @$textBlocks)
        {
        if ($textBlocks->[$index] eq '<' && $self->TagType($textBlocks, $index) == POSSIBLE_OPENING_TAG)
            {
            # If we hit a < and we're checking whether a link is closed, it's not.  The first < becomes literal and the second one
            # becomes the new link opening.
            if ($closingTag eq '>')
                {
                return -1;
                }

            # If we're not searching for the end of a link, we have to skip the link because formatting tags cannot appear within
            # them.  That's of course provided it's closed.
            else
                {
                my $linkHasWhitespace;

                my $endIndex = $self->ClosingTag($textBlocks, $index,
                                                                    ($hasWhitespaceRef && !$hasWhitespace ? \$linkHasWhitespace : undef) );

                if ($endIndex != -1)
                    {
                    if ($linkHasWhitespace)
                        {  $hasWhitespace = 1;  };

                    # index will be incremented again at the end of the loop, which will bring us past the link's >.
                    $index = $endIndex;
                    };
                };
            }

        elsif ($textBlocks->[$index] eq $closingTag)
            {
            my $tagType = $self->TagType($textBlocks, $index);

            if ($tagType == POSSIBLE_CLOSING_TAG)
                {
                # There needs to be something between the tags for them to count.
                if ($index == $beginningIndex + 1)
                    {  return -1;  }
                else
                    {
                    # Success!

                    if ($hasWhitespaceRef)
                        {  $$hasWhitespaceRef = $hasWhitespace;  };

                    return $index;
                    };
                }

            # If there are two opening tags of the same type, the first becomes literal and the next becomes part of a tag.
            elsif ($tagType == POSSIBLE_OPENING_TAG)
                {  return -1;  }
            }

        elsif ($hasWhitespaceRef && !$hasWhitespace)
            {
            if ($textBlocks->[$index] =~ /[ \t\n]/)
                {  $hasWhitespace = 1;  };
            };

        $index++;
        };

    # Hit the end of the text blocks if we're here.
    return -1;
    };


1;
