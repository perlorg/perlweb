package Combust::Template::Provider;
use strict;

# This is based on Template::Provider and Slash's DB provider module.
# http://xrl.us/d8j (Link to cvs.slashcode.com)

use base qw(Template::Provider);
use LWP::Simple qw($ua);
use vars qw($DEBUG);

use File::Basename;
use File::Spec::Functions qw(catfile);

$ua->agent('Combust/1.0');

$DEBUG     = $Template::Provider::DEBUG || 0 unless defined $DEBUG;

use constant PREV => 0;
use constant NAME => 1;
use constant DATA => 2;
use constant LOAD => 3;
use constant NEXT => 4;

# store names for non-named templates by using text of template as
# hash key; that it is not VirtualHost-specific is not a problem;
# this just does a name lookup, and the actual template is compiled
# and stored in the VirtualHosts' template objects
{
	my($anon_num, %anon_template);
	sub _get_anon_name {
		my($text) = @_;
		return $anon_template{$text} if exists $anon_template{$text};
		return $anon_template{$text} = 'anon_' . ++$anon_num;
	}
}

# TODO|FIXME: support compiled templates 
sub fetch {
  my($self, $text) = @_;
  my($name, $data, $error, $slot, $size, $compname, $compfile);
  $size = $self->{ SIZE };

  # if reference, then get a unique name to cache by
  if (ref $text eq 'SCALAR') {
    $text = $$text;
    print STDERR "fetch text : $text\n" if $DEBUG > 2;
    $name = _get_anon_name($text);
    $compname = $name if $self->{COMPILE_DIR};

  }
  else {
    # if regular scalar, get proper template ID ("name") from DB
    print STDERR "fetch text : $text\n" if $DEBUG > 1;

    # fix relative stuff too? ...

    $text =~ s!http://!svn-!;
    $compname = "$text;branch:live" if $self->{COMPILE_DIR};
    print STDERR "compname: ",$compname,"\n" if $DEBUG;
    $name = $text;
    undef $text;
  }
  
  if ($self->{COMPILE_DIR}) {
    my $ext = $self->{COMPILE_EXT} || '.ttc';
    $compfile = catfile($self->{COMPILE_DIR}, $compname . $ext);
    warn "compiled output: $compfile\n" if $DEBUG;
  }
  
  # caching disabled so load and compile but don't cache
  if (defined $size && !$size) {
    print STDERR "fetch($name) [nocache]\n" if $DEBUG;
    ($data, $error) = $self->load($name, $text);
    ($data, $error) = $self->_compile($data, $compfile) unless $error;
    $data = $data->{ data } unless $error;
    
    # cached entry exists, so refresh slot and extract data
  }
  elsif ($name && ($slot = $self->{ LOOKUP }{ $name })) {
    print STDERR "fetch($name) [cached:$size]\n" if $DEBUG;
    ($data, $error) = $self->_refresh($slot);
    $data = $slot->[ DATA ] unless $error;
    
    # nothing in cache so try to load, compile and cache
  }
  else {
    print STDERR "fetch($name) [uncached:$size]\n" if $DEBUG;
    ($data, $error) = $self->load($name, $text);
    ($data, $error) = $self->_compile($data, $compfile) unless $error;
    $data = $self->_store($name, $data) unless $error;
  }

  return($data, $error);
}

sub load {
  my($self, $name) = @_;
  my($data, $error, $now, $time);
  $now = time;
  $time = 0;

  print STDERR "load(@_[1 .. $#_])\n" if $DEBUG;
  
  #warn "LOADING NAME: $name" if $DEBUG;
  
  my $text;

  INCLUDE: {
      my $paths = $self->paths() || do {
	$error = Template::Constants::STATUS_ERROR;
	$data  = $self->error();
	last INCLUDE;
      };
      
      foreach my $dir (@$paths) {
	my $path = "$dir/$name";

	# TODO|FIXME: Load compiled version if it exists and check if
	# it's up to date.  (master SVN revision or modtime for
	# svn/file)

	# cache other/raw files too ... (in mysql?  Cache::FileCache?
	# Another abstraction on top of those?)
	
	if ($path =~ m!^http://!i) {
	  warn "getting $path\n";
	  my $response = $ua->get($path);
	  if ($response->is_success) {
	    $text  = $response->content;
	    if (my $etag = $response->header('ETag')) {
	      $time = ($etag =~ m!(\d+)/!)[0];
	      warn "got file with revision $etag\n" if $DEBUG;
	    }
	  }
	  else {
	    $error = $response->status_line;
	  }
	  print STDERR "path: ", $response->code, "\n";
	}
	else {
	  warn "opening file $path\n";
	  if (open(FH, $path)) {
	    $error = undef;
	    #warn "reading $path\n";
	    local $/ = undef;  
	    $text = <FH>;
	    # $name = $alias;  ?!
	    $time = (stat $path)[9],
	  }
	  else {
	    $error = $!;
	  }
	}
	
	last INCLUDE if $text;
      }
      # template not found, so look for a DEFAULT template
      my $default;
      if (defined ($default = $self->{ DEFAULT }) && $name ne $default) {
	$name = $default;
	redo INCLUDE;
      }
      ($data, $error) = (undef, Template::Constants::STATUS_DECLINED);
    }


  if ($text) { 
    $data = {
	     name	=> $name,
	     text	=> $text,
	     'time'	=> $time,
	     load	=> $now,
	    };
  }
  
  return($data, $error);
}

# hm, refresh is almost what we want, except we want to override
# the logic for deciding whether to reload ... can that be determined
# without reimplementing the whole method?
sub _refresh {
  my($self, $slot) = @_;
  my($head, $file, $data, $error);
  
  print STDERR "_refresh([ @$slot ])\n" if $DEBUG;
  
  # compare ETag from last request with ETag from a new request.
  # This should obviously be optimized about a billion percent. :-)
  if ($slot->[ DATA ]{modtime}) {

    my ($temp, $temp_error) = $self->_load($slot->[ NAME ]); 

    if ($slot->[ DATA ]{modtime} < $temp->{time}) {
      print STDERR "refreshing cache file ", $slot->[ NAME ], "\n"
	if $DEBUG;
      
      ($data, $error) = ($temp, $temp_error);
      ($data, $error) = $self->_compile($data) unless $error;
      $slot->[ DATA ] = $data->{ data } unless $error;
    }
  }
  

  if ($slot->[ PREV ]) {
    $slot->[ PREV ][ NEXT ] = $slot->[ NEXT ];
  } else {
    $self->{ HEAD } = $slot->[ NEXT ];
  }
  
  if ($slot->[ NEXT ]) {
    $slot->[ NEXT ][ PREV ] = $slot->[ PREV ];
  } else {
    $self->{ TAIL } = $slot->[ PREV ];
  }
  
  # ... and add to start of list
  $head = $self->{ HEAD };
  $head->[ PREV ] = $slot if $head;
  $slot->[ PREV ] = undef;
  $slot->[ NEXT ] = $head;
  $self->{ HEAD } = $slot;
  
  return($data, $error);
}

sub _load {
  warn "_load called!\n";
  shift->load(@_);
}

1;


__END__

sub _load {
  my ($class, $file, $paths) = @_;

  for my $path (@{$paths}) {
    if ($path =~ m!^http://!i) {
      warn "http not implemented yet ...";
    }
    else {
      
    }
  }
}

1;
