local XUiFashionLeftBottomPanel = XClass(XUiNode, "XUiFashionLeftBottomPanel")
local XUiFashionColor = require("XUi/XUiFashion/Panel/XUiFashionColor")

local BtnTabIndex = {
    Character = 1,   --成员涂装
    Weapon = 2,      --武器涂装
    HeadPortrait = 3 --头像
}

local function IsCharacterFashionUnlocked(fashionId)
    local status = XDataCenter.FashionManager.GetFashionStatus(fashionId)
    local fashionStatus = XDataCenter.FashionManager.FashionStatus
    return status == fashionStatus.UnLock or status == fashionStatus.Dressed
end

local function IsWeaponFashionUnlocked(weaponFashionId)
    return XTool.IsNumberValid(weaponFashionId)
            and XDataCenter.WeaponFashionManager.CheckHasFashion(weaponFashionId)
            and not XDataCenter.WeaponFashionManager.IsFashionTimeLimit(weaponFashionId)
end

local function IsCharacterFashionOwned(fashionId)
    return XTool.IsNumberValid(fashionId)
            and XDataCenter.FashionManager.CheckHasFashion(fashionId)
            and XDataCenter.FashionManager.IsFashionInTime(fashionId)
end

local function IsWeaponFashionOwned(weaponFashionId)
    return XTool.IsNumberValid(weaponFashionId)
            and XDataCenter.WeaponFashionManager.CheckHasFashion(weaponFashionId)
            and not XDataCenter.WeaponFashionManager.IsFashionTimeLimit(weaponFashionId)
end

local function GetUseFashionTipKey(parent, previewContext)
    if not previewContext or not parent:IsPreviewSuitActive() then
        return "UseSuccess"
    end

    local group = previewContext.Group
    local isGroupOwned = group
            and IsCharacterFashionOwned(group.FashionId)
            and IsWeaponFashionOwned(group.WeaponFashionId)
    return isGroupOwned and "ChangeGetFashionGroup" or "ChangeNoGetFashionGroup"
end

function XUiFashionLeftBottomPanel:OnStart(...)
    self.FashionColorPanel = XUiFashionColor.New(self.PanelDot, self)
    self.BtnUse:AddEventListener(handler(self, self.OnBtnUseClick))
end

function XUiFashionLeftBottomPanel:OnSelectCharacterFashion(fashionId)
    if not XTool.IsNumberValid(fashionId) then
        self.FashionColorPanel:Refresh(nil)
        return
    end

    self.FashionColorPanel:Refresh(fashionId)

end

function XUiFashionLeftBottomPanel:UpdateCharacterModel()
    -- self.BtnUsed.gameObject:SetActiveEx(not self.Parent.CurFashionId)
    -- self.BtnUse.gameObject:SetActiveEx(not self.Parent.CurFashionId)
end

function XUiFashionLeftBottomPanel:UpdateButtonState()
    if not XTool.IsNumberValid(self.Parent.CurFashionId) then
        self:UpdateButtonStateByRandom(false, false)
        return
    end

    local status = XDataCenter.FashionManager.GetFashionStatus(self.Parent.CurFashionId)
    local fashionStatus = XDataCenter.FashionManager.FashionStatus
    local BtnUse = false
    local BtnUsed = false
    local previewContext = self.Parent:IsPreviewSuitActive() and self.Parent:GetPreviewSuitContext() or nil

    if self.FashionColorPanel:IsUseNewColor() then
        BtnUse = true
    elseif status == fashionStatus.Dressed then
        -- 角色涂装已穿戴时，预览态下如果同组武器还能补穿，仍然显示 BtnUse；新染色优先级更高。
        local needWearWeapon = previewContext
                and IsWeaponFashionUnlocked(previewContext.PairId)
                and not XMVCA.XFashionSuit:IsWeaponFashionDressed(previewContext.PairId, previewContext.CharacterId)
        BtnUse = needWearWeapon
        BtnUsed = not needWearWeapon
    elseif status == fashionStatus.UnLock then
        BtnUse = true
    end
    self:UpdateButtonStateByRandom(BtnUse, BtnUsed)
end

function XUiFashionLeftBottomPanel:UpdateButtonStateByRandom(BtnUse, BtnUsed)
    local char = XMVCA.XCharacter:GetCharacter(self.Parent.CharacterId)
    local isRandom = char and char.RandomFashion
    self.BtnUse.gameObject:SetActiveEx(BtnUse and not isRandom)
    self.BtnUsed.gameObject:SetActiveEx(BtnUsed and not isRandom)
end

function XUiFashionLeftBottomPanel:UpdateWeaponButtonState()
    local characterId = self.Parent.CharacterId
    local status = XDataCenter.WeaponFashionManager.GetFashionStatus(self.Parent.CurWeaponFashionId, characterId)
    local fashionStatus = XDataCenter.WeaponFashionManager.FashionStatus
    local BtnUse = false
    local BtnUsed = false
    local previewContext = self.Parent:IsPreviewSuitActive() and self.Parent:GetPreviewSuitContext() or nil

    if status == fashionStatus.Dressed then
        -- 武器页走对称逻辑，并且武器穿戴判断必须带 characterId 才能拿到当前角色的真实状态。
        local needWearFashion = previewContext
                and IsCharacterFashionUnlocked(previewContext.PairId)
                and not XMVCA.XFashionSuit:IsFashionDressed(previewContext.PairId)
        BtnUse = needWearFashion
        BtnUsed = not needWearFashion
    elseif status == fashionStatus.UnLock then
        BtnUse = true
    end
    self:UpdateButtonStateByRandom(BtnUse, BtnUsed)
