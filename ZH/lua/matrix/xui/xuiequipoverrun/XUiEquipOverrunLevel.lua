---@class XUiEquipOverrunLevel : XLuaUi
---@field _Control XEquipControl
local XUiEquipOverrunLevel = XLuaUiManager.Register(XLuaUi, "UiEquipOverrunLevel")

function XUiEquipOverrunLevel:OnAwake()
    self:SetButtonCallBack()
end

function XUiEquipOverrunLevel:OnStart(equipId, level, characterId)
    self.EquipId = equipId
    self.Level = level
    self.CharacterId = characterId 
    if not XTool.IsNumberValidEx(characterId) then
        local templateId = XMVCA.XEquip:GetEquipTemplateId(self.EquipId)
        self.CharacterId = XMVCA.XEquip:GetWeaponOverrunCharacterId(templateId)
    end
    self:Refresh()
end

function XUiEquipOverrunLevel:SetButtonCallBack()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.Close)
end

-- 刷新界面
function XUiEquipOverrunLevel:Refresh()
    local equip = XMVCA.XEquip:GetEquip(self.EquipId)

    -- 等级
    local overrunCfgs = self._Control:GetWeaponOverrunCfgsByTemplateId(equip.TemplateId, self.CharacterId)
    local overrunCfg = overrunCfgs[self.Level]
    local overrunType = overrunCfg.OverrunType
    local isLevelStyle = overrunType == XEnumConst.EQUIP.WEAPON_OVERRUN_UNLOCK_TYPE.SUIT or overrunType == XEnumConst.EQUIP.WEAPON_OVERRUN_UNLOCK_TYPE.ATTR
    self.PanelLevel.gameObject:SetActiveEx(isLevelStyle)
    self.PanelDot.gameObject:SetActiveEx(not isLevelStyle)
    if isLevelStyle then
        self.UiTxtLevelImg1.gameObject:SetActiveEx(self.Level == XEnumConst.EQUIP.WEAPON_OVERRUN_LEVEL_TYPE.LEVEL1)
        self.UiTxtLevelImg2.gameObject:SetActiveEx(self.Level >= XEnumConst.EQUIP.WEAPON_OVERRUN_LEVEL_TYPE.LEVEL2)
    end

    -- 描述
    local deregulateUICfg = self._Control:GetConfigWeaponDeregulateUI(self.Level)
    self.TxtLevel.text = string.IsNilOrEmpty(overrunCfg.Name) and deregulateUICfg.LvUpTips or overrunCfg.Name
    self.TxtDetail.text = overrunCfg.Desc
end

return XUiEquipOverrunLevel