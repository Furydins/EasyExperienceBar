-- Initialization

EasyExperienceBar = LibStub("AceAddon-3.0"):NewAddon("EasyExperienceBar", "AceConsole-3.0")
EasyExperienceBar.AceGUI = LibStub("AceGUI-3.0")
EasyExperienceBar.MainFrame = nil
EasyExperienceBar.ProgressBar = nil

function EasyExperienceBar:GetMaxLevel(exp)
    exp = exp or _G.GetExpansionLevel()
    
    return min(_G.GetMaxPlayerLevel(), _G.GetMaxLevelForExpansionLevel(exp))
end

EasyExperienceBar.level = UnitLevel("player")
EasyExperienceBar.isPlayerMaxLevel = EasyExperienceBar.level >= EasyExperienceBar:GetMaxLevel()

EasyExperienceBar.GetNumQuestLogEntries = C_QuestLog.GetNumQuestLogEntries or GetNumQuestLogEntries
EasyExperienceBar.GetQuestIDForLogIndex = C_QuestLog.GetQuestIDForLogIndex or function(i)
    return select(8, GetQuestLogTitle(i))
end
EasyExperienceBar.SelectQuestLogEntry = SelectQuestLogEntry or function() end
EasyExperienceBar.IsQuestComplete = C_QuestLog.IsComplete or IsQuestComplete
EasyExperienceBar.QuestReadyForTurnIn = C_QuestLog.ReadyForTurnIn or function() return false end

EasyExperienceBar.UpdateTimer = nil

function EasyExperienceBar.EventHandler(self, event, arg1, arg2, arg3, arg4, ...)

    if "PLAYER_ENTERING_WORLD" == event then 
        if arg1 or (arg2 and false) then
            EasyExperienceBar.session.gainedXP = 0
            EasyExperienceBar.session.lastXP = currentXP
            EasyExperienceBar.session.maxXP = maxXP
            EasyExperienceBar.session.startTime = _G.GetTime()
            EasyExperienceBar.session.lastSessionLevelTime = EasyExperienceBar.session.realLevelTime
            EasyExperienceBar.currentSessionLevelStart = EasyExperienceBar.session.startTime
        end
    elseif "PLAYER_LEVEL_UP" == event then
        EasyExperienceBar.level = arg1 or EasyExperienceBar.level
        EasyExperienceBar.isPlayerMaxLevel = EasyExperienceBar.level >= EasyExperienceBar:GetMaxLevel()
        
        EasyExperienceBar.session.realLevelTime = 0
        EasyExperienceBar.lastSessionLevelTime = 0
        EasyExperienceBar.currentSessionLevelStart = _G.GetTime()
        EasyExperienceBar.session.maxXP = UnitXPMax("player")

        if EasyExperienceBar.isMaxLevel then 
            EasyExperienceBar.UpdateTimer:Cancel()
        end
     elseif "UPDATE_EXPANSION_LEVEL" == event or "MAX_EXPANSION_LEVEL_UPDATED" == event then
        local minExpLevel, maxExpLevel
        
        if arg3 then
            minExpLevel = min(arg1, arg2, arg3, arg4)
            maxExpLevel = max(arg1, arg2, arg3, arg4)
        else
            minExpLevel = GetExpansionLevel()
            maxExpLevel = minExpLevel
        end
        
        EasyExperienceBar.isPlayerMaxLevel = EasyExperienceBar.level >= EasyExperienceBar:GetMaxLevel(maxExpLevel)
        
        if EasyExperienceBar.level == _G.GetMaxLevelForExpansionLevel(minExpLevel) or (currentTime - session.startTime >= (86400 * 3)) then
            session.startTime = currentTime
        end

        if not EasyExperienceBar.isMaxLevel then 
            EasyExperienceBar:CreateTimer()
        end
    elseif "QUEST_LOG_UPDATE" == event or ("UNIT_QUEST_LOG_CHANGED" == event and arg1 == "player") then
        EasyExperienceBar:Update()
    elseif "PLAYER_XP_UPDATE" == event then
        EasyExperienceBar:Update()
    end  
end

