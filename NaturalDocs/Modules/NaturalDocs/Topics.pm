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

# This file is part of Natural Docs, which is Copyright © 2003 Greg Valure
# Natural Docs is licensed under the GPL

use strict;
use integer;

package NaturalDocs::Topics;

use vars qw(@EXPORT @ISA);
require Exporter;
@ISA = qw(Exporter);

@EXPORT = ('TOPIC_CLASS', 'TOPIC_SECTION', 'TOPIC_FILE', 'TOPIC_GROUP', 'TOPIC_FUNCTION', 'TOPIC_VARIABLE',
                   'TOPIC_GENERIC', 'TOPIC_TYPE', 'TOPIC_CONSTANT',

                   'TOPIC_CLASS_LIST', 'TOPIC_FILE_LIST', 'TOPIC_FUNCTION_LIST', 'TOPIC_VARIABLE_LIST',
                   'TOPIC_GENERIC_LIST', 'TOPIC_TYPE_LIST', 'TOPIC_CONSTANT_LIST');



###############################################################################
# Group: Constants
# All are exported by default.

#
#   Note: Assumptions
#
#   No constant here will ever be zero.
#

#
#   Constants: Topic Types
#
#   Constants representing all the types of Natural Docs sections.
#
#       TOPIC_CLASS      - A class.  All topics until the next class or section become its members.
#       TOPIC_SECTION  - A main section of code or text.  Formats like a class but doesn't provide scope.  Also ends the
#                                    scope of a class.
#       TOPIC_FILE          - A file.  Is always referenced as a global, but does not end a class scope.
#       TOPIC_GROUP      - A subdivider for long lists.
#       TOPIC_FUNCTION - A function.  The code immediately afterwards will be used as the prototype if it matches the name.
#       TOPIC_VARIABLE  - A variable.  The code immediately afterwards will be used as the prototype if it matches the name.
#       TOPIC_GENERIC   - A generic topic.
#
#       TOPIC_CONSTANT - A constant.  Same as generic, but distinguished for indexing.
#       TOPIC_TYPE          - A type.  Same as generic, but distinguished for indexing.
#
#       TOPIC_CLASS_LIST        - A list of classes.  Will not have scope.
#       TOPIC_FILE_LIST            - A list of files.
#       TOPIC_FUNCTION_LIST  - A list of functions.  Will not have prototypes.
#       TOPIC_VARIABLE_LIST   - A list of variables.  Will not have prototypes.
#       TOPIC_GENERIC_LIST    - A list of generic topics.
#
#       TOPIC_CONSTANT_LIST - A list of constants.
#       TOPIC_TYPE_LIST - A list of types.
#
#   Dependency:
#
#       <PreviousMenuState.nd> depends on these values all being able to fit into a UInt8, i.e. <= 255.
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

use constant TOPIC_LIST_BASE => 100;  # To accomodate for future expansion without changing the actual values.

use constant TOPIC_CLASS_LIST => (TOPIC_CLASS + TOPIC_LIST_BASE);
use constant TOPIC_FILE_LIST => (TOPIC_FILE + TOPIC_LIST_BASE);
use constant TOPIC_FUNCTION_LIST => (TOPIC_FUNCTION + TOPIC_LIST_BASE);
use constant TOPIC_VARIABLE_LIST => (TOPIC_VARIABLE + TOPIC_LIST_BASE);
use constant TOPIC_GENERIC_LIST => (TOPIC_GENERIC + TOPIC_LIST_BASE);
use constant TOPIC_TYPE_LIST => (TOPIC_TYPE + TOPIC_LIST_BASE);
use constant TOPIC_CONSTANT_LIST => (TOPIC_CONSTANT + TOPIC_LIST_BASE);


###############################################################################
# Group: Variables

#
#   array: names
#
#   An array of the topic names.  Use the <Topic Types> as an index into it, except for list types.
#
my @names = ( undef, 'Class', 'Section', 'File', 'Group', 'Function', 'Variable', 'Generic', 'Type', 'Constant' );
# The string order must match the constant values.

#
#   array: pluralNames
#
#   An array of the topic names, but plural.  Use the <Topic Types> as an index into it, except for list types.
#
my @pluralNames = ( undef, 'Classes', 'Sections', 'Files', 'Groups', 'Functions', 'Variables', 'Generics', 'Types', 'Constants' );
# The string order must match the constant values.  "Generics" is wierd, I know.

