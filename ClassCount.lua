-- Saved variables
ClassCountSettings = ClassCountSettings or {
    scale = 1.0,
    opacity = 0.5,
    borderOpacity = 1.0,
    position = { point = "CENTER", relativeTo = nil, relativePoint = "CENTER", xOfs = 0, yOfs = 0 },
    verticalLayout = false,  -- Add vertical layout setting
    showGroupTitle = true,  -- Add setting to show/hide group/raid title and value
}

-- Function to save the frame position
local function SaveFramePosition()
    local point, relativeTo, relativePoint, xOfs, yOfs = ClassCountFrame:GetPoint()
    ClassCountSettings.position = {
        point = point,
        relativeTo = relativeTo,
        relativePoint = relativePoint,
        xOfs = xOfs,
        yOfs = yOfs
    }
end

-- Create the frame
local frame = CreateFrame("Frame", "ClassCountFrame", UIParent)
frame:SetSize(100, 100)  -- Initial frame size (will adjust dynamically)
frame:SetPoint(ClassCountSettings.position.point, ClassCountSettings.position.relativeTo, ClassCountSettings.position.relativePoint, ClassCountSettings.position.xOfs, ClassCountSettings.position.yOfs)
frame:SetMovable(true)    -- Makes the frame movable
frame:EnableMouse(true)   -- Allows frame to respond to mouse input
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    SaveFramePosition()
end)

-- Use a simple texture as the background instead of SetBackdrop
frame.bg = frame:CreateTexture(nil, "BACKGROUND")
frame.bg:SetColorTexture(0, 0, 0, ClassCountSettings.opacity)  -- Black background with transparency
frame.bg:SetAllPoints(true)

-- Add a border
frame.border = CreateFrame("Frame", nil, frame, BackdropTemplateMixin and "BackdropTemplate" or nil)
frame.border:SetPoint("TOPLEFT", -1, 1)
frame.border:SetPoint("BOTTOMRIGHT", 1, -1)
frame.border:SetBackdrop({
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border", edgeSize = 16,
})
frame.border:SetBackdropBorderColor(0, 0, 0, ClassCountSettings.borderOpacity)

-- Add tooltip to the main frame
frame:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText("Right click to open settings", 1, 1, 1)
    GameTooltip:Show()
end)
frame:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
end)

-- Function to get class colors in RGB format
local function GetClassColor(class)
    local color = RAID_CLASS_COLORS[class]
    return color.r, color.g, color.b
end

-- Function to capitalize the first letter of the class and make the rest lowercase
local function FormatClassName(className)
    return string.upper(string.sub(className, 1, 1)) .. string.lower(string.sub(className, 2))
end

-- Initialize class labels storage
frame.classLabels = {}

-- Create a font string for the total count
frame.totalCountLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
frame.totalCountLabel:SetPoint("TOPLEFT", 10, -10)  -- Position it at the top left
frame.totalCountLabel:SetTextColor(0, 1, 1)  -- Cyan color (RGB: 0, 1, 1)

