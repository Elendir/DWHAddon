-- DWH Addon
-- Made by Elendir

DWH  = {}
DWH.name = "DWHAddon"
DWH.command = "/dwh"
DWH.version = 0.01

DWH.modes = {}
DWH.modes.target = "target"
DWH.modes.group = "group"

DWH.defaults = {
	["LeaderUnitTag"] = nil,
	["LeaderName"] = nil,
	["Mode"] = nil
}
DWH.pinType = "DWHLeader"
DWH.pinToolTipCreator = { creator = function(pin) InformationTooltip:AddLine("Raid Leader") end, tooltip = InformationTooltip }
DWH.pinLayoutData = { level = 159, texture = "EsoUI/Art/Inventory/inventory_tabicon_quest_up.dds", size = 64 }

function DWH.Initialize(eventCode, addOnName)
	if(addOnName ~= DWH.name) then return end
	
	DWH.vars = ZO_SavedVars:New( "DWHVars", math.floor(DWH.version * 100), nil, DWH.defaults, nil)
	SLASH_COMMANDS[DWH.command] = DWH.SlashCommands
	ZO_WorldMap_AddCustomPin(
		DWH.pinType,
		-- this function is called everytime, the customs pins of the given pinType are to be drawn (map update because of zone/area change or RefreshPins call)
		DWH.UpdateLeaderPin,
		DWH.RefreshLeaderPin, -- a function to be called, when the map is resized... no need when using default pins
		DWH.pinLayoutData,
		DWH.pinToolTipCreator
	)
	

	ZO_WorldMap_SetCustomPinEnabled( _G[DWH.pinType], true )
	ZO_WorldMap_RefreshCustomPinsOfType( _G[DWH.pinType] )
    -- SetMapPinAssisted( _G[DWH.pinType] , true, 1,1,1)
	-- SetMapPinContinuousPositionUpdate(_G[DWH.pinType], true, 1,1,1)
	
	-- local normalizedX, normalizedZ, heading = GetMapPlayerPosition("player")
	DWH.SetGroupLeader()
end


local bt = {}
function DWH.DelayBuffer(key, buffer)
	if key == nil then return end
	if bt[key] == nil then bt[key] = {} end
	bt[key].buffer = buffer or 3
	bt[key].now = GetFrameTimeMilliseconds()
	if bt[key].last == nil then bt[key].last = bt[key].now end
	bt[key].diff = bt[key].now - bt[key].last
	bt[key].eval = bt[key].diff >= bt[key].buffer
	if bt[key].eval then bt[key].last = bt[key].now end
	return bt[key].eval
end

function DWH.SlashCommands(arg) 	
	
	if(arg == "stl") then
		DWH.SetTargetLeader()
	end
	if(arg == "sgl") then
		d( "Setting group leader" )
		DWH.SetGroupLeader()
	end
end

-- Set Target as Leader
function DWH.SetTargetLeader()
	local unitTag = "reticleover"
	local isPlayer = IsUnitPlayer(unitTag)
	
	-- Do nothing if the target isn't a player
	if(not isPlayer) then return end
	
	DWH.SetLeader(unitTag, DWH.modes.target)
end 


-- Set Group Leader as Leader
function DWH.SetGroupLeader()
	-- Do some validations
	local isInGroup = IsUnitGrouped('player')
	local isLeader = IsUnitGroupLeader('player')
	-- Do nothing if the player isn't in a group or is the leader
	if(not isInGroup) then -- or isLeader
		d("You are not in a group or you are the leader")
		return
	end	
	
	local unitTag = GetGroupLeaderUnitTag()
	 -- d("The leader is"..unitTag)
	
	DWH.SetLeader(unitTag, DWH.modes.group)
		
end


function DWH.SetLeader(unitTag, mode)
	if(unitTag == "" or unitTag == nil or mode == "" or mode == nil) then return end
	DWH.vars.LeaderUnitTag = unitTag
	DWH.vars.LeaderName = GetUnitName(unitTag)
	d("New leader is "..DWH.vars.LeaderName)
	local leaderZone = GetUnitZone(DWH.vars.LeaderUnitTag)
	local playerZone = GetUnitZone('player')
	--d("player zone "..playerZone)
	--d("leader zone "..leaderZone)
	DWH.vars.Mode = mode
	DWH.RefreshLeaderPin()
	
	
end

function DWH.UpdateLeaderPin(pinManager)
	-- Display the marker only if finding a connected leader in the same zone as the player 
	local leaderZone = GetUnitZone(DWH.vars.LeaderUnitTag)
	local playerZone = GetUnitZone('player')
	local sameZone = (leaderZone == playerZone)
	if(sameZone) then
		--d("leader in same zone")
	end
	if(sameZone and DWH.vars.LeaderUnitTag ~= nil and IsUnitOnline(DWH.LeaderUnitTag)) then
		local normalizedX, normalizedZ, heading = GetMapPlayerPosition(DWH.vars.LeaderUnitTag)
		-- local normalizedX, normalizedY = GetMapPing(DWH.vars.LeaderUnitTag)
		--d("x: "..normalizedX)
		--d("z: "..normalizedZ)
		--d("head: "..heading)
		pinManager:CreatePin( _G[DWH.pinType], "DWHLeader1", normalizedX, normalizedZ)	
		
		--ZO_WorldMap:AddMapPin(_G[DWH.pinType], normalizedX, normalizedZ, 10)
	end
	-- pinManager:CreatePin( _G[DWH.pinType], "DWHTest", 0.5, 0.2)	
end

function DWH.RefreshLeaderPin()
	-- d("refreshing pin")
	ZO_WorldMap_RefreshCustomPinsOfType( _G[DWH.pinType] )
end


function DWH.GroupMemberLeft(memberName, reason, wasLocalPlayer)
	if(memberName == DWH.vars.LeaderName and mode == DWH.modes.group) then
		DWH.RemoveLeader()
	end

end

function DWH.LeaderUpdate(leaderUnitTag)
	if(mode == DWH.modes.group) then
		DWH.SetLeader(leaderUnitTag, DWH.modes.group)
		DWH.RefreshLeaderPin()
	end
end


function DWH.RemoveLeader()
	DWH.vars.LeaderUnitTag = nil
	DWH.vars.LeaderName = nil
	DWH.vars.mode = nil
	
	DWH.RefreshLeaderPin()
end

function DWH.Update()
	if not DWH.DelayBuffer("Update", 1000) then return; end
	DWH.RefreshLeaderPin()
end

-- Initialize addon event
EVENT_MANAGER:RegisterForEvent("DWH", EVENT_ADD_ON_LOADED, DWH.Initialize)
EVENT_MANAGER:RegisterForEvent("DWH", EVENT_LEADER_UPDATE, DWH.LeaderUpdate)
EVENT_MANAGER:RegisterForEvent("DWH", EVENT_GROUP_MEMBER_LEFT, DWH.GroupMemberLeft)