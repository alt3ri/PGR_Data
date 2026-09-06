--- 局内战斗控制器
---@class XPunishaarFightControl : XControl
---@field private _Model
---@field private _DeathPending boolean death gate 是否已触发（phase 2 等待 fire frame）
---@field private _DeathPendingTarget string 死亡目标 entityId（Player/Enemy，派 DeathAnim 用）
---@field private _DeathFireFrame number fire BattleEnded 的逻辑帧（curTick + delayFrames）
local XPunishaarFightControl = XClass(XControl, "XPunishaarFightControl", true)

local STECustomEnum = require("XModule/XPunishaar/STEDefine/STECustomEnum")
local Effect = require("XModule/XPunishaar/STEDefine/Effect")

XClassPartialRequire("XModule/XPunishaar/SubModules/InGame/XPunishaarFightConfigControl", "XPunishaarFightControl")

local LogicFrame = 20

--- 战斗结果枚举（BattleEnded 事件携带）
XPunishaarFightControl.BattleResult = {
    Win = 1,    -- 玩家胜利（敌方 HP<=0）
    Lose = 2,   -- 玩家失败（我方 HP<=0）
}

function XPunishaarFightControl:OnInit()
    self:InitConfig()

    ---@type XPunishaarSTEControl
    self.STEControl = self:AddSubControl(require("XModule/XPunishaar/SubModules/InGame/XPunishaarSTEControl"))

    ---@type XPunishaarSTEReader 表现层只读视图（与 STEControl 平级，向 STE 门面现取 env）
    self.STEReader = self:AddSubControl(require("XModule/XPunishaar/SubModules/InGame/XPunishaarSTEReader"))
    self.STEReader:BindSTEControl(self.STEControl)

    ---@type XPunishaarSpeedController 倍速外壳（Control 子控，battle-scoped，档位+持久化；变速驱动经 SetUpdaterSpeed）#68
    self.SpeedController = self:AddSubControl(require("XModule/XPunishaar/SubModules/InGame/XPunishaarSpeedController"))

    ---@type XLogicUpdater
    self._LogicUpdater = require("XModule/XPunishaar/CommonGameUpdater/XLogicUpdater").New(LogicFrame, handler(self, self.OnUpdaterTick))

    self:AddEventListener(self.EventIds.OnPause, self.OnPauseEvent, self)
    self:AddEventListener(self.EventIds.OnResume, self.OnResumeEvent, self)
end

function XPunishaarFightControl:AddAgencyEvent()
    -- 监听跨系统战斗暂停/恢复事件（外部派发，本控制内部 SetUpdaterPause/Resume）#战斗暂停恢复事件
    XEventManager.AddEventListener(XEventId.EVENT_PUNISHAAR_FIGHT_PAUSE, self.SetUpdaterPause, self)
    XEventManager.AddEventListener(XEventId.EVENT_PUNISHAAR_FIGHT_RESUME, self.SetUpdaterResume, self)
    -- 引导结束（正常+强制）监听：战斗中引导结束 + 无 StagePause 弹窗 → 恢复战斗时钟（引导暂停残留）#引导结束恢复
    -- 引导暂停战斗后结束未自动恢复，玩家无暂停页无法手动恢复 → 监听兜底；StagePause 开=玩家手动暂停不恢复
    XEventManager.AddEventListener(XEventId.EVENT_GUIDE_SKIP, self.OnGuideEndResume, self)  -- 强制跳过（Lua 总线）
    self._GuideEndCsHandler = handler(self, self.OnGuideEndResume)
    CsXGameEventManager.Instance:RegisterEvent(XEventId.EVENT_GUIDE_END, self._GuideEndCsHandler)  -- 正常结束（C# 总线，参考 XGuideManager:198）
end

function XPunishaarFightControl:RemoveAgencyEvent()
    XEventManager.RemoveEventListener(XEventId.EVENT_PUNISHAAR_FIGHT_PAUSE, self.SetUpdaterPause, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_PUNISHAAR_FIGHT_RESUME, self.SetUpdaterResume, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GUIDE_SKIP, self.OnGuideEndResume, self)
    if self._GuideEndCsHandler then
        CsXGameEventManager.Instance:RemoveEvent(XEventId.EVENT_GUIDE_END, self._GuideEndCsHandler)
        self._GuideEndCsHandler = nil
    end
end

function XPunishaarFightControl:OnRelease()
    self._LogicUpdater:SetPause()
    self:_StopUpdaterTimer()
end

