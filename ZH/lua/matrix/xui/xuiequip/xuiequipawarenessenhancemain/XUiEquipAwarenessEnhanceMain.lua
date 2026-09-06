--[[
-- XUiEquipAwarenessEnhanceMain.lua
-- 意识一键培养主界面，负责刷新意识格子、共鸣技能格子，以及强化/共鸣/超频入口面板。
-- 初始结构由界面代码生成器生成，当前文件包含手写逻辑。
--]]

local XUiGridEquip = require("XUi/XUiEquip/XUiGridEquip")
local XUiGridTRAwarenessResonanceSkill = require("XUi/XUiTeamRecommend/Grid/XUiGridTRAwarenessResonanceSkill")
local XUiPanelAwarenessEnhanceStrengthen = require("XUi/XUiEquip/XUiEquipAwarenessEnhanceMain/XUiPanelAwarenessEnhanceStrengthen")
local XUiPanelAwarenessEnhanceResonance = require("XUi/XUiEquip/XUiEquipAwarenessEnhanceMain/XUiPanelAwarenessEnhanceResonance")
local XUiPanelAwarenessEnhanceOverclocking = require("XUi/XUiEquip/XUiEquipAwarenessEnhanceMain/XUiPanelAwarenessEnhanceOverclocking")
local CSInstantiate = CS.UnityEngine.Object.Instantiate

local DEFAULT_MATERIAL_NEED_COUNT = 0

local MATERIAL_COLOR = {
    Black = {
        Hex = "000000",
        Text = XUiHelper.Hexcolor2Color("000000"),
    },
    Red = {
        Hex = "FF0000",
        Text = XUiHelper.Hexcolor2Color("FF0000"),
    },
}

---@class XUiEquipAwarenessEnhanceMain : XLuaUi
---@field _Control XEquipControl
---@field PanelAsset UnityEngine.RectTransform
---@field BtnBack XUiComponent.XUiButton
---@field BtnMainUi XUiComponent.XUiButton
---@field BtnHelp XUiComponent.XUiButton
---@field AnimFold PlayableDirector
---@field AnimUnFold PlayableDirector
---@field TopControl UiObject
---@field UiTxtTitle UnityEngine.UI.Text
---@field GridAwareness UiObject
---@field GridDoubleResonanceSkill UiObject
---@field ListEnhance UnityEngine.RectTransform
---@field GridCostItem UiObject
---@field PanelRandom2 UiObject
---@field PanelAwareness1 UnityEngine.RectTransform
---@field PanelAwareness2 UnityEngine.RectTransform
---@field PanelAwareness3 UnityEngine.RectTransform
---@field PanelAwareness4 UnityEngine.RectTransform
---@field PanelAwareness5 UnityEngine.RectTransform
---@field PanelAwareness6 UnityEngine.RectTransform
---@field BtnAutoExchange XUiComponent.XUiButton
---@field BtnExecuteCompleteProcess XUiComponent.XUiButton
---@field PanelStrengthen UiObject
---@field PanelResonance UiObject
---@field PanelOverclocking UiObject
---@field StrengthenSiblingIndex number 强化面板初始层级索引
---@field ResonanceSiblingIndex number 共鸣面板初始层级索引
---@field OverclockingSiblingIndex number 超频面板初始层级索引
---@field IsAllEnhanceComplete boolean 意识强化、共鸣与超频是否均已完成
local XUiEquipAwarenessEnhanceMain = XLuaUiManager.Register(XLuaUi, "UiEquipAwarenessEnhanceMain")

-- 根据当前可用数量和需求数量获取材料数量显示颜色；未传需求数量时按 0 处理。
---@param currentCount number
---@param needCount number|nil
---@return table<string, string|UnityEngine.Color>
function XUiEquipAwarenessEnhanceMain:GetMaterialCostColor(currentCount, needCount)
    needCount = needCount or DEFAULT_MATERIAL_NEED_COUNT
    return currentCount >= needCount and MATERIAL_COLOR.Black or MATERIAL_COLOR.Red
end

----------------------------------------
-- 生命周期 & 初始化
----------------------------------------
function XUiEquipAwarenessEnhanceMain:OnAwake()
    self:InitComponents()
end

