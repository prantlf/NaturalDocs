###############################################################################
#
#   Package: NaturalDocs::Settings
#
###############################################################################
#
#   A package to handle the command line and various other program settings.
#
#   Usage and Dependencies:
#
#       - The <Constant Functions> can be called immediately.
#
#       - Prior to initialization, <NaturalDocs::Builder> must have all its output packages registered.
#
#       - To initialize, call <Load()>.  All other functions will then be available.
#
###############################################################################

# This file is part of Natural Docs, which is Copyright © 2003 Greg Valure
# Natural Docs is licensed under the GPL


use NaturalDocs::Settings::BuildTarget;

use strict;
use integer;

package NaturalDocs::Settings;


###############################################################################
# Group: Variables

# handle: SETTINGSFILEHANDLE
# The file handle used with <Settings.txt>.

# var: inputDirectory
# The input directory.
my $inputDirectory;

# var: projectDirectory
# The project directory.
my $projectDirectory;

# array: buildTargets
# An array of <NaturalDocs::Settings::BuildTarget>s.
my @buildTargets;

# int: tabLength
# The number of spaces in tabs.
my $tabLength;

# bool: rebuildData
# Whether the script should rebuild all data files from scratch.
my $rebuildData;

# bool: rebuildOutput
# Whether the script should rebuild all output files from scratch.
my $rebuildOutput;

# bool: isQuiet
# Whether the script should be run in quiet mode or not.
my $isQuiet;

# bool: headersOnly
# Whether only the header files in C/C++ should be used.
my $headersOnly;

# string: defaultStyle
# The style to be used if an output format doesn't have its own style specified.
my $defaultStyle;


###############################################################################
# Group: Files

#
#   File: Settings.txt
#
#   The file that stores the Natural Docs build targets.
#
#   Format:
#
#       The file is plain text.  Blank lines can appear anywhere and are ignored.  Tags and their content must be completely
#       contained on one line.
#
#       > # [comment]
#
#       The file supports single-line comments via #.  They can appear alone on a line or after content.
#
#       > Format: [version]
#       > TabLength: [length]
#       > Style: [style]
#
#       The file format version, tab length, and default style are specified as above.  Each can only be specified once, with
#       subsequent ones being ignored.  Notice that the tags correspond to the long forms of the command line options.
#
#       > Source: [directory]
#       > Input: [directory]
#
#       The input directory is specified as above.  As in the command line, either "Source" or "Input" can be used.
#
#       > [Extension Option]: [opton]
#
#       Options for extensions can be specified as well.  The long form is used as the tag.
#
#       > Option: [HeadersOnly], [Quiet], [Extension Option]
#
#       Options that don't have parameters can be specified in an Option line.  The commas are not required.
#
#       > Output: [name]
#
#       Specifies an output target with a user defined name.  The name is what will be referenced from the command line, and the
#       name "All" is reserved.
#
#       *The options below can only be specified after an output tag.*  Everything that follows an output tag is part of that target's
#       options until the next output tag.
#
#       > Format: [format]
#
#       The output format of the target.
#
#       > Directory: [directory]
#       > Location: [directory]
#       > Folder: [directory]
#
#       The output directory of the target.  All are synonyms.
#
#       > Style: [style]
#
#       The style of the output target.  This overrides the default and is optional.
#


###############################################################################
# Group: Action Functions

#
#   Function: Load
#
#   Loads and parses all settings from the command line and configuration files.  Will exit if the options are invalid or the syntax
#   reference was requested.
#
sub Load
    {
    my ($self) = @_;

    $self->ParseCommandLine();
    };


#
#   Function: Save
#
#   Saves all settings in configuration files to disk.
#
sub Save
    {
    my ($self) = @_;

    $self->SaveSettingsFile();
    };


###############################################################################
# Group: Information Functions


# Function: InputDirectory
# Returns the input directory.
sub InputDirectory
    {  return $inputDirectory;  };

# Function: BuildTargets
# Returns an arrayref of <NaturalDocs::Settings::BuildTarget>s.
sub BuildTargets
    {  return \@buildTargets;  };

