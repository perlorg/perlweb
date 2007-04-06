package Combust::RoseDB::Column::Point;
use Rose::DB::Object::Metadata ();
use base 'Rose::DB::Object::Metadata::Column';
use strict;

Rose::DB::Object::Metadata->column_type_class(point => __PACKAGE__);

foreach my $type (__PACKAGE__->available_method_types) {
  __PACKAGE__->method_maker_class($type =>  __PACKAGE__ . "::MakeMethods");
  __PACKAGE__->method_maker_type($type => 'generic_array')
}

sub method_uses_formatted_key {
  my($self, $type) = @_;
  return 1  if $type eq 'get' or $type eq 'set' or $type eq 'get_set';
  return 0;
}

sub type { 'point' }

sub select_sql {
  my $v = shift->SUPER::select_sql(@_);
  defined($v) ? "AsText($v)" : undef;
}

sub insert_placeholder_sql {
  'GeomFromText(' . shift->SUPER::query_placeholder_sql(@_) . ')';
}

*update_placeholder_sql = \&insert_placeholder_sql;
*query_placeholder_sql  = \&insert_placeholder_sql;

sub parse_array {
  my $self = shift;
  my $db = shift;
  if (@_ == 1) {
    my $v = shift;
    return undef unless defined $v;
    return [ @$v ] if ref($v) eq 'ARRAY' and @$v == 2;
    my @v = $v =~ /([-+]?\d+(?:\.\d+)?)/g; # parse "POINT(-1.23 1.45)"
    return (@v == 2) ? \@v : undef;
  }
  elsif (@_ == 2) {
    return [ @_ ];
  }
  return undef;
}

sub format_array {
  my $self = shift;
  my $db = shift;
  my $r = shift;
  return undef unless ref($r) eq 'ARRAY' and @$r == 2;
  return "POINT($$r[0] $$r[1])";
}

package Combust::RoseDB::Column::Point::MakeMethods;

use base 'Rose::Object::MakeMethods';
use Rose::DB::Object::Util qw(column_value_formatted_key);
use Rose::DB::Object::Constants
  qw(PRIVATE_PREFIX FLAG_DB_IS_PRIVATE STATE_IN_DB STATE_LOADING
       STATE_SAVING MODIFIED_COLUMNS);

# Mainly copied from Rose::DB::Object::MakeMethods::array
# This is really a generic array but allowing the column class to define the parser/formatter
# instead of calling $db->parse_array or $db->format_array
# maybe we should call $column->parse_value and format_value ???
# Maybe we could give back to RDBO
#
# Also changed the return values from
# return defined $self->{$key} ? wantarray ? @{$self->{$key}} : $self->{$key} : undef;
# to
# return wantarray ? @{$self->{$key} || []} : $self->{$key};
# so in array context you get () instead of (undef) when the key is undefined
# so  my @val = $row->get() or do_foobar() will work correctly

