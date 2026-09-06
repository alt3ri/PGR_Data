local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XUiPanelUpgrade = require("XUi/XUiEquip/XUiEquipWeaponOneClickPopup/XUiPanelUpgrade")
local XUiPanelResonance = require("XUi/XUiEquip/XUiEquipWeaponOneClickPopup/XUiPanelResonance")
local XUiPanelOverrun = require("XUi/XUiEquip/XUiEquipWeaponOneClickPopup/XUiPanelOverrun")
local XUiPanelBubbleOverrunDetail = require("XUi/XUiEquip/XUiEquipWeaponOneClickPopup/XUiPanelBubbleOverrunDetail")
local XUiGridCultureCost = require("XUi/XUiRole/XUiGridCultureCost")

---@class XUiEquipWeaponOneClickPopup:XLuaUi
---@field _Control XEquipControl
local XUiEquipWeaponOneClickPopup = XLuaUiManager.Register(XLuaUi, "UiEquipWeaponOneClickPopup")

local ASSET_ITEM_ID_SCORE = XDataCenter.ItemManager.ItemId.RepeatChallengeCoin -- 拟战积分
local ASSET_ITEM_ID_COIN = XDataCenter.ItemManager.ItemId.Coin -- 螺母

function XUiEquipWeaponOneClickPopup:OnAwake()
    self:RegisterButtonEvent()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, ASSET_ITEM_ID_SCORE, ASSET_ITEM_ID_COIN)
    self._PanelUpgrade = XUiPanelUpgrade.New(self.PanelUpgrade, self)
    self._PanelResonance = XUiPanelResonance.New(self.PanelResonance, self)
    self._PanelOverrun = XUiPanelOverrun.New(self.PanelOverrun, self)
    self._PanelBubbleOverrunDetail = XUiPanelBubbleOverrunDetail.New(self.PanelBubbleOverrunDetail, self)
    self._CostGrids = {}
end

--- @param data { EquipId, TargetData, IsAutoExchange }
function XUiEquipWeaponOneClickPopup:OnStart(data)
    self.EquipId = data and data.EquipId
    self.TargetData = data and data.TargetData
    self.IsAutoExchange = data and data.IsAutoExchange or false
    self.OnExchangeChanged = data and data.OnExchangeChanged
    self.OnCultureFinished = data and data.OnCultureFinished
    self:InitDefaultChooseBySetting()
end

--- 按一键自动设置（WeaponLevel/Resonance/Overrun）初始化各 panel 默认勾选态
function XUiEquipWeaponOneClickPopup:InitDefaultChooseBySetting()
    local XEquipEnum = XMVCA.XEquip.Enum
    local settingControl = self._Control.OneClickAutoSettingControl
    self._PanelUpgrade:SetIsChoose(settingControl:GetSetting(XEquipEnum.OneClickAutoSettingType.WeaponLevel))
    self._PanelResonance:SetIsChoose(settingControl:GetSetting(XEquipEnum.OneClickAutoSettingType.WeaponResonance))
    self._PanelOverrun:SetIsChoose(settingControl:GetSetting(XEquipEnum.OneClickAutoSettingType.WeaponOverrun))
end

function XUiEquipWeaponOneClickPopup:OnEnable()
    self:Refresh()
end

function XUiEquipWeaponOneClickPopup:RegisterButtonEvent()
    self.BtnClosePopup:AddEventListener(handler(self, self.Close))
    self.BtnTanchuangClose:AddEventListener(handler(self, self.Close))
    self.BtnTongBlack:AddEventListener(handler(self, self.OnBtnConfirmClick))
    self.BtnAutoSetting:AddEventListener(handler(self, self.OnBtnAutoSettingClick))
    self.UiEquipBtnRadio:AddEventListener(handler(self, self.OnBtnExchangeRadioClick))
    self.BtnDetailClose:AddEventListener(handler(self, self.OnBtnDetailCloseClick))
    self.BtnResonanceDetailClose:AddEventListener(handler(self, self.OnBtnResonanceDetailCloseClick))
    self.BtnChooseCostDesc:AddEventListener(handler(self, self.OnBtnChooseCostDescClick))
