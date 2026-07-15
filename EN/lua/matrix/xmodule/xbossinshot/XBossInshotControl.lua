---@class XBossInshotControl : XControl
---@field _Model XBossInshotModel
local XBossInshotControl = XClass(XControl, "XBossInshotControl")
function XBossInshotControl:OnInit()
    --初始化内部变量
end

function XBossInshotControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XBossInshotControl:RemoveAgencyEvent()

end

function XBossInshotControl:OnRelease()
    --XLog.Error("这里执行Control的释放")
end

--- 获取当前开启活动Id
function XBossInshotControl:GetActivityId()
    return self._Model:GetActivityId()
end

--- 获取活动的结束时间戳
--- @param id number 活动Id
function XBossInshotControl:GetActivityEndTime(id)
    return self._Model:GetActivityEndTime(id)
end

--- 获取活动是否开启
function XBossInshotControl:IsActivityOpen()
    return self._Model:IsActivityOpen()
end

--- 处理活动结束
function XBossInshotControl:HandleActivityEnd()
    XUiManager.TipText("ActivityAlreadyOver")
    XLuaUiManager.RunMain()
end

--- 设置重新战斗状态
function XBossInshotControl:SetAgainFight(isAgainFight)
    return self._Model:SetAgainFight(isAgainFight)
end

--- 设置重新战斗状态
function XBossInshotControl:GetAgainFight()
    return self._Model:GetAgainFight()
end

--- 获取活动缓存队伍信息
function XBossInshotControl:GetTeam()
    return self._Model:GetTeam()
end

--- 关卡是否解锁
function XBossInshotControl:IsStageUnlock(inshotStageId)
    return self._Model:IsStageUnlock(inshotStageId)
end

--- 获取通关关卡数据
function XBossInshotControl:GetPassStageData(stageId)
    return self._Model:GetPassStageData(stageId)
end

--- 教学关是否通关
function XBossInshotControl:IsTeachStagePass()
    return self._Model:IsTeachStagePass()
end

--- 获取角色选择天赋Id列表
function XBossInshotControl:GetCharacterSelectTalentIds(characterId)
    return self._Model:GetCharacterSelectTalentIds(characterId)
end

--- 角色天赋是否解锁
function XBossInshotControl:IsCharacterTalentUnlock(characterId, talentId)
    return self._Model:IsCharacterTalentUnlock(characterId, talentId)
end

--- 是否显示任务红点
function XBossInshotControl:IsShowTaskRed()
    return self._Model:IsShowTaskRed()
end

--- 获取是否显示回放功能
function XBossInshotControl:GetIsShowPlayback(stageId)
    return self._Model:GetIsShowPlayback(stageId)
end

--- 生成最后战斗的录像数据
function XBossInshotControl:GenLastPlaybackData(bossId, score, scoreLevelIcon, difficulty, towerLevelId)
    return self._Model:GenLastPlaybackData(bossId, score, scoreLevelIcon, difficulty, towerLevelId)
end

--- 获取回放数据
function XBossInshotControl:GetPlaybackDatas(bossId)
    return self._Model:GetPlaybackDatas(bossId)
end

--- 保存回放数据
function XBossInshotControl:SavePlaybackData(bossId, pos, playbackData)
    return self._Model:SavePlaybackData(bossId, pos, playbackData)
end

--- 删除回放数据
function XBossInshotControl:DeletePlaybackData(bossId, pos)
    return self._Model:DeletePlaybackData(bossId, pos)
end

--- 获取新解锁的天赋列表
function XBossInshotControl:GetNewUnlockTalentIds()
    return self._Model:GetNewUnlockTalentIds()
end

--- 是否节日副本中的特定关卡
function XBossInshotControl:IsFestivalActivityStage(stageId)
    return XDataCenter.FubenFestivalActivityManager.IsBossInshotSettlementShowStage(stageId)
end

---------------------------------------- #region 配置表 ----------------------------------------
--- 获取活动配置表
function XBossInshotControl:GetConfigBossInshotActivity(id)
    return self._Model:GetConfigBossInshotActivity(id)
end

--- 获取活动配置bossId列表
function XBossInshotControl:GetActivityBossIds(id)
    return self._Model:GetActivityBossIds(id)
end

function XBossInshotControl:GetTowerBossIds()
    return self._Model:GetTowerBossIds()
end

--- 获取活动配置任务组列表
function XBossInshotControl:GetActivityTaskGroupIds(id)
    return self._Model:GetActivityTaskGroupIds(id)
end

--- 获取活动配置教学关卡Id
function XBossInshotControl:GetActivityTeachStageId(id)
    return self._Model:GetActivityTeachStageId(id)
end

--- 获取活动角色Id列表
function XBossInshotControl:GetActivityCharacterIds(id)
    return self._Model:GetActivityCharacterIds(id)
end

--- 获取活动任务展示奖励
function XBossInshotControl:GetActivityPreviewTaskRewardId(id)
    return self._Model:GetActivityPreviewTaskRewardId(id)
