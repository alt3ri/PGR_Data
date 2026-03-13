---@class XUiArenaSettlement : XLuaUi
---@field _Control XArenaControl
---@field _ResultData ArenaFightResult|nil 结算数据（ArenaResult）
---@field _WinData table|nil 完整的胜利数据（包含 SettleData, CharExp 等，用于 debug）
---@field _AudioInfo any|nil 音效信息
---@field _AnimationDelayTimerId number|nil 动画延迟定时器ID
---@field _AnimationPlayTimerId number|nil 动画播放延迟定时器ID
---@field _IsInAnimationDelay boolean 是否在动画延迟期间（配合Unity动画演出）
---@field ListCharacter UnityEngine.RectTransform|nil 角色列表容器
---@field GridCharacter1 UnityEngine.RectTransform|nil 角色头像模板
local XUiArenaSettlement = XLuaUiManager.Register(XLuaUi, "UiArenaSettlement")

-- region 生命周期

function XUiArenaSettlement:OnAwake()
    self:_RegisterClickEvents()
end

---@param winData table 完整的胜利数据（包含 SettleData, CharExp 等）
function XUiArenaSettlement:OnStart(winData)
    -- 提取 ArenaResult 作为主要结算数据
    self._ResultData = winData.SettleData.ArenaResult
    -- 保存完整的 winData 用于角色列表等
    self._WinData = winData
end

function XUiArenaSettlement:OnEnable()
    self:_Refresh()
    self:_RegisterEventListeners()
    XDataCenter.FunctionEventManager.UnLockFunctionEvent()
end

function XUiArenaSettlement:OnDisable()
    -- 界面隐藏时的逻辑（预留）
end

function XUiArenaSettlement:OnDestroy()
    self:_UnregisterEventListeners()
    self:_ClearAnimationDelayTimer()
    self:_ClearAnimationPlayTimer()
    XDataCenter.AntiAddictionManager.EndFightAction()
end

-- endregion

-- region 事件注册

function XUiArenaSettlement:_RegisterClickEvents()
    self:RegisterClickEvent(self.BtnReFight, self.OnBtnReFightClick)
    self:RegisterClickEvent(self.BtnExitFight, self.OnBtnExitFightClick)
end

function XUiArenaSettlement:_RegisterEventListeners()
    XEventManager.AddEventListener(XEventId.EVENT_ARENA_HIDE_SETTLE, self.Hide, self)
end

function XUiArenaSettlement:_UnregisterEventListeners()
    XEventManager.RemoveEventListener(XEventId.EVENT_ARENA_HIDE_SETTLE, self.Hide, self)
end

-- endregion

-- region 按钮点击事件

function XUiArenaSettlement:OnBtnReFightClick()
    if not self:_CheckCanOperate() then
        return
    end

    -- 检查是否在动画延迟期间
    if self._IsInAnimationDelay then
        return
    end

    self:_StopAudio()

    -- 检查是否在结算期间
    if self:_IsInSettlementPeriod() then
        XUiManager.TipText("ArenaActivityStatusWrong")
        XLuaUiManager.SafeClose("UiArenaChapterDetail")
        self:Close()
        return
    end

    -- 获取当前战区和关卡ID
    local areaId = self._Control:GetCurrentEnterAreaId()
    local stageId = self._Control:GetAreaStageLastStageIdById(areaId)

    self._Control:SetCurrentEnterAreaId(areaId)

    -- 退出战斗（在打开战斗房间前先退出战斗）
    XMVCA.XArena:ExitFight()

    -- 打开战斗房间（PopThenOpen 会自动关闭当前结算界面）
    self._Control:OpenBattleRoleRoom(stageId, true)
end

function XUiArenaSettlement:OnBtnExitFightClick()
    if not self:_CheckCanOperate() then
        return
    end

    -- 检查是否在动画延迟期间
    if self._IsInAnimationDelay then
        return
    end

    self:_StopAudio()

    -- 检查是否在结算期间
    if self:_IsInSettlementPeriod() then
        XLuaUiManager.SafeClose("UiArenaChapterDetail")
    end

    -- 退出战斗
    XMVCA.XArena:ExitFight()

    -- 关闭界面并执行提示
    self:Close()
    XTipManager.Execute()
end

