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
  my $psh = new Pod::Simple::HTML();
  $psh->output_string( \$out );
  $psh->parse_string_document( $data->{text} );

  # cheat and extract title (hacky!)
  my ($title) = $out =~ m!<title>(.+?)</title>!i;

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
