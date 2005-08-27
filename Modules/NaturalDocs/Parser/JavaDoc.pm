###############################################################################
#
#   Package: NaturalDocs::Parser::JavaDoc
#
###############################################################################
#
#   A package for translating JavaDoc topics or Natural Docs topics in JavaDoc comments into Natural Docs.
#
#   Supported tags:
#
#       - @param
#       - @author
#       - @deprecated
#       - @code, @literal (doesn't change font)
#       - @exception, @throws (doesn't link to class)
#       - @link, @linkplain (doesn't change font)
#       - @return, @returns
#       - @see
#       - @since
#       - @value (shown as link instead of replacement)
#       - @version
#
#   Stripped tags:
#
#       - @inheritDoc
#       - @serial, @serialField, @serialData
#       - All other block level tags.
#
#   Unsupported tags:
#
#       These will appear literally in the output because I cannot handle them easily.
#
#       - @docRoot
#       - Any other tags not mentioned
#
#   Supported HTML:
#
#       - p
#       - b, i, u
#       - pre
#       - a href
#       - ol, ul, li (ol gets converted to ul)
#       - gt, lt, amp, quot, nbsp entities
#
#   Stripped HTML:
#
#       - code
#       - HTML comments
#
#   Unsupported HTML:
#
#       These will appear literally in the output because I cannot handle them easily.
#
#       - Any tags with additional properties other than a href.  (ex. <p class=Something>)
#       - Any other tags not mentioned
#
#   Reference:
#
#       http://java.sun.com/j2se/1.5.0/docs/tooldocs/windows/javadoc.html
#
###############################################################################

# This file is part of Natural Docs, which is Copyright (C) 2003-2005 Greg Valure
# Natural Docs is licensed under the GPL

use strict;
use integer;

package NaturalDocs::Parser::JavaDoc;


#
#   hash: blockTags
#   An existence hash of the all-lowercase JavaDoc block tags, not including the @.
#
my %blockTags = ( 'param' => 1, 'author' => 1, 'deprecated' => 1, 'exception' => 1, 'return' => 1, 'see' => 1,
                             'serial' => 1, 'serialfield' => 1, 'serialdata' => 1, 'since' => 1, 'throws' => 1, 'version' => 1,
                             'returns' => 1 );

#
#   hash: inlineTags
#   An existence hash of the all-lowercase JavaDoc inline tags, not including the @.
#
my %inlineTags = ( 'inheritdoc' => 1, 'docroot' => 1, 'code' => 1, 'literal' => 1, 'link' => 1, 'linkplain' => 1, 'value' => 1 );


