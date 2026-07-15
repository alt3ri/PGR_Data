local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local CSXUiPlayTimelineAnimation = CS.XUiPlayTimelineAnimation

local XUiEquipDetailWeaponPanel = require("XUi/XUiEquip/XUiEquipDetailV2P6/XUiEquipDetailWeaponPanel")
local XUiEquipDetailAwarenessPanel = require("XUi/XUiEquip/XUiEquipDetailV2P6/XUiEquipDetailAwarenessPanel")

---@class XUiEquipDetailChildV2P6
---@field _WeaponPanel XUiEquipDetailWeaponPanel
---@field _AwarenessPanel XUiEquipDetailAwarenessPanel
local XUiEquipDetailChildV2P6 = XLuaUiManager.Register(XLuaUi, "UiEquipDetailChildV2P6")
function XUiEquipDetailChildV2P6:OnAwake()
    -- UI初始化
    self.PanelTab.gameObject:SetActiveEx(false)
    self.PanelPainter.gameObject:SetActiveEx(false)
    self.PanelAwarenessResonance.gameObject:SetActiveEx(false)
    self.FxUiLihuiChuxian01.gameObject:SetActiveEx(false)
    -- 子面板按装备类型互斥创建（见 OnStart）；先全部隐藏，避免未创建一侧露出 prefab 默认状态
    self.PanelWeapon.gameObject:SetActiveEx(false)
    self.PanelAwareness.gameObject:SetActiveEx(false)

    -- 场景初始化
    local sceneRoot = self.UiSceneInfo.Transform
    local root = self.UiModelGo.transform
    self.ScenePanelWeapon = root:FindTransform("PanelWeapon")
    self.ScenePanelWeaponPlane = sceneRoot:FindTransform("Plane")
    self.ImgEffectOverrun = root:FindTransform("ImgEffectOverrun")

    self:SetButtonCallBack()
    self:InitPanelAsset()
end

--参数isPreview为true时是装备详情预览，传templateId进来
--characterId只有需要判断武器共鸣特效时才传
function XUiEquipDetailChildV2P6:OnStart(equipId, isPreview, characterId, forceShowBindCharacter, childUiIndex, openUiType, isShowExtendPanel)
    self.IsPreview = isPreview
    self.EquipId = equipId
    self.CharacterId = characterId
    self.ForceShowBindCharacter = forceShowBindCharacter
    self.TemplateId = isPreview and self.EquipId or XMVCA.XEquip:GetEquipTemplateId(equipId)
    self.OpenUiType = openUiType
    self.IsWeapon = XMVCA.XEquip:IsEquipWeapon(self.TemplateId)
    self.IsAwareness = XMVCA.XEquip:IsEquipAwareness(self.TemplateId)
    if self.IsWeapon then
        -- 武器分组子界面（按需创建，与意识互斥）
        self._WeaponPanel = XUiEquipDetailWeaponPanel.New(self.PanelWeapon, self)
    elseif self.IsAwareness then
        -- 意识分组子界面（prefab 引用仍在父类上，AwarenessPanel 内部通过 self.Parent.xxx 访问）
        self._AwarenessPanel = XUiEquipDetailAwarenessPanel.New(self.PanelAwareness, self)
        self._AwarenessPanel:InitOnEquipChanged(equipId, isShowExtendPanel)
    end
    self:RegisterHelpBtn()

    if not XDataCenter.VoteManager.IsInit() then
        XDataCenter.VoteManager.GetVoteGroupListRequest()
    end
end

function XUiEquipDetailChildV2P6:OnEnable()
    self:UpdateView()
end

function XUiEquipDetailChildV2P6:OnDestroy()
end

function XUiEquipDetailChildV2P6:OnGetEvents()
    return {
        XEventId.EVENT_EQUIP_LOCK_STATUS_CHANGE_NOTYFY, 
        XEventId.EVENT_EQUIP_RECYCLE_STATUS_CHANGE_NOTYFY,
        XEventId.EVENT_EQUIP_RESONANCE_NOTYFY,
        XEventId.EVENT_EQUIP_SELECT_EQUIP,
    }
