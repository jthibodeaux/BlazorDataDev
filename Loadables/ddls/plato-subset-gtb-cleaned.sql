-- dbo.extracted_sql_queries definition

-- Drop table

-- DROP TABLE dbo.extracted_sql_queries;

CREATE TABLE dbo.extracted_sql_queries (
	id text NOT NULL,
	parameters text NULL,
	updated_by varchar(200) NOT NULL,
	updated_at timestamp NOT NULL,
	log_description text NOT NULL,
	sql_text text NOT NULL,
	dbname text NOT NULL,
	CONSTRAINT extracted_sql_queries_pkey PRIMARY KEY (id)
);


-- dbo.pipeline_configurations definition

-- Drop table

-- DROP TABLE dbo.pipeline_configurations;

CREATE TABLE dbo.pipeline_configurations (
	id uuid DEFAULT gen_random_uuid() NOT NULL,
	row_version int8 DEFAULT 1 NULL,
	created_date timestamptz NULL,
	modified_date timestamptz NULL,
	is_active bool DEFAULT true NOT NULL,
	is_deleted bool DEFAULT false NOT NULL,
	created_by text NULL,
	modified_by text NULL,
	tenant_id uuid NULL,
	configuration_json text NOT NULL,
	change_reason varchar(500) NULL,
	version_number int4 DEFAULT 1 NOT NULL,
	config_hash varchar(64) NULL
);


-- dbo.tc_capacity_configurations definition

-- Drop table

-- DROP TABLE dbo.tc_capacity_configurations;

CREATE TABLE dbo.tc_capacity_configurations (
	id uuid NOT NULL,
	seasonal_factor_weight float8 DEFAULT 30 NOT NULL,
	system_health_weight float8 DEFAULT 30 NOT NULL,
	outage_impact_weight float8 DEFAULT 20 NOT NULL,
	market_opportunities_weight float8 DEFAULT 10 NOT NULL,
	consultation_weight float8 DEFAULT 10 NOT NULL,
	no_risk_min_score float8 DEFAULT 0 NOT NULL,
	no_risk_max_score float8 DEFAULT 2.5 NOT NULL,
	low_risk_min_score float8 DEFAULT 2.51 NOT NULL,
	low_risk_max_score float8 DEFAULT 5.0 NOT NULL,
	moderate_risk_min_score float8 DEFAULT 5.01 NOT NULL,
	moderate_risk_max_score float8 DEFAULT 7.5 NOT NULL,
	high_risk_min_score float8 DEFAULT 7.51 NOT NULL,
	high_risk_max_score float8 DEFAULT 10.0 NOT NULL,
	no_risk_capacity int4 DEFAULT 0 NOT NULL,
	low_risk_capacity int4 DEFAULT 10 NOT NULL,
	moderate_risk_capacity int4 DEFAULT 25 NOT NULL,
	high_risk_capacity int4 DEFAULT 50 NOT NULL,
	gas_control_weight float8 DEFAULT 40 NOT NULL,
	marketing_weight float8 DEFAULT 15 NOT NULL,
	field_operations_weight float8 DEFAULT 15 NOT NULL,
	reliability_team_weight float8 DEFAULT 15 NOT NULL,
	ghg_team_weight float8 DEFAULT 10 NOT NULL,
	reputation_team_weight float8 DEFAULT 5 NOT NULL,
	distribution_list varchar(1000) NULL,
	emergency_distribution_list varchar(1000) NULL,
	email_delivery_time time DEFAULT '06:00:00'::time without time zone NOT NULL,
	data_collection_time time DEFAULT '04:00:00'::time without time zone NOT NULL,
	fallback_rankings_json jsonb NULL,
	created_date timestamp DEFAULT now() NOT NULL,
	modified_date timestamp DEFAULT now() NOT NULL,
	is_active bool DEFAULT true NOT NULL,
	is_deleted bool DEFAULT false NOT NULL,
	created_by varchar(256) NULL,
	modified_by varchar(256) NULL,
	tenant_id uuid NULL,
	row_version bytea NULL,
	scoring_lookup_tables_json jsonb DEFAULT '{}'::jsonb NOT NULL,
	oba_long_threshold float8 DEFAULT 100000 NOT NULL,
	oba_short_threshold float8 DEFAULT '-100000'::integer NOT NULL,
	market_opportunity_high_demand_threshold float8 DEFAULT 25 NOT NULL,
	market_opportunity_normal_threshold float8 DEFAULT 10 NOT NULL,
	pull_cap_high_relative_threshold float8 DEFAULT 1.3 NOT NULL,
	pull_cap_medium_relative_threshold float8 DEFAULT 1.1 NOT NULL,
	pull_cap_low_relative_threshold float8 DEFAULT 0.9 NOT NULL,
	pull_cap_high_utilization_threshold float8 DEFAULT 0.9 NOT NULL,
	pull_cap_medium_utilization_threshold float8 DEFAULT 0.7 NOT NULL,
	pull_cap_low_utilization_threshold float8 DEFAULT 0.5 NOT NULL,
	downstream_very_high_threshold float8 DEFAULT 4000 NOT NULL,
	downstream_high_threshold float8 DEFAULT 3000 NOT NULL,
	downstream_medium_threshold float8 DEFAULT 2000 NOT NULL,
	downstream_low_threshold float8 DEFAULT 1000 NOT NULL,
	long_term_very_high_threshold float8 DEFAULT 1.3 NOT NULL,
	long_term_high_threshold float8 DEFAULT 1.1 NOT NULL,
	long_term_medium_threshold float8 DEFAULT 0.9 NOT NULL,
	long_term_low_threshold float8 DEFAULT 0.7 NOT NULL,
	long_term_very_low_threshold float8 DEFAULT 0.5 NOT NULL,
	imbalances_very_low_threshold float8 DEFAULT 10 NOT NULL,
	imbalances_low_threshold float8 DEFAULT 30 NOT NULL,
	imbalances_medium_threshold float8 DEFAULT 50 NOT NULL,
	pull_cap_weight float8 DEFAULT 0.2 NOT NULL,
	downstream_movement_weight float8 DEFAULT 0.4 NOT NULL,
	long_term_impact_weight float8 DEFAULT 0.3 NOT NULL,
	oba_position_weight float8 DEFAULT 0.1 NOT NULL,
	morning_analysis_time time DEFAULT '09:00:00'::time without time zone NULL,
	afternoon_analysis_time time DEFAULT '14:00:00'::time without time zone NULL,
	send_morning_emails bool DEFAULT true NULL,
	send_afternoon_emails bool DEFAULT true NULL,
	max_daily_imbalance_mdth float8 DEFAULT 100 NULL,
	min_temperature_fahrenheit float8 DEFAULT '-5'::integer NULL,
	max_cushion_usage_percent float8 DEFAULT 90 NULL,
	max_recent_constraint_hours int4 DEFAULT 3 NULL,
	enable_cold_weather_override bool DEFAULT true NULL,
	enable_high_imbalance_override bool DEFAULT true NULL,
	enable_cushion_usage_override bool DEFAULT true NULL,
	enable_constraint_override bool DEFAULT true NULL,
	enable_system_health_veto bool DEFAULT true NULL,
	system_health_veto_threshold float8 DEFAULT 3.0 NULL,
	system_health_veto_max_score float8 DEFAULT 3.0 NULL,
	enable_outage_veto bool DEFAULT true NULL,
	outage_veto_threshold float8 DEFAULT 3.0 NULL,
	outage_veto_max_score float8 DEFAULT 4.0 NULL,
	enable_capacity_analysis_veto bool DEFAULT true NULL,
	capacity_analysis_veto_threshold float8 DEFAULT 2.0 NULL,
	capacity_analysis_veto_max_score float8 DEFAULT 2.0 NULL,
	pal_recommendation_email_time time DEFAULT '06:00:00'::time without time zone NULL,
	pal_recommendation_email_recipients varchar(2000) DEFAULT ''::character varying NULL,
	combination_rules_json text NULL,
	enable_combinations bool DEFAULT false NULL,
	seasonal_configuration_json text NULL,
	enable_seasonality bool DEFAULT false NULL,
	monthly_max_daily_unpark_json text NULL,
	pipeline_id varchar(10) NULL,
	--CONSTRAINT tc_capacity_configurations_pkey PRIMARY KEY (id)
);
CREATE INDEX idx_tc_capacity_configurations_is_active ON dbo.tc_capacity_configurations USING btree (is_active) WHERE (is_active = true);
CREATE INDEX idx_tc_capacity_configurations_pipeline_active ON dbo.tc_capacity_configurations USING btree (pipeline_id, is_active) WHERE (is_active = true);
CREATE INDEX idx_tc_capacity_configurations_pipeline_id ON dbo.tc_capacity_configurations USING btree (pipeline_id);


