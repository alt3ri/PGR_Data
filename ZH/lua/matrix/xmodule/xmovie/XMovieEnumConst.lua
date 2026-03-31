local XMovieEnumConst = {
    -- spine的组成部位名称
    SPINE_PART_NAME = {
        ROLE = "Role",
        BODY = "Body",
        KOU = "Kou",
    },
    -- 剧情跳过类型
    SkipType = {
        OnlyTips = 1, -- 仅跳过提示
        Summary = 2, -- 带剧情梗概
    },
    -- 自动播放辅助点击，key为ActionType，value为时间间隔毫秒
    -- 支持不同的ActionType自定义延迟时间。支持配置节点忽略辅助点击(value不为number类型)
    AUTO_PLAY_CLICK_ACTION = {
        ["DEFAULT"] = 2000, -- 默认间隔时间
        [301] = "Ignore", -- 此节点的对话自己实现了自动播放逻辑，忽略辅助点击
    },
    -- Action对应的TypeId
    ACTION_TYPE = {
        BG_SWITCH = 101,                -- 背景图切换
        THEME = 102,                    -- 主题节点
        SPINE_LOAD = 105,               -- spine加载
        SPINE_PLAY_ANIM = 106,          -- spine播放动画
        LEFT_TITLE_APPEAR = 107,        -- 左边标题出现
        LEFT_TITLE_DISAPPEAR = 108,     -- 左边标题消失
        TEXT_APPEAR = 109,              -- 文本出现
        TEXT_DISAPPEAR = 110,           -- 文本消失

        ACTOR_APPEAR = 201,             -- 演员出现
        ACTOR_DISAPPEAR = 202,          -- 演员消失
        ACTOR_SHIFT = 203,              -- 演员位移
        ACTOR_CHANGE_FACE = 204,        -- 演员切换表情
        ACTOR_CHANGE_ALPHA = 205,       -- 演员切换背景
        SPINE_APPEAR = 211,             -- Spine出现
        SPINE_DISAPPEAR = 212,          -- Spine消失
        SPINE_SHIFT = 213,              -- Spine位移
        SPINE_CHANGE_ANIM = 214,        -- Spine切换动画
        SPINE_ANIMATION_PLAY = 215,     -- Spine动画播放
        
        DIALOG = 301,                   -- 对话
        SELECTION = 302,                -- 选择分支对话
        SELECTION_DELAY_SKIP = 303,     -- 选择分支延迟跳转
        AUTO_SKIP = 308,                -- 自动跳转节点

        AUDIO_PLAY = 401,               -- 音频播放
        AUDIO_INTERRUPT = 402,          -- 音频中断
        
        EFFECT_PLAY = 501,              -- 特效播放
        EFFECT_UNLOAD = 505,            -- 特效卸载
        TIP_APPEAR = 507,               -- 横幅显示
        TIP_DISAPPEAR = 508,            -- 横幅消失
        INSERT_PANEL_SHOW = 509,        -- 插入分屏显示
        INSERT_PANEL_HIDE = 510,        -- 插入分屏隐藏
        ANIMATION_PLAY = 502,           -- 动画播放
    },
    -- 特效类型
    EFFECT_TYPE = {
        SCREENSHOT = 1,                 -- 屏幕截图特效类型
    },
    -- 动画
    ANIMATION = {
        THEME_ENABLE = "ThemeEnable",   -- 主题启用动画
    },
    -- 长按进入自动播放的时间
    LONG_PRESS_ENTER_AUTO_PLAY_TIME = 1,
    -- 播放速度
    DEFAULT_SPEED = 1,                  -- 默认速度
    LONG_PRESS_SPEED = 32,              -- 长按自动播放速度
    -- 锚点对齐类型
    ANCHOR_ALIGNMENT_TYPE = {
        FULL = 0,                       -- 全部撑开
        TOP_LEFT = 1,                   -- 左上角
        TOP_CENTER = 2,                 -- 上中
        TOP_RIGHT = 3,                  -- 右上角
        MIDDLE_LEFT = 4,                -- 中左
        MIDDLE = 5,                     -- 中心点
        MIDDLE_RIGHT = 6,               -- 中右
        BOTTOM_LEFT = 7,                -- 左下角
        BOTTOM_CENTER = 8,              -- 下中
        BOTTOM_RIGHT = 9,               -- 右下角
        FULL_DISABLE_ADAPTER = 10,      -- 全部撑开，且禁用适配
    },
    -- 锚点对齐类型对应参数 (anchorMinX, anchorMinY, anchorMaxX, anchorMaxY)
    ANCHOR_ALIGNMENT_TYPE_TO_PARAM = {
        [0] = {0, 0, 1, 1},             -- FULL: 全部撑开
        [1] = {0, 1, 0, 1},             -- TOP_LEFT: 左上角
        [2] = {0.5, 1, 0.5, 1},         -- TOP_CENTER: 上中
        [3] = {1, 1, 1, 1},             -- TOP_RIGHT: 右上角
        [4] = {0, 0.5, 0, 0.5},         -- MIDDLE_LEFT: 中左
        [5] = {0.5, 0.5, 0.5, 0.5},     -- MIDDLE: 中心点
        [6] = {1, 0.5, 1, 0.5},         -- MIDDLE_RIGHT: 中右
        [7] = {0, 0, 0, 0},             -- BOTTOM_LEFT: 左下角
        [8] = {0.5, 0, 0.5, 0},         -- BOTTOM_CENTER: 下中
        [9] = {1, 0, 1, 0},             -- BOTTOM_RIGHT: 右下角
        [10] = {0, 0, 1, 1},            -- FULL_DISABLE_ADAPTER: 全部撑开，且禁用适配
    },
    ACTOR_AVATAR_INDEX = 18,            -- 第18号演员为左下角头像位置
    -- 按键映射Id
    SELECTION_KEY_MAP_IDS = { 161, 162, 163, 164 },
}

