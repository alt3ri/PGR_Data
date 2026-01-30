---@class XUiAreaWarRare : XLuaUi
---@field private _Control XAreaWarControl
local XUiAreaWarRare = XLuaUiManager.Register(XLuaUi, "UiAreaWarRare")

function XUiAreaWarRare:OnAwake()
    self.Grid256New.gameObject:SetActiveEx(false)
    self:RegisterUiEvents()

    ---@type XUiGridAreaWarItem
    self.GridAreaWarItem = require("XUi/XUiAreaWar/XUiGridAreaWarItem").New(self.GridCostItem, self)
    ---@type XUiPanelAreaWarRareTab
    self.UiPanelTab = require("XUi/XUiAreaWar/XUiPanelAreaWarRareTab").New(self.PanelTab, self)

    -- 场景初始化
    self.PanelWeapon = self.UiModelGo.transform:FindTransform("PanelWeapon")
end

function XUiAreaWarRare:OnStart()
    self.DataList = self._Control:GetConfig():GetRareItems()
    self.SelectedIndex = 1
end

function XUiAreaWarRare:OnEnable()
    self:RefreshSelectRare()
end

function XUiAreaWarRare:OnDisable()
    
end

function XUiAreaWarRare:OnDestroy()
    self:RemoveObtainTimer()
end

function XUiAreaWarRare:OnGetLuaEvents()
    return {
        XEventId.EVENT_AREA_WAR_ITEM_ROOM_ITEM_CHANGE
    }
end

function XUiAreaWarRare:OnNotify(evt, ...)
    if evt == XEventId.EVENT_AREA_WAR_ITEM_ROOM_ITEM_CHANGE then
        self:RefreshGridAreaWarItem()
    end
end

function XUiAreaWarRare:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:RegisterClickEvent(self.BtnNext, self.OnBtnNextClick)
    self:RegisterClickEvent(self.BtnLast, self.OnBtnLastClick)
    self:RegisterClickEvent(self.BtnLightUp, self.OnBtnLightUpClick)
    self:RegisterClickEvent(self.BtnGet, self.OnBtnGetClick)
end

function XUiAreaWarRare:OnBtnBackClick()
    self:Close()
end

function XUiAreaWarRare:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiAreaWarRare:OnBtnNextClick()
    if self.SelectedIndex < #self.DataList then
        self.SelectedIndex = self.SelectedIndex + 1
    else
        self.SelectedIndex = 1
    end
    self:RefreshSelectRare()
end

function XUiAreaWarRare:OnBtnLastClick()
    if self.SelectedIndex > 1 then
        self.SelectedIndex = self.SelectedIndex - 1
    else
        self.SelectedIndex = #self.DataList
    end
    self:RefreshSelectRare()
end

function XUiAreaWarRare:OnBtnLightUpClick()
    local itemId = self:GetSelectItemId()
    local isSubmit = self._Control:GetItemRoom():IsRaceItemSubmit(itemId)
    if isSubmit then return end
    
    local ownNum = self._Control:GetItemRoom():GetItemNum(itemId)
    if ownNum < XMVCA.XAreaWar.EnumConst.SUBMIT_NUM then
        local tips = XAreaWarConfigs.GetLightUpNoEnoughTips()
        XUiManager.TipError(tips)
        return
    end
    
    XMVCA.XAreaWar:RequestAreaWar4SubmitRaceItem(itemId, function(rewards)
        self:OnSubmitRaceItemSuccess()
        self:StartObtainTimer(rewards)
    end)
end

function XUiAreaWarRare:OnBtnGetClick()
    local itemId = self:GetSelectItemId()
    XLuaUiManager.Open("UiAreaWarPopupCollectionTip", itemId)
end

-- 提交珍稀道具成功
function XUiAreaWarRare:OnSubmitRaceItemSuccess()
    -- 刷新选中Ui
    self:RefreshSelectRare()
    -- 刷新Tab
    self.UiPanelTab:OnSubmitRaceItemSuccess()
    -- 播放动效
    self.FxUiCharacterV2QiuUnLock01.gameObject:SetActiveEx(true)
end

function XUiAreaWarRare:OnItemClick(index)
    self.SelectedIndex = index
    self:RefreshSelectRare()
end

-- 获取选中的ItemId
function XUiAreaWarRare:GetSelectItemId()
    return self.DataList[self.SelectedIndex].ItemId
end

