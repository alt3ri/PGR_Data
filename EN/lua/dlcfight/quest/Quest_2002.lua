local QuestBase = require("Common/XQuestBase")
---@class XQuestScript2002
local Quest_2002 = XDlcScriptManager.RegQuestScript(2002, "XQuestScript2002", QuestBase)

function Quest_2002:Ctor()
end

function Quest_2002:Init()
end

function Quest_2002:Terminate()
end

--================================================
--DLC-任务目标类型：https://kurogame.feishu.cn/docx/TR7AdBehwoWUrrxpV0cc0Wp1nxf

---@class Quest2002Objective
local Quest2002Objective = XClass(nil, "Quest2002Objective")

---@param quest XQuestScript2002
function Quest2002Objective:Ctor(quest)
    self.quest = quest
end

local emptyVector3 = { x = 0, y = 0, z = 0 }

local ObjectiveDefines = {}
--不用数字key，是为了能在IDEA的structure视图中识别这里的table结构，方便快速跳转

--播放露西亚与指挥官剧情对话
---@class QuestObjective2002014 : Quest2002Objective
ObjectiveDefines.Obj2002014 = {
    Id = 2002014,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4001,
        DramaName = "Drama_200203",
    },
    ---@param obj QuestObjective2002014
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,

    ---@param obj QuestObjective2002014
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:AddTimerTask(1, function()
            proxy:PlayDramaCaption("Caption200201") --播放简易字幕
        end)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--前往锚点处导航点
---@class QuestObjective2002015 : Quest2002Objective
ObjectiveDefines.Obj2002015 = {
    Id = 2002015,
    Type = EQuestObjectiveType.ReachTargetPosition,
    Args = {
        LevelId = 4001,
        TracePosArgs = {
            {
                Position = { x = 560.59, y = 143.97, z = 1342.72 },     -- 目标位置（初始为空，后续需要赋值）
                DisplayOffset = { x = 0, y = 1.3, z = 0 }, -- 显示偏移量
                ShowEffect = false,                      -- 是否显示特效
                ForceMapPinActive = false,               -- 是否强制激活地图标记
            },                                           -- 这里加上逗号，方便后续扩展
        },
        TargetPosition = { x = 560.59, y = 143.97, z = 1342.72 },               -- 后续替换为锚点坐标
        ReachDistance = 5,                               -- 到达锚点2米范围内
    },
    ---@param obj QuestObjective2002015
    ---@param proxy XDlcCSharpFuncs
    InitFunc = function(obj, proxy)
    end,
    ---@param obj QuestObjective2002015
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:UnderTakeSelfQuest()
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective2002015
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}


--这里填识别是否激活锚点 ，然后ID给系统用来播放锚点引导弹窗
---@class QuestObjective2002016 : Quest2002Objective
ObjectiveDefines.Obj2002016 = {
    Id = 2002016,
    Type = EQuestObjectiveType.CheckRimSystemCondition,
    Args = {
        LevelId = 4001,
        ConditionIds = { 50010046 },
    },
    ---@param obj QuestObjective2002016
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective2002016
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)

        proxy:FinishQuestObjectiveScriptExit()
    end,
}