end

function XUiEquipWeaponOneClickPopup:OnBtnChooseCostDescClick()
    self:ShowBubbleDetail()
    self.UiTxtDesc.text = CS.XTextManager.GetText("EquipWeaponOneClickDesc")
end

function XUiEquipWeaponOneClickPopup:OnBtnDetailCloseClick()
    self.PanelBubbleDetail.gameObject:SetActiveEx(false)
end

function XUiEquipWeaponOneClickPopup:OnBtnResonanceDetailCloseClick()
    self.PanelBubbleResonanceDetail.gameObject:SetActiveEx(false)
end

function XUiEquipWeaponOneClickPopup:Refresh()
    self:RefreshExchangeRadio()

    local ModuleType = XEnumConst.EQUIP.ONE_CLICK_CULTURE_MODULE_TYPE
    local viewData = self._Control.OneClickCultureControl:GetOneClickCultureViewData(self.TargetData, self.IsAutoExchange)
    self.ViewData = viewData
    if not viewData then
        self:Close()
        return
    end

    if self._OverrunTargetLevel == nil then
        self._OverrunTargetLevel = viewData.OverrunLevel or 0
    end

    -- 先算聚合预览（消耗螺母 / 是否足够 / 升级最高等级 / 执行用），Panel 展示依赖它
    local result = self._Control.OneClickCultureControl:CalcWeaponOneClickCulturePreview(self:GetCurrentArgs())
    self._CultureResult = result

    -- 按模块类型取消耗列表
    local costListByType = {}
    for _, moduleData in ipairs(viewData.ModuleDataList or table.empty) do
        costListByType[moduleData.Type] = moduleData.CostList
    end
    
    -- 升级：玩家材料可养成到的最高等级/突破（SimulateWeaponMaxAchievablePreview 的目标值）
    local isLevelComplete = viewData.IsLevelComplete == true
    if isLevelComplete then
        self._PanelUpgrade:Close()
    else
        self._PanelUpgrade:Open()
        local levelPreview = result.LevelPreview
        local maxLevel = levelPreview and levelPreview.TargetLevel or 0
        local maxBreakthrough = levelPreview and levelPreview.TargetBreakthrough or viewData.Breakthrough
        self._PanelUpgrade:Refresh({
            MaxLevel = maxLevel,
            BreakIcon = self._Control:GetEquipBreakThroughIcon(maxBreakthrough),
            -- 升级材料列表已在 CalcWeaponOneClickCulturePreview 里构建好（喂养+突破，含兑换）
            CostList = result.LevelCostList,
            NextPreview = self._Control.StrengthenControl:GetWeaponNextStrengthenPreview(
                self.EquipId, self.IsAutoExchange),
        })
    end
    -- 共鸣：目标已全达成则不显示
    local isResonanceComplete = viewData.IsResonanceComplete == true
    if isResonanceComplete then
        self._PanelResonance:Close()
    else
        self._PanelResonance:Open()
        -- 实际将共鸣技能数（未选时为 0）；目标数减去已达成的目标技能（非目标技能的共鸣不计）
        local targetResonanceCount = (viewData.TargetResonanceCount or 0) - (viewData.ResonanceCompleteCount or 0)
        self._PanelResonance:Refresh({
            ResonanceCount = self._ChosenResonanceCount or 0,
            TargetCount = targetResonanceCount,
            MaterialList = costListByType[ModuleType.RESONANCE],
            -- 选武器上限 = 首绑槽数
            MaxWeaponSelectCount = result.ResonanceFirstBindCount or 0,
            -- 勾选共鸣目标但材料未选/不足
            IsMaterialLack = result.ResonanceChosen == true and result.ResonanceMaterialEnough ~= true,
        })
    end
    -- 谐振：目标已全达成则不显示
    local isOverrunComplete = viewData.IsOverrunComplete == true
    if isOverrunComplete then
        self._PanelOverrun:Close()
    else
        self._PanelOverrun:Open()
        local overrunTotal = viewData.MaxOverrunLevel or 0
        local realOverrunLevel = viewData.OverrunLevel or 0
        local targetSuitId = self.TargetData.WeaponOverrunChoseSuit or 0
        local equip = XMVCA.XEquip:GetEquip(self.EquipId)
        local currentSuitId = equip and equip:GetOverrunChoseSuit() or 0
        local hasCurrentSuit = XTool.IsNumberValid(currentSuitId)
        -- 谐振步进器状态 flags（CanUpdate/CanActivate/IsActivate/CanBind）
        local flags = self._Control.OneClickCultureControl:_GetOverrunStepFlags(
            self.EquipId, self.TargetData, self._OverrunTargetLevel + 1, self.IsAutoExchange,
            self._CultureResult.UsedTokenMap, self._CultureResult.IsLevelMaxed)
        local isNowLevel = self._OverrunTargetLevel == realOverrunLevel
        local isMaxLevel = self._OverrunTargetLevel >= overrunTotal
        self._PanelOverrun:Refresh({
            ActiveNum = self._OverrunTargetLevel,
            MinLevel = realOverrunLevel,
            TotalNode = overrunTotal,
            IsShowTitleDetail = true,
            -- 绑套装区：会执行绑定（CanBind）且步进器>=1 时展示
            IsShowBindAwareness = flags.CanBind and self._OverrunTargetLevel >= 1,
            TargetSuitName = XTool.IsNumberValid(targetSuitId) and self._Control:GetSuitName(targetSuitId) or "",
            CurrentSuitName = hasCurrentSuit and self._Control:GetSuitName(currentSuitId) or "",
            HasCurrentSuit = hasCurrentSuit,
            CanUpdate = flags.CanUpdate,
            CanActivate = flags.CanActivate,
            IsActivate = flags.IsActivate,
            CanBind = flags.CanBind,
            NeedBindSuit = flags.NeedBindSuit,
            IsNowLevel = isNowLevel,
            IsMaxLevel = isMaxLevel,
            -- 材料 = 从当前谐振等级升到目标等级的消耗（随增减变，不受勾选影响）
            CostList = self._Control.OneClickCultureControl:GetOneClickCultureOverrunCostList(
                self.EquipId, self.TargetData, self.IsAutoExchange, self._OverrunTargetLevel,
                self._CultureResult.UsedTokenMap, self._CultureResult.IsLevelMaxed),
        })
    end

    self:RefreshCostMoney()
    
    local isResonanceMaterialLack = result.ResonanceChosen == true and result.ResonanceMaterialEnough ~= true
    local isResonanceTargetMissing = not isResonanceComplete
        and result.IncludeResonance == true
        and (self._ChosenResonanceCount or 0) <= 0
    local btnBool = not result.HasExecutableTask or isResonanceMaterialLack or isResonanceTargetMissing
    self.BtnTongBlack:SetDisable(btnBool, not btnBool)
