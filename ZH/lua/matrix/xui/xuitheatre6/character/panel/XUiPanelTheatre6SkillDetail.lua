---@class XUiPanelTheatre6SkillDetail : XUiNode
---@field _Control XTheatre6Control
---@field TxtName UnityEngine.UI.Text
---@field GridStar UnityEngine.RectTransform
---@field ImgQuality UnityEngine.UI.Image
---@field TxtSp UnityEngine.UI.Text
---@field ImgIconSp UnityEngine.UI.Image
---@field TxtType UnityEngine.UI.Text
---@field TxtDesc XUiComponent.XUiRichTextCustomRender
---@field TxtSc UnityEngine.UI.Text
---@field GridTag UiObject
---@field BtnFreeze XUiComponent.XUiButton
---@field BtnBuy XUiComponent.XUiButton
---@field BtnSell XUiComponent.XUiButton
---@field BtnDiscard XUiComponent.XUiButton
---@field BtnRemove XUiComponent.XUiButton
---@field BtnEquip XUiComponent.XUiButton
---@field BtnClose XUiComponent.XUiButton
local XUiPanelTheatre6SkillDetail = XLuaUiManager.Register(XUiNode, "XUiPanelTheatre6SkillDetail")

local SkillTypeBgConfigName = {
    [XEnumConst.Theatre6.SlotType.Special] = "SkillType4Bg",
    [XEnumConst.Theatre6.SlotType.Insert] = "SkillType2a3Bg",
    [XEnumConst.Theatre6.SlotType.Active] = "SkillType1Bg",
}
function XUiPanelTheatre6SkillDetail:OnStart()
    self.IsGetSkill = false
    self.IsUsing = false
    self.IsLock = false
    self.IsSell = false

    self._EquipSlotType = nil
    self._EquipPos = nil
    self._IsSlotFull = false
    self:InitComponents()
end

function XUiPanelTheatre6SkillDetail:OnGetLuaEvents()
    return {
        XEventId.EVENT_THEATRE6_GOLD_CHANGE
    }
end

function XUiPanelTheatre6SkillDetail:OnNotify(evt, ...)
    if evt == XEventId.EVENT_THEATRE6_GOLD_CHANGE and not self._ReadOnly then
        self:RefreshBuyBtnStatus()
    end
end

function XUiPanelTheatre6SkillDetail:InitComponents()
    self.BtnEquip:AddEventListener(handler(self, self.OnBtnEquipClick))
    self.BtnRemove:AddEventListener(handler(self, self.OnBtnRemoveClick))
    self.GridTag.gameObject:SetActiveEx(false)
    self.TxtDesc.requestImage = XMVCA.XTheatre6.RichTextImageCallBack

    self.BtnFreeze:AddEventListener(handler(self, self.OnBtnFreezeClick))
    self.BtnSell:AddEventListener(handler(self, self.OnBtnSellClick))
    self.BtnBuy:AddEventListener(handler(self, self.OnBtnBuyClick))
    self.BtnSell:SetSprite(self._Control:GetCoinIcon())
    self.BtnBuy:SetSprite(self._Control:GetCoinIcon())
    -- 首次 Refresh 前先隐藏,避免按钮闪现(后续由 RefreshBtnStatus 控制)
    self.BtnFreeze.gameObject:SetActiveEx(false)
    self.BtnSell.gameObject:SetActiveEx(false)
    self.BtnBuy.gameObject:SetActiveEx(false)
    self.BtnRemove.gameObject:SetActiveEx(false)
    self.BtnEquip.gameObject:SetActiveEx(false)

    if self.GridTagSc then
        self.GridTagSc:AddEventListener(handler(self, self.OnBtnGridTagClick))
    end

    if self.BtnDescList then
        self.BtnDescList:AddEventListener(handler(self, self.OnBtnGridTagClick))
    end
end

