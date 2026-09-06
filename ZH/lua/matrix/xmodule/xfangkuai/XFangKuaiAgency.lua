local XFubenActivityAgency = require("XModule/XBase/XFubenActivityAgency")

---@class XFangKuaiAgency : XFubenActivityAgency
---@field private _Model XFangKuaiModel
local XFangKuaiAgency = XClass(XFubenActivityAgency, "XFangKuaiAgency")
function XFangKuaiAgency:OnInit()
    --初始化一些变量
    self:RegisterActivityAgency()
end

function XFangKuaiAgency:InitRpc()
    XRpc.NotifyFangKuaiData = handler(self, self.NotifyFangKuaiData)
    XRpc.NotifyFangKuaiCurStageData = handler(self, self.NotifyFangKuaiCurStageData)
end

function XFangKuaiAgency:InitEvent()
    --实现跨Agency事件注册
end

function XFangKuaiAgency:NotifyFangKuaiData(data)
    self._Model:NotifyFangKuaiData(data)
end

function XFangKuaiAgency:NotifyFangKuaiCurStageData(data)
    self._Model:NotifyFangKuaiCurStageData(data)
end

---功能是否有红点
function XFangKuaiAgency:CheckRedPoint()
    if not self._Model.ActivityData or not self:GetIsOpen(true) then
        return false
    end
    return self._Model:CheckTaskRedPoint() or self._Model:CheckAllChapterRedPoint()
end

---当有未通关的关卡时显示红点
function XFangKuaiAgency:CheckChallangeRedPoint()
    if not self._Model.ActivityData or not self:GetIsOpen(true) then
        return false
    end
    return self._Model:CheckChapterChallengeRedPoint()
end

---活动是否开启
function XFangKuaiAgency:GetIsOpen(noTips)
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.FangKuai, false, noTips) then
        return false
    end
    if not self._Model.ActivityData or not self:ExCheckInTime() then
        if not noTips then
            XUiManager.TipText("CommonActivityNotStart")
        end
        return false
    end
    return true
end

function XFangKuaiAgency:GetActivityTimeId()
    return self._Model:GetCurActivityTimeId()
end

---检查是否处于活动的游戏时间
function XFangKuaiAgency:CheckActivityIsInGameTime()
    local timeId = self:GetActivityTimeId()
    return XFunctionManager.CheckInTimeByTimeId(timeId)
end

---获取关卡结束时间
function XFangKuaiAgency:GetActivityGameEndTime()
    local timeId = self:GetActivityTimeId()
    return XFunctionManager.GetEndTimeByTimeId(timeId)
end

function XFangKuaiAgency:GetCurStageId(chapterId)
    return self._Model:GetCurStageId(chapterId)
end

function XFangKuaiAgency:GetChapterIdByStage(stageId)
    return self._Model:GetStageIdChapterId(stageId)
end

function XFangKuaiAgency:GetCurStageSettleData()
    return self._Model.ActivityData and self._Model.ActivityData:GetSettleData()
end

function XFangKuaiAgency:GetMaxScore(stageId)
    if not XTool.IsNumberValid(stageId) or not self._Model.ActivityData then
        return 0
    end

    return self._Model.ActivityData:GetMaxScore(stageId) or 0
end

function XFangKuaiAgency:GetStageGroupTabIdx(stageGroupId)
    return self._Model:GetStageGroupTabIdx(stageGroupId)
end

function XFangKuaiAgency:GetStageGroupByStage(stageId)
    local stageGroups = self._Model:GetStageGroupConfigs()
    for _, stageGroup in pairs(stageGroups) do
        if stageGroup.SimpleStageId == stageId or stageGroup.DiffcultStageId == stageId then
            return stageGroup
        end
    end
end

function XFangKuaiAgency:OpenStageFromCollection(stageId, enterCallback)
    if not XTool.IsNumberValid(stageId) then
        return
    end

    local stageGroup = self:GetStageGroupByStage(stageId)
    if XTool.IsTableEmpty(stageGroup) then
        return
    end

    local tabIndex = stageGroup.SimpleStageId == stageId and XEnumConst.FangKuai.SimpleTab or XEnumConst.FangKuai.DifficultTab
    XLuaUiManager.Open("UiFangKuaiChapterDetail", stageGroup.Id, tabIndex,true,enterCallback)
 
end

function XFangKuaiAgency:GiveUpStageFromCollection(stageId, cb)
    if not XTool.IsNumberValid(stageId) then
        if cb then
            cb()
        end
        return
    end

    XNetwork.CallWithAutoHandleErrorCode("FangKuaiStageSettleRequest", {
        StageId = stageId,
        SettleType = XEnumConst.FangKuai.Settle.GiveUp,
    }, function(res)
        self._Model.ActivityData:UpdateSettleData(res.SettleData, stageId)
        local chapterId = self:GetChapterIdByStage(stageId)
        self._Model.ActivityData:ClearStageData(chapterId)
        self:RecordEnhancedCount(stageId)
        if cb then
            cb(res)
        end
    end)
end

