local characterRecord = require("XUi/XUiDraw/XUiDrawTools/XUiDrawCharacterRecord")
---@class XUiLottoDrawControl:XUiNode
local XUiLottoDrawControl = XClass(XUiNode, "XUiLottoDrawControl")

local PANEL_UI_MAP = {
    [XEnumConst.Lotto.Karenina] = {
        Passport = "UiLottoKareninaPassport",
        QuickWear = "UiLottoKareninaQuickWear"
    },
    [XEnumConst.Lotto.Luna] = {
        Passport = "UiLottoLunaPassport",
        QuickWear = "UiLottoLunaQuickWear"
    },
    [XEnumConst.Lotto.Lifu] = {
        Passport = "UiLottoLifuPassport",
        QuickWear = "UiLottoLifuQuickWear"
    },
    [XEnumConst.Lotto.Vera] = {
        Passport = "UiLottoVeraPassport",
        QuickWear = "UiLottoVeraQuickWear"
    },
    [XEnumConst.Lotto.Cibeizhe] = {
        Passport = "UiLottoCibeizhePassport",
        QuickWear = "UiLottoCibeizheQuickWear"
    }
}

---@param lottoGroupData XLottoGroupEntity
function XUiLottoDrawControl:OnStart(lottoGroupData)
    self._IsCanDraw = true
    ---@type XLottoGroupEntity
    self._LottoGroupData = lottoGroupData
    self._IsAfterDrawAim = false
    self._IsAfterShowDrawResult = false
end

--region Record
function XUiLottoDrawControl:_DrawRecord()
    characterRecord.Record()
end
--endregion

--region Draw
---@return boolean 是否抽奖成功
function XUiLottoDrawControl:OnBtnDrawClick()
    if self:_CheckCanDraw() then
        self:_OnDraw()
        return true
    end
    return false
end

function XUiLottoDrawControl:_CheckCanDraw()
    if XMVCA.XEquip:CheckBoxOverLimitOfDraw() then
        return false
    end
    local drawData = self._LottoGroupData:GetDrawData()
    if drawData:IsLottoCountFinish() then
        return false
    end
    local curItemCount = XDataCenter.ItemManager.GetItem(drawData:GetConsumeId()).Count
    local needItemCount = drawData:GetConsumeCount()
    if needItemCount > curItemCount then
        XLuaUiManager.Open("UiLottoTanchuang", drawData)
        return false
    end
    return true
end

function XUiLottoDrawControl:GetLottoId()
    return self._LottoGroupData:GetDrawData():GetId()
end

function XUiLottoDrawControl:_OnDraw()
    self:_DrawRecord()
    local drawData = self._LottoGroupData:GetDrawData()
    XDataCenter.LottoManager.DoLotto(drawData:GetId(), function(rewardList, extraRewardList, lottoRewardId)
        XDataCenter.AntiAddictionManager.BeginDrawCardAction()
        local lottoRewardEntity = self._LottoGroupData:GetDrawData():GetRewardDataById(lottoRewardId)
        self._LottoRewardId = lottoRewardId
        self._ExtraRewardList = extraRewardList
        self._RewardList = XDataCenter.LottoManager.HandleDrawShowRewardEffect(rewardList, lottoRewardEntity:GetShowEffectId())
        XEventManager.DispatchEvent(XEventId.EVENT_LOTTO_DRAW_ON_START, lottoRewardEntity:GetShowTimeLineName())
    end, function()
        XLog.Error("[Error]XUiLottoDrawControl:_OnDraw():抽卡失败")
    end)
end
--endregion

--region DrawResult
function XUiLottoDrawControl:GetShowResult()
    return self._RewardList
end

function XUiLottoDrawControl:GetShowResultLottoRewardId()
    return self._LottoRewardId
end

function XUiLottoDrawControl:ShowDrawResult()
    if XTool.IsTableEmpty(self._RewardList) then
        return
    end
    local drawData = self._LottoGroupData:GetDrawData()
    if self._IsAfterDrawAim then
        return
    end
    self._IsAfterDrawAim = true
    XLuaUiManager.Open("UiDrawShowNew", drawData, self._RewardList, nil, 1, function()
        self._IsAfterShowDrawResult = true
        self._IsAfterDrawAim = false
    end)
end

function XUiLottoDrawControl:ShowRewardDialog(panelType)
    if self._IsAfterShowDrawResult then
        local asynOpen = asynTask(XLuaUiManager.Open)
        RunAsyn(function()
            self:_OnShowFashionRewardList(asynOpen, panelType)
            self:_OnShowExtraRewardList(asynOpen, panelType)
        end)
        self._IsAfterShowDrawResult = false
    end
end

function XUiLottoDrawControl:_OnShowFashionRewardList(asynOpen, panelType)
    if XTool.IsTableEmpty(self._RewardList) then
        return
    end
    local drawData = self._LottoGroupData:GetDrawData()
    local lottoRewardEntity = drawData:GetRewardDataById(self._LottoRewardId)
    local rewardId = drawData:GetCoreRewardTemplateId()
    local isSame = false

    local panelConfig = PANEL_UI_MAP[panelType]
    if not panelConfig then
        XLog.Error("快速使用角色涂装弹框未接入. PanelType=" .. tostring(panelType))
    end

    for _, v in pairs(self._RewardList) do
        -- 核心奖励（角色涂装）
        if v.TemplateId == rewardId and panelConfig then
            asynOpen(panelConfig.Passport, v)
        end

        -- 武器涂装
        if XDataCenter.ItemManager.IsWeaponFashion(v.TemplateId) and panelConfig then
            asynOpen(panelConfig.QuickWear, v.TemplateId)
        end

        if v.TemplateId == lottoRewardEntity:GetTemplateId() then
            isSame = true
        end
    end

    if not isSame then
        asynOpen("UiObtain", self._RewardList, nil) -- UiObtain的第三个参数是closeBack
    end
    self._RewardList = nil
    self._LottoRewardId = nil
end

function XUiLottoDrawControl:_OnShowExtraRewardList(asynOpen, panelType)
    if XTool.IsTableEmpty(self._ExtraRewardList) then
        return
    end

    local panelConfig = PANEL_UI_MAP[panelType]
    if not panelConfig then
        XLog.Error("快速使用弹框未接入. PanelType=" .. tostring(panelType))
    end

    -- 使用头像弹框
    for _, v in pairs(self._ExtraRewardList) do
        if XDataCenter.HeadPortraitManager.IsHeadPortraitValid(v.TemplateId) then
            if panelConfig then
                asynOpen(panelConfig.QuickWear, v.TemplateId)
            end
            self._ExtraRewardList = nil
            return
        end
    end

    asynOpen("UiObtain", self._ExtraRewardList, nil)
    self._ExtraRewardList = nil
end

--endregion

return XUiLottoDrawControl