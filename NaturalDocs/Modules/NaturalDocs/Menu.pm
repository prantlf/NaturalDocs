###############################################################################
#
#   Package: NaturalDocs::Menu
#
###############################################################################
#
#   A package handling the menu's contents and state.
#
#   Usage and Dependencies:
#
#       - The <Event Handlers> can be called by <NaturalDocs::Project> immediately.
#
#       - Prior to initialization, <NaturalDocs::Project> must be initialized, and all files that have been changed must be run
#         through <NaturalDocs::Parser::ParseForInformation()>.
#
#       - To initialize, call <LoadAndUpdate()>.  Afterwards, all other functions are available.
#
#       - To save the changes back to disk, call <Save()>.
#
###############################################################################

# This file is part of Natural Docs, which is Copyright © 2003 Greg Valure
# Natural Docs is licensed under the GPL

use NaturalDocs::Menu::Entry;
use NaturalDocs::Menu::Error;

use strict;
use integer;

package NaturalDocs::Menu;


###############################################################################
# Group: Variables

#
#   hash: menuSynonyms
#
#   A hash of the text synonyms for the menu tokens.  The keys are the lowercase synonyms, and the values are one of
#   the <Menu Item Types>.
#
my %menuSynonyms = (
                                'title'        => ::MENU_TITLE(),
                                'subtitle'   => ::MENU_SUBTITLE(),
                                'sub-title'  => ::MENU_SUBTITLE(),
                                'group'     => ::MENU_GROUP(),
                                'file'         => ::MENU_FILE(),
                                'text'        => ::MENU_TEXT(),
                                'link'        => ::MENU_LINK(),
                                'url'         => ::MENU_LINK(),
                                'footer'    => ::MENU_FOOTER(),
                                'copyright' => ::MENU_FOOTER()
                            );

#
#   bool: hasChanged
#
#   Whether the menu changed or not, regardless of why.
#
my $hasChanged;

#
#   Object: menu
#
#   The parsed menu file.  Is stored as a <MENU_GROUP> <NaturalDocs::Menu::Entry> object, with the top-level entries being
#   stored as the group's content.  This is done because it makes <LoadAndUpdate()> simpler to implement.  However, it is
#   exposed externally via <Content()> as an arrayref.
#
#   This structure will not contain objects for <MENU_TITLE>, <MENU_SUBTITLE>, or <MENU_FOOTER> entries.  Those will be
#   stored in the <title>, <subTitle>, and <footer> variables instead.
#
my $menu;

#
#   hash: defaultTitlesChanged
#
#   A hash of default titles that have changed, since <OnDefaultTitleChange()> will be called before <LoadAndUpdate()>.
#   Collects them to be applied later.
#
my %defaultTitlesChanged;

#
#   String: title
#
#   The title of the menu.
#
my $title;

#
#   String: subTitle
#
#   The sub-title of the menu.
#
my $subTitle;

#
#   String: footer
#
#   The footer for the documentation.
#
my $footer;


###############################################################################
# Group: Files

#
#   File: NaturalDocs_Menu.txt
#
#   The file used to generate the menu.
#
#   Format:
#
#       The file is plain text.  Blank lines can appear anywhere and are ignored.  Tags and their content must be completely
#       contained on one line with the exception of Group's braces.
#
#       > # [comment]
#
#       The file supports single-line comments via #.  They can appear alone on a line or after content.
#
#       > Title: [title]
#       > SubTitle: [subtitle]
#       > Footer: [footer]
#
#       The menu title, subtitle, and footer are specified as above.  Each can only be specified once, with subsequent ones being
#       ignored.  Subtitle is ignored if Title is not present.
#
#       > File: [file title] ([file name])
#       > File: [file title] (auto-title, [file name])
#
#       Files are specified as above.  If "auto-title," precedes the file name in the parenthesis, the file title is ignored and the default
#       is used instead.  If not specified, the file title overrides the default title.
#
#       > Group: [name]
#       > Group: [name] { ... }
#
#       Groups are specified as above.  If no braces are specified, the group's content is everything that follows until the end of the
#       file, the next group (braced or unbraced), or the closing brace of a parent group.  Group braces are the only things in this
#       file that can span multiple lines.
#
#       There is no limitations on where the braces can appear.  The opening brace can appear after the group tag, on its own line,
#       or preceding another tag on a line.  Similarly, the closing brace can appear after another tag or on its own line.  Being
#       bitchy here would just get in the way of quick and dirty editing; the package will clean it up automatically when it writes it
#       back to disk.
#
#       > Text: [text]
#
#       Arbitrary text is specified as above.  As with other tags, everything must be contained on the same line.
#
#       > Link: [URL]
#       > Link: [title] ([URL])
#
#       External links can be specified as above.  If the titled form is not used, the URL is used as the title.
#


