--[[
-- XUiLuckyTenant2ChessBagGrid.lua
-- 背包单个棋子组件
--]]

local XUiLuckyTenant2GameGridChess = require("XUi/XUiLuckyTenant2/XUiLuckyTenant2Game/XUiLuckyTenant2GameGridChess")

---@class XUiLuckyTenant2ChessBagGrid : XUiNode
---@field _Control XLuckyTenant2Control
---@field _Data table
local XUiLuckyTenant2ChessBagGrid = XClass(XUiNode, "XUiLuckyTenant2ChessBagGrid")

function XUiLuckyTenant2ChessBagGrid:OnStart()
    self._Data = false
    -- 通过 GetComponent 获取 Button
    if self.GameObject then
        local button = self.GameObject:GetComponent("XUiButton")
        if button then
            XUiHelper.RegisterClickEvent(self, button, self._OnClick, nil, true)
        end
    end
end

---@param data table 棋子数据
function XUiLuckyTenant2ChessBagGrid:Update(data)
    self._Data = data
    if not data then
        if self.GameObject then
            self.GameObject:SetActiveEx(false)
        end
        return
    end
    
    if self.GameObject then
        self.GameObject:SetActiveEx(true)
    end
    
    if data.IsDirty then
        if self.TxtName then
            self.TxtName.text = data.Name or ""
        end
        if self.ImgQuality then
            if data.Quality then
                self.ImgQuality:SetSprite(data.Quality)
            elseif data.QualityValue and self._Control then
                local qualityIcon = self._Control:GetQualityIconCircle(data.QualityValue)
                if qualityIcon then
                    self.ImgQuality:SetSprite(qualityIcon)
                end
            end
        end
        if (self.RImgIcon or self.IconChess) and data.Icon then
            if self.RImgIcon then
                self.RImgIcon:SetRawImage(data.Icon)
            elseif self.IconChess then
                self.IconChess:SetImage(data.Icon)
            end
        end
        if self.TxtCost then
            self.TxtCost.text = tostring(data.Value or 0)
        end
        if self.PanelRound then
            if data.Round and data.Round > 0 then
                self.PanelRound.gameObject:SetActiveEx(true)
                if self.TxtRound then
                    self.TxtRound.text = tostring(data.Round)
                end
            else
                self.PanelRound.gameObject:SetActiveEx(false)
            end
        end
        self:UpdateTimePanels(data)
        XUiLuckyTenant2GameGridChess.UpdateLevelDisplay(self, data)
    end
    
    if self.Select then
        self.Select.gameObject:SetActiveEx(data.IsSelected or false)
    end
end

---更新倒计时效果（显示前两个有剩余回合数的状态）
---@param data table 棋子数据
function XUiLuckyTenant2ChessBagGrid:UpdateTimePanels(data)
    local states = data.States or {}
    local rounds = {}
    for _, state in ipairs(states) do
        local round = state.Round or state.RemainRound or state.StateRound
        if round ~= nil and round >= 0 then
            rounds[#rounds + 1] = round
        end
    end
    
    -- 如果 States 为空但 data.Round 存在，也使用它（兼容旧数据）
    if #rounds == 0 and data.Round ~= nil and data.Round >= 0 then
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

function XUiLuckyTenant2ChessBagGrid:_OnClick()
    if not self._Control or not self._Data then
        return
    end
    
    -- 选择棋子
    self._Control:SelectBagPiece(self._Data)
    
    -- 向上查找根 UI（XUiLuckyTenant2ChessBag）来刷新详情面板
    local bagUi = self:FindBagUI()
    if bagUi and bagUi.UpdateBag then
        bagUi:UpdateBag()
    end
end

---获取背包 UI（XUiLuckyTenant2ChessBag）
---@return XUiLuckyTenant2ChessBag|nil
function XUiLuckyTenant2ChessBagGrid:FindBagUI()
    -- BagGrid 只在背包界面使用，直接通过 Parent.Parent 获取（Grid -> Group -> Bag UI）
    if self.Parent and self.Parent.Parent then
        return self.Parent.Parent
    end
    return nil
end

return XUiLuckyTenant2ChessBagGrid


