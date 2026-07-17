---@diagnostic disable: type-not-found, unnecessary-if
local XUiEquipOverrunV4P6GridOverrunSuit = require("XUi/XUiEquip/XUiEquipOverrunV4P6/XUiEquipOverrunV4P6GridOverrunSuit")
local XUiEquipOverrunV4P6GridOverrunAttr = require("XUi/XUiEquip/XUiEquipOverrunV4P6/XUiEquipOverrunV4P6GridOverrunAttr")
local XUiEquipOverrunV4P6GridOverrunUpSkill = require("XUi/XUiEquip/XUiEquipOverrunV4P6/XUiEquipOverrunV4P6GridOverrunUpSkill")
local XUiEquipOverrunV4P6PanelDetail = require("XUi/XUiEquip/XUiEquipOverrunV4P6/XUiEquipOverrunV4P6PanelDetail")

local UNLOCK_TYPE = XEnumConst.EQUIP.WEAPON_OVERRUN_UNLOCK_TYPE
local PANEL_LEVEL_MOVE_DURATION = 0.5
local OVERRUN_LEVEL_MAX = 7  -- 谐振等级最大数量，对应 BtnNum1-7
local OVERRUN_GRID_CLASS = {
    [UNLOCK_TYPE.SUIT]  = XUiEquipOverrunV4P6GridOverrunSuit,
    [UNLOCK_TYPE.ATTR]  = XUiEquipOverrunV4P6GridOverrunAttr,
    [UNLOCK_TYPE.UP_SKILL] = XUiEquipOverrunV4P6GridOverrunUpSkill,
}

---@class XUiEquipOverrunV4P6 : XLuaUi
---@field _Control XEquipControl
---@field ParentUi XUiEquipDetailV2P6
---@field PanelMain UnityEngine.RectTransform
---@field PanelLevel1 UnityEngine.RectTransform
---@field PanelLevel2 UnityEngine.RectTransform
---@field PanelLevel3 UnityEngine.RectTransform
---@field PanelLevel4 UnityEngine.RectTransform
---@field PanelLevel5 UnityEngine.RectTransform
---@field PanelLevel6 UnityEngine.RectTransform
---@field PanelLevel7 UnityEngine.RectTransform
---@field PanelDetail UnityEngine.RectTransform
---@field PanelActivated UnityEngine.RectTransform
---@field GridOverrunDic table<number, XUiEquipOverrunV4P6GridOverrunBase>
---@field ButtonGroup CS.XUiButtonGroup
---@field UiPanelDetail XUiEquipOverrunV4P6PanelDetail
---@field UiTxtProgress UnityEngine.UI.Text
---@field TagBgMax UnityEngine.GameObject
---@field BgTranslateRight UnityEngine.Transform
---@field BgTranslateLeft UnityEngine.Transform
---@field BtnNum1 CS.XUiButton  -- 谐振等级1 切换按钮
---@field BtnNum2 CS.XUiButton  -- 谐振等级2 切换按钮
---@field BtnNum3 CS.XUiButton  -- 谐振等级3 切换按钮
---@field BtnNum4 CS.XUiButton  -- 谐振等级4 切换按钮
---@field BtnNum5 CS.XUiButton  -- 谐振等级5 切换按钮
---@field BtnNum6 CS.XUiButton  -- 谐振等级6 切换按钮
---@field BtnNum7 CS.XUiButton  -- 谐振等级7 切换按钮
local XUiEquipOverrunV4P6 = XLuaUiManager.Register(XLuaUi, "UiEquipOverrunV4P6")

function XUiEquipOverrunV4P6:OnAwake()
    self.PanelDetail.gameObject:SetActiveEx(false)
end

function XUiEquipOverrunV4P6:OnStart()
    self.EquipId = self.ParentUi.EquipId
    self.TemplateId = self.ParentUi.TemplateId
    self.Equip = self._Control:GetEquip(self.EquipId)
    local root = self.ParentUi.UiModelGo.transform
    self.BgTranslateRight = root:FindTransform("BgTranslateRight")
    self.BgTranslateLeft = root:FindTransform("BgTranslateLeft")
    local characterId = XTool.IsNumberValidEx(self.ParentUi.CharacterId) and self.ParentUi.CharacterId or XMVCA.XEquip:GetWeaponOverrunCharacterId(self.TemplateId)
    self.OverrunCfgIds = self._Control:GetWeaponOverrunCfgIds(self.TemplateId, characterId)
    self:InitGridOverruns()
    self:InitBtnNums()
