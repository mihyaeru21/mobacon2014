#use strict;
use warnings;
use utf8;
use v5.10;

use Amon2::Lite;
use Digest::MD5 qw/md5_hex/;

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


post '/user/register' => sub {
  my $c = shift;
  my ($username, $password) = ($c->req->param('username'), $c->req->param('password'));

  unless ($username and $password) {
    my $res = $c->render_json({message => "parameter error."});
    $res->status(400);
    return $res;
  }

  my $db = $c->db;
  my $exists = $db->select_row(
    q{SELECT id FROM user WHERE name = ?;},
    $username
  );

  if ($exists) {
    my $res = $c->render_json({message => "User name has already been registered."});
    $res->status(409);
    return $res;
  }

  my $apikey = md5_hex($username . $password);
  $db->query(
    q{INSERT INTO user (name, apikey) VALUES (?, ?);},
    $username,
    $apikey
  );

  my $user = $db->select_row(
    q{SELECT id, name, apikey FROM user WHERE name = ?;},
    $username
  );

  say "";
  say ref $user;
  say "";

  return $c->render_json($user);
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

