-------------------------------------------------------------------------------
-- VanillaListener — probe.lua
--
-- Tracks who the player is targeting or hovering over.
-- Feeds the snooper window with the current "probed" player name.
--
-- Design (ported from Listener by Tammya-MoonGuard):
--   - OnUpdate frame polls target / mouseover every frame
--   - 0.5s timeout: snooper doesn't blank immediately on un-target
--   - Configurable preference: target-first or mouseover-first
--   - Fires VL:OnProbeChanged(name) when the probed player changes
-------------------------------------------------------------------------------

local VL = VanillaListener

VL.Probe = {}
local P = VL.Probe

local PROBE_TIMEOUT = 0.5   -- seconds to hold last target after losing it

local g_probeName  = nil    -- current probed player name (or nil)
local g_probeTime  = 0      -- GetTime() when last valid probe was found
local g_probeFrame = nil    -- hidden OnUpdate frame

-------------------------------------------------------------------------------
-- GetProbed
-- Returns the current probed player name, or nil.
-------------------------------------------------------------------------------
function P:GetProbed()
	return g_probeName
end

-------------------------------------------------------------------------------
-- Update  (called every frame via OnUpdate)
-------------------------------------------------------------------------------
function P:Update()
	local prefer1, prefer2

	if VL.db.char.preferMouseover then
		prefer1, prefer2 = "mouseover", "target"
	else
		prefer1, prefer2 = "target", "mouseover"
	end

	-- Pick the first valid player unit
	local unit
	if UnitExists(prefer1) and UnitIsPlayer(prefer1) then
		unit = prefer1
	elseif UnitExists(prefer2) and UnitIsPlayer(prefer2) then
		unit = prefer2
	end

	local unitName = unit and UnitName(unit) or nil

	if unitName then
		-- Valid unit found — reset the hold timer
		g_probeTime = GetTime()
	else
		-- No valid unit — check if we're still within the hold window
		if GetTime() < g_probeTime + PROBE_TIMEOUT then
			unitName = g_probeName  -- keep the last name a bit longer
		end
	end

	-- Only fire changed event if the name actually changed
	if g_probeName == unitName then return end

	g_probeName = unitName
	VL:OnProbeChanged(unitName)
end

-------------------------------------------------------------------------------
-- Setup
-- Creates the OnUpdate frame. Called from OnEnable.
-------------------------------------------------------------------------------
function P:Setup()
	if g_probeFrame then return end  -- guard against double-setup
	g_probeFrame = CreateFrame("Frame")
	g_probeFrame:SetScript("OnUpdate", function()
		P:Update()
	end)
end

-------------------------------------------------------------------------------
-- OnProbeChanged (on VL, called by probe, handled by snooper)
-- Stub — overridden in snooper.lua.
-------------------------------------------------------------------------------
function VL:OnProbeChanged(name)
	if VL.Snooper then
		VL.Snooper:OnProbeChanged(name)
	end
end
