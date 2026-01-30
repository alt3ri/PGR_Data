--- 每隔一段时间将场上的若干物资链接起来
---@class XGoldenMinerComponentPartnerStoneLink:XEntity
-----@field _OwnControl XGoldenMinerGameControl
-----@field _ParentEntity XGoldenMinerEntityPartner
-----@field TriggerEffect UnityEngine.Transform
local XGoldenMinerComponentPartnerStoneLink = XClass(XEntity, 'XGoldenMinerComponentPartnerStoneLink')

--region Override
function XGoldenMinerComponentPartnerStoneLink:OnInit()
    self._Status = XEnumConst.GOLDEN_MINER.GAME_PARTNER_RADAR_STATUS.NONE
    ---@type UnityEngine.Transform
    self.Transform = nil
    -- Static Value
    self._Type = 0
    ---@type UnityEngine.Vector3
    self._SelfStartPosition = nil
    ---@type string
    self._TriggerEffectUrl = nil
    self._IdleCD = 0
    self._ScanCD = 0
    self._SelectNearestCount = 0
    self._SelectFarestCount = 0
    self._IgnoreStoneTypeDir = {}
    
    self._IsRunning = false -- 是否开始执行（至少执行了一次Update）
    
    -- Dynamic Value
    self._MaxIdleCD = 0
    self._MaxScanCD = 0
    self._CurIdleCD = 0
    self._CurScanCD = 0
    self._CurSelectNearestCount = 0
    self._CurSelectFarestCount = 0
end

function XGoldenMinerComponentPartnerStoneLink:OnRelease()
    self.Transform = nil
    --self.Aim = nil
    self.TriggerEffect = nil
    -- Static Value
    self._Type = nil
    self._SelfStartPosition = nil
    self._TriggerEffectUrl = nil
    self._IdleCD = 0
    self._ScanCD = 0

    -- Dynamic Value
    self._CurIdleCD = 0
    self._CurScanCD = 0
    self._MaxIdleCD = 0
    self._MaxScanCD = 0

    self._IgnoreStoneTypeDir = nil
end
--endregion

--region Getter
function XGoldenMinerComponentPartnerStoneLink:GetSelfStartPosition()
    return self._SelfStartPosition
end

function XGoldenMinerComponentPartnerStoneLink:GetSelectNearestCount()
    return self._SelectNearestCount
end

function XGoldenMinerComponentPartnerStoneLink:GetSelectFarestCount()
    return self._SelectFarestCount
end

function XGoldenMinerComponentPartnerStoneLink:GetCurSelectNearestCount()
    return self._CurSelectNearestCount or 0
end

function XGoldenMinerComponentPartnerStoneLink:GetCurSelectFarestCount()
    return self._CurSelectFarestCount or 0
end

function XGoldenMinerComponentPartnerStoneLink:GetCurMaxIdleCd()
    return self._MaxIdleCD
end

function XGoldenMinerComponentPartnerStoneLink:GetCurMaxScanCd()
    return self._MaxScanCD
end
--endregion

--region Setter
---@param cfg XTableGoldenMinerPartner
function XGoldenMinerComponentPartnerStoneLink:InitByCfg(cfg, ignoreStoneTypeList)
    for _, v in ipairs(ignoreStoneTypeList) do
        self._IgnoreStoneTypeDir[tonumber(v)] = true
    end
    
    self._Type = cfg.Type
    self._TriggerEffectUrl = cfg.TriggerEffect
    self._IdleCD = cfg.FloatParam[1]
    self._ScanCD = cfg.FloatParam[2]
    self._SelectNearestCount = cfg.IntParam[1]
    self._SelectFarestCount = cfg.IntParam[2]

    self._MaxIdleCD = self._IdleCD
    self._MaxScanCD = self._ScanCD
    self:UpdateIdleCd(self._MaxIdleCD)
    self:UpdateScanCd(self._MaxScanCD)
    self:UpdateSelectFarestCount(self._SelectFarestCount)
    self:UpdateSelectNearestCount(self._SelectNearestCount)
end

---@param obj UnityEngine.GameObject
function XGoldenMinerComponentPartnerStoneLink:InitObj(obj)
    self.Transform = obj.transform
    self.StaticPosition = self.Transform.position
    XTool.InitUiObject(self)
