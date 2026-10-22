-- XML templates: a window from the lab's own XML, built on Blizzard's templates (buttons, tabs, a check box, an input box)
-- The XML (xml-templates.xml) is read as the game reads an addon's: its virtual frame becomes a template that
-- CreateFrame takes, as for one of Blizzard's.
Lab.Addon("LabXML", "dev/uilab/scenes/xml-templates.xml")
Lab.OnLogin(function()
    local window = CreateFrame("Frame", "LabXMLWindow", UIParent, "LabXMLWindowTemplate")
    window:SetPoint("CENTER")
    tinsert(UISpecialFrames, "LabXMLWindow")

    -- One of Blizzard's templates straight from code, beside it.
    local button = CreateFrame("Button", nil, UIParent, "UIPanelButtonTemplate")
    button:SetSize(160, 24)
    button:SetPoint("TOP", window, "BOTTOM", 0, -48)
    button:SetText("Show the window")
    button:SetScript("OnClick", function() window:Show() end)
end)
