package Combust::Template::Translator::POD;
use strict;
use Template::Document;

sub new {
  my ($proto, %args) = (shift, @_);
  my $class = ref $proto || $proto;
  bless( {} , $class);
}

sub translate {
  my ($self, $data) = @_;

  my $out = uc $data->{text};

  Template::Document->new({
			   BLOCK => sub { $out },
			   METADATA => {
					translator => 'POD',
					title => 'POD Title!', 
				       }
			  })
      or die $Template::Document::ERROR;

}

1;