##
#   Examines the JavaDoc-style comment and parses it if the topic is in JavaDoc syntax.  Does not handle it if the topic was in
#   Natural Docs syntax and was just using a JavaDoc-style comment.  More specifically:
#
#   - If the comment starts with a Natural Docs topic line, it leaves it unaltered and returns false.
#
#   - If the comment doesn't start with a Natural Docs topic line but has JavaDoc @ tags, it parses it, adds it to parsedTopics, and
#     returns true.
#
#   - If the comment doesn't start with a Natural Docs topic line or have JavaDoc @ tags, it just adds a "<format:headerless>" line
#   at the beginning and returns false.
#
#   Parameters:
#
#       commentLines - An arrayref of the comment lines.  All tabs should be converted to spaces.  *The original memory will
#                               be changed.*
#       lineNumber - The line number of the first of the comment lines.
#       parsedTopics - A reference to the array where any new <NaturalDocs::Parser::ParsedTopics> should be placed.
#
#   Returns:
#
#       If true, the topic was in JavaDoc syntax and it was translated and added to the parsed topics.  If false, the topic was in
#       Natural Docs syntax and was not handled.
#
sub TranslateComment #(string[] commentLines, int lineNumber, ParsedTopics[]* parsedTopics)
    {
    my ($self, $commentLines, $lineNumber, $parsedTopics) = @_;

    # Skip to the first line with content.
    while (scalar @$commentLines && $commentLines->[0] =~ /^[ \t]*$/)
        {  shift @$commentLines;  };

    # Return if the first line is a comment line.
    if (NaturalDocs::Parser::Native->ParseHeaderLine($commentLines->[0]))
        {  return undef;  };

    # Check for any JavaDoc tags and return if there aren't any.
    my $isJavaDoc;

    for (my $i = 0; $i < scalar @$commentLines; $i++)
        {
        if ($commentLines->[$i] =~ /^ *@([a-z]+) /i && exists $blockTags{$1} ||
            $commentLines->[$i] =~ /\{@([a-z]+) /i && exists $inlineTags{$1})
            {
            $isJavaDoc = 1;
            last;
            };
        };

    if (!$isJavaDoc)
        {
        unshift @$commentLines, '<format:headerless>';
        return undef;
        };


    # At this point, we're sure it's a JavaDoc comment and we'll treat it as such.  Time to parse.

    # Stage one: Before block level tags.


    my $i = 0;
    my $output;
    my $unformattedText;
    my $inCode;
    my $sharedCodeIndent;

    while ($i < scalar @$commentLines &&
              !($commentLines->[$i] =~ /^ *@([a-z]+) /i && exists $blockTags{$1}) )
        {
        my $line = $self->ConvertAmpChars($commentLines->[$i]);
        my @tokens = split(/(&lt;\/?pre&gt;)/, $line);

        foreach my $token (@tokens)
            {
            if ($token =~ /^&lt;pre&gt;$/i)
                {
                if (!$inCode && $unformattedText)
                    {
                    $output .= '<p>' . $self->FormatText($unformattedText, 1) . '</p>';
                    };

                $inCode = 1;
                $unformattedText = undef;
                }
            elsif ($token =~ /^&lt;\/pre&gt;$/i)
                {
                if ($inCode && $unformattedText)
                    {
                    $unformattedText =~ s/^ {$sharedCodeIndent}//mg;
                    $unformattedText =~ s/\n{3,}/\n\n/g;
                    $unformattedText =~ s/\n+$//;
                    $output .= '<code>' . $unformattedText . '</code>';

                    $sharedCodeIndent = undef;
                    };

                $inCode = 0;
                $unformattedText = undef;
                }
            elsif (length($token))
                {
                if (!$inCode)
                    {
                    $token =~ s/^ +//;
                    if ($unformattedText)
                        {  $unformattedText .= ' ';  };
                    }
                else
                    {
                    $token =~ /^( *)/;
                    my $indent = length($1);

                    if (!defined $sharedCodeIndent || $indent < $sharedCodeIndent)
                        {  $sharedCodeIndent = $indent;  };
                    };

                $unformattedText .= $token;
                };
            };

        if ($inCode && $unformattedText)
            {  $unformattedText .= "\n";  };

        $i++;
        };

    if ($unformattedText)
        {
        if ($inCode)
            {
            $unformattedText =~ s/^ {$sharedCodeIndent}//mg;
            $unformattedText =~ s/\n{3,}/\n\n/g;
            $unformattedText =~ s/\n+$//;
            $output .= '<code>' . $unformattedText . '</code>';
            }
        else
            {  $output .= '<p>' . $self->FormatText($unformattedText, 1) . '</p>';  };

        $unformattedText = undef;
        };


    # Stage two: Block level tags.

    my ($keyword, $value, $unformattedTextPtr, $unformattedTextCloser);
    my ($params, $authors, $deprecation, $throws, $returns, $seeAlso, $since, $version);


    while ($i < scalar @$commentLines)
        {
        my $line = $self->ConvertAmpChars($commentLines->[$i]);
        $line =~ s/^ +//;

        if ($line =~ /^@([a-z]+) ?(.*)$/i)
            {
            ($keyword, $value) = (lc($1), $2);

            # Process the previous one, if any.
            if ($unformattedText)
                {
                $$unformattedTextPtr .= $self->FormatText($unformattedText) . $unformattedTextCloser;
                $unformattedText = undef;
                };

            if ($keyword eq 'param')
                {
                $value =~ /^([a-z0-9_]+) *(.*)$/i;

                $params .= '<de>' . $1 . '</de><dd>';
                $unformattedText = $2;

                $unformattedTextPtr = \$params;
                $unformattedTextCloser = '</dd>';
                }
            elsif ($keyword eq 'exception' || $keyword eq 'throws')
                {
                $value =~ /^([a-z0-9_]+) *(.*)$/i;

                $throws .= '<de>' . $1 . '</de><dd>';
                $unformattedText = $2;

                $unformattedTextPtr = \$throws;
                $unformattedTextCloser = '</dd>';
                }
            elsif ($keyword eq 'return' || $keyword eq 'returns')
                {
                if ($returns)
                    {  $returns .= ' ';  };

                $unformattedText = $value;
                $unformattedTextPtr = \$returns;
                $unformattedTextCloser = undef;
                }
            elsif ($keyword eq 'author')
                {
                if ($authors)
                    {  $authors .= ', ';  };

                $unformattedText = $value;
                $unformattedTextPtr = \$authors;
                $unformattedTextCloser = undef;
                }
            elsif ($keyword eq 'depreciated')
                {
                if ($deprecation)
                    {  $deprecation .= ' ';  };

                $unformattedText = $value;
                $unformattedTextPtr = \$deprecation;
                $unformattedTextCloser = undef;
                }
            elsif ($keyword eq 'since')
                {
                if ($since)
                    {  $since .= ', ';  };

                $unformattedText = $value;
                $unformattedTextPtr = \$since;
                $unformattedTextCloser = undef;
                }
            elsif ($keyword eq 'version')
                {
                if ($version)
                    {  $version .= ', ';  };

                $unformattedText = $value;
                $unformattedTextPtr = \$version;
                $unformattedTextCloser = undef;
                }
            elsif ($keyword eq 'see')
                {
                if ($seeAlso)
                    {  $seeAlso .= ', ';  };

                $unformattedText = undef;

                if ($value =~ /^&(?:quot|lt);/i)
                    {  $seeAlso .= $self->FormatText($value);  }
                else
                    {  $seeAlso .= $self->ConvertLink($value);  };
                };

            # Everything else will be skipped.
            }
        elsif ($unformattedText)
            {
            $unformattedText .= ' ' . $line;
            };

        $i++;
        };

    if ($unformattedText)
        {
        $$unformattedTextPtr .= $self->FormatText($unformattedText) . $unformattedTextCloser;
        $unformattedText = undef;
        };

    if ($params)
        {  $output .= '<h>Parameters</h><dl>' . $params . '</dl>';  };
    if ($returns)
        {  $output .= '<h>Returns</h><p>' . $returns . '</p>';  };
    if ($throws)
        {  $output .= '<h>Throws</h><dl>' . $throws . '</dl>';  };
    if ($since)
        {  $output .= '<h>Since</h><p>' . $since . '</p>';  };
    if ($version)
        {  $output .= '<h>Version</h><p>' . $version . '</p>';  };
    if ($deprecation)
        {  $output .= '<h>Deprecated</h><p>' . $deprecation . '</p>';  };
    if ($authors)
        {  $output .= '<h>Author</h><p>' . $authors . '</p>';  };
    if ($seeAlso)
        {  $output .= '<h>See Also</h><p>' . $seeAlso . '</p>';  };


    # Stage three: Build the parsed topic.

    my $summary = NaturalDocs::Parser->GetSummaryFromBody($output);

    push @$parsedTopics, NaturalDocs::Parser::ParsedTopic->New(undef, undef, undef, undef, undef, $summary,
                                                                                                $output, $lineNumber, undef);
    return 1;
    };


##
#   Translates any inline tags or HTML codes to <NDMarkup> and returns it.
#
sub FormatText #(string text, bool inParagraph)
    {
    my ($self, $text, $inParagraph) = @_;

    # JavaDoc Literal

    $text =~ s/\{\@(?:code|literal) ([^\}]*)\}/$self->ConvertAmpChars($1)/gie;


    # HTML

    $text =~ s/&lt;b&gt;(.*?)&lt;\/b&gt;/<b>$1<\/b>/gi;
    $text =~ s/&lt;i&gt;(.*?)&lt;\/i&gt;/<i>$1<\/i>/gi;
    $text =~ s/&lt;u&gt;(.*?)&lt;\/u&gt;/<u>$1<\/u>/gi;

    $text =~ s/&lt;code&gt;(.*?)&lt;\/code&gt;/$1/gi;

    $text =~ s/&lt;ul.*?&gt;(.*?)&lt;\/ul&gt;/<ul>$1<\/ul>/gi;
    $text =~ s/&lt;ol.*?&gt;(.*?)&lt;\/ol&gt;/<ul>$1<\/ul>/gi;
    $text =~ s/&lt;li.*?&gt;(.*?)&lt;\/li&gt;/<li>$1<\/li>/gi;

    $text =~ s/&lt;!--.*?--&gt;//gi;

    $text =~ s/&lt;\/p&gt;//gi;
    $text =~ s/^&lt;p&gt;//i;
    if ($inParagraph)
        {  $text =~ s/&lt;p&gt;/<\/p><p>/gi;  }
    else
        {  $text =~ s/&lt;p&gt;//gi;  };

    $text =~ s/&lt;a href=&quot;mailto:(.*?)&quot;.*?&gt;(.*?)&lt;\/a&gt;/$self->MakeEMailLink($1, $2)/gie;
    $text =~ s/&lt;a href=&quot;(.*?)&quot;.*?&gt;(.*?)&lt;\/a&gt;/$self->MakeLink($1, $2)/gie;

    $text =~ s/&amp;nbsp;/ /gi;
    $text =~ s/&amp;amp;/&amp;/gi;
    $text =~ s/&amp;gt;/&gt;/gi;
    $text =~ s/&amp;lt;/&lt;/gi;
    $text =~ s/&amp;quot;/&quot;/gi;



    # JavaDoc

    $text =~ s/\{\@inheritdoc\}//gi;
    $text =~ s/\{\@(?:linkplain|link|value) ([^\}]*)\}/$self->ConvertLink($1)/gie;

    return $text;
    };


