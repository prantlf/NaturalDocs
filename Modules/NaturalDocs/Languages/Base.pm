###############################################################################
#
#   Class: NaturalDocs::Languages::Base
#
###############################################################################
#
#   A base class for all programming language parsers.
#
###############################################################################

# This file is part of Natural Docs, which is Copyright © 2003-2004 Greg Valure
# Natural Docs is licensed under the GPL

use strict;
use integer;

package NaturalDocs::Languages::Base;

use NaturalDocs::DefineMembers 'NAME', 'Name()',
                                                 'EXTENSIONS', 'Extensions()', 'SetExtensions() duparrayref',
                                                 'SHEBANG_STRINGS', 'ShebangStrings()', 'SetShebangStrings() duparrayref',
                                                 'PACKAGE_SEPARATOR', 'PackageSeparator()',
                                                 'IGNORED_PREFIXES',
                                                 'PACKAGE_SEPARATOR_WAS_SET', 'PackageSeparatorWasSet()';


#
#   Handle: SOURCEFILEHANDLE
#
#   The handle of the source file currently being parsed.
#


#
#   Function: New
#
#   Creates and returns a new object.
#
#   Parameters:
#
#       name - The name of the language.
#
sub New #(name)
    {
    my ($selfPackage, $name) = @_;

    my $object = [ ];

    $object->[NAME] = $name;
    $object->[PACKAGE_SEPARATOR] = '.';

    bless $object, $selfPackage;
    return $object;
    };


#
#   Functions: Members
#
#   Name - Returns the language's name.
#   Extensions - Returns an arrayref of the language's file extensions, or undef if none.
#   SetExtensions - Replaces the arrayref of the language's file extensions.
#   ShebangStrings - Returns an arrayref of the language's shebang strings, or undef if none.
#   SetShebangStrings - Replaces the arrayref of the language's shebang strings.
#   PackageSeparator - Returns the language's package separator string.
#   PackageSeparatorWasSet - Returns whether the language's package separator string was ever changed from the default.
#


#
#   Function: SetPackageSeparator
#   Replaces the language's package separator string.
#
sub SetPackageSeparator #(separator)
    {
    my ($self, $separator) = @_;
    $self->[PACKAGE_SEPARATOR] = $separator;
    $self->[PACKAGE_SEPARATOR_WAS_SET] = 1;
    };


#
#   Function: IgnoredPrefixesFor
#
#   Returns an arrayref of ignored prefixes for the passed <TopicType>, or undef if none.  The array is sorted so that the longest
#   prefixes are first.
#
sub IgnoredPrefixesFor #(type)
    {
    my ($self, $type) = @_;

    if (defined $self->[IGNORED_PREFIXES])
        {  return $self->[IGNORED_PREFIXES]->{$type};  }
    else
        {  return undef;  };
    };


#
#   Function: SetIgnoredPrefixesFor
#
#   Replaces the arrayref of ignored prefixes for the passed <TopicType>.
#
sub SetIgnoredPrefixesFor #(type, prefixes)
    {
    my ($self, $type, $prefixesRef) = @_;

    if (!defined $self->[IGNORED_PREFIXES])
        {  $self->[IGNORED_PREFIXES] = { };  };

    if (!defined $prefixesRef)
        {  delete $self->[IGNORED_PREFIXES]->{$type};  }
    else
        {
        my $prefixes = [ @$prefixesRef ];

        # Sort prefixes to be longest to shortest.
        @$prefixes = sort { length $b <=> length $a } @$prefixes;

        $self->[IGNORED_PREFIXES]->{$type} = $prefixes;
        };
    };


#
#   Function: HasIgnoredPrefixes
#
#   Returns whether the language has any ignored prefixes at all.
#
sub HasIgnoredPrefixes
    {  return defined $_[0]->[IGNORED_PREFIXES];  };