#
#   Function: OutputDirectoryOf
#
#   Returns the output directory of a builder object.
#
#   Parameters:
#
#       object - The builder object.
#
#   Returns:
#
#       The builder directory, or undef if the object wasn't found..
#
sub OutputDirectoryOf #(object)
    {
    my ($self, $object) = @_;

    foreach my $buildTarget (@buildTargets)
        {
        if ($buildTarget->Builder() == $object)
            {  return $buildTarget->Directory();  };
        };

    return undef;
    };


#
#   Function: OutputStyleOf
#
#   Returns the style associated with a builder object.
#
#   Parameters:
#
#       object - The builder object.
#
#   Returns:
#
#       The style string, or undef if the object wasn't found.
#
sub OutputStyleOf #(object)
    {
    my ($self, $object) = @_;

    foreach my $buildTarget (@buildTargets)
        {
        if ($buildTarget->Builder() == $object)
            {  return $buildTarget->Style();  };
        };

    return undef;
    };

# Function: ProjectDirectory
# Returns the project directory.
sub ProjectDirectory
    {  return $projectDirectory;  };

# Function: ProjectDataDirectory
# Returns the project data directory.
sub ProjectDataDirectory
    {  return NaturalDocs::File->JoinPath($projectDirectory, 'Data', 1);  };

# Function: StyleDirectory
# Returns the main style directory.
sub StyleDirectory
    {  return NaturalDocs::File->JoinPath($FindBin::RealBin, 'Styles', 1);  };

# Function: TabLength
# Returns the number of spaces tabs should be expanded to.
sub TabLength
    {  return $tabLength;  };

# Function: RebuildData
# Returns whether the script should rebuild all data files from scratch.
sub RebuildData
    {  return $rebuildData;  };

# Function: RebuildOutput
# Returns whether the script should rebuild all output files from scratch.
sub RebuildOutput
    {  return $rebuildOutput;  };

# Function: IsQuiet
# Returns whether the script should be run in quiet mode or not.
sub IsQuiet
    {  return $isQuiet;  };

# Function: HeadersOnly
# Returns whether to only check the header files in C/C++;
sub HeadersOnly
    {  return $headersOnly;  };


###############################################################################
# Group: Constant Functions

#
#   Function: AppVersion
#
#   Returns Natural Docs' version number as an integer.  Use <TextAppVersion()> to get a printable version.
#
sub AppVersion
    {
    my ($self) = @_;
    return NaturalDocs::Version->FromString($self->TextAppVersion());
    };

#
#   Function: TextAppVersion
#
#   Returns Natural Docs' version number as plain text.
#
sub TextAppVersion
    {  return '1.15';  };

#
#   Function: AppURL
#
#   Returns a string of the project's current web address.
#
sub AppURL
    {  return 'http://www.naturaldocs.org';  };


###############################################################################
# Group: Support Functions


#
#   Function: ParseCommandLine
#
#   Parses and validates the command line.  Will cause the script to exit if the options ask for the syntax reference or
#   are invalid.
#
sub ParseCommandLine
    {
    my ($self) = @_;

    # The values are the package names or 'Natural Docs' for the buit in ones.
    my %options = ( '-i' => 'Natural Docs',
                             '-o' => 'Natural Docs',
                             '-p' => 'Natural Docs',
                             '-s' => 'Natural Docs',
                             '-r' => 'Natural Docs',
                             '-ro' => 'Natural Docs',
                             '-t' => 'Natural Docs',
                             '-q' => 'Natural Docs',
                             '-ho' => 'Natural Docs',
                             '-h' => 'Natural Docs',
                             '-?' => 'Natural Docs' );

    my %synonyms = ( '--input'    => '-i',
                                  '--source' => '-i',
                                  '--output'  => '-o',
                                  '--project' => '-p',
                                  '--style'    => '-s',
                                  '--rebuild' => '-r',
                                  '--rebuildoutput' => '-ro',
                                  '--tablength' => '-t',
                                  '--quiet'    => '-q',
                                  '--headersonly' => '-ho',
                                  '--help'     => '-h' );


    # Get all the extension options and check for conflicts.

    my @errorMessages;

    my $allExtensionOptions = NaturalDocs::Extensions->CommandLineOptions();

    if (defined $allExtensionOptions)
        {
        while (my ($extension, $extensionOptions) = each %$allExtensionOptions)
            {
            while (my ($shortOption, $longOption) = each %$extensionOptions)
                {
                my $optionIsBad;

                if (exists $options{$shortOption})
                    {
                    push @errorMessages,
                            $extension . ' defines option ' . $shortOption . ' which is already defined by ' . $options{$shortOption} . '.';
                    $optionIsBad = 1;
                    };

                if (exists $synonyms{$longOption})
                    {
                    push @errorMessages,
                            $extension . ' defines option ' . $longOption . ' which is already defined by '
                            . $options{ $synonyms{$longOption} } . '.';
                    $optionIsBad = 1;
                    };

                if (!defined $optionIsBad)
                    {
                    $options{$shortOption} = $extension;
                    $synonyms{$longOption} = $shortOption;
                    };
                };
            };
        };


    my $valueRef;
    my $option;

    my @outputStrings;
    my %extensionOptions;


    # Sometimes $valueRef is set to $ignored instead of undef because we don't want certain errors to cause other,
    # unnecessary errors.  For example, if they set the input directory twice, we want to show that error and swallow the
    # specified directory without complaint.  Otherwise it would complain about the directory too as if it were random crap
    # inserted into the command line.
    my $ignored;

    my $index = 0;

    while ($index < scalar @ARGV)
        {
        my $arg = $ARGV[$index];

        if (substr($arg, 0, 1) eq '-')
            {
            $option = lc($arg);

            # Support options like -t2 as well as -t 2.
            if ($option =~ /^([^0-9]+)([0-9]+)$/)
                {
                $option = $1;
                splice(@ARGV, $index + 1, 0, $2);
                };

            if (substr($option, 1, 1) eq '-' && exists $synonyms{$option})
                {  $option = $synonyms{$option};  }

            if ($option eq '-i')
                {
                if (defined $inputDirectory)
                    {
                    push @errorMessages, 'You cannot have more than one input directory.';
                    $valueRef = \$ignored;
                    }
                else
                    {  $valueRef = \$inputDirectory;  };
                }
            elsif ($option eq '-p')
                {
                if (defined $projectDirectory)
                    {
                    push @errorMessages, 'You cannot have more than one project directory.';
                    $valueRef = \$ignored;
                    }
                else
                    {  $valueRef = \$projectDirectory;  };
                }
            elsif ($option eq '-o')
                {
                push @outputStrings, undef;
                $valueRef = \$outputStrings[-1];
                }
            elsif ($option eq '-s')
                {
                # We'll allow -s to be specified multiple times and just concatinate it.
                $valueRef = \$defaultStyle;
                }
            elsif ($option eq '-t')
                {
                $valueRef = \$tabLength;
                }
            else
                {
                $valueRef = undef;

                if ($option eq '-r')
                    {
                    $rebuildData = 1;
                    $rebuildOutput = 1;
                    }
                elsif ($option eq '-ro')
                    {  $rebuildOutput = 1;  }
                elsif ($option eq '-q')
                    {  $isQuiet = 1;  }
                elsif ($option eq '-ho')
                    {  $headersOnly = 1;  }
                elsif ($option eq '-?' || $option eq '-h')
                    {
                    $self->PrintSyntax();
                    exit;
                    }
                else
                    {
                    if (exists $options{$option})
                        {
                        $extensionOptions{$option} = undef;
                        $valueRef = \$extensionOptions{$option};
                        }
                    else
                        {  push @errorMessages, 'Unrecognized option ' . $option;  };
                    };

                };

            }

        # Is a segment of text, not an option...
        else
            {
            if (defined $valueRef)
                {
                # We want to preserve spaces in paths.
                if (defined $$valueRef)
                    {  $$valueRef .= ' ';  };

                $$valueRef .= $arg;
                }

            else
                {
                push @errorMessages, 'Unrecognized element ' . $arg;
                };
            };

        $index++;
        };


    # Validate the style, if specified.

    if (defined $defaultStyle)
        {
        if (lc($defaultStyle) ne 'custom')
            {
            my $cssFile = NaturalDocs::File->JoinPath( $self->StyleDirectory(), $defaultStyle . '.css' );
            if (! -e $cssFile)
                {  push @errorMessages, 'The style ' . $defaultStyle . ' does not exist.';  };
            };
        }
    else
        {  $defaultStyle = 'Default';  };


    # Decode and validate the output strings.

    my %outputDirectories;

    foreach my $outputString (@outputStrings)
        {
        my ($format, $directory) = split(/ /, $outputString, 2);

        if (!defined $directory)
            {  push @errorMessages, 'The -o option needs two parameters: -o [format] [directory]';  }
        else
            {
            $directory = NaturalDocs::File->CanonizePath($directory);

            if (! -e $directory || ! -d $directory)
                {
                # They may have forgotten the format portion and the directory name had a space in it.
                if (-e ($format . ' ' . $directory) && -d ($format . ' ' . $directory))
                    {
                    push @errorMessages, 'The -o option needs two parameters: -o [format] [directory]';
                    $format = undef;
                    }
                else
                    {  push @errorMessages, 'The output directory ' . $directory . ' does not exist.';  }
                }
            elsif (exists $outputDirectories{$directory})
                {  push @errorMessages, 'You cannot specify the output directory ' . $directory . ' more than once.';  }
            else
                {  $outputDirectories{$directory} = 1;  };

            if (defined $format)
                {
                my $builderPackage = NaturalDocs::Builder->OutputPackageOf($format);

                if (defined $builderPackage)
                    {
                    push @buildTargets,
                            NaturalDocs::Settings::BuildTarget->New(undef, $builderPackage->New(), $directory, $defaultStyle);
                    }
                else
                    {
                    push @errorMessages, 'The output format ' . $format . ' doesn\'t exist or is not installed.';
                    $valueRef = \$ignored;
                    };
                };
            };
        };

    if (!scalar @buildTargets)
        {  push @errorMessages, 'You did not specify an output directory.';  };


    # Make sure the input and project directories are specified, canonized, and exist.

    if (defined $inputDirectory)
        {
        $inputDirectory = NaturalDocs::File->CanonizePath($inputDirectory);

        if (! -e $inputDirectory || ! -d $inputDirectory)
            {  push @errorMessages, 'The input directory ' . $inputDirectory . ' does not exist.';  };
        }
    else
        {  push @errorMessages, 'You did not specify an input (source) directory.';  };

    if (defined $projectDirectory)
        {
        $projectDirectory = NaturalDocs::File->CanonizePath($projectDirectory);

        if (! -e $projectDirectory || ! -d $projectDirectory)
            {  push @errorMessages, 'The project directory ' . $projectDirectory . ' does not exist.';  };

        # Create the Data subdirectory if it doesn't exist.
        NaturalDocs::File->CreatePath( NaturalDocs::File->JoinPath($projectDirectory, 'Data', 1) );
        }
    else
        {  push @errorMessages, 'You did not specify a project directory.';  };


    # Determine the tab length, and default to four if not specified.

    if (defined $tabLength)
        {
        if ($tabLength !~ /^[0-9]+$/)
            {  push @errorMessages, 'The tab length must be a number.';  };
        }
    else
        {  $tabLength = 4;  };


    # Send the extensions their options.

    if (scalar keys %extensionOptions)
        {
        my $extensionErrors = NaturalDocs::Extensions->ParseCommandLineOptions(\%extensionOptions);

        if (defined $extensionErrors)
            {  push @errorMessages, @$extensionErrors;  };
        };


    # Exit with the error message if there was one.

    if (scalar @errorMessages)
        {
        print join("\n", @errorMessages) . "\nType NaturalDocs -h to see the syntax reference.\n";
        exit;
        };
    };