end

function XUiEquipDetailChildV2P6:OnNotify(evt, ...)
    local args = { ... }
    local equipId = args[1]
    
    -- 切换当前选择的装备
    if evt == XEventId.EVENT_EQUIP_SELECT_EQUIP then
        if self._AwarenessPanel then
            self._AwarenessPanel:OnEquipSelected(equipId)
        end
        return
    end

    -- 以下事件的 equipId 才是「当前装备」，需要与本页 EquipId 匹配；预览模式不响应
    if self.IsPreview or equipId ~= self.EquipId then
        return
    end

    if evt == XEventId.EVENT_EQUIP_LOCK_STATUS_CHANGE_NOTYFY then
        self:UpdateEquipLock()
        self:UpdateEquipRecycle()
    elseif evt == XEventId.EVENT_EQUIP_RECYCLE_STATUS_CHANGE_NOTYFY then
        self:UpdateEquipRecycle()
    elseif evt == XEventId.EVENT_EQUIP_RESONANCE_NOTYFY then
        XMVCA.XEquip:TipEquipOperation(nil, XUiHelper.GetText("DormTemplateSelectSuccess"))
        if self._WeaponPanel then
            self._WeaponPanel:UpdateEquipResonance()

            local slots = args[2]
            for _, pos in ipairs(slots) do
                self._WeaponPanel:SetResonanceEffectActive(pos, true)
            end
        end
    end
end

function XUiEquipDetailChildV2P6:SetButtonCallBack()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainClick)
    self:RegisterClickEvent(self.BtnLock, self.OnBtnLockClick)
    self:RegisterClickEvent(self.BtnUnlock, self.OnBtnUnlockClick)
    self:RegisterClickEvent(self.BtnLaJi, self.OnBtnLaJiClick)
    self:RegisterClickEvent(self.BtnUnLaJi, self.OnBtnUnLaJiClick)
    self:RegisterClickEvent(self.BtnStrengthen, self.OnBtnStrengthen)
end


function XUiEquipDetailChildV2P6:RegisterHelpBtn()
    local keyStr = self.IsWeapon and "EquipWeapon" or "EquipAwareness"
    self:BindHelpBtn(self.BtnHelp, keyStr)

    if XUiManager.IsHideFunc then
        self.BtnHelp.gameObject:SetActiveEx(false)
    end
end

function XUiEquipDetailChildV2P6:OnBtnBackClick()
    self:Close()
end

function XUiEquipDetailChildV2P6:OnBtnMainClick()
    XLuaUiManager.RunMain()
end

function XUiEquipDetailChildV2P6:OnBtnLockClick()
    XMVCA.XEquip:SetLock(self.EquipId, false)
end

function XUiEquipDetailChildV2P6:OnBtnUnlockClick()
    XMVCA.XEquip:SetLock(self.EquipId, true)
end

function XUiEquipDetailChildV2P6:OnBtnLaJiClick()
    XMVCA.XEquip:EquipUpdateRecycleRequest(self.EquipId, false)
end

function XUiEquipDetailChildV2P6:OnBtnUnLaJiClick()
    XMVCA.XEquip:EquipUpdateRecycleRequest(self.EquipId, true)
end

-- 切换到指定装备（由 AwarenessPanel 切意识时调用）
function XUiEquipDetailChildV2P6:SwitchToEquip(equipId)
    self.EquipId = equipId
    self.TemplateId = XMVCA.XEquip:GetEquipTemplateId(equipId)
    self:UpdateView()
    self:PlayAnimation("QieHuan")
end

function XUiEquipDetailChildV2P6:OnBtnStrengthen()
    if self.IsPreview then 
        return
    end
    XLuaUiManager.Open("UiEquipDetailV2P6", self.EquipId, nil, self.CharacterId, self.ForceShowBindCharacter, XEnumConst.EQUIP.UI_EQUIP_DETAIL_BTN_INDEX.STRENGTHEN)
end

function XUiEquipDetailChildV2P6:InitPanelAsset()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset,
        XDataCenter.ItemManager.ItemId.FreeGem,
        XDataCenter.ItemManager.ItemId.ActionPoint,
        XDataCenter.ItemManager.ItemId.Coin
    )