end

function XUiEquipOverrunV4P6:OnEnable()
    self.ParentUi.EffectUiOverrunV4P6.gameObject:SetActiveEx(true)
    self.ParentUi:DisableWeaponRotate()
    self.ParentUi:DoTweenRotateWeaponToOrigin()
    self:RefreshVirtualCamera()
    self.ParentUi:UpdateOverrunSceneEffect()
    self:Refresh()
end

function XUiEquipOverrunV4P6:OnDisable()
    self.ParentUi.EffectUiOverrunV4P6.gameObject:SetActiveEx(false)
    self.ParentUi:EnableWeaponRotate()
    self.ParentUi:SwitchOverrunExitVirtualCamera()
end

function XUiEquipOverrunV4P6:Refresh()
    if self.UiPanelDetail and self.UiPanelDetail:IsNodeShow() then
        self.UiPanelDetail:Refresh()
    end
    self:RefreshGridOverruns()
    self:RefreshGridOverrunVisible()
    self:RefreshProgress()
end

-- 刷新谐振进度文本（当前等级/最大等级），满级时显示 TagBgMax
function XUiEquipOverrunV4P6:RefreshProgress()
    local curLv = self.Equip:GetOverrunLevel()
    local maxLv = self.GridOverrunCount
    self.UiTxtProgress.text = string.format("%s<size=72><color=#636563>/%s</color></size>", curLv, maxLv)
    self.TagBgMax.gameObject:SetActiveEx(curLv >= maxLv)
end

function XUiEquipOverrunV4P6:InitGridOverruns()
    self.GridOverrunDic = {}
    self.GridOverrunCount = 0
    for level, overrunCfgId in pairs(self.OverrunCfgIds) do
        local overrunCfg = self._Control:GetWeaponOverrunConfigById(overrunCfgId)
        local cls = OVERRUN_GRID_CLASS[overrunCfg.OverrunType]
        if cls then
            local go = self["PanelLevel" .. level]
            self.GridOverrunDic[level] = cls.New(go, self, level, overrunCfgId)
            self.GridOverrunCount = self.GridOverrunCount + 1
        end
    end
    self:RefreshGridOverrunPositions(true)
end

function XUiEquipOverrunV4P6:RefreshGridOverruns()
    for _, gridOverrun in pairs(self.GridOverrunDic) do
        gridOverrun:Refresh()
    end
end

function XUiEquipOverrunV4P6:GetUiLayoutKey()
    return self.SelectIndex or 0
end

function XUiEquipOverrunV4P6:GetOverrunUiNodePos(overrunCfg)
    local layoutKey = self:GetUiLayoutKey()
    local x = overrunCfg.UiNodePosX and overrunCfg.UiNodePosX[layoutKey]
    local y = overrunCfg.UiNodePosY and overrunCfg.UiNodePosY[layoutKey]
    return x, y
end

function XUiEquipOverrunV4P6:RefreshGridOverrunPositions(isImmediate)
    for _, gridOverrun in pairs(self.GridOverrunDic) do
        local overrunCfg = gridOverrun:GetOverrunConfig()
        local x, y = self:GetOverrunUiNodePos(overrunCfg)
        if x ~= nil and y ~= nil then
            local rectTransform = gridOverrun.Transform:GetComponent(typeof(CS.UnityEngine.RectTransform))
            local targetPos = CS.UnityEngine.Vector2(x, y)
            if isImmediate then
                rectTransform.anchoredPosition = targetPos
            else
                rectTransform:DOKill()
                gridOverrun:SetLineVisible(false)
                rectTransform:DOAnchorPos(targetPos, PANEL_LEVEL_MOVE_DURATION):OnComplete(function()
                    gridOverrun:SetLineVisible(true)
                end)
            end
        end
    end
end

function XUiEquipOverrunV4P6:RefreshVirtualCamera()
    if self.SelectIndex == nil then
        self.ParentUi:SwitchVirtualCamera(nil, nil)
    else
        local overrunCfg = self._Control:GetWeaponOverrunConfigById(self.OverrunCfgIds[self.SelectIndex])
        self.ParentUi:SwitchVirtualCamera(self.SelectIndex, overrunCfg)
    end
end