-- 刷新选中的藏品信息
function XUiAreaWarRare:RefreshSelectRare()
    local itemId = self:GetSelectItemId()
    
    -- 名称、描述
    self.TxtName.text = self._Control:GetConfig():GetItemName(itemId)
    self.TxtDescription.text = self._Control:GetConfig():GetItemDesc(itemId)
    
    -- 消耗item
    self:RefreshGridAreaWarItem()
    
    -- 奖励
    self:RefreshPanelReward()
    
    -- 点亮按钮/获取材料按钮
    self.BtnGet.gameObject:SetActiveEx(false)
    self.BtnLightUp.gameObject:SetActiveEx(false)
    local isSubmit = self._Control:GetItemRoom():IsRaceItemSubmit(itemId)
    if isSubmit then
        self.BtnLightUp.gameObject:SetActiveEx(true)
        self.BtnLightUp:SetDisable(true)
        self.BtnLightUp:ShowReddot(false)
    else
        local ownNum = self._Control:GetItemRoom():GetItemNum(itemId)
        if ownNum > 0 then
            self.BtnLightUp.gameObject:SetActiveEx(true)
            self.BtnLightUp:SetDisable(false)
            self.BtnLightUp:ShowReddot(true)
        else
            self.BtnGet.gameObject:SetActiveEx(true)
        end
    end
    self.RareLock.gameObject:SetActiveEx(not isSubmit)
    
    -- 页签显示
    self.UiPanelTab:RefreshSelectItemId(itemId)

    -- 刷新模型
    self:RefreshModel()
    
    -- 隐藏动效
    self.FxUiCharacterV2QiuUnLock01.gameObject:SetActiveEx(false)
end

-- 刷新消耗Item
function XUiAreaWarRare:RefreshGridAreaWarItem()
    local itemId = self:GetSelectItemId()
    local isSubmit = self._Control:GetItemRoom():IsRaceItemSubmit(itemId)
    if not isSubmit then
        self.GridAreaWarItem:Open()
        self.GridAreaWarItem:RefreshItemByCost(itemId, XMVCA.XAreaWar.EnumConst.SUBMIT_NUM)
    else
        self.GridAreaWarItem:Close()
    end
end

-- 刷新奖励面板
function XUiAreaWarRare:RefreshPanelReward()
    local itemId = self:GetSelectItemId()
    local isSubmit = self._Control:GetItemRoom():IsRaceItemSubmit(itemId)
    local rewardId = self._Control:GetConfig():GetRareRewardId(itemId)
    local rewardItems = XRewardManager.GetRewardList(rewardId)
    self.Items = self.Items or {}
    local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
    XUiHelper.CreateTemplates(self, self.Items, rewardItems, XUiGridCommon.New, self.Grid256New, self.Grid256New.transform.parent, function(grid, data)
        grid:Refresh(data, nil, nil, false)
        grid.ImgObtain.gameObject:SetActiveEx(isSubmit)
    end)
end

function XUiAreaWarRare:RefreshModel()
    local itemId = self:GetSelectItemId()
    local modelId = self._Control:GetConfig():GetItemModelId(itemId)
    local modelConfig = self._Control:GetConfig():GetConfigModel(modelId)
    local model = self.PanelWeapon:LoadPrefab(modelConfig.ModelUrl, false)
    self.Model = model

    -- 模型位置
    model.transform.localPosition = XLuaVector3.New(modelConfig.PositionX, modelConfig.PositionY, modelConfig.PositionZ)
    -- 模型旋转
    model.transform.localEulerAngles = XLuaVector3.New(modelConfig.RotationX, modelConfig.RotationY, modelConfig.RotationZ)
    -- 模型大小
    model.transform.localScale = XLuaVector3.New(
        modelConfig.ScaleX == 0 and 1 or modelConfig.ScaleX,
        modelConfig.ScaleY == 0 and 1 or modelConfig.ScaleY,
        modelConfig.ScaleZ == 0 and 1 or modelConfig.ScaleZ
    )

    -- 设置旋转
    XModelManager.DragRotateWeapon(self.PanelDrag, model, nil, self.GameObject, true, nil, true)
    
    -- 未提交时添加模型特效
    local isSubmit = self._Control:GetItemRoom():IsRaceItemSubmit(itemId)
    if not isSubmit then
        self:AddModelEffect()
    else
        self:RemoveModelEffect()
    end
end

-- 添加模型特效
function XUiAreaWarRare:AddModelEffect()
    local effectPath = XAreaWarConfigs.GetRareModelUnlockEffect()
    self.ModelEffect = self.Model:LoadPrefab(effectPath)
    local renderingProxy = CS.XNPCRendingUIProxy.GetNPCRendingUIProxy(self.Model)
    renderingProxy:BindEffect(self.ModelEffect)
    self.ModelEffect.gameObject:SetActiveEx(false)
    self.ModelEffect.gameObject:SetActiveEx(true)
end

-- 移除模型特效
function XUiAreaWarRare:RemoveModelEffect()
    if self.ModelEffect then
        self.ModelEffect.gameObject:SetActiveEx(false)
    end
end

-- 延迟弹出奖励弹窗，先播动效
function XUiAreaWarRare:StartObtainTimer(rewards)
    self:RemoveObtainTimer()
    self.ObtainTimer = XScheduleManager.ScheduleOnce(function()
        self.ObtainTimer = nil
        XUiManager.OpenUiObtain(rewards)
    end, 1000)
end

function XUiAreaWarRare:RemoveObtainTimer()
    if self.ObtainTimer then
        XScheduleManager.UnSchedule(self.ObtainTimer)
        self.ObtainTimer = nil
    end
end

return XUiAreaWarRare
