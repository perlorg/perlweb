package Bundle::Combust;

$VERSION = "1.01";

1;

__END__

=head1 NAME

Bundle::Combust - All the modules required to run Combust

=head1 SYNOPSIS

perl -MCPAN -e 'install Bundle::Combust'

=head1 DESCRIPTION

Installs all the modules as listed on
L<http://combust.develooper.com/install.html> that are required
to run a Combust server except DBD::mysql

=head1 CONTENTS

Date::Parse

DBI

Exception::Class

Bundle::LWP

Text::Template

Config::Simple

Mail::Internet

Time::HiRes

URI::Find

Template

Apache::Reload

Pod::Simple

Apache::DBI

Apache::Request

=head1 AUTHOR

Gabor Szabo E<lt>gabor@pti.co.ilE<gt>

If you find out that the list of the required modules of
Combust is not the same as the one provided in this file,
please contact me. If some of the modules in this distribution
do not install correctly, please refer to their documentation
and to the respective authors.

=head1 COPYRIGHT

Copyright 2003 by Gabor Szabo L<http://www.pti.co.il>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut

