###############################################################################
#
#   Package: NaturalDocs::Parser
#
###############################################################################
#
#   A package that coordinates source file parsing between the <NaturalDocs::Languages::Base>-derived objects and its own
#   sub-packages such as <NaturalDocs::Parser::Native>.  Also handles sending symbols to <NaturalDocs::SymbolTable> and
#   other generic topic processing.
#
#   Usage and Dependencies:
#
#       - Prior to use, <NaturalDocs::Settings>, <NaturalDocs::Languages>, <NaturalDocs::Project>, <NaturalDocs::SymbolTable>,
#         and <NaturalDocs::ClassHierarchy> must be initialized.  <NaturalDocs::SymbolTable> and <NaturalDocs::ClassHierarchy>
#         do not have to be fully resolved.
#
#       - Aside from that, the package is ready to use right away.  It does not have its own initialization function.
#
###############################################################################

# This file is part of Natural Docs, which is Copyright © 2003-2004 Greg Valure
# Natural Docs is licensed under the GPL

use NaturalDocs::Parser::ParsedTopic;
use NaturalDocs::Parser::Native;

use strict;
use integer;

package NaturalDocs::Parser;



###############################################################################
# Group: Variables


#
#   var: sourceFile
#
#   The name of the source file currently being parsed.
#
my $sourceFile;

#
#   Array: parsedFile
#
#   An array of <NaturalDocs::Parser::ParsedTopic> objects.
#
my @parsedFile;


#
#   bool: parsingForInformation
#   Whether <ParseForInformation()> was called.  If false, then <ParseForBuild()> was called.
#
my $parsingForInformation;



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
    $sourceFile = $file;

    $parsingForInformation = 1;

    # Watch this parse so we detect any changes.
    NaturalDocs::SymbolTable->WatchFileForChanges($sourceFile);
    NaturalDocs::ClassHierarchy->WatchFileForChanges($sourceFile);

    my $defaultMenuTitle = $self->Parse();

    foreach my $topic (@parsedFile)
        {
        # Add a symbol for the topic.

        NaturalDocs::SymbolTable->AddSymbol($topic->Class(), $topic->Name(), $sourceFile, $topic->Type(),
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
                                                                          $sourceFile, $listType, undef, $listSummary);
                };
            };


        # Add references in the topic.

        while ($body =~ /<link>([^<]+)<\/link>/g)
            {
            NaturalDocs::SymbolTable->AddReference($topic->Scope(), NaturalDocs::NDMarkup->RestoreAmpChars($1),
                                                                           $sourceFile);
            };
        };

    # Handle any changes to the file.
    NaturalDocs::ClassHierarchy->AnalyzeChanges();
    NaturalDocs::SymbolTable->AnalyzeChanges();

    # Update project on the file's characteristics.
    my $hasContent = (scalar @parsedFile > 0);

    NaturalDocs::Project->SetHasContent($sourceFile, $hasContent);
    if ($hasContent)
        {  NaturalDocs::Project->SetDefaultMenuTitle($sourceFile, $defaultMenuTitle);  };

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
    $sourceFile = $file;

    $parsingForInformation = undef;

    $self->Parse();

    return \@parsedFile;
    };



###############################################################################
# Group: Interface Functions


#
#   Function: OnComment
#
#   The function called by <NaturalDocs::Languages::Base>-derived objects when their parsers encounter a comment
#   suitable for documentation.
#
#   Parameters:
#
#       commentLines - An arrayref of the comment's lines.  The language's comment symbols should be converted to spaces,
#                               and there should be no line break characters at the end of each line.  *The original memory may be
#                               changed.*
#       lineNumber - The line number of the first of the comment lines.
#
#   Returns:
#
#       The number of topics created by this comment, or zero if none.
#
sub OnComment #(commentLines, lineNumber)
    {
    my ($self, $commentLines, $lineNumber) = @_;

    $self->CleanComment($commentLines);

    return NaturalDocs::Parser::Native->ParseComment($commentLines, $lineNumber, \@parsedFile);
    };


#
#   Function: OnClass
#
#   A function called by <NaturalDocs::Languages::Base>-derived objects when their parsers encounter a class declaration.
#
#   Parameters:
#
#       class - The class encountered.
#
sub OnClass #(class)
    {
    my ($self, $class) = @_;

    if ($parsingForInformation)
        {  NaturalDocs::ClassHierarchy->AddClass($sourceFile, $class);  };
    };


