###############################################################################
#
#   Package: NaturalDocs::Topics
#
###############################################################################
#
#   The topic constants and functions to convert them to and from strings used throughout the script.  All constants are exported
#   by default.
#
###############################################################################

# This file is part of Natural Docs, which is Copyright © 2003-2004 Greg Valure
# Natural Docs is licensed under the GPL

use strict;
use integer;

package NaturalDocs::Topics;

use vars qw(@EXPORT @ISA);
require Exporter;
@ISA = qw(Exporter);

@EXPORT = ('TOPIC_CLASS', 'TOPIC_SECTION', 'TOPIC_FILE', 'TOPIC_GROUP', 'TOPIC_FUNCTION', 'TOPIC_VARIABLE',
                   'TOPIC_GENERIC', 'TOPIC_TYPE', 'TOPIC_CONSTANT', 'TOPIC_PROPERTY',

                   'TOPIC_CLASS_LIST', 'TOPIC_FILE_LIST', 'TOPIC_FUNCTION_LIST', 'TOPIC_VARIABLE_LIST',
                   'TOPIC_GENERIC_LIST', 'TOPIC_TYPE_LIST', 'TOPIC_CONSTANT_LIST', 'TOPIC_PROPERTY_LIST');



###############################################################################
# Group: Virtual Types
# These are only groups of constants, but should be treated like typedefs or enums.  Each one represents a distinct type and
# their values should only be one of their constants or undef.  All values are exported by default.

#
#   Note: Assumptions
#
#   - No constant here will ever be zero.
#   - All constants are exported by default.
#

#
#   Constants: TopicType
#
#   The type of a Natural Docs topic.
#
#       TOPIC_CLASS      - A class.  All topics until the next class or section become its members.
#       TOPIC_SECTION  - A main section of code or text.  Formats like a class but doesn't provide scope.  Also ends the
#                                    scope of a class.
#       TOPIC_FILE          - A file.  Is always referenced as a global, but does not end a class scope.
#       TOPIC_GROUP      - A subdivider for long lists.
#       TOPIC_FUNCTION - A function.  The code immediately afterwards will be used as the prototype if it matches the name.
#       TOPIC_VARIABLE  - A variable.  The code immediately afterwards will be used as the prototype if it matches the name.
#       TOPIC_PROPERTY - A property.  The code immediately afterwards will be used as the prototype if it matches the name.
#       TOPIC_GENERIC   - A generic topic.
#
#       TOPIC_CONSTANT - A constant.  Same as generic, but distinguished for indexing.
#       TOPIC_TYPE          - A type.  Same as generic, but distinguished for indexing.
#
#       TOPIC_CLASS_LIST        - A list of classes.  Will not have scope.
#       TOPIC_FILE_LIST            - A list of files.
#       TOPIC_FUNCTION_LIST  - A list of functions.  Will not have prototypes.
#       TOPIC_VARIABLE_LIST   - A list of variables.  Will not have prototypes.
#       TOPIC_PROPERTY_LIST  - A list of properties.  Will not have prototypes.
#       TOPIC_GENERIC_LIST    - A list of generic topics.
#
#       TOPIC_CONSTANT_LIST - A list of constants.
#       TOPIC_TYPE_LIST - A list of types.
#
#   Dependencies:
#
#       - <PreviousMenuState.nd> and <SymbolTable.nd> depend on these values all being able to fit into a UInt8, i.e. <= 255.
#       - Most of the variables below depend on the order of the values.
#
use constant TOPIC_CLASS => 1;
use constant TOPIC_SECTION => 2;
use constant TOPIC_FILE => 3;
use constant TOPIC_GROUP => 4;
use constant TOPIC_FUNCTION => 5;
use constant TOPIC_VARIABLE => 6;
use constant TOPIC_GENERIC => 7;
use constant TOPIC_TYPE => 8;
use constant TOPIC_CONSTANT => 9;
use constant TOPIC_PROPERTY => 10;

use constant TOPIC_LIST_BASE => 100;  # To accomodate for future expansion without changing the actual values.

