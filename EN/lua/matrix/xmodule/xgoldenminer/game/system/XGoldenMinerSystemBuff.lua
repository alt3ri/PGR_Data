---@class XGoldenMinerSystemBuff:XEntityControl
---@field _MainControl XGoldenMinerGameControl
---@field private _Model XGoldenMinerModel
local XGoldenMinerSystemBuff = XClass(XEntityControl, "XGoldenMinerSystemBuff")

--region Override
function XGoldenMinerSystemBuff:OnInit()
    ---客户端忽略的buff
    self._IgnoreBuffTypeDir = {
        [XEnumConst.GOLDEN_MINER.BUFF_TYPE.INIT_ITEM] = true,
        [XEnumConst.GOLDEN_MINER.BUFF_TYPE.INIT_SCORES] = true,
        [XEnumConst.GOLDEN_MINER.BUFF_TYPE.SKIP_DISCOUNT] = true,
        [XEnumConst.GOLDEN_MINER.BUFF_TYPE.SHOP_DROP] = true,
        [XEnumConst.GOLDEN_MINER.BUFF_TYPE.SHOP_DISCOUNT] = true,
        [XEnumConst.GOLDEN_MINER.BUFF_TYPE.CORD_MODE] = true,
        [XEnumConst.GOLDEN_MINER.BUFF_TYPE.RAND_ITEM] = true,
    }
    --- 进入游戏立刻触发的buff
    self._BuffTriggerOnEnterGameTypeDir = {
        [XEnumConst.GOLDEN_MINER.BUFF_TYPE.MODIFY_HOOK_GRAB_SIZE] = true,
    }
    ---刷新游戏状态的buff
    self._BuffUpdateGameStatusTypeDir = {
        [XEnumConst.GOLDEN_MINER.BUFF_TYPE.ITEM_STOP_TIME] = true,
    }
    ---刷新钩爪发射速度的buff
    self._BuffUpdateHookShootSpeedTypeDir = {
        [XEnumConst.GOLDEN_MINER.BUFF_TYPE.STRETCH_SPEED] = true,
    }
    ---刷新钩爪回收速度的buff
    self._BuffUpdateHookRevokePercentTypeDir = {
        [XEnumConst.GOLDEN_MINER.BUFF_TYPE.SHORTEN_SPEED] = true,
    }
    ---刷新抓取物分数的buff
    self._BuffUpdateStoneScoreTypeDir = {
        [XEnumConst.GOLDEN_MINER.BUFF_TYPE.STONE_SCORE] = true,
        [XEnumConst.GOLDEN_MINER.BUFF_TYPE.SCORE_FLOAT] = true,
    }
    ---刷新抓取物重量的Buff
    self._BuffUpdateStoneWeightTypeDir = {
        [XEnumConst.GOLDEN_MINER.BUFF_TYPE.WEIGHT_FLOAT] = true,
    }
    ---刷新电磁链接的Buff
    self._BuffUpdatePartnerStoneLinkTypeDir = {
        [XEnumConst.GOLDEN_MINER.BUFF_TYPE.PARTNER_STONE_LINK_PARAMS_MODIFY] = true,
    }
    
    ---刷新钩爪状态的buff
    self.BuffUpdateHookStatusDir = {
        [XEnumConst.GOLDEN_MINER.BUFF_TYPE.MODIFY_HOOK_GRAB_SIZE] = true,
    }

    ---@type table<number, number>
    self._BuffEntityIdDir = {}
    ---@type table<number, table<number, boolean>>
    self._BuffEntityIdTypeDir = {}
    
    self._StoneCopyType = self._MainControl:GetClientStoneCopyType()
end

function XGoldenMinerSystemBuff:EnterGame()
    local buffIdList = self._MainControl:GetGameData():GetInitBuffIdList()
    for _, buffId in ipairs(buffIdList) do
        self:CreateBuffEntity(buffId)
    end
    self:_AddEventListener()
end

function XGoldenMinerSystemBuff:InitAfterEnterGame()
    self:_UpdateBuffTriggerOnEnterGame()
end

function XGoldenMinerSystemBuff:OnUpdate(time)
    self:_UpdateBuffTrigger()
    self:_UpdateBuffLife(time)
end

function XGoldenMinerSystemBuff:OnRelease()
    self:_RemoveEventListener()
    self._IgnoreBuffTypeDir = nil
    self._BuffUpdateGameStatusTypeDir = nil
    self._BuffUpdateHookShootSpeedTypeDir = nil
    self._BuffUpdateHookRevokePercentTypeDir = nil
    self._BuffUpdateStoneScoreTypeDir = nil
    self._BuffUpdateStoneWeightTypeDir = nil
    self._BuffUpdatePartnerStoneLinkTypeDir = nil
    self.BuffUpdateHookStatusDir = nil
    self._BuffEntityIdDir = nil
    self._BuffEntityIdTypeDir = nil
end
--endregion

--region Event

function XGoldenMinerSystemBuff:_AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_GOLDEN_MINER_GAME_RUNTIME_ADD_STONE, self._DoTriggerBuff, self)
end

function XGoldenMinerSystemBuff:_RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_GOLDEN_MINER_GAME_RUNTIME_ADD_STONE, self._DoTriggerBuff, self)
end

--endregion

--region Data - Getter
function XGoldenMinerSystemBuff:GetBuffUidListByType(type)
    return self._BuffEntityIdTypeDir[type]
end

---@return XGoldenMinerEntityBuff
function XGoldenMinerSystemBuff:GetBuffAliveByType(buffType)
    if XTool.IsTableEmpty(self._BuffEntityIdTypeDir[buffType]) then
        return false
    end
    for uid, _ in pairs(self._BuffEntityIdTypeDir[buffType]) do
        if self._MainControl:GetBuffEntityByUid(uid):IsAlive() then
            return self._MainControl:GetBuffEntityByUid(uid)
        end
    end
    return false
end

---@return XGoldenMinerEntityBuff
function XGoldenMinerSystemBuff:CheckBuffStatusByType(buffType, statusType)
    if XTool.IsTableEmpty(self._BuffEntityIdTypeDir[buffType]) then
        return false
    end
    for uid, _ in pairs(self._BuffEntityIdTypeDir[buffType]) do
        if self._MainControl:GetBuffEntityByUid(uid).Status == statusType then
            return self._MainControl:GetBuffEntityByUid(uid)
        end
    end
    return false
end

--- 检查指定类型的buff是否有效：存在且未结束生命周期
function XGoldenMinerSystemBuff:CheckBuffValidByType(buffType)
    if XTool.IsTableEmpty(self._BuffEntityIdTypeDir[buffType]) then
        return false
    end
    for uid, _ in pairs(self._BuffEntityIdTypeDir[buffType]) do
        local buffEntity = self._MainControl:GetBuffEntityByUid(uid)
        if buffEntity.Status ~= XEnumConst.GOLDEN_MINER.GAME_BUFF_STATUS.DIE then
            return buffEntity
        end
    end
    return false
