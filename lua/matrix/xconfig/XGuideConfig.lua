XGuideConfig = XGuideConfig or {}

local TABLE_GUIDE_COMPLETE_PATH = "Share/Guide/GuideComplete.tab"
local TABLE_GUIDE_STEP_PATH = "Share/Guide/GuideStep.tab"
local TABLE_GUIDE_GROUP_PATH = "Share/Guide/GuideGroup.tab"
local TABLE_GUIDE_FIGHT_PATH = "Share/Guide/GuideFight.tab"
local TABLE_GUIDE_ICON_PATH = "Client/Guide/GuideIcon.tab"
local TABLE_GUIDE_TEXT_PATH = "Client/Guide/GuideText.tab"

-- 配置相关
local GuideCompleteTemplates = {}
local GuideStepTemplates = {}
local GuideGroupTemplates = {}
local GuideFightTemplates = {}
---@type table<number, XTableGuideIcon>
local GuideIconTemplates = {}
---@type table<number, XTableGuideText>
local GuideTextTemplates = {}

function XGuideConfig.Init()
    GuideCompleteTemplates = XTableManager.ReadByIntKey(TABLE_GUIDE_COMPLETE_PATH, XTable.XTableGuideComplete, "Id")
    GuideStepTemplates = XTableManager.ReadByIntKey(TABLE_GUIDE_STEP_PATH, XTable.XTableGuideStep, "Id")
    GuideGroupTemplates = XTableManager.ReadByIntKey(TABLE_GUIDE_GROUP_PATH, XTable.XTableGuideGroup, "Id")
    GuideFightTemplates = XTableManager.ReadByIntKey(TABLE_GUIDE_FIGHT_PATH, XTable.XTableGuideFight, "Id")
    GuideIconTemplates = XTableManager.ReadByIntKey(TABLE_GUIDE_ICON_PATH, XTable.XTableGuideIcon, "Id")
    GuideTextTemplates = XTableManager.ReadByIntKey(TABLE_GUIDE_TEXT_PATH, XTable.XTableGuideText, "Id")

    if XMain.IsWindowsEditor then
        -- 开发环境下检查配置表数据完整性
        for _, temp in pairs(GuideGroupTemplates) do
            local completeTemp = GuideCompleteTemplates[temp.CompleteId]
            if (not completeTemp) then
                XLog.ErrorTableDataNotFound("XGuideConfig.Init", "GuideComplete", TABLE_GUIDE_COMPLETE_PATH, "Id", tostring(temp.CompleteId))
            end

            -- for i, stepId in ipairs(temp.StepIds) do
            --     local stepTemp = GuideStepTemplates[stepId]
            --     if (not stepTemp) then
            --         XLog.Error("InitGuideGroupConfig error: can not found step template, step id is " .. stepId .. ", group id is " .. temp.Id)
            --     end
            -- end
        end
    end
end

function XGuideConfig.GetGuideCompleteTemplates()
    return GuideCompleteTemplates
end

function XGuideConfig.GetGuideCompleteTemplatesById(id)
    if not GuideCompleteTemplates then
        return
    end

    return GuideCompleteTemplates[id]
end


function XGuideConfig.GetGuideStepTemplates()
    return GuideStepTemplates
end

function XGuideConfig.GetGuideStepTemplatesById(id)
    if not GuideStepTemplates then
        return
    end

    return GuideStepTemplates[id]
end

function XGuideConfig.GetGuideGroupTemplates()
    return GuideGroupTemplates
end

function XGuideConfig.GetGuideGroupTemplatesById(id)
    if not GuideGroupTemplates then
        return
    end

    return GuideGroupTemplates[id]
end

function XGuideConfig.GetGuideFightTemplates()
    return GuideFightTemplates
end


function XGuideConfig.GetGuideFightTemplatesById(id)
    if not GuideFightTemplates then
        return
    end

    return GuideFightTemplates[id]
end

---@return string
function XGuideConfig.GetGuideIcon(iconId)
    local t = GuideIconTemplates[iconId]
    if not t then
        XLog.Error("引导头像不存在，Id = ", iconId)
        return
    end
    return t.Image
end

---@return XTableGuideText
function XGuideConfig.GetGuideTextTemplate(textId)
    local t = GuideTextTemplates[textId]
    if not t then
        XLog.Error("引导文本配置不存在，文本Id = ", textId)
        return
    end
    return t
end 