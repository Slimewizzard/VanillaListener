-- Namespace
VanillaListener = {}

-- Constants
local MAX_MESSAGES = 20
local MAX_ALL_MESSAGES = 30 -- Limit for "All" view to prevent glitches
local DEFAULT_FONT_SIZE = 12

-- Variables
local trackedPlayers = {}
local selectedPlayer = nil

-- Colors
local COLOR_SAY = "|cffffffff"
local COLOR_YELL = "|cffff4040"
local COLOR_EMOTE = "|cffff7f00"

-- Main Frame
local mainFrame = CreateFrame("Frame", "VanillaListenerFrame", UIParent)
mainFrame:SetWidth(250)
mainFrame:SetHeight(400)
mainFrame:SetPoint("CENTER", UIParent, "CENTER", -150, 0)
mainFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
})
mainFrame:Hide()
mainFrame:SetMovable(true)
mainFrame:EnableMouse(true)
mainFrame:SetResizable(true)
mainFrame:SetMinResize(200, 300)
mainFrame:RegisterForDrag("LeftButton")
mainFrame:SetScript("OnDragStart", function() this:StartMoving() end)
mainFrame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
mainFrame:SetScript("OnSizeChanged", function() 
    if VanillaListenerDB then 
        VanillaListenerDB.mainWidth = mainFrame:GetWidth() 
        VanillaListenerDB.mainHeight = mainFrame:GetHeight()
    end
end)

-- Main Frame Resize Grip
local mainResize = CreateFrame("Button", nil, mainFrame)
mainResize:SetWidth(16)
mainResize:SetHeight(16)
mainResize:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -7, 7)
mainResize:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
mainResize:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
mainResize:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
mainResize:SetScript("OnMouseDown", function() 
    mainFrame:StartSizing("BOTTOMRIGHT") 
end)
mainResize:SetScript("OnMouseUp", function() 
    mainFrame:StopMovingOrSizing() 
end)


-- Main Frame Title
local titleText = mainFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
titleText:SetPoint("TOP", mainFrame, "TOP", 0, -15)
titleText:SetText("VanillaListener")

-- Main Frame Close Button
local closeButton = CreateFrame("Button", nil, mainFrame, "UIPanelCloseButton")
closeButton:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -5, -5)
closeButton:SetScript("OnClick", function() mainFrame:Hide() end)

-- Add Player Input
local input = CreateFrame("EditBox", "VanillaListenerInput", mainFrame, "InputBoxTemplate")
input:SetWidth(130)
input:SetHeight(20)
input:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 20, -50)
input:SetAutoFocus(false)

-- Add Button
local addButton = CreateFrame("Button", "VanillaListenerAddButton", mainFrame, "UIPanelButtonTemplate")
addButton:SetWidth(60)
addButton:SetHeight(20)
addButton:SetPoint("LEFT", input, "RIGHT", 10, 0)
addButton:SetText("Add")
addButton:SetScript("OnClick", function()
    local name = input:GetText()
    
    -- Check Target if input is empty
    if (not name or name == "") and UnitExists("target") and UnitIsPlayer("target") then
        name = UnitName("target")
    end

    if name and name ~= "" then
        VanillaListener:AddPlayer(name)
        input:SetText("")
    else
        DEFAULT_CHAT_FRAME:AddMessage("VanillaListener: Please enter a name or target a player.")
    end
end)

-- Text Size Controls (Moved to Main Frame)
local textSizeLabel = mainFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
textSizeLabel:SetPoint("BOTTOMLEFT", mainFrame, "BOTTOMLEFT", 15, 15)
textSizeLabel:SetText("Text Size")

local decButton = CreateFrame("Button", nil, mainFrame, "UIPanelButtonTemplate")
decButton:SetWidth(20)
decButton:SetHeight(20)
decButton:SetPoint("LEFT", textSizeLabel, "RIGHT", 5, 0)
decButton:SetText("-")
decButton:SetScript("OnClick", function()
    if VanillaListenerDB.fontSize > 8 then
        VanillaListenerDB.fontSize = VanillaListenerDB.fontSize - 1
        VanillaListener:UpdateFontSize()
    end
end)

