package RRE::Model;
use strict;
use RRE::Model::Mail;
use RRE::Model::Link;
use Develooper::DB qw(db_open);

sub new {
  my $proto = shift;
  my $class = ref $proto || $proto;
  my $self = bless( { }, $class);
  return $self;
}

sub get_links {
  my ($self, $args) = @_;

  my $dbh = db_open;

  my $limit = $args->{limit} || 120;

  return map { RRE::Model::Link->new($_) } 
    @{$dbh->selectall_arrayref(
         q[SELECT rre_links.link_id as link_id,date,comment,category_name,url,
                  UNIX_TIMESTAMP(date) as unixtime
          FROM rre_links
            INNER JOIN rre_categories USING(category_id)
            JOIN rre_mails ON(rre_mails.mail_id=rre_links.mail_id)
            JOIN rre_urls ON(rre_links.link_id=rre_urls.link_id)
          ORDER BY date desc, link_id LIMIT ?;
         ],
         {Columns=>{}},
         $limit
        )
     };
} 

sub get_mails {
  my ($self, $args) = @_;
  my $dbh = db_open;
  my $limit;
  #warn join " -> ", %args;
  if ($args->{limit}) {
    warn "LIMIT!!";
    $limit = "LIMIT ?";
  } 
  return map { RRE::Model::Mail->new($_) } 
    @{$dbh->selectall_arrayref(qq[SELECT *,UNIX_TIMESTAMP(date) as unixtime
                                  FROM rre_mails
                                  ORDER BY date DESC $limit], 
                             {Columns=>{}},
                              ($limit ? $args->{limit} : ()) ) };
}

1;