end

--- 获取Boss的名称
function XBossInshotControl:GetBossName(id)
    return self._Model:GetBossName(id)
end

--- 获取Boss的模型Id
function XBossInshotControl:GetBossModelId(id)
    return self._Model:GetBossModelId(id)
end

--- 获取Boss的头像
function XBossInshotControl:GetBossHeadIcon(id)
    return self._Model:GetBossHeadIcon(id)
end

--- 获取Boss的技能Id列表
function XBossInshotControl:GetBossSkillIds(id)
    return self._Model:GetBossSkillIds(id)
end

--- 获取Boss的开启时间
function XBossInshotControl:GetBossOpenTimeId(id)
    return self._Model:GetBossOpenTimeId(id)
end

--- 获取成员配置表
function XBossInshotControl:GetConfigBossInshotCharacter(id)
    return self._Model:GetConfigBossInshotCharacter(id)
end

-- 获取成员名称
function XBossInshotControl:GetCharacterName(id)
    return self._Model:GetCharacterName(id)
end

--- 获取分数配置表
function XBossInshotControl:GetConfigBossInshotScore(id)
    return self._Model:GetConfigBossInshotScore(id)
end

--- 获取评分对应等级图标
function XBossInshotControl:GetScoreLevelIcon(difficulty, score)
    return self._Model:GetScoreLevelIcon(difficulty, score)
end

--- 获取评分对应等级大图标
function XBossInshotControl:GetScoreLevelBigIcon(difficulty, score)
    return self._Model:GetScoreLevelBigIcon(difficulty, score)
end

--- 获取评分对应特效名
function XBossInshotControl:GetScoreLevelEffectName(difficulty, score)
    return self._Model:GetScoreLevelEffectName(difficulty, score)
end

--- 获取达到下一评分等级提示
function XBossInshotControl:GetNextScoreLevelTips(difficulty, score)
    return self._Model:GetNextScoreLevelTips(difficulty, score)
end

--- 获取技能配置表
function XBossInshotControl:GetConfigBossInshotSkill(id)
    return self._Model:GetConfigBossInshotSkill(id)
end

--- 获取技能名称
function XBossInshotControl:GetSkillName(id)
    return self._Model:GetSkillName(id)
end

--- 获取技能提示
function XBossInshotControl:GetSkillTips(id)
    return self._Model:GetSkillTips(id)
end

--- 获取技能描述
function XBossInshotControl:GetSkillDesc(id)
    return self._Model:GetSkillDesc(id)
end

--- 获取技能视频路径
function XBossInshotControl:GetSkillVideoUrl(id)
    return self._Model:GetSkillVideoUrl(id)
end

--- 获取技能对应练习关
function XBossInshotControl:GetSkillPracticeStageId(id)
    return self._Model:GetSkillPracticeStageId(id)
end

--- 获取关卡名称
function XBossInshotControl:GetStageName(id)
    return self._Model:GetStageName(id)
end

--- 获取关卡难度
function XBossInshotControl:GetStageDifficulty(inshotStageId)
    return self._Model:GetStageDifficulty(inshotStageId)
end

--- 获取关卡Id
function XBossInshotControl:GetInshotStageIdByStageId(stageId)
    return self._Model:GetInshotStageIdByStageId(stageId)
end

--- 获取关卡解锁conditionId
function XBossInshotControl:GetStageUnlockConditionId(id)
    return self._Model:GetStageUnlockConditionId(id)
end

--- 获取关卡对应stageId
function XBossInshotControl:GetStageStageId(id)
    return self._Model:GetStageStageId(id)
end

--- 获取关卡的BossId
function XBossInshotControl:GetStageBossId(id)
    return self._Model:GetStageBossId(id)
end

--- 获取Boss的关卡列表
function XBossInshotControl:GetBossStageIds(bossId)
    return self._Model:GetBossStageIds(bossId)
end

--- 获取天赋配置表
function XBossInshotControl:GetConfigBossInshotTalent(id)
    return self._Model:GetConfigBossInshotTalent(id)
end

-- 获得爬塔楼层表
function XBossInshotControl:GetConfigBossInshotTowerAllLevels()
    return self._Model:GetConfigBossInshotTowerAllLevels()
end

--- 获取角色默认穿戴天赋配置表
function XBossInshotControl:GetCharacterDefaultWearTalentCfg(characterId)
    return self._Model:GetCharacterDefaultWearTalentCfg(characterId)
end

--- 获取角色手动穿戴天赋配置表列表
function XBossInshotControl:GetCharacterHandWearTalentCfgs(characterId)
    return self._Model:GetCharacterHandWearTalentCfgs(characterId)
end

-- 获取排名特殊图片
function XBossInshotControl:GetRankingSpecialIcon(rank)
    if type(rank) ~= "number" or rank < 1 or rank > 3 then
        return
    end
    return CS.XGame.ClientConfig:GetString("BabelTowerRankIcon" .. rank)
end

