#!/usr/bin/perl

open INDEX, ">index.html" or die;

print INDEX <<'END';
[% page.title = "Perl6 Apocalypses" %]

<p>
"What I will be revealing in these columns will be the design of Perl
6. Or more accurately, the beginnings of that design, since the design
process will certainly continue after I've had my initial say in the
matter. I'm not omniscient, rumors to the contrary
notwithstanding. This job of playing God is a little too big for
me. Nevertheless, someone has to do it, so I'll try my best to fake
it. And I'll expect all of you to help me out with the process of
creating history. We all have to do our bit with free will."

<div align=right><i>--Larry Wall, Apocalypse 1</i></div>

</p>
<p>

<UL>
END

foreach $pod (<A??.pod>) {
    ($html = $pod) =~ s/pod$/html/;
    ($num) = $pod =~ /(\d+)/;
    $num += 0;
    open POD, $pod or die;
    undef $/;
    $file = <POD>;
    ($date) = $file =~ /last\s*modified:\s+(.*)/i;
    ($anum, $title) = $file =~ /Apocalypse (\d+):\s+(.*)/;
    warn "Mismatch" unless $anum == $num;
    print INDEX <<"END";
<LI><A HREF="$html">
    $num => "$title ($date)"
</A>
END

    if ($num == 6) {
	print INDEX <<'END';
<LI><A HREF="A06.html#Apocalypse_7:_Formats">
    7 => "Formats" </A> (see <A HREF="../exegesis/E07.html">E07</A>)
END
    }
}

print INDEX <<'END';
</UL>
END