end

-- 初始化武器模型/意识立绘
function XUiEquipDetailChildV2P6:InitModel()
    self.ScenePanelWeapon.gameObject:SetActiveEx(false)
    self.ScenePanelWeaponPlane.gameObject:SetActiveEx(false)
end

-- 是否处于 NieR 角色界面模式
function XUiEquipDetailChildV2P6:_IsNieRMode()
    return self.OpenUiType == XUiConfigs.OpenUiType.NieRCharacterUI
end

-- NieR 模式下读取 level/breakTimes（武器/纹章自动判断）
function XUiEquipDetailChildV2P6:_GetNieRLevelAndBreak()
    local character = XDataCenter.NieRManager.GetSelNieRCharacter()
    local equipSite = XMVCA.XEquip:GetEquipSite(self.TemplateId)
    local isWafer = equipSite and equipSite ~= XEnumConst.EQUIP.EQUIP_SITE.WEAPON
    if isWafer then
        return character:GetNieRWaferLevel(self.EquipId), character:GetNieRWaferBreakThroughById(self.EquipId)
    end
    return character:GetNieRWeaponLevel(), character:GetNieRWeaponBreakThrough()
end

-- 刷新界面
function XUiEquipDetailChildV2P6:UpdateView()
    self:InitModel()
    self:UpdateEquipLock()
    self:UpdateEquipRecycle()
    self:UpdateCharacterInfo()
    self:UpdateEquipInfo()
    self:UpdateEquipLevel()
    self:UpdateEquipBreakThrough()
    self:UpdateEquipAttr()

    if self._WeaponPanel then
        self._WeaponPanel:Open()
        self._WeaponPanel:Refresh()
    end

    if self._AwarenessPanel then
        self._AwarenessPanel:Open()
        self._AwarenessPanel:Refresh()
    end
end

-- 刷新锁按钮
function XUiEquipDetailChildV2P6:UpdateEquipLock()
    if self.IsPreview then
        self.BtnUnlock.gameObject:SetActive(false)
        self.BtnLock.gameObject:SetActive(false)
        return
    end

    local isLock = XMVCA.XEquip:IsLock(self.EquipId)
    self.BtnUnlock.gameObject:SetActive(not isLock)
    self.BtnLock.gameObject:SetActive(isLock)
end

-- 刷新回收按钮
function XUiEquipDetailChildV2P6:UpdateEquipRecycle()
    if self.IsPreview then
        self.BtnLaJi.gameObject:SetActive(false)
        self.BtnUnLaJi.gameObject:SetActive(false)
        return
    end

    local isCanRecycle = XMVCA.XEquip:IsEquipCanRecycle(self.EquipId)
    local isRecycle = XMVCA.XEquip:IsRecycle(self.EquipId)
    self.BtnLaJi.gameObject:SetActiveEx(isCanRecycle and isRecycle)
    self.BtnUnLaJi.gameObject:SetActiveEx(isCanRecycle and not isRecycle)
end

-- 刷新穿戴武器信息
function XUiEquipDetailChildV2P6:UpdateCharacterInfo()
    if self.IsPreview then 
        self.PanelCharacterInfo.gameObject:SetActiveEx(false)
        return
    end

    local equip = XMVCA.XEquip:GetEquip(self.EquipId)
    local isWearing = equip:IsWearing()
    self.PanelCharacterInfo.gameObject:SetActiveEx(isWearing)
    if isWearing then
        local icon = XMVCA.XCharacter:GetCharBigRoundnessNotItemHeadIcon(equip.CharacterId)
        self.RImgCharHead:SetRawImage(icon)
    end
end

