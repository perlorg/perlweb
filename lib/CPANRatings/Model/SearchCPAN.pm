package CPANRatings::Model::SearchCPAN;
use strict;
use LWP::Simple qw(get);
use XML::XPath;
use JSON;
use Combust::Cache;

my $json = JSON->new->utf8;

sub new {
  my ($proto, %args) = (shift, @_);
  my $class = ref $proto || $proto;
  my $self = { };
  bless( $self, $class);
}

sub search_distribution {
  shift->_search('dist', @_);
}

sub _search {
  my ($self, $mode, $query) = @_;

  return unless $query;

  my $cache = Combust::Cache->new(type => "CR.search");

  my $data = $cache->fetch(id => "search.module;$mode;$query");

  if ($data) {
    $data = $data->{data};
  }
  else {
    my $url = "http://search.cpan.org/search?query=$query&mode=$mode&format=xml";
    #warn "fetching $url from search.cpan";
    $data = get $url;
    my @results;
    if ($data) {
      my @results; 

      my $xp = XML::XPath->new(xml => $data);
      foreach my $module ($xp->find("/results/$mode")->get_nodelist){
	#print $module->find('name')->string_value, "\n";
	#print $module->find('version')->string_value, "\n";
	my $author_link = $module->find('author/link')->string_value;
	my $author = { link => $author_link };
	$author->{id} = $author_link;
	$author->{id} =~ s!.*author/([A-Z]+)/$!$1!;
	my $distribution = $module->find('link')->string_value;
	$distribution =~ s!(.*?author/[A-Z]+/([^/]+)).*!$2!;
	my $distribution_link = $1 ? $1 . "/" : '' ;
	$distribution =~ s!-\d+(\.\d+)?(_\d+)?$!!;
        
        my $name = $module->find('name')->string_value;

	push @results, { name    => $name,
			 description => $module->find('description')->string_value,
			 version => $module->find('version')->string_value,
			 link    => $module->find('link')->string_value,
			 author  => $author,
			 distribution => { name => $name,
					   link => $distribution_link,
					 },
		       };
      }
      $data = \@results;
    }
    else {
      $data = [];
    }
    $cache->store(data => $data, expires => 6*60*60);
  }
  #warn "Got data: $data";

  #use Data::Dumper;
  #  warn Data::Dumper->Dump([\$data], [qw(data)]);
  
  $data;
}

sub _distribution_page {
  my ($self, $distribution) = @_;
  my $cache = Combust::Cache->new(type => 'CR.search');

  my $data;
  if ($data = $cache->fetch(id => "dist-page;d:$distribution")) {
    return $data->{data};
  }

  $data = get("http://search.cpan.org/dist/$distribution/");

  my $ttl = $data =~ m/cannot be found, did you mean one of these/ ? 3 * 3600 : 24 * 3600;

  $cache->store(data => $data, expires => 24 * 3600);

  $data;
}

sub valid_distribution {
  my ($self, $distribution) = @_; 
  my $page = $self->_distribution_page($distribution);
  return 0 if $page =~ m/cannot be found, did you mean one of these/;
  return 1;
}

sub get_releases {
  my ($self, $distribution) = @_; 

  my $cache = Combust::Cache->new(type => 'CR.search');

  if (my $data = $cache->fetch(id => "releases;d:$distribution;2")) {
    return $data->{data};
  }

  my $json_data = get "http://search.cpan.org/api/dist/$distribution";
  my $data = $json->decode($json_data);

  #warn Data::Dumper->Dump([\$data], [qw(data)]);

  $cache->store(data => $data->{releases}, expires => 3 * 3600);

  $data->{releases};

}



1;

