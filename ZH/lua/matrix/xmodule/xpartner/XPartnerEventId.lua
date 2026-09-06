---@class XPartnerEventId
--- 模块内事件 id（key=value，全大写下划线）。
--- 三段式前缀约定：
---   EVENT_VIEW_*  纯 UI 内部交互事件（UI→UI / UI→Control）
---   EVENT_REPLY_* 网络回应事件（NetWorkControl 回包后派发）
---   EVENT_*       业务数据变更事件（Control 数据变 → UI）
--- 跨模块/全局事件请放 Matrix/MVCA/MVCAEventId.lua。
local XPartnerEventId = {
    --当前选中辅助机变更（一键培养）
    EVENT_PARTNER_SELECT_CHANGE = "EVENT_PARTNER_SELECT_CHANGE",
    --辅助机数据更新（全局事件转发，外部数据变更通知 UI 刷新）
    EVENT_REPLY_PARTNER_DATA_UPDATE = "EVENT_REPLY_PARTNER_DATA_UPDATE",
    --养成选项勾选状态变更（一键培养弹窗）
    EVENT_CULTURE_SELECT_CHANGE = "EVENT_CULTURE_SELECT_CHANGE",
    --狗粮/碎片选择确认变更（一键培养弹窗，§21确认后派发）
    EVENT_PARTNER_FOOD_CHANGE = "EVENT_PARTNER_FOOD_CHANGE",
    --升星狗粮辅助机选择变更（一键培养弹窗 View 内部刷新）
    EVENT_FOOD_SELECT_PREVIEW_CHANGE = "EVENT_FOOD_SELECT_PREVIEW_CHANGE",
    --自动兑换开关变更（一键培养）
    EVENT_AUTO_EXCHANGE_CHANGE = "EVENT_AUTO_EXCHANGE_CHANGE",
    --一键养成流程结束（完成/中断均派发，通知主界面刷新表现）
    EVENT_ONE_KEY_CULTURE_FINISH = "EVENT_ONE_KEY_CULTURE_FINISH",
    --一键养成进度界面关闭且实际发起过养成请求（通知主界面播放完成特效）
    EVENT_VIEW_ONE_KEY_CULTURE_EFFECT = "EVENT_VIEW_ONE_KEY_CULTURE_EFFECT",
    --升星预览打开（一键培养弹窗，描述按钮点击）
    EVENT_VIEW_PARTNER_POPUP_OPEN_STARUP_PREVIEW = "EVENT_VIEW_PARTNER_POPUP_OPEN_STARUP_PREVIEW",
    --伙伴升级回包（喂经验）
    EVENT_REPLY_PARTNER_LEVEL_UP = "EVENT_REPLY_PARTNER_LEVEL_UP",
    --伙伴突破回包（升阶，提升等级上限）
    EVENT_REPLY_PARTNER_BREAK_THROUGH = "EVENT_REPLY_PARTNER_BREAK_THROUGH",
    --伙伴星数进度激活回包（喂狗粮，累积碎片进度）
    EVENT_REPLY_PARTNER_STAR_ACTIVATE = "EVENT_REPLY_PARTNER_STAR_ACTIVATE",
    --伙伴进化回包（升星，品质提升）
    EVENT_REPLY_PARTNER_EVOLUTION = "EVENT_REPLY_PARTNER_EVOLUTION",
    --伙伴技能升级回包
    EVENT_REPLY_PARTNER_SKILL_UP = "EVENT_REPLY_PARTNER_SKILL_UP",
    --伙伴技能穿戴回包（携带成功/失败结果）
    EVENT_REPLY_PARTNER_SKILL_WEAR = "EVENT_REPLY_PARTNER_SKILL_WEAR",
    --碎片合成辅助机回包（兑换）
    EVENT_REPLY_PARTNER_CHIP_EXCHANGE = "EVENT_REPLY_PARTNER_CHIP_EXCHANGE",
}

return XPartnerEventId