--- 战斗单一入口：外部提供开战契约对象（已 set 好字段），战斗自洽开局。
--- 外部是真实环境 / 测试环境 / 回放，战斗本身不关心——只认契约对象。
--- 纯参数入口：直接读传入对象初始化，内部不去 Model 捞数据（正常局内直接调本方法，零旁路）。
---@param initData XPunishaarBattleInitData 开战契约对象
function XPunishaarFightControl:StartBattle(initData)
    if not initData or not initData:Validate() then
        XLog.Error("[Punishaar] 开战契约非法，StartBattle 中止")
        return false
    end

    -- 本局只读契约（与 _STEEnv 配对：一个是这局入参一个是这局世界；进入后不回写）
    self._BattleInitData = initData

    self._BattleOver = false
    -- death gate 字段重置（防跨局复用路径变更后上局 phase 2 残留 _DeathPending=true 致新局首帧跳过死亡检测）#75 M2
    self._DeathPending = false
    self._DeathFireFrame = nil
    self._DeathPendingTarget = nil
    self._BattleResult = nil

    self:InitNewGame()   -- 建 env（用契约 seed/ballSlotCapacity）+ 装初始球
    self:SetupBattle()   -- 纯翻译契约 → 建 Player/Enemy/卡牌
    self.STEControl:RunBattleStartEffects()  -- 战斗开始钩子：跑装备/战斗开始时机的 effect（开局一次）
    -- 注：不在此直接 StartGame——由 UI 层（XUiPunishaarFightMainPanelFighting:_PlayVsNotify）
    -- 播 VSNotify 开场动画、隐藏回调触发 StartGame，让逻辑帧在表现层就位后才流动（变更#32）。
    return true
end

--- 初始化
function XPunishaarFightControl:InitNewGame()
    self.STEControl:InitNewGame(self._BattleInitData)
    -- 按持久化自动战斗偏好给 Global 打 Auto 特征 tag（ByHand 牌据 tag 跳过输入检查直接激活）#Auto
    self.STEControl:InitAutoModeFromSave()
    -- 按持久化倍速偏好初始化 updater 帧率（SpeedController 管档位/持久化，SetUpdaterSpeed 驱动）#68
    self.SpeedController:InitFromSave()
    self:SetUpdaterSpeed(self.SpeedController:GetSpeed() == 2)
    self._LogicUpdater:SetPause()
end

--- 装配一局（读本局只读契约，纯翻译）
function XPunishaarFightControl:SetupBattle()
    self.STEControl:SetupBattle(self._BattleInitData)
end

--- 获取逻辑帧率（每秒逻辑帧数），供 buff 等毫秒→帧换算使用
function XPunishaarFightControl:GetLogicFrame()
    return LogicFrame
end

--- 敌人名称（表现层显示用）。链路：契约 fightId → Fight.EnemyId → Enemy.EnemyName。
--- 找不到返回空串。
---@return string
function XPunishaarFightControl:GetEnemyName()
    if not self._BattleInitData then
        return ""
    end
    local fightCfg = self:GetTablePunishaarFight(self._BattleInitData:GetFightId())
    if not fightCfg then
        return ""
    end
    local enemyCfg = self:GetTablePunishaarEnemy(fightCfg.EnemyId)
    return enemyCfg and enemyCfg.EnemyName or ""
end

--- 卡牌 CD 上限（单位：秒，保留调用方格式化）。表现层显示用。
--- 取源与转换：以**配置表**为准避免帧取整误差——
---   uid →(Reader) cardId + index → 契约按 index 取 level（O(1)，同 cardId 可多张故用 index 唯一键）
---   → CardLevel(cardId*100+level).CD（毫秒）/ 1000 = 秒。
--- 找不到返回 0。
---@param uid any 卡牌实体 uid
---@return number 秒（可能含小数）
function XPunishaarFightControl:GetCardCdMaxSeconds(uid)
    local cardId = self.STEReader:GetCardId(uid)
    local index = self.STEReader:GetCardIndex(uid)
    if not self._BattleInitData then
        return 0
    end
    local level = self._BattleInitData:GetCardLevelByIndex(index)
    if not cardId or not level then
        return 0
    end
    local levelCfg = self:GetTablePunishaarCardLevel(cardId * 100 + level)
    if not levelCfg or not levelCfg.CD then
        return 0
    end
    return levelCfg.CD / 1000
end

function XPunishaarFightControl:EndGame()
    self.STEControl:OnEndGame()
    self._LogicUpdater:SetPause()
    self:_StopUpdaterTimer()
end

--- 真正开始，时间开始流动
function XPunishaarFightControl:StartGame()
    -- 埋点统计：战斗起点时间戳（逻辑帧开始流动记；VSNotify 隐藏回调触发本方法，表现层已就位）
    self._BattleStartTs = XTime.GetServerNowTimestamp()
    self:_StartUpdaterTimer()
    self._LogicUpdater:SetRunning()
end

--region 逻辑帧更新器