#
#   Function: OnClassParent
#
#   A function called by <NaturalDocs::Languages::Base>-derived objects when their parsers encounter a declaration of
#   inheritance.
#
#   Parameters:
#
#       class - The class we're in.
#       parent - The class it inherits.
#       protection - Public/private/protected, if applicable.  Undef otherwise.
#
sub OnClassParent #(class, parent, protection)
    {
    my ($self, $class, $parent, $protection) = @_;

    if ($parsingForInformation)
        {  NaturalDocs::ClassHierarchy->AddParent($sourceFile, $class, $parent);  };
    };



###############################################################################
# Group: Support Functions


#   Function: Parse
#
#   Opens the source file and parses process.  Most of the actual parsing is done in <NaturalDocs::Languages::Base->ParseFile()>
#   and <OnComment()>, though.
#
#   *Do not call externally.*  Rather, call <ParseForInformation()> or <ParseForBuild()>.
#
#   Returns:
#
#       The default menu title of the file.  Will be the file name if nothing better is found.
#
sub Parse
    {
    my ($self) = @_;

    my $language = NaturalDocs::Languages->LanguageOf($sourceFile);
    NaturalDocs::Parser::Native->Start();
    @parsedFile = ( );

    my ($autoTopics, $scopeRecord) = $language->ParseFile($sourceFile, \@parsedFile);


    # Set the menu title.

    my $defaultMenuTitle = $sourceFile;

    if (scalar @parsedFile)
        {
        my $firstType = $parsedFile[0]->Type();

        # If there's only one topic, it's title overrides the file name.  If there's more than one topic but the first one is a section, file,
        # or class, it's title overrides the file name as well.
        if (scalar @parsedFile == 1 ||
            $firstType == ::TOPIC_SECTION() || $firstType == ::TOPIC_FILE() || $firstType == ::TOPIC_CLASS())
            {
            $defaultMenuTitle = $parsedFile[0]->Name();
            }
        else
            {
            # If the title ended up being the file name, add a leading section for it.
            my $name;

            my ($volume, $dirString, $file) = NaturalDocs::File->SplitPath($sourceFile);
            my @directories = NaturalDocs::File->SplitDirectories($dirString);

            if (scalar @directories > 2)
                {
                $dirString = NaturalDocs::File->JoinDirectories('...', $directories[-2], $directories[-1]);
                $name = NaturalDocs::File->JoinPath(undef, $dirString, $file);
                }
            else
                {  $name = $file;  };

            unshift @parsedFile,
                       NaturalDocs::Parser::ParsedTopic->New(::TOPIC_SECTION(), $name, undef, undef, undef, undef, undef);
            };

        # We only want to call the hook if it has content.
        NaturalDocs::Extensions->AfterFileParsed($sourceFile, \@parsedFile);
        };

    $self->AddToClassHierarchy();

    if (defined $autoTopics)
        {
        if (defined $scopeRecord)
            {  $self->RepairScope($autoTopics, $scopeRecord);  };

        $self->MergeAutoTopics($language, $autoTopics);
        };

    $self->MakeAutoGroups($autoTopics);

    # We don't need to do this if there aren't any auto-topics because the only scope changes would be implied by the comments.
    if (defined $autoTopics)
        {  $self->AddScopeDelineators();  };

    return $defaultMenuTitle;
    };


