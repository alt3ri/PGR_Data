local XPokerGuessing2Enum = {
    State = {
        GameWin = 3,
        GameLose = 4,
        RoundWin = 5,
        RoundLose = 6,
        RoundDraw = 7,
    },
    Speak = {
        -- 服务器定义的
        GameWin = 3,
        GameLose = 4,
        RoundWin = 5,
        RoundLose = 6,
        RoundDraw = 7, -- 回合平局
        -- 客户端自定义的
        RoundStart = 101,
        PlayerCardChanged = 102,
        EnemyCardChanged = 103,
    },
    SpeakShowType = {
        Text = 1,
        Emoji = 2,
    },
    RoundState = {
        RoundLose = -1, --回合失败
        RoundDrawn = 0, --回合平局
        RoundWin = 1, --回合胜利
    },
    PokerPlaySide = {
        Player = 1, -- 己方
        Robot = 2, -- 敌方
    },
    ConfigId = { -- 客户端配置表Id枚举
        ItemId = 7,
    }
}
return XPokerGuessing2Enum