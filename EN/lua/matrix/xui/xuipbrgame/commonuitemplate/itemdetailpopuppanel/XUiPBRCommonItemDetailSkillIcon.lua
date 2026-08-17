---@class XUiPBRCommonItemDetailSkillIcon : XUiNode
---@field _Control XPBRGameControl
local XUiPBRCommonItemDetailSkillIcon = XClass(XUiNode, "XUiPBRCommonItemDetailSkillIcon")

function XUiPBRCommonItemDetailSkillIcon:InitComponents()
end

function XUiPBRCommonItemDetailSkillIcon:OnStart(...)
    self:InitComponents()
end

function XUiPBRCommonItemDetailSkillIcon:OnEnable()
end

function XUiPBRCommonItemDetailSkillIcon:OnDisable()
end

function XUiPBRCommonItemDetailSkillIcon:OnDestroy()
end

function XUiPBRCommonItemDetailSkillIcon:Refresh(itemId)
    -- 显示道具图标
    local itemCfg = self._Control:GetPBRItemCfgById(itemId)

    if itemCfg then
        if not string.IsNilOrEmpty(itemCfg.Icon) then
            self.RImgIcon:SetRawImage(itemCfg.Icon)
        end

        if self.ImgLace then
            local color = self._Control:GetClientPBRText("SkillIconLaceColor", itemCfg.OrbColor)

            if not string.IsNilOrEmpty(color) then
                self.ImgLace.color = XUiHelper.Hexcolor2Color(string.gsub(color, "#", ""))
            end
        end
    else
        self.RImgIcon:SetRawImage("")
    end
end

return XUiPBRCommonItemDetailSkillIcon
