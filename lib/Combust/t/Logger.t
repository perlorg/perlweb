use Test::More tests => 28;
use strict;

use_ok('Combust::Logger');

sub testit {
    my ( $utf8, $str, $result ) = @_;

    $Combust::Logger::utf8 = $utf8;
    my $out = Combust::Logger::_format($str);

    ok( !utf8::is_utf8($result), "utf8 flag set correctly" ) unless $utf8;
    is( utf8::is_utf8($out), utf8::is_utf8($result), "utf8 flag set correctly" );
    is( $out, $result, "correct string out" );
}

{
    my $str = "abc";

    ok(!utf8::is_utf8($str));
    testit( 0, $str, $str );
    testit( 1, $str, $str );
}

{
    my $str = "abc" . chr(0xe9);
    my $out = $str;
    utf8::upgrade($out);

    ok(!utf8::is_utf8($str));
    ok(utf8::is_utf8($out));

    testit( 0, $str, $str );
    testit( 1, $str, $out );

}

{
    my $str = "abc" . chr(0x115);
    my $out = $str;
    utf8::encode($out);

    ok(utf8::is_utf8($str));
    ok(!utf8::is_utf8($out));

    testit( 0, $str, $out );
    testit( 1, $str, $str );

}

{
    my $out = "abc" . chr(0xe9);
    my $str = $out;
    utf8::upgrade($str);

    ok(utf8::is_utf8($str));
    ok(!utf8::is_utf8($out));

    testit( 0, $str, $out );
    testit( 1, $str, $str );
}

