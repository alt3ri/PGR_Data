--[[--
-- XUiEquipPartnerOneKeyCultureSelectCell.lua
-- 辅助机一键养成 - 升星材料辅助机选择格子
--]]

---@class XUiEquipPartnerOneKeyCultureSelectCell : XUiNode
---@field _Control XPartnerControl
---@field Parent XUiEquipPartnerOneKeyCultureSelectClipPopup
---@field RImgHeadIcon UnityEngine.UI.RawImage
---@field RImgQuality UnityEngine.UI.RawImage
---@field TxtLevel UnityEngine.UI.Text
---@field ImgBreak UnityEngine.UI.Image
---@field Txtname UnityEngine.UI.Text
---@field BtnAddSelect XUiComponent.XUiButton
---@field ImgSelect UnityEngine.UI.Image
---@field GoGroupLv UnityEngine.RectTransform 等级节点
---@field GoGroupFragment UnityEngine.RectTransform 碎片节点
---@field TxtClipCurCount UnityEngine.UI.Text 碎片当前数量
---@field TxtClipNeedCount UnityEngine.UI.Text 碎片需求数量
---@field GoExchange UnityEngine.RectTransform 兑换标签
local XUiEquipPartnerOneKeyCultureSelectCell = XClass(XUiNode, "XUiEquipPartnerOneKeyCultureSelectCell")

function XUiEquipPartnerOneKeyCultureSelectCell:OnStart()
    self._ColorLack = XUiHelper.Hexcolor2Color("E43730")

    self._ClipCurCountNormalColor = self.TxtClipCurCount.color
    self:InitComponents()
end

function XUiEquipPartnerOneKeyCultureSelectCell:InitComponents()
    self.BtnAddSelect.CallBack = function()
        self:OnBtnAddSelectClick()
    end
end

function XUiEquipPartnerOneKeyCultureSelectCell:OnEnable()
end

function XUiEquipPartnerOneKeyCultureSelectCell:OnDisable()
end

function XUiEquipPartnerOneKeyCultureSelectCell:OnDestroy()
end

---region ui event

function XUiEquipPartnerOneKeyCultureSelectCell:OnBtnAddSelectClick()
    local foodSelectControl = self._Control:GetOneKeyCultureMainControl():GetFoodSelectControl()
    if not self._IsSelect and foodSelectControl:IsFoodSelectFull() then
        XUiManager.TipText("PartnerOneKeySelectCountFull")
        return
    end

    if self._Partner then
        local partnerId = self._Partner:GetId()
        local isSelect = not self._IsSelect
        foodSelectControl:SetFoodSelect(partnerId, isSelect)
        self:_RefreshSelect()
    elseif self._IsClip then
        if not self._IsSelect and not self._IsOreExchangeClip and self._CurCount < self._NeedCount then
            return
        end
        local isSelect = not self._IsSelect
        if self._IsOreExchangeClip then
            foodSelectControl:SetOreExchangeClipSelect(self._ClipIndex, isSelect)
        else
            foodSelectControl:SetClipSelect(self._ClipIndex, isSelect)
        end
        self:_RefreshSelect()
    end
end

---endregion

---region event

---endregion

---@param partner XPartner
function XUiEquipPartnerOneKeyCultureSelectCell:RefreshByPartner(partner)
    self._Partner = partner
    self._IsClip = false
    self._IsOreExchangeClip = false
    self._IsMixed = false
    self._OwnChipCount = 0
    self._ExchangeChipCount = 0

    self.RImgHeadIcon:SetRawImage(partner:GetIcon())
    self.RImgQuality:SetRawImage(XMVCA.XCharacter:GetCharacterQualityIcon(partner:GetQuality()))
    self.Txtname.text = partner:GetName()
    self.TxtLevel.text = partner:GetLevel()

    local breakthroughIcon = partner:GetBreakthroughIcon()
    if breakthroughIcon then
        self.ImgBreak:SetSprite(breakthroughIcon)
    end

    self:_ShowUiByType(false)
    self:_RefreshSelect()
end