end
--endregion

--region Data - Checker
function XGoldenMinerSystemBuff:_CheckIsIgnoreBuff(buffId)
    local buffType = self._MainControl:GetControl():GetCfgBuffType(buffId)
    return self._IgnoreBuffTypeDir[buffType]
end

function XGoldenMinerSystemBuff:CheckBuffAliveById(buffId)
    if XTool.IsTableEmpty(self._BuffEntityIdDir) then
        return false
    end
    if not self._BuffEntityIdDir[buffId] then
        return false
    end
    return self._MainControl:GetBuffEntityByUid(self._BuffEntityIdDir[buffId]):IsAlive()
end

function XGoldenMinerSystemBuff:CheckHasAliveBuffByType(buffType)
    if XTool.IsTableEmpty(self._BuffEntityIdTypeDir[buffType]) then
        return false
    end
    for uid, _ in pairs(self._BuffEntityIdTypeDir[buffType]) do
        if self._MainControl:GetBuffEntityByUid(uid):IsAlive() then
            return true
        end
    end
    return false
end
--endregion

--region Buff - Create
function XGoldenMinerSystemBuff:CreateBuffEntity(buffId, isAdd)
    if self:_CheckIsIgnoreBuff(buffId) then
        return
    end
    ---@type XGoldenMinerEntityBuff
    local buff
    if self._BuffEntityIdDir[buffId] then
        buff = self._MainControl:GetBuffEntityByUid(self._BuffEntityIdDir[buffId])
        buff.CurTimeTypeParam = isAdd and buff.CurTimeTypeParam + buff:GetTimeTypeParam() or buff:GetTimeTypeParam()
        buff.Status = XEnumConst.GOLDEN_MINER.GAME_BUFF_STATUS.CREATE
        return
    end

    ---@type XGoldenMinerEntityBuff
    buff = self._MainControl:AddEntity(self._MainControl.ENTITY_TYPE.BUFF, buffId)
    buff.CurTimeTypeParam = buff:GetTimeTypeParam()
    buff.Status = XEnumConst.GOLDEN_MINER.GAME_BUFF_STATUS.CREATE

    self._BuffEntityIdDir[buffId] = buff:GetUid()
    if not self._BuffEntityIdTypeDir[buff:GetType()] then
        self._BuffEntityIdTypeDir[buff:GetType()] = {}
    end
    self._BuffEntityIdTypeDir[buff:GetType()][buff:GetUid()] = true
    return buff
end
--endregion

--region Buff - Trigger
---@param buff XGoldenMinerEntityBuff
---@return boolean
function XGoldenMinerSystemBuff:TriggerCountBuff(buff)
    if not buff:CheckTimeType(XEnumConst.GOLDEN_MINER.BUFF_TIME_TYPE.COUNT) then
        return false
    end
    if not buff:IsAlive() then
        return false
    end
    buff.CurTimeTypeParam = buff.CurTimeTypeParam - 1
    XMVCA.XGoldenMiner:DebugWarning("Buff生效1次,Id=" .. buff:GetId() .. ",剩余次数=" .. buff.CurTimeTypeParam)
    if buff.CurTimeTypeParam <= 0 then
        buff.Status = XEnumConst.GOLDEN_MINER.GAME_BUFF_STATUS.BE_DIE
    end
    return true
end

---@param buff XGoldenMinerEntityBuff
---@return boolean
function XGoldenMinerSystemBuff:TriggerGlobalRoleSkillBuff(buff)
    if not buff:CheckTimeType(XEnumConst.GOLDEN_MINER.BUFF_TIME_TYPE.GLOBAL) then
        return false
    end
    if not buff:IsAlive() then
        return false
    end

    if buff:CheckType(XEnumConst.GOLDEN_MINER.BUFF_TYPE.BOOM_GET_SCORE) then
        local score = math.random(buff:GetBuffParams(1), buff:GetBuffParams(2))
        self._MainControl:AddMapScore(score)
        XMVCA.XGoldenMiner:DebugWarning("炸弹加分,Score=" .. score)
    end

    if buff:CheckType(XEnumConst.GOLDEN_MINER.BUFF_TYPE.MOUSE_GET_ITEM) then
        local redId = self._MainControl:GetCfgRedEnvelopeRandId(buff:GetBuffParams(1))
        local itemId = self._MainControl:GetCfgRedEnvelopeItemId(redId)
        self._MainControl:AddItem(itemId)
        XMVCA.XGoldenMiner:DebugWarning("定春加道具,ItemId=" .. itemId)
    end

    if buff:CheckType(XEnumConst.GOLDEN_MINER.BUFF_TYPE.QTE_GET_SCORE) then
        local percent = math.random(buff:GetBuffParams(1), buff:GetBuffParams(2) / XEnumConst.GOLDEN_MINER.PERCENT)
        for _, uid in ipairs(self._MainControl:GetHookEntityUidList()) do
            for _, stoneUid in pairs(self._MainControl:GetHookEntityByUid(uid):GetGrabbingStoneUidList()) do
                local qteComponent = self._MainControl:GetStoneEntityByUid(stoneUid)
                if qteComponent and self._MainControl:GetStoneEntityByUid(stoneUid):CheckStatus(XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS.GRABBED) then
                    local score = qteComponent.AddScore * percent
                    qteComponent.AddScore = math.ceil(qteComponent.AddScore + score)
                    XMVCA.XGoldenMiner:DebugWarning("QTE额外加分,Score=" .. score)
                end
            end
        end
    end

    if buff:CheckType(XEnumConst.GOLDEN_MINER.BUFF_TYPE.HOOK_KARENINA) then
        local curCount = buff.CurTimeTypeParam
        if curCount < buff:GetBuffParams(2) then
            buff.CurTimeTypeParam = buff.CurTimeTypeParam + 1
            XMVCA.XGoldenMiner:DebugWarning("土木老姐Buff抓取次数加+1,当前次数=" .. buff.CurTimeTypeParam)
            self:_UpdateHookShootSpeed()
            self:_UpdateHookRevokePercent()
        end
    end

    return true
end

