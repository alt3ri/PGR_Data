local XUiGridDlcRelinkEquipment = require("XUi/XUiDlcRelink/Equip/Grid/XUiGridDlcRelinkEquipment")
local XUiGridDlcRelinkEquipAttribute = require("XUi/XUiDlcRelink/Equip/Grid/XUiGridDlcRelinkEquipAttribute")
---@class XUiPanelDlcRelinkEquipDetail : XUiNode
---@field private _Control XDlcRelinkControl
---@field Parent XUiDlcRelinkEquipBag | XUiDlcRelinkEquipReform | XUiDlcRelinkBubbleEquipDetail
---@field PanelTips UiObject
local XUiPanelDlcRelinkEquipDetail = XClass(XUiNode, "XUiPanelDlcRelinkEquipDetail")

function XUiPanelDlcRelinkEquipDetail:OnStart(isNotSelf)
    self.GridAttribute.gameObject:SetActiveEx(false)
    self.PanelTips.gameObject:SetActiveEx(false)
    self.StoryLine.gameObject:SetActiveEx(false)
    self.GridAttributeGroup.gameObject:SetActiveEx(false)
    self.GridNone.gameObject:SetActiveEx(false)
    self.BtnLock:AddEventListener(handler(self, self.OnBtnLockClick))

    if self.BtnDescFold then
        self.BtnDescFold:AddEventListener(handler(self, self.OnBtnDescFold))
    end

    if self.PanelDetail then
        self.PanelDetail.gameObject:SetActiveEx(false)
    end

    self.IsNotSelf = isNotSelf or false

    ---@type XUiGridDlcRelinkEquipAttribute
    self.MainSkillAttribute = nil
    ---@type XUiGridDlcRelinkEquipAttribute
    self.MainAttribute = nil
    self.Lines = {}
    ---@type table<number, UiObject>
    self.DeputyAttributeGroup = {}
    ---@type table<number, table<number, XUiGridDlcRelinkEquipAttribute>>
    self.DeputyAttributeNodes = {}
    self.GridNones = {}

    self.DefaultLayer = 0
    local canvas = self.GridAttributeGroup:GetObject("Canvas", false)
    if canvas then
        self.DefaultLayer = canvas.sortingOrder
    end

    self._IsShowDetail = self._Control:GetEquipAttrDescIsDetail()

    self:RefreshFoldIcon()
end

function XUiPanelDlcRelinkEquipDetail:Refresh(equipUid)
    self.EquipUid = equipUid
    self:RefreshEquipInfo()
    self:RefreshIsLocked()
    self:RefreshEquipAttributes()
end

function XUiPanelDlcRelinkEquipDetail:RefreshEquipInfo()
    -- 装备格子
    if not self.EquipNode then
        ---@type XUiGridDlcRelinkEquipment
        self.EquipNode = XUiGridDlcRelinkEquipment.New(self.GridEquipment, self)
        self.EquipNode:Open()
    end
    self.EquipNode:Refresh(self.EquipUid, nil, self.IsNotSelf)
    local templateId = self._Control:GetEquipTemplateIdByEquipUid(self.EquipUid, self.IsNotSelf)
    self._OccupationType = self._Control:GetEquipOccupationType(templateId)
    -- 装备名称
    self.TxtName.text = self._Control:GetEquipName(templateId)
    -- 装备职业图标
    local occupationIcon = self._Control:GetEquipOccupationIcon(templateId)
    if not string.IsNilOrEmpty(occupationIcon) then
        self.ImgOccupation:SetSprite(occupationIcon)
    end
    -- 装备职业名称
    self.TxtOccupation.text = self._Control:GetEquipOccupationName(templateId)
    -- 装备类型
    local equipType = self._Control:GetEquipType(templateId)
    self.LabelMain.gameObject:SetActiveEx(equipType == XEnumConst.DlcRelink.EquipType.Main)
    self.LabelNormal.gameObject:SetActiveEx(equipType == XEnumConst.DlcRelink.EquipType.Normal)
    -- 装备战力
    self.TxtLv.text = self._Control:GetEquipAbilityByUid(self.EquipUid, self.IsNotSelf)
    self.TxtMax.gameObject:SetActiveEx(self._Control:CheckEquipIsMaxAbility(self.EquipUid, self.IsNotSelf))
    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.TxtMax.transform.parent)
    -- 顶部槽位扩展提示
    self.PanelTopTips.gameObject:SetActiveEx(equipType == XEnumConst.DlcRelink.EquipType.Main)
    self.TxtTip.text = self._Control:GetClientConfig("EquipSlotExpandTip")
end

