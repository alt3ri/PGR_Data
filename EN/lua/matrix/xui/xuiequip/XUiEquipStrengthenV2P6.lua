---@class XUiEquipStrengthenV2P6 : XLuaUi
local XUiEquipStrengthenV2P6 = XLuaUiManager.Register(XLuaUi, "UiEquipStrengthenV2P6")

local XUiGridCostItem = require("XUi/XUiEquipBreakThrough/XUiGridCostItem")
local XUiGridEquipReplaceAttr = require("XUi/XUiEquipReplaceNew/XUiGridEquipReplaceAttr")
local TIP_COLOR = XUiHelper.Hexcolor2Color("EE2323FF") --文本警示色
local ToInt = XMath.ToInt
local SELECT = CS.UiButtonState.Select
local NORMAL = CS.UiButtonState.Normal

function XUiEquipStrengthenV2P6:OnAwake()
    -- 强化消耗范围复选框（勾选除了【5星】外的所有素材种类）
    self.BtnSelectDic = {
        TgDaoJu = true,
        Tg3Xing = true,
        Tg4Xing = true,
        Tg5Xing = false,
    }
    for btnName, isSelect in pairs(self.BtnSelectDic) do
        local state = isSelect and SELECT or NORMAL
        local btn = self[btnName]
        btn:SetButtonState(state)
    end

    self.GridCostItem.gameObject:SetActiveEx(false)
    self.Slider.value = 0

    self.GridCostItems = {}
    self:SetButtonCallBack()
end

function XUiEquipStrengthenV2P6:OnStart(parent)
    self.Parent = parent
end

function XUiEquipStrengthenV2P6:OnEnable()
    self.EquipId = self.Parent.EquipId
    self.TemplateId = XMVCA.XEquip:GetEquipTemplateId(self.EquipId)
    self.MaxLevelUnit = self._Control.StrengthenControl:GetEquipMaxLevelUnit(self.TemplateId)
    self.MaxBreakthrough = self._Control.StrengthenControl:GetEquipMaxBreakthrough(self.TemplateId)

    self:InitSliderBg()
    self:UpdateView()
end

function XUiEquipStrengthenV2P6:OnGetEvents()
    return {
        XEventId.EVENT_EQUIP_QUICK_STRENGTHEN_NOTYFY,
        XEventId.EVENT_ITEM_COUNT_UPDATE_PREFIX .. XDataCenter.ItemManager.ItemId.Coin
    }
end

function XUiEquipStrengthenV2P6:OnNotify(evt, ...)
    local args = {...}

    if evt == XEventId.EVENT_EQUIP_QUICK_STRENGTHEN_NOTYFY then
        self:UpdateView()
    elseif evt == XEventId.EVENT_ITEM_COUNT_UPDATE_PREFIX .. XDataCenter.ItemManager.ItemId.Coin then
        self:UpdateCostMoney()
        self:UpdateLevel()
    end
end

function XUiEquipStrengthenV2P6:SetButtonCallBack()
    self:RegisterClickEvent(self.BtnPreview, self.OnClickBtnPreview)
    self:RegisterClickEvent(self.BtnGetMaterial, self.OnClickBtnGetMaterial)
    self:RegisterClickEvent(self.BtnStrengthen, self.OnClickBtnStrengthen)
    self:RegisterClickEvent(self.BtnAdd, self.OnClickBtnAdd)
    self:RegisterClickEvent(self.BtnSub, self.OnClickBtnSub)
    self:RegisterClickEvent(self.BtnMax, self.OnClickBtnMax)

    self.Slider.onValueChanged:AddListener(handler(self, self.OnSliderValueChanged))
    self:RegisterClickEvent(self.TgDaoJu, function() self:OnClickTag("TgDaoJu") end)
    self:RegisterClickEvent(self.Tg3Xing, function() self:OnClickTag("Tg3Xing") end)
    self:RegisterClickEvent(self.Tg4Xing, function() self:OnClickTag("Tg4Xing") end)
    self:RegisterClickEvent(self.Tg5Xing, function() self:OnClickTag("Tg5Xing") end)
end

-- 设置滑动条
function XUiEquipStrengthenV2P6:SetSliderValue(value)
    if value < self.MinLevelUnit or value > self.MaxLevelUnit then
        return
    end
    local isSame = self.TargetLevelUnit == value
    self.Slider.value = value
    if isSame then
        self:OnSliderValueChanged()
    end