end

---@param status number XEnumConst.GOLDEN_MINER.GAME_PARTNER_RADAR_STATUS
function XGoldenMinerComponentPartnerStoneLink:_SetStatus(status)
    self._Status = status
end

function XGoldenMinerComponentPartnerStoneLink:ResetCDMax()
    self._MaxIdleCD = self._IdleCD
    self._MaxScanCD = self._ScanCD
end

function XGoldenMinerComponentPartnerStoneLink:ResetLinkCount()
    self._CurSelectNearestCount = self._SelectNearestCount
    self._CurSelectFarestCount = self._SelectFarestCount
end
--endregion

--region Check
function XGoldenMinerComponentPartnerStoneLink:CheckStatus(status)
    return self._Status == status
end
--endregion

--region Control - Status
function XGoldenMinerComponentPartnerStoneLink:ChangeIdle()
    self:UpdateIdleCd(self._MaxIdleCD)
    --self.IdleAnimation.gameObject:SetActiveEx(true)
    --self.ScanAnimation.gameObject:SetActiveEx(false)
    self:_SetStatus(XEnumConst.GOLDEN_MINER.GAME_PARTNER_RADAR_STATUS.IDLE)
end

function XGoldenMinerComponentPartnerStoneLink:_ChangeLink()
    self:UpdateScanCd(self._MaxScanCD)
    --self.IdleAnimation.gameObject:SetActiveEx(false)
    --self.ScanAnimation.gameObject:SetActiveEx(true)
    self:_SetStatus(XEnumConst.GOLDEN_MINER.GAME_PARTNER_RADAR_STATUS.SCAN)
end
--endregion

--region Control

function XGoldenMinerComponentPartnerStoneLink:Update(deltaTime)
    self._IsRunning = true
    
    if self:CheckStatus(XEnumConst.GOLDEN_MINER.GAME_PARTNER_STONE_LINK_STATUS.IDLE) then
        local curCD = self._CurIdleCD - deltaTime
        if curCD <= 0 then
            self:_ChangeLink()
        else
            self._CurIdleCD = curCD
        end
    elseif self:CheckStatus(XEnumConst.GOLDEN_MINER.GAME_PARTNER_STONE_LINK_STATUS.LINK) then
        local curCD = self._CurScanCD - deltaTime
        if curCD <= 0 then
            self:TryLinkStones()
            self:ChangeIdle()
        else
            self._CurScanCD = curCD
        end
    end
end

function XGoldenMinerComponentPartnerStoneLink:UpdateIdleCd(time)
    self._CurIdleCD = time
end

function XGoldenMinerComponentPartnerStoneLink:UpdateScanCd(time)
    self._CurScanCD = time
end

function XGoldenMinerComponentPartnerStoneLink:UpdateMaxIdleCd(time)
    self._MaxIdleCD = time

    -- 如果还没执行过，直接覆盖cd，否则不影响当前的cd
    if not self._IsRunning then
        self:UpdateIdleCd(self._MaxIdleCD)
    end
end

function XGoldenMinerComponentPartnerStoneLink:UpdateMaxScanCd(time)
    self._MaxScanCD = time

    if not self._IsRunning then
        self:UpdateScanCd(self._MaxScanCD)
    end
end

function XGoldenMinerComponentPartnerStoneLink:UpdateSelectNearestCount(count)
    self._CurSelectNearestCount = count
end

function XGoldenMinerComponentPartnerStoneLink:UpdateSelectFarestCount(count)
    self._CurSelectFarestCount = count
end

function XGoldenMinerComponentPartnerStoneLink:GetIgnoreTypeDir()
    local realIgnoreType = {}
    
    -- 先加入默认忽略的
    if not XTool.IsTableEmpty(self._IgnoreStoneTypeDir) then
        for i, v in pairs(self._IgnoreStoneTypeDir) do
            realIgnoreType[i] = v
        end
    end
    
    -- 读取强制抓取buff，剔除允许强制抓取的类型
    local buffUidList = self._OwnControl.SystemBuff:GetBuffUidListByType(XEnumConst.GOLDEN_MINER.BUFF_TYPE.HOOK_EX_FORCE)
    if not XTool.IsTableEmpty(buffUidList) then
        for buffUid, _ in pairs(buffUidList) do
            local buff = self._OwnControl:GetEntityWithUid(buffUid)
            local buffParams = buff:GetBuffParams()
            if not XTool.IsTableEmpty(buffParams) then
                for _, param in pairs(buffParams) do
                    realIgnoreType[param] = false
                end
            end
        end
    end
    
    return realIgnoreType