end

--- 收集当前交互态为一键养成入参
---@return XWeaponOneClickCultureArgs
function XUiEquipWeaponOneClickPopup:GetCurrentArgs()
    return {
        EquipId = self.EquipId,
        TargetData = self.TargetData,
        IncludeLevel = self._PanelUpgrade:GetIsChoose(),
        IncludeResonance = self._PanelResonance:GetIsChoose(),
        IncludeOverrun = self._PanelOverrun:GetIsChoose(),
        AutoExchange = self.IsAutoExchange,
        TargetOverrunLevel = self._OverrunTargetLevel,
        -- 共鸣选择态：选中的共鸣槽位 + 每条武器材料手选的武器实例
        ResonanceSkillMap = self._ChosenResonanceSkillMap,
        ResonanceSelectedEquipMap = self._ResonanceSelectedEquipMap,
        ResonanceSelectedTokenCount = self:GetResonanceSelectedTokenCount(),
    }
end

--- 勾选养成项变化：整体重刷（重算聚合预览 + 各 panel 材料 + 螺母 + 确认按钮置灰）
--- 勾选升级会抢占兑换代币，可能让谐振材料转为不足，需回退步进器
function XUiEquipWeaponOneClickPopup:OnModuleChooseChanged()
    self:ClampOverrunTargetToReachable()
    self:Refresh()