use constant TOPIC_CLASS_LIST => (TOPIC_CLASS + TOPIC_LIST_BASE);
use constant TOPIC_FILE_LIST => (TOPIC_FILE + TOPIC_LIST_BASE);
use constant TOPIC_FUNCTION_LIST => (TOPIC_FUNCTION + TOPIC_LIST_BASE);
use constant TOPIC_VARIABLE_LIST => (TOPIC_VARIABLE + TOPIC_LIST_BASE);
use constant TOPIC_GENERIC_LIST => (TOPIC_GENERIC + TOPIC_LIST_BASE);
use constant TOPIC_TYPE_LIST => (TOPIC_TYPE + TOPIC_LIST_BASE);
use constant TOPIC_CONSTANT_LIST => (TOPIC_CONSTANT + TOPIC_LIST_BASE);
use constant TOPIC_PROPERTY_LIST => (TOPIC_PROPERTY + TOPIC_LIST_BASE);


###############################################################################
# Group: Variables

#
#   array: names
#
#   An array of the topic names.  Use the <TopicTypes> as indexes, except for list types.
#
my @names = ( undef, 'Class', 'Section', 'File', 'Group', 'Function', 'Variable', 'Generic', 'Type', 'Constant', 'Property' );
# The string order must match the constant values.

#
#   array: pluralNames
#
#   An array of the topic names, but plural.  Use the <TopicTypes> as indexes, except for list types.
#
my @pluralNames = ( undef, 'Classes', 'Sections', 'Files', 'Groups', 'Functions', 'Variables', 'Generics', 'Types', 'Constants',
                                'Properties' );
# The string order must match the constant values.  "Generics" is wierd, I know.