#
#   Function: CleanComment
#
#   Removes any extraneous formatting and whitespace from the comment.  Eliminates comment boxes, horizontal lines, leading
#   and trailing line breaks, trailing whitespace from lines, and expands all tab characters.  It keeps leading whitespace, though,
#   since it may be needed for example code, and multiple blank lines, since the original line numbers are needed.
#
#   Parameters:
#
#       commentLines  - An arrayref of the comment lines to clean.  *The original memory will be changed.*  Lines should have the
#                                language's comment symbols replaced by spaces and not have a trailing line break.
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
        # Strip trailing whitespace from the original.

        $commentLines->[$index] =~ s/[ \t]+$//;


        # Expand tabs in the original.  This method is almost six times faster than Text::Tabs' method.

        my $tabIndex = index($commentLines->[$index], "\t");

        while ($tabIndex != -1)
            {
            substr( $commentLines->[$index], $tabIndex, 1, ' ' x ($tabLength - ($tabIndex % $tabLength)) );
            $tabIndex = index($commentLines->[$index], "\t", $tabIndex);
            };


        # Make a working copy and strip leading whitespace as well.  This has to be done after tabs are expanded because
        # stripping indentation could change how far tabs are expanded.

        my $line = $commentLines->[$index];
        $line =~ s/^ +//;

        # If the line is blank...
        if (!length $line)
            {
            # If we have a potential vertical line, this only acceptable if it's at the end of the comment.
            if ($leftSide == IS_UNIFORM)
                {  $leftSide = IS_UNIFORM_IF_AT_END;  };
            if ($rightSide == IS_UNIFORM)
                {  $rightSide = IS_UNIFORM_IF_AT_END;  };
            }

        # If there's at least four symbols in a row, it's a horizontal line.  The second regex supports differing edge characters.  It
        # doesn't matter if any of this matches the left and right side symbols.
        elsif ($line =~ /^([^a-zA-Z0-9 ])\1{3,}$/ ||
                $line =~ /^([^a-zA-Z0-9 ])\1*([^a-zA-Z0-9 ])\2{3,}([^a-zA-Z0-9 ])\3*$/)
            {
            # Convert the original to a blank line.
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
                if ($line =~ /^([^a-zA-Z0-9])\1*(?: |$)/)
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
                if ($line =~ / ([^a-zA-Z0-9])\1*$/)
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

    while ($index < scalar @$commentLines)
        {
        # Clear vertical lines.

        if ($leftSide == IS_UNIFORM)
            {
            # This works because every line should either start this way or be blank.
            $commentLines->[$index] =~ s/ *([^a-zA-Z0-9 ])\1*//;
            };

        if ($rightSide == IS_UNIFORM)
            {
            $commentLines->[$index] =~ s/ *([^a-zA-Z0-9 ])\1*$//;
            };


        # Clear horizontal lines again if there were vertical lines.  This catches lines that were separated from the verticals by
        # whitespace.  We couldn't do this in the first loop because that would make the regexes over-tolerant.

        if ($leftSide == IS_UNIFORM || $rightSide == IS_UNIFORM)
            {
            $commentLines->[$index] =~ s/^ *([^a-zA-Z0-9 ])\1{3,}$//;
            $commentLines->[$index] =~ s/^ *([^a-zA-Z0-9 ])\1*([^a-zA-Z0-9 ])\2{3,}([^a-zA-Z0-9 ])\3*$//;
            };


        $index++;
       };

    };



###############################################################################
# Group: Processing Functions


#
#   Function: MakeAutoGroups
#
#   Creates group topics for files that do not have them.
#
sub MakeAutoGroups
    {
    my ($self) = @_;

    # No groups if less than four topics.
    if (scalar @parsedFile < 4)
        {  return;  };

    my $index = 0;
    my $currentScope;
    my $currentScopeIndex = 0;

    while ($index < scalar @parsedFile)
        {
        if ($parsedFile[$index]->Scope() ne $currentScope)
            {
            $index += $self->MakeAutoGroupsFor($currentScopeIndex, $index);
            $currentScope = $parsedFile[$index]->Scope();
            $currentScopeIndex = $index;
            };

        $index++;
        };

    $self->MakeAutoGroupsFor($currentScopeIndex, $index);
    };


#
#   Function: MakeAutoGroupsFor
#
#   Creates group topics for sections of files that do not have them.  A support function for <MakeAutoGroups()>.
#
#   Parameters:
#
#       startIndex - The index to start at.
#       endIndex - The index to end at.  Not inclusive.
#
#   Returns:
#
#       The number of group topics added.
#
sub MakeAutoGroupsFor #(startIndex, endIndex)
    {
    my ($self, $startIndex, $endIndex) = @_;

    # No groups if any are defined already.
    for (my $i = $startIndex; $i < $endIndex; $i++)
        {
        if ($parsedFile[$i]->Type() == ::TOPIC_GROUP())
            {  return 0;  };
        };

    my $currentType;
    my $groupCount = 0;

    while ($startIndex < $endIndex)
        {
        my $topic = $parsedFile[$startIndex];
        my $type = $topic->Type();

        if (NaturalDocs::Topics->IsList($type))
            {  $type = NaturalDocs::Topics->IsListOf($type);  };

        if ($type != $currentType && NaturalDocs::Topics->IsAutoGroupable($type))
            {
            splice(@parsedFile, $startIndex, 0, NaturalDocs::Parser::ParsedTopic->New(::TOPIC_GROUP(),
                                                                                                                          NaturalDocs::Topics->PluralNameOf($type),
                                                                                                                          $topic->Scope(), $topic->Scope(),
                                                                                                                          undef, undef, undef,
                                                                                                                          $topic->LineNumber()) );

            $currentType = $type;
            $startIndex++;
            $endIndex++;
            $groupCount++;
            }

        elsif ($topic->Type() == ::TOPIC_CLASS())
            {
            $currentType = undef;
            };

        $startIndex++;
        };

    return $groupCount;
    };


