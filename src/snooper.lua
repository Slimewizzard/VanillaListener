-------------------------------------------------------------------------------
-- VanillaListener — snooper.lua
--
-- The Snooper window: a small, persistent frame that automatically shows
-- recent messages from whoever the player is targeting or hovering over.
--
-- Driven by probe.lua. When the probed player changes, the snooper
-- clears and repopulates from chat_history.
-- Live messages are appended directly if the snooper is watching that player.
-------------------------------------------------------------------------------

local VL = VanillaListener

VL.Snooper = {}
local S = VL.Snooper

-- How many messages to show in the snooper (most recent N from history)
local SNOOP_LINES = 30

-- The player currently displayed in the snooper (may differ from probe
-- briefly during the hold timeout).
local g_currentName = nil

-------------------------------------------------------------------------------
-- Setup
-- Called from OnEnable after XML is loaded.
-------------------------------------------------------------------------------
function S:Setup()
	VL:RegisterWindow("snooper", VLSnooperFrame)
	VL:ApplyFontSize()

	-- Start the probe
	VL.Probe:Setup()
end

-------------------------------------------------------------------------------
-- OnProbeChanged
-- Called by probe.lua whenever the probed player changes.
-------------------------------------------------------------------------------
function S:OnProbeChanged(name)
	if g_currentName == name then return end
	g_currentName = name

	local opts = VL.db.char.windows.snooper

	if not name then
		-- No target — hide if configured to hide when empty
		if opts.hideEmpty then
			VLSnooperFrame:Hide()
		else
			VLSnooperFrameTitle:SetText("Snooper")
			VLSnooperChatBox:Clear()
		end
		return
	end

	-- Update title
	VLSnooperFrameTitle:SetText(name)

	-- Repopulate from history
	S:Repopulate(name)

	-- Show the window (unless locked-hidden)
	if not VLSnooperFrame:IsVisible() then
		VLSnooperFrame:Show()
	end
end

-------------------------------------------------------------------------------
-- Repopulate
-- Fills the snooper chatbox with the last SNOOP_LINES messages for `name`.
-- Only shows messages if this player is tracked (has history).
-- Non-tracked players still show in the snooper — the history just won't
-- have entries, so the box will be empty (title still shows their name).
-------------------------------------------------------------------------------
function S:Repopulate(name)
	VLSnooperChatBox:Clear()

	local history = VL:GetHistory(name)
	if not history then return end

	-- Show the tail of the history (most recent SNOOP_LINES entries)
	local total = table.getn(history)
	local start = total - SNOOP_LINES + 1
	if start < 1 then start = 1 end

	for i = start, total do
		local entry = history[i]
		local line  = VL:FormatEntry(entry, false)  -- no sender prefix in snooper
		VLSnooperChatBox:AddMessage(line)
	end
end

-------------------------------------------------------------------------------
-- OnNewEntry
-- Called by chat.lua when a new tracked message arrives.
-- Live-appends if the snooper is currently watching this sender.
-------------------------------------------------------------------------------
function S:OnNewEntry(entry)
	if not VLSnooperFrame:IsVisible() then return end
	if g_currentName ~= entry.s then return end

	local line = VL:FormatEntry(entry, false)
	VLSnooperChatBox:AddMessage(line)
end
