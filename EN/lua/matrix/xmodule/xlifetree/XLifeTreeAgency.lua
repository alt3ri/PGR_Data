---@class XLifeTreeAgency : XAgency
---@field private _Model XLifeTreeModel
local XLifeTreeAgency = XClass(XAgency, "XLifeTreeAgency")


function XLifeTreeAgency:OnInit()
    --初始化一些变量
    self.EnumConst = require("XModule/XLifeTree/XLifeTreeEnumConst")
end

--region rpc
function XLifeTreeAgency:InitRpc()
    --实现服务器事件注册
    XRpc.NotifyLifeTreeData = handler(self, self.NotifyLifeTreeData)
end

function XLifeTreeAgency:NotifyLifeTreeData(data)
    self._Model:RefreshLifeTreeData(data)
end

---@param process number 步骤类型：1完成引导  2完成PV  3章节剧情
---@param processId number 步骤Id
---@param callback function 回调函数
function XLifeTreeAgency:RequestLifeTreeFinishProcess(process, processId, callback)
    XNetwork.Call("LifeTreeFinishProcessRequest", {
        Process = process,
        ProcessId = processId,
    }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        self._Model:RefreshProcessData(res)
        if callback then
            callback(res)
        end
    end)
end


---@param catalogId number
---@param status number
---@param callback function 回调函数
function XLifeTreeAgency:RequestLifeTreeUnlockCharacter(catalogId, status, callback)
    local catalogConfig = self._Model:GetLifeTreeCharacterCatalogConfigById(catalogId)
    local characterId = catalogConfig.CharacterId
    XNetwork.Call("LifeTreeUnlockCharacterRequest", {
        CharacterId = characterId,
        Status = status,
    }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        
        self._Model:RefreshUnlockCharacterData(res.CharacterData)
        if callback then
            callback(res)
        end

        -- 运营埋点
        local dict = {}
        dict["type"] = 4
        dict["character_id"] = characterId
        dict["character_unlock_count"] = status
        CS.XRecord.Record(dict, "1000042", "LifeTreeOperation")
    end)
end
--endregion

--region 配置表
---@return XTableLifeTreeClientConfig
function XLifeTreeAgency:GetLifeTreeClientConfigConfigById(id)
    return self._Model:GetLifeTreeClientConfigConfigById(id)
end

--endregion

--region UI
-- 检查播放引导
function XLifeTreeAgency:CheckPlayGuide()
    -- 玩法未开启
    if not self:IsOpen() then return false end
    -- 引导已完成
    if self._Model:IsFinishGuide() then return false end
    -- 开始引导
    local clientConfig = self._Model:GetLifeTreeClientConfigConfigById("GuideMovieId")
    local movieId = clientConfig.Values[1]
    XDataCenter.MovieManager.PlayMovie(movieId, function()
        XLuaUiManager.Open("UiLifeTreeGuide", function()
            self:OnGuideEnd()
        end)
    end, nil, true)
    return true
end

-- 引导结束
function XLifeTreeAgency:OnGuideEnd()
    self:RequestLifeTreeFinishProcess(XMVCA.XLifeTree.EnumConst.PROCESS_TYPE.GUIDE, nil, function()
        local clientConfig = self._Model:GetLifeTreeClientConfigConfigById("GuideGuideId")
        local guideId = tonumber(clientConfig.Values[1])
        XDataCenter.GuideManager.PlayGuide(guideId)
        XEventManager.DispatchEvent(XEventId.EVENT_LIFE_TREE_GUIDE_END)
    end)
end

local OpenMainUi = function(constellationId)
    -- 如果是指定星座，则打开对应星座图鉴，否则打开主界面。UiLifeTreeCard在点击返回的时候会打开主界面
    if constellationId then
        XLuaUiManager.Open("UiLifeTreeCard", constellationId)
    else
        XLuaUiManager.Open("UiLifeTreeMain")
    end
end

--- 打开主界面Ui
function XLifeTreeAgency:ExOpenMainUi(constellationId)
    if not self:IsOpen(true) then return false end

    -- 跳过CG
    if XLuaVideoManager.GetIsSkipAllCG() then
        OpenMainUi(constellationId)
        return
    end

    local isPlayPv = self._Model:IsFinishPv()
    if not isPlayPv then
        self:RequestLifeTreeFinishProcess(XMVCA.XLifeTree.EnumConst.PROCESS_TYPE.PV)
        local clientConfig = self._Model:GetLifeTreeClientConfigConfigById("VideoIdPV")
        local videoId = clientConfig.Values[1]
        XLuaVideoManager.PlayUiVideo(videoId, function()
            --XLuaUiManager.Open("UiLifeTreeOpen", function()
                OpenMainUi(constellationId)
            --end)
        end, false, true)
    else
        OpenMainUi(constellationId)
    end
end

