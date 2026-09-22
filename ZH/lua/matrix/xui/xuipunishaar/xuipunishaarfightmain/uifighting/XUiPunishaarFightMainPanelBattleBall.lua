local XUiGridBattleBall = require("XUi/XUiPunishaar/XUiPunishaarFightMain/UiFighting/XUiGridBattleBall")

---@class XUiPunishaarFightMainPanelBattleBall : XUiNode
---@field _Control XPunishaarControl
---@field TxtBallNum UnityEngine.UI.Text 当前球数（固定显示当前球数）
---@field TxtBallNumMax UnityEngine.UI.Text 球槽容量（固定显示当前球槽容量）
---@field PanelBallList UnityEngine.RectTransform
---@field GridBall UnityEngine.RectTransform
local XUiPunishaarFightMainPanelBattleBall = XClass(XUiNode, "XUiPunishaarFightMainPanelBattleBall")

function XUiPunishaarFightMainPanelBattleBall:OnStart(...)
end

function XUiPunishaarFightMainPanelBattleBall:OnEnable()
end

function XUiPunishaarFightMainPanelBattleBall:OnDisable()
end

function XUiPunishaarFightMainPanelBattleBall:OnDestroy()
end

function XUiPunishaarFightMainPanelBattleBall:Refresh()
    local fightControl = self._Control and self._Control.GameControl and self._Control.GameControl.FightControl
    local reader = fightControl and fightControl.STEReader
    if not reader then
        return  -- FightControl 未就绪/已释放（切态/销毁时 ForceStop 调 Refresh 兜底，不对齐无妨 #消球动效动画队列）
    end
    local ballList = self:_GetNewOrResetBallList()
    reader:FillBallList(ballList)
    local ballSlotCapacity = reader:GetBallSlotCapacity()

    -- 拆分：TxtBallNum 固定显当前球数，TxtBallNumMax 固定显球槽容量（原插值字符串 BattleBallProgress 弃用）
    if self.TxtBallNum then
        self.TxtBallNum.text = tostring(#ballList)
    end
    if self.TxtBallNumMax then
        self.TxtBallNumMax.text = tostring(ballSlotCapacity)
    end

    if self._BallGridDict == nil then
        ---@type table<UnityEngine.GameObject, XUiGridBattleBall>
        self._BallGridDict = {}
    else
        for i, v in pairs(self._BallGridDict) do
            v:Close()
        end
    end
    -- 有序球 grid 列表（按 BallList 顺序，供动画队列增量操作：消球取队头该色+隐藏 GO/产球挤头；替代旧 cursor 的 pairs 无序遍历 #消球动效动画队列）
    if self._BallGridList == nil then
        self._BallGridList = {}
    else
        for i = #self._BallGridList, 1, -1 do
            self._BallGridList[i] = nil
        end
    end

    XUiHelper.RefreshCustomizedList(self.PanelBallList.transform, self.GridBall, ballList and #ballList or 0, function(index, go)
        local grid = self._BallGridDict[go]
        if not grid then
            grid = XUiGridBattleBall.New(go, self)
            self._BallGridDict[go] = grid
        end
        grid:Open()
        grid:Refresh(ballList[index])
        self._BallGridList[index] = grid  -- 有序列表填（队头在 [1]，对齐 BallList FIFO 顺序）
    end)
    -- STE BallList Len 镜像（供 ProduceBall 算挤头次数，避免 UI _BallGridList 不含产球新球致多步同帧挤头错算 #149审M1）
    self._BallListLen = ballList and #ballList or 0
end

function XUiPunishaarFightMainPanelBattleBall:_GetNewOrResetBallList()
    if self._BallList == nil then
        self._BallList = {}
    else
        for i = #self._BallList, 1, -1 do
            self._BallList[i] = nil
        end
    end
    return self._BallList
end

--- 从队头取 N 颗指定颜色球位置 + grid 引用 + 从有序列表删（消球动画步调）。#消球动效动画队列
--- 有序遍历 _BallGridList（队头在前，对齐 STE ConsumeBall FIFO 消球），取前 count 颗该色。
--- 不立即隐藏 grid：trail delay 0.1s 期间球还在，delay 结束 trail 隐藏 grid（球消失）+ 飞向卡。
--- 返回 positions[]+grids[] 平行数组（队头在前，避免 per-ball {pos,grid} table 包装减 GC）。全播完 Refresh 重建对齐 STE 最终态。
---@param color number BallColor
---@param count number
---@return Vector3[] positions, XUiGridBattleBall[] grids（队头在前，平行）
function XUiPunishaarFightMainPanelBattleBall:RemoveBallsFromFront(color, count)
    -- 复用 buffer（避免每步新建 positions/grids/removeIndices table #消球动效动画队列）
    if not self._RemovePositionsBuf then
        self._RemovePositionsBuf = {}
        self._RemoveGridsBuf = {}
        self._RemoveIndicesBuf = {}
    end
    local positions = self._RemovePositionsBuf
    local grids = self._RemoveGridsBuf
    local removeIndices = self._RemoveIndicesBuf
    -- 清 buf（复用前清 stale；positions/grids 平行，removeIndices 同长）
    for i = #positions, 1, -1 do
        positions[i] = nil
        grids[i] = nil
        removeIndices[i] = nil
    end
    if not self._BallGridList or not count or count <= 0 then
        return positions, grids
    end
    local found = 0
    for i = 1, #self._BallGridList do
        if found >= count then break end
        local grid = self._BallGridList[i]
        if grid and grid:GetColor() == color and grid.GameObject.activeSelf then
            found = found + 1
            positions[found] = grid.Transform.position
            grids[found] = grid
            removeIndices[found] = i
        end
    end
    -- STE Len 镜像同步：删前记 Len，删后 Len -= count（STE 实际消数；非 found——found 是 UI _BallGridList 该色 grid 数，
    -- 若 STE 消产球新球（不在 _BallGridList）则 found<count，按 found 扣会致 _BallListLen 偏大→下次 ProduceBall 多挤 #核实3）
    local lenBefore = self._BallListLen or #self._BallGridList
    -- 倒序删（table.remove 倒序安全，不影响前序 index）；grid 不隐藏（trail delay 结束时隐藏）
    for i = #removeIndices, 1, -1 do
        table.remove(self._BallGridList, removeIndices[i])
    end
    self._BallListLen = lenBefore - count
    return positions, grids
end

--- 产球步：挤队头（球池满时）+ 不显新球（全播完 Refresh 才显）。#消球动效动画队列
--- STE ProduceBall 满则挤队头 FIFO；UI 同步挤头（隐藏队头 grid GO + 删列表），新球不显（无 grid）。
--- 消球步在产球步后取 _BallGridList（已挤头，对齐 STE BallList 队头）。
---@param color number BallColor（未用，预留产球动效接 trail）
---@param count number 产球数
function XUiPunishaarFightMainPanelBattleBall:ProduceBall(color, count)
    if not self._BallGridList or not count or count <= 0 then
        return
    end
    local capacity = self._Control.GameControl.FightControl.STEReader:GetBallSlotCapacity() or 0
    -- 挤头次数对齐 STE：STE ProduceBall 每颗满则挤头，总挤头数 = max(0, 产球前Len + count - capacity)。
    -- 用 _BallListLen（STE Len 镜像）算，避免 UI _BallGridList 不含产球新球致多步同帧挤头错算（#149审M1）
    local lenBefore = self._BallListLen or #self._BallGridList
    local squeezeCount = (capacity > 0) and math.max(0, lenBefore + count - capacity) or 0
    for _ = 1, squeezeCount do
        local grid = self._BallGridList[1]
        if grid then
            grid.GameObject:SetActiveEx(false)
        end
        table.remove(self._BallGridList, 1)
    end
    -- STE Len 镜像同步：挤 squeezeCount + 加 count 新球，Len = lenBefore - squeezeCount + count
    self._BallListLen = lenBefore - squeezeCount + count
    -- 加尾不显新球：_BallGridList 不加（无 grid GO），全播完 Refresh 重建对齐 STE 最终 BallList
end

return XUiPunishaarFightMainPanelBattleBall
