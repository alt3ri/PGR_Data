local XBigWorldActivityAgency = require("XModule/XBase/XBigWorldActivityAgency")

---@class XSkyGardenDroneGameAgency : XBigWorldActivityAgency
---@field private _Model XSkyGardenDroneGameModel
local XSkyGardenDroneGameAgency = XClass(XBigWorldActivityAgency, "XSkyGardenDroneGameAgency")

function XSkyGardenDroneGameAgency:OnInit()
    --初始化一些变量
    self.ChapterType = {
        Normal = 1, -- 普通
        Hard = 2, -- 困难
    }
    self.StageType = {
        Normal = 1, -- 普通
        Special = 2, -- 特殊
        MainLine = 3, -- 主线
        BranchLine = 4, -- 支线
    }
    self.DialogueType = {
        Trigger = 1, -- 触发
        Timer = 2, -- 定时
        Random = 3, -- 随机
    }
end

function XSkyGardenDroneGameAgency:InitRpc()
    --实现服务器事件注册
    --XRpc.XXX
    self:AddRpc("NotifySgDroneGameData", handler(self, self.OnNotifyDroneGameData))
end

function XSkyGardenDroneGameAgency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()
end

function XSkyGardenDroneGameAgency:OnNotifyDroneGameData(data)
    if data and data.GameData then
        self._Model:UpdateStageData(data.GameData.StageInfo)
        self._Model:UpdateStorageStageData(data.GameData.CurStageData)
    end
end

function XSkyGardenDroneGameAgency:OnChapterSelectViewSwitchCompleteCmd(data)
    if data and data.ChapterId then
        XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_SKY_GARDEN_DRONE_CHAPTER_SELECT_VIEW_SWITCH_COMPLETE, data.ChapterId)
    end
end

function XSkyGardenDroneGameAgency:CheckInTime()
    return true
end

function XSkyGardenDroneGameAgency:GetProgressTipData()
    local titel = ""
    local totalCount = 0
    local currentCount = 0
    local progressText = self._Model:GetSgDroneGameConfigValuesByKey("ProgressText")
    local chapterConfigs = self._Model:GetSgDroneGameChapterConfigs()

    if not XTool.IsTableEmpty(chapterConfigs) then
        for _, chapterConfig in pairs(chapterConfigs) do
            if not XTool.IsTableEmpty(chapterConfig.StageIds) then
                for _, stageId in pairs(chapterConfig.StageIds) do
                    local stageConfig = self._Model:GetSgDroneGameStageConfigById(stageId)

                    if stageConfig then
                        if not XTool.IsTableEmpty(stageConfig.StarTargets) then
                            local stageData = self._Model:GetStageData(stageId)

                            totalCount = totalCount + #stageConfig.StarTargets

                            if stageData then
                                for _, targetId in pairs(stageConfig.StarTargets) do
                                    if stageData:IsTargetFinish(targetId) then
                                        currentCount = currentCount + 1
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    if not XTool.IsTableEmpty(progressText) then
        titel = progressText[1]
    end

    return {
        [1] = {
            Title = titel,
            Progress = currentCount .. "/" .. totalCount,
            IsComplete = currentCount >= totalCount,
        }
    }
end

function XSkyGardenDroneGameAgency:CheckFunctionOpen()
    return XMVCA.XBigWorldFunction:DetectionFunction(XMVCA.XBigWorldFunction.FunctionId.SgDroneGame)
end

function XSkyGardenDroneGameAgency:OpenMainUi()
    XMVCA.XBigWorldUI:Open("UiSkyGardenSGDroneMain")
end

return XSkyGardenDroneGameAgency