###############################################################################
# Group: File Functions

#
#   Function: LoadAndUpdate
#
#   Loads the menu file from <NaturalDocs_Menu.txt> and updates it.  If a file is deleted or no longer has Natural Docs
#   content, it is removed from the menu.  If files are added or get Natural Docs content, they are added to the end.  If
#   there are groups defined, the new ones will be added in group Other.
#
sub LoadAndUpdate
    {
    my ($hasGroups, $errors, $filesInMenu, $trashAlert) = ParseMenuFile();

    if (defined $errors)
        {
        HandleErrors($errors);
        # HandleErrors will end execution.
        };

    if ($trashAlert)
        {
        my $backupFile = NaturalDocs::Project::MenuBackupFile();

        NaturalDocs::File::Copy( NaturalDocs::Project::MenuFile(), $backupFile );

        print
        "\n"
        . "Trashed menu warning:\n"
        . "   Natural Docs has detected that none of the file entries in the menu\n"
        . "   resolved to actual files.  If you have significantly changed your source\n"
        . "   tree, this is okay.  If not, this means you probably got the directories\n"
        . "   wrong in the command line.  Since this essentially resets your menu, a\n"
        . "   backup of your original menu file has been saved as\n"
        . "   " . $backupFile . "\n"
        . "\n";
        };


    AddMissingFiles($filesInMenu, $hasGroups);

    # Don't need this anymore.
    %defaultTitlesChanged = ( );
    };


#
#   Function: Save
#
#   Writes the menu to <NaturalDocs_Menu.txt>.
#
sub Save
    {
    my $menuFileHandle;

    open($menuFileHandle, '>' . NaturalDocs::Project::MenuFile())
        or die "Couldn't save menu file " . NaturalDocs::Project::MenuFile() . "\n";


    if (defined $title)
        {
        print $menuFileHandle 'Title: ' . $title . "\n";

        if (defined $subTitle)
            {
            print $menuFileHandle 'SubTitle: ' . $subTitle . "\n";
            }
        else
            {
            print $menuFileHandle
            "\n"
            . "# You can also add a sub-title to your menu by adding a\n"
            . "# \"SubTitle: [subtitle]\" line.\n";
            };
        }
    else
        {
        print $menuFileHandle
        "# You can add a title and sub-title to your menu.\n"
        . "# Just add \"Title: [project name]\" and \"SubTitle: [subtitle]\" lines here.\n";
        };

    print $menuFileHandle "\n";

    if (defined $footer)
        {
        print $menuFileHandle 'Footer: ' . $footer . "\n";
        }
    else
        {
        print $menuFileHandle
        "# You can add a footer to your documentation.  Just add a\n"
        . "# \"Footer: [text]\" line here.  If you want to add a copyright notice,\n"
        . "# this would be the place to do it.\n";
        };

    print $menuFileHandle

    "\n"

    # Remember to keep lines below eighty characters.

    . "# ------------------------------------------------------------------------ #\n\n"

    . "# Cut and paste the lines below to change the order in which your files\n"
    . "# appear on the menu.  Don't worry about adding or removing files, Natural\n"
    . "# Docs will take care of that.\n"
    . "# \n"
    . "# If you change the title of a file, make sure you remove \"auto-title,\"\n"
    . "# from the parenthesis or it won't stick.  Add \"auto-title,\" to the\n"
    . "# the parenthesis before the file name and Natural Docs will generate the\n"
    . "# title from the source file and keep it updated automatically.\n"
    . "# \n"
    . "# You can further organize the menu by grouping the entries.  Add a\n"
    . "# \"Group: [name] {\" line to start a group, and add a \"}\" to end it.  Groups\n"
    . "# can appear within each other.\n"
    . "# \n"
    . "# You can add text and web links to the menu by adding \"Text: [text]\" and\n"
    . "# \"Link: [text] ([URL])\" lines, respectively.\n"
    . "# \n"
    . "# The formatting and comments are auto-generated, so don't worry about\n"
    . "# neatness when editing the file.  Natural Docs will clean it up the next\n"
    . "# time it is run.  When working with groups, just deal with the braces and\n"
    . "# forget about the indentation and comments.\n"

    . "\n"
    . "# ------------------------------------------------------------------------ #\n"

    . "\n";

    WriteEntries($menu->GroupContent(), $menuFileHandle, undef);

    close($menuFileHandle);
    };


