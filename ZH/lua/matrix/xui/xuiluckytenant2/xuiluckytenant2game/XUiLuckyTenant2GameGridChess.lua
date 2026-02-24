---@class XUiLuckyTenant2GameGridChess : XUiNode
---@field _Root XLuaUi|XUiLuckyTenant2Game
---@field _Control XLuckyTenant2Control
---@field _Data table
---@field public Button XUiComponent.XUiButton
local XUiLuckyTenant2GameGridChess = XClass(XUiNode, "XUiLuckyTenant2GameGridChess")

function XUiLuckyTenant2GameGridChess:OnStart()
    self:InitComponents()

    ---@type XUiComponent.XUiButton
    local button = self.Button
    if button then
        button.CallBack = function()
            self:OnClick()
        end
    end

    -- Effect用于游戏界面的特效显示
    if not self.Effect then
        self.Effect = XUiHelper.TryGetComponent(self.Transform, "Effect", "Transform")
    end
    if self.Effect then
        self.Effect.gameObject:SetActiveEx(false)
    end
end

function XUiLuckyTenant2GameGridChess:InitComponents()
end

function XUiLuckyTenant2GameGridChess:UpdateRound(round)
    if round then
        if self.TxtTime01 then
            self.TxtTime01.text = tostring(round)
        end
        if self.TxtTime02 then
            self.TxtTime02.text = tostring(round)
        end
        if self.PanleRound then
            self.PanleRound.gameObject:SetActiveEx(true)
        end
    else
        if self.PanleRound then
            self.PanleRound.gameObject:SetActiveEx(false)
        end
    end
end