function XFangKuaiAgency:IsCurStageId(stageId)
    return XLuaUiManager.IsUiShow("UiFangKuaiFight") and self._Model:GetCurStageIdGuide() == stageId
end

-- 引导
function XFangKuaiAgency:IsCurChapterDetailStageId(stageId)
    ---@type XUiFangKuaiChapterDetail
    local chapterDetail = XLuaUiManager.GetTopLuaUi("UiFangKuaiChapterDetail")
    if chapterDetail ~= nil then
        return chapterDetail:GetStageId() == stageId
    end
    return false
end

-- 引导
function XFangKuaiAgency:IsGuideExitFever(isMeet)
    ---@type XUiFangKuaiFight
    local fight = XLuaUiManager.GetTopLuaUi("UiFangKuaiFight")
    if fight ~= nil then
        return fight:GetExitFevGuideFlag() == isMeet
    end
    return false
end

function XFangKuaiAgency:RecordEnhancedCount(stageId)
    local dir = {}
    dir["chapter_id"] = stageId
    dir["enhance_count"] = self._Model:GetItemEnhancedCountRecord(stageId)
    CS.XRecord.Record(dir, "1000044", "FangKuaiEnhancedCount")
end

--region 副本入口扩展

function XFangKuaiAgency:ExOpenMainUi()
    if not self:GetIsOpen() then
        return
    end
    -- 打开主界面
    XLuaUiManager.Open("UiFangKuaiMain")
end

function XFangKuaiAgency:ExGetConfig()
    if XTool.IsTableEmpty(self.ExConfig) then
        ---@type XTableFubenActivity
        self.ExConfig = XFubenConfigs.GetFubenActivityConfigByManagerName(self.__cname)
    end
    return self.ExConfig
end

function XFangKuaiAgency:ExGetChapterType()
    return XEnumConst.FuBen.ChapterType.FangKuai
end

function XFangKuaiAgency:ExCheckInTime()
    if not self.Super.ExCheckInTime(self) then
        return false
    end
    local timeId = self:GetActivityTimeId()
    return XFunctionManager.CheckInTimeByTimeId(timeId)
end

function XFangKuaiAgency:ExGetProgressTip()
    -- 游戏时间结束，不显示进度
    if not self:CheckActivityIsInGameTime() then
        return ""
    end
    local pass, all = self._Model:GetProgress()
    return XUiHelper.GetText("FangKuaiActivityProgress", pass, all)
end

function XFangKuaiAgency:ExGetRunningTimeStr()
    local isInGameTime = self:CheckActivityIsInGameTime()
    if isInGameTime then
        local gameEndTime = self:GetActivityGameEndTime()
        local gameTime = gameEndTime - XTime.GetServerNowTimestamp()
        local timeStr = XUiHelper.GetTime(gameTime, XUiHelper.TimeFormatType.ACTIVITY)
        return XUiHelper.GetText("FangKuaiResetTime", timeStr)
    else
        return XUiHelper.GetText("FangKuaiActivityEnd")
    end
end

--endregion

function XFangKuaiAgency:EnterDebegMode()
    XSaveTool.SaveData("FangKuai_Debug", true)
end

function XFangKuaiAgency:CloseDebegMode()
    XSaveTool.SaveData("FangKuai_Debug", false)
end

function XFangKuaiAgency:GetStageConfig(stageId)
    return self._Model:GetStageConfig(stageId)
end

function XFangKuaiAgency:GetBlockPoint(blockType, blockLen)
    return self._Model:GetBlockPoint(blockType, blockLen)
end

function XFangKuaiAgency:GetBlockConfig(blockId)
    return self._Model:GetBlockConfig(blockId)
end

--region Debug

---显示当前关卡总行数
function XFangKuaiAgency:DebugCurLineNo()
    if not XMain.IsWindowsEditor then
        return
    end
    if self._Model.ActivityData then
        local chapterId = self._Model:GetFightChapterId()
        if XTool.IsNumberValid(chapterId) then
            local stageData = self._Model.ActivityData:GetStageData(chapterId)
            if stageData then
                XLog.Error("lastLineNo=" .. stageData.LastLineNo)
                return
            end
        end
    end
    XLog.Error("GetCurLineNo error. stage not exist")
end

function XFangKuaiAgency:DebugAddItem(itemId)
    if not XMain.IsWindowsEditor then
        return
    end
    local chapterId = self._Model:GetFightChapterId()
    local stageData = self._Model.ActivityData:GetStageData(chapterId)
    stageData:AddItem(itemId)
    XEventManager.DispatchEvent(XEventId.EVENT_FANGKUAI_REMOVEITEM)
end

function XFangKuaiAgency:DebugSetFevValue(value)
    if not XMain.IsWindowsEditor then
        return
    end
    local chapterId = self._Model:GetFightChapterId()
    self._Model.ActivityData:GetStageData(chapterId).FevValue = value
    XEventManager.DispatchEvent(XEventId.EVENT_FANGKUAI_FEVER_VALUE)
end

--endregion

return XFangKuaiAgency
