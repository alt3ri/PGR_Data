local EventId = {
    --region 内部事件：限制在control、agency中使用
    
    --- 活动时间定时器更新
    EVENT_PBR_INNER_ACTIVITY_TIMER_UPDATE = 1,

    --- 打开道具详情
    EVENT_PBR_INNER_OPEN_ITEM_DETAIL = 2,
    
    --- 图鉴打开怪物波次成长描述弹窗
    EVENT_PBR_INNER_OPEN_MONSTER_ARCHIVE_POPUPPANEL = 3,
    
    --- 天赋点击详情
    EVENT_PBR_INNER_OPEN_GENIUS_DETAIL = 4,
    
    --endregion
    
    --region 外部事件：在EventManager中使用， 定义需注意不与EventId中冲突
    
    --endregion
}

return EventId