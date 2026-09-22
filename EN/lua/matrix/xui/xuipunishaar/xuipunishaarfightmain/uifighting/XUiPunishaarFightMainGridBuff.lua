---@class XUiPunishaarFightMainGridBuff : XUiNode
---@field _Control XPunishaarControl
---@field Icon UnityEngine.UI.Image
---@field TxtLayer UnityEngine.UI.Text
---@field Effect UnityEngine.GameObject 数值变动特效（关再开重播，初始化默认隐）
local XUiPunishaarFightMainGridBuff = XClass(XUiNode, "XUiPunishaarFightMainGridBuff")

function XUiPunishaarFightMainGridBuff:OnStart()
    -- Effect 默认隐（防 prefab 默认 active 残留显）
    if self.Effect then
        self.Effect.gameObject:SetActiveEx(false)
    end
end

--- 清变更检测键：本项从列表消失后若再次显示，应重新播一次数值变动特效
function XUiPunishaarFightMainGridBuff:OnDisable()
    self._LastIconIndex = nil
    self._LastLayer = nil
end

--- 刷新一项状态图标（护盾与 buff 共用本预制）。
--- iconIndex 而非 buffId 作图标标识：Buff 表无 Icon 字段，图标按"用途"配在 ClientConfig.BuffIcons
--- 单 key 多值下（护盾=1 敌我共用 / 敌人 DoT=2 所有 DoT buff 共用一图），故同类 buff 图标相同。
---@param iconIndex number XPunishaarEnum.BuffIconIndex
---@param layer number 显示数值（buff = Σ Layer 聚合值 / 护盾 = 剩余免伤次数）
function XUiPunishaarFightMainGridBuff:Refresh(iconIndex, layer)
    if self.TxtLayer then
        -- 向下取整：护盾(NoHurtTimes)与 buff Layer 都是 PropertyModifiedNum 终值，策划配
        -- Multiply/Divide 修正即产浮点，Lua 5.3 下 tostring(3.0)=="3.0" 会显到 UI 上
        -- （同 PanelEnemyHp/PanelMainHp 血量 math.floor 的坑 #4.8）
        self.TxtLayer.text = tostring(math.floor(layer or 0))
    end

    -- 图标：仅在 iconIndex 变化时换图（避免每次数值变动都走一遍 SetSprite 的资源查找）。
    -- 配置未填（美术未出图）时 path 为空串 → 隐 Icon，不报错（安全空转）。
    if self.Icon and self._LastIconIndex ~= iconIndex then
        local path = iconIndex and self._Control:GetBuffIconPath(iconIndex) or nil
        local show = not string.IsNilOrEmpty(path)
        self.Icon.gameObject:SetActiveEx(show)
        if show then
            self.Icon:SetSprite(path)
        end
    end

    -- 内容变动（换了图标类型 / 数值变）时 Effect 关再开重播。检测键含 iconIndex：同一 grid 位被
    -- 复用去显示另一类状态时，仅比数值会误判「没变→不重播」（同 #82 跨卡误播动画的坑）。
    -- 首次显示两键均 nil：由 nil 变实值 → 播，对齐改造前「0→N 算变动」的行为。
    if self.Effect and (self._LastIconIndex ~= iconIndex or self._LastLayer ~= layer) then
        self.Effect.gameObject:SetActiveEx(false)
        self.Effect.gameObject:SetActiveEx(true)
    end
    self._LastIconIndex = iconIndex
    self._LastLayer = layer
end

return XUiPunishaarFightMainGridBuff
