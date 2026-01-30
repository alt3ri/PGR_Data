local XUiBattleRoleRoomDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoleRoomDefaultProxy")
---@class XUiSoloReformRoleRoomProxy : XUiBattleRoleRoomDefaultProxy
local XUiSoloReformRoleRoomProxy = XClass(XUiBattleRoleRoomDefaultProxy, "XUiSoloReformRoleRoomProxy")

--最大上阵人数
local TeamMaxCharCount = 1
function XUiSoloReformRoleRoomProxy:Ctor(team, stageId)
    self.Team = team
    self.StageId = stageId
end

function XUiSoloReformRoleRoomProxy:AOPOnStartAfter(rootUi)
    self.RootUi = rootUi
    rootUi.BtnTeamPrefab.gameObject:SetActiveEx(false)
    
    -- 隐藏UI上的2号位、3号位
    local canvasGroup2 = rootUi.BtnChar2.gameObject:AddComponent(typeof(CS.UnityEngine.CanvasGroup))
    canvasGroup2.alpha = 0
    local canvasGroup3 = rootUi.BtnChar3.gameObject:AddComponent(typeof(CS.UnityEngine.CanvasGroup))
    canvasGroup3.alpha = 0
    -- 隐藏场景上的2号位、3号位
    local sceneRoot = rootUi.UiSceneInfo.Transform
    sceneRoot:FindTransform("PanelRoleEffect2").gameObject:SetActiveEx(false)
    sceneRoot:FindTransform("PanelRoleEffect3").gameObject:SetActiveEx(false)
    -- 隐藏其他UI
    rootUi.PanelTeamLeader.gameObject:SetActiveEx(false)
    --rootUi.PanelSkill.gameObject:SetActiveEx(false)
    rootUi.BtnLeader.gameObject:SetActiveEx(false)
end

function XUiSoloReformRoleRoomProxy:AOPOnCharacterClickBefore(rootUi, index)
    if index ~= 1 then
        return true
    end    
    local isStop = false
    local isCharCntLimit = self.Team:GetEntityCount() >= TeamMaxCharCount -- 角色数量达到上限
    local isSelectedChar = self.Team:GetEntityIdByTeamPos(index) ~= 0 -- 已选择角色
    if isCharCntLimit and not isSelectedChar then
        isStop = true
    end
    return isStop
end

function XUiSoloReformRoleRoomProxy:AOPOnClickFight()
    local canEnterFight, errorTip = self:GetIsCanEnterFight(self.Team, self.StageId)
    if not canEnterFight then
        if errorTip then
            XUiManager.TipError(errorTip)
        end
        return
    end
    
    --local isAssist = CS.UnityEngine.PlayerPrefs.GetInt(XPrefs.AssistSwitch .. XPlayer.Id) == 1
    self:EnterFight(self.Team, self.StageId)
    return true
end

--列表角色控制
function XUiSoloReformRoleRoomProxy:GetRoleDetailProxy()
    return require("XUi/XUiSoloReform/XUiSoloReformRoleRoom/XUiSoloReformRoomRoleDetailProxy")
end

function XUiSoloReformRoleRoomProxy:FilterPresetTeamEntitiyIds(teamData)
    local chapterId = XMVCA.XSoloReform:GetEnterChapterId()
    if not XTool.IsNumberValid(chapterId) then
        return teamData
    end
    local chapterCfg = XMVCA.XSoloReform:GetSoloReformChapterCfg(chapterId)

    local tempTeamData = {}
    local entitiyIds = {}
    tempTeamData.TeamData = entitiyIds
    tempTeamData.CaptainPos = teamData.CaptainPos
    tempTeamData.FirstFightPos = teamData.FirstFightPos
    tempTeamData.TeamName = teamData.TeamName
    for pos, characterId in ipairs(teamData.TeamData) do
        for _, soloCharacterId in pairs(chapterCfg.UseChara) do
            if characterId == soloCharacterId then
                entitiyIds[1] = characterId --有配置的限定角色,只要1个，放红色位
                return tempTeamData
            end    
        end
    end    
    XUiManager.TipText("SoloReformNoCharacterInTeam")
    return tempTeamData
end

-- 检查是否开启效应选择
function XUiSoloReformRoleRoomProxy:CheckIsEnableGeneralSkillSelection()
    return true
end

function XUiSoloReformRoleRoomProxy:CheckStageRobotIsUseCustomProxy()
    return true
end

function XUiSoloReformRoleRoomProxy:CheckShowAnimationSet()
    return false
end

---检查index位置是否可以拖起角色
function XUiSoloReformRoleRoomProxy:CheckIsCanMoveUpCharacter(index, time)
    return false
end

return XUiSoloReformRoleRoomProxy