#!/bin/sh

set -eu

. /integration/tests/api.sh

volume="$(volume_name mysql_data)"

compose exec --no-TTY mysql mysql -prootpassword bivac <<'SQL'
DROP TABLE IF EXISTS `authors`;

CREATE TABLE `authors` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `first_name` varchar(50) COLLATE utf8_unicode_ci NOT NULL,
  `last_name` varchar(50) COLLATE utf8_unicode_ci NOT NULL,
  `email` varchar(100) COLLATE utf8_unicode_ci NOT NULL,
  `birthdate` date NOT NULL,
  `added` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

INSERT INTO `authors` (`id`, `first_name`, `last_name`, `email`, `birthdate`, `added`) VALUES
  (1, 'Gardner', 'Feest', 'uschuster@example.com', '2011-03-29', '1971-01-19 20:22:59'),
  (2, 'Annie', 'Boyer', 'oma33@example.com', '2006-11-25', '2007-11-21 12:42:49'),
  (3, 'Karson', 'Kihn', 'bertrand.parisian@example.net', '1992-02-26', '1991-04-15 17:17:49'),
  (4, 'Karlee', 'Gulgowski', 'justus45@example.org', '1995-09-24', '1973-03-28 03:20:43');

DROP TABLE IF EXISTS `posts`;

CREATE TABLE `posts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `author_id` int(11) NOT NULL,
  `title` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `description` varchar(500) COLLATE utf8_unicode_ci NOT NULL,
  `content` text COLLATE utf8_unicode_ci NOT NULL,
  `date` date NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
SQL

bivac_backup "$volume"

recreate_service_volume mysql
bivac_restore "$volume"

count="$(compose exec --no-TTY mysql mysql -N -B -prootpassword bivac -e "select count(*) from authors")"
if [ "$count" != "4" ]; then
  echo "expected 4 mysql authors, got $count" >&2
  exit 1
fi
