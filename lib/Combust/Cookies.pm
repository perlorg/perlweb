package Combust::Cookies;
use strict;
use Apache::Cookie;
use URI::Escape qw(uri_escape uri_unescape);

my $default_cookie_name  = 'c';

my %special_cookies = (
  r => [qw(root)],
);

my %special_cookies_reverse;
for my $cookie_name (keys %special_cookies) {
  for my $cookie (@{$special_cookies{$cookie_name}}) {
    $special_cookies_reverse{$cookie} = $cookie_name;
  }
} 

sub new {
  my $proto = shift;
  my $class = ref $proto || $proto;
  my $r = shift;
  my $self = bless( { r => $r }, $class);
  return $self;
}

sub changed {
  my ($self, $cookie, $val) = @_;
  $cookie ||= $default_cookie_name;
  #$self->{_changed} = {} unless $self->{_changed};
  $self->{_changed}->{$cookie} = $val if $val; 
  return $self->{_changed}->{$cookie} || 0;
}

sub parse_cookies {
  my ($self) = @_;

  return $self->{_parsed} if $self->{_parsed};

  my $parsed = {};

  for my $cookie_name ($default_cookie_name, keys %special_cookies) {
    my $cookie = $self->{r}->cookie($cookie_name);
    next unless $cookie;

    $cookie =~ s/\r$// if $cookie;  # remove occasional trailing ^M
 
    $cookie = check_cookie($cookie_name, $cookie);

    #warn "got cookie: [$cookie_name]=[$cookie]";
    
    # FIXME: we are unescaping the keys too... hmn 
    $parsed = { %$parsed, map { uri_unescape($_) } split /\/~/, $cookie } if $cookie;

    $self->update_last_refreshed($cookie_name, $parsed);
  }
  return $self->{_parsed} = $parsed;
}

sub update_last_refreshed {
  my ($self, $cookie_name, $cookies, $force) = @_;

  # $cookies ||= $self->parse_cookies;

  my $last_refreshed = $cookies->{"LR" . $cookie_name} || 0;
  if ($force or $last_refreshed < (time - (86400*7))) {
    $cookies->{"LR" . $cookie_name} = time;
    $self->changed($cookie_name, 1);
  }
}

sub cookie {
  my ($self, $cookie, $val) = @_;

  #warn Data::Dumper->Dump([\$self], [qw(cookie_self)]);

  my $cookies = $self->parse_cookies;

  if (defined $val and (!$cookies->{$cookie} or $cookies->{$cookie} ne $val)) {
    #warn "Setting $cookie to [$val]\n";
    $cookies->{$cookie} = $val;
    delete $cookies->{$cookie} if $val eq '';
    $self->changed($special_cookies_reverse{$cookie} || $default_cookie_name, 1);
  }
  $cookies->{$cookie} || '';
}

sub bake_cookies {
  my $self = shift;

  my $r = $self->{r};
  my $domain = $r->hostname;

  #warn Data::Dumper->Dump([\$self], [qw(self)]);

  my %cookies_out;

  for my $cookie_name (keys %special_cookies, $default_cookie_name) {
    #warn " bake cookies for cookie $cookie_name: ", ref $self;
    next unless $self->changed($cookie_name);

    my $cookies = $self->parse_cookies;

    #warn Data::Dumper->Dump([\$cookies], [qw(cookies)]);
    
    my @keys = $special_cookies{$cookie_name} ? @{ $special_cookies{$cookie_name} } : (keys %$cookies);
    push @keys, "LR" . $cookie_name unless $cookie_name eq $default_cookie_name;

    $self->update_last_refreshed($cookie_name, $cookies, 1);

    #warn "KEYS for $cookie_name: ", join "::", @keys;

    my $encoded = join('/~', map { $_ => (uri_escape(delete $cookies->{$_} || '', "^A-Za-z0-9\-_.!*'()")) }
		       grep { $cookies->{$_} } @keys);

    next unless $encoded;  # TODO - skip the LR cookie ... oh well.

    my $cs = make_checksum($cookie_name, $encoded);
 
    # 2/ is the version
    $encoded = "2/$encoded/$cs";

    #warn "[$cookie_name] encoded: [$encoded]";

    $self->{r}->cookie($cookie_name, $encoded, { expires => '+180d' });
  }
  $self->{r}->bake_cookies;
}


sub check_cookie {
  my ($cookie_name, $raw_id) = @_;
  my ($cookie_version, $cookie, $hex_cs) = $raw_id =~ m!^(.)/(.*?)/([^/]{8})$!;
  #warn "R: $raw_id N: [$cookie_name]  C: [$cookie]  CS: [$hex_cs]\n";
  
  unless ($cookie) { # regex didn't match, probably truncated
    # the empty id have a checksum too, but we will never allow that
    warn "No cookie";
    return '' unless wantarray;
    return ('', "trunc", 0); # don't reset the cookie in this case
  }
  unless ($cookie_version eq "2") { # corruption or a hacker
    warn "Combust::Cookies got cookie_version $cookie_version != 2 ($raw_id)";
    return 0 unless wantarray;
    return ('', "vers",  (rand(100) < 1) );
  }
  if ($hex_cs ne make_checksum($cookie_name, $cookie)) {
    warn "Failed checksum";
    return '' unless wantarray;
    return ('', "failed", (rand(100) < 0.1) );
  }
  #warn "cookie ok!";
  return $cookie unless wantarray;
  return ($cookie, "",  0);
}


sub make_checksum {
  my ($key, $value) = @_;
  my $pad = "~#[d0oODxz\001>~\250as\250d75~\%,";  # TODO|FIXME: this should be picked up from a local file
  my $x = "$pad/$key^/$key/$pad/$value/$key\L//$pad/$value";

  #warn "UTF8: ", utf8::is_utf8($x);
  $x = Encode::encode_utf8($x);

  my $cs = DBI::hash($x, 1);
  my $hex_cs = unpack("H8", pack("L",$cs));
  # warn "K: $key / V: $value / $cs / HCS: ", uc $hex_cs;

  return uc $hex_cs;
}

1;
