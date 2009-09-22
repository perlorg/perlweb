package Combust::API;
use strict;
use Class::Accessor::Class;
use base qw(Class::Accessor::Class);
use JSON::XS qw();

my $json; 

sub _json {
    return $json if $json;
    $json = JSON::XS->new;
    $json->utf8(1);   # we need JSON::XS to handle UTF-8 correctly
    $json->pretty(1); # should be devel mode only
    $json->convert_blessed(1);
    return $json;
}

sub setup_api {
    my ($class, %classes) = @_;
    $class->mk_class_accessors(qw(api_classes));
    $class->api_classes({});
    for my $group (keys %classes) {
      my $api_class = $classes{$group};
      my $mod = "${class}::${api_class}";
      $class->api_classes->{$group} = $mod;
      $mod =~ s!::!/!g;
      require "$mod.pm";
  }
}

sub setup_api_call {
    my ($class, $name, $args) = @_;

    my $group;
    my $method;

    if (($group) = ($name =~ m{^(\w+)/?$})) {
        $method = 'index';
    }
    else {
        ($group, $method) = ($name =~ m{^(\w+)/([a-z]\w*)/?$});
    }

    die "Invalid method name\n" unless $group and $method;

    my $subclass = $class->api_classes->{$group}
      or die qq[No class "$group"\n];

    $method = 'index' if $method eq '';

    unless ($method and $subclass->can($method)) {
        return die qq[No method "$method"\n];
    }

    my $sc = $subclass->new( args => $args );

    return bless { 
                  name   => $name,
                  api    => $sc, 
                  method => $method,
                  args   => $args,
                 }, $class;
}

sub call {
    my $class = shift;

    my $self = $class->setup_api_call(@_);  # ($name, $args)
    
    my ($result, $meta) = eval { 
        my $method = $self->{method};
        $self->{api}->$method
    };
    
    if (my $err = $@) {
        die  $self->{name} . ": $err\n";
    }
    
    #warn Data::Dumper->Dump([\$result], [qw(api_result)]);

    if ($self->{args}->{json}) {
        $result = $class->_json->encode($result);
    }

    #warn Data::Dumper->Dump([\$result], [qw(api_json__)]);
    
    return ($result, $meta);
}


1;
