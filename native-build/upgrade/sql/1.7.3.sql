CREATE TABLE t_service_registry_info (
    f_service_name VARCHAR(30) NOT NULL,
    f_url_name VARCHAR(30) NOT NULL,
    f_url VARCHAR(100) NOT NULL,
    f_method VARCHAR(10) NOT NULL,
    f_parameters LONGTEXT,

    PRIMARY KEY (f_service_name, f_url_name)
);

ALTER TABLE t_storage_table_meta DROP INDEX storagetablemetamodel_f_engine;
ALTER TABLE t_storage_table_meta DROP INDEX storagetablemetamodel_f_store_type;

ALTER TABLE t_session_record DROP INDEX sessionrecord_f_engine_session_id;
ALTER TABLE t_session_record DROP INDEX sessionrecord_f_manager_session_id;