#
#   Function: RepairScope
#
#   Recalculates the scope for all comment topics using the auto-topics and the scope record.  Call this *before* calling
#   <MergeAutoTopics()>.
#
#   Parameters:
#
#       autoTopics - A reference to the list of automatically generated topics.
#       scopeRecord - A reference to an array of <NaturalDocs::Languages::Advanced::ScopeChanges>.
#
sub RepairScope #(autoTopics, scopeRecord)
    {
    my ($self, $autoTopics, $scopeRecord) = @_;

    my $topicIndex = 0;
    my $autoTopicIndex = 0;
    my $scopeIndex = 0;

    my $topic = $parsedFile[0];
    my $autoTopic = $autoTopics->[0];
    my $scopeChange = $scopeRecord->[0];

    my $currentScope;
    my $inFakeScope;

    while (defined $topic)
        {
        # First update the scope via the record if its defined and has the lowest line number.
        if (defined $scopeChange &&
            $scopeChange->LineNumber() <= $topic->LineNumber() &&
            (!defined $autoTopic || $scopeChange->LineNumber() <= $autoTopic->LineNumber()) )
            {
            $currentScope = $scopeChange->Scope();
            $scopeIndex++;
            $scopeChange = $scopeRecord->[$scopeIndex];  # Will be undef when past end.
            $inFakeScope = undef;
            }

        # Next try to end a fake scope with an auto topic if its defined and has the lowest line number.
        elsif (defined $autoTopic &&
                $autoTopic->LineNumber() <= $topic->LineNumber())
            {
            if ($inFakeScope)
                {
                $currentScope = $autoTopic->Scope();
                $inFakeScope = undef;
                };

            $autoTopicIndex++;
            $autoTopic = $autoTopics->[$autoTopicIndex];  # Will be undef when past end.
            }


        # Finally try to handle the topic, since it has the lowest line number.
        else
            {
            if ($topic->Type() == ::TOPIC_CLASS() || $topic->Type() == ::TOPIC_SECTION())
                {
                # They should already have the correct class and scope.
                $currentScope = $topic->Scope();
                $inFakeScope = 1;
                }
            elsif ($topic->Type() == ::TOPIC_FILE() || $topic->Type() == ::TOPIC_FILE_LIST())
                {
                # Fix the file's scope.  The class should be correct.
                $topic->SetScope($currentScope);
                }
           else
                {
                # Fix the class and scope of everything not handled above, which includes functions, variables, and types.

                # Note that the first function or variable topic to appear in a fake scope will assume that scope even if it turns out
                # to be incorrect in the actual code, since the topic will come before the auto-topic.  This will be corrected in
                # MergeAutoTopics().

                $topic->SetClass($currentScope);
                $topic->SetScope($currentScope);
                };

            $topicIndex++;
            $topic = $parsedFile[$topicIndex];  # Will be undef when past end.
            };
        };

    };


#
#   Function: AddToClassHierarchy
#
#   Adds any class topics to the class hierarchy, since they may not have been called with <OnClass()> if they didn't match up to
#   an auto-topic.
#
sub AddToClassHierarchy
    {
    my ($self) = @_;

    foreach my $topic (@parsedFile)
        {
        if ($topic->Type() == ::TOPIC_CLASS())
            {
            $self->OnClass($topic->Name());
            };
        };
    };


