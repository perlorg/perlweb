package Combust::Notes;
use strict;

use Combust::Cookies;
use Combust::Constant qw(OK);
use Combust::Control;

use Time::HiRes qw(time); # let's be accurate about this
use DBI;		  # for DBI::hash()

# TODO:
#   Move this so it's called from Combust::Control rather than as a PostReadRequest handler

use constant MP2 => ( exists $ENV{MOD_PERL_API_VERSION} and 
		      $ENV{MOD_PERL_API_VERSION} >= 2 ); 

BEGIN {
    if (MP2) {
	require Apache2::Request;
	require Apache2::RequestUtil;
	require Apache2::Connection;
    }
    else {
	require Apache::Request;
    }
}


sub handler {
  my $apr = shift;

  return OK if $apr->pnotes('combust_notes');

 if (MP2) {
    Apache2::RequestUtil->request($apr);
  }
  else {
    Apache->request($apr); # ensure Apache->request returns current request
  }
  my $r = Combust::Control->new($apr)->r;

  my $ip      = $r->connection->remote_ip;
  my $param   = $r->param;

  my $ua = $r->headers_in->{'User-Agent'} || '';

  my $req_domain = ($r->hostname =~ m/([^\.]+\.[^\.]+)$/)[0];

  my %combust_notes = (
    remote_ip	=> $ip				|| '-',
    user_agent	=> $ua,
    referer	=> $r->headers_in->{'Referer'}	|| '',
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

