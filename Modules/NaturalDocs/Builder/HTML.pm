###############################################################################
#
#   Package: NaturalDocs::Builder::HTML
#
###############################################################################
#
#   A package that generates output in HTML.
#
#   Usage and Dependencies:
#
#       - Everything is handled by <NaturalDocs::Builder>.
#
###############################################################################

# This file is part of Natural Docs, which is Copyright © 2003 Greg Valure
# Natural Docs is licensed under the GPL


use strict;
use integer;

package NaturalDocs::Builder::HTML;

use base 'NaturalDocs::Builder::Base';


###############################################################################
# Group: Variables

#
#   hash: topicNames
#
#   A hash of text equivalents of the <Topic Types>.  Makes output easier.  The keys
#   are the tokens, and the values are their text equivalents.
#
my %topicNames = ( ::TOPIC_CLASS()       => 'Class',
                                   ::TOPIC_SECTION()   => 'Section',
                                   ::TOPIC_FILE()          => 'File',
                                   ::TOPIC_GROUP()      => 'Group',
                                   ::TOPIC_FUNCTION() => 'Function',
                                   ::TOPIC_VARIABLE() => 'Variable',
                                   ::TOPIC_GENERIC()  => 'Generic',
                                   ::TOPIC_CLASS_LIST()       => 'ClassList',
                                   ::TOPIC_FILE_LIST()          => 'FileList',
                                   ::TOPIC_FUNCTION_LIST() => 'FunctionList',
                                   ::TOPIC_VARIABLE_LIST() => 'VariableList',
                                   ::TOPIC_GENERIC_LIST()  => 'GenericList' );

#
#   Hash: abbreviations
#
#   An existence hash of acceptable abbreviations.  These are words that <AddDoubleSpaces()> won't put a second space
#   after when followed by period-whitespace-capital letter.  Yes, this is seriously over-engineered.
#
my %abbreviations = ( mr => 1, mrs => 1, ms => 1, dr => 1,
                                  rev => 1, fr => 1, 'i.e' => 1,
                                  maj => 1, gen => 1, pres => 1, sen => 1, rep => 1,
                                  n => 1, s => 1, e => 1, w => 1, ne => 1, se => 1, nw => 1, sw => 1 );


###############################################################################
# Group: Menu Variables
#
# These variables are for the menu generation functions only.  Since they're needed in recursion, passing around references
# instead would just be a pain.


#
#   int: menuGroupNumber
#
#   The current menu group number.  Each time a group is created, this is incremented so that each one will be unique.
#
my $menuGroupNumber;

#
#   array: menuSelectionHierarchy
#
#   An array of the group numbers surrounding the selected menu item.  Starts at the group immediately encompassing it, and
#   works its way towards the outermost group.
#
my @menuSelectionHierarchy;


#   int: menuLength
#
#   The length of the entire menu, fully expanded.  The value is computed from <MENU_FILELENGTH> and
#   <MENU_GROUPLENGTH>.
#
my $menuLength;

#
#   constants: menuLength Constants
#
#   Constants used in conjunction with <menuLength>.
#
#   MENU_TITLELENGTH       - The length of the title.
#   MENU_SUBTITLELENGTH - The length of the subtitle.
#   MENU_FILELENGTH         - The length of one file entry.
#   MENU_GROUPLENGTH     - The length of one group entry.
#   MENU_TEXTLENGTH        - The length of one text entry.
#   MENU_LINKLENGTH        - The length of one link entry.
#
#   MENU_LENGTHLIMIT    - The limit of the menu's length.  If the total length surpasses this limit, groups that aren't required
#                                       to be open to show the selection will default to closed on browsers that support it.
#
use constant MENU_TITLELENGTH => 3;
use constant MENU_SUBTITLELENGTH => 1;
use constant MENU_FILELENGTH => 1;
use constant MENU_GROUPLENGTH => 2; # because it's a line and a blank space
use constant MENU_TEXTLENGTH => 1;
use constant MENU_LINKLENGTH => 1;

use constant MENU_LENGTHLIMIT => 45;


###############################################################################
# Group: Implemented Interface Functions


#
#   Function: INIT
#
#   Registers the package with <NaturalDocs::Builder>.
#
sub INIT
    {
    NaturalDocs::Builder::Add(__PACKAGE__);
    };


#
#   Function: CommandLineOption
#
#   Returns the option to follow -o to use this package.  In this case, "html".
#
sub CommandLineOption
    {
    return 'html';
    };


#
#   Function: PurgeFiles
#
#   Deletes the output files associated with the purged source files.
#
sub PurgeFiles
    {
    my $self = shift;

    my $filesToPurge = NaturalDocs::Project::FilesToPurge();
    my $outputPath = NaturalDocs::Settings::OutputDirectory($self);

    foreach my $file (keys %$filesToPurge)
        {  unlink( NaturalDocs::File::JoinPath($outputPath, OutputFileOf($file)) );  };
    };


