use Amon2::Lite;

get '/' => sub {
  my ($c) = @_;
  return $c->create_response(
    200,
    ["Content-Type", "text/plain"],
    ["hello"],
  );
};

__PACKAGE__->to_app();
