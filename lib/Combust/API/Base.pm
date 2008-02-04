package Combust::API::Base;
use strict;

sub new {
    my ($class) = shift;
    bless {@_}, $class;
}

sub user {
    shift->args->{user}
}

sub args {
    shift->{args};
}

sub _required_param {
    my $self = shift;
    my $p = $self->args->{params};
    if (my @missing = grep { !defined $p->{$_} || $p->{$_} eq '' } @_) {
      die( (@missing == 1)
           ? "Required parameter @missing missing\n"
           : "Required parameters (@missing) missing\n");
  }
    return @{$p}{@_};
}

sub _optional_param {
    my $self = shift;
    my $p = $self->args->{params};
    return @{$p}{@_};
}

1;
