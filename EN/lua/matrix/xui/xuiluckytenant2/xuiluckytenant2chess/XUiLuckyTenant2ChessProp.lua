--[[
-- XUiLuckyTenant2ChessProp.lua
-- 道具数量展示（刷新/删除道具在背包中的数量）
--]]

---@class XUiLuckyTenant2ChessProp : XUiNode
---@field _Data table { Amount = number, Icon = string }
local XUiLuckyTenant2ChessProp = XClass(XUiNode, "XUiLuckyTenant2ChessProp")

function XUiLuckyTenant2ChessProp:OnAwake()
    self:InitComponents()
end

function XUiLuckyTenant2ChessProp:InitComponents()
end

function XUiLuckyTenant2ChessProp:OnStart(...)
end

function XUiLuckyTenant2ChessProp:OnEnable()
end

function XUiLuckyTenant2ChessProp:OnDisable()
end

function XUiLuckyTenant2ChessProp:OnDestroy()
end

function XUiLuckyTenant2ChessProp:Open()
    if self.GameObject then
        self.GameObject:SetActiveEx(true)
    end
end

function XUiLuckyTenant2ChessProp:Close()
    if self.GameObject then
        self.GameObject:SetActiveEx(false)
    end
end

---@param data table { Amount = number, Icon = string } 道具数量与图标
---@param index number 索引（由 UpdateDynamicItem 传入）
function XUiLuckyTenant2ChessProp:Update(data, index)
    self._Data = data
    if not data then
        return
    end

    local amount = data.Amount or 0
    local icon = data.Icon or ""

    if self.TxtNumScore then
        self.TxtNumScore.text = tostring(amount)
    end
    if self.RImgScoreIcon then
        if icon and icon ~= "" then
            self.RImgScoreIcon:SetRawImage(icon)
        else
            self.RImgScoreIcon:SetImage("")
        end
    end
end

return XUiLuckyTenant2ChessProp
