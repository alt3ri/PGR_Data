local XUiPunishaarFightMainPanelBattleBall = require("XUi/XUiPunishaar/XUiPunishaarFightMain/UiFighting/XUiPunishaarFightMainPanelBattleBall")
local XUiPunishaarFightMainPanelMainHp = require("XUi/XUiPunishaar/XUiPunishaarFightMain/UiFighting/XUiPunishaarFightMainPanelMainHp")
local XUiPunishaarFightMainPanelEnemyHp = require("XUi/XUiPunishaar/XUiPunishaarFightMain/UiFighting/XUiPunishaarFightMainPanelEnemyHp")
local XUiPunishaarFightMainPanelBattleCardList = require("XUi/XUiPunishaar/XUiPunishaarFightMain/UiFighting/XUiPunishaarFightMainPanelBattleCardList")
local STECustomEnum = require("XModule/XPunishaar/STEDefine/STECustomEnum")
-- EffectController 删除（#73 重构）：攻击特效/卡牌攻击动画收口到 ModelShow 的 EffectPlayer/AnimationPlayer 子组件

-- 受伤飘字 coordinator 偏移（敌人模型上方，FlashTextRoot-local，实测调）#飘字
local DAMAGE_POP_OFFSET_UP = 60

---@class XUiPunishaarFightMainPanelFighting : XUiNode
---@field _Control XPunishaarControl
---@field PanelBattleVSNotify UnityEngine.RectTransform
---@field PaneMiddleNotify UnityEngine.RectTransform
---@field PanelBattleTips UnityEngine.RectTransform
---@field PanelBattleBall XUiPunishaarFightMainPanelBattleBall
---@field PanelBattle UnityEngine.RectTransform
---@field PanelMainHp XUiPunishaarFightMainPanelMainHp
---@field PanelEnemyHp XUiPunishaarFightMainPanelEnemyHp
---@field PanelBattleCardList XUiPunishaarFightMainPanelBattleCardList
---@field Parent XLuaUi
local XUiPunishaarFightMainPanelFighting = XClass(XUiNode, "XUiPunishaarFightMainPanelFighting")

---@param ModelShow XUiPunishaarModelShow
function XUiPunishaarFightMainPanelFighting:InitComponents(ModelShow)
    self.PanelBattleVSNotify.gameObject:SetActiveEx(false)
    self.PaneMiddleNotify.gameObject:SetActiveEx(false)

    ---@type XUiPunishaarFightMainPanelBattleBall
    self.PanelBattleBall = XUiPunishaarFightMainPanelBattleBall.New(self.PanelBattleBall, self)
    ---@type XUiPunishaarFightMainPanelMainHp
    self.PanelMainHp = XUiPunishaarFightMainPanelMainHp.New(self.PanelMainHp, self)
    ---@type XUiPunishaarFightMainPanelEnemyHp
    self.PanelEnemyHp = XUiPunishaarFightMainPanelEnemyHp.New(self.PanelEnemyHp, self)
    ---@type XUiPunishaarFightMainPanelBattleCardList
    self.PanelBattleCardList = XUiPunishaarFightMainPanelBattleCardList.New(self.PanelBattleCardList, self)

    self.PanelBattleBall:Open()
    self.PanelMainHp:Open()
    self.PanelEnemyHp:Open()
    self.PanelBattleCardList:Open()
    -- EffectController 创建删除（#73 重构）：EffectPlayer/AnimationPlayer 由 ModelShow:OnStart 创建

    -- 疲劳弹窗初始隐（显式保证不依赖 prefab 默认 active=false；显隐归 _OnFatigueAnim 显/OnDisable 隐，OnStart 初始隐兜底防误改 prefab 或复用残留）#80
    if self.PaneMiddleNotify then
        self.PaneMiddleNotify.gameObject:SetActiveEx(false)
    end
    -- 受伤飘字 coordinator payload 缓冲（DrainDamageLanded 复用，零 GC）#飘字
    self._DamagePayloadBuf = XTool.XListNew()
end

---@param ModelShow XUiPunishaarModelShow
function XUiPunishaarFightMainPanelFighting:OnStart(ModelShow)
    self:InitComponents(ModelShow)
end

