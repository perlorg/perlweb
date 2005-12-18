package CPANNotify::User;
use base qw(CPANNotify::DBI);
use strict;

__PACKAGE__->set_up_table('cpannotify_users');
__PACKAGE__->has_many(subscriptions => 'CPANNotify::Subscription');
#__PACKAGE__->has_many(emails        => 'CPANNotify::User::Email');


1;