function XUiEquipOverrunV4P6:RefreshGridOverrunVisible()
    for _, gridOverrun in pairs(self.GridOverrunDic) do
        local x, y = self:GetOverrunUiNodePos(gridOverrun:GetOverrunConfig())
        gridOverrun:SetVisible(x ~= nil and y ~= nil)
    end
end

function XUiEquipOverrunV4P6:OnClickGridOverrun(index)
    self:SetSelectIndex(index)
end

function XUiEquipOverrunV4P6:SetSelectIndex(index)
    local prev = self.SelectIndex
    if prev == index then
        return
    end

    self.SelectIndex = index

    -- 切换GridOverrun选中状态
    for _, gridOverrun in pairs(self.GridOverrunDic) do
        gridOverrun:RefreshSelectState()
    end

    self:RefreshVirtualCamera()
    self.ParentUi:UpdateOverrunSceneEffect()
    self:RefreshGridOverrunVisible()
    self:RefreshBtnNums()

    -- 显示/切换/隐藏详情面板
    if index == nil then
        self:HidePanelDetail()
    elseif prev == nil then
        self:ShowPanelDetail()
    elseif prev ~= index then
        self.UiPanelDetail:Refresh()
        self:RefreshGridOverrunPositions(false)
    end
end

-- 获取当前选中的GridOverrun索引
function XUiEquipOverrunV4P6:GetSelectIndex()
    return self.SelectIndex
end

function XUiEquipOverrunV4P6:GetSelectOverrunCfgId()
    if self.SelectIndex then 
        return self.OverrunCfgIds[self.SelectIndex]
    end
end

function XUiEquipOverrunV4P6:GetOverrunCfgIdByLevel(level)
    return self.OverrunCfgIds[level]
end

function XUiEquipOverrunV4P6:GetGridOverrunCount()
    return self.GridOverrunCount
end

-- 初始化谐振等级切换按钮（BtnNum1-BtnNum7），无配置的等级隐藏按钮并注册点击事件
function XUiEquipOverrunV4P6:InitBtnNums()
    for i = 1, OVERRUN_LEVEL_MAX do
        local btn = self["BtnNum" .. i]
        if not self.OverrunCfgIds[i] then
            -- 该等级无配置，隐藏对应按钮
            btn.gameObject:SetActiveEx(false)
        else
            local level = i
            btn:AddEventListener(function() self:OnClickBtnNum(level) end)
        end
    end
end

-- 点击谐振等级按钮，选中对应等级
function XUiEquipOverrunV4P6:OnClickBtnNum(level)
    self:SetSelectIndex(level)
end

-- 刷新 BtnNum1-BtnNum7 的选中状态（与 SelectIndex 保持同步）
function XUiEquipOverrunV4P6:RefreshBtnNums()
    for i = 1, OVERRUN_LEVEL_MAX do
        if self.OverrunCfgIds[i] then
            local btn = self["BtnNum" .. i]
            local state = (self.SelectIndex == i) and CS.UiButtonState.Select or CS.UiButtonState.Normal
            btn:SetButtonState(state)
            btn.TempState = state
        end
    end
end

--region PanelDetail
function XUiEquipOverrunV4P6:GetIsShowPanelDetail()
    return self.SelectIndex ~= nil
end

function XUiEquipOverrunV4P6:ClosePanelDetail()
    self:SetSelectIndex(nil)
end

function XUiEquipOverrunV4P6:ShowPanelDetail()
    self:PlayAnimation("BgTranslateLeft")
    self.BgTranslateLeft:PlayTimelineAnimation()
    self.ParentUi:ShowPanelTabGroup(false)
    self.PanelActivated.gameObject:SetActiveEx(false)

    self:RefreshGridOverruns()
    self:RefreshGridOverrunPositions(false)

    if not self.UiPanelDetail then
        self.UiPanelDetail = XUiEquipOverrunV4P6PanelDetail.New(self.PanelDetail, self)
    end
    self.UiPanelDetail:Open()
end

function XUiEquipOverrunV4P6:HidePanelDetail()
    self:PlayAnimation("BgTranslateRight")
    self.BgTranslateRight:PlayTimelineAnimation()
    self.ParentUi:ShowPanelTabGroup(true)
    self.PanelActivated.gameObject:SetActiveEx(true)

    self:RefreshGridOverruns()
    self:RefreshGridOverrunPositions(false)

    if self.UiPanelDetail then
        self.UiPanelDetail:Close()
    end
end
--endregion

return XUiEquipOverrunV4P6