-- endregion

-- region 私有辅助方法

--- 检查是否可以操作（检查活动状态变化）
---@return boolean
function XUiArenaSettlement:_CheckCanOperate()
    if self._Control:CheckRunMainWhenFightOver() then
        return false
    end
    return true
end

--- 检查是否在结算期间
---@return boolean
function XUiArenaSettlement:_IsInSettlementPeriod()
    return self._Control:GetActivityStatus() == XEnumConst.Arena.ActivityStatus.Over
end

--- 停止音效播放
function XUiArenaSettlement:_StopAudio()
    if self._AudioInfo then
        self._AudioInfo:Stop()
    end
end

--- 清理动画延迟定时器
function XUiArenaSettlement:_ClearAnimationDelayTimer()
    if self._AnimationDelayTimerId then
        XScheduleManager.UnSchedule(self._AnimationDelayTimerId)
        self._AnimationDelayTimerId = nil
    end
end

--- 清理动画播放定时器
function XUiArenaSettlement:_ClearAnimationPlayTimer()
    if self._AnimationPlayTimerId then
        XScheduleManager.UnSchedule(self._AnimationPlayTimerId)
        self._AnimationPlayTimerId = nil
    end

    if self._PlayScoreAnimationTimerId then
        XScheduleManager.UnSchedule(self._PlayScoreAnimationTimerId)
        self._PlayScoreAnimationTimerId = nil
    end
end

--- 启动动画延迟（延迟3秒后允许操作，配合Unity动画演出）
function XUiArenaSettlement:_StartAnimationDelay()
    self:_ClearAnimationDelayTimer()
    self._IsInAnimationDelay = true
    
    -- 延迟3秒后允许操作
    self._AnimationDelayTimerId = XScheduleManager.ScheduleOnce(function()
        if XTool.UObjIsNil(self.Transform) then
            return
        end
        self._IsInAnimationDelay = false
        self._AnimationDelayTimerId = nil
    end, 3 * XScheduleManager.SECOND)
end

-- endregion

-- region 界面刷新

--- 刷新结算界面显示
function XUiArenaSettlement:_Refresh()
    if not self._ResultData then
        return
    end

    local data = self._ResultData
    local areaId = self._Control:GetCurrentEnterAreaId()
    local markId = self._Control:GetMarkIdByAreaId(areaId)
    if not XTool.IsNumberValid(markId) then
        XLog.Error("XUiArenaSettlement:_Refresh markId is not valid")
        return
    end
    local markInfo = self:_GetMarkInfo(markId)
    if not markInfo then
        XLog.Error("XUiArenaSettlement:_Refresh markInfo is not valid")
        return
    end

    -- 初始化UI显示状态
    self:_InitUIState(data, markInfo)

    -- 刷新角色列表显示
    self:_RefreshCharacterList()

    -- 更新分数数据
    if self._Control:IsHasMark(markId) and data.Point > data.OldPoint then
        self._Control:SetAreaDataStagePoint(areaId, data.Point)
    end

    -- 刷新副本入口数据
    self._Control:SetIsRefreshMainPage(true)

    -- 启动动画延迟（延迟3秒后允许操作，配合Unity动画演出）
    self:_StartAnimationDelay()

    -- 延迟3秒后播放音效和分数动画（配合Unity动画演出）
    self:_ClearAnimationPlayTimer()
    self._AnimationPlayTimerId = XScheduleManager.ScheduleOnce(function()
        if XTool.UObjIsNil(self.Transform) then
            return
        end
        self._AnimationPlayTimerId = nil
        -- 播放音效
        self._AudioInfo = XLuaAudioManager.PlayAudioByType(
            XLuaAudioManager.SoundType.SFX,
            XLuaAudioManager.UiBasicsMusic.UiSettle_Win_Number
        )
        -- 播放分数动画
        self:_PlayScoreAnimation(data, markInfo)
    end, 3 * XScheduleManager.SECOND)
end

--- 获取标记信息
---@param markId number 标记ID
---@return table 标记信息（包含 MaxPoint, ShowEnemyHp, ShowMyHp, ShowGroup）
function XUiArenaSettlement:_GetMarkInfo(markId)
    return {
        MaxPoint = self._Control:GetMarkMaxPointByMarkId(markId) or 0,
        ShowEnemyHp = self._Control:IsMarkShowEnemyHp(markId) or false,
        ShowMyHp = self._Control:IsMarkShowMyHp(markId) or false,
        ShowGroup = self._Control:IsMarkShowGourp(markId) or false,
    }