end

-- 预览
function XUiEquipStrengthenV2P6:OnClickBtnPreview()
    if #self.AllConsumeItems == 0 then
        XUiManager.TipText("EquipStrengthenNoItemTips")
        return
    end

    local cloneCosumes = XTool.Clone(self.AllConsumeItems)
    XLuaUiManager.Open("UiEquipStrengthenConsumptionV2P6", self.EquipId, cloneCosumes, function(consumes, breakthrough, level, addExp, costMoney, operations, showExpOverflowConfirm)
        self:OnCosumesChange(consumes, breakthrough, level, addExp, costMoney, operations, showExpOverflowConfirm)
    end)
end

function XUiEquipStrengthenV2P6:OnClickBtnGetMaterial()
    local site = self._Control:GetEquipSite(self.TemplateId)
    local skipIds = self._Control:GetEquipEatSkipIds(XEnumConst.EQUIP.EAT_TYPE.EQUIP, site)
    XLuaUiManager.Open("UiEquipStrengthenSkip", skipIds)
end

function XUiEquipStrengthenV2P6:OnClickBtnStrengthen()
    --未选择目标等级
    if not self.Operations or #self.Operations == 0 then
        XUiManager.TipText("EquipMultiStrengthenNotSelectLevel")
        return
    end

    --未达到突破条件
    if self.TargetBreakthrough ~= 0 and not self.ReachBreakCondition then
        XUiManager.TipMsg(self.ConditionDesc)
        return
    end

    --强化/突破素材不足
    if not self.CanBreakThrough or not self.CanLevelUp then
        XUiManager.TipText("EquipMultiStrengthenItemNotEnough")
        return
    end

    --货币不足
    if
        not XDataCenter.ItemManager.DoNotEnoughBuyAsset(
            XDataCenter.ItemManager.ItemId.Coin,
            self.CostMoney,
            1,
            function()
                self:OnClickBtnStrengthen()
            end,
            "EquipMultiStrengthenCoinNotEnough"
        )
     then
        return
    end

    if XLuaUiManager.IsUiShow("UiEquipCultureConfirm") then
        return
    end

    self:OpenConsumeStarConfirm()
end

-- 二次确认 消耗装备星级太高
function XUiEquipStrengthenV2P6:OpenConsumeStarConfirm()
    local needComfirm = false
    for _, operation in ipairs(self.Operations) do
        for equipId in pairs(operation.UseEquipIdDic or {}) do
            local equipTemplateId = XMVCA.XEquip:GetEquipTemplateId(equipId)
            local star = XMVCA.XEquip:GetEquipStar(equipTemplateId)
            if star >= XEnumConst.EQUIP.CAN_NOT_AUTO_EAT_STAR then
                needComfirm = true
                break
            end
        end
    end
    if needComfirm then
        local title = XUiHelper.GetText("EquipStrengthenPreciousTipTitle")
        local content = XUiHelper.GetText("EquipStrengthenPreciousTipContent")
        XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, nil, function()
            self:OpenkExpOverflowConfirm()
        end)
    else
        self:OpenkExpOverflowConfirm()
    end
end

-- 二次确认 经验溢出
function XUiEquipStrengthenV2P6:OpenkExpOverflowConfirm()
    if self.ShowExpOverflowConfirm then
        local title = XUiHelper.GetText("EquipStrengthenPreciousTipTitle")
        local content = XUiHelper.GetText("EquipStrengthenExpOverflowTips")
        XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, nil, function()
            self:OpenUiEquipCultureConfirm()
        end)
    else
        self:OpenUiEquipCultureConfirm()
    end
end

function XUiEquipStrengthenV2P6:OpenUiEquipCultureConfirm()
    XLuaUiManager.Open("UiEquipCultureConfirm", self.EquipId, self.MinLevelUnit, self.TargetLevelUnit, self.RealLevel, self.Operations)
end

function XUiEquipStrengthenV2P6:OnClickBtnAdd()
    self:SetSliderValue(self.TargetLevelUnit + 1)
end

function XUiEquipStrengthenV2P6:OnClickBtnSub()
    self:SetSliderValue(self.TargetLevelUnit - 1)
end

