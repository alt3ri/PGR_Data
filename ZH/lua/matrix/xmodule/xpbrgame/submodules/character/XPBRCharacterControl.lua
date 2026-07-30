---@class XPBRCharacterControl : XControl
---@field private _Model XPBRGameModel
---@field _MainControl XPBRGameControl
local XPBRCharacterControl = XClass(XControl, "XPBRCharacterControl")

function XPBRCharacterControl:OnInit()

end

function XPBRCharacterControl:AddAgencyEvent()

end

function XPBRCharacterControl:RemoveAgencyEvent()

end

function XPBRCharacterControl:OnRelease()

end

function XPBRCharacterControl:GetCharacterCfg(customCharId)
    return self._Model:GetTablePBRCharacterCfgById(customCharId)
end

function XPBRCharacterControl:GetCharacterCfgs(ignoreSort)
    local cfgs = self._Model:GetTablePBRCharacterCfgs()

    if cfgs then
        local cfgList = {}

        for i, v in pairs(cfgs) do
            if not v.IsHide then
                table.insert(cfgList, v)
            end
        end

        if not ignoreSort then
            ---@param a XTablePBRCharacter
            ---@param b XTablePBRCharacter
            table.sort(cfgList, function(a, b)
                if a.ShowPriority ~= b.ShowPriority then
                    return a.ShowPriority > b.ShowPriority
                end
                
                return a.CharacterId > b.CharacterId
            end)
        end
        
        return cfgList
    end
end

---@return boolean, string @是否解锁，解锁条件描述
function XPBRCharacterControl:GetIsCharacterUnlock(customCharId)
    local charCfg = self._Model:GetTablePBRCharacterCfgById(customCharId)

    if charCfg then
        if XTool.IsNumberValidEx(charCfg.CharacterUnlockStage) then
            local isPassed = XMVCA.XPBRGame:CheckPassedByStageId(charCfg.CharacterUnlockStage)

            if isPassed then
                return true
            else
                local stageCfg = self._Model:GetTablePBRStageCfgById(charCfg.CharacterUnlockStage)
                
                local unlockStr = XUiHelper.FormatTextEx(self._Model:GetClientPBRText('CharacterUnlockDesc'), stageCfg and stageCfg.StageName or '')
                
                return false, unlockStr
            end
        else
            return true
        end
    end
    
    return false
end

--- 获取顺位第一个已解锁的角色Id
function XPBRCharacterControl:GetFirstOneUnlockCharId(includeHide)
    local cfgs = self._Model:GetTablePBRCharacterCfgs()

    if cfgs then
        for i, v in pairs(cfgs) do
            if not v.IsHide or includeHide then
                if self:GetIsCharacterUnlock(v.CharacterId) then
                    return v.CharacterId
                end
            end
        end
    end
end

---@return XPBRCharacterStatusParams[]
function XPBRCharacterControl:GetCharacterStatusInfo(customCharId, needSort, noValDesc)
    local infoList = nil
    
    local charStatusCfg = self._Model:GetTablePBRCharacterStatsCfgById(customCharId)

    if charStatusCfg and not XTool.IsTableEmpty(charStatusCfg.Status) then
        infoList = {}
        
        local strengthenDict = self._MainControl.GeniusControl:GetAllUnlockNodeStatsAddition()
        local charCfg = self._Model:GetTablePBRCharacterCfgById(customCharId)
        
        local recommendStatus = charCfg and charCfg.RecommendStatus or nil
        
        for i, v in pairs(charStatusCfg.Status) do
            local statusCfg = self._Model:GetTablePBRStatsDescCfgById(i)

            if statusCfg and not statusCfg.IsHide then
                ---@type XPBRCharacterStatusParams
                local data = {
                    StatusId = i,
                    Name = statusCfg.StatsName,
                    Icon = statusCfg.Icon,
                    BaseValue = v,
                    StrengthValue = strengthenDict and strengthenDict[i] or 0,
                    IsRecommend = recommendStatus and table.contains(recommendStatus, i) or false,
                    --todo
                }

                if not noValDesc then
                    data.ValueDesc = self:GetFinalValueDescByStatusInfo(data)
                end
                
                table.insert(infoList, data)
            end
        end

        if needSort then
            table.sort(infoList, function(a, b) 
                local statusCfgA = self._Model:GetTablePBRStatsDescCfgById(a.StatusId)
                local statusCfgB = self._Model:GetTablePBRStatsDescCfgById(b.StatusId)

                if not statusCfgA or not statusCfgB then
                    -- 其中一方没有有效配置时保底处理
                    return true
                end
                
                -- 有推荐的属性在最前面
                if a.IsRecommend ~= b.IsRecommend then
                    return a.IsRecommend
                end

                if not XTool.IsNumberValidEx(statusCfgA.ShowPriority) and not XTool.IsNumberValidEx(statusCfgB.ShowPriority) then
                    -- 如果两者都没有配优先级的话，按照Id升序排序
                    return statusCfgA.StatsId < statusCfgB.StatsId
                end

                return statusCfgA.ShowPriority > statusCfgB.ShowPriority
            end)
        end
    end
    
    
    return infoList