function EasyExperienceBar:OnInitialize()
    -- EasyExperienceBar:Print("Launched!")

    EasyExperienceBar.sessionDB = LibStub("AceDB-3.0"):New("EasyExperienceDB")
    EasyExperienceBar.session = EasyExperienceBar.sessionDB.char

    EasyExperienceBar.session = EasyExperienceBar.session or {}
    EasyExperienceBar.session.gainedXP = EasyExperienceBar.session.gainedXP or 0
    EasyExperienceBar.session.lastXP = EasyExperienceBar.session.lastXP or UnitXP("player")
    EasyExperienceBar.session.maxXP = EasyExperienceBar.session.maxXP or UnitXPMax("player")
    EasyExperienceBar.session.startTime = EasyExperienceBar.session.startTime or _G.GetTime() 
    EasyExperienceBar.session.realTotalTime = EasyExperienceBar.session.realTotalTime or 0
    EasyExperienceBar.session.realLevelTime = EasyExperienceBar.session.realLevelTime or 0

    EasyExperienceBar.session.lastSessionLevelTime = EasyExperienceBar.session.lastSessionLevelTime or 0
    EasyExperienceBar.currentSessionLevelStart = EasyExperienceBar.session.startTime
    EasyExperienceBar.session.lastSessionTotalTime = EasyExperienceBar.session.realTotalTime
    EasyExperienceBar.currentTotalTimeStart = EasyExperienceBar.session.startTime

    EasyExperienceBar.MainFrame = _G.CreateFrame("Button", "WoWPro.MainFrame", _G.UIParent, _G.BackdropTemplateMixin and "BackdropTemplate" or nil)
    EasyExperienceBar.MainFrame:SetPoint("CENTER", _G.UIParent, -7, 334.1)
    EasyExperienceBar.MainFrame:SetFrameStrata("BACKGROUND")
    EasyExperienceBar.MainFrame:SetSize(100, 17)

    EasyExperienceBar.BackgroundBar = EasyExperienceBar:CreateBackgroundBar(EasyExperienceBar.MainFrame)
    EasyExperienceBar.BackgroundBar:SetValue(100)
    EasyExperienceBar.BackgroundBar:SetFrameLevel(10)
    EasyExperienceBar.BackgroundBar:Show()

    EasyExperienceBar.RestedBar = EasyExperienceBar:CreateRestedBar(EasyExperienceBar.MainFrame)
    EasyExperienceBar.RestedBar:SetValue(0)
    EasyExperienceBar.RestedBar:SetFrameLevel(20)
    EasyExperienceBar.RestedBar:Show()

    EasyExperienceBar.QuestBar = EasyExperienceBar:CreateQuestBar(EasyExperienceBar.MainFrame)
    EasyExperienceBar.QuestBar:SetValue(100)
    EasyExperienceBar.QuestBar:SetFrameLevel(30)
    EasyExperienceBar.QuestBar:Show()
    
    EasyExperienceBar.ProgressBar = EasyExperienceBar:CreateProgressBar(EasyExperienceBar.MainFrame)
    EasyExperienceBar.ProgressBar:SetValue(50)
    EasyExperienceBar.ProgressBar:SetFrameLevel(40)
    EasyExperienceBar.ProgressBar:Show()

    EasyExperienceBar.Texts = EasyExperienceBar:CreateTexts(EasyExperienceBar.ProgressBar)

    if not EasyExperienceBar.isMaxLevel then 
        EasyExperienceBar:CreateTimer()
    end
    EasyExperienceBar:RegisterEvents()

    EasyExperienceBar:Options()

end

function EasyExperienceBar:CreateTimer()
     EasyExperienceBar.UpdateTimer = C_Timer.NewTicker(0.5, function() EasyExperienceBar.Update() end)
end 

function EasyExperienceBar:RegisterEvents()
    EasyExperienceBar.MainFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    EasyExperienceBar.MainFrame:SetScript("OnEvent", EasyExperienceBar.EventHandler)
end

--/run EasyExperienceBar:UpdateQuestXP(); EasyExperienceBar:CalculateValues(); EasyExperienceBar:UpdateTexts(EasyExperienceBar.Texts, EasyExperienceBar.customTexts)
    

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
    progressBar:SetMinMaxValues(0, 100)
    progressBar:SetValue(0)
    return progressBar
end

function EasyExperienceBar:CreateBackgroundBar(parent)
    local backgroundBar = _G.CreateFrame("StatusBar", nil, EasyExperienceBar.MainFrame, _G.BackdropTemplateMixin and "BackdropTemplate")
    backgroundBar:SetPoint("CENTER", EasyExperienceBar.MainFrame, 0, 0)
    backgroundBar:SetSize(600, 30)

    backgroundBar:SetStatusBarTexture("Interface/Buttons/WHITE8X8")
    backgroundBar:SetStatusBarColor(0, 0, 0, 0.5)
    backgroundBar:SetMinMaxValues(0, 100)
    backgroundBar:SetValue(100)
    return backgroundBar
