package Kind;

use v5.36;
use warnings;
use feature 'try';
no warnings 'experimental';

sub create_cluster ($self, $name) {
    system(qw( kind create cluster -n ), $name) == 0
        || die "unable to create kind cluster named $name: $!";

}

1;