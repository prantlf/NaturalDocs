###############################################################################
#
#   Package: NaturalDocs::DefineMembers
#
###############################################################################
#
#   A custom Perl pragma to define member constants for use in Natural Docs objects.
#
#   Each parameter will be defined as a numeric constant which should be used as that variable's index into the object arrayref.
#   They will be assigned sequentially from zero, and take into account any members defined this way in parent classes.  Note
#   that you can *not* use multiple inheritance with this method.
#
#   Example:
#
#   > package MyPackage;
#   >
#   > use NaturalDocs::DefineMembers 'VAR_A', 'VAR_B', 'VAR_C';
#   >
#   > sub SetA #(A)
#   >    {
#   >    my ($self, $a) = @_;
#   >    $self->[VAR_A] = $a;
#   >    };
#
###############################################################################

# This file is part of Natural Docs, which is Copyright © 2003-2004 Greg Valure
# Natural Docs is licensed under the GPL


package NaturalDocs::DefineMembers;

sub import #(member, member, member ...)
    {
    my ($self, @constants) = @_;
    my $package = caller();

    no strict 'refs';
    my $parent = ${$package . '::ISA'}[0];
    use strict 'refs';

    my $member = 0;

    if (defined $parent && $parent->can('END_OF_MEMBERS'))
        {  $member = $parent->END_OF_MEMBERS();  };

    my $code = '{ package ' . $package . ";\n";

    foreach my $constant (@constants)
        {
        $code .= 'use constant ' . $constant . ' => ' . $member . ";\n";
        $member++;
        };

    $code .= 'use constant END_OF_MEMBERS => ' . $member . ";\n";
    $code .= '};';

    eval $code;
    };

1;
