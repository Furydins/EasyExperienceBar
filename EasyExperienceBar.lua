-- Initialization

EasyExperienceBar = LibStub("AceAddon-3.0"):NewAddon("EasyExperienceBar", "AceConsole-3.0")
EasyExperienceBar.AceGUI = LibStub("AceGUI-3.0")
EasyExperienceBar.MainFrame = nil
EasyExperienceBar.ProgressBar = nil


function EasyExperienceBar:OnInitialize()
 EasyExperienceBar:Print("Launched!")

 EasyExperienceBar.MainFrame = _G.CreateFrame("Button", "WoWPro.MainFrame", _G.UIParent, _G.BackdropTemplateMixin and "BackdropTemplate" or nil)
 EasyExperienceBar.MainFrame:SetPoint("CENTER", _G.UIParent, -7, 334.1)
 EasyExperienceBar.MainFrame:SetSize(100, 17)

 EasyExperienceBar.ProgressBar = EasyExperienceBar:CreateProgressBar(EasyExperienceBar.MainFrame)
 EasyExperienceBar.ProgressBar:SetValue(50)
 EasyExperienceBar.ProgressBar:Show()

end

function EasyExperienceBar:CreateProgressBar(parent)
    local progressBar = _G.CreateFrame("StatusBar", nil, EasyExperienceBar.MainFrame, _G.BackdropTemplateMixin and "BackdropTemplate")
    progressBar:SetPoint("CENTER", EasyExperienceBar.MainFrame, 0, 0)
    progressBar:SetSize(600, 30)

    local texture = UIParent:CreateTexture()
    texture:SetPoint("CENTER")
    texture:SetTexture("Interface/TargetingFrame/UI-StatusBar")

    local tstart = _G.CreateColor(0.335, 0.388, 1.0)
    local tend = _G.CreateColor(0.773, 0.380, 1.0)
    texture:SetGradient("HORIZONTAL", tstart, tend)

    progressBar:SetStatusBarTexture(texture)
    progressBar:SetBackdrop( {
        bgFile = [[Interface\CHARACTERFRAME\UI-Party-Background]],
        edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]],
        tile = true, tileSize = 16, edgeSize = 1,
        insets = { left = 0,  right = 0,  top = 0,  bottom = 0 }
    })
    
    progressBar:SetBackdropColor(0.335, 0.388, 1.0)
    progressBar:SetMinMaxValues(0, 100)
    progressBar:SetValue(0)
    return progressBar
end