--这里识别锚点弹窗是否已关闭
---@class QuestObjective2002017 : Quest2002Objective
ObjectiveDefines.Obj2002017 = {
    Id = 2002017,
    Type = EQuestObjectiveType.CheckRimSystemCondition,
    Args = {
        LevelId = 4001,
        ConditionIds = { 50010046 },
    },
    ---@param obj QuestObjective2002017
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective2002017
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--识别地图引导已完成
---@class QuestObjective2002018 : Quest2002Objective
ObjectiveDefines.Obj2002018 = {
    Id = 2002018,
    Type = EQuestObjectiveType.CheckRimSystemCondition,
    Args = {
        LevelId = 4001,
        ConditionIds = { 50010012 },
    },
    ---@param obj QuestObjective2002018
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective2002018
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}

--阅读比安卡发来的短信
---@class QuestObjective2002027 : Quest2002Objective
ObjectiveDefines.Obj2002027 = {
    Id = 2002027,
    Type = EQuestObjectiveType.ReadShortMessageComplete,
    Args = {
        LevelId = 4001,
        ShortMessageId = 200201,
        AutoSend = true, --enter时，自动发送短信
    },
    ---@param obj QuestObjective2002027
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)

        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective2002027
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--阅读完短信和露西亚对话
---@class QuestObjective2002028 : Quest2002Objective
ObjectiveDefines.Obj2002028 = {
    Id = 2002028,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4001,
        DramaName = "Drama_200204",
    },
    ---@param obj QuestObjective2002028
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,

    ---@param obj QuestObjective2002028
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:LoadLevelNpc( 700005 )
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--路过宝箱 提示通过廊桥
---@class QuestObjective2002029 : Quest2002Objective
ObjectiveDefines.Obj2002029 = {
    Id = 2002029,
    Type = EQuestObjectiveType.ReachTargetPosition,
    Args = {
        LevelId = 4001,
        TracePosArgs = {
            {
                Position = { x = 581.193, y = 144.82, z = 1334.65  },     -- 目标位置（初始为空，后续需要赋值）
                DisplayOffset = { x = 0, y = 1.3, z = 0 }, -- 显示偏移量
                ShowEffect = true,                      -- 是否显示特效
                ForceMapPinActive = false,               -- 是否强制激活地图标记
            },                                           -- 这里加上逗号，方便后续扩展
        },
        TargetPosition = { x = 581.193, y = 144.82, z = 1334.65 },               -- 路中间坐标，宝箱在边上
        ReachDistance = 15,                               -- 到达宝箱附近 必经之路
    },
    ---@param obj QuestObjective2002029
    ---@param proxy XDlcCSharpFuncs
    InitFunc = function(obj, proxy)
    end,
    ---@param obj QuestObjective2002029
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective2002029
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:ShowBigWorldTeach( 1040 )   --添加宝箱图文引导初版
        proxy:FinishQuestObjectiveScriptExit()
    end,
}

--到达与薇拉交互的地点
---@class QuestObjective2002032 : Quest2002Objective
ObjectiveDefines.Obj2002032 = {
    Id = 2002032,
    Type = EQuestObjectiveType.InteractComplete,
    Args = {
        LevelId = 4001,
        TraceActorArgs = {
            {
                TargetType = ETargetActorType.Npc,
                PlaceId = 700005, --活动人员
                DisplayOffset = { x = 0, y = 2, z = 0 },
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        TargetArgs = {
            [ETargetActorType.Npc] = {
                [700005] = 0, --露西亚
            },
        },
    },
    ---@param obj QuestObjective2002032
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:PlayDramaCaption("Caption200205",true)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective2002032
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--播放薇拉与指挥官得聊天剧情
---@class QuestObjective2002033 : Quest2002Objective
ObjectiveDefines.Obj2002033 = {
    Id = 2002033,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4001,
        DramaName = "Drama_200205",
        
    },
    ---@param obj QuestObjective2002033
    ---@param proxy XDlcCSharpFuncs
    InitFunc = function(obj, proxy)
    end,
    ---@param obj QuestObjective2002033
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective2002033
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:UnloadLevelNpc( 700005 )
        proxy:AddTimerTask(0.5, function()
            proxy:PlayDramaCaption("Caption200204") --播放简易字幕
        end)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--前往露天广场传送点
---@class QuestObjective2002034 : Quest2002Objective
ObjectiveDefines.Obj2002034 = {
    Id = 2002034,
    Type = EQuestObjectiveType.InteractComplete,
    Args = {
        LevelId = 4001,
        TraceActorArgs = {
            {
                TargetType = ETargetActorType.SceneObject,
                PlaceId = 100066,
                DisplayOffset = { x = 0, y = 0.5, z = 0 },
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        TargetArgs = {
            [ETargetActorType.SceneObject] = {
                [100066] = 0,
            },
        },
    },
    ---@param obj QuestObjective2002034
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective2002034
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}

--前往咖啡厅的中途导航点
---@class QuestObjective2002046 : Quest2002Objective
ObjectiveDefines.Obj2002046 = {
    Id = 2002046,
    Type = EQuestObjectiveType.ReachTargetPosition,
    Args = {
        LevelId = 4001,
        TracePosArgs = {
            {
                Position = { x = 649.17, y = 192.75, z = 1242.35 },                 -- 目标位置（初始为空，后续需要赋值）
                DisplayOffset = { x = 0, y = 0.3, z = 0 }, -- 显示偏移量
                ShowEffect = true,                      -- 是否显示特效
                ForceMapPinActive = false,               -- 是否强制激活地图标记
            },                                           -- 这里加上逗号，方便后续扩展
        },
        TargetPosition = { x = 649.17, y = 192.75, z = 1242.35 },                   -- 后续替换为锚点坐标
        ReachDistance = 10,                               -- 到达锚点3米范围内
    },
    ---@param obj QuestObjective2002046
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective2002046
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:PlayDramaCaption("Caption200206") --播放简易字幕
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--前往咖啡厅的中途导航点
---@class QuestObjective2002047 : Quest2002Objective
ObjectiveDefines.Obj2002047 = {
    Id = 2002047,
    Type = EQuestObjectiveType.ReachTargetPosition,
    Args = {
        LevelId = 4001,
        TracePosArgs = {
            {
                Position = { x = 648.09, y = 187.55, z = 1185.57 },                 -- 目标位置（初始为空，后续需要赋值）
                DisplayOffset = { x = 0, y = 0.3, z = 0 }, -- 显示偏移量
                ShowEffect = true,                      -- 是否显示特效
                ForceMapPinActive = false,               -- 是否强制激活地图标记
            },                                           -- 这里加上逗号，方便后续扩展
        },
        TargetPosition = { x = 648.09, y = 187.55, z = 1185.57 },                   -- 后续替换为锚点坐标
        ReachDistance = 10,                               -- 到达锚点2米范围内
    },
    ---@param obj QuestObjective2002047
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective2002047
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--前往咖啡厅的中途导航点
---@class QuestObjective2002048 : Quest2002Objective
ObjectiveDefines.Obj2002048 = {
    Id = 2002048,
    Type = EQuestObjectiveType.ReachTargetPosition,
    Args = {
        LevelId = 4001,
        TracePosArgs = {
            {
                Position = { x = 574.94, y = 185.2567, z = 1156.24 },                 -- 目标位置（初始为空，后续需要赋值）
                DisplayOffset = { x = 0, y = 0.3, z = 0 }, -- 显示偏移量
                ShowEffect = true,                      -- 是否显示特效
                ForceMapPinActive = false,               -- 是否强制激活地图标记
            },                                           -- 这里加上逗号，方便后续扩展
        },
        TargetPosition = { x = 574.94, y = 185.2567, z = 1156.24},                   -- 后续替换为锚点坐标
        ReachDistance = 10,                               -- 到达锚点3米范围内
    },
    ---@param obj QuestObjective2002048
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective2002048
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:PlayDramaCaption("Caption200207") --播放简易字幕
        proxy:LoadLevelNpc( 700003 )                 --***********生成卡列
        proxy:FinishQuestObjectiveScriptExit()
    end,
}


--与丽芙交互
---@class QuestObjective2002036 : Quest2002Objective
ObjectiveDefines.Obj2002036 = {
    Id = 2002036,
    Type = EQuestObjectiveType.InteractComplete,
    Args = {
        LevelId = 4001,
        TraceActorArgs = {
            {
                TargetType = ETargetActorType.Npc,
                PlaceId = 700003, --卡列
                DisplayOffset = { x = 0, y = 2, z = 0 },
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        TargetArgs = {
            [ETargetActorType.Npc] = {
                [700003] = 0, --露西亚
            },
        },
    },
    ---@param obj QuestObjective2002036
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective2002036
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}

--播放与丽芙得剧情对话
---@class QuestObjective2002037 : Quest2002Objective
ObjectiveDefines.Obj2002037 = {
    Id = 2002037,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4001,
        DramaName = "Drama_200206",
        
    },
    ---@param obj QuestObjective2002037
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective2002037
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:UnloadLevelNpc( 700003 )
        --*****************************************************************开启咖啡厅玩法面板教学
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--前往活动地点
---@class QuestObjective2002049 : Quest2002Objective
ObjectiveDefines.Obj2002049 = {
    Id = 2002049,
    Type = EQuestObjectiveType.ReachTargetPosition,
    Args = {
        LevelId = 4001,
        TracePosArgs = {
            {
                Position = { x = 559.098, y = 169.451, z = 1167.622 },                 -- 目标位置（初始为空，后续需要赋值）
                DisplayOffset = { x = 0, y = 0.3, z = 0 }, -- 显示偏移量
                ShowEffect = true,                      -- 是否显示特效
                ForceMapPinActive = false,               -- 是否强制激活地图标记
            },                                           -- 这里加上逗号，方便后续扩展
        },
        TargetPosition = { x = 559.098, y = 169.451, z = 1167.622 },                   -- 后续替换为锚点坐标
        ReachDistance = 3,                               -- 到达锚点2米范围内
    },
    ---@param obj QuestObjective2002049
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective2002049
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}

--播放黑屏白字表示活动已参加
---@class QuestObjective2002038 : Quest2002Objective
ObjectiveDefines.Obj2002038 = {
    Id = 2002038,
    Type = EQuestObjectiveType.CheckRimSystemCondition,
    Args = {
        LevelId = 4001,
        ConditionIds = { 50010046 },
    },
    ---@param obj QuestObjective2002038
    ---@param proxy XDlcCSharpFuncs
    InitFunc = function(obj, proxy)
    end,
    ---@param obj QuestObjective2002038
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective2002038
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}

--播放与卡列三人得剧情对话
---@class QuestObjective2002040 : Quest2002Objective
ObjectiveDefines.Obj2002040 = {
    Id = 2002040,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4001,
        DramaName = "Drama_200207",
        
    },
    ---@param obj QuestObjective2002040
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,

    ---@param obj QuestObjective2002040
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        --proxy:ShowBigWorldTeach( 2 )                             --先关闭咖啡厅玩法弹窗 先用草稿版代替
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--识别历程日志引导已完成
---@class QuestObjective2002039 : Quest2002Objective
ObjectiveDefines.Obj2002039 = {
    Id = 2002039,
    Type = EQuestObjectiveType.CheckRimSystemCondition,
    Args = {
        LevelId = 4001,
        ConditionIds = { 50010000 },
    },
    ---@param obj QuestObjective2002039
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective2002039
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:TryActiveSystemGuide()     --尝试触发历程日志引导
        proxy:FinishQuestObjectiveScriptExit()
    end,
}

--空条件 这一步也用来发放咖啡厅任务
---@class QuestObjective2002041 : Quest2002Objective
ObjectiveDefines.Obj2002041 = {
    Id = 2002041,
    Type = EQuestObjectiveType.CheckRimSystemCondition,
    Args = {
        LevelId = 4001,
        ConditionIds = { 50010046 },
    },
    ---@param obj QuestObjective2002041
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective2002041
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--阅读完短信和露西亚对话，接下来要拍照了。
---@class QuestObjective2002042 : Quest2002Objective
ObjectiveDefines.Obj2002042 = {
    Id = 2002042,
    Type = EQuestObjectiveType.ReadShortMessageComplete,
    Args = {
        LevelId = 4001,
        ShortMessageId = 200202,
        AutoSend = true, --enter时，自动发送短信
    },
    ---@param obj QuestObjective2002042
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective2002042
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--通过楼梯，前往与丽芙汇合
---@class QuestObjective2002050 : Quest2002Objective
ObjectiveDefines.Obj2002050 = {
    Id = 2002050,
    Type = EQuestObjectiveType.ReachTargetPosition,
    Args = {
        LevelId = 4001,
        TracePosArgs = {
            {
                Position = { x = 570.44, y = 171.78, z = 1155.55 },                 -- 目标位置（初始为空，后续需要赋值）
                DisplayOffset = { x = 0, y = 0.3, z = 0 }, -- 显示偏移量
                ShowEffect = true,                      -- 是否显示特效
                ForceMapPinActive = false,               -- 是否强制激活地图标记
            },                                           -- 这里加上逗号，方便后续扩展
        },
        TargetPosition = { x = 570.44, y = 171.78, z = 1155.55 },                   -- 后续替换为锚点坐标
        ReachDistance = 5,                               -- 到达锚点2米范围内
    },
    ---@param obj QuestObjective2002050
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective2002050
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:LoadLevelNpc( 700001 )
        proxy:FinishQuestObjectiveScriptExit()
    end,
}

--与露天广场露西亚交互
---@class QuestObjective2002043 : Quest2002Objective
ObjectiveDefines.Obj2002043 = {
    Id = 2002043,
    Type = EQuestObjectiveType.InteractComplete,
    Args = {
        LevelId = 4001,
        TraceActorArgs = {
            {
                TargetType = ETargetActorType.Npc,
                PlaceId = 700001, --露西亚
                DisplayOffset = { x = 0, y = 1.5, z = 0 },
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        TargetArgs = {
            [ETargetActorType.Npc] = {
                [700001] = 0, --露西亚
            },
        },
    },
    ---@param obj QuestObjective2002043
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective2002043
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}

--播放与露西亚得剧情对话 对话完黑屏设置下位置
---@class QuestObjective2002044 : Quest2002Objective
ObjectiveDefines.Obj2002044 = {
    Id = 2002044,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4001,
        DramaName = "Drama_200208",
    },
    ---@param obj QuestObjective2002044
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,

    ---@param obj QuestObjective2002044
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:UnloadLevelNpc( 700001 )
        proxy:LoadLevelNpc( 700006 )
        proxy:LoadLevelNpc( 700007 )
        proxy:SetNpcPosAndRot( proxy:GetLocalPlayerNpcId(), {x = 606.188, y = 189.3128, z = 1146.596},  {x = 0, y = -55, z = 0}, true )
        proxy:AddTimerTask(0.1, function()
            proxy:ResetCamera(true,180,true) --延迟重置相机
        end)
        proxy:FinishQuestObjectiveScriptExit() --延迟结束
    end,
}

--识别拍照引导已经完成 进入剧情对话
---@class QuestObjective2002045 : Quest2002Objective
ObjectiveDefines.Obj2002045 = {
    Id = 2002045,
    Type = EQuestObjectiveType.CheckRimSystemCondition,
    Args = {
        LevelId = 4001,
        ConditionIds = { 50010011 },
    },
    ---@param obj QuestObjective2002045
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective2002045
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}

--播放与露西亚得剧情对话 对话完给道具就要去宿舍了
---@class QuestObjective2002051 : Quest2002Objective
ObjectiveDefines.Obj2002051 = {
    Id = 2002051,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4001,
        DramaName = "Drama_200209",
    },
    ---@param obj QuestObjective2002051
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective2002051
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
        proxy:UnloadLevelNpc( 700006 )
        proxy:UnloadLevelNpc( 700007 )
    end,
}
--阅读商业街NPC发来得短信。
---@class QuestObjective2002061 : Quest2002Objective
ObjectiveDefines.Obj2002061 = {
    Id = 2002061,
    Type = EQuestObjectiveType.ReadShortMessageComplete,
    Args = {
        LevelId = 4003,
        ShortMessageId = 200203,
        AutoSend = true, --enter时，自动发送短信
    },
    ---@param obj QuestObjective2002061
    ---@param proxy XDlcCSharpFuncs
    InitFunc = function(obj, proxy)
    end,
    ---@param obj QuestObjective2002061
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective2002061
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:PlayDramaCaption("Caption200101") --播放简易字幕
        proxy:AddTimerTask(3, function()
            proxy:FinishQuestObjectiveScriptExit() --延迟结束
        end)
    end,
}
--到达宿舍
---@class QuestObjective2002052 : Quest2002Objective
ObjectiveDefines.Obj2002052 = {
    Id = 2002052,
    Type = EQuestObjectiveType.ReachTargetPosition,
    Args = {
        LevelId = 4003,
        TracePosArgs = {
            {
                Position = { x = 18.43, y = 1.63, z = 17.55 },                 -- 目标位置（初始为空，后续需要赋值）
                DisplayOffset = { x = 0, y = 0.5, z = 0 }, -- 显示偏移量
                ShowEffect = false,                      -- 是否显示特效
                ForceMapPinActive = false,               -- 是否强制激活地图标记
            },                                           -- 这里加上逗号，方便后续扩展
        },
        TargetPosition = { x = 18.43, y = 1.63, z = 17.55 },                   -- 后续替换为摆放点坐标
        ReachDistance = 15,                             -- 到达锚点1.5米范围内
    },
    ---@param obj QuestObjective2002052
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective2002052
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--进入宿舍播放timeline
---@class QuestObjective2002053 : Quest2002Objective
ObjectiveDefines.Obj2002053 = {
    Id = 2002053,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4003,
        DramaName = "Drama_200210",

    },
    ---@param obj QuestObjective2002053
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,

    ---@param obj QuestObjective2002053
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}


--到达家具摆放点与照片墙交互
---@class QuestObjective2002054 : Quest2002Objective
ObjectiveDefines.Obj2002054 = {
    Id = 2002054,
    Type = EQuestObjectiveType.InteractComplete,
    Args = {
        LevelId = 4003,
        TraceActorArgs = {
            {
                TargetType = ETargetActorType.SceneObject,
                PlaceId = 1,
                DisplayOffset = { x = 0, y = 0.5, z = 0 },
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        TargetArgs = {
            [ETargetActorType.SceneObject] = {
                [1] = 0,
            },
        },
    },
    ---@param obj QuestObjective2002054
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective2002054
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}

--识别摆放是否完成  这一步ID给系统用来播图文引导
---@class QuestObjective2002055 : Quest2002Objective
ObjectiveDefines.Obj2002055 = {
    Id = 2002055,
    Type = EQuestObjectiveType.CheckRimSystemCondition,
    Args = {
        LevelId = 4003,
        ConditionIds = { 50010010 },
    },
    ---@param obj QuestObjective2002055
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective2002055
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}

--识别图文引导是否完成
---@class QuestObjective2002056 : Quest2002Objective
ObjectiveDefines.Obj2002056 = {
    Id = 2002056,
    Type = EQuestObjectiveType.CheckRimSystemCondition,
    Args = {
        LevelId = 4003,
        ConditionIds = { 50010046 },
    },
    ---@param obj QuestObjective2002056
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective2002056
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--与床交互
--@class QuestObjective2002062 : Quest2003Objective
ObjectiveDefines.Obj2002062 = {
    Id = 2002062,
    Type = EQuestObjectiveType.InteractComplete,
    Args = {
        LevelId = 4003,
        TraceActorArgs = {
            {
                TargetType = ETargetActorType.SceneObject,
                PlaceId = 400010, --垃圾桶
                DisplayOffset = { x = 0, y = 2.2, z = 0 },
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        TargetArgs = {
            [ETargetActorType.SceneObject] = {
                [400010] = 0,--垃圾桶
            },
        },
    },

    EnterFunc = function(obj, proxy)
        proxy:LoadSceneObject(400010)
        proxy:PlayDramaCaption("Caption200208",true) --播放简易字幕
        proxy:FinishQuestObjectiveScriptEnter()
    end,

    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:UnloadSceneObject(400010)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--播放上床休息剧情
---@class QuestObjective2002063 : Quest2002Objective
ObjectiveDefines.Obj2002063 = {
    Id = 2002063,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4003,
        DramaName = "Drama_200211",
    },
    ---@param obj QuestObjective2002063
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,

    ---@param obj QuestObjective2002063
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
local StepDefines = {} --本任务包含的所有任务步骤的参数配置（不要删除！）

--Step的参数配置，至少要有一个，可按需增加
StepDefines.Step200201 = {
    Id = 200201,
    ExecMode = EQuestStepExecMode.Serial,
}
StepDefines.Step200202 = {
    Id = 200202,
    ExecMode = EQuestStepExecMode.Serial,
}

QuestBase.InitSteps(StepDefines) --固定的任务步骤数据初始化调用（不要删除！）
QuestBase.InitQuestObjectives(Quest2002Objective, ObjectiveDefines) --固定的任务目标数据初始化调用（不要删除！）

return Quest_2002
