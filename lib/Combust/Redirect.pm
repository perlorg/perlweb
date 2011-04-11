package Combust::Redirect;
use Moose::Role;
# extends 'Combust::Base';
use Combust::Constant qw(DECLINED OK);

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

my $stat_check = 0;
my %files;

sub rewrite {
    my ($self, $request) = @_;

  my $site = $request->site;
  my $uri  = $request->uri;

  #warn join " / ", "REDIRECT CHECK FOR $site", $uri;

  my $path = $self->get_include_path($request);
  return unless $path and $path->[0];

  my $file;

  if (time - 30 > $stat_check) {
      %files = ();
      $stat_check = time;
  }
      
  while (1) {
    my $dir = shift @$path;
    last unless $dir;
    $file = "$dir/.htredirects";
    my $exists = defined $files{$file} 
      ? $files{$file} 
      : $files{$file} = -e $file || 0;
    last if $exists;
  }

  #warn "FILE: $file";

  $self->redirect_reload($file);
  my $conf = $map->{$file} ? $map->{$file}->{rules} : undef; 

  #warn Data::Dumper->Dump([\$conf],[qw(conf)]);

  return unless $conf and ref $conf eq "ARRAY";

  for my $c (@$conf) {
    #warn "matching $uri to $c->[0]";
    if (my @n = ($uri =~ m/$c->[0]/)) {
      my $url = eval qq["$c->[1]"];
      warn "URLMAP ERROR: $c->[1]: $@" and next if $@;
      next unless $url;
      if ($c->[2] eq "I") {
          warn "rewriting to $url";
          $request->env->{PATH_INFO} = $url; 
      }
      else {
	return $self->redirect($url, $c->[2] eq "P" ? 1 : 0);
      }
    }
  }

}


1;
