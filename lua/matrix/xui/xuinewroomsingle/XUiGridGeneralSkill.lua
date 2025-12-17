---这个类是控制编队房间效应按钮的
---@class _XUiPanelGeneralSkill
local XUiGridGeneralSkill = XClass(XUiNode, "XUiGridGeneralSkill")

function XUiGridGeneralSkill:OnStart(stageId)
    self._StageId = stageId
    self.BtnGeneralSkill.CallBack = handler(self,self.OnBtnClickEvent)
    self.BtnGeneralSkillNotactive.CallBack = handler(self, self.OnNoGeneralSkillBtnClickEvent)
    self:Refresh(true)

    XEventManager.AddEventListener(XEventId.EVENT_TEAM_MEMBER_MANUAL_CHANGE_MEMBER, self.OnTeamMemberManualChange, self)
end

function XUiGridGeneralSkill:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_TEAM_MEMBER_MANUAL_CHANGE_MEMBER, self.OnTeamMemberManualChange, self)
end

function XUiGridGeneralSkill:OnTeamMemberManualChange()
    -- 成员手动变更时，自动选择效应
    local stageRecommendGeneralSkills = nil
    if XTool.IsNumberValid(self.Parent.StageId) then
        stageRecommendGeneralSkills = XMVCA.XFuben:GetGeneralSkillIds(self.Parent.StageId)
    end
    -- 默认选择
    self:GetTeamData():AutoSelectGeneralSkill(stageRecommendGeneralSkills)
end

function XUiGridGeneralSkill:Refresh(noForceRefreshGeneralSkills)
    if XTool.IsTableEmpty(self.Parent) then
        if XMain.IsEditorDebug then
            XLog.Error('当前效应选择信息刷新时，父类节点不存在。该节点的状态是否有效：', self:IsValid(), '节点UI是否存在：', XTool.UObjIsNil(self.GameObject), '生命周期状态：', self._StateFlag)
        else
            XLog.CustomReport("GeneralSkillSelect", "Refresh UiNodeIsValid:", self:IsValid(), "GameObjectDestroy", XTool.UObjIsNil(self.GameObject), "UiNodeDestroy", self._StateFlag)
        end
        return
    end
    
    --判断是否需要隐藏背景遮罩(如果当前关卡有推荐效应，则会实例化以下字段名的UI控制器
    local hasRecommend = not XTool.IsTableEmpty(self.Parent.XUiPanelRecommendGeneralSkill) and true or false
    if hasRecommend then
        self.ImgBgRecommendOff1.gameObject:SetActiveEx(not hasRecommend)
        self.ImgBgRecommendOff2.gameObject:SetActiveEx(not hasRecommend)
    end
    
    local teamData = self:GetTeamData()

    -- 提取UI更新为函数，减少重复代码
    local function UpdateGeneralSkillUI(generalSkillId)
        if XTool.IsNumberValid(generalSkillId) then
            local genralSkillConfig = XMVCA.XCharacter:GetModelCharacterGeneralSkill()[generalSkillId]
            self.BtnGeneralSkill:SetRawImage(genralSkillConfig.IconTranspose)
            self.TxtGenera.text = genralSkillConfig.Name
        end
    end

    if not noForceRefreshGeneralSkills then
        teamData:RefreshGeneralSkills(false, true)
    end

    local hasGeneralSkill = teamData:CheckHasGeneralSkills()
    self.BtnGeneralSkill.gameObject:SetActiveEx(hasGeneralSkill)
    self.BtnGeneralSkillNotactive.gameObject:SetActiveEx(not hasGeneralSkill)

    if hasGeneralSkill then
        local generalSkillId = teamData:GetCurGeneralSkill()
        local needAutoSelect = false
        
        -- 检查是否需要自动选择技能
        if not XTool.IsNumberValid(generalSkillId) or XDataCenter.TeamManager.GetGeneralSkillRefreshTrigger() then
            needAutoSelect = true
        end
        
        -- 如果需要，执行自动选择
        if needAutoSelect then
            local stageRecommendGeneralSkills = nil
            if XTool.IsNumberValid(self.Parent.StageId) then
                stageRecommendGeneralSkills = XMVCA.XFuben:GetGeneralSkillIds(self.Parent.StageId)
            end
            teamData:AutoSelectGeneralSkill(stageRecommendGeneralSkills)
            generalSkillId = teamData:GetCurGeneralSkill()
        end
        
        -- 更新UI（只需要一次）
        UpdateGeneralSkillUI(generalSkillId)
    end
end

function XUiGridGeneralSkill:OnBtnClickEvent()
    if self.Parent and self.Parent.Proxy and self.Parent.StageId and not self.Parent.Proxy:CheckIsCanEditorTeam(self.Parent.StageId, true) then
        return
    end

    local teamData = self:GetTeamData()
    if teamData:CheckHasGeneralSkills() then
        XLuaUiManager.OpenWithCloseCallback('UiBattleRoomGeneralSkillSelect', function() 
            self:Refresh(true)
            if self.Parent and self.Parent.RefreshRoleDetalInfo then
                self.Parent:RefreshRoleDetalInfo()
            end
        end, self.Parent.StageId, teamData)
    else
        XUiManager.TipText('BattleRoleRoomNoGeneralSkillTips')
    end
end

function XUiGridGeneralSkill:OnNoGeneralSkillBtnClickEvent()
    XUiManager.TipText('BattleRoleRoomNoGeneralSkillTips')
end

---@return XTeam 
function XUiGridGeneralSkill:GetTeamData()
    return self.Parent.Team
end

return XUiGridGeneralSkill