local incButton = CreateFrame("Button", nil, mainFrame, "UIPanelButtonTemplate")
incButton:SetWidth(20)
incButton:SetHeight(20)
incButton:SetPoint("LEFT", decButton, "RIGHT", 5, 0)
incButton:SetText("+")
incButton:SetScript("OnClick", function()
    if VanillaListenerDB.fontSize < 24 then
        VanillaListenerDB.fontSize = VanillaListenerDB.fontSize + 1
        VanillaListener:UpdateFontSize()
    end
end)

-- Auto Update Checkbox
local autoUpdateCheck = CreateFrame("CheckButton", "VanillaListenerAutoUpdateCheck", mainFrame, "UICheckButtonTemplate")
autoUpdateCheck:SetWidth(20)
autoUpdateCheck:SetHeight(20)
autoUpdateCheck:SetPoint("LEFT", incButton, "RIGHT", 15, 0)

local autoUpdateText = autoUpdateCheck:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
autoUpdateText:SetPoint("LEFT", autoUpdateCheck, "RIGHT", 0, 1)
autoUpdateText:SetText("Live")

autoUpdateCheck:SetScript("OnClick", function()
    if this:GetChecked() then
        VanillaListenerDB.autoUpdate = true
        -- Determine if we should update view immediately
        if selectedPlayer then VanillaListener:UpdateDetailView() end
    else
        VanillaListenerDB.autoUpdate = false
    end
end)

-- Player List Frame (ScrollFrame container)
local listFrame = CreateFrame("ScrollFrame", "VanillaListenerListFrame", mainFrame, "UIPanelScrollFrameTemplate")
listFrame:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 20, -80)
listFrame:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -30, 40) -- Adjusted to make room for Text Size buttons

local listContent = CreateFrame("Frame", "VanillaListenerListContent", listFrame)
listContent:SetWidth(200)
listContent:SetHeight(280)
listFrame:SetScrollChild(listContent)

-- Detail Window (Independent)
local detailWindow = CreateFrame("Frame", "VanillaListenerDetailWindow", UIParent)
detailWindow:SetWidth(400)
detailWindow:SetHeight(300)
detailWindow:SetPoint("CENTER", UIParent, "CENTER", 150, 0)
detailWindow:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
})
detailWindow:Hide()
detailWindow:SetMovable(true)
detailWindow:EnableMouse(true)
detailWindow:SetResizable(true)
detailWindow:SetMinResize(300, 200)
detailWindow:RegisterForDrag("LeftButton")
detailWindow:SetScript("OnDragStart", function() this:StartMoving() end)
detailWindow:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
detailWindow:SetScript("OnSizeChanged", function() 
    if VanillaListenerDB then 
        VanillaListenerDB.detailWidth = detailWindow:GetWidth() 
        VanillaListenerDB.detailHeight = detailWindow:GetHeight()
        -- Update scroll width to match new size
        if getglobal("VanillaListenerDetailScroll") then
           -- detailScroll is anchored, so we don't set its width. We set content width.
           local newWidth = detailWindow:GetWidth() - 50
           getglobal("VanillaListenerDetailContent"):SetWidth(newWidth)
           getglobal("VanillaListenerDetailText"):SetWidth(newWidth)
           
           -- Recalculate layout
           VanillaListener:UpdateDetailView()
        end
    end
end)

-- Detail Window Resize Grip
local detailResize = CreateFrame("Button", nil, detailWindow)
detailResize:SetWidth(16)
detailResize:SetHeight(16)
detailResize:SetPoint("BOTTOMRIGHT", detailWindow, "BOTTOMRIGHT", -7, 7)
detailResize:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
detailResize:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
detailResize:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
detailResize:SetScript("OnMouseDown", function() 
    detailWindow:StartSizing("BOTTOMRIGHT") 
end)
detailResize:SetScript("OnMouseUp", function() 
    detailWindow:StopMovingOrSizing() 
end)
detailResize:SetFrameLevel(detailWindow:GetFrameLevel() + 5) -- Ensure it's on top

-- Detail Window Title
local detailTitle = detailWindow:CreateFontString(nil, "ARTWORK", "GameFontNormal")
detailTitle:SetPoint("TOP", detailWindow, "TOP", 0, -15)
detailTitle:SetText("Message History")