function XUiPunishaarFightMainPanelFighting:OnEnable()
    self._Control:EnterFight()
    self:RefreshAll()

    local gameControl = self._Control.GameControl.FightControl
    gameControl:AddEventListener(gameControl.EventIds.PlayerHPChanged, self._RefreshPlayerStatus, self)
    gameControl:AddEventListener(gameControl.EventIds.EnemyHPChanged, self._RefreshEnemyStatus, self)
    gameControl:AddEventListener(gameControl.EventIds.BallListChanged, self._RefreshBallList, self)
    gameControl:AddEventListener(gameControl.EventIds.CardCdChanged, self._RefreshCardCd, self)
    gameControl:AddEventListener(gameControl.EventIds.PlayerShieldChanged, self._RefreshPlayerShield, self)
    gameControl:AddEventListener(gameControl.EventIds.EnemyShieldChanged, self._RefreshEnemyBuffList, self)
    gameControl:AddEventListener(gameControl.EventIds.DotBuffLayerChanged, self._RefreshEnemyBuffList, self)  -- 敌人 buff 与护盾共用一个图标列表，任一变都整表重算 #Buff图标
    gameControl:AddEventListener(gameControl.EventIds.CardBallProductChanged, self._RefreshCardBallCount, self)
    gameControl:AddEventListener(gameControl.EventIds.CardBallConsumeChanged, self._RefreshCardBallCount, self)
    -- CardAttackAnim 订阅删除（#73 重构）：AnimationPlayer 自驱订阅（经 ModelShow:BindFightControl 转发）
    gameControl:AddEventListener(gameControl.EventIds.DeathAnim, self._OnDeathAnim, self)  -- 死亡动画触发（no-op 预留）#75
    gameControl:AddEventListener(gameControl.EventIds.FatigueAnim, self._OnFatigueAnim, self)  -- 疲劳弹窗动画触发（no-op 预留）#80
    -- 受伤飘字 coordinator：HPChanged→DrainDamageLanded→算坐标→DispatchEvent(SpawnDamageNumber)（飘字系统纯订阅 SpawnDamageNumber）#飘字
    gameControl:AddEventListener(gameControl.EventIds.PlayerHPChanged, self._OnDamageLanded, self)
    gameControl:AddEventListener(gameControl.EventIds.EnemyHPChanged, self._OnDamageLanded, self)

    -- ModelShow:BindFightControl 在 EnterFight（FightControl 就绪）后转发子组件订阅（AttackEffect/CardAttackAnim）#73
    -- （OnEnable 阶段 FightControl 未创建，注册移此；切走由 OnDisable→UnbindFightControl 注销）
    if self.Parent and self.Parent.ModelShow then
        self.Parent.ModelShow:BindFightControl()
    end
    -- 受伤飘字订阅（平行 ModelShow:BindFightControl 转发；PanelTop=CommonFightMain 持 DamageNumberPlayer）#飘字
    if self.Parent and self.Parent.PanelTop then
        self.Parent.PanelTop:BindFightControl()
    end

    -- 战斗环境已就绪（EnterFight 内 StartBattle 建完环境、跑完 RunBattleStartEffects），
    -- 播 VSNotify 开场动画，隐藏回调里启动逻辑帧（StartGame）——逻辑帧在表现层就位后才流动（#32）。
    self:_PlayVsNotify()
end

