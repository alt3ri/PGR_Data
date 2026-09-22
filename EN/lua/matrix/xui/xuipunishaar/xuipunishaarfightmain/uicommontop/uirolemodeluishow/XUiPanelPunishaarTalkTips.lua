--- 对话气泡子面板（挂 EnemyDetail UiPunishaarTalkTips）：显隐 + 设 TxtTalk 文本。
--- 显隐契约：商人/敌人模型配置存在对话文本字段且非空 → Show(text) 设 TxtTalk + 显；其他任何情况 Hide。
--- 敌人侧暂无对话字段（XTablePunishaarEnemy 无），恒 Hide；商人 Shopping 态 ShopDialog 非空时 Show。#对话接入
---@class XUiPanelPunishaarTalkTips: XUiNode
---@field TxtTalk UnityEngine.UI.Text 对话文本
local XUiPanelPunishaarTalkTips = XClass(XUiNode, "XUiPanelPunishaarTalkTips")

--- 显示对话气泡并设文本。空文本 no-op（不显，对齐"文本不为空才显"契约）。
---@param text string 对话文本
function XUiPanelPunishaarTalkTips:Show(text)
    if string.IsNilOrEmpty(text) then
        return
    end
    if self.TxtTalk then
        self.TxtTalk.text = text
    end
    self:Open()
end

--- 隐藏对话气泡。
function XUiPanelPunishaarTalkTips:Hide()
    self:Close()
end

return XUiPanelPunishaarTalkTips
