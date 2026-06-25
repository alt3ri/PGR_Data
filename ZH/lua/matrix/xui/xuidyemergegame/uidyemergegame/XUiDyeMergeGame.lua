--- 局内界面
---@class XUiDyeMergeGame: XLuaUi
---@field protected _Control XDyeMergeGameControl
local XUiDyeMergeGame = XLuaUiManager.Register(XLuaUi, "UiDyeMergeGame")
local XUiGridDyeMergeColorTips = require("XUi/XUiDyeMergeGame/UiDyeMergeGame/XUiGridDyeMergeColorTips")

--region Ui生命周期

function XUiDyeMergeGame:OnAwake()
    self:_InitInputMediator()    
    
    self.BtnNextStage:AddEventListener(handler(self, self._OnBtnNextStageClick))
    self.PanelFinish.gameObject:SetActiveEx(false)
end

function XUiDyeMergeGame:OnStart(stageId)
    self.StageId = stageId
    self._Control:EnterGame(self.StageId)

    self.PanelBoard = require("XUi/XUiDyeMergeGame/UiDyeMergeGame/XUiPanelDyeMergeBoard").New(self.PanelCheckerboard, self)
    ---@type XUiComDyeMergeGameAction
    self.ComAction = require("XUi/XUiDyeMergeGame/UiDyeMergeGame/Com/XUiComDyeMergeGameAction").New(self.GameObject, self)
    ---@type XUiPanelDyeMergeFinish
    self.PanelStageFinish = require("XUi/XUiDyeMergeGame/UiDyeMergeGame/XUiPanelDyeMergeFinish").New(self.PanelFinish, self)

    if self.PanelTipsWindow then
        self.PanelTipsWindow.gameObject:SetActiveEx(false)
        
        ---@type XUiPanelTipsSmallWindow
        self.TipsWindow = require("XUi/XUiDyeMergeGame/UiDyeMergeGame/XUiPanelTipsSmallWindow").New(self.PanelTipsWindow, self)
    end
    
    self:_InitStageInfoShow()
end

--- 切换到新关卡（不关闭界面，直接刷新）
function XUiDyeMergeGame:_EnterStage(stageId)
    self.StageId = stageId
    self._Control:EnterStage(stageId)
    self:_InitStageInfoShow()
    self.PanelBoard:ResetBoard()
    
    XDataCenter.GuideManager.CheckGuideOpen()
end

function XUiDyeMergeGame:OnEnable()
    self._InputMediator:StartInputSignalUpdateTimer()
    
    self._Control.GamingControl:AddEventListener(XMVCA.XDyeMergeGame.EventIds.EVENT_DYEMERGE_INNER_STAGE_PASSED, self._OnStagePassedEvent, self)
    self._Control.GamingControl:AddEventListener(XMVCA.XDyeMergeGame.EventIds.EVENT_DYEMERGE_INNER_REFRESH_TIPS_WINDOW, self._RefreshTipsWindowShow, self)
end

function XUiDyeMergeGame:OnDisable()
    self._InputMediator:StopInputSignalUpdateTimer()

    self._Control.GamingControl:RemoveEventListener(XMVCA.XDyeMergeGame.EventIds.EVENT_DYEMERGE_INNER_STAGE_PASSED, self._OnStagePassedEvent, self)
    self._Control.GamingControl:RemoveEventListener(XMVCA.XDyeMergeGame.EventIds.EVENT_DYEMERGE_INNER_REFRESH_TIPS_WINDOW, self._RefreshTipsWindowShow, self)
end

function XUiDyeMergeGame:OnDestroy()
    self._Control:ExitGame()
end

--endregion