#
#   hash: constants
#
#   A hash where the keys are the names in all lowercase, and the values are the <Topic Types>.  Note that this contains
#   every synonym used in the parser.  If the name is plural, it will be a list type.
#
my %constants = (

                            'class'          => TOPIC_CLASS,
                            'structure'    => TOPIC_CLASS,
                            'struct'         => TOPIC_CLASS,
                            'package'     => TOPIC_CLASS,
                            'namespace' => TOPIC_CLASS,

                            'classes'        => TOPIC_CLASS_LIST,
                            'structures'    => TOPIC_CLASS_LIST,
                            'structs'         => TOPIC_CLASS_LIST,
                            'packages'     => TOPIC_CLASS_LIST,
                            'namespaces' => TOPIC_CLASS_LIST,

                            'section'      => TOPIC_SECTION,
                            'title'           => TOPIC_SECTION,

                            'file'            => TOPIC_FILE,
                            'program'    => TOPIC_FILE,
                            'script'         => TOPIC_FILE,
                            'module'      => TOPIC_FILE,
                            'document'  => TOPIC_FILE,
                            'doc'           => TOPIC_FILE,
                            'header'      => TOPIC_FILE,

                            'files'            => TOPIC_FILE_LIST,
                            'programs'    => TOPIC_FILE_LIST,
                            'scripts'         => TOPIC_FILE_LIST,
                            'modules'      => TOPIC_FILE_LIST,
                            'documents'  => TOPIC_FILE_LIST,
                            'docs'           => TOPIC_FILE_LIST,
                            'headers'      => TOPIC_FILE_LIST,

                            'group'        => TOPIC_GROUP,

                            'function'     => TOPIC_FUNCTION,
                            'func'          => TOPIC_FUNCTION,
                            'procedure'  => TOPIC_FUNCTION,
                            'proc'          => TOPIC_FUNCTION,
                            'routine'      => TOPIC_FUNCTION,
                            'subroutine' => TOPIC_FUNCTION,
                            'sub'           => TOPIC_FUNCTION,
                            'method'     => TOPIC_FUNCTION,
                            'callback'     => TOPIC_FUNCTION,

                            'functions'     => TOPIC_FUNCTION_LIST,
                            'funcs'          => TOPIC_FUNCTION_LIST,
                            'procedures'  => TOPIC_FUNCTION_LIST,
                            'procs'          => TOPIC_FUNCTION_LIST,
                            'routines'      => TOPIC_FUNCTION_LIST,
                            'subroutines' => TOPIC_FUNCTION_LIST,
                            'subs'           => TOPIC_FUNCTION_LIST,
                            'methods'     => TOPIC_FUNCTION_LIST,
                            'callbacks'     => TOPIC_FUNCTION_LIST,

                            'variable'    => TOPIC_VARIABLE,
                            'var'           => TOPIC_VARIABLE,
                            'integer'     => TOPIC_VARIABLE,
                            'int'           => TOPIC_VARIABLE,
                            'float'        => TOPIC_VARIABLE,
                            'long'        => TOPIC_VARIABLE,
                            'double'     => TOPIC_VARIABLE,
                            'scalar'      => TOPIC_VARIABLE,
                            'array'       => TOPIC_VARIABLE,
                            'arrayref'   => TOPIC_VARIABLE,
                            'hash'        => TOPIC_VARIABLE,
                            'hashref'    => TOPIC_VARIABLE,
                            'bool'         => TOPIC_VARIABLE,
                            'boolean'    => TOPIC_VARIABLE,
                            'flag'          => TOPIC_VARIABLE,
                            'bit'            => TOPIC_VARIABLE,
                            'bitfield'      => TOPIC_VARIABLE,
                            'field'         => TOPIC_VARIABLE,
                            'pointer'     => TOPIC_VARIABLE,
                            'ptr'           => TOPIC_VARIABLE,
                            'reference' => TOPIC_VARIABLE,
                            'ref'           => TOPIC_VARIABLE,
                            'object'      => TOPIC_VARIABLE,
                            'obj'           => TOPIC_VARIABLE,
                            'character'  => TOPIC_VARIABLE,
                            'char'         => TOPIC_VARIABLE,
                            'string'       => TOPIC_VARIABLE,
                            'str'           => TOPIC_VARIABLE,
                            'property'  => TOPIC_VARIABLE,
                            'prop'        => TOPIC_VARIABLE,
                            'handle'     => TOPIC_VARIABLE,

                            'variables'   => TOPIC_VARIABLE_LIST,
                            'vars'          => TOPIC_VARIABLE_LIST,
                            'integers'    => TOPIC_VARIABLE_LIST,
                            'ints'          => TOPIC_VARIABLE_LIST,
                            'floats'       => TOPIC_VARIABLE_LIST,
                            'longs'       => TOPIC_VARIABLE_LIST,
                            'doubles'    => TOPIC_VARIABLE_LIST,
                            'scalars'     => TOPIC_VARIABLE_LIST,
                            'arrays'      => TOPIC_VARIABLE_LIST,
                            'arrayrefs'  => TOPIC_VARIABLE_LIST,
                            'hashes'      => TOPIC_VARIABLE_LIST,
                            'hashrefs'   => TOPIC_VARIABLE_LIST,
                            'bools'        => TOPIC_VARIABLE_LIST,
                            'booleans'   => TOPIC_VARIABLE_LIST,
                            'flags'         => TOPIC_VARIABLE_LIST,
                            'bits'           => TOPIC_VARIABLE_LIST,
                            'bitfields'     => TOPIC_VARIABLE_LIST,
                            'fields'        => TOPIC_VARIABLE_LIST,
                            'pointers'    => TOPIC_VARIABLE_LIST,
                            'ptrs'          => TOPIC_VARIABLE_LIST,
                            'references'=> TOPIC_VARIABLE_LIST,
                            'refs'          => TOPIC_VARIABLE_LIST,
                            'objects'     => TOPIC_VARIABLE_LIST,
                            'objs'          => TOPIC_VARIABLE_LIST,
                            'characters' => TOPIC_VARIABLE_LIST,
                            'chars'        => TOPIC_VARIABLE_LIST,
                            'strings'      => TOPIC_VARIABLE_LIST,
                            'strs'          => TOPIC_VARIABLE_LIST,
                            'properties' => TOPIC_VARIABLE_LIST,
                            'props'       => TOPIC_VARIABLE_LIST,
                            'handles'    => TOPIC_VARIABLE_LIST,

                            'topic'        => TOPIC_GENERIC,
                            'about'       => TOPIC_GENERIC,
                            'note'         => TOPIC_GENERIC,

                            'item'         => TOPIC_GENERIC,
                            'option'      => TOPIC_GENERIC,
                            'symbol'     => TOPIC_GENERIC,
                            'sym'         => TOPIC_GENERIC,
                            'definition'   => TOPIC_GENERIC,
                            'define'       => TOPIC_GENERIC,
                            'def'           => TOPIC_GENERIC,
                            'macro'      => TOPIC_GENERIC,
                            'format'      => TOPIC_GENERIC,

                            'list'                => TOPIC_GENERIC_LIST,

                            'items'        => TOPIC_GENERIC_LIST,
                            'options'      => TOPIC_GENERIC_LIST,
                            'symbols'     => TOPIC_GENERIC_LIST,
                            'syms'         => TOPIC_GENERIC_LIST,
                            'definitions'   => TOPIC_GENERIC_LIST,
                            'defines'       => TOPIC_GENERIC_LIST,
                            'defs'           => TOPIC_GENERIC_LIST,
                            'macros'      => TOPIC_GENERIC_LIST,
                            'formats'      => TOPIC_GENERIC_LIST,

                            'constant'   => TOPIC_CONSTANT,
                            'const'       => TOPIC_CONSTANT,

                            'constants'   => TOPIC_CONSTANT_LIST,
                            'consts'       => TOPIC_CONSTANT_LIST,
                            'enumeration'  => TOPIC_CONSTANT_LIST,
                            'enum'            => TOPIC_CONSTANT_LIST,

                            'type'         => TOPIC_TYPE,
                            'typedef'    => TOPIC_TYPE,

                            'types'         => TOPIC_TYPE_LIST,
                            'typedefs'    => TOPIC_TYPE_LIST

             );