end

function XGoldenMinerComponentPartnerStoneLink:GetSunMoonVirtualStoneIdDir()
    -- 如果有允许抓取虚资源的buff，则不屏蔽虚资源
    if self._OwnControl.SystemBuff:CheckHasAliveBuffByType(XEnumConst.GOLDEN_MINER.BUFF_TYPE.HOOK_EX_GRAB_VIRTUAL) then
        return nil
    else
        return self._OwnControl.SystemMap:GetSunMoonVirtualStoneIdDir()
    end
end

function XGoldenMinerComponentPartnerStoneLink:TryLinkStones()
    local ignoreTypeDir = self:GetIgnoreTypeDir()
    local ignoreUidDir = self:GetSunMoonVirtualStoneIdDir()
    local startPosition = self.StaticPosition
    
    -- 查找场上所有可拖拽的资源
    local stoneEntities = self._OwnControl.SystemMap:GetStoneListSortByDistance(ignoreTypeDir, ignoreUidDir, startPosition, false, true)
    
    if not XTool.IsTableEmpty(stoneEntities) then
        -- 剔除已经连接的资源
        for i = #stoneEntities, 1, -1 do
            local entity = stoneEntities[i]

            if entity:GetComponentLink() then
                table.remove(stoneEntities, i)
            end
        end
        
        -- 如果没有可链接的资源则返回
        if XTool.IsTableEmpty(stoneEntities) then
            return
        end

        local selectEntities = nil
        local canSelectCount = XTool.GetTableCount(stoneEntities)
        
        -- 如果只有一个未链接的也不能连
        if canSelectCount <= 1 then
            return
        end
        
        -- 如果可链接的资源数大于需要链接的数量，则进行选择
        if canSelectCount > (self._CurSelectNearestCount + self._CurSelectFarestCount) then
            selectEntities = {}
            -- 选择最近的x个和最远的y个
            for i = 1, self._CurSelectNearestCount do
                table.insert(selectEntities, stoneEntities[i])
            end

            for i = canSelectCount, canSelectCount - self._CurSelectFarestCount + 1, -1 do
                table.insert(selectEntities, stoneEntities[i])
            end
        else
            selectEntities = stoneEntities
        end
        
        -- 按照x轴从左向右顺序生成连接列表，并为每个连接的资源添加连接组件
        local linkStoneUidList = {}
        local linkStoneUid2X = {}
        local linkStoneUid2Y = {}
        
        for i, v in pairs(selectEntities) do
            local x, y = v:GetTransform():GetPosition()
            local uid = v:GetUid()
            linkStoneUid2X[uid] = x
            linkStoneUid2Y[uid] = y

            table.insert(linkStoneUidList, uid)

            v:AddChildEntity(self._OwnControl.COMPONENT_TYPE.LINK)
        end
        
        table.sort(linkStoneUidList, function(a, b) 
            local x_A = linkStoneUid2X[a]
            local x_B = linkStoneUid2X[b]

            if x_A == x_B then
                local y_A = linkStoneUid2Y[a]
                local y_B = linkStoneUid2Y[b]
                
                return y_A < y_B
            end
            
            return x_A < x_B
        end)

        for i, v in pairs(selectEntities) do
            ---@type XGoldenMinerComponentLink
            local linkCom = v:GetComponentLink()
            linkCom:SetLinkList(linkStoneUidList)
            linkCom:InitLinkRopeShow()
        end

        if XMain.IsEditorDebug then
            local content = {}
            for i, v in pairs(linkStoneUidList) do
                table.insert(content, v)
                table.insert(content, ', ')
            end

            XLog.Debug('触发电磁链接:'..table.concat(content))
        end

    end
    
end

--endregion

return XGoldenMinerComponentPartnerStoneLink