end

function EasyExperienceBar:CreateRestedBar(parent)
    local restedBar = _G.CreateFrame("StatusBar", nil, EasyExperienceBar.MainFrame, _G.BackdropTemplateMixin and "BackdropTemplate")
    restedBar:SetPoint("CENTER", EasyExperienceBar.MainFrame, 0, 0)
    restedBar:SetSize(600, 30)

    restedBar:SetStatusBarTexture("Interface/Buttons/WHITE8X8")
    restedBar:SetStatusBarColor(0.309, 0.562, 1.0, 0.5)
    restedBar:SetMinMaxValues(0, 100)
    restedBar:SetValue(100)
    return restedBar
end

function EasyExperienceBar:CreateQuestBar(parent)
    local questBar = _G.CreateFrame("StatusBar", nil, EasyExperienceBar.MainFrame, _G.BackdropTemplateMixin and "BackdropTemplate")
    questBar:SetPoint("CENTER", EasyExperienceBar.MainFrame, 0, 0)
    questBar:SetSize(600, 30)

    questBar:SetStatusBarTexture("Interface/Buttons/WHITE8X8")
    questBar:SetStatusBarColor(1.0, 0.589, 0.0, 1)
    questBar:SetMinMaxValues(0, 100)
    questBar:SetValue(100)
    return questBar
end

 function EasyExperienceBar:CreateTexts(frame)
    local levelText = frame:CreateFontString()
    levelText:SetPoint("LEFT", frame, "LEFT" , 5, 0)
    levelText:SetFont([[Fonts\FRIZQT__.TTF]], 14, "THICKOUTLINE")
    levelText:SetWidth(100)
    levelText:SetJustifyH("LEFT")
    levelText:SetTextColor(1,1,1)
    levelText:SetText("Level Test")

    local progressText = frame:CreateFontString()
    progressText:SetPoint("CENTER", frame, "CENTER" , 0, 0)
    progressText:SetFont([[Fonts\FRIZQT__.TTF]], 14, "THICKOUTLINE")
    progressText:SetWidth(200)
    progressText:SetJustifyH("CENTER")
    progressText:SetTextColor(1,1,1)
    progressText:SetText("Progress Test")

    local percentText = frame:CreateFontString()
    percentText:SetPoint("RIGHT", frame, "RIGHT" , -5, 0)
    percentText:SetFont([[Fonts\FRIZQT__.TTF]], 14, "THICKOUTLINE")
    percentText:SetJustifyH("RIGHT")
    percentText:SetWidth(100)
    percentText:SetText("Percent Test")

    local levelTimeText = frame:CreateFontString()
    levelTimeText:SetPoint("TOPLEFT", frame, "TOPLEFT" , 5, 24)
    levelTimeText:SetFont([[Fonts\FRIZQT__.TTF]], 13, "THICKOUTLINE")
    levelTimeText:SetWidth(200)
    levelTimeText:SetJustifyH("LEFT")
    levelTimeText:SetText("Level Time")

    local sessionTimeText = frame:CreateFontString()
    sessionTimeText:SetPoint("TOPRIGHT", frame, "TOPRIGHT" , 05, 24)
    sessionTimeText:SetFont([[Fonts\FRIZQT__.TTF]], 13, "THICKOUTLINE")
    sessionTimeText:SetJustifyH("RIGHT")
    sessionTimeText:SetWidth(200)
    sessionTimeText:SetText("Session Time")

    local timeToLevelText = frame:CreateFontString()
    timeToLevelText:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT" , 5, -24)
    timeToLevelText:SetFont([[Fonts\FRIZQT__.TTF]], 13, "THICKOUTLINE")
    timeToLevelText:SetWidth(250)
    timeToLevelText:SetJustifyH("LEFT")
    timeToLevelText:SetText("Time To Level")

    local statText = frame:CreateFontString()
    statText:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT" , -5, -24)
    statText:SetFont([[Fonts\FRIZQT__.TTF]], 13, "THICKOUTLINE")
    statText:SetJustifyH("RIGHT")
    statText:SetWidth(280)
    statText:SetText("Stats")


    return { levelText = levelText,
             progressText = progressText,
             percentText = percentText,
             levelTimeText = levelTimeText,
             sessionTimeText = sessionTimeText,
             timeToLevelText = timeToLevelText,
             statText = statText, }
 end

 function EasyExperienceBar:Update()
     local show = not EasyExperienceBar.isPlayerMaxLevel

    if show then
        if not EasyExperienceBar.BackgroundBar:IsShown() then
            EasyExperienceBar.BackgroundBar:Show()
            EasyExperienceBar.QuestBar:Show()
            EasyExperienceBar.RestedBar:Show()
            EasyExperienceBar.ProgressBar:Show()
        end
        EasyExperienceBar:UpdateQuestXP()
        EasyExperienceBar:CalculateValues()
        EasyExperienceBar:UpdateTexts()
    elseif EasyExperienceBar.BackgroundBar:IsShown() then
        EasyExperienceBar.BackgroundBar:Hide()
        EasyExperienceBar.QuestBar:Hide()
        EasyExperienceBar.RestedBar:Hide()
        EasyExperienceBar.ProgressBar:Hide()
    return true
    end
 end

