package Combust::Cookies;
use strict;
use Apache::Cookie;
use URI::Escape qw(uri_escape uri_unescape);

my $default_cookie_name  = 'c';

my %special_cookies = (
  r => [qw(root)],
  #svd => [qw(s)],
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
  my $cookies = Apache::Cookie->fetch;

  my $parsed = {};
 

  for my $cookie_name ($default_cookie_name, keys %special_cookies) {
    my $cookie = $cookies->{$cookie_name} ? $cookies->{$cookie_name}->value : "";
 
    next unless $cookie;
    
    $cookie =~ s/\r$// if $cookie;  # remove occasional trailing ^M
 
    $cookie = check_cookie($cookie_name, $cookie);

    #warn "got cookie: [$cookie_name]=[$cookie]";
    
    # FIXME: we are unescaping the keys too... hmn 
    $parsed = { %$parsed, map { uri_unescape($_) } split /\/~/, $cookie } if $cookie;

    my $last_refreshed = $parsed->{"LR" . $cookie_name} || 0;
    if ($last_refreshed < (time - (86400*7))) {
      $parsed->{"LR" . $cookie_name} = time;
      $self->changed($cookie_name, 1);
    }
  }
  return $self->{_parsed} = $parsed;
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
  my $notes  = $r->pnotes('combust_notes') or die "No combust_notes, configuration error?";
  my $domain = $r->hostname;

  #warn "\n\n\nBAKING COOKIES\n\n";

  #warn Data::Dumper->Dump([\$self], [qw(self)]);

  for my $cookie_name (keys %special_cookies, $default_cookie_name) {

    #warn " bake cookies for cookie $cookie_name: ", ref $self;

    next unless $self->changed($cookie_name);

    my $cookies = $self->parse_cookies;

    use Data::Dumper;
    #warn Data::Dumper->Dump([\$cookies], [qw(cookies)]);
    
    my @keys = $special_cookies{$cookie_name} ? @{ $special_cookies{$cookie_name} } : (keys %$cookies);
    
    push @keys, "LR" . $cookie_name unless $cookie_name eq $default_cookie_name;

    #warn "KEYS for $cookie_name: ", join "!", @keys;

    my $encoded = join('/~', map { $_ => (uri_escape(delete $cookies->{$_} || '', "^A-Za-z0-9\-_.!*'()")) }
		       grep { $cookies->{$_} } @keys);

    next unless $encoded;  # TODO - skip the LR cookie ... oh well.

    $cookies->{_R} = $$ . rand(1000); # . make_checksum(rand); 

    my $cs = make_checksum($cookie_name, $encoded);
 
    # 2/ is the version
    $encoded = "2/$encoded/$cs";

    #warn "[$cookie_name] encoded: [$encoded]";

    # not that we actually have the /w3c/p3p.xml document
    $r->header_out('P3P',qq[CP="NOI DEVo TAIo PSAo PSDo OUR IND UNI NAV", policyref="/w3c/p3p.xml"]);

    my $cookie = Apache::Cookie->new(
				     $self->{r},
				     -name	=> $cookie_name,
				     -value	=> $encoded,
				     -domain	=>  "$domain",
				     -expires	=> '+180d',
				     -path	=> '/',
				    );
    $cookie->bake;
  }
}


sub check_cookie {
  my ($cookie_name, $raw_id) = @_;
  my ($cookie_version, $cookie, $hex_cs) = $raw_id =~ m!^(.)/(.*?)/([^/]{8})$!;
  #warn "N: [$cookie_name]  C: [$cookie]  CS: [$hex_cs]\n";
  
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
  my $cs = DBI::hash("$pad/$key^/$key/$pad/$value/$key\L//$pad/$value");
  my $hex_cs = unpack("H8", pack("L",$cs));
  return uc $hex_cs;
}

1;
