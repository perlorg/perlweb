package CPANRatings::Control::Show;
use strict;
use base qw(CPANRatings::Control);
use CPANRatings::Model::Reviews;
use CPANRatings::Model::SearchCPAN qw();
use XML::RSS qw();

sub handler ($$) {
  my ($self, $r) = @_;

  my ($mode, $id, $format) = ($r->uri =~ m!^/([ad])/([^/]+?)(?:\.(html|rss))?$!);
  return 404 unless $mode and $id;

  $mode = "author" if $mode eq "a";
  $mode = "distribution" if $mode eq "d";

  $format = $r->param('format') || $format || 'html';
  $format = 'html' unless $format eq "rss";

  my $template = 'display/list.html';

  $self->param('mode' => $mode);
  $self->param('header' => "$id reviews" ) if $mode eq "distribution";

  if ($mode eq "author") {
    my ($first_review) = CPANRatings::Model::Reviews->search_author($id);
    $self->param('header' => "Reviews by " . $first_review->user_name) if $first_review;
  }
  else {

    unless (CPANRatings::Model::SearchCPAN->valid_distribution($id)) {
      return 404;
    }
    my ($first_review) = CPANRatings::Model::Reviews->search(distribution => $id);
    $self->param('distribution' => $first_review->distribution) if $first_review;
    $self->param('distribution' => $id) unless $first_review;
  }

  my $reviews = CPANRatings::Model::Reviews->search(
						    ($mode eq "author" ? "user_id" : $mode)
						    => $id,
						    { order_by => 'updated desc' }
						   );


  $self->param('reviews' => $reviews); 


  my $output;

  my $content_type = '';

  if ($format eq "html") {
    $content_type = 'text/html';
    $self->evaluate_template($r, output => \$output, template => $template, params => $self->params);
  }
  elsif ($format eq "rss") {
    my $rss = new XML::RSS (version => '1.0');
    my $link = "http://" . $self->config->site->{cpanratings}->{servername} 
                  . ($mode eq "author" ? "/a/" : "/d/")
		  . $id;

    $rss->channel(
		  title        => "CPAN Ratings: " . $self->param('header'),
		  link         => $link, 
		  # description  => "the one-stop-shop for all your Linux software needs",
		  dc => {
			 date       => '2000-08-23T07:00+00:00',
			 subject    => "Perl",
			 creator    => 'ask@perl.org',
			 publisher  => 'ask@perl.org',
			 rights     => 'Copyright 2003, The Perl Foundation',
			 language   => 'en-us',
			},
		  syn => {
			  updatePeriod     => "daily",
			  updateFrequency  => "1",
			  updateBase       => "1901-01-01T00:00+00:00",
			 },
#		  taxo => [
#			   'http://dmoz.org/Computers/Internet',
#			   'http://dmoz.org/Computers/PC'
#			  ]
		 );

    my $reviews = $self->param('reviews');
    my $i; 
    while (my $review = $reviews->next) {
      my $text = substr($review->review, 0, 150);
      $text .= " ..." if (length $text < length $review->review);
      $rss->add_item(
		     title       => ($mode eq "author" ? $review->distribution : $review->user_name),
		     link        => "$link#" . $review->review_id,
		     description => $text,
		     dc => {
			    #subject  => "X11/Utilities",
			    creator  => $review->user_name,
			   },
		    );    
      last if ++$i == 10;
    }
    
    $output = $rss->as_string;
    $output = Encode::encode('utf8', $output);
    $self->{_utf8} = 1;
    $content_type = 'application/rdf+xml';
  }

  $self->send_output(\$output, $content_type);
}

1;
