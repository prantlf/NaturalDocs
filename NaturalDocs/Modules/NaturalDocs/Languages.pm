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
#       file - The source file to get the language of.
#
#   Returns:
#
#       A <NaturalDocs::Languages::Language> object for the passed file, or undef if the file is not a recognized language.
#
sub LanguageOf #(file)
    {
    my $file = shift;

    my $extension;
    if ($file =~ /\.([^\.]+)$/)
        {  $extension = lc($1);  };

    if (!defined $extension || $extension eq 'cgi')
        {
        my $fileName = NaturalDocs::File::JoinPath( NaturalDocs::Settings::InputDirectory(), $file);
        my $fileHandle;
        my $shebangLine;

        open($fileHandle, '<' . $fileName) or die 'Could not open ' . $fileName;

        read($fileHandle, $shebangLine, 2);
        if ($shebangLine eq '#!')
            {  $shebangLine = <$fileHandle>;  }
        else
            {  $shebangLine = undef;  };

        close ($fileHandle);

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
    my $file = shift;

    # This function used to be slightly more efficient than just testing if LanguageOf returns undef, but now that we support
    # shebangs, it's really not worth it.

    return (defined LanguageOf($file));
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
    my $string = shift;

    if ($string =~ /^(.+)(?:\.|::|->)(.+)$/)
        {  return ($1, $2);  }
    else
        {  return $string;  };
    };


###############################################################################
# Group: Support Functions

#
#   Function: Add
#
#   Adds a language to the package.
#
#   Parameters:
#
#       name                      - The name of the language.
#       extensions              - An arrayref of the extensions of the language's files.
#       shebangStrings       - An arrayref of the strings to search for in the #! line of the language's files.  Only used when the file
#                                       has a .cgi extension or no extension at all.  Undef if not applicable.
#       lineComment          - The symbol that starts a single line comment.  Undef if none.
#       startComment         - The symbol that starts a multi-line comment.  Undef if none.
#       endComment          - The symbol that ends a multi-line comment.  Undef if none.
#       functionEnders         - An arrayref of symbols that end a function prototype.  Include "\n" if necessary.  Undef if the language
#                                       doesn't have functions.
#       variableEnders        - An arrayref of symbols that end a variable declaration.  Include "\n" if necessary.  Undef if the
#                                       doesn't have variables.
#
#       Note that if neither of the comment styles are specified, it is assumed that the entire file should be treated as a comment.
#
sub Add #(name, extensions, shebangStrings, lineComment, startComment, endComment, functionEnders, variableEnders)
    {
    my $name = shift;
    my $languageExtensions = shift;
    my $languageShebangStrings = shift;

    # This depends on New() having the same parameter order as this function after the first three parameters.
    my $language = NaturalDocs::Languages::Language::New(@_);

    my $languageIndex = scalar @languages;
    push @languages, $language;

    foreach my $extension (@$languageExtensions)
        {
        $extensions{ lc($extension) } = $languageIndex;
        };

    if (defined $languageShebangStrings)
        {
        foreach my $shebangString (@$languageShebangStrings)
            {
            $shebangs{ lc($shebangString) } = $languageIndex;
            };
        };
    };

1;