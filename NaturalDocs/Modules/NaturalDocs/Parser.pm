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
#   The source <FileName> currently being parsed.
#
my $sourceFile;

#
#   var: language
#
#   The language object for the file, derived from <NaturalDocs::Languages::Base>.
#
my $language;

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
#       file - The <FileName> to parse.
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

        NaturalDocs::SymbolTable->AddSymbol($topic->Symbol(), $sourceFile, $topic->Type(),
                                                                   $topic->Prototype(), $topic->Summary());


        # You can't put the function call directly in a while with a regex.  It has to sit in a variable to work.
        my $body = $topic->Body();


        # If it's a list topic, add a symbol for each description list entry.

        if (NaturalDocs::Topics->IsList($topic->Type()))
            {
            my $listType = NaturalDocs::Topics->IsListOf($topic->Type());

            while ($body =~ /<ds>([^<]+)<\/ds><dd>(.*?)<\/dd>/g)
                {
                my ($listTextSymbol, $listSummary) = ($1, $2);

                $listTextSymbol = NaturalDocs::NDMarkup->RestoreAmpChars($listTextSymbol);

                $listSummary =~ /^(.*?)($|[\.\!\?](?:[\)\}\'\ ]|&quot;|&gt;))/;
                $listSummary = $1 . $2;

                my $listSymbol = NaturalDocs::SymbolString->FromText($listTextSymbol);
                $listSymbol = NaturalDocs::SymbolString->Join($topic->Package(), $listSymbol);

                NaturalDocs::SymbolTable->AddSymbol($listSymbol, $sourceFile, $listType, undef, $listSummary);
                };
            };


        # Add references in the topic.

        while ($body =~ /<link>([^<]+)<\/link>/g)
            {
            my $linkText = NaturalDocs::NDMarkup->RestoreAmpChars($1);
            my $linkSymbol = NaturalDocs::SymbolString->FromText($linkText);

            NaturalDocs::SymbolTable->AddReference(::REFERENCE_TEXT(), $linkSymbol,
                                                                           $topic->Package(), $topic->Using(), $sourceFile);
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
#       file - The <FileName> to parse for building.
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
#                               and there should be no line break characters at the end of each line.  *The original memory will be
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
#       class - The <SymbolString> of the class encountered.
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
#       class - The <SymbolString> of the class we're in.
#       parent - The <SymbolString> of the class it inherits.
#       scope - The package <SymbolString> that the reference appeared in.
#       using - An arrayref of package <SymbolStrings> that the reference has access to via "using" statements.
#       resolvingFlags - Any <Resolving Flags> to be used when resolving the reference.  <RESOLVE_NOPLURAL> is added
#                              automatically since that would never apply to source code.
#
sub OnClassParent #(class, parent, scope, using, resolvingFlags)
    {
    my ($self, $class, $parent, $scope, $using, $resolvingFlags) = @_;

    if ($parsingForInformation)
        {
        NaturalDocs::ClassHierarchy->AddParentReference($sourceFile, $class, $parent, $scope, $using,
                                                                                   $resolvingFlags | ::RESOLVE_NOPLURAL());
        };
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
#       The default menu title of the file.  Will be the <FileName> if nothing better is found.
#
sub Parse
    {
    my ($self) = @_;

    $language = NaturalDocs::Languages->LanguageOf($sourceFile);
    NaturalDocs::Parser::Native->Start();
    @parsedFile = ( );

    my ($autoTopics, $scopeRecord, $exportedSymbols) = $language->ParseFile($sourceFile, \@parsedFile);


    $self->AddToClassHierarchy();

    if (defined $autoTopics)
        {
        if (defined $scopeRecord)
            {  $self->RepairPackages($autoTopics, $scopeRecord);  };

        $self->MergeAutoTopics($language, $autoTopics);
        };

    # We don't need to do this if there aren't any auto-topics because the only package changes would be implied by the comments.
    if (defined $autoTopics)
        {  $self->AddPackageDelineators();  };

    if (defined $exportedSymbols)
        {  $self->MatchExportedSymbols($exportedSymbols);  };

    if (NaturalDocs::Settings->AutoGroupLevel() != ::AUTOGROUP_NONE())
        {  $self->MakeAutoGroups($autoTopics);  };


    # Set the menu title.

    my $defaultMenuTitle = $sourceFile;

    if (scalar @parsedFile)
        {
        # If there's only one topic, it's title overrides the file name.  If there's more than one topic but the first one is a section, file,
        # or class, it's title overrides the file name as well.
        if (scalar @parsedFile == 1 || NaturalDocs::Topics->CanBePageTitle( $parsedFile[0]->Type() ))
            {
            $defaultMenuTitle = $parsedFile[0]->Title();
            }
        else
            {
            # If the title ended up being the file name, add a leading section for it.
            my $name;

            my ($inputDirectory, $relativePath) = NaturalDocs::Settings->SplitFromInputDirectory($sourceFile);

            my ($volume, $dirString, $file) = NaturalDocs::File->SplitPath($relativePath);
            my @directories = NaturalDocs::File->SplitDirectories($dirString);

            if (scalar @directories > 2)
                {
                $dirString = NaturalDocs::File->JoinDirectories('...', $directories[-2], $directories[-1]);
                $name = NaturalDocs::File->JoinPath(undef, $dirString, $file);
                }
            else
                {
                $name = $relativePath;
                }

            unshift @parsedFile,
                       NaturalDocs::Parser::ParsedTopic->New(::TOPIC_FILE(), $name, undef, undef, undef, undef, undef, 1);
            };

        # We only want to call the hook if it has content.
        NaturalDocs::Extensions->AfterFileParsed($sourceFile, \@parsedFile);
        };

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
#   Function: RepairPackage
#
#   Recalculates the packages for all comment topics using the auto-topics and the scope record.  Call this *before* calling
#   <MergeAutoTopics()>.
#
#   Parameters:
#
#       autoTopics - A reference to the list of automatically generated <NaturalDocs::Parser::ParsedTopics>.
#       scopeRecord - A reference to an array of <NaturalDocs::Languages::Advanced::ScopeChanges>.
#
sub RepairPackages #(autoTopics, scopeRecord)
    {
    my ($self, $autoTopics, $scopeRecord) = @_;

    my $topicIndex = 0;
    my $autoTopicIndex = 0;
    my $scopeIndex = 0;

    my $topic = $parsedFile[0];
    my $autoTopic = $autoTopics->[0];
    my $scopeChange = $scopeRecord->[0];

    my $currentPackage;
    my $inFakePackage;

    while (defined $topic)
        {
        # First update the scope via the record if its defined and has the lowest line number.
        if (defined $scopeChange &&
            $scopeChange->LineNumber() <= $topic->LineNumber() &&
            (!defined $autoTopic || $scopeChange->LineNumber() <= $autoTopic->LineNumber()) )
            {
            $currentPackage = $scopeChange->Scope();
            $scopeIndex++;
            $scopeChange = $scopeRecord->[$scopeIndex];  # Will be undef when past end.
            $inFakePackage = undef;
            }

        # Next try to end a fake scope with an auto topic if its defined and has the lowest line number.
        elsif (defined $autoTopic &&
                $autoTopic->LineNumber() <= $topic->LineNumber())
            {
            if ($inFakePackage)
                {
                $currentPackage = $autoTopic->Package();
                $inFakePackage = undef;
                };

            $autoTopicIndex++;
            $autoTopic = $autoTopics->[$autoTopicIndex];  # Will be undef when past end.
            }


        # Finally try to handle the topic, since it has the lowest line number.
        else
            {
            if (NaturalDocs::Topics->HasScope($topic->Type()) || NaturalDocs::Topics->EndsScope($topic->Type()))
                {
                # They should already have the correct class and scope.
                $currentPackage = $topic->Package();
                $inFakePackage = 1;
                }
           else
                {
                # Fix the package of everything else.

                # Note that the first function or variable topic to appear in a fake package will assume that package even if it turns out
                # to be incorrect in the actual code, since the topic will come before the auto-topic.  This will be corrected in
                # MergeAutoTopics().

                $topic->SetPackage($currentPackage);
                };

            $topicIndex++;
            $topic = $parsedFile[$topicIndex];  # Will be undef when past end.
            };
        };

    };


#
#   Function: MergeAutoTopics
#
#   Merges the automatically generated topics into the file.  If an auto-topic matches an existing topic, it will have it's prototype
#   and package transferred.  If it doesn't, the auto-topic will be inserted into the list unless
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
    my %propertiesInLists;

    while ($topicIndex < scalar @parsedFile && $autoTopicIndex < scalar @$autoTopics)
        {
        my $topic = $parsedFile[$topicIndex];
        my $autoTopic = $autoTopics->[$autoTopicIndex];

        # Add the auto-topic if it's higher in the file than the current topic.
        if ($autoTopic->LineNumber < $topic->LineNumber())
            {
            if ($autoTopic->Type() == ::TOPIC_FUNCTION() &&
                exists $functionsInLists{$autoTopic->Title()})
                {
                delete $functionsInLists{$autoTopic->Title()};
                }
            elsif ($autoTopic->Type() == ::TOPIC_VARIABLE() &&
                    exists $variablesInLists{$autoTopic->Title()})
                {
                delete $variablesInLists{$autoTopic->Title()};
                }
            # We want to accept variables documented as properties.
            elsif ( ($autoTopic->Type() == ::TOPIC_PROPERTY() || $autoTopic->Type() == ::TOPIC_VARIABLE()) &&
                    exists $propertiesInLists{$autoTopic->Title()})
                {
                delete $propertiesInLists{$autoTopic->Title()};
                }
            elsif (!NaturalDocs::Settings->DocumentedOnly())
                {
                splice(@parsedFile, $topicIndex, 0, $autoTopic);
                $topicIndex++;
                };

            $autoTopicIndex++;
            }

        # Transfer information if we have a match.  We want to accept variables documented as properties.
        elsif ( ($topic->Type() == $autoTopic->Type() ||
                   ($topic->Type() == ::TOPIC_PROPERTY() && $autoTopic->Type() == ::TOPIC_VARIABLE()) ) &&
                index($topic->Title(), $language->MakeSortableSymbol($autoTopic->Title(), $autoTopic->Type())) != -1)
            {
            $topic->SetType($autoTopic->Type());
            $topic->SetPrototype($autoTopic->Prototype());

            if (!NaturalDocs::Topics->HasScope($topic->Type()))
                {  $topic->SetPackage($autoTopic->Package());  };

            $topicIndex++;
            $autoTopicIndex++;
            }

        # Extract functions, variables, and properties in lists.
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
        elsif ($topic->Type() == ::TOPIC_PROPERTY_LIST())
            {
            my $body = $topic->Body();

            while ($body =~ /<ds>([^<]+)<\/ds>/g)
                {  $propertiesInLists{$1} = 1;  };

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
#   Function: MakeAutoGroups
#
#   Creates group topics for files that do not have them.
#
sub MakeAutoGroups
    {
    my ($self) = @_;

    # No groups only one topic.
    if (scalar @parsedFile < 2)
        {  return;  };

    my $index = 0;
    my $currentPackage;
    my $currentPackageIndex = 0;

    while ($index < scalar @parsedFile)
        {
        if ($parsedFile[$index]->Package() ne $currentPackage)
            {
            $index += $self->MakeAutoGroupsFor($currentPackageIndex, $index);
            $currentPackage = $parsedFile[$index]->Package();
            $currentPackageIndex = $index;
            };

        $index++;
        };

    $self->MakeAutoGroupsFor($currentPackageIndex, $index);
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

    # Skip the first entry if its a file.  We don't want to group it, since it should be the title of the file rather than an entry in it.
    if ($startIndex == 0 && $parsedFile[0]->Type() == ::TOPIC_FILE())
        {  $startIndex++;  };

    if ($startIndex >= $endIndex)
        {  return 0;  };

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
                                                                                                                          $topic->Package(), $topic->Using(),
                                                                                                                          undef, undef, undef,
                                                                                                                          $topic->LineNumber()) );

            $currentType = $type;
            $startIndex++;
            $endIndex++;
            $groupCount++;
            }

        elsif (NaturalDocs::Topics->HasScope($type) || NaturalDocs::Topics->EndsScope($type))
            {
            $currentType = undef;
            };

        $startIndex++;
        };

    return $groupCount;
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
            $self->OnClass($topic->Package());
            }
        elsif ($topic->Type() == ::TOPIC_CLASS_LIST())
            {
            my $body = $topic->Body();

            while ($body =~ /<ds>([^<]+)<\/ds>/g)
                {
                $self->OnClass( NaturalDocs::SymbolString->FromText($1) );
                };
            };
        };
    };


