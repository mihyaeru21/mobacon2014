CREATE TABLE IF NOT EXISTS user (
  id int(10) unsigned NOT NULL AUTO_INCREMENT,
  name char(32) NOT NULL UNIQUE,
  apikey char(32) NOT NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS lend (
  user_id int(10) unsigned NOT NULL,
  book_id int(10) unsigned NOT NULL,
  expire  datetime NOT NULL,
  PRIMARY KEY (user_id, book_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

