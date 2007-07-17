package Combust::Template::Provider;
use strict;
use base qw(Template::Provider);

sub is_directory {
  my ($self, $name) = @_;

  # this is ignoring relative and absolute paths; but we don't use
  # those anyway...

  my $path;

 INCPATH: {
    my $paths = $self->paths()
      || return ($self->error(), Template::Constants::STATUS_ERROR);
    
    foreach my $dir (@$paths) {
      $path = "$dir/$name";

      return 1 if -d $path;
    }

  }

  return 0;
}

sub expand_filename {
  my ($self, $name) = @_;

  my $path;

 INCPATH: {
    # otherwise, it's a file name relative to INCLUDE_PATH
    my $paths = $self->paths()
      || return ($self->error(), Template::Constants::STATUS_ERROR);
    
    foreach my $dir (@$paths) {
      $path = "$dir/$name";
      last INCPATH if -f $path;
    }
    undef $path;      # not found
  }

  return +{
	   path => ($path || undef),
	   time => ($path ? ((stat $path)[9] || 0) : 0),
	  };
}

sub _init {
    my $class = shift;
    my $params = $_[0];
    my $self = $class->SUPER::_init(@_);
    $self->{EXTENSIONS} = $params->{EXTENSIONS} || [];
    $self;
}

sub fetch {
    my ($self, $name) = (shift, @_);

    my ($data, $error) = $self->SUPER::fetch(@_);

    if ($error) {
        # no extension to rip off ...
        return ($data, $error) unless $name =~ s/\.[^.]+$//;
        
        for my $ext (@{$self->{EXTENSIONS}}) {
            my $newname = "$name." . $ext->{extension};
            ($data, $error) = $self->{ INCLUDE_PATH } 
            ? $self->load($newname) 
                : (undef, Template::Constants::STATUS_DECLINED);
            
            if (defined $data) {
                $data = {text => $data };
                ($data, $error) = $ext->{translator}->translate($data);
                last;
            }
        }
    }

    return ($data, $error); 
}


1;

__END__

=head1 NAME

Combust::Template::Provider - Combust Template::Provider class

=head1 SYNOPSIS

See L<Template::Provider>

=head1 METHODS

=over 4

=item is_directory

Uses the configured include path to find the specified file and
returns true if it's a directory.

=item expand_filename

Returns the absolute path given the filename (after searching the
template toolkit include path).

=item _init

Takes an extra parameter, EXTENSIONS.  Otherwise deferes to the
regular _init method.

=item fetch

If the template object is configured with EXTENSIONS we'll fall-back
to using the configured translator class to convert the document.  For
example if there's a "pod" translator and a request for F<foo.html>
comes in we'll (if such a file doesn't exist) look for F<foo.pod> and
use the translator to convert.  See L<Combust::Template> and
L<Combust::Template::Translator::POD> for an example.


=back
