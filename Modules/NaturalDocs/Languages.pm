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
#       lineComment          - The symbol or arrayref of symbols that start a single line comment.  Undef if none.
#       startComment         - The symbol or arrayref of symbols that start a multi-line comment.  Undef if none.
#       endComment          - The symbol or arrayref of symbols that end a multi-line comment.  Undef if none.
#       functionEnders         - An arrayref of symbols that end a function prototype.  Include "\n" if necessary.  Undef if the language
#                                       doesn't have functions.
#       variableEnders        - An arrayref of symbols that end a variable declaration.  Include "\n" if necessary.  Undef if the
#                                       doesn't have variables.
#       lineExtender            - The symbol which extends a line of code past a line break.  Undef if not applicable.
#
#       Note that if neither of the comment styles are specified, it is assumed that the entire file should be treated as a comment.
#
#   Revisions:
#
#       Starting with 1.1, the comment parameters accept arrayrefs in addition to single symbols.  We don't force arrayrefs so
#       that custom lines added beforehand don't break.
#
#       1.1 also added the lineExtender parameter.  Since it accepts undef, it doesn't matter if it's not specified by older lines.
#
sub Add #(name, extensions, shebangStrings, lineComment, startComment, endComment, functionEnders, variableEnders, lineEnder)
    {
    my ($name, $extensions, $shebangStrings, $lineComment, $startComment, $endComment, $functionEnders,
           $variableEnders, $lineExtender) = @_;

    # Convert old parameter styles.

    if (defined $lineComment && !ref $lineComment)
        {  $lineComment = [ $lineComment ];  };
    if (defined $startComment && !ref $startComment)
        {  $startComment = [ $startComment ];  };
    if (defined $endComment && !ref $endComment)
        {  $endComment = [ $endComment ];  };

    my $language = NaturalDocs::Languages::Language::New($name, $lineComment, $startComment, $endComment,
                                                                                          $functionEnders, $variableEnders, $lineExtender);

    my $languageIndex = scalar @languages;
    push @languages, $language;

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
    my $sourceFile = shift;

    my $extension;
    if ($sourceFile =~ /\.([^\.]+)$/)
        {  $extension = lc($1);  };

    if (!defined $extension || $extension eq 'cgi')
        {
        my $fullSourceFile = NaturalDocs::File::JoinPath( NaturalDocs::Settings::InputDirectory(), $sourceFile);
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


1;