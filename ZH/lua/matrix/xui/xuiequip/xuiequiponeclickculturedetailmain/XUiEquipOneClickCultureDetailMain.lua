local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XUiPanelEquipOneClickCultureModule = require("XUi/XUiEquip/XUiEquipOneClickCultureDetailMain/XUiPanelEquipOneClickCultureModule")
local XUiGridWeaponResonanceSlot = require("XUi/XUiEquip/XUiEquipOneClickCultureDetailMain/XUiGridWeaponResonanceSlot")

---@class XUiEquipOneClickCultureDetailMain:XLuaUi
---@field _Control XEquipControl
local XUiEquipOneClickCultureDetailMain = XLuaUiManager.Register(XLuaUi, "UiEquipOneClickCultureDetailMain")

function XUiEquipOneClickCultureDetailMain:OnAwake()
    self._ModuleGridList = {}
    self._ResonanceGrids = {
        XUiGridWeaponResonanceSlot.New(self.GridEquipResonance1, self),
        XUiGridWeaponResonanceSlot.New(self.GridEquipResonance2, self),
        XUiGridWeaponResonanceSlot.New(self.GridEquipResonance3, self),
    }
    self:RegisterButtonEvent()
    self._TopController = XUiHelper.NewPanelTopControl(self, self.TopControl)
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.RepeatChallengeCoin, XDataCenter.ItemManager.ItemId.Coin)
    self.BtnOverrunLevelUiObj = self.BtnOverrunLevel:GetComponent("UiObject")
    self.BtnOverrunBoundUiObj = self.BtnOverrunBound:GetComponent("UiObject")
    self._OverrunLevelBtnUi = XTool.InitUiObjectByUi({}, self.BtnOverrunLevel)
end

function XUiEquipOneClickCultureDetailMain:OnStart(targetData)
    self.TargetData = targetData
    self.IsAutoExchange = self._Control.OneClickAutoSettingControl:GetSetting(
        XMVCA.XEquip.Enum.OneClickAutoSettingType.WeaponAutoExchange) == true
    self:RefreshExchangeButton()
    self:InitRoleModel()
end

function XUiEquipOneClickCultureDetailMain:OnEnable()
    self.Effect.gameObject:SetActiveEx(false)
    self:Refresh()
end

function XUiEquipOneClickCultureDetailMain:RegisterButtonEvent()
    self.BtnOneClickCulture:AddEventListener(handler(self, self.OnBtnOneClickCultureClick))
    self.ToggleExchange:AddEventListener(handler(self, self.OnToggleExchangeClick))
    self.BtnOverrunNoLevel:AddEventListener(handler(self, self.OnBtnOverrunClick))
    self.BtnOverrunLevel:AddEventListener(handler(self, self.OnBtnOverrunClick))
    self:BindHelpBtn(self.BtnHelp, "EquipOneClickCultureDetailMain")
end

function XUiEquipOneClickCultureDetailMain:Refresh()
    self.ViewData = self._Control.OneClickCultureControl:GetOneClickCultureViewData(self.TargetData, self.IsAutoExchange)
    if not self.ViewData then
        XLog.Error("UiEquipOneClickCultureDetailMain 找不到武器实例.")
        self:Close()
        return
    end

    self:RefreshBaseInfo()
    self:RefreshResonance()
    self:RefreshOverrun()
    self:RefreshModuleList()
    self:RefreshOneClickButton()
end

--- 加载武器 3D 模型（镜头 prefab 的 PanelRoleModel 节点实际挂武器模型）
function XUiEquipOneClickCultureDetailMain:InitRoleModel()
    local equipId = self._Control.OneClickCultureControl:GetOneClickCultureEquipId(self.TargetData)
    local equip = XMVCA.XEquip:GetEquip(equipId)
    local templateId = equip.TemplateId
    local breakthroughTimes = XMVCA.XEquip:GetEquipBreakthroughTimes(equipId)
    local resonanceCount = XMVCA.XEquip:GetEquipResonanceCount(equipId)
    local modelTransformName = "UiEquipOneClickCultureDetailMain"
    local modelConfig = XMVCA.XEquip:GetWeaponModelCfg(templateId, modelTransformName, breakthroughTimes, resonanceCount)
    local panelModel = self.UiModelGo.transform:FindTransform("PanelRoleModel")
    XModelManager.LoadWeaponModel(
        modelConfig.ModelId,
        panelModel,
        modelConfig.TransformConfig,
        modelTransformName,
        nil,
        { gameObject = self.GameObject, usage = XEnumConst.EQUIP.WEAPON_USAGE.SHOW },
        nil)
    self:AdaptScreenAspectRatio()
