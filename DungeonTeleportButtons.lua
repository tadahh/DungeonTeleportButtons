local LIBRARY_NAME = "Dungeon Teleport Buttons"

local Library = _G[LIBRARY_NAME]

if not Library then
    Library = CreateFrame("Frame", LIBRARY_NAME)

    Library.MAP_ID_TO_SPELL_IDS = {
        -- https://wago.tools/db2/
        -- [MapChallengeMode Id] = {Path of ... SpellId}

        -- Pre TWW
        [402] = {393273}, -- Algeth'ar Academy
        [244] = {424187}, -- Atal'Dazar
        [199] = {424153}, -- Black Rook Hold
        [405] = {393267}, -- Brackenhide Hollow
        [210] = {393766}, -- Court of Stars
        [198] = {424163}, -- Darkheart Thicket
        [463] = {424197}, -- Dawn of the Infinite: Galakrond's Fall
        [464] = {424197}, -- Dawn of the Infinite: Murozond's Rise
        [245] = {410071}, -- Freehold
        [507] = {445424}, -- Grim Batol
        [378] = {354465}, -- Halls of Atonement
        [406] = {393283}, -- Halls of Infusion
        [200] = {393764}, -- Halls of Valor
        [375] = {354464}, -- Mists of Tirna Scithe
        [206] = {410078}, -- Neltharion's Lair
        [404] = {393276}, -- Neltharus
        [369] = {373274}, -- Operation: Mechagon - Junkyard
        [370] = {373274}, -- Operation: Mechagon - Workshop
        [399] = {393256}, -- Ruby Life Pools
        [165] = {159899}, -- Shadowmoon Burial Grounds
        [353] = {464256, 445418}, -- Siege of Boralus
        [392] = {367416}, -- Tazavesh, Soleah's Gambit
        [391] = {367416}, -- Tazavesh, Streets of Wonder
        [2]   = {131204}, -- Temple of the Jade Serpent
        [382] = {354467}, -- Theater of Pain
        [401] = {393279}, -- The Azure Vault
        [168] = {159901}, -- The Everbloom
        [247] = {467553, 467555}, -- The MOTHERLODE!!
        [376] = {354462}, -- The Necrotic Wake
        [400] = {393262}, -- The Nokhud Offensive
        [251] = {410074}, -- The Underrot
        [438] = {410080}, -- The Vortex Pinnacle
        [456] = {424142}, -- Throne of the Tides
        [403] = {393222}, -- Uldaman: Legacy of Tyr
        [248] = {424167}, -- Waycrest Manor

        -- TWW
        [503] = {445417}, -- Ara-Kara, City of Echoes
        [506] = {445440}, -- Cinderbrew Meadery
        [502] = {445416}, -- City of Threads
        [504] = {445441}, -- Darkflame Cleft
        [542] = {1237215}, -- Eco-Dome Al'dani
        [525] = {1216786}, -- Operation: Floodgate
        [499] = {445444}, -- Priory of the Sacred Flame
        [505] = {445414}, -- The Dawnbreaker
        [500] = {445443}, -- The Rookery
        [501] = {445269}, -- The Stonevault
    }

    function Library:Initialize()
        if not C_AddOns.IsAddOnLoaded("Blizzard_ChallengesUI") then
            self:RegisterEvent("ADDON_LOADED")
            return
        end

        if ChallengesFrame and type(ChallengesFrame.Update) == "function" then
            hooksecurefunc(ChallengesFrame, "Update", function () Library:CreateDungeonButtons() end)
        end

        Library:CreateDungeonButtons()
    end

    function Library:UpdateGameTooltip(parent, spellID, initialize)
        if (not initialize and not GameTooltip:IsOwned(parent)) then return end

        local Button_OnEnter = parent:GetScript("OnEnter")

        if (not Button_OnEnter) then return end

        local name = C_Spell.GetSpellName(spellID)

        Button_OnEnter(parent)

        if C_SpellBook.IsSpellKnown(spellID) then
            local spellCooldownInfo = C_Spell.GetSpellCooldown(spellID)

            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(name or TELEPORT_TO_DUNGEON)

            if spellCooldownInfo.duration == 0 or spellCooldownInfo.duration == C_Spell.GetSpellCooldown(61304).duration then
                GameTooltip:AddLine(READY, 0, 1, 0)
            else
                GameTooltip:AddLine(SecondsToTime(ceil(spellCooldownInfo.startTime + spellCooldownInfo.duration - GetTime())), 1, 0, 0)
            end
        else
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(name or TELEPORT_TO_DUNGEON)
            GameTooltip:AddLine(SPELL_FAILED_NOT_KNOWN, 1, 0, 0)
        end

        GameTooltip:Show()
        C_Timer.After(1, function () self:UpdateGameTooltip(parent, spellID) end)
    end

    function Library:CreateDungeonButton(parent, spellIDs)
        if (not spellIDs) then return end

        local spellID = self:SelectBestSpellID(spellIDs)
        local button = self[parent] or CreateFrame("Button", nil, parent, "InsecureActionButtonTemplate")

        button:SetAllPoints(parent)
        button:RegisterForClicks("AnyDown", "AnyUp")
        button:SetAttribute("type", "spell")
        button:SetAttribute("spell", spellID)
        button:SetScript("OnEnter", function () self:UpdateGameTooltip(parent, spellID, true) end)
        button:SetScript("OnLeave", function () if GameTooltip:IsOwned(parent) then GameTooltip:Hide() end end)

        self[parent] = button
    end

    function Library:CreateDungeonButtons()
        if (InCombatLockdown()) then return end
        if (not ChallengesFrame) then return end
        if (not ChallengesFrame.DungeonIcons) then return end

        for _, dungeonIcon in next, ChallengesFrame.DungeonIcons do
            self:CreateDungeonButton(dungeonIcon, self.MAP_ID_TO_SPELL_IDS[dungeonIcon.mapID])
        end
    end

    function Library:OnEvent(event, arg1)
        if event == "ADDON_LOADED" then
            if arg1 == "Blizzard_ChallengesUI" then
                self:Initialize()
                self:UnregisterEvent("ADDON_LOADED")
            end
        end
    end

    function Library:SelectBestSpellID(spellIDs)
        if #spellIDs > 1 then
            for _, spellID in next, spellIDs do
                if C_SpellBook.IsSpellKnown(spellID) then
                    return spellID
                end
            end
        end

        return spellIDs[1]
    end

    Library:SetScript("OnEvent", function (self, ...) self:OnEvent(...) end)
end

-- Initialize

Library:Initialize()