#
#   hash: constants
#
#   A hash where the keys are the names in all lowercase, and the values are the <TopicTypes>.  Note that this contains
#   every synonym used in the parser.  If the name is plural, it will be a list type.
#
my %constants = (

                            'class'  => TOPIC_CLASS,
                            'structure'  => TOPIC_CLASS,
                            'struct'  => TOPIC_CLASS,
                            'package'  => TOPIC_CLASS,
                            'namespace'  => TOPIC_CLASS,

                            'classes'  => TOPIC_CLASS_LIST,
                            'structures'  => TOPIC_CLASS_LIST,
                            'structs'  => TOPIC_CLASS_LIST,
                            'packages'  => TOPIC_CLASS_LIST,
                            'namespaces'  => TOPIC_CLASS_LIST,

                            'section'  => TOPIC_SECTION,
                            'title'  => TOPIC_SECTION,

                            'file'  => TOPIC_FILE,
                            'program'  => TOPIC_FILE,
                            'script'  => TOPIC_FILE,
                            'module'  => TOPIC_FILE,
                            'document'  => TOPIC_FILE,
                            'doc'  => TOPIC_FILE,
                            'header'  => TOPIC_FILE,

                            'files'  => TOPIC_FILE_LIST,
                            'programs'  => TOPIC_FILE_LIST,
                            'scripts'  => TOPIC_FILE_LIST,
                            'modules'  => TOPIC_FILE_LIST,
                            'documents'  => TOPIC_FILE_LIST,
                            'docs'  => TOPIC_FILE_LIST,
                            'headers'  => TOPIC_FILE_LIST,

                            'group'  => TOPIC_GROUP,

                            'function'  => TOPIC_FUNCTION,
                            'func'  => TOPIC_FUNCTION,
                            'procedure'  => TOPIC_FUNCTION,
                            'proc'  => TOPIC_FUNCTION,
                            'routine'  => TOPIC_FUNCTION,
                            'subroutine'  => TOPIC_FUNCTION,
                            'sub'  => TOPIC_FUNCTION,
                            'method'  => TOPIC_FUNCTION,
                            'callback'  => TOPIC_FUNCTION,
                            'constructor'  => TOPIC_FUNCTION,
                            'destructor'  => TOPIC_FUNCTION,

                            'functions'  => TOPIC_FUNCTION_LIST,
                            'funcs'  => TOPIC_FUNCTION_LIST,
                            'procedures'  => TOPIC_FUNCTION_LIST,
                            'procs'  => TOPIC_FUNCTION_LIST,
                            'routines'  => TOPIC_FUNCTION_LIST,
                            'subroutines'  => TOPIC_FUNCTION_LIST,
                            'subs'  => TOPIC_FUNCTION_LIST,
                            'methods'  => TOPIC_FUNCTION_LIST,
                            'callbacks'  => TOPIC_FUNCTION_LIST,
                            'constructors'  => TOPIC_FUNCTION_LIST,
                            'destructors'  => TOPIC_FUNCTION_LIST,

                            'variable'  => TOPIC_VARIABLE,
                            'var'  => TOPIC_VARIABLE,
                            'integer'  => TOPIC_VARIABLE,
                            'int'  => TOPIC_VARIABLE,
                            'uint'  => TOPIC_VARIABLE,
                            'long'  => TOPIC_VARIABLE,
                            'ulong'  => TOPIC_VARIABLE,
                            'short'  => TOPIC_VARIABLE,
                            'ushort'  => TOPIC_VARIABLE,
                            'byte'  => TOPIC_VARIABLE,
                            'ubyte'  => TOPIC_VARIABLE,
                            'sbyte'  => TOPIC_VARIABLE,
                            'float'  => TOPIC_VARIABLE,
                            'double'  => TOPIC_VARIABLE,
                            'real'  => TOPIC_VARIABLE,
                            'decimal'  => TOPIC_VARIABLE,
                            'scalar'  => TOPIC_VARIABLE,
                            'array'  => TOPIC_VARIABLE,
                            'arrayref'  => TOPIC_VARIABLE,
                            'hash'  => TOPIC_VARIABLE,
                            'hashref'  => TOPIC_VARIABLE,
                            'bool'  => TOPIC_VARIABLE,
                            'boolean'  => TOPIC_VARIABLE,
                            'flag'  => TOPIC_VARIABLE,
                            'bit'  => TOPIC_VARIABLE,
                            'bitfield'  => TOPIC_VARIABLE,
                            'field'  => TOPIC_VARIABLE,
                            'pointer'  => TOPIC_VARIABLE,
                            'ptr'  => TOPIC_VARIABLE,
                            'reference'  => TOPIC_VARIABLE,
                            'ref'  => TOPIC_VARIABLE,
                            'object'  => TOPIC_VARIABLE,
                            'obj'  => TOPIC_VARIABLE,
                            'character'  => TOPIC_VARIABLE,
                            'wcharacter'  => TOPIC_VARIABLE,
                            'char'  => TOPIC_VARIABLE,
                            'wchar'  => TOPIC_VARIABLE,
                            'string'  => TOPIC_VARIABLE,
                            'wstring'  => TOPIC_VARIABLE,
                            'str'  => TOPIC_VARIABLE,
                            'wstr'  => TOPIC_VARIABLE,
                            'handle'  => TOPIC_VARIABLE,

                            'variables'  => TOPIC_VARIABLE_LIST,
                            'vars'  => TOPIC_VARIABLE_LIST,
                            'integers'  => TOPIC_VARIABLE_LIST,
                            'ints'  => TOPIC_VARIABLE_LIST,
                            'uints'  => TOPIC_VARIABLE_LIST,
                            'longs'  => TOPIC_VARIABLE_LIST,
                            'ulongs'  => TOPIC_VARIABLE_LIST,
                            'shorts'  => TOPIC_VARIABLE_LIST,
                            'ushorts'  => TOPIC_VARIABLE_LIST,
                            'bytes'  => TOPIC_VARIABLE_LIST,
                            'ubytes'  => TOPIC_VARIABLE_LIST,
                            'sbytes'  => TOPIC_VARIABLE_LIST,
                            'floats'  => TOPIC_VARIABLE_LIST,
                            'doubles'  => TOPIC_VARIABLE_LIST,
                            'reals'  => TOPIC_VARIABLE_LIST,
                            'decimals'  => TOPIC_VARIABLE_LIST,
                            'arrays'  => TOPIC_VARIABLE_LIST,
                            'arrayrefs'  => TOPIC_VARIABLE_LIST,
                            'hashes'  => TOPIC_VARIABLE_LIST,
                            'hashrefs'  => TOPIC_VARIABLE_LIST,
                            'bools'  => TOPIC_VARIABLE_LIST,
                            'booleans'  => TOPIC_VARIABLE_LIST,
                            'flags'  => TOPIC_VARIABLE_LIST,
                            'bits'  => TOPIC_VARIABLE_LIST,
                            'bitfields'  => TOPIC_VARIABLE_LIST,
                            'fields'  => TOPIC_VARIABLE_LIST,
                            'pointers'  => TOPIC_VARIABLE_LIST,
                            'ptrs'  => TOPIC_VARIABLE_LIST,
                            'references'  => TOPIC_VARIABLE_LIST,
                            'refs'  => TOPIC_VARIABLE_LIST,
                            'objects'  => TOPIC_VARIABLE_LIST,
                            'objs'  => TOPIC_VARIABLE_LIST,
                            'characters'  => TOPIC_VARIABLE_LIST,
                            'wcharacters'  => TOPIC_VARIABLE_LIST,
                            'chars'  => TOPIC_VARIABLE_LIST,
                            'wchars'  => TOPIC_VARIABLE_LIST,
                            'strings'  => TOPIC_VARIABLE_LIST,
                            'wstrings'  => TOPIC_VARIABLE_LIST,
                            'strs'  => TOPIC_VARIABLE_LIST,
                            'wstrs'  => TOPIC_VARIABLE_LIST,
                            'handles'  => TOPIC_VARIABLE_LIST,

                            'property'  => TOPIC_PROPERTY,
                            'prop'  => TOPIC_PROPERTY,

                            'properties'  => TOPIC_PROPERTY_LIST,
                            'props'  => TOPIC_PROPERTY_LIST,

                            'topic'  => TOPIC_GENERIC,
                            'about'  => TOPIC_GENERIC,
                            'note'  => TOPIC_GENERIC,

                            'item'  => TOPIC_GENERIC,
                            'option'  => TOPIC_GENERIC,
                            'symbol'  => TOPIC_GENERIC,
                            'sym'  => TOPIC_GENERIC,
                            'definition'  => TOPIC_GENERIC,
                            'define'  => TOPIC_GENERIC,
                            'def'  => TOPIC_GENERIC,
                            'macro'  => TOPIC_GENERIC,
                            'format'  => TOPIC_GENERIC,

                            'list'  => TOPIC_GENERIC_LIST,

                            'items'  => TOPIC_GENERIC_LIST,
                            'options'  => TOPIC_GENERIC_LIST,
                            'symbols'  => TOPIC_GENERIC_LIST,
                            'syms'  => TOPIC_GENERIC_LIST,
                            'definitions'  => TOPIC_GENERIC_LIST,
                            'defines'  => TOPIC_GENERIC_LIST,
                            'defs'  => TOPIC_GENERIC_LIST,
                            'macros'  => TOPIC_GENERIC_LIST,
                            'formats'  => TOPIC_GENERIC_LIST,

                            'constant'  => TOPIC_CONSTANT,
                            'const'  => TOPIC_CONSTANT,

                            'constants'  => TOPIC_CONSTANT_LIST,
                            'consts'  => TOPIC_CONSTANT_LIST,
                            'enumeration'  => TOPIC_CONSTANT_LIST,
                            'enum'  => TOPIC_CONSTANT_LIST,

                            'type'  => TOPIC_TYPE,
                            'typedef'  => TOPIC_TYPE,

                            'types'  => TOPIC_TYPE_LIST,
                            'typedefs'  => TOPIC_TYPE_LIST

             );

