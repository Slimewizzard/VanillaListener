-------------------------------------------------------------------------------
-- VanillaListener
-- RP chat tracker for TurtleWoW 1.12.1
-- Inspired by: Listener (retail) by Tammya-MoonGuard, WIM by Belazor
-------------------------------------------------------------------------------

VanillaListener = AceLibrary("AceAddon-2.0"):new(
	"AceEvent-2.0",
	"AceDB-2.0",
	"AceConsole-2.0"
)

local VL = VanillaListener

-------------------------------------------------------------------------------
-- Database defaults
-------------------------------------------------------------------------------

-- Per-character: which players this character is tracking
VL:RegisterDB("VanillaListenerDB", "VanillaListenerCharDB")

VL:RegisterDefaults("char", {
	players  = {},   -- [name] = true
	windows  = {
		main = {
			point = "CENTER", relPoint = "CENTER", x = -150, y = 0,
			width = 250, height = 400,
		},
		history = {
			point = "CENTER", relPoint = "CENTER", x = 150, y = 0,
			width = 400, height = 300,
		},
		snooper = {
			point = "CENTER", relPoint = "CENTER", x = 0, y = -200,
			width = 320, height = 180,
			locked    = false,
			hideEmpty = true,
		},
	},
	fontSize        = 12,
	autoUpdate      = true,
	notify          = true,
	preferMouseover = false,   -- probe: prefer mouseover over target
})

-- Per-account: message history shared across all characters
VL:RegisterDefaults("account", {
	chatHistory = {},   -- [playerName] = { {id,t,e,m,s}, ... }
	nextLineId  = 1,
	maxMessages = 200,
})

-------------------------------------------------------------------------------
-- Slash command handler (registered in OnEnable via raw WoW API)
-------------------------------------------------------------------------------
local function SlashHandler(input)
	input = string.lower(string.gsub(input or "", "^%s*(.-)%s*$", "%1"))

	if input == "" then
		VL:ToggleMain()

	elseif string.find(input, "^add%s") then
		local name = string.gsub(string.sub(input, 5), "^%s*(.-)%s*$", "%1")
		if name ~= "" then VL:AddPlayer(name)
		else DEFAULT_CHAT_FRAME:AddMessage("VanillaListener: Usage: /vl add <name>") end

	elseif string.find(input, "^remove%s") then
		local name = string.gsub(string.sub(input, 8), "^%s*(.-)%s*$", "%1")
		if name ~= "" then VL:RemovePlayer(name)
		else DEFAULT_CHAT_FRAME:AddMessage("VanillaListener: Usage: /vl remove <name>") end

	elseif string.find(input, "^clear%s") then
		local name = string.gsub(string.sub(input, 7), "^%s*(.-)%s*$", "%1")
		if name == "all" then VL:ClearAllHistory()
		elseif name ~= "" then VL:ClearHistory(name)
		else DEFAULT_CHAT_FRAME:AddMessage("VanillaListener: Usage: /vl clear <name|all>") end

	elseif input == "list" then
		VL:PrintTrackedList()

	else
		DEFAULT_CHAT_FRAME:AddMessage("VanillaListener: Commands: add | remove | clear | list")
	end
end

SLASH_VANILLALISTENER1 = "/vl"
SLASH_VANILLALISTENER2 = "/listener"
SLASH_VANILLALISTENER3 = "/vanillalistener"
SlashCmdList["VANILLALISTENER"] = SlashHandler

-------------------------------------------------------------------------------
-- Lifecycle
-------------------------------------------------------------------------------

function VL:OnEnable()
	-- Ace2 may or may not call this — real init is in VL_InitFrame below
end

function VL:OnDisable()
	VL:UnregisterAllEvents()
end

-- One-shot OnUpdate: fires on the first frame tick after the UI fully loads.
-- More reliable than VARIABLES_LOADED when AceEvent is in use.
local VL_InitFrame = CreateFrame("Frame")
local VL_InitDone = false
VL_InitFrame:SetScript("OnUpdate", function()
	if VL_InitDone then return end
	VL_InitDone = true
	VL_InitFrame:SetScript("OnUpdate", nil)
	VL_DoInit()
end)

function VL_DoInit()
	DEFAULT_CHAT_FRAME:AddMessage("|cff00ccffVanillaListener|r initializing...")

	local ok, err = pcall(function()

		VLMainFrame:SetResizable(true)
		VLMainFrame:SetMinResize(200, 300)
		VLHistoryFrame:SetResizable(true)
		VLHistoryFrame:SetMinResize(300, 200)
		VLSnooperFrame:SetResizable(true)
		VLSnooperFrame:SetMinResize(200, 100)

		DEFAULT_CHAT_FRAME:AddMessage("VL: frames resizable OK")

		VL:SetupListScroll()
		VL:BuildRowPool()

		DEFAULT_CHAT_FRAME:AddMessage("VL: pool built OK")

		VL.History:Setup()
		VL.Snooper:Setup()

		DEFAULT_CHAT_FRAME:AddMessage("VL: modules OK")

		VLMainLiveCheck:SetChecked(VL.db.char.autoUpdate)
		VLMainNotifyCheck:SetChecked(VL.db.char.notify)

		VL:RegisterEvents()

	end)

	if ok then
		DEFAULT_CHAT_FRAME:AddMessage("|cff00ccffVanillaListener|r ready. Type /vl to open.")
	else
		DEFAULT_CHAT_FRAME:AddMessage("|cffff0000VanillaListener ERROR:|r " .. tostring(err))
	end
end)

-------------------------------------------------------------------------------
-- Player management helpers (thin wrappers used by slash commands and UI)
-------------------------------------------------------------------------------

function VL:NormalizeName(name)
	if not name or name == "" then return nil end
	return string.upper(string.sub(name, 1, 1)) .. string.lower(string.sub(name, 2))
end

function VL:IsTracked(name)
	return self.db.char.players[name] == true
end

function VL:AddPlayer(name)
	name = VL:NormalizeName(name)
	if not name then return end
	if VL:IsTracked(name) then
		VL:Print(name .. " is already tracked.")
		return
	end
	self.db.char.players[name] = true
	VL:OnPlayerAdded(name)
	VL:Print("Now tracking " .. name .. ".")
end

function VL:RemovePlayer(name)
	name = VL:NormalizeName(name)
	if not name then return end
	if not VL:IsTracked(name) then
		VL:Print(name .. " is not in your tracking list.")
		return
	end
	self.db.char.players[name] = nil
	VL:OnPlayerRemoved(name)
	VL:Print("Stopped tracking " .. name .. ".")
end

function VL:PrintTrackedList()
	local names = {}
	for name in pairs(self.db.char.players) do
		table.insert(names, name)
	end
	if table.getn(names) == 0 then
		VL:Print("No players tracked.")
		return
	end
	table.sort(names)
	VL:Print("Tracked: " .. table.concat(names, ", "))
end

-- Stubs — filled in by playerlist.lua and history.lua
function VL:OnPlayerAdded(name)   end
function VL:OnPlayerRemoved(name) end