-- dbo.tc_capacity_decisions definition

-- Drop table

-- DROP TABLE dbo.tc_capacity_decisions;

CREATE TABLE dbo.tc_capacity_decisions (
	id uuid NOT NULL,
	capacity_amount int4 NOT NULL,
	decision_date date NOT NULL,
	risk_level varchar(100) NOT NULL,
	final_score float8 NOT NULL,
	seasonal_factor_score float8 NOT NULL,
	system_health_score float8 NOT NULL,
	outage_score float8 NOT NULL,
	opportunity_score float8 NOT NULL,
	consultation_score float8 NOT NULL,
	justification_summary text NULL,
	primary_factors text NULL,
	persona_insights text NULL,
	risk_assessment text NULL,
	safety_assessment text NULL,
	is_safety_override bool DEFAULT false NOT NULL,
	email_sent bool DEFAULT false NOT NULL,
	email_sent_time timestamp NULL,
	pipeline_state_json jsonb NULL,
	persona_rankings_json jsonb NULL,
	created_date timestamp DEFAULT now() NOT NULL,
	modified_date timestamp DEFAULT now() NOT NULL,
	is_active bool DEFAULT true NOT NULL,
	is_deleted bool DEFAULT false NOT NULL,
	created_by varchar(256) NULL,
	modified_by varchar(256) NULL,
	tenant_id uuid NULL,
	row_version bytea NULL,
	capacity_analysis_score float8 DEFAULT 0 NOT NULL,
	history_constraint_score float8 DEFAULT 0 NOT NULL,
	forecast_constraint_score float8 DEFAULT 0 NOT NULL,
	month_score float8 DEFAULT 0 NOT NULL,
	day_of_week_score float8 DEFAULT 0 NOT NULL,
	time_period_score float8 DEFAULT 0 NOT NULL,
	day_type_score float8 DEFAULT 0 NOT NULL,
	outage_duration_score float8 DEFAULT 0 NOT NULL,
	outage_impact_score float8 DEFAULT 0 NOT NULL,
	outage_cycle_score float8 DEFAULT 0 NOT NULL,
	outage_impact_group_score float8 DEFAULT 0 NOT NULL,
	linepack_score float8 DEFAULT 0 NOT NULL,
	throughput_score float8 DEFAULT 0 NOT NULL,
	imbalances_score float8 DEFAULT 0 NOT NULL,
	equipment_score float8 DEFAULT 0 NOT NULL,
	pull_cap_score float8 DEFAULT 0 NOT NULL,
	downstream_movement_score float8 DEFAULT 0 NOT NULL,
	long_term_impact_score float8 DEFAULT 0 NOT NULL,
	metadata text DEFAULT ''::text NULL,
	pre_veto_score numeric(5, 2) NULL,
	applied_vetoes_json text NULL,
	safety_issues_json text NULL,
	validation_errors_json text NULL,
	processing_time_ms int8 NULL,
	calculation_method varchar(50) NULL,
	is_validated bool DEFAULT false NULL,
	email_recipients text NULL,
	email_subject varchar(200) NULL,
	safety_override_reason text NULL,
	configuration_snapshot_json jsonb NULL,
	extended_properties_json jsonb NULL,
	pipeline_id varchar(10) NULL,
	CONSTRAINT tc_capacity_decisions_pkey PRIMARY KEY (id)
);
CREATE INDEX idx_tc_capacity_decision_pipeline_date ON dbo.tc_capacity_decisions USING btree (pipeline_id, decision_date);
CREATE INDEX idx_tc_capacity_decisions_decision_date ON dbo.tc_capacity_decisions USING btree (decision_date);
CREATE INDEX idx_tc_capacity_decisions_email_sent ON dbo.tc_capacity_decisions USING btree (email_sent);
CREATE INDEX idx_tc_capacity_decisions_is_safety_override ON dbo.tc_capacity_decisions USING btree (is_safety_override);
CREATE INDEX idx_tc_capacity_decisions_not_deleted ON dbo.tc_capacity_decisions USING btree (is_deleted) WHERE (is_deleted = false);
CREATE INDEX idx_tc_capacity_decisions_pipeline_id ON dbo.tc_capacity_decisions USING btree (pipeline_id);


