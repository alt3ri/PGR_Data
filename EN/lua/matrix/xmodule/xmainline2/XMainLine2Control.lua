---@class XMainLine2Control : XControl
---@field _Model XMainLine2Model
local XMainLine2Control = XClass(XControl, "XMainLine2Control")

local ChapterIdEnum = {
    Kamui4P5 = 1041,
}

function XMainLine2Control:OnInit()
    --初始化内部变量
    ---@type XMainLine2MessageControl
    self.MessageControl = self:AddSubControl(require("XModule/XMainLine2/SubModules/Message/XMainLine2MessageControl"))
    ---@type XMainLine2UiStageAreaControl
    self.UiStageAreaControl = self:AddSubControl(require("XModule/XMainLine2/SubModules/UiStageArea/XMainLine2UiStageAreaControl"))
    
    --- 内部事件
    self.EventIds = {
        FOCUS_STAGE_WITH_AREA_GROUP = 1, -- 在配置了区域的情况下，聚焦指定关卡
    }
end

function XMainLine2Control:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XMainLine2Control:RemoveAgencyEvent()

end

function XMainLine2Control:OnRelease()
    --XLog.Error("这里执行Control的释放")
end

--#region 服务端数据 -------------------------------------------------------------------------------------------------
-- 获取主章节是否已领取成就
function XMainLine2Control:IsAchievementGet(mainId)
    return self._Model:IsAchievementGet(mainId)
end

-- 获取章节奖励是否已领取，服务器记录的下标从0开始
function XMainLine2Control:IsTreasureGet(chapterId, index)
    return self._Model:IsTreasureGet(chapterId, index)
end

-- 获取主章节奖励是否已领取，服务器记录的下标从0开始
function XMainLine2Control:IsMainTreasureGet(mainId, index)
    return self._Model:IsMainTreasureGet(mainId, index)
end

--#endregion ---------------------------------------------------------------------------------------------------------

--#region 配置表 --------------------------------------------------------------------------------------------------
-- 获取主章节配置表
function XMainLine2Control:GetConfigMain(mainId)
    return self._Model:GetConfigMain(mainId)
end

-- 获取主章节的章节列表
function XMainLine2Control:GetMainChapterIds(mainId)
    return self._Model:GetMainChapterIds(mainId)
end

-- 获取主章节的成就
function XMainLine2Control:GetMainAchievementId(mainId)
    return self._Model:GetMainAchievementId(mainId)
end

-- 获取主章节的特殊特效
function XMainLine2Control:GetSpecialEffect(mainId)
    return self._Model:GetSpecialEffect(mainId)
end

-- 获取主章节是否隐藏模式选项
function XMainLine2Control:GetMainHideChapterOption(mainId)
    return self._Model:GetMainHideChapterOption(mainId)
end

-- 获取主章节任务组Id
function XMainLine2Control:GetMainTaskGroupId(mainId)
    return self._Model:GetMainTaskGroupId(mainId)
end

-- 获取章节配置表
function XMainLine2Control:GetConfigChapter(chapterId)
    return self._Model:GetConfigChapter(chapterId)
end

-- 获取章节难度
function XMainLine2Control:GetChapterDifficult(chapterId)
    return self._Model:GetChapterDifficult(chapterId)
end

-- 获取章节描述
function XMainLine2Control:GetChapterDesc(chapterId)
    return self._Model:GetChapterDesc(chapterId)
end

-- 获取章节难度名称
function XMainLine2Control:GetChapterDifficultName(chapterId)
    return self._Model:GetChapterDifficultName(chapterId)
end

-- 获取章节难度英文名称
function XMainLine2Control:GetChapterDifficultEnName(chapterId)
    return self._Model:GetChapterDifficultEnName(chapterId)
end

-- 获取章节难度颜色
function XMainLine2Control:GetChapterDifficultColor(chapterId)
    return self._Model:GetChapterDifficultColor(chapterId)
end

-- 获取章节限时开放TimerId
function XMainLine2Control:GetChapterActivityTimeId(chapterId)
    return self._Model:GetChapterActivityTimeId(chapterId)
end

-- 获取章节预置名称
function XMainLine2Control:GetChapterPrefabName(chapterId)
    return self._Model:GetChapterPrefabName(chapterId)
end

-- 获取章节背景图对应关卡下标列表
function XMainLine2Control:GetChapterBgStageIndexs(chapterId)
    return self._Model:GetChapterBgStageIndexs(chapterId)
end

