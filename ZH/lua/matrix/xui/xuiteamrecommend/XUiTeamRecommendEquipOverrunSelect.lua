local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridTRWeaponOverrunSuit = require("XUi/XUiTeamRecommend/Grid/XUiGridTRWeaponOverrunSuit")
local XUiTeamRecommendEquipOverrunSelect = XLuaUiManager.Register(XLuaUi, "UiTeamRecommendEquipOverrunSelect")
local CSInstantiate = CS.UnityEngine.Object.Instantiate

function XUiTeamRecommendEquipOverrunSelect:OnAwake()
    self.GridSuitSimple.gameObject:SetActiveEx(false)
    self.PanelActive.gameObject:SetActiveEx(false)
    self.PanelNotActive.gameObject:SetActiveEx(false)
    self.ActiveGoList = {}
    self.NotActiveGoList = {}

    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnTanchuangClose, self.Close)
    self:InitDynamicTable()
end

function XUiTeamRecommendEquipOverrunSelect:OnStart(recommendCharData)
    self.RecommendCharData = recommendCharData
    self.TargetSuitId = recommendCharData.WeaponOverrunChoseSuit
    self.CurSelectSuitId = self.TargetSuitId
    local candidateEquipId = XMVCA.XTeamRecommend:GetRecommendEquipCandidate(recommendCharData.WeaponId, recommendCharData.CharacterId)
    local candidateEquip = XTool.IsNumberValid(candidateEquipId) and XMVCA.XEquip:GetEquip(candidateEquipId) or nil
    self.EquipBoundSuitId = candidateEquip and candidateEquip:GetOverrunChoseSuit() or 0
    self:Refresh()
end

function XUiTeamRecommendEquipOverrunSelect:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelSelectList.gameObject)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(XUiGridTRWeaponOverrunSuit)
end

-- 刷新推荐谐振套装列表
function XUiTeamRecommendEquipOverrunSelect:Refresh()
    self.TxtTitle.gameObject:SetActiveEx(false)
    self.TxtPreviewTitle.gameObject:SetActiveEx(true)
    self.BtnCanActive.gameObject:SetActiveEx(true)
    self.BtnCanActive:SetDisable(true)
    self.BtnChange.gameObject:SetActiveEx(false)
    self.BtnActive.gameObject:SetActiveEx(false)
    self.TxtSpend.gameObject:SetActiveEx(false)

    self.SuitDataList = self:GetSuitDataList()
    self.ImgEmpty.gameObject:SetActiveEx(XTool.IsTableEmpty(self.SuitDataList))
    if XTool.IsTableEmpty(self.SuitDataList) then
        return
    end

    local selectIndex = 1
    for index, suitData in ipairs(self.SuitDataList) do
        if suitData.Id == self.TargetSuitId then
            selectIndex = index
            break
        end
    end

    self.CurSelectSuitId = self.SuitDataList[selectIndex].Id
    self.DynamicTable:SetDataSource(self.SuitDataList)
    self.DynamicTable:ReloadDataASync(selectIndex)
    self:RefreshSuitDetail(self.SuitDataList[selectIndex])
end

-- 构造推荐角色可用的谐振套装
function XUiTeamRecommendEquipOverrunSelect:GetSuitDataList()
    local weaponId = self.RecommendCharData.WeaponId
    local characterId = self.RecommendCharData.CharacterId
    local overrunSuitCfg = XMVCA.XEquip:GetWeaponOverrunSuitCfgByTemplateId(weaponId)
    local bindType = overrunSuitCfg.ChipBindType
    if bindType == XEnumConst.EQUIP.USER_TYPE.ALL then
        bindType = XMVCA.XCharacter:GetCharacterType(characterId)
    end

    local suitCount = {}
    for _, slotData in pairs(self.RecommendCharData.AwarenessSlotList or {}) do
        suitCount[slotData.SuitId] = (suitCount[slotData.SuitId] or 0) + 1
    end

    local suitDataList = {}
    local suitIdList = XMVCA.XEquip:GetSuitIdsByCharacterType(bindType, XEnumConst.EQUIP.OVERRUN_BLIND_SUIT_MIN_QUALITY, true, true)
    for _, suitId in ipairs(suitIdList) do
        local suitData = {
            Id = suitId,
            Quality = XMVCA.XEquip:GetSuitQuality(suitId),
            CharWearCnt = suitCount[suitId] or 0,
            IsTarget = suitId == self.TargetSuitId,
            IsEquipBoundSuit = suitId == self.EquipBoundSuitId,
        }
        table.insert(suitDataList, suitData)
    end

    table.sort(suitDataList, function(a, b)
        if a.IsTarget ~= b.IsTarget then
            return a.IsTarget
        end
        if a.IsEquipBoundSuit ~= b.IsEquipBoundSuit then
            return a.IsEquipBoundSuit
        end
        return a.Id > b.Id
    end)
    return suitDataList