#
#   Function: BuildFile
#
#   Builds the output file from the parsed source file.
#
#   Parameters:
#
#       sourcefile       - The name of the source file.
#       parsedFile      - An arrayref of the source file as <NaturalDocs::Parser::ParsedTopic> objects.
#
sub BuildFile #(sourceFile, parsedFile)
    {
    my ($self, $sourceFile, $parsedFile) = @_;

    my $outputDirectory = NaturalDocs::Settings::OutputDirectory($self);
    my $outputFile = NaturalDocs::File::JoinPath($outputDirectory, OutputFileOf($sourceFile));


    my $outputFileHandle;

    # 99.99% of the time the output directory will already exist, so this will actually be more efficient.  It only won't exist
    # if a new file was added in a new subdirectory and this is the first time that file was ever parsed.
    if (!open($outputFileHandle, '>' . $outputFile))
        {
        NaturalDocs::File::CreatePath( NaturalDocs::File::NoFileName($outputFile) );

        open($outputFileHandle, '>' . $outputFile)
            or die "Couldn't create output file " . $outputFile . "\n";
        };

    print $outputFileHandle


        '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0//EN" '
            . '"http://www.w3.org/TR/REC-html40/strict.dtd">' . "\n\n"

        . '<html><head>'

            . '<title>'
                . BuildTitle($sourceFile)
            . '</title>'

            . '<link rel="stylesheet" type="text/css" href="'. MakeRelativeURL(OutputFileOf($sourceFile), 'NaturalDocs.css') . '">'

            . '<script language=JavaScript><!-- ' . "\n"

            . 'function ToggleMenu(id)'
                . '{'
                . 'if (!document.getElementById) { return; };'

                . 'var display = document.getElementById(id).style.display;'

                . 'if (display == "none") { display = "block"; }'
                . 'else { display = "none"; }'

                . 'document.getElementById(id).style.display = display;'
                . '}'

            . '// --></script>'

        . '</head><body>' . "\n\n"

        . '<!--  Generated by Natural Docs, version ' . NaturalDocs::Settings::AppVersion() . ' -->' . "\n"
        . '<!--  ' . NaturalDocs::Settings::AppURL() . '  -->' . "\n\n"


        # I originally had this part done in CSS, but there were too many problems.  Back to good old HTML tables.
        . '<table border=0 cellspacing=0 cellpadding=0 width=100%><tr>'

            . '<td class=Menu valign=top>'

                . BuildMenu($sourceFile)

            . '</td>' . "\n\n"

            . '<td class=Content valign=top>'
                . BuildContent($sourceFile, $parsedFile)
            . '</td>' . "\n\n"

        . '</tr></table>'

        . '<div class=Footer>'
            . BuildFooter()
        . '</div>'

        . '</body></html>';


    close($outputFileHandle);
    };


#
#   Function: UpdateMenu
#
#   Updates the menu in all the output files that weren't rebuilt.  Also generates index.html.
#
sub UpdateMenu
    {
    my $self = shift;


    # Update the menu on unbuilt files.

    my $filesToUpdate = NaturalDocs::Project::UnbuiltFilesWithContent();

    foreach my $sourceFile (keys %$filesToUpdate)
        {
        UpdateFile($sourceFile);
        };


    # Update index.html

    my $firstMenuEntry = FindFirstFile(NaturalDocs::Menu::Content());

    my $indexFile = NaturalDocs::File::JoinPath( NaturalDocs::Settings::OutputDirectory($self), 'index.html' );
    my $indexFileHandle;

    open($indexFileHandle, '>' . $indexFile)
        or die "Couldn't create output file " . $indexFile . ".\n";

    print $indexFileHandle
    '<html><head>'
         . '<meta http-equiv="Refresh" CONTENT="0; URL='
             . MakeRelativeURL( 'index.html', OutputFileOf($firstMenuEntry->Target()) ) . '">'
    . '</head></html>';

    close $indexFileHandle;
    };


#
#   Function: EndBuild
#
#   Checks that the project's CSS file is the same as the master CSS file, unless -s Custom is specified.
#
#       purgedFiles     - Whether <PurgeFiles()> was called.
#       builtFiles         - Whether <BuildFile()> was called.  If this parameter is false, <NaturalDocs::SymbolTable> is not available.
#       updatedMenu  - Whether <UpdateMenu()> was called.
#
sub EndBuild #(purgedFiles, builtFiles, updatedMenu)
    {
    my $self = shift;

    my $style = NaturalDocs::Settings::OutputStyle($self);

    if (lc($style) ne 'custom')
        {
        my $masterCSSFile = NaturalDocs::File::JoinPath( NaturalDocs::Settings::StyleDirectory(), $style . '.css' );
        my $localCSSFile = NaturalDocs::File::JoinPath( NaturalDocs::Settings::OutputDirectory($self), 'NaturalDocs.css' );

        if (! -e $localCSSFile)
            {
            if (!NaturalDocs::Settings::IsQuiet())
                {  print "Adding CSS file...\n";  };

            NaturalDocs::File::Copy($masterCSSFile, $localCSSFile);
            }

        # We check both the date and the size in case the user switches between two styles which just happen to have the same
        # date.  Should rarely happen, but it might.
        elsif ( (stat($masterCSSFile))[9] != (stat($localCSSFile))[9] ||
                 (stat($masterCSSFile))[7] != (stat($localCSSFile))[7] )
            {
            if (!NaturalDocs::Settings::IsQuiet())
                {  print "Updating CSS file...\n";  };

            NaturalDocs::File::Copy($masterCSSFile, $localCSSFile);
            };
        };
    };


