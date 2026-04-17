---@field _Control XPBRGameControl
---@class XUiPBRPause : XLuaUi
local XUiPBRPause = XLuaUiManager.Register(XLuaUi, "UiPBRPause")

local XUiPBRPauseUiPBRPanelStatus = require('XUi/XUiPBRGame/XUiPBRPause/RoleDetail/XUiPBRPauseUiPBRPanelStatus')
local XUiPBRPausePanelProp = require('XUi/XUiPBRGame/XUiPBRPause/ItemList/XUiPBRPausePanelProp')
local XUiPBRPausePanelSkill = require('XUi/XUiPBRGame/XUiPBRPause/ItemList/XUiPBRPausePanelSkill')
local XUiPBRPauseUiPBRPanelDetail = require('XUi/XUiPBRGame/XUiPBRPause/ItemDetail/XUiPBRPauseUiPBRPanelDetail')

function XUiPBRPause:OnAwake()
    self:InitComponents()
end

function XUiPBRPause:InitComponents()
    -- Button
    self.BtnTanchuangCloseWhite:AddEventListener(function() self:OnBtnTanchuangCloseWhiteClick() end)
    self.BtnSettle:AddEventListener(function() self:OnBtnSettleClick() end)
    self.BtnQuit:AddEventListener(function() self:OnBtnQuitClick() end)
   
    -- XUiNode
    ---@type XUiPBRPauseUiPBRPanelStatus
    self.PanelStatus = XUiPBRPauseUiPBRPanelStatus.New(self.UiPBRPanelAttribute, self)
    ---@type XUiPBRPausePanelProp
    self.PanelProp = XUiPBRPausePanelProp.New(self.PanelProp, self)
    ---@type XUiPBRPausePanelSkill
    self.PanelSkill = XUiPBRPausePanelSkill.New(self.PanelSkill, self)
    
    self.UiPBRPanelDetail.gameObject:SetActiveEx(false)
    
    ---@type XUiPBRPauseUiPBRPanelDetail
    self.ItemDetailPanel = XUiPBRPauseUiPBRPanelDetail.New(self.UiPBRPanelDetail, self)
    
    CS.XInputManager.SetCurInputMap(CS.XInputMapId.System)
end

function XUiPBRPause:OnStart(isFight)
    self.IsFight = isFight

    if self.IsFight then
        if CS.XFight.IsRunning then
            CS.XFight.Instance:Pause()
            XDataCenter.FightWordsManager.Pause()
            self:AddRecordStr(CS.XTextManager.GetLuaText("XUiSet.lua_111"))
        end

        if CS.StatusSyncFight.XFightClient.FightInstance then
            CS.StatusSyncFight.XFightClient.FightInstance:OnPauseForClient()
        end
    end

    -- 刷新道具显示
    local itemDict = self._Control.InGameControl:GetOwnedItemIdsByType()

    -- 分别展示道具和技能列表
    self.PanelSkill:RefreshItemShow(itemDict[XMVCA.XPBRGame.EnumConst.ItemType.Skill])
    self.PanelProp:RefreshItemShow(itemDict[XMVCA.XPBRGame.EnumConst.ItemType.Other])

    -- 标题
    local beginData = XDataCenter.FubenManager.GetFightBeginData()
    if beginData and beginData.StageId then
        local stageCfg = self._Control:GetStageCfgById(beginData.StageId)

        if stageCfg then
            local waves = self._Control.InGameControl:GetWaveInSegmentSettleData()
            
            self.TxtTitle.text = XUiHelper.FormatTextEx(self._Control:GetClientPBRText('UIPauseTitle'), stageCfg.StageName, waves)
        end
    end
end

function XUiPBRPause:OnEnable()
    CS.XJoystickLSHelper.ForceResponse = true

    self._Control:AddEventListener(XMVCA.XPBRGame.EventId.EVENT_PBR_INNER_OPEN_ITEM_DETAIL, self.OnItemDetailOpenEvent, self)
end