sub ConvertAmpChars #(text)
    {
    my ($self, $text) = @_;

    $text =~ s/&/&amp;/g;
    $text =~ s/</&lt;/g;
    $text =~ s/>/&gt;/g;
    $text =~ s/"/&quot;/g;

    return $text;
    };

sub ConvertLink #(text)
    {
    my ($self, $text) = @_;

    $text =~ /^ *([a-z0-9\_\.\:\#]+(?:\([^\)]*\))?) *(.*)$/i;
    my ($target, $label) = ($1, $2);

    # Convert the anchor to part of the link, but remove it altogether if it's the beginning of the link.
    $target =~ s/^\#//;
    $target =~ s/\#/\./;

    $label =~ s/ +$//;

    if (!length $label)
        {  return '<link original="' . $target . '">' . $target . '</link>';  }
    else
        {  return '<link original="' . $label . ' (' . $target . ')" name="' . $label . '">' . $target . '</link>';  };
    };

sub MakeLink #(target, text)
    {
    my ($self, $target, $text) = @_;

    if (lc($target) eq lc($text))
        {  return '<url>' . $target . '</url>';  }
    else
        {  return '<url name="' . $text . '">' . $target . '</url>';  };
    };

sub MakeEMailLink #(target, text)
    {
    my ($self, $target, $text) = @_;

    if (lc($target) eq lc($text))
        {  return '<email>' . $target . '</email>';  }
    else
        {  return '<email name="' . $text . '">' . $target . '</email>';  };
    };


1;
