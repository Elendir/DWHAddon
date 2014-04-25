-- DWH Addon
-- Made by Elendir

DWH  = {}
DWH.name = "DWHAddon"
DWH.command = "/dwh"
DWH.version = 0.96

DWH.eventsRegistered = true

DWH.defaults = {
	["LeaderUnitTag"] = nil,
	["LeaderName"] = nil,
	["Mode"] = nil
}
DWH.pinType = "DWHLeader"
DWH.pinToolTipCreator = { creator = function(pin) InformationTooltip:AddLine("Raid Leader") end, tooltip = InformationTooltip }
DWH.pinLayoutData = { level = 159, texture = "EsoUI/Art/Inventory/inventory_tabicon_quest_up.dds", size = DWH_SETTINGS.markerSize, color = DWH_SETTINGS.markerColor  }
DWH.compassLayoutData = { texture = "esoui/art/compass/quest_assistedareapin.dds" , maxDistance = DWH_SETTINGS.maxCompassMarkerDistance, color = DWH_SETTINGS.compassMarkerColor }

function DWH.Initialize(eventCode, addOnName)
	if(addOnName ~= DWH.name) then return end
	
	DWH.vars = ZO_SavedVars:New( "DWHVars", math.floor(DWH.version * 100), nil, DWH.defaults, nil)
	SLASH_COMMANDS[DWH.command] = DWH.SlashCommands
	ZO_WorldMap_AddCustomPin(
		DWH.pinType,
		-- this function is called everytime, the customs pins of the given pinType are to be drawn (map update because of zone/area change or RefreshPins call)
		DWH.UpdateLeaderPin,
		nil, -- a function to be called, when the map is resized... no need when using default pins
		DWH.pinLayoutData,
		DWH.pinToolTipCreator
	)
	
	DWH_COMPASS:Initialize(DWH.compassLayoutData, DWH.UpdateCompass)
	

	ZO_WorldMap_SetCustomPinEnabled( _G[DWH.pinType], true )
	--DWH.SetGroupLeader()
	DWH.RefreshLeaderPin()
end




function DWH.SlashCommands(arg) 	
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
	
	if(isLeader) then 
		d("You are the leader")
		return
	end
	
	local unitTag = GetGroupLeaderUnitTag()
	DWH.SetLeader(unitTag)
		
end


function DWH.SetLeader(unitTag)
	if(unitTag == "" or unitTag == nil) then return end
	leaderName = GetUnitName(unitTag)
	if not IsUnitOnline(unitTag)  then
		d(leaderName.." is not connected")
		return
	end
	DWH.vars.LeaderUnitTag = unitTag
	DWH.vars.LeaderName = leaderName
	if leaderName ~= DWH.vars.LeaderName then 
		d("New leader is "..DWH.vars.LeaderName)
	end

	
	DWH.RegisterUpdateEvents()
	if(not DWH.eventsRegistered) then
		DWH.RegisterEvents()
	end
end


function DWH.UpdateCompass(pinManager)
	local leaderZone = GetUnitZone(DWH.vars.LeaderUnitTag)
	local playerZone = GetUnitZone('player')
	local sameZone = (leaderZone == playerZone)
	if(sameZone and DWH.vars.LeaderUnitTag ~= nil and IsUnitOnline(DWH.vars.LeaderUnitTag)) then
		local normalizedX, normalizedY, heading = GetMapPlayerPosition(DWH.vars.LeaderUnitTag)
		pinManager:UpdateLeaderPosition(normalizedX, normalizedY)
	else
		pinManager:RemovePin()
	end
end

function DWH.UpdateLeaderPin(pinManager)
	local leaderZone = GetUnitZone(DWH.vars.LeaderUnitTag)
	local playerZone = GetUnitZone('player')
	local sameZone = (leaderZone == playerZone)
	if(sameZone and DWH.vars.LeaderUnitTag ~= nil and IsUnitOnline(DWH.vars.LeaderUnitTag)) then
		local normalizedX, normalizedZ, heading = GetMapPlayerPosition(DWH.vars.LeaderUnitTag)
		pinManager:CreatePin( _G[DWH.pinType], "DWHLeader1", normalizedX, normalizedZ)	
	end
end

function DWH.RefreshLeaderPin()
	ZO_WorldMap_RefreshCustomPinsOfType( _G[DWH.pinType] )
	DWH_COMPASS:RefreshPin()
end