#
#   Function: CopyIgnoredPrefixesOf
#
#   Copies all the ignored prefix settings of the passed <NaturalDocs::Languages::Base> object.
#
sub CopyIgnoredPrefixesOf #(language)
    {
    my ($self, $language) = @_;

    if ($language->HasIgnoredPrefixes())
        {
        $self->[IGNORED_PREFIXES] = { };

        while (my ($topicType, $prefixes) = each %{$language->[IGNORED_PREFIXES]})
            {
            $self->[IGNORED_PREFIXES]->{$topicType} = [ @$prefixes ];
            };
        };
    };



###############################################################################
# Group: Parsing Functions


#
#   Function: ParseFile
#
#   Parses the passed source file, sending comments acceptable for documentation to <NaturalDocs::Parser->OnComment()>.
#   This *must* be defined by a subclass.
#
#   Parameters:
#
#       sourceFile - The <FileName> of the source file to parse.
#       topicList - A reference to the list of <NaturalDocs::Parser::ParsedTopics> being built by the file.
#
#   Returns:
#
#       The array ( autoTopics, scopeRecord ).
#
#       autoTopics - An arrayref of automatically generated <NaturalDocs::Parser::ParsedTopics> from the file, or undef if none.
#       scopeRecord - An arrayref of <NaturalDocs::Languages::Advanced::ScopeChanges>, or undef if none.
#


#
#   Function: FormatPrototype
#
#   Parses a prototype so that it can be formatted nicely in the output.  By default, it formats function prototypes assuming the
#   parameter list is enclosed in parenthesis and parameters are separated by commas and semicolons.  It leaves all other
#   prototypes alone.
#
#   Parameters:
#
#       type - The <TopicType>.
#       prototype - The text prototype.
#
#   Returns:
#
#       The array ( preParam, opening, params, closing, postParam ).
#
#       preParam - The part of the prototype prior to the parameter list.  If there is no parameter list, this is the only part of the
#                        array that will be defined.
#       open - The opening symbol to the parameter list, such as parenthesis.  If there is none but there are parameters, it will be
#                 a space.
#       params - An arrayref of parameters, one per entry.  Will be undef if none.
#       close - The closing symbol to the parameter list, such as parenthesis.  If there is none but there are parameters, it will be
#                 a space.
#       postParam - The part of the prototype after the parameter list, or undef if none.
#
sub FormatPrototype #(type, prototype)
    {
    my ($self, $type, $prototype) = @_;

    $prototype =~ tr/\t\n /   /s;
    $prototype =~ s/^ //;
    $prototype =~ s/ $//;

    # Cut out early if it's not a function.
    if ($type ne ::TOPIC_FUNCTION())
        {  return ( $prototype, undef, undef, undef, undef );  };

    # The parsing routine needs to be able to find the parameters no matter how many parenthesis there are.  For example, look
    # at this VB function declaration:
    #
    # <WebMethod()> Public Function RetrieveTable(ByRef Msg As Integer, ByVal Key As String) As String()

    my @segments = split(/([\(\)])/, $prototype);
    my ($pre, $open, $paramString, $params, $close, $post);
    my $nest = 0;

    while (scalar @segments)
        {
        my $segment = shift @segments;

        if ($nest == 0)
            {  $pre .= $segment;  }

        elsif ($nest == 1 && $segment eq ')')
            {
            if ($paramString =~ /[,;]/)
                {
                $post = join('', $segment, @segments);
                last;
                }
            else
                {
                $pre .= $paramString . $segment;
                $paramString = undef;
                };
            }

        else
            {  $paramString .= $segment;  };

        if ($segment eq '(')
            {  $nest++;  }
        elsif ($segment eq ')' && $nest > 0)
            {  $nest--;  };
        };

    # If there wasn't closing parenthesis...
    if ($paramString && !defined $post)
        {
        $pre .= $paramString;
        $paramString = undef;
        };


    if (!defined $paramString)
        {
        return ( $pre, undef, undef, undef, undef );
        }
    else
        {
        if ($pre =~ /( ?\()$/)
            {
            $open = $1;
            $pre =~ s/ ?\($//;
            };

        if ($post=~ /^(\) ?)/)
            {
            $close = $1;
            $post =~ s/^\) ?//;

            if (!length $post)
                {  $post = undef;  };
            };

        my $params = [ ];

        while ($paramString =~ /([^,;]+[,;]?) ?/g)
            {  push @$params, $1;  };

        return ( $pre, $open, $params, $close, $post );
        };
    };


