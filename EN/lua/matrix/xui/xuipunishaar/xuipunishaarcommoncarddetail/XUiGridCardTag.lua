--- 卡牌单标签 grid（Tag 图标 + Tag 名称），由 GroupCardTag 下按配置 Tag 数量克隆。
--- 对称于主卡/副卡详情（XUiPanelPunishaarMainCard/XUiPanelPunishaarSubCard 的 GroupCardTag）。
--- 与 XUiPanelPunishaarCardTag 区别：本组件按 PunishaarCardTag.Id 列表克隆（效果/构筑标签），
---   XUiPanelPunishaarCardTag 按卡牌 Type/Size 显类型图标（语义不同，不复用）#78。
--- 放通用根目录 XUiPunishaarCommonCardDetail/ 供主/副卡详情共享 #78 修正。
---@class XUiGridCardTag : XUiNode
---@field Parent
---@field ImgElement UnityEngine.UI.RawImage Tag 图标（对应 PunishaarCardTag.Icon，prefab 节点名 ImgElement #78 修正）
---@field TxtElement UnityEngine.UI.Text Tag 名称（对应 PunishaarCardTag.Name，prefab 节点名 TxtElement #78 修正）
local XUiGridCardTag = XClass(XUiNode, "XUiGridCardTag")

--- 刷新单 Tag 显示。
--- tagCfg 为 nil（PunishaarCardTag 表数据未填/Id 查不到）时隐藏本 grid。
---@param tagCfg XTablePunishaarCardTag|nil
function XUiGridCardTag:Refresh(tagCfg)
    if not tagCfg then
        self:Close()
        return
    end
    
    if self.ImgElement and not string.IsNilOrEmpty(tagCfg.Icon) then
        self.ImgElement:SetSprite(tagCfg.Icon)
    end
    
    if self.TxtElement then
        self.TxtElement.text = tagCfg.Name or ""
    end
end

return XUiGridCardTag