#
#   hash: indexable
#
#   An existence hash of the <TopicTypes> that should be indexed.
#
my %indexable = ( TOPIC_FUNCTION() => 1,
                             TOPIC_CLASS() => 1,
                             TOPIC_FILE() => 1,
                             TOPIC_VARIABLE() => 1,
                             TOPIC_PROPERTY() => 1,
                             TOPIC_TYPE() => 1,
                             TOPIC_CONSTANT() => 1 );

#
#   hash: basicAutoGroupable
#
#   An existence hash of the <TopicTypes> that auto-groups should be created for when using <AUTOGROUP_BASIC>.
#
my %basicAutoGroupable = ( TOPIC_FUNCTION() => 1,
                                           TOPIC_VARIABLE() => 1,
                                           TOPIC_PROPERTY() => 1 );

#
#   hash: fullAutoGroupable
#
#   An existence hash of the <TopicTypes> that auto-groups should be created for when using <AUTOGROUP_FULL> *in
#   addition to* those found in <basicAutoGroupable>.
#
my %fullAutoGroupable = ( TOPIC_FILE() => 1,
                                        TOPIC_TYPE() => 1,
                                        TOPIC_CONSTANT() => 1 );



###############################################################################
# Group: Functions

#
#   Function: IsList
#
#   Returns whether the <TopicType> is a list topic.
#
sub IsList #(topic)
    {
    my ($self, $topic) = @_;
    return ($topic >= TOPIC_LIST_BASE);
    };