function XUiPBRPause:OnDisable()
    if self.IsFight then
        if CS.XFight.IsRunning then
            CS.XFight.Instance:Resume()
            XDataCenter.FightWordsManager.Resume()
        end
        if CS.StatusSyncFight.XFightClient.FightInstance then
            CS.StatusSyncFight.XFightClient.FightInstance:OnResumeForClient()
        end
    end
    CS.XJoystickLSHelper.ForceResponse = false

    self._Control:RemoveEventListener(XMVCA.XPBRGame.EventId.EVENT_PBR_INNER_OPEN_ITEM_DETAIL, self.OnItemDetailOpenEvent, self)
end

function XUiPBRPause:OnDestroy()
    CS.XInputManager.SetCurInputMap(CS.XInputManager.BeforeInputMapID)
end


function XUiPBRPause:OnBtnTanchuangCloseWhiteClick()
    self:Close()
end

function XUiPBRPause:OnBtnSettleClick()
    local title = CS.XTextManager.GetText("TipTitle")
    local content = self._Control:GetClientPBRText('BattleSettleByHandTips')
    
    local confirmCb = function()
        self._Control.InGameControl:SetFightExitType(XMVCA.XPBRGame.EnumConst.FightExitType.Settle)
        self:_ForceExitFight(false)
    end

    if self._Control.InGameControl:CheckIsInEndlessMode() then
        -- 无尽模式无需二次确认
        confirmCb()
    else
        XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, nil, confirmCb)
    end
end

function XUiPBRPause:OnBtnQuitClick()
    self._Control.InGameControl:SetFightExitType(XMVCA.XPBRGame.EnumConst.FightExitType.GiveUp)
    
    self:_ForceExitFight(true)
end

function XUiPBRPause:_ForceExitFight(isForce)
    self:CsRecord(XSetConfigs.RecordOperationType.Retreat)
    XMVCA.XDlcRoom:RecordFightQuit(3)
    CS.XFightInterface.Exit(isForce)
    self:Close()
end

function XUiPBRPause:OnItemDetailOpenEvent(posUi, itemId)
    self.ItemDetailPanel:Open()
    self.ItemDetailPanel:RefreshItemShow(posUi, itemId)
end


--region Record- 与通用暂停界面逻辑一致
-- 记录埋点
function XUiPBRPause:CsRecord(type)
    if not CS.XFight.IsRunning then return end
    local dict = {}
    local stageId = CS.XFight.Instance.FightData.StageId
    local stageType = XMVCA.XFuben:GetStageType(stageId)
    if stageType then
        if stageType == XDataCenter.FubenManager.StageType.Arena then
            dict["pve_type"] = stageType
            dict["activity_no"] = XMVCA.XArena:GetActivityNo()
            dict["boss_level"] = 0
            dict["challenge_id"] = XMVCA.XArena:GetActivityCurrentChallengeId()
            dict["boss_id"] = 0
            dict["i_group_id"] = XMVCA.XArena:GetCurrentFightEventGroupId()
            dict["i_buff_id"] = XMVCA.XArena:GetCurrentFightBuffId()
            dict["i_area_id"] = XMVCA.XArena:GetCurrentAreaId()
        elseif stageType == XDataCenter.FubenManager.StageType.BossSingle then
            local data = XMVCA.XFubenBossSingle:GetBossSingleData()
            dict["pve_type"] = stageType
            dict["activity_no"] = data and data:GetBossSingleActivityNo() or 0
            dict["boss_level"] = data and data:GetEnterBossLevel() or 0
            dict["challenge_id"] = 0
            dict["boss_id"] = data and data:GetEnterBossId() or 0
            dict["i_feature_id"] = XMVCA.XFubenBossSingle:GetCurrentFeatureId()
        end
    end

    dict["stage_id"] = stageId
    dict["type"] = type
    CS.XRecord.Record(dict, "200015", "FightStopOperation")
end

function XUiPBRPause:AddRecordStr(str)
    if not CS.XFight.Instance then
        return
    end
    local frame = CS.XFight.Instance.Frame
    CS.XFight.Instance.RoleManager:CheckAddRecordStr(string.format("%s\t%s\tFalse\t%s", frame, str, ""))
end
--endregion

return XUiPBRPause
