/**
 * A collection of .sql scripts on the file system
*/
component accessors="true" {

	processingdirective preservecase="true";

	property name="SqlFiles";
	property name="Id";
	property name="FullName";
	property name="ChartSQLStudio";
	property name="Path";
	property name="Config";
	property name="FriendlyName";
	property name="DefaultStudioDatasource";
	property name="Storys";
	property name="LatestStory";

	public function init(
		required string path,
		required ChartSQLStudio ChartSQLStudio
	){
		variables.path = path;
		variables.SqlFiles = [];
		variables.Id = createUUID();
		variables.ChartSQLStudio = arguments.ChartSQLStudio;

		//Replace all file characters which periods
		variables.FullName = new values.FullyQualifiedPathName(variables.path).toString();
		variables.ChartSQLStudio.addPackage(this);
		variables.Storys = [];
		variables.IsLoadingConfig = false;
		this.loadConfig();
		return this;
	}

	public function addStory(required Story Story){
		if(!this.findStoryById(Story.getId()).exists()){
			variables.Storys.append(Story);
		}
	}

	public function clearStorys(){
		for(var Story in variables.Storys){
			Story.delete();
		}
	}

	public Story function createStory(
		required string Name
		string Id
	) {

		var args = arguments;
		args.Package = this;

		var Story = new Story(
			argumentCollection = args
		);
		this.saveConfig();
		return Story;
	}

	/**
	 * Removes the story from the collection by creating a new collection
	 * of stories without the one to be removed
	 */
	public function removeStory(required Story Story){
		var newStorys = [];
		for(var story in variables.Storys){
			if(story.getId() != arguments.Story.getId()){
				arrayAppend(newStorys, story);
			}
		}
		variables.Storys = newStorys;
		this.saveConfig();
	}

	public optional function findStoryById(
		required string id
	) {
		for (var Story in this.getStorys()){
			// writeDump(Story.getId() & "_" & id);
			if (Story.getId() == id){
				return new optional(Story);
			}
		}
		return new optional(nullValue());
	}

	public function findStoryByName(
		required string name
	) {
		for (var Story in this.getStorys()){
			if (Story.getName() == name){
				return new optional(Story);
			}
		}
		return new optional(nullValue());
	}

	/**
	 * Constructor to load a new package from a file
	 */
	static function fromFile(required string directory, required ChartSQLStudio ChartSQLStudio){
		if(!directoryExists(directory)){
			directoryCreate(directory, true);
		}
		return new Package(path=directory, ChartSQLStudio=ChartSQLStudio);
	}

	/**
	 * Get all of the files in the directory recursively that are .sql files
	 */
	public function listFiles(path=variables.path){
		var files = directoryList(path=arguments.path, recurse=true, filter="*.sql", listInfo="query");
		return files;
	}

	public function setDefaultStudioDatasource(required StudioDatasource StudioDatasource){
		variables.DefaultStudioDatasource = arguments.StudioDatasource;
		//Sets the value into the config
		this.saveConfig();
	}

	public optional function getDefaultStudioDatasource(){
		if(variables.keyExists("DefaultStudioDatasource")){
			return new optional(variables.DefaultStudioDatasource);
		} else {
			return new optional(nullValue());
		}
	}

	public function loadSqlFiles(){
		var files = listFiles();
		for(var file in files){
			var path = file.directory & server.separator.file & file.name;
			var fullName = new values.FullyQualifiedPathName(path).toString();
			if(!this.findSqlFileByFullName(fullName).exists()){
				new SqlFile(path=path, name=file.name, package=this);
			}
		}

		//Now marks as missing if the file does not exist
		for(var sqlFile in variables.SqlFiles){
			if(!fileExists(sqlFile.getPath())){
				SqlFile.setIsMissing(true);
				SqlFile.setIsMissingFile(true);
			} else {
				SqlFile.setIsMissingFile(false);
				SqlFile.setIsMissing(false);
			}
		}
		// variables.SqlFiles = newPackageCollection;
		//Update ChartSQLStudio collection also

		return SqlFiles;
	}

	/**
	 * Override getSqlFiles so that we can filter those that are missing by
	 * default
	 */
	public function getSqlFiles(){
		var out = [];
		for(var sqlFile in variables.SqlFiles){
			if(!sqlFile.getIsMissing()){
				arrayAppend(out, sqlFile);
			}
		}

		//Sort the files by Title directive
		arraySort(out, function(a, b){

			var aTitle = a.getNamedDirectives().Title.getValueRaw()?:a.getFullName();
			var bTitle = b.getNamedDirectives().Title.getValueRaw()?:b.getFullName();

			if(aTitle == bTitle){
				return 0;
			} else if(aTitle > bTitle){
				return 1;
			} else {
				return -1;
			}
		});
		return out;
	}

	public function addSqlFile(SqlFile){
		if(!this.findSqlFileByFullName(fullName).exists()){
			arrayAppend(variables.SqlFiles, SqlFile);
		}
	}

	public SqlFile function createNewSqlFile(
		required string name,
		required string dotpath=""
	){
		var basePath = variables.path;
		var paths = listToArray(arguments.dotpath, ".");
		var subPath = arrayToList(paths, server.separator.file);
		var directoryPath = basePath & server.separator.file & subPath;
		directoryPath = replace(directoryPath, "\\", server.separator.file, "all");

		var fullPath = basePath & server.separator.file & subPath & server.separator.file & name;
		fullPath = replace(fullPath, "\\", server.separator.file, "all");

		if(!directoryExists(directoryPath)){
			directoryCreate(directoryPath, true);
		}

		//Check if the file already exists
		if(fileExists(fullPath)){
			throw("File already exists: " & fullPath);
		}
		// writeDump(local);
		// return;
		fileWrite(fullPath, "");
		var SqlFile = new SqlFile(path=fullPath, name=name, package=this);
		return SqlFile;
	}

	public function removeSqlFile(SqlFile) {
		var newSqlFiles = [];
		for(var sqlFile in variables.SqlFiles){
			if(sqlFile.getFullName() != arguments.SqlFile.getFullName()){
				arrayAppend(newSqlFiles, sqlFile);
			}
		}
		variables.SqlFiles = newSqlFiles;
	}

	public optional function findSqlFileByName(required string name){
		for(var sqlFile in variables.SqlFiles){
			if(sqlFile.getName() == arguments.name){
				return new optional(sqlFile);
			}
		}
		return new optional(nullValue());
	}

	public function findSqlFileByFullName(required string name){
		for(var sqlFile in variables.SqlFiles){
			if(sqlFile.getFullName() == arguments.name){
				return new optional(sqlFile);
			}
		}
		return new optional(nullValue());
	}

	public function setFriendlyName(required string FriendlyName){
		variables.FriendlyName = arguments.FriendlyName;
		this.saveConfig();
	}

	/**
	 * Loads the configuration file for the package and creates
	 * one if it does not exist. The package config will hold meta data about
	 * the package that will be used for publishing and other features.
	 */
	public function loadConfig(){
		var basePath = this.getPath();
		var file = basePath & server.separator.file & "package.config.json";
		if(!fileExists(file)){
			variables.config = structNew("ordered");
			config.FullName = this.getFullName();
			config.Path = this.getPath();
			config.FriendlyName = "New Package";
			this.saveConfig();
		} else {

			// When we are loading the config then we do not want to save it
			// if any related objects call saveConfig();
			variables.IsLoadingConfig = true;

			var config = fileRead(file);
			config = deserializeJSON(config);

			variables.FullName = config.FullName;
			variables.FriendlyName = config.FriendlyName?:"";

			if(isDefined("config.DefaultStudioDatasource.Name")){
				// Only if the datasource exists will we load it. Otherwise we will just ignore it and it will not be
				// set or saved
				DefaultStudioDatasourceOptional = variables.ChartSQLStudio.findStudioDatasourceByName(config.DefaultStudioDatasource.Name);
				if(DefaultStudioDatasourceOptional.exists()){
					variables.DefaultStudioDatasource = DefaultStudioDatasourceOptional.get();
				}
			}

			//Load the stories
			if(isDefined("config.Storys")){
				for(var storyConfig in config.Storys){
					if(!this.findStoryById(storyConfig.Id).exists()){

						var Story = this.createStory(
							Package = this,
							Name = storyConfig.Name,
							Id = storyConfig.Id
						);

						// Create the Slides
						for(var slideConfig in storyConfig.Slides){
							var Slide = Story.createSlide(
								Title = slideConfig.Title,
								FullName = slideConfig.FullName,
								Id = slideConfig.Id
							);
						}
					}
				}
			}

			// Reset flag so that we can save the config again
			// when we are done loading
			variables.IsLoadingConfig = false;
		}
		return config;
	}

	public function saveConfig(){

		// When we are loading the config then we do not want to save it
		// if any related objects call saveConfig();
		if(variables.IsLoadingConfig){
			return;
		}

		var basePath = this.getPath();
		var file = basePath & server.separator.file & "package.config.json";

		var out = new zero.serializerFast(this, {
			FullName:{},
			Path:{},
			FriendlyName:{},
			DefaultStudioDatasource:{
				Name:{}
			},
			Storys:{
				Name:{},
				Id:{},
				Slides:{
					Title:{},
					FullName:{},
					Id:{}
				}
			}
		});

		var ConfigFile = ConfigFile::fromStruct(out);
		ConfigFile.setPath(file);
		ConfigFile.write();
		// fileWrite(file, serializeJSON(variables.config));
	}

	public optional function getLatestStory(){
		if(variables.storys.len() == 0){
			return new optional(nullValue());
		} else {
			return new optional(variables.storys[variables.storys.len()]);
		}
	}
}