###############################################################################
# Group: Section Functions


#
#   function: BuildTitle
#
#   Builds and returns the HTML page title of a file.
#
#   Parameters:
#
#       sourceFile - The source file to build the title of.
#
#   Returns:
#
#       The source file's title in HTML.
#
sub BuildTitle #(sourceFile)
    {
    my $sourceFile = shift;

    # If we have a menu title, the page title is [menu title] - [file title].  Otherwise it is just [file title].

    my $title = NaturalDocs::Project::DefaultMenuTitleOf($sourceFile);

    my $menuTitle = NaturalDocs::Menu::Title();
    if (defined $menuTitle && $menuTitle ne $title)
        {  $title = $menuTitle . ' - ' . $title;  };

    $title = StringToHTML($title);

    return $title;
    };

#
#   function: BuildMenu
#
#   Builds and returns the side menu of a file.
#
#   Parameters:
#
#       sourceFile - The source file to build the menu for.
#
#   Returns:
#
#       The side menu in HTML.
#
sub BuildMenu #(sourceFile)
    {
    my $sourceFile = shift;

    $menuGroupNumber = 1;
    @menuSelectionHierarchy = ( );
    $menuLength = 0;


    # Comment needed for UpdateFile().
    my $output = '<!--START_ND_MENU-->';

    # The title and sub-title, if any.

    my $menuTitle = NaturalDocs::Menu::Title();
    if (defined $menuTitle)
        {
        $menuLength += MENU_TITLELENGTH;

        $output .=
        '<div class=MTitle>'
            . StringToHTML($menuTitle);

        my $menuSubTitle = NaturalDocs::Menu::SubTitle();
        if (defined $menuSubTitle)
            {
            $menuLength += MENU_SUBTITLELENGTH;

            $output .=
            '<div class=MSubTitle>'
                . StringToHTML($menuSubTitle)
            . '</div>';
            };

        $output .=
        '</div>';
        };


    $output .= BuildMenuSegment($sourceFile, NaturalDocs::Menu::Content(), undef);


    # If the completely expanded menu is too long, collapse all the groups that aren't in the selection hierarchy.  By doing this
    # instead of having them default to closed via CSS, any browser that doesn't support changing this at runtime will keep
    # the menu entirely open so that its still usable.

    if ($menuLength > MENU_LENGTHLIMIT())
        {
        $output .=

        '<script language=JavaScript><!--' . "\n"

        # Using ToggleMenu here causes IE to sometimes say display is nothing instead of "block" or "none" on the first click.
        # Whatever.  This is just as good.

        . 'if (document.getElementById)'
            . '{';

            if (scalar @menuSelectionHierarchy)
                {
                $output .=

                'for (var menu = 1; menu < ' . $menuGroupNumber . '; menu++)'
                    . '{'
                    . 'if (menu != ' . join(' && menu != ', @menuSelectionHierarchy) . ')'
                        . '{'
                        . 'document.getElementById("MGroupContent" + menu).style.display = "none";'
                        . '};'
                    . '};'
                }
            else
                {
                $output .=

                'for (var menu = 1; menu < ' . $menuGroupNumber . '; menu++)'
                    . '{'
                    . 'document.getElementById("MGroupContent" + menu).style.display = "none";'
                    . '};'
                };

            $output .=
            '}'

        . '// --></script>';
        };

    # Comment needed for UpdateFile().
    $output .= '<!--END_ND_MENU-->';

    return $output;
    };


