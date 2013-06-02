use strict;
use integer;

package Tests::Languages::JavaScript;

use base 'Exporter';
our @EXPORT = ('Test');


sub New { #(name)
    my ($selfPackage, $name) = @_;

    my $object = [ ];

    bless $object, $selfPackage;
    return $object;
}


sub Test { #()
    my ($self) = @_;

    print "Testing " . join(", ", keys(%INC)) . "\n";
# NaturalDocs/NaturalDocs -p NaturalDocs/Tests/Languages/JavaScript/Project -o html NaturalDocs/Tests/Languages/JavaScript/Output -i NaturalDocs/Tests/Languages/JavaScript/Input -r
}


1;
