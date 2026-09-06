--- 卡牌单标签组件（类型图标 + 类型名 + 槽位尺寸）。
--- 由 GroupCardTag 下按配置 Tag 数量克隆，对称于 GroupSubTag 下的 SubCardTag。
--- 主卡详情 Tips 顶层用单实例展示主卡的类型/尺寸（非按 Tag 列表克隆）。
---@class XUiPanelPunishaarCardTag: XUiNode
---@field protected _Control XPunishaarControl
---@field Parent
---@field IconTag UnityEngine.UI.Image 卡牌类型图标（按 PunishaarCard.Type 取对应类型图标）
---@field TxtType UnityEngine.UI.Text 卡牌类型名（对应 Type，见 XMVCA.XPunishaar.EnumConst.CardType：角色/武器/意识/共鸣）
---@field TxtSlotSize UnityEngine.UI.Text 槽位尺寸文本（对应 PunishaarCard.Size：卡牌占格数）
local XUiPanelPunishaarCardTag = XClass(XUiNode, "XUiPanelPunishaarCardTag")

--- 刷新标签。
---@param cardCfg table|nil PunishaarCard 配置（取 Type/Size）
function XUiPanelPunishaarCardTag:Refresh(cardCfg)
    if not cardCfg then
        if self.TxtType     then self.TxtType.text = "" end
        if self.TxtSlotSize then self.TxtSlotSize.text = "" end
        if self.IconTag     then self.IconTag.gameObject:SetActiveEx(false) end
        return
    end

    if self.TxtType then
        local typeName = XMVCA.XPunishaar:GetClientStringByKey("CardTypeNames", cardCfg.Type)
        self.TxtType.text = typeName
    end
    
    if self.TxtSlotSize then
        self.TxtSlotSize.text = tostring(cardCfg.Size or 1)
    end
    
    -- TODO: 按 Type 取类型图标；PunishaarCard 表无按 Type 区分的图标字段、资源 Key 未定，暂不接线
    if self.IconTag then
        self.IconTag.gameObject:SetActiveEx(false)
    end
end

return XUiPanelPunishaarCardTag
