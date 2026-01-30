---@class XArenaDataBase
local XArenaDataBase = XClass(nil, "XArenaDataBase")

function XArenaDataBase:Ctor(...)
    self._IsClear = true
    self:SetData(...)
end

function XArenaDataBase:SetData(...)
    local args = { ... }

    if not XTool.IsTableEmpty(args) then
        self._IsClear = false
        self:_InitData(...)
    end
end

function XArenaDataBase:IsClear()
    return self._IsClear
end

function XArenaDataBase:Clear()
    self._IsClear = true
    self:_ClearData()
end

function XArenaDataBase:_ClearData()
    
end

function XArenaDataBase:_InitData(...)

end

return XArenaDataBase