package Combust::Base;
use Moose;
use Combust::Config;

my $config = Combust::Config->new();

has 'request' => (
    is       => 'rw',
    required => 0,
);

sub get_include_path {
  my $self = shift;
  my $request = shift || $self->request;

  my $combust_root = $config->root;

  my $site = $request->site;
  unless ($site) {
    my @path = ("${combust_root}/apache/root_templates/");
    return \@path;
  }

  my @site_dirs = split /:/, ($config->site->{$site}->{docs_site} || $site);

  #warn Data::Dumper->Dump([\$r], [qw(r)]);

  my $path;

  my $root_docs = $config->root_docs;
  $path = [
           (map { "$root_docs/$_/" } @site_dirs),
           "$root_docs/shared/",
           "$root_docs/",
          ];

  push @$path, "${combust_root}/apache/root_templates/";

  #warn Data::Dumper->Dump([\$path], [qw(path)]);
  
  return $path;

}


1;
