package Combust::Control::Error;
use strict;
use base 'Combust::Control';
#use Develooper::SendMail qw(sendmail);

sub handler ($$) {
  my ($class, $r) = @_;

  # should use notes->param maybe ... hmn.
  $r = Apache::Request->instance($r);

  $r->uri =~ m!^/error/(\d+)!;
  my $error = $1 || 404;

  my $template = "error/error.html";

  my $error_header = "";
  $error_header = 'File not found' if $error == 404;
  $error_header = 'Server Error'   if $error == 500;

  my $error_text = $r->pnotes('error') || '';

  my $params = { error        => $error,
		 error_header => $error_header,
		 error_text   => $error_text, 
	       };

  # is this right?  
  my $r_err = $r->main || $r->prev || $r;
  $params->{error_uri} = $r_err->uri;

#  if ($error == 500) {
#    sendmail(to => 'ask@develooper.com',
#	     from => 'ask-metamark-errors@develooper.com',
#	     subject => 'Metamark server error - ' . $params->{error_uri},
#	     body => "Who knows what the error was by now?  Check the log!",
#	    );
#  }

  my $output;
  $class->evaluate_template($r, output => \$output, template => $template, params => $params);
  $class->send_output($r, \$output);
}

1;