end

--- 谐振目标激活等级变化：更新目标等级并整体重刷（谐振消耗随等级变）
function XUiEquipWeaponOneClickPopup:OnOverrunTargetChanged(targetLevel)
    self._OverrunTargetLevel = targetLevel
    self:Refresh()
end

--- 气泡（挂在本页面，子项也挂本页面）
function XUiEquipWeaponOneClickPopup:ShowBubbleDetail()
    self.PanelBubbleDetail.gameObject:SetActiveEx(true)
end

function XUiEquipWeaponOneClickPopup:ShowBubbleResonanceDetail(btnDesc)
    self.PanelBubbleResonanceDetail.gameObject:SetActiveEx(true)
    if not btnDesc then
        return
    end
    -- 调整气泡位置
    local uiCamera = CS.XUiManager.Instance.UiCamera
    local btnRect = btnDesc.transform
    local screenPoint = CS.UnityEngine.RectTransformUtility.WorldToScreenPoint(uiCamera, btnRect.position)
    local parentRect = self.BubbleDetail.transform.parent
    local ok, localPoint = CS.UnityEngine.RectTransformUtility.ScreenPointToLocalPointInRectangle(
        parentRect, screenPoint, uiCamera)
    if ok then
        local anchoredPos = self.BubbleDetail.anchoredPosition
        self.BubbleDetail:SetAnchoredPosition(anchoredPos.x, localPoint.y)
    end
end

function XUiEquipWeaponOneClickPopup:ShowBubbleOverrunDetail()
    local sub = self._Control.OneClickCultureControl
    local levelList, totalStage = sub:GetOverrunLevelPreviewList(self.EquipId, self.TargetData, self._OverrunTargetLevel or 0)
    self._PanelBubbleOverrunDetail:Show({
        ActiveStage = self._OverrunTargetLevel or 0,
        TotalStage = totalStage,
        LevelList = levelList,
    })
end

--- 自动兑换复选框状态（与来源界面同步）
function XUiEquipWeaponOneClickPopup:RefreshExchangeRadio()
    local state = self.IsAutoExchange and CS.UiButtonState.Select or CS.UiButtonState.Normal
    self.UiEquipBtnRadio:SetButtonState(state)
end

function XUiEquipWeaponOneClickPopup:OnBtnExchangeRadioClick()
    self.IsAutoExchange = not self.IsAutoExchange
    self:RefreshExchangeRadio()
    if self.OnExchangeChanged then
        self.OnExchangeChanged(self.IsAutoExchange)
    end
    self:ClampOverrunTargetToReachable()
    self:Refresh()
end

--- 步进器超出当前材料可达等级时，退回真实等级
--- 触发时机：切自动兑换、切升级模块勾选（升级会抢兑换代币，可能让谐振材料转为不足）
function XUiEquipWeaponOneClickPopup:ClampOverrunTargetToReachable()
    local viewData = self.ViewData
    local realOverrunLevel = viewData and viewData.OverrunLevel or 0
    if not self._OverrunTargetLevel or self._OverrunTargetLevel <= realOverrunLevel then
        return
    end
    local sub = self._Control.OneClickCultureControl
    local result = sub:CalcWeaponOneClickCulturePreview(self:GetCurrentArgs())
    local reachable = sub:IsOverrunLevelReachable(
        self.EquipId, self.TargetData, self._OverrunTargetLevel, self.IsAutoExchange,
        result.UsedTokenMap, result.IsLevelMaxed)
    if not reachable then
        self._OverrunTargetLevel = realOverrunLevel
    end
