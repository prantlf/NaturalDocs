###############################################################################
#
#   Package: NaturalDocs::Languages
#
###############################################################################
#
#   A package to manage all the programming languages Natural Docs supports.
#
#   Usage and Dependencies:
#
#       - Prior to use, <NaturalDocs::Settings> must be initialized and all supported languages need to be added via <Add()>.
#
###############################################################################

# This file is part of Natural Docs, which is Copyright © 2003 Greg Valure
# Natural Docs is licensed under the GPL

use NaturalDocs::Languages::Language;
use NaturalDocs::Languages::PLSQL;
use NaturalDocs::Languages::Pascal;
use NaturalDocs::Languages::Ada;
use NaturalDocs::Languages::Tcl;

use strict;
use integer;

package NaturalDocs::Languages;


###############################################################################
# Group: Variables

#
#   array: languages
#
#   An array of all the defined languages.  Each entry is a <NaturalDocs::Languages::Language> object.
#
my @languages;

#
#   hash: extensions
#
#   A hash of all the defined languages' extensions.  The keys are the all-lowercase extensions, and the values are indexes into
#   <languages>.
#
my %extensions;

#
#   hash: shebangs
#
#   A hash of all the defined languages' strings to search for in the shebang (#!) line.  The keys are the all-lowercase strings, and
#   the values are indexes into <languages>.
#
my %shebangs;


###############################################################################
# Group: Functions


#
#   Function: LanguageOf
#
#   Returns the language of the passed source file.
#
#   Parameters:
#
#       sourceFile - The source file to get the language of.
#
#   Returns:
#
#       A <NaturalDocs::Languages::Language> object for the passed file, or undef if the file is not a recognized language.
#
sub LanguageOf #(sourceFile)
    {
    my ($self, $sourceFile) = @_;

    my $extension;
    if ($sourceFile =~ /\.([^\.]+)$/)
        {  $extension = lc($1);  };

    if (!defined $extension || $extension eq 'cgi')
        {
        my $fullSourceFile = NaturalDocs::File->JoinPath( NaturalDocs::Settings->InputDirectory(), $sourceFile);
        my $shebangLine;

        open(SOURCEFILEHANDLE, '<' . $fullSourceFile) or die 'Could not open ' . $sourceFile;

        read(SOURCEFILEHANDLE, $shebangLine, 2);
        if ($shebangLine eq '#!')
            {  $shebangLine = <SOURCEFILEHANDLE>;  }
        else
            {  $shebangLine = undef;  };

        close (SOURCEFILEHANDLE);

        if (!defined $shebangLine)
            {  return undef;  }
        else
            {
            $shebangLine = lc($shebangLine);

            foreach my $shebangString (keys %shebangs)
                {
                if (index($shebangLine, $shebangString) != -1)
                    {  return $languages[ $shebangs{$shebangString} ];  };
                };

            return undef;
            };
        }
    elsif (exists $extensions{$extension})
        {
        return $languages[ $extensions{$extension} ];
        }
    else
        {
        return undef;
        };
    };


#
#   Function: IsSupported
#
#   Returns whether the language of the passed file is supported.
#
#   Parameters:
#
#       file - The file to test.
#
#   Returns:
#
#       Whether the file's language is supported.
#
sub IsSupported #(file)
    {
    my ($self, $file) = @_;

    # This function used to be slightly more efficient than just testing if LanguageOf returns undef, but now that we support
    # shebangs, it's really not worth it.

    return (defined $self->LanguageOf($file));
    };


#
#   Function: SeparateMember
#
#   Separates a class from its member.  If there are multiple member separators in the string, it assumes the last one is correct
#   and all previous ones are part of the class name.  For example, "package::class::function" will be split into "package::class"
#   and "function".
#
#   Parameters:
#
#       string - The string of text to separate.
#
#   Returns:
#
#       An array.  If the string had a member separator in it, the first item will be the class and the second the identifier.  If there
#       was no member separator, there will only be one item, which will contain the original string.
#
sub SeparateMember #(string)
    {
    my ($self, $string) = @_;

    if ($string =~ /^(.+)(?:\.|::|->)(.+)$/)
        {  return ($1, $2);  }
    else
        {  return $string;  };
    };


###############################################################################
# Group: Interface Functions
# These functions are not for general use.  They're interfaces between specific packages and should only be used where noted.


#
#   Function: Add
#
#   Adds a <NaturalDocs::Languages::Language> object to the package.
#
#   Usage:
#
#       This function is *only* to be called by <NaturalDocs::Languages::Language->New()>.  Languages self-add when
#       created, so there is no need to call anywhere else.
#
#   Parameters:
#
#       languageObject  - A reference to the <NaturalDocs::Languages::Language> object.
#       extensions         - An arrayref of the extensions of the language's files.
#       shebangStrings  - An arrayref of the strings to search for in the #! line of the language's files.  Only used when the file
#                                 has a .cgi extension or no extension at all.  Undef if not applicable.
#
sub Add #(languageObject, extensions, shebangStrings)
    {
    my ($self, $languageObject, $extensions, $shebangStrings) = @_;

    # Prior to 1.13, Add() was called from the main script to add languages.  Since people may be cutting and pasting old code,
    # they may not be aware that the method changed.  We want to throw a specific error message for this situation so it's clear.
    # We can detect an old Add() call because it had many more parameters.
    if (scalar @_ > 4)
        {
        die "Natural Docs doesn't use NaturalDocs::Languages::Add() anymore.  Use NaturalDocs::Language::Languages->New().\n";
        };

    my $languageIndex = scalar @languages;
    push @languages, $languageObject;

    foreach my $extension (@$extensions)
        {
        $extensions{ lc($extension) } = $languageIndex;
        };

    if (defined $shebangStrings)
        {
        foreach my $shebangString (@$shebangStrings)
            {
            $shebangs{ lc($shebangString) } = $languageIndex;
            };
        };
    };


1;