-- 获取章节的最后一个stageId
function XMainLine2Control:GetChapterLastStageId(chapterId)
    return self._Model:GetChapterLastStageId(chapterId)
end

-- 获取章节背景图Spine进度的关卡下标
function XMainLine2Control:GetChapterBgSpineStageIndexs(chapterId)
    return self._Model:GetChapterBgSpineStageIndexs(chapterId)
end

-- 获取章节背景图Spine进度
function XMainLine2Control:GetChapterBgSpineProgressWans(chapterId)
    return self._Model:GetChapterBgSpineProgressWans(chapterId)
end

-- 获取章节Spine进度的关卡下标
function XMainLine2Control:GetChapterSpineStageIndexs(chapterId)
    return self._Model:GetChapterSpineStageIndexs(chapterId)
end

-- 获取章节Spine进度
function XMainLine2Control:GetChapterSpineProgressWans(chapterId)
    return self._Model:GetChapterSpineProgressWans(chapterId)
end

-- 获取主章节标题
function XMainLine2Control:GetMainTitle(mainId)
    return self._Model:GetMainTitle(mainId)
end

-- 获取主章节结算背景图
function XMainLine2Control:GetMainSettlementBg(mainId)
    return self._Model:GetMainSettlementBg(mainId)
end

-- 获取关卡分组表
function XMainLine2Control:GetConfigStageGroup(partId)
    return self._Model:GetConfigStageGroup(partId)
end

-- 获取关卡表
function XMainLine2Control:GetConfigStage(stageId)
    return self._Model:GetConfigStage(stageId)
end

-- 获取关卡细分类型
function XMainLine2Control:GetStageDetailType(stageId)
    return self._Model:GetStageDetailType(stageId)
end

-- 关卡是否忽略新章节标签、完成进度的计算
function XMainLine2Control:IsStageIgnore(stageId)
    return self._Model:IsStageIgnore(stageId)
end

-- 获取关卡VideoId
function XMainLine2Control:GetStageVideoId(stageId)
    local videoIds = self._Model:GetStageVideoIds(stageId)
    if #videoIds == 0 then return end

    local conditions = self._Model:GetStageVideoConditions(stageId)
    for i, videoId in ipairs(videoIds) do
        local condition = conditions[i]
        if condition and condition ~= 0 then
            local isReach, desc = XConditionManager.CheckCondition(condition)
            if isReach then
                return videoId
            end
        end
    end
    return videoIds[1]
end

-- 获取关卡特殊序号
function XMainLine2Control:GetStageSpecialorder(stageId)
    return self._Model:GetStageSpecialorder(stageId)
end

-- 获取关卡怪物头像
function XMainLine2Control:GetStageMonsterHeads(stageId)
    return self._Model:GetStageMonsterHeads(stageId)
end

-- 获取关卡怪物头像替换位置
function XMainLine2Control:GetStageMonsterReplaceOrders(stageId)
    return self._Model:GetStageMonsterReplaceOrders(stageId)
end

-- 获取关卡特效路径
function XMainLine2Control:GetStageEffectPath(stageId)
    return self._Model:GetStageEffectPath(stageId)
end

-- 获取通关奖励表
function XMainLine2Control:GetConfigTreasure(treasureId)
    return self._Model:GetConfigTreasure(treasureId)
end

-- 获取成就表
function XMainLine2Control:GetConfigAchievement(achievementId)
    return self._Model:GetConfigAchievement(achievementId)
end

-- 获取成就奖励Id
function XMainLine2Control:GetAchievementClearRewardId(achievementId)
    return self._Model:GetAchievementClearRewardId(achievementId)
end

-- 获取成就图标
function XMainLine2Control:GetAchievementIcon(achievementId)
    return self._Model:GetAchievementIcon(achievementId)
end

-- 获取成就未解锁图标
function XMainLine2Control:GetAchievementIconLock(achievementId)
    return self._Model:GetAchievementIconLock(achievementId)
end

function XMainLine2Control:GetEggTipsText(eggId)
    return self._Model:GetEggTipsText(eggId)
end

function XMainLine2Control:GetEggTitle(eggId)
    return self._Model:GetEggTitle(eggId)
end

function XMainLine2Control:GetEggDesc(eggId)
    return self._Model:GetEggDesc(eggId)
end

function XMainLine2Control:GetEggRewardId(eggId)
    return self._Model:GetEggRewardId(eggId)
end

function XMainLine2Control:IsClientConfigExit(key)
    return self._Model:IsClientConfigExit(key)
end