-- Detail Window Close Button
local detailClose = CreateFrame("Button", nil, detailWindow, "UIPanelCloseButton")
detailClose:SetPoint("TOPRIGHT", detailWindow, "TOPRIGHT", -5, -5)
detailClose:SetScript("OnClick", function() detailWindow:Hide() end)


-- Detail ScrollFrame
local detailScroll = CreateFrame("ScrollFrame", "VanillaListenerDetailScroll", detailWindow, "UIPanelScrollFrameTemplate")
detailScroll:SetPoint("TOPLEFT", detailWindow, "TOPLEFT", 20, -40)
detailScroll:SetPoint("BOTTOMRIGHT", detailWindow, "BOTTOMRIGHT", -30, 25) -- Adjusted to 25 to clear resize grip

local detailContent = CreateFrame("Frame", "VanillaListenerDetailContent", detailScroll)
detailContent:SetWidth(350)
detailContent:SetHeight(230)
detailScroll:SetScrollChild(detailContent)

local detailText = detailContent:CreateFontString("VanillaListenerDetailText", "ARTWORK", "GameFontHighlightSmall")
-- Switched to TOPLEFT to be consistent with normal text flow on resize? 
-- No, user wants BOTTOM anchoring like chat.
-- To fix jumping, we MUST ensure the container height is STABLE.
-- If we use BOTTOMLEFT, the text grows up.
detailText:SetPoint("BOTTOMLEFT", detailContent, "BOTTOMLEFT", 0, 0)
detailText:SetWidth(350)
detailText:SetJustifyH("LEFT")
detailText:SetText("")


-- Core Functions

function VanillaListener:OnLoad()
    self.frame = CreateFrame("Frame")
    self.frame:RegisterEvent("ADDON_LOADED")
    self.frame:RegisterEvent("CHAT_MSG_SAY")
    self.frame:RegisterEvent("CHAT_MSG_YELL")
    self.frame:RegisterEvent("CHAT_MSG_EMOTE")
    self.frame:RegisterEvent("CHAT_MSG_TEXT_EMOTE")
    self.frame:SetScript("OnEvent", self.OnEvent)
    
    DEFAULT_CHAT_FRAME:AddMessage("VanillaListener loaded. Type /vl to open.")
    
    SLASH_VANILLALISTENER1 = "/vl"
    SLASH_VANILLALISTENER2 = "/listener"
    SlashCmdList["VANILLALISTENER"] = function()
        if mainFrame:IsVisible() then
            mainFrame:Hide()
            detailWindow:Hide()
        else
            mainFrame:Show()
        end
    end
end

function VanillaListener:OnEvent()
    if event == "ADDON_LOADED" and arg1 == "VanillaListener" then
        if not VanillaListenerDB then VanillaListenerDB = {} end
        if not VanillaListenerDB.players then VanillaListenerDB.players = {} end
        if not VanillaListenerDB.allMessages then VanillaListenerDB.allMessages = {} end -- Initialize dedicated All list
        if not VanillaListenerDB.fontSize then VanillaListenerDB.fontSize = DEFAULT_FONT_SIZE end
        if VanillaListenerDB.autoUpdate == nil then VanillaListenerDB.autoUpdate = true end -- Default True
        
        -- Restore sizes
        if VanillaListenerDB.mainWidth then mainFrame:SetWidth(VanillaListenerDB.mainWidth) end
        if VanillaListenerDB.mainHeight then mainFrame:SetHeight(VanillaListenerDB.mainHeight) end
        if VanillaListenerDB.detailWidth then detailWindow:SetWidth(VanillaListenerDB.detailWidth) end
        if VanillaListenerDB.detailHeight then detailWindow:SetHeight(VanillaListenerDB.detailHeight) end
        
        getglobal("VanillaListenerAutoUpdateCheck"):SetChecked(VanillaListenerDB.autoUpdate) -- Restore checkbox state
        VanillaListener:UpdatePlayerList()
        VanillaListener:UpdateFontSize()
        
    elseif event == "CHAT_MSG_SAY" or event == "CHAT_MSG_YELL" or event == "CHAT_MSG_EMOTE" or event == "CHAT_MSG_TEXT_EMOTE" then
        VanillaListener:HandleMessage(event, arg1, arg2)
    end
end

