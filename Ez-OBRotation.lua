----------------------------------------------------------------------
-- Ez-OBRotation - One Button Rotation Keybind Display
-- Shows the keybind of the spell displayed on the SBA button
----------------------------------------------------------------------

local AddonName = "Ez-OBRotation"

local fontBold = "Interface\\AddOns\\Ez-OBRotation\\Fonts\\Luciole-Bold.ttf"
local fontReg  = "Interface\\AddOns\\Ez-OBRotation\\Fonts\\Luciole-Regular.ttf"

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")

local settingsCategory = nil 
local usingBartender = false

local defaults = {
    fontSize = 24,
    fontPath = fontBold, 
    r = 1, g = 1, b = 1, 
    anchor = "TOPRIGHT",
    minimapPos = 220,
}

local anchorMap = {
    ["Top Left"] = "TOPLEFT",
    ["Top Right"] = "TOPRIGHT",
    ["Bottom Left"] = "BOTTOMLEFT",
    ["Bottom Right"] = "BOTTOMRIGHT",
    ["Centered"] = "CENTER"
}
local reverseAnchorMap = {}
for k, v in pairs(anchorMap) do reverseAnchorMap[v] = k end

local anchorOffsets = {
    TOPRIGHT = {-2, -2},
    TOPLEFT = {2, -2},
    BOTTOMRIGHT = {-2, 2},
    BOTTOMLEFT = {2, 2},
    CENTER = {0, 0}
}

f:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        if not _G.EzOBR_Config then _G.EzOBR_Config = CopyTable(defaults) end
        if not _G.EzOBR_Config.anchor then _G.EzOBR_Config.anchor = "TOPRIGHT" end
        if not _G.EzOBR_Config.minimapPos then _G.EzOBR_Config.minimapPos = 220 end
        if not _G.EzOBR_Config.fontPath then _G.EzOBR_Config.fontPath = fontBold end

        usingBartender = C_AddOns.IsAddOnLoaded("Bartender4")
        
        self:CreateMenu()
        self:CreateMinimapButton()
        self:StartDetective()
        
        print("|cff00FF00Ez-OBRotation:|r Loaded!")
    end
end)

