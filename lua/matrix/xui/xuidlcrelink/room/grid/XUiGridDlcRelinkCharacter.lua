---@class XUiGridDlcRelinkCharacter : XUiNode
---@field private _Control XDlcRelinkControl
local XUiGridDlcRelinkCharacter = XClass(XUiNode, "XUiGridDlcRelinkCharacter")

function XUiGridDlcRelinkCharacter:OnStart(callBack)
    self.CallBack = callBack
    XUiHelper.RegisterClickEvent(self, self.BtnCharacter, self.OnBtnCharacterClick, true, true)
    self.TxtNow.gameObject:SetActiveEx(false)
    self.ImgSelect.gameObject:SetActiveEx(false)
end

function XUiGridDlcRelinkCharacter:GetCharacterId()
    return self.CharacterId
end

function XUiGridDlcRelinkCharacter:Refresh(characterId)
    self.CharacterId = characterId
    -- 角色小头像
    local fashionId = XMVCA.XCharacter:GetCharacterTemplate(characterId).DefaultNpcFashtionId
    self.RImgHead:SetRawImage(XDataCenter.FashionManager.GetFashionSmallHeadIcon(fashionId))
    -- 装备战力
    local totalAbility = self._Control:GetEquipTotalAbilityByCharacterId(characterId)
    self.TxtLv.text = string.format(self._Control:GetClientConfig("EquipLevelDesc"), totalAbility)
    -- 角色职业图标
    self:RefreshOccupation()
end

function XUiGridDlcRelinkCharacter:OnGetLuaEvents()
    return {
        XEventId.EVENT_DLC_RELINK_SWITCH_OCCUPATION,
    }
end

function XUiGridDlcRelinkCharacter:OnNotify(event, ...)
    local args = { ... }
    if event == XEventId.EVENT_DLC_RELINK_SWITCH_OCCUPATION then
        if args[1] == self.CharacterId then
            self:RefreshOccupation()
        end
    end
end

-- 刷新职业图标
function XUiGridDlcRelinkCharacter:RefreshOccupation()
    local occupationType = self._Control:GetOccupationTypeByCharacterId(self.CharacterId)
    local occupationIcon = self._Control:GetClientConfig("CharacterOccupationIcon", occupationType) or ""
    if not string.IsNilOrEmpty(occupationIcon) then
        self.RImgType:SetRawImage(occupationIcon)
    end
end

-- 设置选中状态
function XUiGridDlcRelinkCharacter:SetSelect(isSelect)
    self.ImgSelect.gameObject:SetActiveEx(isSelect)
end

-- 设置当前状态
function XUiGridDlcRelinkCharacter:SetNow(isNow)
    self.TxtNow.gameObject:SetActiveEx(isNow)
end

function XUiGridDlcRelinkCharacter:OnBtnCharacterClick()
    if self.CallBack then
        self.CallBack(self)
    end
end

return XUiGridDlcRelinkCharacter