---@param stoneEntity XGoldenMinerEntityStone
---@return boolean
function XGoldenMinerSystemBuff:TriggerStoneBuffByType(stoneEntity, buffType)
    if buffType == XEnumConst.GOLDEN_MINER.BUFF_TYPE.HOOK_DRAG_EX_STONE_COPY then
        local buffUidList = self:GetBuffUidListByType(buffType)

        if XTool.IsTableEmpty(buffUidList) then
            return false
        end

        -- 不属于可以复制的类型则跳过
        if not table.contains(self._StoneCopyType, stoneEntity.Data:GetType()) then
            return
        end

        -- 已经被拷贝过，或者本身就是拷贝产物，则不会触发拷贝buff
        if stoneEntity:CheckIsBeCopy() or stoneEntity:GetIsCopy() then
            return
        end
        
        local createProbability = 0
        local isLevelUp = false

        for buffUid, v in pairs(buffUidList) do
            local buff = self._MainControl:GetBuffEntityByUid(buffUid)

            if buff and buff:IsAlive() then
                local tmpProbability = buff:GetBuffParams(1)
                local tmpIsLevelUp = XTool.IsNumberValidEx(buff:GetBuffParams(2)) and true or false

                if tmpProbability > createProbability then
                    createProbability = tmpProbability
                end

                if tmpIsLevelUp then
                    isLevelUp = true
                end
            end
        end

        if XTool.IsNumberValidEx(createProbability) then
            --- 万分比
            local value = self._MainControl.Random:Next(0, XEnumConst.GOLDEN_MINER.TEN_THOUSAND_PERCENT)

            if value <= createProbability then
                -- 生成
                local newStoneId = stoneEntity.Data:GetId()
                ---@type XGoldenMinerMapStoneData
                local cloneData = XTool.CloneEx(stoneEntity.Data, false)
                
                if isLevelUp then
                    local stoneCfg = self._Model:GetStoneCfg(newStoneId)
                    
                    if stoneCfg and XTool.IsNumberValidEx(stoneCfg.LevelUpId) then
                        newStoneId = stoneCfg.LevelUpId
                        cloneData:ChangeStoneId(newStoneId)
                        cloneData:SetStoneConfig(self._Model:GetStoneCfg(newStoneId))
                        cloneData:SetIsUseOriginalScale(true)
                        cloneData:SetMapIndex(nil) -- 升级后的资源跟配置对不上，因此置空防止按照配置执行一些逻辑
                    end
                end
                
                self._MainControl.SystemMap:AddCopyStoneCommand(cloneData, stoneEntity)
                
                stoneEntity:AddBeCopyTimes()
            end
        end
    end
end

function XGoldenMinerSystemBuff:_UpdateBuffTrigger()
    if XTool.IsTableEmpty(self._BuffEntityIdDir) then
        return
    end
    local isTrigger = false
    for _, uid in pairs(self._BuffEntityIdDir) do
        local buff = self._MainControl:GetBuffEntityByUid(uid)
        if buff:IsCreate() then
            XMVCA.XGoldenMiner:DebugWarning("触发Buff,id=" .. buff:GetId())
            buff:ChangeAlive()
            self:BuffTriggerFullScreenEffect(buff)
            isTrigger = true
        end
    end
    if isTrigger then
        self:_DoTriggerBuff()
    end
end

function XGoldenMinerSystemBuff:_UpdateBuffTriggerOnEnterGame()
    if XTool.IsTableEmpty(self._BuffEntityIdDir) then
        return
    end
    local isTrigger = false
    for _, uid in pairs(self._BuffEntityIdDir) do
        local buff = self._MainControl:GetBuffEntityByUid(uid)
        if self._BuffTriggerOnEnterGameTypeDir[buff:GetType()] and buff:IsCreate() then
            XMVCA.XGoldenMiner:DebugWarning("触发Buff,id=" .. buff:GetId())
            buff:ChangeAlive()
            self:BuffTriggerFullScreenEffect(buff)
            isTrigger = true
        end
    end
    if isTrigger then
        self:_DoTriggerBuffOnEnterGame()
    end
end

function XGoldenMinerSystemBuff:_DoTriggerBuff()
    self:_DebugAliveBuff()
    self:_UpdateGameStatus()
    self:_UpdateGameTime()
    self:_UpdateShipSpeed()
    self:_UpdateShipMoveMode()
    self:_UpdateShipShell()
    self:_UpdateShipGrabStoneTypes()
    self:_UpdateItem()
    self:_UpdateItemToEntity()
    self:_UpdateHook()
    self:_UpdateHookIdleSpeed()
    self:_UpdateHookShootSpeed()
    self:_UpdateHookRevokePercent()
    self:_UpdateStoneScore()
    self:_UpdateStoneWeight()
    self:_UpdatePartnerStoneLink()
    self:_UpdateHookStatus()
    self:_UpdateStoneRealStatus()
    self:_UpdateIgnoreGameClearIgnoreStoneTypeDir()
    self:_UpdateReflectEdge()
end

function XGoldenMinerSystemBuff:_DoTriggerBuffOnEnterGame()
    self:_UpdateHookStatus()
end

function XGoldenMinerSystemBuff:_UpdateGameStatus()
    if self:GetBuffAliveByType(XEnumConst.GOLDEN_MINER.BUFF_TYPE.ITEM_STOP_TIME) then
        self._MainControl:TimeStop()
        return
    end
    self._MainControl:TimeResume()
end

function XGoldenMinerSystemBuff:_UpdateGameTime()
    ---@type XGoldenMinerEntityBuff
    local buff
    -- 初始加时
    buff = self:GetBuffAliveByType(XEnumConst.GOLDEN_MINER.BUFF_TYPE.INIT_ADD_TIME)
    if buff then
        local stageCount = buff:GetBuffParams(2)
        if not XTool.IsNumberValid(stageCount) or stageCount > self._MainControl:GetGameData():GetFinishStageCount() then
            self._MainControl:AddTime(buff:GetBuffParams(1))
        end
        self:TriggerCountBuff(buff)
    end

    -- 道具加时
    buff = self:GetBuffAliveByType(XEnumConst.GOLDEN_MINER.BUFF_TYPE.ADD_TIME)
    if buff then
        self._MainControl:AddTime(buff:GetBuffParams(1))
        self:TriggerCountBuff(buff)
    end
end

function XGoldenMinerSystemBuff:_UpdateShipSpeed()
    local speedAdd = 0
    
    ---@type XGoldenMinerEntityBuff
    local buff
    buff = self:GetBuffAliveByType(XEnumConst.GOLDEN_MINER.BUFF_TYPE.HUMAN_SPEED)
    if buff and buff:IsAlive() then
        speedAdd = speedAdd + buff:GetBuffParams(1)
    end

    buff = self:GetBuffAliveByType(XEnumConst.GOLDEN_MINER.BUFF_TYPE.SHIP_SPEED_MOVE)
    if buff and buff:IsAlive() then
        speedAdd = speedAdd + buff:GetBuffParams(1)
    end

    self._MainControl:GetShip():GetComponentMove():SetCurBuffAddSpeedPercent(speedAdd)

    if XTool.IsNumberValidEx(speedAdd) then
        XMVCA.XGoldenMiner:DebugWarning("飞船移速加速百分之:" .. tostring(speedAdd))
    end
end

function XGoldenMinerSystemBuff:_UpdateShipMoveMode()
    local buff
    buff = self:GetBuffAliveByType(XEnumConst.GOLDEN_MINER.BUFF_TYPE.HUMAN_REVERSE_MOVE)
    if buff and buff:IsAlive() then
        self._MainControl:GetShip():GetComponentMove():SetIsRopeUpdateShipMove(true)
    end
