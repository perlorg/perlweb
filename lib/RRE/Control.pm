package RRE::Control;
use strict;
use base 'Combust::Control';
use Combust::Template::Provider;
use RRE::Model;
use Combust::Cache;

sub handler($$) {
  my ($class, $r) = @_;

  $r = Apache::Request->instance($r);

  #warn "RRE Handler!";
  #warn "RURI: ", $r->uri;

  my $template = '';
  my $content_type = 'text/html';
  my $uri = $r->uri;
  
  $uri =~ s!/$!/index.html!;

  my $cache = Combust::Cache->new(type => 'rre');

  if (my $d = $cache->fetch(id => "html;$uri" )) {
    return $class->send_cached($r, $d, $content_type)
      unless $r->param('cache_bypass');
  }

  my $rre = RRE::Model->new();
  my $params = { rre => $rre };

  if ($uri =~ m!^/index.html$!) {
    $template = "index.html"; 
  }
  elsif ($uri =~ m!^/rss/(index\.html)$!) { 
    warn "DSSS!";
    $template = "rss.html";
  } 
  elsif($uri =~ m!^/(\d{4}(/\d{2}){2}/a(\.\d{2}){3})\.html$!) {
    my $date = $1;
    $date =~ s!/a\.! !;
    $date =~ s!/!-!g;
    $date =~ s!\.!:!g;
    my $mail = RRE::Model::Mail->load({ date => $date });
    return 404 unless $mail->{mail_id};

    $r->update_mtime($mail->{unixtime});

    $params->{mail} = $mail;

    $template = "mail.html";
  }
  else {
    return 404;
  }    

  my $output;
  my $rv = $class->evaluate_template($r,
				     output => \$output,
				     template => $template,
				     params => $params,
				    );
  if ($@) {
    $r->pnotes('error', $@);
    return 404 if $@ =~ m/not found$/;
    return 500; 
  }

  $cache->store(data => $output,
		meta_data => { content_type => $content_type },
		expire => 86400*2,
		purge_key => "rre",
	       );

  $r->update_mtime(time);

  $class->send_output($r, \$output, $content_type);
}

1;
