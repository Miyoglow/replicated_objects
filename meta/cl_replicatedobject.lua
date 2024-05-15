
local PLUGIN = PLUGIN

local REPLOBJ = PLUGIN.replicatedObjectClass or ix.middleclass("ix_replicatedobject")

function REPLOBJ.static:Subclassed(subclass)
	net.Receive(subclass.name .. ":sync", function(length)
		for instanceID, instanceVars in pairs(util.JSONToTable(util.Decompress(net.ReadData(length)))) do
			subclass:New(instanceID, instanceVars)
		end
	end)

	net.Receive(subclass.name .. ":delete", function()
		local instances = subclass:GetInstances()
		local instanceID = net.ReadUInt(16)
		local instance = instances[instanceID]

		if (instance) then
			instances[instanceID] = nil
			subclass:SetInstances(instances)

			if (instance.OnDelete) then
				instance:OnDelete()
			end

			instance = nil
		end
	end)
end

function REPLOBJ.static:RegisterVar(field, fieldType, accessorName)
	net.Receive(self.name .. ":" .. field, function()
		local instance = self:GetInstances()[net.ReadUInt(16)]
		local value = net.ReadType()

		local vars = instance:GetVars()
		local old = vars[field]
			vars[field] = value
		instance:SetVars(vars)

		local notifyFunc = instance["Notify" .. accessorName]

		if (notifyFunc) then
			notifyFunc(instance, old, value)
		end
	end)

	self["Get" .. accessorName] = function(instance)
		return instance:GetVars()[field]
	end

	local varRegisters = self:GetVarRegisters()
		varRegisters[field] = true
	self:GetVarRegisters(varRegisters)
end

PLUGIN.replicatedObjectClass = REPLOBJ