-- dbo.tc_compressordata definition

-- Drop table

-- DROP TABLE dbo.tc_compressordata;

CREATE TABLE dbo.tc_compressordata (
	ap_compressor varchar(50) NOT NULL,
	"timestamp" timestamp(6) NOT NULL,
	ap_compressorunit_gtn varchar(50) NOT NULL,
	bhp float8 NULL,
	enginestatus varchar(50) NULL,
	pipeline_id varchar(20) NULL,
	suctionpressure float8 NULL,
	gasday timestamptz NULL,
	dischargepressure float8 NULL,
	suctiontemperature float8 NULL,
	dischargetemperature float8 NULL,
	fuel_gas_flow float8 NULL,
	source_system varchar(50) NULL,
	atmospherictemperature float8 NULL,
	totalhorsepower float8 NULL,
	totalfuel float8 NULL
);
CREATE INDEX idx_tc_compressordata_gasday ON dbo.tc_compressordata USING btree (gasday) WHERE (gasday IS NOT NULL);
CREATE INDEX idx_tc_compressordata_pipeline_id ON dbo.tc_compressordata USING btree (pipeline_id);
CREATE INDEX idx_tc_compressordata_source_system ON dbo.tc_compressordata USING btree (source_system) WHERE (source_system IS NOT NULL);


-- dbo.tc_compressorplan definition

-- Drop table

-- DROP TABLE dbo.tc_compressorplan;

CREATE TABLE dbo.tc_compressorplan (
	"timestamp" timestamp(6) NOT NULL,
	ap_compressor varchar(50) NOT NULL,
	atmospherictemperature float8 NULL,
	dischargepressure float8 NULL,
	dischargetemperature float8 NULL,
	suctionpressure float8 NULL,
	suctiontemperature float8 NULL,
	totalfuel float8 NULL,
	totalhorsepower float8 NULL,
	id serial4 NOT NULL,
	pipeline_id text DEFAULT 'nbpl'::text NULL
);
CREATE INDEX idx_tc_compressorplan_pipeline_id ON dbo.tc_compressorplan USING btree (pipeline_id);


-- dbo.tc_dailymeterreadings definition

-- Drop table

-- DROP TABLE dbo.tc_dailymeterreadings;

CREATE TABLE dbo.tc_dailymeterreadings (
	"timestamp" timestamp(6) NOT NULL,
	ap_meter int4 NOT NULL,
	btu float8 NULL,
	flow_rate_mmcfd float8 NULL,
	pressure float8 NULL,
	id int4 NOT NULL,
	current_daytotal_mmcf float8 NULL,
	minop int4 NULL,
	pipeline_id varchar(10) NULL,
	meter_name varchar(255) NULL,
	maxop int4 NULL,
	location_name varchar(255) NULL,
	meter_type varchar(50) NULL
);
CREATE INDEX idx_tc_dailymeterreadings_pipeline_id ON dbo.tc_dailymeterreadings USING btree (pipeline_id);


-- dbo.tc_meterlocations definition

-- Drop table

-- DROP TABLE dbo.tc_meterlocations;

CREATE TABLE dbo.tc_meterlocations (
	ap_meter int4 NULL,
	"location" text NULL,
	pipeline_id varchar(10) NULL
);


-- dbo.tc_persona_configs definition

-- Drop table

-- DROP TABLE dbo.tc_persona_configs;

CREATE TABLE dbo.tc_persona_configs (
	id uuid NOT NULL,
	persona_type int4 NOT NULL,
	description text NULL,
	context_template text NOT NULL,
	priority_goals text NOT NULL,
	default_rankings text NOT NULL,
	is_active bool DEFAULT true NOT NULL,
	is_deleted bool DEFAULT false NOT NULL,
	created_date timestamptz NOT NULL,
	modified_date timestamptz NOT NULL,
	created_by varchar(100) NOT NULL,
	modified_by varchar(100) NOT NULL,
	tenant_id uuid NOT NULL,
	display_name varchar(100) NULL,
	kpi_rules jsonb DEFAULT '[]'::jsonb NULL,
	pipeline_id varchar(10) NULL,
	CONSTRAINT tc_persona_configs_pkey PRIMARY KEY (id)
);
CREATE INDEX idx_tc_persona_configs_pipeline_id ON dbo.tc_persona_configs USING btree (pipeline_id);
CREATE INDEX idx_tc_persona_configs_type ON dbo.tc_persona_configs USING btree (persona_type);
-- dbo.tc_persona_configs_history definition
-- Drop table
-- DROP TABLE dbo.tc_persona_configs_history;
CREATE TABLE dbo.tc_persona_configs_history (
	id uuid NOT NULL,
	configs_id uuid NOT NULL,
	persona_type int4 NOT NULL,
	description text NULL,
	context_template text NOT NULL,
	priority_goals text NOT NULL,
	default_rankings text NOT NULL,
	is_active bool DEFAULT true NOT NULL,
	is_deleted bool DEFAULT false NOT NULL,
	created_date timestamptz NOT NULL,
	modified_date timestamptz NOT NULL,
	created_by varchar(100) NOT NULL,
	modified_by varchar(100) NOT NULL,
	tenant_id uuid NOT NULL,
	display_name varchar(100) NULL,
	kpi_rules jsonb DEFAULT '[]'::jsonb NULL,
	change_type text NOT NULL,
	pipeline_id varchar(10) NULL,
	CONSTRAINT tc_persona_configs_history_pkey PRIMARY KEY (id)
);
CREATE INDEX idx_tc_persona_configs_history_type ON dbo.tc_persona_configs_history USING btree (persona_type);


