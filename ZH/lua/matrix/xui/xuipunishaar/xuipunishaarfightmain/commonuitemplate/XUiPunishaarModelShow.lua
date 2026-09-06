--- 卡牌/敌人 3D 模型 + 动画 + 特效 XUiNode（瘦壳，纯表现层）。
--- 5 类拆分（#73 重构）：本壳只管生命周期 + BuySuccess 订阅转发 + 持4子组件 + 兼容转发；
---   业务职责分发到 Model/Animation/Effect/Config 子组件。
--- 挂点经 prefab UiObject 引用（非 FindTransform）：
---   - 卡牌：PanelRoleModel1..N 连续索引（nil 视为结束 break）
---   - 敌人：PanelEnemyModel（单）
---   - 特效根：PanelEffectRoot（EffectPlayer 池 createFunc fallback parent）
--- XUiNode:InitNode 自动 InitUiObject 填充 self.PanelRoleModel1..N / self.PanelEnemyModel / self.PanelEffectRoot。
---@class XUiPunishaarModelShow : XUiNode
---@field protected _Control XPunishaarControl
---@field PanelRoleModel1 UnityEngine.RectTransform 卡牌模型挂点 1（连续索引 1..N，遍历到 nil 止；@field 仅列代表，余按名 PanelRoleModel2..N 自动填充）
---@field PanelEnemyModel UnityEngine.RectTransform 敌人模型挂点（单）
---@field PanelEffectRoot UnityEngine.Transform 特效根挂点（EffectPlayer 池 createFunc fallback parent）
---@field private _ConfigResolver XUiPunishaarModelConfigResolver
---@field private _ModelPool XUiPunishaarModelPool
---@field private _AnimationPlayer XUiPunishaarAnimationPlayer
---@field private _EffectPlayer XUiPunishaarEffectPlayer
local XUiPunishaarModelShow = XClass(XUiNode, "XUiPunishaarModelShow")

local XUiPunishaarModelConfigResolver = require("XUi/XUiPunishaar/XUiPunishaarFightMain/CommonUiTemplate/Model/XUiPunishaarModelConfigResolver")
local XUiPunishaarModelPool = require("XUi/XUiPunishaar/XUiPunishaarFightMain/CommonUiTemplate/Model/XUiPunishaarModelPool")
local XUiPunishaarAnimationPlayer = require("XUi/XUiPunishaar/XUiPunishaarFightMain/CommonUiTemplate/Model/XUiPunishaarAnimationPlayer")
local XUiPunishaarEffectPlayer = require("XUi/XUiPunishaar/XUiPunishaarFightMain/CommonUiTemplate/Model/XUiPunishaarEffectPlayer")

local STECustomEnum = require("XModule/XPunishaar/STEDefine/STECustomEnum")

function XUiPunishaarModelShow:OnStart()
    -- 4 子组件作 XUiNode 子节点创建（New(node, parent)），_Control 由框架从 parent 链注入
    -- （不业务传 control，对齐 XUiNode 范式）。子组件共享 self.Transform（无视觉，纯逻辑子节点），
    -- InitUiObject 会把 ModelShow 的 prefab 挂点引用（PanelRoleModel1..N/PanelEnemyModel）填到各子组件 self 上。
    self._ConfigResolver = XUiPunishaarModelConfigResolver.New(self.Transform, self)
    self._ModelPool = XUiPunishaarModelPool.New(self.Transform, self)
    self._AnimationPlayer = XUiPunishaarAnimationPlayer.New(self.Transform, self)
    self._EffectPlayer = XUiPunishaarEffectPlayer.New(self.Transform, self)
    -- sibling refs downward 注入（非 Ctor 传、非 upward 访问）；挂点遍历在 ModelPool:OnStart 内做
    self._ModelPool:SetSiblings(self._ConfigResolver)
    self._AnimationPlayer:SetSiblings(self._ModelPool, self._ConfigResolver)
    self._EffectPlayer:SetSiblings(self._ModelPool, self._ConfigResolver, self._AnimationPlayer)
end

--region 生命周期（XUiNode 钩子）

function XUiPunishaarModelShow:OnEnable()
    local gc = self._Control and self._Control.GameControl
    if not gc then
        return
    end
    gc:AddEventListener(gc.ShopEventId.BuySuccess, self.RefreshFightAreaModels, self)
    -- 事件获得卡（NotifyPunishaarMasterCardChange）经全局事件派发，补订刷新战斗区模型（否则事件卡上阵后模型不显示）#事件卡模型
    XEventManager.AddEventListener(XEventId.EVENT_PUNISHAAR_MASTER_CARD_CHANGE, self.RefreshFightAreaModels, self)
    self:RefreshFightAreaModels()  -- 初始渲染
end

--- 切走/隐藏即释放模型 + 注销 BuySuccess（标准缓存池策略，非低内存模式）。
--- 注意：AttackEffect/CardAttackAnim 订阅由 PanelFighting:OnDisable→UnbindFightControl 转发注销，
---   不在此处（与 FightMain 切走对齐 vs PanelFighting 切走对齐是不同时序，订阅归 PanelFighting）。#73
function XUiPunishaarModelShow:OnDisable()
    local gc = self._Control and self._Control.GameControl
    if gc then
        gc:RemoveEventListener(gc.ShopEventId.BuySuccess, self.RefreshFightAreaModels, self)
    end
    XEventManager.RemoveEventListener(XEventId.EVENT_PUNISHAAR_MASTER_CARD_CHANGE, self.RefreshFightAreaModels, self)
    self:ReleaseModel()