sub generic_array
{
  my($class, $name, $args) = @_;

  my $key = $args->{'hash_key'} || $name;
  my $interface = $args->{'interface'} || 'get_set';

  my $column_name = $args->{'column'} ? $args->{'column'}->name : $name;

  my $formatted_key = column_value_formatted_key($key);

  my %methods;
  my $column_obj;

  if($interface eq 'get_set')
  {
    my $default = $args->{'default'};

    if(defined $default)
    {
      $methods{$name} = sub
      {
        my $self = shift;

        $column_obj ||= $self->meta->column($name);

        my $db = $self->db or die "Missing Rose::DB object attribute";
        my $driver = $db->driver || 'unknown';

        if(@_)
        {
          if($self->{STATE_LOADING()})
          {
            $self->{$key} = undef;
            $self->{$formatted_key,$driver} = $_[0];
          }
          else
          {
            $self->{$key} = $column_obj->parse_array($db,@_);

            if(!defined $_[0] || defined $self->{$key})
            {
              $self->{$formatted_key,$driver} = undef;
              $self->{MODIFIED_COLUMNS()}{$column_name} = 1;
            }
            else
            {
              Carp::croak $self->error($db->error);
            }
          }
        }

        return unless(defined wantarray);

        # Pull default through if necessary
        unless(defined $self->{$key} || defined $self->{$formatted_key,$driver})
        {
          $self->{$key} = $column_obj->parse_array($db,$default);

          if(!defined $default || defined $self->{$key})
          {
            $self->{$formatted_key,$driver} = undef;
            $self->{MODIFIED_COLUMNS()}{$column_name} = 1;
          }
          else
          {
            Carp::croak $self->error($db->error);
          }
        }

        if($self->{STATE_SAVING()})
        {
          $self->{$formatted_key,$driver} = $column_obj->format_array($db,$self->{$key})
            unless(defined $self->{$formatted_key,$driver} || !defined $self->{$key});

          return $self->{$formatted_key,$driver};
        }

        if(defined $self->{$key})
        {
          $self->{$formatted_key,$driver} = undef;
          return wantarray ? @{$self->{$key}} : $self->{$key};
        }

        if(defined $self->{$formatted_key,$driver})
        {
          $self->{$key} = $column_obj->parse_array($db,$self->{$formatted_key,$driver});
          $self->{$formatted_key,$driver} = undef;

          return wantarray ? @{$self->{$key} || []} : $self->{$key};
        }

        return undef;
      }
    }
    else
    {
      $methods{$name} = sub
      {
        my $self = shift;

        $column_obj ||= $self->meta->column($name);

        my $db = $self->db or die "Missing Rose::DB object attribute";
        my $driver = $db->driver || 'unknown';

        if(@_)
        {
          if($self->{STATE_LOADING()})
          {
            $self->{$key} = undef;
            $self->{$formatted_key,$driver} = $_[0];
          }
          else
          {
            $self->{$key} = $column_obj->parse_array($db,@_);

            if(!defined $_[0] || defined $self->{$key})
            {
              $self->{$formatted_key,$driver} = undef;
              $self->{MODIFIED_COLUMNS()}{$column_name} = 1;
            }
            else
            {
              Carp::croak $self->error($db->error);
            }
          }
        }

        if($self->{STATE_SAVING()})
        {
          return undef  unless(defined($self->{$formatted_key,$driver}) || defined($self->{$key}));

          $self->{$formatted_key,$driver} = $column_obj->format_array($db,$self->{$key})
            unless(defined $self->{$formatted_key,$driver} || !defined $self->{$key});

          return $self->{$formatted_key,$driver};
        }

        return unless(defined wantarray);

        if(defined $self->{$key})
        {
          $self->{$formatted_key,$driver} = undef;
          return wantarray ? @{$self->{$key}} : $self->{$key};
        }

        if(defined $self->{$formatted_key,$driver})
        {
          $self->{$key} = $column_obj->parse_array($db,$self->{$formatted_key,$driver});
          $self->{$formatted_key,$driver} = undef;

          return wantarray ? @{$self->{$key} || []} : $self->{$key};
        }

        return undef;
      }
    }
  }
  elsif($interface eq 'get')
  {
    my $default = $args->{'default'};

    if(defined $default)
    {
      $methods{$name} = sub
      {
        my $self = shift;

        $column_obj ||= $self->meta->column($name);

        my $db = $self->db or die "Missing Rose::DB object attribute";
        my $driver = $db->driver || 'unknown';

        if(!defined $self->{$key} && (!$self->{STATE_SAVING()} || !defined $self->{$formatted_key,$driver}))
        {
          $self->{$key} = $column_obj->parse_array($db,$default);

          if(!defined $default || defined $self->{$key})
          {
            $self->{$formatted_key,$driver} = undef;
            $self->{MODIFIED_COLUMNS()}{$column_name} = 1;
          }
          else
          {
            Carp::croak $self->error($db->error);
          }
        }

        if($self->{STATE_SAVING()})
        {
          $self->{$formatted_key,$driver} = $column_obj->format_array($db,$self->{$key})
            unless(defined $self->{$formatted_key,$driver} || !defined $self->{$key});

          return $self->{$formatted_key,$driver};
        }

        return unless(defined wantarray);

        if(defined $self->{$key})
        {
          $self->{$formatted_key,$driver} = undef;
          return wantarray ? @{$self->{$key}} : $self->{$key};
        }

        if(defined $self->{$formatted_key,$driver})
        {
          $self->{$key} = $column_obj->parse_array($db,$self->{$formatted_key,$driver});
          $self->{$formatted_key,$driver} = undef;

          return wantarray ? @{$self->{$key} || []} : $self->{$key};
        }

        return undef;
      }
    }
    else
    {
      $methods{$name} = sub
      {
        my $self = shift;

        $column_obj ||= $self->meta->column($name);

        my $db = $self->db or die "Missing Rose::DB object attribute";
        my $driver = $db->driver || 'unknown';

        if($self->{STATE_SAVING()})
        {
          return undef  unless(defined($self->{$formatted_key,$driver}) || defined($self->{$key}));

          $self->{$formatted_key,$driver} = $column_obj->format_array($db,$self->{$key})
            unless(defined $self->{$formatted_key,$driver} || !defined $self->{$key});

          return $self->{$formatted_key,$driver};
        }

        return unless(defined wantarray);

        if(defined $self->{$key})
        {
          $self->{$formatted_key,$driver} = undef;
          return wantarray ? @{$self->{$key}} : $self->{$key};
        }

        if(defined $self->{$formatted_key,$driver})
        {
          $self->{$key} = $column_obj->parse_array($db,$self->{$formatted_key,$driver});
          $self->{$formatted_key,$driver} = undef;

          return wantarray ? @{$self->{$key} || []} : $self->{$key};
        }

        return undef;
      }
    }
  }
  elsif($interface eq 'set')
  {
    $methods{$name} = sub
    {
      my $self = shift;

      $column_obj ||= $self->meta->column($name);

      my $db = $self->db or die "Missing Rose::DB object attribute";
      my $driver = $db->driver || 'unknown';

      Carp::croak "Missing argument in call to $name"  unless(@_);

      if($self->{STATE_LOADING()})
      {
        $self->{$key} = undef;
        $self->{$formatted_key,$driver} = $_[0];
      }
      else
      {
        $self->{$key} = $column_obj->parse_array($db,$_[0]);

        if(!defined $_[0] || defined $self->{$key})
        {
          $self->{$formatted_key,$driver} = undef;
          $self->{MODIFIED_COLUMNS()}{$column_name} = 1;
        }
        else
        {
          Carp::croak $self->error($db->error);
        }
      }

      if($self->{STATE_SAVING()})
      {
        return undef  unless(defined($self->{$formatted_key,$driver}) || defined($self->{$key}));

        $self->{$formatted_key,$driver} = $column_obj->format_array($db,$self->{$key})
          unless(defined $self->{$formatted_key,$driver} || !defined $self->{$key});

        return $self->{$formatted_key,$driver};
      }

      if(defined $self->{$key})
      {
        $self->{$formatted_key,$driver} = undef;
        return wantarray ? @{$self->{$key}} : $self->{$key};
      }

      if(defined $self->{$formatted_key,$driver})
      {
        $self->{$key} = $column_obj->parse_array($db,$self->{$formatted_key,$driver});
        $self->{$formatted_key,$driver} = undef;

        return wantarray ? @{$self->{$key} || []} : $self->{$key};
      }

      return undef;
    }
  }
  else { Carp::croak "Unknown interface: $interface" }

  return \%methods;
}

1;