end

function XGoldenMinerSystemBuff:_UpdateShipShell()
    local buff
    buff = self:GetBuffAliveByType(XEnumConst.GOLDEN_MINER.BUFF_TYPE.HUMAN_CHANGE_SHELL)
    if buff and buff:IsAlive() then
        local shellRawImageUrl = self._MainControl:GetShipShellById(buff:GetBuffParams(1))
        self._MainControl.SystemShip:SetShipShell(shellRawImageUrl)
    end
end

function XGoldenMinerSystemBuff:_UpdateShipGrabStoneTypes()
    local buffUidList = self._BuffEntityIdTypeDir[XEnumConst.GOLDEN_MINER.BUFF_TYPE.HUMAN_REVERSE_MOVE_GRAB_STONES]
    if XTool.IsTableEmpty(buffUidList) then
        return
    end

    for uid, _ in pairs(buffUidList) do
        local buff = self._MainControl:GetBuffEntityByUid(uid)
        if buff and buff:IsAlive() then
            local buffParams = buff:GetBuffParams()
            if XTool.IsTableEmpty(buffParams) then
                return
            end

            local grabStoneTypes = {}
            for i = 2, #buffParams do
                grabStoneTypes[buffParams[i]] = true
            end

            if buffParams[1] == XEnumConst.GOLDEN_MINER.STONE_SUN_MOON_REAL_TYPE.VIRTUAL then
                self._MainControl:GetShip():GetComponentGrab():SetCanGrabVirtualStoneTypes(grabStoneTypes)
            elseif buffParams[1] == XEnumConst.GOLDEN_MINER.STONE_SUN_MOON_REAL_TYPE.REAL then
                self._MainControl:GetShip():GetComponentGrab():SetCanGrabRealStoneTypes(grabStoneTypes)
            else
                self._MainControl:GetShip():GetComponentGrab():SetCanGrabStoneTypes(grabStoneTypes)
            end
        end
    end
end

function XGoldenMinerSystemBuff:_UpdateItem()
    ---@type XGoldenMinerEntityBuff
    local buff
    buff = self:GetBuffAliveByType(XEnumConst.GOLDEN_MINER.BUFF_TYPE.STAGE_ADD_ITEM)
    if buff then
        for _, itemId in ipairs(buff:GetBuffParams()) do
            self._MainControl:AddItem(itemId)
            XMVCA.XGoldenMiner:DebugWarning("每关开始获得道具:" .. itemId, "(本打印不记录是否获得成功)")
        end
        self:TriggerCountBuff(buff)
    end
end

function XGoldenMinerSystemBuff:_UpdateHook()
    ---@type XGoldenMinerEntityBuff
    local buff
    for _, uid in ipairs(self._MainControl:GetHookEntityUidList()) do
        local hookComponent = self._MainControl:GetHookEntityByUid(uid):GetComponentHook()
        buff = self:GetBuffAliveByType(XEnumConst.GOLDEN_MINER.BUFF_TYPE.HOOK_EX_IGNORE)
        if buff and buff:IsAlive() then
            hookComponent:SetExIgnoreTypeDir(buff:GetBuffParams())
            XMVCA.XGoldenMiner:DebugWarning("钩爪添加忽略抓取物类型:", buff:GetBuffParams())
        end

        buff = self:GetBuffAliveByType(XEnumConst.GOLDEN_MINER.BUFF_TYPE.HOOK_GRAB_DESTROY)
        if buff and buff:IsAlive() then
            hookComponent:SetGrabDestroyTypeDir(buff:GetBuffParams())
            XMVCA.XGoldenMiner:DebugWarning("钩爪添加直接抓爆抓取物类型:", buff:GetBuffParams())
        end

        local buffUidList = self:GetBuffUidListByType(XEnumConst.GOLDEN_MINER.BUFF_TYPE.REFLECT_EDGE)
        local count = 0
        if not XTool.IsTableEmpty(buffUidList) then
            for buffUid, _ in pairs(buffUidList) do
                buff = self._MainControl:GetBuffEntityByUid(buffUid)
                if buff:IsAlive() then
                    local paramCount = buff:GetBuffParams(1)
                    if paramCount > count then
                        count = paramCount
                    end
                end
            end
        end

        hookComponent:SetReflectLimitCountByBuff(count)

        buff = self:GetBuffAliveByType(XEnumConst.GOLDEN_MINER.BUFF_TYPE.HUMAN_REVERSE_MOVE)
        if buff and buff:IsAlive() then
            hookComponent:SetIsHumanReversMoveBuffAlive(true)
        else
            hookComponent:SetIsHumanReversMoveBuffAlive(false)
        end
    end
end

function XGoldenMinerSystemBuff:_UpdateHookIdleSpeed()
    local speed = self:_ComputeHookIdleSpeed()
    if XTool.IsNumberValid(speed) then
        for _, uid in ipairs(self._MainControl:GetHookEntityUidList()) do
            local hookComponent = self._MainControl:GetHookEntityByUid(uid):GetComponentHook()
            hookComponent:SetIdleSpeed(speed)
            XMVCA.XGoldenMiner:DebugWarning("已触发Buff下钩爪摆动速度:" .. speed)
        end
    end
end

function XGoldenMinerSystemBuff:_UpdateHookShootSpeed()
    for _, uid in ipairs(self._MainControl:GetHookEntityUidList()) do
        local hookComponent = self._MainControl:GetHookEntityByUid(uid):GetComponentHook()
        hookComponent:SetCurShootSpeed(self:_ComputeHookShootSpeed(hookComponent))
        XMVCA.XGoldenMiner:DebugWarning("已触发Buff下钩爪发射速度:" .. hookComponent:GetCurShootSpeed())
    end
end

function XGoldenMinerSystemBuff:_UpdateHookRevokePercent()
    for _, uid in ipairs(self._MainControl:GetHookEntityUidList()) do
        local hookComponent = self._MainControl:GetHookEntityByUid(uid):GetComponentHook()
        hookComponent:SetCurRevokeSpeedPercent(self:_ComputeHookRevokePercent())
        XMVCA.XGoldenMiner:DebugWarning("已触发Buff下钩爪回收速度倍率:" .. hookComponent:GetCurRevokeSpeedPercent())
    end
end

