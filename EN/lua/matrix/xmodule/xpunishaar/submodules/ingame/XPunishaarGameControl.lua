--- 关卡级生命周期壳：进入关卡(EnterRun)时由 Control lazy 创建，退出结算界面时销毁。
--- 拥有关卡内子控制器 RunControl（逻辑流程，eager）+ FightControl（战斗引擎，lazy 于 EnterFight）。
--- 职责：管理关卡级 lifecycle + GC；不承担具体逻辑（RunControl 负责）。
--- 设计见 readme #60：GameControl 跨结算存活（per-battle 结算 + run 级 ChallengeSettlement 均在生命内），
---   真正退出关卡 = 退出 ChallengeSettlement 界面（_OnBtnExit）或续关(EnterGame release+rebuild)。
---@class XPunishaarGameControl : XControl
---@field private _MainControl XPunishaarControl  -- 根 Control（祖父），框架 Ctor 传根
---@field public RunControl XPunishaarRunControl  -- 关卡逻辑流程子控
---@field public FightControl XPunishaarFightControl  -- 战斗引擎子控（lazy）
local XPunishaarGameControl = XClass(XControl, "XPunishaarGameControl", true)

XClassPartialRequire("XModule/XPunishaar/SubModules/InGame/XPunishaarGameConfigControl", "XPunishaarGameControl")
-- 关卡级 flow partial（原 Control 降级，外部界面不可直调，经 _Control.GameControl 访问）
-- 编排策略链+找位算法+InsertCard/BuyGoods/MoveCard+ArrangeRewardCard 骨架（#72 自 Shop 抽离，self 不变跨 partial 同类）
XClassPartialRequire("XModule/XPunishaar/SubModules/InGame/XPunishaarGameControlArrange", "XPunishaarGameControl")
XClassPartialRequire("XModule/XPunishaar/SubModules/InGame/XPunishaarGameControlShop", "XPunishaarGameControl")
XClassPartialRequire("XModule/XPunishaar/SubModules/InGame/XPunishaarGameControlNodeFlow", "XPunishaarGameControl")
XClassPartialRequire("XModule/XPunishaar/SubModules/InGame/XPunishaarGameControlDrag", "XPunishaarGameControl")
XClassPartialRequire("XModule/XPunishaar/SubModules/InGame/XPunishaarGameControlProjection", "XPunishaarGameControl")
-- HUD 调度 partial（关卡内：节点推进选+缓存+显隐，#86；condition 求值 TODO）
XClassPartialRequire("XModule/XPunishaar/SubModules/Hud/XPunishaarHudControl", "XPunishaarGameControl")

function XPunishaarGameControl:OnInit()
    self:InitConfig()

    -- 关卡逻辑子控（eager：整个关卡期常驻）
    self.RunControl = self:AddSubControl(require("XModule/XPunishaar/SubModules/Run/XPunishaarRunControl"))
    -- typed 回指：子控拿父 GameControl（框架 _MainControl 指根 Control 非即时父，故显式置回指）
    self.RunControl._GameControl = self

    -- HUD 调度缓存（#86：当前节点选的 HUD cfg + 玩家手动关标志 + 组加载 buffer 复用）
    self._HudCfg = nil
    self._IsHudDismissed = false
    self._HudCfgBuffer = {}
    self._HudCandidateBuffer = {}      -- 过滤后候选 buffer 复用（GameNoRepeat=1 不放回过滤后）
    self._DrawnHudNoRepeatSet = {}     -- 本关卡已抽 GameNoRepeat=1 的 hudId 集合（关卡级不放回缓存）

    -- 升级动画播放缓存：保留卡 TemplateId + finalLevel（升级后留的卡；BuyUpgradeChain 设，RefreshAsEquipped 查匹配播+清）#升级动画
    -- 用 TemplateId+Level 而非 MasterCardId：keptMasterId=chainConsumed[1].Id 是被消耗卡（升级后移除不在列表），保留卡 Id 不可预知（服务端合成），但保留卡 TemplateId=商品 TemplateId + Level=finalLevel 可预知
    self._PendingLevelupAnimTemplateId = nil
    self._PendingLevelupAnimLevel = nil
end

--- typed 祖父接口：取根 Control（XPunishaarControl）。
--- 子控经此访问祖父，不走裸 _MainControl 链（修正2：禁连续向上访问 _MainControl）。
---@return XPunishaarControl
function XPunishaarGameControl:GetControl()
    return self._MainControl
end

--- 进入关卡（Control:EnterGame lazy 建 GameControl 后调）。
---@param gameData table 服务端局数据
function XPunishaarGameControl:EnterRun(gameData)
    self.RunControl:EnterRun(gameData)
end

--- 关内节点推进时关 FightMain 面板（不销毁 GameControl，仍处关卡内）。
function XPunishaarGameControl:ExitRun()
    self.RunControl:ExitRun()
end

--- 进入战斗（玩家点开始战斗，Fighting UI OnStart 经 Control:EnterFight 转发到此）。
--- lazy 建 FightControl + StartBattle；BattleEnded 监听挂 GameControl（原 Control:_OnBattleEnded 迁此）。
---@param initData XPunishaarBattleInitData 开战契约
function XPunishaarGameControl:EnterFight(initData)
    if not self.FightControl then
        self.FightControl = self:AddSubControl(require("XModule/XPunishaar/SubModules/InGame/XPunishaarFightControl"))
        self.FightControl._GameControl = self  -- typed 回指
        self.FightControl:AddEventListener(self.FightControl.EventIds.BattleEnded, handler(self, self._OnBattleEnded))
    end
    self.FightControl:StartBattle(initData)
end

--- 战斗子阶段结束（Control:ExitFight / EnterStory 转发）：释放战斗引擎，GameControl 仍存活（仍在关卡内）。
function XPunishaarGameControl:ReleaseFightControl()
    if self.FightControl then
        self:RemoveSubControl(self.FightControl)
        self.FightControl = nil
    end
end

--- 战斗结束回调（FightControl.BattleEnded 监听，原 Control:_OnBattleEnded 迁此）。
---@param result number BattleResult 枚举
---@param loseMaxColor number
function XPunishaarGameControl:_OnBattleEnded(result, loseMaxColor)
    self.RunControl:OnBattleEnded(result, loseMaxColor)
end

function XPunishaarGameControl:OnRelease()
    -- 框架 RemoveSubControl 已级联释放 RunControl/FightControl 子控，此处只清引用
    self.RunControl = nil
    self.FightControl = nil
    -- 保底清关卡级 HUD 缓存（_DrawnHudNoRepeatSet 不放回集合；防实例引用残留致下关卡误判）#86
    self:ClearHud()
    -- 清升级动画缓存（防残留致下关卡误播）#升级动画
    self._PendingLevelupAnimTemplateId = nil
    self._PendingLevelupAnimLevel = nil
end

return XPunishaarGameControl
