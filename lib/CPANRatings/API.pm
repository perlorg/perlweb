package CPANRatings::API;
use strict;
use Class::Accessor::Fast;
use JSON;

use Data::Dumper::Simple;

my $json = JSON->new(selfconvert => 1, pretty => 1);

my %classes;
BEGIN {
    %classes = (
                'test'    => 'Test',
                'helpful' => 'Helpful',
    );

    for my $group (keys %classes) {
      my $class = $classes{$group};
      my $mod = "CPANRatings::API::$class";
      $classes{$group} = $mod;
      $mod =~ s!::!/!g;
      require "$mod.pm";
  }
}

sub new {
    my ($class) = shift;
    bless {@_}, $class;
}

sub call {
    my ($class, $name, $args) = @_;

    my ($group, $method) = ($name =~ m!^(\w+)/?([a-z]\w+)?!);
    die "Invalid method name\n" unless $group and $method;
    
    my $subclass = $classes{$group}
      or die qq[No class "$group"\n];
    
    unless ($method and $subclass->can($method)) {
        return die qq[No method "$method"\n];
    }
    
    # TODO:
    #  start DB transaction here (tricky with CDBI, grrh)
    
    my $sc = $subclass->new( args => $args ); # db => $db );
    
    my ($result, $meta) = eval { $sc->$method };
    
    #warn Dumper(\$method, \$result, \$meta);
    
    if (my $err = $@) {
        # $db->rollback;
        die "$name: $err\n";
    }
    
    #  $db->commit;
    
    #warn Data::Dumper->Dump([\$result], [qw(api_result)]);
    
    if ($args->{json}) {
        $result = $json->objToJson($result);
    }
    
    return ($result, $meta);

}

sub user {
    shift->args->{user}
}

sub args {
    shift->{args};
}

sub _required_param {
    my $self = shift;
    my $p = $self->args->{params};
    if (my @missing = grep { !defined $p->{$_} || $p->{$_} eq '' } @_) {
      die( (@missing == 1)
           ? "Required parameter @missing missing\n"
           : "Required parameters (@missing) missing\n");
  }
    return @{$p}{@_};
}

sub _optional_param {
    my $self = shift;
    my $p = $self->args->{params};
    return @{$p}{@_};
}


1;