function XUiEquipAwarenessEnhanceMain:InitComponents()
    self:RegisterClickEvent(self.BtnBack, function() self:Close() end)
    self:RegisterClickEvent(self.BtnMainUi, function() XLuaUiManager.RunMain() end)
    self:BindHelpBtn(self.BtnHelp, "UiEquipAwarenessEnhanceMainHelpKey")

    self.AssetPanel = XUiHelper.XUiPanelAsset(self, self.PanelAsset,
        XDataCenter.ItemManager.ItemId.Coin, XDataCenter.ItemManager.ItemId.RepeatChallengeCoin, XGuildConfig.GuildCoin)

    self.AwarenessGrids = {}
    self.ResonanceSkillGrids = {}
    self.IsAllEnhanceComplete = false
    self.GridAwareness.gameObject:SetActiveEx(false)
    self.GridDoubleResonanceSkill.gameObject:SetActiveEx(false)

    self.UiPanelStrengthen = XUiPanelAwarenessEnhanceStrengthen.New(self.PanelStrengthen, self)
    self.UiPanelResonance = XUiPanelAwarenessEnhanceResonance.New(self.PanelResonance, self)
    self.UiPanelOverclocking = XUiPanelAwarenessEnhanceOverclocking.New(self.PanelOverclocking, self)
    self.UiPanelStrengthen:Open()
    self.UiPanelResonance:Open()
    self.UiPanelOverclocking:Open()

    self.StrengthenSiblingIndex = self.PanelStrengthen.transform:GetSiblingIndex()
    self.ResonanceSiblingIndex = self.PanelResonance.transform:GetSiblingIndex()
    self.OverclockingSiblingIndex = self.PanelOverclocking.transform:GetSiblingIndex()

    self:RegisterClickEvent(self.BtnAutoExchange, function() self:OnBtnAutoExchangeClick() end)
    self:RegisterClickEvent(self.BtnExecuteCompleteProcess, function() self:OnBtnExecuteCompleteProcessClick() end)
end

function XUiEquipAwarenessEnhanceMain:OnStart(characterId)
    self.CharacterId = characterId
end

function XUiEquipAwarenessEnhanceMain:OnEnable()
    self:Refresh()
end

function XUiEquipAwarenessEnhanceMain:OnDisable()
end

function XUiEquipAwarenessEnhanceMain:OnDestroy()
end

function XUiEquipAwarenessEnhanceMain:OnGetLuaEvents()
    return {
        XEventId.EVENT_EQUIP_AWARENESS_ENHANCE_REFRESH,
    }
end

function XUiEquipAwarenessEnhanceMain:OnNotify(evt)
    if evt == XEventId.EVENT_EQUIP_AWARENESS_ENHANCE_REFRESH then
        self:Refresh()
    end
end

----------------------------------------
-- 总刷新入口
----------------------------------------
function XUiEquipAwarenessEnhanceMain:RefreshAwarenessContext()
    self.AwarenessEquipIdBySite = self._Control:GetCharacterAwarenessIdDic(self.CharacterId)
    self.RefEquipId = self._Control:GetFirstWearAwarenessEquipId(self.AwarenessEquipIdBySite)
    self.RefTemplateId = self.RefEquipId and XMVCA.XEquip:GetEquipTemplateId(self.RefEquipId) or nil
end

function XUiEquipAwarenessEnhanceMain:Refresh()
    self:RefreshAutoExchangeFromCache()
    self:RefreshAwarenessContext()
    self:RefreshPanelAwareness()
    self:RefreshPanelResonanceSkill()
    self:RefreshEnhancePanels()
end

-- 刷新意识强化功能面板，并将已完成面板按强化、共鸣、超频顺序移至末尾。
function XUiEquipAwarenessEnhanceMain:RefreshEnhancePanels()
    -- 先恢复初始层级，避免多次刷新后以上一次排序结果作为基准。
    self.PanelStrengthen.transform:SetSiblingIndex(self.StrengthenSiblingIndex)
    self.PanelResonance.transform:SetSiblingIndex(self.ResonanceSiblingIndex)
    self.PanelOverclocking.transform:SetSiblingIndex(self.OverclockingSiblingIndex)

    local isStrengthenComplete = self.UiPanelStrengthen:Refresh()
    local isResonanceComplete = self.UiPanelResonance:Refresh()
    local isOverclockingVisible = self:HasAwakeSupportedAwareness()
    local isOverclockingComplete = false
    if isOverclockingVisible then
        self.UiPanelOverclocking:Open()
        isOverclockingComplete = self.UiPanelOverclocking:Refresh()
    else
        self.UiPanelOverclocking:Close()
    end

    local isAllComplete = isStrengthenComplete and isResonanceComplete and (not isOverclockingVisible or isOverclockingComplete)
    self.IsAllEnhanceComplete = isAllComplete
    self.BtnExecuteCompleteProcess:SetDisable(isAllComplete)

    if isStrengthenComplete then
        self.PanelStrengthen.transform:SetAsLastSibling()
    end

    if isResonanceComplete then
        self.PanelResonance.transform:SetAsLastSibling()
    end

    if isOverclockingComplete then
        self.PanelOverclocking.transform:SetAsLastSibling()
    end
end

-- 判断当前穿戴意识中是否存在星级支持超频的意识。
---@return boolean
function XUiEquipAwarenessEnhanceMain:HasAwakeSupportedAwareness()
    for site = 1, XEnumConst.EQUIP.WEAR_AWARENESS_COUNT do
        local equipId = self.AwarenessEquipIdBySite[site]
        if equipId and XMVCA.XEquip:CheckEquipStarCanAwake(equipId) then
            return true
        end
    end

    return false
end