end

function XUiTeamRecommendEquipOverrunSelect:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local suitData = self.SuitDataList[index]
        grid:Refresh(suitData)
        grid:SetCurSelect(suitData.Id == self.CurSelectSuitId)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self.CurSelectSuitId = self.SuitDataList[index].Id
        for _, item in pairs(self.DynamicTable:GetGrids()) do
            item:SetCurSelect(false)
        end
        grid:SetCurSelect(true)
        self:RefreshSuitDetail(self.SuitDataList[index])
    end
end

-- 刷新当前谐振套装详情
function XUiTeamRecommendEquipOverrunSelect:RefreshSuitDetail(suitData)
    self:PlayAnimation("QieHuan")
    self.TxtName.text = XMVCA.XEquip:GetSuitName(suitData.Id)
    self.RImgIcon:SetRawImage(XMVCA.XEquip:GetEquipSuitIconPath(suitData.Id))

    for _, activeGo in ipairs(self.ActiveGoList) do
        activeGo.gameObject:SetActiveEx(false)
    end
    for _, notActiveGo in ipairs(self.NotActiveGoList) do
        notActiveGo.gameObject:SetActiveEx(false)
    end

    local activeIndex = 1
    local notActiveIndex = 1
    local overrunTips
    for _, info in ipairs(XMVCA.XEquip:GetSuitActiveSkillDesList(suitData.Id, suitData.CharWearCnt, true)) do
        local isActive = info.IsActive and (not info.IsActiveByOverrun or suitData.IsTarget)
        local goList = isActive and self.ActiveGoList or self.NotActiveGoList
        local goIndex = isActive and activeIndex or notActiveIndex
        local go = goList[goIndex]
        if not go then
            local template = isActive and self.PanelActive or self.PanelNotActive
            go = CSInstantiate(template, template.transform.parent)
            table.insert(goList, go)
        end

        go.gameObject:SetActiveEx(true)
        go.transform:SetAsLastSibling()
        local uiObj = go:GetComponent("UiObject")
        uiObj:GetObject("TxtTitle").text = info.PosDes
        uiObj:GetObject("TxtSkill").text = info.SkillDes
        if isActive then
            local imgState = XUiHelper.TryGetComponent(uiObj.transform, "PanelTitle/ImgState")
            imgState.gameObject:SetActiveEx(info.IsActiveByOverrun)
            if info.IsActiveByOverrun then
                local txtState = XUiHelper.TryGetComponent(uiObj.transform, "PanelTitle/ImgState/TxtState", "Text")
                txtState.gameObject:SetActiveEx(true)
                txtState.text = XUiHelper.GetText("EquipOverrunActive")
            end
            activeIndex = activeIndex + 1
        else
            uiObj:GetObject("PanelCanActive").gameObject:SetActiveEx(info.IsActiveByOverrun and suitData.IsTarget)
            notActiveIndex = notActiveIndex + 1
        end

        if info.IsActiveByOverrun then
            overrunTips = info.OverrunTips
        end
    end

    self.TxtDetail.text = suitData.IsTarget and overrunTips or XUiHelper.GetText("EquipOverrunNotActive")
end

return XUiTeamRecommendEquipOverrunSelect
