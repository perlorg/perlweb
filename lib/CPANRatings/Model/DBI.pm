package CPANRatings::Model::DBI;
use strict;
use base qw(Class::DBI::mysql);
use Develooper::DB qw(db_open);

sub dbh {
  shift->db_Main;
}

sub db_Main { 
  my $class = shift;
  return db_open('combust', {$class->_default_attributes})
}

sub get {
  my $self = shift;
  my $attr = shift;
  
  my $data = $self->SUPER::get($attr, @_);
  my $data2;

  if ($] > 5.007) {
    #Encode::_utf8_on($data);
    $data2 = Encode::decode_utf8($data);
  }
  
  return defined $data2 ? $data2 : $data;
}

1;
