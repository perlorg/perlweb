package RRE::Control::RSS;
use strict;
use base 'RRE::Control';
use RRE::Model;

sub handler($$) {

  my ($class, $r) = @_;

  warn "RSS RRE Handler!";
  warn "RSS URI: ", $r->uri;

  my $template = 'rss.xml';
  my $content_type = 'application/rss+xml';
  my $uri = $r->uri;

  my $rre = RRE::Model->new();
  my $params = { rre => $rre };

  my $cache = Combust::Cache->new(type => 'rre');

  if (my $d = $cache->fetch(id => "rss;$uri" )) {
    return $class->send_cached($r, $d, $content_type);
  }


  my @entries;
  if ($uri =~ m!^/rss/mails.xml$!) {
    @entries = $rre->get_mails({limit => 10});
    @entries = map { $_->{title} = $_->{subject};
		     $_->{cdata} = $_->body_html;
		     $_ } @entries;
    $params->{title} = 'Mails';
  }
  elsif ($uri =~ m!^/rss/links.xml$!) {
    @entries = $rre->get_links({limit => 140});
    @entries = map { $_->{title} = $_->title;
		     $_->{cdata} = $_->body_html;
		     $_ } @entries;
    $params->{title} = 'Links'; 
  }
  elsif ($uri =~ m!^/rss/notification.xml$!) {
    @entries = $rre->get_mails({limit => 10});
    @entries = map { $_->{title} = $_->{subject};
		     $_->{cdata} = $_->body_html;
		     $_->{cdata} =~ s/^((.*?<p>){8})(.*)/$1/sm;
		     $_->{cdata} .= qq[<p><a href="]. $_->fqdn_url . qq[">Continued ...</a>]
                       if $2;
		     
		     $_ } @entries;
    $params->{title} = 'Mails';
  }

  else {
    return 404;
  }    

  $params->{entries} = \@entries;

  my $output;
  my $rv = $class->evaluate_template($r,
				     output => \$output,
				     template => $template,
				     params => $params,
				    );

  $output =~ s/^\s*//s;

  if ($@) {
    $r->pnotes('error', $@);
    return 404 if $@ =~ m/not found$/;
    return 500; 
  }

  $cache->store(data => $output,
		meta_data => { content_type => $content_type },
		expire => 86400*2,
	       );

  $class->send_output($r, \$output, $content_type);

}


1;