function XGoldenMinerSystemBuff:_UpdateItemToEntity()
    ---@type XGoldenMinerEntityBuff
    local buff
    -- 添加瞄准镜
    buff = self:GetBuffAliveByType(XEnumConst.GOLDEN_MINER.BUFF_TYPE.AIM)
    if buff then
        local reflectAimCount = buff:GetBuffParams(1)
        for _, uid in ipairs(self._MainControl:GetHookEntityUidList()) do
            self._MainControl:GetHookEntityByUid(uid):GetComponentHook():SetAim(true, reflectAimCount)
        end
        self:TriggerCountBuff(buff)
    end

    -- 使用炸弹
    buff = self:GetBuffAliveByType(XEnumConst.GOLDEN_MINER.BUFF_TYPE.BOOM)
    if buff then
        for _, uid in ipairs(self._MainControl:GetHookEntityUidList()) do
            local hookEntity = self._MainControl:GetHookEntityByUid(uid)
            for _, stoneUid in ipairs(hookEntity:GetGrabbingStoneUidList()) do
                self._MainControl.SystemStone:SetStoneEntityStatus(self._MainControl:GetStoneEntityByUid(stoneUid), XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS.DESTROY)
            end
            XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_PLAY_EFFECT,
                    XEnumConst.GOLDEN_MINER.GAME_EFFECT_TYPE.GRAB_BOOM,
                    hookEntity:GetComponentHook():GetGrabPoint(),
                    self._MainControl:GetClientUseBoomEffect())
        end
        self:TriggerCountBuff(buff)
    end

    -- 点石成金
    buff = self:GetBuffAliveByType(XEnumConst.GOLDEN_MINER.BUFF_TYPE.STONE_CHANGE_GOLD)
    if buff then
        for _, uid in ipairs(self._MainControl:GetHookEntityUidList()) do
            local hookEntity = self._MainControl:GetHookEntityByUid(uid)
            local newGrabbingUidDir = {}
            for i, stoneUid in ipairs(hookEntity:GetGrabbingStoneUidList()) do
                local stoneEntity = self._MainControl:GetStoneEntityByUid(stoneUid)
                if stoneEntity:CheckStatus(XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS.GRABBING) then
                    XMVCA.XGoldenMiner:DebugWarning("点石-石头：", stoneEntity:__DebugLog())
                    local newStoneEntity = self._MainControl.SystemMap:StoneChangeToGold(stoneEntity)
                    if newStoneEntity then
                        newGrabbingUidDir[i] = newStoneEntity:GetUid()
                        XMVCA.XGoldenMiner:DebugWarning("点石-金子：", newStoneEntity:__DebugLog())
                    end
                    self._MainControl.SystemStone:SetStoneEntityStatus(newStoneEntity and newStoneEntity or stoneEntity, XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS.GRABBING)
                end
            end
            for i, stoneUid in pairs(newGrabbingUidDir) do
                hookEntity:GetGrabbingStoneUidList()[i] = stoneUid
            end
            self:_UpdateStoneScore()
            XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_PLAY_EFFECT,
                    XEnumConst.GOLDEN_MINER.GAME_EFFECT_TYPE.GRAB_BOOM,
                    hookEntity:GetComponentHook():GetGrabPoint(),
                    self._MainControl:GetClientUseBoomEffect())
        end
        self:TriggerCountBuff(buff)
    end

    -- 类型炸弹
    buff = self:GetBuffAliveByType(XEnumConst.GOLDEN_MINER.BUFF_TYPE.TYPE_BOOM)
    if buff then
        local stoneType = buff:GetBuffParams(1)
        for uid, _ in pairs(self._MainControl:GetStoneEntityUidDirByType(stoneType)) do
            local stoneEntity = self._MainControl:GetStoneEntityByUid(uid)
            if stoneEntity:IsAlive() then
                self._MainControl.SystemStone:SetStoneEntityStatus(stoneEntity, XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS.BE_DESTROY)
                XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_PLAY_EFFECT,
                        XEnumConst.GOLDEN_MINER.GAME_EFFECT_TYPE.TYPE_BOOM,
                        stoneEntity:GetTransform(),
                        self._MainControl:GetClientUseBoomEffect())
            end
        end
        self:TriggerCountBuff(buff)
    end

    -- 电磁炮
    buff = self:GetBuffAliveByType(XEnumConst.GOLDEN_MINER.BUFF_TYPE.ELECTROMAGNETIC)
    if buff then
        local typeDir = {}
        for _, type in ipairs(buff:GetBuffParams()) do
            typeDir[type] = true
        end
        local infoList = self._MainControl:GetClientElectromagneticResult()
        local handler = function(stoneEntity)
            if (stoneEntity:IsAlive()) and typeDir[stoneEntity.Data:GetType()] then
                local weight = stoneEntity.Data:GetWeight()
                for _, info in ipairs(infoList) do
                    if weight >= info.min and weight <= info.max then
                        self._MainControl.SystemMap:StoneChangeToOther(stoneEntity, info.stoneId, false, true)
                        self._MainControl.SystemStone:SetStoneEntityStatus(stoneEntity, XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS.ALIVE)
                    end
                end
            end
        end
        local beDieTime = self._MainControl.SystemMap:HandlerElectromagnetic(handler)
        self:TriggerCountBuff(buff)
        buff:SetCurBeDieTime(beDieTime)
    end
end

function XGoldenMinerSystemBuff:_UpdateStoneScore()
    if XTool.IsTableEmpty(self._MainControl:GetStoneEntityUidDirByType()) then
        return
    end
    for uid, _ in pairs(self._MainControl:GetStoneEntityUidDirByType()) do
        local stoneEntity = self._MainControl:GetStoneEntityByUid(uid)
        if not stoneEntity:CheckStatus(XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS.GRABBED) and not stoneEntity:GetComponentQTE() then
            self:_ComputeStoneScore(stoneEntity)
        end
    end
end

function XGoldenMinerSystemBuff:_UpdateStoneWeight()
    if XTool.IsTableEmpty(self._MainControl:GetStoneEntityUidDirByType()) then
        return
    end
    for uid, _ in pairs(self._MainControl:GetStoneEntityUidDirByType()) do
        local stoneEntity = self._MainControl:GetStoneEntityByUid(uid)
        if not stoneEntity:CheckStatus(XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS.GRABBED) then
            local newWeight = self:_ComputeStoneWeight(stoneEntity)
            stoneEntity:GetComponentStone():SetCurWeight(newWeight)
            XMVCA.XGoldenMiner:DebugLogWithType(XMVCA.XGoldenMiner.EnumConst.DebuggerLogType.StoneWeight, "已触发Buff下抓取物重量:" .. stoneEntity:GetComponentStone().CurWeight .. ",StoneId=" .. stoneEntity.Data:GetId())
        end
    end
end

