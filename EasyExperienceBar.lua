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

EasyExperienceBar.session = EasyExperienceBar.session or {}
EasyExperienceBar.session.gainedXP = EasyExperienceBar.session.gainedXP or 0
EasyExperienceBar.session.lastXP = EasyExperienceBar.session.lastXP or UnitXP("player")
EasyExperienceBar.session.maxXP = EasyExperienceBar.session.maxXP or UnitXPMax("player")
EasyExperienceBar.session.startTime = EasyExperienceBar.session.startTime or time()
EasyExperienceBar.session.realTotalTime = EasyExperienceBar.session.realTotalTime or 0
EasyExperienceBar.session.realLevelTime = EasyExperienceBar.session.realLevelTime or 0
EasyExperienceBar.session.lastTimePlayedRequest = EasyExperienceBar.session.lastTimePlayedRequest or 0


function EasyExperienceBar:OnInitialize()
    EasyExperienceBar:Print("Launched!")

    EasyExperienceBar.MainFrame = _G.CreateFrame("Button", "WoWPro.MainFrame", _G.UIParent, _G.BackdropTemplateMixin and "BackdropTemplate" or nil)
    EasyExperienceBar.MainFrame:SetPoint("CENTER", _G.UIParent, -7, 334.1)
    EasyExperienceBar.MainFrame:SetSize(100, 17)

    EasyExperienceBar.BackgroundBar = EasyExperienceBar:CreateBackgroundBar(EasyExperienceBar.MainFrame)
    EasyExperienceBar.BackgroundBar:SetValue(100)
    EasyExperienceBar.BackgroundBar:Show()

    EasyExperienceBar.ProgressBar = EasyExperienceBar:CreateProgressBar(EasyExperienceBar.MainFrame)
    EasyExperienceBar.ProgressBar:SetValue(50)
    EasyExperienceBar.ProgressBar:Show()

    EasyExperienceBar:UpdateQuestXP()
    EasyExperienceBar:CalculateValues()

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
    progressBar:SetMinMaxValues(0, 100)
    progressBar:SetValue(0)
    return progressBar
end

function EasyExperienceBar:CreateBackgroundBar(parent)
    local backgroundBar = _G.CreateFrame("StatusBar", nil, EasyExperienceBar.MainFrame, _G.BackdropTemplateMixin and "BackdropTemplate")
    backgroundBar:SetPoint("CENTER", EasyExperienceBar.MainFrame, 0, 0)
    backgroundBar:SetSize(600, 30)

    backgroundBar:SetStatusBarTexture("Interface/Buttons/WHITE8X8")
    backgroundBar:SetStatusBarColor(0.309, 0.564, 1.0, 0.5)
    backgroundBar:SetMinMaxValues(0, 100)
    backgroundBar:SetValue(100)
    return backgroundBar
end


function EasyExperienceBar:CalculateValues()
    local show = true -- TODO:
    
    if EasyExperienceBar.timerHandler then
        EasyExperienceBar.timerHandler:Cancel()
        EasyExperienceBar.timerHandler = nil
    end
    
    if show then
        local level = _G.UnitLevel("player")
        local totalTime = EasyExperienceBar.session.realTotalTime or 0
        local levelTime = EasyExperienceBar.session.realLevelTime or 0
        local currentTime = _G.GetTime()
        sessionTime = 0
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
        if true and (EasyExperienceBar.session.lastTimePlayedRequest or 0) > 0 then
            totalTime = currentTime - EasyExperienceBar.session.lastTimePlayedRequest + EasyExperienceBar.session.realTotalTime
            levelTime = currentTime - EasyExperienceBar.session.lastTimePlayedRequest + EasyExperienceBar.session.realLevelTime
        end
        
        --cfg["EasyExperienceBar.sessiontime-text"] or cfg["showxphour-text"] 
        if true or true then
            if EasyExperienceBar.session.startTime > 0 then
                EasyExperienceBar.sessionTime = currentTime - EasyExperienceBar.session.startTime
                
                local coeff = EasyExperienceBar.sessionTime / 3600
                
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
            sessionTime = sessionTime,
            sessionTimeText = EasyExperienceBar:FormatTime(sessionTime),
            percentXP = totalXP > 0 and ((currentXP / totalXP) * 100) or 0,
            percentremaining = totalXP > 0 and ((remainingXP / totalXP) * 100) or 0,
            percentrested = totalXP > 0 and ((restedXP / totalXP) * 100) or 0,
            percentquest = totalXP > 0 and ((questXP / totalXP) * 100) or 0,
            percentcomplete = totalXP > 0 and ((completeXP / totalXP) * 100) or 0,
            percentincomplete = totalXP > 0 and ((incompleteXP / totalXP) * 100) or 0,
            totalpercentcomplete = totalXP > 0 and (((completeXP + currentXP) / totalXP) * 100) or 0,

         --   additionalProgress = {
          --      {
          --          -- Complete Quest XP
          --          direction = "forward",
          --          width = completeXP
          --      },
          --      {
          --          -- Incomplete Quest XP
          --          direction = "forward",
          --          width = env.config["showincompletequest-bar"] and incompleteXP or 0,
          --          offset = completeXP,
          --      },
          --      {
          --          -- Rested XP
          --          direction = "forward",
          --          width = restedXP,
          --          offset = completeXP + (env.config["showincompletequest-bar"] and incompleteXP or 0)
          --      }
          --  }
        }

        
        EasyExperienceBar:Print("currentXP: " .. allstates.currentXP)
        EasyExperienceBar:Print("remainingXP: " .. allstates.remainingXP)
        EasyExperienceBar:Print("PercentXP: " .. allstates.percentXP)
        EasyExperienceBar:Print("totalXP: " .. allstates.totalXP)
        EasyExperienceBar.ProgressBar:SetValue(allstates.percentXP)
        
        EasyExperienceBar:UpdateCustomTexts(allstates)
        
        EasyExperienceBar.timerHandler = C_Timer.NewTimer(1, function()
                WeakAuras.ScanEvents("LWA_EXPERIENCE_UPDATE")
        end)
        
        return true
        
    elseif allstates[""]["show"] then
        allstates[""] = {
            show = false,
            changed = true,
        }
        
        return true
    end
end

EasyExperienceBar.timerHandler = EasyExperienceBar.timerHandler or nil

--this.GetSavedVars = function()
--    local WAS = this.saved or {}
--    this.saved = WAS
--    
--    
    
--    return WAS
--end

function EasyExperienceBar:UpdateQuestXP()
    local numQ = C_QuestLog.GetNumQuestLogEntries()
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
    return strtrim(t:gsub("^%s*0*", ""):gsub("^%s*[DdHhMm]", ""), " :/-|")
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
        if ctrue then
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