end

--- 面板销毁清空缓存池 + 注销兜底 + 子组件 OnDestroy 转发。
function XUiPunishaarModelShow:OnDestroy()
    local gc = self._Control and self._Control.GameControl
    if gc then
        gc:RemoveEventListener(gc.ShopEventId.BuySuccess, self.RefreshFightAreaModels, self)
    end
    XEventManager.RemoveEventListener(XEventId.EVENT_PUNISHAAR_MASTER_CARD_CHANGE, self.RefreshFightAreaModels, self)
    self:ClearPool()
    if self._EffectPlayer then
        self._EffectPlayer:OnDestroy()
    end
end

--endregion

--region FightControl 订阅转发（PanelFighting:OnEnable/OnDisable 显式调，与 PanelFighting 切换对齐）

--- PanelFighting:OnEnable（EnterFight 后）调，转发 AnimationPlayer + EffectPlayer 订阅。
--- FightControl 在 PanelFighting:OnEnable 的 EnterFight 后才就绪，ModelShow:OnEnable 阶段不订阅。#73
function XUiPunishaarModelShow:BindFightControl()
    local fightControl = self._Control and self._Control.GameControl and self._Control.GameControl.FightControl
    if not fightControl then
        return
    end
    self._AnimationPlayer:BindFightControl(fightControl)
    self._EffectPlayer:BindFightControl(fightControl)
end

--- PanelFighting:OnDisable 调，转发子组件注销 + 强制回收飞行中特效。
function XUiPunishaarModelShow:UnbindFightControl()
    if self._AnimationPlayer then
        self._AnimationPlayer:UnbindFightControl()
    end
    if self._EffectPlayer then
        self._EffectPlayer:UnbindFightControl()
    end
end

--endregion

--region 兼容转发（旧 API 转发到子组件，外部调用方未全迁移期保兼容）

function XUiPunishaarModelShow:ShowCardModel(cardId, slotIndex)
    self._ModelPool:ShowCardModel(cardId, slotIndex)
end

function XUiPunishaarModelShow:ShowEnemyModel(modelName, idleAnima)
    self._ModelPool:ShowEnemyModel(modelName, idleAnima)
end

function XUiPunishaarModelShow:RefreshEnemyModel()
    self._ModelPool:RefreshEnemyModel()
end

function XUiPunishaarModelShow:ReleaseModel()
    if self._ModelPool then
        self._ModelPool:ReleaseModel()
    end
end

function XUiPunishaarModelShow:ReleaseEnemyModel()
    if self._ModelPool then
        self._ModelPool:ReleaseEnemyModel()
    end
end

--- 商人模型加载（Shopping 态专用，复用 PanelEnemyModel，镜像 ShowEnemyModel）。
---@param modelName string shopCfg.ModelId
---@param idleAnima string|nil shopCfg.NormalIdleAnima
function XUiPunishaarModelShow:ShowShopNpcModel(modelName, idleAnima)
    if self._ModelPool then
        self._ModelPool:ShowShopNpcModel(modelName, idleAnima)
    end
end

--- 取敌方模型 Transform（供飘字 coordinator=PanelFighting 算"模型上方"坐标用，转发 ModelPool）#飘字
---@return UnityEngine.Transform|nil
function XUiPunishaarModelShow:GetEnemyModelTransform()
    if self._ModelPool then
        return self._ModelPool:GetEnemyModelTransform()
    end
end

function XUiPunishaarModelShow:ClearPool()
    if self._ModelPool then
        self._ModelPool:ClearPool()
    end
end

function XUiPunishaarModelShow:RefreshFightAreaModels()
    if self._ModelPool then
        self._ModelPool:RefreshFightAreaModels()
    end
end

--- 攻击动画（slot 默认 1，fromBegin=true 打断重播）。
--- 注意：旧签名 (cardId, slotIndex, fromBegin) → AnimationPlayer:PlayCardAttack(slotIndex, cardId, fromBegin) 参数顺序反转。#73
---@param cardId number
---@param slotIndex number|nil
---@param fromBegin boolean|nil
function XUiPunishaarModelShow:PlayAttackAnima(cardId, slotIndex, fromBegin)
    self._AnimationPlayer:PlayCardAttack(slotIndex, cardId, fromBegin)
end

---@param cardId number
---@param slotIndex number|nil
function XUiPunishaarModelShow:PlayIdleAnima(cardId, slotIndex)
    self._AnimationPlayer:PlayCardIdle(slotIndex, cardId)
end

---@param fromBegin boolean|nil
function XUiPunishaarModelShow:PlayEnemyAttackAnima(fromBegin)
    self._AnimationPlayer:PlayEnemyAttack(fromBegin)
end

---@param slotIndex number
---@return UnityEngine.Transform|nil
function XUiPunishaarModelShow:GetCardModelTransform(slotIndex)
    return self._ModelPool:GetCardModelTransform(slotIndex)
end

---@return UnityEngine.Transform|nil
function XUiPunishaarModelShow:GetFirstCardModelTransform()
    return self._ModelPool:GetFirstCardModelTransform()
end

--- 取敌人攻击特效 prefab 路径（兼容转发，收口到 ConfigResolver）。
---@return string|nil
function XUiPunishaarModelShow:GetEnemyAttackSFX()
    return self._ConfigResolver:GetAttackSFX(STECustomEnum.GlobalEntityIds.Enemy)
end

--endregion

return XUiPunishaarModelShow
