package RRE::Control;
use strict;
use base 'Combust::Control';
use Combust::Template::Provider;
use RRE::Model;


sub handler($$) {
  my ($class, $r) = @_;

  warn "RRE Handler!";
  warn "RURI: ", $r->uri;

  my $template = '';
  my $content_type = 'text/html';
  my $uri = $r->uri;

 $r->update_mtime(time);


  $uri =~ s!/$!/index.html!;

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
  $class->send_output($r, \$output, $content_type);
}

1;
