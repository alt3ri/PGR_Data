---@class XBigWorldInstanceAgency : XAgency
---@field private _Model XBigWorldInstanceModel
---@field private _Settle XBigWorldSettle
local XBigWorldInstanceAgency = XClass(XAgency, "XBigWorldInstanceAgency")

local CsSyncFight = CS.StatusSyncFight

function XBigWorldInstanceAgency:OnInit()
    self.LevelPlayType = {
        None = 0,
        JumpPlay = 1, --跳跳乐
        Review = 2, --回顾副本
    }
    
    self.LevelType = {
        BigWorld = 1, -- 大世界
        Instance = 2, -- 副本
    }

    self.LevelSubType = {
        StoryInst = 1, -- 剧情副本
        LevelPlayInst = 2 -- 玩法副本
    }

    self.LevelSaveOption = {
        None = 0, -- 不保存
        SaveExit = 1, -- 保存
        NoSaveExit = 2 -- 不保存
    }
    
end

function XBigWorldInstanceAgency:InitRpc()
    self:AddRpc("NotifyBigWorldLevelPlayDataChange", handler(self, self.OnNotifyBigWorldLevelPlayDataChange))
end

function XBigWorldInstanceAgency:InitEvent()
end

function XBigWorldInstanceAgency:RemoveEvent()
end

function XBigWorldInstanceAgency:GetSettleUiName(settleId)
    return self._Model:GetSettleUiName(settleId)
end

function XBigWorldInstanceAgency:OpenSettle(data)
    if not data then
        return
    end
    self:GetSettle():DoSettle(data.SettleData)
end

function XBigWorldInstanceAgency:OnSettleClosed()
    self:GetSettle():DoSettleClosed()
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_BIG_WORLD_SETTLEMENT)
end

---@return XBigWorldSettle
function XBigWorldInstanceAgency:GetSettle()
    if not self._Settle then
        self._Settle = require("XModule/XBigWorldInstance/Settle/XBigWorldSettle").New()
    end
    return self._Settle
end

function XBigWorldInstanceAgency:InitLevelPlayData(dataList)
    self._Model:InitLevelPlayData(dataList)
end

function XBigWorldInstanceAgency:OnNotifyBigWorldLevelPlayDataChange(data)
    self._Model:UpdateLevelPlayData(data)
end

function XBigWorldInstanceAgency:CheckLevelPlayFullCleared(levelPlayId)
    return self._Model:CheckLevelPlayFullCleared(levelPlayId)
end

function XBigWorldInstanceAgency:CheckLevelPlayCleared(levelPlayId)
    return self._Model:CheckLevelPlayCleared(levelPlayId)
end

function XBigWorldInstanceAgency:ShowExitLevelPopup()
    local levelId = XMVCA.XBigWorldGamePlay:GetCurrentLevelId()
    ---@type StatusSyncFight.XTableLevel
    local template = CsSyncFight.XLevelConfig.GetTemplate(levelId)
    local levelSubType = template and template.LevelSubType or nil
    if levelSubType == self.LevelSubType.StoryInst then
        self:ShowExitStoryInstPopup(levelId)
    elseif levelSubType == self.LevelSubType.LevelPlayInst then
        self:ShowExitPlayInstPopup(levelId)
    else
        XLog.Error("打开二次确认弹窗失败 LevelId = " .. levelId .. " LevelSubType = " .. levelSubType)
    end
end

function XBigWorldInstanceAgency:ShowExitStoryInstPopup(levelId)
    local confirmData = XMVCA.XBigWorldCommon:GetPopupQuitConfirmData()
    local title = XMVCA.XBigWorldService:GetText("StoryLevelTipExitTitle")
    local tips = XMVCA.XBigWorldService:GetText("StoryLevelTipExitText")
    local sureText = XMVCA.XBigWorldService:GetText("StoryLevelTipExitSureText")
    local cancelText = XMVCA.XBigWorldService:GetText("StoryLevelTipExitCancelText")

    confirmData:InitInfo(title, tips, true)
    confirmData:InitCancelClick(cancelText, function()
        XMVCA.XBigWorldGamePlay:RequestLeaveInstLevel(self.LevelSaveOption.NoSaveExit)
    end)
    confirmData:InitSureClick(sureText, function()
        XMVCA.XBigWorldGamePlay:RequestLeaveInstLevel(self.LevelSaveOption.SaveExit)
    end)

    XMVCA.XBigWorldUI:OpenQuitConfirmPopup(confirmData)
end

function XBigWorldInstanceAgency:ShowExitPlayInstPopup(levelId)
    ---@type StatusSyncFight.XTableBigWorldLevelPlay
    local template = CsSyncFight.XLevelConfig.GetLevelPlayConfigByLevelId(levelId)
    local levelPlayType = template.Type
    
    ---@type XBWPopupQuitConfirmData
    local confirmData
    local title = template and template.Name or XMVCA.XBigWorldService:GetText("InstLevelTipExitTitle")
    local tips = XMVCA.XBigWorldService:GetText("InstLevelTipExitText", title)
    if levelPlayType == self.LevelPlayType.JumpPlay then
        confirmData = XMVCA.XBigWorldCommon:GetPopupQuitConfirmData()
        confirmData:InitInfo(title, tips, true)

        local sureText = XMVCA.XBigWorldService:GetText("InstLevelTipExitSureText")
        local cancelText = XMVCA.XBigWorldService:GetText("InstLevelTipExitCancelText")

        confirmData:InitCancelClick(cancelText, function()
            XMVCA.XBigWorldGamePlay:RequestLeaveInstLevel()
        end)
        confirmData:InitSureClick(sureText, function()
            XMVCA.XBigWorldGamePlay:RequestAgainChallengeInst()
        end)
        XMVCA.XBigWorldUI:OpenQuitConfirmPopup(confirmData)
    elseif template.Type == self.LevelPlayType.Review then
        confirmData = XMVCA.XBigWorldCommon:GetPopupQuitConfirmData()
        confirmData:InitInfo(title, tips, true)

        local sureText = XMVCA.XBigWorldService:GetText("InstLevelTipExitCancelText")
        local cancelText = XMVCA.XBigWorldService:GetText("CancelText")

        confirmData:InitCancelClick(cancelText)
        confirmData:InitSureClick(sureText, function()
            XMVCA.XBigWorldGamePlay:RequestLeaveInstLevel()
        end)
        XMVCA.XBigWorldUI:OpenQuitConfirmPopup(confirmData)
    else
        XLog.Error("打开二次确认弹窗失败 LevelId = " .. levelId .. " levelPlayType = " .. levelPlayType)
    end
end

return XBigWorldInstanceAgency