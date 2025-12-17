local QuestBase = require("Common/XQuestBase")
---@class XQuestScript4012 : XQuestBase
local XQuestScript4012 = XDlcScriptManager.RegQuestScript(4012, "XQuestScript4012", QuestBase)

---@param proxy XDlcCSharpFuncs
function XQuestScript4012:Ctor(proxy)
end

function XQuestScript4012:Init()

end

function XQuestScript4012:Terminate()
end

---@class Quest4012Objective
local ObjectiveBase = XClass(nil, "Quest4012Objective")

---@param quest XQuestScript4012
function ObjectiveBase:Ctor(quest)
    self.quest = quest
end

local emptyVector3 = { x = 0, y = 0, z = 0 }

local ObjectiveDefines = {}

--01.播放A1级动画：场景漫游
---@class QuestObjective40120101 : Quest4012Objective
ObjectiveDefines.Obj40120101 = {
    Id = 40120101,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4012,
        DramaName = "Drama_1001_023",
    },
    ---@param obj QuestObjective40120102
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective40120101
    ---@param proxy XDlcCSharpFuncs
    HandleEventFunc = function(obj, proxy, eventType, eventArgs)
    end,
    ---@param obj QuestObjective40120101
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}


--02.到达指定地点寻找露西亚
---@class QuestObjective40120102 : Quest4012Objective
ObjectiveDefines.Obj40120102 = {
    Id = 40120102,
    Type = EQuestObjectiveType.ReachTargetPosition,
    Args = {
        LevelId = 4012,
        TracePosArgs = {
            {
                Position = { x = 102.391, y = 144.864, z = 110.42 },                 -- 目标位置（初始为空，后续需要赋值）
                DisplayOffset = { x = 0, y = 0.5, z = 0 }, -- 显示偏移量
                ShowEffect = false,                      -- 是否显示特效
                ForceMapPinActive = false,               -- 是否强制激活地图标记
            },                                           -- 这里加上逗号，方便后续扩展
        },
        TargetPosition = { x = 102.391, y = 144.864, z = 110.42 },                   -- 后续替换为摆放点坐标
        ReachDistance = 5,                             -- 到达锚点1.5米范围内
    },
    ---@param obj QuestObjective40120102
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective40120102
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}

