--- 主卡头像节点（角色类 Role / 辅助机类 Partner 共用结构）。#67
--- 两个独立 GameObject（UiPunishaarCardHeadRole / UiPunishaarCardHeadPets），结构相同：
---   各自 UiObject 绑 ImgHead（头像图）+ ImgFrozen（图鉴中固定隐藏）。
--- 由上层按 cardCfg.Type 二选一显隐，本节点只负责头像赋值。
---   本节点只管图标赋值 + 冻结态显隐。逻辑图片赋值与旧单 ImgHead 一致，仅结构分两类别。
---@class XUiPunishaarCollectionCardHead : XUiNode
---@field ImgHead UnityEngine.UI.RawImage 头像图（cardCfg.Icon）
---@field ImgFrozen UnityEngine.GameObject 图鉴中固定隐藏的冻结遮罩
local XUiPunishaarCollectionCardHead = XClass(XUiNode, "XUiPunishaarCollectionCardHead")

function XUiPunishaarCollectionCardHead:OnStart()
    if self.ImgFrozen then
        self.ImgFrozen.gameObject:SetActiveEx(false)
    end
end
--- 刷新头像。头像显示是刚性需求：ImgHead 绑定缺失 / Icon 配置为空 均打 Error。
---@param icon string|nil cardCfg.Icon
---@param cardId number|nil 卡牌模板Id
function XUiPunishaarCollectionCardHead:Refresh(icon, cardId)
    if not self.ImgHead then
        XLog.Error("[PunishaarCardHead] Refresh: ImgHead 绑定缺失，检查 head prefab UiObject 是否绑 ImgHead + 子节点是否有 RawImage, cardId:", tostring(cardId))
        return
    end
    if string.IsNilOrEmpty(icon) then
        XLog.Error("[PunishaarCardHead] Refresh: 头像配置 Icon 为空，请检查 PunishaarCard.Icon 配置, cardId:", tostring(cardId))
        return
    end
    self.ImgHead:SetRawImage(icon)
end

return XUiPunishaarCollectionCardHead
