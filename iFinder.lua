iFinder = {};
Constants = getglobal("Constants")
Utils = getglobal("Utils")
-- ifinder
--      Messages : {instance id => {name => "stored message ;:; time"} }
--      IncludeChinese : include chinese messasges

--      iFinderFrame (UI) : 
--          InstanceListFrame
--          MessageListFrame

function iFinder.OnLoad()
    iFinder.Messages = {};
    iFinder.SelectedInstances = {};
    this:RegisterEvent("ADDON_LOADED");
    this:RegisterEvent("CHAT_MSG_CHANNEL");
    -- this:RegisterEvent("PLAYER_REGEN_ENABLED");
    -- this:RegisterEvent("PLAYER_REGEN_DISABLED");
end

function iFinder.OnEvent(event)
    if event == "CHAT_MSG_CHANNEL" then
        local messageText = arg1
        local messagerName = arg2
        -- arg1 message, arg2 name, arg9 channel
        for _, lfmToken in pairs(Constants.LFM_ARGS) do
            messageText = "黑石深渊---来治疗和坦克, 3=2"
            if Utils.subStringCount(messageText, lfmToken, false) > 0 then
                for instanceName, instanceObj in pairs(Constants.INSTANCES) do
                    if Utils.containsValueInTable(iFinder.SelectedInstances, instanceName) then
                        for _, alias in pairs(instanceObj.aka) do
                            if Utils.subStringCount(messageText, alias, false) > 0 then
                                iFinder.Messages[messagerName] = {time = math.floor(GetTime()), message = messageText, instance = instanceName}
                                createMessageListElement(iFinderFrame.MessageListFrame, instanceName, messageText, messagerName, nil, iFinderFrame.MessageListFrame:GetNumChildren())
                                return
                            end
                        end
                    end
                end
            end
        end
    end

    if event == "ADDON_LOADED" then
        createMinimapButton();
        createFinderWindow();
    end
end


function createMinimapButton()
    if MinimapPos == nil or type(MinimapPos) == "number" then
        MinimapPos = {}
        MinimapPos.x, MinimapPos.y = {-180,-17}
    end
    iFinderminimapButton = CreateFrame("Button", "iFinderMap", Minimap)
    iFinderminimapButton:SetFrameStrata("HIGH")
    iFinderminimapButton:SetWidth(32)
    iFinderminimapButton:SetHeight(32)
    iFinderminimapButton:ClearAllPoints()
    iFinderminimapButton:SetPoint("TOPLEFT", Minimap,"TOPLEFT",MinimapPos.x,MinimapPos.y)

    iFinderminimapButton:SetHighlightTexture("Interface\\MINIMAP\\UI-Minimap-ZoomButton-Highlight", "ADD")
    iFinderminimapButton:RegisterForDrag("RightButton")
    iFinderminimapButton.texture = iFinderminimapButton:CreateTexture(nil, "BUTTON")
    iFinderminimapButton.texture:SetTexture("Interface\\AddOns\\iFinder\\media\\icon")
    iFinderminimapButton.texture:SetPoint("CENTER", iFinderminimapButton)
    iFinderminimapButton.texture:SetWidth(20)
    iFinderminimapButton.texture:SetHeight(20)

    iFinderminimapButton.border = iFinderminimapButton:CreateTexture(nil, "BORDER")
    iFinderminimapButton.border:SetTexture("Interface\\MINIMAP\\MiniMap-TrackingBorder")
    iFinderminimapButton.border:SetPoint("TOPLEFT", iFinderminimapButton.texture, -6, 5)
    iFinderminimapButton.border:SetWidth(52)
    iFinderminimapButton.border:SetHeight(52)

    iFinderminimapButton:SetScript("OnMouseDown", function()
        point, relativeTo, relativePoint, xOffset, yOffset = this.texture:GetPoint(1)
        this.texture:SetPoint(point, relativeTo, relativePoint, xOffset + 2, yOffset - 2)
    end);
    iFinderminimapButton:SetScript("OnLeave", function(self, button)
        this.texture:SetPoint("CENTER", iFinderminimapButton,0,0)
    end);
    iFinderminimapButton:SetScript("OnMouseUp", function()
        if arg1 == "LeftButton" then
            if iFinderFrame:IsShown() then
                closeFinder()
            else
                iFinderFrame:Show()
            end
        end
        this.texture:SetPoint("CENTER", iFinderminimapButton)
    end);
    iFinderminimapButton:SetScript("OnDragStart", function()
        miniDrag = true
    end)
    iFinderminimapButton:SetScript("OnDragStop", function()
        miniDrag = false
    end)
    iFinderminimapButton:SetScript("OnUpdate", function()
        if miniDrag then
            local xpos,ypos = GetCursorPosition();
            local xmin,ymin,xm,ym = Minimap:GetLeft(), Minimap:GetBottom(), Minimap:GetRight(), Minimap:GetTop();
            local scale = Minimap:GetEffectiveScale();
            local xdelta, ydelta = (xm - xmin + 5)/2*scale, (ym - ymin + 5) /2 * scale;
            xpos = xmin*scale-xpos+xdelta;
            ypos = ypos-ymin*scale-ydelta;
            local angle = math.deg(math.atan2(ypos,xpos));
            local   x,y =0,0;
            if (Squeenix or (simpleMinimap_Skins and simpleMinimap_Skins:GetShape() == "square")
                        or (pfUI and pfUI_config["disabled"]["minimap"] ~= "1")) then
                x = math.max(-xdelta, math.min((xdelta*1.5) * cos(angle), xdelta))
                y = math.max(-ydelta, math.min((ydelta*1.5) * sin(angle), ydelta))
            else
                x= cos(angle)*xdelta
                y= sin(angle)*ydelta
            end
            local sc= this:GetEffectiveScale()
            MinimapPos.x = (xdelta-x)/sc - 17
            MinimapPos.y = (y-ydelta)/sc + 17
            this:SetPoint("TOPLEFT", Minimap, "TOPLEFT", MinimapPos.x , MinimapPos.y);
        end
    end)
