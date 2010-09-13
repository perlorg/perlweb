package Combust::Logger;
# vim: ts=8:sw=2:expandtab

use strict;
use warnings;
use base qw(Exporter);

use Carp;
use Sys::Syslog qw(:DEFAULT setlogsock);
use Sys::Hostname qw(hostname);
use Fcntl qw(:DEFAULT :flock);
use File::Path qw(mkpath);

use Combust::Config;
my $config = Combust::Config->new;

use JSON::XS;
my $json = JSON::XS->new;

our @EXPORT = qw(
  logconfig
  logtofile
  logdie
  logalert
  logerr
  logwarn
  logsay
  logtrace
  logdebug
  logtimes
);

our $Prefix  = $Apache::Server::Starting ? 'httpd' : ($0 =~ m:([^/]+)$:)[0];
our $Verbose = 0 && $Apache::Server::Starting; # avoid used once warning
our $Domain  = 'unix';
our $sayfh   = \*STDERR;
our $saywarn = 0;
our $utf8    = 1;
our $done_syslog;
our $LogToFile;
our $ShowExitBanner;
our %Count;

my @orig_argv;

BEGIN { @orig_argv = ($0, @ARGV) } # record original argv before options are removed

my $opened;
our $do_syslog;
my $only_syslog;

sub prefix {
  return localtime()." $Prefix\[$$]: ";
}

sub _openlog {
  closelog() if $opened;
  return unless $do_syslog;
  setlogsock( $Domain );
  openlog $Prefix, 'pid', 'local0';
  $opened = 1;
}

sub logconfig {
  my %p = @_;

  $Verbose = $p{verbose} if exists $p{verbose};
  $Prefix  = $p{prefix}  if exists $p{prefix};
  $Domain  = $p{domain}  if exists $p{domain};
  $sayfh   = $p{sayfh}   if exists $p{sayfh};
  $saywarn = $p{saywarn} if exists $p{saywarn};
  $utf8    = $p{utf8}    if exists $p{utf8};
  $do_syslog = $p{syslog} if exists $p{syslog};
  $only_syslog = $p{only_syslog} if exists $p{only_syslog};
  $SIG{__WARN__} = (ref $p{sigwarn}) ? $p{sigwarn} : \&_sigwarn if $p{sigwarn};
  logbanner() if $p{banner};

  if ($utf8) {
    binmode(STDERR,":utf8");
    binmode($sayfh,":utf8");
  }

  _openlog();
}

sub _syslog {
  my $type = shift;
  ++$Count{$type};
  return unless $do_syslog or $type eq 'alert';
  _openlog() unless $opened;
  syslog($type, "%s", $_) for (split /\r?\n/, $_[0]);
}

# ------ handlers ------

sub _dowarn {
  my ($level, $msg) = @_;
  _syslog $level, $msg;
  return if $only_syslog;
  local $done_syslog = 1; # prevent syslog being called twice
  my $prefix = prefix();
  my $has_newline = ($msg =~ m/\n$/);
  local $\;
  print $sayfh "$prefix$msg".($has_newline ? "" : "\n") if $saywarn;
  # here we possibly trigger a __WARN__ hook, possibly calling our _sigwarn
  return warn $prefix, $msg if $has_newline;
  carp $prefix, $msg; # ends up calling warn
}

sub _sigwarn { # via __WARN__ hook
  my $msg = _format(@_);
  unless ($done_syslog) { # detect if we got here via _dowarn()
    _syslog "warning", $msg;
    $msg = prefix . $msg;
    local $\;
    print $sayfh $msg if $saywarn;
  }
  warn $msg;	# has a newline already
}

# ------ significant messages ------

sub logdie {
  # not terribly efficient; but we were going to "die" anyway, so ...
  my $had_newline = chomp(my $msg = join (" ", @_));
  $msg = _format(@_);
  _syslog "err", "PANIC: $msg";
  $msg = prefix . $msg;
  $msg = Carp::shortmess($msg) unless $had_newline;
  print $sayfh "$msg\n" if $saywarn;
  die $msg,"\n";
}

sub logalert {
  local $do_syslog = 1;
  _dowarn("alert", _format(@_));
}

sub logerr {
  _dowarn("err", _format('ERROR:', @_));
}

sub logwarn {
  _dowarn("warning", _format(@_));
}