function XGoldenMinerSystemBuff:_UpdatePartnerStoneLink()
    ---@type XGoldenMinerComponentPartnerStoneLink[]
    local stonLinkComs = self._MainControl.SystemPartner:GetPartnerComponentsByType(self._MainControl.COMPONENT_TYPE.PARTNER_STONELINK)

    if XTool.IsTableEmpty(stonLinkComs) then
        return
    end
    
    local buffUidList = self:GetBuffUidListByType(XEnumConst.GOLDEN_MINER.BUFF_TYPE.PARTNER_STONE_LINK_PARAMS_MODIFY)

    if not XTool.IsTableEmpty(buffUidList) then
        local isAnyBuffAlive = false
        
        for buffUid, v in pairs(buffUidList) do
            local buff = self._MainControl:GetBuffEntityByUid(buffUid)

            if buff and buff:IsAlive() then
                isAnyBuffAlive = true

                for i, stoneLinkCom in pairs(stonLinkComs) do
                    local nearestCount = buff:GetBuffParams(1)
                    local farestCount = buff:GetBuffParams(2)
                    local idleCd = buff:GetBuffParams(3)

                    if XTool.IsNumberValidEx(nearestCount) then
                        if nearestCount >= stoneLinkCom:GetCurSelectNearestCount() then
                            stoneLinkCom:UpdateSelectNearestCount(nearestCount)
                        end
                    end

                    if XTool.IsNumberValidEx(farestCount) then
                        if farestCount >= stoneLinkCom:GetCurSelectFarestCount() then
                            stoneLinkCom:UpdateSelectFarestCount(farestCount)
                        end
                    end

                    if XTool.IsNumberValidEx(idleCd) then
                        if idleCd <= stoneLinkCom:GetCurMaxIdleCd() then
                            stoneLinkCom:UpdateMaxIdleCd(idleCd)
                        end
                    end

                    local effectTime = buff:GetBuffParams(4)

                    if XTool.IsNumberValidEx(effectTime) and effectTime < stoneLinkCom:GetCurMaxScanCd() then
                        stoneLinkCom:UpdateMaxScanCd(effectTime)
                    end
                end
            end
        end

        -- 如果有任意buff生效了，那么逻辑到此为止
        if isAnyBuffAlive then
            return
        end
    end
    
    -- 否则无论是没有buff，还是没有生效的buff，都将电磁链接的数据重置
    for i, stoneLinkCom in pairs(stonLinkComs) do
        stoneLinkCom:ResetCDMax()
        stoneLinkCom:ResetLinkCount()
    end
end

function XGoldenMinerSystemBuff:_UpdateHookStatus()
    local hookUidList = self._MainControl.SystemHook:GetHookEntityUidList()

    if XTool.IsTableEmpty(hookUidList) then
        return
    end
    
    -- 修改钩爪尺寸
    local buffIds = self:GetBuffUidListByType(XEnumConst.GOLDEN_MINER.BUFF_TYPE.MODIFY_HOOK_GRAB_SIZE)
    
    local sizePercent = 1
    local sizePercentAdds = 0
    
    if not XTool.IsTableEmpty(buffIds) then
        for buffId, _ in pairs(buffIds) do
            local buff = self._MainControl:GetBuffEntityByUid(buffId)

            if buff and buff:IsAlive() then
                sizePercentAdds = sizePercentAdds + buff:GetBuffParams(1)
            end
        end

        if sizePercentAdds ~= 0 then
            sizePercentAdds = sizePercentAdds / XEnumConst.GOLDEN_MINER.PERCENT

            sizePercent = sizePercent + sizePercentAdds
        end
    end
    
    self._MainControl:FixWallOutByPercent(sizePercent)

    for i, hookUid in pairs(hookUidList) do
        local hookEntity = self._MainControl:GetHookEntityByUid(hookUid)

        if hookEntity then
            -- 弹网钩爪特殊处理
            local netCom = hookEntity:GetComponentNetAim()

            if netCom then
                netCom:SetGrabSize(sizePercent)
            else
                local hookCom = hookEntity:GetComponentHook()

                if hookCom and hookCom.SetGrabSize then
                    hookCom:SetGrabSize(sizePercent)
                end
            end
        end
    end
    
    -- 弹网钩爪 - 设置抓取重量计算规则
    local buff = self:GetBuffAliveByType(XEnumConst.GOLDEN_MINER.BUFF_TYPE.SET_NET_HOOK_GRAB_WEIGHT_RULE)

    if buff then
        for i, hookUid in pairs(hookUidList) do
            local hookEntity = self._MainControl:GetHookEntityByUid(hookUid)

            if hookEntity then
                -- 弹网钩爪特殊处理
                local netCom = hookEntity:GetComponentNetAim()

                if netCom then
                    netCom:SetGrabWeightRule(buff:GetBuffParams(1))
                end
            end
        end
    end
end

function XGoldenMinerSystemBuff:_UpdateStoneRealStatus()
    self._MainControl.SystemMap:UpdateSunMoon(false, false)
end

function XGoldenMinerSystemBuff:_UpdateIgnoreGameClearIgnoreStoneTypeDir()
    self._MainControl:SetIgnoreGameClearIgnoreStoneTypeDir(self:_GetIgnoreGameClearIgnoreStoneTypeDir())
end

function XGoldenMinerSystemBuff:_UpdateReflectEdge()
    local buff = self:GetBuffAliveByType(XEnumConst.GOLDEN_MINER.BUFF_TYPE.REFLECT_EDGE)
    if buff and buff:IsAlive() then
        self._MainControl.SystemMap:OpenReflectEdge(true)
    else
        self._MainControl.SystemMap:OpenReflectEdge(false)
    end
end

---@param hook XGoldenMinerComponentHook
function XGoldenMinerSystemBuff:_ComputeHookIdleSpeed()
    local buffUidList = self._MainControl.SystemBuff:GetBuffUidListByType(XEnumConst.GOLDEN_MINER.BUFF_TYPE.HOOK_CHANGE_IDLE_SPEED)
    if XTool.IsTableEmpty(buffUidList) then
        return false
    end

    local totalSpeedPercent = 0
    for uid, _ in pairs(buffUidList) do
        local buff = self._MainControl:GetBuffEntityByUid(uid)
        if buff and buff:IsAlive() then
            local params = buff:GetBuffParams()
            local speedPercent = tonumber(params[1])
            if XTool.IsNumberValid(speedPercent) then
                totalSpeedPercent = totalSpeedPercent + speedPercent
            end
        end
    end

    local basicsSpeed = self._MainControl:GetClientRopeRockSpeed()
    local finialSpeed = basicsSpeed * (1 + totalSpeedPercent / XEnumConst.GOLDEN_MINER.PERCENT)

    return finialSpeed
end

function XGoldenMinerSystemBuff:_ComputeHookShootSpeed(hook)
    if XTool.IsTableEmpty(self._BuffEntityIdDir) then
        return hook:GetShootSpeed()
    end
    local buffUidList = self:GetBuffUidListByType(XEnumConst.GOLDEN_MINER.BUFF_TYPE.STRETCH_SPEED)
    local percentChange = 0
    if not XTool.IsTableEmpty(buffUidList) then
        for uid, _ in pairs(buffUidList) do
            local buff = self._MainControl:GetBuffEntityByUid(uid)
            if buff:IsAlive() then
                percentChange = percentChange + buff:GetBuffParams(1)
            end
        end
    end

    local buff = self:GetBuffAliveByType(XEnumConst.GOLDEN_MINER.BUFF_TYPE.HOOK_KARENINA)
    if buff and buff:IsAlive() then
        percentChange = percentChange + buff:GetBuffParams(1) * buff.CurTimeTypeParam
    end
    return hook:GetShootSpeed() * (1 + percentChange / XEnumConst.GOLDEN_MINER.PERCENT)