#
#   Function: MergeAutoTopics
#
#   Merges the automatically generated topics into the file.  If an auto-topic matches an existing topic, it will be deleted and,
#   if appropriate, have it's prototype, class, and scope transferred.  If it doesn't, the auto-topic will be inserted into the list unless
#   <NaturalDocs::Settings->DocumentedOnly()> is set.
#
#   Parameters:
#
#       language - The <NaturalDocs::Languages::Base>-derived class for the file.
#       autoTopics - A reference to the list of automatically generated topics.
#
sub MergeAutoTopics #(language, autoTopics)
    {
    my ($self, $language, $autoTopics) = @_;

    my $topicIndex = 0;
    my $autoTopicIndex = 0;

    my %functionsInLists;
    my %variablesInLists;

    while ($topicIndex < scalar @parsedFile && $autoTopicIndex < scalar @$autoTopics)
        {
        my $topic = $parsedFile[$topicIndex];
        my $autoTopic = $autoTopics->[$autoTopicIndex];

        # Add the auto-topic if it's higher in the file than the current topic.
        if ($autoTopic->LineNumber < $topic->LineNumber())
            {
            if ($autoTopic->Type() == ::TOPIC_FUNCTION() &&
                exists $functionsInLists{$autoTopic->Name()})
                {
                delete $functionsInLists{$autoTopic->Name()};
                }
            elsif ($autoTopic->Type() == ::TOPIC_VARIABLE() &&
                    exists $variablesInLists{$autoTopic->Name()})
                {
                delete $variablesInLists{$autoTopic->Name()};
                }
            elsif (!NaturalDocs::Settings->DocumentedOnly())
                {
                splice(@parsedFile, $topicIndex, 0, $autoTopic);
                $topicIndex++;
                };

            $autoTopicIndex++;
            }

        # Transfer information if we have a match.
        elsif ($topic->Type() == $autoTopic->Type() &&
                index($topic->Name(), $language->MakeSortableSymbol($autoTopic->Name(), $autoTopic->Type())) != -1)
            {
            $topic->SetPrototype($autoTopic->Prototype());
            $topic->SetClass($autoTopic->Class());
            $topic->SetScope($autoTopic->Scope());

            $topicIndex++;
            $autoTopicIndex++;
            }

        # Extract functions and variables in lists.
        elsif ($topic->Type() == ::TOPIC_FUNCTION_LIST())
            {
            my $body = $topic->Body();

            while ($body =~ /<ds>([^<]+)<\/ds>/g)
                {  $functionsInLists{$1} = 1;  };

            $topicIndex++;
            }
        elsif ($topic->Type() == ::TOPIC_VARIABLE_LIST())
            {
            my $body = $topic->Body();

            while ($body =~ /<ds>([^<]+)<\/ds>/g)
                {  $variablesInLists{$1} = 1;  };

            $topicIndex++;
            }

        # Otherwise there's no match.  Skip the topic.  The auto-topic will be added later.
        else
            {
            $topicIndex++;
            }
        };

    # Add any auto-topics remaining.
    if ($autoTopicIndex < scalar @$autoTopics && !NaturalDocs::Settings->DocumentedOnly())
        {
        push @parsedFile, @$autoTopics[$autoTopicIndex..scalar @$autoTopics-1];
        };
    };


#
#   Function: AddScopeDelineators
#
#   Adds section and class topics to make sure the scope is correctly represented in the documentation.  Should be called last in
#   this process.
#
sub AddScopeDelineators
    {
    my ($self) = @_;

    my $index = 0;
    my $currentScope;

    my %usedScopes;

    while ($index < scalar @parsedFile)
        {
        my $topic = $parsedFile[$index];

        if ($topic->Scope() ne $currentScope)
            {
            $currentScope = $topic->Scope();

            if ($topic->Type() != ::TOPIC_CLASS() && $topic->Type() != ::TOPIC_CLASS_LIST() &&
                $topic->Type() != ::TOPIC_SECTION())
                {
                my $newTopic;

                if (!defined $currentScope)
                    {
                    $newTopic = NaturalDocs::Parser::ParsedTopic->New(::TOPIC_SECTION(), 'Global',
                                                                                                   undef, undef,
                                                                                                   undef, undef, undef,
                                                                                                   $topic->LineNumber());
                    }
                else
                    {
                    my $name = $currentScope;
                    if (exists $usedScopes{$currentScope})
                        {  $name .= ' (continued)';  };

                    $newTopic = NaturalDocs::Parser::ParsedTopic->New(::TOPIC_CLASS(), $name,
                                                                                                   undef, $currentScope,
                                                                                                   undef, undef, undef,
                                                                                                   $topic->LineNumber());
                    }

                splice(@parsedFile, $index, 0, $newTopic);
                $index++;
                };

            if (defined $currentScope)
                {  $usedScopes{$currentScope} = 1;  };
            };

        $index++;
        };
    };


1;
