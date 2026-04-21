---@class XUiPBRMonsterPanelTag: XUiNode
---@field protected _Control XPBRGameControl
---@field Parent
local XUiPBRMonsterPanelTag = XClass(XUiNode, "XUiPBRMonsterPanelTag")

function XUiPBRMonsterPanelTag:ShowTagByType(type)
    self.ImgBgOrdinary.gameObject:SetActiveEx(false)
    self.ImgBgElite.gameObject:SetActiveEx(false)
    self.ImgBgBoss.gameObject:SetActiveEx(false)

    if type == XMVCA.XPBRGame.EnumConst.Collections.MonsterTagType.Normal then
        self.ImgBgOrdinary.gameObject:SetActiveEx(true)
        
    elseif type == XMVCA.XPBRGame.EnumConst.Collections.MonsterTagType.Elite then
        self.ImgBgElite.gameObject:SetActiveEx(true)

    elseif type == XMVCA.XPBRGame.EnumConst.Collections.MonsterTagType.Boss then
        self.ImgBgBoss.gameObject:SetActiveEx(true)
        
    end

    self.TxtTagName.text = self._Control:GetClientPBRText('CollectionMonsterTypeLabel', type)
end

return XUiPBRMonsterPanelTag