end

function XGoldenMinerSystemBuff:_ComputeHookRevokePercent()
    local defaultPercent = 1
    if XTool.IsTableEmpty(self._BuffEntityIdDir) then
        return defaultPercent
    end
    local percentChange = 0
    local buffUidList = self:GetBuffUidListByType(XEnumConst.GOLDEN_MINER.BUFF_TYPE.SHORTEN_SPEED)
    if not XTool.IsTableEmpty(buffUidList) then
        for uid, _ in pairs(buffUidList) do
            local buff = self._MainControl:GetBuffEntityByUid(uid)
            if buff:IsAlive() then
                percentChange = percentChange + buff:GetBuffParams(1)
            end
        end
    end
    local buff = self:GetBuffAliveByType(XEnumConst.GOLDEN_MINER.BUFF_TYPE.HOOK_KARENINA)
    if buff and buff:IsAlive() then
        percentChange = percentChange + buff:GetBuffParams(1) * buff.CurTimeTypeParam
    end
    return defaultPercent + percentChange / XEnumConst.GOLDEN_MINER.PERCENT
end

---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerSystemBuff:_ComputeStoneScore(stoneEntity)
    local stoneComponent = stoneEntity:GetComponentStone()
    local carryStone = stoneEntity:GetCarryStoneEntity()
    if XTool.IsTableEmpty(self._BuffEntityIdDir) then
        stoneComponent.CurScore = stoneComponent.Score
        if carryStone then
            carryStone:GetComponentStone().CurScore = carryStone:GetComponentStone().Score
        end
        return
    end
    local percentChange = self:_CalculatePercentChange(stoneEntity.Data:GetType())
    --local buffUidList
    ---- 指定Type抓取物获得的分数增加 X%
    --buffUidList = self:GetBuffUidListByType(XEnumConst.GOLDEN_MINER.BUFF_TYPE.STONE_SCORE)
    --if not XTool.IsTableEmpty(buffUidList) then
    --    for uid, _ in pairs(buffUidList) do
    --        local buff = self._MainControl:GetBuffEntityByUid(uid)
    --        if buff:IsAlive() and stoneEntity.Data:CheckType(buff:GetBuffParams(1)) then
    --            percentChange = percentChange + buff:GetBuffParams(2)
    --        end
    --    end
    --end
    ---- 每次夹取物品价值变化
    --buffUidList = self:GetBuffUidListByType(XEnumConst.GOLDEN_MINER.BUFF_TYPE.SCORE_FLOAT)
    --if not XTool.IsTableEmpty(buffUidList) then
    --    for uid, _ in pairs(buffUidList) do
    --        local buff = self._MainControl:GetBuffEntityByUid(uid)
    --        if buff:IsAlive() then
    --            percentChange = percentChange + math.random(buff:GetBuffParams(1), buff:GetBuffParams(2))
    --        end
    --    end
    --end

    stoneComponent.CurScore = math.ceil(stoneComponent.Score * (1 + percentChange / XEnumConst.GOLDEN_MINER.PERCENT))
    XMVCA.XGoldenMiner:DebugLogWithType(XMVCA.XGoldenMiner.EnumConst.DebuggerLogType.GrabScore, "已触发Buff下抓取物分数:" .. stoneComponent.CurScore .. ",StoneId=" .. stoneEntity.Data:GetId())
    if carryStone then
        carryStone:GetComponentStone().CurScore = math.ceil(carryStone:GetComponentStone().Score * (1 + percentChange / XEnumConst.GOLDEN_MINER.PERCENT))
        XMVCA.XGoldenMiner:DebugLogWithType(XMVCA.XGoldenMiner.EnumConst.DebuggerLogType.GrabScore, "已触发Buff下抓取物携带物分数:" .. carryStone:GetComponentStone().CurScore .. ",StoneId=" .. carryStone.Data:GetId())
    end
end

---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerSystemBuff:_ComputeStoneWeight(stoneEntity)
    if XTool.IsTableEmpty(self._BuffEntityIdDir) then
        return stoneEntity:GetComponentStone().Weight
    end
    local percentChange = 0
    -- 变化重量
    local buffUidList = self:GetBuffUidListByType(XEnumConst.GOLDEN_MINER.BUFF_TYPE.WEIGHT_FLOAT)
    if not XTool.IsTableEmpty(buffUidList) then
        for uid, _ in pairs(buffUidList) do
            local buff = self._MainControl:GetBuffEntityByUid(uid)
            if buff:IsAlive() and (stoneEntity.Data:CheckType(buff:GetBuffParams(1)) or buff:GetBuffParams(1) == 0) then
                percentChange = percentChange + buff:GetBuffParams(2)
            end
        end
    end

    return stoneEntity:GetComponentStone().Weight * (1 + percentChange / XEnumConst.GOLDEN_MINER.PERCENT)
end

function XGoldenMinerSystemBuff:_GetIgnoreGameClearIgnoreStoneTypeDir()
    local ignoreStoneTypeDir = {}
    local buffUidList = self:GetBuffUidListByType(XEnumConst.GOLDEN_MINER.BUFF_TYPE.HOOK_EX_FORCE)
    if not XTool.IsTableEmpty(buffUidList) then
        for uid, _ in pairs(buffUidList) do
            local buff = self._MainControl:GetBuffEntityByUid(uid)
            if buff:IsAlive() then
                for _, type in ipairs(buff:GetBuffParams()) do
                    ignoreStoneTypeDir[type] = true
                end
            end
        end
    end

    return ignoreStoneTypeDir
end
--endregion

--region Buff - Update
---@return boolean
function XGoldenMinerSystemBuff:_UpdateBuffLife(time)
    for _, uid in pairs(self._BuffEntityIdDir) do
        self:_UpdateBuff(self._MainControl:GetBuffEntityByUid(uid), time)
    end
end

---@param buff XGoldenMinerEntityBuff
function XGoldenMinerSystemBuff:_UpdateBuff(buff, time)
    if buff:CheckTimeType(XEnumConst.GOLDEN_MINER.BUFF_TIME_TYPE.TIME) and buff:IsAlive() then
        XMVCA.XGoldenMiner:DebugWarning("Buff持续生效,Id=" .. buff:GetId() .. ",倒计时=" .. buff.CurTimeTypeParam)
        buff.CurTimeTypeParam = buff.CurTimeTypeParam - time
        buff.CurTimeTypeParam = math.max(buff.CurTimeTypeParam, 0)
        if buff.CurTimeTypeParam <= 0 then
            buff.Status = XEnumConst.GOLDEN_MINER.GAME_BUFF_STATUS.BE_DIE
        end
    elseif buff.Status == XEnumConst.GOLDEN_MINER.GAME_BUFF_STATUS.BE_DIE then
        buff:DownBeDieTime(time)
        if buff:CheckIsWillBeDie() then
            self:_OnBuffDie(buff)
            self:BuffDieFullScreenEffect(buff)
        end
    end
