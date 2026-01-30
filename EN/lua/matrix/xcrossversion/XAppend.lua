local XAppend = {}

local XCEventId = require("XCrossVersion/XAppendList/XCEventId")
local XCUiRegistry = require("XCrossVersion/XAppendList/XCUiRegistry")
local XCRedPointConditions = require("XCrossVersion/XAppendList/XCRedPointConditions")

local function AppendEventId()
    for k, v in pairs(XCEventId) do
        XEventId[k] = v
    end
end

local function AppendUiRegistry()
    local UiRegistry = require("UiRegistry")
    for k, v in pairs(XCUiRegistry) do
        UiRegistry[k] = v
    end
end

local function AppendRedPointConditions()
    for k, v in pairs(XCRedPointConditions) do
        XRedPointConditions.Conditions[k] = v
    end
end

function XAppend.Execute()
    -- 顺序非常重要
    AppendUiRegistry()
    AppendEventId()
    -- AppendModuleId()
    -- AppendUIBindControl()
    AppendRedPointConditions()
end

return XAppend