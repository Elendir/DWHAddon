DWH_COMPASS = {}
local PARENT = COMPASS.container
local FOV = math.pi * 0.6

DWH_COMPASS.PinManager = ZO_ControlPool:Subclass()

-- COMPASS -- 
function DWH_COMPASS:Initialize(layout, callback)
	self.control = WINDOW_MANAGER:CreateControlFromVirtual("DWH_CP_Control", GuiRoot, "ZO_MapPin")
	self.control:SetHidden(false)
	self.pinManager = DWH_COMPASS.PinManager:New(layout, callback)
	self.FOV = FOV
end


function DWH_COMPASS:Update()
	if(self.pinManager) then
		local heading = GetPlayerCameraHeading()
		if not heading then
			return
		end
		if heading > math.pi then --normalize heading to [-pi,pi]
			heading = heading - 2 * math.pi
		end
	
		local x, y = GetMapPlayerPosition("player")
		self.pinManager:Update( x, y, heading )
	end
end

function DWH_COMPASS:RefreshPin()
	self.pinManager.callback(self.pinManager)
end


-- PIN MANAGER -- 
function DWH_COMPASS.PinManager:New(layout, callback)
	local subclass = ZO_ControlPool.New(self, "ZO_MapPin", PARENT, "Pin")
	subclass.pins = {}
	subclass.pinData = {}
	subclass.defaultAngle = 1
	subclass.layout = layout
	subclass.callback = callback
	subclass.leaderX = 0
	subclass.leaderY = 0
	return subclass
end

function DWH_COMPASS.PinManager:UpdateLeaderPosition(x, y)
	self.leaderX = x
	self.leaderY = y
end

function DWH_COMPASS.PinManager:GetNewPin()
	local pin, pinKey = self:AcquireObject()
	pin:SetHandler("OnMouseDown", nil)
	pin:SetHandler("OnMouseUp", nil)
	pin:SetHandler("OnMouseEnter", nil)
	pin:SetHandler("OnMouseExit", nil)
	
	pin.xLoc = self.leaderX
	pin.yLoc = self.leaderY	
	
	pin.pinType = "DWHCompassLeader"
	pin.pinTag = "DWHRaidLeader"
	local texture = pin:GetNamedChild( "Background" )
	texture:SetTexture( self.layout.texture )
	texture:SetColor(self.layout.color[1] , self.layout.color[2] , self.layout.color[3], 1)
	return pin, pinKey
end

function DWH_COMPASS.PinManager:Update(x, y, heading)
	local value
	local pin
	local angle
	local normalizedAngle
	local xDif, yDif
	local layout
	local normalizedDistance
	xDif = x - self.leaderX
	yDif = y - self.leaderY
	normalizedDistance = (xDif * xDif + yDif * yDif) / (self.layout.maxDistance * self.layout.maxDistance)
	if normalizedDistance < 1 then
		if self.pinKey then
			pin = self:GetExistingObject(self.pinKey)
		else
			pin, self.pinKey = self:GetNewPin()
		end
		
		if not pin then
			self:ReleaseObject(self.pinKey)
			self.pinKey = nil
			return
		end 
		
		pin:SetHidden(true)
		angle = -math.atan2( xDif, yDif )
		angle = (angle + heading)
		if angle > math.pi then
			angle = angle - 2 * math.pi
		elseif angle < -math.pi then
			angle = angle + 2 * math.pi
		end	
		
		normalizedAngle = 2 * angle / (self.layout.FOV or DWH_COMPASS.FOV)
		if zo_abs(normalizedAngle) > (self.layout.maxAngle or self.defaultAngle) then
			pin:SetHidden( true )
		else
			pin:ClearAnchors()
			pin:SetAnchor( CENTER, PARENT, CENTER, 0.5 * PARENT:GetWidth() * normalizedAngle, 0)
			pin:SetHidden( false )
			
			if self.layout.sizeCallback then
				self.layout.sizeCallback( pin, angle, normalizedAngle, normalizedDistance )
			else
				if zo_abs(normalizedAngle) > 0.25 then
					pin:SetDimensions( 36 - 16 * zo_abs(normalizedAngle), 36 - 16 * zo_abs(normalizedAngle) )
				else
					pin:SetDimensions( 32 , 32  )
				end
			end
		
		    pin:SetAlpha(1 - normalizedDistance)
			if self.layout.additionalLayout then
				self.layout.additionalLayout[1]( pin, angle, normalizedAngle, normalizedDistance)
			end
		end
	end
end

function DWH_COMPASS.PinManager:RemovePin() 
	self:ReleaseAllObjects()
end
