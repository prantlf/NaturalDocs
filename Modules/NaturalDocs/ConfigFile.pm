###############################################################################
#
#   Package: NaturalDocs::ConfigFile
#
###############################################################################
#
#   A package to manage some of the shared functionality needed for Natural Docs' configuration files.
#
#   Usage:
#
#       - <StartingParseOf()> must be called for each configuration file before using any other functions with that file.
#
###############################################################################

# This file is part of Natural Docs, which is Copyright © 2003-2004 Greg Valure
# Natural Docs is licensed under the GPL

use strict;
use integer;

package NaturalDocs::ConfigFile;


###############################################################################
# Group: Variables

#
#   handle: CONFIG_FILEHANDLE
#
#   The file handle used when annotating the configuration file with error comments.
#

#
#   string: file
#
#   The current configuration file being parsed.
#
my $file;

#
#   array: errors
#
#   An array of errors added by <AddError()>.  Every odd entry is the line number, and every even entry following is the
#   error message.
#
my @errors;


###############################################################################
# Group: Functions


#
#   Function: StartingParseOf
#
#   Notifies the package that a new configuration file is about to be parsed.  You *must* call this function for each configuration
#   file before using any other package functions with it.
#
#   Parameters:
#
#       file - The file about to be parsed.
#
sub StartingParseOf #(file)
    {
    my ($self, $passedFile) = @_;
    $file = $passedFile;
    @errors = ( );
    };


#
#   Function: Obscure
#
#   Obscures the passed text so that it is not user editable and returns it.  The encoding method is not secure; it is just designed
#   to be fast and to discourage user editing.
#
sub Obscure #(text)
    {
    my ($self, $text) = @_;

    # ` is specifically chosen to encode to space because of its rarity.  We don't want a trailing one to get cut off before decoding.
    $text =~ tr{a-zA-Z0-9\ \\\/\.\:\_\-\`}
                    {pY9fGc\`R8lAoE\\uIdH6tN\/7sQjKx0B5mW\.vZ41PyFg\:CrLaO\_eUi2DhT\-nSqJkXb3MwVz\ };

    return $text;
    };


#
#   Function: Unobscure
#
#   Restores text encoded with <Obscure()> and returns it.
#
sub Unobscure #(text)
    {
    my ($self, $text) = @_;

    $text =~ tr{pY9fGc\`R8lAoE\\uIdH6tN\/7sQjKx0B5mW\.vZ41PyFg\:CrLaO\_eUi2DhT\-nSqJkXb3MwVz\ }
                    {a-zA-Z0-9\ \\\/\.\:\_\-\`};

    return $text;
    };

###############################################################################
# Group: Error Functions


#
#   Function: AddError
#
#   Stores an error for the current configuration file.
#
#   Parameters:
#
#       lineNumber - The line number, with the first line being one, not zero.
#       message - The error message.
#
sub AddError #(lineNumber, message)
    {
    my ($self, $lineNumber, $message) = @_;
    push @errors, $lineNumber, $message;
    };


#
#   Function: ErrorCount
#
#   Returns how many errors the configuration file has.
#
sub ErrorCount
    {
    return (scalar @errors) / 2;
    };


#
#   Function: HandleErrors
#
#   Handles any errors that we're found in the configuration file, which currently means printing them out in the GNU error format
#   and annotating the configuration file with error comments.  It does *not* end execution.
#
sub HandleErrors
    {
    my ($self) = @_;

    if (scalar @errors)
        {
        open(CONFIG_FILEHANDLE, '<' . $file);
        my @lines = <CONFIG_FILEHANDLE>;
        close(CONFIG_FILEHANDLE);

        # We need to keep track of both the real and the original line numbers.  The original line numbers are for matching errors in
        # the errors array, and don't include any comment lines added or deleted.  Line number is the current line number including
        # those comment lines for sending to the display.
        my $lineNumber = 1;
        my $originalLineNumber = 1;

        open(CONFIG_FILEHANDLE, '>' . $file);

        # We don't want to keep the old error header, if present.
        if ($lines[0] =~ /^\# There (?:is an error|are \d+ errors) in this file\./)
            {
            shift @lines;
            $originalLineNumber++;

            # We want to drop the blank line after it as well.
            if (scalar @lines && $lines[0] eq "\n")
                {
                shift @lines;
                $originalLineNumber++;
                };
            };

        if ($self->ErrorCount() == 1)
            {
            print CONFIG_FILEHANDLE
            "# There is an error in this file.  Search for ERROR to find it.\n\n";
            }
        else
            {
            print CONFIG_FILEHANDLE
            "# There are " . $self->ErrorCount() . " errors in this file.  Search for ERROR to find them.\n\n";
            };

        $lineNumber += 2;


        foreach my $line (@lines)
            {
            while (scalar @errors && $originalLineNumber == $errors[0])
                {
                my $errorLine = shift @errors;
                my $errorMessage = shift @errors;

                print CONFIG_FILEHANDLE "# ERROR: " . $errorMessage . "\n";

                # Use the GNU error format, which should make it easier to handle errors when Natural Docs is part of a build process.
                # See http://www.gnu.org/prep/standards_15.html

                $errorMessage = lcfirst($errorMessage);
                $errorMessage =~ s/\.$//;

                print STDERR 'NaturalDocs:' . $file . ':' . $lineNumber . ': ' . $errorMessage . "\n";

                $lineNumber++;
                };

            # We want to remove error lines from previous runs.
            if (substr($line, 0, 9) ne '# ERROR: ')
                {
                print CONFIG_FILEHANDLE $line;
                $lineNumber++;
                };

            $originalLineNumber++;
            };

        close(CONFIG_FILEHANDLE);
        };
    };


1;
