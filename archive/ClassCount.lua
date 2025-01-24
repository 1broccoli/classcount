-- Create the frame
local frame = CreateFrame("Frame", "ClassCountFrame", UIParent)
frame:SetSize(100, 100)  -- Initial frame size (will adjust dynamically)
frame:SetPoint("CENTER")  -- Default position
frame:SetMovable(true)    -- Makes the frame movable
frame:EnableMouse(true)   -- Allows frame to respond to mouse input
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

-- Use a simple texture as the background instead of SetBackdrop
frame.bg = frame:CreateTexture(nil, "BACKGROUND")
frame.bg:SetColorTexture(0, 0, 0, 0.5)  -- Black background with transparency
frame.bg:SetAllPoints(true)

-- Add a border
frame.border = CreateFrame("Frame", nil, frame, BackdropTemplateMixin and "BackdropTemplate" or nil)
frame.border:SetPoint("TOPLEFT", -1, 1)
frame.border:SetPoint("BOTTOMRIGHT", 1, -1)
frame.border:SetBackdrop({
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border", edgeSize = 16,
})
frame.border:SetBackdropBorderColor(0, 0, 0)

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
    frame.totalCountLabel:SetText(string.format("%s: %d", groupType, groupSize))

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
            label:SetPoint("TOPLEFT", 10, -30 - (labelIndex - 1) * 12)  -- Adjust position for class labels
            label:SetText(string.format("%s: %d", formattedClass, count))  -- Use formatted class name
            label:SetTextColor(r, g, b)
            label:Show()
            frame.classLabels[labelIndex] = label
            labelIndex = labelIndex + 1
        end
    end

    -- Adjust frame height based on the number of class labels and total label
    local height = 40 + (labelIndex - 1) * 12  -- Adjusted height calculation based on smaller font and labels
    frame:SetSize(75, height)  -- Adjust frame width (75) and height dynamically
end

-- Register an event to update the class count when the group composition changes
frame:RegisterEvent("GROUP_ROSTER_UPDATE")
frame:RegisterEvent("PLAYER_ENTERING_WORLD") -- In case the player logs in while in a group
frame:SetScript("OnEvent", UpdateClassCount)

-- Initial update
UpdateClassCount()
