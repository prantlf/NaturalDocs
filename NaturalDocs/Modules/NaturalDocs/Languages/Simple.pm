###############################################################################
#
#   Class: NaturalDocs::Languages::Simple
#
###############################################################################
#
#   A class containing the characteristics of a particular programming language for basic support within Natural Docs.
#   Also serves as a base class for languages that break from general conventions, such as not having parameter lists use
#   parenthesis and commas.
#
###############################################################################

# This file is part of Natural Docs, which is Copyright © 2003-2004 Greg Valure
# Natural Docs is licensed under the GPL

use strict;
use integer;

package NaturalDocs::Languages::Simple;

use base 'NaturalDocs::Languages::Base';


use NaturalDocs::DefineMembers 'LINE_COMMENT_SYMBOLS', 'LineCommentSymbols()', 'SetLineCommentSymbols() duparrayref',
                                                 'BLOCK_COMMENT_SYMBOLS', 'BlockCommentSymbols()',
                                                                                              'SetBlockCommentSymbols() duparrayref',
                                                 'PROTOTYPE_ENDERS',
                                                 'LINE_EXTENDER', 'LineExtender()', 'SetLineExtender()';

#
#   Functions: Members
#
#   LineCommentSymbols - Returns an arrayref of symbols that start a line comment, or undef if none.
#   SetLineCommentSymbols - Replaces the arrayref of symbols that start a line comment.
#   BlockCommentSymbols - Returns an arrayref of start/end symbol pairs that specify a block comment, or undef if none.  Pairs
#                                        are specified with two consecutive array entries.
#   SetBlockCommentSymbols - Replaces the arrayref of start/end symbol pairs that specify a block comment.  Pairs are
#                                             specified with two consecutive array entries.
#   LineExtender - Returns the symbol to ignore a line break in languages where line breaks are significant.
#   SetLineExtender - Replaces the symbol to ignore a line break in languages where line breaks are significant.
#


#
#   Function: PrototypeEndersFor
#
#   Returns an arrayref of prototype ender symbols for the passed <TopicType>, or undef if none.
#
sub PrototypeEndersFor #(type)
    {
    my ($self, $type) = @_;

    if (defined $self->[PROTOTYPE_ENDERS])
        {  return $self->[PROTOTYPE_ENDERS]->{$type};  }
    else
        {  return undef;  };
    };


#
#   Function: SetPrototypeEndersFor
#
#   Replaces the arrayref of prototype ender symbols for the passed <TopicType>.
#
sub SetPrototypeEndersFor #(type, enders)
    {
    my ($self, $type, $enders) = @_;

    if (!defined $self->[PROTOTYPE_ENDERS])
        {  $self->[PROTOTYPE_ENDERS] = { };  };

    if (!defined $enders)
        {  delete $self->[PROTOTYPE_ENDERS]->{$type};  }
    else
        {
        $self->[PROTOTYPE_ENDERS]->{$type} = [ @$enders ];
        };
    };



###############################################################################
# Group: Parsing Functions


