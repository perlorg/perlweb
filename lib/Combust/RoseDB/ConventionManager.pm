package Combust::RoseDB::ConventionManager;

use base qw(Rose::DB::Object::ConventionManager);

# This is straight from Rose::DB::Object::ConventionManager 
# except for the thing to catch statuses
sub plural_to_singular {
    my($self, $word) = @_;

    if (my $code = $self->plural_to_singular_function) {
        return $code->($word);
    }

    return $word  if($word =~ /[aeiouy]ss$/i);

    # review_status(es) prefix(es)
    if ($word =~ s/([xs])es$/$1/) {
       return $word;
    }

    $word =~ s/s$//;


    return $word;
}

1;
