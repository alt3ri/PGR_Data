local XFubenActivityAgency = require('XModule/XBase/XFubenActivityAgency')

---@class XDyeMergeGameAgency : XFubenActivityAgency
---@field private _Model XDyeMergeGameModel
local XDyeMergeGameAgency = XClass(XFubenActivityAgency, "XDyeMergeGameAgency", true)
--部分类require
XClassPartialRequire("XModule/XDyeMergeGame/XDyeMergeGameConfigAgency", "XDyeMergeGameAgency")

function XDyeMergeGameAgency:OnInit()
    self:RegisterActivityAgency()
    
    --初始化一些变量
    self:InitConfig()
    
    self.EnumConst = require("XModule/XDyeMergeGame/XDyeMergeGameEnumConst")
    self.EventIds = require("XModule/XDyeMergeGame/XDyeMergeGameEventId")
    
    ---@type XDyeMergeNetworkAgency
    self.Network = self:AddSubAgency(require("XModule/XDyeMergeGame/SubModules/Network/XDyeMergeNetworkAgency"))
end

function XDyeMergeGameAgency:InitRpc()
    -- 子 Agency 的 InitRpc 在 AddSubAgency 时已自动调用，这里无需重复
end

function XDyeMergeGameAgency:InitEvent()

end

function XDyeMergeGameAgency:ExOnSkip()
    if self:GetIsActivityOpen(true) then
        XLuaUiManager.Open('UiDyeMergeMain')
        return true
    else
        return false
    end
end

function XDyeMergeGameAgency:GetIsActivityOpen(needTips)
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.DyeMergeGame, true, needTips) then
        return false
    end

    if not self:ExCheckInTime() then
        if needTips then
            XUiManager.TipText('CommonActivityNotInTime')
        end
        return false
    end

    if not self._Model:CheckHasValidActivityId() then
        if needTips then
            XUiManager.TipText('CommonActivityNotInTime')
        end
        return false
    end

    return true
end

function XDyeMergeGameAgency:GetIsStageUnlockById(stageId)
    local stageCfg = self:GetTableDyeMergeStageById(stageId)

    if not stageCfg then
        return false
    end

    -- 判断前置条件
    if XTool.IsNumberValidEx(stageCfg.PreStage) then
        if not self:CheckPassedByStageId(stageCfg.PreStage) then
            -- 返回需通关前置关卡
            local preStageCfg = self:GetTableDyeMergeStageById(stageCfg.PreStage)

            if preStageCfg then
                return false, XUiHelper.FormatTextEx(self:GetClientDyeMergeTextByKey('StageUnlockPreStageFormat'), preStageCfg.Name)
            end

            return false
        end
    end

    return true
end

--- 判断关卡是否通关：完成所有目标
function XDyeMergeGameAgency:CheckPassedByStageId(stageId)
    local stageRecord = self._Model:GetStageRecord()

    if not XTool.IsTableEmpty(stageRecord) then
        return table.contains(stageRecord, stageId)
    end

    return false
end

--- 返回"进度关卡"的 stageId
--- 规则：全局第一个未通关关卡；若全通则为最后一个关卡；章节为空时返回 nil
function XDyeMergeGameAgency:GetLatestProgressStageId()
    local chapterIds = self:GetCurActivityChapterIds()
    if XTool.IsTableEmpty(chapterIds) then
        return nil
    end
    local lastStageId
    for _, chapterId in ipairs(chapterIds) do
        local chapterCfg = self:GetTableDyeMergeChapterById(chapterId)
        if chapterCfg and not XTool.IsTableEmpty(chapterCfg.StageIds) then
            for _, stageId in ipairs(chapterCfg.StageIds) do
                lastStageId = stageId
                if not self:CheckPassedByStageId(stageId) then
                    return stageId
                end
            end
        end
    end
    return lastStageId
end

--- 判断指定章节是否全部通关
function XDyeMergeGameAgency:IsChapterAllPassed(chapterId)
    local chapterCfg = self:GetTableDyeMergeChapterById(chapterId)
    if not chapterCfg or XTool.IsTableEmpty(chapterCfg.StageIds) then
        return false
    end
    for _, stageId in ipairs(chapterCfg.StageIds) do
        if not self:CheckPassedByStageId(stageId) then
            return false
        end
    end
    return true
end

--- 获取最新完成的章节ID（索引最大的全通关章节），无则返回 nil
function XDyeMergeGameAgency:GetLatestPassedChapterId()
    local chapterIds = self:GetCurActivityChapterIds()
    if XTool.IsTableEmpty(chapterIds) then return nil end
    for i = #chapterIds, 1, -1 do
        if self:IsChapterAllPassed(chapterIds[i]) then
            return chapterIds[i]
        end
    end
    return nil
end

--- 判断指定章节是否解锁
function XDyeMergeGameAgency:GetIsChapterUnlock(chapterId)
    -- 再检查是否有解锁
    local chapterCfg = self:GetTableDyeMergeChapterById(chapterId)

    if not chapterCfg then
        return false, ''
    end

    if XTool.IsNumberValidEx(chapterCfg.TimeId) and not XFunctionManager.CheckInTimeByTimeId(chapterCfg.TimeId) then
        local now = XTime.GetServerNowTimestamp()
        local startTime = XFunctionManager.GetStartTimeByTimeId(chapterCfg.TimeId)
        local endTime = XFunctionManager.GetEndTimeByTimeId(chapterCfg.TimeId)
        
        local desc = ''

        if now < startTime then
            local leftTime = startTime - now
            local leftTimeStr = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY)
            
            desc = XUiHelper.FormatTextEx(self:GetClientDyeMergeTextByKey("ChapterUnlockTimeLimitTips"), leftTimeStr)
        elseif XTool.IsNumberValidEx(endTime) and now >= endTime then
            desc = self:GetClientDyeMergeTextByKey("ChapterOutOfDateTips")
        end
        
        return false, desc, XMVCA.XDyeMergeGame.EnumConst.ChapterLockType.TimeLimit
    end

    if XTool.IsNumberValidEx(chapterCfg.Condition) then
        local result, lockTips = XConditionManager.CheckCondition(chapterCfg.Condition)
        return result, lockTips, XMVCA.XDyeMergeGame.EnumConst.ChapterLockType.Condition
    end
    
    return true
end

--region 蓝点

function XDyeMergeGameAgency:CheckAnyChapterShowReddot()
    local actCfg = self:GetCurActivityCfg(true)

    if not actCfg or XTool.IsTableEmpty(actCfg.ChapterIds) then
        return false
    end

    for i, v in pairs(actCfg.ChapterIds) do
        if self:CheckChapterShowReddot(v) then
            return true
        end
    end
    
    return false
end

function XDyeMergeGameAgency:CheckChapterShowReddot(chapterId)
    -- 先检查有没有标记
    local isMark = self._Model:GetNewChapterIsMarked(chapterId)

    if isMark then
        return false
    end
    
    -- 再检查是否有解锁
    local chapterCfg = self:GetTableDyeMergeChapterById(chapterId)

    if not chapterCfg then
        return false
    end

    -- 解锁了且没有标记则需要显示蓝点
    if self:GetIsChapterUnlock(chapterId) then
        return true
    end
end

--endregion

--region 新手引导

function XDyeMergeGameAgency:GetCurGamingStageId()
    return self._Model:GetCurGamingStageId()
end

--endregion

return XDyeMergeGameAgency