end

--- 分辨率适配
function XUiEquipOneClickCultureDetailMain:AdaptScreenAspectRatio()
    local nearRoot = self.UiModelGo.transform:FindTransform("NearRoot")
    if not nearRoot then
        return
    end
    local cameraNames = { "CamNearMainPad", "CamNearMainStandard", "CamNearMainWidescreen" }
    local ratios = string.Split(CS.XGame.ClientConfig:GetString("PassportModelAdapt"))

    local width = CS.XUiManager.RealScreenWidth
    local height = CS.XUiManager.RealScreenHeight
    local realRatio = math.max(width, height) / math.min(width, height)

    local currentIndex = 1
    for _, targetRatio in pairs(ratios) do
        if realRatio > tonumber(targetRatio) then
            currentIndex = currentIndex + 1
        else
            break
        end
    end

    for i, name in ipairs(cameraNames) do
        local cam = nearRoot:FindTransform(name)
        if cam then
            cam.gameObject:SetActiveEx(i == currentIndex)
        end
    end
end

function XUiEquipOneClickCultureDetailMain:RefreshBaseInfo()
    local data = self.ViewData
    local templateId = data.TemplateId
    local star = self._Control:GetEquipStar(templateId)
    for index = 1, XEnumConst.EQUIP.MAX_STAR_COUNT do
        self["ImgStar" .. index].gameObject:SetActiveEx(index <= star)
    end
    self.TxtEquipName.text = self._Control:GetEquipName(templateId)
    self.TxtLevel.text = data.Level
    self.TxtLevel2.text = data.LevelLimit
    self:SetUiSprite(self.ImgBreak, self._Control:GetEquipBreakThroughIcon(data.Breakthrough))

    local isWearing = XTool.IsNumberValid(data.CharacterId)
    self.PanelCharacterInfo.gameObject:SetActiveEx(isWearing)
    if isWearing then
        self.RImgCharHead:SetRawImage(XMVCA.XCharacter:GetCharBigRoundnessNotItemHeadIcon(data.CharacterId))
    end
end

function XUiEquipOneClickCultureDetailMain:RefreshResonance()
    local data = self.ViewData
    self.PaneEquipResonance.gameObject:SetActiveEx(true)
    -- PaneEquipResonance 下 child 0 是 BtnResonance，共鸣槽从 child 1 起，故 defaultIndex = 1
    XTool.UpdateDynamicItemByUiCache(
        self._ResonanceGrids,
        data.ResonanceList,
        self.PaneEquipResonance.transform,
        XUiGridWeaponResonanceSlot,
        self,
        1)
end

function XUiEquipOneClickCultureDetailMain:RefreshOverrun()
    local data = self.ViewData
    local isConfigured = XTool.IsNumberValid(data.TargetSuitId) and data.MaxOverrunLevel > 0
    self.PanelEquipOverrun.gameObject:SetActiveEx(isConfigured)
    if not isConfigured then
        return
    end
    self:_RefreshOverrunLevelBtn()
    self:_RefreshOverrunSuit()
end

function XUiEquipOneClickCultureDetailMain:_RefreshOverrunSuit()
    local suitId = self.ViewData.TargetSuitId
    local suitIcon = XTool.IsNumberValid(suitId) and XMVCA.XEquip:GetEquipSuitIconPath(suitId) or nil
    self.RImgSuit:SetRawImage(suitIcon)
end

-- 谐振等级按钮渲染
function XUiEquipOneClickCultureDetailMain:_RefreshOverrunLevelBtn()
    local data = self.ViewData
    local lv = data.MaxOverrunLevel or 0
    local isLevel = lv > 0
    local showLevel = (data.OverrunLevel or 0) .. "/" .. (lv or 0)
    local OVERRUN_LEVEL_TYPE = XEnumConst.EQUIP.WEAPON_OVERRUN_LEVEL_TYPE
    local isLv1 = lv == OVERRUN_LEVEL_TYPE.LEVEL1
    local isLvGe2 = lv >= OVERRUN_LEVEL_TYPE.LEVEL2

    self.BtnOverrunLevel.gameObject:SetActiveEx(isLevel)
    if not isLevel then
        return
    end

    local btnUi = self._OverrunLevelBtnUi
    btnUi.TxtLevel.text = tostring(showLevel)
    btnUi.TxtLevel1.text = tostring(showLevel)
    btnUi.UiTxtLevelImg1.gameObject:SetActiveEx(isLv1)
    btnUi.UiTxtLevelImg2.gameObject:SetActiveEx(isLvGe2)
    btnUi.UiTxtLevelImg3.gameObject:SetActiveEx(isLv1)
    btnUi.UiTxtLevelImg4.gameObject:SetActiveEx(isLvGe2)
    btnUi.PanelDotGroup.gameObject:SetActiveEx(isLvGe2)
    btnUi.PanelDotGroup1.gameObject:SetActiveEx(isLvGe2)

    local sub = self._Control.OneClickCultureControl
    self.BtnOverrunLevel:SetDisable(not sub:IsOverrunLevelFull(data.EquipId, self.TargetData))

    local isTargetSuitActivated = sub:IsOverrunSuitActivated(data.EquipId, data.TargetSuitId)
    local blackMask = self.BtnOverrunBoundUiObj:GetObject("BlackMask")
    if blackMask then
        blackMask.gameObject:SetActiveEx(not isTargetSuitActivated)
    end
