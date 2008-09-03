package Combust::Request::Apache2;
use strict;
use base qw(Combust::Request);
use Apache2::Request;
use Apache2::RequestRec ();
use Apache2::Response   ();
use Apache2::RequestUtil;
use Apache2::Upload;
use Apache2::Cookie;

my $config = Combust->config;

sub _r {
    my $self = shift;

    return $self->{_r} if $self->{_r};

    my $r = Apache2::RequestUtil->request;

    return $self->{_r} = Apache2::Request->new( $r, TEMP_DIR => $config->work_path, );

}


sub req_param {
    shift->_r->param(@_);
}

sub req_params {
    shift->_r->parms;
}

sub notes {
    shift->_r->pnotes(@_);
}

sub upload {
    shift->_r->upload(@_);
}

sub hostname {
    shift->_r->hostname;
}

sub header_in {
    my ( $req, $key, $value ) = @_;
    return $req->_r->headers_in->{$key} = $value if $value;
    return $req->_r->headers_in->{$key};
}

sub header_out {
    my ( $req, $key, $value ) = @_;
    return $req->_r->headers_out->{$key} = $value if $value;
    return $req->_r->headers_out->{$key};
}

sub remote_ip {
    shift->_r->connection->remote_ip;
}

sub uri {
    shift->_r->uri(@_);
}

sub method {
    lc shift->_r->method;
}

sub update_mtime {
    shift->_r->update_mtime(shift);
}

sub send_http_header {
    my ( $self, $ct ) = @_;
    $self->_r->content_type($ct) if $ct;
    return 1;    # don't need send_http_header in Apache 2
}

sub sendfile {
    my ($self, $file) = @_;
    return $self->_r->sendfile($file);
}

sub get_cookie {
    my ( $self, $name ) = @_;
    unless ( $self->{cookies} ) {
        $self->{cookies} = Apache2::Cookie->fetch || {};
    }
    my $c = $self->{cookies}->{$name};
    $c ? $c->value : undef;
}

sub set_cookie {
    my ( $self, $name, $value, $args ) = @_;

    my $cookie = Apache2::Cookie->new(
        $self->{r},
        -name   => $name,
        -value  => $value,
        -domain => $args->{domain},
        (   $args->{expires}
            ? ( -expires => $args->{expires} )
            : ()
        ),
        -path => $args->{path},
    );

    push @{ $self->{cookies_out} }, $cookie;
}

sub bake_cookies {
    my $self = shift;
    $_->bake for @{ $self->{cookies_out} };
}


1;