function XUiEquipStrengthenV2P6:OnClickBtnMax()
    local maxTargetLevelUnit = self._Control.StrengthenControl:GetMaxStrengthenTargetLevelUnit(self.EquipId, self.AllConsumeItems)
    self:SetSliderValue(maxTargetLevelUnit)
end

function XUiEquipStrengthenV2P6:OnClickTag(btnName)
    self.BtnSelectDic[btnName] = not self.BtnSelectDic[btnName]
    local state = self.BtnSelectDic[btnName] and SELECT or NORMAL
    self[btnName]:SetButtonState(state)
    self[btnName].TempState = state
    self:UpdateSelectConsumeType()
end

function XUiEquipStrengthenV2P6:InitSliderBg()
    local star = XMVCA.XEquip:GetEquipQuality(self.TemplateId)
    local sliderPath = CS.XGame.ClientConfig:GetString("EquipStrengthenProgressStar" .. star)
    self.SliderBackground:SetSprite(sliderPath)
    self.ImgSliderFil:SetSprite(sliderPath)
end

-- 刷新界面
function XUiEquipStrengthenV2P6:UpdateView()
    local equipId = self.EquipId

    local isMaxLevel = XMVCA.XEquip:IsMaxLevelAndBreakthrough(equipId)
    if isMaxLevel then
        self.Parent:CloseWithSelectCurEquip()
        return
    end

    local equip = XMVCA.XEquip:GetEquip(self.EquipId)
    local curLevelUnit = self._Control.StrengthenControl:GetEquipLevelUnit(equipId)
    self.MinLevelUnit = curLevelUnit
    self.TargetLevelUnit = curLevelUnit
    self:UpdateSelectConsumeType()

    --更新滑动条可滑动区域等级单位范围
    self.Slider:SetBorderValue(self.MinLevelUnit, self.MaxLevelUnit) 

    --重新进入界面，滑动条都到装备当前等级处
    self.Slider.minValue = 1 --最小值代表等级单位
    self.Slider.maxValue = self.MaxLevelUnit --最大值代表等级单位
    self.Slider.value = curLevelUnit
end

--#region 根据等级刷新预览

--滑动条变化回调
function XUiEquipStrengthenV2P6:OnSliderValueChanged()
    --手动修改消耗道具，只刷新进度条，不触发事件
    if self.IgnoreSliderEvent then 
        return
    end

    self.TargetLevelUnit = ToInt(self.Slider.value)

    --更新消耗
    self:UpdateByLevel()
end

-- 刷新选中的消耗类型
function XUiEquipStrengthenV2P6:UpdateSelectConsumeType()
    local isConsumeItem = self.BtnSelectDic["TgDaoJu"] --是否消耗道具
    local consumeStarDic = {} --消耗星级，1-5代表装备星级

    if self.BtnSelectDic["Tg3Xing"] then
        consumeStarDic[1] = true
        consumeStarDic[2] = true
        consumeStarDic[3] = true
    end

    if self.BtnSelectDic["Tg4Xing"] then
        consumeStarDic[4] = true
    end

    if self.BtnSelectDic["Tg5Xing"] then
        consumeStarDic[5] = true
    end

    --更新可消耗列表
    self.AllConsumeItems = self._Control.StrengthenControl:GetAllConsumeItems(self.EquipId, {
        IncludeItems = isConsumeItem,
        ConsumeStarDic = consumeStarDic,
    })
    --通过等级刷新界面
    self:UpdateByLevel()
end

--通过目标等级刷新消耗界面
function XUiEquipStrengthenV2P6:UpdateByLevel()
    local equipId = self.EquipId
    local targetBreakthrough, targetLevel = self._Control.StrengthenControl:ConvertToBreakThroughAndLevel(self.TemplateId, self.TargetLevelUnit)

    -- 突破消耗
    local breakthroughCostMoney, canBreakThrough = self:UpdateBreakthrough(targetBreakthrough)

    --升级消耗
    local levelUpResult = self._Control.StrengthenControl:SimulateEquipLevelUp(
        equipId, targetBreakthrough, targetLevel, self.AllConsumeItems)

    -- 缓存变量
    self.TargetBreakthrough = targetBreakthrough --对应突破阶段
    self.TargetLevel = targetLevel
    self.RealLevel = levelUpResult.ReachLevel --对应突破阶段的真实等级

    self.CanBreakThrough = canBreakThrough --突破素材是否足够
    self.CanLevelUp = levelUpResult.CanLevelUp --升级素材是否足够
    self.CostMoney = breakthroughCostMoney + levelUpResult.CostMoney --总消耗货币
    self.Operations = levelUpResult.Operations --升级/突破 消耗操作列表
    self.ShowExpOverflowConfirm = levelUpResult.ShowExpOverflowConfirm -- 经验溢出二次确认

    self:UpdateCostMoney()
    self:UpdateLevel()
    self:UpdateEquipAttr()
    self:UpdateCostExp(levelUpResult.UsedExp, levelUpResult.LackExp)
