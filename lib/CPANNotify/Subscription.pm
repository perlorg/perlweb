package CPANNotify::Subscription;
use base qw(CPANNotify::DBI);
use strict;

__PACKAGE__->set_up_table('cpannotify_subscriptions');

sub accessor_name_for {
    my ($class, $column) = @_;
    return "_$column" if $column eq 'user';
    $column;
}

sub user {
  my $self = shift;
  my $id = $self->_user(@_);
  return unless $id;
  CPANNotify::User->retrieve($id);
}



1;
