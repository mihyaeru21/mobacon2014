use Amon2::Lite;

get '/' => sub {
  my ($c) = @_;
  return $c->render_json([1, 2, 'hoge']);
};

__PACKAGE__->load_plugins(
  'Web::JSON',
);

__PACKAGE__->to_app();