function XUiPanelTheatre6SkillDetail:Refresh(skillId, params)
    local readOnly = true
    if params then
        readOnly = params.ReadOnly ~= nil and params.ReadOnly or false
        self.IsBaseSkill = params.IsBaseSkill ~= nil and params.IsBaseSkill or false
        self.IsLock = params.IsLock or false
        self.IsSell = params.IsSell or false
        self.IsInShop = params.IsInShop or false
        self.Pos = params.Pos or 0
        self.SlotType = params.SlotType or 0
        self.IsGetSkill = not self.IsInShop and XTool.IsNumberValid(self.SlotType)
        self.IsUsing = self.IsGetSkill and self.SlotType ~= XEnumConst.Theatre6.SlotType.Bag
    end
    self._SkillId = skillId
    local skillConfig = self._Control:GetSkillCfgById(self._SkillId)
    self.TxtName.text = skillConfig.Name                                                  --名称
    self.TxtSp.text = skillConfig.CostTL                                                  --SP消耗
    self.ImgIconSp:SetSprite(self._Control:GetClientConfigValue("IconSp"))                --SP图标
    self.TxtType.text = self._Control:GetClientConfigValue("SkillType", skillConfig.Type) --技能类型
    self.TxtDesc.text = self._Control:GetSkillDesc(self._SkillId, false)
    if self.UiRImgIcon then
        self.UiRImgIcon:SetRawImage(skillConfig.Icon) --技能图标
    end

    self.BtnSell:SetNameByGroup(0, skillConfig.SellPrice)
    if self.IsLock then
        self.BtnFreeze:SetButtonState(CS.UiButtonState.Normal)
        self.BtnFreeze:SetNameByGroup(0, XUiHelper.GetText("Theatre6UnLock"))
    else
        self.BtnFreeze:SetButtonState(CS.UiButtonState.Select)

        self.BtnFreeze:SetNameByGroup(0, XUiHelper.GetText("Theatre6Lock"))
    end

    local spriteName = ""
    self.SlotTypes = self._Control:GetSkillInstallSlots(skillId)
    if self.SlotTypes then
        local slotType = self.SlotTypes[1] --默认第一个槽位
        if slotType then
            spriteName = self._Control:GetClientConfigValue(SkillTypeBgConfigName[slotType], skillConfig.Quality)
        end
    else
        spriteName = self._Control:GetQualityIcon(skillConfig.Quality)
    end
    if self.ImgQuality.SetSprite then
        self.ImgQuality:SetSprite(spriteName)
    else
        self.ImgQuality:SetRawImage(spriteName)
    end

    self.GridTagSc:SetNameByGroup(0, XUiHelper.GetText("Theatre6OverClockEfficiency"))
    self.GridTagSc:SetNameByGroup(1, string.format("%s%%", math.floor(skillConfig.CSMag / 100)))

    self:UpdateStarGrid(skillConfig.Level) --星级
    self:UpdateSkillBuildTagsGrid(skillConfig.BuildTags, skillConfig.KeyWordIds)
    local effectiveReadOnly = readOnly or self.IsBaseSkill or self._Control:IsCurModeSettle()
    self._ReadOnly = effectiveReadOnly
    self:RefreshBtnStatus(effectiveReadOnly)
    if not effectiveReadOnly then
        self:RefreshBuyBtnStatus()
    end
end

function XUiPanelTheatre6SkillDetail:RefreshBuyBtnStatus()
    local skillConfig = self._Control:GetSkillCfgById(self._SkillId)
    local coinEnough = self._Control:IsCoinEnough(skillConfig.BuyPrice)
    local showPrice = tostring(skillConfig.BuyPrice)
    if not coinEnough then
        showPrice = string.format("<color=%s>%s</color>", self._Control:GetClientConfigValue("NotEnough"),
            skillConfig.BuyPrice)
    end
    self.BtnBuy:SetNameByGroup(0, showPrice) --价格
    self.BtnBuy:SetDisable(not coinEnough)
    self.BtnRemove:SetDisable(self._Control:IsSkillBagFull())

end

