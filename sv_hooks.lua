
local PLUGIN = PLUGIN

function PLUGIN:PlayerInitialSpawn(client)
	for subclass, _ in pairs(self.replicatedObjectClass.subclasses) do
		subclass:SyncInstances(client)
	end
end

function PLUGIN:DatabaseConnected()
	local query = mysql:Create("ix_schema")
		query:Create("table", "VARCHAR(64) NOT NULL")
		query:Create("columns", "TEXT NOT NULL")
		query:PrimaryKey("table")
	query:Execute()

	for subclass, _ in pairs(self.replicatedObjectClass.subclasses) do
		query = mysql:Create(subclass.name)
			query:Create("id", "INT(11) UNSIGNED NOT NULL AUTO_INCREMENT")
			query:PrimaryKey("id")
		query:Execute()

		query = mysql:InsertIgnore("ix_schema")
			query:Insert("table", subclass.name)
			query:Insert("columns", util.TableToJSON({}))
		query:Execute()

		timer.Simple(0, function()
			subclass:Restore()
		end)
	end
end