-- 检测打开生命树章节解锁弹窗
function XLifeTreeAgency:CheckOpenUiLifeTreeChapterUnlock(exhibitionFubenType, exhibitionFubenConfigId)
    -- 屏蔽打脸功能
    if XDataCenter.FunctionEventManager.CheckFuncDisable() then
        return
    end

    -- 玩法未开启
    if not self:IsOpen() then return end
    
    -- 未播放生命树Pv
    if not self._Model:IsFinishPv() then return end

    -- 未配置解锁弹窗
    local exhibitionChapterId = XMVCA.XMainLine2:GetFubenExhibitionId(exhibitionFubenType, exhibitionFubenConfigId)
    local chapterConfigs = self._Model:GetLifeTreeChapterConfigs()
    if not chapterConfigs[exhibitionChapterId] then return end

    -- 已弹过
    if self._Model:IsChapterFinish(exhibitionChapterId) then return end

    -- 对应角色解锁次数>0不用弹
    local chapterConfig = self._Model:GetLifeTreeChapterConfigById(exhibitionChapterId)
    local unlockCount = self._Model:GetCharacterUnlockCountByCatalogId(chapterConfig.CharacterCatalogId)
    if unlockCount > 0 then return end

    -- 打开弹窗
    XLuaUiManager.Open("UiLifeTreeChapterUnlock", exhibitionChapterId, true)
end

-- 检测打开当前版本章节的生命树弹窗
function XLifeTreeAgency:CheckOpenUiLifeTreeChapterUnlockCurVersion()
    -- 屏蔽打脸功能
    if XDataCenter.FunctionEventManager.CheckFuncDisable() then
        return
    end

    -- 玩法未开启
    if not self:IsOpen() then return end
    
    -- 未播放生命树Pv
    if not self._Model:IsFinishPv() then return end
    
    -- 已弹过
    local config = self._Model:GetLifeTreeClientConfigConfigById("CurVersionChapterId")
    local exhibitionChapterId = tonumber(config.Values[1])
    if self._Model:IsChapterFinish(exhibitionChapterId) then return end
    
    -- 对应角色解锁次数>0不用弹
    local chapterConfig = self._Model:GetLifeTreeChapterConfigById(exhibitionChapterId)
    local unlockCount = self._Model:GetCharacterUnlockCountByCatalogId(chapterConfig.CharacterCatalogId)
    if unlockCount > 0 then return end

    -- 打开弹窗
    XLuaUiManager.Open("UiLifeTreeChapterUnlock", exhibitionChapterId, false)
end

-- 检测打开卡牌解锁弹窗
function XLifeTreeAgency:CheckOpenUiLifeTreeCardUnlock(exhibitionFubenType, exhibitionFubenConfigId)
    -- 屏蔽打脸功能
    if XDataCenter.FunctionEventManager.CheckFuncDisable() then
        return
    end

    -- 玩法未开启
    if not self:IsOpen() then return end

    -- 未播放生命树Pv
    if not self._Model:IsFinishPv() then return end
    
    local exhibitionChapterId = XMVCA.XMainLine2:GetFubenExhibitionId(exhibitionFubenType, exhibitionFubenConfigId)

    -- 未配置解锁弹窗，无需弹窗
    local chapterConfigs = self._Model:GetLifeTreeChapterConfigs()
    local chapterConfig = chapterConfigs[exhibitionChapterId]
    if not chapterConfig then return end

    local catalogId = chapterConfig.CharacterCatalogId
    local catalogConfig = self._Model:GetLifeTreeCharacterCatalogConfigById(catalogId)
    local characterId = catalogConfig.CharacterId
    local characterConfig = self._Model:GetLifeTreeCharacterConfigById(characterId)
    local unlockCount = self._Model:GetCharacterUnlockCount(characterId)
    local allUnlockCount = #characterConfig.ConditionIds
    
    -- 解锁完成
    if unlockCount >= allUnlockCount then return end
    
    -- 下一解锁条件
    local nextUnlockIndex = unlockCount + 1
    local conditionId = characterConfig.ConditionIds[nextUnlockIndex]
    local isReach, tips = XConditionManager.CheckCondition(conditionId)
    
    -- 判断是否从未解锁变成已解锁
    local lastConditionIndex = self._Model:GetCacheCharacterConditionIndex(characterId)
    if lastConditionIndex ~= nil and nextUnlockIndex > lastConditionIndex and isReach then
        XLuaUiManager.Open("UiLifeTreeCardUnlock", catalogId, nextUnlockIndex, exhibitionChapterId)
    end
    
    -- 缓存当前解锁下标
    local cacheIndex = isReach and nextUnlockIndex or unlockCount
    self._Model:SetCacheCharacterConditionIndex(characterId, cacheIndex)
end
--endregion

--region 蓝点

---角色是否显示蓝点
---@param catalogId number
---@return boolean 是否显示蓝点
function XLifeTreeAgency:IsRedCharacterByCatalogId(catalogId)
    local unlockCount, state = XMVCA.XLifeTree:GetCharacterStateByCatalogId(catalogId) -- 解锁次数和状态
    if state == XMVCA.XLifeTree.EnumConst.CHARACTER_STATE.NEXT_UNLOCKABLE then
        return true
    end
    return false
