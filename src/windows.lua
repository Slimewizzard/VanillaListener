-------------------------------------------------------------------------------
-- VanillaListener — windows.lua
--
-- Window registry, position/size persistence, open/close helpers,
-- font size controls.
--
-- Each window is registered with a key that matches a db.char.windows entry:
--   "main"    → VLMainFrame
--   "history" → VLHistoryFrame
--   "snooper" → VLSnooperFrame
-------------------------------------------------------------------------------

local VL = VanillaListener

-- Maps window key → WoW frame (populated after XML loads)
VL.Windows = {}

-- Maps frame → window key (reverse lookup for SaveWindowPosition)
local frameToKey = {}

-------------------------------------------------------------------------------
-- RegisterWindow
-- Called by each module (playerlist.lua, history.lua, snooper.lua) after
-- their frame exists to wire it into the persistence system.
-------------------------------------------------------------------------------
function VL:RegisterWindow(key, frame)
	VL.Windows[key] = frame
	frameToKey[frame] = key
end

-------------------------------------------------------------------------------
-- SaveWindowPosition
-- Called from XML OnDragStop / OnSizeChanged / resize grip OnMouseUp.
-------------------------------------------------------------------------------
function VL:SaveWindowPosition(frame)
	local key = frameToKey[frame]
	if not key then return end

	local w = self.db.char.windows[key]
	if not w then return end

	local point, _, relPoint, x, y = frame:GetPoint(1)
	w.point    = point
	w.relPoint = relPoint
	w.x        = x
	w.y        = y
	w.width    = frame:GetWidth()
	w.height   = frame:GetHeight()
end

-------------------------------------------------------------------------------
-- RestoreWindowPosition
-- Called from XML OnShow.
-------------------------------------------------------------------------------
function VL:RestoreWindowPosition(frame)
	local key = frameToKey[frame]
	if not key then return end

	local w = self.db.char.windows[key]
	if not w then return end

	frame:ClearAllPoints()
	frame:SetPoint(w.point, UIParent, w.relPoint, w.x, w.y)
	if w.width  then frame:SetWidth(w.width)   end
	if w.height then frame:SetHeight(w.height) end
end

-------------------------------------------------------------------------------
-- ToggleMain
-- Slash command / minimap button handler.
-------------------------------------------------------------------------------
function VL:ToggleMain()
	local f = VL.Windows.main
	if not f then
		DEFAULT_CHAT_FRAME:AddMessage("VL debug: Windows.main is nil, trying VLMainFrame directly")
		if VLMainFrame then
			if VLMainFrame:IsVisible() then VLMainFrame:Hide()
			else VLMainFrame:Show() end
		else
			DEFAULT_CHAT_FRAME:AddMessage("VL debug: VLMainFrame also nil - XML not loaded?")
		end
		return
	end
	if f:IsVisible() then f:Hide()
	else f:Show() end
end

-------------------------------------------------------------------------------
-- ChangeFontSize
-- Connected to the +/- buttons in the main window bottom bar.
-------------------------------------------------------------------------------
function VL:ChangeFontSize(delta)
	local newSize = self.db.char.fontSize + delta
	if newSize < 8  then newSize = 8  end
	if newSize > 24 then newSize = 24 end
	self.db.char.fontSize = newSize
	VL:ApplyFontSize()
end

function VL:ApplyFontSize()
	local size = self.db.char.fontSize
	local font = "Fonts\\FRIZQT__.TTF"
	if VLHistoryChatBox then VLHistoryChatBox:SetFont(font, size) end
	if VLSnooperChatBox then VLSnooperChatBox:SetFont(font, size) end
end

-------------------------------------------------------------------------------
-- AddPlayerFromInput
-- Triggered by the Add button and the input EditBox OnEnterPressed.
-------------------------------------------------------------------------------
function VL:AddPlayerFromInput()
	local name = VLMainInput:GetText()

	-- Fall back to target if input is empty
	if (not name or name == "") and UnitExists("target") and UnitIsPlayer("target") then
		name = UnitName("target")
	end

	if name and name ~= "" then
		VL:AddPlayer(name)
		VLMainInput:SetText("")
	else
		VL:Print("Type a name or target a player first.")
	end
end
