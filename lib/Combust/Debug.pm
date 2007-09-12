package Combust::Debug;

our %CBDEBUG;

BEGIN {
  if (my $CBDEBUG = $ENV{CBDEBUG}) {
    @CBDEBUG{split /,/, $CBDEBUG} = ();
  }
}

sub import {
  shift;
  my $pkg = caller;
  my %opt = ($pkg, '###', @_);
  my @opt = map { $opt{$_} } grep { exists $CBDEBUG{$_} } keys %opt
    or return;

  @_ = ('Smart::Comments', @opt);
  require Smart::Comments;
  goto &{Smart::Comments->can('import')};
}

1;
__END__

=head1 NAME

Combust::Debug -- Debugging using Smart::Comments

=head1 SYNOPSIS

  use Combust::Debug;
  use Combust::Debug foo => '###foo', bar => '###bar';

  ###foo Debug enabled by foo

  ###bar Debug enabled by bar

=head1 DESCRIPTION

Combust::DEBUG provides an easy way for debug to be included in a module in its
comments. Which debug is shown is controlled by the CBDEBUG environment variable.

Arguments passed on the use line are tag => prefix pairs. L<Smart::Comments> requires
that all prefixes begin with C<###> and C<__PACKAGE__ =E<gt> '###'> is always assumed.

CBDEBUG is a comma separated list of strings. If CBDEBUG contains any of the named
tags in the use list, then L<Smart::Comments> is enabled for those tags

=head1 SEE ALSO

L<Smart::Comments>


