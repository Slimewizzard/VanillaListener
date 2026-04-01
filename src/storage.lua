-------------------------------------------------------------------------------
-- VanillaListener — storage.lua
--
-- Message store/retrieve, global lineid system, per-player cap enforcement.
--
-- Entry format (lean, Listener-style):
--   { id, t, e, m, s }
--     id = global sequential line id
--     t  = unix timestamp (time())
--     e  = short event key: "SAY", "YELL", "EMOTE", "TEXT_EMOTE",
--                            "PARTY", "RAID", "RAID_WARNING"
--     m  = message text
--     s  = sender name
-------------------------------------------------------------------------------

local VL = VanillaListener

-- Maps CHAT_MSG_* event names to the short key stored in entries.
local EVENT_TO_KEY = {
	CHAT_MSG_SAY          = "SAY",
	CHAT_MSG_YELL         = "YELL",
	CHAT_MSG_EMOTE        = "EMOTE",
	CHAT_MSG_TEXT_EMOTE   = "TEXT_EMOTE",
	CHAT_MSG_PARTY        = "PARTY",
	CHAT_MSG_RAID         = "RAID",
	CHAT_MSG_RAID_WARNING = "RAID_WARNING",
}
VL.EVENT_TO_KEY = EVENT_TO_KEY

-- Channel prefix labels shown in combined/snooper views.
local CHANNEL_PREFIX = {
	PARTY        = "|cffaaaaff[P]|r ",
	RAID         = "|cffff7f00[R]|r ",
	RAID_WARNING = "|cffff2020[RW]|r ",
}
VL.CHANNEL_PREFIX = CHANNEL_PREFIX

-- Colors per message type.
local TYPE_COLOR = {
	SAY          = "|cffffffff",
	YELL         = "|cffff4040",
	EMOTE        = "|cffff7f00",
	TEXT_EMOTE   = "|cffff7f00",
	PARTY        = "|cffaaaaff",
	RAID         = "|cffff7f00",
	RAID_WARNING = "|cffff2020",
}
VL.TYPE_COLOR = TYPE_COLOR

-------------------------------------------------------------------------------
-- AddMessage
--
-- Called by chat.lua for every tracked player message.
-- Appends to chat_history[sender], enforces the per-player cap,
-- and returns the new entry so callers can forward it to open windows.
-------------------------------------------------------------------------------
function VL:AddMessage(event, text, sender)
	local key = EVENT_TO_KEY[event]
	if not key then return end

	local db      = self.db.account
	local history = db.chatHistory

	if not history[sender] then
		history[sender] = {}
	end

	local entry = {
		id = db.nextLineId,
		t  = time(),
		e  = key,
		m  = text,
		s  = sender,
	}
	db.nextLineId = db.nextLineId + 1

	local playerHistory = history[sender]
	table.insert(playerHistory, entry)

	-- Trim to cap — remove from front in one pass (handles burst arrivals)
	local over = table.getn(playerHistory) - db.maxMessages
	if over > 0 then
		for i = 1, over do
			table.remove(playerHistory, 1)
		end
	end

	return entry
end

-------------------------------------------------------------------------------
-- GetHistory
--
-- Returns the message list for a player, or nil if none.
-- Caller should treat this as read-only.
-------------------------------------------------------------------------------
function VL:GetHistory(name)
	return self.db.account.chatHistory[name]
end

-------------------------------------------------------------------------------
-- GetAllHistory
--
-- Returns a flat list of all tracked players' messages sorted by id,
-- limited to the most recent `limit` entries (default 200).
-- Builds a fresh sorted table each call — used for the "All Tracked" view.
-------------------------------------------------------------------------------
function VL:GetAllHistory(limit)
	limit = limit or 200
	local db      = self.db.account
	local players = self.db.char.players
	local merged  = {}

	for name in pairs(players) do
		local h = db.chatHistory[name]
		if h then
			for _, entry in ipairs(h) do
				table.insert(merged, entry)
			end
		end
	end

	-- Sort by global line id (chronological order)
	table.sort(merged, function(a, b) return a.id < b.id end)

	-- Trim to limit
	local total = table.getn(merged)
	if total > limit then
		local trimmed = {}
		for i = total - limit + 1, total do
			table.insert(trimmed, merged[i])
		end
		return trimmed
	end

	return merged
end

-------------------------------------------------------------------------------
-- ClearHistory
--
-- Wipes history for a single player.
-------------------------------------------------------------------------------
function VL:ClearHistory(name)
	name = VL:NormalizeName(name)
	if not name then return end
	self.db.account.chatHistory[name] = nil
	VL:Print("Cleared history for " .. name .. ".")
end

-------------------------------------------------------------------------------
-- ClearAllHistory
--
-- Wipes the entire history and resets the lineid counter.
-------------------------------------------------------------------------------
function VL:ClearAllHistory()
	self.db.account.chatHistory = {}
	self.db.account.nextLineId  = 1
	VL:Print("All history cleared.")
end

-------------------------------------------------------------------------------
-- FormatEntry
--
-- Returns a formatted string for a single entry ready for AddMessage()
-- on a ScrollingMessageFrame.
--
-- stamp format (Listener-style relative+aging):
--   < 1 min  →  "<1m"
--   < 30 min →  "Xm"
--   >= 30min →  "HH:MM"
--
-- The stamp color dims as the message ages.
-------------------------------------------------------------------------------
function VL:FormatEntry(entry, showSender)
	local age  = time() - entry.t
	local stamp

	if age < 60 then
		stamp = "<1m"
	elseif age < 1800 then
		stamp = math.floor(age / 60) .. "m"
	else
		stamp = date("%H:%M", entry.t)
	end

	local stampColor
	if age >= 3600 then
		stampColor = "|cff666666"
	elseif age >= 1800 then
		stampColor = "|cff888888"
	elseif age >= 600 then
		stampColor = "|cffaaaaaa"
	elseif age >= 60 then
		stampColor = "|cffcccccc"
	else
		stampColor = "|cff05acf8"
	end

	local prefix  = CHANNEL_PREFIX[entry.e] or ""
	local msgColor = TYPE_COLOR[entry.e] or "|cffffffff"

	local senderStr = ""
	if showSender then
		senderStr = "|cffeda55f" .. entry.s .. ":|r "
	end

	return stampColor .. "[" .. stamp .. "]|r " .. prefix .. senderStr .. msgColor .. entry.m .. "|r"
end
