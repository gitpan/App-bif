package Log::Any::Adapter::Diag;
use strict;
use warnings;
use base qw(Log::Any::Adapter::FileScreenBase);
require Test::More;

__PACKAGE__->make_logging_methods(
    sub {
        my $self = shift;
        Test::More::diag( join( ' ', @_ ) );
    }
);

1;
__END__
