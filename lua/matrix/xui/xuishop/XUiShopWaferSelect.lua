local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
--[[
    v1.29 商店优化
    优化当前分解商店-意识商店的筛选功能
        （1）去掉当前【位置】筛选按钮，以及下拉选择位置的下拉条
        （2）将原【位置】按钮替换成【切换套装】按钮。
        （3）进入分解-意识商店时，默认选中套装为排序第一意识套装（康德丽娜）
        （4）点击【切换套装】按钮，弹出二级界面，显示所有可选择的意识套装图标、名称、属性简介。
        （5）选中某一意识套装后，点击【确认】按钮后，关闭二级界面，商店刷新为对应意识，显示顺序按照意识位置从一到六依次显示。
        （6）5星和4星意识商店中有材料道具，【切换套装】按钮变成【筛选】按钮，同时在筛选界面新增分类：【其他类】。
        （7）选中【其他类】，商店刷新对应的除意识外的道具。
        （8）【2】—【5】步骤的操作逻辑参考【战斗——资源——作战补给——资源商店——切换套装】的操作逻辑，可直接复用，需要特殊处理不属于意识类的道具
--]]
local XUiShopWaferSelect = XLuaUiManager.Register(XLuaUi, "UiShopWaferSelect")
local Equip_Type = {
    SuitAssistant = 8, --"辅助"
    SuitCommon = 9,--"通用"
    SuitEffect = 10, --效应
    SuitAll = 11, --全部
}

function XUiShopWaferSelect:OnAwake()
    self:InitComponent()
    self:InitDynamicTable()
end

function XUiShopWaferSelect:OnStart(SelectData, dataProvider, selectCallBack)
    self.DataProvider = {}
    self.OrginDataProvider = {}

    for i = #dataProvider, 1, -1 do
        table.insert(self.OrginDataProvider,dataProvider[i])
        table.insert(self.DataProvider,dataProvider[i])
    end
    self.SelectCallBack = selectCallBack
    self.CurData = SelectData
    self:_InitTags()
    self:UpdateGridList()
end

function XUiShopWaferSelect:InitComponent()
    self.BtnConfirm.CallBack = function() self:OnBtnConfirmClick() end
    self.BtnClose.CallBack = function() self:OnBtnCloseClick() end
    self.BtnCancel.CallBack = function() self:OnBtnCloseClick() end
    self.BtnTanchuangClose.CallBack = function() self:OnBtnCloseClick() end
    self.GridSuitSimple.gameObject:SetActiveEx(false)
end

function XUiShopWaferSelect:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelSelectList.gameObject)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(require("XUi/XUiShop/XUiShopWaferSelectGrid"))
end

function XUiShopWaferSelect:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.DataProvider[index]
        self:UpdateGrid(grid, data)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        local data = self.DataProvider[index]
        self:OnGridClick(data)
    end
end

function XUiShopWaferSelect:OnGridClick(data)
    if self.CurData.WaferData == data then
        self.CurData.WaferData = nil
    else
        self.CurData.WaferData = data
    end

    for k, v in ipairs(self.DataProvider) do
        local grid = self.DynamicTable:GetGridByIndex(k)
        if grid then
            self:UpdateGrid(grid, v)
        end
    end
end

function XUiShopWaferSelect:UpdateGrid(grid, data)
    if data then
        local isSelected = self.CurData.WaferData == data
        grid:Refresh(data, isSelected)
    end
end

function XUiShopWaferSelect:UpdateGridList()
    self.ImgEmpty.gameObject:SetActiveEx(not self.DataProvider or #self.DataProvider == 0)
    self.DynamicTable:SetDataSource(self.DataProvider)
    self.DynamicTable:ReloadDataASync()
end

function XUiShopWaferSelect:OnBtnConfirmClick()
    if self.SelectCallBack then
        self.SelectCallBack(self.CurData)
    end

    self:Close()
end

function XUiShopWaferSelect:OnBtnCloseClick()
    if self.SelectCallBack then
        self.SelectCallBack({waferData= nil,TagId = nil})
    end
    self:Close()
end
function XUiShopWaferSelect:_InitTags()
    self.EnableElementTags = {}
    self:_InitElementTagsData()
    self:_CreateTagsUi()
end
function XUiShopWaferSelect:_InitElementTagsData()
    local allElements = XMVCA.XCharacter:GetModelCharacterElement()
    for key, value in pairs(Equip_Type) do
        local type = { Id = value, ElementName = XUiHelper.GetText(key), }
        table.insert(self.EnableElementTags, type)
    end
    local sortList = { 11, 9, 8, 10 }
    local orderMap = {}
    for i, id in ipairs(sortList) do
        orderMap[id] = i
    end
    table.sort(self.EnableElementTags, function(a, b)
        return (orderMap[a.Id] or math.huge) < (orderMap[b.Id] or math.huge)
    end)
    for elementId, v in pairs(allElements) do

        table.insert(self.EnableElementTags, v)
    end

end
function XUiShopWaferSelect:_CreateTagsUi()
    local tagButton = {}
    local defaultSelect =  1
  
    for index = 1,#self.EnableElementTags do
        local tag = self.EnableElementTags[index]
        local prefab = CS.UnityEngine.GameObject.Instantiate(self.GridCharacterBtnTag.gameObject, self.GridCharacterBtnTag.transform.parent)
        prefab.gameObject:SetActiveEx(true)
        local btnTag = prefab:GetComponent("XUiButton")
        if tag.Id == 7 then --独域，找不到替代符
           btnTag:SetName(XUiHelper.GetText("SpEnhanceSkillTab"))
        else
            btnTag:SetName(tag.ElementName)
        end 
        if  self.CurData.TagId == tag.Id then
            defaultSelect = index
        end
        table.insert(tagButton,btnTag)
    end
    self.PanelBtnContent:Init(tagButton,function(index) self:RefreshDataByTag(index) end)
    
    self.PanelBtnContent:SelectIndex(defaultSelect)
        -- if self.CurData.TagId == nil and tag.Id == Equip_Type.SuitAll  then
        --     btnTag.ButtonState = CS.UiButtonState.Select
        -- elseif self.CurData.TagId == tag.Id then
        --     self:RefreshDataByTag(tag.Id)
        --     btnTag.ButtonState = CS.UiButtonState.Select
        -- end



end
function XUiShopWaferSelect:RefreshDataByTag(tagIndex)
    self.DataProvider = {}
    local tagType = self.EnableElementTags[tagIndex].Id
    if tagType == Equip_Type.SuitAll then
        self.DataProvider = self.OrginDataProvider
        self:UpdateGridList()
        return
    end

    for i, data in ipairs(self.OrginDataProvider) do
        if data.equipType and data.equipType[tagType] then
            table.insert(self.DataProvider, data)
        end
    end
    self:UpdateGridList()
    self.CurData.TagId = tagType
end

return XUiShopWaferSelect