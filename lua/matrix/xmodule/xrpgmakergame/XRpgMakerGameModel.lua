local tableInsert = table.insert

---@class XRpgMakerGameModel : XModel
---@field _Config XRpgMakerGameConfig
---@field StageId number 当前关卡Id
---@field MapId number 当前地图Id
---@field SelectRoleId number 当前选中角色Id
local XRpgMakerGameModel = XClass(XModel, "XRpgMakerGameModel")
function XRpgMakerGameModel:OnInit()
    --初始化内部变量
    --这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析
    self._Config = require("XModule/XRpgMakerGame/XRpgMakerGameConfig").New(self._ConfigUtil)
end

-- 退出玩法清理内部数据
function XRpgMakerGameModel:ClearPrivate()
    self._Config:ClearPrivate()
end

-- 重登清理数据
function XRpgMakerGameModel:ResetAll()
    self._Config:ResetAll()
end

---@return XRpgMakerGameConfig
function XRpgMakerGameModel:GetConfig()
    return self._Config
end

-- 进入关卡
function XRpgMakerGameModel:OnEnterStage(enterStageResponse)
    self.StageId = enterStageResponse.StageId
    self.MapId = enterStageResponse.MapId
    self.SelectRoleId = enterStageResponse.SelectRoleId
    self.Actions = enterStageResponse.Actions
end

--region 玩法进度
---获取单期玩法所有的星星数和当前已获得的星星数量
---@param chapterGroupId number 单期章节组Id
---@return number 星星总数
---@return number 当前已获得的星星数量
function XRpgMakerGameModel:GetChapterGroupStarCount(chapterGroupId)
    local allStarCnt = 0 -- 星星总数
    local curStarCnt = 0 -- 当前已获得星星数量
    
    -- 记录章节Id
    local chapterIdDic = {}
    local chapterConfigs = self:GetConfig():GetConfigChapter()
    for _, chapterConfig in pairs(chapterConfigs) do
        if chapterConfig.GroupId == chapterGroupId then
            chapterIdDic[chapterConfig.Id] = true
        end
    end
    
    -- 记录关卡Id
    local stageIdDic = {}
    local stageConfigs = self:GetConfig():GetConfigStage()
    for _, stageConfig in pairs(stageConfigs) do
        if chapterIdDic[stageConfig.ChapterId] == true then
            stageIdDic[stageConfig.Id] = true
        end
    end
    
    -- 收集成就
    local starConfigs = self:GetConfig():GetConfigStarCondition()
    for _, starConfig in pairs(starConfigs) do
        if stageIdDic[starConfig.StageId] == true then
            allStarCnt = allStarCnt + 1
            local stageDb = XDataCenter.RpgMakerGameManager.GetRpgMakerActivityStageDb(starConfig.StageId)
            if stageDb and stageDb:IsStarConditionClear(starConfig.Id) then
                curStarCnt = curStarCnt + 1
            end
        end
    end
    return allStarCnt, curStarCnt
end
--endregion

--region 引导
-- 设置当前关卡Id
function XRpgMakerGameModel:SetCurrentStageId(stageId)
    self.CurrentStageId = stageId
end

-- 获取当前关卡Id
function XRpgMakerGameModel:GetCurrentStageId()
    return self.CurrentStageId
end
--endregion

return XRpgMakerGameModel
