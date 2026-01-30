--- 用于集成Dlc中共用的功能
---@class XDlcHelperAgency : XAgency
---@field private _Model XDlcHelperModel
local XDlcHelperAgency = XClass(XAgency, "XDlcHelperAgency")

function XDlcHelperAgency:OnInit()
    --- 根据dlc系统类型获取模型Id的信号渠 
    ---@type table<number, XAgency>
    self._DlcModelIdGetter = {}
end

function XDlcHelperAgency:InitRpc()

end

function XDlcHelperAgency:InitEvent()

end

function XDlcHelperAgency:OnRelease()
    self._DlcModelIdGetter = nil
end

--region ModelIdGetter

function XDlcHelperAgency:AddDlcModelIdGetterWithWorldType(worldType, agency)
    if CheckClassSuper(agency, XAgency) then
        self._DlcModelIdGetter[worldType] = agency
    else
        XLog.Error('注册的参数不是一个Agency:', agency)
    end
end

function XDlcHelperAgency:RemoveDlcModelIdGetterWithWorldType(worldType, agency)
    if self._DlcModelIdGetter and self._DlcModelIdGetter[worldType] == agency then
        self._DlcModelIdGetter[worldType] = nil
    end
end

function XDlcHelperAgency:GetDlcModelIdWithWorldType(worldType, characterData)
    local agency = self._DlcModelIdGetter[worldType]

    if agency then
        if agency.ExGetDlcModelIdByCharacterData then
            return agency:ExGetDlcModelIdByCharacterData(characterData)
        else
            XLog.Error('Agency: '..tostring(agency:GetId())..' 未实现方法：ExGetDlcModelIdByCharacterData')
        end
    else
        XLog.Error('WorldType: '..tostring(worldType)..' 未注册提供获取ModelId接口的Agency')
    end
end

function XDlcHelperAgency:GetDlcFightCharHeadIcon(worldType, worldNpcData)
    local agency = self._DlcModelIdGetter[worldType]

    if agency then
        if agency.GetFightCharHeadIcon then
            return agency:GetFightCharHeadIcon(worldNpcData)
        else
            XLog.Error('Agency: '..tostring(agency:GetId())..' 未实现方法：GetFightCharHeadIcon')
        end
    else
        XLog.Error('WorldType: '..tostring(worldType)..' 未注册提供获取HeadIcon接口的Agency')
    end
end

function XDlcHelperAgency:CheckLevelPlayFullCleared(worldType, levelPlayId)
    local agency = self._DlcModelIdGetter[worldType]

    if agency then
        if agency.CheckLevelPlayFullCleared then
            return agency:CheckLevelPlayFullCleared(levelPlayId)
        else
            XLog.Error('Agency: '..tostring(agency:GetId())..' 未实现方法：CheckLevelPlayFullCleared')
        end
    else
        XLog.Error('WorldType: '..tostring(worldType)..' 未注册提供检查副本玩法是否全通接口的Agency')
    end
end

function XDlcHelperAgency:CheckLevelPlayCleared(worldType, levelPlayId)
    local agency = self._DlcModelIdGetter[worldType]

    if agency then
        if agency.CheckLevelPlayCleared then
            return agency:CheckLevelPlayCleared(levelPlayId)
        else
            XLog.Error('Agency: '..tostring(agency:GetId())..' 未实现方法：CheckLevelPlayCleared')
        end
    else
        XLog.Error('WorldType: '..tostring(worldType)..' 未注册提供检查副本玩法是否全通接口的Agency')
    end
end

function XDlcHelperAgency:GetAnimExpressionSOGroupId(worldType, fashionId)
    local agency = self._DlcModelIdGetter[worldType]
    if agency then
        if agency.GetAnimExpressionSOGroupId then
            return agency:GetAnimExpressionSOGroupId(fashionId)
        else
            XLog.Error('Agency: '..tostring(agency:GetId())..' 未实现方法：GetAnimExpressionSOGroupId')
        end
    else
        XLog.Error('WorldType: '..tostring(worldType)..' 未注册提供检查副本玩法是否全通接口的Agency')
    end
end

--endregion


return XDlcHelperAgency