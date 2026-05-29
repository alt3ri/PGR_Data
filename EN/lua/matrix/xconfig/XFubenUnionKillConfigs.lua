XFubenUnionKillConfigs = XTool.GetNoneSenseTable()



XFubenUnionKillConfigs.UnionRoomPlayerState = {
    Normal = 0, --正常、未准备
    Ready = 1, --准备
    Select = 2, --编辑队伍
    Fight = 3   --战斗中
}

XFubenUnionKillConfigs.UnionRoomState = {
    Normal = 0,
    Fight = 1, -- 战斗
    Settle = 2, -- 结算
    Close = 3, -- 关闭
}

XFubenUnionKillConfigs.UnionKillStageType = {
    EventStage = 1, -- 事件关
    BossStage = 2, -- boss关
    TrialStage = 3, -- 试炼关
}
XFubenUnionKillConfigs.UnionKillCharType = {
    Own = 1, -- 自己拥有标记
    Share = 2, -- 共享角色标记
}
XFubenUnionKillConfigs.UnionRankType = {
    ThumbsUp = 1, -- 点赞排名
    KillNumber = 2                                  -- 歼敌排名
}
XFubenUnionKillConfigs.LeaveReason = {
    LeaveTeam = 1, -- 离开队伍
    LeaveFight = 2, -- 离开战斗
    TimeOver = 3, -- 战斗事件结束
    KickOut = 4, -- 被踢
    Offline = 5, -- 离线
    Logout = 6, -- 登出
}
XFubenUnionKillConfigs.TipsMessageType = {
    Praise = 1, -- 点赞
    FightBrrow = 2, -- 我借用了玩家的xxx,
    ResultBorrow = 3, -- 点赞
    LeaveStage = 4, -- 离开关卡
}

XFubenUnionKillConfigs.ActivityChangeType = {
    None = 0,
    ActivityOpen = 1, -- 活动开启
    ActivityClose = 2, -- 活动结束
    SectionChange = 3, -- 章节改变
    WeatherChange = 4, -- 天气改变
}

XFubenUnionKillConfigs.NotShowToday = "UnionKillTipsNotShowToday"
XFubenUnionKillConfigs.FirstShowHelp = "UnionKillTipsFirstShowHelp"

XFubenUnionKillConfigs.MaxTeamCount = 4             -- 队伍人数
XFubenUnionKillConfigs.MaxCharacterCount = 3        -- 出站人数
XFubenUnionKillConfigs.PraiseInterval = CS.XGame.ClientConfig:GetInt("UnionPraiseInterval")          -- 点赞界面倒计时
XFubenUnionKillConfigs.RankRequestInterval = CS.XGame.ClientConfig:GetInt("UnionRankRequestInterval")     -- 排名请求间隔
XFubenUnionKillConfigs.AllReadyCount = CS.XGame.ClientConfig:GetInt("UnionAllReadyInterval")

-- 测试用-以后改为读表
XFubenUnionKillConfigs.PraiseWords = "UnionTipPraise"
-- 类型1， 0对应参数PlayerId, 1对应CharacterId
XFubenUnionKillConfigs.FightBorrowMine = "UnionTipsFightBorrow"
XFubenUnionKillConfigs.FightBorrowOthers = "UnionTipsBorrowOthers"
-- 类型2, playerId对应是谁说的话，ShareCharacterInfos对应用了哪个角色
XFubenUnionKillConfigs.RefreshHighestPoint = "UnionTipHighestPoint"
-- 类型3， 0对应PlyaerId
--local DefaultActivityId = 0