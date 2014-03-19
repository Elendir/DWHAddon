-- DWH Addon
-- Made by Elendir

DWH  = {}
DWH.name = "DWHAddon"
DWH.command = "/dwh"
DWH.version = 0.01

DWH.modes.target = "target"
DWH.modes.group = "group"

DWH.defaults = {
	["LeaderUnitTag"] = nil,
	["LeaderName"] = nil,
	["Mode"] = nil
}
DWH.pinType = "DWHLeader"
DWH.pinToolTipCreator = { creator = function(pin) InformationTooltip:AddLine("Raid Leader") end, tooltip = InformationTooltip }
DWH.pinLayoutData = { level = 159, texture = "EsoUI/Art/Inventory/inventory_tabicon_quest_up.dds", size = POI_PIN_SIZE }

local function DWH.Initialize(eventCode, addOnName)
	if(addOnName ~= DWH.name) then return end
	
	DWH.vars = ZO_SavedVars:New( "DWHVars", math.floor(DWH.version * 100), nil, DWH.defaults, nil)
	SLASH_COMMANDS[DWH.command] = DWHSlashCommands
	
	ZO_WorldMap_AddCustomPin(
		 _G[DWH.pinType],
		-- this function is called everytime, the customs pins of the given pinType are to be drawn (map update because of zone/area change or RefreshPins call)
		function(pinManager) DWH.UpdateLeaderPin(pinManager) end,
		nil, -- a function to be called, when the map is resized... no need when using default pins
		DWH.pinLayoutData,
		DWH.pinToolTipCreator
	)
	
end

function DWHSlashCommands(arg) 	
	
	if(arg == "stl") then
		DWH.setTargetLeader()
	end
	if(arg == "sgl") then
		DWH.setGroupLeader()
	end
end

-- Set Target as Leader
local function DWH.SetTargetLeader()
	local unitTag = "reticleover"
	local isPlayer = IsUnitPlayer(unitTag)
	
	-- Do nothing if the target isn't a player
	if(not isPlayer) then return end
	
	DWH.SetLeader(unitTag, DWH.modes.target)
end 


-- Set Group Leader as Leader
local function DWH.SetGroupLeader()
	-- Do some validations
	local isInGroup = IsUnitGrouped('player')
	local isLeader = IsUnitGroupLeader('player')
		
	-- Do nothing if the player isn't in a group or is the leader
	if(not isInGroup or isLeader) then return end	
	
	local unitTag = GetGroupLeaderUnitTag()
	
	DWH.SetLeader(unitTag, DWH.modes.group)
			
end


local function DWH.SetLeader(unitTag, mode)
	if(unitTag == "" or unitTag == nil or mode == "" or mode == nil) then return end
	DWH.vars.LeaderUnitTag = unitTag
	DWH.vars.LeaderName = GetUnitName(unitTag)
	DWH.vars.Mode = mode
	
end

local function DWH.UpdateLeaderPin(pinManager)
	-- Display the marker only if finding a connected leader in the same zone as the player 
	local leaderZone = GetUnitZone(DWH.vars.LeaderUnitTag)
	local playerZone = GetUnitZone('player')
	local sameZone = (leaderZone == playerZone)
	if(sameZone and DWH.vars.LeaderUnitTag ~= nil and IsUnitOnline(DWH.LeaderUnitTag)) then
		-- local normalizedX, normalizedZ, heading = GetMapPlayerPosition(DWH.vars.LeaderUnitTag)
		local normalizedX, normalizedY = GetMapPing(DWH.vars.LeaderUnitTag)
		pinManager:CreatePin( _G[DWH.pinType], "DWHLeader1", normalizedX, normalizedY)	
	end
end

local function DWH.RefreshLeaderPin()
	ZO_WorldMap_RefreshCustomPinsOfType( _G[DWH.pinType] )
end


local function DWH.GroupMemberLeft(memberName, reason, wasLocalPlayer)
	if(memberName == DWH.vars.LeaderName and mode = DWH.modes.group) then
		DWH.RemoveLeader()
	end

end

local function DWH.LeaderUpdate(leaderUnitTag)
	if(mode == DWH.modes.group) then
		DWH.SetLeader(leaderUnitTag, DWH.modes.group)
		DWH.RefreshLeaderPin()
	end
end


local function DWH.RemoveLeader()
	DWH.vars.LeaderUnitTag = nil
	DWH.vars.LeaderName = nil
	DWH.vars.mode = nil
	
	DWH.RefreshLeaderPin()
end

-- Initialize addon event
EVENT_MANAGER:RegisterForEvent("DWH", EVENT_ADD_ON_LOADED, DWH.Initialize)
EVENT_MANAGER:RegisterForEvent("DWH", EVENT_LEADER_UPDATE, DWH.LeaderUpdate)
EVENT_MANAGER:RegisterForEvent("DWH", EVENT_GROUP_MEMBER_LEFT, DWH.GroupMemberLeft)