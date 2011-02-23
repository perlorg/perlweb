package Combust::Router;
use Moose;
use MooseX::NonMoose;
use Router::Simple ();
use Config::General ();
extends 'Router::Simple';

use namespace::clean -except => 'meta';


no Moose;
__PACKAGE__->meta->make_immutable;
