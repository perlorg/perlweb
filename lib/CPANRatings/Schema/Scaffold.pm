package CPANRatings::Schema::Scaffold;
use Moose;
extends 'Mesoderm';

my %no_serialize = (
   reviews      => [ qw( module ) ],
   review_users => [ qw( id bitcard_id content_suppressed ) ],
);

override column_info => sub {
    my ($self, $column) = @_;
    my $info = super;
    if ($column->{data_type} =~ m/(DATE|TIME)/) {
        $info->{timezone} = 'UTC';
    }
    if (my $columns = $no_serialize{ $column->table->name } ) {
        my $column_name = $column->name;
        $info->{is_serializable} = 0
          if grep { $_ eq $column_name } @$columns;
    }

    $info->{is_serializable} = 1
      if $column->name eq 'review' and $column->table->name eq 'reviews';

    return $info;
};


sub ignore_table {
    my ($self, $table) = @_;
    return 1 if $table->name =~ m/_old$/;
    return 0 if $table->name =~ m/^review/;
    return 1;
}

override 'table_moniker'         => sub { __accessor(@_) };
override 'relationship_accessor' => sub { __accessor(@_) };
override 'mapping_accessor'      => sub { __accessor(@_) };

sub __accessor {
    my $a = super;
    $a =~ s/reviews?_//;
    return $a;
}

override table_components => sub {
    my ($self, $table) = @_;
    my @components = super;
    push @components, 'Helper::Row::ToJSON', 'InflateColumn::DateTime';
    return @components;
};

1;