-- Function to update the class count
local function UpdateClassCount()
    -- Clear previous content
    for _, label in pairs(frame.classLabels) do
        label:Hide()
    end

    -- Class names and their counts in the group
    local classCounts = {}

    -- Check if in a raid or party
    local groupSize = GetNumGroupMembers()
    if groupSize == 0 then 
        frame:Hide()  -- Hide the frame if no group
        return 
    end

    -- Show the frame if there are group members
    frame:Show()

    -- Set the total count text to "Group" or "Raid"
    local groupType = IsInRaid() and "Raid" or "Group"
    if ClassCountSettings.showGroupTitle then
        frame.totalCountLabel:SetText(string.format("%s: %d", groupType, groupSize))
        frame.totalCountLabel:Show()
    else
        frame.totalCountLabel:Hide()
    end

    -- Iterate over group/raid members
    for i = 1, groupSize do
        local unit = (IsInRaid() and "raid"..i) or "party"..i
        if i == groupSize and not IsInRaid() then -- include player in party
            unit = "player"
        end
        local class = select(2, UnitClass(unit)) -- Get the player's class
        if class then
            classCounts[class] = (classCounts[class] or 0) + 1
        end
    end

    -- Display class counts
    local labelIndex = 1
    for class, count in pairs(classCounts) do
        if count > 0 then
            local r, g, b = GetClassColor(class)
            local formattedClass = FormatClassName(class)  -- Format the class name
            local label = frame.classLabels[labelIndex] or frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")  -- Smaller font for class labels
            if ClassCountSettings.verticalLayout then
                label:SetPoint("TOPLEFT", 10, -30 - (labelIndex - 1) * 12)  -- Adjust position for vertical layout
            else
                label:SetPoint("TOPLEFT", 10 + (labelIndex - 1) * 60, -30)  -- Adjust position for horizontal layout
            end
            label:SetText(string.format("%s: %d", formattedClass, count))  -- Use formatted class name
            label:SetTextColor(r, g, b)
            label:Show()
            frame.classLabels[labelIndex] = label
            labelIndex = labelIndex + 1
        end
    end

    -- Adjust frame height based on the number of class labels and total label
    local height = ClassCountSettings.verticalLayout and (40 + (labelIndex - 1) * 12) or 55  -- Adjusted height calculation based on layout
    if not ClassCountSettings.showGroupTitle then
        height = height - 20  -- Reduce height if group title is hidden
    end
    local width = ClassCountSettings.verticalLayout and 100 or (10 + (labelIndex - 1) * 60)  -- Adjust width for layout
    frame:SetSize(width, height)  -- Adjust frame width and height dynamically

    -- Ensure class labels stay within the frame
    for i, label in ipairs(frame.classLabels) do
        if ClassCountSettings.verticalLayout then
            label:SetPoint("TOPLEFT", 10, (ClassCountSettings.showGroupTitle and -30 or -10) - (i - 1) * 12)
        else
            label:SetPoint("TOPLEFT", 10 + (i - 1) * 60, ClassCountSettings.showGroupTitle and -30 or -10)
        end
    end
end

-- Register an event to update the class count when the group composition changes
frame:RegisterEvent("GROUP_ROSTER_UPDATE")
frame:RegisterEvent("PLAYER_ENTERING_WORLD") -- In case the player logs in while in a group
frame:SetScript("OnEvent", UpdateClassCount)

-- Initial update
UpdateClassCount()

-- Create the settings frame
local settingsFrame = CreateFrame("Frame", "ClassCountSettingsFrame", UIParent)
settingsFrame:SetSize(200, 250)
settingsFrame.originalHeight = 250  -- Store the original height
settingsFrame:SetPoint("CENTER")
settingsFrame:SetMovable(true)
settingsFrame:EnableMouse(true)
settingsFrame:RegisterForDrag("LeftButton")
settingsFrame:SetScript("OnDragStart", settingsFrame.StartMoving)
settingsFrame:SetScript("OnDragStop", settingsFrame.StopMovingOrSizing)
settingsFrame:Hide()

settingsFrame.bg = settingsFrame:CreateTexture(nil, "BACKGROUND")
settingsFrame.bg:SetColorTexture(0, 0, 0, 0.5)
settingsFrame.bg:SetAllPoints(true)

settingsFrame.border = CreateFrame("Frame", nil, settingsFrame, BackdropTemplateMixin and "BackdropTemplate" or nil)
settingsFrame.border:SetPoint("TOPLEFT", -1, 1)
settingsFrame.border:SetPoint("BOTTOMRIGHT", 1, -1)
settingsFrame.border:SetBackdrop({
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border", edgeSize = 16,
})
settingsFrame.border:SetBackdropBorderColor(0, 0, 0)

-- Add a title to the settings frame
settingsFrame.title = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
settingsFrame.title:SetPoint("TOP", 0, -10)
settingsFrame.title:SetText("Class Count Settings")
settingsFrame.title:SetTextColor(1, 0, 0)  -- Red color (RGB: 1, 0, 0)

-- Add a close button to the settings frame
settingsFrame.closeButton = CreateFrame("Button", nil, settingsFrame, "UIPanelCloseButton")
settingsFrame.closeButton:SetPoint("TOPRIGHT", -5, -5)
settingsFrame.closeButton:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
settingsFrame.closeButton:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
settingsFrame.closeButton:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
settingsFrame.closeButton:SetScript("OnClick", function()
    settingsFrame:Hide()
end)

