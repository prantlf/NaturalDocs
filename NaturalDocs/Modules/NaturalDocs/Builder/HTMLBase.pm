###############################################################################
#
#   Package: NaturalDocs::Builder::HTMLBase
#
###############################################################################
#
#   A base package for all the shared functionality in <NaturalDocs::Builder::HTML> and
#   <NaturalDocs::Builder::FramedHTML>.
#
###############################################################################

# This file is part of Natural Docs, which is Copyright © 2003 Greg Valure
# Natural Docs is licensed under the GPL


use Tie::RefHash;

use strict;
use integer;

package NaturalDocs::Builder::HTMLBase;

use base 'NaturalDocs::Builder::Base';


###############################################################################
# Group: Package Variables
# These variables are shared by all instances of the package so don't change them.

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

#
#   array: indexHeadings
#
#   An array of the headings of all the index sections.  First is for symbols, second for numbers, and the rest for each letter.
#
my @indexHeadings = ( '$#!', '0-9', 'A' .. 'Z' );

#
#   array: indexAnchors
#
#   An array of the HTML anchors of all the index sections.  First is for symbols, second for numbers, and the rest for each letter.
#
my @indexAnchors = ( 'Symbols', 'Numbers', 'A' .. 'Z' );


###############################################################################
# Group: ToolTip Package Variables
#
#   These variables are for the tooltip generation functions only.  Since they're reset on every call to <BuildContent()> and
#   <BuildIndexContent()>, and are only used by them and their support functions, they can be shared by all instances of the
#   package.

#
#   int: tooltipLinkNumber
#
#   A number used as part of the ID for each link that has a tooltip.  Should be incremented whenever one is made.
#
my $tooltipLinkNumber;

#
#   int: tooltipNumber
#
#   A number used as part of the ID for each tooltip.  Should be incremented whenever one is made.
#
my $tooltipNumber;

#
#   hash: tooltipSymbolsToNumbers
#
#   A hash that maps the tooltip symbols to their assigned numbers.
#
my %tooltipSymbolsToNumbers;

#
#   string: tooltipHTML
#
#   The generated tooltip HTML.
#
my $tooltipHTML;


###############################################################################
# Group: Menu Package Variables
#
#   These variables are for the menu generation functions only.  Since they're reset on every call to <BuildMenu()> and are
#   only used by it and its support functions, they can be shared by all instances of the package.
#


#
#   int: menuGroupNumber
#
#   The current menu group number.  Each time a group is created, this is incremented so that each one will be unique.
#
my $menuGroupNumber;

#
#   array: menuSelectionHierarchy
#
#   An array of the <NaturalDocs::Menu::Entry> objects of each group surrounding the selected menu item.  First entry is the
#   group immediately encompassing it, and each subsequent entries works its way towards the outermost group.
#
my @menuSelectionHierarchy;


#
#   int: menuLength
#
#   The length of the entire menu, fully expanded.  The value is computed from the <Menu Length Constants>.
#
my $menuLength;


#
#   hash: menuGroupLengths
#
#   A hash of the length of each group, *not* including any subgroup contents.  The keys are references to each groups'
#   <NaturalDocs::Menu::Entry> object, and the values are their lengths computed from the <Menu Length Constants>.
#
my %menuGroupLengths;
tie %menuGroupLengths, 'Tie::RefHash';


#
#   hash: menuGroupNumbers
#
#   A hash of the number of each group, as managed by <menuGroupNumber>.  The keys are references to each groups'
#   <NaturalDocs::Menu::Entry> object, and the values are the number.
#
my %menuGroupNumbers;
tie %menuGroupNumbers, 'Tie::RefHash';


#
#   constants: Menu Length Constants
#
#   Constants used to approximate the lengths of the menu or its groups.
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
use constant MENU_INDEXLENGTH => 1;

use constant MENU_LENGTHLIMIT => 35;


###############################################################################
# Group: Implemented Interface Functions
#
#   The behavior of these functions is shared between HTML output formats.
#


#
#   Function: PurgeFiles
#
#   Deletes the output files associated with the purged source files.
#
sub PurgeFiles
    {
    my $self = shift;

    my $filesToPurge = NaturalDocs::Project->FilesToPurge();
    my $outputPath = NaturalDocs::Settings->OutputDirectoryOf($self);

    foreach my $file (keys %$filesToPurge)
        {  unlink( NaturalDocs::File->JoinPath($outputPath, $self->OutputFileOf($file)) );  };
    };


#
#   Function: PurgeIndexes
#
#   Deletes the output files associated with the purged source files.
#
#   Parameters:
#
#       indexes  - An existence hashref of the index types to purge.  The keys are the <Topic Types> or * for the general index.
#
sub PurgeIndexes #(indexes)
    {
    my ($self, $indexes) = @_;

    my $outputPath = NaturalDocs::Settings->OutputDirectoryOf($self);

    foreach my $index (keys %$indexes)
        {
        $self->PurgeIndexFiles(($index eq '*' ? undef : $index), undef);
        };
    };


