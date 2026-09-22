--- 大巴扎战斗模型槽 + 生命周期 + Transform 查询（纯表现层，XUiNode 子节点）。
--- 持 _CardModelPanels[1..N] + _EnemyModelPanel（XUiPanelRoleModel 实例），挂点经 prefab UiObject 引用：
---   - 卡牌：self.PanelRoleModel1..N 连续索引（nil 视为结束 break；InitUiObject 填充，共享 ModelShow Transform）
---   - 敌人：self.PanelEnemyModel（单）
--- Transform 查询收口 slot-based 接口（GetCardModelTransform(slot)/GetFirstCardModelTransform/GetEnemyModelTransform），
---   entityId→slotIndex 转换由 EffectPlayer 用 STEReader:GetCardIndex 做（ModelPool 不持 STEReader ref，保持纯模型槽职责）。
--- 逻辑整段搬运自 XUiPunishaarModelShow（OnStart/ShowCardModel/ShowEnemyModel/RefreshEnemyModel/
---   ReleaseModel/ReleaseEnemyModel/ClearPool/RefreshFightAreaModels/Get*Transform），不改变语义。#63 #73
---@class XUiPunishaarModelPool : XUiNode
---@field protected _Control XPunishaarControl
---@field private _ConfigResolver XUiPunishaarModelConfigResolver
---@field private _CardModelPanels table<number, XUiPanelRoleModel> [slotIndex] = XUiPanelRoleModel
---@field private _EnemyModelPanel XUiPanelRoleModel|nil
---@field private _AreaCardsList XTool.XList 紧凑一维序卡牌缓冲（RefreshFightAreaModels 复用，不每次 new）
---@field private _LoadedCardSlotCount number 已加载战斗区卡牌 slot 数（RefreshFightAreaModels 缓存，供 GetPlayerCenterPos 算中心用）#81
local XUiPunishaarModelPool = XClass(XUiNode, "XUiPunishaarModelPool")

local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")

-- 卡牌挂点遍历上限：略大于当前最大 8，nil 即止（连续索引约定）
local MAX_CARD_SLOT = 12

--- XUiNode 生命周期钩子：New 后框架调。
--- 挂点引用（self.PanelRoleModel1..N / self.PanelEnemyModel）由 InitUiObject 填充
---   （子组件共享 ModelShow.Transform/GameObject，prefab UiObject 引用同步填到 self 上，不读 parent 字段）。
function XUiPunishaarModelPool:OnStart()
    self._CardModelPanels = {}
    self._EnemyModelPanel = nil
    self._LoadedCardSlotCount = 0

    -- 遍历卡牌挂点（连续索引，nil 视为结束）+ 创建敌人模型 panel
    local parentName = "PunishaarCardModel"
    for i = 1, MAX_CARD_SLOT do
        local node = self["PanelRoleModel" .. i]
        if not node then
            break
        end
        ---@type XUiPanelRoleModel
        local panel = XUiPanelRoleModel.New(node, parentName .. i, true)  -- hideWeapon=true
        panel:ShowRoleModel()
        self._CardModelPanels[i] = panel
    end

    if self.PanelEnemyModel then
        ---@type XUiPanelRoleModel
        self._EnemyModelPanel = XUiPanelRoleModel.New(self.PanelEnemyModel, parentName .. "Enemy", true)
        self._EnemyModelPanel:ShowRoleModel()
    end
end

--- sibling refs downward 注入（ModelShow:OnStart 创建后调，非 Ctor 传、非 upward 访问）。
---@param configResolver XUiPunishaarModelConfigResolver
function XUiPunishaarModelPool:SetSiblings(configResolver)
    self._ConfigResolver = configResolver
end

--- 取模型根 Transform（EffectPlayer 池 createFunc fallback parent 用）。
--- 子组件共享 ModelShow.Transform，self.Transform 即模型根（等价原 self._ModelShow.Transform）。
---@return UnityEngine.Transform
function XUiPunishaarModelPool:GetModelRootTransform()
    return self.Transform
end

---@param slotIndex number
---@return XUiPanelRoleModel|nil
function XUiPunishaarModelPool:GetCardModelPanel(slotIndex)
    return self._CardModelPanels and self._CardModelPanels[slotIndex]
end

---@return XUiPanelRoleModel|nil
function XUiPunishaarModelPool:GetEnemyModelPanel()
    return self._EnemyModelPanel
end

