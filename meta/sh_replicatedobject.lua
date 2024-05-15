
local PLUGIN = PLUGIN

local REPLOBJ = PLUGIN.replicatedObjectClass or ix.middleclass("ix_replicatedobject")

REPLOBJ._id = REPLOBJ._id or 0
REPLOBJ._vars = REPLOBJ._vars or {}

REPLOBJ.static._instances = REPLOBJ.static._instances or {}
REPLOBJ.static._varRegisters = REPLOBJ.static._varRegisters or {}

function REPLOBJ:GetID()
	return self._id
end

function REPLOBJ:GetVars()
	return self._vars
end

function REPLOBJ:SetID(id)
	self._id = id
end

function REPLOBJ:SetVars(vars)
	self._vars = vars
end

function REPLOBJ:Initialize(id, createVars)
	local varRegisters = self.class:GetVarRegisters()
	local vars = {}

	for field, value in pairs(createVars) do
		if (varRegisters[field]) then
			vars[field] = value
		end
	end

	id = tonumber(id)

	self:SetID(id)
	self:SetVars(vars)

	local instances = self.class:GetInstances()
		instances[id] = self
	self.class:SetInstances(instances)

	if (self.Init) then
		self:Init()
	end

	if (SERVER) then
		self:Sync(player.GetAll())
	end
end

function REPLOBJ.static:GetInstances()
	return self._instances
end

function REPLOBJ.static:SetInstances(instances)
	self._instances = instances
end

function REPLOBJ.static:GetVarRegisters()
	return self._varRegisters
end

function REPLOBJ.static:SetVarRegisters(varRegisters)
	self._varRegisters = varRegisters
end

PLUGIN.replicatedObjectClass = REPLOBJ
