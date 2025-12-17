local import = CS.XLuaEngine.Import
local XCrossVersionRequire = {}

function XCrossVersionRequire.RequireAlways()
    require("XCrossVersion/XUtilities/XCUiHelper")
end

function XCrossVersionRequire.Require()
    import("XCrossVersion")
end

return XCrossVersionRequire