function XMovieEnumConst:GetActionClass(actionType)
    self.ACTION_CLASS = self.ACTION_CLASS or {
        [101] = require("XMovieActions/XMovieActionBgSwitch"), --背景切换
        [102] = require("XMovieActions/XMovieActionTheme"), --章节主题
        [103] = require("XMovieActions/XMovieActionBgScale"), --背景缩放位置调整
        [104] = require("XMovieActions/XMovieActionBgMoveAnimation"), --背景位移动画
        [105] = require("XMovieActions/XMovieActionSpineAnim"), --Spine动画加载
        [106] = require("XMovieActions/XMovieActionPlaySpineAnim"), --Spine动画播放
        [107] = require("XMovieActions/XMovieActionLeftTitleAppear"), --左边标题出现
        [108] = require("XMovieActions/XMovieActionLeftTitleDisappear"), --左边标题消失
        [109] = require("XMovieActions/XMovieActionTextAppear"), -- 文本出现
        [110] = require("XMovieActions/XMovieActionTextDisAppear"), -- 文本消失
        [111] = require("XMovieActions/XMovieActionBgEffect"), -- 背景特效
        [112] = require("XMovieActions/XMovieActionTextAnim"), -- 文本动画
        [113] = require("XMovieActions/XMovieActionBgRotate"), --背景旋转
        [114] = require("XMovieActions/XMovieActionBgGroup"), --背景组
        [115] = require("XMovieActions/XMovieActionBgShake"), --抖动

        [201] = require("XMovieActions/XMovieActionActorAppear"), --演员出现
        [202] = require("XMovieActions/XMovieActionActorDisappear"), --演员消失
        [203] = require("XMovieActions/XMovieActionActorShift"), --演员位移
        [204] = require("XMovieActions/XMovieActionActorChangeFace"), --演员表情
        [205] = require("XMovieActions/XMovieActionActorAlphaChange"), --演员背景
        [211] = require("XMovieActions/XMovieActionSpineActorAppear"), --spine演员出现
        [212] = require("XMovieActions/XMovieActionSpineActorDisappear"), --spine演员消失
        [213] = require("XMovieActions/XMovieActionSpineActorShift"), --spine演员位移
        [214] = require("XMovieActions/XMovieActionSpineActorChangeAnim"), --spine演员切换动画
        [215] = require("XMovieActions/XMovieActionSpineActorAnimationPlay"), --spine演员预置的UI动画播放

        [301] = require("XMovieActions/XMovieActionDialog"), --普通对话
        [302] = require("XMovieActions/XMovieActionSelection"), --选择分支对话
        [303] = require("XMovieActions/XMovieActionDelaySkip"), --延迟跳转
        [304] = require("XMovieActions/XMovieActionFullScreenDialog"), --全屏字幕
        [305] = require("XMovieActions/XMovieActionYieldResume"), --挂起/恢复
        [306] = require("XMovieActions/XMovieActionRoleMask"), --上下遮罩动画
        [307] = require("XMovieActions/XMovieActionCenterTips"), --居中提示文本
        [308] = require("XMovieActions/XMovieActionAutoSkip"), --自动跳转节点
        [309] = require("XMovieActions/XMovieActionAddReview"), --增加回顾记录
        [310] = require("XMovieActions/XMovieActionFullScreenDialogNew"), -- 新全屏字幕

        [401] = require("XMovieActions/XMovieActionSoundPlay"), --BGM/CV/音效 播放
        [402] = require("XMovieActions/XMovieActionAudioInterrupt"), --BGM/CV/音效 打断

        [501] = require("XMovieActions/XMovieActionEffectPlay"), --特效播放
        [502] = require("XMovieActions/XMovieActionAnimationPlay"), --UI动画播放
        [503] = require("XMovieActions/XMovieActionVideoPlay"), --视频播放
        [504] = require("XMovieActions/XMovieActionSetGray"), --灰度设置
        [505] = require("XMovieActions/XMovieActionUnLoad"), --动效卸载
        [506] = require("XMovieActions/XMovieActionPrefabAnimation"), --预制体动画
        [507] = require("XMovieActions/XMovieActionInsertTipAppear"), --中间插入横幅
        [508] = require("XMovieActions/XMovieActionInsertTipDisappear"), --中间横幅消失
        [509] = require("XMovieActions/XMovieActionShowInsertPanel"), --显示两边插入分屏
        [510] = require("XMovieActions/XMovieActionHideInsertPanel"), --隐藏插入分屏
        [511] = require("XMovieActions/XMovieActionEffectMove"), --特效位移

        [601] = require("XMovieActions/XMovieActionStaff"), --staff职员表

        --3D剧情相关
        [701] = require("XMovieActions/XMovieActionSceneLoad"), --场景加载
        [702] = require("XMovieActions/XMovieActionCameraLoad"), --摄像头加载
        [703] = require("XMovieActions/XMovieActionCameraPlay"), --播放相机动画
        [704] = require("XMovieActions/XMovieActionActorLoad"), --角色模型加载
        [705] = require("XMovieActions/XMovieActionModelMove"), --角色移动
        [706] = require("XMovieActions/XMovieActionSetActorTransform"), --设置角色位置
        [707] = require("XMovieActions/XMovieActionModelAnimationPlay"), --角色动画播放
        [708] = require("XMovieActions/XMovieActionDialog3D"), --3D剧情对话框
        [709] = require("XMovieActions/XMovieActionTimelineLoad"), --Timeline动画预制体加载
        [710] = require("XMovieActions/XMovieActionTimelinePlay"), --Timeline动画播放
        [711] = require("XMovieActions/XMovieActionPlayCV"), --播放角色语音
        [712] = require("XMovieActions/XMovieActionSwitchMixMode"), --切换2D与3D混合模式
        [713] = require("XMovieActions/XMovieActionSetBg"), --设置混合模式背景图片
    }
    
    return self.ACTION_CLASS[actionType]
end

return XMovieEnumConst
