package Combust::Site;
use Moose;
use Combust::Router;

use overload '""' => \&_overload, fallback => 1;
sub _overload {
    return shift->name;
}

has 'name' => (
   is       => 'rw',
   isa      => 'Str',
   required => 1,
);

has 'router' => (
   is  => 'ro',
   isa => 'Combust::Router',
   default => sub { Combust::Router->new },
);

has 'domain' => (
   is  => 'rw',
   isa => 'Str',
   required => 1,   
);

has 'domain_aliases' => (
   traits     => ['Array'],
   is  => 'rw',
   isa => 'ArrayRef[Str]',
   default    => sub { [] },
   handles => {
     domain_alias_list => 'elements',
   },
);


no Moose;
__PACKAGE__->meta->make_immutable;
