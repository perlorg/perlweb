package CPANNotify::Control::API;
use strict;
use Combust::Constant qw(OK);
use base qw(CPANNotify::Control);
use JSON;

my $json = JSON->new( ); # skipinvalid => 1);

sub render {
    my $self = shift;

    # $self->no_cache;
    return 403 unless $self->is_logged_in;

    my ($mode) = ($self->request->uri =~ m!/api/([^/]+)!);
    warn "MODE: $mode";

    my $user = $self->user;

    if ($mode eq 'subscriptions') {
	my $email = $self->req_param('email');

        my @subscriptions = map { { type => $_->search_type, name => $_->name, id => $_->id } } $user->subscriptions;

        my $obj = { subscriptions => \@subscriptions };
        my $out = $json->objToJson($obj);
        return OK, $out;
    }
    elsif ($mode eq 'subscribe') {
        my $sub = $self->req_param('sub');
        my $type = $self->req_param('type') || 'dist';
        $type = 'dist' unless $type =~ m/^(author|dist|module)$/;

        return OK, 'Name of distribution or module required' unless $sub;

        if (CPANNotify::Subscription->search(user => $user, search_type => $type, name => $sub)) {
            return OK, 'You were already subscribed';
        }
        else {
            CPANNotify::Subscription->create({user => $user, search_type => $type, name => $sub});
            return OK, 'Subscribed!';
        }
    }
    elsif ($mode eq 'unsubscribe') {
        my ($id) = ($self->request->uri =~ m!/(\d+)$!);
        my $sub = CPANNotify::Subscription->retrieve($id);
        if ($sub and $sub->user == $user) {
            $sub->delete and return OK, $json->objToJson( { status => 'OK', id => $id });
        }
        return OK, $json->objToJson( { status => 'ERROR' } ); 
    }

    # return $self->login unless $self->is_logged_in;
}


1;
