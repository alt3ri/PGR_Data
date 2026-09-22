---Control 部分类：配置查询转发层
---配置表统一由 Agency 注册（见 XTransfiniteTowerAgencyConfig），此处仅转发，
---保持方法名/签名不变，Control 主体与 UI 继续用 self:GetXxxCfg。
---@type XTransfiniteTowerControl
local XTransfiniteTowerControl = XClassPartial("XTransfiniteTowerControl")

function XTransfiniteTowerControl:InitConfig()
    -- 配置表由 Agency 注册，Control 无需注册
end

--region Get 封装（转发 Agency）

---@return XTableTransfiniteTowerActivity
function XTransfiniteTowerControl:GetActivityCfg(activityId)
    return self:GetAgency():GetActivityCfg(activityId)
end

---@return XTableTransfiniteTowerChapter
function XTransfiniteTowerControl:GetChapterCfg(chapterId)
    return self:GetAgency():GetChapterCfg(chapterId)
end

---@return XTableTransfiniteTowerStage
function XTransfiniteTowerControl:GetStageCfg(stageCfgId)
    return self:GetAgency():GetStageCfg(stageCfgId)
end

---@return XTableTransfiniteTowerCharacter
function XTransfiniteTowerControl:GetCharacterCfg(characterCfgId)
    return self:GetAgency():GetCharacterCfg(characterCfgId)
end

---@return XTableTransfiniteTowerCharacterGroup
function XTransfiniteTowerControl:GetCharacterGroupCfg(characterGroupId)
    return self:GetAgency():GetCharacterGroupCfg(characterGroupId)
end

---@return XTableTransfiniteTowerFightCount
function XTransfiniteTowerControl:GetFightCountCfg(fightCount)
    return self:GetAgency():GetFightCountCfg(fightCount)
end

---通用配置项（按 Key 取，Values 为字符串数组）
---@return XTableTransfiniteTowerConfig
function XTransfiniteTowerControl:GetConfigByKey(key)
    return self:GetAgency():GetConfigByKey(key)
end

--endregion

--region 列表查询 helper（转发 Agency）

---按 StageGroupId 取该组所有 Stage 配置，按 Order 升序返回
---@return XTableTransfiniteTowerStage[]
function XTransfiniteTowerControl:GetStagesByGroupId(stageGroupId)
    return self:GetAgency():GetStagesByGroupId(stageGroupId)
end

---取当前 Stage 的下一层 Stage（同组 Order+1）；无下一层返回 nil
---@return XTableTransfiniteTowerStage
function XTransfiniteTowerControl:GetNextStageCfg(stageCfgId)
    return self:GetAgency():GetNextStageCfg(stageCfgId)
end

---取当前 Stage 所属 Chapter（反查 Chapter.StageGroupId）
---@return XTableTransfiniteTowerChapter
function XTransfiniteTowerControl:GetChapterByStageGroupId(stageGroupId)
    return self:GetAgency():GetChapterByStageGroupId(stageGroupId)
end

---取当前 Stage 所属 Chapter 的 Id（stageCfgId → StageGroupId → 反查 Chapter）
---@return number
function XTransfiniteTowerControl:GetChapterIdByStageCfg(stageCfgId)
    return self:GetAgency():GetChapterIdByStageCfg(stageCfgId)
end

---取所有领航员 Character 配置（Type==2），按 Id 升序
---@return XTableTransfiniteTowerCharacter[]
function XTransfiniteTowerControl:GetLeaderCharacterCfgList()
    return self:GetAgency():GetLeaderCharacterCfgList()
end

---战斗关卡id（Stage.StageId）→ 本模块关卡配置
---@return XTableTransfiniteTowerStage
function XTransfiniteTowerControl:GetStageCfgByBattleStageId(battleStageId)
    return self:GetAgency():GetStageCfgByBattleStageId(battleStageId)
end

--endregion

return XTransfiniteTowerControl
