---@class XUiMainModel : XModel
local XUiMainModel = XClass(XModel, "XUiMainModel")

-- tableKey{ tableName = {ReadFunc , DirPath, Identifier, TableDefindName, CacheType} }
local TableKey = {
    UiPanelTip = { DirPath = XConfigUtil.DirectoryType.Client, CacheType = XConfigUtil.CacheType.Normal },
    ActivityBtn = { DirPath = XConfigUtil.DirectoryType.Client, CacheType = XConfigUtil.CacheType.Normal },
    ActivityToastHall = { DirPath = XConfigUtil.DirectoryType.Client, CacheType = XConfigUtil.CacheType.Normal },
    ActivityToastHallSkin = { DirPath = XConfigUtil.DirectoryType.Client, CacheType = XConfigUtil.CacheType.Normal },
    ActivityToastHallSceneRule = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "SceneKey", ReadFunc = XConfigUtil.ReadType.String, CacheType = XConfigUtil.CacheType.Normal },
}

local BoardTableKey = {
    BoardEffectActivity = { CacheType = XConfigUtil.CacheType.Normal },
}

-- 活动按钮永久一次性红点用独立 block，设恒定版本号避免随应用版本清（跨版本常驻不二次红点）
-- 不影响实例内其他 _SaveUtil 数据（如 ActivityToastHallLastShowTime 继续走默认版本检查）
local ActivityBtnRedOnceBlockKey = "ActivityBtnRedOnce"

function XUiMainModel:OnInit()
    --初始化内部变量
    --这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析

    --定义TableKey
    self._ConfigUtil:InitConfigByTableKey("UiMain", TableKey)
    self._ConfigUtil:InitConfigByTableKey("BoardEffect", BoardTableKey)

    -- 活动按钮永久一次性红点 block 设恒定版本号，使该 block 永不随应用版本清
    -- 不调实例级 SetVersionCheckEnable(false)，避免污染其他默认 block 数据
    self._SaveUtil:SetCustomVersionGetFunc(handler(self, self.GetActivityBtnRedOnceVersion), ActivityBtnRedOnceBlockKey)

    self.BoardEffectData = false
    --新手任务合集ActivityBtn配置Id
    self:_InitNewPlayerTaskCollection()
end

function XUiMainModel:ClearPrivate()
end

function XUiMainModel:ResetAll()
    --这里执行重登数据清理
    self.BoardEffectData = false
end

----------public start----------

---@return table<number, XTableUiPanelTip>
function XUiMainModel:GetUiPanelTip()
    return self._ConfigUtil:GetByTableKey(TableKey.UiPanelTip)
end

---@return XTableActivityBtn[]
function XUiMainModel:GetActivityBtn()
    return self._ConfigUtil:GetByTableKey(TableKey.ActivityBtn)
end

---@return XTableActivityBtn
function XUiMainModel:GetActivityBtnConfigById(id)
    if not XTool.IsNumberValid(id) then
        return
    end

    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.ActivityBtn, id)
end

--region 活动按钮永久一次性红点

--- 活动按钮永久一次性红点 block 的版本号：恒定，使该 block 永不随应用版本清
function XUiMainModel:GetActivityBtnRedOnceVersion()
    return 1
end

--- 生成活动按钮永久一次性红点的存档 key（字符串）
--- 【分层】此方法是唯一知道 key 组成的地方；下层 Save/Is/条件类只透明接收 key 不问结构
--- 其他系统复用永久一次性红点模式时，仿此方法用自己的字段组 key，存取接口不变
--- 含 Id/TimeId/SkipId 三字段，不含 Name：
--- 跨版本复用 Id 给新活动时，TimeId/SkipId 不同 → key 不同 → 新活动正常显示红点；
--- 同一活动跨版本常驻时，三字段稳定 → key 稳定 → 不被清缓存、无二次红点
--- 字符串拼接零碰撞（hash 才有碰撞）；key 在 grid Init 时生成一次并缓存，Check 热路径复用，无 GC 顾虑
---@param activityBtnConfig XTableActivityBtn
---@return string
function XUiMainModel:GetActivityBtnIdentityKey(activityBtnConfig)
    local id = activityBtnConfig.Id or 0
    local timeId = activityBtnConfig.TimeId or 0
    local skipId = activityBtnConfig.SkipId or 0
    return string.format("%s_%s_%s", id, timeId, skipId)
end

--- 记录活动按钮永久一次性红点已点击
---@param key string 身份key（组成由 GetActivityBtnIdentityKey 封装，此处不问）
function XUiMainModel:SaveActivityBtnRedOnceClicked(key)
    self._SaveUtil:SaveDataByBlockKey(ActivityBtnRedOnceBlockKey, key, true)
end

--- 活动按钮永久一次性红点是否已点击过
---@param key string 身份key
---@return boolean
function XUiMainModel:IsActivityBtnRedOnceClicked(key)
    return self._SaveUtil:GetDataByBlockKey(ActivityBtnRedOnceBlockKey, key) == true
end

--endregion

---@return table<number, XTableActivityToastHall>
function XUiMainModel:GetActivityToastHallCfgs()
    return self._ConfigUtil:GetByTableKey(TableKey.ActivityToastHall) or {}
end

---@return XTableActivityToastHall
function XUiMainModel:GetActivityToastHallCfgById(id)
    if not XTool.IsNumberValid(id) then
        return
    end

    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.ActivityToastHall, id, true)
end

---@return XTableActivityToastHallSkin
function XUiMainModel:GetActivityToastHallSkinCfgById(id)
    if not XTool.IsNumberValid(id) then
        return
    end

    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.ActivityToastHallSkin, id, true)
end

---@return XTableActivityToastHallSceneRule
function XUiMainModel:GetActivityToastHallSceneRuleCfg(sceneKey)
    if string.IsNilOrEmpty(sceneKey) then
        return
    end

    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.ActivityToastHallSceneRule, sceneKey, true)
end

---@return table<string, XTableActivityToastHallSceneRule>
function XUiMainModel:GetActivityToastHallSceneRuleCfgs()
    return self._ConfigUtil:GetByTableKey(TableKey.ActivityToastHallSceneRule) or {}
end

function XUiMainModel:GetActivityToastHallDefaultSceneKey()
    local cfgs = self:GetActivityToastHallSceneRuleCfgs()
    if XTool.IsTableEmpty(cfgs) then
        return
    end

    local defaultSceneKey
    for _, cfg in pairs(cfgs) do
        local sceneKey = cfg.SceneKey
        if not string.IsNilOrEmpty(sceneKey) and (not defaultSceneKey or sceneKey < defaultSceneKey) then
            defaultSceneKey = sceneKey
        end
    end

    return defaultSceneKey
end

function XUiMainModel:SetActivityToastHallLastShowTime(id, time)
    self._SaveUtil:SaveData("ActivityToastHallLastShowTime_" .. tostring(id), time)
end

function XUiMainModel:GetActivityToastHallLastShowTime(id)
    return self._SaveUtil:GetData("ActivityToastHallLastShowTime_" .. tostring(id)) or 0
end

function XUiMainModel:GetNewPlayerTaskCollection()
    return self._NewPlayerTaskCollection
end

--region BoardEffect

function XUiMainModel:UpdateBoardEffectData(data)
    if not data then
        self.BoardEffectData = false
        return
    end
    self.BoardEffectData = data
end

function XUiMainModel:UpdateLastTriggerTime(time)
    if not self.BoardEffectData then
        return
    end
    self.BoardEffectData.LastTriggerTime = time or 0
end

function XUiMainModel:GetBoardEffectActivityId()
    if not self.BoardEffectData then
        return 0
    end
    return self.BoardEffectData.ActivityId or 0
end

function XUiMainModel:GetBoardEffectLastTriggerTime()
    if not self.BoardEffectData then
        return 0
    end
    return self.BoardEffectData.LastTriggerTime or 0
end

---@return XTableBoardEffectActivity
function XUiMainModel:GetBoardEffectActivityById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(BoardTableKey.BoardEffectActivity, id)
end

-- 获取TriggerProbability
function XUiMainModel:GetBoardEffectTriggerProbability()
    local activity = self:GetBoardEffectActivityById(self:GetBoardEffectActivityId())
    return activity and activity.TriggerProbability or 0
end

-- 获取TriggerCd
function XUiMainModel:GetBoardEffectTriggerCd()
    local activity = self:GetBoardEffectActivityById(self:GetBoardEffectActivityId())
    return activity and activity.TriggerCd or 0
end

-- 获取EffectRootNames
function XUiMainModel:GetBoardEffectEffectRootNames()
    local activity = self:GetBoardEffectActivityById(self:GetBoardEffectActivityId())
    return activity and activity.EffectRootNames or {}
end

-- 获取EffectPaths
function XUiMainModel:GetBoardEffectEffectPaths()
    local activity = self:GetBoardEffectActivityById(self:GetBoardEffectActivityId())
    return activity and activity.EffectPaths or {}
end

-- 获取EffectTimes
function XUiMainModel:GetBoardEffectEffectTimes()
    local activity = self:GetBoardEffectActivityById(self:GetBoardEffectActivityId())
    return activity and activity.EffectTimes or {}
end

--endregion

----------public end----------

----------private start----------

function XUiMainModel:_InitNewPlayerTaskCollection()
    self._NewPlayerTaskCollection = {}
    local activityBtnData = string.Split(CS.XGame.ClientConfig:GetString("NewPlayerTaskCollectionActivityBtnIds"), "|")
    if XTool.IsTableEmpty(activityBtnData) then
        return
    end

    for _, activityBtnDataStr in ipairs(activityBtnData) do
        local strSplitArr = string.Split(activityBtnDataStr, "#")
        local activityBtnId = tonumber(strSplitArr[1])
        local bestRewardId = tonumber(strSplitArr[2])
        if XTool.IsNumberValid(activityBtnId) then
            table.insert(self._NewPlayerTaskCollection, { ActivityBtnId = activityBtnId, BestRewardId = bestRewardId })
        end
    end
end

----------private end----------

----------config start----------


----------config end----------


return XUiMainModel
