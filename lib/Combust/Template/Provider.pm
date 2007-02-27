package Combust::Template::Provider;
use strict;
#use base qw(Combust::Template::Provider::Base);
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


1;