end

function XUiFashionLeftBottomPanel:UpdateHeadPortraitButtonState()
    local characterId = self.Parent.CharacterId
    local headInfo = self.Parent.HeadInfo
    local isUnLock = XDataCenter.FashionManager.IsFashionHeadUnLock(headInfo.HeadFashionId, headInfo.HeadFashionType,
        characterId)
    local isUsing = XDataCenter.FashionManager.IsFashionHeadUsing(headInfo.HeadFashionId, headInfo.HeadFashionType,
        characterId)

    local BtnUse = false
    local BtnUsed = false

    if isUsing then      --已穿戴
        BtnUsed = true
    elseif isUnLock then --已解锁
        BtnUse = true
    end
    self.BtnUse.gameObject:SetActiveEx(BtnUse)
    self.BtnUsed.gameObject:SetActiveEx(BtnUsed)
end

function XUiFashionLeftBottomPanel:OnBtnUseClick()
    if self.Parent:GetLastSelectedTabIndex() == BtnTabIndex.Character then
        self:OnBtnUseCharacterFashionClick()
    elseif self.Parent:GetLastSelectedTabIndex() == BtnTabIndex.Weapon then
        self:OnBtnUseWeaponFashionClick()
    elseif self.Parent:GetLastSelectedTabIndex() == BtnTabIndex.HeadPortrait then
        if not XMVCA.XCharacter:IsOwnCharacter(self.Parent.CharacterId) then
            XUiManager.TipText("CharacterLock")
            return
        end

        local headInfo = self.Parent.HeadInfo
        XMVCA.XCharacter:CharacterSetHeadInfoRequest(
            self.Parent.CharacterId,
            headInfo.HeadFashionId,
            headInfo.HeadFashionType,
            function()
                XUiManager.TipText("UseSuccess")
                self.Parent:UpdateHeadPortraitList(true)
            end
        )
    end
end

function XUiFashionLeftBottomPanel:OnBtnUseCharacterFashionClick()
    local fashionId = self.Parent.CurFashionId
    if not XTool.IsNumberValid(fashionId) then
        return
    end

    local colorId = self.FashionColorPanel:GetColorId()
    local status = XDataCenter.FashionManager.GetFashionStatus(fashionId)
    local fashionStatus = XDataCenter.FashionManager.FashionStatus
    local previewContext = self.Parent:IsPreviewSuitActive() and self.Parent:GetPreviewSuitContext() or nil
    local needUseFashion = self.FashionColorPanel:IsUseNewColor() or status == fashionStatus.UnLock
    local needUseWeapon = previewContext
            and IsWeaponFashionUnlocked(previewContext.PairId)
            and not XMVCA.XFashionSuit:IsWeaponFashionDressed(previewContext.PairId, previewContext.CharacterId)

    local function onUseFinished()
        local tipKey = GetUseFashionTipKey(self.Parent, previewContext)
        XUiManager.TipText(tipKey)
        self.Parent:UpdateFashionList(true)
    end

    -- 角色页先完成当前涂装/颜色，再按解锁情况补穿同组武器，整条链路只收一次提示和刷新。
    local function useWeaponFashion()
        if not needUseWeapon then
            onUseFinished()
            return
        end

        XDataCenter.WeaponFashionManager.UseFashion(previewContext.PairId, previewContext.CharacterId, onUseFinished)
    end

    if needUseFashion then
        self._Control:UseFashion(fashionId, colorId, useWeaponFashion)
    elseif needUseWeapon then
        useWeaponFashion()
    else
        return
    end
end

function XUiFashionLeftBottomPanel:OnBtnUseWeaponFashionClick()
    local characterId = self.Parent.CharacterId
    local weaponFashionId = self.Parent.CurWeaponFashionId
    local status = XDataCenter.WeaponFashionManager.GetFashionStatus(weaponFashionId, characterId)
    local fashionStatus = XDataCenter.WeaponFashionManager.FashionStatus
    local previewContext = self.Parent:IsPreviewSuitActive() and self.Parent:GetPreviewSuitContext() or nil
    local needUseWeapon = status == fashionStatus.UnLock
    local needUseFashion = previewContext
            and IsCharacterFashionUnlocked(previewContext.PairId)
            and not XMVCA.XFashionSuit:IsFashionDressed(previewContext.PairId)

    local function onUseFinished()
        local tipKey = GetUseFashionTipKey(self.Parent, previewContext)
        XUiManager.TipText(tipKey)
        self.Parent:UpdateWeaponFashionList(true)
    end

    -- 武器页先处理当前武器，再按解锁情况补穿同组角色涂装；未解锁时直接跳过替换。
    local function useCharacterFashion()
        if not needUseFashion then
            onUseFinished()
            return
        end

        XDataCenter.FashionManager.UseFashion(previewContext.PairId, onUseFinished)
    end

    if needUseWeapon then
        XDataCenter.WeaponFashionManager.UseFashion(weaponFashionId, characterId, useCharacterFashion)
    elseif needUseFashion then
        useCharacterFashion()
    else
        return
    end
end

function XUiFashionLeftBottomPanel:OnColorDotClick(colorId)

    self:UpdateButtonState()
    --刷新角色模型会把颜色id清空，注意流程调用顺序
    self.Parent:UpdateCharacterResModel(self.Parent.CharacterId, self.Parent.CurFashionId)
end


return XUiFashionLeftBottomPanel
