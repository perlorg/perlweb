package Combust::Redirect;
use strict;
use Apache::Constants qw(REDIRECT MOVED DECLINED OK);
# use Combust::Config;
use base qw(Combust::Control);

my $map = {};

sub reload {
  my ($self, $file) = @_;

  #warn "Checking file $file";

  my $mtime = (stat($file))[9];
  unless ($mtime) {
    #warn "could not find file: $file";
    delete $map->{$file};
    return;
  }

  #warn "mtime: $mtime, last update: ", $map->{$file}->{update};

  return if $map->{$file}->{update}
    and $map->{$file}->{update} > $mtime;

  $map->{$file}->{update} = time;

  #warn "reloading $file";

  my $site_rules = [];
  if (open MAP, $file) {
    while (<MAP>) {
      #warn ":: $_\n";
      next unless (my ($regexp, $url, $option) = $_ =~ m/(\S+)\s+(\S+)(?:\s*(\S+))?/);
      $regexp =~ s/^/\^/ unless $regexp =~ m/^\^/;
      $regexp =~ s/$/\$/ unless $regexp =~ m/\$$/;
      $option ||= '';
      $option = "I" if $option =~ m/^int/i;
      $option = "P" if $option =~ m/^per/i;
      $option = "" unless $option =~ m/^[IP]$/;
      #warn "regexp: $regexp => $url";
      push @{$site_rules}, [$regexp, $url, $option];
    }
    close MAP;
  } 
  else {
    warn "Could not open url map file $file: $!";
  } 
  $map->{$file}->{rules} = $site_rules;
}


#for my $site (keys %sites) {
#  __PACKAGE__->reload($site);
#

sub handler($$) {
  my ($self, $r) = @_;

  # this avoids some weirdness I can't otherwise figure out right now.
  return DECLINED if $r->uri =~ m!^/images!;

  my $site = $r->dir_config('site');
  #warn join " / ", "REDIRECT CHECK FOR $site", $r->uri, $r->content_type;

  my $path = $self->provider->paths;
  return unless $path and $path->[0];
  $path = $path->[0];

  my $file = "$path/.htredirects";

  $self->reload($file);
  my $conf = $map->{$file} ? $map->{$file}->{rules} : undef; 

  return DECLINED unless $conf and ref $conf eq "ARRAY";

  my $uri = $r->uri;
  for my $c (@$conf) {
    #warn "matching $uri to $c->[0]";
    if (my @n = ($uri =~ m/$c->[0]/)) {
      my $url = eval qq["$c->[1]"];
      warn "URLMAP ERROR: $c->[1]: $@" and next if $@;
      next unless $url;
      if ($c->[2] eq "I") {
	$r->uri($url);
      }
      else {
	return $self->redirect($r, $url,
				$c->[2] eq "P" ? 1 : 0
			       );
      }
    }
  }
  return DECLINED;

}


1;