#
#   hash: indexable
#
#   An existence hash of the <Topic Types> that should be indexed.
#
my %indexable = ( TOPIC_FUNCTION() => 1,
                             TOPIC_CLASS() => 1,
                             TOPIC_FILE() => 1,
                             TOPIC_VARIABLE() => 1,
                             TOPIC_TYPE() => 1,
                             TOPIC_CONSTANT() => 1 );



###############################################################################
# Group: Functions

#
#   Function: IsList
#
#   Returns whether the topic is a list topic.
#
sub IsList #(topic)
    {
    my ($self, $topic) = @_;
    return ($topic >= TOPIC_LIST_BASE);
    };

#
#   Function: IsListOf
#
#   Returns what type the list topic is a list of.  Assumes the topic is a list topic.
#
sub IsListOf #(topic)
    {
    my ($self, $topic) = @_;
    return ($topic - TOPIC_LIST_BASE);
    };


#
#   Function: IsIndexable
#
#   Returns whether the topic should be indexed.
#
sub IsIndexable #(topic)
    {
    my ($self, $topic) = @_;
    return $indexable{$topic};
    };


#
#   Function: AllIndexable
#
#   Returns an array of all possible indexable <Topic Types>.
#
sub AllIndexable
    {
    my ($self) = @_;
    return keys %indexable;
    };


#
#   Function: NameOf
#
#   Returns the name string of the passed constant.
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
#   Returns the plural name string of the passed constant.  Do *not* ever pass the plural name back to <ConstantOf()> because
#   plural list topic names will return undef, and plural non-list topic names will return a list topic.
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
#   Returns the <Topic Types> associated with the string, or undef if none.  This supports every Natural Docs synonym the parser
#   supports.  Note that if the string is plural, it will return a list type.  If that's not desired, use <NonListConstantOf()> instead.
#
sub ConstantOf #(string)
    {
    my ($self, $string) = @_;
    return $constants{ lc($string) };
    };

#
#   Function: NonListConstantOf
#
#   Returns the <Topic Types> associated with the string, or undef if none.  If the result is a list topic, it runs it through
#   <IsListOf()> before returning it.  This supports every Natural Docs synonym the parser supports.
#
sub NonListConstantOf #(string)
    {
    my ($self, $string) = @_;

    my $topic = $self->ConstantOf($string);

    if ($self->IsList($topic))
        {  return $self->IsListOf($topic);  }
    else
        {  return $topic;  };
    };


1;