function VanillaListener:UpdateFontSize()
    local fontPath = "Fonts\\FRIZQT__.TTF"
    detailText:SetFont(fontPath, VanillaListenerDB.fontSize)
    -- Recalculate layout
    if selectedPlayer then VanillaListener:UpdateDetailView() end
end

function VanillaListener:HandleMessage(event, text, sender)
    -- Check if sender is in our list
    local isTracked = VanillaListenerDB.players[sender]
    
    if isTracked then
        local entry = { timestamp = time(), text = text, type = event }
        
        -- Add to individual player list
        table.insert(VanillaListenerDB.players[sender].messages, entry)
        if table.getn(VanillaListenerDB.players[sender].messages) > MAX_MESSAGES then
            table.remove(VanillaListenerDB.players[sender].messages, 1)
        end
        
        -- Add to "All Tracked" list
        if not VanillaListenerDB.allMessages then VanillaListenerDB.allMessages = {} end
        local allEntry = { timestamp = time(), text = text, type = event, sender = sender }
        table.insert(VanillaListenerDB.allMessages, allEntry)
        if table.getn(VanillaListenerDB.allMessages) > MAX_ALL_MESSAGES then
            table.remove(VanillaListenerDB.allMessages, 1)
        end
        
        -- Auto-Update Logic:
        -- Only update if window visible AND Auto-Update is enabled
        if detailWindow:IsVisible() and VanillaListenerDB.autoUpdate then
            if selectedPlayer == "*ALL*" or selectedPlayer == sender then
                VanillaListener:UpdateDetailView()
            end
        end
    end
end

function VanillaListener:AddPlayer(name)
    -- Normalize name (capitalize first letter)
    name = string.upper(string.sub(name, 1, 1)) .. string.lower(string.sub(name, 2))
    
    if not VanillaListenerDB.players[name] then
        VanillaListenerDB.players[name] = { messages = {} }
        VanillaListener:UpdatePlayerList()
        -- Auto select new player
        selectedPlayer = name
        VanillaListener:UpdateDetailView()
        if not detailWindow:IsVisible() then detailWindow:Show() end
        
        DEFAULT_CHAT_FRAME:AddMessage("VanillaListener: Added " .. name)
    else
         DEFAULT_CHAT_FRAME:AddMessage("VanillaListener: " .. name .. " is already tracked.")
    end
end

function VanillaListener:RemovePlayer(name)
    if VanillaListenerDB.players[name] then
        VanillaListenerDB.players[name] = nil
        if selectedPlayer == name then
            selectedPlayer = nil
            detailWindow:Hide()
        end
        VanillaListener:UpdatePlayerList()
    end
end

function VanillaListener:UpdatePlayerList()
    -- Clear current children of listContent
    local children = { listContent:GetChildren() }
    for _, child in ipairs(children) do
        child:Hide()
        child:SetParent(nil)
    end
    
    local yOffset = 0
    
    -- "All Tracked" Button
    local allBtn = CreateFrame("Button", nil, listContent)
    allBtn:SetWidth(150)
    allBtn:SetHeight(20)
    allBtn:SetPoint("TOPLEFT", listContent, "TOPLEFT", 0, yOffset)
    
    local allHighlight = allBtn:CreateTexture(nil, "HIGHLIGHT")
    allHighlight:SetAllPoints(allBtn)
    allHighlight:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
    allHighlight:SetBlendMode("ADD")
    
    local allText = allBtn:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    allText:SetPoint("LEFT", allBtn, "LEFT", 5, 0)
    allText:SetText("All Tracked")
    
    allBtn:SetScript("OnClick", function()
        selectedPlayer = "*ALL*"
        VanillaListener:UpdateDetailView(true)
        if not detailWindow:IsVisible() then detailWindow:Show() end
    end)
    
    yOffset = yOffset - 25 -- Separator space
    
    local sortedNames = {}
    for name, _ in pairs(VanillaListenerDB.players) do
        table.insert(sortedNames, name)
    end
    table.sort(sortedNames)
    
    for _, name in ipairs(sortedNames) do
        local playerName = name -- Fix for closure
        local btn = CreateFrame("Button", nil, listContent)
        btn:SetWidth(150)
        btn:SetHeight(20)
        btn:SetPoint("TOPLEFT", listContent, "TOPLEFT", 0, yOffset)
        
        -- Highlight texture
        local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetAllPoints(btn)
        highlight:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
        highlight:SetBlendMode("ADD")
        
        local text = btn:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        text:SetPoint("LEFT", btn, "LEFT", 5, 0)
        text:SetText(playerName)
        
        btn:SetScript("OnClick", function()
            selectedPlayer = playerName
            VanillaListener:UpdateDetailView(true)
            if not detailWindow:IsVisible() then detailWindow:Show() end
        end)
        
        -- Remove button (small x)
        local removeBtn = CreateFrame("Button", nil, btn)
        removeBtn:SetWidth(20)
        removeBtn:SetHeight(20)
        removeBtn:SetPoint("RIGHT", btn, "RIGHT", 20, 0) -- Slightly outside the main button text area
        
        local removeText = removeBtn:CreateFontString(nil, "ARTWORK", "GameFontRed")
        removeText:SetPoint("CENTER", removeBtn, "CENTER", 0, 0)
        removeText:SetText("X")
        
        removeBtn:SetScript("OnClick", function()
            VanillaListener:RemovePlayer(playerName)
        end)
        
        yOffset = yOffset - 20
    end
    
    listContent:SetHeight(math.abs(yOffset))