--- 刷新散碎片格子
---@param chipItemId number 碎片道具 Id（用于显示图标）
---@param index number 当前碎片在列表中的序号（1-based）
---@param curCount number 当前散碎片持有数
function XUiEquipPartnerOneKeyCultureSelectCell:RefreshByPartnerClip(chipItemId, index, curCount)
    self._IsMixed = false
    self._OwnChipCount = 0
    self._ExchangeChipCount = 0
    self:_RefreshByClip(chipItemId, index, curCount, false)
end

--- 刷新矿石兑换碎片格子
---@param chipItemId number
---@param index number
---@param curCount number
---@param isMixed boolean
---@param ownChipCount number
---@param exchangeChipCount number
function XUiEquipPartnerOneKeyCultureSelectCell:RefreshByOreExchangeClip(chipItemId, index, curCount, isMixed, ownChipCount, exchangeChipCount)
    self._IsMixed = isMixed == true
    self._OwnChipCount = ownChipCount or 0
    self._ExchangeChipCount = exchangeChipCount or curCount
    self:_RefreshByClip(chipItemId, index, curCount, true)
end

function XUiEquipPartnerOneKeyCultureSelectCell:_RefreshByClip(chipItemId, index, curCount, isOreExchangeClip)
    self._Partner = nil
    self._IsClip = true
    self._IsOreExchangeClip = isOreExchangeClip
    self._ChipItemId = chipItemId
    self._ClipIndex = index

    local goodsShowParams = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(chipItemId)
    if goodsShowParams then
        self.RImgHeadIcon:SetRawImage(goodsShowParams.Icon)
    end
    self.Txtname.text = goodsShowParams and goodsShowParams.Name

    local partner = self._Control:GetOneKeyCultureMainControl():GetCurPartnerEntity()
    local chipNeedCount = partner and partner:GetChipNeedCount() or 0
    self._CurCount = curCount
    self._NeedCount = chipNeedCount
    if self._IsMixed then
        self.TxtClipCurCount.text = string.format("%d+%d", self._OwnChipCount, self._ExchangeChipCount)
    else
        self.TxtClipCurCount.text = curCount
    end
    local isEnough = curCount >= chipNeedCount or self._IsMixed
    self.TxtClipCurCount.color = isEnough and self._ClipCurCountNormalColor or self._ColorLack
    self.TxtClipNeedCount.text = chipNeedCount

    self:_ShowUiByType(true)
    self.GoExchange.gameObject:SetActiveEx(isOreExchangeClip)
    self:_RefreshSelect()
end

--- 按类型显示/隐藏 UI 节点
---@param isClip boolean 是否为碎片格子
function XUiEquipPartnerOneKeyCultureSelectCell:_ShowUiByType(isClip)
    -- 先全部隐藏
    self.GoGroupLv.gameObject:SetActiveEx(false)
    self.GoGroupFragment.gameObject:SetActiveEx(false)
    self.RImgQuality.gameObject:SetActiveEx(false)
    self.GoExchange.gameObject:SetActiveEx(false)
    self.ImgBreak.gameObject:SetActiveEx(false)

    -- 再按类型点亮
    if isClip then
        self.GoGroupFragment.gameObject:SetActiveEx(true)
    else
        self.GoGroupLv.gameObject:SetActiveEx(true)
        self.RImgQuality.gameObject:SetActiveEx(true)
        self.ImgBreak.gameObject:SetActiveEx(true)
    end
end

function XUiEquipPartnerOneKeyCultureSelectCell:_RefreshSelect()
    local isSelect = false
    if self._Partner then
        isSelect = self._Control:GetOneKeyCultureMainControl():GetFoodSelectControl():IsFoodSelect(self._Partner:GetId())
    elseif self._IsClip then
        local foodSelectControl = self._Control:GetOneKeyCultureMainControl():GetFoodSelectControl()
        if self._IsOreExchangeClip then
            isSelect = foodSelectControl:IsOreExchangeClipSelect(self._ClipIndex)
        else
            isSelect = foodSelectControl:IsClipSelect(self._ClipIndex)
        end
    end
    self._IsSelect = isSelect
    self.ImgSelect.gameObject:SetActiveEx(isSelect)
end

return XUiEquipPartnerOneKeyCultureSelectCell