#
#   Function: BuildMenuSegment
#
#   A recursive function to build a segment of the menu.  *Remember to reset the <Menu Variables> before calling this for the
#   first time.*
#
#   Parameters:
#
#       sourceFile - The source file the menu is being built for.
#
#       menuSegment - An arrayref specifying the segment of the menu to build.  Either pass the menu itself or the content
#                               of a group.
#       hasSelectionRef - A reference to a boolean variable, which will be set to true if this function call had the selection in it.
#                                 Won't be set if undef.
#
#   Returns:
#
#       The menu segment in HTML.
#
sub BuildMenuSegment #(sourceFile, menuSegment, hasSelectionRef)
    {
    my ($sourceFile, $menuSegment, $hasSelectionRef) = @_;

    my $output;

    foreach my $entry (@$menuSegment)
        {
        if ($entry->Type() == ::MENU_GROUP())
            {
            my $myGroupNumber = $menuGroupNumber;
            $menuGroupNumber++;

            $menuLength += MENU_GROUPLENGTH;

            my $hasSelection;

            $output .=
            '<div class=MEntry>'
                . '<div class=MGroup>'

                    . '<a href="javascript:ToggleMenu(\'MGroupContent' . $myGroupNumber . '\')">'
                        . StringToHTML($entry->Title())
                    . '</a>'

                    . '<div class=MGroupContent id=MGroupContent' . $myGroupNumber . '>'
                        . BuildMenuSegment($sourceFile, $entry->GroupContent(), \$hasSelection)
                    . '</div>'

                . '</div>'
            . '</div>';

            if ($hasSelection)
                {
                push @menuSelectionHierarchy, $myGroupNumber;

                if ($hasSelectionRef)
                    {  $$hasSelectionRef = 1;  };
                };
            }

        elsif ($entry->Type() == ::MENU_FILE())
            {
            $menuLength += MENU_FILELENGTH;

            if ($entry->Target() eq $sourceFile)
                {
                $output .=
                '<div class=MEntry>'
                    . '<div class=MFile id=MSelected>'
                        . AddHiddenBreaks( StringToHTML( $entry->Title() ))
                    . '</div>'
                . '</div>';

                if ($hasSelectionRef)
                    {  $$hasSelectionRef = 1;  };
                }
            else
                {
                $output .=
                '<div class=MEntry>'
                    . '<div class=MFile>'
                        . '<a href="' . MakeRelativeURL( OutputFileOf($sourceFile), OutputFileOf($entry->Target()) ) . '">'
                            . AddHiddenBreaks( StringToHTML( $entry->Title() ))
                        . '</a>'
                    . '</div>'
                . '</div>';
                };
            }

        elsif ($entry->Type() == ::MENU_TEXT())
            {
            $output .=
            '<div class=MEntry>'
                . '<div class=MText>'
                    . StringToHTML( $entry->Title() )
                . '</div>'
            . '</div>';
            }

        elsif ($entry->Type() == ::MENU_LINK())
            {
            $output .=
            '<div class=MEntry>'
                . '<div class=MLink>'
                    . '<a href="' . $entry->Target() . '">'
                        . StringToHTML( $entry->Title() )
                    . '</a>'
                . '</div>'
            . '</div>';
            };
        };

    return $output;
    };


#
#   Function: BuildContent
#
#   Builds and returns the main page content.
#
#   Parameters:
#
#       sourceFile - The source file name.
#       parsedFile - The parsed source file as an arrayref of <NaturalDocs::Parser::ParsedTopic> objects.
#
#   Returns:
#
#       The page content in HTML.
#
sub BuildContent #(sourceFile, parsedFile)
    {
    my ($sourceFile, $parsedFile) = @_;

    my $output;
    my $i = 0;

    while ($i < scalar @$parsedFile)
        {
        $output .= '<div class=CTopic>';

        my $anchor = SymbolToHTMLSymbol( $parsedFile->[$i]->Class(), $parsedFile->[$i]->Name() );


        # The anchors are closed, but not around the text, so the :hover CSS style won't accidentally kick in.
        # There's plenty of repeated code in this if-else tree, but this makes it simpler.

        if ($i == 0)
            {
            $output .=

            '<div class=CMain>'

                . '<h1 class=CTitle>'
                    . '<a name="' . $anchor . '"></a>'
                    . AddHiddenBreaks( StringToHTML( $parsedFile->[$i]->Name() ) )
                . '</h1>';
            }
        elsif ($parsedFile->[$i]->Type() == ::TOPIC_SECTION() || $parsedFile->[$i]->Type() == ::TOPIC_CLASS())
            {
            $output .=

            '<div class=C' . $topicNames{ $parsedFile->[$i]->Type() } . '>'

                . '<h2 class=CTitle>'
                    . '<a name="' . $anchor . '"></a>'
                    . AddHiddenBreaks( StringToHTML( $parsedFile->[$i]->Name() ))
                . '</h2>';
            }
        else
            {
            $output .=

            '<div class=C' . $topicNames{ $parsedFile->[$i]->Type() } . '>'

                . '<h3 class=CTitle>'
                    . '<a name="' . $anchor . '"></a>'
                    . AddHiddenBreaks( StringToHTML( $parsedFile->[$i]->Name() ))
                . '</h3>';
            };


        if (defined $parsedFile->[$i]->Prototype())
            {
            $output .=
            # A surrounding table as a hack to make the div form-fit.
            '<table border=0 cellspacing=0 cellpadding=0><tr><td>'
                . '<div class=CPrototype>'
                    . StringToHTML( $parsedFile->[$i]->Prototype() )
                . '</div>'
            . '</tr></td></table>';
            };


        if (defined $parsedFile->[$i]->Body())
            {
            $output .= NDMarkupToHTML( $sourceFile, $parsedFile->[$i]->Body(), $parsedFile->[$i]->Scope() );
            };


        if ($i == 0 ||
            $parsedFile->[$i]->Type() == ::TOPIC_CLASS() || $parsedFile->[$i]->Type() == ::TOPIC_SECTION())
            {
            $output .= BuildSummary($sourceFile, $parsedFile, $i);
            };


        $output .=
            '</div>' # CType
        . '</div>'; # CTopic

        $i++;
        };

    return $output;
    };