end

--- 初始化UI显示状态
---@param data table 结算数据
---@param markInfo table 标记信息
function XUiArenaSettlement:_InitUIState(data, markInfo)
    -- 设置文本类型的内容（名称、标题等）
    self.TxtTitle.text = self._Control:GetCurrentEnterAreaStageName()
    
    -- 设置数值类型文本的默认值为0
    self:_InitDefaultValues()
    
    self.BtnReFight.gameObject:SetActiveEx(true)
    self.PanelNewRecord.gameObject:SetActiveEx(false)
    self.PanelBossLoseHp.gameObject:SetActiveEx(markInfo.ShowEnemyHp)
    self.PanelSurplusHp.gameObject:SetActiveEx(markInfo.ShowMyHp)
    self.PanelGroupCount.gameObject:SetActiveEx(markInfo.ShowGroup)
    
    self:_UpdateHighScoreDisplay(data, markInfo, true)
end

--- 初始化数值类型文本的默认值（设置为0）
function XUiArenaSettlement:_InitDefaultValues()
    if self.TxtPoint then
        self.TxtPoint.text = "0"
    end
    if self.TxtHighScore then
        self.TxtHighScore.text = "0"
    end
    if self.TxtHitScore then
        self.TxtHitScore.text = "+0"
    end
    if self.TxtRemainHp then
        self.TxtRemainHp.text = "0%"
    end
    if self.TxtRemainHpScore then
        self.TxtRemainHpScore.text = "+0"
    end
    if self.TxtGroupCount then
        self.TxtGroupCount.text = XUiHelper.GetText("ArenaGrouplScore", 0)
    end
    if self.TxtGroupCountScore then
        self.TxtGroupCountScore.text = "+0"
    end
end

--- 播放分数动画
---@param data table 结算数据
---@param markInfo table 标记信息
function XUiArenaSettlement:_PlayScoreAnimation(data, markInfo)
    local animaTime = CS.XGame.ClientConfig:GetFloat("BossSingleAnimaTime")
    
    self._PlayScoreAnimationTimerId = XUiHelper.Tween(animaTime, function(progress)
        if XTool.UObjIsNil(self.Transform) then
            return
        end

        self:_UpdateEnemyHpDisplay(data, markInfo, progress)
        self:_UpdateMyHpDisplay(data, markInfo, progress)
        self:_UpdateGroupDisplay(data, markInfo, progress)
        self:_UpdateScoreDisplay(data, markInfo, progress)
    end, function()
        self._PlayScoreAnimationTimerId = nil
        self:_StopAudio()
        self:_RefreshNewScore(data, markInfo)
    end)
end

--- 更新歼敌奖励显示
---@param data table 结算数据
---@param markInfo table 标记信息
---@param progress number 动画进度 (0-1)
function XUiArenaSettlement:_UpdateEnemyHpDisplay(data, markInfo, progress)
    if not markInfo.ShowEnemyHp then
        return
    end

    local hitCombo = math.floor(progress * data.EnemyHurt)
    local hitScore = "+" .. math.floor(progress * data.EnemyPoint)
    -- self.TxtHitCombo.text = hitCombo  -- 不设置 TxtHitCombo 的值
    self.TxtHitScore.text = hitScore
end

--- 更新我方血量显示
---@param data table 结算数据
---@param markInfo table 标记信息
---@param progress number 动画进度 (0-1)
function XUiArenaSettlement:_UpdateMyHpDisplay(data, markInfo, progress)
    if not markInfo.ShowMyHp then
        return
    end

    local remainHp = math.floor(progress * data.MyHpLeft) .. "%"
    local remainHpScore = "+" .. math.floor(progress * data.MyHpPoint)
    self.TxtRemainHp.text = remainHp
    self.TxtRemainHpScore.text = remainHpScore
end

