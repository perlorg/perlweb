package Combust::API;
use strict;

use base qw(Class::Accessor::Class);
__PACKAGE__->mk_class_accessors(qw(api_classes));

use JSON;
use Data::Dumper::Simple;

my $json = JSON->new(selfconvert => 1, pretty => 1);

sub setup_api {
    my ($class, %classes) = @_;
    $class->api_classes({});
    for my $group (keys %classes) {
      my $api_class = $classes{$group};
      my $mod = "${class}::${api_class}";
      $class->api_classes->{$group} = $mod;
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
    
    my $subclass = $class->api_classes->{$group}
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
