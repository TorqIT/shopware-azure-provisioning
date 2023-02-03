-- Adminer 4.8.1 MySQL 5.5.5-10.4.22-MariaDB-1:10.4.22+maria~focal dump

SET NAMES utf8;
SET time_zone = '+00:00';
SET foreign_key_checks = 0;
SET sql_mode = 'NO_AUTO_VALUE_ON_ZERO';

USE `pimcore`;

SET NAMES utf8mb4;

DROP TABLE IF EXISTS `application_logs`;
CREATE TABLE `application_logs` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `pid` int(11) DEFAULT NULL,
  `timestamp` datetime NOT NULL,
  `message` text DEFAULT NULL,
  `priority` enum('emergency','alert','critical','error','warning','notice','info','debug') DEFAULT NULL,
  `fileobject` varchar(1024) DEFAULT NULL,
  `info` varchar(1024) DEFAULT NULL,
  `component` varchar(190) DEFAULT NULL,
  `source` varchar(190) DEFAULT NULL,
  `relatedobject` int(11) unsigned DEFAULT NULL,
  `relatedobjecttype` enum('object','document','asset') DEFAULT NULL,
  `maintenanceChecked` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `component` (`component`),
  KEY `timestamp` (`timestamp`),
  KEY `relatedobject` (`relatedobject`),
  KEY `priority` (`priority`),
  KEY `maintenanceChecked` (`maintenanceChecked`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

TRUNCATE `application_logs`;

DROP TABLE IF EXISTS `assets`;
CREATE TABLE `assets` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `parentId` int(11) unsigned DEFAULT NULL,
  `type` varchar(20) DEFAULT NULL,
  `filename` varchar(255) CHARACTER SET utf8 COLLATE utf8_bin DEFAULT '',
  `path` varchar(765) CHARACTER SET utf8 COLLATE utf8_bin DEFAULT NULL,
  `mimetype` varchar(190) DEFAULT NULL,
  `creationDate` int(11) unsigned DEFAULT NULL,
  `modificationDate` int(11) unsigned DEFAULT NULL,
  `userOwner` int(11) unsigned DEFAULT NULL,
  `userModification` int(11) unsigned DEFAULT NULL,
  `customSettings` longtext DEFAULT NULL,
  `hasMetaData` tinyint(1) NOT NULL DEFAULT 0,
  `versionCount` int(10) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `fullpath` (`path`,`filename`),
  KEY `parentId` (`parentId`),
  KEY `filename` (`filename`),
  KEY `modificationDate` (`modificationDate`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC;

TRUNCATE `assets`;
INSERT INTO `assets` (`id`, `parentId`, `type`, `filename`, `path`, `mimetype`, `creationDate`, `modificationDate`, `userOwner`, `userModification`, `customSettings`, `hasMetaData`, `versionCount`) VALUES
(1,	0,	'folder',	'',	'/',	NULL,	1641743279,	1641743279,	1,	1,	NULL,	0,	0);

DROP TABLE IF EXISTS `assets_metadata`;
CREATE TABLE `assets_metadata` (
  `cid` int(11) unsigned NOT NULL,
  `name` varchar(190) NOT NULL,
  `language` varchar(10) CHARACTER SET ascii NOT NULL DEFAULT '',
  `type` enum('input','textarea','asset','document','object','date','select','checkbox') DEFAULT NULL,
  `data` longtext DEFAULT NULL,
  PRIMARY KEY (`cid`,`name`,`language`),
  KEY `name` (`name`),
  CONSTRAINT `fk_assets_metadata_assets` FOREIGN KEY (`cid`) REFERENCES `assets` (`id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

TRUNCATE `assets_metadata`;

DROP TABLE IF EXISTS `cache_items`;
CREATE TABLE `cache_items` (
  `item_id` varbinary(255) NOT NULL,
  `item_data` mediumblob NOT NULL,
  `item_lifetime` int(10) unsigned DEFAULT NULL,
  `item_time` int(10) unsigned NOT NULL,
  PRIMARY KEY (`item_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

TRUNCATE `cache_items`;

DROP TABLE IF EXISTS `classes`;
CREATE TABLE `classes` (
  `id` varchar(50) NOT NULL,
  `name` varchar(190) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

TRUNCATE `classes`;

DROP TABLE IF EXISTS `classificationstore_collectionrelations`;
CREATE TABLE `classificationstore_collectionrelations` (
  `colId` int(11) unsigned NOT NULL,
  `groupId` int(11) unsigned NOT NULL,
  `sorter` int(10) DEFAULT 0,
  PRIMARY KEY (`colId`,`groupId`),
  KEY `FK_classificationstore_collectionrelations_groups` (`groupId`),
  CONSTRAINT `FK_classificationstore_collectionrelations_groups` FOREIGN KEY (`groupId`) REFERENCES `classificationstore_groups` (`id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

TRUNCATE `classificationstore_collectionrelations`;

DROP TABLE IF EXISTS `classificationstore_collections`;
CREATE TABLE `classificationstore_collections` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `storeId` int(11) DEFAULT NULL,
  `name` varchar(255) NOT NULL DEFAULT '',
  `description` varchar(255) DEFAULT NULL,
  `creationDate` int(11) unsigned DEFAULT 0,
  `modificationDate` int(11) unsigned DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `storeId` (`storeId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

TRUNCATE `classificationstore_collections`;

DROP TABLE IF EXISTS `classificationstore_groups`;
CREATE TABLE `classificationstore_groups` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `storeId` int(11) DEFAULT NULL,
  `parentId` int(11) unsigned NOT NULL DEFAULT 0,
  `name` varchar(190) NOT NULL DEFAULT '',
  `description` varchar(255) DEFAULT NULL,
  `creationDate` int(11) unsigned DEFAULT 0,
  `modificationDate` int(11) unsigned DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `storeId` (`storeId`),
  KEY `name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

TRUNCATE `classificationstore_groups`;

DROP TABLE IF EXISTS `classificationstore_keys`;
CREATE TABLE `classificationstore_keys` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `storeId` int(11) DEFAULT NULL,
  `name` varchar(190) NOT NULL DEFAULT '',
  `title` varchar(255) NOT NULL DEFAULT '',
  `description` text DEFAULT NULL,
  `type` varchar(190) DEFAULT NULL,
  `creationDate` int(11) unsigned DEFAULT 0,
  `modificationDate` int(11) unsigned DEFAULT 0,
  `definition` longtext DEFAULT NULL,
  `enabled` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `name` (`name`),
  KEY `enabled` (`enabled`),
  KEY `type` (`type`),
  KEY `storeId` (`storeId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

TRUNCATE `classificationstore_keys`;

DROP TABLE IF EXISTS `classificationstore_relations`;
CREATE TABLE `classificationstore_relations` (
  `groupId` int(11) unsigned NOT NULL,
  `keyId` int(11) unsigned NOT NULL,
  `sorter` int(11) DEFAULT NULL,
  `mandatory` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`groupId`,`keyId`),
  KEY `FK_classificationstore_relations_classificationstore_keys` (`keyId`),
  KEY `mandatory` (`mandatory`),
  CONSTRAINT `FK_classificationstore_relations_classificationstore_groups` FOREIGN KEY (`groupId`) REFERENCES `classificationstore_groups` (`id`) ON DELETE CASCADE,
  CONSTRAINT `FK_classificationstore_relations_classificationstore_keys` FOREIGN KEY (`keyId`) REFERENCES `classificationstore_keys` (`id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

TRUNCATE `classificationstore_relations`;

DROP TABLE IF EXISTS `classificationstore_stores`;
CREATE TABLE `classificationstore_stores` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(190) DEFAULT NULL,
  `description` longtext DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

TRUNCATE `classificationstore_stores`;

DROP TABLE IF EXISTS `custom_layouts`;
CREATE TABLE `custom_layouts` (
  `id` varchar(64) NOT NULL,
  `classId` varchar(50) NOT NULL,
  `name` varchar(190) DEFAULT NULL,
  `description` text DEFAULT NULL,
  `creationDate` int(11) unsigned DEFAULT NULL,
  `modificationDate` int(11) unsigned DEFAULT NULL,
  `userOwner` int(11) unsigned DEFAULT NULL,
  `userModification` int(11) unsigned DEFAULT NULL,
  `default` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`,`classId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

TRUNCATE `custom_layouts`;

DROP TABLE IF EXISTS `dependencies`;
CREATE TABLE `dependencies` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `sourcetype` enum('document','asset','object') NOT NULL DEFAULT 'document',
  `sourceid` int(11) unsigned NOT NULL DEFAULT 0,
  `targettype` enum('document','asset','object') NOT NULL DEFAULT 'document',
  `targetid` int(11) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `combi` (`sourcetype`,`sourceid`,`targettype`,`targetid`),
  KEY `targettype_targetid` (`targettype`,`targetid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

TRUNCATE `dependencies`;

DROP TABLE IF EXISTS `documents`;
CREATE TABLE `documents` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `parentId` int(11) unsigned DEFAULT NULL,
  `type` enum('page','link','snippet','folder','hardlink','email','newsletter','printpage','printcontainer') DEFAULT NULL,
  `key` varchar(255) CHARACTER SET utf8 COLLATE utf8_bin DEFAULT '',
  `path` varchar(765) CHARACTER SET utf8 COLLATE utf8_bin DEFAULT NULL,
  `index` int(11) unsigned DEFAULT 0,
  `published` tinyint(1) unsigned DEFAULT 1,
  `creationDate` int(11) unsigned DEFAULT NULL,
  `modificationDate` int(11) unsigned DEFAULT NULL,
  `userOwner` int(11) unsigned DEFAULT NULL,
  `userModification` int(11) unsigned DEFAULT NULL,
  `versionCount` int(10) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `fullpath` (`path`,`key`),
  KEY `parentId` (`parentId`),
  KEY `key` (`key`),
  KEY `published` (`published`),
  KEY `modificationDate` (`modificationDate`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC;

TRUNCATE `documents`;
INSERT INTO `documents` (`id`, `parentId`, `type`, `key`, `path`, `index`, `published`, `creationDate`, `modificationDate`, `userOwner`, `userModification`, `versionCount`) VALUES
(1,	0,	'page',	'',	'/',	999999,	1,	1641743279,	1641743279,	1,	1,	0);

DROP TABLE IF EXISTS `documents_editables`;
CREATE TABLE `documents_editables` (
  `documentId` int(11) unsigned NOT NULL DEFAULT 0,
  `name` varchar(750) CHARACTER SET ascii NOT NULL DEFAULT '',
  `type` varchar(50) DEFAULT NULL,
  `data` longtext DEFAULT NULL,
  PRIMARY KEY (`documentId`,`name`),
  CONSTRAINT `fk_documents_editables_documents` FOREIGN KEY (`documentId`) REFERENCES `documents` (`id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

TRUNCATE `documents_editables`;

DROP TABLE IF EXISTS `documents_email`;
CREATE TABLE `documents_email` (
  `id` int(11) unsigned NOT NULL DEFAULT 0,
  `controller` varchar(500) DEFAULT NULL,
  `template` varchar(255) DEFAULT NULL,
  `to` varchar(255) DEFAULT NULL,
  `from` varchar(255) DEFAULT NULL,
  `replyTo` varchar(255) DEFAULT NULL,
  `cc` varchar(255) DEFAULT NULL,
  `bcc` varchar(255) DEFAULT NULL,
  `subject` varchar(255) DEFAULT NULL,
  `missingRequiredEditable` tinyint(1) unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_documents_email_documents` FOREIGN KEY (`id`) REFERENCES `documents` (`id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

TRUNCATE `documents_email`;

DROP TABLE IF EXISTS `documents_hardlink`;
CREATE TABLE `documents_hardlink` (
  `id` int(11) unsigned NOT NULL DEFAULT 0,
  `sourceId` int(11) DEFAULT NULL,
  `propertiesFromSource` tinyint(1) DEFAULT NULL,
  `childrenFromSource` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `sourceId` (`sourceId`),
  CONSTRAINT `fk_documents_hardlink_documents` FOREIGN KEY (`id`) REFERENCES `documents` (`id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

TRUNCATE `documents_hardlink`;

DROP TABLE IF EXISTS `documents_link`;
CREATE TABLE `documents_link` (
  `id` int(11) unsigned NOT NULL DEFAULT 0,
  `internalType` enum('document','asset','object') DEFAULT NULL,
  `internal` int(11) unsigned DEFAULT NULL,
  `direct` varchar(1000) DEFAULT NULL,
  `linktype` enum('direct','internal') DEFAULT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_documents_link_documents` FOREIGN KEY (`id`) REFERENCES `documents` (`id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

TRUNCATE `documents_link`;

DROP TABLE IF EXISTS `documents_newsletter`;
CREATE TABLE `documents_newsletter` (
  `id` int(11) unsigned NOT NULL DEFAULT 0,
  `controller` varchar(500) DEFAULT NULL,
  `template` varchar(255) DEFAULT NULL,
  `from` varchar(255) DEFAULT NULL,
  `subject` varchar(255) DEFAULT NULL,
  `trackingParameterSource` varchar(255) DEFAULT NULL,
  `trackingParameterMedium` varchar(255) DEFAULT NULL,
  `trackingParameterName` varchar(255) DEFAULT NULL,
  `enableTrackingParameters` tinyint(1) unsigned DEFAULT NULL,
  `sendingMode` varchar(20) DEFAULT NULL,
  `plaintext` longtext DEFAULT NULL,
  `missingRequiredEditable` tinyint(1) unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_documents_newsletter_documents` FOREIGN KEY (`id`) REFERENCES `documents` (`id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

TRUNCATE `documents_newsletter`;

DROP TABLE IF EXISTS `documents_page`;
CREATE TABLE `documents_page` (
  `id` int(11) unsigned NOT NULL DEFAULT 0,
  `controller` varchar(500) DEFAULT NULL,
  `template` varchar(255) DEFAULT NULL,
  `title` varchar(255) DEFAULT NULL,
  `description` varchar(383) DEFAULT NULL,
  `metaData` text DEFAULT NULL,
  `prettyUrl` varchar(255) DEFAULT NULL,
  `contentMasterDocumentId` int(11) DEFAULT NULL,
  `targetGroupIds` varchar(255) DEFAULT NULL,
  `missingRequiredEditable` tinyint(1) unsigned DEFAULT NULL,
  `staticGeneratorEnabled` tinyint(1) unsigned DEFAULT NULL,
  `staticGeneratorLifetime` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `prettyUrl` (`prettyUrl`),
  CONSTRAINT `fk_documents_page_documents` FOREIGN KEY (`id`) REFERENCES `documents` (`id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

TRUNCATE `documents_page`;
INSERT INTO `documents_page` (`id`, `controller`, `template`, `title`, `description`, `metaData`, `prettyUrl`, `contentMasterDocumentId`, `targetGroupIds`, `missingRequiredEditable`, `staticGeneratorEnabled`, `staticGeneratorLifetime`) VALUES
(1,	'App\\Controller\\DefaultController::defaultAction',	'',	'',	'',	NULL,	NULL,	NULL,	NULL,	NULL,	NULL,	NULL);

DROP TABLE IF EXISTS `documents_printpage`;
CREATE TABLE `documents_printpage` (
  `id` int(11) unsigned NOT NULL DEFAULT 0,
  `controller` varchar(500) DEFAULT NULL,
  `template` varchar(255) DEFAULT NULL,
  `lastGenerated` int(11) DEFAULT NULL,
  `lastGenerateMessage` text DEFAULT NULL,
  `contentMasterDocumentId` int(11) DEFAULT NULL,
  `missingRequiredEditable` tinyint(1) unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_documents_printpage_documents` FOREIGN KEY (`id`) REFERENCES `documents` (`id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

TRUNCATE `documents_printpage`;

DROP TABLE IF EXISTS `documents_snippet`;
CREATE TABLE `documents_snippet` (
  `id` int(11) unsigned NOT NULL DEFAULT 0,
  `controller` varchar(500) DEFAULT NULL,
  `template` varchar(255) DEFAULT NULL,
  `contentMasterDocumentId` int(11) DEFAULT NULL,
  `missingRequiredEditable` tinyint(1) unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_documents_snippet_documents` FOREIGN KEY (`id`) REFERENCES `documents` (`id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

TRUNCATE `documents_snippet`;

DROP TABLE IF EXISTS `documents_translations`;
CREATE TABLE `documents_translations` (
  `id` int(11) unsigned NOT NULL DEFAULT 0,
  `sourceId` int(11) unsigned NOT NULL DEFAULT 0,
  `language` varchar(10) NOT NULL DEFAULT '',
  PRIMARY KEY (`sourceId`,`language`),
  KEY `id` (`id`),
  KEY `language` (`language`),
  CONSTRAINT `fk_documents_translations_documents` FOREIGN KEY (`id`) REFERENCES `documents` (`id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

TRUNCATE `documents_translations`;

DROP TABLE IF EXISTS `edit_lock`;
CREATE TABLE `edit_lock` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `cid` int(11) unsigned NOT NULL DEFAULT 0,
  `ctype` enum('document','asset','object') DEFAULT NULL,
  `userId` int(11) unsigned NOT NULL DEFAULT 0,
  `sessionId` varchar(255) DEFAULT NULL,
  `date` int(11) unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `ctype` (`ctype`),
  KEY `cidtype` (`cid`,`ctype`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

TRUNCATE `edit_lock`;

DROP TABLE IF EXISTS `element_workflow_state`;
CREATE TABLE `element_workflow_state` (
  `cid` int(10) NOT NULL DEFAULT 0,
  `ctype` enum('document','asset','object') NOT NULL,
  `place` text DEFAULT NULL,
  `workflow` varchar(100) NOT NULL,
  PRIMARY KEY (`cid`,`ctype`,`workflow`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

TRUNCATE `element_workflow_state`;

DROP TABLE IF EXISTS `email_blacklist`;
CREATE TABLE `email_blacklist` (
  `address` varchar(190) NOT NULL DEFAULT '',
  `creationDate` int(11) unsigned DEFAULT NULL,
  `modificationDate` int(11) unsigned DEFAULT NULL,
  PRIMARY KEY (`address`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

TRUNCATE `email_blacklist`;

DROP TABLE IF EXISTS `email_log`;
CREATE TABLE `email_log` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `documentId` int(11) unsigned DEFAULT NULL,
  `requestUri` varchar(500) DEFAULT NULL,
  `params` text DEFAULT NULL,
  `from` varchar(500) DEFAULT NULL,
  `replyTo` varchar(255) DEFAULT NULL,
  `to` longtext DEFAULT NULL,
  `cc` longtext DEFAULT NULL,
  `bcc` longtext DEFAULT NULL,
  `sentDate` int(11) unsigned DEFAULT NULL,
  `subject` varchar(500) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `sentDate` (`sentDate`,`id`),
  KEY `fk_email_log_documents` (`documentId`),
  FULLTEXT KEY `fulltext` (`from`,`to`,`cc`,`bcc`,`subject`,`params`),
  CONSTRAINT `fk_email_log_documents` FOREIGN KEY (`documentId`) REFERENCES `documents` (`id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

TRUNCATE `email_log`;

DROP TABLE IF EXISTS `glossary`;
CREATE TABLE `glossary` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `language` varchar(10) DEFAULT NULL,
  `casesensitive` tinyint(1) DEFAULT NULL,
  `exactmatch` tinyint(1) DEFAULT NULL,
  `text` varchar(255) DEFAULT NULL,
  `link` varchar(255) DEFAULT NULL,
  `abbr` varchar(255) DEFAULT NULL,
  `site` int(11) unsigned DEFAULT NULL,
  `creationDate` int(11) unsigned DEFAULT 0,
  `modificationDate` int(11) unsigned DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `language` (`language`),
  KEY `site` (`site`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

TRUNCATE `glossary`;

DROP TABLE IF EXISTS `gridconfigs`;
CREATE TABLE `gridconfigs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ownerId` int(11) DEFAULT NULL,
  `classId` varchar(50) DEFAULT NULL,
  `name` varchar(50) DEFAULT NULL,
  `searchType` varchar(50) DEFAULT NULL,
  `type` enum('asset','object') NOT NULL DEFAULT 'object',
  `config` longtext DEFAULT NULL,
  `description` longtext DEFAULT NULL,
  `creationDate` int(11) DEFAULT NULL,
  `modificationDate` int(11) DEFAULT NULL,
  `shareGlobally` tinyint(1) DEFAULT NULL,
  `setAsFavourite` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `ownerId` (`ownerId`),
  KEY `classId` (`classId`),
  KEY `searchType` (`searchType`),
  KEY `shareGlobally` (`shareGlobally`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

TRUNCATE `gridconfigs`;

DROP TABLE IF EXISTS `gridconfig_favourites`;
CREATE TABLE `gridconfig_favourites` (
  `ownerId` int(11) NOT NULL,
  `classId` varchar(50) NOT NULL,
  `objectId` int(11) NOT NULL DEFAULT 0,
  `gridConfigId` int(11) NOT NULL,
  `searchType` varchar(50) NOT NULL DEFAULT '',
  `type` enum('asset','object') NOT NULL DEFAULT 'object',
  PRIMARY KEY (`ownerId`,`classId`,`searchType`,`objectId`),
  KEY `classId` (`classId`),
  KEY `searchType` (`searchType`),
  KEY `grid_config_id` (`gridConfigId`),
  CONSTRAINT `fk_gridconfig_favourites_gridconfigs` FOREIGN KEY (`gridConfigId`) REFERENCES `gridconfigs` (`id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

TRUNCATE `gridconfig_favourites`;

DROP TABLE IF EXISTS `gridconfig_shares`;
CREATE TABLE `gridconfig_shares` (
  `gridConfigId` int(11) NOT NULL,
  `sharedWithUserId` int(11) NOT NULL,
  PRIMARY KEY (`gridConfigId`,`sharedWithUserId`),
  KEY `sharedWithUserId` (`sharedWithUserId`),
  KEY `grid_config_id` (`gridConfigId`),
  CONSTRAINT `fk_gridconfig_shares_gridconfigs` FOREIGN KEY (`gridConfigId`) REFERENCES `gridconfigs` (`id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

TRUNCATE `gridconfig_shares`;

DROP TABLE IF EXISTS `http_error_log`;
CREATE TABLE `http_error_log` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `uri` varchar(1024) CHARACTER SET utf8 COLLATE utf8_bin DEFAULT NULL,
  `code` int(3) DEFAULT NULL,
  `parametersGet` longtext DEFAULT NULL,
  `parametersPost` longtext DEFAULT NULL,
  `cookies` longtext DEFAULT NULL,
  `serverVars` longtext DEFAULT NULL,
  `date` int(11) unsigned DEFAULT NULL,
  `count` bigint(20) unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `uri` (`uri`),
  KEY `code` (`code`),
  KEY `date` (`date`),
  KEY `count` (`count`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC;

TRUNCATE `http_error_log`;

DROP TABLE IF EXISTS `importconfigs`;
CREATE TABLE `importconfigs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ownerId` int(11) DEFAULT NULL,
  `classId` varchar(50) DEFAULT NULL,
  `name` varchar(50) DEFAULT NULL,
  `config` longtext DEFAULT NULL,
  `description` longtext DEFAULT NULL,
  `creationDate` int(11) DEFAULT NULL,
  `modificationDate` int(11) DEFAULT NULL,
  `shareGlobally` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `ownerId` (`ownerId`),
  KEY `classId` (`classId`),
  KEY `shareGlobally` (`shareGlobally`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

TRUNCATE `importconfigs`;

DROP TABLE IF EXISTS `importconfig_shares`;
CREATE TABLE `importconfig_shares` (
  `importConfigId` int(11) NOT NULL,
  `sharedWithUserId` int(11) NOT NULL,
  PRIMARY KEY (`importConfigId`,`sharedWithUserId`),
  KEY `sharedWithUserId` (`sharedWithUserId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

TRUNCATE `importconfig_shares`;

DROP TABLE IF EXISTS `lock_keys`;
CREATE TABLE `lock_keys` (
  `key_id` varchar(64) NOT NULL,
  `key_token` varchar(44) NOT NULL,
  `key_expiration` int(10) unsigned NOT NULL,
  PRIMARY KEY (`key_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

TRUNCATE `lock_keys`;

DROP TABLE IF EXISTS `messenger_messages`;
CREATE TABLE `messenger_messages` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `body` longtext NOT NULL,
  `headers` longtext NOT NULL,
  `queue_name` varchar(255) NOT NULL,
  `created_at` datetime NOT NULL,
  `available_at` datetime NOT NULL,
  `delivered_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `IDX_75EA56E016BA31DB` (`delivered_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

TRUNCATE `messenger_messages`;

DROP TABLE IF EXISTS `migration_versions`;
CREATE TABLE `migration_versions` (
  `version` varchar(1024) COLLATE utf8_unicode_ci NOT NULL,
  `executed_at` datetime DEFAULT NULL,
  `execution_time` int(11) DEFAULT NULL,
  PRIMARY KEY (`version`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

TRUNCATE `migration_versions`;
INSERT INTO `migration_versions` (`version`, `executed_at`, `execution_time`) VALUES
('Pimcore\\Bundle\\CoreBundle\\Migrations\\Version20201008082752',	NULL,	NULL),
('Pimcore\\Bundle\\CoreBundle\\Migrations\\Version20201008091131',	NULL,	NULL),
('Pimcore\\Bundle\\CoreBundle\\Migrations\\Version20201008101817',	NULL,	NULL),
('Pimcore\\Bundle\\CoreBundle\\Migrations\\Version20201008132324',	NULL,	NULL),
('Pimcore\\Bundle\\CoreBundle\\Migrations\\Version20201009095924',	NULL,	NULL),
('Pimcore\\Bundle\\CoreBundle\\Migrations\\Version20201012154224',	NULL,	NULL),
('Pimcore\\Bundle\\CoreBundle\\Migrations\\Version20201014101437',	NULL,	NULL),
('Pimcore\\Bundle\\CoreBundle\\Migrations\\Version20201113143914',	NULL,	NULL),
('Pimcore\\Bundle\\CoreBundle\\Migrations\\Version20201201084201',	NULL,	NULL),
('Pimcore\\Bundle\\CoreBundle\\Migrations\\Version20210107103923',	NULL,	NULL),
('Pimcore\\Bundle\\CoreBundle\\Migrations\\Version20210218142556',	NULL,	NULL),
('Pimcore\\Bundle\\CoreBundle\\Migrations\\Version20210323082921',	NULL,	NULL),
('Pimcore\\Bundle\\CoreBundle\\Migrations\\Version20210323110055',	NULL,	NULL),
('Pimcore\\Bundle\\CoreBundle\\Migrations\\Version20210324152821',	NULL,	NULL),
('Pimcore\\Bundle\\CoreBundle\\Migrations\\Version20210324152822',	NULL,	NULL),
('Pimcore\\Bundle\\CoreBundle\\Migrations\\Version20210330132354',	NULL,	NULL),
('Pimcore\\Bundle\\CoreBundle\\Migrations\\Version20210408153226',	NULL,	NULL),
('Pimcore\\Bundle\\CoreBundle\\Migrations\\Version20210412112812',	NULL,	NULL),
('Pimcore\\Bundle\\CoreBundle\\Migrations\\Version20210428145320',	NULL,	NULL),
('Pimcore\\Bundle\\CoreBundle\\Migrations\\Version20210430124911',	NULL,	NULL),
('Pimcore\\Bundle\\CoreBundle\\Migrations\\Version20210505093841',	NULL,	NULL),
('Pimcore\\Bundle\\CoreBundle\\Migrations\\Version20210531125102',	NULL,	NULL),
('Pimcore\\Bundle\\CoreBundle\\Migrations\\Version20210608094532',	NULL,	NULL),
('Pimcore\\Bundle\\CoreBundle\\Migrations\\Version20210616114744',	NULL,	NULL),
('Pimcore\\Bundle\\CoreBundle\\Migrations\\Version20210624085031',	NULL,	NULL),
('Pimcore\\Bundle\\CoreBundle\\Migrations\\Version20210630062445',	NULL,	NULL),
('Pimcore\\Bundle\\CoreBundle\\Migrations\\Version20210702102100',	NULL,	NULL),
('Pimcore\\Bundle\\CoreBundle\\Migrations\\Version20210706090823',	NULL,	NULL),
('Pimcore\\Bundle\\CoreBundle\\Migrations\\Version20210901130000',	NULL,	NULL),
('Pimcore\\Bundle\\CoreBundle\\Migrations\\Version20210928135248',	NULL,	NULL),
('Pimcore\\Bundle\\CoreBundle\\Migrations\\Version20211016084043',	'2022-02-08 17:07:57',	29),
('Pimcore\\Bundle\\CoreBundle\\Migrations\\Version20211018104331',	'2022-02-08 17:07:57',	589),
('Pimcore\\Bundle\\CoreBundle\\Migrations\\Version20211028134037',	'2022-02-08 17:07:58',	1),
('Pimcore\\Bundle\\CoreBundle\\Migrations\\Version20211028155535',	NULL,	NULL),
('Pimcore\\Bundle\\CoreBundle\\Migrations\\Version20211103055110',	'2022-02-08 17:07:58',	329),
('Pimcore\\Bundle\\CoreBundle\\Migrations\\Version20211209131141',	'2022-02-08 17:07:58',	282),
('Pimcore\\Bundle\\CoreBundle\\Migrations\\Version20211221152344',	'2022-02-08 17:07:59',	41),
('Pimcore\\Bundle\\CoreBundle\\Migrations\\Version20220119082511',	'2022-02-08 17:07:59',	59),
('Pimcore\\Bundle\\CoreBundle\\Migrations\\Version20220120121803',	'2022-02-08 17:07:59',	190),
('Pimcore\\Bundle\\CoreBundle\\Migrations\\Version20220120162621',	'2022-02-08 17:07:59',	327),
('Pimcore\\Bundle\\CoreBundle\\Migrations\\Version20220201132131',	'2022-02-08 17:07:59',	1);

DROP TABLE IF EXISTS `notes`;
CREATE TABLE `notes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `type` varchar(255) DEFAULT NULL,
  `cid` int(11) DEFAULT NULL,
  `ctype` enum('asset','document','object') DEFAULT NULL,
  `date` int(11) DEFAULT NULL,
  `user` int(11) DEFAULT NULL,
  `title` varchar(255) DEFAULT NULL,
  `description` longtext DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `cid_ctype` (`cid`,`ctype`),
  KEY `date` (`date`),
  KEY `user` (`user`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

TRUNCATE `notes`;

DROP TABLE IF EXISTS `notes_data`;
CREATE TABLE `notes_data` (
  `id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `type` enum('text','date','document','asset','object','bool') DEFAULT NULL,
  `data` text DEFAULT NULL,
  PRIMARY KEY (`id`,`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

TRUNCATE `notes_data`;

DROP TABLE IF EXISTS `notifications`;
CREATE TABLE `notifications` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `type` varchar(20) NOT NULL DEFAULT 'info',
  `title` varchar(250) NOT NULL DEFAULT '',
  `message` text NOT NULL,
  `sender` int(11) DEFAULT NULL,
  `recipient` int(11) NOT NULL,
  `read` tinyint(1) NOT NULL DEFAULT 0,
  `creationDate` timestamp NOT NULL DEFAULT current_timestamp(),
  `modificationDate` timestamp NULL DEFAULT NULL,
  `linkedElementType` enum('document','asset','object') DEFAULT NULL,
  `linkedElement` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `recipient` (`recipient`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

TRUNCATE `notifications`;

DROP TABLE IF EXISTS `objects`;
CREATE TABLE `objects` (
  `o_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `o_parentId` int(11) unsigned DEFAULT NULL,
  `o_type` enum('object','folder','variant') DEFAULT NULL,
  `o_key` varchar(255) CHARACTER SET utf8 COLLATE utf8_bin DEFAULT '',
  `o_path` varchar(765) CHARACTER SET utf8 COLLATE utf8_bin DEFAULT NULL,
  `o_index` int(11) unsigned DEFAULT 0,
  `o_published` tinyint(1) unsigned DEFAULT 1,
  `o_creationDate` int(11) unsigned DEFAULT NULL,
  `o_modificationDate` int(11) unsigned DEFAULT NULL,
  `o_userOwner` int(11) unsigned DEFAULT NULL,
  `o_userModification` int(11) unsigned DEFAULT NULL,
  `o_classId` varchar(50) DEFAULT NULL,
  `o_className` varchar(255) DEFAULT NULL,
  `o_childrenSortBy` enum('key','index') DEFAULT NULL,
  `o_childrenSortOrder` enum('ASC','DESC') DEFAULT NULL,
  `o_versionCount` int(10) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`o_id`),
  UNIQUE KEY `fullpath` (`o_path`,`o_key`),
  KEY `key` (`o_key`),
  KEY `index` (`o_index`),
  KEY `published` (`o_published`),
  KEY `parentId` (`o_parentId`),
  KEY `type` (`o_type`),
  KEY `o_modificationDate` (`o_modificationDate`),
  KEY `o_classId` (`o_classId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC;

TRUNCATE `objects`;
INSERT INTO `objects` (`o_id`, `o_parentId`, `o_type`, `o_key`, `o_path`, `o_index`, `o_published`, `o_creationDate`, `o_modificationDate`, `o_userOwner`, `o_userModification`, `o_classId`, `o_className`, `o_childrenSortBy`, `o_childrenSortOrder`, `o_versionCount`) VALUES
(1,	0,	'folder',	'',	'/',	999999,	1,	1641743279,	1641743279,	1,	1,	NULL,	NULL,	NULL,	NULL,	0);

DROP TABLE IF EXISTS `object_url_slugs`;
CREATE TABLE `object_url_slugs` (
  `objectId` int(10) unsigned NOT NULL DEFAULT 0,
  `classId` varchar(50) NOT NULL DEFAULT '0',
  `fieldname` varchar(70) NOT NULL DEFAULT '0',
  `index` int(11) unsigned NOT NULL DEFAULT 0,
  `ownertype` enum('object','fieldcollection','localizedfield','objectbrick') NOT NULL DEFAULT 'object',
  `ownername` varchar(70) NOT NULL DEFAULT '',
  `position` varchar(70) NOT NULL DEFAULT '0',
  `slug` varchar(765) NOT NULL,
  `siteId` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`slug`,`siteId`),
  KEY `index` (`index`),
  KEY `objectId` (`objectId`),
  KEY `classId` (`classId`),
  KEY `fieldname` (`fieldname`),
  KEY `position` (`position`),
  KEY `ownertype` (`ownertype`),
  KEY `ownername` (`ownername`),
  KEY `slug` (`slug`),
  KEY `siteId` (`siteId`),
  CONSTRAINT `fk_object_url_slugs__objectId` FOREIGN KEY (`objectId`) REFERENCES `objects` (`o_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC;

TRUNCATE `object_url_slugs`;

DROP TABLE IF EXISTS `properties`;
CREATE TABLE `properties` (
  `cid` int(11) unsigned NOT NULL DEFAULT 0,
  `ctype` enum('document','asset','object') NOT NULL DEFAULT 'document',
  `cpath` varchar(765) CHARACTER SET utf8 DEFAULT NULL,
  `name` varchar(190) NOT NULL DEFAULT '',
  `type` enum('text','document','asset','object','bool','select') DEFAULT NULL,
  `data` text DEFAULT NULL,
  `inheritable` tinyint(1) unsigned DEFAULT 1,
  PRIMARY KEY (`cid`,`ctype`,`name`),
  KEY `getall` (`cpath`,`ctype`,`inheritable`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC;

TRUNCATE `properties`;

DROP TABLE IF EXISTS `quantityvalue_units`;
CREATE TABLE `quantityvalue_units` (
  `id` varchar(50) NOT NULL,
  `group` varchar(50) DEFAULT NULL,
  `abbreviation` varchar(20) DEFAULT NULL,
  `longname` varchar(250) DEFAULT NULL,
  `baseunit` varchar(50) DEFAULT NULL,
  `factor` double DEFAULT NULL,
  `conversionOffset` double DEFAULT NULL,
  `reference` varchar(50) DEFAULT NULL,
  `converter` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_baseunit` (`baseunit`),
  CONSTRAINT `fk_baseunit` FOREIGN KEY (`baseunit`) REFERENCES `quantityvalue_units` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

TRUNCATE `quantityvalue_units`;

DROP TABLE IF EXISTS `recyclebin`;
CREATE TABLE `recyclebin` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `type` varchar(20) DEFAULT NULL,
  `subtype` varchar(20) DEFAULT NULL,
  `path` varchar(765) DEFAULT NULL,
  `amount` int(3) DEFAULT NULL,
  `date` int(11) unsigned DEFAULT NULL,
  `deletedby` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

TRUNCATE `recyclebin`;

DROP TABLE IF EXISTS `redirects`;
CREATE TABLE `redirects` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `type` enum('entire_uri','path_query','path','auto_create') NOT NULL,
  `source` varchar(255) DEFAULT NULL,
  `sourceSite` int(11) DEFAULT NULL,
  `target` varchar(255) DEFAULT NULL,
  `targetSite` int(11) DEFAULT NULL,
  `statusCode` varchar(3) DEFAULT NULL,
  `priority` int(2) DEFAULT 0,
  `regex` tinyint(1) DEFAULT NULL,
  `passThroughParameters` tinyint(1) DEFAULT NULL,
  `active` tinyint(1) DEFAULT NULL,
  `expiry` int(11) unsigned DEFAULT NULL,
  `creationDate` int(11) unsigned DEFAULT 0,
  `modificationDate` int(11) unsigned DEFAULT 0,
  `userOwner` int(11) unsigned DEFAULT NULL,
  `userModification` int(11) unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `priority` (`priority`),
  KEY `routing_lookup` (`active`,`regex`,`sourceSite`,`source`,`type`,`expiry`,`priority`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC;

TRUNCATE `redirects`;

DROP TABLE IF EXISTS `schedule_tasks`;
CREATE TABLE `schedule_tasks` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `cid` int(11) unsigned DEFAULT NULL,
  `ctype` enum('document','asset','object') DEFAULT NULL,
  `date` int(11) unsigned DEFAULT NULL,
  `action` enum('publish','unpublish','delete','publish-version') DEFAULT NULL,
  `version` bigint(20) unsigned DEFAULT NULL,
  `active` tinyint(1) unsigned DEFAULT 0,
  `userId` int(11) unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `cid` (`cid`),
  KEY `ctype` (`ctype`),
  KEY `active` (`active`),
  KEY `version` (`version`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

TRUNCATE `schedule_tasks`;

DROP TABLE IF EXISTS `search_backend_data`;
CREATE TABLE `search_backend_data` (
  `id` int(11) NOT NULL,
  `fullpath` varchar(765) CHARACTER SET utf8 DEFAULT NULL,
  `maintype` varchar(8) NOT NULL DEFAULT '',
  `type` varchar(20) DEFAULT NULL,
  `subtype` varchar(190) DEFAULT NULL,
  `published` tinyint(1) unsigned DEFAULT NULL,
  `creationDate` int(11) unsigned DEFAULT NULL,
  `modificationDate` int(11) unsigned DEFAULT NULL,
  `userOwner` int(11) DEFAULT NULL,
  `userModification` int(11) DEFAULT NULL,
  `data` longtext DEFAULT NULL,
  `properties` text DEFAULT NULL,
  PRIMARY KEY (`id`,`maintype`),
  KEY `fullpath` (`fullpath`),
  KEY `maintype` (`maintype`),
  KEY `type` (`type`),
  KEY `subtype` (`subtype`),
  KEY `published` (`published`),
  FULLTEXT KEY `fulltext` (`data`,`properties`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC;

TRUNCATE `search_backend_data`;

DROP TABLE IF EXISTS `settings_store`;
CREATE TABLE `settings_store` (
  `id` varchar(190) NOT NULL DEFAULT '',
  `scope` varchar(190) NOT NULL DEFAULT '',
  `data` longtext DEFAULT NULL,
  `type` enum('bool','int','float','string') NOT NULL DEFAULT 'string',
  PRIMARY KEY (`id`,`scope`),
  KEY `scope` (`scope`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

TRUNCATE `settings_store`;

DROP TABLE IF EXISTS `sites`;
CREATE TABLE `sites` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `mainDomain` varchar(255) DEFAULT NULL,
  `domains` text DEFAULT NULL,
  `rootId` int(11) unsigned DEFAULT NULL,
  `errorDocument` varchar(255) DEFAULT NULL,
  `localizedErrorDocuments` text DEFAULT NULL,
  `redirectToMainDomain` tinyint(1) DEFAULT NULL,
  `creationDate` int(11) unsigned DEFAULT 0,
  `modificationDate` int(11) unsigned DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `rootId` (`rootId`),
  CONSTRAINT `fk_sites_documents` FOREIGN KEY (`rootId`) REFERENCES `documents` (`id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

TRUNCATE `sites`;

DROP TABLE IF EXISTS `tags`;
CREATE TABLE `tags` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `parentId` int(10) unsigned DEFAULT NULL,
  `idPath` varchar(190) DEFAULT NULL,
  `name` varchar(255) CHARACTER SET utf8 COLLATE utf8_bin DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idPath_name` (`idPath`,`name`),
  KEY `idpath` (`idPath`),
  KEY `parentid` (`parentId`),
  KEY `name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC;

TRUNCATE `tags`;

DROP TABLE IF EXISTS `tags_assignment`;
CREATE TABLE `tags_assignment` (
  `tagid` int(10) unsigned NOT NULL DEFAULT 0,
  `cid` int(10) NOT NULL DEFAULT 0,
  `ctype` enum('document','asset','object') NOT NULL,
  PRIMARY KEY (`tagid`,`cid`,`ctype`),
  KEY `ctype` (`ctype`),
  KEY `ctype_cid` (`cid`,`ctype`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

TRUNCATE `tags_assignment`;

DROP TABLE IF EXISTS `targeting_rules`;
CREATE TABLE `targeting_rules` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL DEFAULT '',
  `description` text DEFAULT NULL,
  `scope` varchar(50) DEFAULT NULL,
  `active` tinyint(1) DEFAULT NULL,
  `prio` smallint(5) unsigned NOT NULL DEFAULT 0,
  `conditions` longtext DEFAULT NULL,
  `actions` longtext DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

TRUNCATE `targeting_rules`;

DROP TABLE IF EXISTS `targeting_storage`;
CREATE TABLE `targeting_storage` (
  `visitorId` varchar(100) NOT NULL,
  `scope` varchar(50) NOT NULL,
  `name` varchar(100) NOT NULL,
  `value` text DEFAULT NULL,
  `creationDate` datetime DEFAULT NULL,
  `modificationDate` datetime DEFAULT NULL,
  PRIMARY KEY (`visitorId`,`scope`,`name`),
  KEY `targeting_storage_scope_index` (`scope`),
  KEY `targeting_storage_name_index` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

TRUNCATE `targeting_storage`;

DROP TABLE IF EXISTS `targeting_target_groups`;
CREATE TABLE `targeting_target_groups` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL DEFAULT '',
  `description` text DEFAULT NULL,
  `threshold` int(11) DEFAULT NULL,
  `active` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

TRUNCATE `targeting_target_groups`;

DROP TABLE IF EXISTS `tmp_store`;
CREATE TABLE `tmp_store` (
  `id` varchar(190) NOT NULL DEFAULT '',
  `tag` varchar(190) DEFAULT NULL,
  `data` longtext DEFAULT NULL,
  `serialized` tinyint(2) NOT NULL DEFAULT 0,
  `date` int(11) unsigned DEFAULT NULL,
  `expiryDate` int(11) unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `tag` (`tag`),
  KEY `date` (`date`),
  KEY `expiryDate` (`expiryDate`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

TRUNCATE `tmp_store`;

DROP TABLE IF EXISTS `translations_admin`;
CREATE TABLE `translations_admin` (
  `key` varchar(190) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL DEFAULT '',
  `type` varchar(10) DEFAULT NULL,
  `language` varchar(10) NOT NULL DEFAULT '',
  `text` text DEFAULT NULL,
  `creationDate` int(11) unsigned DEFAULT NULL,
  `modificationDate` int(11) unsigned DEFAULT NULL,
  PRIMARY KEY (`key`,`language`),
  KEY `language` (`language`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

TRUNCATE `translations_admin`;
INSERT INTO `translations_admin` (`key`, `type`, `language`, `text`, `creationDate`, `modificationDate`) VALUES
('Product',	NULL,	'cs',	'',	1644339824,	1644339824),
('Product',	NULL,	'de',	'',	1644339824,	1644339824),
('Product',	NULL,	'en',	'',	1644339824,	1644339824),
('Product',	NULL,	'es',	'',	1644339824,	1644339824),
('Product',	NULL,	'fa',	'',	1644339824,	1644339824),
('Product',	NULL,	'fr',	'',	1644339824,	1644339824),
('Product',	NULL,	'hu',	'',	1644339824,	1644339824),
('Product',	NULL,	'it',	'',	1644339824,	1644339824),
('Product',	NULL,	'ja',	'',	1644339824,	1644339824),
('Product',	NULL,	'nl',	'',	1644339824,	1644339824),
('Product',	NULL,	'pl',	'',	1644339824,	1644339824),
('Product',	NULL,	'pt',	'',	1644339824,	1644339824),
('Product',	NULL,	'pt_BR',	'',	1644339824,	1644339824),
('Product',	NULL,	'ru',	'',	1644339824,	1644339824),
('Product',	NULL,	'sk',	'',	1644339824,	1644339824),
('Product',	NULL,	'sv',	'',	1644339824,	1644339824),
('Product',	NULL,	'sv_FI',	'',	1644339824,	1644339824),
('Product',	NULL,	'th',	'',	1644339824,	1644339824),
('Product',	NULL,	'tr',	'',	1644339824,	1644339824),
('Product',	NULL,	'uk',	'',	1644339824,	1644339824),
('Product',	NULL,	'zh_Hans',	'',	1644339824,	1644339824),
('login',	NULL,	'en',	'',	1641743319,	1641743319);

DROP TABLE IF EXISTS `translations_messages`;
CREATE TABLE `translations_messages` (
  `key` varchar(190) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL DEFAULT '',
  `type` varchar(10) DEFAULT NULL,
  `language` varchar(10) NOT NULL DEFAULT '',
  `text` text DEFAULT NULL,
  `creationDate` int(11) unsigned DEFAULT NULL,
  `modificationDate` int(11) unsigned DEFAULT NULL,
  PRIMARY KEY (`key`,`language`),
  KEY `language` (`language`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

TRUNCATE `translations_messages`;

DROP TABLE IF EXISTS `tree_locks`;
CREATE TABLE `tree_locks` (
  `id` int(11) NOT NULL DEFAULT 0,
  `type` enum('asset','document','object') NOT NULL DEFAULT 'asset',
  `locked` enum('self','propagate') DEFAULT NULL,
  PRIMARY KEY (`id`,`type`),
  KEY `type` (`type`),
  KEY `locked` (`locked`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

TRUNCATE `tree_locks`;

DROP TABLE IF EXISTS `users`;
CREATE TABLE `users` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `parentId` int(11) unsigned DEFAULT NULL,
  `type` enum('user','userfolder','role','rolefolder') NOT NULL DEFAULT 'user',
  `name` varchar(50) DEFAULT NULL,
  `password` varchar(190) DEFAULT NULL,
  `firstname` varchar(255) DEFAULT NULL,
  `lastname` varchar(255) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `language` varchar(10) DEFAULT NULL,
  `contentLanguages` longtext DEFAULT NULL,
  `admin` tinyint(1) unsigned DEFAULT 0,
  `active` tinyint(1) unsigned DEFAULT 1,
  `permissions` text DEFAULT NULL,
  `roles` varchar(1000) DEFAULT NULL,
  `welcomescreen` tinyint(1) DEFAULT NULL,
  `closeWarning` tinyint(1) DEFAULT NULL,
  `memorizeTabs` tinyint(1) DEFAULT NULL,
  `allowDirtyClose` tinyint(1) unsigned DEFAULT 1,
  `docTypes` varchar(255) DEFAULT NULL,
  `classes` text DEFAULT NULL,
  `twoFactorAuthentication` varchar(255) DEFAULT NULL,
  `activePerspective` varchar(255) DEFAULT NULL,
  `perspectives` longtext DEFAULT NULL,
  `websiteTranslationLanguagesEdit` longtext DEFAULT NULL,
  `websiteTranslationLanguagesView` longtext DEFAULT NULL,
  `lastLogin` int(11) unsigned DEFAULT NULL,
  `keyBindings` text DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `type_name` (`type`,`name`),
  KEY `parentId` (`parentId`),
  KEY `name` (`name`),
  KEY `password` (`password`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

TRUNCATE `users`;
INSERT INTO `users` (`id`, `parentId`, `type`, `name`, `password`, `firstname`, `lastname`, `email`, `language`, `contentLanguages`, `admin`, `active`, `permissions`, `roles`, `welcomescreen`, `closeWarning`, `memorizeTabs`, `allowDirtyClose`, `docTypes`, `classes`, `twoFactorAuthentication`, `activePerspective`, `perspectives`, `websiteTranslationLanguagesEdit`, `websiteTranslationLanguagesView`, `lastLogin`, `keyBindings`) VALUES
(0,	0,	'user',	'system',	NULL,	NULL,	NULL,	NULL,	NULL,	NULL,	1,	1,	NULL,	NULL,	NULL,	NULL,	NULL,	1,	NULL,	NULL,	NULL,	NULL,	NULL,	NULL,	NULL,	NULL,	NULL),
(2,	0,	'user',	'admin',	'$2y$10$I1nT0VD1PMOn4e0567aHV.pi1hqPD.vjMtOx.TWbKGlyhZ.6kg.oa',	NULL,	NULL,	NULL,	'en',	NULL,	1,	1,	'',	'',	0,	1,	1,	0,	'',	'',	'null',	NULL,	'',	'',	'',	1644339806,	NULL);

DROP TABLE IF EXISTS `users_permission_definitions`;
CREATE TABLE `users_permission_definitions` (
  `key` varchar(50) NOT NULL DEFAULT '',
  `category` varchar(50) NOT NULL DEFAULT '',
  PRIMARY KEY (`key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

TRUNCATE `users_permission_definitions`;
INSERT INTO `users_permission_definitions` (`key`, `category`) VALUES
('admin_translations',	''),
('application_logging',	''),
('assets',	''),
('asset_metadata',	''),
('classes',	''),
('clear_cache',	''),
('clear_fullpage_cache',	''),
('clear_temp_files',	''),
('dashboards',	''),
('documents',	''),
('document_types',	''),
('emails',	''),
('gdpr_data_extractor',	''),
('glossary',	''),
('http_errors',	''),
('notes_events',	''),
('notifications',	''),
('notifications_send',	''),
('objects',	''),
('plugins',	''),
('predefined_properties',	''),
('recyclebin',	''),
('redirects',	''),
('reports',	''),
('reports_config',	''),
('robots.txt',	''),
('routes',	''),
('seemode',	''),
('seo_document_editor',	''),
('share_configurations',	''),
('sites',	''),
('system_settings',	''),
('tags_assignment',	''),
('tags_configuration',	''),
('tags_search',	''),
('targeting',	''),
('thumbnails',	''),
('translations',	''),
('users',	''),
('web2print_settings',	''),
('website_settings',	''),
('workflow_details',	'');

DROP TABLE IF EXISTS `users_workspaces_asset`;
CREATE TABLE `users_workspaces_asset` (
  `cid` int(11) unsigned NOT NULL DEFAULT 0,
  `cpath` varchar(765) CHARACTER SET utf8 COLLATE utf8_bin DEFAULT NULL,
  `userId` int(11) unsigned NOT NULL DEFAULT 0,
  `list` tinyint(1) DEFAULT 0,
  `view` tinyint(1) DEFAULT 0,
  `publish` tinyint(1) DEFAULT 0,
  `delete` tinyint(1) DEFAULT 0,
  `rename` tinyint(1) DEFAULT 0,
  `create` tinyint(1) DEFAULT 0,
  `settings` tinyint(1) DEFAULT 0,
  `versions` tinyint(1) DEFAULT 0,
  `properties` tinyint(1) DEFAULT 0,
  PRIMARY KEY (`cid`,`userId`),
  UNIQUE KEY `cpath_userId` (`cpath`,`userId`),
  KEY `userId` (`userId`),
  CONSTRAINT `fk_users_workspaces_asset_assets` FOREIGN KEY (`cid`) REFERENCES `assets` (`id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  CONSTRAINT `fk_users_workspaces_asset_users` FOREIGN KEY (`userId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC;

TRUNCATE `users_workspaces_asset`;

DROP TABLE IF EXISTS `users_workspaces_document`;
CREATE TABLE `users_workspaces_document` (
  `cid` int(11) unsigned NOT NULL DEFAULT 0,
  `cpath` varchar(765) CHARACTER SET utf8 COLLATE utf8_bin DEFAULT NULL,
  `userId` int(11) unsigned NOT NULL DEFAULT 0,
  `list` tinyint(1) unsigned DEFAULT 0,
  `view` tinyint(1) unsigned DEFAULT 0,
  `save` tinyint(1) unsigned DEFAULT 0,
  `publish` tinyint(1) unsigned DEFAULT 0,
  `unpublish` tinyint(1) unsigned DEFAULT 0,
  `delete` tinyint(1) unsigned DEFAULT 0,
  `rename` tinyint(1) unsigned DEFAULT 0,
  `create` tinyint(1) unsigned DEFAULT 0,
  `settings` tinyint(1) unsigned DEFAULT 0,
  `versions` tinyint(1) unsigned DEFAULT 0,
  `properties` tinyint(1) unsigned DEFAULT 0,
  PRIMARY KEY (`cid`,`userId`),
  UNIQUE KEY `cpath_userId` (`cpath`,`userId`),
  KEY `userId` (`userId`),
  CONSTRAINT `fk_users_workspaces_document_documents` FOREIGN KEY (`cid`) REFERENCES `documents` (`id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  CONSTRAINT `fk_users_workspaces_document_users` FOREIGN KEY (`userId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC;

TRUNCATE `users_workspaces_document`;

DROP TABLE IF EXISTS `users_workspaces_object`;
CREATE TABLE `users_workspaces_object` (
  `cid` int(11) unsigned NOT NULL DEFAULT 0,
  `cpath` varchar(765) CHARACTER SET utf8 COLLATE utf8_bin DEFAULT NULL,
  `userId` int(11) unsigned NOT NULL DEFAULT 0,
  `list` tinyint(1) unsigned DEFAULT 0,
  `view` tinyint(1) unsigned DEFAULT 0,
  `save` tinyint(1) unsigned DEFAULT 0,
  `publish` tinyint(1) unsigned DEFAULT 0,
  `unpublish` tinyint(1) unsigned DEFAULT 0,
  `delete` tinyint(1) unsigned DEFAULT 0,
  `rename` tinyint(1) unsigned DEFAULT 0,
  `create` tinyint(1) unsigned DEFAULT 0,
  `settings` tinyint(1) unsigned DEFAULT 0,
  `versions` tinyint(1) unsigned DEFAULT 0,
  `properties` tinyint(1) unsigned DEFAULT 0,
  `lEdit` text DEFAULT NULL,
  `lView` text DEFAULT NULL,
  `layouts` text DEFAULT NULL,
  PRIMARY KEY (`cid`,`userId`),
  UNIQUE KEY `cpath_userId` (`cpath`,`userId`),
  KEY `userId` (`userId`),
  CONSTRAINT `fk_users_workspaces_object_objects` FOREIGN KEY (`cid`) REFERENCES `objects` (`o_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  CONSTRAINT `fk_users_workspaces_object_users` FOREIGN KEY (`userId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC;

TRUNCATE `users_workspaces_object`;

DROP TABLE IF EXISTS `uuids`;
CREATE TABLE `uuids` (
  `uuid` char(36) NOT NULL,
  `itemId` int(11) unsigned NOT NULL,
  `type` varchar(25) NOT NULL,
  `instanceIdentifier` varchar(50) NOT NULL,
  PRIMARY KEY (`uuid`,`itemId`,`type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

TRUNCATE `uuids`;

DROP TABLE IF EXISTS `versions`;
CREATE TABLE `versions` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `cid` int(11) unsigned DEFAULT NULL,
  `ctype` enum('document','asset','object') DEFAULT NULL,
  `userId` int(11) unsigned DEFAULT NULL,
  `note` text DEFAULT NULL,
  `stackTrace` text DEFAULT NULL,
  `date` int(11) unsigned DEFAULT NULL,
  `public` tinyint(1) unsigned NOT NULL DEFAULT 0,
  `serialized` tinyint(1) unsigned DEFAULT 0,
  `versionCount` int(10) unsigned NOT NULL DEFAULT 0,
  `binaryFileHash` varchar(128) CHARACTER SET ascii DEFAULT NULL,
  `binaryFileId` bigint(20) unsigned DEFAULT NULL,
  `autoSave` tinyint(4) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `cid` (`cid`),
  KEY `ctype_cid` (`ctype`,`cid`),
  KEY `date` (`date`),
  KEY `binaryFileHash` (`binaryFileHash`),
  KEY `autoSave` (`autoSave`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

TRUNCATE `versions`;

DROP TABLE IF EXISTS `webdav_locks`;
CREATE TABLE `webdav_locks` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `owner` varchar(100) DEFAULT NULL,
  `timeout` int(10) unsigned DEFAULT NULL,
  `created` int(11) DEFAULT NULL,
  `token` varbinary(100) DEFAULT NULL,
  `scope` tinyint(4) DEFAULT NULL,
  `depth` tinyint(4) DEFAULT NULL,
  `uri` varbinary(1000) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `token` (`token`),
  KEY `uri` (`uri`(100))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

TRUNCATE `webdav_locks`;

DROP TABLE IF EXISTS `website_settings`;
CREATE TABLE `website_settings` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(190) NOT NULL DEFAULT '',
  `type` enum('text','document','asset','object','bool') DEFAULT NULL,
  `data` text DEFAULT NULL,
  `language` varchar(15) NOT NULL DEFAULT '',
  `siteId` int(11) unsigned DEFAULT NULL,
  `creationDate` int(11) unsigned DEFAULT 0,
  `modificationDate` int(11) unsigned DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `name` (`name`),
  KEY `siteId` (`siteId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

TRUNCATE `website_settings`;

-- 2022-02-08 17:10:03
