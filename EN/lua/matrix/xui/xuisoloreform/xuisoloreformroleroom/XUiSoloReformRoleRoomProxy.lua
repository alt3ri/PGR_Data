local XUiBattleRoleRoomDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoleRoomDefaultProxy")
---@class XUiSoloReformRoleRoomProxy : XUiBattleRoleRoomDefaultProxy
local XUiSoloReformRoleRoomProxy = XClass(XUiBattleRoleRoomDefaultProxy, "XUiSoloReformRoleRoomProxy")

function XUiSoloReformRoleRoomProxy:Ctor(team, stageId)
    self.Team = team
    self.StageId = stageId
end

--最大上阵人数,读章节配置CharacterCount,默认1并钳制到队伍上限3
function XUiSoloReformRoleRoomProxy:GetMaxCharCount()
    if self._MaxCharCount then
        return self._MaxCharCount
    end
    local chapterId = XMVCA.XSoloReform:GetEnterChapterId()
    self._MaxCharCount = XMVCA.XSoloReform:GetChapterCharacterCount(chapterId)
    return self._MaxCharCount
end

--强制机器人数超过可上场数时,编队界面清掉超出号位(只留前N个),与PreFight截断保持一致
function XUiSoloReformRoleRoomProxy:ClearErrorTeamEntityId(team, ...)
    XUiBattleRoleRoomDefaultProxy.ClearErrorTeamEntityId(self, team, ...)
    local maxCount = self:GetMaxCharCount()
    local entityIds = team:GetEntityIds()
    for pos = maxCount + 1, #entityIds do
        if XTool.IsNumberValid(entityIds[pos]) then
            team:UpdateEntityTeamPos(entityIds[pos], pos, false) -- isJoin=false 即移除
        end
    end
end

function XUiSoloReformRoleRoomProxy:AOPOnStartAfter(rootUi)
    self.RootUi = rootUi
    rootUi.BtnTeamPrefab.gameObject:SetActiveEx(false)

    -- 按上阵人数隐藏多余号位(UI + 场景特效)
    local maxCount = self:GetMaxCharCount()
    local sceneRoot = rootUi.UiSceneInfo.Transform
    
    if maxCount < 2 then
        self.CanvasGroup2 = rootUi.BtnChar2.gameObject:AddComponent(typeof(CS.UnityEngine.CanvasGroup))
        self.CanvasGroup2.alpha = 0
        sceneRoot:FindTransform("PanelRoleEffect2").gameObject:SetActiveEx(false)
    end
    if maxCount < 3 then
        self.CanvasGroup3 = rootUi.BtnChar3.gameObject:AddComponent(typeof(CS.UnityEngine.CanvasGroup))
        self.CanvasGroup3.alpha = 0
        sceneRoot:FindTransform("PanelRoleEffect3").gameObject:SetActiveEx(false)
    end
    -- 隐藏其他UI
    rootUi.PanelTeamLeader.gameObject:SetActiveEx(false)
    --rootUi.PanelSkill.gameObject:SetActiveEx(false)
    rootUi.BtnLeader.gameObject:SetActiveEx(false)
end

function XUiSoloReformRoleRoomProxy:AOPOnCharacterClickBefore(rootUi, index)
    local maxCount = self:GetMaxCharCount()
    if index > maxCount then
        return true
    end
    local isCharCntLimit = self.Team:GetEntityCount() >= maxCount -- 角色数量达到上限
    local isSelectedChar = self.Team:GetEntityIdByTeamPos(index) ~= 0 -- 已选择角色
    return isCharCntLimit and not isSelectedChar
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

    -- 按上阵人数,顺序填入命中限定角色的预设角色
    local maxCount = self:GetMaxCharCount()
    local count = 0
    for _, characterId in ipairs(teamData.TeamData) do
        if table.contains(chapterCfg.UseChara, characterId) then
            count = count + 1
            entitiyIds[count] = characterId
            if count >= maxCount then
                break
            end
        end
    end
    if count == 0 then
        XUiManager.TipText("SoloReformNoCharacterInTeam")
    end
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
    local maxCount = self:GetMaxCharCount()
    return maxCount > 1
end

return XUiSoloReformRoleRoomProxy