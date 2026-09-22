local DEFAULT_CONDITION_COLOR = {
    [true] = CS.UnityEngine.Color.black,
    [false] = CS.UnityEngine.Color.red,
}

local XUiGridCostItem = XClass(nil, "XUiGridCostItem")

function XUiGridCostItem:Ctor(rootUi, ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi

    self:InitAutoScript()
end

function XUiGridCostItem:Refresh(itemId, needCount)
    self.ItemId = itemId
    self.NeedCount = needCount

    self:InitItemInfo()
    self:UpdateHaveCount()

    XDataCenter.ItemManager.AddCountUpdateListener(itemId, function()
        self:UpdateHaveCount()
    end, self.TxtHaveCount)
end

function XUiGridCostItem:InitItemInfo()
    local goodsShowParams = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(self.ItemId)

    self.RImgIcon:SetRawImage(goodsShowParams.Icon)
    XUiHelper.SetQualityIcon(self.RootUi, self.ImgQuality, goodsShowParams.Quality)
    self.TxtNeedCount.text = "/" .. self.NeedCount
end

function XUiGridCostItem:UpdateHaveCount()
    local haveCount = XDataCenter.ItemManager.GetCount(self.ItemId)

    self.TxtHaveCount.text = haveCount
    self.TxtHaveCount.color = self:_GetConditionColor(haveCount >= self.NeedCount)
end

function XUiGridCostItem:InitAutoScript()
    XTool.InitUiObject(self)
    self:AutoAddListener()
end

function XUiGridCostItem:RegisterClickEvent(uiNode, func)
    if func == nil then
        XLog.Error("XUiGridCostItem:RegisterClickEvent函数参数错误：参数func不能为空")
        return
    end

    if type(func) ~= "function" then
        XLog.Error("XUiGridCostItem:RegisterClickEvent函数错误, 参数func需要是function类型, func的类型是" .. type(func))
    end

    local listener = function(...)
        func(self, ...)
    end

    CsXUiHelper.RegisterClickEvent(uiNode, listener)
end

function XUiGridCostItem:AutoAddListener()
    self:RegisterClickEvent(self.BtnClick, self.OnBtnClickClick)
end

function XUiGridCostItem:OnBtnClickClick()
    if self._CustomClickFunc then
        self._CustomClickFunc(self._CustomClickObj)
        return
    end
    XLuaUiManager.Open("UiTip", XDataCenter.ItemManager.GetItem(self.ItemId))
end

-- 直接设置图标和数量（不依赖 ItemManager，用于辅助机头像等自定义条目）
---@param icon string 图标路径
---@param quality number 品质
---@param needCount number 需求数量
---@param haveCount number 持有数量
function XUiGridCostItem:RefreshCustom(icon, quality, needCount, haveCount)
    self.ItemId = nil
    self.NeedCount = needCount

    self.RImgIcon:SetRawImage(icon)
    XUiHelper.SetQualityIcon(self.RootUi, self.ImgQuality, quality)
    self.TxtNeedCount.text = "/" .. needCount
    self.TxtHaveCount.text = haveCount
    self.TxtHaveCount.color = self:_GetConditionColor(haveCount >= needCount)
end

-- 设置外部覆盖的颜色模板
---@param colorDic table<boolean, UnityEngine.Color> {[true]=满足色, [false]=不满足色}
function XUiGridCostItem:SetConditionColorOverride(colorDic)
    self._ConditionColorOverride = colorDic
end

--- 按外部数据刷新（不读 ItemManager，用于自定义条目）
---@param icon string 图标路径
---@param quality number 品质
---@param needCount number 需求数量
---@param haveCount number? 可选，持有数量
---@param needText string? 可选，覆盖需求数量文本（如"未选中"）
function XUiGridCostItem:RefreshByData(icon, quality, needCount, haveCount, needText)
    self.ItemId = nil
    self.NeedCount = needCount

    self.RImgIcon:SetRawImage(icon)
    XUiHelper.SetQualityIcon(self.RootUi, self.ImgQuality, quality)
    self.TxtNeedCount.text = needText or ("/" .. needCount)
    if haveCount then
        self.TxtHaveCount.text = haveCount
        self.TxtHaveCount.color = self:_GetConditionColor(haveCount >= needCount)
    else
        self.TxtHaveCount.text = ""
    end
end

--- 按预格式化文本刷新（不读 ItemManager，不做数值比较）
---@param icon string 图标路径
---@param quality number 品质
---@param haveText string 持有数量文本
---@param needText string 需求数量文本
---@param isSatisfied boolean? 可选，是否满足条件（控制颜色）
function XUiGridCostItem:RefreshByStringData(icon, quality, haveText, needText)
    self.ItemId = nil
    self.NeedCount = nil

    self.RImgIcon:SetRawImage(icon)
    XUiHelper.SetQualityIcon(self.RootUi, self.ImgQuality, quality)
    self.TxtNeedCount.text = needText or ""
    self.TxtHaveCount.text = haveText
end


function XUiGridCostItem:_GetConditionColor(isSatisfied)
    local colorDic = self._ConditionColorOverride or DEFAULT_CONDITION_COLOR
    return colorDic[isSatisfied]
end


-- 设置自定义点击回调，覆盖默认的打开 Tip 行为
---@param func function 回调方法
---@param obj any 回调的 self 对象
function XUiGridCostItem:SetCustomClick(func, obj)
    self._CustomClickFunc = func
    self._CustomClickObj = obj
end

return XUiGridCostItem