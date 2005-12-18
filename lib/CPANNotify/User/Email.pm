package CPANNotify::User::Email;
use base qw(CPANNotify::DBI);
use strict;

__PACKAGE__->set_up_table('cpannotify_emails');

sub accessor_name {
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
