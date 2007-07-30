package Combust::Cookies;
use strict;
use Apache::Cookie;
use URI::Escape qw(uri_escape uri_unescape);
use Combust::Secret qw(get_secret);

our $DEBUG = 0;

my $default_cookie_name  = 'c';

my %special_cookies = ();
my %special_cookies_reverse = ();

# put the "root" cookie into the "r" browser cookie
__PACKAGE__->add_special_cookie("root" => "r");

sub _setup_special_cookies_reverse {
    for my $cookie_name (keys %special_cookies) {
        for my $cookie (@{$special_cookies{$cookie_name}}) {
            $special_cookies_reverse{$cookie} = $cookie_name;
        }
    } 
}

sub add_special_cookie {
    my ($class, $cookie, $cookie_name) = @_;
    $special_cookies{$cookie_name} ||= [];
    push @{ $special_cookies{$cookie_name} }, $cookie;
    _setup_special_cookies_reverse();
}

sub new {
  my $proto = shift;
  my $class = ref $proto || $proto;
  my $r = shift;
  my %args = @_;
  my $self = bless( { r => $r,
                      domain => $args{domain}
                    }, $class);
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

    warn "got cookie: [$cookie_name]=[$cookie]" if $DEBUG;
    
    # FIXME: we are unescaping the keys too... hmn 
    $parsed = { %$parsed, map { uri_unescape($_) } split /\/~/, $cookie } if defined $cookie;

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

  warn Data::Dumper->Dump([\$self], [qw(cookie_self)]) if $DEBUG > 1;

  my $cookies = $self->parse_cookies;

  if (defined $val and (!$cookies->{$cookie} or $cookies->{$cookie} ne $val)) {
    #warn "Setting $cookie to [$val]\n";
    $cookies->{$cookie} = $val;
    delete $cookies->{$cookie} if $val eq '';
    $self->changed($special_cookies_reverse{$cookie} || $default_cookie_name, 1);
  }
  defined $cookies->{$cookie} ? $cookies->{$cookie} : '';
}

sub bake_cookies {
  my $self = shift;

  my $r = $self->{r};

  #warn Data::Dumper->Dump([\$self], [qw(self)]);

  my $ts = time;

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

    my $encoded = join('/~',
                       map {
                           my $val = delete $cookies->{$_};
                           #warn "VAL for $_: ", (defined $val ? $val : 'undef'), "\n";
                           ($_ => uri_escape($val, "^A-Za-z0-9\-_.!*'()"))
                           }
		       grep { defined $cookies->{$_} } 
                       @keys
                      );

    next unless $encoded;  # TODO - skip the LR cookie ... oh well.

    my $cs = make_checksum($cookie_name, $ts, $encoded, 1);
 
    # 3/ is the version
    $encoded = "3/$ts/$encoded/$cs";

    #warn "[$cookie_name] encoded: [$encoded]";

    $self->{r}->cookie($cookie_name, $encoded, { expires => '+180d',
                                                 domain => $self->{domain} });
  }
  $self->{r}->bake_cookies;
}


sub check_cookie {
  my ($cookie_name, $raw_id) = @_;
  my ($cookie_version, $ts, $cookie, $hex_cs) = $raw_id =~ m!^(.)/(\d+)/(.*?)/([^/]{8})$!;
  #warn "R: $raw_id N: [$cookie_name]  C: [$cookie]  CS: [$hex_cs]\n";
  
  unless ($cookie) { # regex didn't match, probably truncated
    # the empty id have a checksum too, but we will never allow that
    warn "No cookie";
    return '' unless wantarray;
    return ('', "trunc", 0); # don't reset the cookie in this case
  }
  unless ($cookie_version eq "3") { # corruption or a hacker
    warn "Combust::Cookies got cookie_version $cookie_version != 2 ($raw_id)";
    return 0 unless wantarray;
    return ('', "vers",  (rand(100) < 1) );
  }
  if ($hex_cs ne make_checksum($cookie_name, $ts, $cookie, 0)) {
    warn "Failed checksum" if $DEBUG;
    return '' unless wantarray;
    return ('', "failed", (rand(100) < 0.1) );
  }
  warn "cookie ok!" if $DEBUG;
  return $cookie unless wantarray;
  return ($cookie, "",  0);
}


my %secret_cache;

sub make_checksum {
  my ($key, $ts, $value, $create) = @_;
  warn "KEY: [$key] / TS: [$ts] / VALUE: [$value]" if $DEBUG;

  if (keys %secret_cache > 2000) {
      %secret_cache = ();
  }

  # make sure the cache matches up with what get_secret generates
  $ts -= $ts % 3600;
  my $pad = $secret_cache{$ts};

  ($ts, $pad) = get_secret(time => $ts, 
                           expires_at => ($ts + 86400 * 180),
                           type => 'cookie'
                          ) if !$pad;
  $secret_cache{$ts} = $pad;

  # fail-safe to make sure people can't make up their own cookies
  $pad = rand unless $pad;  

  my $x = "$pad/$key^/$key/$pad/$value/$key\L//$pad/$value";

  #warn "UTF8: ", utf8::is_utf8($x);
  $x = Encode::encode_utf8($x);

  my $cs = DBI::hash($x, 1);
  my $hex_cs = unpack("H8", pack("L",$cs));
  # warn "K: $key / V: $value / $cs / HCS: ", uc $hex_cs;

  return uc $hex_cs;
}

1;
