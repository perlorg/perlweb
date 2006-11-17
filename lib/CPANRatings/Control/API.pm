package CPANRatings::Control::API;
use strict;
use base qw(CPANRatings::Control Combust::Control::API);
use Apache::Constants qw(OK NOT_FOUND);
use JSON;
use Sys::Hostname qw(hostname);
use CPANRatings::API;
use Return::Value;

my $json = JSON->new(selfconvert => 1, pretty => 1);

sub check_auth {
    my $self = shift;
    return failure 'Invalid Auth Token'
      unless (($self->req_param('auth_token') || '')
              eq $self->user_auth_token($self->cookie('uq')));
}


1;