-- 刷新武器信息
function XUiEquipDetailChildV2P6:UpdateEquipInfo()
    local star = XMVCA.XEquip:GetEquipStar(self.TemplateId)
    for i = 1, XEnumConst.EQUIP.MAX_STAR_COUNT do
        self["ImgStar" .. i].gameObject:SetActiveEx(i <= star)
    end
    self.TxtEquipName.text = XMVCA.XEquip:GetEquipName(self.TemplateId)

    self.TxtWeaponType.gameObject:SetActiveEx(self.IsWeapon)
    if self.IsWeapon then 
        local equipType = XMVCA.XEquip:GetEquipType(self.TemplateId)
        local weaponGroupCfg = XMVCA.XArchive:GetWeaponGroupByType(equipType)
        self.TxtWeaponType.text = weaponGroupCfg and weaponGroupCfg.GroupName or ""
    end
end

-- 刷新武器等级
function XUiEquipDetailChildV2P6:UpdateEquipLevel()
    local level, levelLimit
    local equipId = self.EquipId

    if self:_IsNieRMode() then
        local nieRLevel, nieRBreak = self:_GetNieRLevelAndBreak()
        level = nieRLevel
        levelLimit = XMVCA.XEquip:GetEquipBreakthroughLevelLimit(self.TemplateId, nieRBreak)
        local isMaxLevel = XMVCA.XEquip:IsMaxLevelAndBreakthrough(equipId)
        self.PanelMaxLevel.gameObject:SetActiveEx(isMaxLevel)
        self.PanelMaxStrengthen.gameObject:SetActiveEx(isMaxLevel)
        self.BtnStrengthen.gameObject:SetActive(not isMaxLevel)
    elseif self.IsPreview then
        level = 1
        levelLimit = XMVCA.XEquip:GetEquipBreakthroughLevelLimit(self.TemplateId)
        self.PanelMaxLevel.gameObject:SetActive(false)
        self.PanelMaxStrengthen.gameObject:SetActiveEx(false)
        self.BtnStrengthen.gameObject:SetActive(false)
    else
        local equip = XMVCA.XEquip:GetEquip(equipId)
        level = equip.Level
        levelLimit = XMVCA.XEquip:GetEquipBreakthroughLevelLimitByEquipId(equipId)
        local isMaxLevel = XMVCA.XEquip:IsMaxLevelAndBreakthrough(equipId)
        self.PanelMaxLevel.gameObject:SetActive(isMaxLevel)
        self.PanelMaxStrengthen.gameObject:SetActiveEx(isMaxLevel)
        self.BtnStrengthen.gameObject:SetActive(not isMaxLevel)
    end

    self.TxtLevel.text = level
    self.TxtLevel2.text = levelLimit
end

-- 刷新武器突破
function XUiEquipDetailChildV2P6:UpdateEquipBreakThrough()
    if self:_IsNieRMode() then
        local _, breakTimes = self:_GetNieRLevelAndBreak()
        self:SetUiSprite(self.ImgBreak, self._Control:GetEquipBreakThroughIcon(breakTimes))
        return
    elseif self.IsPreview then
        self:SetUiSprite(self.ImgBreak, self._Control:GetEquipBreakThroughIcon(0))
        return
    end

    local equip = XMVCA.XEquip:GetEquip(self.EquipId)
    self:SetUiSprite(self.ImgBreak, self._Control:GetEquipBreakThroughIcon(equip.Breakthrough))
end

-- 刷新装备属性
function XUiEquipDetailChildV2P6:UpdateEquipAttr()
    local attrMap
    if self:_IsNieRMode() then
        local equipLevel = self:_GetNieRLevelAndBreak()
        attrMap = XMVCA.XEquip:GetTemplateEquipAttrMap(self.EquipId, equipLevel)
    elseif self.IsPreview then
        attrMap = XMVCA.XEquip:GetTemplateEquipAttrMap(self.EquipId)
    else
        attrMap = XMVCA.XEquip:GetEquipAttrMap(self.EquipId)
    end

    for i = 1, XEnumConst.EQUIP.MAX_ATTR_COUNT do
        local attrInfo = attrMap[i]
        local isShow = attrInfo ~= nil
        self["PanelAttr" .. i].gameObject:SetActiveEx(isShow)
        if isShow then
            self["TxtName" .. i].text = attrInfo.Name
            self["TxtAttr" .. i].text = attrInfo.Value
        end
    end
end

return XUiEquipDetailChildV2P6