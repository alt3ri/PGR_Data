--[[
-- XUiLuckyTenant2PropDisplay.lua
-- 公共：动态显示刷新/删除道具数量（与 XUiLuckyTenant2Chess:UpdateProp 中列表部分一致）
--]]

local XUiLuckyTenant2ChessProp = require("XUi/XUiLuckyTenant2/XUiLuckyTenant2Chess/XUiLuckyTenant2ChessProp")
local XTool = XTool

local M = {}

---使用 Control 的刷新/删除道具数量与图标，更新动态道具列表（两栏：刷新道具、删除道具）
---@param control XLuckyTenant2Control
---@param gridArray table 用于存储克隆出的 XUiLuckyTenant2ChessProp 实例
---@param templateObj UnityEngine.GameObject 模板节点（如 Prop1、PropReward）
---@param parent XLuaUi 父 UI
function M.UpdatePropDisplay(control, gridArray, templateObj, parent)
    if not control or not gridArray or not templateObj or not parent then
        return
    end
    local propDataList = {
        { Amount = control:GetRefreshCoin(), Icon = control:GetRefreshPropIcon() },
        { Amount = control:GetDeleteCoin(), Icon = control:GetDeletePropIcon() },
    }
    XTool.UpdateDynamicItem(gridArray, propDataList, templateObj, XUiLuckyTenant2ChessProp, parent)
end

return M
