local QuestBase = require("Common/XQuestBase")
-------------------任务脚本类定义，用任务ID替换这块内容里的XXXX和0000
---@class XQuestScriptXXXX
local XQuestScriptXXXX = XDlcScriptManager.RegQuestScript(0000, "XQuestScriptXXXX", QuestBase)

---@param proxy StatusSyncFight.XFightScriptProxy
function XQuestScriptXXXX:Ctor(proxy)
    self._proxy = proxy ---@type XDlcCSharpFuncs
end

function XQuestScriptXXXX:Init()
end

function XQuestScriptXXXX:Terminate()
end
-------------------------------------

-------------------任务目标的基类定义，为了方便访问quest，用任务ID替换这块内容里的XXXX
---@class QuestXXXXObjective
local ObjectiveBase = XClass(nil, "QuestXXXXObjective")

---@param quest XQuestScriptXXXX
function ObjectiveBase:Ctor(quest)
    self.quest = quest
end
-------------------------------------

local ObjectiveDefines = {} --本任务包含的所有任务目标的定义，包含参数和逻辑（不要删除！）

---------单个任务目标的定义，用任务ID替换XXXX或0000，用objective的ID后几位（一般是去掉任务ID后剩余的那几位）替换YYY
---------替换操作，推荐用快捷键 Ctrl + R 完成，IDEA能够自动重构引用到的地方，不用一个个改
---@class QuestObjectiveXXXXYYY : QuestXXXXObjective
ObjectiveDefines.ObjXXXXYYY = {
    Id = 00000, --该任务目标的ID，和配表里的保持一致（必填！）
    Type = EQuestObjectiveType.InteractComplete, --该任务目标的类型，只能使用枚举EQuestObjectiveType来填（必填！）
    Args = {
        LevelId = 4011, --该任务目标所属关卡（必填！）
        TargetType = ETargetActorType.Npc,
        TargetPlaceId = 1,
    },
    ---@param obj QuestObjectiveXXXXYYY
    InitFunc = function(obj) --完全没有初始化逻辑要写时，可以删除或屏蔽该函数定义

    end,
    ---@param obj QuestObjectiveXXXXYYY
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy) --完全没有进入逻辑要写时，可以删除或屏蔽该函数定义
        --进入逻辑，做一些准备工作，例如加载某个NPC或者场景物件
        proxy:FinishQuestObjectiveScriptEnter()--必要语句，如果有上面的进入逻辑
    end,
    ---@param obj QuestObjectiveXXXXYYY
    ---@param proxy XDlcCSharpFuncs
    HandleEventFunc = function(obj, proxy, eventType, eventArgs)

    end,
    ---@param obj QuestObjectiveXXXXYYY
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy) --完全没有退出逻辑要写时，可以删除或屏蔽该函数定义
        --退出逻辑，做一些善后工作，例如销毁/卸载某个npc
        proxy:FinishQuestObjectiveScriptExit()--必要语句，如果有上面的退出逻辑
    end,
}

local StepDefines = {} --本任务包含的所有任务步骤的参数配置（不要删除！）

--Step的参数配置，至少要有一个，可按需增加
StepDefines.Step000000 = {
    Id = 000000,
    ExecMode = EQuestStepExecMode.Serial,
}

QuestBase.InitSteps(StepDefines) --固定的任务步骤数据初始化调用（不要删除！）
QuestBase.InitQuestObjectives(ObjectiveBase, ObjectiveDefines) --固定的任务目标数据初始化调用（不要删除！）





---------------------------以下是旧规范代码，不要复制---------------------------

----===================[[ 任务步骤]]
----region ========================[[ 步骤1 ]]=============================>>
-----@param self XQuestScriptXXXX
--XQuestScriptXXX.StepEnterFuncs[1] = function(self)
--    --步骤的初始化，例如：
--    --刷怪，生成动态对象等
--end
--
-----@param self XQuestScriptXXXX
--XQuestScriptXXX.StepHandleEventFuncs[1] = function(self, eventType, eventArgs)
--    --步骤1的事件响应，例如：
--    --怪物击杀，进入某区域等事件的响应
--end
--
-----@param self XQuestScriptXXXX
--XQuestScriptXXX.StepExitFuncs[1] = function(self)
--    --步骤的结束处理，例如：
--    --移除任务时创建的临时对象
--    --如果特殊完成逻辑的定制
--end
----endregion ========================[[ 步骤1 ]]=============================<<