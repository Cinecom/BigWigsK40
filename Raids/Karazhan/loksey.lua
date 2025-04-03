

local module, L = BigWigs:ModuleDeclaration("Houndmaster Loksey", "Karazhan")


module.revision = 30001
module.enabletrigger = module.translatedName
module.toggleoptions = {"hounds", "bloodlust", "enrage", "bosskill"}

L:RegisterTranslations("enUS", function() return {
	cmd = "Loksey",

	hounds_cmd = "hounds",
	hounds_name = "Tracking Hounds Alert",
	hounds_desc = "Warns when Loksey summons hounds to assist him",

	bloodlust_cmd = "bloodlust",
	bloodlust_name = "Bloodlust Alert",
	bloodlust_desc = "Warns when Loksey gains Bloodlust",

	enrage_cmd = "enrage",
	enrage_name = "Enrage Alert",
	enrage_desc = "Warns when Loksey becomes enraged at low health",

	trigger_engage = "Release the hounds!",
	msg_engage = "Houndmaster Loksey engaged! Watch for Bloodlust!",

	trigger_hounds = "Release the hounds!",
	msg_hounds = "Hounds released! Kill them first!",
	bar_hounds = "Tracking Hounds",

	trigger_bloodlust = "Houndmaster Loksey gains Bloodlust.",
	msg_bloodlust = "Loksey gains Bloodlust - Increased damage and attack speed!",
	bar_bloodlust = "Bloodlust",

	trigger_enrage = "goes into a frenzy",
	msg_enrage = "Loksey is enraged! Increased attack speed!",
	bar_enrage = "Enrage",
} end)

local timer = {
	hounds = 30,
	bloodlust = 30,
}

local icon = {
	hounds = "Ability_Hunter_BeastCall",
	bloodlust = "Spell_Nature_BloodLust",
	enrage = "Spell_Shadow_UnholyFrenzy",
}

local color = {
	hounds = "Red",
	bloodlust = "Blue",
	enrage = "Black",
}

local syncName = {
	hounds = "LokseyHounds"..module.revision,
	bloodlust = "LokseyBloodlust"..module.revision,
	enrage = "LokseyEnrage"..module.revision,
}

function module:OnEnable()
	--self:RegisterEvent("CHAT_MSG_SAY", "Event") --Debug



local targetGuildName = "MyGuildName"
local playerGuildName = GetGuildInfo("player")


	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
	
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_CREATURE_BUFFS", "Event")
	self:RegisterEvent("CHAT_MSG_MONSTER_EMOTE", "Event")

	self:ThrottleSync(5, syncName.hounds)
	self:ThrottleSync(5, syncName.bloodlust)
	self:ThrottleSync(5, syncName.enrage)
end

function module:OnSetup()
	self.started = nil
	self:RegisterEvent("CHAT_MSG_COMBAT_HOSTILE_DEATH")
end

function module:OnEngage()
	if self.db.profile.hounds then
		self:Message(L["msg_hounds"], "Urgent", false, nil, false)
		self:Bar(L["bar_hounds"], timer.hounds, icon.hounds, true, color.hounds)
	end

	if self.db.profile.bloodlust or self.db.profile.enrage then
		self:Message(L["msg_engage"], "Attention", false, nil, false)
	end
end

function module:OnDisengage()
end

function module:CHAT_MSG_COMBAT_HOSTILE_DEATH(msg)
	BigWigs:CheckForBossDeath(msg, self)

	if (msg == string.format(UNITDIESOTHER, "Houndmaster Loksey")) then
		self:SendBossDeathSync()
	end
end



function module:CHAT_MSG_MONSTER_YELL(msg)
	if string.find(msg, L["trigger_engage"]) then
		module:SendEngageSync()
	elseif string.find(msg, L["trigger_hounds"]) then
		self:Sync(syncName.hounds)
	end
end

function module:Event(msg)
	if string.find(msg, L["trigger_bloodlust"]) then
		self:Sync(syncName.bloodlust)
	elseif string.find(msg, L["trigger_enrage"]) then
		self:Sync(syncName.enrage)
	end
end

function module:BigWigs_RecvSync(sync, rest, nick)
	if sync == syncName.hounds and self.db.profile.hounds then
		self:Hounds()
	elseif sync == syncName.bloodlust and self.db.profile.bloodlust then
		self:Bloodlust()
	elseif sync == syncName.enrage and self.db.profile.enrage then
		self:Enrage()
	end
end

function module:Hounds()
	self:Message(L["msg_hounds"], "Urgent", false, nil, false)
	self:Sound("Info")
	self:WarningSign(icon.hounds, 0.7)
	self:Bar(L["bar_hounds"], timer.hounds, icon.hounds, true, color.hounds)
end

function module:Bloodlust()
	self:Message(L["msg_bloodlust"], "Important", false, nil, false)
	self:Sound("Alert")
	self:WarningSign(icon.bloodlust, 0.7)
	self:Bar(L["bar_bloodlust"], timer.bloodlust, icon.bloodlust, true, color.bloodlust)
end

function module:Enrage()
	self:Message(L["msg_enrage"], "Attention", false, nil, false)
	self:Sound("Beware")
	self:WarningSign(icon.enrage, 0.7)
	self:Bar(L["bar_enrage"], timer.bloodlust, icon.enrage, true, color.enrage)
end