# perl
use strict;
use warnings;
use 5.10.1;
use Data::Dumper;$Data::Dumper::Indent=1;
use Data::Dump qw( dd pp );
use Carp;
use Cwd;
use Text::Wrap qw( wrap ); $Text::Wrap::columns = 76;

my $dir = cwd();
my $sourcedir = "$dir/inputs";
croak "Could not locate '$sourcedir'" unless (-d $sourcedir);
my $outdir = "$dir/outputs";
croak "Could not locate '$outdir'" unless (-d $outdir);

croak "No Perl version specified on command-line" unless @ARGV == 1;
my $version = shift(@ARGV);
croak "Perl version '$version' incorrectly specified"
    unless $version =~ m/^5\.\d{2}\.\d{1,2}$/;

my $input = "$sourcedir/$version.source.txt";
croak "Could not locate input file '$input'" unless (-f $input);

my @paragraphs_raw = ();
open my $IN, '<', $input or croak "Unable to open '$input' for reading";
{
    local $/ = "\n\n";
    chomp(@paragraphs_raw = <$IN>);
}
close $IN or croak "Unable to close '$input' after reading";
#dd(\@paragraphs_raw);

my @paragraphs_refined = ();
for my $p (@paragraphs_raw) {
    chomp $p;
    my %para;
    $para{raw} = $p;
    if ($p =~ m/^\s+/) {
        # the SHAs
        my @shas_raw = split(/\n/, $p);
        my @shas_refined = ();
        for my $q (@shas_raw) {
            my ($sha, $file) = $q =~ m/^\s+(\S+)\s+(\S+)$/;
            croak "Unable to parse SHA lines"
                unless (length $sha and length $file);
            my %sha_data = (
                sha     => $sha,
                file    => $file,
            );
            push @shas_refined, \%sha_data;
        }
        $para{shas} = \@shas_refined;
    }
    else {
        my $unwrapped = $p =~ s/\n/ /gr;

=pod

        You can download Perl 5.16.2 from your favorite CPAN mirror or from:
        <a href="https://www.metacpan.org/release/RJBS/perl-5.16.2/">https://www.metacpan.org/release/RJBS/perl-5.16.2/</a>

=cut
        if ($unwrapped =~ m/^(.*)(https:\/\/www\.metacpan\.org.*)$/) {
            ($para{text}, $para{url_raw}) = ($1,$2);
        }
        else {
            $para{text} = $unwrapped;
        }
    }
    push @paragraphs_refined, \%para;
}
#dd(\@paragraphs_refined);

my $output = "$outdir/perl-${version}.html";
open my $OUT, '>', $output or croak "Unable to open '$output' for writing";
say $OUT '[% page.title = "Perl ' . $version . ' Release Announcement" %]';
for my $p (@paragraphs_refined) {
    say $OUT '';
    if (exists $p->{url_raw}) {

=pod

<p>
You can download Perl 5.16.2 from your favorite CPAN mirror or from:
<a href="https://www.metacpan.org/release/RJBS/perl-5.16.2/">https://www.metacpan.org/release/RJBS/perl-5.16.2/</a>
</p>

=cut
        say $OUT '<p>';
        say $OUT wrap('','',$p->{text});
        say $OUT '<a href="' . $p->{url_raw} . '">' . $p->{url_raw} . '</a>';
        say $OUT '</p>';
    }
    elsif (exists $p->{shas}) {
        say $OUT '<p>';
        say $OUT '<code>';
        for my $el (@{$p->{shas}}) {
            say $OUT "    $el->{sha}  $el->{file}";
        }
        say $OUT '</code>';
        say $OUT '</p>';
    }
    else {
        say $OUT '<p>';
        say $OUT wrap('','',$p->{text});
        say $OUT '</p>';
    }
}
close $OUT or croak "Unable to close '$output' after writing";
say "Finished!";