end

--- 货币消耗展示
function XUiEquipWeaponOneClickPopup:RefreshCostMoney()
    local result = self._CultureResult
    local costList = {}
    if result then
        -- 代币消耗 = 升级兑换 + 谐振兑换
        local scoreCost = ((result.UsedTokenMap or table.empty)[ASSET_ITEM_ID_SCORE] or 0)
            + ((result.OverrunTokenCostMap or table.empty)[ASSET_ITEM_ID_SCORE] or 0)
        table.insert(costList, { Id = ASSET_ITEM_ID_SCORE, Count = scoreCost, IsEnough = true })
        local coinCost = result.TotalCostMoney or 0
        table.insert(costList, { Id = ASSET_ITEM_ID_COIN, Count = coinCost, IsEnough = true })
    end
    XTool.UpdateDynamicItem(self._CostGrids, costList, self.PanelConsume, XUiGridCultureCost, self)
end

function XUiEquipWeaponOneClickPopup:OnBtnConfirmClick()
    local result = self._CultureResult
    if not result then
        return
    end
    -- 选了共鸣目标但共鸣材料没选够（手选武器 + 代币持有 < 首绑槽数）→ 提示
    if result.ResonanceChosen and not result.ResonanceMaterialEnough then
        XUiManager.TipText("EquipOneClickCultureMaterialNotEnough")
        return
    end
    -- 执行链为空则不执行（按钮已 SetDisable，此处双保险）
    if not result.HasExecutableTask then
        return
    end
    -- 关主弹窗，交给进度弹窗驱动执行链（升级/共鸣/谐振逐单元展示强化中→完成）；养成成功后回刷来源界面
    local onCultureFinished = self.OnCultureFinished
    local onConfirm = function()
        self:Close()
        XLuaUiManager.Open("UiEquipWeaponEnhanceProgressPopup", {
            Result = result,
            OnClose = function(isSuccess)
                self:RecordCultureFinish(result, isSuccess)
                if isSuccess and onCultureFinished then
                    onCultureFinished()
                end
            end,
        })
    end

    local isConfirmSettingEnabled = self._Control.OneClickAutoSettingControl:GetSetting(
        XMVCA.XEquip.Enum.OneClickAutoSettingType.ConfirmSetting)
    if not isConfirmSettingEnabled then
        onConfirm()
        return
    end

    local exchangeList = self._Control.OneClickCultureControl:BuildWeaponCultureAutoExchangeList(result)
    if not XTool.IsTableEmpty(exchangeList) then
        XLuaUiManager.Open("UiRoleExchangeTipPopup", exchangeList, onConfirm)
        return
    end
    local content = XUiHelper.GetText("AwarenessOneClickConfirmContent")
    XUiManager.DialogTip(nil, content, XUiManager.DialogType.Normal, nil, onConfirm)
end

function XUiEquipWeaponOneClickPopup:OnBtnAutoSettingClick()
    XLuaUiManager.Open("UiEquipOneClickAutoCommonSetting")
end

