package Combust::Notes;
use strict;

use Combust::Cookies;

use Apache::Cookie;
use Apache::Request;
use Apache::Constants qw(OK NOT_FOUND);
use Time::HiRes qw(time); # let's be accurate about this
use DBI;		  # for DBI::hash()

sub handler {
  my $r = Apache::Request->instance( shift );

  my $ip      = $r->connection->remote_ip;
  my $param   = $r->param;

  my $ua = $r->header_in('User-Agent') || '';

  my $req_domain = ($r->hostname =~ m/([^\.]+\.[^\.]+)$/)[0];

  my %combust_notes = (
    remote_ip	=> $ip				|| '-',
    user_agent	=> $ua,
    referer	=> $r->header_in('Referer')	|| '',
    user_id	=> 'none',
    'time'	=> time(),
    param	=> $param,
    req_domain  => $req_domain,
    site        => $r->dir_config("site"),
  );

  $r->pnotes(combust_notes => \%combust_notes);

  return OK;
}

1;