function EasyExperienceBar:UpdateTexts()
    local textDisplays = EasyExperienceBar.Texts
    local textValues = EasyExperienceBar.customTexts

    textDisplays.levelText:SetText(textValues.c1)
    textDisplays.progressText:SetText(textValues.c2)
    textDisplays.percentText:SetText(textValues.c3)
    textDisplays.timeToLevelText:SetText(textValues.c4)
    textDisplays.statText:SetText(textValues.c5)
    textDisplays.levelTimeText:SetText(textValues.c6)
    textDisplays.sessionTimeText:SetText(textValues.c7)
end


function EasyExperienceBar:CalculateValues()
    local level = _G.UnitLevel("player")
    local totalTime = EasyExperienceBar.session.realTotalTime or 0
    local levelTime = EasyExperienceBar.session.realLevelTime or 0
    local currentTime = _G.GetTime()
    local hourlyXP, timeToLevel = 0, 0
    local gainedXP = EasyExperienceBar.session.gainedXP or 0
    local currentXP = _G.UnitXP("player") or 0
    local totalXP = _G.UnitXPMax("player") or 0
    local remainingXP = totalXP - currentXP
    local restedXP = _G.GetXPExhaustion() or 0
    local questXP = EasyExperienceBar.questXP or 0
    local completeXP = EasyExperienceBar.completeXP or 0
    local incompleteXP = EasyExperienceBar.incompleteXP or 0
    
    -- cfg["leveltime-text"]
    if true  then
        totalTime = (currentTime - EasyExperienceBar.currentTotalTimeStart) + EasyExperienceBar.session.lastSessionTotalTime
        levelTime = (currentTime - EasyExperienceBar.currentSessionLevelStart) + EasyExperienceBar.session.lastSessionLevelTime
    end

    EasyExperienceBar.session.realLevelTime = levelTime
    EasyExperienceBar.session.realTotalTime = totalTime

    -- EasyExperienceBar:Print(totalTime)
    -- EasyExperienceBar:Print(levelTime)

    -- EasyExperienceBar:Print( "Strat Time: " .. EasyExperienceBar.session.startTime)
    --cfg["EasyExperienceBar.sessiontime-text"] or cfg["showxphour-text"] 
    if true or true then
        if EasyExperienceBar.session.startTime > 0 then
            EasyExperienceBar.sessionTime = currentTime - EasyExperienceBar.session.startTime
            -- EasyExperienceBar:Print("Current Time " .. currentTime)
            -- EasyExperienceBar:Print("Session Time " .. EasyExperienceBar.sessionTime)
            -- EasyExperienceBar:Print("Start Time " .. EasyExperienceBar.session.startTime)
            
            local coeff = EasyExperienceBar.sessionTime / 3600
                -- EasyExperienceBar:Print("coeff " .. coeff)
            
            if coeff > 0 and gainedXP > 0 then
                hourlyXP = ceil(gainedXP / coeff)
                timeToLevel = ceil(remainingXP / hourlyXP * 3600)
            end
        end
    end
    
    local allstates = {
        show = true,
        changed = true,
        progressType = "static",
        value = currentXP,
        total = totalXP,
        
        -- Usable Variables
        level = level,
        currentXP = currentXP,
        totalXP = totalXP,
        remainingXP = remainingXP,
        restedXP = restedXP,
        questXP = questXP,
        completeXP = completeXP,
        incompleteXP = incompleteXP,
        hourlyXP = hourlyXP,
        timeToLevel = timeToLevel,
        timeToLevelText = timeToLevel > 0 and EasyExperienceBar:FormatTime(timeToLevel) or "--",
        totalTime = totalTime,
        totalTimeText = EasyExperienceBar:FormatTime(totalTime),
        levelTime = levelTime,
        levelTimeText = EasyExperienceBar:FormatTime(levelTime),
        sessionTime = EasyExperienceBar.sessionTime,
        sessionTimeText = EasyExperienceBar:FormatTime(EasyExperienceBar.sessionTime),
        percentXP = totalXP > 0 and ((currentXP / totalXP) * 100) or 0,
        percentremaining = totalXP > 0 and ((remainingXP / totalXP) * 100) or 0,
        percentrested = totalXP > 0 and ((restedXP / totalXP) * 100) or 0,
        percentquest = totalXP > 0 and ((questXP / totalXP) * 100) or 0,
        percentcomplete = totalXP > 0 and ((completeXP / totalXP) * 100) or 0,
        percentincomplete = totalXP > 0 and ((incompleteXP / totalXP) * 100) or 0,
        totalpercentcomplete = totalXP > 0 and (((completeXP + currentXP) / totalXP) * 100) or 0,
    }

    EasyExperienceBar.ProgressBar:SetValue(allstates.percentXP)
    EasyExperienceBar.QuestBar:SetValue(50) -- min(allstates.percentXP + allstates.percentcomplete, 100))
    EasyExperienceBar.RestedBar:SetValue(min(allstates.percentXP + allstates.percentcomplete + allstates.percentrested, 100))
    
    EasyExperienceBar:UpdateCustomTexts(allstates)
    
    return true
