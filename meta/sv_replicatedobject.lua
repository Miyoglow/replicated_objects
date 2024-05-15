
local PLUGIN = PLUGIN

local REPLOBJ = PLUGIN.replicatedObjectClass or ix.middleclass("ix_replicatedobject")

function REPLOBJ:Sync(receiver)
	local data = util.Compress(util.TableToJSON({[self:GetID()] = self:GetVars()}))

	net.Start(self.class.name .. ":sync")
		net.WriteData(data, #data)
	net.Send(receiver)
end

function REPLOBJ.static:Create(createVars, callback)
	local query = mysql:Insert(self.name)
		local varRegisters = self:GetVarRegisters()

		for field, value in pairs(createVars) do
			if (varRegisters[field]) then
				query:Insert(field, value)
			end
		end

		query:Callback(function(result, status, lastID)
			callback(self:New(lastID, createVars))
		end)
	query:Execute()
end

function REPLOBJ.static:Delete(id)
	local query = mysql:Delete(self.name)
		query:Where("id", id)
	query:Execute()

	local instances = self:GetInstances()
	local instance = instances[id]

	if (instance) then
		instances[id] = nil
		self:SetInstances(instances)

		if (instance.OnDelete) then
			instance:OnDelete()
		end

		net.Start(self.name .. ":delete")
			net.WriteUInt(id, 16)
		net.Broadcast()

		instance = nil
	end
end

function REPLOBJ.static:Restore()
	local query = mysql:Select(self.name)
		query:Select("id")

		local varRegisters = self:GetVarRegisters()

		for field, _ in pairs(varRegisters) do
			query:Select(field)
		end

		query:Callback(function(result)
			if (istable(result) and #result > 0) then
				for _, row in ipairs(result) do
					local restoreVars = {}

					for field, value in pairs(row) do
						local varRegister = varRegisters[field]

						if (varRegister and value != "NULL") then
							if (varRegister == ix.type.number) then
								restoreVars[field] = tonumber(value)
							elseif (varRegister == ix.type.bool) then
								restoreVars[field] = tobool(value)
							else
								restoreVars[field] = tostring(value)
							end
						end
					end

					self:New(row.id, restoreVars)
				end
			end
		end)
	query:Execute()
end

function REPLOBJ.static:SyncInstances(receiver)
	local instances = self:GetInstances()

	local sendTbl = {}

	for instanceID, instance in pairs(instances) do
		sendTbl[instanceID] = instance:GetVars()
	end

	local data = util.Compress(util.TableToJSON(sendTbl))

	net.Start(self.name .. ":sync")
		net.WriteData(data, #data)
	net.Send(receiver)
end

function REPLOBJ.static:Subclassed(subclass)
	util.AddNetworkString(subclass.name .. ":sync")
	util.AddNetworkString(subclass.name .. ":delete")
end

function REPLOBJ.static:RegisterVar(field, fieldType, accessorName)
	local netString = self.name .. ":" .. field
	util.AddNetworkString(netString)

	ix.db.AddToSchema(self.name, field, fieldType)

	self["Set" .. accessorName] = function(instance, value)
		local vars = instance:GetVars()
		local old = vars[field]
			vars[field] = value
		instance:SetVars(vars)

		net.Start(netString)
			net.WriteUInt(instance:GetID(), 16)
			net.WriteType(value)
		net.Broadcast()

		local query = mysql:Update(self.name)
			query:Update(field, value)
			query:Where("id", instance:GetID())
		query:Execute()

		local notifyFunc = instance["Notify" .. accessorName]

		if (notifyFunc) then
			notifyFunc(instance, old, value)
		end
	end

	self["Get" .. accessorName] = function(instance)
		return instance:GetVars()[field]
	end

	local varRegisters = self:GetVarRegisters()
		varRegisters[field] = fieldType
	self:SetVarRegisters(varRegisters)
end

PLUGIN.replicatedObjectClass = REPLOBJ