# ------ normal and trace messages ------

sub logsay {
  chomp(my $msg = _format(@_));
  _syslog "notice", $msg if $Verbose;
  local $\;
  print $sayfh prefix."$msg\n";
}

sub logtrace {
  return unless $Verbose > 2;
  chomp(my $msg = _format(@_));
  _syslog "info", $msg;
  local $\;
  print $sayfh prefix."$msg\n";
}

sub logdebug {
  return unless $Verbose > 4;
  chomp(my $msg = _format(@_));
  _syslog "debug", $msg;
  local $\;
  print $sayfh prefix."$msg\n";
}

sub logtimes {
  my $msg = shift || '';
  my @base = @_; $base[0] ||= $^T;
  my @now  = (time, (times)[0,1]);
  
  $msg = "[$msg] " if $msg;
  $msg .= sprintf "wall: %02d:%02d user: %02d:%05.2f system: %02d:%05.2f",
    map { my $d = $now[$_]-($base[$_]||0); my $m = int($d/60); ($m, $d-$m*60) } 0..2;

  _syslog "notice", $msg if $Verbose;
  local $\;
  print $sayfh prefix."$msg\n";

  @now;
}


# ---- 

sub _format {
    my @args = @_;
    #warn Data::Dumper->Dump([\@_], [qw(_)]);
    my $msg = join " ", map { ref $_ ? $json->encode($_) : defined $_ ? $_ : 'UNDEF' } @args;
    if ($utf8) {
        # Our output streams are utf8. If string is not already utf8 and
        # does not decode as valid utf8, then upgrade from latin1
        utf8::upgrade($msg) unless utf8::is_utf8($msg) or utf8::decode($msg);
    }
    else {
        # Our output streams cannot handle wide-characters. If msg is utf8 then
        # attempt to downgrade to latin1, otherwise just ensure the utf8 flag is not set
        utf8::encode($msg) unless utf8::downgrade($msg,1);
    }
    $msg;
}


sub logtofile {
  my %p = @_;
  my $basename = $p{file} || $Prefix;
  my $lock_mode = $p{lock} || 'die';
  my @lt = localtime();
  my $filename = sprintf "%s.log.%4d%02d%02d", $basename, $lt[5]+1900, $lt[4]+1, $lt[3];
  my $lock_ok;
  carp "Bad lockmode '$lock_mode'" unless $lock_mode =~ m/^(die|warn|none)$/;

  my $dir = $config->log_path;
  -e $dir or mkpath $dir, 0;
  if ($p{hierarchical}) {
    my ($year,$month) = $filename =~ / (\d{4}) (\d{2}) \d{2} $/x;
    my $subdir = "$dir/$year/$month";
    -e $subdir or mkpath $subdir, 0;
    $filename = "$year/$month/$filename";
  }
  my $path = "$dir/$filename";
  open(STDOUT,">>$path") or die("logtofile: Can't open($path): $!");
  select(STDOUT); $|=1;
  $LogToFile = $path;

  logconfig(
    sayfh => \*STDOUT,   # write logsay etc to (new, current) stdout
    sigwarn => 1,        # catch warn() and output with prefix
    saywarn => 1,        # write warn etc msgs to sayfh (STDOUT) as well as via warn() to STDERR
    syslog => 0,         # don't use syslog (stderr for cron will send email)
    prefix => $basename, # match name used for logfile
    banner => 1,
  );

  if (flock(STDOUT, LOCK_EX|LOCK_NB)) {
    $lock_ok = 1;
  }
  else {
    my $msg = "Can't lock $path (another $basename running?): $!";
    print "$msg ($lock_mode)\n" unless $lock_mode eq 'none';
    die   "$msg\n" if $lock_mode eq 'die';
    logalert "$msg\n" if $lock_mode eq 'warn';
  }

  my $symlink  = "$dir/$basename.log";
  my $readlink = readlink($symlink) || '';
  unless ($readlink eq $filename) {
    local *LOCK;
    if ($readlink
        and -f "$dir/$readlink"
        # open in append (write) mode as solaris requires this for flock(LOCK_EX)
        and open(LOCK, ">>$dir/$readlink")
        and !flock(LOCK, LOCK_EX|LOCK_NB)) 
    {
      $lock_ok = 0; # report not okay as another process is still running
      my $msg = "Can't lock $readlink (another $basename running?): $!";
      print "$msg ($lock_mode)\n" unless $lock_mode eq 'none';
      die   "$msg\n" if $lock_mode eq 'die';
      logalert "$msg\n" if $lock_mode eq 'warn';
    }
    unlink $symlink;
    symlink $filename, $symlink or warn "symlink($filename, $symlink): $!";
  }
  return $lock_ok;
}