#
#   Function: MatchExportedSymbols
#
#   Determines which topics should be exported and sets <NaturalDocs::Parser::ParsedTopic->SetIsExported()> on them.
#
#   Parameters:
#
#       exportedSymbols - An existence hashref of exported symbols.  *The original memory will be changed.*
#
sub MatchExportedSymbols #(exportedSymbols)
    {
    my ($self, $exportedSymbols) = @_;

    foreach my $topic (@parsedFile)
        {
        if (NaturalDocs::Topics->IsList( $topic->Type() ))
            {
            # The regexp doesn't work directly on a function call.  It must be a variable.
            my $body = $topic->Body();

            while ($body =~ /<ds>([^<]+)<\/ds>/g)
                {
                my $listSymbol = NaturalDocs::NDMarkup->RestoreAmpChars($1);

                if (exists $exportedSymbols->{$listSymbol})
                    {
                    delete $exportedSymbols->{$listSymbol};
                    $topic->SetIsExported(1);
                    $topic->AddExportedListSymbol($listSymbol);
                    };
                };
            }
        elsif (exists $exportedSymbols->{ $topic->Title() })
            {
            delete $exportedSymbols->{ $topic->Title() };
            $topic->SetIsExported(1);
            };
        };
    };


#
#   Function: AddPackageDelineators
#
#   Adds section and class topics to make sure the package is correctly represented in the documentation.  Should be called last in
#   this process.
#
sub AddPackageDelineators
    {
    my ($self) = @_;

    my $index = 0;
    my $currentPackage;

    # Values are the arrayref [ title, type ];
    my %usedPackages;

    while ($index < scalar @parsedFile)
        {
        my $topic = $parsedFile[$index];

        if ($topic->Package() ne $currentPackage)
            {
            $currentPackage = $topic->Package();

            if (NaturalDocs::Topics->HasScope($topic->Type()))
                {
                $usedPackages{$currentPackage} = [ $topic->Title(), $topic->Type() ];
                }
            elsif (!NaturalDocs::Topics->EndsScope($topic->Type()))
                {
                my $newTopic;

                if (!defined $currentPackage)
                    {
                    $newTopic = NaturalDocs::Parser::ParsedTopic->New(::TOPIC_SECTION(), 'Global',
                                                                                                   undef, undef,
                                                                                                   undef, undef, undef,
                                                                                                   $topic->LineNumber());
                    }
                else
                    {
                    my ($title, $body, $summary, $type);
                    my @packageIdentifiers = NaturalDocs::SymbolString->IdentifiersOf($currentPackage);

                    if (exists $usedPackages{$currentPackage})
                        {
                        $title = $usedPackages{$currentPackage}->[0];
                        $type = $usedPackages{$currentPackage}->[1];
                        $body = '<p>(continued)</p>';
                        $summary = '(continued)';
                        }
                    else
                        {
                        $title = join($language->PackageSeparator(), @packageIdentifiers);
                        $type = ::TOPIC_CLASS();

                        # Body and summary stay undef.

                        $usedPackages{$currentPackage} = $title;
                        };

                    my @titleIdentifiers = NaturalDocs::SymbolString->IdentifiersOf( NaturalDocs::SymbolString->FromText($title) );
                    for (my $i = 0; $i < scalar @titleIdentifiers; $i++)
                        {  pop @packageIdentifiers;  };

                    $newTopic = NaturalDocs::Parser::ParsedTopic->New($type, $title,
                                                                                                   NaturalDocs::SymbolString->Join(@packageIdentifiers), undef,
                                                                                                   undef, $summary, $body,
                                                                                                   $topic->LineNumber());
                    }

                splice(@parsedFile, $index, 0, $newTopic);
                $index++;
                }
            };

        $index++;
        };
    };


1;
