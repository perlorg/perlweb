package Combust::Template::Plugin::JavaScript;
use base qw(Template::Plugin);
use Template::Plugin;

use strict;
use vars qw($VERSION);
$VERSION = '0.01';

use vars qw($FILTER_NAME);
$FILTER_NAME = 'js';

sub new {
    my($self, $context, @args) = @_;
    my $name = $args[0] || $FILTER_NAME;
    $context->define_filter($name, \&encode_js, 0);
    return $self;
}

sub encode_js {
    local $_ = shift;
    return '' unless defined $_;

    s!(['"])!\\$1!g;
    s!\n!\\n!g;
    s!\f!\\f!g;
    s!\r!\\r!g;
    s!\t!\\t!g;
    $_;
}

1;

__END__

=head1 NAME

Template::Plugin::JavaScript - Encodes text to be safe in JavaScript

=head1 SYNOPSIS

  [% USE JavaScript %]
  <script type="text/javascript">
  document.write("[% sometext | js %]");
  </script>

=head1 DESCRIPTION

Template::Plugin::JavaScript is a TT filter that filters text so it
can be safely used in JavaScript quotes.

  [% USE JavaScript %]
  document.write("[% FILTER js %]
  Here's some text going on.
  [% END %]");

will become:

  document.write("\nHere\'s some text going on.\n");

=head1 AUTHOR

The original idea comes from Movable Type's C<encode_js> global filter.

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Apache::JavaScript::DocumentWrite>

=cut
