/**
 * A configured datasource that we will connect to to run the scripts and get output
*/
component accessors="true" {

	property name="ChartSQLStudio";
	property name="Name" type="string";
	property name="Type" type="string";
	property name="Config" type="struct" setter="false" hint="Use updateConfig() to update the config";
	property name="Datasource" type="Datasource";
	property name="Metadata";

	public function init(
		required string name,
		required string type,
		required struct config,
		required ChartSQLStudio ChartSQLStudio
	){
		variables.name = arguments.name;
		variables.type = arguments.type;
		variables.config = arguments.config;
		variables.ChartSQLStudio = arguments.ChartSQLStudio;
		variables.Datasource = createObject("core.model.datasources.#variables.type#").init(argumentCollection=variables.config);
		variables.ChartSQLStudio.addStudioDatasource(this);
		return this;
	}

	public function getMetadata(){
		var metaData = getComponentMetadata("core.model.datasources.#variables.type#");
		var out = {
			Name = metaData.displayName?:variables.Type,
			Description = metaData.description?:"#variables.Type# Connector",
			Type = variables.Type,
			IconClass = metaData.iconClass?:"ti ti-database",
			Fields = variables.ChartSQLStudio.getDatasourceTemplate(variables.Type)
		}

		//Populate the current values
		for(var field in out.fields){
			field.value = variables.Config[field.name]?:nullValue();
		}

		return out;
	}

	public function updateConfig(required struct Config){
		variables.Datasource = createObject("core.model.datasources.#variables.type#").init(argumentCollection=arguments.config);
		variables.Config = arguments.config;
		variables.ChartSQLStudio.saveConfig();
		return this;
	}
}