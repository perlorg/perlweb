package Combust::Template::Provider;
use strict;
use base qw(Combust::Template::Provider::Base);

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
      last INCPATH
	if -d $path;
    }

  }

  return $path ? 1 : 0;
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
	   time => ((stat $path)[9] || 0),
	  };
}


1;