-- 获取客户端配置表参数
function XMainLine2Control:GetClientConfigParams(key, index)
    return self._Model:GetClientConfigParams(key, index)
end

function XMainLine2Control:GetClientConfigNumber(key, index)
    return self._Model:GetClientConfigNumber(key, index)
end

--#endregion 配置表 -----------------------------------------------------------------------------------------------

--- 主章节是否全通关
---@param mainId number 主章节Id
function XMainLine2Control:IsMainPassed(mainId)
    return self._Model:IsMainPassed(mainId)
end

--- 主章节奖励是否领取完成
---@param mainId number 主章节Id
function XMainLine2Control:IsMainTreasureFinish(mainId)
    return self._Model:IsMainTreasureFinish(mainId)
end

--- 获取主章节进度
---@param mainId number 主章节Id
function XMainLine2Control:GetMainProgress(mainId)
    return self._Model:GetMainProgress(mainId)
end

--- 章节是否通关
---@param chapterId number 章节Id
function XMainLine2Control:IsChapterPassed(chapterId)
    return self._Model:IsChapterPassed(chapterId)
end

--- 章节是否解锁
---@param chapterId number 章节Id
function XMainLine2Control:IsChapterUnlock(chapterId)
    return self._Model:IsChapterUnlock(chapterId)
end

--- 章节奖励是否领取完成
---@param chapterId number 章节Id
function XMainLine2Control:IsChapterTreasureFinish(chapterId)
    return self._Model:IsChapterTreasureFinish(chapterId)
end

--- 章节是否显示蓝点
---@param chapterId number 章节Id
function XMainLine2Control:IsChapterRed(chapterId)
    return self._Model:IsChapterRed(chapterId)
end

--- 获取章节通关进度
---@param chapterId number 章节Id
function XMainLine2Control:GetChapterProgress(chapterId)
    return self._Model:GetChapterProgress(chapterId)
end

--- 获取章节所有关卡入口的数据
---@param chapterId number 章节Id
function XMainLine2Control:GetChapterEntranceDatas(chapterId)
    local entrances = {}
    local chapterCfg = self:GetConfigChapter(chapterId)
    for _, groupId in ipairs(chapterCfg.StageGroupIds) do
        local groupCfg = self:GetConfigStageGroup(groupId)

        -- 一个关卡一个入口
        if groupCfg.GroupType == XEnumConst.MAINLINE2.GROUP_TYPE.INDEPENDENT_ENTRANCE then
            for _, stageId in ipairs(groupCfg.StageIds) do
                table.insert(entrances, { StageIds = {stageId}, GroupId = groupId })
            end
        -- 多个关卡同个入口
        elseif groupCfg.GroupType == XEnumConst.MAINLINE2.GROUP_TYPE.COMBINE_ENTRANCE then
            local stageIds = XTool.Clone(groupCfg.StageIds)
            table.insert(entrances, { StageIds = stageIds, GroupId = groupId })
        end
    end
    return entrances
end

--- 获取章节打的下一关入口
---@param chapterId number 章节Id
function XMainLine2Control:GetChapterNextEntrance(chapterId)
    return self._Model:GetChapterNextEntrance(chapterId)
end

--- 获取关卡的通关进度
---@param stageId number 关卡Id
function XMainLine2Control:GetStageProgress(stageId)
    return self._Model:GetStageProgress(stageId)
end

--- 获取关卡成就完成情况
---@param stageId number 关卡Id
function XMainLine2Control:GetStageAchievementMap(stageId)
    return self._Model:GetStageAchievementMap(stageId)
end

--- 获取关卡成就信息
---@param stageId number 关卡Id
---@param isFighting boolean 是否在战斗中
---@param isCombineStageGroup boolean 是否合并同个关卡组的成就
function XMainLine2Control:GetStagesAchievementInfos(stageId, isFighting, isCombineStageGroup)
    return self._Model:GetStagesAchievementInfos(stageId, isFighting, isCombineStageGroup)
end

--- 关卡是否解锁
---@param stageId number 关卡Id
function XMainLine2Control:IsStageUnlock(stageId)
    return self._Model:IsStageUnlock(stageId)
end

--- 关卡是否显示
---@param stageId number 关卡Id
function XMainLine2Control:IsStageShow(stageId)
    return self._Model:IsStageShow(stageId)
end

--- 获取关卡是否通关
---@param stageId number 关卡Id
function XMainLine2Control:IsStagePass(stageId)
    return self._Model:IsStagePass(stageId)
end

