package Combust::RoseDB::Object;
use strict;

# from http://dev.perl.org/perl6/rfc/335.html
sub methods {
    my ( $class, $types ) = @_;
    $class = ref $class || $class;
    $types ||= '';
    my %classes_seen;
    my %methods;
    my @class = ($class);

    no strict 'refs';
    while ( $class = shift @class ) {
        next if $classes_seen{$class}++;
        unshift @class, @{"${class}::ISA"} if $types eq 'all';

        # Based on methods_via() in perl5db.pl
        for my $method (
            grep {
                      not /^[(_]/
                  and not /^dbh?$/
                  and not /^[A-Z_]+$/
                  and defined &{ ${"${class}::"}{$_} }
            }
            keys %{"${class}::"}
          )
        {
            $methods{$method} = wantarray ? undef: $class->can($method);
        }
    }

    return [ sort keys %methods ];
}


sub update_if_changed {
    my $self    = shift;
    my $changed = 0;

    while ( my ( $k, $v ) = splice( @_, 0, 2 ) ) {
        my $ov = $self->$k;
        if ( defined($v) ne defined($ov) or ( defined($v) and $v ne $ov ) ) {
            $self->$k($v);
            ++$changed;
        }
    }

    $changed;
}

1;