-- 获取结算评分特效名
function XBossInshotControl:GetMarkEffectName(id)
    return self._Model:GetMarkEffectName(id)
end
---------------------------------------- #endregion 配置表 ----------------------------------------


---------------------------------------- #region 爬塔 ----------------------------------------

-- 塔是否解锁
function XBossInshotControl:IsTowerUnlocked()
    local activityId = self._Model:GetActivityId()
    local activityConf = self._Model:GetConfigBossInshotActivity(activityId)
    for _, condition in pairs(activityConf.TowerConditions) do
        if not XConditionManager.CheckCondition(condition) then
            return false, condition
        end
    end

    return true
end

-- 获取爬塔评分对应等级配置
function XBossInshotControl:GetTowerScoreLevelConf(level, score)
    return self._Model:GetTowerScoreLevelConf(level, score)
end

-- 获取爬塔数据
function XBossInshotControl:GetBossTowerData(levelId)
    return self._Model:GetBossTowerData(levelId)
end

-- 获得当前所在楼层
function XBossInshotControl:GetBossTowerCurrentLevel()
    return self._Model:GetBossTowerCurrentLevel()
end

-- 获得当前已通关的最高楼层
function XBossInshotControl:GetBossTowerPassedHighestLevel()
    local passedLevel = self._Model:GetBossTowerCurrentLevel()

    while passedLevel > 0 do
        if self:HasPassedTowerLevel(passedLevel) then
            return passedLevel
        end

        passedLevel = passedLevel - 1
    end

    return passedLevel
end

-- 是否已全部通关
function XBossInshotControl:IsTowerAllClear()
    local allLevelConf = self:GetConfigBossInshotTowerAllLevels()
    local curLevel = self:GetBossTowerCurrentLevel()
    local curLevelData = self:GetBossTowerData(curLevel)
    local nextLevelConf = allLevelConf[curLevel + 1]
    if not nextLevelConf and curLevelData.IsPass then return true end
    return false
end

-- 是否为塔的最终关卡
function XBossInshotControl:IsTowerFinalLevel(levelId)
    local allLevelConf = self:GetConfigBossInshotTowerAllLevels()
    return not allLevelConf[levelId + 1]
end

-- 是否已经通关指定楼层
function XBossInshotControl:HasPassedTowerLevel(levelId)
    local data = self:GetBossTowerData(levelId)
    if not data then return false end
    return data.IsPass or false
end

-- 是否有需要进入下一楼层
function XBossInshotControl:HasNeedTryEnterNextLevel()
    -- 当前在0层则需要
    local currentLevel = self:GetBossTowerCurrentLevel()
    if currentLevel == 0 then return true end

    -- 到达最高层则不需要
    local nextLevelConf = self:GetConfigBossInshotTowerAllLevels()[currentLevel + 1]
    if not nextLevelConf then return false end

    -- 此层通关且下一层在时间范围内则需要
    local currentLevelData = self:GetBossTowerData(currentLevel)
    if currentLevelData.IsPass and XFunctionManager.CheckInTimeByTimeId(nextLevelConf.TimeId) then
        return true
    end

    -- 其他情况下不需要
    return false
end

-- 根据爬塔关卡Id获得它的BossId
function XBossInshotControl:GetTowerBossIdByStageId(towerStageId)
    return self._Model:GetTowerBossIdByStageId(towerStageId)
end

-- 弹出Toast数据，以弹出各种上升下降弹窗，如果队列为空则返回nil
function XBossInshotControl:GetAndClearToastData()
    return self._Model:GetAndClearToastData()
end

-- 是否具有Toast数据
function XBossInshotControl:HasToastData()
    return self._Model:HasToastData()
end

-- 尝试进入下一层
function XBossInshotControl:TryEnterNextLevel(cbWithResult)
    XNetwork.Call("BossInshotEnterNextTowerRequest", {}, function(resp)
        if resp.Code == XCode.Success then
            self._Model:OnEnterNextLevel(resp.NextTowerData)
        end

        cbWithResult(resp)
    end)
end

-- 在未通关的时候，为具有多个Boss的关卡选择一关
function XBossInshotControl:TowerSelectStage(levelId, stageId, cb)
    XNetwork.Call(
        "BossInshotTowerSelectBossRequest",
        {
            TowerId = levelId,
            StageId = stageId
        },
        function(resp)
            if resp.Code == XCode.Success then
                self._Model:OnSelectLevel(levelId, stageId)
            end

            cb(resp)
        end)
end

-- 在通关后，为具有多个Boss的关卡选择一关
function XBossInshotControl:TowerSelectStageAfterAllClear(levelId, stageId, cb)
    XNetwork.Call(
        "BossInshotTowerSelectBossAfterAllPassRequest",
        {
            TowerId = levelId,
            StageId = stageId
        },
        function(resp)
            if resp.Code == XCode.Success then
                self._Model:OnSelectLevelAfterAllClear(levelId, stageId)
            end

            cb(resp)
        end)
end

---------------------------------------- #endregion 爬塔 ----------------------------------------
return XBossInshotControl
