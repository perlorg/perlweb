package Combust::Request;
use strict;

sub new {
  my $class = shift;
  bless { cookies_out => [] }, $class;
}

sub content_type {
  my ($self, $content_type) = @_;
  if ($content_type) {
    $self->{_content_type} = $content_type;
  }
  $self->{_content_type};
}

# we override this in the Apache13 class to use pnotes.
# should it be called 'note' rather than notes? (since it always just works on one...)
sub notes {
  my ($self, $note) = (shift, shift);
  $self->{notes}->{$note} = shift if @_;
  $self->{notes}->{$note};
}

sub cookie {
  my ($self, $name) = (shift, shift);
  if (@_) {
    my ($value, $args) = @_;
    $args ||= {};
    $args->{domain} = $args->{domain} || $self->hostname;
    $args->{path}   = $args->{path} || '/';
    $self->set_cookie($name, $value, $args);
  }
  else {
    $self->get_cookie($name);
  }
}

sub is_main {
    # do something smarter when supporting sub-requests
    return 1;
}

1;

=head1 NAME


=head2 METHODS

=over 4

=item content_type([new_content_type])

=item cookie(name, [value], [args])

=item notes(note, [value])

=item req_param


=item req_params

Hash ref to all the request parameters.

=back  

=cut