end

function EasyExperienceBar:UpdateQuestXP()
    local _, numQ = C_QuestLog.GetNumQuestLogEntries()
    local questXP = 0
    local completeXP = 0
    local incompleteXP = 0
    local questID, rewardXP
    local selQ = 0
    local GetQuestLogRewardXP = GetQuestLogRewardXP or function()
        return 0
    end
    
    if GetQuestLogSelection then
        selQ = _G.GetQuestLogSelection()
    end
    
    for i = 1, numQ do
        C_QuestLog.SetSelectedQuest(i)
        questID = C_QuestLog.GetQuestIDForLogIndex(i)
        
        if questID > 0 then
            rewardXP = _G.GetQuestLogRewardXP(questID) or 0
            
            if rewardXP > 0 then
                questXP = questXP + rewardXP
                
                if C_QuestLog.IsComplete(questID) or C_QuestLog.ReadyForTurnIn(questID) then
                    completeXP = completeXP + rewardXP
                else
                    incompleteXP = incompleteXP + rewardXP
                end
            end
        end
    end
    
    EasyExperienceBar.questXP = questXP
    EasyExperienceBar.completeXP = completeXP
    EasyExperienceBar.incompleteXP = incompleteXP
    
    if selQ > 0 then
        EasyExperienceBar:SelectQuestLogEntry(selQ)
        EasyExperienceBar:StaticPopup_Hide("ABANDON_QUEST")
        EasyExperienceBar:StaticPopup_Hide("ABANDON_QUEST_WITH_ITEMS")
        
        if QuestLogControlPanel_UpdateState then
            local SetAbandonQuest = SetAbandonQuest or function() end
            
            EasyExperienceBar:QuestLogControlPanel_UpdateState()
            EasyExperienceBar:SetAbandonQuest()
        end
    end
end

function EasyExperienceBar:round(num, decimals)
    local mult = 10^(decimals or 0)
    
    return Round(num * mult) / mult
end

function EasyExperienceBar:FormatTime(time, format)
    if time <= 59 then
        return "< 1m"
    end
    
    local d, h, m, s = ChatFrame_TimeBreakDown(time)
    local t = format or "%dd %hh %mm" --"%d:%H:%M:%S"
    
    
    local pad = function(v)
        return v < 10 and "0" .. v or v
    end
    
    local subs = {
        ["%%D([Dd]?)"] = d > 0 and (pad(d) .. "%1") or "",
        ["%%d([Dd]?)"] = d > 0 and (d .. "%1") or "",
        ["%%H([Hh]?)"] = (d > 0 or h > 0) and (pad(h) .. "%1") or "",
        ["%%h([Hh]?)"] = (d > 0 or h > 0) and (h .. "%1") or "",
        ["%%M([Mm]?)"] = pad(m) .. "%1",
        ["%%m([Mm]?)"] = m .. "%1",
        ["%%S([Ss]?)"] = pad(s) .. "%1",
        ["%%s([Ss]?)"] = s .. "%1",
    }
    
    for k,v in pairs(subs) do
        t = t:gsub(k, v)
    end
    
    -- Remove trailing spaces/zeroes/symbols
    local text = strtrim(t:gsub("^%s*0*", ""):gsub("^%s*[DdHhMm]", ""), " :/-|")

    if text == "" then
        return "< 1m"
    end

    return text