function XUiPanelDlcRelinkEquipDetail:RefreshIsLocked()
    if self.IsNotSelf or not XTool.IsNumberValid(self.EquipUid) then
        self.BtnLock.gameObject:SetActiveEx(false)
        return
    end
    self.BtnLock.gameObject:SetActiveEx(true)
    local isLocked = self._Control:GetEquipIsLockedByEquipUid(self.EquipUid, self.IsNotSelf)
    self.BtnLock:SetButtonState(isLocked and CS.UiButtonState.Select or CS.UiButtonState.Normal)
end

function XUiPanelDlcRelinkEquipDetail:RefreshEquipAttributes()
    self:HideEquipAttributes()

    local lineCount = 1
    -- 主技能属性
    local mainSkillAttr = self._Control:GetEquipMainFactorByUid(self.EquipUid, true, self.IsNotSelf)
    if mainSkillAttr then
        local node = self:EnsureMainAttrNode(true)
        node:Refresh(mainSkillAttr)
        node:RefreshDetailShow(self._IsShowDetail, mainSkillAttr)
        node:MoveToParentLatest()
        node:ShowBg1()
    end

    -- 主属性
    local mainAttr = self._Control:GetEquipMainFactorByUid(self.EquipUid, false, self.IsNotSelf)
    if mainAttr then
        local node = self:EnsureMainAttrNode(false)
        node:Refresh(mainAttr)
        node:RefreshDetailShow(self._IsShowDetail, mainAttr)
        node:MoveToParentLatest()
        --背景图交错开
        if mainSkillAttr then
            node:ShowBg2()
        else
            node:ShowBg1()
        end
    end

    -- 加持描述
    self:RefreshBlessingTips()

    -- 副属性
    local templateId = self._Control:GetEquipTemplateIdByEquipUid(self.EquipUid, self.IsNotSelf)
    local quality = self._Control:GetEquipQuality(templateId)
    local deputyNum = self._Control:GetEquipQualityDeputyFactorNum(quality)

    --主副属性分割线
    if (mainSkillAttr or mainAttr) and deputyNum > 0 then
        self:EnsureLineActive(lineCount)
        lineCount = lineCount + 1
    end

    local count = 1
    local attrs = {}
    local ShowNoneCount = 0
    for index = 1, deputyNum do
        local slot = self._Control:GetEquipDeputyFactorByUid(self.EquipUid, index, self.IsNotSelf)
        if not slot or not slot.Attributes or #slot.Attributes == 0 then
            ShowNoneCount = ShowNoneCount + 1
        else
            for _, v in ipairs(slot.Attributes) do
                local idx = math.ceil(count / 2)
                if attrs[idx] then
                    table.insert(attrs[idx], v)
                else
                    attrs[idx] = { v }
                end
                count = count + 1
            end
        end
    end

    for k, v in ipairs(attrs) do
        self:RefreshDeputyAttributes(k, v)
    end

    for index = 1, ShowNoneCount do
        self:EnsureNone(index)
    end
end

function XUiPanelDlcRelinkEquipDetail:RefreshFoldIcon()
    if self.IconSimpleState then
        self.IconSimpleState.gameObject:SetActiveEx(not self._IsShowDetail)
    end

    if self.IconDetailState then
        self.IconDetailState.gameObject:SetActiveEx(self._IsShowDetail)
    end
end

function XUiPanelDlcRelinkEquipDetail:HideEquipAttributes()
    if self.MainSkillAttribute then
        self.MainSkillAttribute:Close()
    end
    if self.MainAttribute then
        self.MainAttribute:Close()
    end
    self.PanelTips.gameObject:SetActiveEx(false)
    for _, line in pairs(self.Lines) do
        line.gameObject:SetActiveEx(false)
    end
    for _, nodes in pairs(self.DeputyAttributeNodes) do
        for _, node in pairs(nodes or {}) do
            node:Close()
        end
    end
    for _, group in pairs(self.DeputyAttributeGroup) do
        group.gameObject:SetActiveEx(false)
    end
    for _, none in pairs(self.GridNones) do
        none.gameObject:SetActiveEx(false)
    end
end

function XUiPanelDlcRelinkEquipDetail:EnsureLineActive(index)
    local line = self.Lines[index]
    if not line then
        line = XUiHelper.Instantiate(self.StoryLine, self.PanelGroup)
        self.Lines[index] = line
    end
    line.gameObject:SetActiveEx(true)
    line.transform:SetAsLastSibling()
end

