package RRE::Model::Mail;
use strict;
use Develooper::DB qw(db_open);
use URI::Find;
use URI::Escape qw(uri_escape);

sub new {
  my $proto = shift;
  my $class = ref $proto || $proto;
  my $args = shift;
  my $self = bless( $args, $class);
  return $self;
}

sub load {
  my ($proto, $args) = @_;
  my $mail;
  my $dbh = db_open;
  if ($args->{date}) {
    $mail = $dbh->selectrow_hashref(
           q[SELECT *,UNIX_TIMESTAMP(date) as unixtime
             FROM rre_mails where date=?],{}, $args->{date}
    );
  }
  elsif($args->{next} or $args->{prev}) {
    my $comparator = $args->{next} ? '>' : '<';
    my $order      = $args->{next} ? '' : 'DESC';
    $mail = $dbh->selectrow_hashref(
              qq[SELECT *,UNIX_TIMESTAMP(date) as unixtime
                 FROM rre_mails where date $comparator ?
                 ORDER BY date $order
                 LIMIT 1],
                 {},
              $proto->{date}
    );
  } 
  $mail ||= {};
  #warn Data::Dumper->Dump([\$mail], [qw(mail)]);
  $proto->new($mail);
}

sub next { shift->load({ next => 1 }); }
sub prev { shift->load({ prev => 1 }); }


sub categories {
  my $self = shift;
  my $dbh = db_open();
  #warn "MAIL_ID: ", $self->{mail_id};
  my $categories = $dbh->selectall_arrayref(
        q[select DISTINCT rre_categories.category_name from rre_links
          INNER JOIN rre_categories USING(category_id)
          WHERE rre_links.mail_id = ? order by link_id 
                              ], 
                             {Columns=>{}},
                             $self->{mail_id}
                            );
  # warn Data::Dumper->Dump([\$categories, \$self], [qw(cartegories self)]);
  $categories;
}

sub body_html {
  my $self = shift;
  my $body = $self->{body};

  my $url_finder = URI::Find->new
    (
     sub {
       my ($uri, $orig_uri) = @_;
       $uri = qq[<a href="$uri">$uri</a>];
       $uri;
     }
    );

  $url_finder->find(\$body);

  # hack to not make the last "end" a link
  $body =~ s!\n\nend\n!\n \nend\n!;

  $body =~ s!\n\n([^\n]{2,50})\n\n!\n<h3>$1</h3>\n\n!mg;

  my $url = $self->fqdn_url;

  $body =~ s!<h3>(.*?)</h3>!my $n = uri_escape($1); qq[<h3><a name="$n" href="$url#$n">$1] 
                                                     . '</a></h3>'!ge;

  $body =~ s/\n\n/<p>/g;
  $body =~ s!\n!<br />\n!g;

  return $body;
}

sub url {
  my $self = shift;
  my $url  = $self->{date};
  $url =~ s!-!/!g;
  $url =~ s! !/a.!;
  $url =~ s!:!.!g;
  return $url . ".html";
}  

sub fqdn_url {
  my $self = shift;
  return 'http://www.redrockeater.org/' . $self->url;
}

1;