-- dbo.tc_pipeline_definitions definition

-- Drop table

-- DROP TABLE dbo.tc_pipeline_definitions;

CREATE TABLE dbo.tc_pipeline_definitions (
	pipeline_id varchar(20) NOT NULL,
	pipeline_name varchar(200) NOT NULL,
	description text NULL,
	is_default bool DEFAULT false NULL,
	is_active bool DEFAULT true NULL,
	maop float8 DEFAULT 1400.0 NULL,
	minop float8 DEFAULT 800.0 NULL,
	maop_cushion float8 DEFAULT 50.0 NULL,
	minop_cushion float8 DEFAULT 50.0 NULL,
	minimum_constraint_hours int4 DEFAULT 5 NULL,
	peak_period_start time DEFAULT '06:00:00'::time without time zone NULL,
	peak_period_end time DEFAULT '22:00:00'::time without time zone NULL,
	consider_only_peak_hours bool DEFAULT true NULL,
	database_schema varchar(100) NULL,
	station_table varchar(500) NULL,
	stations varchar(100) NULL,
	segment_table varchar(100) NULL,
	meter_table varchar(100) NULL,
	ml_table varchar(100) NULL,
	pipeline_aor_id int4 NULL,
	supports_linepack_optimization bool DEFAULT false NULL,
	supports_storage_optimization bool DEFAULT false NULL,
	supports_interconnection_optimization bool DEFAULT false NULL,
	supports_cross_border_operations bool DEFAULT false NULL,
	supports_park_operations bool DEFAULT false NULL,
	supports_loan_operations bool DEFAULT false NULL,
	created_at timestamp DEFAULT CURRENT_TIMESTAMP NULL,
	updated_at timestamp DEFAULT CURRENT_TIMESTAMP NULL,
	external_connection_string_key varchar(100) NULL,
	CONSTRAINT tc_pipeline_definitions_pkey PRIMARY KEY (pipeline_id)
);
CREATE INDEX idx_pipeline_definitions_connection_key ON dbo.tc_pipeline_definitions USING btree (external_connection_string_key) WHERE (external_connection_string_key IS NOT NULL);


-- dbo.tc_pipemeasurements definition

-- Drop table

-- DROP TABLE dbo.tc_pipemeasurements;

