package Combust::Secret;
use strict;
use Carp qw(croak);
use Combust::DB qw(db_open);
use Exporter 'import';
our @EXPORT_OK = qw(get_secret);


# Loosely inspired by / based on LJ::get_secret

my %secret_cache;

sub get_secret {
    my %args = @_;
    croak "type is required" unless $args{type};

    my $read_only = $args{time} && !wantarray;

    if (keys %secret_cache > 200) {
      %secret_cache = ();
    }
    
    my $time = $args{time} || time;
    $time -= $time % 3600;
    
    my $cache_key = join ";", $args{type}, $time;

    my $expires = $args{expires_at} ? $args{expires_at} : time + 86400 * 14;

    if (my $secret = $secret_cache{$cache_key}) {
        return $read_only ? $secret : ($time, $secret);
    }

    # if (memcached servers)
    #    try fetching from memcached
    #    return $read_only ? $secret : ($time, $secret) if $secret;
    # } 

    my $dbh = db_open('combust');
    return undef unless $dbh;

    my $secret = $dbh->selectrow_array
        ("SELECT secret FROM combust_secrets ".
         "WHERE secret_ts=? AND type=?",
         undef, $time, $args{type}
         );

    if ($secret) {
        $secret_cache{$cache_key} = $secret;
        return $read_only ? $secret : ($time, $secret);
    }

    return undef if $read_only;

    $secret = random_chars(32);

    $dbh->do("INSERT IGNORE INTO combust_secrets
              SET secret_ts=?, secret=?, type=?, expires_ts=?",
             undef, $time, $secret, $args{type}, $expires);

    # check for races:
    $secret = get_secret(%args, time => $time);

    $secret_cache{$cache_key} = $secret if $secret;

    return ($time, $secret);
}

sub random_chars {
    my $length = shift || 32;
    my $str = "";
    my $chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789^%!#-{}';
    for (1..$length) {
        $str .= substr($chars, int(rand(69)), 1);
    }
    $str;
}



1;
