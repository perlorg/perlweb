#============================================================= -*-Perl-*-
#
# Combust::Template::Provider::Base - Originated as Template::Provider
# (from TT 2.09)
#
# COPYRIGHT
#   Copyright (C) 1996-2000 Andy Wardley.  All Rights Reserved.
#   Copyright (C) 1998-2000 Canon Research Centre Europe Ltd.
#
#   This module is free software; you can redistribute it and/or
#   modify it under the same terms as Perl itself.
#
#============================================================================

package Combust::Template::Provider::Base;

require 5.004;

use strict;
use vars qw( $VERSION $DEBUG $ERROR $DOCUMENT $STAT_TTL $MAX_DIRS );
use base qw( Template::Base );
use Template::Config;
use Template::Constants;
use Template::Document;
use File::Basename;
use File::Spec;

$VERSION  = sprintf("%d.%02d", q$Revision: 2.67 $ =~ /(\d+)\.(\d+)/);

# name of document class
$DOCUMENT = 'Template::Document' unless defined $DOCUMENT;

# maximum time between performing stat() on file to check staleness
$STAT_TTL = 1 unless defined $STAT_TTL;

# maximum number of directories in an INCLUDE_PATH, to prevent runaways
$MAX_DIRS = 64 unless defined $MAX_DIRS;

use constant PREV   => 0;
use constant NAME   => 1;
use constant DATA   => 2; 
use constant LOAD   => 3;
use constant NEXT   => 4;
use constant STAT   => 5;

$DEBUG = 0 unless defined $DEBUG;

#========================================================================
#                         -- PUBLIC METHODS --
#========================================================================

#------------------------------------------------------------------------
# fetch($name)
#
# Returns a compiled template for the name specified by parameter.
# The template is returned from the internal cache if it exists, or
# loaded and then subsequently cached.  The ABSOLUTE and RELATIVE
# configuration flags determine if absolute (e.g. '/something...')
# and/or relative (e.g. './something') paths should be honoured.  The
# INCLUDE_PATH is otherwise used to find the named file. $name may
# also be a reference to a text string containing the template text,
# or a file handle from which the content is read.  The compiled
# template is not cached in these latter cases given that there is no
# filename to cache under.  A subsequent call to store($name,
# $compiled) can be made to cache the compiled template for future
# fetch() calls, if necessary. 
#
# Returns a compiled template or (undef, STATUS_DECLINED) if the 
# template could not be found.  On error (e.g. the file was found 
# but couldn't be read or parsed), the pair ($error, STATUS_ERROR)
# is returned.  The TOLERANT configuration option can be set to 
# downgrade any errors to STATUS_DECLINE.
#------------------------------------------------------------------------