---更新倒计时效果（显示前两个有剩余回合数的状态）
---@param data table 棋子数据
function XUiLuckyTenant2GameGridChess:UpdateTimePanels(data)
    local XLuckyTenant2Enum = require("XModule/XLuckyTenant2/Game/XLuckyTenant2Enum")
    local TriggerState = XLuckyTenant2Enum.TriggerState

    local states = data.States or {}
    local rounds = {}
    for _, state in ipairs(states) do
        local round = state.Round or state.RemainRound or state.StateRound
        if round ~= nil and round >= 0 then
            rounds[#rounds + 1] = round
        end
    end

    -- 如果 States 为空但 data.Round 存在，也使用它（兼容旧数据）
    -- 注意：data.Round 可能是 false（第一回合隐藏倒计时）
    if #rounds == 0 and type(data.Round) == "number" and data.Round >= 0 then
        rounds[#rounds + 1] = data.Round
    end

    -- 显示第一个倒计时
    if self.PanelTime01 then
        if rounds[1] then
            self.PanelTime01.gameObject:SetActiveEx(true)
            if self.TxtTime01 then
                self.TxtTime01.text = tostring(rounds[1])
            end
        else
            self.PanelTime01.gameObject:SetActiveEx(false)
        end
    end

    -- 显示第二个倒计时
    if self.PanelTime02 then
        if rounds[2] then
            self.PanelTime02.gameObject:SetActiveEx(true)
            if self.TxtTime02 then
                self.TxtTime02.text = tostring(rounds[2])
            end
        else
            self.PanelTime02.gameObject:SetActiveEx(false)
        end
    end
end

---统一更新等级显示：仅当可升级时显示等级面板与文本，游戏界面与选棋/背包界面共用
---@param data table 棋子数据（需含 IsCanUpgrade、Level）
function XUiLuckyTenant2GameGridChess:UpdateLevelDisplay(data)
    if not data then
        return
    end
    local isCanUpgrade = data.IsCanUpgrade or false
    if self.PanelLv then
        self.PanelLv.gameObject:SetActiveEx(isCanUpgrade)
    end
    if self.TxtLv then
        if isCanUpgrade then
            self.TxtLv.text = "Lv." .. tostring(data.Level or 1)
        else
            self.TxtLv.text = ""
        end
    end
end

---@param data table 棋子数据
function XUiLuckyTenant2GameGridChess:Update(data)
    -- 游戏界面：处理JustChangeRound快速更新
    if data and data.JustChangeRound ~= nil then
        self:UpdateRound(data.JustChangeRound)
        return
    end

    self._Data = data
    if not data then
        return
    end

    -- 游戏界面：处理IsValid和空位置
    if data.IsValid ~= nil then
        if data.IsValid then
            -- 设置图标
            if self.RImgIcon then
                if self.RImgIcon.SetImage then
                    self.RImgIcon:SetImage(data.Icon)
                end
            end

            -- 显示PanelChess
            if self.PanelChess then
                self.PanelChess.gameObject:SetActiveEx(true)
            end

            -- 设置品质
            if self.ImgQuality then
                local qualityIcon = self._Control:GetQualityIconCircle(data.Quality)
                self.ImgQuality:SetSprite(qualityIcon)
            end

            -- 设置分数/价值
            if self.TxtCost then
                self.TxtCost.text = tostring(data.Score or data.Value or 0)
            end

            -- 设置名称（只有棋盘上的棋子才显示名字）
            -- IsValid 为 true 表示棋子在棋盘上
            if self.TxtName then
                if data.IsValid == true then
                    self.TxtName.text = data.Name or ""
                else
                    self.TxtName.text = ""
                end
            end

            -- 设置等级（游戏界面与选棋/背包共用逻辑）
            self:UpdateLevelDisplay(data)

            -- 设置位置名称
            if data.X and data.Y then
                self.Transform.name = "Chess_" .. data.X .. "_" .. data.Y
            end


            -- 更新倒计时效果（显示前两个有剩余回合数的状态）
            self:UpdateTimePanels(data)
        else
            -- 隐藏PanelChess
            if self.PanelChess then
                self.PanelChess.gameObject:SetActiveEx(false)
            end
        end
        return
    end

    -- 选棋界面/背包界面：更新基本信息
    -- 更新品质图标
    if self.ImgQuality then
        if data.QualityValue then
            local control = self._Control
            if not control and self.Parent then
                control = self.Parent._Control
            end
            if not control and self._Root and self._Root._Control then
                control = self._Root._Control
            end
            if control and control.GetQualityIconCircle then
                local qualityIcon = control:GetQualityIconCircle(data.QualityValue)
                if qualityIcon and self.ImgQuality.SetSprite then
                    self.ImgQuality:SetSprite(qualityIcon)
                end
            end
        elseif data.Quality and type(data.Quality) == "string" then
            if self.ImgQuality.SetSprite then
                self.ImgQuality:SetSprite(data.Quality)
            elseif self.ImgQuality.SetImage then
                self.ImgQuality:SetImage(data.Quality)
            end
        end
    end

    -- 更新棋子图标
    if self.RImgIcon then
        if self.RImgIcon.SetImage then
            self.RImgIcon:SetImage(data.Icon or "")
        end
    end

    -- 显示PanelChess（选棋界面/背包界面有数据时显示）
    if self.PanelChess then
        self.PanelChess.gameObject:SetActiveEx(true)
    end

    -- 更新价值
    if self.TxtCost then
        self.TxtCost.text = tostring(data.Value or 0)
    end

    -- 更新倒计时效果（显示前两个有剩余回合数的状态）
    self:UpdateTimePanels(data)

    -- 更新等级（与游戏界面共用：仅可升级时显示）
    self:UpdateLevelDisplay(data)

    -- 隐藏名称（背包/选棋界面的棋子不显示名字）
    if self.TxtName then
        self.TxtName.text = ""
    end
end

function XUiLuckyTenant2GameGridChess:OnClick()
    if not self._Data then
        return
    end

    -- 游戏界面：处理棋盘上的棋子点击
    if self._Data.IsValid ~= nil then
        if self._Data.IsValid then
            -- 更新棋子详情数据
            self._Control:UpdatePieceDataOnChessboard(self._Data)
            self.Parent:OnClickPieceOnChessboard(self._Data)
        end
        return
    end

    -- 选棋界面/背包界面：处理选择逻辑
    -- 检查是否在背包界面
    local bagUi = self:FindBagUI()
    if bagUi then
        -- 在背包界面中，选择该棋子并刷新详情
        local control = self._Control
        if not control and self.Parent then
            control = self.Parent._Control
        end
        if not control and bagUi._Control then
            control = bagUi._Control
        end

        if control and self._Data.Uid then
            -- 通过 Uid 查找背包中的棋子数据
            local uiData = control:GetUiData()
            local bagData = uiData.Bag
            local selectedPiece = nil

            -- 在所有分组中查找匹配的棋子
            for _, groupData in ipairs(bagData) do
                if groupData.Pieces then
                    for _, pieceData in ipairs(groupData.Pieces) do
                        if pieceData.Uid == self._Data.Uid then
                            selectedPiece = pieceData
                            break
                        end
                    end
                    if selectedPiece then
                        break
                    end
                end
            end

            -- 如果找到了棋子，选择它并刷新详情
            if selectedPiece then
                control:SelectBagPiece(selectedPiece)
                bagUi:UpdateBag()
            end
        end
    end
end

---获取背包 UI（XUiLuckyTenant2ChessBag）
---@return XUiLuckyTenant2ChessBag|nil
function XUiLuckyTenant2GameGridChess:FindBagUI()
    -- 通过 Parent（Detail）的方法获取 Bag UI
    if self.Parent and self.Parent.GetBagUI then
        return self.Parent:GetBagUI()
    end
    return nil
end

function XUiLuckyTenant2GameGridChess:ShowEffect()
    if self._Data and (self._Data.IsValid == nil or self._Data.IsValid) then
        if self.Effect then
            self.Effect.gameObject:SetActiveEx(true)
            XScheduleManager.ScheduleOnce(function()
                if self.Effect then
                    self.Effect.gameObject:SetActiveEx(false)
                end
            end, 800)
        end
        if self.PlayAnimation then
            self:PlayAnimation("Refresh")
        end
    end
end

function XUiLuckyTenant2GameGridChess:OnEnable()
end

function XUiLuckyTenant2GameGridChess:OnDisable()
end

function XUiLuckyTenant2GameGridChess:OnDestroy()
end

return XUiLuckyTenant2GameGridChess
