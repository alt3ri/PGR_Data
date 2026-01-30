local XUiPanelAreaWarDetailTips = XClass(nil, "XUiPanelAreaWarDetailTips")
local OriginProbability = 100 --todo 初始概率
function XUiPanelAreaWarDetailTips:Ctor(ui,parent,toggleGroup,curProbability)
    self.GameObject = ui.gameObject
    self.Parent = parent
    self.Transform = ui.transform
    self.ToggleGroup = toggleGroup
    XTool.InitUiObject(self)
    if self.Parent.Parent then
        self._Control = self.Parent.Parent._Control
    else
        self._Control = self.Parent._Control
    end
    self:InitView()
    if not curProbability then
        curProbability = OriginProbability
    end
    self:Refresh(curProbability)
end

function XUiPanelAreaWarDetailTips:InitView()
    self.CollectionDropPanels = {}
    self.QualityDic = {}
    self.CurQualityDic ={}
    for index, itemConfig in pairs(self._Control:GetConfig():GetConfigItem()) do
        if not self.QualityDic[itemConfig.Quality] then
            self.QualityDic[itemConfig.Quality] = {}
        end
        local unlock = self._Control:IsItemUnlock(itemConfig.ItemId)
        if unlock then
            table.insert(self.QualityDic[itemConfig.Quality], itemConfig.ItemId)
        end
        if itemConfig.EffectType == self._Control.ItemEffectType.GlobaleEffect then
            if unlock then
                if self.Parent._Control:GetItemRoom():GetItemDic()[itemConfig.ItemId] then
                    self.CurQualityDic[itemConfig.ItemId]= 2
                else
                    self.CurQualityDic[itemConfig.ItemId]= 1
                end
            else
                self.CurQualityDic[itemConfig.ItemId]= 0
            end
        end
    end
    self:InitCollectionDropPanel()
    self:InitTokenDropPanel()

    self.Parent.PanelBuff:SetName(self._Control:GetGlobalProbability() .. "%")
    self.Parent.PanelBuff:AddEventListener(handler(self, function ()
        self:Show(true)
        self:RefreshToggleGroup(self.Parent.EmptyClick)
    end))
    self.Parent.EmptyClick:AddEventListener(handler(self,function ()
        self:Hide()
        self.Parent.EmptyClick.gameObject:SetActiveEx(false)
    end))
   
end

function XUiPanelAreaWarDetailTips:InitCollectionDropPanel()
    self.PanelCollectionDrop.gameObject:SetActiveEx(false)
    local bindPanelObj = function(panel, itemIds)
        local obj = {}
        XTool.InitUiObjectByUi(obj, panel)
        obj.GridItem.gameObject:SetActiveEx(false)
        for _, itemId in pairs(itemIds) do
            local itemGo = CS.UnityEngine.GameObject.Instantiate(obj.GridItem.gameObject, obj.GridItem.parent.transform)
            itemGo.gameObject:SetActiveEx(true)
            local btnData = itemGo:GetComponent("XUiButton")
            local itemConfig = self._Control:GetConfig():GetConfigItem(itemId)
            btnData:SetRawImage(itemConfig.Icon)
            local icon = self._Control:GetConfig():GetItemQualityIcon(itemConfig.Quality)
            btnData:SetSprite(icon)
            btnData:AddEventListener(handler(self,function()
                XLuaUiManager.Open("UiAreaWarPopupCollectionTip", itemId)
            end))
        end
        return obj
    end
    for i = #self.QualityDic, 1, -1 do
        local quality = i
        local v = self.QualityDic[i]
        if #v > 0 then
            local prefab = CS.UnityEngine.GameObject.Instantiate(self.PanelCollectionDrop.gameObject,
                self.PanelCollectionDrop.parent.transform)
            local panel = bindPanelObj(prefab, v)
            prefab:SetActiveEx(true)
            self.CollectionDropPanels[quality] = panel
            panel.TxtTitle.text = XUiHelper.GetText("XAreaWarDetail" .. i)
            panel.GameObject:SetActiveEx(true)
        end
    end
end
function XUiPanelAreaWarDetailTips:InitTokenDropPanel()
    self.TokenDropPanel ={}
    XTool.InitUiObjectByUi(self.TokenDropPanel, self.PanelTokenDrop)
    self.TokenDropPanel.GridItem.gameObject:SetActiveEx(false)
    for itemId,status in pairs(self.CurQualityDic) do
        local itemConfig = self._Control:GetConfig():GetConfigItem(itemId)
        if itemConfig.EffectType == self._Control.ItemEffectType.GlobaleEffect then
            local itemGo = CS.UnityEngine.GameObject.Instantiate(self.TokenDropPanel.GridItem.gameObject, self.TokenDropPanel.GridItem.parent.transform)
            itemGo.gameObject:SetActiveEx(true)
            local btnData = itemGo:GetComponent("XUiButton")
            btnData:SetRawImage(itemConfig.Icon)
            local icon = self._Control:GetConfig():GetItemQualityIcon(itemConfig.Quality)
            btnData:SetSprite(icon)
            btnData:SetName("+"..tostring(math.floor(itemConfig.EffectProbability/100)).."%")
            btnData:SetDisable(status == 0)
            local mask =itemGo.transform:Find("ImgMask")
            if mask then
                mask.gameObject:SetActiveEx(status == 1)
            end
            btnData:AddEventListener(handler(self, function()
                XLuaUiManager.Open("UiAreaWarPopupCollectionTip", itemId)
            end))

        end
    end

end
function XUiPanelAreaWarDetailTips:Refresh(curProbability)
    for quality, panel in pairs(self.CollectionDropPanels) do
        local isShow = curProbability ~= OriginProbability and quality >= XMVCA.XAreaWar.EnumConst.SHOW_PROBABILITY_MIN_QUALITY
        panel.TxtNum.transform.parent.gameObject:SetActiveEx(isShow)
        panel.TxtNum.text = "x" .. curProbability .. "%"
    end
end

function XUiPanelAreaWarDetailTips:Show(showCurProbility)
    self.GameObject:SetActiveEx(true)
    self.TokenDropPanel.GameObject:SetActiveEx(showCurProbility)
    for _, panel in pairs(self.CollectionDropPanels) do
        panel.GameObject:SetActiveEx(not showCurProbility)
    end
end

function XUiPanelAreaWarDetailTips:Hide()
    self.GameObject:SetActiveEx(false)
     for _,tog in pairs(self.ToggleGroup) do
        if tog.ImgSelectKuang then
            tog.ImgSelectKuang.gameObject:SetActiveEx(false)
        end
    end
end
function XUiPanelAreaWarDetailTips:RefreshToggleGroup(target)
    self.Parent.CurSelectProbabilityItem = nil
    if target.ImgSelectKuang then
        target.ImgSelectKuang.gameObject:SetActiveEx(true)
    end
    self.Parent.EmptyClick.gameObject:SetActiveEx(true)
end
return XUiPanelAreaWarDetailTips
