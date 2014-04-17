-- DWH Addon
-- Made by Elendir

DWH  = {}
DWH.name = "DWHAddon"
DWH.command = "/dwh"
DWH.version = 0.9

DWH.defaults = {
	["LeaderUnitTag"] = nil,
	["LeaderName"] = nil,
	["Mode"] = nil
}
DWH.pinType = "DWHLeader"
DWH.pinToolTipCreator = { creator = function(pin) InformationTooltip:AddLine("Raid Leader") end, tooltip = InformationTooltip }
DWH.pinLayoutData = { level = 159, texture = "EsoUI/Art/Inventory/inventory_tabicon_quest_up.dds", size = 64, color = DWH_SETTINGS.markerColor  }
DWH.compassLayoutData = { texture = "esoui/art/compass/quest_assistedareapin.dds" , maxDistance = DWH_SETTINGS.maxCompassMarkerDistance, color = DWH_SETTINGS.compassMarkerColor }

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
	
	DWH_COMPASS:Initialize(DWH.compassLayoutData, DWH.UpdateCompass)
	

	ZO_WorldMap_SetCustomPinEnabled( _G[DWH.pinType], true )
	DWH.SetGroupLeader()
	DWH.RefreshLeaderPin()
end




function DWH.SlashCommands(arg) 	
	
	--if(arg == "stl") then
	--	DWH.SetTargetLeader()
	--end
	--if(arg == "sgl") then
	--	d( "Setting group leader" )
	--	DWH.SetGroupLeader()
	-- end
	
	if(arg == "start") then
		DWH.SetGroupLeader()
	end
	
	if(arg == "stop") then
		DWH.RemoveLeader()
	end
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
	DWH.SetLeader(unitTag)
		
end


function DWH.SetLeader(unitTag)
	if(unitTag == "" or unitTag == nil) then return end
	DWH.vars.LeaderUnitTag = unitTag
	DWH.vars.LeaderName = GetUnitName(unitTag)
	if not IsUnitOnline(DWH.vars.LeaderUnitTag)  then
		d(DWH.vars.LeaderName.." is not connected")
		return
	end
	d("New leader is "..DWH.vars.LeaderName)
	--DWH.RefreshLeaderPin()
end


function DWH.UpdateCompass(pinManager)
	local leaderZone = GetUnitZone(DWH.vars.LeaderUnitTag)
	local playerZone = GetUnitZone('player')
	local sameZone = (leaderZone == playerZone)
	if(sameZone and DWH.vars.LeaderUnitTag ~= nil and IsUnitOnline(DWH.LeaderUnitTag)) then
		local normalizedX, normalizedY, heading = GetMapPlayerPosition(DWH.vars.LeaderUnitTag)
		pinManager:UpdateLeaderPosition(normalizedX, normalizedY)
	end
end

function DWH.UpdateLeaderPin(pinManager)
	local leaderZone = GetUnitZone(DWH.vars.LeaderUnitTag)
	local playerZone = GetUnitZone('player')
	local sameZone = (leaderZone == playerZone)
	if(sameZone and DWH.vars.LeaderUnitTag ~= nil and IsUnitOnline(DWH.LeaderUnitTag)) then
		local normalizedX, normalizedZ, heading = GetMapPlayerPosition(DWH.vars.LeaderUnitTag)
		pinManager:CreatePin( _G[DWH.pinType], "DWHLeader1", normalizedX, normalizedZ)	
	end
end

function DWH.RefreshLeaderPin()
	ZO_WorldMap_RefreshCustomPinsOfType( _G[DWH.pinType] )
	DWH_COMPASS:RefreshPin()
end


function DWH.GroupMemberLeft(memberName, reason, wasLocalPlayer)
	if(memberName == DWH.vars.LeaderName) then
		DWH.RemoveLeader()
	end

end

function DWH.LeaderUpdate(leaderUnitTag)
	DWH.SetLeader(leaderUnitTag, DWH.modes.group)
	--DWH.RefreshLeaderPin()
end


function DWH.RemoveLeader()
	DWH.vars.LeaderUnitTag = nil
	DWH.vars.LeaderName = nil
	
	--DWH.RefreshLeaderPin()
end

--local bt = {}
--function DWH.DelayBuffer(key, buffer)
--	if key == nil then return end
--	if bt[key] == nil then bt[key] = {} end
--	bt[key].buffer = buffer or 3
--	bt[key].now = GetFrameTimeMilliseconds()
--	if bt[key].last == nil then bt[key].last = bt[key].now end
--	bt[key].diff = bt[key].now - bt[key].last
--	bt[key].eval = bt[key].diff >= bt[key].buffer
--	if bt[key].eval then bt[key].last = bt[key].now end
--	return bt[key].eval
--end

function DWH.Update()
	--if not DWH.DelayBuffer("Update", 1000) then return; end
	--DWH.RefreshLeaderPin()
	DWH_COMPASS:Update()
end

-- Initialize addon event
EVENT_MANAGER:RegisterForEvent("DWH", EVENT_ADD_ON_LOADED, DWH.Initialize)
EVENT_MANAGER:RegisterForEvent("DWH", EVENT_LEADER_UPDATE, DWH.LeaderUpdate)
EVENT_MANAGER:RegisterForEvent("DWH", EVENT_GROUP_MEMBER_LEFT, DWH.GroupMemberLeft)

EVENT_MANAGER:RegisterForUpdate("DWH", DWH_SETTINGS.leaderPositionUpdateInterval, DWH.RefreshLeaderPin)
EVENT_MANAGER:RegisterForUpdate("DWHUpdate", DWH_SETTINGS.compassMarkerUpdateInterval, DWH.Update)