function XUiPanelTheatre6SkillDetail:RefreshBtnStatus(readOnly)
    if self.PanelBtn then
        self.PanelBtn.gameObject:SetActiveEx(not readOnly)
    end
    if not readOnly then
        self.BtnFreeze.gameObject:SetActiveEx(not self.IsGetSkill)
        self.BtnBuy.gameObject:SetActiveEx(not self.IsGetSkill)

        self.BtnSell.gameObject:SetActiveEx(self.IsGetSkill)
        self.BtnDiscard.gameObject:SetActiveEx(false)
        local showEquip = self.IsGetSkill and not self.IsUsing
        self.BtnEquip.gameObject:SetActiveEx(showEquip)
        if showEquip then

            
            local installSlots = self._Control:GetSkillInstallSlots(self._SkillId)
            local canEquip = false
            for _, slot in pairs(installSlots) do
                local exchange, changepos = self._Control:CheckSkillCanEquipSkill(self._SkillId, slot)
                if exchange then
                    canEquip = true
                    self._EquipSlotType = slot
                    self._EquipPos = changepos
                    break
                end
            end

            if not canEquip then
                for _, slot in pairs(installSlots) do
                    local positions = self._Control:GetEmptySlotPositions(slot)
                    if positions and #positions > 0 then
                    canEquip = true
                    self._EquipSlotType = slot
                    self._EquipPos = positions[1]
                    end
                end
            end
            self._IsSlotFull = not canEquip
            self.BtnEquip:SetDisable(self._IsSlotFull)
        end
        self.BtnRemove.gameObject:SetActiveEx(self.IsGetSkill and self.IsUsing)
    end
end

function XUiPanelTheatre6SkillDetail:UpdateStarGrid(startCount)
    XUiHelper.RefreshCustomizedList(self.GridStar.transform.parent, self.GridStar, startCount, function(index, grid)

    end)
end

function XUiPanelTheatre6SkillDetail:OnBtnGridTagClick()
    if XLuaUiManager.IsUiShow("UiTheatre6BubbleTagDetail") then
        XLuaUiManager.Close("UiTheatre6BubbleTagDetail")
        return
    end
    local skillConfig = self._Control:GetSkillCfgById(self._SkillId)
    self._Control:OpenTagTip(skillConfig.BuildTags, self.Parent.PanelBubble, skillConfig.KeyWordIds)
end

function XUiPanelTheatre6SkillDetail:UpdateSkillBuildTagsGrid(buildTags, keyWordIds)
    local buildTagCfgs = self._Control:GetShowBuildTagWithSort(buildTags)
    XUiHelper.RefreshCustomizedList(self.GridTag.transform.parent, self.GridTag, #buildTags, function(index, grid)
        local ui = {}
    XTool.InitUiObjectByUi(ui, grid)
        ui.BtnGrid:AddEventListener(function()
            if XLuaUiManager.IsUiShow("UiTheatre6BubbleTagDetail") then
                XLuaUiManager.Close("UiTheatre6BubbleTagDetail")
                return
            end
            self._Control:OpenTagTip(buildTags, self.Parent.PanelBubble, keyWordIds)
        end)
        ui.GameObject:SetActiveEx(true)
        ui.ImgIcon:SetSprite(buildTagCfgs[index].Icon)
        ui.TxtName.text = buildTagCfgs[index].Name
    end)
end

function XUiPanelTheatre6SkillDetail:OnBtnEquipClick()
    if self._IsSlotFull then
        XUiManager.TipText("Theatre6SkillSlotFull")
        return
    end

    self._Control:SkillMoveOrSwapRequest(self._SkillId, self._EquipSlotType, self._EquipPos, function()
        self:CloseUi()
    end)
end

function XUiPanelTheatre6SkillDetail:OnBtnRemoveClick()
    if self._Control:IsSkillBagFull() then
        XUiManager.TipText("Theatre6SkillBagFull")
        return
    end
    local dstPositions = self._Control:GetEmptySlotPositions(XEnumConst.Theatre6.SlotType.Bag)
    local dstPosition = dstPositions[1] or 1
    self._Control:SkillMoveOrSwapRequest(self._SkillId, XEnumConst.Theatre6.SlotType.Bag, dstPosition, function()
        self:CloseUi()
    end)
end

function XUiPanelTheatre6SkillDetail:OnBtnFreezeClick()
    self._Control:ShopGoodLockRequest(self.Pos, self.IsLock, function(lockStatus)
        self:CloseUi()
    end)
end

function XUiPanelTheatre6SkillDetail:OnBtnSellClick()
    self._Control:SellSkillGood(self._SkillId, function()
        self:CloseUi()
    end)
end

function XUiPanelTheatre6SkillDetail:OnBtnBuyClick()
    self._Control:BuySkillGood(self._SkillId, self.Pos, function()
        self:CloseUi()
    end)
end

function XUiPanelTheatre6SkillDetail:CloseUi()
    if self.Parent then
        self.Parent:Close()
    end
    self:Close()
end

return XUiPanelTheatre6SkillDetail
