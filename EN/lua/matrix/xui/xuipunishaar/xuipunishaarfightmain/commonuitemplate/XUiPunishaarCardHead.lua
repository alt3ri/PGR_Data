--- 主卡头像节点（角色类 Role / 辅助机类 Partner 共用结构）。#67
--- 两个独立 GameObject（UiPunishaarCardHeadRole / UiPunishaarCardHeadPets），结构相同：
---   各自 UiObject 绑 ImgHead（头像图，喂 cardCfg.Icon）+ ImgFrozen（冻结态遮罩）。
--- 由上层 CardShow/Panel 按 cardCfg.Type 二选一显隐（Character→Role / Weapon→Partner），
---   本节点只管图标赋值 + 冻结态显隐。逻辑图片赋值与旧单 ImgHead 一致，仅结构分两类别。
---@class XUiPunishaarCardHead : XUiNode
---@field ImgHead UnityEngine.UI.RawImage 头像图（cardCfg.Icon）
---@field ImgFrozen UnityEngine.GameObject 冻结态遮罩（商店商品级冻结显隐；非商店恒 false）
local XUiPunishaarCardHead = XClass(XUiNode, "XUiPunishaarCardHead")

--- 刷新头像 + 冻结态。头像显示是刚性需求：ImgHead 绑定缺失 / Icon 配置为空 均打 Error。
---@param icon string|nil cardCfg.Icon
---@param frozen boolean 是否冻结
---@param cardId number|nil 卡牌模板 Id（仅用于 Error 日志定位配置行）
function XUiPunishaarCardHead:Refresh(icon, frozen, cardId)
    if not self.ImgHead then
        XLog.Error("[PunishaarCardHead] Refresh: ImgHead 绑定缺失，检查 head prefab UiObject 是否绑 ImgHead + 子节点是否有 RawImage, cardId:", tostring(cardId))
        return
    end
    if string.IsNilOrEmpty(icon) then
        XLog.Error("[PunishaarCardHead] Refresh: 头像配置 Icon 为空，请检查 PunishaarCard.Icon 配置, cardId:", tostring(cardId))
        return
    end
    self.ImgHead:SetRawImage(icon)
    if self.ImgFrozen then
        self.ImgFrozen.gameObject:SetActiveEx(frozen == true)
    end
end

return XUiPunishaarCardHead
