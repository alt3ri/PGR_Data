XCrossVersionManagerCreator = function()

    local XCrossVersionManager = {}

    local Enabled = false

    local XAppend = require("XCrossVersion/XAppend")
    local XCrossVersionRequire = require("XCrossVersion/XCrossVersionRequire")

    local function LoadConfig()
        Enabled = CS.XGame.ClientConfig:GetInt("CrossVersionEnable") == 1
        -- 调试
        -- Enabled = true
    end

    function XCrossVersionManager.Init()
        LoadConfig()
    end

    function XCrossVersionManager.GetEnable()
        return Enabled
    end

    function XCrossVersionManager:LoadRequire()
        if not Enabled then
            XCrossVersionRequire.RequireAlways()
            return
        end
        XAppend.Execute()
        XCrossVersionRequire.Require()
        XStrongholdConfigs.InitCrossVersion()
    end

    XCrossVersionManager.Init()
    return XCrossVersionManager
end