end

function createFinderWindow()
    iFinder.frameBackdrop = {
      -- path to the background texture
      bgFile = "Interface\\AddOns\\iFinder\\media\\white",  
      -- path to the border texture
      edgeFile = "Interface\\AddOns\\iFinder\\media\\border",
      -- true to repeat the background texture to fill the frame, false to scale it
      tile = true,
      -- size (width or height) of the square repeating background tiles (in pixels)
      tileSize = 8,
      -- thickness of edge segments and square size of edge corners (in pixels)
      edgeSize = 12,
      -- distance from the edges of the frame to those of the background texture (in pixels)
      insets = {
        left = 1,
        right = 1,
        top = 1,
        bottom = 1
      }
    }

    iFinderFrame = CreateFrame("Frame","iFinderFrame",UIParent)
    iFinderFrame:SetWidth(700)
    iFinderFrame:SetHeight(600)
    iFinderFrame:ClearAllPoints()
    iFinderFrame:SetPoint("CENTER", UIParent,"CENTER") 
    iFinderFrame:SetFrameStrata("FULLSCREEN_DIALOG")
    iFinderFrame:SetMovable(true)
    iFinderFrame:EnableMouse(true)
    iFinderFrame:SetBackdrop(iFinder.frameBackdrop)
    iFinderFrame:SetBackdropColor(15/255, 15/255, 15/255, 0.7)
    iFinderFrame:SetScript("OnMouseDown", function(self, button)
        iFinderFrame:StartMoving()
    end)
    iFinderFrame:SetScript("OnMouseUp", function(self, button)
        iFinderFrame:StopMovingOrSizing()
    end)
    
    iFinderFrame.closeButtonX = CreateFrame("Button", "iFinderButton", iFinderFrame,"UIPanelCloseButton")
    iFinderFrame.closeButtonX:SetPoint("TOPRIGHT", iFinderFrame, "TOPRIGHT", 2, 2)
    iFinderFrame.closeButtonX:SetScript("OnClick", function()
        closeFinder()
    end)

    -- create Options Frame
    iFinderFrame.optionsFrame = createOptionsFrame(iFinderFrame)
    
    -- create Options Button
    iFinderFrame.optionsButton = createButton("      Options       ", "optionButton", 14, iFinderFrame)
    iFinderFrame.optionsButton:SetPoint("TOPLEFT", iFinderFrame, "TOPLEFT", 12, -8)
    iFinderFrame.optionsButton:SetScript("OnClick", function()
        if iFinderFrame.optionsFrame:IsShown() then
            iFinderFrame.optionsFrame:Hide()
        else
            iFinderFrame.optionsFrame:Show()
        end
    end)

    -- create Instance list frame
    iFinderFrame.InstanceListFrame = CreateFrame("ScrollFrame","iFinderInstanceListFrame", iFinderFrame)
    iFinderFrame.InstanceListFrame:ClearAllPoints()
    iFinderFrame.InstanceListFrame:SetPoint("LEFT", iFinderFrame, "LEFT", 5, 8)
    iFinderFrame.InstanceListFrame:SetFrameLevel(iFinderFrame:GetFrameLevel()+1) 
    iFinderFrame.InstanceListFrame:SetWidth(238)
    iFinderFrame.InstanceListFrame:SetHeight(iFinderFrame:GetHeight() - 80)
    iFinderFrame.InstanceListFrame:EnableMouseWheel(true)
    iFinderFrame.InstanceListFrame:SetBackdrop(iFinder.frameBackdrop)
    iFinderFrame.InstanceListFrame:SetBackdropColor(20/255, 20/255, 20/255, 0.9)

    -- populate instance list frame
    iFinderFrame.instanceList = {}
    local number = 0
    for instanceName, _  in pairs(Constants.INSTANCES) do
        instanceCheckbox = createInstanceListElement(iFinderFrame.InstanceListFrame, instanceName, number)
        table.insert(iFinderFrame.instanceList, instanceCheckbox)
        number = number + 1
    end

    -- create Apply button
    iFinderFrame.applyButton = createButton("      Apply       ", "applyButton", 14, iFinderFrame)
    iFinderFrame.applyButton:SetPoint("BOTTOMLEFT", iFinderFrame, "BOTTOMLEFT", 80, 14)
    iFinderFrame.applyButton:SetScript("OnClick", function()
        iFinder.SelectedInstances = {}
        for _, instanceCheckbox in pairs(iFinderFrame.instanceList) do
            if Utils.toboolean(instanceCheckbox:GetChecked()) == true then
                table.insert(iFinder.SelectedInstances, instanceCheckbox:GetName())
            end
        end
    end)

    -- create message list frame
    iFinderFrame.MessageListFrame = CreateFrame("ScrollFrame","iFinderMessageListFrame", iFinderFrame)
    iFinderFrame.MessageListFrame:ClearAllPoints()
    iFinderFrame.MessageListFrame:SetPoint("LEFT", iFinderFrame, "LEFT", iFinderFrame.InstanceListFrame:GetWidth() + 8, -9)
    iFinderFrame.MessageListFrame:SetFrameLevel(iFinderFrame:GetFrameLevel()+1) 
    iFinderFrame.MessageListFrame:SetWidth(iFinderFrame:GetWidth() - iFinderFrame.InstanceListFrame:GetWidth() - 8 - 4)
    iFinderFrame.MessageListFrame:SetHeight(iFinderFrame:GetHeight() - 45)
    iFinderFrame.MessageListFrame:EnableMouseWheel(true)
    iFinderFrame.MessageListFrame:SetBackdrop(iFinder.frameBackdrop)
    iFinderFrame.MessageListFrame:SetBackdropColor(20/255, 20/255, 20/255, 0.9)
