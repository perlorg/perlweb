use Test::More qw(no_plan);
use strict;

use_ok('Combust::Template');
ok(my $t = Combust::Template->new(), "new");
ok(my $out = $t->process('default_site/index.html', {}, {site => 'test'}), 'process');
like($out, qr/not configured for the hostname/, 'check the default site template');

1;
