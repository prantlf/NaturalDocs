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
#       - To initialize, call <ParseCommandLine()>.  All other functions will then be available.
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

# var: inputDirectory
# The input directory.
my $inputDirectory;

# var: projectDirectory
# The project directory.
my $projectDirectory;

# array: buildTargets
# An array of <NaturalDocs::Settings::BuildTargets>.
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
# Group: Functions

#
#   Function: ParseCommandLine
#
#   Parses and validates the command line.  Will cause the script to exit if the options ask for the syntax reference or
#   are invalid.  Needs to be run before calling any other functions in this package.
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
        my $builderPackage = NaturalDocs::Builder->OutputPackageOf($format);

        if (!defined $builderPackage)
            {
            push @errorMessages, 'The output format ' . $format . ' doesn\'t exist or is not installed.';
            $valueRef = \$ignored;
            };

        $directory = NaturalDocs::File->CanonizePath($directory);

        if (! -e $directory || ! -d $directory)
            {  push @errorMessages, 'The output directory ' . $directory . ' does not exist.';  };

        if (exists $outputDirectories{$directory})
            {  push @errorMessages, 'You cannot specify the output directory ' . $directory . ' more than once.';  };

        push @buildTargets, NaturalDocs::Settings::BuildTarget->New(undef, $builderPackage->New(), $directory, $defaultStyle);
        $outputDirectories{$directory} = 1;
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

    my $output =

    "Natural Docs, version " . $self->TextAppVersion() . "\n"
    . $self->AppURL() . "\n"
    . "This program is licensed under the GPL\n"
    . "--------------------------------------\n"
    . "\n"
    . "Syntax:\n"
    . "\n"
    . "     NaturalDocs -i [input (source) directory]\n"
    . "                  -o [output format] [output directory]\n"
    . "                  (-o [output format] [output directory] ...)\n"
    . "                  -p [project directory]\n"
    . "                  [options]\n"
    . "\n"
    . "Examples:\n"
    . "\n"
    . "     NaturalDocs -i C:\\My Project\\Source -o HTML C:\\My Project\\Docs\n"
    . "                 -p C:\\My Project\\Natural Docs\n"
    . "     NaturalDocs -i /src/project -o HTML /doc/project\n"
    . "                 -p /etc/naturaldocs/project -s Small -q\n"
    . "\n"
    . "Parameters:\n"
    . "\n"
    . " -i [dir]\n--input [dir]\n--source [dir]\n"
    . "     Specifies the input (source) directory.  Required.\n"
    . "\n"
    . " -o [fmt] [dir]\n--output [fmt] [dir]\n"
    . "     Specifies the output format and directory.  Required.\n"
    . "     Can be specified multiple times, but only once per output format.\n"
    . "     Possible output formats:\n";

    my $outputPackages = NaturalDocs::Builder::OutputPackages();

    foreach my $outputPackage (@$outputPackages)
        {
        $output .= "          " . $outputPackage->CommandLineOption() . "\n";
        };

    $output .=
    "\n"
    . " -p [dir]\n--project [dir]\n"
    . "     Specifies the project directory.  Required.\n"
    . "     There needs to be a unique project directory for every source directory.\n"
    . "\n"
    . " -s [style]\n--style [style]\n"
    . "     Specifies the CSS style when building HTML output.  Can be a single style\n"
    . "     (\"Small\") for all output or a series of [format]=[style] entries\n"
    . "     (\"HTML=Small\") separated by spaces to distinguish between them.  If set\n"
    . "     to \"Custom\", Natural Docs will not sync the output's CSS file with one\n"
    . "     from its style directory.\n"
    . "\n"
    . " -t [len]\n--tablength [len]\n"
    . "   Specifies the number of spaces tabs should be expanded to.  This only needs\n"
    . "   to be set if you use tabs in example code and text diagrams.  Defaults to 4.\n"
    . "\n"
    . " -r\n--rebuild\n"
    . "     Rebuilds all output and data files from scratch.\n"
    . "     Does not affect the menu file.\n"
    . "\n"
    . " -ro\n--rebuildoutput\n"
    . "     Rebuilds all output files from scratch.\n"
    . "\n"
    . " -q\n--quiet\n"
    . "     Suppresses all non-error output.\n"
    . "\n"
    . " -ho\n--headersonly\n"
    . "     For C/C++, only check the headers and not the source files.\n"
    . "\n"
    . " -?\n -h\n--help\n"
    . "     Displays this syntax reference.\n";

    print $output;
    };


# Function: InputDirectory
# Returns the input directory.
sub InputDirectory
    {  return $inputDirectory;  };

# Function: BuildTargets
# Returns an arrayref of <NaturalDocs::Settings::BuildTargets>.
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

# Function: StyleDirectory
# Returns the main style directory.
sub StyleDirectory
    {  return NaturalDocs::File->JoinPath($FindBin::Bin, 'Styles', 1);  };

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
    {  return '1.13';  };

#
#   Function: AppURL
#
#   Returns a string of the project's current web address.
#
sub AppURL
    {  return 'http://www.naturaldocs.org';  };


1;