--- 缓存章节Id对应的主章节Id
---@param chapterId number 章节Id
---@param mainId number 主章节Id
function XMainLine2Control:CacheChapterMainId(chapterId, mainId)
    self._Model:CacheChapterMainId(chapterId, mainId)
end

--- 获取章节对应的mainId
---@param chapterId number 章节Id
function XMainLine2Control:GetChapterMainId(chapterId)
    return self._Model:GetChapterMainId(chapterId)
end

--- 缓存关卡Id对应的章节Id
---@param stageId number 关卡Id
---@param chapterId number 章节Id
function XMainLine2Control:CacheStageChapterId(stageId, chapterId)
    self._Model:CacheStageChapterId(stageId, chapterId)
end

--- 获取关卡对应的章节Id
---@param stageId number 关卡Id
function XMainLine2Control:GetStageChapterId(stageId)
    return self._Model:GetStageChapterId(stageId)
end

--- 缓存关卡Id所在的组Id
---@param stageId number 关卡Id
---@param groupId number 关卡组Id
function XMainLine2Control:CacheStageGroupId(stageId, groupId)
    self._Model:CacheStageGroupId(stageId, groupId)
end

--- 获取关卡所在的关卡列表
---@param stageId number 关卡Id
---@return number[] 关卡Id列表
function XMainLine2Control:GetStageStageIds(stageId)
    return self._Model:GetStageStageIds(stageId)
end

--- 获取章节最后打的关卡Id
---@param chapterId number 章节Id
function XMainLine2Control:GetLastPassStage(chapterId)
    return self._Model:GetLastPassStage(chapterId)
end

--- 设置播放过第一次进入特效
---@param mainId number 主章节Id
function XMainLine2Control:SetIsPlayFirstEnterEffect(mainId)
    return self._Model:SetIsPlayFirstEnterEffect(mainId)
end

--- 是否播放过第一次进入特效
---@param mainId number 主章节Id
function XMainLine2Control:GetIsPlayFirstEnterEffect(mainId)
    return self._Model:GetIsPlayFirstEnterEffect(mainId)
end

--- 设置播放过章节切换特效
---@param chapterId number 主章节Id
function XMainLine2Control:SetIsPlaySwitchEnterEffect(chapterId)
    self._Model:SetIsPlaySwitchEnterEffect(chapterId)
end

--- 是否播放过章节切换特效
---@param chapterId number 主章节Id
function XMainLine2Control:GetIsPlaySwitchEnterEffect(chapterId)
    return self._Model:GetIsPlaySwitchEnterEffect(chapterId)
end

-- 缓存主章节释放的数据
---@param mainId number 主章节Id
function XMainLine2Control:CacheMainReleaseData(mainId, data)
    self._Model:CacheMainReleaseData(mainId, data)
end

-- 获取主章节上次释放时的数据
---@param mainId number 主章节Id
---@param isRemove boolean 是否移除数据
function XMainLine2Control:GetMainReleaseData(mainId, isRemove)
    return self._Model:GetMainReleaseData(mainId, isRemove)
end

-- 获取章节上一次的解锁入口下标
function XMainLine2Control:GetChapterLastUnlockEntranceIndex(chapterId)
    return self._Model:GetChapterLastUnlockEntranceIndex(chapterId)
end

-- 设置章节上一次的解锁入口下标
function XMainLine2Control:SetChapterLastUnlockEntranceIndex(chapterId, entranceIndex)
    return self._Model:SetChapterLastUnlockEntranceIndex(chapterId, entranceIndex)
end

--#region 指挥官 -------------------------------------------------------------------------------------------------
-- 是否已经设置指挥官性别
function XMainLine2Control:IsSetPlayerGender()
    return self._Model:IsSetPlayerGender()
end

-- 获取主线指挥官性别
function XMainLine2Control:GetPlayerGender()
    return self._Model:GetPlayerGender()
end

-- 设置主线指挥官性别
function XMainLine2Control:SetPlayerGender(genderType)
    self._Model:SetPlayerGender(genderType)
end
--#endregion 指挥官 ----------------------------------------------------------------------------------------------

--- 获取章节界面类的接口，主要是对通用派生做支持
function XMainLine2Control:GetChapterUiCls(chapterId)
    if chapterId == ChapterIdEnum.Kamui4P5 then
        return require("XUi/XUiMainLine2/CustomUiChapter/XUiMainLine2PanelChapter4P5")
    end
    
    return require("XUi/XUiMainLine2/XUiMainLine2PanelEntranceList")
end

return XMainLine2Control