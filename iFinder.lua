iFinder = {};
Constants = getglobal("Constants")
Utils = getglobal("Utils")
iFinder.Messages = {}
iFinder.ScrollPosition = 0

-- iFinder
--      Messages : {{sender = "character", time = 123, message = "LF1M dps BRD Lava runs", instance = "Blackrock Depths", frame = 0x123, lineElements = {0x4567, ...}
--      iFinderFrame (UI) : 
--          InstanceListFrame
--          MessageListFrame

function iFinder.OnLoad()
    iFinder.SelectedInstances = {};
    iFinder.shownMessageCount = 0; -- number of messages shown in the message lists
    this:RegisterEvent("ADDON_LOADED");
    this:RegisterEvent("CHAT_MSG_CHANNEL");
end

function iFinder.OnEvent(event)
    if event == "CHAT_MSG_CHANNEL" then
        local messageText = arg1
        local messagerName = arg2
        -- arg1 message, arg2 name, arg9 channel
        for _, lfmToken in pairs(Constants.LFM_ARGS) do
            if Utils.containsWord(messageText, lfmToken, false) then
                for instanceName, instanceObj in pairs(Constants.INSTANCES) do
                    if Utils.containsValueInTable(iFinder.SelectedInstances, instanceName) then
                        for _, alias in pairs(instanceObj.aka) do
                            if Utils.containsWord(messageText, alias, false) then
                                -- messageText = alias .. '| ' .. messageText
                                local splitMessage = Utils.splitString(messageText, 82)

                                local index = Utils.containsPairInStructsTable(iFinder.Messages, "sender", messagerName)
                                if index == nil then
                                    local newMessageListElement, messageLinesElements = createMessageListElement(iFinderFrame.MessageListFrame, instanceName, splitMessage, messagerName, nil)
                                    table.insert(iFinder.Messages, {sender = messagerName, time = math.floor(GetTime()), message = splitMessage, instance = "Dire Maul", frame = newMessageListElement, lineElements = messageLinesElements})
                                else
                                    -- remove the message element from the list frame, update with changes, then re-add it at the first position
                                    local existingMessage = iFinder.Messages[index]
                                    table.remove(iFinder.Messages, index)

                                    for lineIndex, lineElement in ipairs(existingMessage.lineElements) do
                                        if lineIndex <= table.getn(splitMessage) then
                                            lineElement:SetText(splitMessage[lineIndex])
                                        else
                                            lineElement:SetText("") -- set left over line elements to blank
                                        end
                                    end

                                    -- if need additional line elements for the updated string, create them
                                    for lineIndex, lineText in ipairs(splitMessage) do
                                        if lineIndex > table.getn(existingMessage.lineElements) then
                                            createMessageLineElement(existingMessage.frame, lineText, lineIndex, Constants.LINE_HEIGHT, "YELLOW")
                                        end
                                    end

                                    existingMessage.message = splitMessage
                                    existingMessage.time = math.floor(GetTime())
                                    existingMessage.instance = instanceName

                                    table.insert(iFinder.Messages, 1, existingMessage)
                                end

                                reDrawMessageFrame(0)
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

function reDrawMessageFrame(delta)
    if arg1 == 1 and iFinder.ScrollPosition < table.getn(iFinder.Messages) then
        iFinder.ScrollPosition = iFinder.ScrollPosition + 1
    elseif arg1 == -1 and iFinder.ScrollPosition > 0 then
        iFinder.ScrollPosition = iFinder.ScrollPosition - 1
    end

    local totalMessagesHeight = 0
    local reversedMessages = Utils.reverseTable(iFinder.Messages)

    for index, message in pairs(iFinder.Messages) do
        message.frame:Hide()
    end

    local totalHeight = 0
    for index, message in pairs(reversedMessages) do
        -- starting at the scroll position, populate the message list frame
        if index >= iFinder.ScrollPosition then
            totalHeight = totalHeight + message.frame:GetHeight()

            if totalHeight > iFinderFrame.MessageListFrame:GetHeight() then
                break -- stop drawing when the message list frame is fully populated
            end

            message.frame:Hide()
            message.frame:SetPoint("TOPLEFT", iFinderFrame.MessageListFrame, "TOPLEFT", 0, -1*totalMessagesHeight)
            message.frame:Show()
            totalMessagesHeight = totalMessagesHeight + message.frame:GetHeight()
        end
    end
    return totalMessagesHeight
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
    iFinderFrame:SetWidth(1200)
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

    local scrollframe = CreateFrame("ScrollFrame", "messageListScrollbar", iFinderFrame) -- "UIPanelScrollFrameTemplate"
    scrollframe:SetPoint("LEFT", iFinderFrame, "LEFT", iFinderFrame.InstanceListFrame:GetWidth() + 8, -9)
    scrollframe:SetBackdrop(iFinder.frameBackdrop)
    scrollframe:SetBackdropColor(20/255, 20/255, 20/255, 0.9)
    scrollframe:SetWidth(iFinderFrame:GetWidth() - iFinderFrame.InstanceListFrame:GetWidth() - 8 - 4)
    scrollframe:SetHeight(iFinderFrame:GetHeight() - 45)
    scrollframe:EnableMouseWheel(true)
    scrollframe:SetScript("OnMouseWheel", function(this, change)
        reDrawMessageFrame(arg1)
    end)

    -- create message list frame
    iFinderFrame.MessageListFrame = CreateFrame("ScrollFrame", "iFinderMessageListFrame", iFinderFrame)
    iFinderFrame.MessageListFrame:ClearAllPoints()
    iFinderFrame.MessageListFrame:SetPoint("LEFT", iFinderFrame, "LEFT", iFinderFrame.InstanceListFrame:GetWidth() + 8, -9)
    iFinderFrame.MessageListFrame:SetFrameLevel(iFinderFrame:GetFrameLevel()+1) 
    iFinderFrame.MessageListFrame:SetWidth(iFinderFrame:GetWidth() - iFinderFrame.InstanceListFrame:GetWidth() - 8 - 4)
    iFinderFrame.MessageListFrame:SetHeight(iFinderFrame:GetHeight() - 45)
    iFinderFrame.MessageListFrame:EnableMouseWheel(true)
    iFinderFrame.MessageListFrame:SetBackdrop(iFinder.frameBackdrop)
    iFinderFrame.MessageListFrame:SetBackdropColor(20/255, 20/255, 20/255, 0.9)

    scrollframe:SetScrollChild(iFinderFrame.MessageListFrame)
end

function createButton(text, name, textSize, parentFrame)
    newButton = CreateFrame("Button", name, parentFrame, "UIPanelButtonTemplate2")
    newButton:SetText(text)
    newButton:SetWidth(newButton:GetTextWidth())
    newButton:SetHeight(newButton:GetTextHeight())
    return newButton
end

function createMessageLineElement(parentFrame, text, lineNumber, lineHeight, color)
    local messageLineStringElement = parentFrame:CreateFontString(nil, "ARTWORK")
    messageLineStringElement:SetFont("Interface\\AddOns\\iFinder\\media\\simhei.TTF", 18)
    messageLineStringElement:SetText(text)
    messageLineStringElement:SetTextColor(Constants.COLORS[color][1], Constants.COLORS[color][2], Constants.COLORS[color][3])
    messageLineStringElement:SetWidth(parentFrame:GetWidth() - 100)
    messageLineStringElement:SetHeight(lineHeight)
    messageLineStringElement:SetJustifyH("LEFT")
    messageLineStringElement:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 6, -1*(lineNumber - 1)*lineHeight)
    return messageLineStringElement
end

function createMessageListElement(parentFrame, instanceName, messageLines, playerName, tags, yCoord)
    local newMessageElementFrame = CreateFrame("Frame", nil, parentFrame)
    newMessageElementFrame:SetWidth(parentFrame:GetWidth())
    newMessageElementFrame:SetHeight(table.getn(messageLines) * Constants.LINE_HEIGHT)
    newMessageElementFrame:SetWidth(parentFrame:GetWidth() - 100)
    newMessageElementFrame:EnableMouse(true)

    -- local color = "YELLOW"
    -- if math.mod(iFinder.shownMessageCount, 2) == 1 then
    --     color = "WHITE"
    -- end

    local messageLineElements = {}
    for lineNumber, messageLine in ipairs(messageLines) do
        local messageLineStringElement = createMessageLineElement(newMessageElementFrame, messageLine, lineNumber, Constants.LINE_HEIGHT, "YELLOW")
        
        -- local messageLineStringElement = newMessageElementFrame:CreateFontString(nil, "ARTWORK")
        -- messageLineStringElement:SetFont("Interface\\AddOns\\iFinder\\media\\simhei.TTF", 18)
        -- messageLineStringElement:SetText(messageLine)
        -- messageLineStringElement:SetTextColor(Constants.COLORS[color][1], Constants.COLORS[color][2], Constants.COLORS[color][3])
        -- messageLineStringElement:SetWidth(parentFrame:GetWidth() - 100)
        -- messageLineStringElement:SetHeight(LINE_HEIGHT)
        -- messageLineStringElement:SetJustifyH("LEFT")
        -- messageLineStringElement:SetPoint("TOPLEFT", newMessageElementFrame, "TOPLEFT", 6, -1*(lineNumber - 1)*LINE_HEIGHT)
        table.insert(messageLineElements, messageLineStringElement)
    end

    iFinder.shownMessageCount = iFinder.shownMessageCount + 1

    local replyButton = createButton("  reply  ", playerName, 12, newMessageElementFrame)
    replyButton:SetPoint("TOPLEFT", newMessageElementFrame, "TOPLEFT", newMessageElementFrame:GetWidth() - 40, -2)
    replyButton:SetScript("OnClick", function()
        -- close existing visible reply frame (if exists)
        if replyFrame ~= nil and replyFrame:IsShown() then
            replyFrame:Hide()
        end
        -- if the message recipient is different that the existing one then create new reply frame
        if replyFrame == nil or tostring(replyFrame:GetName()) ~= playerName then
            replyFrame = createReplyFrame(parentFrame, x, y, playerName, "Mage 50+")
            replyFrame:Show()
        else
            replyFrame:Hide()
        end
        -- TODO open reply frame with name of person to default
    end)
    return newMessageElementFrame, messageLineElements
end

function setMessageElementColor(messageElement, color)
    local portions = {messageElement:GetChildren()}
end

function createInstanceListElement(parentFrame, text, index)
    local label = parentFrame:CreateFontString(nil, "ARTWORK")
    label:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 6, -1*14*index - 14)
    label:SetFont("Fonts\\FRIZQT__.TTF", 12)
    label:SetText(text)
    label:SetTextColor(Constants.COLORS["YELLOW"][1], Constants.COLORS["YELLOW"][2], Constants.COLORS["YELLOW"][3])
    label:SetWidth(label:GetStringWidth())
    label:SetHeight(12)

    local checkbox = CreateFrame("CheckButton", text, parentFrame, "UICheckButtonTemplate")
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

