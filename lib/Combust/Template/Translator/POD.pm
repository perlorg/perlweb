
package Pod::Simple::HTML::Combust;
use base qw(Pod::Simple::HTML);

# stub out the Pod::Simple::HTML do_beginning and do_end methods which
# deal with the page header and footer.

sub do_beginning {
  return 1;
}

sub do_end {
  return 1;
}

# As of Pod::Simple 0.97 and Pod::Simple::PullParser 1.03, we no
# longer need our private hack.  (Except for the "TITLE" thing)
# a temporary fix until Pod::Simple::PullParser catches up
sub get_title_aside {
  my $self = shift;
  my $max_tokens = 25;
  my $title;
  my @to_unget;
  my $state = 0;
  my $depth = 0;

  while($max_tokens-- and defined(my $token = $self->get_token)) {
    push @to_unget, $token;
    if ($state == 0) {
      ++$state if $token->is_start and $token->tagname eq 'head1';
    }
    elsif($state == 1) {
      --$state if $token->is_end and $token->tagname eq 'head1';
      if ($token->is_text) {
	# allow poorly formed pod where people do
	# =head1 this is the title
	$title = $token->text unless defined $title;
	++$state if ($token->text eq 'TITLE' or $token->text eq "NAME");
      }
    }
    elsif($state == 2) {
      $title = "";
      ++$state, $depth=0 if $token->is_end and $token->tagname eq 'head1';
    }
    elsif($state == 3) {
      $depth++ if $token->is_start;
      last if $token->is_end and --$depth == 0;
      $title .= $token->text if $token->is_text;
    }
  }

  # Put it all back:
  $self->unget_token(@to_unget);

  return '' unless defined $title;
  $title =~ s/^\s+//;
  return $title;
}

sub resolve_pod_page_link {
  my($self, $to, $section) = @_;
  # section shouldn't be used here

  # this mostly works, but Pod::Simple doesn't think a pod_page_link
  # is absolute.  Probably a bug.
  #if ($to =~ /^perl/) {
  #  return 'http://www.perldoc.com/perl5.8.4/pod/' . $to;
  #}

  return undef;                 # the default returning TODO sucks
}

package Combust::Template::Translator::POD;
use strict;
use Template::Document;
use Pod::Simple;
use Pod::Simple::HTML;

sub new {
  my ($proto, %args) = (shift, @_);
  my $class = ref $proto || $proto;
  bless( {} , $class);
}

sub translate {
  my ($self, $data) = @_;

  my $out;
  my $psh = new Pod::Simple::HTML::Combust();
  $psh->no_errata_section(1);
  $psh->complain_stderr(1);
  $psh->output_string( \$out );
  $psh->set_source( \( $data->{text} ) );
  my $title = $psh->get_title_short( );
  $psh->run;

  Template::Document->new({
			   BLOCK => sub { $out },
			   METADATA => {
					translator => 'POD',
					title => $title,
				       }
			  })
      or die $Template::Document::ERROR;

}

1;