--- 主卡模型加载到指定 slot（默认 1）。查 PunishaarCardModel 取 ModelId + NormalIdleAnima。无行/空→不加载。
---@param cardId number 卡牌模板 Id（主卡 cardId 才有行）
---@param slotIndex number|nil 卡牌挂点索引 1..N（默认 1）
function XUiPunishaarModelPool:ShowCardModel(cardId, slotIndex)
    local panel = self._CardModelPanels and self._CardModelPanels[slotIndex or 1]
    if not panel then
        return
    end
    local row = self._ConfigResolver:GetCardModelRow(cardId)
    if not row or string.IsNilOrEmpty(row.ModelId) then
        return
    end

    panel:UpdateCuteModelByModelName(nil, nil, nil, nil, nil,
            row.ModelId, function()
                CS.XShadowHelper.AddShadow(panel.GameObject, true)
                XUiHelper.TryAddComponent(panel:GetCurRoleModel(), typeof(CS.XAnimationFrameEventManager))
            end, true)
    panel:ShowRoleModel()

    if not string.IsNilOrEmpty(row.NormalIdleAnima) then
        panel:PlayAnimaCross(row.NormalIdleAnima)
    end
end

--- 敌人模型加载（直喂 modelName，不经 PunishaarCardModel 查表）。
---@param modelName string Npc 表 ModelId 值（= enemyCfg.EnemyModel）
---@param idleAnima string|nil 待机动画名
function XUiPunishaarModelPool:ShowEnemyModel(modelName, idleAnima)
    if not self._EnemyModelPanel or string.IsNilOrEmpty(modelName) then
        return
    end
    self._EnemyModelPanel:UpdateCuteModelByModelName(nil, nil, nil, nil, nil,
            modelName, function()
                CS.XShadowHelper.AddShadow(self._EnemyModelPanel.GameObject, true)
            end, true)
    self._EnemyModelPanel:ShowRoleModel()

    if not string.IsNilOrEmpty(idleAnima) then
        self._EnemyModelPanel:PlayAnimaCross(idleAnima)
    end
end

--- 敌人/Boss 模型刷新：契约 fightId → Fight.EnemyId → Enemy.EnemyModel → ShowEnemyModel。
--- fightId 取法 + AttackAnima 缓存收口到 ConfigResolver（GetEnemyCfgByFightId + SetEnemyAttackAnima）。#63 #73
function XUiPunishaarModelPool:RefreshEnemyModel()
    if not self._Control then
        return
    end
    local enemyCfg = self._ConfigResolver:GetEnemyCfgByFightId()
    -- 缓存敌人攻击动画名（ConfigResolver 持缓存，供 PlayEnemyAttack 读，避免每次攻击现查）#73
    self._ConfigResolver:SetEnemyAttackAnima(enemyCfg and enemyCfg.AttackAnima)
    self:ShowEnemyModel(enemyCfg and enemyCfg.EnemyModel, enemyCfg and enemyCfg.NormalIdleAnima)
end

--- 释放所有模型（卡各 slot + 敌人）回缓存池（切卡/关界面前调，对齐 Task_3 降内存）。
function XUiPunishaarModelPool:ReleaseModel()
    if self._CardModelPanels then
        for _, panel in pairs(self._CardModelPanels) do
            panel:ReleaseCurrentModel()
        end
    end
    if self._EnemyModelPanel then
        self._EnemyModelPanel:ReleaseCurrentModel()
    end
    self._LoadedCardSlotCount = 0  -- 释放后无已加载卡牌，中心点查询将返 nil #81
end

--- 仅释放敌人模型（主卡保留）。Shop 态切换时调——Shop 无战斗上下文，敌人模型应释放。#63
function XUiPunishaarModelPool:ReleaseEnemyModel()
    if self._EnemyModelPanel then
        self._EnemyModelPanel:ReleaseCurrentModel()
    end
end

--- 商人模型加载到 PanelEnemyModel（Shopping 态专用，敌人此时已释放）。
--- 镜像 ShowEnemyModel 范式（Q4 不 hoist，复制），动画在模型加载完成后（callback 内）播。
---@param modelName string 商人模型 modelName（shopCfg.TraderModelId），空则不加载
---@param idleAnima string|nil 商人待机动画名，空则不播；须模型加载完成后才播（强前后关系）
function XUiPunishaarModelPool:ShowShopNpcModel(modelName, idleAnima)
    if not self._EnemyModelPanel or string.IsNilOrEmpty(modelName) then
        return
    end
    self._EnemyModelPanel:UpdateCuteModelByModelName(nil, nil, nil, nil, nil,
            modelName, function()
                CS.XShadowHelper.AddShadow(self._EnemyModelPanel.GameObject, true)
                -- 模型加载完成后才播动画（强前后关系：先有模型 Animator 才能 PlayAnimaCross）
                if not string.IsNilOrEmpty(idleAnima) then
                    self._EnemyModelPanel:PlayAnimaCross(idleAnima)
                end
            end, true)
    self._EnemyModelPanel:ShowRoleModel()
end

