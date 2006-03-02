package CPANNotify::Control::Subscriptions;
use strict;
use base qw(CPANNotify::Control);
use Apache::Constants qw(OK);

sub render {
    my $self = shift;

    $self->r->set_last_modified(time);

    return $self->login unless $self->is_logged_in;

    if ($self->request->uri =~ m!^/sub/logout!) {
        return $self->logout;
    }

    if (my $sub = $self->req_param('sub')) {
        my $type = $self->req_param('type') || 'dist';
        $type = 'dist' unless $type =~ m/^(author|dist|module)$/;

        my $user = $self->user; 

        my $subscribed = 0;
        $subscribed++ if CPANNotify::Subscription->search(user => $user, search_type => $type, name => $sub);
        $self->tpl_param(add_request => { subscribed => $subscribed, name => $sub, type => $type } );
    }

    return OK, $self->evaluate_template('tpl/subscriptions.html');
}

1; 
