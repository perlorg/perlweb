package Trivial::App;
use Moose;
extends 'Combust::App';
with 'Combust::App::ApacheRouters';
with 'Combust::Redirect';


1;

