###############################################################################
#
#   Package: NaturalDocs::Support::Enumerator
#
###############################################################################
#
#   An object that assigns numbers to data elements so that the numbers can be passed around instead of copies of the actual
#   data.  Can convert data to numbers and back again.
#
###############################################################################

use strict;
use integer;

package NaturalDocs::Support::Enumerator;


###############################################################################
# Group: Implementation

#
#   About: Members
#
#   The objects are implemented as blessed arrayrefs.  Index zero is a hashref with the keys being the data and the values
#   being their numbers.  Index one and greater are the data elements themselves so that they may be looked up by number.
#   Obviously the class will never assign zero to an element.
#


###############################################################################
# Group: Functions

#
#   Function: New
#
#   Returns a new object.
#
sub New
    {
    my $object = [ { } ];
    bless $object;

    return $object;
    };


#
#   Function: MakeNumber
#
#   Assigns and returns a number for the data element.  Created numbers will always start at one and increment
#   upwards.
#
sub MakeNumber #(data)
    {
    my ($self, $data) = @_;

    my $hash = $self->Hash();
    my $number = $hash->{$data};

    if (!defined $number)
        {
        $number = scalar @$self;
        push @$self, $data;
        $hash->{$data} = $number;
        };

    return $number;
    };


#
#   Function: ToData
#
#   Returns a number's data, or undef if none.
#
sub ToData #(number)
    {
    my ($self, $number) = @_;

    if ($number >= scalar @$self)
        {  return undef;  }
    else
        {  return $self->[$number];  };
    };


#
#   Function: ToNumber
#
#   Returns a data element's number, or undef if none
#
sub ToNumber #(data)
    {
    my ($self, $data) = @_;

    return $self->Hash()->{$data};
    };


#
#   Function: DeleteNumber
#
#   Deletes the entry of a number.  This will *not* change any other numbers, nor will the number ever be reused.  If you later
#   attempt to retrieve the data for this entry, it will be undef.
#
#   Parameters:
#
#       number - The number of the data entry to delete.
#
sub DeleteNumber #(number)
    {
    my ($self, $number) = @_;

    my $data = $self->ToData($number);

    if (defined $data)
        {
        $self->[$number] = undef;
        delete $self->Hash()->{$data};
        };
    };


#
#   Function: HighestNumber
#
#   Returns the highest number that was ever assigned.  Note that this does not account for if that number was deleted or not.
#   Use this when you need to iterate through the numbers, such as to dump them to a file.  You can't simply stop when
#   <ToData()> returns undef because it will do that for deleted numbers as well.
#
sub HighestNumber
    {
    my $self = shift;
    return scalar @$self;
    };


###############################################################################
# Group: Support Functions

#
#   Function: Hash
#
#   Returns the hashref at index zero.  The code is clearer this way.
#
sub Hash
    {  return $_[0]->[0];  };


1;