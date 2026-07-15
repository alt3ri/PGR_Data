local EventId = {
    --region 内部事件：限制在control、agency中使用
    
    --- 活动时间定时器更新
    EVENT_DYEMERGE_INNER_ACTIVITY_TIMER_UPDATE = 1,
    --- 方块深度脏标记：方块移动或变长后触发，通知 UI 层更新 SiblingIndex
    --- payload: uid (number)
    EVENT_DYEMERGE_INNER_BLOCK_DEPTH_DIRTY = 2,
    --- 动画响应
    EVENT_DYEMERGE_INNER_ANIMATION_RUN = 3,
    --- 通关事件
    EVENT_DYEMERGE_INNER_STAGE_PASSED = 4,
    --- 刷新关卡攻略小窗显示状态
    EVENT_DYEMERGE_INNER_REFRESH_TIPS_WINDOW = 5,
    --endregion
    
    --region 外部事件：在EventManager中使用， 定义需注意不与EventId中冲突
    
    --endregion
}

return EventId