end

EasyExperienceBar.tickerRTP = EasyExperienceBar.tickerRTP or nil
EasyExperienceBar.requestingTimePlayed = false

function EasyExperienceBar:ClearTickerRTP()
    if EasyExperienceBar.tickerRTP then
        EasyExperienceBar.tickerRTP:Cancel()
        EasyExperienceBar.tickerRTP = nil
    end
    
    EasyExperienceBar.requestingTimePlayed = false
end

function EasyExperienceBar:RequestTimePlayed()
    if not EasyExperienceBar.requestingTimePlayed then
        EasyExperienceBar:ClearTickerRTP()
        
        EasyExperienceBar.requestingTimePlayed = true
        
        EasyExperienceBar.tickerRTP = C_Timer.NewTimer(0.5, function() RequestTimePlayed() end)
    end
end

EasyExperienceBar.customTexts = {
    c1 = "Level " .. EasyExperienceBar.level,
    c2 = "0 / 0 (0)",
    c3 = "0%",
    c4 = "",
    c5 = "",
    c6 = "",
    c7 = "",
}

function EasyExperienceBar:UpdateCustomTexts(state)
    local c1, c2, c3, c4, c5, c6, c7
    local s = state or EasyExperienceBar.state
    local isMaxLevel = EasyExperienceBar.isPlayerMaxLevel
    
    c1 = "Level " .. (s.level or _G.UnitLevel("player"))
    
    if isMaxLevel then
        c2 = "Max Level"
    else
        c2 = string.format("%s / %s (%s)", FormatLargeNumber(s.currentXP or 0), FormatLargeNumber(s.totalXP or 0), FormatLargeNumber(s.remainingXP or 0))
    end
    
    c3 = string.format("%s%%" .. ((s.percentcomplete or 0) > 0 and " (%s%%)" or ""), EasyExperienceBar:round(s.percentXP or 0, 1), EasyExperienceBar:round(s.totalpercentcomplete or 0, 1))
    
    if not isMaxLevel then
        -- cfg["showxphour-text"]
        if true then
            local hourlyXP = s.hourlyXP or 0
            
            c4 = string.format("Leveling in: %s (%s%s XP/Hour)", s.timeToLevelText or "", hourlyXP > 10000 and EasyExperienceBar:round(hourlyXP / 1000, 1) or FormatLargeNumber(hourlyXP), hourlyXP > 10000 and "K" or "")
        end
        
        -- cfg["questrested-text"]
        if true then
            c5 = string.format("Completed: |cFFFF9700%s%%|r - Rested: |cFF4F90FF%s%%|r", EasyExperienceBar:round(s.percentcomplete or 0, 1), EasyExperienceBar:round(s.percentrested or 0, 1))
        end
    end
    
    -- cfg["leveltime-text"]
    if true then
        if isMaxLevel then
            c6 = "Time played: " .. (s.totalTimeText or "")
        else
            c6 = "Time this level: " .. (s.levelTimeText or "")
        end
    end
    
    -- cfg["sessiontime-text"]
    if true then
        c7 = "Time this session: " .. (s.sessionTimeText or "")
    end
    
    EasyExperienceBar.customTexts = {
        c1 = c1,
        c2 = c2,
        c3 = c3,
        c4 = c4,
        c5 = c5,
        c6 = c6,
        c7 = c7,
    }
end

-- Options

EasyExperienceBar.options = {}
function EasyExperienceBar:Options()

    local options = {
        name = "EasyExperienceBar",
        handler = EasyExperienceBar.options,
        type = 'group',
        args = {
            msg = {
                type = 'input',
                name = 'My Message',
                desc = 'The message for my addon',
                set = 'SetMyMessage',
                get = 'GetMyMessage',
            },
        },
    }
    LibStub("AceConfig-3.0"):RegisterOptionsTable("EasyExperienceBar", options)
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions("EasyExperienceBar", "EasyExperienceBar")
end

function EasyExperienceBar:GetMyMessage(info)
    return myMessageVar
end

function EasyExperienceBar:SetMyMessage(info, input)
    myMessageVar = input
end



