###############################################################################
#
#   Package: NaturalDocs::Parser::ParsedTopic
#
###############################################################################
#
#   A class for parsed topics of source files.  Also encompasses some of the <TopicType>-specific behavior.
#
#
#   Topic: Type-Specific Behavior
#
#   TOPIC_CLASS:
#
#       - <Symbol()> will be generated from both the title and the package passed to <New()>.
#       - <Package()> will be generated from both the title and the package passed to <New()>, not just the package.
#
#   TOPIC_FILE:
#
#       - <Symbol()> will be generated from the title only, guaranteeing that it's global.
#       - <Package()> will return the package passed to <New()>, so it will still appear as part of the package when iterating
#         through the topics.  Also so its body will have the package as its scope when resolving links.
#
#   Everything else:
#
#       - <Symbol()> will be generated from both the title and the package.
#       - <Package()> will be generated from the package passed to <New()> only.  Any separators found in the title will not
#         be reflected here.
#
###############################################################################

# This file is part of Natural Docs, which is Copyright © 2003-2004 Greg Valure
# Natural Docs is licensed under the GPL

use strict;
use integer;

package NaturalDocs::Parser::ParsedTopic;


###############################################################################
# Group: Implementation

#
#   Constants: Members
#
#   The object is a blessed arrayref with the following indexes.
#
#       TYPE           - The <TopicType>.
#       TITLE          - The title of the topic.
#       PACKAGE    - The package <SymbolString> the topic appears in, or undef if none.
#       USING         - An arrayref of additional package <SymbolStrings> available to the topic via "using" statements, or undef if
#                           none.
#       PROTOTYPE - The prototype, if it exists and is applicable.
#       SUMMARY    - The summary, if it exists.
#       BODY          - The body of the topic, formatted in <NDMarkup>.  Some topics may not have bodies, and if not, this
#                           will be undef.
#       LINE_NUMBER  - The line number the topic appears at in the file.
#       EXPORTED  - If set, a second, global topic should also be defined to forward to this one.
#       EXPORTED_LIST  - If the <TopicType> is a list, a hashref of the symbols in that list that should be exported.  Undef if
#                                   none or not applicable.
#
use NaturalDocs::DefineMembers 'TYPE', 'TITLE', 'PACKAGE', 'USING', 'PROTOTYPE', 'SUMMARY', 'BODY',
                                                 'LINE_NUMBER', 'EXPORTED', 'EXPORTED_LIST';
# DEPENDENCY: New() depends on the order of these constants, and that this class is not inheriting any members.


###############################################################################
# Group: Functions

#
#   Function: New
#
#   Creates a new object.
#
#   Parameters:
#
#       type          - The <TopicType>.
#       title           - The title of the topic.
#       package    - The package <SymbolString> the topic appears in, or undef if none.
#       using         - An arrayref of additional package <SymbolStrings> available to the topic via "using" statements, or undef if none.
#       prototype   - The prototype, if it exists and is applicable.  Otherwise set to undef.
#       summary   - The summary of the topic, if any.
#       body          - The body of the topic, formatted in <NDMarkup>.  May be undef, as some topics may not have bodies.
#       lineNumber - The line number the topic appears at in the file.
#
#   Returns:
#
#       The new object.
#
sub New #(type, title, package, using, prototype, summary, body, lineNumber)
    {
    # DEPENDENCY: This depends on the order of the parameter list being the same as the constants, and that there are no
    # members inherited from a base class.

    my $package = shift;

    my $object = [ @_, undef, undef ];  # for EXPORTED, EXPORTED_LIST
    bless $object, $package;

    return $object;
    };


# Function: Type
# Returns the <TopicType>.
sub Type
    {  return $_[0]->[TYPE];  };

# Function: SetType
# Replaces the <TopicType>.
sub SetType #(type)
    {  $_[0]->[TYPE] = $_[1];  };

# Function: Title
# Returns the title of the topic.
sub Title
    {  return $_[0]->[TITLE];  };

