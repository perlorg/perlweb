#!/usr/bin/perl

open INDEX, ">index.html" or die;

print INDEX <<'END';
[% page.title = "Synopses" %]

<p>
A new series that the Perl 6 design team will be releasing soon after each Apocalypse.
</p>
<p>
Er, at least, that's how things started out.  The synopses are now
in the process of becoming our design documents, so you'll find a
lot of details here that aren't mentioned elsewhere.  If there's a
conflict between any other documents and these documents, believe
these documents (unless the other document is email from one of us,
of course, in which case you should yell at us for not keeping these
up to date.)
</p>
<p>
So when we say "S5", we mean "spec" as well as "synopsis".
</p>

<UL>
END

foreach $pod (<S??.pod>) {
    ($html = $pod) =~ s/pod$/html/;
    ($num) = $pod =~ /(\d+)/;
    $num += 0;
    open POD, $pod or die;
    undef $/;
    $file = <POD>;
    ($date) = $file =~ /last\s*modified:\s+(.*)/i;
    ($anum, $title) = $file =~ /Synopsis (\d+):\s+(.*)/;
    warn "Mismatch" unless $anum == $num;
    print INDEX <<"END";
<LI><A HREF="$html">
    $num => "$title ($date)"
</A>
END

}

print INDEX <<'END';
</UL>
END
