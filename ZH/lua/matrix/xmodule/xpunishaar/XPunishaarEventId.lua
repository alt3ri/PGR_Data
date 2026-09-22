--- 大巴扎系统级事件 Id（服务端 RPC 推送等，界面外可收发）
--- 走 XPunishaarAgency 派发/监听（XAgency 自带 XEventDispatcher，定义与派发捆绑：本文件定义的事件仅经 Agency 收发）
--- 范式参考 XDyeMergeGameEventId：一处定义 + Agency 载入 self.EventIds + 经 XMVCA.XPunishaar.EventIds 暴露
--- key=value=string（短串 interned 共享，零 per-use 分配）
local EventId = {
    --region 系统级事件（Agency 生命周期，服务端 RPC 推送；界面外可订阅）
    EVENT_PUNISHAAR_INNER_GOLD_CHANGE             = "PunishaarGoldChange",             -- 局内金币变更（服务端推送）
    EVENT_PUNISHAAR_INNER_MASTER_CARD_CHANGE      = "PunishaarMasterCardChange",      -- 主卡新增或合成消耗（服务端推送 / UI 本地动作如副卡替换/卖出）
    EVENT_PUNISHAAR_INNER_SUB_CARD_CHANGE         = "PunishaarSubCardChange",         -- 副卡装配变化（服务端推送）
    EVENT_PUNISHAAR_INNER_REWARD_RESULT           = "PunishaarRewardResult",          -- 通用奖励下发（服务端推送，payload=StageId）
    EVENT_PUNISHAAR_INNER_FIGHT_AREA_GRID_UNLOCK  = "PunishaarFightAreaGridUnlock",  -- 对战区槽位解锁（服务端推送，payload=Amount）
    EVENT_PUNISHAAR_INNER_BAG_GRID_UNLOCK         = "PunishaarBagGridUnlock",         -- 背包槽位解锁（服务端推送，payload=Amount）
    --endregion
}

return EventId
