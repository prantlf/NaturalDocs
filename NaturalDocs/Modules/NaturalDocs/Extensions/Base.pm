###############################################################################
#
#   Package: NaturalDocs::Extensions::Base
#
###############################################################################
#
#   A base package for all Natural Docs extensions.
#
###############################################################################

# This file is part of Natural Docs, which is Copyright © 2003-2004 Greg Valure
# Natural Docs is licensed under the GPL

use strict;
use integer;

package NaturalDocs::Extensions::Base;


###############################################################################
# Group: Required Functions
# These functions must be defined by extension packages if appropriate.

#
#   Function: BEGIN
#
#   If your extension requires any external packages that are not included in all Perl distributions by default, you *must*
#   define BEGIN to call <NaturalDocs::Extensions->Requires()> for them instead of using 'use [package]' or 'require [package]'
#   directly.  Doing so allows Natural Docs to degrade gracefully as explained in the documentation for
#   <NaturalDocs::Extensions->Requires()>.
#
#   Example:
#
#   > sub BEGIN
#   >    {
#   >    NaturalDocs::Extensions->Requires(__PACKAGE__, 'String::CRC32', 'Crypt::Blowfish');
#   >    };
#

#
#   Function: INIT
#
#   For any extension package to be recognized, it *must* define INIT and have it call <NaturalDocs::Extensions->Add()> for
#   itself.  Use the code below.
#
#   > sub INIT
#   >    {
#   >    NaturalDocs::Extensions->Add(__PACKAGE__);
#   >    };
#


###############################################################################
# Group: Interface Functions

#
#   Function: CommandLineOptions
#
#   Use this function to return a hashref of all the command line options the extension accepts.  The keys are the short versions
#   ('-i') and the values are the long versions ('--input').  Both must be in *all lowercase*.  If there are no command line options
#   for this extension, don't define this function.
#
#   For example, this function can be defined as
#
#   > sub CommandLineOptions
#   >    {
#   >    return { '-c' => '--cvs' };
#   >    }
#
sub CommandLineOptions
    {
    return undef;
    };

#
#   Function: ParseCommandLineOptions
#
#   This is called after the command line has been parsed.  Use it to see which flags have been set and to get their values, if
#   applicable.  If there are no command line options for this extension, don't define this function.
#
#   Parameters:
#
#       options - A hashref of the command line options and values.  The keys are the short versions ('-i') in all lowercase, and the
#                     values are any options that followed, or undef if none.  Do not change the hashref.
#
#   Returns:
#
#       If you find errors in the values of any of your options, return an arrayref of error message strings, one for each error.
#       If there are no errors, return undef.
#
#   Implementation Notes:
#
#       Since options that are set but don't have a value will be set to undef in the hash, test for the keys existence using 'exists'
#       to see if the option was set at all.
#
#       It's possible that there will be options in the hashref besides those that are used by the package.  Ignore them.  Do not
#       test options besides your own because they are not guaranteed to be there in future versions of Natural Docs.
#
sub ParseCommandLineOptions #(options)
    {
    return undef;
    };



###############################################################################
# Group: Hooks
#
# Implement these functions as necessary to create your extension.  Note that these functions will be called regardless of
# whether any of the extension's command line options were set, so it's the extension's responsibility to ignore these calls
# if necessary.


#
#   Function: AfterFileParsed
#
#   Called after a file has been parsed, but before it is scanned for symbols or turned into output.  Any modifications done here
#   will affect those two functions.
#
#   Note that this function will only be called when the file has Natural Docs content.  It will not send an empty array.
#
#   Parameters:
#
#       file - The source file.
#       parsedFile - The arrayref of <NaturalDocs::Parser::ParsedTopic> objects.  Directly change this arrayref as necessary.
#
sub AfterFileParsed #(file, parsedFile)
    {
    };


#
#   Topic: Need More?
#
#   If you need another hook for your extension, contact Natural Docs' <Maintainer>.  Describe what you need and what you
#   plan to do with it.
#


1;
