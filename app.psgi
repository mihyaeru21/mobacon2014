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

  my $param_lost = not ($username and $password);
  my $name_over = length $username > 32;
  my $pass_over = length $password > 65535;
  if ($param_lost or $name_over or $pass_over) {
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

  return $c->render_json({
    id => $user->{id},
    username => $user->{name},
    api_key => $user->{apikey},
  });
};


get '/user/{username:.+}' => sub {
  my ($c, $args) = @_;

  my $username = $args->{username};
  my $user = $c->db->select_row(
    q{SELECT id FROM user WHERE name = ?;},
    $username
  );

  unless ($user) {
    my $res = $c->render_json({message => "Not found."});
    $res->status(404);
    return $res;
  }

  return $c->render_json(
    {id => $user->{id}}
  );
};

any ['delete'], '/user/{username:.+}' => sub {
  my ($c, $args) = @_;

  my $username = $args->{username};
  my $apikey_req = $c->req->param('api_key');

  unless ($apikey_req) {
    my $res = $c->render_json({message => "Unauthorized"});
    $res->status(401);
    return $res;
  }

  my $user = $c->db->select_row(
    q{SELECT id, apikey FROM user WHERE name = ?;},
    $username
  );

  my $apikey_db = $user->{apikey};
  unless ($apikey_req eq $apikey_db) {
    my $res = $c->render_json({message => "invalid api_key"});
    $res->status(401);
    return $res;
  }
  unless ($user) {
    my $res = $c->render_json({message => "not found"});
    $res->status(404);
    return $res;
  }

  # todo: レンタル中チェック

  $c->db->query(
    q{DELETE FROM user WHERE name = ?;},
    $username
  );

  return $c->render_json(
    {id => $user->{id}}
  );
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