#
#   Function: BuildSummary
#
#   Builds a summary, either for the entire file or the current class/section.
#
#   Parameters:
#
#       sourceFile - The source file the summary appears in.
#
#       parsedFile - A reference to the parsed source file.
#
#       index   - The index into the parsed file to start at.  If undef or zero, it builds a summary for the entire file.  If it's the
#                    index of a class or section entry, it builds a summary for that class or section.
#
#   Returns:
#
#       The summary in HTML.
#
sub BuildSummary #(sourceFile, parsedFile, index)
    {
    my ($sourceFile, $parsedFile, $index) = @_;
    my $completeSummary;

    if (!defined $index || $index == 0)
        {
        $index = 0;
        $completeSummary = 1;
        }
    else
        {
        # Skip the class/section entry.
        $index++;
        };


    # Return nothing if there's only one entry.
    if ($index + 1 >= scalar @$parsedFile ||
        ( !$completeSummary &&
          ( $parsedFile->[$index]->Type() == ::TOPIC_CLASS() || $parsedFile->[$index]->Type() == ::TOPIC_SECTION() )
        ))
        {
        return '';
        };


    # In a nice efficiency twist, these buggers will hold the opening div tags if true, undef if false.  Not that this script is known
    # for its efficiency.  Not that Perl is known for its efficiency.  Anyway...
    my $inSectionOrClassTag;
    my $inGroupTag;
    my $isMarkedAttr;
    my $entrySizeAttr = ' class=SEntrySize';
    my $descriptionSizeAttr = ' class=SDescriptionSize';

    my $output =
    '<div class=Summary><div class=STitle>Summary</div>'

        # Not all browsers get table padding right, so we need a div to apply the border.
        . '<div class=SBorder>'
        . '<table border=0 cellspacing=0 cellpadding=0 class=STable>';

        while ($index < scalar @$parsedFile && ($completeSummary ||
                ($parsedFile->[$index]->Type() != ::TOPIC_SECTION() && $parsedFile->[$index]->Type() != ::TOPIC_CLASS()) ))
            {
            my $type = $parsedFile->[$index]->Type();


            # Remove modifiers as appropriate for the current entry.

            if ($type == ::TOPIC_SECTION() || $type == ::TOPIC_CLASS())
                {
                $inSectionOrClassTag = undef;
                $inGroupTag = undef;
                $isMarkedAttr = undef;
                }
            elsif ($type == ::TOPIC_GROUP())
                {
                $inGroupTag = undef;
                $isMarkedAttr = undef;
                };


            $output .=
             '<tr><td' . ($isMarkedAttr | $entrySizeAttr) . '>'
                . '<div class=S' . ($index == 0 ? 'Main' : $topicNames{$type}) . '>'
                    . '<div class=SEntry>';


            # Add any remaining modifiers to the HTML in the form of div tags.  This modifier approach isn't the most elegant
            # thing, but there's not a lot of options.  It works.

            $output .= $inSectionOrClassTag . $inGroupTag;


            # Add the entry itself.

            $output .=
            '<a href="#' . SymbolToHTMLSymbol( $parsedFile->[$index]->Class(), $parsedFile->[$index]->Name() ) . '"';

            if (defined $parsedFile->[$index]->Prototype())
                {
                my $prototype = $parsedFile->[$index]->Prototype();

                # IE will actually show a trailing line break in the tooltip, so we need to strip it.
                $prototype =~ s/\n$//;

                $output .= ' title="' . ConvertAmpChars($prototype) . '"';
                };

            $output .= '>'
                . AddHiddenBreaks( StringToHTML( $parsedFile->[$index]->Name() ))
            . '</a>';


            # Close the modifiers.

            if (defined $inGroupTag)
                {  $output .= '</div>';  };
            if (defined $inSectionOrClassTag)
                {  $output .= '</div>';  };

            $output .=
                    '</div>' # Entry
                . '</div>' # Type

            . '</td><td' . ($isMarkedAttr | $descriptionSizeAttr) . '>'

                . '<div class=S' . ($index == 0 ? 'Main' : $topicNames{$type}) . '>'
                    . '<div class=SDescription>';


            # Add the modifiers to the HTML yet again.

            $output .= $inSectionOrClassTag . $inGroupTag;


            # We want the summary to be the first sentence of the body, if it's regular text.  If it's a list, we'll leave it empty.

            if (defined $parsedFile->[$index]->Body())
                {
                $parsedFile->[$index]->Body() =~ /^<p>(.*?)(<\/p>|[\.\!\?](?:[\)\}\'\ ]|&quot;|&gt;))/;

                if (length $1)
                    {
                    my $summary = $1;
                    if ($2 ne '</p>')
                        {  $summary .= $2;  };

                    $output .= NDMarkupToHTML($sourceFile, $summary, $parsedFile->[$index]->Scope());
                    };
                };


            # Close the modifiers again.

            if (defined $inGroupTag)
                {  $output .= '</div>';  };
            if (defined $inSectionOrClassTag)
                {  $output .= '</div>';  };


            $output .=
                    '</div>' # Description
                . '</div>' # Type

            . '</td></tr>';


            # Prepare the modifiers for the next entry.

            if ($type == ::TOPIC_CLASS())
                {
                $inSectionOrClassTag = '<div class=SInClass>';
                $inGroupTag = undef;
                }
            elsif ($type == ::TOPIC_SECTION())
                {
                $inSectionOrClassTag = '<div class=SInSection>';
                $inGroupTag = undef;
                }
            elsif ($type == ::TOPIC_GROUP())
                {
                $inGroupTag = '<div class=SInGroup>';
                };

            if (!defined $isMarkedAttr)
                {  $isMarkedAttr = ' class=SMarked';  }
            else
                {  $isMarkedAttr = undef;  };

            $entrySizeAttr = undef;
            $descriptionSizeAttr = undef;


            $index++;
            };

        $output .=
        '</table>'
    . '</div>' # Border
    . '</div>'; # Summary

    return $output;
    };


#
#   Function: BuildFooter
#
#   Builds and returns the HTML footer for the page.
#
sub BuildFooter
    {
    my $footer = NaturalDocs::Menu::Footer();

    if (defined $footer)
        {
        if (substr($footer, -1, 1) ne '.')
            {  $footer .= '.';  };

        $footer =~ s/\(c\)/&copy;/gi;

        $footer .= '&nbsp; Generated by <a href="' . NaturalDocs::Settings::AppURL() . '">Natural Docs</a>.'
        }
    else
        {
        $footer = 'Generated by <a href="' . NaturalDocs::Settings::AppURL() . '">Natural Docs</a>';
        };
    };


#
#   Function: UpdateFile
#
#   Updates an output file.  Replaces the menu, HTML title, and footer.  It opens the output file, makes the changes, and saves it
#   back to disk, which is much quicker than rebuilding the file from scratch if these were the only things that changed.
#
#   Parameters:
#
#       sourceFile - The source file.
#
sub UpdateFile #(sourceFile)
    {
    my $sourceFile = shift;

    my $outputDirectory = NaturalDocs::Settings::OutputDirectory(__PACKAGE__);
    my $outputFile = NaturalDocs::File::JoinPath( $outputDirectory, OutputFileOf($sourceFile) );
    my $outputFileHandle;

    if (open($outputFileHandle, '<' . $outputFile))
        {
        my $content;

        read($outputFileHandle, $content, (stat($outputFile))[7]);
        close($outputFileHandle);


        $content =~ s{<title>[^<]*<\/title>}{'<title>' . BuildTitle($sourceFile) . '</title>'}e;

        $content =~ s/<!--START_ND_MENU-->.*?<!--END_ND_MENU-->/BuildMenu($sourceFile)/es;

        $content =~ s/<div class=Footer>.*<\/div>/"<div class=Footer>" . BuildFooter() . "<\/div>"/e;


        open($outputFileHandle, '>' . $outputFile);
        print $outputFileHandle $content;
        close($outputFileHandle);
        };
    };


###############################################################################
# Group: Support Functions


#
#   function: OutputFileOf
#
#   Returns the output file name of the source file, no path included.
#
sub OutputFileOf #(sourceFile)
    {
    my $sourceFile = shift;

    # We need to change any extensions to dashes because Apache will think file.pl.html is a script.
    $sourceFile =~ s/\./-/g;
    $sourceFile =~ s/ /_/g;

    return $sourceFile . '.html';
    };

#
#   function: MakeRelativeURL
#
#   Returns a relative path between two files and returns it in URL format.
#
#   Parameters:
#
#       baseFile    - The base file.
#       targetFile  - The target of the link.
#
#   Returns:
#
#       The relative URL to the target.
#
sub MakeRelativeURL #(baseFile, targetFile)
    {
    my ($baseFile, $targetFile) = @_;

    my $baseDir = NaturalDocs::File::NoFileName($baseFile);
    my $relativePath = NaturalDocs::File::MakeRelativePath($baseDir, $targetFile);

    return ConvertAmpChars( NaturalDocs::File::ConvertToURL($relativePath) );
    };

#
#   Function: StringToHTML
#
#   Converts a text string to HTML.  Does not apply paragraph tags or accept formatting tags.
#
#   Parameters:
#
#       string - The string to convert.
#
#   Returns:
#
#       The string in HTML.
#
sub StringToHTML #(string)
    {
    my $string = shift;

    $string =~ s/&/&amp;/g;
    $string =~ s/</&lt;/g;
    $string =~ s/>/&gt;/g;

    # Me likey the fancy quotes.  They work in IE 4+, Mozilla, and Opera 5+.  We've already abandoned NS4 with the CSS
    # styles, so might as well.
    $string =~ s/^\'/&lsquo;/gm;
    $string =~ s/([\ \(\[\{])\'/$1&lsquo;/g;
    $string =~ s/\'/&rsquo;/g;

    $string =~ s/^\"/&ldquo;/gm;
    $string =~ s/([\ \(\[\{])\"/$1&ldquo;/g;
    $string =~ s/\"/&rdquo;/g;

    # Me likey the double spaces too.  As you can probably tell, I like print-formatting better than web-formatting.  The indented
    # paragraphs without blank lines in between them do become readable when you have fancy quotes and double spaces too.
    return AddDoubleSpaces($string);
    };


#
#   Function: SymbolToHTMLSymbol
#
#   Converts a class and symbol to a HTML symbol, meaning one that is safe to include in anchor and link tags.  You don't need
#   to pass the result to <ConvertAmpChars()>.
#
#   Parameters:
#
#       class     - The symbol's class.  Set to undef if global.
#       symbol  - The symbol's name.
#
#   Returns:
#
#       The HTML symbol string.
#
sub SymbolToHTMLSymbol #(class, symbol)
    {
    my ($class, $symbol) = @_;

    ($class, $symbol) = NaturalDocs::SymbolTable::Defines($class, $symbol);

    # Some of these changes can potentially create conflicts, though they should be incredibly rare.

    if (defined $class)
        {  $symbol = $class . '.' . $symbol;  };

    # If only Mozilla was nice about putting special characters in URLs like IE and Opera are, I could leave spaces in and replace
    # "<>& with their amp chars.  But alas, Mozilla shows them as %20, etc. instead.  It would have made for nice looking URLs.
    $symbol =~ s/[\"<>\?&%]//g;
    $symbol =~ s/ /_/g;

    return $symbol;
    };


#
#   Function: NDMarkupToHTML
#
#   Converts a block of <NDMarkup> to HTML.
#
#   Parameters:
#
#       sourceFile - The source file the <NDMarkup> appears in.
#       text    - The <NDMarkup> text to convert.
#       scope  - The scope the <NDMarkup> appears in.
#
#   Returns:
#
#       The text in HTML.
#
sub NDMarkupToHTML #(sourceFile, text, scope)
    {
    my ($sourceFile, $text, $scope) = @_;
    my $output;
    my $inCode;

    my @splitText = split(/(<\/?code>)/, $text);

    while (scalar @splitText)
        {
        $text = shift @splitText;

        if ($text eq '<code>')
            {
            $output .= '<pre class=CCode>';
            $inCode = 1;
            }
        elsif ($text eq '</code>')
            {
            $output .= '</pre>';
            $inCode = undef;
            }
        elsif ($inCode)
            {
            $output .= $text;
            }
        else
            {
            # Format non-code text.

            # Resolve and convert links.
            $text =~ s/<link>([^<]+)<\/link>/MakeLink($scope, $1, $sourceFile)/ge;

            sub MakeLink #(scope, text, sourceFile)
                {
                my ($scope, $text, $sourceFile) = @_;

                my $target = NaturalDocs::SymbolTable::References($scope, NaturalDocs::NDMarkup::RestoreAmpChars($text),
                                                                                              $sourceFile);

                if (defined $target)
                    {
                    my $targetFile;

                    if ($target->File() ne $sourceFile)
                        {  $targetFile = MakeRelativeURL(OutputFileOf($sourceFile), OutputFileOf($target->File()));  };
                    # else leave it undef

                    my $prototypeAttr;

                    if (defined $target->Prototype())
                        {  $prototypeAttr = ' title="' . ConvertAmpChars($target->Prototype()) . '"';  };

                    return '<a href="' . $targetFile . '#' . SymbolToHTMLSymbol( $target->Class(), $target->Symbol() ) . '"'
                            . $prototypeAttr . ' class=L' . $topicNames{$target->Type()} . '>' . $text . '</a>';
                    }
                else
                    {
                    return '&lt;' . $text . '&gt;';
                    };
                };

            # Convert quotes to fancy quotes.
            $text =~ s/^\'/&lsquo;/gm;
            $text =~ s/([\ \(\[\{])\'/$1&lsquo;/g;
            $text =~ s/\'/&rsquo;/g;

            $text =~ s/^&quot;/&ldquo;/gm;
            $text =~ s/([\ \(\[\{])&quot;/$1&ldquo;/g;
            $text =~ s/&quot;/&rdquo;/g;

            # Add double spaces too.
            $text = AddDoubleSpaces($text);

            # Paragraphs
            $text =~ s/<p>/<p class=CParagraph>/g;

            # Bulleted lists
            $text =~ s/<ul>/<ul class=CBulletList>/g;

            # Headings
            $text =~ s/<h>/<h4 class=CHeading>/g;
            $text =~ s/<\/h>/<\/h4>/g;

            # Description Lists
            $text =~ s/<dl>/<table border=0 cellspacing=0 cellpadding=0 class=CDescriptionList>/g;
            $text =~ s/<\/dl>/<\/table>/g;

            $text =~ s/<de>/<tr><td class=CDLEntry>/g;
            $text =~ s/<\/de>/<\/td>/g;
            $text =~ s/<ds>([^<]+)<\/ds>/MakeDescriptionListSymbol($scope, $1)/ge;

            sub MakeDescriptionListSymbol #(scope, text)
                {
                my $scope = shift;
                my $text = shift;

                return
                '<tr>'
                    . '<td class=CDLEntry>'
                        # The anchors are closed, but not around the text, to prevent the :hover CSS style from kicking in.
                        . '<a name="' . SymbolToHTMLSymbol($scope, NaturalDocs::NDMarkup::RestoreAmpChars($text)) . '"></a>'
                        . $text
                    . '</td>';
                };

            $text =~ s/<dd>/<td class=CDLDescription>/g;
            $text =~ s/<\/dd>/<\/td><\/tr>/g;

            $output .= $text;
            };
        };

    return $output;
    };


#
#   Function: AddDoubleSpaces
#
#   Adds second spaces after the appropriate punctuation with &nbsp; so they show up in HTML.  They don't occur if there isn't at
#   least one space after the punctuation, so things like class.member notation won't be affected.
#
#   Parameters:
#
#       text - The text to convert.
#
#   Returns:
#
#       The text with double spaces as necessary.
#
sub AddDoubleSpaces #(text)
    {
    my $text = shift;

    # Question marks and exclamation points get double spaces unless followed by a lowercase letter.
    $text =~ s/([\!\?])(&quot;|&[lr][sd]quo;|[\'\"\]\}\)]?) (?![a-z])/$1$2&nbsp; /g;

    # Periods get double spaces if it's not followed by a lowercase letter.  However, if it's followed by a capital letter and the
    # preceding word is in the list of acceptable abbreviations, it won't get the double space.  Yes, I do realize I am seriously
    # over-engineering this.
    $text =~ s/([^\ \r\n]+)\.(&quot;|&[lr][sd]quo;|[\'\"\]\}\)]?) ([^a-z])/$1 . '.' . $2 . MaybeExpand($1, $3) . $3/ge;

    sub MaybeExpand #(leadWord, nextLetter)
        {
        my ($leadWord, $nextLetter) = @_;

        if ($nextLetter =~ /^[A-Z]$/ && exists $abbreviations{ lc($leadWord) } )
            { return ' '; }
        else
            { return '&nbsp; '; };
        };

    return $text;
    };

#
#   Function: ConvertAmpChars
#
#   Converts certain characters to their HTML amp char equivalents.
#
#   Parameters:
#
#       text - The text to convert.
#
#   Returns:
#
#       The converted text.
#
sub ConvertAmpChars #(text)
    {
    my $text = shift;

    $text =~ s/&/&amp;/g;
    $text =~ s/\"/&quot;/g;
    $text =~ s/</&lt;/g;
    $text =~ s/>/&gt;/g;

    return $text;
    };


#
#   Function: HiddenBreak
#
#   Returns a hidden word break in HTML.  Or more accurately, the best approximation of it I can make.
#
sub HiddenBreak
    {
    return '<span class=HiddenBreak> </span>';
    };


#
#   Function: AddHiddenBreaks
#
#   Adds hidden breaks to symbols.  Puts them after symbol and directory separators so long names won't screw up the layout.
#
#   Parameters:
#
#       string - The string to break.
#
#   Returns:
#
#       The string with hidden breaks.
#
sub AddHiddenBreaks #(string)
    {
    my $string = shift;

    $string =~ s/(\w(?:\.|::|\\|\/))(\w)/$1 . HiddenBreak() . $2/ge;

    return $string;
    };

#
#   Function: FindFirstFile
#
#   A recursive function that finds and returns the first file entry in the menu.
#
#   Parameters:
#
#       arrayref - The array to search.  Set to <NaturalDocs::Menu::Content()>.
#
sub FindFirstFile #(arrayref)
    {
    my $arrayref = shift;

    my $i = 0;
    while ($i < scalar @$arrayref)
        {
        if ($arrayref->[$i]->Type() == ::MENU_FILE())
            {
            return $arrayref->[$i];
            }
        elsif ($arrayref->[$i]->Type() == ::MENU_GROUP())
            {
            my $result = FindFirstFile($arrayref->[$i]->GroupContent());
            if (defined $result)
                {  return $result;  };
            };

        $i++;
        };

    return undef;
    };


1;