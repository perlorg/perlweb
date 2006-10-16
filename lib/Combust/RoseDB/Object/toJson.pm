package Combust::RoseDB::Object::toJson;
use strict;

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

sub toJson {
  my $self = shift;
  my %hash;

  foreach my $column ($self->_json_columns) {
    my $name = ref($column) ? $column->name : $column;
    my $v = $self->$name; 
    if (ref($v)) {
      if ($v->isa('DateTime')) {
        my $meth = $date_formatter{$column->type};
        $v = $v->$meth; # strftime($date_format{$column->type});
      }
    }
    $hash{$name} = $v if defined $v;
  }

  foreach my $rel ($self->_json_relationships) {
    my $is_array = $rel->type =~ /many$/i;
    my $name = $rel->name;
    if ($is_array) {
      $hash{$name} = [ map { $_->toJson } $self->$name ];
    }
    else {
      $hash{$name} = $self->$name;
    }
  }

  \%hash;
}

1;