function XPunishaarFightControl:StartUpdater()
    self._LogicUpdater:SetRunning()
end

function XPunishaarFightControl:SetUpdaterPause()
    self._LogicUpdater:SetPause()
end

function XPunishaarFightControl:SetUpdaterResume()
    self._LogicUpdater:SetResume()
end

--- 引导结束（正常 EVENT_GUIDE_END / 强制 EVENT_GUIDE_SKIP）+ 无 StagePause 弹窗 → 恢复战斗时钟
--- 引导暂停战斗后结束未自动恢复，玩家无暂停页无法手动恢复 → 监听兜底恢复；StagePause 开=玩家手动暂停不恢复 #引导结束恢复
function XPunishaarFightControl:OnGuideEndResume()
    if not XLuaUiManager.IsUiShow("UiPunishaarStagePause") then
        self:SetUpdaterResume()
    end
end

--- 这里约束只能切换二倍速
function XPunishaarFightControl:SetUpdaterSpeed(isDouble)
    -- 埋点统计：曾开过 2 倍速即永记 true（once true 永 true，含 InitFromSave 开局即 2x 情形）
    if isDouble then
        self._UsedDoubleSpeed = true
    end
    self._LogicUpdater:SetLogicFrame(isDouble and LogicFrame * 2 or LogicFrame)
end

function XPunishaarFightControl:OnUpdaterTick(curLogicFrame)
    if self._BattleOver then
        return
    end

    -- 帧内：推进一个逻辑步
    self.STEControl:STETick()

    -- 胜负判定（战斗自洽的一部分）：推进一步后检查是否终局
    self:CheckBattleEnd()
end

--- 胜负判定 + death gate：任一方 HP<=0 触发死亡 gate（不直 fire BattleEnded）。
--- #75 改造：原 CheckBattleEnd 检测 HP<=0 即 fire BattleEnded；改为两阶段 gate——
---   Phase 1（未 death-pending）：判 HP≤0 → 标 _DeathPending + 记 _DeathFireFrame=curTick+delayFrames +
---     取消 overkill（CancelScheduledOnTarget 死亡目标 delay>0 队列）+ 派 DeathAnim（表现层 no-op 预留）。
---     不 EndGame / 不 DispatchEvent BattleEnded（让在飞攻击动画 land，不盖飞弹）。
---   Phase 2（death-pending）：curTick>=_DeathFireFrame → FireBattleEnded（fire 结算）。
--- 不变量保留：HP≤0 即死；同帧死亡判玩家胜利；仅玩家死判败；仅敌人死判胜（result 在 phase 1 算好 stash）。
function XPunishaarFightControl:CheckBattleEnd()
    local curTick = self.STEControl:GetEnv():GetTick()

    -- Phase 2：death-pending → 等 fire frame
    if self._DeathPending then
        if curTick >= self._DeathFireFrame then
            self:FireBattleEnded()
        end
        return
    end

    -- Phase 1：检测死亡
    local pHp, eHp = self.STEControl:GetHp()
    local playerDead = pHp ~= nil and pHp <= 0
    local enemyDead = eHp ~= nil and eHp <= 0
    if not (playerDead or enemyDead) then
        return
    end

    -- result 算好 stash（phase 2 fire 用，不依赖 fire frame 的 HP 状态）
    local result
    if playerDead and not enemyDead then
        result = self.BattleResult.Lose
    else
        result = self.BattleResult.Win
    end

    self._DeathPending = true
    self._BattleResult = result
    self._DeathFireFrame = curTick + Effect.GetAttackLandDelayFrames()

    -- 死亡目标（DeathAnim 用）：敌人死→敌人；仅玩家死→玩家
    local deadTarget
    if enemyDead then
        deadTarget = STECustomEnum.GlobalEntityIds.Enemy
    else
        deadTarget = STECustomEnum.GlobalEntityIds.Player
    end
    self._DeathPendingTarget = deadTarget

    -- 取消 overkill：死亡目标 delay>0 的待落地指令（land=L 的 delay=0 已在 STETick 内落地抽干）
    local env = self.STEControl:GetEnv()
    if playerDead then
        env:CancelScheduledOnTarget(STECustomEnum.GlobalEntityIds.Player)
    end
    if enemyDead then
        env:CancelScheduledOnTarget(STECustomEnum.GlobalEntityIds.Enemy)
    end

    XLog.Debug(string.format("【战斗 death gate】result=%s PlayerHP=%s EnemyHP=%s，延 %s 帧后 fire BattleEnded",
            tostring(result), tostring(pHp), tostring(eHp), tostring(self._DeathFireFrame - curTick)))

    -- 派 DeathAnim（表现层 no-op 预留：后续补死亡动画时在此接 finish 回调 → FireBattleEnded）
    self:DispatchEvent(self.EventIds.DeathAnim)