----------------------------------------
-- 意识格子区
----------------------------------------
function XUiEquipAwarenessEnhanceMain:RefreshPanelAwareness()
    for equipSite = 1, XEnumConst.EQUIP.WEAR_AWARENESS_COUNT do
        local grid = self.AwarenessGrids[equipSite]
        if not grid then
            local go = CSInstantiate(self.GridAwareness, self["PanelAwareness" .. equipSite])
            grid = XUiGridEquip.New(go, self, function() self:OnAwarenessClick(equipSite) end)
            self.AwarenessGrids[equipSite] = grid
        end

        local equipId = self.AwarenessEquipIdBySite[equipSite]
        if not equipId then
            grid:Close()
        else
            grid:Open()
            grid:Refresh(equipId)
        end
    end
end

function XUiEquipAwarenessEnhanceMain:OnAwarenessClick(site)
    local targetAwarenessSlotList = XMVCA.XTeamRecommend:GetCharacterTargetAwarenessSlotList(self.CharacterId) or {}
    local targetSlotData = targetAwarenessSlotList[site]
    if targetSlotData and XTool.IsNumberValid(targetSlotData.EquipTemplateId) then
        local sourceTransform = self.AwarenessGrids[site].Transform
        XLuaUiManager.Open("UiTeamRecommendAwarenessTipsPopup", self.CharacterId, targetSlotData, nil, sourceTransform)
    end
end

----------------------------------------
-- 共鸣技能格子区
----------------------------------------
function XUiEquipAwarenessEnhanceMain:RefreshPanelResonanceSkill()
    local targetAwarenessSlotList = XMVCA.XTeamRecommend:GetCharacterTargetAwarenessSlotList(self.CharacterId) or {}
    local resonanceControl = self._Control.ResonanceControl
    local parent = self.GridDoubleResonanceSkill.transform.parent
    for index = 1, XEnumConst.EQUIP.WEAR_AWARENESS_COUNT do
        local grid = self.ResonanceSkillGrids[index]
        if not grid then
            local go = CSInstantiate(self.GridDoubleResonanceSkill, parent)
            go.gameObject:SetActiveEx(true)
            grid = {
                GameObject = go.gameObject,
                Transform = go.transform,
                TargetSkillGrids = {},
            }
            XTool.InitUiObject(grid)
            self.ResonanceSkillGrids[index] = grid
        end

        local targetSlotData = targetAwarenessSlotList[index]
        local hasTargetAwareness = targetSlotData ~= nil and XTool.IsNumberValid(targetSlotData.EquipTemplateId)
        local siteText = "0" .. index
        grid.TxtPos.text = siteText
        grid.TxtPosEmpty.text = siteText
        grid.ImgPos.gameObject:SetActiveEx(hasTargetAwareness)

        local equipId = self.AwarenessEquipIdBySite[index]
        local equip = self._Control:GetEquip(equipId)
        for pos = 1, XEnumConst.EQUIP.AWARENESS_RESONANCE_COUNT do
            local targetSkillUi = grid["GridResonanceSkill" .. pos]
            local targetGrid = grid.TargetSkillGrids[pos]
            if not targetGrid then
                targetGrid = XUiGridTRAwarenessResonanceSkill.New(targetSkillUi, self)
                grid.TargetSkillGrids[pos] = targetGrid
            end
            targetGrid:SetEnableClick(hasTargetAwareness)

            local targetResonanceData = hasTargetAwareness and targetSlotData.ResonanceList and targetSlotData.ResonanceList[pos]
            local targetState = resonanceControl:GetAwarenessResonanceTargetState(equip, pos, targetResonanceData, self.CharacterId)
            targetGrid:Refresh({
                ResonanceData = targetResonanceData,
                Site = index,
                Pos = pos,
                WearingEquipId = equipId,
                TargetState = targetState,
            })
            targetGrid:SetActiveImgPos(false)
            targetGrid:SetSelected(false)
            grid["PanelNoEquip0" .. pos].gameObject:SetActiveEx(false)
        end
    end
end

function XUiEquipAwarenessEnhanceMain:OnResonanceSkillClick(pos, site)
    local roleTargetDetailData = XMVCA.XTeamRecommend:BuildRoleTargetDetailData(self.CharacterId)
    local recommendCharData = roleTargetDetailData and roleTargetDetailData.RecommendCharData
    if not recommendCharData then
        return
    end

    XLuaUiManager.Open("UiTeamRecommendResonanceSkillPopup", recommendCharData, site, pos)
end

----------------------------------------
-- 全局工具按钮：自动兑换 / 一键执行
----------------------------------------
function XUiEquipAwarenessEnhanceMain:RefreshAutoExchangeFromCache()
    local isOn = self._Control:GetAwarenessEnhanceMainAutoExchangeOn()
    self.BtnAutoExchange:SetButtonState(isOn and CS.UiButtonState.Select or CS.UiButtonState.Normal)
end

function XUiEquipAwarenessEnhanceMain:OnBtnAutoExchangeClick()
    local isOn = self.BtnAutoExchange:GetToggleState()
    self._Control:SetAwarenessEnhanceMainAutoExchangeOn(isOn)
    self:Refresh()
end

function XUiEquipAwarenessEnhanceMain:OnBtnExecuteCompleteProcessClick()
    if self.IsAllEnhanceComplete then
        return
    end
    XLuaUiManager.Open("UiEquipAwarenessOneClickPopup", self.CharacterId)
end

return XUiEquipAwarenessEnhanceMain