#
#   Function: EndBuild
#
#   Checks that the project's CSS file is the same as the master CSS file, unless -s Custom is specified.
#
sub EndBuild #(hasChanged)
    {
    my ($self, $hasChanged) = @_;

    my $style = NaturalDocs::Settings->OutputStyleOf($self);

    if (lc($style) ne 'custom')
        {
        my $masterCSSFile = NaturalDocs::File->JoinPath( NaturalDocs::Settings->StyleDirectory(), $style . '.css' );
        my $localCSSFile = NaturalDocs::File->JoinPath( NaturalDocs::Settings->OutputDirectoryOf($self), 'NaturalDocs.css' );

        # We check both the date and the size in case the user switches between two styles which just happen to have the same
        # date.  Should rarely happen, but it might.
        if (! -e $localCSSFile ||
            (stat($masterCSSFile))[9] != (stat($localCSSFile))[9] ||
             -s $masterCSSFile != -s $localCSSFile)
            {
            if (!NaturalDocs::Settings->IsQuiet())
                {  print "Updating CSS file...\n";  };

            NaturalDocs::File->Copy($masterCSSFile, $localCSSFile);
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
    my ($self, $sourceFile) = @_;

    # If we have a menu title, the page title is [menu title] - [file title].  Otherwise it is just [file title].

    my $title = NaturalDocs::Project->DefaultMenuTitleOf($sourceFile);

    my $menuTitle = NaturalDocs::Menu->Title();
    if (defined $menuTitle && $menuTitle ne $title)
        {  $title .= ' - ' . $menuTitle;  };

    $title = $self->StringToHTML($title);

    return $title;
    };

#
#   function: BuildMenu
#
#   Builds and returns the side menu of a file.
#
#   Parameters:
#
#       outputFile - The output file to build the menu for.  Does not have to be on the menu itself.
#       isFramed - Whether the menu will appear in a frame.  If so, it assumes the <base> HTML tag is set to make links go to the
#                       appropriate frame.
#
#   Returns:
#
#       The side menu in HTML.
#
sub BuildMenu #(outputFile, isFramed)
    {
    my ($self, $outputFile, $isFramed) = @_;

    $menuGroupNumber = 1;
    @menuSelectionHierarchy = ( );
    $menuLength = 0;
    %menuGroupLengths = ( );
    %menuGroupNumbers = ( );

    my ($segmentOutput, $hasSelection, $rootLength) =
        $self->BuildMenuSegment($outputFile, $isFramed, NaturalDocs::Menu->Content());


    # Comment needed for UpdateFile().
    my $output = '<!--START_ND_MENU-->';

    # The title and sub-title, if any.

    my $menuTitle = NaturalDocs::Menu->Title();
    if (defined $menuTitle)
        {
        $menuLength += MENU_TITLELENGTH;
        $rootLength += MENU_TITLELENGTH;

        $output .=
        '<div class=MTitle>'
            . $self->StringToHTML($menuTitle);

        my $menuSubTitle = NaturalDocs::Menu->SubTitle();
        if (defined $menuSubTitle)
            {
            $menuLength += MENU_SUBTITLELENGTH;
            $rootLength += MENU_SUBTITLELENGTH;

            $output .=
            '<div class=MSubTitle>'
                . $self->StringToHTML($menuSubTitle)
            . '</div>';
            };

        $output .=
        '</div>';
        };


    $output .= $segmentOutput;


    # If the completely expanded menu is too long, collapse all the groups that aren't in the selection hierarchy.  By doing this
    # instead of having them default to closed via CSS, any browser that doesn't support changing this at runtime will keep
    # the menu entirely open so that its still usable.

    if ($menuLength > MENU_LENGTHLIMIT())
        {
        my $toExpand = $self->ExpandMenu($outputFile, $rootLength);

        $output .=

        '<script language=JavaScript><!--' . "\n"

        # Using ToggleMenu here causes IE to sometimes say display is nothing instead of "block" or "none" on the first click.
        # Whatever.  This is just as good.

        . 'if (document.getElementById)'
            . '{';

            if (scalar @$toExpand)
                {
                $output .=

                'for (var menu = 1; menu < ' . $menuGroupNumber . '; menu++)'
                    . '{'
                    . 'if (menu != ' . join(' && menu != ', @$toExpand) . ')'
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
#       outputFile - The output file the menu is being built for.  Does not have to be on the menu itself.
#       isFramed - Whether the menu will be in a HTML frame or not.  Assumes that if it is, the <base> HTML tag will be set so that
#                       links are directed to the proper frame.
#       menuSegment - An arrayref specifying the segment of the menu to build.  Either pass the menu itself or the contents
#                               of a group.
#
#   Returns:
#
#       The array ( menuHTML, hasSelection, length ).
#
#       menuHTML - The menu segment in HTML.
#       hasSelection - Whether the group or any of its subgroups contains the entry for the selected file.
#       groupLength - The length of the group, *not* including the contents of any subgroups, as computed from the
#                            <Menu Length Constants>.
#
sub BuildMenuSegment #(outputFile, isFramed, menuSegment)
    {
    my ($self, $outputFile, $isFramed, $menuSegment) = @_;

    my ($output, $hasSelection, $groupLength);

    foreach my $entry (@$menuSegment)
        {
        if ($entry->Type() == ::MENU_GROUP())
            {
            my $entryNumber = $menuGroupNumber;
            $menuGroupNumber++;

            my ($entryOutput, $entryHasSelection, $entryLength) =
                $self->BuildMenuSegment($outputFile, $isFramed, $entry->GroupContent());

            $menuGroupLengths{$entry} = $entryLength;
            $menuGroupNumbers{$entry} = $entryNumber;

            $output .=
            '<div class=MEntry>'
                . '<div class=MGroup>'

                    . '<a href="javascript:ToggleMenu(\'MGroupContent' . $entryNumber . '\')"'
                         . ($isFramed ? ' target="_self"' : '') . '>'
                        . $self->StringToHTML($entry->Title())
                    . '</a>'

                    . '<div class=MGroupContent id=MGroupContent' . $entryNumber . '>'
                        . $entryOutput
                    . '</div>'

                . '</div>'
            . '</div>';

            if ($entryHasSelection)
                {
                $hasSelection = 1;
                push @menuSelectionHierarchy, $entry;
                };

            $menuLength += MENU_GROUPLENGTH;
            $groupLength += MENU_GROUPLENGTH;
            }

        elsif ($entry->Type() == ::MENU_FILE())
            {
            my $targetOutputFile = $self->OutputFileOf($entry->Target());

            if ($outputFile eq $targetOutputFile)
                {
                $output .=
                '<div class=MEntry>'
                    . '<div class=MFile id=MSelected>'
                        . $self->AddHiddenBreaks( $self->StringToHTML($entry->Title() ))
                    . '</div>'
                . '</div>';

                $hasSelection = 1;
                }
            else
                {
                $output .=
                '<div class=MEntry>'
                    . '<div class=MFile>'
                        . '<a href="' . $self->MakeRelativeURL($outputFile, $targetOutputFile) . '">'
                            . $self->AddHiddenBreaks( $self->StringToHTML( $entry->Title() ))
                        . '</a>'
                    . '</div>'
                . '</div>';
                };

            $menuLength += MENU_FILELENGTH;
            $groupLength += MENU_FILELENGTH;
            }

        elsif ($entry->Type() == ::MENU_TEXT())
            {
            $output .=
            '<div class=MEntry>'
                . '<div class=MText>'
                    . $self->StringToHTML( $entry->Title() )
                . '</div>'
            . '</div>';

            $menuLength += MENU_TEXTLENGTH;
            $groupLength += MENU_TEXTLENGTH;
            }

        elsif ($entry->Type() == ::MENU_LINK())
            {
            $output .=
            '<div class=MEntry>'
                . '<div class=MLink>'
                    . '<a href="' . $entry->Target() . '"' . ($isFramed ? ' target="_top"' : '') . '>'
                        . $self->StringToHTML( $entry->Title() )
                    . '</a>'
                . '</div>'
            . '</div>';

            $menuLength += MENU_LINKLENGTH;
            $groupLength += MENU_LINKLENGTH;
            }

        elsif ($entry->Type() == ::MENU_INDEX())
            {
            my $indexFile = $self->IndexFileOf($entry->Target);

            if ($outputFile eq $indexFile)
                {
                $output .=
                '<div class=MEntry>'
                    . '<div class=MIndex id=MSelected>'
                        . $self->StringToHTML( $entry->Title() )
                    . '</div>'
                . '</div>';

                $hasSelection = 1;
                }
            else
                {
                $output .=
                '<div class=MEntry>'
                    . '<div class=MIndex>'
                        . '<a href="' . $self->MakeRelativeURL( $outputFile, $self->IndexFileOf($entry->Target()) ) . '">'
                            . $self->StringToHTML( $entry->Title() )
                        . '</a>'
                    . '</div>'
                . '</div>';
                };

            $menuLength += MENU_INDEXLENGTH;
            $groupLength += MENU_INDEXLENGTH;
            };
        };

    return ($output, $hasSelection, $groupLength);
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
    my ($self, $sourceFile, $parsedFile) = @_;

    $self->ResetToolTips();

    my $output;
    my $i = 0;

    while ($i < scalar @$parsedFile)
        {
        my $anchor = $self->SymbolToHTMLSymbol( $parsedFile->[$i]->Class(), $parsedFile->[$i]->Name() );
        my $hasCBody;


        # The anchors are closed, but not around the text, so the :hover CSS style won't accidentally kick in.
        # There's plenty of repeated code in this if-else tree, but this makes it simpler.

        if ($i == 0)
            {
            $output .=

            '<div class=CMain>'
                . '<div class=CTopic>'

                . '<h1 class=CTitle>'
                    . '<a name="' . $anchor . '"></a>'
                    . $self->AddHiddenBreaks( $self->StringToHTML( $parsedFile->[$i]->Name() ) )
                . '</h1>';
            }
        elsif ($parsedFile->[$i]->Type() == ::TOPIC_SECTION() || $parsedFile->[$i]->Type() == ::TOPIC_CLASS())
            {
            $output .=

            '<div class=C' . NaturalDocs::Topics->NameOf( $parsedFile->[$i]->Type() ) . '>'
                . '<div class=CTopic>'

                . '<h2 class=CTitle>'
                    . '<a name="' . $anchor . '"></a>'
                    . $self->AddHiddenBreaks( $self->StringToHTML( $parsedFile->[$i]->Name() ))
                . '</h2>';
            }
        else
            {
            $output .=

            '<div class=C' . NaturalDocs::Topics->NameOf( $parsedFile->[$i]->Type() ) . '>'
                . '<div class=CTopic>'

                . '<h3 class=CTitle>'
                    . '<a name="' . $anchor . '"></a>'
                    . $self->AddHiddenBreaks( $self->StringToHTML( $parsedFile->[$i]->Name() ))
                . '</h3>';
            };


        if (defined $parsedFile->[$i]->Prototype())
            {
            if (!$hasCBody)
                {
                $output .= '<div class=CBody>';
                $hasCBody = 1;
                };

            $output .= $self->BuildPrototype($parsedFile->[$i]->Type(), $parsedFile->[$i]->Prototype(), $sourceFile);
            };


        if (defined $parsedFile->[$i]->Body())
            {
            if (!$hasCBody)
                {
                $output .= '<div class=CBody>';
                $hasCBody = 1;
                };

            $output .= $self->NDMarkupToHTML( $sourceFile, $parsedFile->[$i]->Body(), $parsedFile->[$i]->Scope() );
            };


        if ($i == 0 ||
            $parsedFile->[$i]->Type() == ::TOPIC_CLASS() || $parsedFile->[$i]->Type() == ::TOPIC_SECTION())
            {
            if (!$hasCBody)
                {
                $output .= '<div class=CBody>';
                $hasCBody = 1;
                };

            $output .= $self->BuildSummary($sourceFile, $parsedFile, $i);
            };


        if ($hasCBody)
            {  $output .= '</div>';  };

        $output .=
            '</div>' # CTopic
        . '</div>'; # CType

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
    my ($self, $sourceFile, $parsedFile, $index) = @_;
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
            my $topic = $parsedFile->[$index];


            # Remove modifiers as appropriate for the current entry.

            if ($topic->Type() == ::TOPIC_SECTION() || $topic->Type() == ::TOPIC_CLASS())
                {
                $inSectionOrClassTag = undef;
                $inGroupTag = undef;
                $isMarkedAttr = undef;
                }
            elsif ($topic->Type() == ::TOPIC_GROUP())
                {
                $inGroupTag = undef;
                $isMarkedAttr = undef;
                };


            $output .=
             '<tr' . $isMarkedAttr . '><td' . $entrySizeAttr . '>'
                . '<div class=S' . ($index == 0 ? 'Main' : NaturalDocs::Topics->NameOf($topic->Type())) . '>'
                    . '<div class=SEntry>';


            # Add any remaining modifiers to the HTML in the form of div tags.  This modifier approach isn't the most elegant
            # thing, but there's not a lot of options.  It works.

            $output .= $inSectionOrClassTag . $inGroupTag;


            # Add the entry itself.

            my $toolTipProperties;

            # We only want a tooltip here if there's a protoype.  Otherwise it's redundant.

            if (defined $topic->Prototype())
                {
                my $tooltipID = $self->BuildToolTip($topic->Class(), $topic->Name(), $sourceFile, $topic->Type(),
                                                                     $topic->Prototype(), $topic->Summary());
                $toolTipProperties = $self->BuildToolTipLinkProperties($tooltipID);
                };

            $output .=
            '<a href="#' . $self->SymbolToHTMLSymbol( $parsedFile->[$index]->Class(), $parsedFile->[$index]->Name() ) . '" '
                . $toolTipProperties . '>'
                . $self->AddHiddenBreaks( $self->StringToHTML( $parsedFile->[$index]->Name() ))
            . '</a>';


            # Close the modifiers.

            if (defined $inGroupTag)
                {  $output .= '</div>';  };
            if (defined $inSectionOrClassTag)
                {  $output .= '</div>';  };

            $output .=
                    '</div>' # Entry
                . '</div>' # Type

            . '</td><td' . $descriptionSizeAttr . '>'

                . '<div class=S' . ($index == 0 ? 'Main' : NaturalDocs::Topics->NameOf($topic->Type())) . '>'
                    . '<div class=SDescription>';


            # Add the modifiers to the HTML yet again.

            $output .= $inSectionOrClassTag . $inGroupTag;


            # We want the summary to be the first sentence of the body, if it's regular text.  If it's a list, we'll leave it empty.

            if (defined $parsedFile->[$index]->Body())
                {
                $output .= $self->NDMarkupToHTML($sourceFile, $parsedFile->[$index]->Summary(), $parsedFile->[$index]->Scope());
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

            if ($topic->Type() == ::TOPIC_CLASS())
                {
                $inSectionOrClassTag = '<div class=SInClass>';
                $inGroupTag = undef;
                }
            elsif ($topic->Type() == ::TOPIC_SECTION())
                {
                $inSectionOrClassTag = '<div class=SInSection>';
                $inGroupTag = undef;
                }
            elsif ($topic->Type() == ::TOPIC_GROUP())
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
#   Function: BuildPrototype
#
#   Builds and returns the prototype as HTML.
#
#   Parameters:
#
#       type - The type of prototype it is.
#       prototype - The prototype to format.
#       file - The file the prototype was defined in.
#
#   Returns:
#
#       The prototype in HTML.
#
sub BuildPrototype #(type, prototype, file)
    {
    my ($self, $type, $prototype, $file) = @_;

    my $language = NaturalDocs::Languages->LanguageOf($file);
    my ($pre, $open, $params, $close, $post) = $language->FormatPrototype($type, $prototype);

    my $output;

    if (defined $params && scalar @$params > 1)
        {
        if (defined $open)
            {
            $open = $self->ConvertAmpChars($open);
            $open =~ s/ /&nbsp;/g;
            };
        if (defined $close)
            {
            $close = $self->ConvertAmpChars($close);
            $close =~ s/ /&nbsp;/g;
            };

        my $firstParam = shift @$params;
        my $lastParam = pop @$params;

        $output =
        # Crappy hacky extra div and table because browsers interpret padding on tables differently.
        '<table border=0 cellspacing=0 cellpadding=0><tr><td><div class=CPrototype>'
        . '<table border=0 cellspacing=0 cellpadding=0><tr>'

            . '<td style="vertical-align: bottom; text-align: right">' . $self->ConvertAmpChars($pre) . '</td>'
            . '<td style="vertical-align: bottom">' . $open . '</td>'
            . '<td style="vertical-align: bottom" nowrap>' . $self->ConvertAmpChars($firstParam) . '</td>';

            if (scalar @$params)
                {
                $output .=
                   '<td colspan=2></td>'
               . '</tr><tr>'
                   . '<td colspan=2></td>'
                   . '<td nowrap>';

                for (my $i = 0; $i < scalar @$params; $i++)
                    {
                    if ($i > 0)
                        {  $output .= '<br>';  };

                    $output .= $self->ConvertAmpChars($params->[$i]);
                    };

                $output .= '</td>';
                };

            if (defined $lastParam)
                {
                $output .=
                    '<td colspan=2></td>'
                . '</tr><tr>'
                    . '<td colspan=2></td>'
                    . '<td style="vertical-align: top" nowrap>' . $self->ConvertAmpChars($lastParam) . '</td>';
                };

            $output .=
            '<td style="vertical-align: top">' . $close . '</td>'
            . '<td style="vertical-align: top">' . $self->ConvertAmpChars($post) . '</td>'
       . '</tr></table>'
       . '</div></td></tr></table>';
        }

    else # (!defined $params || scalar @$params == 1)
        {
        my $string = $pre . $open . (defined $params ? $params->[1] : '') . $close . $post;

        $output =
        # A surrounding table as a hack to make the div form-fit.
        '<table border=0 cellspacing=0 cellpadding=0><tr><td>'
            . '<div class=CPrototype>'
                . $self->ConvertAmpChars($string)
            . '</div>'
        . '</tr></td></table>';
        };

    return $output;
    };

#
#   Function: BuildFooter
#
#   Builds and returns the HTML footer for the page.
#
sub BuildFooter
    {
    my $self = shift;
    my $footer = NaturalDocs::Menu->Footer();

    if (defined $footer)
        {
        if (substr($footer, -1, 1) ne '.')
            {  $footer .= '.';  };

        $footer =~ s/\(c\)/&copy;/gi;

        $footer .= '&nbsp; Generated by <a href="' . NaturalDocs::Settings->AppURL() . '">Natural Docs</a>.'
        }
    else
        {
        $footer = 'Generated by <a href="' . NaturalDocs::Settings->AppURL() . '">Natural Docs</a>';
        };

    return '<!--START_ND_FOOTER-->' . $footer . '<!--END_ND_FOOTER-->';
    };


#
#   Function: BuildIndexContent
#
#   Builds and returns index's content in HTML.
#
#   Parameters:
#
#       index  - An arrayref of <NaturalDocs::SymbolTable::IndexElement> objects.
#       outputFile - The output file the index is going to be stored in.  Since there may be multiple files, just send the first file.
#
#   Returns:
#
#       An arrayref of the index sections.  Index 0 is the symbols, index 1 is the numbers, and each following index is A through Z.
#       The content of each section is its HTML, or undef if there is nothing for that section.
#
sub BuildIndexContent #(index, outputFile)
    {
    my ($self, $index, $outputFile) = @_;

    $self->ResetToolTips();

    my $content = [ ];
    my $contentIndex;

    foreach my $entry (@$index)
        {
        # Check for headings

        $contentIndex = uc(substr($entry->Symbol(), 0, 1));

        if ($contentIndex =~ /^[0-9]$/)
            {  $contentIndex = 1;  }
        elsif ($contentIndex !~ /^[A-Z]$/)
            {  $contentIndex = 0;  }
        else
            {  $contentIndex = (ord(lc($contentIndex)) - ord('a')) + 2;  };


        # Build a simple entry

        if (!ref $entry->Class() && !ref $entry->File())
            {
            $content->[$contentIndex] .=
                $self->BuildIndexLink($entry->Symbol(), 'ISymbol', $entry->Class(), 1, $entry->Symbol(),
                                                $entry->File(), $entry->Type(), $entry->Prototype(), $entry->Summary(), $outputFile);
            }


        # Build an entry with subindexes.

        else
            {
            $content->[$contentIndex] .=
            '<div class=IEntry>'
                . '<span class=ISymbol>' . $self->StringToHTML($entry->Symbol()) . '</span>';

                if (defined $entry->Class() && !ref $entry->Class())
                    {  $content->[$contentIndex] .= ' <span class=IParent>(' . $entry->Class() . ')</span>';  };

                $content->[$contentIndex] .=
                '<div class=ISubIndex>';

            if (ref $entry->Class())
                {
                my $classEntries = $entry->Class();

                foreach my $classEntry (@$classEntries)
                    {
                    if (ref $classEntry->File())
                        {
                        $content->[$contentIndex] .= '<div class=IEntry><span class=IParent>';

                        if (defined $classEntry->Class())
                            {  $content->[$contentIndex] .= $self->AddHiddenBreaks($self->StringToHTML($classEntry->Class()));  }
                        else
                            {  $content->[$contentIndex] .= 'Global';  };

                        $content->[$contentIndex] .= '</span><div class=ISubIndex>';

                        my $fileEntries = $classEntry->File();
                        foreach my $fileEntry (@$fileEntries)
                            {
                            $content->[$contentIndex] .=
                                $self->BuildIndexLink($fileEntry->File(), 'IFile', $classEntry->Class(), 0, $entry->Symbol(),
                                                                 $fileEntry->File(), $fileEntry->Type(), $fileEntry->Prototype(),
                                                                 $fileEntry->Summary(), $outputFile);
                            };

                        $content->[$contentIndex] .= '</div></div>';
                        }

                    else #(!ref $classEntry->File())
                        {
                        $content->[$contentIndex] .=
                            $self->BuildIndexLink( ($classEntry->Class() || 'Global'), 'IParent', $classEntry->Class(), 0, $entry->Symbol(),
                                                              $classEntry->File(), $classEntry->Type(), $classEntry->Prototype(),
                                                              $classEntry->Summary(), $outputFile);
                        };
                    };
                }

            else #(!ref $entry->Class())
                {
                # ref $entry->File() is logically true then.

                my $fileEntries = $entry->File();
                foreach my $fileEntry (@$fileEntries)
                    {
                    $content->[$contentIndex] .=
                        $self->BuildIndexLink($fileEntry->File(), 'IFile', $entry->Class(), 0, $entry->Symbol(), $fileEntry->File(),
                                                         $fileEntry->Type(), $fileEntry->Prototype(), $fileEntry->Summary(), $outputFile);
                    };
                };

            $content->[$contentIndex] .= '</div></div>'; # Symbol IEntry and ISubIndex
            };


        # Add the tooltips to each section.

        $content->[$contentIndex] .= $self->BuildToolTips();
        $self->ResetToolTips(1);
        };


    return $content;
    };


#
#   Function: BuildIndexLink
#
#   Returns a link in the index, complete with surrounding <IEntry> tags.
#
#   Parameters:
#
#       name  - The text to appear for the link.
#       tag  - The tag to apply to name.  For example, <ISymbol>.
#       class  - The class of the symbol, if any.
#       showClass  - Whether the class name should be shown in parenthesis.
#       symbol  - The symbol to link to.
#       file  - The source file the symbol appears in.
#       type  - The type of the symbol.  One of the <Topic Types>.
#       prototype  - The prototype of the symbol, if any.
#       summary  - The summary of the symbol, if any.
#       outputFile  - The output file the link is appearing in.
#
#   Returns:
#
#       The link entry, including <IEntry> tags.
#
sub BuildIndexLink #(name, tag, class, showClass, symbol, file, type, prototype, summary, outputFile)
    {
    my ($self, $name, $tag, $class, $showClass, $symbol, $file, $type, $prototype, $summary, $outputFile) = @_;

    my $output =
    '<div class=IEntry>'
        . '<a href="' . $self->MakeRelativeURL( $outputFile, $self->OutputFileOf($file) )
            . '#' . $self->SymbolToHTMLSymbol($class, $symbol) . '" '
            . 'class=' . $tag . ' ';

    my $tooltipID = $self->BuildToolTip($class, $symbol, $file, $type, $prototype, $summary);
    my $tooltipProperties = $self->BuildToolTipLinkProperties($tooltipID);

    $output .= $tooltipProperties . '>' . $self->AddHiddenBreaks($self->StringToHTML($name)) . '</a>';

    if ($showClass && defined $class)
        {  $output .= ', <span class=IParent>' . $class . '</span>';  };

    $output .= '</div>';

    return $output;
    };


#
#   Function: BuildIndexFiles
#
#   Builds an index file or files.
#
#   Parameters:
#
#       type - The type the index is limited to, or undef for none.  Should be one of the <Topic Types>.
#       indexContent - An arrayref containing the index content.  Each entry is a section; index 0 is symbols, index 1 is numbers,
#                             and following indexes represent A through Z.
#       beginPage - All the content of the HTML page up to where the index content should appear.
#       endPage - All the content of the HTML page past where the index should appear.
#
#   Returns:
#
#       The number of pages in the index.
#
sub BuildIndexFiles #(type, indexContent, beginPage, endPage)
    {
    my ($self, $type, $indexContent, $beginPage, $endPage) = @_;

    my $page = 1;
    my $pageSize = 0;
    my @pageLocation;

    # The maximum page size acceptable before starting a new page.  Note that this doesn't include beginPage and endPage,
    # because we don't want something like a large menu screwing up the calculations.
    use constant PAGESIZE_LIMIT => 40000;


    # File the pages.

    for (my $i = 0; $i < scalar @$indexContent; $i++)
        {
        if (!defined $indexContent->[$i])
            {  next;  };

        $pageSize += length($indexContent->[$i]);
        $pageLocation[$i] = $page;

        if ($pageSize + length($indexContent->[$i + 1]) > PAGESIZE_LIMIT)
            {
            $page++;
            $pageSize = 0;
            };
        };


    # Build the pages.

    my $indexFileName;
    $page = -1;
    my $oldPage = -1;

    for (my $i = 0; $i < scalar @$indexContent; $i++)
        {
        if (!defined $indexContent->[$i])
            {  next;  };

        $page = $pageLocation[$i];

        # Switch files if we need to.

        if ($page != $oldPage)
            {
            if ($oldPage != -1)
                {
                print INDEXFILEHANDLE $endPage;
                close(INDEXFILEHANDLE);
                };

            $indexFileName = NaturalDocs::File->JoinPath(NaturalDocs::Settings->OutputDirectoryOf($self),
                                                                               $self->IndexFileOf($type, $page));

            open(INDEXFILEHANDLE, '>' . $indexFileName)
                or die "Couldn't create output file " . $indexFileName . ".\n";

            print INDEXFILEHANDLE $beginPage;

            print INDEXFILEHANDLE '' . $self->BuildIndexNavigationBar($type, $page, \@pageLocation);

            $oldPage = $page;
            };

        print INDEXFILEHANDLE
        '<div class=ISection>'

            . '<div class=IHeading>'
                . '<a name="' . $indexAnchors[$i] . '"></a>'
                 . $indexHeadings[$i]
            . '</div>'

            . $indexContent->[$i]

        . '</div>';
        };

    if ($page != -1)
        {
        print INDEXFILEHANDLE $endPage;
        close(INDEXFILEHANDLE);
        }

    # Build a dummy page so there's something at least.
    else
        {
        $indexFileName = NaturalDocs::File->JoinPath(NaturalDocs::Settings->OutputDirectoryOf($self),
                                                                           $self->IndexFileOf($type, 1));

        open(INDEXFILEHANDLE, '>' . $indexFileName)
            or die "Couldn't create output file " . $indexFileName . ".\n";

        print INDEXFILEHANDLE
            $beginPage
            . $self->BuildIndexNavigationBar($type, 1, \@pageLocation)
            . 'There are no entries in the ' . lc( NaturalDocs::Topics->NameOf($type) ) . ' index.'
            . $endPage;

        close(INDEXFILEHANDLE);
        };


    return $page;
    };


#
#   Function: BuildIndexNavigationBar
#
#   Builds a navigation bar for a page of the index.
#
#   Parameters:
#
#       type - The type of the index, or undef for general.  Should be one of the <Topic Types>.
#       page - The page of the index the navigation bar is for.
#       locations - An arrayref of the locations of each section.  Index 0 is for the symbols, index 1 for the numbers, and the rest
#                       for each letter.  The values are the page numbers where the sections are located.
#
sub BuildIndexNavigationBar #(type, page, locations)
    {
    my ($self, $type, $page, $locations) = @_;

    my $output = '<div class=INavigationBar>';

    for (my $i = 0; $i < scalar @indexHeadings; $i++)
        {
        if ($i != 0)
            {  $output .= ' &middot; ';  };

        if (defined $locations->[$i])
            {
            $output .= '<a href="';

            if ($locations->[$i] != $page)
                {  $output .= $self->IndexFileOf($type, $locations->[$i]);  };

            $output .= '#' . $indexAnchors[$i] . '">' . $indexHeadings[$i] . '</a>';
            }
        else
            {
            $output .= $indexHeadings[$i];
            };
        };

    $output .= '</div>';

    return $output;
    };


#
#   Function: BuildToolTip
#
#   Builds the HTML for a symbol's tooltip and stores it in <tooltipHTML>.
#
#   Parameters:
#
#       class - The target's class, or undef for global.
#       symbol - The target symbol.
#       file - The file the target's defined in.
#       type - The symbol type.  Should be one of the <Topic Types>.
#       prototype - The target prototype, or undef for none.
#       summary - The target summary, or undef for none.
#
#   Returns:
#
#       If a tooltip is necessary for the link, returns the tooltip ID.  If not, returns undef.
#
sub BuildToolTip #(class, symbol, file, type, prototype, summary)
    {
    my ($self, $class, $symbol, $file, $type, $prototype, $summary) = @_;

    if (defined $prototype || defined $summary)
        {
        my $fullSym = $self->SymbolToHTMLSymbol($class, $symbol);
        my $number = $tooltipSymbolsToNumbers{$fullSym};

        if (!defined $number)
            {
            $number = $tooltipNumber;
            $tooltipNumber++;

            $tooltipSymbolsToNumbers{$fullSym} = $number;

            $tooltipHTML .=
            '<div class=CToolTip id="tt' . $number . '">'
                . '<div class=C' . NaturalDocs::Topics->NameOf($type) . '>';

            if (defined $prototype)
                {
                $tooltipHTML .= $self->BuildPrototype($type, $prototype, $file);
                };

            if (defined $summary)
                {
                # Remove links, since people can't/shouldn't be clicking on tooltips anyway.

                $summary =~ s/<\/?(?:link|url)>//g;

                $summary = $self->NDMarkupToHTML(undef, $summary, undef);

                # XXX - Hack.  We want to remove e-mail links as well, but keep their obfuscation.  So we leave the tags in there for
                # the NDMarkupToHTML call, then strip out the link part afterwards.  The text obfuscation should still be in place.

                $summary =~ s/<\/?a[^>]+>//g;

                $tooltipHTML .= $summary;
                };

            $tooltipHTML .=
                '</div>'
            . '</div>';
            };

        return 'tt' . $number;
        }
    else
        {  return undef;  };
    };

#
#   Function: BuildToolTips
#
#   Builds and returns the tooltips for the page in HTML.
#
sub BuildToolTips
    {
    my $self = shift;
    return $tooltipHTML;
    };

#
#   Function: MenuToggleJavaScript
#
#   Returns the JavaScript necessary to expand and collapse the menus.
#
#   Creates the JavaScript function ToggleMenu(id).  Pass the menu group ID and it will toggle its display style between
#   "block" and "none".
#
sub MenuToggleJavaScript
    {
    my $self = shift;

    return

    '<script language=JavaScript><!-- ' . "\n"

    . 'function ToggleMenu(id)'
        . '{'
        . 'if (!window.document.getElementById) { return; };'

        . 'var display = window.document.getElementById(id).style.display;'

        . 'if (display == "none") { display = "block"; }'
        . 'else { display = "none"; }'

        . 'window.document.getElementById(id).style.display = display;'
        . '}'

    . '// --></script>';
    };


#
#   Function: BrowserStylesJavaScript
#
#   Returns the JavaScript necessary to detect the browser.
#
#   The JavaScript creates two variables, browserType and browserVer.  These contain the <Browser Styles> if the browser is
#   detected, has JavaScript turned on, etc.  One or both may be undefined.
#
sub BrowserStylesJavaScript
    {
    my $self = shift;

    return

    '<script language=JavaScript><!--' . "\n"

        . 'var agt=navigator.userAgent.toLowerCase();'
        . 'var browserType;'
        . 'var browserVer;'

        . 'if (agt.indexOf("opera") != -1) {'
            . 'browserType = "Opera";'
            . 'if (agt.indexOf("opera 5") != -1 || agt.indexOf("opera/5") != -1) {'
                . 'browserVer = "Opera5"; }'
            . 'else if (agt.indexOf("opera 6") != -1 || agt.indexOf("opera/6") != -1) {'
                . 'browserVer = "Opera6"; }'
            . 'else if (agt.indexOf("opera 7") != -1 || agt.indexOf("opera/7") != -1) {'
                . 'browserVer = "Opera7"; }'
            . '}'

        . 'else if (agt.indexOf("khtml") != -1 || agt.indexOf("konq") != -1) {'
            . 'browserType = "KHTML"; }'

        . 'else if (agt.indexOf("msie") != -1) {'
            . 'browserType = "IE";'
            . 'if (agt.indexOf("msie 4") != -1) {'
                . 'browserVer = "IE4"; }'
            . 'else if (agt.indexOf("msie 5") != -1) {'
                . 'browserVer = "IE5"; }'
            . 'else if (agt.indexOf("msie 6") != -1) {'
                . 'browserVer = "IE6"; }'
            . '}'

        . 'else if (agt.indexOf("gecko") != -1) {'
            . 'browserType = "Gecko"; }'

        # Opera already taken care of.
        . 'else if (agt.indexOf("mozilla") != -1 && agt.indexOf("compatible") == -1 && agt.indexOf("spoofer") == -1 && '
            . 'agt.indexOf("webtv") == -1 && agt.indexOf("hotjava") == -1) {'
            . 'browserType = "Netscape";'
            . 'if (agt.indexOf("mozilla/4") != -1) {'
                . 'browserVer = "Netscape4"; }'
            . '}'

    . '// --></script>';
    };


#
#   Function: ToolTipsJavaScript
#
#   Returns the JavaScript necessary to show, hide, and position tool tips.
#
#   Creates the functions ShowTip(tooltipID, linkID) and HideTip(tooltipID), which toggle the tooltips' visibility style between
#   "visible" and "hidden".  Tooltip elements should be hidden by default.  Each link needs to have a unique ID.
#
sub ToolTipsJavaScript
    {
    my $self = shift;

    return

    '<script language=JavaScript><!--' . "\n"

    . 'var tooltipTimer = 0;'

    . 'function ShowTip(event, tooltipID, linkID)'
        . '{'
        . 'if (tooltipTimer)'
            . '{  clearTimeout(tooltipTimer);  };'

        . 'var docX = event.clientX + window.pageXOffset;'
        . 'var docY = event.clientY + window.pageYOffset;'

        . 'var showCommand = "ReallyShowTip(\'" + tooltipID + "\', \'" + linkID + "\', " + docX + ", " + docY + ")";'

        # KHTML can't handle showing on a timer right now.

        . 'if (browserType != "KHTML")'
            . '{  tooltipTimer = setTimeout(showCommand, 1000);  }'
        . 'else'
            . '{  eval(showCommand);  };'
        . '}'

    . 'function ReallyShowTip(tooltipID, linkID, docX, docY)'
        . '{'
        . 'tooltipTimer = 0;'

        . 'var tooltip;'
        . 'var link;'

        . 'if (document.getElementById)'
            . '{'
            . 'tooltip = document.getElementById(tooltipID);'
            . 'link = document.getElementById(linkID);'
            . '}'
        . 'else if (document.all)'
            . '{'
            . 'tooltip = eval("document.all[\'" + tooltipID + "\']");'
            . 'link = eval("document.all[\'" + linkID + "\']");'
            . '}'

        . 'if (tooltip)'
            . '{'
            . 'var left = 0;'
            . 'var top = 0;'

            # Not everything supports offsetTop/Left/Width, and some, like Konqueror and Opera 5, think they do but do it badly.

            . 'if (link && link.offsetWidth != null && browserType != "KHTML" && browserVer != "Opera5")'
                . '{'
                . 'var item = link;'
                . 'while (item != document.body)'
                    . '{'
                    . 'left += item.offsetLeft;'
                    . 'item = item.offsetParent;'
                    . '}'

                . 'item = link;'
                . 'while (item != document.body)'
                    . '{'
                    . 'top += item.offsetTop;'
                    . 'item = item.offsetParent;'
                    . '}'
                . 'top += link.offsetHeight;'
                . '}'

            # The fallback method is to use the mouse X and Y relative to the document.  We use a separate if and test if its a number
            # in case some browser snuck through the above if statement but didn't support everything.

            . 'if (!isFinite(top) || top == 0)'
                . '{'
                . 'left = docX;'
                . 'top = docY;'
                . '}'

            # Some spacing to get it out from under the cursor.

            . 'top += 10;'

            # Make sure the tooltip doesn't get smushed by being too close to the edge, or in some browsers, go off the edge of the
            # page.  We do it here because Konqueror does get offsetWidth right even if it doesn't get the positioning right.

            . 'if (tooltip.offsetWidth != null)'
                . '{'
                . 'var width = tooltip.offsetWidth;'
                . 'var docWidth = document.body.clientWidth;'

                . 'if (left + width > docWidth)'
                    . '{  left = docWidth - width - 1;  }'
                . '}'

            # Opera 5 chokes on the px extension, so it can use the Microsoft one instead.

            . 'if (tooltip.style.left != null && browserVer != "Opera5")'
                . '{'
                . 'tooltip.style.left = left + "px";'
                . 'tooltip.style.top = top + "px";'
                . '}'
            . 'else if (tooltip.style.pixelLeft != null)'
                . '{'
                . 'tooltip.style.pixelLeft = left;'
                . 'tooltip.style.pixelTop = top;'
                . '}'

            . 'tooltip.style.visibility = "visible";'
            . '}'
        . '}'

    . 'function HideTip(tooltipID)'
        . '{'
        . 'if (tooltipTimer)'
            . '{'
            . 'clearTimeout(tooltipTimer);'
            . 'tooltipTimer = 0;'
            . '}'

        . 'var tooltip;'

        . 'if (document.getElementById)'
            . '{  tooltip = document.getElementById(tooltipID); }'
        . 'else if (document.all)'
            . '{  tooltip = eval("document.all[\'" + tooltipID + "\']");  }'

        . 'if (tooltip)'
            . '{  tooltip.style.visibility = "hidden";  }'
        . '}'

    . '// --></script>';
    };

#
#   Function: OpeningBrowserStyles
#
#   Returns the JavaScript that will add opening browser styles if necessary.
#
sub OpeningBrowserStyles
    {
    my $self = shift;

    return

    '<script language=JavaScript><!--' . "\n"

        # IE 4 and 5 don't understand 'undefined', so you can't say '!= undefined'.
        . 'if (browserType) {'
            . 'document.write("<div class=" + browserType + ">");'
            . 'if (browserVer) {'
                . 'document.write("<div class=" + browserVer + ">"); }'
            . '}'

    . '// --></script>';
    };


#
#   Function: ClosingBrowserStyles
#
#   Returns the JavaScript that will close browser styles if necessary.
#
sub ClosingBrowserStyles
    {
    my $self = shift;

    return

    '<script language=JavaScript><!--' . "\n"

        . 'if (browserType) {'
            . 'if (browserVer) {'
                . 'document.write("</div>"); }'
            . 'document.write("</div>");'
            . '}'

    . '// --></script>';
    };



###############################################################################
# Group: Support Functions


#
#   function: PurgeIndexFiles
#
#   Removes all or some of the output files for an index.
#
#   Parameters:
#
#       type  - The index type, or undef for general.  Should be one of the <Topic Types>.
#       startingPage - If defined, only pages starting with this number will be removed.  Otherwise all pages will be removed.
#
sub PurgeIndexFiles #(type, startingPage)
    {
    my ($self, $type, $page) = @_;

    if (!defined $page)
        {  $page = 1;  };

    my $outputDirectory = NaturalDocs::Settings->OutputDirectoryOf($self);

    for (;;)
        {
        my $file = NaturalDocs::File->JoinPath($outputDirectory, $self->IndexFileOf($type, $page));

        if (-e $file)
            {
            unlink($file);
            $page++;
            }
        else
            {
            last;
            };
        };
    };


#
#   function: OutputFileOf
#
#   Returns the output file name of the source file.
#
sub OutputFileOf #(sourceFile)
    {
    my ($self, $sourceFile) = @_;

    # We need to change any extensions to dashes because Apache will think file.pl.html is a script.
    # We also need to add a dash if the file doesn't have an extension so there'd be no conflicts with index.html,
    # FunctionIndex.html, etc.

    if (!($sourceFile =~ s/\./-/g))
        {  $sourceFile .= '-';  };

    $sourceFile =~ s/ /_/g;

    return $sourceFile . '.html';
    };

#
#   function:IndexFileOf
#
#   Returns the output file name of the index file.
#
#   Parameters:
#
#       type  - The type of index, or undef if general.
#       page  - The page number.  Undef is the same as one.
#
sub IndexFileOf #(type, page)
    {
    my ($self, $type, $page) = @_;

    return (defined $type ? NaturalDocs::Topics->NameOf($type) : 'General') . 'Index'
            . (defined $page && $page != 1 ? $page : '') . '.html';
    };

#
#   function:IndexTitleOf
#
#   Returns the page title of the index file.
#
#   Parameters:
#
#       type  - The type of index, or undef if general.
#
sub IndexTitleOf #(type)
    {
    my ($self, $type) = @_;

    return (defined $type ? NaturalDocs::Topics->NameOf($type) . ' ' : '') . 'Index';
    };

#
#   function: MakeRelativeURL
#
#   Returns a relative path between two files in the output tree and returns it in URL format.
#
#   Parameters:
#
#       baseFile    - The base file in local format, *not* in URL format.
#       targetFile  - The target of the link in local format, *not* in URL format.
#
#   Returns:
#
#       The relative URL to the target.
#
sub MakeRelativeURL #(baseFile, targetFile)
    {
    my ($self, $baseFile, $targetFile) = @_;

    my $baseDir = NaturalDocs::File->NoFileName($baseFile);
    my $relativePath = NaturalDocs::File->MakeRelativePath($baseDir, $targetFile);

    return $self->ConvertAmpChars( NaturalDocs::File->ConvertToURL($relativePath) );
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
    my ($self, $string) = @_;

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
    return $self->AddDoubleSpaces($string);
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
    my ($self, $class, $symbol) = @_;

    ($class, $symbol) = NaturalDocs::SymbolTable->Defines($class, $symbol);

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
    my ($self, $sourceFile, $text, $scope) = @_;
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

            # Convert quotes to fancy quotes.
            # DEPENDENCY: BuildLink needs to be able to undo these.
            $text =~ s/^\'/&lsquo;/gm;
            $text =~ s/([\ \(\[\{])\'/$1&lsquo;/g;
            $text =~ s/\'/&rsquo;/g;

            $text =~ s/^&quot;/&ldquo;/gm;
            $text =~ s/([\ \(\[\{])&quot;/$1&ldquo;/g;
            $text =~ s/&quot;/&rdquo;/g;

            # Resolve and convert links.
            $text =~ s/<link>([^<]+)<\/link>/$self->BuildLink($scope, $1, $sourceFile)/ge;
            $text =~ s/<url>([^<]+)<\/url>/<a href=\"$1\" class=LURL>$1<\/a>/g;
            $text =~ s/<email>([^<]+)<\/email>/$self->BuildEMailLink($1)/eg;

            # Add double spaces too.
            $text = $self->AddDoubleSpaces($text);

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
            $text =~ s/<ds>([^<]+)<\/ds>/$self->MakeDescriptionListSymbol($scope, $1)/ge;

            sub MakeDescriptionListSymbol #(scope, text)
                {
                my ($self, $scope, $text) = @_;

                return
                '<tr>'
                    . '<td class=CDLEntry>'
                        # The anchors are closed, but not around the text, to prevent the :hover CSS style from kicking in.
                        . '<a name="' . $self->SymbolToHTMLSymbol($scope, NaturalDocs::NDMarkup->RestoreAmpChars($text)) . '"></a>'
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
#   Function: BuildLink
#
#   Creates a HTML link to a symbol, if it exists.
#
#   Parameters:
#
#       scope  - The scope the link appears in.
#       text  - The link text
#       sourceFile  - The file the link appears in.
#
#   Returns:
#
#       The link in HTML, including tags.  If the link doesn't resolve to anything, returns the HTML that should be substituted for it.
#
sub BuildLink #(scope, text, sourceFile)
    {
    my ($self, $scope, $text, $sourceFile) = @_;

    my $restoredText = NaturalDocs::NDMarkup->RestoreAmpChars($text);

    # DEPENDENCY: This is undoing the fancy quotes from NDMarkupToHTML.
    $restoredText =~ s/&(?:[lr]dquo|quot);/\"/g;
    $restoredText =~ s/&[lr]squo;/\'/g;

    my $target = NaturalDocs::SymbolTable->References($scope, $restoredText, $sourceFile);

    if (defined $target)
        {
        my $targetFile;

        if ($target->File() ne $sourceFile)
            {  $targetFile = $self->MakeRelativeURL( $self->OutputFileOf($sourceFile), $self->OutputFileOf($target->File()) );  };
        # else leave it undef

        my $targetTooltipID = $self->BuildToolTip($target->Class(), $target->Symbol(), $sourceFile, $target->Type(),
                                                                      $target->Prototype(), $target->Summary());

        my $toolTipProperties = $self->BuildToolTipLinkProperties($targetTooltipID);

        return '<a href="' . $targetFile . '#' . $self->SymbolToHTMLSymbol( $target->Class(), $target->Symbol() ) . '" '
                    . 'class=L' . NaturalDocs::Topics->NameOf($target->Type()) . ' ' . $toolTipProperties . '>' . $text . '</a>';
        }
    else
        {
        return '&lt;' . $text . '&gt;';
        };
    };


#
#   Function: BuildEMailLink
#
#   Creates a HTML link to an e-mail address.  The address will be transparently munged to protect it (hopefully) from spambots.
#
#   Parameters:
#
#       address  - The e-mail address.
#
#   Returns:
#
#       The HTML e-mail link, complete with tags.
#
sub BuildEMailLink #(address)
    {
    my ($self, $address) = @_;
    my @splitAddress;


    # Hack the address up.  We want two user pieces and two host pieces.

    my ($user, $host) = split(/\@/, $address);

    my $userSplit = length($user) / 2;

    push @splitAddress, substr($user, 0, $userSplit);
    push @splitAddress, substr($user, $userSplit);

    push @splitAddress, '@';

    my $hostSplit = length($host) / 2;

    push @splitAddress, substr($host, 0, $hostSplit);
    push @splitAddress, substr($host, $hostSplit);


    # Now put it back together again.  We'll use spans to split the text transparently and JavaScript to split and join the link.

    return
    "<a href=\"#\" onClick=\"location.href='mai' + 'lto:' + '" . join("' + '", @splitAddress) . "'; return false;\" class=LEMail>"
        . $splitAddress[0] . '<span style="display: none">(delete this)</span>' . $splitAddress[1]
        . '<span>@</span>'
        . $splitAddress[3] . '<span style="display: none">(delete this)</span>' . $splitAddress[4]
    . '</a>';
    };


#
#   Function: BuildToolTipLinkProperties
#
#   Returns the properties that should go in the link tag to add a tooltip to it.  Because the function accepts undef, you can
#   call it without checking if <BuildToolTip()> returned undef or not.
#
#   Parameters:
#
#       toolTipID - The ID of the tooltip.  If undef, the function will return undef.
#
#   Returns:
#
#       The properties that should be put in the link tag, or undef if toolTipID wasn't specified.
#
sub BuildToolTipLinkProperties #(toolTipID)
    {
    my ($self, $toolTipID) = @_;

    if (defined $toolTipID)
        {
        my $currentNumber = $tooltipLinkNumber;
        $tooltipLinkNumber++;

        return 'id=link' . $currentNumber . ' '
                . 'onMouseOver="ShowTip(event, \'' . $toolTipID . '\', \'link' . $currentNumber . '\')" '
                . 'onMouseOut="HideTip(\'' . $toolTipID . '\')"';
        }
    else
        {  return undef;  };
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
    my ($self, $text) = @_;

    # Question marks and exclamation points get double spaces unless followed by a lowercase letter.

    $text =~ s/  ([^\ \t\r\n] [\!\?])  # Must appear after a non-whitespace character to apply.

                      (&quot;|&[lr][sd]quo;|[\'\"\]\}\)]?)  # Tolerate closing quotes, parenthesis, etc.
                      ((?:<[^>]+>)*)  # Tolerate tags

                      \   # The space
                      (?![a-z])  # Not followed by a lowercase character.

                   /$1$2$3&nbsp;\ /gx;


    # Periods get double spaces if it's not followed by a lowercase letter.  However, if it's followed by a capital letter and the
    # preceding word is in the list of acceptable abbreviations, it won't get the double space.  Yes, I do realize I am seriously
    # over-engineering this.

    $text =~ s/  ([^\ \t\r\n]+)  # The word prior to the period.

                      \.

                      (&quot;|&[lr][sd]quo;|[\'\"\]\}\)]?)  # Tolerate closing quotes, parenthesis, etc.
                      ((?:<[^>]+>)*)  # Tolerate tags

                      \   # The space
                      ([^a-z])   # The next character, if it's not a lowercase letter.

                  /$1 . '.' . $2 . $3 . MaybeExpand($1, $4) . $4/gex;

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
    my ($self, $text) = @_;

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
    my $self = shift;
    return '<span class=HB> </span>';
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
    my ($self, $string) = @_;

    # \.(?=.{5,}) instead of \. so file extensions don't get breaks.
    # :+ instead of :: because Mac paths are separated by a : and we want to get those too.

    $string =~ s/(\w(?:\.(?=.{5,})|:+|->|\\|\/))(\w)/$1 . $self->HiddenBreak() . $2/ge;

    return $string;
    };

#
#   Function: FindFirstFile
#
#   A function that finds and returns the first file entry in the menu, or undef if none.
#
sub FindFirstFile
    {
    # Hidden parameter: arrayref
    # Used for recursion only.

    my ($self, $arrayref) = @_;

    if (!defined $arrayref)
        {  $arrayref = NaturalDocs::Menu->Content();  };

    foreach my $entry (@$arrayref)
        {
        if ($entry->Type() == ::MENU_FILE())
            {
            return $entry;
            }
        elsif ($entry->Type() == ::MENU_GROUP())
            {
            my $result = $self->FindFirstFile($entry->GroupContent());
            if (defined $result)
                {  return $result;  };
            };
        };

    return undef;
    };


#
#   Function: ExpandMenu
#
#   Determines which groups should be expanded.
#
#   Parameters:
#
#       outputFile - The file the menu is being built for.  Does not have to be on the menu itself.
#       rootLength - The length of the menu's root group, *not* including the contents of subgroups.
#
#   Returns:
#
#       An arrayref of all the group numbers that should be expanded.  At minimum, it will contain the numbers of the groups
#       present in <menuSelectionHierarchy>, though it may contain more.
#
sub ExpandMenu #(outputFile, rootLength)
    {
    my ($self, $outputFile, $rootLength) = @_;

    my $toExpand = [ ];


    # First expand everything in the selection hierarchy.

    my $length = $rootLength;

    foreach my $entry (@menuSelectionHierarchy)
        {
        $length += $menuGroupLengths{$entry};
        push @$toExpand, $menuGroupNumbers{$entry};
        };


    # Now do multiple passes of group expansion as necessary.  We start from bottomIndex and expand outwards.  We stop going
    # in a direction if a group there is too long -- we do not skip over it and check later groups as well.  However, if one direction
    # stops, the other can keep going.

    my $pass = 1;
    my $hasSubGroups;

    while ($length < MENU_LENGTHLIMIT)
        {
        my $content;
        my $topIndex;
        my $bottomIndex;


        if ($pass == 1)
            {
            # First pass, we expand the selection's siblings.

            if (scalar @menuSelectionHierarchy)
                {  $content = $menuSelectionHierarchy[0]->GroupContent();  }
            else
                {  $content = NaturalDocs::Menu->Content();  };

            $bottomIndex = 0;

            while ($bottomIndex < scalar @$content &&
                     !($content->[$bottomIndex]->Type() == ::MENU_FILE() &&
                       $self->OutputFileOf($content->[$bottomIndex]->Target()) eq $outputFile) &&
                     !($content->[$bottomIndex]->Type() != ::MENU_INDEX() &&
                       $self->IndexFileOf($content->[$bottomIndex]->Target()) eq $outputFile) )
                {  $bottomIndex++;  };

            if ($bottomIndex == scalar @$content)
                {  $bottomIndex = 0;  };
            $topIndex = $bottomIndex - 1;
            }

        elsif ($pass == 2)
            {
            # If the section we just expanded had no sub-groups, do another pass trying to expand the parent's sub-groups.  The
            # net effect is that groups won't collapse as much unnecessarily.  Someone can click on a file in a sub-group and the
            # groups in the parent will stay open.

            if (!$hasSubGroups && scalar @menuSelectionHierarchy)
                {
                if (scalar @menuSelectionHierarchy > 1)
                    {  $content = $menuSelectionHierarchy[1]->GroupContent();  }
                else
                    {  $content = NaturalDocs::Menu->Content();  };

                $bottomIndex = 0;

                while ($bottomIndex < scalar @$content &&
                         $content->[$bottomIndex] != $menuSelectionHierarchy[0])
                    {  $bottomIndex++;  };

                $topIndex = $bottomIndex - 1;
                $bottomIndex++;  # Increment past our own group.
                $hasSubGroups = undef;
                }
            else
                {  last;  };
            }

        # No more passes.
        else
            {  last;  };


        while ( ($topIndex >= 0 || $bottomIndex < scalar @$content) && $length < MENU_LENGTHLIMIT)
            {
            # We do the bottom first.

            while ($bottomIndex < scalar @$content && $content->[$bottomIndex]->Type() != ::MENU_GROUP())
                {  $bottomIndex++;  };

            if ($bottomIndex < scalar @$content)
                {
                my $bottomEntry = $content->[$bottomIndex];
                $hasSubGroups = 1;

                if ($length + $menuGroupLengths{$bottomEntry} <= MENU_LENGTHLIMIT)
                    {
                    $length += $menuGroupLengths{$bottomEntry};
                    push @$toExpand, $menuGroupNumbers{$bottomEntry};
                    $bottomIndex++;
                    }
                else
                    {  $bottomIndex = scalar @$content;  };
                };

            # Top next.

            while ($topIndex >= 0 && $content->[$topIndex]->Type() != ::MENU_GROUP())
                {  $topIndex--;  };

            if ($topIndex >= 0)
                {
                my $topEntry = $content->[$topIndex];
                $hasSubGroups = 1;

                if ($length + $menuGroupLengths{$topEntry} <= MENU_LENGTHLIMIT)
                    {
                    $length += $menuGroupLengths{$topEntry};
                    push @$toExpand, $menuGroupNumbers{$topEntry};
                    $topIndex--;
                    }
                else
                    {  $topIndex = -1;  };
                };
            };


        $pass++;
        };

    return $toExpand;
    };

#
#   Function: ResetToolTips
#
#   Resets the <ToolTip Variables> for a new page.
#
#   Parameters:
#
#       samePage  - Set this flag if there's the possibility that the next batch of tooltips may be on the same page as the last.
#
sub ResetToolTips #(samePage)
    {
    my ($self, $samePage) = @_;

    if (!$samePage)
        {
        $tooltipLinkNumber = 1;
        $tooltipNumber = 1;
        };

    $tooltipHTML = undef;
    %tooltipSymbolsToNumbers = ( );
    };

1;