function XUiPunishaarFightMainPanelFighting:OnDisable()
    self:_StopVsNotifyTimer()  -- 先停 VSNotify 定时器，防 ExitFight 释放 FightControl 后回调打到 nil
    -- 疲劳弹窗隐藏（切走/战斗结束时隐，防复用残留）#80
    if self.PaneMiddleNotify then
        self.PaneMiddleNotify.gameObject:SetActiveEx(false)
    end
    -- 释放期取值：GameControl 可能已被上层释放，逐段判空（OnEnable 侧 EnterFight 刚建好无此顾虑）
    local gameControl = self._Control and self._Control.GameControl and self._Control.GameControl.FightControl
    if gameControl then
        gameControl:RemoveEventListener(gameControl.EventIds.PlayerHPChanged, self._RefreshPlayerStatus, self)
        gameControl:RemoveEventListener(gameControl.EventIds.EnemyHPChanged, self._RefreshEnemyStatus, self)
        gameControl:RemoveEventListener(gameControl.EventIds.BallListChanged, self._RefreshBallList, self)
        gameControl:RemoveEventListener(gameControl.EventIds.CardCdChanged, self._RefreshCardCd, self)
        gameControl:RemoveEventListener(gameControl.EventIds.PlayerShieldChanged, self._RefreshPlayerShield, self)
        gameControl:RemoveEventListener(gameControl.EventIds.EnemyShieldChanged, self._RefreshEnemyBuffList, self)
        gameControl:RemoveEventListener(gameControl.EventIds.DotBuffLayerChanged, self._RefreshEnemyBuffList, self)
        gameControl:RemoveEventListener(gameControl.EventIds.CardBallProductChanged, self._RefreshCardBallCount, self)
        gameControl:RemoveEventListener(gameControl.EventIds.CardBallConsumeChanged, self._RefreshCardBallCount, self)
        -- CardAttackAnim 注销删除（#73 重构）：由 ModelShow:UnbindFightControl 转发子组件注销
        gameControl:RemoveEventListener(gameControl.EventIds.DeathAnim, self._OnDeathAnim, self)
        gameControl:RemoveEventListener(gameControl.EventIds.FatigueAnim, self._OnFatigueAnim, self)
        gameControl:RemoveEventListener(gameControl.EventIds.PlayerHPChanged, self._OnDamageLanded, self)
        gameControl:RemoveEventListener(gameControl.EventIds.EnemyHPChanged, self._OnDamageLanded, self)
    end
    -- ModelShow:UnbindFightControl 转发子组件注销（AttackEffect/CardAttackAnim）+ 强制回收飞行中特效 #73
    -- 须在 ExitFight 之前调（ExitFight 会 ReleaseFightControl，先释放则子组件拿不到 fightControl 注销）
    if self.Parent and self.Parent.ModelShow then
        self.Parent.ModelShow:UnbindFightControl()
    end
    -- 受伤飘字注销（平行 ModelShow:UnbindFightControl，ExitFight 前调）#飘字
    if self.Parent and self.Parent.PanelTop then
        self.Parent.PanelTop:UnbindFightControl()
    end
    -- 释放战斗引擎与 EnterFight 配对在同一对显隐钩子（OnEnable/OnDisable）：复用模型下本面板靠
    -- Close(→OnDisable)/Open(→OnEnable) 切换，切走必释放、切回才重启。若放 OnDestroy，Close 不触发
    -- OnDestroy → 切走不释放且切回 OnEnable 会重复 EnterFight 误重启战斗（见变更#22）。
    -- 须在注销 FightControl 事件监听之后调用（ExitFight 会 ReleaseFightControl，先释放则上面拿到 nil）。
    self._Control:ExitFight()
end

--region 受伤飘字 coordinator（算敌人坐标+派发 SpawnDamageNumber；玩家坐标由播放器内部锚点）#飘字

--- HPChanged 回调：Drain 本帧落地伤害 → 算敌人坐标 → 派发 SpawnDamageNumber（玩家 pos=nil）。
function XUiPunishaarFightMainPanelFighting:_OnDamageLanded()
    local gameControl = self._Control and self._Control.GameControl and self._Control.GameControl.FightControl
    if not gameControl or not gameControl.STEControl then
        return
    end
    self._DamagePayloadBuf:Clear()
    local count = gameControl.STEControl:DrainDamageLanded(self._DamagePayloadBuf)
    if count <= 0 then
        return
    end
    for i = 1, count do
        local item = self._DamagePayloadBuf:GetValueByIndex(i)
        if item then
            local pos = self:_ResolveDamagePos(item.targetId)  -- 玩家 nil（播放器用 PlayerDamageTxtPoint）/ 敌人模型投影
            gameControl:DispatchEvent(gameControl.EventIds.SpawnDamageNumber, item.targetId, item.atkPerHit, item.attackTimes, false, pos)
        end
    end
end