end

function VanillaListener:UpdateDetailView(forceBottom)
    -- Store current vertical scroll position
    local currentScroll = detailScroll:GetVerticalScroll()
    local maxScroll = detailScroll:GetVerticalScrollRange()
    local wasAtBottom = (currentScroll >= (maxScroll - 5))
    
    if not selectedPlayer then 
        detailTitle:SetText("Message History")
        detailContent:SetHeight(200) 
        return 
    end
    
    local displayMessages = {}
    
    if selectedPlayer == "*ALL*" then
        detailTitle:SetText("History: All Tracked")
        if VanillaListenerDB.allMessages then
            displayMessages = VanillaListenerDB.allMessages
        end
    elseif VanillaListenerDB.players[selectedPlayer] then
        detailTitle:SetText("History: " .. selectedPlayer)
        displayMessages = VanillaListenerDB.players[selectedPlayer].messages
    else
        detailTitle:SetText("Message History")
        detailContent:SetHeight(200) 
        return
    end
    
    local fullText = ""
    for _, msg in ipairs(displayMessages) do
        local color = COLOR_SAY
        if msg.type == "CHAT_MSG_YELL" then color = COLOR_YELL end
        if msg.type == "CHAT_MSG_EMOTE" or msg.type == "CHAT_MSG_TEXT_EMOTE" then color = COLOR_EMOTE end
        
        local timeStr = date("%H:%M:%S", msg.timestamp)
        local prefix = ""
        if selectedPlayer == "*ALL*" and msg.sender then
             prefix = "|cffeda55f[" .. msg.sender .. "]|r "
        end
        fullText = fullText .. "|cffaeaeae[" .. timeStr .. "]|r " .. prefix .. color .. msg.text .. "|r\n"
    end
    
    detailText:SetWidth(detailContent:GetWidth())
    detailText:SetText(fullText)
    
    -- Calculate height
    local stringHeight = detailText:GetHeight()
    local frameHeight = detailScroll:GetHeight()
    
    -- Ensuring content is AT LEAST the size of the viewable area is KEY for bottom alignment
    if stringHeight < frameHeight then 
        stringHeight = frameHeight 
    end
    
    -- Add a little padding for readabilty
    detailContent:SetHeight(stringHeight + 20)
    detailScroll:UpdateScrollChildRect()
    
    -- Auto-scroll logic (Sticky Bottom) WITH DELAY FIX
    -- We set a flag to force the scroll update on the NEXT frame.
    -- This allows the text to fully render/wrap so the height calculation is 100% accurate.
    if wasAtBottom or forceBottom then
        detailWindow.pendingScroll = true
    end
end

-- Add OnUpdate script to handle the delayed scroll
detailWindow:SetScript("OnUpdate", function()
    if this.pendingScroll then
        -- Recalculate rect in case size changed during render
        detailScroll:UpdateScrollChildRect() 
        local newMax = detailScroll:GetVerticalScrollRange()
        detailScroll:SetVerticalScroll(newMax)
        this.pendingScroll = false -- Reset flag
    end
end)

VanillaListener:OnLoad()