end

---@param buff XGoldenMinerEntityBuff
function XGoldenMinerSystemBuff:_OnBuffDie(buff)
    XMVCA.XGoldenMiner:DebugWarning("Buff效果结束,Id=" .. buff:GetId())
    self:_DebugAliveBuff()
    local type = buff:GetType()
    if self._BuffUpdateGameStatusTypeDir[type] then
        self:_UpdateGameStatus()
    end
    if self._BuffUpdateHookShootSpeedTypeDir[type] then
        self:_UpdateHookShootSpeed()
    end
    if self._BuffUpdateHookRevokePercentTypeDir[type] then
        self:_UpdateHookRevokePercent()
    end
    if self._BuffUpdateStoneScoreTypeDir[type] then
        self:_UpdateStoneScore()
    end
    if self._BuffUpdateStoneWeightTypeDir[type] then
        self:_UpdateStoneWeight()
    end
    if self._BuffUpdatePartnerStoneLinkTypeDir[type] then
        self._UpdatePartnerStoneLink()
    end
    if self.BuffUpdateHookStatusDir[type] then
        self._UpdateHookStatus()
    end
    if type == XEnumConst.GOLDEN_MINER.BUFF_TYPE.ELECTROMAGNETIC then
        self._MainControl.SystemMap:ClearElectromagnetic()
    end
    buff.Status = XEnumConst.GOLDEN_MINER.GAME_BUFF_STATUS.DIE
end
--endregion

--region Buff - Effect
---@param buff XGoldenMinerEntityBuff
function XGoldenMinerSystemBuff:BuffTriggerFullScreenEffect(buff)
    if buff:CheckType(XEnumConst.GOLDEN_MINER.BUFF_TYPE.WEIGHT_FLOAT) then
        self:_PlayFullScreenEffect(XEnumConst.GOLDEN_MINER.GAME_EFFECT_TYPE.WEIGHT_FLOAT, self._MainControl:GetClientWeightFloatEffect())
    elseif buff:CheckType(XEnumConst.GOLDEN_MINER.BUFF_TYPE.ITEM_STOP_TIME) then
        self:_PlayFullScreenEffect(XEnumConst.GOLDEN_MINER.GAME_EFFECT_TYPE.TIME_STOP, self._MainControl:GetClientStopTimeStartEffect())
    end
end

---@param buff XGoldenMinerEntityBuff
function XGoldenMinerSystemBuff:BuffDieFullScreenEffect(buff)
    if buff:CheckType(XEnumConst.GOLDEN_MINER.BUFF_TYPE.WEIGHT_FLOAT) then
        self:_PlayFullScreenEffect(XEnumConst.GOLDEN_MINER.GAME_EFFECT_TYPE.WEIGHT_RESUME, self._MainControl:GetClientWeightFloatEffect())
    elseif buff:CheckType(XEnumConst.GOLDEN_MINER.BUFF_TYPE.ITEM_STOP_TIME) then
        self:_PlayFullScreenEffect(XEnumConst.GOLDEN_MINER.GAME_EFFECT_TYPE.TIME_RESUME, self._MainControl:GetClientStopTimeStopEffect())
    end
end

function XGoldenMinerSystemBuff:_PlayFullScreenEffect(effectType, path)
    XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_PLAY_EFFECT, effectType, nil, path)
end
--endregion

--region 计算分数
--(使用Buff系统计算分数目前算是取巧，鉴于目前抓取物都是受Buff影响放在这里，后续如果存在复杂影响分数的来源，可以单独做个分数系统在抓取时判断)
---@param score int 原始分数 也就是抓取物配置的分数
function XGoldenMinerSystemBuff:CalculateStoneCurScore(storeType, score)
    local percentChange = self:_CalculatePercentChange(storeType)
    return math.ceil(score * (1 + percentChange / XEnumConst.GOLDEN_MINER.PERCENT))
end

-- 基于当前所有影响石头分数的Buff计算分数变化百分比
function XGoldenMinerSystemBuff:_CalculatePercentChange(storeType)
    local percentChange = 0
    local buffUidList
    -- 指定Type抓取物获得的分数增加 X%
    buffUidList = self:GetBuffUidListByType(XEnumConst.GOLDEN_MINER.BUFF_TYPE.STONE_SCORE)
    if not XTool.IsTableEmpty(buffUidList) then
        for uid, _ in pairs(buffUidList) do
            local buff = self._MainControl:GetBuffEntityByUid(uid)
            if buff:IsAlive() then
                local paramStoneType = buff:GetBuffParams(1)
                if paramStoneType == XEnumConst.GOLDEN_MINER.STONE_TYPE.ALL or storeType == paramStoneType then
                    percentChange = percentChange + buff:GetBuffParams(2)
                end
            end
        end
    end
    -- 每次夹取物品价值变化
    buffUidList = self:GetBuffUidListByType(XEnumConst.GOLDEN_MINER.BUFF_TYPE.SCORE_FLOAT)
    if not XTool.IsTableEmpty(buffUidList) then
        for uid, _ in pairs(buffUidList) do
            local buff = self._MainControl:GetBuffEntityByUid(uid)
            if buff:IsAlive() then
                percentChange = percentChange + math.random(buff:GetBuffParams(1), buff:GetBuffParams(2))
            end
        end
    end

    return percentChange
end

--endregion

--region Debug
function XGoldenMinerSystemBuff:_DebugAliveBuff()
    if not XMVCA.XGoldenMiner.IsDebug then
        return
    end
    local aliveBuffList = self:_DebugGetAliveBuffList()
    XMVCA.XGoldenMiner:DebugWarning("当前生效buff个数:", #aliveBuffList)
    for _, aliveBuff in ipairs(aliveBuffList) do
        XMVCA.XGoldenMiner:DebugWarning("buff:" .. aliveBuff:GetId(), aliveBuff:__DebugLog())
    end
end

---@return XGoldenMinerEntityBuff[]
function XGoldenMinerSystemBuff:_DebugGetAliveBuffList()
    local aliveBuffList = {}
    if XTool.IsTableEmpty(self._BuffEntityIdDir) then
        return aliveBuffList
    end
    for _, uid in pairs(self._BuffEntityIdDir) do
        if self._MainControl:GetBuffEntityByUid(uid):IsAlive() then
            aliveBuffList[#aliveBuffList + 1] = self._MainControl:GetBuffEntityByUid(uid)
        end
    end
    return aliveBuffList
end
--endregion

return XGoldenMinerSystemBuff