#
#   Function: PrintSyntax
#
#   Prints the syntax reference.
#
sub PrintSyntax
    {
    my ($self) = @_;

    # Make sure all line lengths are under 80 characters.

    print

    "Natural Docs, version " . $self->TextAppVersion() . "\n"
    . $self->AppURL() . "\n"
    . "This program is licensed under the GPL\n"
    . "--------------------------------------\n"
    . "\n"
    . "Syntax:\n"
    . "\n"
    . "    NaturalDocs -i [input (source) directory]\n"
    . "                 -o [output format] [output directory]\n"
    . "                 (-o [output format] [output directory] ...)\n"
    . "                 -p [project directory]\n"
    . "                 [options]\n"
    . "\n"
    . "Examples:\n"
    . "\n"
    . "    NaturalDocs -i C:\\My Project\\Source -o HTML C:\\My Project\\Docs\n"
    . "                -p C:\\My Project\\Natural Docs\n"
    . "    NaturalDocs -i /src/project -o HTML /doc/project\n"
    . "                -p /etc/naturaldocs/project -s Small -q\n"
    . "\n"
    . "Parameters:\n"
    . "\n"
    . " -i [dir]\n--input [dir]\n--source [dir]\n"
    . "     Specifies the input (source) directory.  Required.\n"
    . "\n"
    . " -o [fmt] [dir]\n--output [fmt] [dir]\n"
    . "    Specifies the output format and directory.  Required.\n"
    . "    Can be specified multiple times, but only once per directory.\n"
    . "    Possible output formats:\n";

    $self->PrintOutputFormats('    - ');

    print
    "\n"
    . " -p [dir]\n--project [dir]\n"
    . "    Specifies the project directory.  Required.\n"
    . "    There needs to be a unique project directory for every source directory.\n"
    . "\n"
    . " -s [style]\n--style [style]\n"
    . "    Specifies the CSS style when building HTML output.  If set to \"Custom\",\n"
    . "    Natural Docs will not sync the output's CSS file with one from its style\n"
    . "    directory.\n"
    . "\n"
    . " -t [len]\n--tablength [len]\n"
    . "    Specifies the number of spaces tabs should be expanded to.  This only needs\n"
    . "    to be set if you use tabs in example code and text diagrams.  Defaults to 4.\n"
    . "\n"
    . " -r\n--rebuild\n"
    . "    Rebuilds all output and data files from scratch.\n"
    . "    Does not affect the menu file.\n"
    . "\n"
    . " -ro\n--rebuildoutput\n"
    . "    Rebuilds all output files from scratch.\n"
    . "\n"
    . " -q\n--quiet\n"
    . "    Suppresses all non-error output.\n"
    . "\n"
    . " -ho\n--headersonly\n"
    . "    For C/C++, only check the headers and not the source files.\n"
    . "\n"
    . " -?\n -h\n--help\n"
    . "    Displays this syntax reference.\n";
    };