end

function createButton(text, name, textSize, parentFrame)
    newButton = CreateFrame("Button", name, parentFrame, "UIPanelButtonTemplate2")
    -- newButton:SetFrameLevel(100)
    newButton:SetText(text)
    newButton:SetHeight(newButton:GetTextHeight())
    newButton:SetWidth(newButton:GetTextWidth())
    newButton:SetFont("Fonts\\FRIZQT__.TTF", textSize)
    return newButton
end

function createMessageListElement(parentFrame, instanceName, text, playerName, tags, index)
    -- if the message list frame is full: delete the oldest message
    newMessageHeight = 16
    newMessageY = -1*newMessageHeight*index - 10
    _, __, ___, ____, messageListY = iFinderFrame.MessageListFrame:GetPoint()
    if newMessageY < messageListY - iFinderFrame.MessageListFrame:GetHeight() then
        -- TODO: resize
        DEFAULT_CHAT_FRAME:AddMessage('|c00ffff00' .. 'message element OVERFLOWING' .. ' |r');
    end

    local newMessageElement = CreateFrame("Button", "messageElement", parentFrame)
    newMessageElement:SetFont("Interface\\AddOns\\iFinder\\media\\simhei.TTF", 18)
    newMessageElement:SetText(text)
    newMessageElement:SetTextColor(Constants.COLORS.YELLOW[1], Constants.COLORS.YELLOW[2], Constants.COLORS.YELLOW[3])
    newMessageElement:SetWidth(newMessageElement:GetTextWidth())
    newMessageElement:SetHeight(newMessageHeight) -- height
    newMessageElement:SetFrameLevel(parentFrame:GetFrameLevel()+1)
    newMessageElement:EnableMouse(false)
    newMessageElement:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 6, newMessageY)

    local replyButton = createButton(" reply ", playerName, 12, parentFrame)
    replyButton:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 20 + newMessageElement:GetTextWidth(), newMessageY - 2)
    replyButton:SetScript("OnClick", function()
        -- TODO open reply frame with name of person to default
        DEFAULT_CHAT_FRAME:AddMessage('|c00ffff00' .. tostring(this:GetName()) .. ' |r');
    end)

    return newMessageElement