#
#   Function: ParseFile
#
#   Parses the passed source file, sending comments acceptable for documentation to <NaturalDocs::Parser->OnComment()>
#   and all other sections to <OnCode()>.
#
#   Parameters:
#
#       sourceFile - The <FileName> of the source file to parse.
#       topicList - A reference to the list of <NaturalDocs::Parser::ParsedTopics> being built by the file.
#
#   Returns:
#
#       Since this class cannot automatically document the code or generate a scope record, it always returns ( undef, undef ).
#
sub ParseFile #(sourceFile, topicsList)
    {
    my ($self, $sourceFile, $topicsList) = @_;

    open(SOURCEFILEHANDLE, '<' . $sourceFile)
        or die "Couldn't open input file " . $sourceFile . "\n";

    my @commentLines;
    my @codeLines;
    my $lastCommentTopicCount = 0;

    if ($self->Name() eq 'Text File')
        {
        my $line;

        while ($line = <SOURCEFILEHANDLE>)
            {
            ::XChomp(\$line);
            push @commentLines, $line;
            };

        NaturalDocs::Parser->OnComment(\@commentLines, 1);
        }

    else
        {
        my $line = <SOURCEFILEHANDLE>;
        my $lineNumber = 1;

        while (defined $line)
            {
            ::XChomp(\$line);
            my $originalLine = $line;


            # Retrieve single line comments.  This leaves $line at the next line.

            if ($self->StripOpeningSymbols(\$line, $self->LineCommentSymbols()))
                {
                do
                    {
                    push @commentLines, $line;
                    $line = <SOURCEFILEHANDLE>;

                    if (!defined $line)
                        {  goto EndDo;  };

                    ::XChomp(\$line);
                    }
                while ($self->StripOpeningSymbols(\$line, $self->LineCommentSymbols()));

                EndDo:  # I hate Perl sometimes.
                }


            # Retrieve multiline comments.  This leaves $line at the next line.

            elsif (my $closingSymbol = $self->StripOpeningBlockSymbols(\$line, $self->BlockCommentSymbols()))
                {
                # Note that it is possible for a multiline comment to start correctly but not end so.  We want those comments to stay in
                # the code.  For example, look at this prototype with this splint annotation:
                #
                # int get_array(integer_t id,
                #                    /*@out@*/ array_t array);
                #
                # The annotation starts correctly but doesn't end so because it is followed by code on the same line.

                my $lineRemainder;

                for (;;)
                    {
                    $lineRemainder = $self->StripClosingSymbol(\$line, $closingSymbol);

                    push @commentLines, $line;

                    #  If we found an end comment symbol...
                    if (defined $lineRemainder)
                        {  last;  };

                    $line = <SOURCEFILEHANDLE>;

                    if (!defined $line)
                        {  last;  };

                    ::XChomp(\$line);
                    };

                if ($lineRemainder !~ /^[ \t]*$/)
                    {
                    # If there was something past the closing symbol this wasn't an acceptable comment, so move the lines to code.
                    push @codeLines, @commentLines;
                    @commentLines = ( );
                    };

                $line = <SOURCEFILEHANDLE>;
                }


            # Otherwise just add it to the code.

            else
                {
                push @codeLines, $line;
                $line = <SOURCEFILEHANDLE>;
                };


            # If there were comments, send them to Parser->OnComment().

            if (scalar @commentLines)
                {
                # First process any code lines before the comment.
                if (scalar @codeLines)
                    {
                    $self->OnCode(\@codeLines, $lineNumber, $topicsList, $lastCommentTopicCount);
                    $lineNumber += scalar @codeLines;
                    @codeLines = ( );
                    };

                $lastCommentTopicCount = NaturalDocs::Parser->OnComment(\@commentLines, $lineNumber);
                $lineNumber += scalar @commentLines;
                @commentLines = ( );
                };

            };  # while (defined $line)


        # Clean up any remaining code.
        if (scalar @codeLines)
            {
            $self->OnCode(\@codeLines, $lineNumber, $topicsList, $lastCommentTopicCount);
            @codeLines = ( );
            };

        };

    close(SOURCEFILEHANDLE);

    return ( undef, undef );
    };


