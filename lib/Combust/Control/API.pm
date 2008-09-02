package Combust::Control::API;
use strict;
use base qw(Combust::Control);
use Combust::Constant qw(OK NOT_FOUND);
use JSON::XS qw(encode_json);
use Sys::Hostname qw(hostname);
use Return::Value;

sub render {
    my $self = shift;
    my ($uri, $method) = ($self->request->uri =~ m!^(/api/((\w+)/?([a-z]\w+))?)!);

    # MSIE caches POST requests sometimes (?)
    $self->no_cache(1) if $self->r->method eq 'POST';
    
    if ($self->can('check_auth')) {
        unless (my $auth_setup = $self->check_auth($method)) {
            return $self->system_error("$auth_setup" || 'Authentication failure');
        }
    }
    
    my ($result, $meta) = eval {
        $self->api($method, $self->api_params, { json => 1 });
    };
    if ($@) {
        return $self->system_error($@);
    }
    
    return $self->system_error("$uri didn't return a result") unless (defined $result);

    return OK, $result, 'text/javascript';
}

sub api_params {
    shift->request->req_params;
}

sub _format_error {
    my $self = shift;
    my $time = scalar localtime();
    chomp(my $err = join(" ", $time, @_));
    warn "ERROR: $err\n";
    encode_json({ system_error => $err,
                  server       => hostname,
                  datetime     => $time,
                });
}

sub show_error {
    my $self = shift;
    $self->send_output($self->_format_error(@_), 'text/javascript');
    return 400;
}

sub system_error {
    my $self = shift;
    $self->send_output($self->_format_error(@_), 'text/javascript');
    return 500;
}

# todo: should these be in Combust::Control ?
sub no_cache {
    my $self = shift;
    my $status = shift;
    $status = 1 unless defined $status;
    $self->{no_cache} = $status;
}

sub post_process {
    my $self = shift;

    if ($self->{no_cache}) {
        my $r = $self->r;

        $r->header_out('Expires', HTTP::Date::time2str( time() ));
        $r->header_out('Cache-Control', 'private, no-store, no-cache, must-revalidate, post-check=0, pre-check=0');
        $r->header_out('Pragma', 'no-cache');
    }
    
    return OK;
}



1;


