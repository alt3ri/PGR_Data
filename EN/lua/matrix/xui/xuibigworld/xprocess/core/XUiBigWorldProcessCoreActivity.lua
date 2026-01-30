local XUiGridBWItem = require("XUi/XUiBigWorld/XCommon/Grid/XUiGridBWItem")
local XUiBigWorldProcessCoreTip = require("XUi/XUiBigWorld/XProcess/Core/Tip/XUiBigWorldProcessCoreTip")
local XUiGirdBigWorldProcessCoreExtra = require("XUi/XUiBigWorld/XProcess/Core/Grid/XUiGirdBigWorldProcessCoreExtra")

---@class XUiBigWorldProcessCoreActivity : XUiNode
---@field ImgBg UnityEngine.UI.RawImage
---@field TxtName UnityEngine.UI.Text
---@field BtnHelp XUiComponent.XUiButton
---@field Content UnityEngine.RectTransform
---@field GridCommon UnityEngine.RectTransform
---@field BtnGo XUiComponent.XUiButton
---@field BtnOngoing XUiComponent.XUiButton
---@field ListProgress UnityEngine.RectTransform
---@field TagNew UnityEngine.RectTransform
---@field Parent XUiBigWorldProcessCore
local XUiBigWorldProcessCoreActivity = XClass(XUiNode, "XUiBigWorldProcessCoreActivity")

function XUiBigWorldProcessCoreActivity:OnStart()
    ---@type XBWCourseCoreElementEntity
    self._Entity = false
    ---@type XUiGridBWItem[]
    self._RewardGridList = {}
    ---@type XUiBigWorldProcessCoreTip
    self._TipUi = XUiBigWorldProcessCoreTip.New(self.PanelState or self.ListProgress, self)
    
    
    self._ExtraGridList = {}
    
    self:_InitUi()
    self:_RegisterButtonClicks()
end

function XUiBigWorldProcessCoreActivity:OnEnable()
    self:_RegisterListeners()
    self:_RegisterSchedules()
    self:_RegisterRedPointEvents()
end

function XUiBigWorldProcessCoreActivity:OnDisable()
    self:_RemoveListeners()
    self:_RemoveSchedules()
end

function XUiBigWorldProcessCoreActivity:OnDestroy()
end

function XUiBigWorldProcessCoreActivity:OnBtnHelpClick()
    if self._Entity then
        local teachId = self._Entity:GetTeachId()

        if XTool.IsNumberValid(teachId) then
            XMVCA.XBigWorldTeach:OpenTeachTipUi(teachId)
        end
    end
end

function XUiBigWorldProcessCoreActivity:OnBtnGoClick()
    if self._Entity then
        local skipId = self._Entity:GetCurrentSkipId()

        if XTool.IsNumberValid(skipId) then
            XMVCA.XBigWorldSkipFunction:SkipTo(skipId)
        end
    end
end

function XUiBigWorldProcessCoreActivity:OnBtnOngoingClick()
    if self._Entity then
        if not self._Entity:IsSkip() then
            local tip = self._Entity:GetUnableSkipTip()

            XMVCA.XBigWorldUI:TipMsg(tip)
        end
    end
end

function XUiBigWorldProcessCoreActivity:OnBtnAdvanceClick()
    if not self._Entity or not self._Entity:IsShowEarlyAccess() then
        if self.BtnAdvance then
            self.BtnAdvance.gameObject:SetActiveEx(false)
        end
        return
    end
    self._Entity:OpenPopupAdvance()
end

---@param elementEntity XBWCourseCoreElementEntity
function XUiBigWorldProcessCoreActivity:Refresh(elementEntity)
    self._Entity = elementEntity
    self.TxtName.text = elementEntity:GetName()
    self.TagNew.gameObject:SetActiveEx(elementEntity:IsNew())
    local showSkip = elementEntity:IsSkip()
    local btnSkipName = elementEntity:GetSkipBtnName() 
    if showSkip and btnSkipName then
        self.BtnGo:SetNameByGroup(0, btnSkipName)
    end
    self.BtnGo.gameObject:SetActiveEx(showSkip)
    if self.BtnAdvance then
        self.BtnAdvance.gameObject:SetActiveEx(elementEntity:IsShowEarlyAccess())
    end
    self.BtnGo:ShowReddot(elementEntity:IsSkipStateChange())
    self._TipUi:Refresh(elementEntity)
    self:_RefreshHelp(elementEntity)
    self:_RefreshLocked(elementEntity)
    self:_RefreshReward(elementEntity)
    self:_RefreshBackground(elementEntity)
    self:_RefreshExtra()
    self:_RefreshComplete(not showSkip and elementEntity:IsComplete())
    elementEntity:RecordSkipState()