end

-- 根据消耗池计算满足目标等级的最终经验及升级消耗（只计算升级消耗，不计算突破）
-- 消耗顺序、强化模拟、经验溢出检查已下沉到 XEquipStrengthenControl:SimulateEquipLevelUp / SimulateLevelUpInBreakthrough

-- 获取强化的最高目标等级已下沉到 XEquipStrengthenControl:GetMaxStrengthenTargetLevelUnit
--#endregion 根据等级刷新预览


--#region 根据消耗列表刷新预览
-- 手动改变消耗列表
function XUiEquipStrengthenV2P6:OnCosumesChange(consumes, breakthrough, level, addExp, levelUpCostMoney, operations, showExpOverflowConfirm)
    self.AllConsumeItems = consumes
    local breakthroughCostMoney, canBreakThrough = self:UpdateBreakthrough(breakthrough)

    -- 缓存变量
    self.TargetLevelUnit = self._Control.StrengthenControl:ConvertToLevelUnit(self.TemplateId, breakthrough, level) --目标总等级
    self.TargetBreakthrough = breakthrough --对应突破阶段
    self.TargetLevel = level -- 对应等级
    self.RealLevel = level -- 对应突破阶段的真实等级

    self.CanLevelUp = true --升级素材是否足够
    self.CanBreakThrough = canBreakThrough --突破素材是否足够
    self.CostMoney = levelUpCostMoney + breakthroughCostMoney

    self.Operations = operations --升级/突破 消耗操作列表
    self.ShowExpOverflowConfirm = showExpOverflowConfirm -- 经验溢出二次确认

    self:UpdateCostMoney()
    self:UpdateLevel()
    self:UpdateEquipAttr()
    self.IgnoreSliderEvent = true
    self:SetSliderValue(self.TargetLevelUnit)
    self.IgnoreSliderEvent = false
    self:UpdateCostExp(addExp)
end
--#endregion 根据消耗列表刷新预览

--根据传入的消耗类型字典 返回可消耗物品/装备排序列表
-- 已下沉到 XEquipStrengthenControl:GetAllConsumeItems

-- 刷新等级
function XUiEquipStrengthenV2P6:UpdateLevel()
    if self.ColorTxtLv == nil then
        self.ColorTxtLv = self.TxtLv.color
    end

    --等级，突破显示
    local breakThroughIcon = self._Control.StrengthenControl:GetEquipBreakThroughIcon(self.TargetBreakthrough)
    self.ImgBreak:SetSprite(breakThroughIcon)
    local levelLimit = XMVCA.XEquip:GetEquipBreakthroughLevelLimit(self.TemplateId, self.TargetBreakthrough)
    self.TxtLv.text = self.TargetLevel
    self.TxtLvMax.text = "/" .. levelLimit

    local notStrengthen = not self.IsMoneyEnough or
        (self.TargetLevelUnit ~= self.MinLevelUnit and not self.CanLevelUp) or
        (self.TargetBreakthrough ~= 0 and not self.CanBreakThrough)
    self.TxtLv.color = notStrengthen and TIP_COLOR or self.ColorTxtLv

    -- 刷新加减按钮状态
    local isReach = self.TargetLevelUnit <= self.MinLevelUnit
    self.BtnSub:SetDisable(isReach, not isReach)
    isReach = self.TargetLevelUnit >= self.MaxLevelUnit
    self.BtnAdd:SetDisable(isReach, not isReach)
end

