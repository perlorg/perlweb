package Combust::Template::Plugin::Rotato;
use base qw( Template::Plugin );
use Template::Plugin;

sub new {
  my $class   = shift;
  my $context = shift;
  my $hash = shift;

  return $class->error("No data provided")
    unless $hash;

  # find total weight;
  my $total = 0;
  my @ordered = ();
  for (keys %{$hash}) {
    $total += $hash->{$_}{weight};
    push @ordered, [$total,$_];
  }

  bless {
	 data => $hash,
	 total => $total,
	 ordered => \@ordered,
	}, $class;
}

sub pick {
  my $self = shift;

  my $n = int(rand( $self->{total} ));
  my $prev = undef;
  for (@{$self->{ordered}}) {
    $prev = $_->[1];
    last if ($_->[0] > $n);
  }

  $self->error("Didn't find a value")
    unless $prev;

  return $self->{data}{$prev}{data};
}

1;
