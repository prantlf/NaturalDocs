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
#   Function: ToNumber
#
#   Returns a data element's number, creating one for it if necessary.  Created numbers will always start at one and increment
#   upwards.  If you don't want a number to be created, use <FindNumber()> instead.
#
#   Parameters:
#
#       data - The data element to find/create a number for.
#
#   Returns:
#
#       The number for the element.
#
sub ToNumber #(data)
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
#   Returns a number's data, if defined.
#
#   Parameters:
#
#       number - The number to find the data of.
#
#   Returns:
#
#       The data of the number, or undef if none.
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
#   Function: FindNumber
#
#   Finds the number of a data element, but does not create one if it does not exist.
#
#   Parameters:
#
#       data - The data element to find the number of.
#
#   Returns:
#
#       The data's number, or undef if none.
#
sub FindNumber #(data)
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