local function CreateSliderInputBox(slider, settingsFrame)
    local inputBox = CreateFrame("EditBox", nil, slider, "InputBoxTemplate")
    inputBox:SetSize(50, 20)
    inputBox:SetPoint("CENTER", _G[slider:GetName() .. 'Text'], "CENTER")  -- Place input box over the title's text
    inputBox:SetAutoFocus(true)
    inputBox:SetNumeric(true)
    inputBox:SetScript("OnEnterPressed", function(self)
        local value = tonumber(self:GetText())
        if value then
            slider:SetValue(value)
        end
        self:Hide()
        _G[slider:GetName() .. 'Text']:Show()  -- Show the title text
    end)
    inputBox:SetScript("OnEscapePressed", function(self)
        self:Hide()
        _G[slider:GetName() .. 'Text']:Show()  -- Show the title text
    end)
    inputBox:Hide()
    return inputBox
end

local function SetupSlider(slider, minValue, maxValue, value, step, text, settingsFrame)
    slider:SetMinMaxValues(minValue, maxValue)
    slider:SetValue(value)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    slider:SetWidth(150)
    _G[slider:GetName() .. 'Low']:SetText(tostring(minValue))
    _G[slider:GetName() .. 'High']:SetText(tostring(maxValue))
    _G[slider:GetName() .. 'Text']:SetPoint("TOP", slider, "TOP", 0, 25)  -- Add spacing between title and slider
    _G[slider:GetName() .. 'Text']:SetText(text)
    _G[slider:GetName() .. 'Text']:SetTextColor(1, 1, 0)  -- Yellow color

    _G[slider:GetName() .. 'Text']:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Click title to set value", 1, 1, 1)
        GameTooltip:Show()
    end)
    _G[slider:GetName() .. 'Text']:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    local inputBox = CreateSliderInputBox(slider, settingsFrame)
    _G[slider:GetName() .. 'Text']:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            inputBox:SetText(tostring(math.floor(slider:GetValue())))
            inputBox:Show()
            self:Hide()  -- Hide the title text
        end
    end)
end

-- Add a slider to adjust the scale of the main frame
settingsFrame.scaleSlider = CreateFrame("Slider", "ClassCountScaleSlider", settingsFrame, "OptionsSliderTemplate")
settingsFrame.scaleSlider:SetPoint("TOP", 0, -50)
SetupSlider(settingsFrame.scaleSlider, 1, 200, ClassCountSettings.scale * 100, 1, 'Main Frame Scale [' .. ClassCountSettings.scale * 100 .. ']', settingsFrame)

settingsFrame.scaleSlider:SetScript("OnValueChanged", function(self, value)
    local scale = value / 100
    frame:SetScale(scale)
    ClassCountSettings.scale = scale
    _G[self:GetName() .. 'Text']:SetText('Main Frame Scale [' .. value .. ']')
end)

-- Add a slider to adjust the opacity of the main frame's backdrop
settingsFrame.opacitySlider = CreateFrame("Slider", "ClassCountOpacitySlider", settingsFrame, "OptionsSliderTemplate")
settingsFrame.opacitySlider:SetPoint("TOP", 0, -100)
SetupSlider(settingsFrame.opacitySlider, 0, 100, ClassCountSettings.opacity * 100, 1, 'Backdrop Opacity [' .. ClassCountSettings.opacity * 100 .. ']', settingsFrame)

settingsFrame.opacitySlider:SetScript("OnValueChanged", function(self, value)
    local opacity = value / 100
    frame.bg:SetColorTexture(0, 0, 0, opacity)
    ClassCountSettings.opacity = opacity
    _G[self:GetName() .. 'Text']:SetText('Backdrop Opacity [' .. value .. ']')
end)

-- Add a slider to adjust the opacity of the main frame's border
settingsFrame.borderOpacitySlider = CreateFrame("Slider", "ClassCountBorderOpacitySlider", settingsFrame, "OptionsSliderTemplate")
settingsFrame.borderOpacitySlider:SetPoint("TOP", 0, -150)
SetupSlider(settingsFrame.borderOpacitySlider, 0, 100, ClassCountSettings.borderOpacity * 100, 1, 'Border Opacity [' .. ClassCountSettings.borderOpacity * 100 .. ']', settingsFrame)

settingsFrame.borderOpacitySlider:SetScript("OnValueChanged", function(self, value)
    local borderOpacity = value / 100
    frame.border:SetBackdropBorderColor(0, 0, 0, borderOpacity)
    ClassCountSettings.borderOpacity = borderOpacity
    _G[self:GetName() .. 'Text']:SetText('Border Opacity [' .. value .. ']')
end)

