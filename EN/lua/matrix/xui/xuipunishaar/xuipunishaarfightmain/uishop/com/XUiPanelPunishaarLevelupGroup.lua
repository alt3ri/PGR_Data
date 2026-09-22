--- 商店卡牌升级组（LevelupGroup：控制节点始终显示，GO 随父 CardShow 显隐；不 Open/Close 控显隐）。
--- 内部 CanLevelup + Levelup 两子节点，对称关系：
---   可升级态（canUpgrade）：显 CanLevelup + 播 TagLevelupEnable loop。
---   升级执行后（玩家拥有卡被升级，非商品栏卡）：对称隐 CanLevelup（停 loop）+ 显 Levelup + 播 LevelupSweep（finCb 播完隐 Levelup）。
---   无升级状态（canUpgrade=false 且非升级中）：CanLevelup + Levelup 都隐 + 关停动画。
--- 不走 Open/Close：PlayAnimation 只需 GO activeInHierarchy（XUiNode:PlayAnimation:442 不依赖 _IsNodeShow），
---   避免 Open 态挂 inactive 祖先下容器 re-enable 时 EnableChildNodes 级联报错（LevelupGroup _IsNodeShow=false 不级联）。
---@class XUiPanelPunishaarLevelupGroup: XUiNode
---@field protected _Control XPunishaarControl
---@field Parent
---@field CanLevelup UnityEngine.RectTransform 可升级标识节点（可升级态显 + 播 TagLevelupEnable loop）
---@field Levelup UnityEngine.RectTransform 升级中标识节点（升级执行后显 + 播 LevelupSweep，finCb 播完隐）
local XUiPanelPunishaarLevelupGroup = XClass(XUiNode, "XUiPanelPunishaarLevelupGroup")

function XUiPanelPunishaarLevelupGroup:OnStart()
    -- CanLevelup + Levelup 初始隐（无升级状态默认都隐）
    if self.CanLevelup then
        self.CanLevelup.gameObject:SetActiveEx(false)
    end
    if self.Levelup then
        self.Levelup.gameObject:SetActiveEx(false)
    end
    self._IsCanLevelUp = false
    self._IsPlayingLevelupSweep = false  -- 升级动画播中标志（防二次刷新隐 Levelup 打断）
end

--- OnEnable（Open 时调）：可升级态重播 TagLevelupEnable loop。
--- 全量刷新 Close→Open 致 PlayableDirector 停（loop 动画被打断），SetCanLevelUp 因 _IsCanLevelUp 缓存未变早返不重播；
--- 此处 OnEnable 检测 _IsCanLevelUp=true 重播 loop，恢复可升级动效。
function XUiPanelPunishaarLevelupGroup:OnEnable()
    if self._IsCanLevelUp then
        self:PlayAnimation("TagLevelupEnable", nil, nil, CS.UnityEngine.Playables.DirectorWrapMode.Loop)
    end
end

--- 设置可升级状态：可升级显 CanLevelup + 播 TagLevelupEnable loop；不可升级隐 CanLevelup（停 loop）+ 隐 Levelup（关停升级动画）。
--- 状态变化才动（false→true 首次播 loop 避免 loop 跳跃；true→true 不重播；true→false 隐停）。
---@param canUpgrade boolean
function XUiPanelPunishaarLevelupGroup:SetCanLevelUp(canUpgrade)
    if canUpgrade == self._IsCanLevelUp then
        return
    end
    self._IsCanLevelUp = canUpgrade == true
    if self._IsCanLevelUp then
        -- 可升级态：显 CanLevelup + 隐 Levelup（防 finCb 未调残留）+ 播 TagLevelupEnable loop
        if self.CanLevelup then
            self.CanLevelup.gameObject:SetActiveEx(true)
        end
        if self.Levelup then
            self.Levelup.gameObject:SetActiveEx(false)
        end
        self:PlayAnimation("TagLevelupEnable", nil, nil, CS.UnityEngine.Playables.DirectorWrapMode.Loop)
    else
        -- 不可升级态：隐 CanLevelup（停 loop）+ 隐 Levelup（关停升级动画，无升级状态都隐）
        -- 但升级动画播中（_IsPlayingLevelupSweep）保持 Levelup 显，防二次刷新（MASTER_CARD_CHANGE 补刷）打断动画
        if self.CanLevelup then
            self.CanLevelup.gameObject:SetActiveEx(false)
        end
        if self.Levelup and not self._IsPlayingLevelupSweep then
            self.Levelup.gameObject:SetActiveEx(false)
        end
    end
end

--- 升级执行后调（被升级的玩家拥有卡，非商品栏卡）：对称隐 CanLevelup + 停 TagLevelupEnable，
--- 显 Levelup + 播 LevelupSweep（finCb 播完隐 Levelup）。
--- 卡牌隐藏（CardShow Close → LevelupGroup GO inactive）时不执行（无必要）。
function XUiPanelPunishaarLevelupGroup:OnLevelupEvent()
    -- 卡牌隐藏不执行（GO activeInHierarchy = CardShow 显隐反映）
    if not self.GameObject.activeInHierarchy then
        return
    end
    -- 对称：隐 CanLevelup + 停 TagLevelupEnable loop（动画在 LevelupGroup 非 CanLevelup，隐节点不停，需 StopAnimation）
    self._IsCanLevelUp = false
    if self.CanLevelup then
        self.CanLevelup.gameObject:SetActiveEx(false)
    end
    self:StopAnimation("TagLevelupEnable")
    -- 显 Levelup + 播 LevelupSweep（finCb 播完隐 Levelup；GO 销毁则 XObjIsNil 守卫跳过）
    if self.Levelup then
        self.Levelup.gameObject:SetActiveEx(true)
        self._IsPlayingLevelupSweep = true  -- 升级动画播中标志（SetCanLevelUp(false) 不隐 Levelup，防二次刷新打断）
        self:PlayAnimation("LevelupSweep", function()
            self._IsPlayingLevelupSweep = false  -- 动画完成清标志
            if self.Levelup and not XTool.UObjIsNil(self.Levelup) then
                self.Levelup.gameObject:SetActiveEx(false)
            end
        end)
    end
end

return XUiPanelPunishaarLevelupGroup