---@return XUiGridDlcRelinkEquipAttribute
function XUiPanelDlcRelinkEquipDetail:EnsureMainAttrNode(isSkill)
    local field = isSkill and "MainSkillAttribute" or "MainAttribute"
    if not self[field] then
        local go = XUiHelper.Instantiate(self.GridAttribute, self.PanelGroup)
        
        local detailGo = self.PanelDetail and XUiHelper.Instantiate(self.PanelDetail, self.PanelGroup) or nil
        self[field] = XUiGridDlcRelinkEquipAttribute.New(go, self, detailGo)
    end
    local node = self[field]
    node:Open()
    return node
end

function XUiPanelDlcRelinkEquipDetail:EnsureNone(index)
    local none = self.GridNones[index]
    if not none then
        none = XUiHelper.Instantiate(self.GridNone, self.PanelGroup)
        self.GridNones[index] = none
    end
    none.gameObject:SetActiveEx(true)
    none.transform:SetAsLastSibling()
end

function XUiPanelDlcRelinkEquipDetail:EnsureDeputyGroup(index)
    local grid = self.DeputyAttributeGroup[index]
    if not grid then
        grid = XUiHelper.Instantiate(self.GridAttributeGroup, self.PanelGroup)
        self.DeputyAttributeGroup[index] = grid
    end
    grid.gameObject:SetActiveEx(true)
    grid.transform:SetAsLastSibling()
    return grid
end

-- 刷新副属性条目（目前支持最多2条）
function XUiPanelDlcRelinkEquipDetail:RefreshDeputyAttributes(index, attributes)
    local grid = self:EnsureDeputyGroup(index)
    local attrCount = #attributes

    grid:GetObject("GridAttribute1").gameObject:SetActiveEx(attrCount >= 1)
    local panelDetail1 = grid:GetObject("PanelDetail1", false)

    if panelDetail1 then
        panelDetail1.gameObject:SetActiveEx(attrCount >= 1)
    end

    local hasSecond = attrCount >= 2
    grid:GetObject("Line").gameObject:SetActiveEx(hasSecond)
    grid:GetObject("GridAttribute2").gameObject:SetActiveEx(hasSecond)

    local panelDetail2 = grid:GetObject("PanelDetail2", false)

    if panelDetail2 then
        panelDetail2.gameObject:SetActiveEx(hasSecond)
    end

    self.DeputyAttributeNodes[index] = self.DeputyAttributeNodes[index] or {}
    for i = 1, math.min(attrCount, 2) do
        if not self.DeputyAttributeNodes[index][i] then
            self.DeputyAttributeNodes[index][i] = XUiGridDlcRelinkEquipAttribute.New(grid:GetObject("GridAttribute" .. i), self, grid:GetObject("PanelDetail" .. i, false))
        end
        local node = self.DeputyAttributeNodes[index][i]
        node:Open()
        node:Refresh(attributes[i])
        node:RefreshDetailShow(self._IsShowDetail, attributes[i], true)
        if i & 1 == 1 then
            node:ShowBg1()
        else
            node:ShowBg2()
        end
    end
end

function XUiPanelDlcRelinkEquipDetail:RefreshBlessingTips()
    if self.Parent.CheckExtendSlotAndMainSlotWearEquip then
        local isShowTip = self.Parent:CheckExtendSlotAndMainSlotWearEquip()
        self.PanelTips.gameObject:SetActiveEx(isShowTip)
        if isShowTip then
            local isOccupationTypeSame = false
            local mainEquipUid
            if self.IsNotSelf then
                mainEquipUid = self._Control.OtherMemberControl:GetEquipWearEquipUidBySlot(XEnumConst.DlcRelink.EquipSlotIndex.MainSlot)
            else
                mainEquipUid = self._Control:GetEquipUidByCharacterId(self.Parent.CharacterId, XEnumConst.DlcRelink.EquipSlotIndex.MainSlot)
            end
            if XTool.IsNumberValid(mainEquipUid) then
                local equipId = self._Control:GetEquipTemplateIdByEquipUid(mainEquipUid, self.IsNotSelf)
                local mainOccupationType = self._Control:GetEquipOccupationType(equipId)
                isOccupationTypeSame = self._OccupationType == mainOccupationType
            end
            if not self._PanelTipObj then
                self._PanelTipObj = {}
                XUiHelper.InitUiClass(self._PanelTipObj, self.PanelTips)
                self._PanelTipObj.TxtTipsNotEffective.text = self._Control:GetClientConfig("TipsNotEffective")
                self._PanelTipObj.TxtTipsInBlessing.text = self._Control:GetClientConfig("TipsInBlessing")
            end
            self._PanelTipObj.TipsNotEffective.gameObject:SetActiveEx(not isOccupationTypeSame)
            self._PanelTipObj.TipsInBlessing.gameObject:SetActiveEx(isOccupationTypeSame)
            self.PanelTips.transform:SetAsLastSibling()
        end
    end
end