----------------------------------------------------------------------
-- 2. MINIMAP BUTTON
----------------------------------------------------------------------
function f:CreateMinimapButton()
    local btn = CreateFrame("Button", "EzOBR_MinimapButton", Minimap)
    btn:SetSize(33, 33)
    btn:SetFrameLevel(8)
    btn:SetFrameStrata("MEDIUM")
    
    local icon = btn:CreateTexture(nil, "BACKGROUND")
    icon:SetTexture("Interface\\Icons\\Trade_Engineering")
    icon:SetSize(21, 21)
    icon:SetPoint("CENTER")
    icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
    
    local border = btn:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(56, 56)
    border:SetPoint("TOPLEFT")
    
    btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    local function UpdatePos()
        local angle = math.rad(EzOBR_Config.minimapPos)
        -- Radius for proper edge positioning
        local radius = (Minimap:GetWidth() / 2) + 5
        btn:ClearAllPoints()
        btn:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
    end
    
    btn:RegisterForDrag("LeftButton")
    btn:SetScript("OnDragStart", function(self) self:LockHighlight() self.isDragging = true end)
    btn:SetScript("OnDragStop", function(self) self:UnlockHighlight() self.isDragging = false end)
    btn:SetScript("OnUpdate", function(self)
        if self.isDragging then
            local mx, my = Minimap:GetCenter()
            local cx, cy = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale()
            EzOBR_Config.minimapPos = math.deg(math.atan2(cy / scale - my, cx / scale - mx))
            UpdatePos()
        end
    end)
    
    btn:RegisterForClicks("AnyUp")
    btn:SetScript("OnClick", function() 
        local panel = _G["EzOBR_OptionsPanel"]
        if panel then
            if panel:IsShown() then
                panel:Hide()
            else
                panel:ClearAllPoints()
                panel:SetPoint("CENTER")
                panel:Show()
            end
        end
    end)
    
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("Ez-OBRotation")
        GameTooltip:AddLine("Left-click to toggle settings", 1, 1, 1)
        GameTooltip:AddLine("Drag to move", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", GameTooltip_Hide)

    UpdatePos()
end

----------------------------------------------------------------------
-- 3. SETTINGS MENU
----------------------------------------------------------------------
function f:CreateMenu()
    local panel = CreateFrame("Frame", "EzOBR_OptionsPanel", UIParent, "BackdropTemplate")
    panel.name = "Ez-OBRotation"
    panel:SetSize(400, 420)
    panel:SetPoint("CENTER")
    panel:Hide()
    panel:SetFrameStrata("DIALOG")
    
    table.insert(UISpecialFrames, "EzOBR_OptionsPanel")
    
    panel:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
    })
    panel:SetBackdropColor(0, 0, 0, 1)
    
    panel:SetMovable(true)
    panel:EnableMouse(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", panel.StartMoving)
    panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
    
    local closeBtn = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -5, -5)
    
    settingsCategory = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
    Settings.RegisterAddOnCategory(settingsCategory)

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -20)
    title:SetText("Ez-OBRotation Settings")

    local modeText = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    modeText:SetPoint("TOP", title, "BOTTOM", 0, -10)
    modeText:SetText(usingBartender and "|cff00FF00Mode: Bartender4 detected|r" or "|cff00FF00Mode: Blizzard Action Bars|r")

    local slider = CreateFrame("Slider", "EzOBR_SizeSlider", panel, "OptionsSliderTemplate")
    slider:SetPoint("TOP", modeText, "BOTTOM", 0, -30)
    slider:SetWidth(200)
    slider:SetMinMaxValues(10, 50)
    slider:SetValue(EzOBR_Config.fontSize)
    slider:SetValueStep(1)
    _G[slider:GetName() .. 'Low']:SetText("10")
    _G[slider:GetName() .. 'High']:SetText("50")
    _G[slider:GetName() .. 'Text']:SetText("Font Size: " .. EzOBR_Config.fontSize)
    
    slider:SetScript("OnValueChanged", function(self, value)
        EzOBR_Config.fontSize = math.floor(value)
        _G[self:GetName() .. 'Text']:SetText("Font Size: " .. EzOBR_Config.fontSize)
    end)

    local colorBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    colorBtn:SetPoint("TOP", slider, "BOTTOM", 0, -25)
    colorBtn:SetSize(120, 25)
    colorBtn:SetText("Text Color")
    
    local colorPreview = panel:CreateTexture(nil, "ARTWORK")
    colorPreview:SetSize(20, 20)
    colorPreview:SetPoint("LEFT", colorBtn, "RIGHT", 10, 0)
    colorPreview:SetColorTexture(EzOBR_Config.r, EzOBR_Config.g, EzOBR_Config.b)

    colorBtn:SetScript("OnClick", function()
        local function OnColorSelect()
            local r, g, b = ColorPickerFrame:GetColorRGB()
            EzOBR_Config.r, EzOBR_Config.g, EzOBR_Config.b = r, g, b
            colorPreview:SetColorTexture(r, g, b)
        end
        ColorPickerFrame:SetupColorPickerAndShow({
            r = EzOBR_Config.r, g = EzOBR_Config.g, b = EzOBR_Config.b,
            swatchFunc = OnColorSelect,
        })
    end)

    local dropLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    dropLabel:SetPoint("TOP", colorBtn, "BOTTOM", -40, -20)
    dropLabel:SetText("Text Position:")

    local drop = CreateFrame("Frame", "EzOBR_PosDropdown", panel, "UIDropDownMenuTemplate")
    drop:SetPoint("LEFT", dropLabel, "RIGHT", -10, -2)
    local function InitDropdown(self, level)
        local info = UIDropDownMenu_CreateInfo()
        for k, v in pairs(anchorMap) do
            info.text = k
            info.func = function() 
                EzOBR_Config.anchor = v
                UIDropDownMenu_SetText(drop, k)
            end
            info.checked = (EzOBR_Config.anchor == v)
            UIDropDownMenu_AddButton(info, level)
        end
    end
    UIDropDownMenu_Initialize(drop, InitDropdown)
    UIDropDownMenu_SetWidth(drop, 100)
    UIDropDownMenu_SetText(drop, reverseAnchorMap[EzOBR_Config.anchor] or "Top Right")

    -- Font Selection Buttons
    local fontLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    fontLabel:SetPoint("TOP", dropLabel, "BOTTOM", 40, -30)
    fontLabel:SetText("Font Style:")
    
    local fontButtons = {
        {"Luciole Bold", fontBold},        
        {"Luciole Regular", fontReg},      
        {"Standard (Friz)", "Fonts\\FRIZQT__.TTF"}, 
        {"Combat (Skurri)", "Fonts\\SKURRI.TTF"},   
    }
    
    local lastFontBtn = nil
    for i, fontData in ipairs(fontButtons) do
        local fbtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
        if i == 1 then
            fbtn:SetPoint("TOP", fontLabel, "BOTTOM", 0, -5)
        else
            fbtn:SetPoint("TOP", lastFontBtn, "BOTTOM", 0, -3)
        end
        fbtn:SetSize(140, 22)
        fbtn:SetText(fontData[1])
        
        fbtn:SetScript("OnClick", function() 
            EzOBR_Config.fontPath = fontData[2]
            print("|cff00FF00Ez-OBRotation:|r Font changed to " .. fontData[1])
        end)
        lastFontBtn = fbtn
    end

    SLASH_EZOBR1 = "/ezobr"
    SlashCmdList["EZOBR"] = function() 
        if panel:IsShown() then
            panel:Hide()
        else
            panel:Show()
        end
    end
    
    -- Debug command
    SLASH_EZOBRDEBUG1 = "/ezobrdebug"
    SlashCmdList["EZOBRDEBUG"] = function()
        print("|cff00FF00=== Ez-OBRotation Debug ===|r")
        print("Using Bartender:", C_AddOns.IsAddOnLoaded("Bartender4"))
        
        local found = false
        
        -- Search Blizzard default buttons for AssistedCombatRotationFrame
        local barPrefixes = {
            "ActionButton", 
            "MultiBarBottomLeftButton", 
            "MultiBarBottomRightButton",
            "MultiBarRightButton", 
            "MultiBarLeftButton", 
            "MultiBar5Button",
            "MultiBar6Button", 
            "MultiBar7Button",
            "MultiBar8Button",
        }
        for _, prefix in ipairs(barPrefixes) do
            for i = 1, 12 do
                local btn = _G[prefix..i]
                if btn and btn:IsVisible() and btn.AssistedCombatRotationFrame and btn.AssistedCombatRotationFrame:IsShown() then
                    found = true
                    print("Found SBA on Blizzard:", prefix..i)
                end
            end
        end
        
        -- Search Bartender buttons
        for i = 1, 180 do
            local btn = _G["BT4Button"..i]
            if btn and btn:IsVisible() and btn.AssistedCombatRotationFrame and btn.AssistedCombatRotationFrame:IsShown() then
                found = true
                print("Found SBA on Bartender: BT4Button"..i)
            end
        end
        
        -- Search ALL visible frames for AssistedCombatRotationFrame (the yellow arrow)
        print("|cffFFFF00Searching ALL frames for AssistedCombatRotationFrame...|r")
        local searchCount = 0
        for frameName, frame in pairs(_G) do
            if type(frame) == "table" and type(frame.IsVisible) == "function" then
                if frame.AssistedCombatRotationFrame then
                    searchCount = searchCount + 1
                    local isShown = frame.AssistedCombatRotationFrame:IsShown()
                    print("Frame with AssistedCombatRotationFrame:", frameName, "- Shown:", isShown)
                    if frame:IsVisible() and isShown then
                        print("  ^ THIS ONE IS THE SBA BUTTON!")
                        
                        -- Get detailed info about this button
                        local btn = frame
                        print("  - btn.action:", btn.action)
                        print("  - btn._state_action:", btn._state_action)
                        
                        if btn.GetAttribute then
                            print("  - GetAttribute('action'):", btn:GetAttribute("action"))
                        end
                        
                        if btn.CalculateAction then
                            local ok, result = pcall(btn.CalculateAction, btn)
                            print("  - CalculateAction():", ok and result or "FAILED")
                        end
                        
                        -- Try to get spell info
                        local actionSlot = btn.action or btn._state_action or (btn.GetAttribute and btn:GetAttribute("action"))
                        if actionSlot then
                            local actionType, id = GetActionInfo(actionSlot)
                            print("  - ActionInfo:", actionType, id)
                            if actionType == "spell" and id then
                                local name = C_Spell.GetSpellName(id)
                                print("  - Spell Name:", name)
                                local slots = C_ActionBar.FindSpellActionButtons(id)
                                if slots then
                                    print("  - Spell is on slots:", table.concat(slots, ", "))
                                    for _, slot in pairs(slots) do
                                        local cmd = nil
                                        if slot <= 12 then cmd = "ACTIONBUTTON"..slot
                                        elseif slot >= 61 and slot <= 72 then cmd = "MULTIACTIONBAR1BUTTON"..(slot-60)
                                        elseif slot >= 49 and slot <= 60 then cmd = "MULTIACTIONBAR2BUTTON"..(slot-48)
                                        elseif slot >= 25 and slot <= 36 then cmd = "MULTIACTIONBAR3BUTTON"..(slot-24)
                                        elseif slot >= 37 and slot <= 48 then cmd = "MULTIACTIONBAR4BUTTON"..(slot-36)
                                        elseif slot >= 73 and slot <= 84 then cmd = "MULTIACTIONBAR5BUTTON"..(slot-72)
                                        elseif slot >= 85 and slot <= 96 then cmd = "MULTIACTIONBAR6BUTTON"..(slot-84)
                                        end
                                        if cmd then
                                            local key = GetBindingKey(cmd)
                                            print("    Slot", slot, "->", cmd, "-> Key:", key or "NONE")
                                        end
                                    end
                                else
                                    print("  - Spell NOT found on any action bar!")
                                end
                            end
                        else
                            print("  - Could not get action slot!")
                        end
                    end
                end
            end
        end
        print("Total frames with AssistedCombatRotationFrame:", searchCount)
        
        if not found and searchCount == 0 then
            print("|cffFF0000No SBA button found anywhere!|r")
        end
    end