#
#   Function: PrintOutputFormats
#
#   Prints all the possible output formats that can be specified with -o.  Each one will be placed on its own line.
#
#   Parameters:
#
#       prefix - Characters to prefix each one with, such as for indentation.
#
sub PrintOutputFormats #(prefix)
    {
    my ($self, $prefix) = @_;

    my $outputPackages = NaturalDocs::Builder::OutputPackages();

    foreach my $outputPackage (@$outputPackages)
        {
        print $prefix . $outputPackage->CommandLineOption() . "\n";
        };
    };


#
#   Function: LoadSettingsFile
#
#   Loads and parses <Settings.txt>.
#
#   Returns:
#
#       An arrayref of <NaturalDocs::Settings::BuildTarget>s.  If there's nothing in the file, it returns an empty arrayref.
#
sub LoadSettingsFile
    {
    my ($self) = @_;

    my $errors = [ ];
    my $buildTargets = [ ];
    my $lineNumber = 1;

    if (open(SETTINGSFILEHANDLE, '<' . NaturalDocs::Project->SettingsFile()))
        {
        my $settingsFileContent;
        read(SETTINGSFILEHANDLE, $settingsFileContent, -s SETTINGSFILEHANDLE);
        close(SETTINGSFILEHANDLE);

        # We don't check if the settings file is from a future version because we can't just throw it out and regenerate it like we can
        # with other data files.  So we just keep going regardless.  Any syntactic differences will show up as errors.

        $settingsFileContent =~ /^[ \t]*format:[ \t]+([0-9\.]+)/mi;
        my $version = $1;

        # Strip tabs.
        $settingsFileContent =~ tr/\t/ /;

        my @lines = split(/\n/, $settingsFileContent);
        my $segment;

        foreach my $line (@lines)
            {
            # Strip off comments and edge spaces.
            $line =~ s/#.*$//;
            $line =~ s/^ +//;
            $line =~ s/ +$//;

            # Ignore lines with no content.
            if (!length $line)
                {  next;  };

            # If the line is keyword: name...
             if ($line =~ /^([^:]+): +([^ ].*)$/)
                {
                my $keyword = lc($1);
                my $name = $2;

#                    if (exists $menuSynonyms{$type})
#                        {
#                        $type = $menuSynonyms{$type};

#                        # Currently index is the only type allowed modifiers.
#                        if (defined $modifier && $type != ::MENU_INDEX())
#                            {
#                            push @$errors, NaturalDocs::Menu::Error->New($lineNumber,
#                                                                                                 $modifier . ' ' . $menuSynonyms{$type}
#                                                                                                 . ' is not a valid keyword.');
#                            next;
#                            };

#                        if ($type == ::MENU_GROUP())
#                            {
#                            # End a braceless group, if we were in one.
#                            if ($inBracelessGroup)
#                                {
#                                $currentGroup = pop @groupStack;
#                                $inBracelessGroup = undef;
#                                };

#                            my $entry = NaturalDocs::Menu::Entry->New(::MENU_GROUP(), $name, undef, undef);

#                            $currentGroup->PushToGroup($entry);

#                            push @groupStack, $currentGroup;
#                            $currentGroup = $entry;

#                            $afterGroupToken = 1;
#                            }

#                        elsif ($type == ::MENU_FILE())
#                            {
#                            my $flags = 0;

#                            no integer;

#                            if ($version >= 1.0)
#                                {
#                                if (lc($extras[0]) eq 'no auto-title')
#                                    {
#                                    $flags |= ::MENU_FILE_NOAUTOTITLE();
#                                    shift @extras;
#                                    }
#                                elsif (lc($extras[0]) eq 'auto-title')
#                                    {
#                                    # It's already the default, but we want to accept the keyword anyway.
#                                    shift @extras;
#                                    };
#                                }
#                            else
#                                {
#                                # Prior to 1.0, the only extra was "auto-title" and the default was off instead of on.
#                                if (lc($extras[0]) eq 'auto-title')
#                                    {  shift @extras;  }
#                                else
#                                    {
#                                    # We deliberately leave it auto-titled, but save the original title.
#                                    $oldLockedTitles->{$extras[0]} = $name;
#                                    };
#                                };

#                            use integer;

#                            if (!scalar @extras)
#                                {
#                                push @$errors, NaturalDocs::Menu::Error->New($lineNumber,
#                                                                                                     'File entries need to be in format '
#                                                                                                     . '"File: [title] ([location])"');
#                                next;
#                                };

#                            my $entry = NaturalDocs::Menu::Entry->New(::MENU_FILE(), $name, $extras[0], $flags);

#                            $currentGroup->PushToGroup($entry);

#                            $filesInMenu->{$extras[0]} = $entry;
#                            }

#                        # There can only be one title, subtitle, and footer.
#                        elsif ($type == ::MENU_TITLE())
#                            {
#                            if (!defined $title)
#                                {  $title = $name;  }
#                            else
#                                {  push @$errors, NaturalDocs::Menu::Error->New($lineNumber, 'Title can only be defined once.');  };
#                            }
#                        elsif ($type == ::MENU_SUBTITLE())
#                            {
#                            if (defined $title)
#                                {
#                                if (!defined $subTitle)
#                                    {  $subTitle = $name;  }
#                                else
#                                    {  push @$errors, NaturalDocs::Menu::Error->New($lineNumber, 'SubTitle can only be defined once.');  };
#                                }
#                            else
#                                {  push @$errors, NaturalDocs::Menu::Error->New($lineNumber, 'Title must be defined before SubTitle.');  };
#                            }
#                        elsif ($type == ::MENU_FOOTER())
#                            {
#                            if (!defined $footer)
#                                {  $footer = $name;  }
#                            else
#                                {  push @$errors, NaturalDocs::Menu::Error->New($lineNumber, 'Copyright can only be defined once.');  };
#                            }

#                        elsif ($type == ::MENU_TEXT())
#                            {
#                            $currentGroup->PushToGroup( NaturalDocs::Menu::Entry->New(::MENU_TEXT(), $name, undef, undef) );
#                            }

#                        elsif ($type == ::MENU_LINK())
#                            {
#                            my $target;

#                            if (scalar @extras)
#                                {
#                                $target = $extras[0];
#                                }

#                            # We need to support # appearing in urls.
#                            elsif (scalar @segments >= 2 && $segments[0] eq '#' && $segments[1] =~ /^[^ ].*\) *$/ &&
#                                    $name =~ /^.*\( *[^\(\)]*[^\(\)\ ]$/)
#                                {
#                                $name =~ /^(.*)\(\s*([^\(\)]*[^\(\)\ ])$/;

#                                $name = $1;
#                                $target = $2;

#                                $name =~ s/ +$//;

#                                $segments[1] =~ /^([^ ].*)\) *$/;

#                                $target .= '#' . $1;

#                                shift @segments;
#                                shift @segments;
#                                }

#                            else
#                                {
#                                $target = $name;
#                                };

#                            $currentGroup->PushToGroup( NaturalDocs::Menu::Entry->New(::MENU_LINK(), $name, $target, undef) );
#                            }

#                        elsif ($type == ::MENU_INDEX())
#                            {
#                            if (!defined $modifier || $modifier eq 'general')
#                                {
#                                my $entry = NaturalDocs::Menu::Entry->New(::MENU_INDEX(), $name, undef, undef);
#                                $currentGroup->PushToGroup($entry);

#                                $indexes{'*'} = 1;
#                                }
#                            elsif ($modifier eq 'don\'t')
#                                {
#                                # We'll tolerate splits by spaces as well as commas.
#                                my @splitLine = split(/ +|, */, lc($name));

#                                foreach my $bannedIndex (@splitLine)
#                                    {
#                                    if ($bannedIndex eq 'general')
#                                        {  $bannedIndex = '*';  }
#                                    else
#                                        {  $bannedIndex = NaturalDocs::Topics->NonListConstantOf($bannedIndex);  };

#                                    if (defined $bannedIndex)
#                                        {  $bannedIndexes{$bannedIndex} = 1;  };
#                                    };
#                                }
#                            else
#                                {
#                                my $modifierType = NaturalDocs::Topics->NonListConstantOf($modifier);

#                                if (defined $modifierType && NaturalDocs::Topics->IsIndexable($modifierType))
#                                    {
#                                    $indexes{$modifierType} = 1;
#                                    $currentGroup->PushToGroup(
#                                        NaturalDocs::Menu::Entry->New(::MENU_INDEX(), $name, $modifierType, undef) );
#                                    }
#                                else
#                                    {
#                                    push @$errors, NaturalDocs::Menu::Error->New($lineNumber, $modifier . ' is not a valid index type.');
#                                    };
#                                };
#                            }

#                        # There's also MENU_FORMAT, but that was already dealt with.  We don't need to parse it, just make sure it
#                        # doesn't cause an error.

#                        }

#                    # If the keyword doesn't exist...
#                    else
#                        {
#                        push @$errors, NaturalDocs::Menu::Error->New($lineNumber, $1 . ' is not a valid keyword.');
#                        };

                 }

            # If the text is not keyword: name or whitespace...
            else
                {
                push @$errors, NaturalDocs::Menu::Error->New($lineNumber, 'Every line must start with a keyword.');
                };


            $lineNumber++;
            }; # foreach line



#        # End a braceless group, if we were in one.
#        if ($inBracelessGroup)
#            {
#            $currentGroup = pop @groupStack;
#            $inBracelessGroup = undef;
#            };

#        # Close up all open groups.
#        my $openGroups = 0;
#        while (scalar @groupStack)
#            {
#            $currentGroup = pop @groupStack;
#            $openGroups++;
#            };

#        if ($openGroups == 1)
#            {  push @$errors, NaturalDocs::Menu::Error->New($lineNumber, 'There is an unclosed group.');  }
#        elsif ($openGroups > 1)
#            {  push @$errors, NaturalDocs::Menu::Error->New($lineNumber, 'There are ' . $openGroups . ' unclosed groups.');  };


#        no integer;

#        if ($version < 1.0)
#            {
#            # Prior to 1.0, there was no auto-placement.  New entries were either tacked onto the end of the menu, or if there were
#            # groups, added to a top-level group named "Other".  Since we have auto-placement now, delete "Other" so that its
#            # contents get placed.

#            my $index = scalar @{$menu->GroupContent()} - 1;
#            while ($index >= 0)
#                {
#                if ($menu->GroupContent()->[$index]->Type() == ::MENU_GROUP() &&
#                    lc($menu->GroupContent()->[$index]->Title()) eq 'other')
#                    {
#                    splice( @{$menu->GroupContent()}, $index, 1 );
#                    last;
#                    };

#                $index--;
#                };

#            # Also, prior to 1.0 there was no auto-grouping and crappy auto-titling.  We want to apply these the first time a post-1.0
#            # release is run.

#            my @groupStack = ( $menu );
#            while (scalar @groupStack)
#                {
#                my $groupEntry = pop @groupStack;

#                $groupEntry->SetFlags( $groupEntry->Flags() | ::MENU_GROUP_UPDATETITLES() | ::MENU_GROUP_UPDATEORDER() |
#                                                   ::MENU_GROUP_UPDATESTRUCTURE() );

#                foreach my $entry (@{$groupEntry->GroupContent()})
#                    {
#                    if ($entry->Type() == ::MENU_GROUP())
#                        {  push @groupStack, $entry;  };
#                    };
#                };
#            };

#        use integer;
     };


#    if (!scalar @$errors)
#        {  $errors = undef;  };
#    if (!scalar keys %$oldLockedTitles)
#        {  $oldLockedTitles = undef;  };

#    return ($errors, $filesInMenu, $oldLockedTitles);
    };


