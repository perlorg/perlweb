
package Pod::Simple::HTML::Combust;
use base qw(Pod::Simple::HTML);

# this would be cool, but is a little too big, and we can't hide it in
# a =begin html block.
# sub index { shift->_get_titled_section('INDEX', desperate => 1, @_); }

# support both NAME and TITLE
sub get_title {
  my $x = shift;
  $x->_get_titled_section(
   'NAME', max_token => 50, desperate => 1, @_)
  ||
  $x->_get_titled_section(
   'TITLE', max_token => 50, desperate => 1, @_)
}

# stub out the Pod::Simple::HTML do_beginning and do_end methods which
# deal with the page header and footer.

sub do_beginning {
  return 1;
}

sub do_end {
  return 1;
}

# The Pod::Simple 3.x version is much better, and links to
# search.cpan.org.  But for now, we'll keep it empty.
sub resolve_pod_page_link {
  my($self, $to, $section) = @_;
  return undef;                 # the default returning TODO sucks
}

package Combust::Template::Translator::POD;
use strict;
use Template::Document;
use Pod::Simple 3.02;
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