end

function XUiBigWorldProcessCoreActivity:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    self.BtnHelp:AddEventListener(handler(self, self.OnBtnHelpClick))
    self.BtnGo:AddEventListener(handler(self, self.OnBtnGoClick))
    self.BtnOngoing:AddEventListener(handler(self, self.OnBtnOngoingClick))
    if self.BtnAdvance then
        self.BtnAdvance:AddEventListener(handler(self, self.OnBtnAdvanceClick))
    end
end

function XUiBigWorldProcessCoreActivity:_RegisterListeners()
    -- 在此处注册事件监听
end

function XUiBigWorldProcessCoreActivity:_RemoveListeners()
    -- 在此处移除事件监听
end

function XUiBigWorldProcessCoreActivity:_RegisterSchedules()
    -- 在此处注册定时器
end

function XUiBigWorldProcessCoreActivity:_RemoveSchedules()
    -- 在此处移除定时器
end

function XUiBigWorldProcessCoreActivity:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

function XUiBigWorldProcessCoreActivity:_InitUi()
    self.GridCommon.gameObject:SetActiveEx(false)
end

---@param elementEntity XBWCourseCoreElementEntity
function XUiBigWorldProcessCoreActivity:_RefreshLocked(elementEntity)
    self.BtnOngoing.gameObject:SetActiveEx(not elementEntity:IsSkip() and not elementEntity:IsComplete())
end

---@param elementEntity XBWCourseCoreElementEntity
function XUiBigWorldProcessCoreActivity:_RefreshHelp(elementEntity)
    self.BtnHelp.gameObject:SetActiveEx(elementEntity:IsHaveTeach())
end

---@param elementEntity XBWCourseCoreElementEntity
function XUiBigWorldProcessCoreActivity:_RefreshBackground(elementEntity)
    self.ImgBg:SetImage(elementEntity:GetBackground())
end

---@param elementEntity XBWCourseCoreElementEntity
function XUiBigWorldProcessCoreActivity:_RefreshReward(elementEntity)
    local rewards = elementEntity:GetRewards()
    local index = 1

    if not XTool.IsTableEmpty(rewards) then
        for i, reward in pairs(rewards) do
            local grid = self._RewardGridList[i]

            if not grid then
                local gridUi = XUiHelper.Instantiate(self.GridCommon, self.Content)

                grid = XUiGridBWItem.New(gridUi, self)
                self._RewardGridList[i] = grid
            end

            grid:Open()
            grid:Refresh(reward)
            grid:RefreshCount()
            index = index + 1
        end
    end
    for i = index, #self._RewardGridList do
        self._RewardGridList[i]:Close()
    end
end

function XUiBigWorldProcessCoreActivity:_RefreshExtra()
    if not self._Entity then
        XTool.UpdateDynamicItem(self._ExtraGridList, nil, self.GirdExtra, XUiGirdBigWorldProcessCoreExtra, self)
        return
    end
    local extra = self._Entity:GetExtraItems()
    XTool.UpdateDynamicItem(self._ExtraGridList, extra, self.GirdExtra, XUiGirdBigWorldProcessCoreExtra, self)
end

function XUiBigWorldProcessCoreActivity:_RefreshComplete(showComplete)
    if not self.ImgCompete then
        return
    end
    self.ImgCompete.gameObject:SetActiveEx(showComplete)
end

---@return XBWCourseCoreElementEntity
function XUiBigWorldProcessCoreActivity:GetEntity()
    return self._Entity
end

return XUiBigWorldProcessCoreActivity