end

function createInstanceListElement(parentFrame, text, index)
    label = parentFrame:CreateFontString(nil, "ARTWORK")
    label:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 6, -1*14*index - 14)
    label:SetFont("Fonts\\FRIZQT__.TTF", 12)
    label:SetText(text)
    label:SetTextColor(Constants.COLORS["YELLOW"][1], Constants.COLORS["YELLOW"][2], Constants.COLORS["YELLOW"][3])
    label:SetWidth(label:GetStringWidth())
    label:SetHeight(12)

    checkbox = CreateFrame("CheckButton", text, parentFrame, "UICheckButtonTemplate")
    checkbox:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 6 + label:GetWidth() + 4, -1*14*index - 14)
    checkbox:SetHeight(16)
    checkbox:SetWidth(16)
    return checkbox
end

function createOptionsFrame(parentFrame)   
    optionsFrame = CreateFrame("Frame", nil, parentFrame)
    optionsFrame:SetWidth(300)
    optionsFrame:SetHeight(130)
    optionsFrame:SetPoint("TOP", parentFrame, "TOP", 0, 0)
    -- optionsFrame:SetPoint("BOTTOM", parentFrame, "TOP", 0, -1 * GetScreenHeight()/3)
    optionsFrame:SetBackdrop(iFinder.frameBackdrop)
    optionsFrame:SetBackdropColor(40/255, 40/255, 40/255, 0.8)
    optionsFrame:EnableMouse(true)
    optionsFrame:SetMovable(true)
    optionsFrame:SetFrameLevel(parentFrame:GetFrameLevel() + 4)
    optionsFrame:SetClampedToScreen(true)
    optionsFrame:SetScript("OnMouseDown", function()
        this:StartMoving()
    end)
    optionsFrame:SetScript("OnMouseUp", function()
        this:StopMovingOrSizing()
    end)
    optionsFrame:Hide()
    return optionsFrame
end

function showFinder()
    iFinderFrame:Show()
end

function closeFinder()
    iFinderFrame.optionsFrame:Hide()
    iFinderFrame:Hide()
end