end

function XUiEquipOneClickCultureDetailMain:RefreshModuleList()
    XTool.UpdateDynamicItem(
        self._ModuleGridList,
        self.ViewData.ModuleDataList,
        self.PanelUnit,
        XUiPanelEquipOneClickCultureModule,
        self)
end

function XUiEquipOneClickCultureDetailMain:RefreshOneClickButton()
    local textKey = self.ViewData.IsAllComplete and "EquipOneClickCultureComplete" or "EquipOneClickCultureOneClick"
    self.BtnOneClickCulture:SetNameByGroup(0, CS.XTextManager.GetText(textKey))
    self.BtnOneClickCulture:SetDisable(self.ViewData.IsAllComplete, not self.ViewData.IsAllComplete)
end

function XUiEquipOneClickCultureDetailMain:OnBtnOneClickCultureClick()
    if self.ViewData.IsAllComplete then
        return
    end
    XLuaUiManager.Open("UiEquipWeaponOneClickPopup", {
        EquipId = self.ViewData.EquipId,
        TargetData = self.TargetData,
        IsAutoExchange = self.IsAutoExchange,
        OnExchangeChanged = handler(self, self.OnPopupExchangeChanged),
        OnCultureFinished = handler(self, self.OnCultureFinished),
    })
end

--- 一键养成执行成功后回刷（进度弹窗关闭时触发；本界面被弹窗覆盖不会自动 OnEnable，需手动刷）
function XUiEquipOneClickCultureDetailMain:OnCultureFinished()
    self:ReplayUpgradeEffect()
    self:Refresh()
end

function XUiEquipOneClickCultureDetailMain:ReplayUpgradeEffect()
    if not self.Effect then
        return
    end
    self.Effect.gameObject:SetActiveEx(false)
    self.Effect.gameObject:SetActiveEx(true)
end

--- 一键养成弹窗内切换自动兑换时回同步
function XUiEquipOneClickCultureDetailMain:OnPopupExchangeChanged(isAutoExchange)
    self.IsAutoExchange = isAutoExchange
    self:SaveAutoExchangeSetting()
    self:RefreshExchangeButton()
    self:Refresh()
end

function XUiEquipOneClickCultureDetailMain:OnToggleExchangeClick()
    self.IsAutoExchange = not self.IsAutoExchange
    self:SaveAutoExchangeSetting()
    self:RefreshExchangeButton()
    self:Refresh()
end

function XUiEquipOneClickCultureDetailMain:SaveAutoExchangeSetting()
    self._Control.OneClickAutoSettingControl:SetSetting(
        XMVCA.XEquip.Enum.OneClickAutoSettingType.WeaponAutoExchange, self.IsAutoExchange)
end

function XUiEquipOneClickCultureDetailMain:RefreshExchangeButton()
    local state = self.IsAutoExchange and CS.UiButtonState.Select or CS.UiButtonState.Normal
    self.ToggleExchange:SetButtonState(state)
end

function XUiEquipOneClickCultureDetailMain:OnBtnOverrunClick()
    XLuaUiManager.Open("UiEquipOverrunSelect", self.ViewData.EquipId, handler(self, self.Refresh), true, self.ViewData.TargetSuitId)
end

function XUiEquipOneClickCultureDetailMain:OpenCultureUi(tabIndex)
    XLuaUiManager.Open(
        "UiEquipDetailV2P6",
        self.ViewData.EquipId,
        nil,
        self.ViewData.CharacterId,
        nil,
        tabIndex)
end

return XUiEquipOneClickCultureDetailMain
