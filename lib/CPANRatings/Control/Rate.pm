package CPANRatings::Control::Rate;
use strict;
use base qw(CPANRatings::Control);
use CPANRatings::Model::Reviews;
use POSIX qw(strftime);
use Apache::Util qw();

sub handler($$) {
  my ($self, $r) = @_;

  my ($submit) = $r->uri =~ m!^/rate/submit!;

  my $template = 'rate/rate_form.html';

  return $self->login
    unless $self->is_logged_in; 

  $self->param('user' => $self->user_info);

  my $x = $r->parms;
  for my $f (keys %$x) {
    warn "$f -> $x->{$f}";
  }


  $self->params->{module} = $r->param('module');

  my $distribution = $r->param('distribution');

  return $self->error('Distribution name required')
    unless $distribution;
  
  $self->params->{distribution} = { name => $distribution,
				    versions => [ CPANRatings::Model::SearchCPAN->get_versions($distribution) ],
				  };

  if ($submit) {
    my $errors = {};

    # TODO should check if the module is valid for the distribution

    my @fields = qw(rating_1 rating_2 rating_3 rating_4 rating_overall review version_reviewed module distribution);
    my %data;
    for my $f (@fields) {
      $data{$f} = Apache::Util::escape_html($r->param($f) || '');
      if (grep { $f eq $_ } qw(distribution version_reviewed review rating_overall)) {
	$errors->{$f} = "Required field"
	  unless defined $data{$f};
      }
    }

    $data{user_id} = $self->user_info->{user_id};
    $data{user_name} = $self->user_info->{name} || $self->user_info->{login};

    unless (%$errors) {

      $data{updated} = strftime "%Y-%m-%d %T", localtime;

      my $review;
      if (($review) = CPANRatings::Model::Reviews->search(distribution => $data{distribution},
							  module       => $data{module},
							  user_id      => $data{user_id},
							 )) {
	for my $f (keys %data) {
	  $review->$f($data{$f});
	}
	$review->update;
      }
      else {
	$review = CPANRatings::Model::Reviews->create(\%data);
      }

      $self->param('review', $review);

      $template = 'rate/rate_submitted.html';
    } 
    else {
      $self->setup_rate_form;
      $self->param(errors => $errors);
    }
  }
  else {

    my ($review) = CPANRatings::Model::Reviews->search(distribution => $distribution,
						       module       => $self->param('module'),
						       user_id      => $self->user_info->{user_id},
						      );

    if ($review) {
      $self->param('review', $review);
      warn $review->rating_overall;
    }

    $self->setup_rate_form;
  }

  my $output;
  $self->evaluate_template($r, output => \$output, template => $template, params => $self->params);
  $r->update_mtime(time);
  $self->send_output($r, \$output);
}

sub setup_rate_form {
  my $self = shift;

  $self->params->{questions} = 
    [{field => 'rating_1',
      name  => 'Documentation'
     },
     {field => 'rating_2',
      name  => 'Interface',
     },
     {field => 'rating_3',
      name  => 'Ease of Use',
     },
     {field => 'rating_overall',
      name  => 'Overall',
     },
    ];
}

sub error {
  my ($self, $message) = @_;

  $self->param(error => {message => $message});

  my $r = $self->r;

  my $output;
  $self->evaluate_template($r, output => \$output, template => 'rate/rate_error.html', params => $self->params);
  $r->update_mtime(time);
  $self->send_output($r, \$output);

}

1;