--- 算敌人飘字坐标（FlashTextRoot-local）。玩家返 nil（播放器用 PlayerDamageTxtPoint）；敌人=模型挂点屏幕投影（参 #70）。
---@param targetId number Player/Enemy
---@return UnityEngine.Vector3|nil
function XUiPunishaarFightMainPanelFighting:_ResolveDamagePos(targetId)
    local GlobalIds = STECustomEnum.GlobalEntityIds
    if targetId == GlobalIds.Player then
        return nil  -- 播放器用 PlayerDamageTxtPoint
    elseif targetId == GlobalIds.Enemy then
        -- 敌人模型挂点(3D) → WorldToScreenPoint(UiNearCamera) → ScreenPointToLocal(FlashTextRoot, UiCamera)
        local flashTextRoot = self.Parent and self.Parent.PanelTop and self.Parent.PanelTop.FlashTextRoot
        if not flashTextRoot then
            return nil
        end
        local modelTrans = self.Parent and self.Parent.ModelShow and self.Parent.ModelShow:GetEnemyModelTransform()
        if not modelTrans then
            return nil
        end
        local uiModelGo = self.Parent and self.Parent.UiModelGo
        local camTrans = uiModelGo and uiModelGo.transform:FindTransform("UiNearCamera")
        local cam = camTrans and camTrans.gameObject:GetComponent(typeof(CS.UnityEngine.Camera))
        if not cam then
            return nil
        end
        local screenPos = CS.UnityEngine.RectTransformUtility.WorldToScreenPoint(cam, modelTrans.position)
        local ok, localPos = CS.UnityEngine.RectTransformUtility.ScreenPointToLocalPointInRectangle(
                flashTextRoot, screenPos, CS.XUiManager.Instance.UiCamera)
        if not ok or not localPos then
            return nil
        end
        return CS.UnityEngine.Vector3(localPos.x, localPos.y + DAMAGE_POP_OFFSET_UP, 0)  -- 模型上方
    end
    return nil
end

--endregion

function XUiPunishaarFightMainPanelFighting:OnDestroy()
    -- 兜底停 VSNotify 定时器（Remove 绕过 OnDisable 时的残留）
    self:_StopVsNotifyTimer()
    -- 兜底释放：ExitRun 用 XLuaUiManager.Remove 销毁 FightMain，Remove 不保证级联子节点 OnDisable，
    -- 若绕过 OnDisable 直接销毁则 ExitFight 漏调、FightControl 实例残留。ExitFight/ReleaseFightControl
    -- 幂等，与 OnDisable 已释放的场景叠加无害。
    self._Control:ExitFight()
end

function XUiPunishaarFightMainPanelFighting:RefreshAll()
    self:_RefreshNames()
    self:_RefreshRoleImage()
    self:_RefreshPlayerStatus()
    self:_RefreshEnemyStatus()
    self:_RefreshPlayerShield()
    self:_RefreshEnemyBuffList()
    self:_RefreshEnemyCd()
    self:_RefreshBallList()
    self:_RefreshCardList()
end

function XUiPunishaarFightMainPanelFighting:_RefreshNames()
    self.PanelMainHp:SetName(XPlayer.Name)
    self.PanelEnemyHp:SetName(self._Control.GameControl.FightControl:GetEnemyName())
end

function XUiPunishaarFightMainPanelFighting:_RefreshRoleImage()
    local headPortraitInfo = XPlayerManager.GetHeadPortraitInfoById(XPlayer.CurrHeadPortraitId)
    if headPortraitInfo ~= nil then
        self.PanelMainHp:SetRoleImg(headPortraitInfo.ImgSrc)
    end
    self.PanelEnemyHp:SetRoleImg(self._Control.GameControl.FightControl:GetEnemyRImg())
end

function XUiPunishaarFightMainPanelFighting:_RefreshPlayerStatus()
    local curHp = self._Control.GameControl.FightControl.STEReader:GetPlayerHp()
    local hpMax = self._Control.GameControl.FightControl.STEReader:GetPlayerHpMax()
    self.PanelMainHp:RefreshHpShow(curHp, hpMax)
end

function XUiPunishaarFightMainPanelFighting:_RefreshEnemyStatus()
    local curHp = self._Control.GameControl.FightControl.STEReader:GetEnemyHp()
    local hpMax = self._Control.GameControl.FightControl.STEReader:GetEnemyHpMax()
    self.PanelEnemyHp:RefreshHpShow(curHp, hpMax)
end

function XUiPunishaarFightMainPanelFighting:_RefreshPlayerShield()
    self.PanelMainHp:RefreshShield(self._Control.GameControl.FightControl.STEReader:GetPlayerShield())
end

--- 刷新敌人状态图标列表（护盾 + buff 共用一个列表，故 EnemyShieldChanged / DotBuffLayerChanged
--- 两事件汇入同一口，任一变都整表重算）#Buff图标
function XUiPunishaarFightMainPanelFighting:_RefreshEnemyBuffList()
    self.PanelEnemyHp:RefreshBuffList()
end

--- 刷新敌人CD进度（初始刷 + 每帧 CardCdChanged 事件刷；敌人 TickEnemy 复用该事件派发）#80
function XUiPunishaarFightMainPanelFighting:_RefreshEnemyCd()
    self.PanelEnemyHp:RefreshCd()
