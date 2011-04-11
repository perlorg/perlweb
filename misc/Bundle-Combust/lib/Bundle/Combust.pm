package Bundle::Combust;

$VERSION = "1.04";

1;

__END__

=head1 NAME

Bundle::Combust - All the modules required to run Combust

=head1 SYNOPSIS

    perl -MCPAN -e 'install Bundle::Combust'

or if using a version not on CPAN

    perl -MCPAN -I/Users/ask/src/combust/misc/Bundle-Combust/lib  -e 'install "Bundle::Combust"'


=head1 DESCRIPTION

Installs all the modules as listed on
L<http://combust.develooper.com/install.html> that are required
to run a Combust server except DBD::mysql



=head1 CONTENTS

Date::Parse

DBI

Devel::StackTrace

Class::Data::Inheritable

Exception::Class

Compress::Zlib

Bundle::LWP

Config::Simple

Time::HiRes

URI::Find

AppConfig

Template

Template::Timer

Apache::Reload

Pod::Escapes

Pod::Simple

Digest::SHA

Apache::DBI

Apache::Test

Apache::Request

Yahoo::Search

XML::NamespaceSupport

XML::SAX

XML::Simple

Exception::Class

String::CRC32

Cache::Memcached

Class::Accessor::Class

JSON::XS

=head1 AUTHOR

If you find out that the list of the required modules of
Combust is not the same as the one provided in this file,
please contact me. If some of the modules in this distribution
do not install correctly, please refer to their documentation
and to the respective authors.

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut

