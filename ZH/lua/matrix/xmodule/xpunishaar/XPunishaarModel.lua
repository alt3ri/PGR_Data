---@class XPunishaarModel : XModelBase
---@field OutSideModel XPunishaarSubModelOutSide 外部子模块

local XPunishaarModel = XClass(XModelBase, "XPunishaarModel")

function XPunishaarModel:OnInit()
    --初始化内部变量
    --这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析
    ---@filed _StageStatusDict table<number, XPunishaarStageStatus> 关卡状态字典, key: stageId, value: XPunishaarStageStatus
    self._ActivityId = 0 --活动id

    self._OutSideModel = self:AddSubModel(require("XModule/XPunishaar/SubModules/OutSide/XPunishaarSubModelOutSide"))

end

function XPunishaarModel:ClearPrivate()
    self._BattleInitData = nil
    self._LastRewardGoodsList = nil
    self._OutSideModel:ClearPrivate()
end

--- 清除当局运行缓存（整局结算 Refresh 完成后、跳转下一界面前调用）。
--- 不触碰 OutSideModel 的通关记录和 ActivityId。
function XPunishaarModel:ClearCurrentRun()
    local stageId = self._CurrentStage and self._CurrentStage.StageId
    if stageId then
        self._OutSideModel:ClearSaveStage(stageId)
    end
    self._CurrentStage = nil
    self._BattleInitData = nil
    self._LastRewardGoodsList = nil
end

function XPunishaarModel:ResetAll()
    self._CurrentStage = nil
    self._OutSideModel:ClearPrivate()
    self._ActivityId = 0
end

--region ----------public start----------

function XPunishaarModel:GetActivityId()
    return self._ActivityId
end

function XPunishaarModel:CheckHasValidActivityId()
    return XTool.IsNumberValidEx(self._ActivityId)
end

--- 取开战契约对象（可复用、唯一实例；首次访问惰性创建）。
--- 外部经 set 接口逐项写它，Control 初始化时读它开局。字段复用减少每局 table 分配。
---@return XPunishaarBattleInitData
function XPunishaarModel:GetBattleInitData()
    if not self._BattleInitData then
        self._BattleInitData = require("XModule/XPunishaar/STEDefine/XPunishaarBattleInitData").New()
    end
    return self._BattleInitData
end

--- 换局前清空契约对象以复用（清字段不销毁实例）。
---@return XPunishaarBattleInitData
function XPunishaarModel:ResetBattleInitData()
    local data = self:GetBattleInitData()
    data:Reset()
    return data
end

--- 取契约对象但不创建（供"是否已备好开战数据"的判断；未 set 过返回 nil）。
---@return XPunishaarBattleInitData|nil
function XPunishaarModel:PeekBattleInitData()
    return self._BattleInitData
end

---@param stage table Server.XPunishaarStage
function XPunishaarModel:SetCurrentStage(stage)
    self._CurrentStage = stage
    
    -- 同步更新局外存档缓存，保证局外界面读取到最新关卡进度
    if stage and stage.StageId then
        self._OutSideModel:SetSaveStage(stage.StageId, stage)
    end
end

---@return table|nil Server.XPunishaarStage
function XPunishaarModel:GetCurrentStage()
    return self._CurrentStage
end

--- 更新当前局的节点信息（不替换整个 Stage，仅更新 CurrentNode）
---@param node table Server.XPunishaarNode
function XPunishaarModel:SetCurrentNode(node)
    if self._CurrentStage then
        self._CurrentStage.CurrentNode = node
    end
end

--- 更新局内金币（服务端推送 NotifyPunishaarGoldChange 时调用）
---@param gold number
function XPunishaarModel:SetCurrentGold(gold)
    if self._CurrentStage then
        self._CurrentStage.Gold = gold
    end
end

--- 处理主卡变化通知（购买/合成后）：新增主卡写入，被消耗主卡移除。
---@param addedCard table XPunishaarMasterCard（新增的主卡，可为nil）
---@param removedCardIds table int[]（合成消耗移除的主卡唯一Id列表，可为nil）
function XPunishaarModel:UpdateMasterCardByNotify(addedCard, removedCardIds)
    local cards = self._CurrentStage and self._CurrentStage.TotalMasterCards
    if not cards then return end
    if addedCard and addedCard.Id then
        cards[addedCard.Id] = addedCard
    end
    if removedCardIds then
        for _, id in ipairs(removedCardIds) do
            cards[id] = nil
        end
    end
end

--- 批量更新主卡位置（DoSetCardPos 成功后客户端本地同步，无服务端 Node 下发）。
---@param cardPosList table XPunishaarCardPosInfo[]（{ Id, AreaType, StartPos }）
function XPunishaarModel:UpdateCardPositions(cardPosList)
    local cards = self._CurrentStage and self._CurrentStage.TotalMasterCards
    if not cards then return end
    for _, info in ipairs(cardPosList) do
        if cards[info.Id] then
            cards[info.Id].AreaType = info.AreaType
            cards[info.Id].StartPos = info.StartPos
        end
    end
end

--- 处理副卡装配通知：更新宿主主卡的副卡槽位。
---@param masterCardId number 宿主主卡唯一Id
---@param subCardId number 装配后副卡模板Id（0=已移除）
function XPunishaarModel:UpdateSubCardByNotify(masterCardId, subCardId)
    local cards = self._CurrentStage and self._CurrentStage.TotalMasterCards
    if not cards or not cards[masterCardId] then return end
    cards[masterCardId].SubCardId = subCardId
end

--- 通用奖励下发通知：缓存奖励整体（表现层拉取弹窗集中展示）+ 更新局内槽位解锁上限。
--- 金币/主卡/副卡的实际状态由专用 Notify（GoldChange/MasterCardChange/SubCardChange）单独推送，
--- 此处仅缓存奖励列表 + 槽位解锁更新 stage.GridLimit（增量累加）。
---@param stageId number 奖励所属关卡存档
---@param rewardGoodsList table XPunishaarRewardGoods[]（按 RewardType 区分）
function XPunishaarModel:OnNotifyPunishaarRewardResult(stageId, rewardGoodsList)
    -- 缓存整体奖励（表现层经 GetLastRewardGoodsList 拉取弹窗展示）
    self._LastRewardGoodsList = rewardGoodsList

    if not rewardGoodsList or not self._CurrentStage then return end
    local RewardType = XMVCA.XPunishaar.EnumConst.RewardType
    for _, reward in ipairs(rewardGoodsList) do
        -- 槽位解锁：更新局内 GridLimit（增量累加）
        if reward.RewardType == RewardType.FightAreaGridLimit then
            self._CurrentStage.FightAreaGridLimit = (self._CurrentStage.FightAreaGridLimit or 0) + (reward.Amount or 0)
        elseif reward.RewardType == RewardType.BagGridLimit then
            self._CurrentStage.BagGridLimit = (self._CurrentStage.BagGridLimit or 0) + (reward.Amount or 0)
        end
        -- Gold/MasterCard/SubCard/MaxHp：仅缓存（展示），实际状态由专用 Notify 下发
    end
end

--- 获取最近一次奖励列表（表现层弹窗集中展示用）
---@return table|nil XPunishaarRewardGoods[]
function XPunishaarModel:GetLastRewardGoodsList()
    return self._LastRewardGoodsList
end

function XPunishaarModel:GetOutSideModel()
    return self._OutSideModel
end
--endregion ----------public end----------


--region 关卡本地记录

local StageReadKeyPrefix = "PunishaarStageRead_"
function XPunishaarModel:GetStageReadKey(stageId)
    return string.format(
        "%s%s_%s",
        StageReadKeyPrefix,
        self._ActivityId,
        stageId
    )
end

function XPunishaarModel:GetIsStageRead(stageId)
    local key = self:GetStageReadKey(stageId)
    return self._SaveUtil:GetData(key) or false
end

function XPunishaarModel:SetStageRead(stageId)
    local key = self:GetStageReadKey(stageId)
    self._SaveUtil:SaveData(key, true)
end

--清除关卡红点本地记录
function XPunishaarModel:ClearStageRead(stageId)
    self._SaveUtil:SaveData(
        self:GetStageReadKey(stageId),
        nil
    )
end

local CollectionReadKeyPrefix = "PunishaarCollectionRead_"
function XPunishaarModel:GetCollectionReadKey(catalogType)
    return string.format(
        "%s%s_%s",
        CollectionReadKeyPrefix,
        self._ActivityId,
        catalogType
    )
end

function XPunishaarModel:GetCollectionReadDict(catalogType)
    return self._SaveUtil:GetData(self:GetCollectionReadKey(catalogType)) or {}
end

function XPunishaarModel:SaveCollectionReadDict(catalogType, readDict)
    self._SaveUtil:SaveData(self:GetCollectionReadKey(catalogType), readDict)
end

function XPunishaarModel:IsCollectionCardRead(catalogType, cardId)
    local readDict =
    self:GetCollectionReadDict(catalogType)

    return readDict[cardId] == true
end

function XPunishaarModel:AddCollectionUnlocked(catalogType, cardId)
    local isNew = self._OutSideModel:AddCollectionUnlocked(catalogType, cardId)

    if isNew then
        XEventManager.DispatchEvent(XEventId.EVENT_PUNISHAAR_COLLECTION_RED_POINT_CHANGE)
    end

    return isNew
end
--endregion

--region 倍速偏好本地缓存

local SpeedIndexKey = "PunishaarSpeedIndex"

--- 读倍速档位偏好（未存返 nil，调用方校验回退默认）#68
---@return number|nil
function XPunishaarModel:GetSavedSpeedIndex()
    return self._SaveUtil:GetData(SpeedIndexKey)
end

--- 写倍速档位偏好 #68
---@param idx number 档位索引
function XPunishaarModel:SetSavedSpeedIndex(idx)
    self._SaveUtil:SaveData(SpeedIndexKey, idx)
end

--endregion

--region 自动战斗偏好本地缓存

local AutoModeKey = "PunishaarAutoMode"

--- 读自动战斗偏好（未存返 nil/falsy，调用方判 falsy 即关闭）#Auto
---@return boolean|nil
function XPunishaarModel:GetAutoModeEnabled()
    return self._SaveUtil:GetData(AutoModeKey)
end

--- 写自动战斗偏好 #Auto
---@param enabled boolean
function XPunishaarModel:SetAutoModeEnabled(enabled)
    self._SaveUtil:SaveData(AutoModeKey, enabled and true or false)
end

--endregion

--region ----------private start----------

--region 协议数据
function XPunishaarModel:OnNotifyPunishaarLoginData(data)
    self._ActivityId = data.ActivityId

    self._OutSideModel:InitLoginData(
        data.SaveStageIds,
        data.PassStageIds,
        data.CharacterCardCatalogsDict,
        data.PartnerCardCatalogsDict,
        data.EquipCatalogs,
        data.ResonanceCatalogs
    )

    XEventManager.DispatchEvent(XEventId.EVENT_PUNISHAAR_COLLECTION_RED_POINT_CHANGE)
end

--进入玩法获得整个玩法的数据
function XPunishaarModel:InitDataDb(data)
    self._ActivityId = data.ActivityId
    -- 登录/重进时从存档字典重建当前 Stage（CurrentStageId=0 表示无进行中存档）
    local stages = data.StageSaves
    local currentId = data.CurrentStageId
    if currentId and currentId ~= 0 and stages then
        self._CurrentStage = stages[currentId]
    end
    self._OutSideModel:InitDataDb(data)
    XEventManager.DispatchEvent(XEventId.EVENT_PUNISHAAR_COLLECTION_RED_POINT_CHANGE)
end

---endregion 协议数据

--endregion ----------private end----------


return XPunishaarModel