end

----------------------------------------------------------------------
-- 4. KEYBIND DETECTION LOGIC
-- 
-- Goal: 
-- 1. Find the SBA button (has AssistedCombatHighlightFrame - golden ring)
-- 2. Hide the yellow arrow on it
-- 3. Get the spell currently displayed on that button
-- 4. Find the keybind for that spell on the action bars
-- 5. Show that keybind on the SBA button
----------------------------------------------------------------------
function f:StartDetective()
    
    local function GetBindCommand(slot)
        if not slot then return nil end
        if slot <= 12 then return "ACTIONBUTTON"..slot end
        if slot >= 61 and slot <= 72 then return "MULTIACTIONBAR1BUTTON"..(slot-60) end
        if slot >= 49 and slot <= 60 then return "MULTIACTIONBAR2BUTTON"..(slot-48) end
        if slot >= 25 and slot <= 36 then return "MULTIACTIONBAR3BUTTON"..(slot-24) end
        if slot >= 37 and slot <= 48 then return "MULTIACTIONBAR4BUTTON"..(slot-36) end
        if slot >= 73 and slot <= 84 then return "MULTIACTIONBAR5BUTTON"..(slot-72) end
        if slot >= 85 and slot <= 96 then return "MULTIACTIONBAR6BUTTON"..(slot-84) end
        if slot >= 97 and slot <= 108 then return "MULTIACTIONBAR7BUTTON"..(slot-96) end
        if slot >= 109 and slot <= 120 then return "MULTIACTIONBAR8BUTTON"..(slot-108) end
        return nil
    end

    -- Find keybind for a spell by searching all action bars
    local function FindKeyForSpell(spellID)
        if not spellID then return nil end
        local slots = C_ActionBar.FindSpellActionButtons(spellID)
        if slots then
            for _, slot in pairs(slots) do
                local command = GetBindCommand(slot)
                if command then
                    local key = GetBindingKey(command)
                    if key then return key end
                end
            end
        end
        return nil
    end

    -- Check if a button is the SBA button (has the yellow arrow - AssistedCombatRotationFrame)
    local function IsSBAButton(btn)
        if not btn then return false end
        if not btn:IsVisible() then return false end
        -- The SBA button has AssistedCombatRotationFrame (the yellow arrow)
        if btn.AssistedCombatRotationFrame and btn.AssistedCombatRotationFrame:IsShown() then
            return true
        end
        return false
    end

    -- Find the SBA button - check ALL buttons
    local function FindSBAButton()
        -- Check Blizzard default buttons
        local barPrefixes = {
            "ActionButton", 
            "MultiBarBottomLeftButton", 
            "MultiBarBottomRightButton",
            "MultiBarRightButton", 
            "MultiBarLeftButton", 
            "MultiBar5Button",
            "MultiBar6Button",
            "MultiBar7Button",
            "MultiBar8Button",
        }
        for _, prefix in ipairs(barPrefixes) do
            for i = 1, 12 do
                local btn = _G[prefix..i]
                if btn and IsSBAButton(btn) then 
                    return btn 
                end
            end
        end
        -- Then check Bartender buttons
        for i = 1, 180 do
            local btn = _G["BT4Button"..i]
            if btn and IsSBAButton(btn) then 
                return btn 
            end
        end
        return nil
    end

    -- Get the spell ID currently displayed on a button
    local function GetButtonSpellID(btn)
        if not btn then return nil end
        
        -- For Blizzard buttons, use btn.action directly
        if btn.action then
            local actionType, id = GetActionInfo(btn.action)
            if actionType == "spell" then
                return id
            elseif actionType == "macro" then
                local spellID = GetMacroSpell(id)
                return spellID
            end
        end
        
        -- For Bartender buttons - try multiple methods
        
        -- Method 1: GetSpellId (some Bartender versions)
        if btn.GetSpellId then
            local ok, result = pcall(btn.GetSpellId, btn)
            if ok and result and result > 0 then return result end
        end
        
        -- Method 2: _state_action (Bartender internal)
        if btn._state_action then
            local actionType, id = GetActionInfo(btn._state_action)
            if actionType == "spell" then
                return id
            elseif actionType == "macro" then
                local spellID = GetMacroSpell(id)
                return spellID
            end
        end
        
        -- Method 3: Get action from the button's action attribute
        if btn.GetAttribute then
            local actionSlot = btn:GetAttribute("action")
            if actionSlot and actionSlot > 0 then
                local actionType, id = GetActionInfo(actionSlot)
                if actionType == "spell" then
                    return id
                elseif actionType == "macro" then
                    local spellID = GetMacroSpell(id)
                    return spellID
                end
            end
        end
        
        -- Method 4: Try CalculateAction (Bartender)
        if btn.CalculateAction then
            local ok, actionSlot = pcall(btn.CalculateAction, btn)
            if ok and actionSlot and actionSlot > 0 then
                local actionType, id = GetActionInfo(actionSlot)
                if actionType == "spell" then
                    return id
                elseif actionType == "macro" then
                    local spellID = GetMacroSpell(id)
                    return spellID
                end
            end
        end
        
        -- Method 5: Check the icon texture and try to find the spell
        if btn.icon then
            local texture = btn.icon:GetTexture()
            if texture then
                -- This is a fallback - try to identify spell by texture
                -- Not ideal but might work
            end
        end
        
        return nil
    end

    local hookedButtons = {}
    
    local function HideGlows(btn)
        if btn.SpellActivationAlert then 
            btn.SpellActivationAlert:SetAlpha(0) 
        end
        if btn.AssistedCombatRotationFrame then 
            btn.AssistedCombatRotationFrame:SetAlpha(0)
            
            if not hookedButtons[btn] then
                hookedButtons[btn] = true
                local frame = btn.AssistedCombatRotationFrame
                hooksecurefunc(frame, "Show", function(self)
                    if btn.EzOBR_Text and btn.EzOBR_Text:IsShown() then
                        self:SetAlpha(0)
                    end
                end)
                local origSetAlpha = frame.SetAlpha
                frame.SetAlpha = function(self, alpha)
                    if btn.EzOBR_Text and btn.EzOBR_Text:IsShown() then
                        origSetAlpha(self, 0)
                    else
                        origSetAlpha(self, alpha)
                    end
                end
            end
        end
    end

    local function RestoreGlows(btn)
        if btn.SpellActivationAlert then 
            btn.SpellActivationAlert:SetAlpha(1) 
        end
        if btn.AssistedCombatRotationFrame then 
            btn.AssistedCombatRotationFrame:SetAlpha(1)
        end
    end

    local lastActiveButton = nil
    local lastKeyText = nil
    
    local function FormatKey(key)
        if not key then return nil end
        return key:gsub("SHIFT%-", "s"):gsub("CTRL%-", "c"):gsub("ALT%-", "a")
    end

    C_Timer.NewTicker(0.03, function()
        -- Step 1: Find the SBA button (the one with the golden ring)
        local sbaButton = FindSBAButton()

        if lastActiveButton and lastActiveButton ~= sbaButton then
            if lastActiveButton.EzOBR_Text then 
                lastActiveButton.EzOBR_Text:Hide() 
            end
            RestoreGlows(lastActiveButton)
            lastKeyText = nil
        end

        lastActiveButton = sbaButton

        if not sbaButton then return end

        -- Step 2: Hide the yellow arrow
        HideGlows(sbaButton)

        -- Step 3: Create/get text overlay
        if not sbaButton.EzOBR_Text then
            sbaButton.EzOBR_Text = sbaButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            sbaButton.EzOBR_Text:SetDrawLayer("OVERLAY", 7)
        end
        
        local text = sbaButton.EzOBR_Text
        text:Show()
        
        if not pcall(text.SetFont, text, EzOBR_Config.fontPath, EzOBR_Config.fontSize, "OUTLINE") then
            text:SetFont("Fonts\\FRIZQT__.TTF", EzOBR_Config.fontSize, "OUTLINE")
        end
        text:SetTextColor(EzOBR_Config.r, EzOBR_Config.g, EzOBR_Config.b, 1)

        text:ClearAllPoints()
        local point = EzOBR_Config.anchor or "TOPRIGHT"
        local offsets = anchorOffsets[point] or anchorOffsets.TOPRIGHT
        text:SetPoint(point, sbaButton, point, offsets[1], offsets[2])

        -- Step 4: Get the spell currently displayed on the SBA button
        local spellID = GetButtonSpellID(sbaButton)
        
        -- Step 5: Find the keybind for this spell on the action bars
        local foundKey = FindKeyForSpell(spellID)
        local formattedKey = FormatKey(foundKey) or ""
        
        if formattedKey ~= lastKeyText then
            text:SetText(formattedKey)
            lastKeyText = formattedKey
        end
    end)
end
