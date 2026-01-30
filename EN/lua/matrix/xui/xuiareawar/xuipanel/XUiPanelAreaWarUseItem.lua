local XUiPanelAreaWarUseItem = XClass(nil, "XUiPanelAreaWarUseItem")
local OriginProbability = 100 --todo 初始概率
function XUiPanelAreaWarUseItem:Ctor(ui, parent)

    self.GameObject = ui.gameObject
    self.Parent = parent
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    if self.Parent.Parent then
        self._Control = self.Parent.Parent._Control
    else
        self._Control = self.Parent._Control
    end
    self:InitView()
    XDataCenter.AreaWarManager.SetUsingProbabilityItems(nil)
    XEventManager.AddEventListener(XEventId.EVENT_AREA_WAR_ITEM_ROOM_ITEM_CHANGE, self.RefreshView, self)
end

function XUiPanelAreaWarUseItem:InitView()

    local showItem = false
    self.GridItem.gameObject:SetActiveEx(false)
    self.SelectStatus = {}
    self.AllUseItem = {}
    local items ={}
    local roomItemsDic = self._Control:GetItemRoom():GetItemDic()
    for index, itemConfig in pairs(self._Control:GetConfig():GetConfigItem()) do
        local item = roomItemsDic[itemConfig.ItemId]
        if item and itemConfig.EffectType == self._Control.ItemEffectType.UsingEffect then
            table.insert(items,item)
        else
            if itemConfig.EffectType == self._Control.ItemEffectType.UsingEffect then
                table.insert(items,{ ItemId = itemConfig.ItemId, Num = 0 })
            end
        end
        if not showItem and (itemConfig.Quality == 4 or itemConfig.Quality == 5) then 
            if self._Control:IsItemUnlock(itemConfig.ItemId) then
                showItem = true
            end
        end
    end
    table.sort(items,function(a,b)
        return a.ItemId>b.ItemId
    end)
    for k,item in pairs(items)do
        local prefab = CS.UnityEngine.GameObject.Instantiate(self.GridItem.gameObject, self.GridItem.transform.parent)
        local itemConfig = self._Control:GetConfig():GetConfigItem(item.ItemId)
        local gridUi = self:BindUseItem(item, itemConfig, prefab, item.Num == 0)
        gridUi.GameObject:SetActiveEx(true)
        self.AllUseItem[item.ItemId] = gridUi
    end
    self.GameObject:SetActiveEx(showItem)
    self:RefreshProbability(0,true)
end

function XUiPanelAreaWarUseItem:RefreshView() 
    if self.GameObject:Equals(nil) then
        return
    end
    local roomItemsDic = self._Control:GetItemRoom():GetItemDic()
    for id,gridUi in pairs(self.AllUseItem) do
        local itemConfig = self._Control:GetConfig():GetConfigItem(id)
        local selfBtn = gridUi.GameObject:GetComponent("XUiButton")
        local disable = true
        if roomItemsDic[id] then
            disable = roomItemsDic[id].Num ==0
            selfBtn:SetNameByGroup(0, roomItemsDic[id].Num)
        else
            selfBtn:SetNameByGroup(0, 0)
        end
        selfBtn:SetDisable(disable)
        gridUi.BtnClick:AddEventListener(handler(self, function()
            self:OnSelect(gridUi,disable, itemConfig)
        end),true)
        if self.SelectStatus[id]  then
            self.SelectStatus[id] = false
            self:RefreshProbability(math.floor(itemConfig.EffectProbability/100), self.SelectStatus[itemConfig.ItemId])
        end
    end
end

function XUiPanelAreaWarUseItem:BindUseItem(itemData, itemConfig, grid, disable)
    local obj = {}
    XTool.InitUiObjectByUi(obj, grid)
    local selfBtn = obj.GameObject:GetComponent("XUiButton")
    selfBtn:SetNameByGroup(1, "+" .. math.floor(itemConfig.EffectProbability/100) .. "%")
    selfBtn:SetNameByGroup(0, itemData.Num)
    selfBtn:SetRawImage(itemConfig.Icon)
    selfBtn.transform:Find("Select/RImgIcon"):GetComponent(typeof(CS.UnityEngine.UI.RawImage)):SetRawImage(itemConfig.Icon)
    selfBtn.transform:Find("Disable/RImgIcon"):GetComponent(typeof(CS.UnityEngine.UI.RawImage)):SetRawImage(itemConfig.Icon)
    selfBtn:SetDisable(disable)
    
    obj.BtnClick:AddEventListener(handler(self, function()
        self:OnSelect(obj,disable, itemConfig)
    end))
    return obj
end

function XUiPanelAreaWarUseItem:OnSelect(btnobj,disable, itemConfig)
    if disable then
        XLuaUiManager.Open("UiAreaWarPopupCollectionTip", itemConfig.ItemId)
        return
    end
    
    self.SelectStatus[itemConfig.ItemId] = not self.SelectStatus[itemConfig.ItemId]
    local btn = btnobj.GameObject:GetComponent("XUiButton")
    if self.SelectStatus[itemConfig.ItemId] then
        btn:SetButtonState(CS.UiButtonState.Select)
    else
        btn:SetButtonState(CS.UiButtonState.Normal)
    end
    self:RefreshProbability(math.floor(itemConfig.EffectProbability/100), self.SelectStatus[itemConfig.ItemId])
end

function XUiPanelAreaWarUseItem:GetUsingItem()
    local usingItems = {}
    for key, value in pairs(self.SelectStatus) do
        if value then
        table.insert(usingItems,key)
        end
    end
    XDataCenter.AreaWarManager.SetUsingProbabilityItems(usingItems)
end

function XUiPanelAreaWarUseItem:RefreshProbability(probability,add)
        if not self.OriginProbability then
        self.OriginProbability = OriginProbability
    end
    if add then
        self.OriginProbability = self.OriginProbability + probability
    else
        self.OriginProbability = self.OriginProbability - probability
    end
    if self.Parent.GridPorbabilityItem then
        self.Parent.GridPorbabilityItem.TxtNum.transform.parent.gameObject:SetActiveEx(self.OriginProbability ~= OriginProbability)
        self.Parent.GridPorbabilityItem.TxtNum.text ="x".. self.OriginProbability.."%"
    end
    if self.Parent.GridPorbabilityItemFight then
         self.Parent.GridPorbabilityItemFight.TxtNum.transform.parent.gameObject:SetActiveEx(self.OriginProbability ~= OriginProbability)
        self.Parent.GridPorbabilityItemFight.TxtNum.text ="x".. self.OriginProbability.."%"
    end
    self.Parent.PanelTips:Refresh(self.OriginProbability)
end


function XUiPanelAreaWarUseItem:OnDestory()
    XEventManager.RemoveEventListener(XEventId.EVENT_AREA_WAR_ITEM_ROOM_ITEM_CHANGE, self.RefreshView, self)
end
return XUiPanelAreaWarUseItem