-- 锁定/解锁装备
function XUiPanelDlcRelinkEquipDetail:OnBtnLockClick()
    if self.IsNotSelf then
        return
    end
    if not XTool.IsNumberValid(self.EquipUid) then
        return
    end

    local isLocked = self._Control:GetEquipIsLockedByEquipUid(self.EquipUid)
    local callback = function()
        self:RefreshIsLocked()
    end

    if isLocked then
        self._Control:RequestUnlockEquip(self.EquipUid, callback)
    else
        self._Control:RequestLockEquip(self.EquipUid, callback)
    end
end

function XUiPanelDlcRelinkEquipDetail:OpenDeleteFactorPanel(orderInLayer, callback)
    if XTool.IsTableEmpty(self.DeputyAttributeGroup) then
        return
    end

    if self.IsDeletePanelOpen then
        -- 仅更新层级
        for _, group in ipairs(self.DeputyAttributeGroup) do
            local canvas = group:GetObject("Canvas")
            if canvas and orderInLayer and canvas.sortingOrder ~= orderInLayer then
                canvas.sortingOrder = orderInLayer
            end
        end
        return
    end
    self.IsDeletePanelOpen = true
    self.DeleteFactorCallback = callback

    for index, group in ipairs(self.DeputyAttributeGroup) do
        local canvas = group:GetObject("Canvas")
        if canvas and orderInLayer then
            canvas.sortingOrder = orderInLayer
        end
        local btnDelete = group:GetObject("BtnDelete")
        if btnDelete then
            btnDelete.gameObject:SetActiveEx(true)
            btnDelete.CallBack = function()
                self:OnBtnDeleteClick(index)
            end
        end
    end
end

function XUiPanelDlcRelinkEquipDetail:OnBtnDeleteClick(index)
    if not XTool.IsNumberValid(index) then
        return
    end

    local remainFactorRemoveNum = self.Parent:GetRemainFactorRemoveNum()
    if remainFactorRemoveNum <= 0 then
        self._Control:OpenCommonTipText("EquipReformDeleteNoTimesTips")
        return
    end

    local slot = self._Control:GetEquipDeputyFactorByUid(self.EquipUid, index)
    if not slot or not slot.Attributes or #slot.Attributes == 0 then
        return
    end

    local needConfirm = false
    for _, attr in pairs(slot.Attributes) do
        if self._Control:CheckEquipAttributeIsMaxLevel(attr) then
            needConfirm = true
            break
        end
    end

    if needConfirm then
        local title = self._Control:GetClientConfig("TipTitle")
        local data = self._Control:GetClientConfig("EquipReformDeleteConfirmTipContent")
        local content = data[1] or ""
        local extraData = { ConfirmText = data[2] or "", CancelText = data[3] or "", TipsKey = "EquipReformDeleteConfirm", }
        self._Control:OpenCommonTipDialog(title, content, nil, function()
            self:OnDeleteFactorConfirm(index)
        end, extraData)
        return
    end

    self:OnDeleteFactorConfirm(index)
end

function XUiPanelDlcRelinkEquipDetail:OnDeleteFactorConfirm(index)
    if not self._Control:AbleSyncDataToMatchServer() then
        return
    end
    self._Control:RequestEquipRemoveFactor(self.EquipUid, index, function()
        if self.DeleteFactorCallback then
            self.DeleteFactorCallback()
        end
        -- 成功提示
        self._Control:OpenCommonLeftTipDialog(self._Control:GetClientConfig("EquipReformDeleteSuccessTips"))
    end)
end

function XUiPanelDlcRelinkEquipDetail:CloseDeleteFactorPanel()
    if XTool.IsTableEmpty(self.DeputyAttributeGroup) then
        return
    end
    self.IsDeletePanelOpen = nil
    self.DeleteFactorCallback = nil

    for _, group in ipairs(self.DeputyAttributeGroup) do
        local canvas = group:GetObject("Canvas")
        if canvas and canvas.sortingOrder ~= self.DefaultLayer then
            canvas.sortingOrder = self.DefaultLayer
        end
        ---@type XUiComponent.XUiButton
        local btnDelete = group:GetObject("BtnDelete")
        if btnDelete then
            btnDelete.gameObject:SetActiveEx(false)
            btnDelete.CallBack = nil
        end
    end
end

--- 装备详情
function XUiPanelDlcRelinkEquipDetail:OnBtnDescFold()
    self._IsShowDetail = not self._IsShowDetail

    -- 刷新词条详情显示情况
    self:RefreshEquipAttributes()
    self:RefreshFoldIcon()
    
    self._Control:SetEquipAttrDescIsDetail(self._IsShowDetail)
end


return XUiPanelDlcRelinkEquipDetail
