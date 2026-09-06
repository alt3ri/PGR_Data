--- 卡牌数值标签（TagDamage/TagCD 通用 XUiNode）。
--- 挂卡牌根节点（grid 层，非 CardShow 子树）：atk/cd 数据由父 grid 算好喂入，避免子→父上行访问（UI-Rule）。
--- 含 normal/up 两文本对称显隐：current≈config（浮点 eps）→ 显 normal（TxtDamage/TxtCD）；
---   current≠config → 显 up（TxtDamageUp/TxtCDUp）。
--- 变更检测：first（首次）或 current/config 与上次不同才赋值/切显隐/播动效；值不变跳过（每帧调省开销）。
---@class XUiPunishaarCardValueTag: XUiNode
---@field protected _Control XPunishaarControl
---@field Parent
---@field TxtDamage UnityEngine.UI.Text @TagDamage 实例绑（normal）
---@field TxtDamageUp UnityEngine.UI.Text @TagDamage 实例绑（up）
---@field TxtCD UnityEngine.UI.Text @TagCD 实例绑（normal）
---@field TxtCDUp UnityEngine.UI.Text @TagCD 实例绑（up）
local XUiPunishaarCardValueTag = XClass(XUiNode, "XUiPunishaarCardValueTag")

local EPS = 1e-4

function XUiPunishaarCardValueTag:OnStart()
    -- 默认全隐，由 Refresh 决定显哪个
    if self.TxtDamage then self.TxtDamage.gameObject:SetActiveEx(false) end
    if self.TxtDamageUp then self.TxtDamageUp.gameObject:SetActiveEx(false) end
    if self.TxtCD then self.TxtCD.gameObject:SetActiveEx(false) end
    if self.TxtCDUp then self.TxtCDUp.gameObject:SetActiveEx(false) end
end

--- 按 current vs config 判等显 normal/up + 变更检测驱动 Refresh 动效。
--- first（_LastCurrent nil）或 current/config 变化 → 赋值 + 切显隐；changed（非首次的变更）→ 播动效。
--- 值不变跳过（每帧调省 .text 赋值 / SetActiveEx 开销）。
---@param currentValue number 运行时值（base+delta / reader 最终值）
---@param configValue number 配置基础值
---@param formattedText string 已格式化展示文本
function XUiPunishaarCardValueTag:Refresh(currentValue, configValue, formattedText)
    local normalTxt = self.TxtDamage or self.TxtCD
    local upTxt = self.TxtDamageUp or self.TxtCDUp
    if not normalTxt or not upTxt then
        return
    end
    -- 变更检测前置：first 或 changed 才处理；值不变直接 return（每帧调零开销）
    local first = self._LastCurrent == nil
    local changed = not first
            and (self._LastCurrent ~= currentValue or self._LastConfig ~= configValue)
    self._LastCurrent = currentValue
    self._LastConfig = configValue
    if not (first or changed) then
        return
    end
    local equal = math.abs(currentValue - configValue) < EPS
    -- 显式 if/else 取 show/hide：避 Lua `cond and a or b` 在 a 为 nil 时的回退陷阱
    local showTxt, hideTxt
    if equal then
        showTxt, hideTxt = normalTxt, upTxt
    else
        showTxt, hideTxt = upTxt, normalTxt
    end
    -- 先写显的目标文本，再切显隐（切时新显的已有文本，避免首帧空）
    showTxt.text = formattedText
    if not showTxt.gameObject.activeSelf then
        showTxt.gameObject:SetActiveEx(true)
    end
    if hideTxt.gameObject.activeSelf then
        hideTxt.gameObject:SetActiveEx(false)
    end
    if changed then
        self:_PlayRefreshAnim()
    end
end

--- 清空（grid 切空槽/副卡态时隐标签 + 清缓存，下次 Refresh 视作首次不播动效）。
function XUiPunishaarCardValueTag:Clear()
    if self.TxtDamage then self.TxtDamage.gameObject:SetActiveEx(false) end
    if self.TxtDamageUp then self.TxtDamageUp.gameObject:SetActiveEx(false) end
    if self.TxtCD then self.TxtCD.gameObject:SetActiveEx(false) end
    if self.TxtCDUp then self.TxtCDUp.gameObject:SetActiveEx(false) end
    self._LastCurrent = nil
    self._LastConfig = nil
end

--- Refresh 动效钩子：数值变更时播 XUiNode:PlayAnimation("Refresh")。
--- prefab 上 Tag 根节点（TagDamage/TagCD）需挂 Animation 组件 + "Refresh" state。#79
function XUiPunishaarCardValueTag:_PlayRefreshAnim()
    self:PlayAnimation("Refresh")
end

return XUiPunishaarCardValueTag