###############################################################################
# Group: Information Functions

#
#   Function: HasChanged
#
#   Returns whether the menu has changed or not.
#
sub HasChanged
    {  return $hasChanged;  };

#
#   Function: Content
#
#   Returns the parsed menu as an arrayref of <NaturalDocs::Menu::Entry> objects.  Do not change the arrayref.
#
#   The arrayref will not contain <MENU_TITLE> and <MENU_SUBTITLE> entries.  Use the <Title()> and <SubTitle()> functions
#   instead.
#
sub Content
    {  return $menu->GroupContent();  };

#
#   Function: Title
#
#   Returns the title of the menu, or undef if none.
#
sub Title
    {  return $title;  };

#
#   Function: SubTitle
#
#   Returns the sub-title of the menu, or undef if none.
#
sub SubTitle
    {  return $subTitle;  };

#
#   Function: Footer
#
#   Returns the footer of the documentation, or undef if none.
#
sub Footer
    {  return $footer;  };



###############################################################################
# Group: Event Handlers
#
#   These functions are called by <NaturalDocs::Project> only.  You don't need to worry about calling them.  For example, when
#   changing the default menu title of a file, you only need to call <NaturalDocs::Project::SetDefaultMenuTitle()>.  That function
#   will handle calling <OnDefaultTitleChange()>.


#
#   Function: OnFileChange
#
#   Called by <NaturalDocs::Project> if it detects that the menu file has changed.
#
sub OnFileChange
    {
    $hasChanged = 1;
    };


#
#   Function: OnDefaultTitleChange
#
#   Called by <NaturalDocs::Project> if the default menu title of a source file has changed.
#
#   Parameters:
#
#       file    - The source file that had its default menu title changed.
#       title   - The new title
#
sub OnDefaultTitleChange #(file, title)
    {
    my $file = shift;
    # We don't care about what it was changed to.  We keep the parameter because it may be useful if we ever switch to an
    # auto-detecting title override system.

    # Collect them for later.  We'll deal with them in LoadAndUpdateMenu().

    $defaultTitlesChanged{$file} = 1;
    };


###############################################################################
# Group: Support Functions