#
#   Function: IgnoredPrefixLength
#
#   Returns the length of the prefix that should be ignored in the index, or zero if none.
#
#   Parameters:
#
#       name - The name of the symbol.
#       type  - The symbol's <TopicType>.
#
#   Returns:
#
#       The length of the prefix to ignore, or zero if none.
#
sub IgnoredPrefixLength #(name, type)
    {
    my ($self, $name, $type) = @_;

    foreach my $prefixes ($self->IgnoredPrefixesFor($type), $self->IgnoredPrefixesFor(::TOPIC_GENERAL()))
        {
        if (defined $prefixes)
            {
            foreach my $prefix (@$prefixes)
                {
                if (substr($name, 0, length($prefix)) eq $prefix)
                    {  return length($prefix);  };
                };
            };
        };

    return 0;
    };



###############################################################################
# Group: Support Functions


#
#   Function: StripOpeningSymbols
#
#   Determines if the line starts with any of the passed symbols, and if so, replaces it with spaces.  This only happens
#   if the only thing before it on the line is whitespace.
#
#   Parameters:
#
#       lineRef - A reference to the line to check.
#       symbols - An arrayref of the symbols to check for.
#
#   Returns:
#
#       If the line starts with any of the passed comment symbols, it will replace it in the line with spaces and return the symbol.
#       If the line doesn't, it will leave the line alone and return undef.
#
sub StripOpeningSymbols #(lineRef, symbols)
    {
    my ($self, $lineRef, $symbols) = @_;

    if (!defined $symbols)
        {  return undef;  };

    foreach my $symbol (@$symbols)
        {
        my $index = index($$lineRef, $symbol);

        if ($index != -1 && substr($$lineRef, 0, $index) =~ /^[ \t]*$/)
            {
            return substr($$lineRef, $index, length($symbol), ' ' x length($symbol));
            };
        };

    return undef;
    };


#
#   Function: StripOpeningBlockSymbols
#
#   Determines if the line starts with any of the opening symbols in the passed symbol pairs, and if so, replaces it with spaces.
#   This only happens if the only thing before it on the line is whitespace.
#
#   Parameters:
#
#       lineRef - A reference to the line to check.
#       symbolPairs - An arrayref of the symbol pairs to check for.  Pairs are specified as two consecutive array entries, with the
#                            opening symbol first.
#
#   Returns:
#
#       If the line starts with any of the opening symbols, it will replace it in the line with spaces and return the closing symbol.
#       If the line doesn't, it will leave the line alone and return undef.
#
sub StripOpeningBlockSymbols #(lineRef, symbolPairs)
    {
    my ($self, $lineRef, $symbolPairs) = @_;

    if (!defined $symbolPairs)
        {  return undef;  };

    for (my $i = 0; $i < scalar @$symbolPairs; $i += 2)
        {
        my $index = index($$lineRef, $symbolPairs->[$i]);

        if ($index != -1 && substr($$lineRef, 0, $index) =~ /^[ \t]*$/)
            {
            substr($$lineRef, $index, length($symbolPairs->[$i]), ' ' x length($symbolPairs->[$i]));
            return $symbolPairs->[$i + 1];
            };
        };

    return undef;
    };


#
#   Function: StripClosingSymbol
#
#   Determines if the line contains a symbol, and if so, truncates it just before the symbol.
#
#   Parameters:
#
#       lineRef - A reference to the line to check.
#       symbol - The symbol to check for.
#
#   Returns:
#
#       The remainder of the line, or undef if the symbol was not found.
#
sub StripClosingSymbol #(lineRef, symbol)
    {
    my ($self, $lineRef, $symbol) = @_;

    my $index = index($$lineRef, $symbol);

    if ($index != -1)
        {
        my $lineRemainder = substr($$lineRef, $index + length($symbol));
        $$lineRef = substr($$lineRef, 0, $index);

        return $lineRemainder;
        }
    else
        {  return undef;  };
    };


1;
