package CPANNotify::Control;
use strict;
use base qw(Combust::Control Combust::Control::Bitcard);
use CPANNotify::User;
use Apache::Constants qw(OK);
use CPANNotify::User;
use HTML::Prototype;

sub init {
    my $self = shift;
    $self->bc_check_login_parameters;
    return OK;
}

my $prototype = HTML::Prototype->new;
sub prototype {
  $prototype;
}

sub bc_user_class { 'CPANNotify::User' }
sub bc_info_required { 'email' }


package CPANNotify::Control::Basic;
use base qw(CPANNotify::Control Combust::Control::Basic);

package CPANNotify::Control::Error;
use base qw(CPANNotify::Control Combust::Control::Error);

1;

