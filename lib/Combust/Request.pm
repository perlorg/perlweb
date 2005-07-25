package Combust::Request;
use strict;

sub new {
  my $class = shift;
  bless { cookies_out => [] }, $class;
}

sub content_type {
  my ($self, $content_type) = @_;
  if ($content_type) {
    $self->{_content_type} = $content_type;
  }
  $self->{_content_type};
}

# we override this in the Apache13 class to use pnotes.
# should it be called 'note' rather than notes? (since it always just works on one...)
sub notes {
  my ($self, $note) = (shift, shift);
  $self->{notes}->{$note} = shift if @_;
  $self->{notes}->{$note};
}

sub cookie {
  my ($self, $name) = (shift, shift);
  if (@_) {
    my ($value, $args) = @_;
    $args ||= {};
    $args->{domain} = $args->{domain} || $self->hostname;
    $args->{path}   = $args->{path} || '/';
    $self->set_cookie($name, $value, $args);
  }
  else {
    $self->get_cookie($name);
  }
}


# maybe these should be in Combust::Request::Factory or some such...

my $request_class;
sub request_class {
  return $request_class if $request_class;
  my $class = shift;
  $request_class = $class->pick_request_class;
  eval "require $request_class";
  die qq[Could not load "$request_class": $@] if $@;
  $request_class;
}

sub pick_request_class {
  my ( $class, $request_class ) = @_;

  return 'Combust::Request::' . $request_class if $request_class;
  return "Combust::Request::$ENV{COMBUST_REQUEST_CLASS}" if $ENV{COMBUST_REQUEST_CLASS};

  if ($ENV{MOD_PERL}) {
    my ($software, $version) = $ENV{MOD_PERL} =~ /^(\S+)\/(\d+(?:[\.\_]\d+)+)/;
    if ($software eq 'mod_perl') {
      $version =~ s/_//g;
      $version =~ s/(\.[^.]+)\./$1/g;
      return 'Combust::Request::Apache20' if $version >= 2.000001;
      return 'Combust::Request::Apache13' if $version >= 1.29;
      die "Unsupported mod_perl version: $ENV{MOD_PERL}";
    }
    else {
      die "Unsupported mod_perl: $ENV{MOD_PERL}"
    }
  }

  return 'Combust::Request::CGI';
}


1;