--- 清空所有模型缓存池（面板销毁调）。
function XUiPunishaarModelPool:ClearPool()
    if self._CardModelPanels then
        for _, panel in pairs(self._CardModelPanels) do
            panel:RemoveRoleModelPool()
        end
    end
    if self._EnemyModelPanel then
        self._EnemyModelPanel:RemoveRoleModelPool()
    end
end

--- 战斗区卡牌模型刷新：按紧凑一维序（StartPos 升序）遍历战斗区卡，每张卡加载到对应 slot。
--- 触发：OnEnable 初始 + BuySuccess（买/卖/移/弃/冻结——凡战斗区卡集合变更）。#63
function XUiPunishaarModelPool:RefreshFightAreaModels()
    if not self._Control then
        self._LoadedCardSlotCount = 0
        return
    end
    if not self._AreaCardsList then
        self._AreaCardsList = XTool.XListNew()
    end
    local list = self._AreaCardsList
    list:Clear()
    local CardAreaType = XMVCA.XPunishaar.EnumConst.CardAreaType
    local count = self._Control:FillAreaCardsSorted(CardAreaType.FightArea, list)
    self._LoadedCardSlotCount = count  -- 缓存已加载 slot 数，供 GetPlayerCenterPos 算阵型中心 #81
    for i = 1, count do
        local card = list:GetValueByIndex(i)
        if card then
            self:ShowCardModel(card.TemplateId, i)
        end
    end
    -- 空 slot（> count）释放模型
    for i = count + 1, MAX_CARD_SLOT do
        local panel = self._CardModelPanels and self._CardModelPanels[i]
        if not panel then
            break
        end
        panel:ReleaseCurrentModel()
    end
end

--region Transform 查询（slot-based，供 EffectPlayer 调）

--- 取卡牌模型挂点 Transform（按 slot 索引，1-based）。
---@param slotIndex number
---@return UnityEngine.Transform|nil
function XUiPunishaarModelPool:GetCardModelTransform(slotIndex)
    local panel = self._CardModelPanels and self._CardModelPanels[slotIndex]
    return panel and panel.Transform
end

--- 取第一张已加载卡牌的模型挂点 Transform（供玩家锚点用，弃重心算）。
---@return UnityEngine.Transform|nil
function XUiPunishaarModelPool:GetFirstCardModelTransform()
    if not self._CardModelPanels then
        return nil
    end
    for i = 1, MAX_CARD_SLOT do
        local panel = self._CardModelPanels[i]
        if panel and panel.Transform then
            return panel.Transform
        end
    end
    return nil
end

--- 取敌人模型挂点 Transform（敌人单实例，无 slot）。
---@return UnityEngine.Transform|nil
function XUiPunishaarModelPool:GetEnemyModelTransform()
    local panel = self._EnemyModelPanel
    return panel and panel.Transform
end

--- 取玩家卡牌阵型中心点坐标（敌人攻击飞弹落点用）。
--- Player 无实体，敌人攻击落点=所有已加载卡牌模型坐标的中心点（与 targetId 无关）#81。
--- 无已加载卡牌（count==0）时回退取任一卡牌挂点坐标（首 slot panel Transform）。
--- 用 GetPosition 标量 API（避 Vector3 装箱 GC），返回 3 标量；调用方在必须 Vector3 处
---   （如 BattleEffect 贝塞尔）才构造，不在本方法内构造 Vector3。
--- 基于 RefreshFightAreaModels 缓存的 _LoadedCardSlotCount（slots 1..count 已加载），
---   战斗区卡加载/买卖/移动经 BuySuccess→RefreshFightAreaModels 自动跟进中心。
---@return number|nil cx
---@return number|nil cy
---@return number|nil cz 无任何卡牌挂点时全 nil
function XUiPunishaarModelPool:GetPlayerCenterPos()
    local count = self._LoadedCardSlotCount or 0
    -- 有已加载卡牌：取所有已加载卡牌模型坐标的中心点（标量累加，避每卡 .position 装箱）
    if count > 0 and self._CardModelPanels then
        local x, y, z, n = 0, 0, 0, 0
        for i = 1, count do
            local panel = self._CardModelPanels[i]
            if panel and panel.Transform then
                local px, py, pz = panel.Transform:GetPosition()
                x = x + px
                y = y + py
                z = z + pz
                n = n + 1
            end
        end
        if n > 0 then
            return x / n, y / n, z / n
        end
    end
    -- 无已加载卡牌：回退取任一卡牌挂点坐标（首 slot panel Transform，GetPosition 标量）
    local fallback = self:GetFirstCardModelTransform()
    if fallback then
        return fallback:GetPosition()
    end
    return nil, nil, nil  -- prefab 无任何卡牌挂点（PanelRoleModel1 缺失）
end

--endregion

return XUiPunishaarModelPool
