package Combust::Cookies;
use strict;
use Apache::Cookie;

my $cookie_name  = 'z';

sub new {
  my $proto = shift;
  my $class = ref $proto || $proto;
  my $r = shift;
  my $self = bless( { r => $r }, $class);
  return $self;
}

sub changed {
  my ($self, $val) = @_;
  $self->{_changed} = $val if $val; 
  return $self->{_changed} || 0;
}

sub parse_cookies {
  my $self = shift;

  return $self->{_parsed} if $self->{_parsed};
  my $cookies = Apache::Cookie->new($self->{r})->parse || {};

  my $cookie = $cookies->{$cookie_name} ? $cookies->{$cookie_name}->value : "";
  $cookie =~ s/\r$// if $cookie;  # remove occasional trailing ^M

  $cookie = check_cookie($cookie);

  warn "got cookie: [$cookie]";

  my $parsed = $cookie ? { split /\//, $cookie } : {};

  my $last_refreshed = $parsed->{lr} || 0;
  if ($last_refreshed < (time - (86400*7))) {
    $parsed->{lr} = time;
    $self->changed(1);
  }
  return $self->{_parsed} = $parsed;
}

sub cookie {
  my ($self, $cookie, $val) = @_;

  #warn Data::Dumper->Dump([\$self], [qw(cookie_self)]);

  my $cookies = $self->parse_cookies;
  if ($val and (!$cookies->{$cookie} or $cookies->{$cookie} ne $val)) {
    warn "Setting $cookie to [$val]";
    $cookies->{$cookie} = $val;
    $self->changed(1);
  }
  $cookies->{$cookie} || '';
}

sub bake_cookies {
  my $self = shift;

  return unless $self->changed;

  warn " bake cookies: ", ref $self;
  #warn Data::Dumper->Dump([\$self], [qw(self)]);

  my $r = $self->{r};
  my $notes  = $r->pnotes('combust_notes') or die "No combust_notes, configuration error?";
  my $domain = $notes->{req_domain};

  my $cookies = $self->parse_cookies;

  use Data::Dumper;
  warn Data::Dumper->Dump([\$cookies], [qw(cookies)]);

  unless (%$cookies) {
    $cookies->{_R} = $$ . rand(1000) . make_checksum(rand); 
  }
  else {
    $cookies->{_R} = undef; 
  }

  my $encoded = join('/', map { $_ => $cookies->{$_} } grep { $cookies->{$_} } keys %$cookies);

  my $cs = make_checksum($encoded);

  # 1/ is the version
  $encoded = "1/$encoded/$cs";

  warn "encoded: [$encoded]";

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

sub check_cookie {
  my ($raw_id) = @_;
  my ($cookie_version, $cookie, $hex_cs) = $raw_id =~ m!^(.)/(.*?)/([^/]{8})$!;
  warn "V: [$cookie_version]  C: [$cookie]  CS: [$hex_cs]";
  
  unless ($cookie) { # regex didn't match, probably truncated
    # the empty id have a checksum too, but we will never allow that
    warn "No cookie";
    return '' unless wantarray;
    return ('', "trunc", 0); # don't reset the user_id in this case
  }
  unless ($cookie_version eq "1") { # corruption or a hacker
    warn "XRL::Cookies got cookie_version $cookie_version != 1 ($raw_id)";
    return 0 unless wantarray;
    return ('', "vers",  (rand(100) < 0.1) );
  }
  if ($hex_cs ne make_checksum($cookie)) {
    warn "Failed checksum";
    return '' unless wantarray;
    return ('', "failed", (rand(100) < 0.1) );
  }
  #warn "cookie ok!";
  return $cookie unless wantarray;
  return ($cookie, "",  0);
}


sub make_checksum {
  my $id = shift;
  my $pad = "\001~#{f0Oz}~\250\25043%,";
  my $cs = DBI::hash("$pad/$id^/$id/$pad/$id\L//$pad/$id");
  my $hex_cs = unpack("H8", pack("L",$cs));
  return uc $hex_cs;
}

1;
