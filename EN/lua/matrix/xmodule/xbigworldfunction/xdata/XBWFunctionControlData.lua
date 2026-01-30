---@class XBWFunctionControlData
local XBWFunctionControlData = XClass(nil, "XBWFunctionControlData")

function XBWFunctionControlData:Ctor(functionType)
    self._FunctionType = false
    self._Args = false

    self:SetFunctionType(functionType)
end

function XBWFunctionControlData:SetFunctionType(functionType)
    self._FunctionType = functionType or XMVCA.XBigWorldFunction.FunctionType.None
end

function XBWFunctionControlData:GetFunctionType()
    return self._FunctionType
end

function XBWFunctionControlData:SetArgs(args)
    if args then
        self._Args = XTool.CsList2LuaTable(args)
    else
        self._Args = false
    end
end

function XBWFunctionControlData:GetArgs(isUnpack)
    if self._Args then
        if isUnpack then
            table.unpack(self._Args)
        else
            return self._Args
        end
    end

    return nil
end

function XBWFunctionControlData:GetArgByIndex(index)
    if self._Args then
        return self._Args[index]
    end

    return nil
end

function XBWFunctionControlData:IsEmpty()
    local functionType = self:GetFunctionType()

    return not functionType or functionType == XMVCA.XBigWorldFunction.FunctionType.None
end

function XBWFunctionControlData:Clear()
    self._FunctionType = false
    self._Args = false
end

return XBWFunctionControlData