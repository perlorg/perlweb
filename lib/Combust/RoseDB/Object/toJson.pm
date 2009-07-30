package Combust::RoseDB::Object::toJson;
use strict;
use Scalar::Util;
use JSON::XS;

sub _json_columns {
  shift->meta->columns;
}

sub _json_relationships {
  return;
}

my %date_format = (
  'datetime' => '%a %d %b %Y %H:%M',
  'timestamp'=> '%a %d %b %Y %H:%M',
  'date'     => '%a %d %b %Y',
  'time'     => '%H:%M',
);          

my %date_formatter = (
  datetime  => 'iso8601',
  timestamp => 'iso8601',
  date      => 'ymd',
  time      => 'hms',
);

sub get_data_hash {
  my $self = shift;
  my %hash;

  foreach my $column ($self->_json_columns) {
    my $name = ref($column) ? $column->accessor_method_name : $column;
    $name = $column->name 
      if $name =~ /^_/ and ref($column) and $name eq "_" . $column->name;
    my $v = $self->$name; 
    if (Scalar::Util::blessed($v)) {
      if ($v->isa('DateTime')) {
        my $meth = $date_formatter{$column->type};
        $v = $v->clone->set_time_zone('UTC')->$meth;
        $v .= "Z" if $meth eq 'iso8601';
      }
    }
    $hash{$name} = $v if defined $v;
  }

  foreach my $rel ($self->_json_relationships) {
    my $is_array = $rel->type =~ /many$/i;
    my $name = $rel->name;
    if ($is_array) {
      $hash{$name} = [ map { $_->TO_JSON } $self->$name ];
    }
    else {
      $hash{$name} = $self->$name;
    }
  }

  \%hash;
}

# JSON::XS
sub TO_JSON {
    my $self = shift;
    $self->get_data_hash;
}


1;