sub logbanner {
  $ShowExitBanner = 1;
  my $hostname = hostname();
  print $sayfh "\n\n===== ".localtime()." on $hostname\n"; # marker for restarts that can easily be searched for.
  print $sayfh "STARTED (@orig_argv) pid=$$\n";
}


END {
  return unless $ShowExitBanner;
  # add marker for exit that can easily be searched for, also show end time and duration
  my $died = ($?==255 && $@) ? $@ : ($?) ? "($?)" : "";
  my $mins = (time-$^T)/60;
  printf "----- ".localtime()." END after %.1f mins (%.1f hours). %s\n\n", $mins, $mins/60, $died;
}

1;

__END__

=head1 NAME

  Combust::Logger - Direct diagnostic output to the right place

=head1 SYNOPSYS

  use Combust::Logger;
  
  logconfig( prefix => 'httpd' );
  
  logerr("Not found: $file");
  logdie("Internal error");

  logtofile();

=head1 DESCRIPTION

Combust::Logger will direct diagnostic and error output to the
desired location, currently this is syslog and STDERR. That is unless
the script is running inside mod_perl, then syslog will not be called.

Each of the logging functions will join all arguments together
with a single space and then perform the operations described below.

The verbose level can be set with C<logconfig> or by setting the
$Combust::Logger::Verbose package variable.

=over 4

=item logconfig ( OPTIONS )

C<OPTIONS> is a list of name-value pairs. Accepted names are

domain - Set the network domain to use to connect to the syslog daemon.
This will default to 'unix'

prefix - program name to use when logging. This will default to the last
element of the path in $0

verbose - Set the verbose level

=item logalert ( [ ARGS ] )

Log with syslog as 'alert' and call carp.

=item logdie ( [ ARGS ] )

Log with syslog as 'err' and call I<croak>.

=item logerr ( [ ARGS ] )

Log with syslog as 'err' and call carp.

=item logwarn ( [ ARGS ] )

Log with syslog as 'warn' and call carp.

=item logsay ( [ ARGS ] )

Print to STDERR (typically written to local log file) with a newline appended.
Log with syslog as 'notice' if verbose level is non-zero.

=item logtrace ( [ ARGS ] )

Log with syslog as 'info' and print to STDERR with a newline appended.
Only if verbose level is greater than 2.

=item logdebug ( [ ARGS ] )

Log with syslog as 'debug' and print to STDERR with a newline appended.
Only if verbose level is greater than 4.

=item logtimes ( [ MSG [, BASE ] ] )

Same as

  logsay("[$MSG] $times");

Where $times is a string showing wall, user and system times from
the given BASE or the start of the program. It returns an array
which can be passed for BASE in a subsequent call, this allows a
program to get times for its sections, eg

  my @base;
  foreach my $section (sections) {
    ...
    @base = logtimes($section, @base);
  }
  logtimes('Total');

=item logtofile ( OPTIONS )

Directs stdout to append to a log file:

 ~/logs/$name.log.YYYYMMDD

where $name defaults to the basename of the program.
A symlink ~/logs/$name.log is also maintained.

A $SIG{__WARN__} hook is also used to write a copy of any warning
messages into the log file.

It's primarily designed to enable simple logging for cron jobs.

=back

=cut

For reference, from the syslog man page:

          LOG_EMERG           A panic condition.   This  is  nor-
                              mally broadcast to all users.

          LOG_ALERT           A   condition   that   should    be
                              corrected  immediately,  such  as a
                              corrupted system database.

          LOG_CRIT            Critical conditions, such  as  hard
                              device errors.

          LOG_ERR             Errors.

          LOG_WARNING         Warning messages.

          LOG_NOTICE          Conditions that are not error  con-
                              ditions,  but that may require spe-
                              cial handling.

          LOG_INFO            Informational messages.

          LOG_DEBUG           Messages that  contain  information
                              normally of use only when debugging
                              a program.


