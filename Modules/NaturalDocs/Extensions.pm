###############################################################################
#
#   Package: NaturalDocs::Extensions
#
###############################################################################
#
#   A package to manage all the extensions to Natural Docs.
#
###############################################################################

# This file is part of Natural Docs, which is Copyright © 2003-2004 Greg Valure
# Natural Docs is licensed under the GPL

use strict;
use integer;

package NaturalDocs::Extensions;


###############################################################################
# Group: Variables

#
#   array: extensions
#
#   An array of all the extension packages.
#
my @extensions;

#
#   hash: requireErrors
#
#   A hash of all the errors from each package's <Requires()> requirements.  The keys are the package names, and the values are
#   the error message.  If there were no errors for a package, it will not have an entry here.
#
my %requireErrors;


###############################################################################
# Group: Functions


#
#   Function: Requires
#
#   Adds external packages similar to if you used the line 'require [package]'.  This is similar to 'use [package]' except that
#   nothing is exported, meaning you always have to use 'package::function()' instead of just 'function()'.  We don't want an
#   extension to potentially cause a naming conflict with Natural Docs' functions, either now or in a future version.
#
#   All extension packages *must* call this function from BEGIN if they need to use external packages other than what is included
#   in all Perl distributions by default.  You can find a list of them at <http://www.perldoc.com/perl5.005_03/lib.html>.
#
#   Using this function instead of a direct 'use [package]' lets Natural Docs degrade gracefully if those packages aren't there.  If
#   you just used 'use [package]' instead, Natural Docs would always quit with an error if that package wasn't there, whether the
#   user was trying to use your extension or not.  Using this function instead only gives that error message if the packages aren't
#   installed and the user tried to use your extension anyway.
#
#   Parameters:
#
#       extension  - The extension package.
#       requirement  - The required external package.  Specify as many times as you like.
#
#   Example:
#
#   > NaturalDocs::Extensions->Requires(__PACKAGE__, 'String::CRC32', 'Crypt::Blowfish');
#
sub Requires #(extension, requirement, requirement, requirement ...)
    {
    my ($self, $extension, @requirements) = @_;

    foreach my $requirement (@requirements)
        {
        eval 'require ' . $requirement;
        if ($@)
            {
            $requireErrors{$extension} = $@;
            last;
            };
        };
    };


#
#   Function: Add
#
#   Adds an extension package to Natural Docs.  All extension packages *must* call this function from INIT to be recognized.
#
#   Parameters:
#
#       package  - The package name.
#
sub Add #(package)
    {
    my ($self, $package) = @_;

    push @extensions, $package;
    };


#
#   Function: CommandLineOptions
#
#   Returns a hashref of the command line options by extension package.  The keys are the package names, and the values are
#   hashrefs where the keys are the all-lowercase short options ('-i') and the values are the all-lowercase long options ('--input').
#   If there are no command line options for a particular extension, it will not be included in the hashref.  If there are no command
#   line options for any extensions, it will return undef.
#
sub CommandLineOptions
    {
    my ($self) = @_;

    my $allOptions = { };

    foreach my $extension (@extensions)
        {
        my $extensionOptions = $extension->CommandLineOptions();

        if (defined $extensionOptions)
            {  $allOptions->{$extension} = $extensionOptions;  };
        };

    if (scalar keys %$allOptions)
        {  return $allOptions;  }
    else
        {  return undef;  };
    };


#
#   Function: ParseCommandLineOptions
#
#   Sends the command line options to their extensions.
#
#   Parameters:
#
#       options - A hashref of the command line options and their values.  The keys are the all-lowercase short options ('-i') and
#                     the values are their parameters, or undef if none.
#
#   Returns:
#
#       An arrayref of error messages, or undef if none.
#
sub ParseCommandLineOptions #(options)
    {
    my ($self, $options) = @_;

    my $errors = [ ];

    foreach my $extension (@extensions)
        {
        # If there are errors in an extension, we have to stop if the user tries to use it.
        if (exists $requireErrors{$extension})
            {
            my $extensionOptions = $extension->CommandLineOptions();

            foreach my $extensionOption (keys %$extensionOptions)
                {
                if (exists $options->{$extensionOption})
                    {
                    die 'You cannot use the ' . $extensionOption . " option for the following reason:\n"
                        . $requireErrors{$extension} . "\nThe " . $extensionOption . " option is part of " . $extension . ".\n";
                    last;
                    };
                };
            }

        else
            {
            # Since the default is to do nothing, it's safe to send the options to extensions that don't define any.  Also, it's noted in the
            # documentation for NaturalDocs::Extensions::Base that ParseCommandLineOptions() may have options from other
            # extensions in there, so that won't cause a problem either.
            my $extensionErrors = $extension->ParseCommandLineOptions($options);

            if (defined $extensionErrors)
                {  push @$errors, @$extensionErrors;  };
            };
        };

    if (scalar @$errors)
        {  return $errors;  }
    else
        {  return undef;  };
    };



###############################################################################
# Group: Hook Targets
# These functions call the equivalent functions of each extension.


#
#   Function: AfterFileParsed
#
#   Called after a file has been parsed, but before it is scanned for symbols or turned into output.  Only call this function if the
#   file has Natural Docs content.
#
#   Parameters:
#
#       file - The source file.
#       parsedFile - The arrayref of <NaturalDocs::Parser::ParsedTopic> objects.
#
sub AfterFileParsed #(file, parsedFile)
    {
    my ($self, $file, $parsedFile) = @_;

    foreach my $extension (@extensions)
        {
        if (!exists $requireErrors{$extension})
            {  $extension->AfterFileParsed($file, $parsedFile);  };
        };
    };


1;