--- 武器养成埋点：培养目标与最终结果
---@param result table CalcWeaponOneClickCulturePreview 结果
---@param isSuccess boolean 执行链是否完整执行完（中途终止为 false）
function XUiEquipWeaponOneClickPopup:RecordCultureFinish(result, isSuccess)
    local equip = XMVCA.XEquip:GetEquip(self.EquipId)
    if not equip then
        return
    end
    local isFiveStar = XMVCA.XEquip:GetEquipStar(equip.TemplateId) == XEnumConst.EQUIP.FIVE_STAR
    local targetResonanceSkills = {}
    for _, task in ipairs(result.ResonanceTaskList or table.empty) do
        targetResonanceSkills[#targetResonanceSkills + 1] = task.SkillId
    end
    local isResonanceReached = true
    for _, task in ipairs(result.ResonanceTaskList or table.empty) do
        local info = equip:GetResonanceInfo(task.Pos)
        local isTaskReached = info and (isFiveStar or (info.CharacterId == equip.CharacterId and info.TemplateId == task.SkillId))
        if not isTaskReached then
            isResonanceReached = false
            break
        end
    end
    local targetOverrunLevel = self._OverrunTargetLevel or 0
    local targetLevel = result.LevelPreview and result.LevelPreview.TargetLevel or equip.Level
    local dict = {
        item_id = equip.TemplateId,
        plan_choose = self.TargetData and self.TargetData.Id or 0,
        include_level = result.IncludeLevel == true and 1 or 0,
        resonance_skills = targetResonanceSkills,
        overrun_level = targetOverrunLevel,
        final_state = {
            [equip.TemplateId] = {
                level = equip.Level,
                resonance_skills = targetResonanceSkills,
                overrun_level = equip:GetOverrunLevel(),
            },
        },
        is_target_reached = {
            level = equip.Level >= targetLevel and 1 or 0,
            resonance = isResonanceReached and 1 or 0,
            overrun = isSuccess and 1 or 0,
        },
    }
    CS.XRecord.Record(dict, "1000005", "WeaponOneClickCulture")
end

--- 取已选共鸣技能字典（供选择弹窗回显）
---@return table<number, boolean>|nil
function XUiEquipWeaponOneClickPopup:GetChosenResonanceSkillMap()
    return self._ChosenResonanceSkillMap
end

--- 写回已选共鸣技能字典（选择弹窗确认后），更新计数并刷新
---@param selectedSkillMap table<number, boolean>|nil
function XUiEquipWeaponOneClickPopup:SetChosenResonanceSkillMap(selectedSkillMap)
    self._ChosenResonanceSkillMap = selectedSkillMap
    local count = 0
    if selectedSkillMap then
        for _, isSelected in pairs(selectedSkillMap) do
            if isSelected then
                count = count + 1
            end
        end
    end
    self._ChosenResonanceCount = count
    self:Refresh()
end

--- 取全局手选的武器字典（不分模板，供选择弹窗回显 + 各格子按模板统计）
---@return table<number, boolean>|nil equipId → true
function XUiEquipWeaponOneClickPopup:GetResonanceSelectedEquips()
    return self._ResonanceSelectedEquipMap
end

--- 写回全局手选的武器字典（选武器弹窗确认后，空表则清空）
---@param selectedEquipIdMap table<number, boolean>|nil equipId → true
function XUiEquipWeaponOneClickPopup:SetResonanceSelectedEquips(selectedEquipIdMap)
    if XTool.IsTableEmpty(selectedEquipIdMap) then
        self._ResonanceSelectedEquipMap = nil
    else
        self._ResonanceSelectedEquipMap = selectedEquipIdMap
    end
    -- 刷新主弹窗（重建共鸣材料格子，各格子按模板统计全局选中数刷新）
    self:Refresh()
end

--- 取手选的共鸣代币数量（与武器共享首绑槽数上限）
---@return number
function XUiEquipWeaponOneClickPopup:GetResonanceSelectedTokenCount()
    return self._ResonanceSelectedTokenCount or 0
end

--- 写回手选的共鸣代币数量（0 则清空）
---@param count number|nil
function XUiEquipWeaponOneClickPopup:SetResonanceSelectedTokenCount(count)
    self._ResonanceSelectedTokenCount = (count and count > 0) and count or nil
    self:Refresh()
end

return XUiEquipWeaponOneClickPopup