end

--- fire BattleEnded 进结算（由 death gate phase 2 调；后续死亡动画 finish 回调亦调本方法）。
--- 从 CheckBattleEnd 剥离的 fire 逻辑：算 loseMaxColor + EndGame + DispatchEvent BattleEnded。
function XPunishaarFightControl:FireBattleEnded()
    if self._BattleOver then
        return
    end
    self._BattleOver = true

    local result = self._BattleResult
    local loseMaxColor = result == self.BattleResult.Win and 0 or self.STEReader:GetMaxCountColorInSlot()

    -- 埋点统计：战斗终点时间戳（BattleEnded fire 前记；不减暂停——服务器时间自然含暂停时长）
    self._BattleEndTs = XTime.GetServerNowTimestamp()
    XLog.Debug(string.format("【战斗结束】result=%s loseMaxColor=%s", tostring(result), tostring(loseMaxColor)))

    -- 先 DispatchEvent 再 EndGame：BattleEnded 回调链(_OnBattleEnded→CollectBattleStats→GetBallProduced)需读 env，
    -- EndGame 会释放 env（STEControl:OnEndGame _STEEnv=nil），故回调须在 EndGame 前同步执行完 #76 bug 修正
    self:DispatchEvent(self.EventIds.BattleEnded, result, loseMaxColor)
    self:EndGame()
end

--- 聚合战斗埋点统计（OnBattleEnded 正式路径调，结果传 FinishFight→DoFinishFight→Request）。
--- 字段名/类型对齐服务端 proto XPunishaarFinishFightRequest（XPunishaarProto.cs）。
--- 纯读：只读 STE 状态 + 本控制器的墙钟字段，不改任何状态。
---@return table stats { FightTime, FightSpeed, IsAutoFight, UseSkillCount, AutoUseSkillCount, BallProduction, BallConsumption }
function XPunishaarFightControl:CollectBattleStats()
    local autoCount, manualCount = 0, 0
    -- 遍历所有卡牌，按 ByHand tag 分组求和 DoneTimes（手动=玩家点击驱动；自动=CD 驱动）
    if not self._CardIdsBuf then self._CardIdsBuf = {} end
    local cardCount = self.STEReader:FillCardEntityIds(self._CardIdsBuf)
    for i = 1, cardCount do
        local uid = self._CardIdsBuf[i]
        local done = self.STEReader:GetCardDoneTimes(uid) or 0
        if self.STEReader:IsCardByHand(uid) then
            manualCount = manualCount + done
        else
            autoCount = autoCount + done
        end
    end
    -- 球总量经 STEControl 读 Global single property（事务提交后的最终值）
    local ballProduced = self.STEControl:GetBallProduced()
    local ballConsumed = self.STEControl:GetBallConsumed()
    -- IsAutoFight：本局曾真正启用过自动战斗（STEControl 累计，once true 永 true）#IsAutoFight
    local isAutoFight = self.STEControl:IsAutoFightUsed()
    -- FightTime 单位=秒（proto int 秒）：XTime.GetServerNowTimestamp 返回秒级 timestamp，
    -- 直接 diff 即可（勿 /1000——timestamp 本身就是秒，除 1000 永远 0，#77 bug 修正）
    local fightTime = math.floor((self._BattleEndTs or 0) - (self._BattleStartTs or 0))
    return {
        FightTime = fightTime,                       -- int 秒
        FightSpeed = self._UsedDoubleSpeed == true, -- bool（曾用 2x）
        IsAutoFight = isAutoFight,                  -- bool（曾启用自动战斗）
        UseSkillCount = manualCount,                -- int（手动释放=ByHand 卡 DoneTimes 和）
        AutoUseSkillCount = autoCount,              -- int（自动释放=非 ByHand 卡 DoneTimes 和）
        BallProduction = ballProduced or 0,         -- int
        BallConsumption = ballConsumed or 0,         -- int
    }
end

function XPunishaarFightControl:_StopUpdaterTimer()
    if self._UpdaterTimeId then
        XScheduleManager.UnSchedule(self._UpdaterTimeId)
        self._UpdaterTimeId = nil
    end
end

function XPunishaarFightControl:_StartUpdaterTimer()
    self:_StopUpdaterTimer()

    self._UpdaterTimeId = XScheduleManager.ScheduleForever(function()
        self._LogicUpdater:Update(XLuaTime.deltaTime)
    end, 0)
end
--endregion


--region 事件监听

function XPunishaarFightControl:OnPauseEvent()
    self:SetUpdaterPause()
end

function XPunishaarFightControl:OnResumeEvent()
    self:SetUpdaterResume()
end

--endregion

return XPunishaarFightControl