CREATE TABLE dbo.tc_pipemeasurements (
	id serial4 NOT NULL,
	pipeline_id varchar(10) NULL,
	flowdate date NOT NULL,
	operationalcapacity int8 NULL,
	totalscheduledquantity int8 NULL,
	created_date timestamp DEFAULT now() NULL,
	assetabrv varchar(50) NULL,
-- dbo.tc_pipemeasurements definition
-- Drop table
-- DROP TABLE dbo.tc_pipemeasurements;
CREATE TABLE dbo.tc_pipemeasurements (
	assetnbr int4 NOT NULL,
	assetabrv text NOT NULL,
	flowdate date NOT NULL,
	cycle_name text NOT NULL,
	cycleseq int4 NOT NULL,
	loc_id int4 NOT NULL,
	loc_name text NOT NULL,
	loc_sub_type text NOT NULL,
	loc_qty_ind text NOT NULL,
	location_purpose_desc text NOT NULL,
	operational_capacity int4 NOT NULL,
	scheduled_quantity int4 NOT NULL,
	posting_date text NOT NULL,
	pipeline_id varchar(10) DEFAULT 'nbpl'::character varying NOT NULL
);
CREATE INDEX idx_tc_pipemeasurements_pipeline_id ON dbo.tc_pipemeasurements USING btree (pipeline_id);


-- dbo.tc_recommendations definition

-- Drop table

-- DROP TABLE dbo.tc_recommendations;

CREATE TABLE dbo.tc_recommendations (
	id uuid NOT NULL,
	analysis_datetime timestamp NOT NULL,
	recommendation_type varchar(50) NOT NULL,
	serialized_data jsonb NOT NULL,
	created_date timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	created_by varchar(100) DEFAULT 'System'::character varying NOT NULL,
	tenant_id uuid DEFAULT '11111111-1111-1111-1111-111111111111'::uuid NOT NULL,
	pipeline_id varchar(10) NULL,
	CONSTRAINT tc_recommendations_pkey PRIMARY KEY (id)
);
CREATE INDEX idx_tc_recommendations_datetime ON dbo.tc_recommendations USING btree (analysis_datetime);
CREATE UNIQUE INDEX idx_tc_recommendations_unique ON dbo.tc_recommendations USING btree (analysis_datetime, recommendation_type, pipeline_id);
-- dbo.tchistoricaloutages definition
-- Drop table
-- DROP TABLE dbo.tchistoricaloutages;
CREATE TABLE dbo.tchistoricaloutages (
	sap_floc text NULL,
	segment_names text NULL,
	"location" text NULL,
	pipeline_aor_id int4 NULL,
	object_type text NULL,
	impact text NULL,
	field_op_area text NULL,
	id int8 NULL,
	sap_company_code int4 NULL,
	floc text NULL,
	start_date timestamp NULL,
	end_date timestamp NULL,
	notification_date timestamp NULL,
	coding_code text NULL,
	description text NULL,
	createdts timestamp NULL,
	user_status text NULL,
	notification_num int8 NULL,
	import_time timestamp NULL,
	longdesc text NULL,
	flocid text NULL,
	pipeline_id varchar(10) NULL
);
CREATE INDEX idx_tchistoricaloutages_dates ON dbo.tchistoricaloutages USING btree (start_date, end_date);
CREATE INDEX idx_tchistoricaloutages_id ON dbo.tchistoricaloutages USING btree (id);
CREATE INDEX idx_tchistoricaloutages_pipeline ON dbo.tchistoricaloutages USING btree (pipeline_aor_id);
CREATE INDEX idx_tchistoricaloutages_sap_floc ON dbo.tchistoricaloutages USING btree (sap_floc);
CREATE INDEX idx_tchistoricaloutages_status ON dbo.tchistoricaloutages USING btree (user_status);


-- dbo.tc_constraint_paths definition

-- Drop table

-- DROP TABLE dbo.tc_constraint_paths;

CREATE TABLE dbo.tc_constraint_paths (
	id serial4 NOT NULL,
	pipeline_id varchar(20) NOT NULL,
	start_station varchar(100) NOT NULL,
	end_station varchar(100) NOT NULL,
	priority int4 DEFAULT 1 NULL,
	frequency_count int4 DEFAULT 0 NULL,
	last_observed timestamp NULL,
	notes text NULL,
	is_active bool DEFAULT true NULL,
	created_at timestamp DEFAULT now() NULL,
	CONSTRAINT tc_constraint_paths_pipeline_id_start_station_end_station_key UNIQUE (pipeline_id, start_station, end_station),
	CONSTRAINT tc_constraint_paths_pkey PRIMARY KEY (id),
	CONSTRAINT tc_constraint_paths_pipeline_id_fkey FOREIGN KEY (pipeline_id) REFERENCES dbo.tc_pipeline_definitions(pipeline_id)
);
-- dbo.tc_meters definition
-- Drop table
-- DROP TABLE dbo.tc_meters;
CREATE TABLE dbo.tc_meters (
	id serial4 NOT NULL,
	pipeline_id varchar(20) NOT NULL,
	meter_id int4 NOT NULL,
	meter_name varchar(100) NOT NULL,
	"location" varchar(200) NULL,
	meter_type varchar(50) NULL,
	flow_direction varchar(20) NULL,
	is_active bool DEFAULT true NULL,
	created_at timestamp DEFAULT CURRENT_TIMESTAMP NULL,
	updated_at timestamp DEFAULT CURRENT_TIMESTAMP NULL,
	station_name varchar(100) NULL,
	is_core_meter bool DEFAULT false NULL,
	CONSTRAINT tc_meters_pkey PRIMARY KEY (id),
	CONSTRAINT tc_meters_pipeline_id_fkey FOREIGN KEY (pipeline_id) REFERENCES dbo.tc_pipeline_definitions(pipeline_id)
);
CREATE INDEX idx_tc_meters_is_core ON dbo.tc_meters USING btree (pipeline_id, is_core_meter) WHERE (is_core_meter = true);
CREATE INDEX idx_tc_meters_pipeline_id ON dbo.tc_meters USING btree (pipeline_id);
CREATE UNIQUE INDEX idx_tc_meters_unique ON dbo.tc_meters USING btree (pipeline_id, meter_id);


-- dbo.tc_persona_memories definition

-- Drop table

-- DROP TABLE dbo.tc_persona_memories;

CREATE TABLE dbo.tc_persona_memories (
	id uuid DEFAULT gen_random_uuid() NOT NULL,
	persona_config_id uuid NOT NULL,
	persona_type int4 NOT NULL,
	memory_date timestamp NOT NULL,
	"content" text NOT NULL,
	summary varchar(500) NOT NULL,
	embedding _float8 NOT NULL,
	"type" int4 NOT NULL,
	importance float4 DEFAULT 0.5 NOT NULL,
	capacity_decision_id uuid NULL,
	metadata jsonb NULL,
	is_active bool DEFAULT true NOT NULL,
	is_deleted bool DEFAULT false NOT NULL,
	created_date timestamp DEFAULT now() NOT NULL,
	modified_date timestamp DEFAULT now() NOT NULL,
	created_by varchar(256) NULL,
	modified_by varchar(256) NULL,
	tenant_id uuid NULL,
	row_version bytea NULL,
	pipeline_id varchar(10) NULL,
	CONSTRAINT tc_persona_memories_pkey PRIMARY KEY (id),
	CONSTRAINT fk_tc_persona_memories_capacity_decision FOREIGN KEY (capacity_decision_id) REFERENCES dbo.tc_capacity_decisions(id) ON DELETE SET NULL,
	CONSTRAINT fk_tc_persona_memories_persona_config FOREIGN KEY (persona_config_id) REFERENCES dbo.tc_persona_configs(id) ON DELETE CASCADE
);
CREATE INDEX idx_tc_persona_memories_is_deleted ON dbo.tc_persona_memories USING btree (is_deleted);
CREATE INDEX idx_tc_persona_memories_memory_date ON dbo.tc_persona_memories USING btree (memory_date);
CREATE INDEX idx_tc_persona_memories_persona_type ON dbo.tc_persona_memories USING btree (persona_type);
CREATE INDEX idx_tc_persona_memories_pipeline_id ON dbo.tc_persona_memories USING btree (pipeline_id);
CREATE INDEX idx_tc_persona_memories_type ON dbo.tc_persona_memories USING btree (type);
CREATE INDEX idx_tc_persona_memory_pipeline_date ON dbo.tc_persona_memories USING btree (pipeline_id, memory_date);


-- dbo.tc_pipeline_capacity_config definition
-- Drop table
-- DROP TABLE dbo.tc_pipeline_capacity_config;
CREATE TABLE dbo.tc_pipeline_capacity_config (
	pipeline_id varchar(20) NOT NULL,
	maop_cushion float4 DEFAULT 5.0 NOT NULL,
	minop_cushion float4 DEFAULT 5.0 NOT NULL,
	maop float4 DEFAULT 911.0 NOT NULL,
	minop float4 DEFAULT 500.0 NOT NULL,
	minimum_constraint_hours int4 DEFAULT 5 NOT NULL,
	peak_period_start time DEFAULT '06:00:00'::time without time zone NOT NULL,
	peak_period_end time DEFAULT '22:00:00'::time without time zone NOT NULL,
	consider_only_peak_hours bool DEFAULT true NOT NULL,
	skip_zero_measurements bool DEFAULT true NOT NULL,
	downstream_only bool DEFAULT true NOT NULL,
	max_path_distance int4 DEFAULT 3 NOT NULL,
	capacity_utilization_threshold float4 DEFAULT 95.0 NOT NULL,
	show_capacity_utilization bool DEFAULT true NOT NULL,
	created_at timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	updated_at timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	CONSTRAINT tc_pipeline_capacity_config_pkey PRIMARY KEY (pipeline_id),
	CONSTRAINT fk_pipeline_capacity_config_pipeline FOREIGN KEY (pipeline_id) REFERENCES dbo.tc_pipeline_definitions(pipeline_id) ON DELETE CASCADE
);
CREATE INDEX idx_tc_pipeline_capacity_config_pipeline ON dbo.tc_pipeline_capacity_config USING btree (pipeline_id);

-- dbo.tc_pipeline_scoring_config definition

-- Drop table

-- DROP TABLE dbo.tc_pipeline_scoring_config;

CREATE TABLE dbo.tc_pipeline_scoring_config (
	pipeline_id varchar(20) NOT NULL,
	seasonal_factor_weight int4 DEFAULT 25 NULL,
	system_health_weight int4 DEFAULT 20 NULL,
	outage_impact_weight int4 DEFAULT 15 NULL,
	market_opportunities_weight int4 DEFAULT 25 NULL,
	consultation_weight int4 DEFAULT 15 NULL,
	no_risk_min float8 DEFAULT 0.0 NULL,
	no_risk_max float8 DEFAULT 2.5 NULL,
	no_risk_capacity float8 DEFAULT 150.0 NULL,
	low_risk_min float8 DEFAULT 2.5 NULL,
	low_risk_max float8 DEFAULT 5.0 NULL,
	low_risk_capacity float8 DEFAULT 100.0 NULL,
	moderate_risk_min float8 DEFAULT 5.0 NULL,
	moderate_risk_max float8 DEFAULT 7.5 NULL,
	moderate_risk_capacity float8 DEFAULT 50.0 NULL,
	high_risk_min float8 DEFAULT 7.5 NULL,
	high_risk_max float8 DEFAULT 10.0 NULL,
	high_risk_capacity float8 DEFAULT 0.0 NULL,
	oba_long_threshold int4 DEFAULT 50000 NULL,
	oba_short_threshold int4 DEFAULT '-50000'::integer NULL,
	market_opportunity_high_demand_threshold int4 DEFAULT 75 NULL,
	market_opportunity_normal_threshold int4 DEFAULT 50 NULL,
	pull_cap_high_relative_threshold float8 DEFAULT 0.8 NULL,
	pull_cap_low_relative_threshold float8 DEFAULT 0.3 NULL,
	created_at timestamp DEFAULT CURRENT_TIMESTAMP NULL,
	updated_at timestamp DEFAULT CURRENT_TIMESTAMP NULL,
	CONSTRAINT tc_pipeline_scoring_config_pkey PRIMARY KEY (pipeline_id),
	CONSTRAINT tc_pipeline_scoring_config_pipeline_id_fkey FOREIGN KEY (pipeline_id) REFERENCES dbo.tc_pipeline_definitions(pipeline_id)
);


-- dbo.tc_pipeline_scoring_lookups definition
-- Drop table
-- DROP TABLE dbo.tc_pipeline_scoring_lookups;
CREATE TABLE dbo.tc_pipeline_scoring_lookups (
	pipeline_id varchar(20) NOT NULL,
	month_scores jsonb NULL,
	day_of_week_scores jsonb NULL,
	day_type_scores jsonb NULL,
	history_constraint_scores jsonb NULL,
	forecast_constraint_scores jsonb NULL,
	outage_duration_scores jsonb NULL,
	outage_impact_scores jsonb NULL,
	outage_cycle_scores jsonb NULL,
	outage_impact_group_scores jsonb NULL,
	imbalance_scores jsonb NULL,
	pull_cap_adinom_scores jsonb NULL,
	downstream_movement_scores jsonb NULL,
	long_term_impact_scores jsonb NULL,
	monthly_max_daily_unpark jsonb NULL,
	created_at timestamp DEFAULT CURRENT_TIMESTAMP NULL,
	updated_at timestamp DEFAULT CURRENT_TIMESTAMP NULL,
	CONSTRAINT tc_pipeline_scoring_lookups_pkey PRIMARY KEY (pipeline_id),
	CONSTRAINT tc_pipeline_scoring_lookups_pipeline_id_fkey FOREIGN KEY (pipeline_id) REFERENCES dbo.tc_pipeline_definitions(pipeline_id)
);
-- dbo.tc_pipeline_segments definition

-- Drop table

-- DROP TABLE dbo.tc_pipeline_segments;

CREATE TABLE dbo.tc_pipeline_segments (
	id serial4 NOT NULL,
	pipeline_id varchar(20) NULL,
	segment_order_name varchar(100) NOT NULL,
	segment varchar(100) NOT NULL,
	segment_order int4 NOT NULL,
	start_station varchar(100) NULL,
	end_station varchar(100) NULL,
	maop float4 NULL,
	minop float4 NULL,
	milepost float4 NULL,
	pressure float4 NULL,
	flow_factor float4 NULL,
	volume float4 NULL,
	notes text NULL,
	is_active bool DEFAULT true NOT NULL,
	created_at timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	updated_at timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	CONSTRAINT tc_pipeline_segments_pkey PRIMARY KEY (id),
	CONSTRAINT uq_pipeline_segments_name UNIQUE (pipeline_id, segment_order_name),
	CONSTRAINT uq_pipeline_segments_order UNIQUE (pipeline_id, segment_order),
	CONSTRAINT fk_pipeline_segments_pipeline FOREIGN KEY (pipeline_id) REFERENCES dbo.tc_pipeline_definitions(pipeline_id) ON DELETE CASCADE
);
CREATE INDEX idx_pipeline_segments_active ON dbo.tc_pipeline_segments USING btree (pipeline_id, is_active) WHERE (is_active = true);
CREATE INDEX idx_pipeline_segments_end_station ON dbo.tc_pipeline_segments USING btree (pipeline_id, end_station);
CREATE INDEX idx_pipeline_segments_pipeline_id ON dbo.tc_pipeline_segments USING btree (pipeline_id);
CREATE INDEX idx_pipeline_segments_segment_order ON dbo.tc_pipeline_segments USING btree (pipeline_id, segment_order);
CREATE INDEX idx_pipeline_segments_start_station ON dbo.tc_pipeline_segments USING btree (pipeline_id, start_station);
CREATE INDEX idx_tc_pipeline_segments_end_station ON dbo.tc_pipeline_segments USING btree (pipeline_id, end_station);
CREATE UNIQUE INDEX idx_tc_pipeline_segments_pipeline_order_name ON dbo.tc_pipeline_segments USING btree (pipeline_id, segment_order_name);
CREATE INDEX idx_tc_pipeline_segments_start_station ON dbo.tc_pipeline_segments USING btree (pipeline_id, start_station);




-- dbo.tc_pipeline_stations definition

-- Drop table

-- DROP TABLE dbo.tc_pipeline_stations;

CREATE TABLE dbo.tc_pipeline_stations (
	id serial4 NOT NULL,
	pipeline_id varchar(20) NOT NULL,
	station_name varchar(100) NOT NULL,
	flow_order int4 NULL,
	station_type varchar(20) NOT NULL,
	maop float8 NULL,
	minop float8 NULL,
	maop_cushion float8 NULL,
	minop_cushion float8 NULL,
	is_active bool DEFAULT true NULL,
	created_at timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	created_by varchar(100) DEFAULT 'system'::character varying NULL,
	updated_at timestamp NULL,
	updated_by varchar(100) NULL,
	mile_post float8 NULL,
	station_role int4 DEFAULT 0 NOT NULL,
	rated_hp float8 NULL,
	is_booster bool NULL,
	meter_id int4 NULL,
	station_number varchar(50) NULL,
	distribution varchar(100) NULL,
	CONSTRAINT tc_pipeline_stations_pkey PRIMARY KEY (id),
	CONSTRAINT tc_pipeline_stations_pipeline_id_fkey FOREIGN KEY (pipeline_id) REFERENCES dbo.tc_pipeline_definitions(pipeline_id)
);
CREATE INDEX idx_pipeline_stations_type_active ON dbo.tc_pipeline_stations USING btree (pipeline_id, station_type, is_active);
CREATE INDEX idx_tc_pipeline_stations_flow_order ON dbo.tc_pipeline_stations USING btree (pipeline_id, flow_order);
CREATE INDEX idx_tc_pipeline_stations_meter_id ON dbo.tc_pipeline_stations USING btree (meter_id) WHERE (meter_id IS NOT NULL);
CREATE INDEX idx_tc_pipeline_stations_pipeline_id ON dbo.tc_pipeline_stations USING btree (pipeline_id);
CREATE UNIQUE INDEX idx_tc_pipeline_stations_pipeline_name ON dbo.tc_pipeline_stations USING btree (pipeline_id, station_name);
CREATE UNIQUE INDEX idx_tc_pipeline_stations_pipeline_order_unique ON dbo.tc_pipeline_stations USING btree (pipeline_id, flow_order) WHERE (flow_order IS NOT NULL);
CREATE INDEX idx_tc_pipeline_stations_type_active ON dbo.tc_pipeline_stations USING btree (pipeline_id, station_type, is_active) WHERE (is_active = true);


-- gtn section

CREATE TABLE dbo.apv2_operational_available_capacity
(
	assetnbr INTEGER
	,assetabrv VARCHAR(50)
	,flowdate DATE
	,cycle_name VARCHAR(25)
	,cycleseq INTEGER
	,loc_id INTEGER
	,loc_name VARCHAR(50)
	,loc_sub_type VARCHAR(20)
	,loc_qty_ind VARCHAR(10)
	,location_purpose_desc VARCHAR(50)
	,design_capacity BIGINT
	,operational_capacity BIGINT
	,scheduled_quantity BIGINT
	,operational_available_capacity BIGINT
	,flow_ind VARCHAR(5)
	,it_ind VARCHAR(5)
	,posting_date TIMESTAMP WITHOUT TIME ZONE
	,import_time TIMESTAMP WITHOUT TIME ZONE
)

CREATE TABLE dbo.apv2_gtn_unit_masterlist
(
	pipeline VARCHAR(50)
	,station VARCHAR(50)
	,unitnumber VARCHAR(50)
	,unitname VARCHAR(50)
	,compressor VARCHAR(50)
	,horsepower INTEGER
	,minflow NUMERIC(18,2)
	,maxflow NUMERIC(18,2)
	,compminspeed INTEGER
	,compmaxspeed INTEGER
	,pi_compressorunit VARCHAR(50)
)



CREATE TABLE dbo.apv2_gtn_meter
(
	"timestamp" TIMESTAMP WITHOUT TIME ZONE
	,ap_meter INTEGER
	,btu DOUBLE PRECISION
	,flow_rate_mmcfd DOUBLE PRECISION
	,pressure DOUBLE PRECISION
	,id BIGINT NOT NULL DEFAULT 0
	,current_daytotal_mmcf DOUBLE PRECISION
	,temperature DOUBLE PRECISION
	,PRIMARY KEY (id)
)

CREATE TABLE dbo.apv2_gtn_cs_unit
(
	ap_compressor VARCHAR(256)
	,"timestamp" TIMESTAMP WITHOUT TIME ZONE
	,ap_compressorunit_gtn VARCHAR(256)
	,bhp DOUBLE PRECISION
	,enginestatus VARCHAR(256)
	,fuelflow DOUBLE PRECISION
	,intstatus INTEGER
	,modelbhp DOUBLE PRECISION
	,pressuredischarge DOUBLE PRECISION
	,pressuresuction DOUBLE PRECISION
	,rpm DOUBLE PRECISION
	,tempsuction DOUBLE PRECISION
	,id BIGINT NOT NULL DEFAULT 0
	,flowrate DOUBLE PRECISION
	,PRIMARY KEY (id)
)


CREATE TABLE dbo.apv2_gtn_station_masterlist
(
	pipeline VARCHAR(50)
	,dist VARCHAR(50)
	,floworder NUMERIC(18,2)
	,stationnumber VARCHAR(50)
	,stationname VARCHAR(50)
	,notes VARCHAR(64)
	,maop INTEGER
	,minop INTEGER
	,rated_hp INTEGER
	,meterid INTEGER
	,milepost NUMERIC(18,2)
	,"booster" BOOLEAN  DEFAULT true
)

CREATE TABLE dbo.apv2_gtn_segment_masterlist
(
	pipeline VARCHAR(50)
	,startcs VARCHAR(50)
	,endcs VARCHAR(50)
	,segmentordername VARCHAR(50)
	,segment VARCHAR(50)
	,segmentorder INTEGER
	,notes VARCHAR(50)
	,maop INTEGER
	,minop INTEGER
	,milepost NUMERIC(18,2)
	,pressure INTEGER
	,ffactor REAL
	,volume INTEGER
)

CREATE TABLE dbo.apv2_operational_available_capacity
(
	assetnbr INTEGER
	,assetabrv VARCHAR(50)
	,flowdate DATE
	,cycle_name VARCHAR(25)
	,cycleseq INTEGER
	,loc_id INTEGER
	,loc_name VARCHAR(50)
	,loc_sub_type VARCHAR(20)
	,loc_qty_ind VARCHAR(10)
	,location_purpose_desc VARCHAR(50)
	,design_capacity BIGINT
	,operational_capacity BIGINT
	,scheduled_quantity BIGINT
	,operational_available_capacity BIGINT
	,flow_ind VARCHAR(5)
	,it_ind VARCHAR(5)
	,posting_date TIMESTAMP WITHOUT TIME ZONE
	,import_time TIMESTAMP WITHOUT TIME ZONE
)



CREATE TABLE dbo.apv2_gtn_unit_masterlist
(
	pipeline VARCHAR(50)
	,station VARCHAR(50)
	,unitnumber VARCHAR(50)
	,unitname VARCHAR(50)
	,compressor VARCHAR(50)
	,horsepower INTEGER
	,minflow NUMERIC(18,2)
	,maxflow NUMERIC(18,2)
	,compminspeed INTEGER
	,compmaxspeed INTEGER
	,pi_compressorunit VARCHAR(50)
)

CREATE TABLE dbo.apv2_gtn_meter
(
	"timestamp" TIMESTAMP WITHOUT TIME ZONE
	,ap_meter INTEGER
	,btu DOUBLE PRECISION
	,flow_rate_mmcfd DOUBLE PRECISION
	,pressure DOUBLE PRECISION
	,id BIGINT NOT NULL DEFAULT 0
	,current_daytotal_mmcf DOUBLE PRECISION
	,temperature DOUBLE PRECISION
	,PRIMARY KEY (id)
)

CREATE TABLE dbo.apv2_gtn_cs_unit
(
	ap_compressor VARCHAR(256)
	,"timestamp" TIMESTAMP WITHOUT TIME ZONE
	,ap_compressorunit_gtn VARCHAR(256)
	,bhp DOUBLE PRECISION
	,enginestatus VARCHAR(256)
	,fuelflow DOUBLE PRECISION
	,intstatus INTEGER
	,modelbhp DOUBLE PRECISION
	,pressuredischarge DOUBLE PRECISION
	,pressuresuction DOUBLE PRECISION
	,rpm DOUBLE PRECISION
	,tempsuction DOUBLE PRECISION
	,id BIGINT NOT NULL DEFAULT 0
	,flowrate DOUBLE PRECISION
	,PRIMARY KEY (id)
)

CREATE TABLE dbo.apv2_gtn_station_masterlist
(
	pipeline VARCHAR(50)
	,dist VARCHAR(50)
	,floworder NUMERIC(18,2)
	,stationnumber VARCHAR(50)
	,stationname VARCHAR(50)
	,notes VARCHAR(64)
	,maop INTEGER
	,minop INTEGER
	,rated_hp INTEGER
	,meterid INTEGER
	,milepost NUMERIC(18,2)
	,"booster" BOOLEAN  DEFAULT true
)

CREATE TABLE dbo.apv2_gtn_segment_masterlist
(
	pipeline VARCHAR(50)
	,startcs VARCHAR(50)
	,endcs VARCHAR(50)
	,segmentordername VARCHAR(50)
	,segment VARCHAR(50)
	,segmentorder INTEGER
	,notes VARCHAR(50)
	,maop INTEGER
	,minop INTEGER
	,milepost NUMERIC(18,2)
	,pressure INTEGER
	,ffactor REAL
	,volume INTEGER
)