#
#   Function: ParseMenuFile
#
#   Loads and parses the menu file.
#
#   Returns:
#
#       The array ( hasGroups, errors, filesInMenu, trashAlert ).
#
#       hasGroups - Whether the menu uses groups or not.
#       errors - An arrayref of errors appearing in the file, each one being an <NaturalDocs::Menu::Error> object.
#       filesInMenu - An existence hashref of all the source files that appear in the menu.  This parameter will always exist.
#       trashAlert - Will be true if the menu file had a significant number of file entries, but all of them resolved invalid.  Use to
#                        protect against accidential menu file trashing due to mistakes in the command line.
#
#       Yeah, this method isn't the best, but the alternatives would be to make them package variables (they aren't needed outside
#       of <LoadAndUpdate()>) or to make <LoadAndUpdate()> a huge beast function (which it was before this was split off.)
#
sub ParseMenuFile
    {
    my $hasGroups;
    my $errors = [ ];
    my $filesInMenu = { };
    my $fileEntries = 0;

    # A stack of Menu::Entry object references as we move through the groups.
    my @groupStack;

    $menu = NaturalDocs::Menu::Entry::New(::MENU_GROUP(), undef, undef);
    my $currentGroup = $menu;

    # Whether we're currently in a braceless group, since we'd have to find the implied end rather than an explicit one.
    my $inBracelessGroup;

    # Whether we're right after a group token, which is the only place there can be an opening brace.
    my $afterGroupToken;

    my $lineNumber = 1;
    my $menuFileHandle;

    if (open($menuFileHandle, '<' . NaturalDocs::Project::MenuFile()))
        {
        my $menuFileContent;
        read($menuFileHandle, $menuFileContent, (stat(NaturalDocs::Project::MenuFile()))[7]);
        close($menuFileHandle);

        my @segments = split(/([\n{}\#])/, $menuFileContent);
        my $segment;
        $menuFileContent = undef;

        while (scalar @segments)
            {
            $segment = shift @segments;

            # Ignore empty segments caused by splitting.
            if (!length $segment)
                {  next;  };

            # Ignore line breaks.
            if ($segment eq "\n")
                {
                $lineNumber++;
                next;
                };

            # Ignore comments.
            if ($segment eq '#')
                {
                while (scalar @segments && $segments[0] ne "\n")
                    {  shift @segments;  };

                next;
                };


            # Check for an opening brace after a group token.  This has to be separate from the rest of the code because the flag
            # needs to be reset after every non-ignored segment.
            if ($afterGroupToken)
                {
                $afterGroupToken = undef;

                if ($segment eq '{')
                    {
                    $inBracelessGroup = undef;
                    next;
                    }
                else
                    {
                    $inBracelessGroup = 1;
                    };
                };


            # Now on to the real code.

            if ($segment eq '{')
                {
                push @$errors, NaturalDocs::Menu::Error::New($lineNumber, 'Opening braces are only allowed after Group tags.');
                }
            elsif ($segment eq '}')
                {
                # End a braceless group, if we were in one.
                if ($inBracelessGroup)
                    {
                    my $isEmpty = $currentGroup->GroupIsEmpty();

                    $currentGroup = pop @groupStack;
                    $inBracelessGroup = undef;

                    # Ignore this group if it was empty.
                    if ($isEmpty)
                        {  $currentGroup->PopFromGroup();  };
                    };

                # End a braced group too.
                if (scalar @groupStack)
                    {
                    my $isEmpty = $currentGroup->GroupIsEmpty();

                    $currentGroup = pop @groupStack;

                    # Ignore this group if it was empty.
                    if ($isEmpty)
                        {  $currentGroup->PopFromGroup();  };
                    }
                else
                    {
                    push @$errors, NaturalDocs::Menu::Error::New($lineNumber, 'Unmatched closing brace.');
                    };
                }

            # If the segment is a segment of text...
            else
                {
                $segment =~ s/^[ \t]+//;
                $segment =~ s/[ \t]+$//;

                # If the segment is keyword: name...
                if ($segment =~ /^([^:]+):\s+(.+)$/)
                    {
                    my $type = lc($1);
                    my $name = $2;

                    if (exists $menuSynonyms{$type})
                        {
                        $type = $menuSynonyms{$type};

                        if ($type == ::MENU_GROUP())
                            {
                            $hasGroups = 1;

                            # End a braceless group, if we were in one.
                            if ($inBracelessGroup)
                                {
                                my $isEmpty = $currentGroup->GroupIsEmpty();

                                $currentGroup = pop @groupStack;
                                $inBracelessGroup = undef;

                                # Ignore this group if it was empty.
                                if ($isEmpty)
                                    {  $currentGroup->PopFromGroup();  };
                                };

                            my $entry = NaturalDocs::Menu::Entry::New(::MENU_GROUP(), $name, undef);

                            $currentGroup->PushToGroup($entry);

                            push @groupStack, $currentGroup;
                            $currentGroup = $entry;

                            $afterGroupToken = 1;
                            }

                        elsif ($type == ::MENU_FILE())
                            {
                            if ($name =~ /^(.*)\(\s*(.+?)\s*\)$/)
                                {
                                my $fileTitle = $1;
                                my $parenthSection = $2;

                                $fileTitle =~ s/[ \t]+$//;

                                my $file;

                                if ($parenthSection =~ /^auto-title,\s*(.+)$/i)
                                    {
                                    # Clear the file title.  When creating the menu entry, having the title set to undef will make the entry use
                                    # the default one.
                                    $fileTitle = undef;
                                    $file = $1;

                                    # If the default title changed on this file, the menu changed.
                                    if (exists $defaultTitlesChanged{$file})
                                        {  $hasChanged = 1;  };
                                    }
                                else
                                    {
                                    $file = $parenthSection;
                                    };

                                if (NaturalDocs::Project::HasContent($file))  # This will also check if it exists.
                                    {
                                    $currentGroup->PushToGroup( NaturalDocs::Menu::Entry::New(::MENU_FILE(), $fileTitle, $file) );
                                    $filesInMenu->{$file} = 1;
                                    }
                                else
                                    {
                                    # If the file doesn't exist or have Natural Docs content, leave it off.
                                    $hasChanged = 1;
                                    };

                                # Regardless of whether it was okay or not.
                                $fileEntries++;
                                }
                            else # $name doesn't have parenthesis
                                {
                                push @$errors, NaturalDocs::Menu::Error::New($lineNumber, 'File entry is not in the proper format');
                                };
                            }

                        # There can only be one title and sub-title.
                        elsif ($type == ::MENU_TITLE())
                            {
                            if (!defined $title)
                                {  $title = $name;  }
                            else
                                {  push @$errors, NaturalDocs::Menu::Error::New($lineNumber, 'Title can only be defined once.');  };
                            }
                        elsif ($type == ::MENU_SUBTITLE())
                            {
                            if (defined $title)
                                {
                                if (!defined $subTitle)
                                    {  $subTitle = $name;  }
                                else
                                    {  push @$errors, NaturalDocs::Menu::Error::New($lineNumber, 'SubTitle can only be defined once.');  };
                                }
                            else
                                {  push @$errors, NaturalDocs::Menu::Error::New($lineNumber, 'Title must be defined before SubTitle.');  };
                            }
                        elsif ($type == ::MENU_FOOTER())
                            {
                            if (!defined $footer)
                                {  $footer = $name;  }
                            else
                                {  push @$errors, NaturalDocs::Menu::Error::New($lineNumber, 'Copyright can only be defined once.');  };
                            }

                        elsif ($type == ::MENU_TEXT())
                            {
                            $currentGroup->PushToGroup( NaturalDocs::Menu::Entry::New(::MENU_TEXT(), $name, undef) );
                            }

                        elsif ($type == ::MENU_LINK())
                            {
                            my $target;

                            if ($name =~ /^(.*)\(\s*([^\(\)]+)\s*\)$/)
                                {
                                $name = $1;
                                $target = $2;

                                $name =~ s/[ \t]+$//;
                                }
                            # We need to support # appearing in urls.
                            elsif (scalar @segments >= 2 && $segments[0] eq '#' && $segments[1] =~ /^[^ \t].*\)\s*$/ &&
                                    $name =~ /^.*\(\s*[^\(\)]*[^\(\)\ \t]$/)
                                {
                                $name =~ /^(.*)\(\s*([^\(\)]*[^\(\)\ \t])$/;

                                $name = $1;
                                $target = $2;

                                $name =~ s/[ \t]+$//;

                                $segments[1] =~ /^([^ \t].*)\)\s*$/;

                                $target .= '#' . $1;

                                shift @segments;
                                shift @segments;
                                }
                            else
                                {
                                $target = $name;

                                # Set the name to undef because that means use the URL when creating the menu entry.
                                $name = undef;
                                };

                            $currentGroup->PushToGroup( NaturalDocs::Menu::Entry::New(::MENU_LINK(), $name, $target) );
                            };

                        }

                    # If the keyword doesn't exist...
                    else
                        {
                        push @$errors, NaturalDocs::Menu::Error::New($lineNumber, $1 . ' is not a valid keyword.');
                        };

                    }

                # If the text is not keyword: name or whitespace...
                 elsif (length $segment)
                    {
                    # We check the length because the segment may just have been whitespace between symbols (i.e. "\n  {" or
                    # "} #")  If that's the case, the segment content would have been erased when we clipped the leading and trailing
                    # whitespace from the line.
                    push @$errors, NaturalDocs::Menu::Error::New($lineNumber, 'Every line must start with a keyword.');
                    };

                }; # segment of text
            }; #while segments


        # End a braceless group, if we were in one.
        if ($inBracelessGroup)
            {
            my $isEmpty = $currentGroup->GroupIsEmpty();

            $currentGroup = pop @groupStack;
            $inBracelessGroup = undef;

            # Ignore this group if it was empty.
            if ($isEmpty)
                {  $currentGroup->PopFromGroup();  };
            };

        # Close up all open groups.
        my $openGroups = 0;
        while (scalar @groupStack)
            {
            my $isEmpty = $currentGroup->GroupIsEmpty();

            $currentGroup = pop @groupStack;

            # Ignore this group if it was empty.
            if ($isEmpty)
                {  $currentGroup->DeleteLastGroupItem();  };

            $openGroups++;
            };

        if ($openGroups == 1)
            {  push @$errors, NaturalDocs::Menu::Error::New($lineNumber, 'There is an unclosed group.');  }
        elsif ($openGroups > 1)
            {  push @$errors, NaturalDocs::Menu::Error::New($lineNumber, 'There are ' . $openGroups . ' unclosed groups.');  };
        };


    if (!scalar @$errors)
        {  $errors = undef;  };

    my $trashAlert;
    if ($fileEntries > 5 && !scalar keys %$filesInMenu)
        {  $trashAlert = 1;  };

    return ($hasGroups, $errors, $filesInMenu, $trashAlert);
    };


#
#   Function: AddMissingFiles
#
#   Adds all files with Natural Docs content to the menu that are not already on it.
#
#   Parameters:
#
#       filesInMenu - An existence hashref of all the files present in the menu.
#       hasGroups - Whether the menu uses groups or not.  Determines whether new files will be added to the end or to a group
#                          named Other.
#
sub AddMissingFiles #(filesInMenu, hasGroups)
    {
    my ($filesInMenu, $hasGroups) = @_;


    # Determine where to put the new entries.

    my $newFilesGroup;
    my $createdGroup;

    if ($hasGroups && !$menu->GroupIsEmpty())
        {
        my $menuContent = $menu->GroupContent();

        if ($menuContent->[-1]->Type() == ::MENU_GROUP() && lc( $menuContent->[-1]->Title() ) eq 'other')
            {
            $newFilesGroup = $menuContent->[-1];
            }
        else
            {
            $newFilesGroup = NaturalDocs::Menu::Entry::New(::MENU_GROUP(), 'Other', undef);
            $createdGroup = 1;
            };
        }
    else
        {
        $newFilesGroup = $menu;
        };


    # Add the files.

    my $filesWithContent = NaturalDocs::Project::FilesWithContent();

    foreach my $file (keys %$filesWithContent)
        {
        if (!exists $filesInMenu->{$file})
            {
            $newFilesGroup->PushToGroup( NaturalDocs::Menu::Entry::New(::MENU_FILE(), undef, $file) );
            $hasChanged = 1;
            };
        };


    # Add Other to the menu if necessary.

    if ($createdGroup && !$newFilesGroup->GroupIsEmpty())
        {  $menu->PushToGroup($newFilesGroup);  };
    };


#
#   Function: HandleErrors
#
#   Handles errors appearing in the menu file.
#
#   Parameters:
#
#       errors - An arrayref of the errors as <NaturalDocs::Menu::Error> objects.
#
sub HandleErrors #(errors)
    {
    my $errors = shift;

    my $menuFile = NaturalDocs::Project::MenuFile();
    my $menuFileHandle;
    my $menuFileContent;

    open($menuFileHandle, '<' . $menuFile);
    read($menuFileHandle, $menuFileContent, (stat($menuFile))[7]);
    close($menuFileHandle);

    my @lines = split(/\n/, $menuFileContent);
    $menuFileContent = undef;

    # We need to keep track of both the real and the original line numbers.  The original line numbers are for matching errors in the
    # errors array, and don't include any comment lines added or deleted.  Line number is the current line number including those
    # comment lines for sending to the display.
    my $lineNumber = 1;
    my $originalLineNumber = 1;

    my $error = 0;


    open($menuFileHandle, '>' . $menuFile);

    if ($lines[0] =~ /^\# There (?:is an error|are \d+ errors) in this file\./)
        {
        shift @lines;
        $originalLineNumber++;

        if (!length $lines[0])
            {
            shift @lines;
            $originalLineNumber++;
            };
        };

    if (scalar @$errors == 1)
        {  print $menuFileHandle "# There is an error in this file.  Search for ERROR to find it.\n\n";  }
    else
        {  print $menuFileHandle "# There are " . (scalar @$errors) . " errors in this file.  Search for ERROR to find them.\n\n";  };

    $lineNumber += 2;


    foreach my $line (@lines)
        {
        while ($error < scalar @$errors && $originalLineNumber == $errors->[$error]->Line())
            {
            print $menuFileHandle "# ERROR: " . $errors->[$error]->Description() . "\n";

            # Use the GCC "[file]:[line]: [description]" format, which should make it easier to handle errors when Natural Docs is part
            # of a build process.
            print $menuFile . ':' . $lineNumber . ': ' . $errors->[$error]->Description() . "\n";

            $lineNumber++;
            $error++;
            };

        # We want to remove error lines from previous runs.
        if (substr($line, 0, 9) ne '# ERROR: ')
            {
            print $menuFileHandle $line . "\n";
            $lineNumber++;
            };

        $originalLineNumber++;
        };

    close($menuFileHandle);

    if (scalar @$errors == 1)
        {  die "There is an error in the menu file.\n";  }
    else
        {  die "There are " . (scalar @$errors) . " errors in the menu file.\n";  };
    };


#
#   Function: WriteEntries
#
#   A recursive function to write the contents of an arrayref of <NaturalDocs::Menu::Entry> objects to disk.
#
#   Parameters:
#
#       entries          - The arrayref of menu entries to write.
#       fileHandle      - The handle to the output file.
#       indentChars   - The indentation _characters_ to add before each line.  It is not the number of characters, it is the characters
#                              themselves.  Use undef for none.
#
sub WriteEntries #(entries, fileHandle, indentChars)
    {
    my ($entries, $fileHandle, $indentChars) = @_;

    foreach my $entry (@$entries)
        {
        if ($entry->Type() == ::MENU_FILE())
            {
            print $fileHandle $indentChars . 'File: ' . $entry->Title()
                                  . '  (' . ($entry->SpecifiesTitle() ? '' : 'auto-title, ') . $entry->Target() . ")\n";
            }
        elsif ($entry->Type() == ::MENU_GROUP())
            {
            print $fileHandle "\n" . $indentChars . 'Group: ' . $entry->Title() . "  {\n\n";
            WriteEntries($entry->GroupContent(), $fileHandle, '   ' . $indentChars);
            print $fileHandle '   ' . $indentChars . '}  # Group: ' . $entry->Title() . "\n\n";
            }
        elsif ($entry->Type() == ::MENU_TEXT())
            {
            print $fileHandle $indentChars . 'Text: ' . $entry->Title() . "\n";
            }
        elsif ($entry->Type() == ::MENU_LINK())
            {
            if ($entry->SpecifiesTitle())
                {
                print $fileHandle $indentChars . 'Link: ' . $entry->Title() . '  (' . $entry->Target() . ')' . "\n";
                }
            else
                {
                print $fileHandle $indentChars . 'Link: ' . $entry->Target() . "\n";
                };
             };
        };
    };


1;