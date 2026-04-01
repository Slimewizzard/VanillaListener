-------------------------------------------------------------------------------
-- VanillaListener — history.lua
--
-- History window: per-player or "All Tracked" combined view.
-- Uses ScrollingMessageFrame — no manual height, no pendingScroll hack.
-------------------------------------------------------------------------------

local VL = VanillaListener

VL.History = {}
local H = VL.History

H.selectedPlayer = nil   -- name string or "*ALL*" or nil

-------------------------------------------------------------------------------
-- Setup
-- Called from OnEnable after XML is loaded.
-------------------------------------------------------------------------------
function H:Setup()
	VL:RegisterWindow("history", VLHistoryFrame)
	VL:ApplyFontSize()
end

-------------------------------------------------------------------------------
-- SelectPlayer
-- Switch the history view to a player (or "*ALL*" or nil to clear).
-- Opens the window if not already visible.
-------------------------------------------------------------------------------
function H:SelectPlayer(name)
	H.selectedPlayer = name

	if not name then
		VLHistoryFrameTitle:SetText("Message History")
		VLHistoryChatBox:Clear()
		return
	end

	if name == "*ALL*" then
		VLHistoryFrameTitle:SetText("All Tracked")
	else
		VLHistoryFrameTitle:SetText("History: " .. name)
	end

	H:Repopulate()

	if not VLHistoryFrame:IsVisible() then
		VLHistoryFrame:Show()
	end
end

-------------------------------------------------------------------------------
-- Repopulate
-- Clears the chatbox and fills it from storage.
-- Called on SelectPlayer and on window show.
-------------------------------------------------------------------------------
function H:Repopulate()
	VLHistoryChatBox:Clear()

	local entries
	if H.selectedPlayer == "*ALL*" then
		entries = VL:GetAllHistory(200)
	elseif H.selectedPlayer then
		entries = VL:GetHistory(H.selectedPlayer) or {}
	else
		return
	end

	local showSender = (H.selectedPlayer == "*ALL*")
	for _, entry in ipairs(entries) do
		local line = VL:FormatEntry(entry, showSender)
		VLHistoryChatBox:AddMessage(line)
	end
end

-------------------------------------------------------------------------------
-- OnNewEntry
-- Called by chat.lua when a new message arrives for a tracked player.
-- Live-appends if auto-update is on and the window is showing this player.
-------------------------------------------------------------------------------
function H:OnNewEntry(entry)
	if not VL.db.char.autoUpdate then return end
	if not VLHistoryFrame:IsVisible() then return end

	local sel = H.selectedPlayer
	if sel == "*ALL*" or sel == entry.s then
		local showSender = (sel == "*ALL*")
		local line = VL:FormatEntry(entry, showSender)
		VLHistoryChatBox:AddMessage(line)
	end
end
