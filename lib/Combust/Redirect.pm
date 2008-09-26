package Combust::Redirect;
use strict;
use Apache::Constants qw(DECLINED DONE);

my $map = {};

sub redirect_reload {
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
      $regexp = qr/$regexp/;
      push @{$site_rules}, [$regexp, $url, $option];
    }
    close MAP;
  } 
  else {
    warn "Could not open url map file $file: $!";
  } 
  $map->{$file}->{rules} = $site_rules;
}

sub redirect_check {
  my $self = shift;

  my $site = $self->site;
  my $uri  = $self->request->uri;

  #warn join " / ", "REDIRECT CHECK FOR $site", $uri;

  my $path = $self->get_include_path;
  return unless $path and $path->[0];
  $path = $path->[0];

  my $file = "$path/.htredirects";

  #warn "FILE: $file";

  $self->redirect_reload($file);
  my $conf = $map->{$file} ? $map->{$file}->{rules} : undef; 

  #warn Data::Dumper->Dump([\$conf],[qw(conf)]);

  return DECLINED unless $conf and ref $conf eq "ARRAY";

  for my $c (@$conf) {
    #warn "matching $uri to $c->[0]";
    if (my @n = ($uri =~ m/$c->[0]/)) {
      my $url = eval qq["$c->[1]"];
      warn "URLMAP ERROR: $c->[1]: $@" and next if $@;
      next unless $url;
      if ($c->[2] eq "I") {
	$self->request->uri($url);
        my $subr = $self->request->_r->lookup_uri($url);
        $subr->run;
        return DONE;
      }
      else {
	return $self->redirect($url, $c->[2] eq "P" ? 1 : 0);
      }
    }
  }
  return DECLINED;

}


1;
