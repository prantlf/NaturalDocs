###############################################################################
#
#   Package: NaturalDocs::Parser
#
###############################################################################
#
#   A package that coordinates source file parsing between the <NaturalDocs::Languages::Base>-derived objects and its own
#   sub-packages such as <NaturalDocs::Parser::Native>.  Also handles sending symbols to <NaturalDocs::SymbolTable>.
#
#   Usage and Dependencies:
#
#       - Prior to use, <NaturalDocs::Settings>, <NaturalDocs::Languages>, <NaturalDocs::Project>, and
#         <NaturalDocs::SymbolTable> must be initialized.  <NaturalDocs::SymbolTable> does not have to be fully resolved.
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

    my $defaultMenuTitle = $self->Parse($file);

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
#
#   Returns:
#
#       The number of topics created by this comment, or zero if none.
#
sub OnComment #(commentLines)
    {
    my ($self, $commentLines) = @_;

    $self->CleanComment($commentLines);

    return NaturalDocs::Parser::Native->ParseComment($commentLines, \@parsedFile);
    };



###############################################################################
# Group: Parser Stages
#
# Do not call these functions directly, as they are stages in the parsing process.  Rather, call <ParseForInformation()> or
# <ParseForBuild()>.


#   Function: Parse
#
#   Opens the source file and parses process.  Most of the actual parsing is done in <NaturalDocs::Languages::Base->ParseFile()>
#   and <OnComment()>, though.  Do not call directly; rather, call <ParseForInformation()> or <ParseForBuild()>.
#
#   Parameters:
#
#       file - The name of the file to parse.
#
#   Returns:
#
#       The default menu title of the file.  Will be the file name if nothing better is found.
#
sub Parse #(file)
    {
    my ($self, $file) = @_;

    my $language = NaturalDocs::Languages->LanguageOf($file);
    NaturalDocs::Parser::Native->Start();
    @parsedFile = ( );

    $language->ParseFile($file, \@parsedFile);


    # Set the menu title.

    my $defaultMenuTitle = $file;

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

            my ($volume, $dirString, $file) = NaturalDocs::File->SplitPath($file);
            my @directories = NaturalDocs::File->SplitDirectories($dirString);

            if (scalar @directories > 2)
                {
                $dirString = NaturalDocs::File->JoinDirectories('...', $directories[-2], $directories[-1]);
                $name = NaturalDocs::File->JoinPath(undef, $dirString, $file);
                }
            else
                {  $name = $file;  };

            unshift @parsedFile, NaturalDocs::Parser::ParsedTopic->New(::TOPIC_SECTION(), $name, undef, undef, undef, undef);
            };

        # We only want to call the hook if it has content.
        NaturalDocs::Extensions->AfterFileParsed($file, \@parsedFile);
        };

    return $defaultMenuTitle;
    };


#
#   Function: CleanComment
#
#   Removes any extraneous formatting and whitespace from the comment.  Eliminates comment boxes, horizontal lines, leading
#   and trailing line breaks, trailing whitespace from lines, more than two line breaks in a row, and expands all tab characters.
#   It keeps leading whitespace, though, since it may be needed for example code.
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
    my $prevLineBlank = 1;

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
    };


1;
