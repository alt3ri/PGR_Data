local QuestBase = require("Common/XQuestBase")
---@class XQuestScript1001
local Quest_1001 = XDlcScriptManager.RegQuestScript(1001, "XQuestScript1001", QuestBase)
function Quest_1001:Ctor()
end

function Quest_1001:Init()
end

function Quest_1001:Terminate()
end

--================================================
--DLC-任务目标类型：https://kurogame.feishu.cn/docx/TR7AdBehwoWUrrxpV0cc0Wp1nxf

---@class Quest1001Objective
local Quest1001Objective = XClass(nil, "Quest1001Objective")

---@param quest XQuestScript1001
function Quest1001Objective:Ctor(quest)
    self.quest = quest
end

local emptyVector3 = { x = 0, y = 0, z = 0 }

local ObjectiveDefines = {}
--不用数字key，是为了能在IDEA的structure视图中识别这里的table结构，方便快速跳转
--1.阅读露西亚发来的短信
---@class QuestObjective10010101 : Quest1001Objective
ObjectiveDefines.Obj10010101 = {
    Id = 10010101,
    Type = EQuestObjectiveType.ReadShortMessageComplete,
    Args = {
        LevelId = 4001,
        ShortMessageId = 100101,-------短信id
        AutoSend = true, --enter时，自动发送短信
    },
    ---@param obj QuestObjective10010101
    ---@param proxy XDlcCSharpFuncs
    InitFunc = function(obj, proxy)
    end,
    ---@param obj QuestObjective10010101
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective10010101
    ---@param proxy XDlcCSharpFuncs
    HandleEventFunc = function(obj, proxy, eventType, eventArgs)
    end,
    ---@param obj QuestObjective10010101
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--2.到达宿舍
---@class QuestObjective10010102 : Quest1001Objective
ObjectiveDefines.Obj10010102 = {
    Id = 10010102,
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
    ---@param obj QuestObjective10010102
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective10010102
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:AddTimerTask(1.5, function()
            proxy:PlayDramaCaption("Caption100101") --播放简易字幕
        end)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--3.拿电影券
---@class QuestObjective10010103 : Quest1001Objective
ObjectiveDefines.Obj10010103 = {
    Id = 10010103,
    Type = EQuestObjectiveType.InteractComplete,
    Args = {
        LevelId = 4003,
        TraceActorArgs = {
            {
                TargetType = ETargetActorType.SceneObject,
                PlaceId = 400001,
                DisplayOffset = { x = 0, y = 0.5, z = 0 },
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        TargetArgs = {
            [ETargetActorType.SceneObject] = {
                [400001] = 0,--电影券
            },
        },
    },
    ---@param obj QuestObjective10010103
    InitFunc = function(obj)
        obj.soRabbitCakePID = 400001
    end,
    ---@param obj QuestObjective10010103
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:LoadSceneObject(obj.soRabbitCakePID)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective10010103
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:UnloadSceneObject(obj.soRabbitCakePID)
        proxy:PlayDramaCaption("Caption100102") --播放简易字幕
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--4.发现有四叶草
---@class QuestObjective10010104 : Quest1001Objective
ObjectiveDefines.Obj10010104 = {
    Id = 10010104,
    Type = EQuestObjectiveType.InteractComplete,
    Args = {
        LevelId = 4003,
        TraceActorArgs = {
            {
                TargetType = ETargetActorType.SceneObject,
                PlaceId = 400002,
                DisplayOffset = { x = 0, y = 0.5, z = 0 },
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        TargetArgs = {
            [ETargetActorType.SceneObject] = {
                [400002] = 0,--拿四叶草
            },
        },
    },
    ---@param obj QuestObjective10010104
    InitFunc = function(obj)
        obj.soRabbitCakeP1ID = 400002
    end,
    ---@param obj QuestObjective10010104
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:LoadSceneObject(obj.soRabbitCakeP1ID)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective10010104
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:UnloadSceneObject(obj.soRabbitCakeP1ID)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--5.播放A1级动画：陷入循环
---@class QuestObjective10010105 : Quest1001Objective
ObjectiveDefines.Obj10010105 = {
    Id = 10010105,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4003,
        DramaName = "Drama_1001_001",
    },
    ---@param obj QuestObjective10010105
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective10010105
    ---@param proxy XDlcCSharpFuncs
    HandleEventFunc = function(obj, proxy, eventType, eventArgs)
    end,
    ---@param obj QuestObjective10010105
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--6.阅读露西亚发来的循环短信
---@class QuestObjective10010106 : Quest1001Objective
ObjectiveDefines.Obj10010106 = {
    Id = 10010106,
    Type = EQuestObjectiveType.ReadShortMessageComplete,
    Args = {
        LevelId = 4003,
        ShortMessageId = 100102,-------短信id
        AutoSend = true, --enter时，自动发送短信
    },
    ---@param obj QuestObjective10010106
    ---@param proxy XDlcCSharpFuncs
    InitFunc = function(obj, proxy)
    end,
    ---@param obj QuestObjective10010106
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective10010106
    ---@param proxy XDlcCSharpFuncs
    HandleEventFunc = function(obj, proxy, eventType, eventArgs)
    end,
    ---@param obj QuestObjective10010106
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:PlayDramaCaption("Caption100103") --播放简易字幕
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--7.拿走四叶草和露西亚见面
---@class QuestObjective10010107 : Quest1001Objective
ObjectiveDefines.Obj10010107 = {
    Id = 10010107,
    Type = EQuestObjectiveType.InteractComplete,
    Args = {
        LevelId = 4003,
        TraceActorArgs = {
            {
                TargetType = ETargetActorType.SceneObject,
                PlaceId = 400003,
                DisplayOffset = { x = 0, y = 0.5, z = 0 },
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        TargetArgs = {
            [ETargetActorType.SceneObject] = {
                [400003] = 0,--四叶草物件
            },
        },
    },
    ---@param obj QuestObjective10010107
    InitFunc = function(obj)
        obj.soRabbitCakeP2ID = 400003
    end,
    ---@param obj QuestObjective10010107
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:LoadSceneObject(obj.soRabbitCakeP2ID)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective10010107
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:UnloadSceneObject(obj.soRabbitCakeP2ID)
        proxy:PlayDramaCaption("Caption100104") --播放简易字幕
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--8.阅读新闻周刊
---@class QuestObjective10010108 : Quest1001Objective
ObjectiveDefines.Obj10010108 = {
    Id = 10010108,
    Type = EQuestObjectiveType.InteractComplete,
    Args = {
        LevelId = 4003,
        TraceActorArgs = {
            {
                TargetType = ETargetActorType.SceneObject,
                PlaceId = 400004,
                DisplayOffset = { x = 0, y = 0.5, z = 0 },
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        TargetArgs = {
            [ETargetActorType.SceneObject] = {
                [400004] = 0,--新闻周刊
            },
        },
    },
    ---@param obj QuestObjective10010108
    InitFunc = function(obj)
        obj.soRabbitCakeP1ID = 400004
    end,
    ---@param obj QuestObjective10010108
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:LoadSceneObject(obj.soRabbitCakeP1ID)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective10010108
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:UnloadSceneObject(obj.soRabbitCakeP1ID)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--69.关闭叙事UI的判断
---@class QuestObjective10010171 : Quest1001Objective
ObjectiveDefines.obj10010171 = {
    Id = 10010171,
    Type = EQuestObjectiveType.UiClosed,
    Args = {
        LevelId = 4003,
        IntParams = { 1 },
        UiName = "UiBigWorldNarrative"
    },
    ---@param obj QuestObjective10010171
    ---@param proxy StatusSyncFight.XFightScriptProxy
    InitFunc = function(obj, proxy)

    end,
    ---@param obj QuestObjective10010171
    ---@param proxy StatusSyncFight.XFightScriptProxy
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective10010171
    ---@param proxy StatusSyncFight.XFightScriptProxy
    HandleEventFunc = function(obj, proxy, eventType, eventArgs)

    end,
    ---@param obj QuestObjective10010171
    ---@param proxy StatusSyncFight.XFightScriptProxy
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--9.前往DIY衣柜换一件衣服
---@class QuestObjective10010109 : Quest1001Objective
ObjectiveDefines.Obj10010109 = {
    Id = 10010109,
    Type = EQuestObjectiveType.ReachTargetPosition,
    Args = {
        LevelId = 4003,
        TracePosArgs = {
            {
                Position = { x = 10., y = 1.44, z = 15.84 },                 -- 目标位置（初始为空，后续需要赋值）
                DisplayOffset = { x = 0, y = 0.5, z = 0 }, -- 显示偏移量
                ShowEffect = false,                      -- 是否显示特效
                ForceMapPinActive = false,               -- 是否强制激活地图标记
            },                                           -- 这里加上逗号，方便后续扩展
        },
        TargetPosition = { x = 10, y = 1.44, z = 15.84 },                   -- 后续替换为摆放点坐标
        ReachDistance = 15,                             -- 到达锚点1.5米范围内
    },
    ---@param obj QuestObjective10010109
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:AddTimerTask(0.5, function()
            proxy:PlayDramaCaption("Caption100105") --播放简易字幕
        end)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective10010109
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--10.前往时序广场和露西亚见面
---@class QuestObjective10010110 : Quest1001Objective
ObjectiveDefines.Obj10010110 = {
    Id = 10010110,
    Type = EQuestObjectiveType.ReachTargetPosition,
    Args = {
        LevelId = 4001,
        TracePosArgs = {
            {
                Position = { x = 532.99, y = 145.97, z = 1323.71 },                 -- 目标位置（初始为空，后续需要赋值）
                DisplayOffset = { x = 0, y = 0.5, z = 0 }, -- 显示偏移量
                ShowEffect = false,                      -- 是否显示特效
                ForceMapPinActive = false,               -- 是否强制激活地图标记
            },                                           -- 这里加上逗号，方便后续扩展
        },
        TargetPosition = { x = 532.99, y = 145.97, z = 1323.71 },                   -- 后续替换为摆放点坐标
        ReachDistance = 15,                             -- 到达锚点1.5米范围内
    },
    ---@param obj QuestObjective10010110
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective10010110
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--11.播放A1级动画：小露送给指挥官折纸
---@class QuestObjective10010111 : Quest1001Objective
ObjectiveDefines.Obj10010111 = {
    Id = 10010111,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4001,
        DramaName = "Drama_1001_002",
    },
    ---@param obj QuestObjective10010111
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective10010111
    ---@param proxy XDlcCSharpFuncs
    HandleEventFunc = function(obj, proxy, eventType, eventArgs)
    end,
    ---@param obj QuestObjective10010111
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        local uuid4 = proxy:GetLocalPlayerNpcId()
        --XScriptTool.DoTeleportNpcPosAndRotWithBlackScreen(proxy, uuid4, { x = 672.39, y = 167.99, z = 1158.134 }, { x = 0, y = 90, z = 0 }, 0.1)
        --proxy:SetNpcPosition(uuid4, { x = 672.39, y = 167.99, z = 1158.134 }, false)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--12.前往VR体验店的位置
---@class QuestObjective10010112 : Quest1001Objective
ObjectiveDefines.Obj10010112 = {
    Id = 10010112,
    Type = EQuestObjectiveType.ReachTargetPosition,
    Args = {
        LevelId = 4001,
        TracePosArgs = {
            {
                Position = { x = 673.11, y = 167.99, z = 1144.16 },                 -- 目标位置（初始为空，后续需要赋值）
                DisplayOffset = { x = 0, y = 0.5, z = 0 }, -- 显示偏移量
                ShowEffect = false,                      -- 是否显示特效
                ForceMapPinActive = false,               -- 是否强制激活地图标记
            },                                           -- 这里加上逗号，方便后续扩展
        },
        TargetPosition = { x = 673.11, y = 167.99, z = 1144.161 },                   -- 后续替换为摆放点坐标
        ReachDistance = 15,                             -- 到达锚点1.5米范围内
    },
    ---@param obj QuestObjective10010112
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective10010112
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--13.播放B1级动画：介绍心跳回忆装置
---@class QuestObjective10010113 : Quest1001Objective
ObjectiveDefines.Obj10010113 = {
    Id = 10010113,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4001,
        DramaName = "Drama_1001_003",
    },
    ---@param obj QuestObjective10010113
    InitFunc = function(obj)
        obj.soRabbitCakeP10ID = 900001
    end,
    ---@param obj QuestObjective10010113
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
        proxy:LoadSceneObject(obj.soRabbitCakeP10ID)
    end,
    ---@param obj QuestObjective10010113
    ---@param proxy XDlcCSharpFuncs
    HandleEventFunc = function(obj, proxy, eventType, eventArgs)
    end,
    ---@param obj QuestObjective10010113
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:RequestEnterInstLevel(4011, { x = 20.9339, y = 56.59, z = 40.44 } )
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--14.通过装置进入阿呆蛙副本
---@class QuestObjective10010114 : Quest1001Objective
ObjectiveDefines.Obj10010114 = {
    Id = 10010114,
    Type = EQuestObjectiveType.InstanceComplete,
    Args = {
        LevelId = 4001,
        TraceActorArgs = {
            {
                TargetType = ETargetActorType.SceneObject,
                PlaceId = 900001, ----入口
                DisplayOffset = { x = 0, y = 0.5, z = 0 },
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        InstLevelId = 4011,
        Count = 1,
    },
}
--15.播放A1级动画：露西亚和指挥官聊关于阿呆蛙副本的内容
---@class QuestObjective10010115 : Quest1001Objective
ObjectiveDefines.Obj10010115 = {
    Id = 10010115,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4001,
        DramaName = "Drama_1001_004",
    },
    ---@param obj QuestObjective10010115
    ---@param proxy XDlcCSharpFuncs
    InitFunc = function(obj, proxy)
        obj.soRabbitCakeP10ID = 900001
    end,
    ---@param obj QuestObjective10010115
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective10010115
    ---@param proxy XDlcCSharpFuncs
    HandleEventFunc = function(obj, proxy, eventType, eventArgs)
    end,
    ---@param obj QuestObjective10010115
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:UnloadSceneObject(obj.soRabbitCakeP10ID)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--16.前往九龙餐厅1楼跑图1
---@class QuestObjective10010116 : Quest1001Objective
ObjectiveDefines.Obj10010116 = {
    Id = 10010116,
    Type = EQuestObjectiveType.ReachTargetPosition,
    Args = {
        LevelId = 4001,
        TracePosArgs = {
            {
                Position = { x = 677.2227, y = 167.9902, z = 1124.703 },                 -- 目标位置（初始为空，后续需要赋值）
                DisplayOffset = { x = 0, y = 0.5, z = 0 }, -- 显示偏移量
                ShowEffect = false,                      -- 是否显示特效
                ForceMapPinActive = false,               -- 是否强制激活地图标记
            },                                           -- 这里加上逗号，方便后续扩展
        },
        TargetPosition = { x = 677.2227, y = 167.9902, z = 1124.703 },                   -- 后续替换为摆放点坐标
        ReachDistance = 15,                             -- 到达锚点1.5米范围内
    },
    ---@param obj QuestObjective10010116
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective10010116
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--17.前往九龙餐厅1楼跑图2
---@class QuestObjective10010117 : Quest1001Objective
ObjectiveDefines.Obj10010117 = {
    Id = 10010117,
    Type = EQuestObjectiveType.ReachTargetPosition,
    Args = {
        LevelId = 4001,
        TracePosArgs = {
            {
                Position = { x = 675.2095, y = 160.7298, z = 1133.489 },                 -- 目标位置（初始为空，后续需要赋值）
                DisplayOffset = { x = 0, y = 0.5, z = 0 }, -- 显示偏移量
                ShowEffect = false,                      -- 是否显示特效
                ForceMapPinActive = false,               -- 是否强制激活地图标记
            },                                           -- 这里加上逗号，方便后续扩展
        },
        TargetPosition = { x = 675.2095, y = 160.7298, z = 1133.489 },                   -- 后续替换为摆放点坐标
        ReachDistance = 15,                             -- 到达锚点1.5米范围内
    },
    ---@param obj QuestObjective10010117
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective10010117
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--18.播放B1级动画：九龙餐厅排队
---@class QuestObjective10010118 : Quest1001Objective
ObjectiveDefines.Obj10010118 = {
    Id = 10010118,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4001,
        DramaName = "Drama_1001_005",
    },
    ---@param obj QuestObjective10010118
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective10010118
    ---@param proxy XDlcCSharpFuncs
    HandleEventFunc = function(obj, proxy, eventType, eventArgs)
    end,
    ---@param obj QuestObjective10010116
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        local uuid4 = proxy:GetLocalPlayerNpcId()
        --proxy:SetNpcPosition(uuid4, { x = 541.0229, y = 168.5649, z = 1183.6 }, false)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--19.移动到咖啡厅的跑图
---@class QuestObjective10010119 : Quest1001Objective
ObjectiveDefines.Obj10010119 = {
    Id = 10010119,
    Type = EQuestObjectiveType.ReachTargetPosition,
    Args = {
        LevelId = 4001,
        TracePosArgs = {
            {
                Position = { x = 559.38, y = 169.44, z = 1175.57 },                 -- 目标位置（初始为空，后续需要赋值）
                DisplayOffset = { x = 0, y = 0.5, z = 0 }, -- 显示偏移量
                ShowEffect = false,                      -- 是否显示特效
                ForceMapPinActive = false,               -- 是否强制激活地图标记
            },                                           -- 这里加上逗号，方便后续扩展
        },
        TargetPosition = { x = 559.38, y = 169.44, z = 1175.57 },                   -- 后续替换为摆放点坐标
        ReachDistance = 15,                             -- 到达锚点1.5米范围内
    },
    ---@param obj QuestObjective10010119
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective10010119
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--20.播放B1级动画：咖啡师给指挥官和露西亚拉花
---@class QuestObjective10010120: Quest1001Objective
ObjectiveDefines.Obj10010120 = {
    Id = 10010120,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4001,
        DramaName = "Drama_1001_006",
    },
    ---@param obj QuestObjective10010120
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective10010120
    ---@param proxy XDlcCSharpFuncs
    HandleEventFunc = function(obj, proxy, eventType, eventArgs)
    end,
    ---@param obj QuestObjective10010120
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--21.移动到咖啡厅的座位旁边
---@class QuestObjective10010121 : Quest1001Objective
ObjectiveDefines.Obj10010121 = {
    Id = 10010121,
    Type = EQuestObjectiveType.ReachTargetPosition,
    Args = {
        LevelId = 4001,
        TracePosArgs = {
            {
                Position = { x = 567.44, y = 168.56, z = 1204.32 },                 -- 目标位置（初始为空，后续需要赋值）
                DisplayOffset = { x = 0, y = 0.5, z = 0 }, -- 显示偏移量
                ShowEffect = false,                      -- 是否显示特效
                ForceMapPinActive = false,               -- 是否强制激活地图标记
            },                                           -- 这里加上逗号，方便后续扩展
        },
        TargetPosition = { x = 567.44, y = 168.56, z = 1204.32 },                   -- 后续替换为摆放点坐标
        ReachDistance = 15,                             -- 到达锚点1.5米范围内
    },
    ---@param obj QuestObjective10010121
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective10010121
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--22.播放A1级动画：指挥官关心露西亚
---@class QuestObjective10010122: Quest1001Objective
ObjectiveDefines.Obj10010122 = {
    Id = 10010122,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4001,
        DramaName = "Drama_1001_007",
    },
    ---@param obj QuestObjective10010122
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
        
    end,
    ---@param obj QuestObjective10010122
    ---@param proxy XDlcCSharpFuncs
    HandleEventFunc = function(obj, proxy, eventType, eventArgs)
    end,
    ---@param obj QuestObjective10010122
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        local uuid4 = proxy:GetLocalPlayerNpcId()
        --proxy:SetNpcPosition(uuid4, { x = 551.37, y = 144.56, z = 1385.23 }, false)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--23.从时序广场回到宿舍
---@class QuestObjective10010123 : Quest1001Objective
ObjectiveDefines.Obj10010123 = {
    Id = 10010123,
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
    ---@param obj QuestObjective10010123
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective10010123
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--24.将四叶草放置在吧台上
---@class QuestObjective10010124 : Quest1001Objective
ObjectiveDefines.Obj10010124 = {
    Id = 10010124,
    Type = EQuestObjectiveType.InteractComplete,
    Args = {
        LevelId = 4003,
        TraceActorArgs = {
            {
                TargetType = ETargetActorType.SceneObject,
                PlaceId = 400003,
                DisplayOffset = { x = 0, y = 0.5, z = 0 },
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        TargetArgs = {
            [ETargetActorType.SceneObject] = {
                [400003] = 0,--四叶草物件
            },
        },
    },
    ---@param obj QuestObjective10010124
    InitFunc = function(obj)
        obj.soRabbitCakeP4ID = 400003
    end,
    ---@param obj QuestObjective10010124
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:LoadSceneObject(obj.soRabbitCakeP4ID)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective10010124
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:UnloadSceneObject(obj.soRabbitCakeP4ID)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--25.回到宿舍的床上休息
---@class QuestObjective10010125 : Quest1001Objective
ObjectiveDefines.Obj10010125 = {
    Id = 10010125,
    Type = EQuestObjectiveType.InteractComplete,
    Args = {
        LevelId = 4003,
        TraceActorArgs = {
            {
                TargetType = ETargetActorType.SceneObject,
                PlaceId = 400005,
                DisplayOffset = { x = 0, y = 0.5, z = 0 },
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        TargetArgs = {
            [ETargetActorType.SceneObject] = {
                [400005] = 0,--休息空物件
            },
        },
    },
    ---@param obj QuestObjective10010125
    InitFunc = function(obj)
        obj.soRabbitCakeP15ID = 400005
    end,
    ---@param obj QuestObjective10010125
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:LoadSceneObject(obj.soRabbitCakeP15ID)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective10010125
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:UnloadSceneObject(obj.soRabbitCakeP15ID)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--26.播放A1级动画：上床休息进入循环
---@class QuestObjective10010126: Quest1001Objective
ObjectiveDefines.Obj10010126 = {
    Id = 10010126,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4003,
        DramaName = "Drama_1001_008",
    },
    ---@param obj QuestObjective10010126
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
        
    end,
    ---@param obj QuestObjective10010126
    ---@param proxy XDlcCSharpFuncs
    HandleEventFunc = function(obj, proxy, eventType, eventArgs)
    end,
    ---@param obj QuestObjective10010126
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--27.播放B1级动画：分析情况
---@class QuestObjective10010127: Quest1001Objective
ObjectiveDefines.Obj10010127 = {
    Id = 10010127,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4003,
        DramaName = "Drama_1001_009",
    },
    ---@param obj QuestObjective10010127
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective10010127
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--69.播放B1级动画：分析情况
---@class QuestObjective10010169: Quest1001Objective
ObjectiveDefines.obj10010169 = {
    Id = 10010169,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4003,
        DramaName = "Drama_1001_038",
    },
    ---@param obj QuestObjective10010169
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective10010169
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--28通过交互台发送短信
---@class QuestObjective10010128 : Quest1001Objective
ObjectiveDefines.Obj10010128 = {
    Id = 10010128,
    Type = EQuestObjectiveType.InteractComplete,
    Args = {
        LevelId = 4003,
        TraceActorArgs = {
            {
                TargetType = ETargetActorType.SceneObject,
                PlaceId = 400006,
                DisplayOffset = { x = 0, y = 0.5, z = 0 },
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        TargetArgs = {
            [ETargetActorType.SceneObject] = {
                [400006] = 0,--发送短信
            },
        },
    },
    ---@param obj QuestObjective10010128
    InitFunc = function(obj)
        obj.soRabbitCakeP5ID = 400006
    end,
    ---@param obj QuestObjective10010128
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:LoadSceneObject(obj.soRabbitCakeP5ID)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective10010128
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:UnloadSceneObject(obj.soRabbitCakeP5ID)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--29.给露西亚发短信询问
---@class QuestObjective10010129 : Quest1001Objective
ObjectiveDefines.Obj10010129 = {
    Id = 10010129,
    Type = EQuestObjectiveType.ReadShortMessageComplete,
    Args = {
        LevelId = 4003,
        ShortMessageId = 100103,-------短信id
        AutoSend = true, --enter时，自动发送短信
    },
    ---@param obj QuestObjective10010129
    ---@param proxy XDlcCSharpFuncs
    InitFunc = function(obj, proxy)
    end,
    ---@param obj QuestObjective10010129
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective10010129
    ---@param proxy XDlcCSharpFuncs
    HandleEventFunc = function(obj, proxy, eventType, eventArgs)
    end,
    ---@param obj QuestObjective10010129
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--31.前往时序广场和露西亚见面
---@class QuestObjective10010131 : Quest1001Objective
ObjectiveDefines.Obj10010131 = {
    Id = 10010131,
    Type = EQuestObjectiveType.ReachTargetPosition,
    Args = {
        LevelId = 4001,
        TracePosArgs = {
            {
                Position = { x = 532.99, y = 145.97, z = 1323.71 },                 -- 目标位置（初始为空，后续需要赋值）
                DisplayOffset = { x = 0, y = 0.5, z = 0 }, -- 显示偏移量
                ShowEffect = false,                      -- 是否显示特效
                ForceMapPinActive = false,               -- 是否强制激活地图标记
            },                                           -- 这里加上逗号，方便后续扩展
        },
        TargetPosition = { x = 532.99, y = 145.97, z = 1323.71 },                   -- 后续替换为摆放点坐标
        ReachDistance = 15,                             -- 到达锚点1.5米范围内
    },
    ---@param obj QuestObjective10010131
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective10010131
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--32.播放B1级动画：和小露在时序广场会合
---@class QuestObjective10010132 : Quest1001Objective
ObjectiveDefines.Obj10010132 = {
    Id = 10010132,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4001,
        DramaName = "Drama_1001_010",
    },
    ---@param obj QuestObjective10010132
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective10010132
    ---@param proxy XDlcCSharpFuncs
    HandleEventFunc = function(obj, proxy, eventType, eventArgs)
    end,
    ---@param obj QuestObjective10010132
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        local uuid4 = proxy:GetLocalPlayerNpcId()
        --proxy:SetNpcPosition(uuid4, { x = 667.81, y = 156.22, z = 1210.64 }, false)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--33.来到银行时尚门口
---@class QuestObjective10010133 : Quest1001Objective
ObjectiveDefines.Obj10010133 = {
    Id = 10010133,
    Type = EQuestObjectiveType.ReachTargetPosition,
    Args = {
        LevelId = 4001,
        TracePosArgs = {
            {
                Position = { x = 681.76, y = 156.22, z = 1221.01 },                 -- 目标位置（初始为空，后续需要赋值）
                DisplayOffset = { x = 0, y = 0.5, z = 0 }, -- 显示偏移量
                ShowEffect = false,                      -- 是否显示特效
                ForceMapPinActive = false,               -- 是否强制激活地图标记
            },                                           -- 这里加上逗号，方便后续扩展
        },
        TargetPosition = { x = 681.76, y = 156.22, z = 1221.01 },                   -- 后续替换为摆放点坐标
        ReachDistance = 15,                             -- 到达锚点1.5米范围内
    },
    ---@param obj QuestObjective10010133
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective10010133
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--34.播放B1级动画：来到银河时尚门口
---@class QuestObjective10010134 : Quest1001Objective
ObjectiveDefines.Obj10010134 = {
    Id = 10010134,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4001,
        DramaName = "Drama_1001_039",
    },
    ---@param obj QuestObjective10010134
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective10010134
    ---@param proxy XDlcCSharpFuncs
    HandleEventFunc = function(obj, proxy, eventType, eventArgs)
    end,
    ---@param obj QuestObjective10010134
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--35.播放A3级动画：小露试新的发型
---@class QuestObjective10010135 : Quest1001Objective
ObjectiveDefines.Obj10010135 = {
    Id = 10010135,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4001,
        DramaName = "Drama_1001_011",
    },
    ---@param obj QuestObjective10010135
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective10010135
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--36.播放B1级动画：不一样的体验
---@class QuestObjective10010136 : Quest1001Objective
ObjectiveDefines.Obj10010136 = {
    Id = 10010136,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4001,
        DramaName = "Drama_1001_040",
    },
    ---@param obj QuestObjective10010136
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective10010136
    ---@param proxy XDlcCSharpFuncs
    HandleEventFunc = function(obj, proxy, eventType, eventArgs)
    end,
    ---@param obj QuestObjective10010136
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        local uuid4 = proxy:GetLocalPlayerNpcId()
        --proxy:SetNpcPosition(uuid4, { x = 536.53, y = 168.56, z = 1174.5 }, false)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--37.前往库洛洛咖啡厅
---@class QuestObjective10010137 : Quest1001Objective
ObjectiveDefines.Obj10010137 = {
    Id = 10010137,
    Type = EQuestObjectiveType.ReachTargetPosition,
    Args = {
        LevelId = 4001,
        TracePosArgs = {
            {
                Position = { x = 559.38, y = 169.44, z = 1175.57 },                 -- 目标位置（初始为空，后续需要赋值）
                DisplayOffset = { x = 0, y = 0.5, z = 0 }, -- 显示偏移量
                ShowEffect = false,                      -- 是否显示特效
                ForceMapPinActive = false,               -- 是否强制激活地图标记
            },                                           -- 这里加上逗号，方便后续扩展
        },
        TargetPosition = { x = 559.38, y = 169.44, z = 1175.57 },                   -- 后续替换为摆放点坐标
        ReachDistance = 15,                             -- 到达锚点1.5米范围内
    },
    ---@param obj QuestObjective10010137
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective10010137
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--38.播放B1级动画：指挥官指出咖啡厅新人的错误
---@class QuestObjective10010138: Quest1001Objective
ObjectiveDefines.Obj10010138 = {
    Id = 10010138,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4001,
        DramaName = "Drama_1001_012",
    },
    ---@param obj QuestObjective10010138
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective10010138
    ---@param proxy XDlcCSharpFuncs
    HandleEventFunc = function(obj, proxy, eventType, eventArgs)
    end,
    ---@param obj QuestObjective10010138
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        local uuid4 = proxy:GetLocalPlayerNpcId()
        --proxy:SetNpcPosition(uuid4, { x = 677.32, y = 167.99, z = 1139.9 }, false)
        --XScriptTool.DoTeleportNpcPosAndRotWithBlackScreen(proxy, uuid4, { x = 677.32, y = 167.99, z = 1139.9 }, { x = 0, y = 90, z = 0 })
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--39.前往九龙餐厅1楼跑图
---@class QuestObjective10010139 : Quest1001Objective
ObjectiveDefines.Obj10010139 = {
    Id = 10010139,
    Type = EQuestObjectiveType.ReachTargetPosition,
    Args = {
        LevelId = 4001,
        TracePosArgs = {
            {
                Position = { x = 657.03, y = 160.35, z = 1136.99 },                 -- 目标位置（初始为空，后续需要赋值）
                DisplayOffset = { x = 0, y = 0.5, z = 0 }, -- 显示偏移量
                ShowEffect = false,                      -- 是否显示特效
                ForceMapPinActive = false,               -- 是否强制激活地图标记
            },                                           -- 这里加上逗号，方便后续扩展
        },
        TargetPosition = { x = 657.03, y = 160.35, z = 1136.99 },                   -- 后续替换为摆放点坐标
        ReachDistance = 15,                             -- 到达锚点1.5米范围内
    },
    ---@param obj QuestObjective10010139
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective10010139
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--40.露西亚和指挥官在九龙餐厅享用美食
---@class QuestObjective10010140: Quest1001Objective
ObjectiveDefines.Obj10010140 = {
    Id = 10010140,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4001,
        DramaName = "Drama_1001_013",
    },
    ---@param obj QuestObjective10010140
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective10010140
    ---@param proxy XDlcCSharpFuncs
    HandleEventFunc = function(obj, proxy, eventType, eventArgs)
    end,
    ---@param obj QuestObjective10010140
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        local uuid4 = proxy:GetLocalPlayerNpcId()
        proxy:SetNpcPosition(uuid4, { x = 669.81, y = 167.99, z = 1158.3 }, false)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--41.前往星辰酿泡酒吧
---@class QuestObjective10010141 : Quest1001Objective
ObjectiveDefines.Obj10010141 = {
    Id = 10010141,
    Type = EQuestObjectiveType.ReachTargetPosition,
    Args = {
        LevelId = 4001,
        TracePosArgs = {
            {
                Position = { x = 683.76, y = 192.60, z = 1207.20 },                 -- 目标位置（初始为空，后续需要赋值）
                DisplayOffset = { x = 0, y = 0.5, z = 0 }, -- 显示偏移量
                ShowEffect = false,                      -- 是否显示特效
                ForceMapPinActive = false,               -- 是否强制激活地图标记
            },                                           -- 这里加上逗号，方便后续扩展
        },
        TargetPosition = { x = 683.76, y = 192.60, z = 1207.20 },                   -- 后续替换为摆放点坐标
        ReachDistance = 15,                             -- 到达锚点1.5米范围内
    },
    ---@param obj QuestObjective10010141
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective10010141
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--70.B1级指挥官和露西亚调酒
---@class QuestObjective10010170: Quest1001Objective
ObjectiveDefines.Obj10010170 = {
    Id = 10010170,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4001,
        DramaName = "Drama_1001_045",
    },
    ---@param obj QuestObjective10010170
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective10010170
    ---@param proxy XDlcCSharpFuncs
    HandleEventFunc = function(obj, proxy, eventType, eventArgs)
    end,
    ---@param obj QuestObjective10010170
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--42.A2级第一人称互动叙事
---@class QuestObjective10010142: Quest1001Objective
ObjectiveDefines.Obj10010142 = {
    Id = 10010142,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4001,
        DramaName = "Drama_1001_014",
    },
    ---@param obj QuestObjective10010142
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective10010142
    ---@param proxy XDlcCSharpFuncs
    HandleEventFunc = function(obj, proxy, eventType, eventArgs)
    end,
    ---@param obj QuestObjective10010142
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        --local uuid4 = proxy:GetLocalPlayerNpcId()
        --proxy:SetNpcPosition(uuid4, { x = 551.37, y = 144.56, z = 1385.23 }, false)
        local pos = { x = 12.58, y = 1.144, z = 13.27 }
        proxy:SwitchLevel(4003, pos)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--43.从时序广场回到宿舍
---@class QuestObjective10010143 : Quest1001Objective
ObjectiveDefines.Obj10010143 = {
    Id = 10010143,
    Type = EQuestObjectiveType.ReachTargetPosition,
    Args = {
        LevelId = 4003,
        TracePosArgs = {
            {
                Position = { x = 12.58, y = 1.144, z = 13.27 },                 -- 目标位置（初始为空，后续需要赋值）
                DisplayOffset = { x = 0, y = 0.5, z = 0 }, -- 显示偏移量
                ShowEffect = false,                      -- 是否显示特效
                ForceMapPinActive = false,               -- 是否强制激活地图标记
            },                                           -- 这里加上逗号，方便后续扩展
        },
        TargetPosition = { x = 12.58, y = 1.144, z = 13.27 },                   -- 后续替换为摆放点坐标
        ReachDistance = 15,                             -- 到达锚点1.5米范围内
    },
    ---@param obj QuestObjective10010143
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective10010143
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--44.播放A1级动画：未到的明天
---@class QuestObjective10010144 : Quest1001Objective
ObjectiveDefines.Obj10010144 = {
    Id = 10010144,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4003,
        DramaName = "Drama_1001_015",
    },
    ---@param obj QuestObjective10010144
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective10010144
    ---@param proxy XDlcCSharpFuncs
    HandleEventFunc = function(obj, proxy, eventType, eventArgs)
    end,
    ---@param obj QuestObjective10010144
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--45.拿起宿舍的咖啡让自己冷静
---@class QuestObjective10010145 : Quest1001Objective
ObjectiveDefines.Obj10010145 = {
    Id = 10010145,
    Type = EQuestObjectiveType.InteractComplete,
    Args = {
        LevelId = 4003,
        TraceActorArgs = {
            {
                TargetType = ETargetActorType.SceneObject,
                PlaceId = 400007,
                DisplayOffset = { x = 0, y = 0.5, z = 0 },
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        TargetArgs = {
            [ETargetActorType.SceneObject] = {
                [400007] = 0,--拿起咖啡
            },
        },
    },
    ---@param obj QuestObjective10010145
    InitFunc = function(obj)
        obj.soRabbitCakeP1ID = 400007
    end,
    ---@param obj QuestObjective10010145
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:LoadSceneObject(obj.soRabbitCakeP1ID)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective10010145
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:UnloadSceneObject(obj.soRabbitCakeP1ID)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--46.前往宿舍沙发坐下来
---@class QuestObjective10010146 : Quest1001Objective
ObjectiveDefines.Obj10010146 = {
    Id = 10010146,
    Type = EQuestObjectiveType.ReachTargetPosition,
    Args = {
        LevelId = 4003,
        TracePosArgs = {
            {
                Position = { x = 14.43, y = 0.76, z = 21.13 },                 -- 目标位置（初始为空，后续需要赋值）
                DisplayOffset = { x = 0, y = 0.5, z = 0 }, -- 显示偏移量
                ShowEffect = false,                      -- 是否显示特效
                ForceMapPinActive = false,               -- 是否强制激活地图标记
            },                                           -- 这里加上逗号，方便后续扩展
        },
        TargetPosition = { x = 14.43, y = 0.76, z = 21.13 },                   -- 后续替换为摆放点坐标
        ReachDistance = 15,                             -- 到达锚点1.5米范围内
    },
    ---@param obj QuestObjective10010146
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective10010146
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--47.播放B1级动画：整理思绪
---@class QuestObjective10010147 : Quest1001Objective
ObjectiveDefines.Obj10010147 = {
    Id = 10010147,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4003,
        DramaName = "Drama_1001_016",
    },
    ---@param obj QuestObjective10010147
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective10010147
    ---@param proxy XDlcCSharpFuncs
    HandleEventFunc = function(obj, proxy, eventType, eventArgs)
    end,
    ---@param obj QuestObjective10010147
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--48通过交互台发送短信
---@class QuestObjective10010148 : Quest1001Objective
ObjectiveDefines.Obj10010148 = {
    Id = 10010148,
    Type = EQuestObjectiveType.InteractComplete,
    Args = {
        LevelId = 4003,
        TraceActorArgs = {
            {
                TargetType = ETargetActorType.SceneObject,
                PlaceId = 400006,
                DisplayOffset = { x = 0, y = 0.5, z = 0 },
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        TargetArgs = {
            [ETargetActorType.SceneObject] = {
                [400006] = 0,--发送短信物件
            },
        },
    },
    ---@param obj QuestObjective10010148
    InitFunc = function(obj)
        obj.soRabbitCakeP5ID = 400006
    end,
    ---@param obj QuestObjective10010148
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:LoadSceneObject(obj.soRabbitCakeP5ID)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective10010148
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:UnloadSceneObject(obj.soRabbitCakeP5ID)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--49.给露西亚发短信询问
---@class QuestObjective10010149 : Quest1001Objective
ObjectiveDefines.Obj10010149 = {
    Id = 10010149,
    Type = EQuestObjectiveType.ReadShortMessageComplete,
    Args = {
        LevelId = 4003,
        ShortMessageId = 100104,-------短信id
        AutoSend = true, --enter时，自动发送短信
    },
    ---@param obj QuestObjective10010149
    ---@param proxy XDlcCSharpFuncs
    InitFunc = function(obj, proxy)
    end,
    ---@param obj QuestObjective10010149
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective10010149
    ---@param proxy XDlcCSharpFuncs
    HandleEventFunc = function(obj, proxy, eventType, eventArgs)
    end,
    ---@param obj QuestObjective10010149
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--50.与露西亚见面，可选阅读物
---@class QuestObjective10010150 : Quest1001Objective
ObjectiveDefines.Obj10010150 = {
    Id = 10010150,
    Type = EQuestObjectiveType.ReachTargetPosition,
    Args = {
        LevelId = 4001,
        TracePosArgs = {
            {
                Position = { x = 532.99, y = 145.97, z = 1323.71 },                 -- 目标位置（初始为空，后续需要赋值）
                DisplayOffset = { x = 0, y = 0.5, z = 0 }, -- 显示偏移量
                ShowEffect = false,                      -- 是否显示特效
                ForceMapPinActive = false,               -- 是否强制激活地图标记
            },                                           -- 这里加上逗号，方便后续扩展
        },
        TargetPosition = { x = 532.99, y = 145.97, z = 1323.71 },                   -- 后续替换为摆放点坐标
        ReachDistance = 15,                             -- 到达锚点1.5米范围内
    },
    ---@param obj QuestObjective10010149
    ---@param proxy XDlcCSharpFuncs
    InitFunc = function(obj, proxy)
    end,
    ---@param obj QuestObjective10010150
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective10010150
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--51.播放A1级动画：将目前所有的信息告诉小露
---@class QuestObjective10010151 : Quest1001Objective
ObjectiveDefines.Obj10010151 = {
    Id = 10010151,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4001,
        DramaName = "Drama_1001_017",
    },
    ---@param obj QuestObjective10010151
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective10010151
    ---@param proxy XDlcCSharpFuncs
    HandleEventFunc = function(obj, proxy, eventType, eventArgs)
    end,
    ---@param obj QuestObjective10010151
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        local uuid4 = proxy:GetLocalPlayerNpcId()
        --proxy:SetNpcPosition(uuid4, { x = 672.39, y = 167.99, z = 1158.134 }, false)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--52.前往九龙食府寻找装置人员
---@class QuestObjective10010152 : Quest1001Objective
ObjectiveDefines.Obj10010152 = {
    Id = 10010152,
    Type = EQuestObjectiveType.ReachTargetPosition,
    Args = {
        LevelId = 4001,
        TracePosArgs = {
            {
                Position = { x = 673.11, y = 167.99, z = 1144.16 },                 -- 目标位置（初始为空，后续需要赋值）
                DisplayOffset = { x = 0, y = 0.5, z = 0 }, -- 显示偏移量
                ShowEffect = false,                      -- 是否显示特效
                ForceMapPinActive = false,               -- 是否强制激活地图标记
            },                                           -- 这里加上逗号，方便后续扩展
        },
        TargetPosition = { x = 673.11, y = 167.99, z = 1144.161 },                   -- 后续替换为摆放点坐标
        ReachDistance = 15,                             -- 到达锚点1.5米范围内
    },
    ---@param obj QuestObjective10010152
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective10010152
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--53.播放B1级动画：将指挥官和露西亚带到存放完整版装置的地方
---@class QuestObjective10010153 : Quest1001Objective
ObjectiveDefines.Obj10010153 = {
    Id = 10010153,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4001,
        DramaName = "Drama_1001_018",
    },
    ---@param obj QuestObjective10010153
    ---@param proxy XDlcCSharpFuncs
    InitFunc = function(obj, proxy)
        obj.soRabbitCakeP11ID = 900002
    end,
    ---@param obj QuestObjective10010153
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
        proxy:LoadSceneObject(obj.soRabbitCakeP11ID)
    end,
    ---@param obj QuestObjective10010153
    ---@param proxy XDlcCSharpFuncs
    HandleEventFunc = function(obj, proxy, eventType, eventArgs)
    end,
    ---@param obj QuestObjective10010153
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        local uuid4 = proxy:GetLocalPlayerNpcId()
        proxy:SetNpcPosition(uuid4, {  x = 637.52, y = 192.28, z = 1267.38 }, false)
        --XScriptTool.DoTeleportNpcPosAndRotWithBlackScreen(proxy, uuid4, {  x = 637.52, y = 192.28, z = 1267.38 }, { x = 0, y = -42.5, z = 0 })
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--54.通过装置进入阿呆蛙副本
---@class QuestObjective10010154 : Quest1001Objective
ObjectiveDefines.Obj10010154 = {
    Id = 10010154,
    Type = EQuestObjectiveType.InstanceComplete,
    Args = {
        LevelId = 4001,
        TraceActorArgs = {
            {
                TargetType = ETargetActorType.SceneObject,
                PlaceId = 900002, ----入口
                DisplayOffset = { x = 0, y = 0.5, z = 0 },
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        InstLevelId = 4023,
        Count = 1,
    },
}
--55.播放B1级动画：露西亚和指挥官聊关于阿呆蛙副本的内容
---@class QuestObjective10010155 : Quest1001Objective
ObjectiveDefines.Obj10010155 = {
    Id = 10010155,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4001,
        DramaName = "Drama_1001_019",
    },
    ---@param obj QuestObjective10010155
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective10010155
    ---@param proxy XDlcCSharpFuncs
    HandleEventFunc = function(obj, proxy, eventType, eventArgs)
    end,
    ---@param obj QuestObjective10010155
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        local uuid4 = proxy:GetLocalPlayerNpcId()
        --proxy:SetNpcPosition(uuid4, { x = 637.52, y = 192.28, z = 1267.38 }, false)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--56.前往时序广场寻找心跳回忆NPC
---@class QuestObjective10010156 : Quest1001Objective
ObjectiveDefines.Obj10010156 = {
    Id = 10010156,
    Type = EQuestObjectiveType.ReachTargetPosition,
    Args = {
        LevelId = 4001,
        TracePosArgs = {
            {
                Position = { x = 635.13, y = 156.99, z = 1298.24 },                 -- 目标位置（初始为空，后续需要赋值）
                DisplayOffset = { x = 0, y = 0.5, z = 0 }, -- 显示偏移量
                ShowEffect = false,                      -- 是否显示特效
                ForceMapPinActive = false,               -- 是否强制激活地图标记
            },                                           -- 这里加上逗号，方便后续扩展
        },
        TargetPosition = { x = 635.13, y = 156.99, z = 1298.24 },                   -- 后续替换为摆放点坐标
        ReachDistance = 15,                             -- 到达锚点1.5米范围内
    },
    ---@param obj QuestObjective10010156
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective10010156
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--57.露西亚和指挥官拿到完整版本的心跳回忆设备
---@class QuestObjective10010157: Quest1001Objective
ObjectiveDefines.Obj10010157 = {
    Id = 10010157,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4001,
        DramaName = "Drama_1001_020",
    },
    ---@param obj QuestObjective10010157
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective10010157
    ---@param proxy XDlcCSharpFuncs
    HandleEventFunc = function(obj, proxy, eventType, eventArgs)
    end,
    ---@param obj QuestObjective10010157
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        local uuid4 = proxy:GetLocalPlayerNpcId()
        --proxy:SetNpcPosition(uuid4, { x = 551.37, y = 144.56, z = 1385.23 }, false)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--58.从时序广场回到宿舍
---@class QuestObjective10010158 : Quest1001Objective
ObjectiveDefines.Obj10010158 = {
    Id = 10010158,
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
    ---@param obj QuestObjective10010158
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective10010158
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--59.前往宿舍沙发坐下来
---@class QuestObjective10010159 : Quest1001Objective
ObjectiveDefines.Obj10010159 = {
    Id = 10010159,
    Type = EQuestObjectiveType.ReachTargetPosition,
    Args = {
        LevelId = 4003,
        TracePosArgs = {
            {
                Position = { x = 12.87, y = 0.76, z = 21.13 },                 -- 目标位置（初始为空，后续需要赋值）
                DisplayOffset = { x = 0, y = 0.5, z = 0 }, -- 显示偏移量
                ShowEffect = false,                      -- 是否显示特效
                ForceMapPinActive = false,               -- 是否强制激活地图标记
            },                                           -- 这里加上逗号，方便后续扩展
        },
        TargetPosition = { x = 12.87, y = 0.76, z = 21.13 },                   -- 后续替换为摆放点坐标
        ReachDistance = 15,                             -- 到达锚点1.5米范围内
    },
    ---@param obj QuestObjective10010159
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective10010159
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--60.播放B1级动画：和小露一起探讨心跳回忆的场景构建细节
---@class QuestObjective10010160 : Quest1001Objective
ObjectiveDefines.Obj10010160 = {
    Id = 10010160,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4003,
        DramaName = "Drama_1001_021",
    },
    ---@param obj QuestObjective10010160
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective10010160
    ---@param proxy XDlcCSharpFuncs
    HandleEventFunc = function(obj, proxy, eventType, eventArgs)
    end,
    ---@param obj QuestObjective10010160
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--61.播放A1级动画：准备进入心跳回忆
---@class QuestObjective10010161 : Quest1001Objective
ObjectiveDefines.Obj10010161 = {
    Id = 10010161,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4003,
        DramaName = "Drama_1001_022",
    },
    ---@param obj QuestObjective10010161
    InitFunc = function(obj)
        obj.soRabbitCakeP12ID = 400008
    end,
    ---@param obj QuestObjective10010161
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
        proxy:LoadSceneObject(obj.soRabbitCakeP12ID)
    end,
    ---@param obj QuestObjective10010161
    ---@param proxy XDlcCSharpFuncs
    HandleEventFunc = function(obj, proxy, eventType, eventArgs)
    end,
    ---@param obj QuestObjective10010161
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:RequestEnterInstLevel(4012, { x = 80.238, y = 143.6, z = 96.568 } )
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--62.通过装置进入心跳回忆副本
---@class QuestObjective10010162 : Quest1001Objective
ObjectiveDefines.Obj10010162 = {
    Id = 10010162,
    Type = EQuestObjectiveType.InstanceComplete,
    Args = {
        LevelId = 4003,
        TraceActorArgs = {
            {
                TargetType = ETargetActorType.SceneObject,
                PlaceId = 400008, ----入口
                DisplayOffset = { x = 0, y = 0.5, z = 0 },
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        InstLevelId = 4012,
        Count = 1,
    },
}
--63.播放A1级动画：指挥官脱离循环
---@class QuestObjective10010163 : Quest1001Objective
ObjectiveDefines.Obj10010163 = {
    Id = 10010163,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4003,
        DramaName = "Drama_1001_031",
    },
    ---@param obj QuestObjective10010163
    InitFunc = function(obj)
        obj.soRabbitCakeP12ID = 400008
    end,
    ---@param obj QuestObjective10010163
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective10010163
    ---@param proxy XDlcCSharpFuncs
    HandleEventFunc = function(obj, proxy, eventType, eventArgs)
    end,
    ---@param obj QuestObjective10010163
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:UnloadSceneObject(obj.soRabbitCakeP12ID)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--65.播放B1级动画：后日谈，指挥官和露西亚选照片
---@class QuestObjective10010165 : Quest1001Objective
ObjectiveDefines.Obj10010165 = {
    Id = 10010165,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4003,
        DramaName = "Drama_1001_032",
    },
    ---@param obj QuestObjective10010165
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective10010165
    ---@param proxy XDlcCSharpFuncs
    HandleEventFunc = function(obj, proxy, eventType, eventArgs)
    end,
    ---@param obj QuestObjective10010165
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        local uuid4 = proxy:GetLocalPlayerNpcId()
        proxy:SetNpcPosition(uuid4, { x =11.16, y = 1.44, z = 13.32 }, false)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--64.前往照片墙找到露西亚
---@class QuestObjective10010164 : Quest1001Objective
ObjectiveDefines.Obj10010164 = {
    Id = 10010164,
    Type = EQuestObjectiveType.ReachTargetPosition,
    Args = {
        LevelId = 4003,
        TracePosArgs = {
            {
                Position = { x = 9.50, y = 0.76, z = 20.50 },                 -- 目标位置（初始为空，后续需要赋值）
                DisplayOffset = { x = 0, y = 0.5, z = 0 }, -- 显示偏移量
                ShowEffect = false,                      -- 是否显示特效
                ForceMapPinActive = false,               -- 是否强制激活地图标记
            },                                           -- 这里加上逗号，方便后续扩展
        },
        TargetPosition = { x = 9.50, y = 0.76, z = 20.50 },                   -- 后续替换为摆放点坐标
        ReachDistance = 10,                             -- 到达锚点1.5米范围内
    },
    ---@param obj QuestObjective10010164
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective10010164
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--68.播放A1级动画：后日谈，重新回到约会场景
---@class QuestObjective10010168 : Quest1001Objective
ObjectiveDefines.Obj10010168 = {
    Id = 10010168,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4003,
        DramaName = "Drama_1001_044",
    },
    ---@param obj QuestObjective10010168
    InitFunc = function(obj)
        obj.soRabbitCakeP13ID = 400009
    end,
    ---@param obj QuestObjective10010168
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:LoadSceneObject(obj.soRabbitCakeP13ID)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective10010168
    ---@param proxy XDlcCSharpFuncs
    HandleEventFunc = function(obj, proxy, eventType, eventArgs)
    end,
    ---@param obj QuestObjective10010168
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}

local StepDefines = {} --本任务包含的所有任务步骤的参数配置（不要删除！）

--Step的参数配置，至少要有一个，可按需增加
StepDefines.Step = {
    Id = 100101,
    ExecMode = EQuestStepExecMode.Serial,
}
QuestBase.InitSteps(StepDefines) --固定的任务步骤数据初始化调用（不要删除！）
QuestBase.InitQuestObjectives(Quest1001Objective, ObjectiveDefines) --固定的任务目标数据初始化调用（不要删除！）

return Quest_1001