--- 更新波次奖励显示
---@param data table 结算数据
---@param markInfo table 标记信息
---@param progress number 动画进度 (0-1)
function XUiArenaSettlement:_UpdateGroupDisplay(data, markInfo, progress)
    if not markInfo.ShowGroup then
        return
    end

    local groupCount = XUiHelper.GetText("ArenaGrouplScore", math.floor(progress * data.NpcGroup))
    local groupCountScore = "+" .. math.floor(progress * data.NpcGroupPoint)
    self.TxtGroupCount.text = groupCount
    self.TxtGroupCountScore.text = groupCountScore
end

--- 更新分数显示
---@param data table 结算数据
---@param markInfo table 标记信息
---@param progress number 动画进度 (0-1)
function XUiArenaSettlement:_UpdateScoreDisplay(data, markInfo, progress)
    -- 当前总分
    local currentPoint = math.floor(progress * data.Point)
    if data.Point >= markInfo.MaxPoint and markInfo.MaxPoint > 0 then
        self.TxtPoint.text = XUiHelper.GetText("ArenaMaxAllScore", currentPoint)
    else
        self.TxtPoint.text = tostring(currentPoint)
    end
end

function XUiArenaSettlement:_UpdateHighScoreDisplay(data, markInfo, isOld)
    -- 历史最高分
    -- 4.2 新增字段ArenaMaxPoint(Area), 与4.1的OldPoint功能(Stage)有区分, 如果 data.ArenaMaxPoint 为 nil，则使用 0 作为后备
    local highScore = 0

    if isOld then
        highScore =  data.OldArenaMaxPoint or 0
    else
        highScore =  data.ArenaMaxPoint or 0
    end
    
    if (highScore or 0) >= markInfo.MaxPoint and markInfo.MaxPoint > 0 then
        self.TxtHighScore.text = highScore .. "/" .. markInfo.MaxPoint
    else
        self.TxtHighScore.text = tostring(highScore)
    end
end

--- 刷新角色列表显示
function XUiArenaSettlement:_RefreshCharacterList()
    if not self.ListCharacter or not self.GridCharacter1 then
        return
    end

    -- 获取角色ID列表（参考 XUiFubenBossSingleSettlement）
    local characterList = nil

    -- 优先从完整的 winData 中获取（用于 debug 重新打开）
    if self._WinData then
        if self._WinData.SettleData and self._WinData.SettleData.NpcHpInfo then
            characterList = self._WinData.SettleData.NpcHpInfo
        elseif self._WinData.CharExp then
            characterList = self._WinData.CharExp
        end
    end

    if not characterList or XTool.IsTableEmpty(characterList) then
        return
    end

    -- 显示参与战斗的角色列表
    for _, v in ipairs(characterList) do
        -- 支持两种数据结构：NpcHpInfo 使用 CharacterId，CharExp 使用 Id
        local characterId = v.CharacterId or v.Id
        if characterId and characterId > 0 then
            local gridObj = XUiHelper.Instantiate(self.GridCharacter1, self.ListCharacter)
            local imgHead = gridObj.transform:Find("RImgHead")
            if imgHead then
                local rawImage = imgHead:GetComponent("RawImage")
                if rawImage then
                    rawImage:SetRawImage(XMVCA.XCharacter:GetCharBigHeadIcon(characterId))
                end
            end
        end
    end

    -- 隐藏模板
    if self.GridCharacter1 and not XTool.UObjIsNil(self.GridCharacter1.gameObject) then
        self.GridCharacter1.gameObject:SetActiveEx(false)
    end
end

function XUiArenaSettlement:_RefreshNewScore(data, markInfo)
    local hasNewMaxPoint = data.Point > (data.OldArenaMaxPoint or 0)

    if self.PanelNewRecord then
        self.PanelNewRecord.gameObject:SetActiveEx(hasNewMaxPoint)

        if hasNewMaxPoint then
            self:DelayCall(function()
                self:_UpdateHighScoreDisplay(data, markInfo, false)
                self:PlayAnimation('AnimQiehuan')
            end, 0.5)
        end
    end
end

-- endregion

-- region 其他方法

--- 隐藏结算界面（通过事件调用）
function XUiArenaSettlement:Hide()
    if self.GameObject and not XTool.UObjIsNil(self.GameObject) then
        self.GameObject:SetActiveEx(false)
    end
end

-- endregion

return XUiArenaSettlement