sub fetch {
    my ($self, $name) = @_;
    my ($data, $error);

    if (ref $name) {
        # $name can be a reference to a scalar, GLOB or file handle
        ($data, $error) = $self->_load($name);
        ($data, $error) = $self->_compile($data)
            unless $error;
        $data = $data->{ data }
            unless $error;
    }
    elsif (File::Spec->file_name_is_absolute($name)) {
        # absolute paths (starting '/') allowed if ABSOLUTE set
        ($data, $error) = $self->{ ABSOLUTE } 
            ? $self->_fetch($name) 
            : $self->{ TOLERANT } 
                ? (undef, Template::Constants::STATUS_DECLINED)
                : ("$name: absolute paths are not allowed (set ABSOLUTE option)",
                   Template::Constants::STATUS_ERROR);
    }
    elsif ($name =~ m[^\.+/]) {
        # anything starting "./" is relative to cwd, allowed if RELATIVE set
        ($data, $error) = $self->{ RELATIVE } 
            ? $self->_fetch($name) 
            : $self->{ TOLERANT } 
                ? (undef, Template::Constants::STATUS_DECLINED)
                : ("$name: relative paths are not allowed (set RELATIVE option)",
                   Template::Constants::STATUS_ERROR);
    }
    else {
      # otherwise, it's a file name relative to INCLUDE_PATH
      ($data, $error) = $self->{ INCLUDE_PATH } 
        ? $self->_fetch_path($name) 
          : (undef, Template::Constants::STATUS_DECLINED);

      if ($error) {
        # no extension to rip off ...
        return ($data, $error) unless $name =~ s/\.[^.]+$//;

        for my $ext (@{$self->{EXTENSIONS}}) {
          #warn Data::Dumper->Dump([\$ext], [qw(ext)]);
          my $newname = "$name." . $ext->{extension};
          #warn "looking for newname: $newname";
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
    }

#    $self->_dump_cache() 
#       if $DEBUG > 1;

    return ($data, $error);
}


#------------------------------------------------------------------------
# store($name, $data)
#
# Store a compiled template ($data) in the cached as $name.
#------------------------------------------------------------------------

sub store {
    my ($self, $name, $data) = @_;
    $self->_store($name, {
        data => $data,
        load => 0,
    });
}


#------------------------------------------------------------------------
# load($name)
#
# Load a template without parsing/compiling it, suitable for use with 
# the INSERT directive.  There's some duplication with fetch() and at
# some point this could be reworked to integrate them a little closer.
#------------------------------------------------------------------------

sub load {
    my ($self, $name) = @_;
    my ($data, $error);
    my $path = $name;

    if (File::Spec->file_name_is_absolute($name)) {
        # absolute paths (starting '/') allowed if ABSOLUTE set
        $error = "$name: absolute paths are not allowed (set ABSOLUTE option)" 
            unless $self->{ ABSOLUTE };
    }
    elsif ($name =~ m[^\.+/]) {
        # anything starting "./" is relative to cwd, allowed if RELATIVE set
        $error = "$name: relative paths are not allowed (set RELATIVE option)"
            unless $self->{ RELATIVE };
    }
    else {
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
    }

    if (defined $path && ! $error) {
        local $/ = undef;    # slurp files in one go
        local *FH;
        if (open(FH, $path)) {
            $data = <FH>;
            close(FH);
        }
        else {
            $error = "$name: $!";
        }
    }

    if ($error) {
        return $self->{ TOLERANT } 
            ? (undef, Template::Constants::STATUS_DECLINED)
            : ($error, Template::Constants::STATUS_ERROR);
    }
    elsif (! defined $path) {
        return (undef, Template::Constants::STATUS_DECLINED);
    }
    else {
        return ($data, Template::Constants::STATUS_OK);
    }
}

 

#------------------------------------------------------------------------
# include_path(\@newpath)
#
# Accessor method for the INCLUDE_PATH setting.  If called with an
# argument, this method will replace the existing INCLUDE_PATH with
# the new value.
#------------------------------------------------------------------------

sub include_path {
     my ($self, $path) = @_;
     $self->{ INCLUDE_PATH } = $path if $path;
     return $self->{ INCLUDE_PATH };
}


#------------------------------------------------------------------------
# paths()
#
# Evaluates the INCLUDE_PATH list, ignoring any blank entries, and 
# calling and subroutine or object references to return dynamically
# generated path lists.  Returns a reference to a new list of paths 
# or undef on error.
#------------------------------------------------------------------------

sub paths {
    my $self   = shift;
    my @ipaths = @{ $self->{ INCLUDE_PATH } };
    my (@opaths, $dpaths, $dir);
    my $count = $MAX_DIRS;

    while (@ipaths && --$count) {
        $dir = shift @ipaths || next;

        # $dir can be a sub or object ref which returns a reference
        # to a dynamically generated list of search paths.
        
        if (ref $dir eq 'CODE') {
            eval { $dpaths = &$dir() };
            if ($@) {
                chomp $@;
		warn "error: $@";
                return $self->error($@);
            }
            unshift(@ipaths, @$dpaths);
            next;
        }
        elsif (UNIVERSAL::can($dir, 'paths')) {
            $dpaths = $dir->paths() 
                || return $self->error($dir->error());
            unshift(@ipaths, @$dpaths);
            next;
        }
        else {
            push(@opaths, $dir);
        }
    }
    return $self->error("INCLUDE_PATH exceeds $MAX_DIRS directories")
        if @ipaths;

    return \@opaths;
}


#------------------------------------------------------------------------
# DESTROY
#
# The provider cache is implemented as a doubly linked list which Perl
# cannot free by itself due to the circular references between NEXT <=> 
# PREV items.  This cleanup method walks the list deleting all the NEXT/PREV 
# references, allowing the proper cleanup to occur and memory to be 
# repooled.
#------------------------------------------------------------------------

sub DESTROY {
    my $self = shift;
    my ($slot, $next);

    $slot = $self->{ HEAD };
    while ($slot) {
        $next = $slot->[ NEXT ];
        undef $slot->[ PREV ];
        undef $slot->[ NEXT ];
        $slot = $next;
    }
    undef $self->{ HEAD };
    undef $self->{ TAIL };
}




#========================================================================
#                        -- PRIVATE METHODS --
#========================================================================

#------------------------------------------------------------------------
# _init()
#
# Initialise the cache.
#------------------------------------------------------------------------

sub _init {
    my ($self, $params) = @_;
    my $size = $params->{ CACHE_SIZE   };
    my $path = $params->{ INCLUDE_PATH } || '.';
    my $cdir = $params->{ COMPILE_DIR  } || '';
    my $dlim = $params->{ DELIMITER    };
    my $exts = $params->{ EXTENSIONS   } || [];

    my $debug;

    # tweak delim to ignore C:/
    unless (defined $dlim) {
        $dlim = ($^O eq 'MSWin32') ? ':(?!\\/)' : ':';
    }

    # coerce INCLUDE_PATH to an array ref, if not already so
    $path = [ split(/$dlim/, $path) ]
        unless ref $path eq 'ARRAY';

    # don't allow a CACHE_SIZE 1 because it breaks things and the 
    # additional checking isn't worth it
    $size = 2 
        if defined $size && ($size == 1 || $size < 0);

    # FIXME - TT 2.09 only -
    #if (defined ($debug = $params->{ DEBUG })) {
      #$self->{ DEBUG } = $debug & ( Template::Constants::DEBUG_PROVIDER
      #                              | Template::Constants::DEBUG_FLAGS );
    #}
    #else {
        $self->{ DEBUG } = $DEBUG;
    #}

    if ($self->{ DEBUG }) {
        local $" = ', ';
        $self->debug("creating cache of ", 
              defined $size ? $size : 'unlimited',
              " slots for [ @$path ]");
    }

    # create COMPILE_DIR and sub-directories representing each INCLUDE_PATH
    # element in which to store compiled files
    if ($cdir) {

# Stas' hack
#        # this is a hack to solve the problem with INCLUDE_PATH using
#        # relative dirs
#        my $segments = 0;
#        for (@$path) {
#            my $c = 0;
#            $c++ while m|\.\.|g;
#            $segments = $c if $c > $segments;
#        }
#        $cdir .= "/".join "/",('hack') x $segments if $segments;
#

        require File::Path;
        foreach my $dir (@$path) {
            next if ref $dir;
            my $wdir = $dir;
            $wdir =~ s[:][]g if $^O eq 'MSWin32';
            $wdir =~ /(.*)/;  # untaint
            &File::Path::mkpath(File::Spec->catfile($cdir, $1));
        }
    }

    $self->{ LOOKUP       } = { };
    $self->{ SLOTS        } = 0;
    $self->{ SIZE         } = $size;
    $self->{ INCLUDE_PATH } = $path;
    $self->{ DELIMITER    } = $dlim;
    $self->{ COMPILE_DIR  } = $cdir;
    $self->{ EXTENSIONS   } = $exts;
    $self->{ COMPILE_EXT  } = $params->{ COMPILE_EXT } || '';
    $self->{ ABSOLUTE     } = $params->{ ABSOLUTE } || 0;
    $self->{ RELATIVE     } = $params->{ RELATIVE } || 0;
    $self->{ TOLERANT     } = $params->{ TOLERANT } || 0;
    $self->{ DOCUMENT     } = $params->{ DOCUMENT } || $DOCUMENT;
    $self->{ PARSER       } = $params->{ PARSER };
    $self->{ DEFAULT      } = $params->{ DEFAULT };
#   $self->{ PREFIX       } = $params->{ PREFIX };
    $self->{ PARAMS       } = $params;

    return $self;
}


#------------------------------------------------------------------------
# _fetch($name)
#
# Fetch a file from cache or disk by specification of an absolute or
# relative filename.  No search of the INCLUDE_PATH is made.  If the 
# file is found and loaded, it is compiled and cached.
#------------------------------------------------------------------------

sub _fetch {
    my ($self, $name) = @_;
    my $size = $self->{ SIZE };
    my ($slot, $data, $error);

    $self->debug("_fetch($name)") if $self->{ DEBUG };

    my $compiled = $self->_compiled_filename($name);

    if (defined $size && ! $size) {
        # caching disabled so load and compile but don't cache
        if ($compiled && -f $compiled && (stat($name))[9] <= (stat($compiled))[9]) {
            $data = $self->_load_compiled($compiled);
            $error = $self->error() unless $data;
        }
        else {
            ($data, $error) = $self->_load($name);
            ($data, $error) = $self->_compile($data, $compiled)
                unless $error;
            $data = $data->{ data }
            unless $error;
        }
    }
    elsif ($slot = $self->{ LOOKUP }->{ $name }) {
        # cached entry exists, so refresh slot and extract data
        ($data, $error) = $self->_refresh($slot);
        $data = $slot->[ DATA ]
            unless $error;
    }
    else {
        # nothing in cache so try to load, compile and cache
        if ($compiled && -f $compiled && (stat($name))[9] <= (stat($compiled))[9]) {
            $data = $self->_load_compiled($compiled);
            $error = $self->error() unless $data;
            $self->store($name, $data) unless $error;
        }
        else {
            ($data, $error) = $self->_load($name);
            ($data, $error) = $self->_compile($data, $compiled)
                unless $error;
            $data = $self->_store($name, $data)
                unless $error;
        }

    }

    return ($data, $error);
}


#------------------------------------------------------------------------
# _fetch_path($name)
#
# Fetch a file from cache or disk by specification of an absolute cache
# name (e.g. 'header') or filename relative to one of the INCLUDE_PATH 
# directories.  If the file isn't already cached and can be found and 
# loaded, it is compiled and cached under the full filename.
#------------------------------------------------------------------------

sub _fetch_path {
    my ($self, $name) = @_;
    my ($size, $compext, $compdir) = 
        @$self{ qw( SIZE COMPILE_EXT COMPILE_DIR ) };
    my ($dir, $paths, $path, $compiled, $slot, $data, $error);
    local *FH;

    $self->debug("_fetch_path($name)") if $self->{ DEBUG };

    # caching is enabled if $size is defined and non-zero or undefined
    my $caching = (! defined $size || $size);

    INCLUDE: {

        # the template may have been stored using a non-filename name
        if ($caching && ($slot = $self->{ LOOKUP }->{ $name })) {
            # cached entry exists, so refresh slot and extract data
            ($data, $error) = $self->_refresh($slot);
            $data = $slot->[ DATA ] 
                unless $error;
            last INCLUDE;
        }

        $paths = $self->paths() || do {
            $error = Template::Constants::STATUS_ERROR;
            $data  = $self->error();
            last INCLUDE;
        };

        # search the INCLUDE_PATH for the file, in cache or on disk
        foreach $dir (@$paths) {
            $path = "$dir/$name";

            $self->debug("searching path: $path\n") if $self->{ DEBUG };

            if ($caching && ($slot = $self->{ LOOKUP }->{ $path })) {
                # cached entry exists, so refresh slot and extract data
                ($data, $error) = $self->_refresh($slot);
                $data = $slot->[ DATA ]
                    unless $error;
                last INCLUDE;
            }
            elsif (-f $path) {
                $compiled = $self->_compiled_filename($path)
                    if $compext || $compdir;

                if ($compiled && -f $compiled && (stat($path))[9] <= (stat($compiled))[9]) {
                    if ($data = $self->_load_compiled($compiled)) {
                        # store in cache
                        $data  = $self->store($path, $data);
                        $error = Template::Constants::STATUS_OK;
                        last INCLUDE;
                    }
                    else {
                        warn($self->error(), "\n");
                    }
                }
                # $compiled is set if an attempt to write the compiled 
                # template to disk should be made

                ($data, $error) = $self->_load($path, $name);
                ($data, $error) = $self->_compile($data, $compiled)
                    unless $error;
                $data = $self->_store($path, $data)
                    unless $error || ! $caching;
                $data = $data->{ data } if ! $caching;
                # all done if $error is OK or ERROR
                last INCLUDE if ! $error 
                    || $error == Template::Constants::STATUS_ERROR;
            }
        }
        # template not found, so look for a DEFAULT template
        my $default;
        if (defined ($default = $self->{ DEFAULT }) && $name ne $default) {
            $name = $default;
            redo INCLUDE;
        }
        ($data, $error) = (undef, Template::Constants::STATUS_DECLINED);
    } # INCLUDE

    return ($data, $error);
}



sub _compiled_filename {
    my ($self, $file) = @_;
    my ($compext, $compdir) = @$self{ qw( COMPILE_EXT COMPILE_DIR ) };
    my ($path, $compiled);

    return undef
        unless $compext || $compdir;

    $path = $file;
    $path =~ /^(.+)$/s or die "invalid filename: $path";
    $path =~ s[:][]g if $^O eq 'MSWin32';

    $compiled = "$path$compext";
    $compiled = File::Spec->catfile($compdir, $compiled) if length $compdir;

    return $compiled;
}


sub _load_compiled {
    my ($self, $file) = @_;
    my $compiled;

    # load compiled template via require();  we zap any
    # %INC entry to ensure it is reloaded (we don't 
    # want 1 returned by require() to say it's in memory)
    delete $INC{ $file };
    eval { $compiled = require $file; };
    return $@
         ? $self->error("compiled template $compiled: $@")
         : $compiled;
}



#------------------------------------------------------------------------
# _load($name, $alias)
#
# Load template text from a string ($name = scalar ref), GLOB or file 
# handle ($name = ref), or from an absolute filename ($name = scalar).
# Returns a hash array containing the following items:
#   name    filename or $alias, if provided, or 'input text', etc.
#   text    template text
#   time    modification time of file, or current time for handles/strings
#   load    time file was loaded (now!)  
#
# On error, returns ($error, STATUS_ERROR), or (undef, STATUS_DECLINED)
# if TOLERANT is set.
#------------------------------------------------------------------------

sub _load {
    my ($self, $name, $alias) = @_;
    my ($data, $error);
    my $tolerant = $self->{ TOLERANT };
    my $now = time;
    local $/ = undef;    # slurp files in one go
    local *FH;

    $alias = $name unless defined $alias or ref $name;

    $self->debug("_load($name, ", defined $alias ? $alias : '<no alias>', 
                 ')') if $self->{ DEBUG };

    LOAD: {
        if (ref $name eq 'SCALAR') {
            # $name can be a SCALAR reference to the input text...
            $data = {
                name => defined $alias ? $alias : 'input text',
                text => $$name,
                time => $now,
                load => 0,
            };
        }
        elsif (ref $name) {
            # ...or a GLOB or file handle...
            my $text = <$name>;
            $data = {
                name => defined $alias ? $alias : 'input file handle',
                text => $text,
                time => $now,
                load => 0,
            };
        }
        elsif (-f $name) {
            if (open(FH, $name)) {
                my $text = <FH>;
                $data = {
                    name => $alias,
                    text => $text,
                    time => (stat $name)[9],
                    load => $now,
                };
            }
            elsif ($tolerant) {
                ($data, $error) = (undef, Template::Constants::STATUS_DECLINED);
            }
            else {
                $data  = "$alias: $!";
                $error = Template::Constants::STATUS_ERROR;
            }
        }
        else {
            ($data, $error) = (undef, Template::Constants::STATUS_DECLINED);
        }
    }

    return ($data, $error);
}


#------------------------------------------------------------------------
# _refresh(\@slot)
#
# Private method called to mark a cache slot as most recently used.
# A reference to the slot array should be passed by parameter.  The 
# slot is relocated to the head of the linked list.  If the file from
# which the data was loaded has been upated since it was compiled, then
# it is re-loaded from disk and re-compiled.
#------------------------------------------------------------------------

sub _refresh {
    my ($self, $slot) = @_;
    my ($head, $file, $data, $error);


    $self->debug("_refresh([ ", 
                 join(', ', map { defined $_ ? $_ : '<undef>' } @$slot),
                 '])') if $self->{ DEBUG };

    # if it's more than $STAT_TTL seconds since we last performed a 
    # stat() on the file then we need to do it again and see if the file
    # time has changed
    if ( (time - $slot->[ STAT ]) > $STAT_TTL && stat $slot->[ NAME ] ) {
        $slot->[ STAT ] = time;

        if ( (stat(_))[9] != $slot->[ LOAD ]) {

            $self->debug("refreshing cache file ", $slot->[ NAME ]) 
                if $self->{ DEBUG };
            
            ($data, $error) = $self->_load($slot->[ NAME ],
                                           $slot->[ DATA ]->{ name });
            ($data, $error) = $self->_compile($data)
                unless $error;

            unless ($error) {
                $slot->[ DATA ] = $data->{ data };
                $slot->[ LOAD ] = $data->{ time };
            }
        }
    }

    unless( $self->{ HEAD } == $slot ) {
        # remove existing slot from usage chain...
        if ($slot->[ PREV ]) {
            $slot->[ PREV ]->[ NEXT ] = $slot->[ NEXT ];
        }
        else {
            $self->{ HEAD } = $slot->[ NEXT ];
        }
        if ($slot->[ NEXT ]) {
            $slot->[ NEXT ]->[ PREV ] = $slot->[ PREV ];
        }
        else {
            $self->{ TAIL } = $slot->[ PREV ];
        }
        
        # ..and add to start of list
        $head = $self->{ HEAD };
        $head->[ PREV ] = $slot if $head;
        $slot->[ PREV ] = undef;
        $slot->[ NEXT ] = $head;
        $self->{ HEAD } = $slot;
    }

    return ($data, $error);
}


#------------------------------------------------------------------------
# _store($name, $data)
#
# Private method called to add a data item to the cache.  If the cache
# size limit has been reached then the oldest entry at the tail of the 
# list is removed and its slot relocated to the head of the list and 
# reused for the new data item.  If the cache is under the size limit,
# or if no size limit is defined, then the item is added to the head 
# of the list.  
#------------------------------------------------------------------------

sub _store {
    my ($self, $name, $data, $compfile) = @_;
    my $size = $self->{ SIZE };
    my ($slot, $head);

    # extract the load time and compiled template from the data
#    my $load = $data->{ load };
    my $load = (stat($name))[9];
    $data = $data->{ data };

    $self->debug("_store($name, $data)") if $self->{ DEBUG };

    if (defined $size && $self->{ SLOTS } >= $size) {
        # cache has reached size limit, so reuse oldest entry

        $self->debug("reusing oldest cache entry (size limit reached: $size)\nslots: $self->{ SLOTS }") if $self->{ DEBUG };

        # remove entry from tail of list
        $slot = $self->{ TAIL };
        $slot->[ PREV ]->[ NEXT ] = undef;
        $self->{ TAIL } = $slot->[ PREV ];
        
        # remove name lookup for old node
        delete $self->{ LOOKUP }->{ $slot->[ NAME ] };

        # add modified node to head of list
        $head = $self->{ HEAD };
        $head->[ PREV ] = $slot if $head;
        @$slot = ( undef, $name, $data, $load, $head, time );
        $self->{ HEAD } = $slot;

        # add name lookup for new node
        $self->{ LOOKUP }->{ $name } = $slot;
    }
    else {
        # cache is under size limit, or none is defined

        $self->debug("adding new cache entry") if $self->{ DEBUG };

        # add new node to head of list
        $head = $self->{ HEAD };
        $slot = [ undef, $name, $data, $load, $head, time ];
        $head->[ PREV ] = $slot if $head;
        $self->{ HEAD } = $slot;
        $self->{ TAIL } = $slot unless $self->{ TAIL };

        # add lookup from name to slot and increment nslots
        $self->{ LOOKUP }->{ $name } = $slot;
        $self->{ SLOTS }++;
    }

    return $data;
}


#------------------------------------------------------------------------
# _compile($data)
#
# Private method called to parse the template text and compile it into 
# a runtime form.  Creates and delegates a Template::Parser object to
# handle the compilation, or uses a reference passed in PARSER.  On 
# success, the compiled template is stored in the 'data' item of the 
# $data hash and returned.  On error, ($error, STATUS_ERROR) is returned,
# or (undef, STATUS_DECLINED) if the TOLERANT flag is set.
# The optional $compiled parameter may be passed to specify
# the name of a compiled template file to which the generated Perl
# code should be written.  Errors are (for now...) silently 
# ignored, assuming that failures to open a file for writing are 
# intentional (e.g directory write permission).
#------------------------------------------------------------------------

sub _compile {
    my ($self, $data, $compfile) = @_;
    my $text = $data->{ text };
    my ($parsedoc, $error);

    $self->debug("_compile($data, ", 
                 defined $compfile ? $compfile : '<no compfile>', ')') 
        if $self->{ DEBUG };

    my $parser = $self->{ PARSER } 
        ||= Template::Config->parser($self->{ PARAMS })
        ||  return (Template::Config->error(), Template::Constants::STATUS_ERROR);

    # discard the template text - we don't need it any more
    delete $data->{ text };   

    # call parser to compile template into Perl code
    if ($parsedoc = $parser->parse($text, $data)) {

        $parsedoc->{ METADATA } = { 
            'name'    => $data->{ name },
            'modtime' => $data->{ time },
            %{ $parsedoc->{ METADATA } },
        };
        
        # write the Perl code to the file $compfile, if defined
        if ($compfile) {
            my $basedir = &File::Basename::dirname($compfile);
            $basedir =~ /(.*)/;
            $basedir = $1;
            &File::Path::mkpath($basedir) unless -d $basedir;

            my $docclass = $self->{ DOCUMENT };
            $error = 'cache failed to write '
                    . &File::Basename::basename($compfile)
                    . ': ' . $docclass->error()
                unless $docclass->write_perl_file($compfile, $parsedoc);
 
            # set atime and mtime of newly compiled file, don't bother
            # if time is undef
            if (!defined($error) && defined $data->{ time }) {
                my ($cfile) = $compfile =~ /^(.+)$/s or do {
                    return("invalid filename: $compfile", 
                              Template::Constants::STATUS_ERROR);
                };

                my ($ctime) = $data->{ time } =~ /^(\d+)$/;
                unless ($ctime || $ctime eq 0) {
                    return("invalid time: $ctime", 
                              Template::Constants::STATUS_ERROR);
                }
                utime($ctime, $ctime, $cfile);
            }
        }

        unless ($error) {
            return $data                                        ## RETURN ##
                if $data->{ data } = Template::Document->new($parsedoc);
            $error = $Template::Document::ERROR;
        }
    }
    else {
        $error = Template::Exception->new( 'parse', "$data->{ name } " .
                                           $parser->error() );
    }

    # return STATUS_ERROR, or STATUS_DECLINED if we're being tolerant
    return $self->{ TOLERANT } 
        ? (undef, Template::Constants::STATUS_DECLINED)
        : ($error,  Template::Constants::STATUS_ERROR)
}


#------------------------------------------------------------------------
# _dump()
#
# Debug method which returns a string representing the internal object 
# state.
#------------------------------------------------------------------------

sub _dump {
    my $self = shift;
    my $size = $self->{ SIZE };
    my $parser = $self->{ PARSER };
    $parser = $parser ? $parser->_dump() : '<no parser>';
    $parser =~ s/\n/\n    /gm;
    $size = 'unlimited' unless defined $size;

    my $output = "[Template::Provider] {\n";
    my $format = "    %-16s => %s\n";
    my $key;

    $output .= sprintf($format, 'INCLUDE_PATH', 
                       '[ ' . join(', ', @{ $self->{ INCLUDE_PATH } }) . ' ]');
    $output .= sprintf($format, 'CACHE_SIZE', $size);

    foreach $key (qw( ABSOLUTE RELATIVE TOLERANT DELIMITER
                      COMPILE_EXT COMPILE_DIR )) {
        $output .= sprintf($format, $key, $self->{ $key });
    }
    $output .= sprintf($format, 'PARSER', $parser);


    local $" = ', ';
    my $lookup = $self->{ LOOKUP };
    $lookup = join('', map { 
        sprintf("    $format", $_, defined $lookup->{ $_ }
                ? ('[ ' . join(', ', map { defined $_ ? $_ : '<undef>' }
                               @{ $lookup->{ $_ } }) . ' ]') : '<undef>');
    } sort keys %$lookup);
    $lookup = "{\n$lookup    }";
    
    $output .= sprintf($format, LOOKUP => $lookup);

    $output .= '}';
    return $output;
}


#------------------------------------------------------------------------
# _dump_cache()
#
# Debug method which prints the current state of the cache to STDERR.
#------------------------------------------------------------------------

sub _dump_cache {
    my $self = shift;
    my ($node, $lut, $count);

    $count = 0;
    if ($node = $self->{ HEAD }) {
        while ($node) {
            $lut->{ $node } = $count++;
            $node = $node->[ NEXT ];
        }
        $node = $self->{ HEAD };
        print STDERR "CACHE STATE:\n";
        print STDERR "  HEAD: ", $self->{ HEAD }->[ NAME ], "\n";
        print STDERR "  TAIL: ", $self->{ TAIL }->[ NAME ], "\n";
        while ($node) {
            my ($prev, $name, $data, $load, $next) = @$node;
#           $name = '...' . substr($name, -10) if length $name > 10;
            $prev = $prev ? "#$lut->{ $prev }<-": '<undef>';
            $next = $next ? "->#$lut->{ $next }": '<undef>';
            print STDERR "   #$lut->{ $node } : [ $prev, $name, $data, $load, $next ]\n";
            $node = $node->[ NEXT ];
        }
    }
}

1;

__END__

