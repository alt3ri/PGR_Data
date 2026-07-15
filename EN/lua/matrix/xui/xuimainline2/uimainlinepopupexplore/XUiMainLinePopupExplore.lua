---
---@class XUiMainLinePopupExplore: XLuaUi
---@field protected _Control XMainLine2Control
local XUiMainLinePopupExplore = XLuaUiManager.Register(XLuaUi, "UiMainLinePopupExplore")

local XUiGridPopupExploreChoice = require("XUi/XUiMainLine2/UiMainLinePopupExplore/XUiGridPopupExploreChoice")
local XUiInputSignalMediator = require("XUi/XUiCommon/XUiInputSignalMediator")

--region Ui生命周期

function XUiMainLinePopupExplore:OnAwake()
    self.BtnTanchuangClose:AddEventListener(function()
        self:Close()
    end)
    
    ---@type XUiGridPopupExploreChoice[]
    self._ChoiceGridList = {}

    self.BtnChoice.gameObject:SetActiveEx(false)
    ---@type XUiInputSignalMediator
    self.InputSignalMediator = XUiInputSignalMediator.New(self.GameObject, self, self._Control.MessageControl.EnumConst.UIInputTypes)
    self.InputSignalMediator:RegisterSignalHandler(self._Control.MessageControl.EnumConst.UIInputTypes.SelectChoice, handler(self, self.OnSelectChoiceSignal))

    self._ChoiceGridClickHandler = function(index)
        self.InputSignalMediator:ReceiveInputSignal(self._Control.MessageControl.EnumConst.UIInputTypes.SelectChoice, index)
    end
end

function XUiMainLinePopupExplore:OnStart(messagePosId)
    self.MessagePosId = messagePosId
    self.CurContentId = 0
    self.NextContentId = self._Control.MessageControl:GetCfgMessageBeginContentIdById(self.MessagePosId)

    --- 初始化三个子面板

    self.PanelGoods.gameObject:SetActiveEx(false)
    self.PanelCharacter.gameObject:SetActiveEx(false)
    self.PanelSoundWave.gameObject:SetActiveEx(false)

    ---@type XUiPanelMainLinePopupExploreGoods
    self.ItemPanel = require("XUi/XUiMainLine2/UiMainLinePopupExplore/XUiPanelMainLinePopupExploreGoods").New(self.PanelGoods, self)
    ---@type XUiPanelMainLinePopupExploreRole
    self.RolePanel = require("XUi/XUiMainLine2/UiMainLinePopupExplore/XUiPanelMainLinePopupExploreRole").New(self.PanelCharacter, self)
    ---@type XUiPanelMainLinePopupExploreSound
    self.SoundPanel = require("XUi/XUiMainLine2/UiMainLinePopupExplore/XUiPanelMainLinePopupExploreSound").New(self.PanelSoundWave, self)
    
    self:ShowNextContent()
end

function XUiMainLinePopupExplore:OnEnable()
    self.InputSignalMediator:StartInputSignalUpdateTimer()
end

function XUiMainLinePopupExplore:OnDisable()
    self.InputSignalMediator:StopInputSignalUpdateTimer()
    
    -- 关闭的时候检查是否全部选项点完
    self:_TrySetMessageAllRead()
end

function XUiMainLinePopupExplore:OnDestroy()

end

--endregion

function XUiMainLinePopupExplore:ShowNextContent()
    local contentCfg = self._Control.MessageControl:GetTableMainLine2MessageContentsCfgById(self.NextContentId)

    if contentCfg then
        self.CurContentId = self.NextContentId
        
        self:_UpdateContentShow(contentCfg)
    end
end

---@param contentCfg XTableMainLine2MessageContents
function XUiMainLinePopupExplore:_UpdateContentShow(contentCfg)
    if contentCfg.Type == self._Control.MessageControl.EnumConst.MessageContentType.Normal then
        self.ItemPanel:Close()
        self.SoundPanel:Close()
        self.RolePanel:Open()
        
        self.RolePanel:Refresh(contentCfg)
    elseif contentCfg.Type == self._Control.MessageControl.EnumConst.MessageContentType.ItemShow then
        self.SoundPanel:Close()
        self.RolePanel:Close()
        self.ItemPanel:Open()

        self.ItemPanel:Refresh(contentCfg)
    elseif contentCfg.Type == self._Control.MessageControl.EnumConst.MessageContentType.WithAudio then
        self.ItemPanel:Close()
        self.RolePanel:Close()
        self.SoundPanel:Open()

        self.SoundPanel:Refresh(contentCfg)
    end

    if not XTool.IsTableEmpty(self._ChoiceGridList) then
        for i, v in pairs(self._ChoiceGridList) do
            v:Close()
        end
    end
    
    local count = contentCfg.ConfirmContent and #contentCfg.ConfirmContent or 0
    
    XUiHelper.RefreshCustomizedList(self.ListChoice.transform, self.BtnChoice, count, function(index, go)
        local grid = self._ChoiceGridList[go]

        if not grid then
            grid = XUiGridPopupExploreChoice.New(go, self, self._ChoiceGridClickHandler, self.MessagePosId)
        end
        
        grid:Open()
        grid:Refresh(index, contentCfg.Id, contentCfg.ConfirmContent[index] or '')
    end)
end


function XUiMainLinePopupExplore:_TrySetMessageAllRead()
    local curState = self._Control.MessageControl:GetMessageStateById(self.MessagePosId)

    if curState < self._Control.MessageControl.EnumConst.MessageState.AllRead and self._Control.MessageControl:CheckMessageAllReadFromCache(self.MessagePosId) then
        self._Control.MessageControl:DoMainLine2MessageStateUpdateRequest(self.MessagePosId, self._Control.MessageControl.EnumConst.MessageState.AllRead)
    end
end

--region 信号处理

--- 信号处理：选择选项
function XUiMainLinePopupExplore:OnSelectChoiceSignal(index)
    -- 更新内容
    local contentCfg = self._Control.MessageControl:GetTableMainLine2MessageContentsCfgById(self.CurContentId)

    if contentCfg then
        if XTool.IsTableEmpty(contentCfg.NextMessageIds) then
            -- 约定配空表示结束
            self:Close()
            return
        end
        
        local nextId = contentCfg.NextMessageIds[index]

        if not XTool.IsNumberValidEx(nextId) then
            XLog.Error("[主线Message][配置错误]messageContentId：" .. tostring(self.CurContentId) .. '文本内容选项索引：' .. tostring(index) .. '对应的下一个配置不存在')
            return
        end
        
        self.NextContentId = nextId
        
        self:ShowNextContent()
    end
end

--endregion



return XUiMainLinePopupExplore