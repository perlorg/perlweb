package CPANRatings::Schema::Scaffold;
use Moose;
extends 'Mesoderm';

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

1;
