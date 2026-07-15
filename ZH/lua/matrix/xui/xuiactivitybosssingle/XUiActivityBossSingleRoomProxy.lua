local XUiBattleRoleRoomDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoleRoomDefaultProxy")

--- 超难关编队界面代理
---@class XUiActivityBossSingleRoomProxy : XUiBattleRoleRoomDefaultProxy
local XUiActivityBossSingleRoomProxy = XClass(XUiBattleRoleRoomDefaultProxy, "XUiActivityBossSingleRoomProxy")

local MAX_ROLE_COUNT = 3

function XUiActivityBossSingleRoomProxy:Ctor(team, stageId, proxyArg)
    self._NeedCharacterCount = (proxyArg and proxyArg.NeedCharacterCount) or MAX_ROLE_COUNT
    self._RobotIds = proxyArg and proxyArg.RobotIds
end

function XUiActivityBossSingleRoomProxy:OnNotify(evt, ...)
    if evt == XEventId.EVENT_ACTIVITY_ON_RESET then
        XDataCenter.FubenActivityBossSingleManager.OnActivityEnd()
    end
end

function XUiActivityBossSingleRoomProxy:GetRoleDetailProxy()
    local _RobotIds = self._RobotIds
    return {
        GetEntities = function()
            local entities = {}
            local ids = XMVCA.XCharacter:GetRobotAndCharacterIdList(_RobotIds)
            for i, id in ipairs(ids or {}) do
                if XRobotManager.CheckIsRobotId(id) then
                    entities[i] = XRobotManager.GetRobotById(id)
                else
                    entities[i] = XMVCA.XCharacter:GetCharacter(id)
                end
            end
            return entities
        end
    }
end

function XUiActivityBossSingleRoomProxy:CheckShowAnimationSet()
    return false
end

--######################## AOP ########################

function XUiActivityBossSingleRoomProxy:AOPOnEnableAfter(rootUi)
    local count = self._NeedCharacterCount
    if count >= MAX_ROLE_COUNT then return end
    for pos = count + 1, MAX_ROLE_COUNT do
        if rootUi["BtnChar" .. pos] then
            rootUi["BtnChar" .. pos].gameObject:SetActiveEx(false)
        end
    end
    
    if count ~= MAX_ROLE_COUNT then
        rootUi.BtnTeamPrefab.gameObject:SetActiveEx(false)
    else
        rootUi.BtnTeamPrefab.gameObject:SetActiveEx(true)
    end
end


function XUiActivityBossSingleRoomProxy:AOPOnFirstFightBtnClick(buttonGroup, index, team)
    return index > self._NeedCharacterCount
end

function XUiActivityBossSingleRoomProxy:CheckIsCanMoveUpCharacter(index, time)
    return index <= self._NeedCharacterCount
end

function XUiActivityBossSingleRoomProxy:CheckIsCanMoveDownCharacter(index)
    return index <= self._NeedCharacterCount
end

return XUiActivityBossSingleRoomProxy