#
#   Function: OnCode
#
#   Called whenever a section of code is encountered by the parser.  Is used to find the prototype of the last topic created.
#
#   Parameters:
#
#       codeLines - The source code as an arrayref of lines.
#       codeLineNumber - The line number of the first line of code.
#       topicList - A reference to the list of <NaturalDocs::Parser::ParsedTopics> being built by the file.
#       lastCommentTopicCount - The number of Natural Docs topics that were created by the last comment.
#
sub OnCode #(codeLines, codeLineNumber, topicList, lastCommentTopicCount)
    {
    my ($self, $codeLines, $codeLineNumber, $topicList, $lastCommentTopicCount) = @_;

    if ($lastCommentTopicCount && $self->HasPrototype($topicList->[-1]->Type()))
        {
        my $index = 0;
        my $prototype;

        # Skip all blank lines before a prototype.
        while ($index < scalar @$codeLines && $codeLines->[$index] =~ /^[ \t]*$/)
            {  $index++;  };

        # Add prototype lines until we reach the end of the prototype or the end of the comment lines.
        while ($index < scalar @$codeLines)
            {
            # We need to add a line break because that may be a prototype ender.
            $prototype .= $codeLines->[$index] . "\n";

            my $endOfPrototype = $self->EndOfPrototype($topicList->[-1]->Type(), \$prototype, undef);

            if ($endOfPrototype == -1)
                {
                $index++;
                }
            else
                {
                # We found it!
                $prototype = substr($prototype, 0, $endOfPrototype);
                $self->RemoveExtenders(\$prototype);

                # Try to match the title to the prototype.

                my $titleInPrototype = $topicList->[-1]->Title();

                # Strip parenthesis so Function(2) and Function(int, int) will still match Function(anything).
                $titleInPrototype =~ s/[\t ]*\(.*$//;

                if (index($prototype, $titleInPrototype) != -1)
                    {
                    $topicList->[-1]->SetPrototype($prototype);
                    };

                return;
                };
            };

        # If we got out of that while loop by running out of lines, there was no prototype.
        };
    };



###############################################################################
# Group: Support Functions


#
#   Function: HasPrototype
#
#   Returns whether the language accepts prototypes from the passed <TopicType>.
#
sub HasPrototype #(type)
    {
    my ($self, $type) = @_;
    return ( defined $self->PrototypeEndersFor($type) );
    };


#
#   Function: EndOfPrototype
#
#   Returns the index of the end of the prototype in a string.
#
#   Parameters:
#
#       type - The <TopicType> of the prototype.
#       stringRef  - A reference to the string.
#       falsePositives  - An existence hashref of indexes into the string that would trigger false positives, and thus should be
#                              ignored.  This is for use by derived classes only, so set to undef.
#
#   Returns:
#
#       The zero-based offset into the string of the end of the prototype, or -1 if the string doesn't contain a symbol that would
#       end it.
#
sub EndOfPrototype #(type, stringRef, falsePositives)
    {
    my ($self, $type, $stringRef, $falsePositives) = @_;

    my $symbols = $self->PrototypeEndersFor($type);
    if (!defined $symbols)
        {  return -1;  };

    if (!defined $falsePositives)
        {  $falsePositives = { };  };

    my $enderIndex = -1;

    foreach my $ender (@$symbols)
        {
        my $testIndex;

        if ($ender eq "\n" && defined $self->LineExtender())
            {
            my $startingIndex = 0;

            for (;;)
                {
                $testIndex = index($$stringRef, $ender, $startingIndex);

                if ($testIndex == -1)
                    {  last;  };

                my $extenderIndex = rindex($$stringRef, $self->LineExtender(), $testIndex);

                if ($extenderIndex == -1 ||
                    ( substr( $$stringRef, $extenderIndex + length($self->LineExtender()),
                                 $testIndex - $extenderIndex - length($self->LineExtender()) ) !~ /^[ \t]*$/ &&
                      !exists $falsePositives->{$testIndex}) )
                    {
                    last;
                    };

                $startingIndex = $testIndex + 1;
                };
            }

        elsif ($ender =~ /^[a-z]+$/i)
            {
            my $startingIndex = 0;

            for (;;)
                {
                $testIndex = index($$stringRef, $ender, $startingIndex);

                if ($testIndex == -1)
                    {  last;  };

                # If the ender is a text keyword, the next and previous character can't be alphanumeric.
                if ( ($testIndex == 0 || substr($$stringRef, $testIndex - 1, 1) !~ /^[a-z0-9_]$/i) &&
                     substr($$stringRef, $testIndex + length($ender), 1) !~ /^[a-z0-9_]$/i &&
                     !exists $falsePositives->{$testIndex} )
                    {
                    last;
                    };

                $startingIndex = $testIndex + 1;
                };
            }

        else # ender is a symbol or a line break with no defined line extender.
            {
            my $startingIndex = 0;

            for (;;)
                {
                $testIndex = index($$stringRef, $ender, $startingIndex);

                if ($testIndex == -1 || !exists $falsePositives->{$testIndex})
                    {  last;  };

                $startingIndex = $testIndex + 1;
                };
            };


        if ($testIndex != -1 && ($enderIndex == -1 || $testIndex < $enderIndex))
            {  $enderIndex = $testIndex;  };
        };

    return $enderIndex;
    };


#
#   Function: FalsePositivesForSemicolonsInParenthesis
#
#   Returns an existence hashref of potential false positives for languages that can end a function prototype with a semicolon
#   but also use them to separate parameters.  For example:
#
#   > function MyFunction( param1: type; param2, param3: type; param4: type);
#
#   It will create false positives for every semicolon appearing within parenthesis.
#
#   Parameters:
#
#       stringRef - The potential function prototype.
#
#   Returns:
#
#       An existence hashref of false positive indexes.  If none, will return an empty hashref.
#
sub FalsePositivesForSemicolonsInParenthesis #(stringRef)
    {
    my ($self, $stringRef) = @_;

    my $falsePositives = { };
    my $startingParenIndex = 0;

    for (;;)
        {
        my $openingParenIndex = index($$stringRef, '(', $startingParenIndex);

        if ($openingParenIndex == -1)
            {  last;  };

        my $closingParenIndex = index($$stringRef, ')', $openingParenIndex);
        my $startingSemicolonIndex = $openingParenIndex;

        for (;;)
            {
            my $semicolonIndex = index($$stringRef, ';', $startingSemicolonIndex);

            if ($semicolonIndex == -1 || ($closingParenIndex != -1 && $semicolonIndex > $closingParenIndex))
                {  last;  };

            $falsePositives->{$semicolonIndex} = 1;
            $startingSemicolonIndex = $semicolonIndex + 1;
            };

        if ($closingParenIndex == -1)
            {  last;  }
        else
            {  $startingParenIndex = $closingParenIndex + 1;  };
        };

    return $falsePositives;
    };


#
#   Function: RemoveExtenders
#
#   Strips any <LineExtender()> symbols out of the prototype.
#
#   Parameters:
#
#       stringRef - A reference to the string.  It will be altered rather than a new one returned.
#
sub RemoveExtenders #(stringRef)
    {
    my ($self, $stringRef) = @_;

    if (defined $self->LineExtender())
        {
        my @lines = split(/\n/, $$stringRef);

        for (my $i = 0; $i < scalar @lines; $i++)
            {
            my $extenderIndex = rindex($lines[$i], $self->LineExtender());

            if ($extenderIndex != -1 && substr($lines[$i], $extenderIndex + length($self->LineExtender())) =~ /^[ \t]*$/)
                {  $lines[$i] = substr($lines[$i], 0, $extenderIndex);  };
            };

        $$stringRef = join(' ', @lines);
        };
    };


1;