-- 刷新属性
function XUiEquipStrengthenV2P6:UpdateEquipAttr()
    local curAttrMap = XMVCA.XEquip:GetEquipAttrMap(self.EquipId)
    local targetBreakthrough, targetLevel = self._Control.StrengthenControl:ConvertToBreakThroughAndLevel(self.TemplateId, self.TargetLevelUnit)
    local preAttrMap = XMVCA.XEquip:GetEquipAttrMap(self.EquipId, targetBreakthrough, targetLevel)

    for attrIndex, attrInfo in pairs(curAttrMap) do
        local uiObj = self["PanelAttr" .. attrIndex]
        uiObj:GetObject("TxtName").text = attrInfo.Name
        uiObj:GetObject("TxtCurAttr").text = attrInfo.Value

        local preAttrInfo = preAttrMap[attrIndex]
        local isShowArrow = attrInfo.Value ~= preAttrInfo.Value
        uiObj:GetObject("ImgArrow").gameObject:SetActiveEx(isShowArrow)
        local txtNextAttr = uiObj:GetObject("TxtNextAttr")
        txtNextAttr.gameObject:SetActiveEx(isShowArrow)
        if isShowArrow then 
            txtNextAttr.text = preAttrInfo.Value
        end
    end
end

-- 刷新强化消耗的经验
function XUiEquipStrengthenV2P6:UpdateCostExp(usedExp, lackExp)
    if self.ColorTxtExp == nil then
        self.ColorTxtExp = self.TxtExp.color
    end

    if lackExp and lackExp > 0 then
        self.TxtExp.text = string.format("%s(-%s)", math.floor(usedExp), math.floor(lackExp))
        self.TxtExp.color = TIP_COLOR
    else
        self.TxtExp.text = tostring(math.floor(usedExp))
        self.TxtExp.color = self.ColorTxtExp
    end
end

-- 刷新突破
function XUiEquipStrengthenV2P6:UpdateBreakthrough(targetBreakthrough)
    --突破需要的螺母
    local breakthroughCostMoney = self._Control.StrengthenControl:GetMutiBreakthroughUseMoney(self.EquipId, targetBreakthrough)

    -- 下一突破条件
    local equip = XMVCA.XEquip:GetEquip(self.EquipId)
    local nextReach, nextDesc = self._Control.StrengthenControl:CheckBreakthroughCondition(self.TemplateId, equip.Breakthrough + 1)

    -- 目标突破条件
    self.ReachBreakCondition, self.ConditionDesc = self._Control.StrengthenControl:CheckBreakthroughCondition(self.TemplateId, targetBreakthrough)
    
    -- 刷新突破条件/突破消耗
    self.PanelBreachNeed.gameObject:SetActiveEx(not nextReach)
    self.PanelBreachConsume.gameObject:SetActiveEx(nextReach)
    if not nextReach then
        self.TxtNotPass.text = nextDesc
        local canBreakThrough = targetBreakthrough == equip.Breakthrough -- 当前等级不用突破
        return breakthroughCostMoney, canBreakThrough
    else
        -- 目标突破的消耗
        local consumeItems, canBreakThrough = self._Control.StrengthenControl:GetMutiBreakthroughConsumeItems(self.EquipId, targetBreakthrough)
        local isEmpty = XTool.IsTableEmpty(consumeItems)
        self.PanelBreakthroughConsume.gameObject:SetActiveEx(not isEmpty)
        if not isEmpty then
            for index, item in ipairs(consumeItems) do
                local grid = self.GridCostItems[index]
                if not grid then
                    local ui = CSObjectInstantiate(self.GridCostItem, self.PanelCostItem)
                    grid = XUiGridCostItem.New(self, ui)
                    table.insert(self.GridCostItems, grid)
                end
                grid:Refresh(item.Id, item.Count)
                grid.GameObject:SetActiveEx(true)
            end
            for i = #consumeItems + 1, #self.GridCostItems do
                self.GridCostItems[i].GameObject:SetActiveEx(false)
            end
        end

        return breakthroughCostMoney, canBreakThrough
    end
end

-- 刷新需要的螺母
function XUiEquipStrengthenV2P6:UpdateCostMoney()
    if self.ColorTxtCost == nil then
        self.ColorTxtCost = self.TxtCost.color
    end

    self.IsMoneyEnough = XDataCenter.ItemManager.GetCoinsNum() >= self.CostMoney
    self.TxtCost.text = self.CostMoney
    self.TxtCost.color = self.IsMoneyEnough and self.ColorTxtCost or TIP_COLOR
end

return XUiEquipStrengthenV2P6