function XUiDyeMergeGame:_InitInputMediator()
    ---@type XUiInputSignalMediator
    self._InputMediator = require("XUi/XUiCommon/XUiInputSignalMediator").New(self.GameObject, self, self._Control.EnumConst.UIInputTypes)
    self._InputMediator:SetUpdateIntervalTime(50)
    
    self._InputMediator:RegisterSignalHandler(self._Control.EnumConst.UIInputTypes.ClickHelp, handler(self, self._OnClickHelpSignal))
    self._InputMediator:RegisterSignalHandler(self._Control.EnumConst.UIInputTypes.ClickBack, handler(self, self._OnClickBackSignal))
    self._InputMediator:RegisterSignalHandler(self._Control.EnumConst.UIInputTypes.GamingClickReset, handler(self, self._OnGamingClickResetSignal))
    self._InputMediator:RegisterSignalHandler(self._Control.EnumConst.UIInputTypes.GamingClickTips, handler(self, self._OnGamingClickTipsSignal))
    self._InputMediator:RegisterSignalHandler(self._Control.EnumConst.UIInputTypes.GamingClickGrid, handler(self, self._OnGamingClickGridSignal))
    self._InputMediator:RegisterSignalHandler(self._Control.EnumConst.UIInputTypes.GamingClickFloor, handler(self, self._OnGamingClickFloorSignal))

    self.BtnBack:AddEventListener(function()
        self._InputMediator:ReceiveInputSignal(self._Control.EnumConst.UIInputTypes.ClickBack)
    end)
    
    self.BtnReset:AddEventListener(function()
        self._InputMediator:ReceiveInputSignal(self._Control.EnumConst.UIInputTypes.GamingClickReset)
    end)
    
    self.BtnTips:AddEventListener(function()
        self._InputMediator:ReceiveInputSignal(self._Control.EnumConst.UIInputTypes.GamingClickTips)
    end)
    
    self.BtnHelp:AddEventListener(function()
        self._InputMediator:ReceiveInputSignal(self._Control.EnumConst.UIInputTypes.ClickHelp)
    end)
end

function XUiDyeMergeGame:_InitStageInfoShow()
    -- 小窗模式
    if self.TipsWindow then
        self.TipsWindow:Close()
    end
    
    self.GridColorTips.gameObject:SetActiveEx(false)
    
    local stageCfg = XMVCA.XDyeMergeGame:GetTableDyeMergeStageById(self.StageId)

    if not stageCfg then
        return
    end

    self.TxtTitle.text = stageCfg.Name

    self:_InitButtonShow()
    
    -- 合成规则图片
    local mapperIds = stageCfg.RuleTipsMapperIds
    if XTool.IsTableEmpty(mapperIds) then 
        return
    end

    self.GridColorTips.gameObject:SetActiveEx(false)
    local gc = self._Control.GamingControl

    if self._TipsGrids == nil then
        self._TipsGrids = {}
    else
        for i, v in pairs(self._TipsGrids) do
            v:Close()
        end
    end

    XUiHelper.RefreshCustomizedList(self.GridColorTips.transform.parent, self.GridColorTips, #mapperIds, function(index, go)
        local grid = self._TipsGrids[go]

        if not grid then
            grid = XUiGridDyeMergeColorTips.New(go, self)
            self._TipsGrids[go] = grid
        end

        grid:Open()
        
        local mapperCfg = gc:GetTableDyeMergeColorMapper(mapperIds[index])
        if mapperCfg then
            grid:RefreshIcons(mapperCfg.Icons)
        end
    end)
    
    self.PanelBoard:UpdateBoardTransform(stageCfg.BoardOffsetX, stageCfg.BoardOffsetY, stageCfg.BoardScale)
end

function XUiDyeMergeGame:_InitButtonShow()
    self.BtnReset.gameObject:SetActiveEx(true)
    -- 提示按钮
    self.BtnTips.gameObject:SetActiveEx(XMVCA.XDyeMergeGame:GetIsStageHasTipsImageById(self.StageId))
    self.BtnNextStage.gameObject:SetActiveEx(false)
end
--region 信号处理

function XUiDyeMergeGame:_OnClickHelpSignal()
    if self._Control.GamingControl:CheckIsAnimationLocked() then return end
    XUiManager.ShowHelpTip(XMVCA.XDyeMergeGame:GetCurActivityHelpKey())
end

