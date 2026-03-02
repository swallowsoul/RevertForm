local _G = _G
local addonName = ...

local playerRace = select(2, _G.UnitRace("player"))
if not (playerRace == "Worgen" or playerRace == "Dracthyr") then return end
if not _G.RevertForm then RevertForm = {} end
_G.RevertForm[addonName] = true

local playerModel = _G.CreateFrame("PlayerModel")
local macroCond = "[nocombat,nomounted,novehicleui]"
local spellId, modelId

if playerRace == "Worgen" then
	spellId = 68996
	modelId = {[307454] = "w", [307453] = "w"}	-- Worgen
elseif playerRace == "Dracthyr" then
	spellId = 372014
	modelId = {[4207724] = "d"}					-- Dracthyr
end

local macroText = "/cast " .. macroCond .. " " .. _G.C_Spell.GetSpellName(spellId) .. "\n/run ClearOverrideBindings(RevertFormButton)"
local GetBindingKey, ClearOverrideBindings, SetOverrideBindingClick, InCombatLockdown, SecureCmdOptionParse
	= _G.GetBindingKey, _G.ClearOverrideBindings, _G.SetOverrideBindingClick, _G.InCombatLockdown, _G.SecureCmdOptionParse

local function setupKeyBinding(f)
	ClearOverrideBindings(f)
	local k1, k2 = GetBindingKey("TOGGLESHEATH")
	if k1 then SetOverrideBindingClick(f, false, k1, f:GetName()) end
	if k2 then SetOverrideBindingClick(f, false, k2, f:GetName()) end
end

local revertFormButton = _G.CreateFrame("Button", "RevertFormButton", nil, "SecureActionButtonTemplate")
revertFormButton:SetAttribute("type", "macro")
revertFormButton:RegisterEvent("UNIT_MODEL_CHANGED")
revertFormButton:RegisterEvent("UNIT_AURA")
revertFormButton:RegisterEvent("PLAYER_REGEN_ENABLED")
revertFormButton:RegisterEvent("PLAYER_ENTERING_WORLD")
revertFormButton:RegisterForClicks("LeftButtonDown", "LeftButtonUp")
revertFormButton:SetScript("OnEvent",
	function(self, event, ...)
		-- Model Trigger: Determine Current Form
		if event == "UNIT_MODEL_CHANGED" and ... == "player" then
			playerModel:SetUnit("player")
			local m = playerModel:GetModelFileID()
			if m then
				_G.RevertForm = modelId[m] and true or false
				if not InCombatLockdown() then
					if _G.RevertForm and SecureCmdOptionParse(macroCond) then
						setupKeyBinding(self)			-- Is Transformable, Can Transform; Set KeyBind
						self:SetAttribute("macrotext", macroText)
					else
						ClearOverrideBindings(self)		-- Not Transformable or Can't Transform; Unset
						self:SetAttribute("macrotext", "")
					end
				end
			end
		elseif not InCombatLockdown() and _G.RevertForm and SecureCmdOptionParse(macroCond) then
			setupKeyBinding(self)			-- Event Trigger: Is Transformable, Can Transform; Set KeyBind
			self:SetAttribute("macrotext", macroText)
		elseif not InCombatLockdown() then
			ClearOverrideBindings(self)		-- Event Trigger: Not Transformable or Can't Transform; Unset
			self:SetAttribute("macrotext", "")
		end
	end
)
