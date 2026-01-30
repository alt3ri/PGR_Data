local XDlcSimulationChallengeAgency = require("XModule/XBase/XDlcSimulationChallengeAgency")
local XDlcRelinkRoom = require("XModule/XDlcRelink/XEntity/XDlcRelinkRoom")
local XDlcRelinkWorldFight = require("XModule/XDlcRelink/XEntity/XDlcRelinkWorldFight")
---@class XDlcRelinkAgency : XDlcSimulationChallengeAgency
---@field private _Model XDlcRelinkModel
local XDlcRelinkAgency = XClass(XDlcSimulationChallengeAgency, "XDlcRelinkAgency")
function XDlcRelinkAgency:OnInit()
    --初始化一些变量
    self:DlcRegisterChapter()
end

function XDlcRelinkAgency:InitRpc()
    --实现服务器事件注册
    --XRpc.XXX
    XRpc.NotifyDlcRelinkData = handler(self, self.NotifyDlcRelinkData)
    XRpc.NotifyDlcRelinkNewEquip = handler(self, self.NotifyDlcRelinkNewEquip)
    XRpc.NotifyDlcRelinkRemoveEquip = handler(self, self.NotifyDlcRelinkRemoveEquip)
    XRpc.NotifyDlcRelinkEquipPreset = handler(self, self.NotifyDlcRelinkEquipPreset)
    XRpc.NotifyDlcRelinkCharacterData = handler(self, self.NotifyDlcRelinkCharacterData)
end

function XDlcRelinkAgency:InitEvent()
    XMVCA.XDlcHelper:AddDlcModelIdGetterWithWorldType(XEnumConst.DlcWorld.WorldType.Relink, self)
end

function XDlcRelinkAgency:RemoveEvent()
    XMVCA.XDlcHelper:RemoveDlcModelIdGetterWithWorldType(XEnumConst.DlcWorld.WorldType.Relink, self)
end

--region 服务端信息更新

--- 更新活动数据
function XDlcRelinkAgency:NotifyDlcRelinkData(data)
    if not data or not data.DlcRelinkData then
        return
    end
    -- 结算数据记录
    if data.IsSettleFuben then
        local level = data.DlcRelinkData.Level or 0
        local exp = data.DlcRelinkData.Exp or 0
        self._Model:RecordSettlementLevelAndExp(level, exp)
    end
    self._Model:NotifyActivityData(data.DlcRelinkData)
end

--- 新增装备数据
function XDlcRelinkAgency:NotifyDlcRelinkNewEquip(data)
    if not data then
        return
    end
    if not self._Model.ActivityData then
        return
    end
    for _, v in pairs(data.EquipDatas) do
        self._Model.ActivityData:AddEquipsData(v)
    end
end

--- 删除装备数据
function XDlcRelinkAgency:NotifyDlcRelinkRemoveEquip(data)
    if not data then
        return
    end
    if not self._Model.ActivityData then
        return
    end
    for _, v in pairs(data.EquipUids) do
        self._Model.ActivityData:RemoveEquipsData(v)
    end
end

--- 装备预设同步（全量）
function XDlcRelinkAgency:NotifyDlcRelinkEquipPreset(data)
    if not data then
        return
    end
    if not self._Model.ActivityData then
        return
    end
    self._Model.ActivityData:SetEquipPresetSets(data.EquipPresetSets)
    XEventManager.DispatchEvent(XEventId.EVENT_DLC_RELINK_SYNC_EQUIP_PRESET)
end

-- 角色数据同步
function XDlcRelinkAgency:NotifyDlcRelinkCharacterData(data)
    if not data then
        return
    end
    if not self._Model.ActivityData then
        return
    end
    for _, v in pairs(data.Character) do
        self._Model.ActivityData:AddCharacters(v)
    end
end

--endregion

--region 通用

function XDlcRelinkAgency:GetIsOpen(noTips)
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.DlcRelink, false, noTips) then
        return false
    end
    if not self._Model.ActivityData or not self:ExCheckInTime() then
        if not noTips then
            XUiManager.TipText('CommonActivityNotStart')
        end
        return false
    end
    return true
end

function XDlcRelinkAgency:OpenMainUi()
    if not self:GetIsOpen() then
        return false
    end
    XLuaUiManager.Open("UiDlcRelinkMain")
    return true
end

--endregion

--region Dlc

function XDlcRelinkAgency:DlcGetRoomProxy()
    return XDlcRelinkRoom.New()
end

function XDlcRelinkAgency:DlcGetFightEvent()
    return XDlcRelinkWorldFight.New()