#
#   Function: SaveSettingsFile
#
#   Saves <Settings.txt> to disk.
#
sub SaveSettingsFile
    {
    my ($self) = @_;

    open(SETTINGSFILEHANDLE, '>' . NaturalDocs::Project->SettingsFile())
        or die 'Could not save settings file ' . NaturalDocs::Project->SettingsFile();

    # Remember to keep lines under 80 characters.
    print SETTINGSFILEHANDLE

    "# Do not change or remove this line.\n"
    . 'Format: ' . $self->TextAppVersion() . "\n"
    . "\n"
    . "# ----------------------------------------------------------------------- #\n"
    . "\n"

    . 'Source: ' . $self->InputDirectory() . "\n"
    . "\n"

    . 'Style: ' . $defaultStyle . "\n"
    . 'TabLength: ' . $tabLength . "\n"
    . "\n"
    . "# ----------------------------------------------------------------------- #\n"
    . "\n";

    for (my $i = 0; $i < scalar @buildTargets; $i++)
        {
        print SETTINGSFILEHANDLE

        'Output: ' . ($i + 1) . "\n"
        . "\n"

        . '   Format: ' . $buildTargets[$i]->Builder()->CommandLineOption() . "\n"
        . '   Directory: ' . $buildTargets[$i]->Directory() . "\n";

        if ($buildTargets[$i]->Style() ne $defaultStyle)
            {
            print SETTINGSFILEHANDLE
            "\n"
            . '   Style: ' . $buildTargets[$i]->Style();
            };

        print SETTINGSFILEHANDLE "\n\n";
        };

    close(SETTINGSFILEHANDLE);
    };


1;