end

---角色是否显示蓝点
---@param characterId number
---@return boolean 是否显示蓝点
function XLifeTreeAgency:IsRedCharacter(characterId)
    -- 未播放生命树Pv
    if not self._Model:IsFinishPv() then return end

    -- 非生命树角色
    local charConfigs = self._Model:GetLifeTreeCharacterConfigs()
    if not charConfigs[characterId] then
        return false
    end

    -- 玩家未拥有该角色
    if not XMVCA.XCharacter:IsOwnCharacter(characterId) then
        return false
    end

    local unlockCount, state = XMVCA.XLifeTree:GetCharacterState(characterId) -- 解锁次数和状态
    if state == XMVCA.XLifeTree.EnumConst.CHARACTER_STATE.NEXT_UNLOCKABLE then
        return true
    end
    return false
end

---星座任务是否显示蓝点
---@param constellationId number 星座Id
---@return boolean 是否显示蓝点
function XLifeTreeAgency:IsRedTask(constellationId)
    local taskIds = self._Model:GetTaskIds(constellationId)
    for _, taskId in ipairs(taskIds) do
        if XDataCenter.TaskManager.CheckTaskAchieved(taskId) then
            return true
        end
    end
    return false
end

---星座是否显示蓝点
---@param constellationId number 星座Id
---@return boolean 是否显示蓝点
function XLifeTreeAgency:IsRedConstellation(constellationId)
    if self:IsRedTask(constellationId) then
        return true
    end
    
    local constellationConfig = self._Model:GetLifeTreeConstellationConfigById(constellationId)
    for _, catalogId in ipairs(constellationConfig.CharacterCatalogIds) do
        if self:IsRedCharacterByCatalogId(catalogId) then
            return true
        end
    end
    return false
end

-- 活动是否显示蓝点
function XLifeTreeAgency:IsRed()
    local constellationConfigs = self._Model:GetLifeTreeConstellationConfigs()
    for _, constellationConfig in pairs(constellationConfigs) do
        if self:IsRedConstellation(constellationConfig.Id) then
            return true
        end
    end
    return false
end

--endregion

-- 功能是否开启
function XLifeTreeAgency:IsOpen(isTips)
    -- 提审包屏蔽
    if XUiManager.IsHideFunc then return false end
    -- 玩法是否开启
    local noTips = not isTips
    local isOpen = XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.LifeTree, false, noTips)
    return isOpen
end

-- 是否是生命树角色
function XLifeTreeAgency:IsLifeTreeCharacter(characterId)
    local characterConfigs = self._Model:GetLifeTreeCharacterConfigs()
    return characterConfigs[characterId] ~= nil
end

-- 角色是否解锁对应次数
function XLifeTreeAgency:IsCharacterUnlocked(characterId, unlockCount)
    return self._Model:IsCharacterUnlock(characterId, unlockCount)
end

-- 获取角色状态
---@param catalogId number
---@return number 角色状态
function XLifeTreeAgency:GetCharacterStateByCatalogId(catalogId)
    -- 配置是否上线
    local catalogConfig = self._Model:GetLifeTreeCharacterCatalogConfigById(catalogId)
    local characterId = catalogConfig.CharacterId
    if not XTool.IsNumberValidEx(characterId) then
        return 0, XMVCA.XLifeTree.EnumConst.CHARACTER_STATE.OFFLINE
    end

    -- 判断解锁条件
    local charConfig = self._Model:GetLifeTreeCharacterConfigById(characterId)
    local curUnlockCount = self._Model:GetCharacterUnlockCount(characterId)

    -- 判断下一解锁条件是否达成
    if curUnlockCount < #charConfig.ConditionIds then
        local conditionId = charConfig.ConditionIds[curUnlockCount + 1]
        local isReach, desc = XConditionManager.CheckCondition(conditionId)
        if isReach then
            return curUnlockCount, XMVCA.XLifeTree.EnumConst.CHARACTER_STATE.NEXT_UNLOCKABLE
        end
    end

    return curUnlockCount, XMVCA.XLifeTree.EnumConst.CHARACTER_STATE.NEXT_LOCKED
end

-- 获取角色状态
---@param characterId number
---@return number 角色状态
function XLifeTreeAgency:GetCharacterState(characterId)
    -- 判断解锁条件
    local charConfig = self._Model:GetLifeTreeCharacterConfigById(characterId)
    local curUnlockCount = self._Model:GetCharacterUnlockCount(characterId)

    -- 判断下一解锁条件是否达成
    if curUnlockCount < #charConfig.ConditionIds then
        local conditionId = charConfig.ConditionIds[curUnlockCount + 1]
        local isReach, desc = XConditionManager.CheckCondition(conditionId)
        if isReach then
            return curUnlockCount, XMVCA.XLifeTree.EnumConst.CHARACTER_STATE.NEXT_UNLOCKABLE
        end
    end

    return curUnlockCount, XMVCA.XLifeTree.EnumConst.CHARACTER_STATE.NEXT_LOCKED
end


return XLifeTreeAgency
