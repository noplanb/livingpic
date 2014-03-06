CREATE TABLE `contact_details` (
  `id` int(11) NOT NULL auto_increment,
  `contact_record_id` int(11) default NULL,
  `field_name` varchar(50) collate utf8_unicode_ci default NULL,
  `field_value` varchar(150) collate utf8_unicode_ci default NULL,
  `kind` varchar(50) collate utf8_unicode_ci default NULL,
  `country_code` int(11) default NULL,
  `value` varchar(50) collate utf8_unicode_ci default NULL,
  `status` varchar(30) collate utf8_unicode_ci default NULL,
  `created_on` datetime NOT NULL,
  `updated_on` datetime NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `index_contact_details_on_contact_record_id` (`contact_record_id`),
  KEY `index_contact_details_on_kind` (`kind`),
  KEY `index_contact_details_on_value` (`value`),
  KEY `index_contact_details_on_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `contact_records` (
  `id` int(11) NOT NULL auto_increment,
  `user_id` int(11) default NULL,
  `source_id` int(11) default NULL,
  `first_name` varchar(50) collate utf8_unicode_ci default NULL,
  `last_name` varchar(50) collate utf8_unicode_ci default NULL,
  PRIMARY KEY  (`id`),
  KEY `index_contact_records_on_user_id` (`user_id`),
  KEY `index_contact_records_on_first_name` (`first_name`),
  KEY `index_contact_records_on_last_name` (`last_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `devices` (
  `id` int(11) NOT NULL auto_increment,
  `user_id` int(11) default NULL,
  `platform` varchar(255) collate utf8_unicode_ci default NULL,
  `version` varchar(255) collate utf8_unicode_ci default NULL,
  `created_on` datetime NOT NULL,
  `updated_on` datetime NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `index_devices_on_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `invites` (
  `id` int(11) NOT NULL auto_increment,
  `occasion_id` int(11) default NULL,
  `inviter_id` int(11) default NULL,
  `invitee_id` int(11) default NULL,
  `created_on` datetime NOT NULL,
  `updated_on` datetime NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `index_invites_on_occasion_id` (`occasion_id`),
  KEY `index_invites_on_inviter_id` (`inviter_id`),
  KEY `index_invites_on_invitee_id` (`invitee_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `notifications` (
  `id` int(11) NOT NULL auto_increment,
  `recipient_id` int(11) default NULL,
  `occasion_id` int(11) default NULL,
  `trigger_id` int(11) default NULL,
  `trigger_type` varchar(255) collate utf8_unicode_ci default NULL,
  `contact_detail_id` int(11) default NULL,
  `contact_value` varchar(50) collate utf8_unicode_ci default NULL,
  `kind` varchar(255) collate utf8_unicode_ci default NULL,
  `template_id` varchar(255) collate utf8_unicode_ci default NULL,
  `status` varchar(20) collate utf8_unicode_ci default NULL,
  `ext_id` varchar(50) collate utf8_unicode_ci default NULL,
  `hash_code` varchar(15) collate utf8_unicode_ci default NULL,
  `created_on` datetime NOT NULL,
  `updated_on` datetime NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `index_notifications_on_occasion_id` (`occasion_id`),
  KEY `index_notifications_on_kind` (`kind`),
  KEY `index_notifications_on_trigger_type_and_trigger_id` (`trigger_type`,`trigger_id`),
  KEY `index_notifications_on_hash_code` (`hash_code`),
  KEY `index_notifications_on_recipient_id` (`recipient_id`),
  KEY `index_notifications_on_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `occasion_pop_estimates` (
  `id` int(11) NOT NULL auto_increment,
  `occasion_id` int(11) default NULL,
  `user_id` int(11) default NULL,
  `value` int(11) default NULL,
  `created_on` datetime NOT NULL,
  `updated_on` datetime NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `index_occasion_pop_estimates_on_occasion_id` (`occasion_id`),
  KEY `index_occasion_pop_estimates_on_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `occasions` (
  `id` int(11) NOT NULL auto_increment,
  `user_id` int(11) default NULL,
  `name` varchar(255) collate utf8_unicode_ci default NULL,
  `longitude` float default NULL,
  `latitude` float default NULL,
  `start_time` datetime default NULL,
  `end_time` datetime default NULL,
  `city` varchar(50) collate utf8_unicode_ci default NULL,
  `created_on` datetime NOT NULL,
  `updated_on` datetime NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `index_occasions_on_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `participations` (
  `id` int(11) NOT NULL auto_increment,
  `occasion_id` int(11) default NULL,
  `user_id` int(11) default NULL,
  `indication_id` int(11) default NULL,
  `indication_type` varchar(255) collate utf8_unicode_ci default NULL,
  `kind` varchar(255) collate utf8_unicode_ci default NULL,
  `created_on` datetime NOT NULL,
  `updated_on` datetime NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `index_participations_on_occasion_id` (`occasion_id`),
  KEY `index_participations_on_user_id` (`user_id`),
  KEY `index_participations_on_indication_type_and_indication_id` (`indication_type`,`indication_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `photo_taggings` (
  `id` int(11) NOT NULL auto_increment,
  `photo_id` int(11) default NULL,
  `tagger_id` int(11) default NULL,
  `taggee_id` int(11) default NULL,
  `tlx` int(11) default NULL,
  `tly` int(11) default NULL,
  `brx` int(11) default NULL,
  `bry` int(11) default NULL,
  `created_on` datetime NOT NULL,
  `updated_on` datetime NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `index_photo_taggings_on_photo_id` (`photo_id`),
  KEY `index_photo_taggings_on_tagger_id` (`tagger_id`),
  KEY `index_photo_taggings_on_taggee_id` (`taggee_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `photos` (
  `id` int(11) NOT NULL auto_increment,
  `user_id` int(11) default NULL,
  `longitude` float default NULL,
  `latitude` float default NULL,
  `occasion_id` int(11) default NULL,
  `pic_file_name` varchar(255) collate utf8_unicode_ci default NULL,
  `pic_content_type` varchar(255) collate utf8_unicode_ci default NULL,
  `pic_file_size` int(11) default NULL,
  `pic_updated_at` datetime default NULL,
  `time` datetime default NULL,
  `created_on` datetime NOT NULL,
  `updated_on` datetime NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `index_photos_on_user_id` (`user_id`),
  KEY `index_photos_on_occasion_id` (`occasion_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `schema_migrations` (
  `version` varchar(255) collate utf8_unicode_ci NOT NULL,
  UNIQUE KEY `unique_schema_migrations` (`version`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `users` (
  `id` int(11) NOT NULL auto_increment,
  `first_name` varchar(255) collate utf8_unicode_ci default NULL,
  `last_name` varchar(255) collate utf8_unicode_ci default NULL,
  `password` varchar(255) collate utf8_unicode_ci default NULL,
  `mobile_number` varchar(255) collate utf8_unicode_ci default NULL,
  `email` varchar(255) collate utf8_unicode_ci default NULL,
  `status` varchar(255) collate utf8_unicode_ci default NULL,
  `auth_token` varchar(255) collate utf8_unicode_ci default NULL,
  `campaign` varchar(255) collate utf8_unicode_ci default NULL,
  `app_version` varchar(75) collate utf8_unicode_ci default NULL,
  `push_enabled` tinyint(1) default NULL,
  `registered_on` datetime default NULL,
  `last_active_on` datetime default NULL,
  `created_on` datetime NOT NULL,
  `updated_on` datetime NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `index_users_on_status` (`status`),
  KEY `index_users_on_mobile_number` (`mobile_number`),
  KEY `index_users_on_first_name` (`first_name`),
  KEY `index_users_on_last_name` (`last_name`),
  KEY `index_users_on_auth_token` (`auth_token`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

INSERT INTO schema_migrations (version) VALUES ('20120809211551');

INSERT INTO schema_migrations (version) VALUES ('20120809211821');

INSERT INTO schema_migrations (version) VALUES ('20120809213715');

INSERT INTO schema_migrations (version) VALUES ('20120809215857');

INSERT INTO schema_migrations (version) VALUES ('20120809220450');

INSERT INTO schema_migrations (version) VALUES ('20120810173048');

INSERT INTO schema_migrations (version) VALUES ('20120814181110');

INSERT INTO schema_migrations (version) VALUES ('20120822205901');

INSERT INTO schema_migrations (version) VALUES ('20121005173914');

INSERT INTO schema_migrations (version) VALUES ('20121201021825');