end

function XUiPunishaarFightMainPanelFighting:_RefreshBallList()
    self.PanelBattleBall:Refresh()
end

function XUiPunishaarFightMainPanelFighting:_RefreshCardList()
    self.PanelBattleCardList:RefreshSlot()
    self.PanelBattleCardList:Refresh()
end

function XUiPunishaarFightMainPanelFighting:_RefreshCardCd()
    self.PanelBattleCardList:RefreshAllCardCd()
    -- 敌人CD复用 CardCdChanged 事件派发（XPunishaarSTEPipeline.TickEnemy 末尾 Emit），同帧一并刷 #80
    self:_RefreshEnemyCd()
end

--- 刷新所有卡牌的产/消球数显示（CardBallProductChanged / CardBallConsumeChanged 事件回调）。
--- 轻量刷新：仅遍历已有 grid 刷球数，不全量重建（避免 Close all + RefreshCustomizedList 的 GC）。
function XUiPunishaarFightMainPanelFighting:_RefreshCardBallCount()
    self.PanelBattleCardList:RefreshBallCount()
end

-- _PlayAttackAnim 删除（#73 重构）：CardAttackAnim 自驱订阅 + FillTickDoneCards 逐卡播放收口到 AnimationPlayer

--- 死亡动画回调（DeathAnim 事件，CheckBattleEnd death gate 帧末派发）#75
--- 暂无死亡动画：no-op 预留。后续补死亡动画时，此处调 ModelShow:PlayDeathAnima，
---   动画 finish 回调里调 FightControl:FireBattleEnded() 进结算（gate 已延 delayFrames，不盖飞弹动画）。
function XUiPunishaarFightMainPanelFighting:_OnDeathAnim()
    XLog.Debug("[Punishaar] DeathAnim 触发（暂无死亡动画，no-op 预留 #75）")
end

--- 疲劳弹窗动画回调（FatigueAnim 事件，EffectGroup 组末尾 EmitEvent 派发；逻辑时间超阈值挂疲劳 buff 时触发）#80
--- 暂无疲劳弹窗动画：no-op 预留。后续补动画时此处播疲劳 UI 弹窗。
function XUiPunishaarFightMainPanelFighting:_OnFatigueAnim()
    -- 疲劳弹窗：显 PaneMiddleNotify（prefab 已挂载，OnStart 初始隐藏；FatigueAnim 事件触发=逻辑时间超阈值挂疲劳 buff）#80
    if self.PaneMiddleNotify then
        self.PaneMiddleNotify.gameObject:SetActiveEx(true)
    end
end

--region VSNotify 开场动画

--- 播战斗开始 VSNotify：显示 → 停留配置时长 → 隐藏回调启动逻辑帧。
--- 逻辑帧启动延后到动画隐藏后，保证表现层就位再 tick（#32）。
--- 复用模型下 OnEnable=新局开始，每局都播（#22 已保证切走切回 1:1 重建）。
function XUiPunishaarFightMainPanelFighting:_PlayVsNotify()
    self:_StopVsNotifyTimer()

    if self.PanelBattleVSNotify then
        self.PanelBattleVSNotify.gameObject:SetActiveEx(true)
    end

    local duration = self._Control:GetVsNotifyDuration()
    self._VsNotifyTimerId = XScheduleManager.ScheduleOnce(function()
        self:_OnVsNotifyFinished()
    end, duration * XScheduleManager.SECOND)
end

function XUiPunishaarFightMainPanelFighting:_OnVsNotifyFinished()
    self._VsNotifyTimerId = nil
    if self.PanelBattleVSNotify then
        self.PanelBattleVSNotify.gameObject:SetActiveEx(false)
    end
    -- 启动逻辑帧（StartBattle 内不再自动 StartGame，由本回调触发）
    local gameControl = self._Control.GameControl.FightControl
    if gameControl then
        gameControl:StartGame()
    end
    -- VSNotify 结束，启用倍速按钮 #68
    local fightMain = self.Parent
    if fightMain and fightMain.PanelTop then
        fightMain.PanelTop:SetSpeedBtnInteractable(true)
    end
end

function XUiPunishaarFightMainPanelFighting:_StopVsNotifyTimer()
    if self._VsNotifyTimerId then
        XScheduleManager.UnSchedule(self._VsNotifyTimerId)
        self._VsNotifyTimerId = nil
    end
end

--endregion

return XUiPunishaarFightMainPanelFighting