function createReplyFrame(parentFrame, xPos, yPos, recipient, defaultMessage)
    local replyFrame = CreateFrame("Frame", nil, parentFrame)
    replyFrame:SetWidth(260)
    replyFrame:SetHeight(80)
    replyFrame:SetPoint("TOP", parentFrame, "TOP", 0, 0)
    replyFrame:SetBackdrop(iFinder.frameBackdrop)
    replyFrame:SetBackdropColor(15/255, 15/255, 15/255, 0.9)
    replyFrame:EnableMouse(true)
    replyFrame:SetMovable(true)
    replyFrame:SetFrameLevel(parentFrame:GetFrameLevel() + 4)
    replyFrame:SetClampedToScreen(true)
    replyFrame:SetScript("OnMouseDown", function()
        this:StartMoving()
    end)
    replyFrame:SetScript("OnMouseUp", function()
        this:StopMovingOrSizing()
    end)

    local replyFrameClose = CreateFrame("Button", "replyCloseButton", replyFrame, "UIPanelCloseButton")
    replyFrameClose:SetPoint("TOPRIGHT", replyFrame, "TOPRIGHT", 2, 2)
    replyFrameClose:SetScript("OnClick", function()
        this:GetParent():Hide()
    end)

    -- local replyFrameMsg = CreateFrame("EditBox", nil, replyFrame)
    -- replyFrameMsg:SetPoint("TOPLEFT", replyFrame, "TOPLEFT", 10, -1*replyFrameClose:GetHeight() - 4)
    -- replyFrameMsg:SetWidth(replyFrame:GetWidth() - 20)
    -- replyFrameMsg:SetAutoFocus(false)
    -- replyFrameMsg:SetFont("Fonts\\FRIZQT__.TTF", 10)
    -- replyFrameMsg:SetText(tostring(UnitLevel("player")) .. tostring(UnitClass("player")))
    -- replyFrameMsg:SetTextColor(Constants.COLORS["WHITE"][1], Constants.COLORS["WHITE"][2], Constants.COLORS["WHITE"][3])
    -- replyFrameMsg:SetMaxLetters(200)
    -- replyFrameMsg:SetBackdrop(iFinder.frameBackdrop)
    -- replyFrameMsg:SetBackdropColor(25/255, 25/255, 25/255, 1.0)
    -- replyFrameMsg:SetMultiLine(true)
    -- replyFrameMsg:SetTextInsets(5, 5, 5, 0)

    local widthFromLeft = 20
    local tankTex = replyFrame:CreateTexture(nil, "ARTWORK")
    tankTex:SetTexture("Interface\\AddOns\\iFinder\\media\\Tank")
    tankTex:SetPoint("TOPLEFT", replyFrame, "TOPLEFT", widthFromLeft + 2, -8)
    tankTex:SetWidth(36)
    tankTex:SetHeight(36)
    widthFromLeft = widthFromLeft + tankTex:GetWidth() + 2

    local tankCheckbox = CreateFrame("CheckButton", text, replyFrame, "UICheckButtonTemplate")
    tankCheckbox:SetPoint("TOPLEFT", replyFrame, "TOPLEFT", widthFromLeft + 1, -14)
    tankCheckbox:SetHeight(20)
    tankCheckbox:SetWidth(20)
    widthFromLeft = widthFromLeft + tankCheckbox:GetWidth() + 1

    local healerTex = replyFrame:CreateTexture(nil, "ARTWORK")
    healerTex:SetTexture("Interface\\AddOns\\iFinder\\media\\Healer")
    healerTex:SetPoint("TOPLEFT", replyFrame, "TOPLEFT", widthFromLeft + 20, -8)
    healerTex:SetWidth(36)
    healerTex:SetHeight(36)
    widthFromLeft = widthFromLeft + healerTex:GetWidth() + 20

    local healerCheckbox = CreateFrame("CheckButton", text, replyFrame, "UICheckButtonTemplate")
    healerCheckbox:SetPoint("TOPLEFT", replyFrame, "TOPLEFT", widthFromLeft + 1, -14)
    healerCheckbox:SetHeight(20)
    healerCheckbox:SetWidth(20)
    widthFromLeft = widthFromLeft + healerCheckbox:GetWidth() + 1

    local damageTex = replyFrame:CreateTexture(nil, "ARTWORK")
    damageTex:SetTexture("Interface\\AddOns\\iFinder\\media\\Damage")
    damageTex:SetPoint("TOPLEFT", replyFrame, "TOPLEFT", widthFromLeft + 20, -8)
    damageTex:SetWidth(36)
    damageTex:SetHeight(36)
    widthFromLeft = widthFromLeft + damageTex:GetWidth() + 20

    local damageCheckbox = CreateFrame("CheckButton", text, replyFrame, "UICheckButtonTemplate")
    damageCheckbox:SetPoint("TOPLEFT", replyFrame, "TOPLEFT", widthFromLeft + 1, -14)
    damageCheckbox:SetHeight(20)
    damageCheckbox:SetWidth(20)
    widthFromLeft = widthFromLeft + damageCheckbox:GetWidth() + 1

    replyFrameChineseSend = createButton(" Reply In Chinese ", "replySendButton", 12, replyFrame)
    replyFrameChineseSend:SetWidth(replyFrameChineseSend:GetTextWidth()+5)
    replyFrameChineseSend:SetPoint("BOTTOM", replyFrame, "BOTTOM", -60, 8)
    replyFrameChineseSend:SetScript("OnClick", function()
        roles = {}
        if Utils.toboolean(tankCheckbox:GetChecked()) == true then
            table.insert(roles, "坦克")
        end
        if Utils.toboolean(healerCheckbox:GetChecked()) == true then
            table.insert(roles, "治疗")
        end
        if Utils.toboolean(damageCheckbox:GetChecked()) == true then
            table.insert(roles, "dps")
        end

        local class = ""
        if UnitClass("player") == "Warrior" then
            class = "战士"
        elseif UnitClass("player") == "Paladin" then
            class = "圣骑士"
        elseif UnitClass("player") == "Hunter" then
            class = "猎人"
        elseif UnitClass("player") == "Shaman" then
            class = "萨满"
        elseif UnitClass("player") == "Rogue" then
            class = "盗贼"
        elseif UnitClass("player") == "Druid" then
            class = "德鲁伊"
        elseif UnitClass("player") == "Mage" then
            class = "法师"
        elseif UnitClass("player") == "Warlock" then
            class = "术士"
        elseif UnitClass("player") == "Priest" then
            class = "牧师"
        end

        local message = class .. " " .. table.concat(roles, "/")
        SendChatMessage(message, "WHISPER", nil, recipient)
        this:GetParent():Hide()
    end)

    replyFrameSend = createButton(" Reply In English ", "replySendButton", 12, replyFrame)
    replyFrameSend:SetPoint("BOTTOM", replyFrame, "BOTTOM", 60, 8)
    replyFrameSend:SetWidth(replyFrameSend:GetTextWidth()+5)
    replyFrameSend:SetScript("OnClick", function()
        roles = {}
        if Utils.toboolean(tankCheckbox:GetChecked()) == true then
            table.insert(roles, "tank")
        end
        if Utils.toboolean(healerCheckbox:GetChecked()) == true then
            table.insert(roles, "heals")
        end
        if Utils.toboolean(damageCheckbox:GetChecked()) == true then
            table.insert(roles, "dps")
        end
        
        local message = UnitClass("player") .. " " .. table.concat(roles, "/")
        SendChatMessage(message, "WHISPER", nil, recipient)     
        this:GetParent():Hide()
    end)

    replyFrame:Hide()
    return replyFrame
end

function showFinder()
    iFinderFrame:Show()
end

function closeFinder()
    iFinderFrame.optionsFrame:Hide()
    iFinderFrame:Hide()
end