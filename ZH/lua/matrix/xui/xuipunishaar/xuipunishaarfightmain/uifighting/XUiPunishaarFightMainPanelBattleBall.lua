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
    local ballList = self:_GetNewOrResetBallList()
    self._Control.GameControl.FightControl.STEReader:FillBallList(ballList)
    local ballSlotCapacity = self._Control.GameControl.FightControl.STEReader:GetBallSlotCapacity()

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

    XUiHelper.RefreshCustomizedList(self.PanelBallList.transform, self.GridBall, ballList and #ballList or 0, function(index, go)
        local grid = self._BallGridDict[go]
        if not grid then
            grid = XUiGridBattleBall.New(go, self)
            self._BallGridDict[go] = grid
        end
        grid:Open()
        grid:Refresh(ballList[index])
    end)
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

return XUiPunishaarFightMainPanelBattleBall