#
#   Function: Symbol
#
#   Returns the <SymbolString> defined by the topic.  It is fully resolved and does _not_ need to be joined with <Package()>.
#
#   Type-Specific Behavior:
#
#       - <TOPIC_FILE> symbols will always be generated from the title only, so that they are always global.
#       - Everything else's smybols will be generated from the title and the package passed to <New()>.
#
sub Symbol
    {
    my ($self) = @_;

    my $titleSymbol = NaturalDocs::SymbolString->FromText($self->[TITLE]);

    if ($self->Type() == ::TOPIC_FILE())
        {  return $titleSymbol;  }
    else
        {
        return NaturalDocs::SymbolString->Join( $self->[PACKAGE], $titleSymbol );
        };
    };


#
#   Function: Package
#
#   Returns the package <SymbolString> that the topic appears in.
#
#   Type-Specific Behavior:
#
#       - <TOPIC_CLASS'> package will be generated from both the title and the package passed to <New()>, not just the package.
#       - <TOPIC_FILE's> package will be the one passed to <New()>, even though it isn't part of it's <Symbol()>.
#       - Everything else's package will be what was passed to <New()>, even if the title has separator symbols in it.
#
sub Package
    {
    my ($self) = @_;

    if ($self->Type() == ::TOPIC_CLASS())
        {  return $self->Symbol();  }
    else
        {  return $self->[PACKAGE];  };
    };


# Function: SetPackage
# Replaces the package the topic appears in.  This will behave the same way as the package parameter in <New()>.  Later calls
# to <Package()> will still be generated according to the <Type-Specific Behavior>.
sub SetPackage #(package)
    {  $_[0]->[PACKAGE] = $_[1];  };

# Function: Using
# Returns an arrayref of additional scope <SymbolStrings> available to the topic via "using" statements, or undef if none.
sub Using
    {  return $_[0]->[USING];  };

# Function: SetUsing
# Replaces the using arrayref of sope <SymbolStrings>.
sub SetUsing #(using)
    {  $_[0]->[USING] = $_[1];  };

# Function: Prototype
# Returns the prototype if one is defined.  Will be undef otherwise.
sub Prototype
    {  return $_[0]->[PROTOTYPE];  };

# Function: SetPrototype
# Replaces the function or variable prototype.
sub SetPrototype #(prototype)
    {  $_[0]->[PROTOTYPE] = $_[1];  };

# Function: Summary
# Returns the topic summary, if it exists, formatted in <NDMarkup>.
sub Summary
    {  return $_[0]->[SUMMARY];  };

# Function: Body
# Returns the topic's body, formatted in <NDMarkup>.  May be undef.
sub Body
    {  return $_[0]->[BODY];  };

# Function: SetBody
# Replaces the topic's body, formatted in <NDMarkup>.  May be undef.
sub SetBody #(body)
    {
    my ($self, $body) = @_;
    $self->[BODY] = $body;
    };

# Function: LineNumber
# Returns the line the topic appears at in the file.
sub LineNumber
    {  return $_[0]->[LINE_NUMBER];  };

# Function: IsExported
# Returns whether a second, global version of the topic should be defined to forward to this one.
sub IsExported
    {  return $_[0]->[EXPORTED];  };

# Function: SetIsExported
# Sets whether the topic should have a second, global version to forward to this one.
sub SetIsExported #(isExported)
    {  $_[0]->[EXPORTED] = $_[1];  };

# Function: IsListSymbolExported
# Returns whether the passed list item is exported, provided the <TopicType> is a list type.
sub IsListSymbolExported #(symbol)
    {
    my ($self, $symbol) = @_;

    if (defined $self->[EXPORTED_LIST])
        {  return exists $self->[EXPORTED_LIST]->{$symbol};  }
    else
        {  return undef;  };
    };

# Function: AddExportedListSymbol
# Adds a list item to be exported, provided the <TopicType> is a list type.
sub AddExportedListSymbol #(symbol)
    {
    my ($self, $symbol) = @_;

    if (!defined $self->[EXPORTED_LIST])
        {  $self->[EXPORTED_LIST] = { };  };

    $self->[EXPORTED_LIST]->{$symbol} = 1;
    };

1;
