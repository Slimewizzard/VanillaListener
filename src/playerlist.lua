-------------------------------------------------------------------------------
-- VanillaListener — playerlist.lua
--
-- Main window player list. Fixed pool of row buttons (no frame leak).
-- Uses UIPanelScrollFrameTemplate — content frame grows with list size,
-- scroll frame handles overflow naturally.
-------------------------------------------------------------------------------

local VL = VanillaListener

local ROW_HEIGHT  = 22
local MAX_ROWS    = 40   -- max pool size (more than enough tracked players)

local rowPool     = {}   -- reusable button frames
local displayList = {}   -- current sorted list including "*ALL*"

-------------------------------------------------------------------------------
-- BuildRowPool
-- Called once from OnEnable. Creates MAX_ROWS reusable row buttons.
-------------------------------------------------------------------------------
function VL:BuildRowPool()
	for i = 1, MAX_ROWS do
		local btn = CreateFrame("Button", "VLListRow"..i, VLMainListContent)
		btn:SetWidth(160)
		btn:SetHeight(ROW_HEIGHT - 2)

		local hl = btn:CreateTexture(nil, "HIGHLIGHT")
		hl:SetAllPoints(btn)
		hl:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
		hl:SetBlendMode("ADD")

		local label = btn:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		label:SetPoint("LEFT", btn, "LEFT", 5, 0)
		btn.label = label

		local removeBtn = CreateFrame("Button", nil, btn)
		removeBtn:SetWidth(20)
		removeBtn:SetHeight(20)
		removeBtn:SetPoint("LEFT", btn, "RIGHT", 2, 0)
		local xText = removeBtn:CreateFontString(nil, "ARTWORK", "GameFontRed")
		xText:SetPoint("CENTER")
		xText:SetText("X")
		btn.removeBtn = removeBtn

		btn:SetScript("OnClick", function()
			if btn.rowData == "*ALL*" then
				VL.History:SelectPlayer("*ALL*")
			elseif btn.rowData then
				VL.History:SelectPlayer(btn.rowData)
			end
		end)

		removeBtn:SetScript("OnClick", function()
			if btn.rowData and btn.rowData ~= "*ALL*" then
				VL:RemovePlayer(btn.rowData)
			end
		end)

		btn:Hide()
		removeBtn:Hide()
		table.insert(rowPool, btn)
	end

	VL:RegisterWindow("main", VLMainFrame)
	VLMainFrameTitle:SetText("VanillaListener")
	VLMainLiveCheck:SetChecked(VL.db.char.autoUpdate)
	VLMainNotifyCheck:SetChecked(VL.db.char.notify)
end

-- No-op: FauxScrollFrame not used
function VL:SetupListScroll() end

-------------------------------------------------------------------------------
-- RefreshPlayerList
-- Rebuilds display list and repositions pool buttons in the content frame.
-------------------------------------------------------------------------------
function VL:RefreshPlayerList()
	displayList = { "*ALL*" }
	local names = {}
	for name in pairs(self.db.char.players) do
		table.insert(names, name)
	end
	table.sort(names)
	for _, n in ipairs(names) do
		table.insert(displayList, n)
	end

	local total = table.getn(displayList)

	for i = 1, MAX_ROWS do
		local btn = rowPool[i]
		local data = displayList[i]
		if data then
			btn.rowData = data
			btn:SetPoint("TOPLEFT", VLMainListContent, "TOPLEFT", 0, -(i - 1) * ROW_HEIGHT)
			if data == "*ALL*" then
				btn.label:SetText("|cffeda55fAll Tracked|r")
				btn.removeBtn:Hide()
			else
				btn.label:SetText(data)
				btn.removeBtn:Show()
			end
			btn:Show()
		else
			btn.rowData = nil
			btn:Hide()
			btn.removeBtn:Hide()
		end
	end

	-- Resize content frame so scroll frame knows the full height
	local contentHeight = total * ROW_HEIGHT
	if contentHeight < 1 then contentHeight = 1 end
	VLMainListContent:SetHeight(contentHeight)
end

-------------------------------------------------------------------------------
-- Hooks from init.lua
-------------------------------------------------------------------------------
function VL:OnPlayerAdded(name)
	VL:RefreshPlayerList()
	if VL.History then VL.History:SelectPlayer(name) end
end

function VL:OnPlayerRemoved(name)
	VL:RefreshPlayerList()
	if VL.History and VL.History.selectedPlayer == name then
		VL.History:SelectPlayer(nil)
	end
end