--03.播放A1级动画：找到露西亚
---@class QuestObjective40120103 : Quest4012Objective
ObjectiveDefines.Obj40120103 = {
    Id = 40120103,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4012,
        DramaName = "Drama_1001_024",
    },
    ---@param obj QuestObjective40120103
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective40120103
    ---@param proxy XDlcCSharpFuncs
    HandleEventFunc = function(obj, proxy, eventType, eventArgs)
    end,
    ---@param obj QuestObjective40120103
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--04.播放B1级动画：和露西亚聊天
---@class QuestObjective40120104 : Quest4012Objective
ObjectiveDefines.Obj40120104 = {
    Id = 40120104,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4012,
        DramaName = "Drama_1001_025",
    },
    ---@param obj QuestObjective40120104
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective40120104
    ---@param proxy XDlcCSharpFuncs
    HandleEventFunc = function(obj, proxy, eventType, eventArgs)
    end,
    ---@param obj QuestObjective40120104
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:LoadLevelNpc(1)
        local uuid4 = proxy:GetLocalPlayerNpcId()
        XScriptTool.DoTeleportNpcPosAndRotWithBlackScreen(proxy, uuid4, { x = 104.233, y = 144.538, z = 111.46 }, { x = 0, y = 22.848, z = 0 })
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--05.和露西亚一起合影
---@class QuestObjective40120105 : Quest4012Objective
ObjectiveDefines.Obj40120105  = {
    Id = 40120105,
    Type = EQuestObjectiveType.TakePhotoComplete,
    Args = {
        LevelId = 4012,
        DetectionNpcPlaceIdList = { 1 },
        DetectionSceneObjectPlaceIdList = {}
    },

    EnterFunc = function(obj, proxy)
        proxy:OpenGameplayPhotograph(6, { 1 }, {})
        proxy:FinishQuestObjectiveScriptEnter()
    end,

    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--06.到达指定地点放烟花
---@class QuestObjective40120106 : Quest4012Objective
ObjectiveDefines.Obj40120106 = {
    Id = 40120106,
    Type = EQuestObjectiveType.ReachTargetPosition,
    Args = {
        LevelId = 4012,
        TracePosArgs = {
            {
                Position = { x = 119.01, y = 143.163, z = 110.748 },                 -- 目标位置（初始为空，后续需要赋值）
                DisplayOffset = { x = 0, y = 0.5, z = 0 }, -- 显示偏移量
                ShowEffect = false,                      -- 是否显示特效
                ForceMapPinActive = false,               -- 是否强制激活地图标记
            },                                           -- 这里加上逗号，方便后续扩展
        },
        TargetPosition = { x = 119.01, y = 143.163, z = 110.748 },                   -- 后续替换为摆放点坐标
        ReachDistance = 5,                             -- 到达锚点1.5米范围内
    },
    ---@param obj QuestObjective40120106
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:UnloadLevelNpc(1)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective40120106
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--07.放烟花交互
---@class QuestObjective40120107 : Quest4012Objective
ObjectiveDefines.Obj40120107 = {
    Id = 40120107,
    Type = EQuestObjectiveType.InteractComplete,
    Args = {
        LevelId = 4012,
        TraceActorArgs = {
            {
                TargetType = ETargetActorType.SceneObject,
                PlaceId = 2,
                DisplayOffset = { x = 0, y = 0.5, z = 0 },
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        TargetArgs = {
            [ETargetActorType.SceneObject] = {
                [2] = 0,--拿四叶草
            },
        },
    },
    ---@param obj QuestObjective40120107
    InitFunc = function(obj)
        obj.soRabbitCakeP1ID = 2
    end,
    ---@param obj QuestObjective40120107
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:LoadSceneObject(obj.soRabbitCakeP1ID)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective40120107
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:UnloadSceneObject(obj.soRabbitCakeP1ID)
        proxy:LoadLevelNpc(2)
        local uuid4 = proxy:GetLocalPlayerNpcId()
        XScriptTool.DoTeleportNpcPosAndRotWithBlackScreen(proxy, uuid4, { x = 124.307, y = 143.393, z = 109.022 }, { x = 0, y = 266.295, z = 0 })
        proxy:FinishQuestObjectiveScriptExit()
    end,
}

--08.和露西亚一起合影
---@class QuestObjective40120108 : Quest4012Objective
ObjectiveDefines.Obj40120108  = {
    Id = 40120108,
    Type = EQuestObjectiveType.TakePhotoComplete,
    Args = {
        LevelId = 4012,
        DetectionNpcPlaceIdList = { 2 },
        DetectionSceneObjectPlaceIdList = {}
    },

    EnterFunc = function(obj, proxy)
        proxy:OpenGameplayPhotograph(6, { 2 }, {})
        proxy:FinishQuestObjectiveScriptEnter()
    end,

    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}

--09.和露西亚一起散步
---@class QuestObjective40120109 : Quest4012Objective
ObjectiveDefines.Obj40120109 = {
    Id = 40120109,
    Type = EQuestObjectiveType.ReachTargetPosition,
    Args = {
        LevelId = 4012,
        TracePosArgs = {
            {
                Position = { x = 108.855, y = 143.80, z = 96.59 },                 -- 目标位置（初始为空，后续需要赋值）
                DisplayOffset = { x = 0, y = 0.5, z = 0 }, -- 显示偏移量
                ShowEffect = false,                      -- 是否显示特效
                ForceMapPinActive = false,               -- 是否强制激活地图标记
            },                                           -- 这里加上逗号，方便后续扩展
        },
        TargetPosition = { x = 108.855, y = 143.80, z = 96.59 },                   -- 后续替换为摆放点坐标
        ReachDistance = 5,                             -- 到达锚点1.5米范围内
    },
    ---@param obj QuestObjective40120109
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:UnloadLevelNpc(2)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective40120109
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--10.播放A3级动画：动态CG
---@class QuestObjective40120110 : Quest4012Objective
ObjectiveDefines.Obj40120110 = {
    Id = 40120110,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4012,
        DramaName = "Drama_1001_026",
    },
    ---@param obj QuestObjective40120110
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective40120110
    ---@param proxy XDlcCSharpFuncs
    HandleEventFunc = function(obj, proxy, eventType, eventArgs)
    end,
    ---@param obj QuestObjective40120110
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
        proxy:UnloadLevelNpc(2)
    end,
}
--11.到达指定地点播放互动叙事
---@class QuestObjective40120111 : Quest4012Objective
ObjectiveDefines.Obj40120111 = {
    Id = 40120111,
    Type = EQuestObjectiveType.ReachTargetPosition,
    Args = {
        LevelId = 4012,
        TracePosArgs = {
            {
                Position = { x = 90.663, y = 144.16, z = 99.99 },                 -- 目标位置（初始为空，后续需要赋值）
                DisplayOffset = { x = 0, y = 0.5, z = 0 }, -- 显示偏移量
                ShowEffect = false,                      -- 是否显示特效
                ForceMapPinActive = false,               -- 是否强制激活地图标记
            },                                           -- 这里加上逗号，方便后续扩展
        },
        TargetPosition = { x = 90.663, y = 144.16, z = 99.99 },                   -- 后续替换为摆放点坐标
        ReachDistance = 5,                             -- 到达锚点1.5米范围内
    },
    ---@param obj QuestObjective40120111
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective40120111
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--12.到达指定地点播放互动叙事
---@class QuestObjective40120112 : Quest4012Objective
ObjectiveDefines.Obj40120112 = {
    Id = 40120112,
    Type = EQuestObjectiveType.ReachTargetPosition,
    Args = {
        LevelId = 4012,
        TracePosArgs = {
            {
                Position = { x = 78.87, y = 143.59, z = 95.82 },                 -- 目标位置（初始为空，后续需要赋值）
                DisplayOffset = { x = 0, y = 0.5, z = 0 }, -- 显示偏移量
                ShowEffect = false,                      -- 是否显示特效
                ForceMapPinActive = false,               -- 是否强制激活地图标记
            },                                           -- 这里加上逗号，方便后续扩展
        },
        TargetPosition = { x = 78.87, y = 143.59, z = 95.82 },                   -- 后续替换为摆放点坐标
        ReachDistance = 5,                             -- 到达锚点1.5米范围内
    },
    ---@param obj QuestObjective40120112
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective40120112
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--13.到达指定地点播放互动叙事
---@class QuestObjective40120113 : Quest4012Objective
ObjectiveDefines.Obj40120113 = {
    Id = 40120113,
    Type = EQuestObjectiveType.ReachTargetPosition,
    Args = {
        LevelId = 4012,
        TracePosArgs = {
            {
                Position = { x = 83.158, y = 143.42, z = 118.30 },                 -- 目标位置（初始为空，后续需要赋值）
                DisplayOffset = { x = 0, y = 0.5, z = 0 }, -- 显示偏移量
                ShowEffect = false,                      -- 是否显示特效
                ForceMapPinActive = false,               -- 是否强制激活地图标记
            },                                           -- 这里加上逗号，方便后续扩展
        },
        TargetPosition = { x = 83.158, y = 143.42, z = 118.30 },                   -- 后续替换为摆放点坐标
        ReachDistance = 5,                             -- 到达锚点1.5米范围内
    },
    ---@param obj QuestObjective40120113
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective40120113
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}

--14.到达指定地点播放互动叙事
---@class QuestObjective40120114 : Quest4012Objective
ObjectiveDefines.Obj40120114 = {
    Id = 40120114,
    Type = EQuestObjectiveType.ReachTargetPosition,
    Args = {
        LevelId = 4012,
        TracePosArgs = {
            {
                Position = { x = 100.77, y = 143.50, z = 123.5 },                 -- 目标位置（初始为空，后续需要赋值）
                DisplayOffset = { x = 0, y = 0.5, z = 0 }, -- 显示偏移量
                ShowEffect = false,                      -- 是否显示特效
                ForceMapPinActive = false,               -- 是否强制激活地图标记
            },                                           -- 这里加上逗号，方便后续扩展
        },
        TargetPosition = { x = 100.77, y = 143.50, z = 123.5 },                   -- 后续替换为摆放点坐标
        ReachDistance = 5,                             -- 到达锚点1.5米范围内
    },
    ---@param obj QuestObjective40120114
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective40120114
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}

--15.播放A2级动画：和露西亚相互送礼物
---@class QuestObjective40120115 : Quest4012Objective
ObjectiveDefines.Obj40120115 = {
    Id = 40120115,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4012,
        DramaName = "Drama_1001_027",
    },
    ---@param obj QuestObjective40120115
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective40120115
    ---@param proxy XDlcCSharpFuncs
    HandleEventFunc = function(obj, proxy, eventType, eventArgs)
    end,
    ---@param obj QuestObjective40120115
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}

--16.播放A1级动画：相约去海边
---@class QuestObjective40120116 : Quest4012Objective
ObjectiveDefines.Obj40120116 = {
    Id = 40120116,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4012,
        DramaName = "Drama_1001_028",
    },
    ---@param obj QuestObjective40120116
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective40120116
    ---@param proxy XDlcCSharpFuncs
    HandleEventFunc = function(obj, proxy, eventType, eventArgs)
    end,
    ---@param obj QuestObjective40120116
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--17.到达指定地点最后一次约会的地方
---@class QuestObjective40120117 : Quest4012Objective
ObjectiveDefines.Obj40120117 = {
    Id = 40120117,
    Type = EQuestObjectiveType.ReachTargetPosition,
    Args = {
        LevelId = 4012,
        TracePosArgs = {
            {
                Position = { x = 80.71, y = 143.58, z = 95.84 },                 -- 目标位置（初始为空，后续需要赋值）
                DisplayOffset = { x = 0, y = 0.5, z = 0 }, -- 显示偏移量
                ShowEffect = false,                      -- 是否显示特效
                ForceMapPinActive = false,               -- 是否强制激活地图标记
            },                                           -- 这里加上逗号，方便后续扩展
        },
        TargetPosition = { x = 80.71, y = 143.58, z = 95.84 },                   -- 后续替换为摆放点坐标
        ReachDistance = 5,                             -- 到达锚点1.5米范围内
    },
    ---@param obj QuestObjective40120117
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective40120117
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--18.播放B1级动画：最后一次的约会1
---@class QuestObjective40120118 : Quest4012Objective
ObjectiveDefines.Obj40120118 = {
    Id = 40120118,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4012,
        DramaName = "Drama_1001_043",
    },
    ---@param obj QuestObjective40120118
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective40120118
    ---@param proxy XDlcCSharpFuncs
    HandleEventFunc = function(obj, proxy, eventType, eventArgs)
    end,
    ---@param obj QuestObjective40120118
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--19.播放A1级动画：最后一次的约会2
---@class QuestObjective40120119 : Quest4012Objective
ObjectiveDefines.Obj40120119 = {
    Id = 40120119,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4012,
        DramaName = "Drama_1001_029",
    },
    ---@param obj QuestObjective40120119
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective40120119
    ---@param proxy XDlcCSharpFuncs
    HandleEventFunc = function(obj, proxy, eventType, eventArgs)
    end,
    ---@param obj QuestObjective40120119
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--19.播放S2级动画：时间尽头
---@class QuestObjective40120120: Quest4012Objective
ObjectiveDefines.Obj40120120 = {
    Id = 40120120,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4012,
        DramaName = "Drama_1001_030",
    },
    ---@param obj QuestObjective40120120
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective40120120
    ---@param proxy XDlcCSharpFuncs
    HandleEventFunc = function(obj, proxy, eventType, eventArgs)
    end,
    ---@param obj QuestObjective40120120
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishInstLevel() --标记当前副本关卡完成
        proxy:RequestLeaveInstanceLevel(false)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
local StepDefines = {}

StepDefines.Step401201 = {
    Id = 401201,
    ExecMode = EQuestStepExecMode.Serial,
    NeedCompleteCount = 1,
}

QuestBase.InitSteps(StepDefines)
QuestBase.InitQuestObjectives(ObjectiveBase, ObjectiveDefines)