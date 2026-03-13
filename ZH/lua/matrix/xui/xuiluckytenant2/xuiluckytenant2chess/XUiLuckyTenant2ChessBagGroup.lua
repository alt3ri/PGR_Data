--[[
-- XUiLuckyTenant2ChessBagGroup.lua
-- 背包分组组件（按棋子类型分组）
--]]

local XUiLuckyTenant2ChessBagGrid = require("XUi/XUiLuckyTenant2/XUiLuckyTenant2Chess/XUiLuckyTenant2ChessBagGrid")

---@class XUiLuckyTenant2ChessBagGroup : XUiNode
---@field _Control XLuckyTenant2Control
---@field _Grids XUiLuckyTenant2ChessBagGrid[]
local XUiLuckyTenant2ChessBagGroup = XClass(XUiNode, "XUiLuckyTenant2ChessBagGroup")

function XUiLuckyTenant2ChessBagGroup:OnStart()
    self._Grids = {}
end

---@param data table 分组数据 {Type, TypeDesc, IconBond, Pieces}
function XUiLuckyTenant2ChessBagGroup:Update(data)
    if not data then
        return
    end
    
    -- 标题显示羁绊名
    if self.TxtTitle then
        self.TxtTitle.text = data.TypeDesc or ""
    end
    
    -- 羁绊图标（新增 IconBond 节点时设置）
    if self.IconBond then
        local icon = data.IconBond
        if string.IsNilOrEmpty(icon) then
            self.IconBond.gameObject:SetActiveEx(false)
        else
            self.IconBond.gameObject:SetActiveEx(true)
            if self.IconBond.SetRawImage then
                self.IconBond:SetRawImage(icon)
            elseif self.IconBond.SetImage then
                self.IconBond:SetImage(icon)
            end
        end
    end
    
    if self.GridChess then
        XTool.UpdateDynamicItem(self._Grids, data.Pieces or {}, self.GridChess, XUiLuckyTenant2ChessBagGrid, self)
    end
end

return XUiLuckyTenant2ChessBagGroup