end 

--- 获取角色描述信息，面板显示用、固定显示次序：攻击方式、天赋、连锁效果
---@return XPBRCharacterExclusiveDescParams[]
function XPBRCharacterControl:GetCharacterExclusiveDescInfo(customCharId)
    local infoList = nil
    
    local characterCfg = self._Model:GetTablePBRCharacterCfgById(customCharId)

    if characterCfg then
        infoList = {}
        -- 攻击方式的描述
        table.insert(infoList, {
            Desc = XUiHelper.ReplaceTextNewLine(characterCfg.BasicAttackDesc),
        })
        
        -- 天赋描述
        table.insert(infoList, {
            Desc = XUiHelper.ReplaceTextNewLine(characterCfg.CorePassiveDesc)
        })
        
        -- combo效果描述
        table.insert(infoList, {
            Desc = XUiHelper.ReplaceTextNewLine(characterCfg.ComboBoostDesc)
        })
    end
    
    
    return infoList
end

---@param info XPBRCharacterStatusParams 
function XPBRCharacterControl:GetFinalValueDescByStatusInfo(info)
    local statusCfg = self._Model:GetTablePBRStatsDescCfgById(info.StatusId)

    if statusCfg then
        -- 计算之和
        local finalValue = info.BaseValue + (info.StrengthValue or 0) + (info.TempAddition or 0)

        -- 和基础值判断获取修饰文本
        local fixDesc = ''
        
        if finalValue > info.BaseValue then
            fixDesc = self._Model:GetClientPBRText('RoleAttribShowLabel', 2)
        elseif finalValue < info.BaseValue then
            fixDesc = self._Model:GetClientPBRText('RoleAttribShowLabel', 3)
        else
            fixDesc = self._Model:GetClientPBRText('RoleAttribShowLabel', 1)
        end
        
        local finalValueStr = ''
        
        if statusCfg.ValueBase == XMVCA.XPBRGame.EnumConst.StatusValueType.Permyriad then
            finalValue = finalValue / XMVCA.XPBRGame.EnumConst.Permyriad2PercentValueBase

            finalValueStr = string.format("%.2f", finalValue)

            finalValueStr =  XUiHelper.FormatTextEx(self._Model:GetClientPBRText('PercentShowFormat'), finalValueStr)
        else
            finalValueStr =  string.format("%.2f", finalValue)
        end

        return XUiHelper.FormatTextEx(fixDesc, finalValueStr)
    end
    
    return ''
end

--- 根据属性类型及其值获取最终描述
---@param statusId number
---@param value number
function XPBRCharacterControl:GetValueDescByStatusIdAndValue(statusId, value)
    local statusCfg = self._Model:GetTablePBRStatsDescCfgById(statusId)

    if statusCfg then
        local finalValueStr = ''
        
        if statusCfg.ValueBase == XMVCA.XPBRGame.EnumConst.StatusValueType.Permyriad then
            value = value / XMVCA.XPBRGame.EnumConst.Permyriad2PercentValueBase

            finalValueStr = string.format("%.2f", value)

            finalValueStr =  XUiHelper.FormatTextEx(self._Model:GetClientPBRText('PercentShowFormat'), finalValueStr)
        else
            finalValueStr =  string.format("%.2f", value)
        end

        return finalValueStr
    end
    
    return ''
end

function XPBRCharacterControl:GetStatusFightValueSrcById(statusId)
    local statusCfg = self._Model:GetTablePBRStatsDescCfgById(statusId)

    if statusCfg then
        return statusCfg.FightValueSrc or 0
    end
    
    return 0
end


--region Animation

function XPBRCharacterControl:GetCharacterIdleActionById(customCharId)
    local charCfg = self._Model:GetTablePBRCharacterCfgById(customCharId)

    if charCfg then
        return charCfg.IdleAction
    end
end

function XPBRCharacterControl:GetCharacterWinActionById(customCharId)
    local charCfg = self._Model:GetTablePBRCharacterCfgById(customCharId)

    if charCfg then
        return charCfg.WinAction
    end
end

function XPBRCharacterControl:GetCharacterFailActionById(customCharId)
    if not XTool.IsNumberValidEx(customCharId) then
        return
    end
    
    local charCfg = self._Model:GetTablePBRCharacterCfgById(customCharId)

    if charCfg then
        return charCfg.FailAction
    end
end
--endregion

return XPBRCharacterControl

--- 角色的属性参数定义
---@class XPBRCharacterStatusParams
---@field StatusId number
---@field Name string
---@field Icon string
---@field ValueDesc string @最终值描述
---@field IsStrength boolean @是否被任意强化过（局内或局外）
---@field BaseValue number @基础配置值
---@field StrengthValue number @局外强化加成值
---@field TempAddition number @局内临时加成值
---@field IsRecommend boolean @是否是推荐强化的属性

--- 角色通用描述信息
---@class XPBRCharacterExclusiveDescParams
---@field Desc string