function DWH.LeaderPositionUpdate()
	local leaderZone = GetUnitZone(DWH.vars.LeaderUnitTag)
	local playerZone = GetUnitZone('player')
	local sameZone = (leaderZone == playerZone)
	if(sameZone and DWH.vars.LeaderUnitTag ~= nil and IsUnitOnline(DWH.vars.LeaderUnitTag)) then
		local normalizedX, normalizedY, heading = GetMapPlayerPosition(DWH.vars.LeaderUnitTag)
		ZO_WorldMap_RefreshCustomPinsOfType( _G[DWH.pinType] )
		DWH_COMPASS:UpdatePinPosition(normalizedX, normalizedY)
	else
		DWH.RemoveLeader()
	end
end


function DWH.GroupMemberLeft(memberName, reason, wasLocalPlayer)
	if(memberName == DWH.vars.LeaderName) then
		DWH.RemoveLeader()
	end
	DWH.CheckLeader()

end

function DWH.GroupMemberJoined(memberName)
	DWH.CheckLeader()
end

function DWH.CheckLeader()
	local leaderTag = GetGroupLeaderUnitTag()
	if(DWH.vars.LeaderUnitTag ~= leaderTag) then
		DWH.SetLeader(leaderTag)
	end
end

function DWH.ConnectionHandler(unitTag, isOnline)
	if(unitTag == GetGroupLeaderUnitTag() and isOnline) then
		DWH.SetLeader(unitTag)
	elseif(unitTag == DWH.vars.LeaderUnitTag) then
		DWH.RemoveLeader()
	end

end

function DWH.LeaderUpdate()
	DWH.SetLeader(GetGroupLeaderUnitTag())
	--DWH.RefreshLeaderPin()
end


function DWH.RemoveLeader()
	DWH.vars.LeaderUnitTag = nil
	DWH.vars.LeaderName = nil
	DWH.RefreshLeaderPin()
	DWH.UnregisterUpdateEvents()
	if(DWH.eventsRegistered) then
		DWH.UnregisterEvents()
	end
end

function DWH.DisplayUpdate()
	DWH_COMPASS:Update()
end



function DWH.RegisterUpdateEvents()
	EVENT_MANAGER:RegisterForUpdate("DWHLeaderUpdate", DWH_SETTINGS.leaderPositionUpdateInterval, DWH.RefreshLeaderPin)
	EVENT_MANAGER:RegisterForUpdate("DWHDisplayUpdate", DWH_SETTINGS.compassMarkerUpdateInterval, DWH.DisplayUpdate)
end

function DWH.UnregisterUpdateEvents()
	EVENT_MANAGER:UnregisterForUpdate("DWHLeaderUpdate")
	EVENT_MANAGER:UnregisterForUpdate("DWHDisplayUpdate")
end


function DWH.RegisterEvents()
	EVENT_MANAGER:RegisterForEvent("DWH", EVENT_LEADER_UPDATE, DWH.LeaderUpdate)
	EVENT_MANAGER:RegisterForEvent("DWH", EVENT_GROUP_MEMBER_LEFT, DWH.GroupMemberLeft)
	EVENT_MANAGER:RegisterForEvent("DWH", EVENT_GROUP_MEMBER_JOINED, DWH.GroupMemberJoined)
	EVENT_MANAGER:RegisterForEvent("DWH", EVENT_GROUP_MEMBER_CONNECTED_STATUS, DWH.ConnectionHandler)	
	DWH.eventsRegistered = true
end

function DWH.UnregisterEvents()
	EVENT_MANAGER:UnregisterForEvent("DWH", EVENT_LEADER_UPDATE)
	EVENT_MANAGER:UnregisterForEvent("DWH", EVENT_GROUP_MEMBER_LEFT)
	EVENT_MANAGER:UnregisterForEvent("DWH", EVENT_GROUP_MEMBER_JOINED)
	EVENT_MANAGER:UnregisterForEvent("DWH", EVENT_GROUP_MEMBER_CONNECTED_STATUS)
	DWH.eventsRegistered = false
end


local oldData = ZO_MapPin.SetData
ZO_MapPin.SetData = function( self, pinTypeId, pinTag)
	local back = GetControl(self.m_Control, "Background")
	if(pinTypeId == _G[DWH.pinType] and DWH.vars.LeaderUnitTag ~= nil) then 
		local color = DWH_SETTINGS.markerColor
		back:SetColor( color[1], color[2], color[3], 1)	
	else
		back:SetColor( 1, 1, 1, 1)	
	end
	oldData(self, pinTypeId, pinTag)
end

-- Initialize addon event
EVENT_MANAGER:RegisterForEvent("DWH", EVENT_ADD_ON_LOADED, DWH.Initialize)
DWH.RegisterEvents()
