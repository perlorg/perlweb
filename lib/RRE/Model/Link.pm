package RRE::Model::Link;
use strict;
use Develooper::DB qw(db_open);
use URI::Find;
use URI::Escape qw(uri_escape);

sub new {
  my $proto = shift;
  my $class = ref $proto || $proto;
  my $args = shift;
  my $self = bless( $args, $class);
  return $self;
}

sub title {
  my $self = shift;
  my $title = $self->{comment};
  $title =~ s/\n.*//;
  $title;
}

sub urls {
  my $self = shift;
  return $self->{_urls} if $self->{_urls};
  my $dbh = db_open();
  $self->{_urls} = $dbh->selectcol_arrayref(
                           q[select url from rre_urls where link_id=? order by url_id],
                           {},
                           $self->{link_id}
                   );
  return $self->{_urls} || [];
}

sub body {
  my $self = shift;
  join "\n", $self->{comment}, @{$self->urls};
}  

sub fqdn_url {
  my $self = shift;
  (@{$self->urls})[0] || '';
}

sub body_html {
  my $self = shift;
  my $body = $self->body;

  my $url_finder = URI::Find->new
    (
     sub {
       my ($uri, $orig_uri) = @_;
       $uri = qq[<a href="$uri">$uri</a>];
       $uri;
     }
    );

  $url_finder->find(\$body);

  #$body =~ s!\n([^\n]{2,50})\n\n!\n<h3>$1</h3>\n\n!g;

  my $url = $self->fqdn_url;

  #$body =~ s!<h3>(.*?)</h3>!my $n = uri_escape($1); qq[<h3><a name="$n" href="$url#$n">$1] 
  #                                                   . '</a></h3>'!ge;

  $body =~ s/\n\n/<p>/g;
  $body =~ s!\n!<br />\n!g;

  return $body;
}


1;
