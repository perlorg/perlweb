package Combust::Request::Plack;
use Moose;
use MooseX::NonMoose;
use Plack::Request;
use Combust::Request::URI;
extends 'Plack::Request';

has 'response' => (
    is         => 'ro',
    isa        => 'Plack::Response',
    lazy_build => 1,
    handles    => {
        content_type => 'content_type',
        header_out   => 'header',
        status       => 'status',
    },
);

sub _build_response {
    shift->new_response;
}

has 'site' => (
    is       => 'rw',
    isa      => 'Combust::Site',
    required => 0,
);

has 'notes_container' => (
    traits => ['Hash'],
    is  => 'ro',
    isa => 'HashRef[Any]',
    default => sub { {} },
    handles => {
       notes => 'accessor',
    },
);

sub remote_ip {
    shift->address;
}

sub req_param {
    my ($self, $param) = (shift, shift);
    $self->args->{$param} = shift if @_;
    return $self->parameters->{$param};
}

sub args {
    my $self = shift;
    return wantarray ? %{ $self->query_parameters } : $self->env->{QUERY_STRING}
}

# Plack::Request returns a regular URI object; in the past
# Combust::Request would return the path (similar to
# Apache::Request->uri), so we do a bit of craziness to emulate that.
sub uri {
    my $self = shift;
    my $uri = $self->SUPER::uri(@_);
    $uri = Combust::Request::URI->new( $uri->as_string );
    return $uri;
}

sub request_url {
    shift->uri->as_string;
}

sub req_params {
    shift->parameters;
}

sub hostname {
    shift->uri->host;
}

sub header_in {
    shift->header(@_);
}

sub method {
    shift->env->{REQUEST_METHOD};
}

sub update_mtime {
    my $self = shift;
    my $old = $self->{_mtime} || 0;
    my $new = shift || time;
    $self->{_mtime} = $new if $new > $old;
    $self->{_mtime};
}

sub modified_time {
    my $self = shift;
    return $self->{_mtime};
}

sub send_http_header { 
    # noop
}

sub dir_config {
    warn "dir_config [$_[1]] called";
    return ();
}

sub get_cookie {
  my ($self, $name) = @_;
  $self->cookies->{$name};
}

sub set_cookie {
    my ($self, $name, $value, $args) = @_;

    $self->response->cookies->{$name} = {
        value  => $value,
        domain => $args->{domain},
        (   $args->{expires}
            ? (expires => $args->{expires})
            : ()
        ),
        path => $args->{path},
    };

}

sub is_main { 1 }

1;
