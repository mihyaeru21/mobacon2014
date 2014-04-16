#use strict;
use warnings;
use utf8;
use v5.10;

use Amon2::Lite;

get '/' => sub {
  my ($c) = @_;
  my $rows = $c->db->selectall_arrayref(
    q{SELECT id, title FROM books ORDER BY id ASC LIMIT ?;},
    +{},
    10
  );
  return $c->render_json($rows);
};


post '/admin/reset' => sub {
  my $c = shift;
  $c->db->query(q{TRUNCATE TABLE user;});
  $c->db->query(q{TRUNCATE TABLE lend;});
  return $c->create_response(204);
};



use DBIx::Sunny;
sub db {
  my $self = shift;
  return $self->{db} ||= $self->_db_connect;
}

sub _db_connect {
  my $self = shift;

  my $dbsource = "dbi:mysql:database=heroku_e54741c2341fd99;host=us-cdbr-east-05.cleardb.net";
  my $dbh = DBIx::Sunny->connect($dbsource, $ENV{'MYSQL_USER'}, $ENV{'MYSQL_PASS'}, +{
      RaiseError        => 1,
      mysql_enable_utf8 => 1,
  });

  return $dbh;
}


__PACKAGE__->load_plugins(
  'Web::JSON',
);

__PACKAGE__->to_app();

