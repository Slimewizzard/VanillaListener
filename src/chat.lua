-------------------------------------------------------------------------------
-- VanillaListener — chat.lua
--
-- Registers WoW chat events and routes incoming messages.
-- Two responsibilities:
--   1. Store messages for tracked players (via storage.lua)
--   2. Mention alerts for non-tracked players who say your name
-------------------------------------------------------------------------------

local VL = VanillaListener

local TRACKED_EVENTS = {
	"CHAT_MSG_SAY",
	"CHAT_MSG_YELL",
	"CHAT_MSG_EMOTE",
	"CHAT_MSG_TEXT_EMOTE",
	"CHAT_MSG_PARTY",
	"CHAT_MSG_RAID",
	"CHAT_MSG_RAID_WARNING",
}

-------------------------------------------------------------------------------
-- RegisterEvents / UnregisterEvents
-- Called from init.lua OnEnable / OnDisable.
-------------------------------------------------------------------------------
function VL:RegisterEvents()
	for _, evt in ipairs(TRACKED_EVENTS) do
		self:RegisterEvent(evt, "OnChatEvent")
	end
end

function VL:UnregisterEvents()
	for _, evt in ipairs(TRACKED_EVENTS) do
		self:UnregisterEvent(evt)
	end
end

-------------------------------------------------------------------------------
-- OnChatEvent
--
-- AceEvent routes all registered events here.
-- `event` is the WoW event name, arg1 = message text, arg2 = sender name.
-------------------------------------------------------------------------------
function VL:OnChatEvent(event)
	local text   = arg1
	local sender = arg2

	if not sender or sender == "" then return end

	-- Mention alert: non-tracked player mentioned you in nearby chat
	if self.db.char.notify then
		local me = UnitName("player")
		if sender ~= me and not self.db.char.players[sender] then
			if string.find(string.lower(text), string.lower(me)) then
				UIErrorsFrame:AddMessage(
					"|cffff0000[VanillaListener]|r " .. sender .. " mentioned you!",
					1, 1, 1, 1, UIERRORS_HOLD_TIME
				)
				DEFAULT_CHAT_FRAME:AddMessage(
					"|cffff0000[VanillaListener]|r " .. sender .. " mentioned you: " .. text
				)
			end
		end
	end

	-- Only proceed if this sender is tracked
	if not self.db.char.players[sender] then return end

	-- Store the message; AddMessage returns the new entry
	local entry = VL:AddMessage(event, text, sender)
	if not entry then return end

	-- Forward to any open windows that care about this sender
	VL:OnNewEntry(entry)
end

-------------------------------------------------------------------------------
-- OnNewEntry
--
-- Called after a new entry is stored.
-- history.lua and snooper.lua override/extend this to push into their frames.
-------------------------------------------------------------------------------
function VL:OnNewEntry(entry)
	-- Forwarded to history.lua: live append if auto-update is on
	if VL.History and VL.History.OnNewEntry then
		VL.History:OnNewEntry(entry)
	end
	-- Forwarded to snooper.lua: append if snooper is watching this sender
	if VL.Snooper and VL.Snooper.OnNewEntry then
		VL.Snooper:OnNewEntry(entry)
	end
end