-- Add a checkbox to toggle the layout of the main frame
settingsFrame.layoutCheckbox = CreateFrame("CheckButton", "ClassCountLayoutCheckbox", settingsFrame, "UICheckButtonTemplate")
settingsFrame.layoutCheckbox:SetPoint("TOP", 0, -200)
settingsFrame.layoutCheckbox.Text:SetText("Vertical Layout")  -- Fix the error by using 'Text' instead of 'text'
settingsFrame.layoutCheckbox:SetChecked(ClassCountSettings.verticalLayout)

settingsFrame.layoutCheckbox:SetScript("OnClick", function(self)
    ClassCountSettings.verticalLayout = self:GetChecked()
    UpdateClassCount()
    frame:Show()  -- Ensure the frame is shown after updating the layout
end)

-- Add a checkbox to show/hide the group/raid title and value
settingsFrame.showGroupTitleCheckbox = CreateFrame("CheckButton", "ClassCountShowGroupTitleCheckbox", settingsFrame, "UICheckButtonTemplate")
settingsFrame.showGroupTitleCheckbox:SetPoint("TOP", 0, -230)
settingsFrame.showGroupTitleCheckbox.Text:SetText("Show Group/Raid Title")
settingsFrame.showGroupTitleCheckbox:SetChecked(ClassCountSettings.showGroupTitle)

settingsFrame.showGroupTitleCheckbox:SetScript("OnClick", function(self)
    ClassCountSettings.showGroupTitle = self:GetChecked()
    UpdateClassCount()
end)

-- Adjust checkboxes position
settingsFrame.layoutCheckbox:SetPoint("TOPLEFT", 20, -175)
settingsFrame.showGroupTitleCheckbox:SetPoint("TOPLEFT", settingsFrame.layoutCheckbox, "BOTTOMLEFT", 0, -10)

-- Adjust settings frame height dynamically
local function AdjustSettingsFrameHeight()
    local additionalHeight = 0
    if settingsFrame.scaleSlider.inputBox and settingsFrame.scaleSlider.inputBox:IsShown() then
        additionalHeight = additionalHeight + 30
    end
    if settingsFrame.opacitySlider.inputBox and settingsFrame.opacitySlider.inputBox:IsShown() then
        additionalHeight = additionalHeight + 30
    end
    if settingsFrame.borderOpacitySlider.inputBox and settingsFrame.borderOpacitySlider.inputBox:IsShown() then
        additionalHeight = additionalHeight + 30
    end
    settingsFrame:SetHeight(settingsFrame.originalHeight + additionalHeight)
end

-- Show settings frame on right-click
frame:SetScript("OnMouseDown", function(self, button)
    if button == "RightButton" then
        settingsFrame:Show()
        AdjustSettingsFrameHeight()
    end
end)

-- Slash command to show the main frame
SLASH_CLASSCOUNT1 = "/cct"
SlashCmdList["CLASSCOUNT"] = function()
    frame:Show()
end

-- Event handlers to save settings on logout and load settings on addon load
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGOUT")
eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "ClassCount" then
        -- Apply saved settings
        frame:SetScale(ClassCountSettings.scale)
        frame.bg:SetColorTexture(0, 0, 0, ClassCountSettings.opacity)
        frame.border:SetBackdropBorderColor(0, 0, 0, ClassCountSettings.borderOpacity)
        frame:SetPoint(ClassCountSettings.position.point, ClassCountSettings.position.relativeTo, ClassCountSettings.position.relativePoint, ClassCountSettings.position.xOfs, ClassCountSettings.position.yOfs)
        settingsFrame.scaleSlider:SetValue(ClassCountSettings.scale * 100)
        settingsFrame.opacitySlider:SetValue(ClassCountSettings.opacity * 100)
        settingsFrame.borderOpacitySlider:SetValue(ClassCountSettings.borderOpacity * 100)
        settingsFrame.layoutCheckbox:SetChecked(ClassCountSettings.verticalLayout)
        settingsFrame.showGroupTitleCheckbox:SetChecked(ClassCountSettings.showGroupTitle)
        UpdateClassCount()
    elseif event == "PLAYER_LOGOUT" then
        -- Save settings
        SaveFramePosition()
    end
end)