#
#   Function: IsListOf
#
#   Returns what <TopicType> the list <TopicType> is of.
#
sub IsListOf #(topic)
    {
    my ($self, $topic) = @_;
    return ($topic - TOPIC_LIST_BASE);
    };


#
#   Function: IsIndexable
#
#   Returns whether the <TopicType> should be indexed.
#
sub IsIndexable #(topic)
    {
    my ($self, $topic) = @_;
    return $indexable{$topic};
    };


#
#   Function: IsAutoGroupable
#
#   Returns whether the <TopicType> should have auto-groups created for it.
#
sub IsAutoGroupable #(topic)
    {
    my ($self, $topic) = @_;

    my $level = NaturalDocs::Settings->AutoGroupLevel();

    if ($level == ::AUTOGROUP_BASIC())
        {
        return $basicAutoGroupable{$topic};
        }
    elsif ($level == ::AUTOGROUP_FULL())
        {
        return (exists $basicAutoGroupable{$topic} || exists $fullAutoGroupable{$topic});
        }
    else
        {  return undef;  };
    };


#
#   Function: AllIndexable
#
#   Returns an array of all possible indexable <TopicTypes>.
#
sub AllIndexable
    {
    my ($self) = @_;
    return keys %indexable;
    };


#
#   Function: NameOf
#
#   Returns the name string of the passed <TopicType>.
#
sub NameOf #(topic)
    {
    my ($self, $topic) = @_;

    if ($self->IsList($topic))
        {  return $names[ $self->IsListOf($topic) ] . 'List';  }
    else
        {  return $names[ $topic ];  };
    };

#
#   Function: PluralNameOf
#
#   Returns the plural name string of the passed <TopicType>.  Note that if you pass the plural name back to <ConstantOf()>,
#   you will get a list <TopicType> instead of the original one.
#
sub PluralNameOf #(topic)
    {
    my ($self, $topic) = @_;

    if ($self->IsList($topic))
        {  return $names[ $self->IsListOf($topic) ] . 'Lists';  }
    else
        {  return $pluralNames[ $topic ];  };
    };

#
#   Function: ConstantOf
#
#   Returns the <TopicType> associated with the string, or undef if none.  This supports every Natural Docs synonym the parser
#   supports.  Note that if the string is plural, it will return a list type.  If that's not desired, use <BaseConstantOf()> instead.
#
sub ConstantOf #(string)
    {
    my ($self, $string) = @_;
    return $constants{ lc($string) };
    };

#
#   Function: BaseConstantOf
#
#   Returns the <TopicType> associated with the string, or undef if none.  The result will never be a list topic.  This supports
#   every Natural Docs synonym the parser supports.
#
sub BaseConstantOf #(string)
    {
    my ($self, $string) = @_;

    my $topic = $self->ConstantOf($string);

    if ($self->IsList($topic))
        {  return $self->IsListOf($topic);  }
    else
        {  return $topic;  };
    };


1;