function XUiDyeMergeGame:_OnClickBackSignal()
    if self._Control.GamingControl:CheckIsAnimationLocked() then return end
    if self._Control.GamingControl._IsStagePassed then
        self:Close()
        return
    end
    local content = XMVCA.XDyeMergeGame:GetClientDyeMergeTextByKey("ExitGameTips")
    local title = CS.XTextManager.GetText("TipTitle")

    XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, nil, function()
        self:Close()
    end)
end

function XUiDyeMergeGame:_OnGamingClickResetSignal()
    if self._Control.GamingControl:CheckIsInteractionLocked() then return end
    local gc = self._Control.GamingControl

    -- 关卡未变化时跳过全量重置
    if not gc._IsDirty then
        -- 有选中方块时取消选中，恢复视觉态
        if gc._IsSelect and gc._SelectUid then
            gc:_ExecuteCancelSelect(gc._SelectUid)
        end
        return
    end

    -- 保存首次进关时的基准快照引用（ResetGame 内部 InitGame 会覆盖 _TestInitSnapshot）
    local baselineLogicSnapshot = gc._TestInitSnapshot
    -- local baselineViewSnapshot = self.PanelBoard:TestTakeViewSnapshot()

    -- Phase 1：逻辑层重置
    gc:ResetGame()

    -- Phase 2：表现层重建
    self.PanelBoard:ResetBoard()

    -- [Test] 将重置后的状态与首次进关的基准快照比对
    if baselineLogicSnapshot then
        gc:TestCompareLogicSnapshot(baselineLogicSnapshot)
    end
    -- if baselineViewSnapshot then
    --     self.PanelBoard:TestCompareViewSnapshot(baselineViewSnapshot)
    -- end
end

function XUiDyeMergeGame:_OnGamingClickTipsSignal()
    if self._Control.GamingControl:CheckIsAnimationLocked() then return end
    self._Control.GamingControl:MarkTipsViewed()
    
    local tipsImg = XMVCA.XDyeMergeGame:GetCfgStageTipsImageById(self.StageId)
    
    XLuaUiManager.OpenWithCloseCallback("UiDyeMergePopupTips", function() 
        self:_RefreshTipsWindowShow()
    end, tipsImg)
end

function XUiDyeMergeGame:_OnGamingClickGridSignal(uid)
    self._Control.GamingControl:OnUiGridClick(uid)
end

function XUiDyeMergeGame:_OnGamingClickFloorSignal(posIndex)
    local x, y = self._Control.GamingControl:IndexToVec2(posIndex)
    self._Control.GamingControl:OnUiFloorClick(x, y)
end

--endregion

function XUiDyeMergeGame:_OnStagePassedEvent(nextStageId)
    self.PanelStageFinish:Open()

    self.BtnTips.gameObject:SetActiveEx(false)
    self.BtnNextStage.gameObject:SetActiveEx(true)
    
    self._NextStageId = nextStageId
    
    self.BtnReset.gameObject:SetActiveEx(false)
    
    self.BtnNextStage:SetNameByGroup(0, XMVCA.XDyeMergeGame:GetClientConfigBtnNameInPassed(XTool.IsNumberValidEx(self._NextStageId)))
end

function XUiDyeMergeGame:_OnBtnNextStageClick()
    if XTool.IsNumberValidEx(self._NextStageId) then
        self.PanelFinish.gameObject:SetActiveEx(false)
        
        local nextStageId = self._NextStageId
        self._NextStageId = nil

        XMVCA.XDyeMergeGame.Network:DoDyeMergeTryEnterStageRequest(nextStageId, function(success)
            if success then
                self:_EnterStage(nextStageId)
            end
        end)
    else
        self:Close()
    end
end

function XUiDyeMergeGame:_RefreshTipsWindowShow()
    -- 刷新小窗
    if self.TipsWindow then
        if self._Control.GamingControl:GetIsTipsSmallWindowOpen() then
            local tipsImg = XMVCA.XDyeMergeGame:GetCfgStageTipsImageById(self.StageId)
            
            self.TipsWindow:Open()
            self.TipsWindow:Refresh(tipsImg)
        else
            self.TipsWindow:Close()
        end
    end
end

return XUiDyeMergeGame