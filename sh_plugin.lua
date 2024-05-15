
local PLUGIN = PLUGIN

PLUGIN.name = "Replicated Objects"
PLUGIN.description = "Implements easily added replicated objects that are saved in the database."
PLUGIN.author = "Miyoglow"

ix.util.Include("meta/sh_replicatedobject.lua")
ix.util.Include("meta/sv_replicatedobject.lua")
ix.util.Include("meta/cl_replicatedobject.lua")

ix.util.Include("sv_hooks.lua")
