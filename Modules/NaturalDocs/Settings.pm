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

# hash: outputFormats
# A hash of the output formats and directories being used.  The keys are the package names, and the values are their
# corresponding directories.
my %outputFormats;

# bool: rebuildData
# Whether the script should rebuild all data files from scratch.
my $rebuildData;

# bool: rebuildOutput
# Whether the script should rebuild all output files from scratch.
my $rebuildOutput;

# bool: isQuiet
# Whether the script should be run in quiet mode or not.
my $isQuiet;

# string: defaultOutputStyle
# The style to be used if an output format doesn't have its own style specified.
my $defaultOutputStyle;

# hash: outputStyles
# A hash of the output format styles.  The keys are the package names, and the values are the style strings.  If a package does
# not have an entry in this hash, it uses <defaultOutputStyle>.
my %outputStyles;

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
    my %synonyms = ( '--input'    => '-i',
                                  '--source' => '-i',
                                  '--output'  => '-o',
                                  '--project' => '-p',
                                  '--style'    => '-s',
                                  '--rebuild' => '-r',
                                  '--rebuildoutput' => '-ro',
                                  '--quiet'    => '-q',
                                  '--help'     => '-h' );

    my %outputOptions;
    my $outputPackages = NaturalDocs::Builder::OutputPackages();

    foreach my $outputPackage (@$outputPackages)
        {
        $outputOptions{ lc($outputPackage->CommandLineOption()) } = $outputPackage;
        };


    my @errorMessages;
    my $valueRef;
    my $option;

    my $styleString;

    # Sometimes $valueRef is set to $ignored instead of undef because we don't want certain errors to cause other,
    # unnecessary errors.  For example, if they set the input directory twice, we want to show that error and swallow the
    # specified directory without complaint.  Otherwise it would complain about the directory too as if it were random crap
    # inserted into the command line.
    my $ignored;

    foreach my $arg (@ARGV)
        {
        if (substr($arg, 0, 1) eq '-')
            {
            $option = lc($arg);
            if (substr($option, 1, 1) eq '-')
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
            elsif ($option eq '-s')
                {
                # We'll allow -s to be specified multiple times and just concatinate it.

                if (defined $styleString)
                    {  $styleString .= ' ';  };

                $valueRef = \$styleString;
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
                elsif ($option eq '-h')
                    {
                    PrintSyntax();
                    exit;
                    }
                elsif ($option ne '-o')
                    {
                    push @errorMessages, 'Unrecognized option ' . $option;
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

            elsif ($option eq '-o')
                {
                my $format = $outputOptions{lc($arg)};

                if (!defined $format)
                    {
                    push @errorMessages, 'The output format ' . $format . ' doesn\'t exist or is not installed.';
                    $valueRef = \$ignored;
                    }
                elsif (exists $outputFormats{$format})
                    {
                    push @errorMessages, 'You can only have one output directory for each output format.';
                    $valueRef = \$ignored;
                    }
                else
                    {
                    $outputFormats{$format} = undef;
                    $valueRef = \$outputFormats{$format};
                    };
                }

            else
                {
                push @errorMessages, 'Unrecognized element ' . $arg;
                };
            };
        };


    # Make sure all the required directories are specified, canonized, and exist.

    if (defined $inputDirectory)
        {
        $inputDirectory = NaturalDocs::File::CanonizePath($inputDirectory);

        if (! -e $inputDirectory || ! -d $inputDirectory)
            {  push @errorMessages, 'The input directory ' . $inputDirectory . ' does not exist.';  };
        }
    else
        {  push @errorMessages, 'You did not specify an input (source) directory.';  };

    if (defined $projectDirectory)
        {
        $projectDirectory = NaturalDocs::File::CanonizePath($projectDirectory);

        if (! -e $projectDirectory || ! -d $projectDirectory)
            {  push @errorMessages, 'The project directory ' . $projectDirectory . ' does not exist.';  };
        }
    else
        {  push @errorMessages, 'You did not specify a project directory.';  };

    if (scalar keys %outputFormats)
        {
        while (my ($format, $dir) = each %outputFormats)
            {
            $outputFormats{$format} = NaturalDocs::File::CanonizePath($dir);

            if (! -e $dir || ! -d $dir)
                {  push @errorMessages, 'The output directory ' . $dir . ' does not exist.';  };
            };
        }
    else
        {  push @errorMessages, 'You did not specify an output directory.';  };


    # Decode the style string.  Apparently @ARGV splits not only on spaces, but also on = automatically.  Of course this was plainly
    # documentented and would never cause any problems.

    my @styles = split(/ +/, $styleString);

    if (scalar @styles == 1)
        {  $defaultOutputStyle = $styles[0];  }
    else
        {
        $defaultOutputStyle = 'Default';

        while (scalar @styles)
            {
            my $outputFormat = shift @styles;
            my $outputStyle = shift @styles;

            my $outputPackage = $outputOptions{ lc($outputFormat) };

            # We don't care if the output format is actually being used, just that it exists.
            if (defined $outputPackage)
                {  $outputStyles{$outputPackage} = $outputStyle;  }

            # We only add an error message if the format wasn't already specified as an output format to avoid duplicating it.
            elsif (!defined $outputFormats{$outputFormat})
                {  push @errorMessages, 'The output format ' . $outputFormat . ' doesn\'t exist or is not installed.';  };
            };
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
    # Make sure all line lengths are under 80 characters.

    my $output =

    "Natural Docs, version " . TextAppVersion() . "\n"
    . AppURL() . "\n"
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
    . "-i, --input, --source\n"
    . "     Specifies the input (source) directory.  Required.\n"
    . "\n"
    . "-o, --output\n"
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
    . "-p, --project\n"
    . "     Specifies the project directory.  Required.\n"
    . "     There needs to be a unique project directory for every source directory.\n"
    . "\n"
    . "-s, --style\n"
    . "     Specifies the CSS style when building HTML output.  Can be a single style\n"
    . "     (\"Small\") for all output or a series of [format]=[style] entries\n"
    . "     (\"HTML=Small\") separated by spaces to distinguish between them.  If set\n"
    . "     to \"Custom\", Natural Docs will not sync the output's CSS file with one\n"
    . "     from its style directory.\n"
    . "\n"
    . "-r, --rebuild\n"
    . "     Rebuilds all output and data files from scratch.\n"
    . "     Does not affect the menu file.\n"
    . "\n"
    . "-ro, --rebuildoutput\n"
    . "     Rebuilds all output files from scratch.\n"
    . "\n"
    . "-q, --quiet\n"
    . "     Suppresses all non-error output.\n"
    . "\n"
    . "-h, --help\n"
    . "     Displays this syntax reference.\n";

    print $output;
    };


# Function: InputDirectory
# Returns the input directory.
sub InputDirectory
    {  return $inputDirectory;  };

#
#   Function: OutputDirectory
#
#   Returns the output directory of an output format.
#
#   Parameters:
#
#       package - The output package.
#
#   Returns:
#
#       The output format directory, or undef if the format wasn't specified.
#
sub OutputDirectory #(package)
    {  return $outputFormats{$_[0]};  };

# Function: OutputFormats
# Returns a hashref of the output formats and their directories.  The keys are the package names, and the values are their
# directories.  The hashref is not a copy of the data, so don't change it.
sub OutputFormats
    {  return \%outputFormats;  };

#
#   Function: OutputStyle
#
#   Returns the style associated with an output format.
#
#   Parameters:
#
#       package - The output package.
#
#   Returns:
#
#       The style string.
#
sub OutputStyle #(package)
    {
    my $package = shift;

    if (exists $outputStyles{$package})
        {  return $outputStyles{$package};  }
    else
        {  return $defaultOutputStyle;  };
    };

# Function: ProjectDirectory
# Returns the project directory.
sub ProjectDirectory
    {  return $projectDirectory;  };

# Function: StyleDirectory
# Returns the main style directory.
sub StyleDirectory
    {  return NaturalDocs::File::JoinPath($FindBin::Bin, 'Styles', 1);  };

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


###############################################################################
# Group: Constant Functions

#
#   Function: AppVersion
#
#   Returns Natural Docs' version number as an integer.  Use <TextAppVersion()> to get a printable version.
#
sub AppVersion
    {  return NaturalDocs::Version::FromString(TextAppVersion());  };

#
#   Function: TextAppVersion
#
#   Returns Natural Docs' version number as plain text.
#
sub TextAppVersion
    {  return '1.1';  };

#
#   Function: AppURL
#
#   Returns a string of the project's current web address.
#
sub AppURL
    {  return 'http://www.naturaldocs.org';  };


1;