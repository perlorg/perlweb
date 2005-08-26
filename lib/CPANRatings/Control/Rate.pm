package CPANRatings::Control::Rate;
use strict;
use base qw(CPANRatings::Control);
use CPANRatings::Model::Reviews;
use POSIX qw(strftime);
use Apache::Util qw();
use Apache::Constants qw(OK);

sub render {

  my $self = shift;

  my $r = $self->r;

  return $self->render_helpful_vote if $r->uri =~ m!^/rate/helpful!; 

  my ($submit) = $r->uri =~ m!^/rate/submit!;

  my $template = 'rate/rate_form.html';

  return $self->login
    unless $self->is_logged_in; 

  $self->tpl_param('user' => $self->user_info);

  $self->tpl_params->{module} = $self->req_param('module');

  my $distribution = $self->req_param('distribution');

  return $self->error('Distribution name required')
    unless $distribution;

  return $self->error('No such distribution: ' . $distribution)
    unless CPANRatings::Model::SearchCPAN->valid_distribution($distribution);

  $self->tpl_params->{distribution} = { name => $distribution,
					releases => CPANRatings::Model::SearchCPAN->get_releases($distribution),
				      };

  if ($submit) {
    my $errors = {};

    # TODO should check if the module is valid for the distribution

    my @fields = qw(rating_1 rating_2 rating_3 rating_4 rating_overall review version_reviewed module distribution);
    my %data;
    for my $f (@fields) {
      $data{$f} = Apache::Util::escape_html($r->param($f) || '');
      if (grep { $f eq $_ } qw(distribution version_reviewed review)) {
	$errors->{$f} = "Required field"
	  unless defined $data{$f} and $data{$f} ne "";
      }
    }

    $data{user} = $self->user_info->id;
    $data{user_name} = $self->user_info->name || $self->user_info->username;

    unless (%$errors) {

      $data{updated} = strftime "%Y-%m-%d %T", localtime
	unless $self->req_param('minor_edit');

      my $review;
      if (($review) = CPANRatings::Model::Reviews->search(distribution => $data{distribution},
							  module       => $data{module},
							  user         => $data{user_id},
							 )) {
	for my $f (keys %data) {
	  $review->$f($data{$f});
	}
	$review->update;
      }
      else {
	$review = CPANRatings::Model::Reviews->create(\%data);
      }

      $self->tpl_param('review', $review);

      $template = 'rate/rate_submitted.html';
    } 
    else {
      $self->setup_rate_form;
      $self->tpl_param(errors => $errors);
    }
  }
  else {

    my ($review) = CPANRatings::Model::Reviews->search(distribution => $distribution,
						       module       => $self->tpl_param('module') || '',
						       user         => $self->user_info->id,
						      );

    if ($review) {
      $self->tpl_param('review', $review);
      #warn $review->rating_overall;
    }

    $self->setup_rate_form;
  }

  return OK, $self->evaluate_template($template);
}

sub setup_rate_form {
  my $self = shift;

  $self->tpl_params->{questions} = 
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

  $self->tpl_param(error => {message => $message});

  $self->r->update_mtime(time);

  return OK, $self->evaluate_template('rate/rate_error.html');
}

sub render_helpful_vote {
  my $self = shift;

  my $review_id = $self->req_param('review_id') || '';
  my $vote      = $self->req_param('v') || '';

  $review_id = ''  unless $review_id =~ m/^\d+$/;

  $vote =~ m/^[yn]$/ or return $self->_return_helpful_vote($review_id, 'BADVOTE');

  my $user = $self->user_info or return $self->_return_helpful_vote($review_id, 'UNRECOGNIZED');

  my $review = CPANRatings::Model::Reviews->retrieve($review_id)
    or return $self->_return_helpful_vote($review_id, 'SERVICE-FAILURE');

  return $self->_return_helpful_vote($review_id, 'ILLEGAL') if $review->user->id == $user->id;

  my $updated = $review->add_helpful({ user => $user, helpful => $vote eq 'y' ? 1 : 0 });

  $self->_return_helpful_vote($review_id, 'SERVICE-FAILURE')
    unless $updated;
  
  $self->_return_helpful_vote($review_id, 'SUCCESS',
                              ($updated == 2 
                                 ? "We'll update your vote." 
                                 : 'Your vote will be counted within a couple of hours.'
                              )
                             );

}

sub _return_helpful_vote {
  my ($self, $review_id, $code, $value) = @_;

  $value = $value || '';

  # SUCCESS 
  # BADVOTE
  # UNRECOGNIZED
  # SERVICE-FAILURE
  # ILLEGAL
 
  my $msg = <<EOV;
<html>
<head><title>CPAN Ratings</title>

<script language="Javascript1.1" type="text/javascript">
<!--
parent.showYesNoCommunityResponse("$review_id","$code","$value");
//-->
</script>
</head>
</html>


EOV

  return OK, \$msg;

}

1;

__END__

