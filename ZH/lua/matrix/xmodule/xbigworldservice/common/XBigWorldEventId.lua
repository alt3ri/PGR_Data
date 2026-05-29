local id = 1000000

local function NewId()
    id = id + 1
    return id
end

local dlcEventId = {
    -- 战斗端角色加载完成
    EVENT_LOCAL_PLAYER_NPC_LOAD_COMPLETED = NewId(),

    -- 刷新任务界面选中状态
    EVENT_REFRESH_QUEST_MAIN = NewId(),

    -- 任务Objective状态刷新
    EVENT_QUEST_OBJECTIVE_STATE_CHANGED = NewId(),

    -- 刷新任务红点
    EVENT_QUEST_RED_POINT_REFRESH = NewId(),

    -- 刷新主界面选择的任务
    EVENT_QUEST_REFRESH_MAIN_SELECT = NewId(),

    -- 任务完成
    EVENT_QUEST_FINISH = NewId(),

    -- 角色编队状态刷新
    EVENT_ROLE_TEAM_STATUS_REFRESH = NewId(),

    -- 短信领取任务
    EVENT_MESSAGE_QUEST_NOTIFY = NewId(),

    -- 咖啡回合开始
    EVENT_CAFE_ROUND_BEGIN = NewId(),

    -- 咖啡回合改变
    EVENT_CAFE_ROUND_CHANGED = NewId(),

    -- 咖啡进入战斗
    EVENT_CAFE_ENTER_FIGHT = NewId(),

    -- 咖啡退出战斗
    EVENT_CAFE_EXIT_FIGHT = NewId(),

    -- 手牌更新
    EVENT_CAFE_UPDATE_PLAY_CARD = NewId(),

    -- 咖啡厅Hud刷新
    EVENT_CAFE_HUD_REFRESH = NewId(),

    -- 咖啡厅Hud隐藏
    EVENT_CAFE_HUD_HIDE = NewId(),

    -- 结算
    EVENT_CAFE_SETTLEMENT = NewId(),

    -- 回合播报
    EVENT_CAFE_REFRESH_BROADCAST = NewId(),

    -- 触发重抽
    EVENT_CAFE_RE_DRAW_CARD = NewId(),

    -- NPC回合演出
    EVENT_CAFE_ROUND_NPC_SHOW = NewId(),

    -- 特效飞行完成
    EVENT_CAFE_EFFECT_FLY_COMPLETE = NewId(),

    -- 特效开始飞行
    EVENT_CAFE_EFFECT_BEGIN_FLY = NewId(),

    -- 吧台NPC角色改变了
    EVENT_CAFE_BAR_COUNTER_NPC_CHANGED = NewId(),

    -- 触发buff
    EVENT_CAFE_APPLY_BUFF = NewId(),

    -- 出牌区下标更新
    EVENT_CAFE_DEAL_INDEX_UPDATE = NewId(),

    -- 出牌
    EVENT_CAFE_DECK_TO_DEAL = NewId(),

    -- 牌组数量变化
    EVENT_CAFE_POOL_CARD_COUNT_UPDATE = NewId(),

    -- 新卡牌
    EVENT_CAFE_NEW_CARD_UNLOCK = NewId(),

    -- 重置Buff预览
    EVENT_CAFE_RESET_BUFF_PREVIEW = NewId(),

    -- 小地图图钉隐藏
    EVENT_LITTLE_MAP_PIN_HIDE = NewId(),

    -- 追踪图钉
    EVENT_MAP_PIN_TRACK_CHANGE = NewId(),

    -- 详情刷新
    EVENT_MAP_DETAIL_CHANGE = NewId(),

    -- 添加图钉
    EVENT_MAP_PIN_ADD = NewId(),

    -- 删除图钉
    EVENT_MAP_PIN_REMOVE = NewId(),

    -- 开始传送图钉
    EVENT_MAP_PIN_BEGIN_TELEPORT = NewId(),

    -- 结束传送图钉
    EVENT_MAP_PIN_END_TELEPORT = NewId(),

    -- 更新图钉虚拟位置
    EVENT_MAP_PIN_ASSISTED_TRACK_UPDATE = NewId(),

    -- 更新图钉位置
    EVENT_MAP_PIN_POSITION_UPDATE = NewId(),

    -- 更新图钉样式
    EVENT_MAP_PIN_STYLE_UPDATE = NewId(),

    -- 更新环境图钉显示
    EVENT_MAP_PIN_AI_MEMORY_DISPLAY_CHANGE = NewId(),

    -- 图钉详情关闭
    EVENT_MAP_PIN_DETAIL_CLOSE = NewId(),

    -- 修改图钉展示类型
    EVENT_SET_MAP_PIN_SHOW_TYPE = NewId(),

    -- 地图传送弹窗关闭
    EVENT_MAP_TELEPORT_POPUP_CLOSE = NewId(),

    -- 地图传送弹窗打开
    EVENT_MAP_TELEPORT_POPUP_OPEN = NewId(),

    -- 地图切换
    EVENT_MAP_SWITCH = NewId(),

    -- 玩家进入区域
    EVENT_PLAYER_ENTER_AREA = NewId(),

    -- 玩家离开区域
    EVENT_PLAYER_EXIT_AREA = NewId(),

    -- 宝箱数据更新
    EVENT_BOX_DATA_UPDATE = NewId(),

    -- 商业街 关卡刷新
    EVENT_BUSINESS_STREET_STAGE_REFRESH = NewId(),

    -- 商业街建造刷新
    EVENT_BUSINESS_STREET_BUILD_REFRESH = NewId(),

    -- 商业街资源刷新
    EVENT_BUSINESS_STREET_RES_REFRESH = NewId(),

    -- 商业街BUFF刷新
    EVENT_BUSINESS_STREET_BUFF_REFRESH = NewId(),

    -- 商业街喜好说话刷新
    EVENT_BUSINESS_STREET_LIKE_TALK_REFRESH = NewId(),

    -- 商业街任务完成刷新
    EVENT_BUSINESS_STREET_FINISH_TASK_REFRESH = NewId(),

    -- 商业街任务刷新
    EVENT_BUSINESS_STREET_TASK_REFRESH = NewId(),

    -- 激活场景物体
    EVENT_SCENE_OBJECT_ACTIVATE = NewId(),

    -- 短信阅读完成
    EVENT_MESSAGE_FINISH_NOTIFY = NewId(),

    -- 收到短信
    EVENT_RECEIVE_MESSAGE_NOTIFY = NewId(),

    -- 阅读短信
    EVENT_RECORD_MESSAGE_NOTIFY = NewId(),

    -- 播放下一条短信
    EVENT_PLAY_NEXT_MESSAGE_NOTIFY = NewId(),

    -- 短信选项选择
    EVENT_MESSAGE_OPTION_SELECT_NOTIFY = NewId(),

    -- 短信播放结束
    EVENT_MESSAGE_PLAY_FINISH_NOTIFY = NewId(),

    -- 短信播放暂停
    EVENT_MESSAGE_PLAY_PAUSE_NOTIFY = NewId(),

    -- 设置重置
    EVENT_SETTING_RESET = NewId(),

    -- 设置保存
    EVENT_SETTING_SAVE = NewId(),

    -- 设置恢复默认
    EVENT_SETTING_RESTORE = NewId(),

    -- 解锁图文教程
    EVENT_TEACH_UNLOCK = NewId(),

    -- 阅读图文教程
    EVENT_TEACH_READ = NewId(),

    -- 图文提示关闭
    EVENT_TEACH_TIP_CLOSE = NewId(),

    -- Mask黑屏关闭
    EVENT_BLACK_MASK_LOADING_CLOSE = NewId(),

    -- 战斗关卡开始更新
    EVENT_FIGHT_LEVEL_BEGIN_UPDATE = NewId(),

    -- 战斗进入关卡
    EVENT_FIGHT_ENTER_LEVEL = NewId(),

    -- 战斗离开关卡
    EVENT_FIGHT_LEAVE_LEVEL = NewId(),

    -- 战斗UI界面OnEnable
    EVENT_FIGHT_UI_HUD_ENABLE = NewId(),

    -- Hud界面设置显隐
    EVENT_SET_UI_HUD_ACTIVE = NewId(),

    -- Hud界面刷新红点
    EVENT_HUD_RED_POINT_REFRESH = NewId(),

    -- 大世界结算
    EVENT_BIG_WORLD_SETTLEMENT = NewId(),

    --大世界功能开启开始
    EVENT_BIG_WORLD_FUNCTION_EVENT_BEGIN = NewId(),

    -- 大世界功能开启完成
    EVENT_BIG_WORLD_FUNCTION_EVENT_END = NewId(),

    -- 打脸完成
    EVENT_BIG_WORLD_FUNCTION_EVENT_COMPLETE = NewId(),
    
    -- 检查打脸
    EVENT_CHECK_FUNCTION_POPUP = NewId(),

    -- 进入大世界前
    EVENT_BEFORE_ENTER_GAME = NewId(),

    -- 进入大世界后
    EVENT_AFTER_ENTER_GAME = NewId(),

    -- 大世界功能屏蔽
    EVENT_FUNCTION_SHIELD_CHANEG = NewId(),

    -- 大世界功能控制
    EVENT_FUNCTION_SHIELD_CONTROL = NewId(),

    -- 大世界开场引导完成
    EVENT_BIG_WORLD_OPEN_GUIDE_FINISH = NewId(),

    -- DIY界面关闭
    EVENT_UI_BIG_WORLD_DIY_DESTROY = NewId(),

    -- 指挥官DIY保存完成(刷新指挥官模型)
    EVENT_BIG_WORLD_COMMANDER_DIY_MODEL_UPDATE = NewId(),

    -- 指挥官DIY重置完成
    EVENT_BIG_WORLD_COMMANDER_DIY_RESET = NewId(),

    -- 指挥官DIY背包更新
    EVENT_BIG_WORLD_COMMANDER_DIY_BACKPACK_UPDATE = NewId(),

    -- 历程界面红点刷新
    EVENT_COURSE_RED_POINT_REFRESH = NewId(),

    -- 历程界面领取奖励
    EVENT_COURSE_REWARD_RECEIVE = NewId(),

    -- 历程切换页签
    EVENT_COURSE_CHANGE_PAGE = NewId(),

    -- 历程切换版本
    EVENT_COURSE_CHANGE_VERSION = NewId(),

    -- 图文教程解锁触发
    EVENT_HELP_COURSE_UNLOCK_TRIGGER = NewId(),
    
    -- 视角发生变化
    EVENT_BIG_WORLD_PERSPECTIVE_CHANGED = NewId(),
    
    -- 视角按钮功能禁用
    EVENT_BIG_WORLD_PERSPECTIVE_DISABLE = NewId(),
    
    -- 背包更新
    EVENT_BIG_WORLD_BACKPACK_UPDATE = NewId(),

    -- 无人机游戏暂存
    EVENT_SKY_GARDEN_DRONE_GAME_SUSPEND = NewId(),

    -- 无人机游戏关卡刷新
    EVENT_SKY_GARDEN_DRONE_GAME_STAGE_UI_REFRESH = NewId(),

    -- 无人机游戏关卡详情刷新
    EVENT_SKY_GARDEN_DRONE_GAME_STAGE_DETAIL_UI_REFRESH = NewId(),

    -- 无人机切换关卡完成
    EVENT_SKY_GARDEN_DRONE_CHAPTER_SELECT_VIEW_SWITCH_COMPLETE = NewId(),

    -- 无人机按键广播
    EVENT_SKY_GARDEN_DRONE_KEY_PRESS_NOTIFY = NewId(),

    -- 预览视频播放结束
    EVENT_BIG_WORLD_PREVIEW_VIDEO_FINISH = NewId(),

    -- 预览界面关闭
    EVENT_BIG_WORLD_PREVIEW_CLOSE = NewId(),

    -- 商店购买
    EVENT_BIG_WORLD_SHOP_BUY = NewId(),

    -- 提前体验
    EVENT_BIG_WORLD_ADVANCE_UPDATE = NewId(),

    -- 环境角色加载完毕
    EVENT_BIG_WORLD_ECOLOGY_LOAD_COMPLETE = NewId(),
}

return dlcEventId