end

function XDlcRelinkAgency:DlcGetWorldType()
    return XEnumConst.DlcWorld.WorldType.Relink
end

function XDlcRelinkAgency:DlcCheckActivityInTime()
    return self:ExCheckInTime()
end

function XDlcRelinkAgency:DlcReconnect()
    local title = XUiHelper.GetText("TipTitle")
    local message = XUiHelper.GetText("OnlineInstanceReconnect")

    XUiManager.DialogTip(title, message, XUiManager.DialogType.Normal, function()
        XMVCA.XDlcRoom:CancelReconnectToWorld()
    end, function()
        self:DlcInitFight()
        XMVCA.XDlcRoom:ReconnectToWorld()
    end)
end

--- 打开邀请UI
---@param inviteData XChatData 邀请数据
function XDlcRelinkAgency:DlcOpenInviteUi(inviteData)
    XLuaUiManager.Open("UiDlcRelinkPopupInvitation", inviteData)
end

--- 检测邀请UI是否打开
function XDlcRelinkAgency:DlcCheckInviteUiShow()
    return XLuaUiManager.IsUiShow("UiDlcRelinkPopupInvitation")
end

--- 战斗侧获取角色模型Id
function XDlcRelinkAgency:ExGetDlcModelIdByCharacterData(characterData)
    -- 4.2没有换装需求 暂时不处理
end

--- 战斗侧获取角色头像
---@param worldNpcData XWorldNpcData
---@return string
function XDlcRelinkAgency:GetFightCharHeadIcon(worldNpcData)
    if not worldNpcData then
        return ""
    end
    local character = worldNpcData.Character
    if not character then
        return ""
    end

    local fashionId = XMVCA.XCharacter:GetCharacterTemplate(character.Id).DefaultNpcFashtionId
    return XDataCenter.FashionManager.GetFashionSmallHeadIcon(fashionId)
end

--endregion

--region 副本扩展入口

function XDlcRelinkAgency:ExCheckInTime()
    local timeId = self._Model:GetActivityTimeId()
    return XFunctionManager.CheckInTimeByTimeId(timeId)
end

function XDlcRelinkAgency:ExGetChapterType()
    return XEnumConst.FuBen.ChapterType.DlcRelink
end

function XDlcRelinkAgency:ExGetProgressTip()
    local passCount, totalCount = self:GetLevelPassProgress()
    local progressStr = string.format("%d/%d", passCount, totalCount)
    local progressTip = self._Model:GetClientConfig("LevelPassProgressTip", 1)
    return string.format(progressTip, progressStr)
end

function XDlcRelinkAgency:ExCheckIsShowRedPoint()
    if not self:GetIsOpen(true) then
        return false
    end
    if self:CheckAllLevelHasNewUnlock() then
        return true
    end
    if self:CheckAllTaskRedPoint() then
        return true
    end
    return false
end

--endregion

--region 玩法相关

--- 获取关卡通过进度
function XDlcRelinkAgency:GetLevelPassProgress()
    local passCount, totalCount = 0, 0
    local chapterIds = self._Model:GetActivityChapterIds()
    for _, chapterId in pairs(chapterIds) do
        local levelIds = self._Model:GetChapterLevelIds(chapterId)
        for _, levelId in pairs(levelIds) do
            totalCount = totalCount + 1
            if self._Model:CheckLevelPassed(levelId) then
                passCount = passCount + 1
            end
        end
    end
    return passCount, totalCount
end

--- 检查所有关卡是否有新解锁
function XDlcRelinkAgency:CheckAllLevelHasNewUnlock()
    local chapterIds = self._Model:GetActivityChapterIds()
    for _, chapterId in pairs(chapterIds) do
        if self._Model:CheckChapterHasAnyNewLevel(chapterId) then
            return true
        end
    end
    return false
end

--- 检查任务红点 已完成未领取奖励
function XDlcRelinkAgency:CheckAllTaskRedPoint()
    local configs = self._Model:GetShopTaskConfigs()
    if XTool.IsTableEmpty(configs) then
        return false
    end
    for _, config in pairs(configs) do
        if config.Type == XEnumConst.DlcRelink.ShopTaskType.Task then
            local taskIds = config.ParamId or {}
            for _, taskId in ipairs(taskIds) do
                local taskData = XDataCenter.TaskManager.GetTaskDataById(taskId)
                if taskData and taskData.State == XDataCenter.TaskManager.TaskState.Achieved then
                    return true
                end
            end
        end
    end
    return false
end

--endregion

return XDlcRelinkAgency
