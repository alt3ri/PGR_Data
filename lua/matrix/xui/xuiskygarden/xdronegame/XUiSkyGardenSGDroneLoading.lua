
---@class XUiSkyGardenSGDroneLoading : XBigWorldUi
---@field ImgLoading UnityEngine.UI.RawImage
---@field Desc UnityEngine.UI.Text
---@field TitleText UnityEngine.UI.Text
---@field SpineRoot XUiLoadPrefab
---@field Loading UnityEngine.RectTransform
---@field _Control XSkyGardenDroneGameControl
local XUiSkyGardenSGDroneLoading = XMVCA.XBigWorldUI:Register(nil, "UiSkyGardenSGDroneLoading")


function XUiSkyGardenSGDroneLoading:OnAwake()
    self:_RegisterButtonClicks()
end

function XUiSkyGardenSGDroneLoading:OnStart()
end

function XUiSkyGardenSGDroneLoading:OnEnable()
    self:_RegisterListeners()
    self:_RegisterSchedules()
    self:_RegisterRedPointEvents()
end

function XUiSkyGardenSGDroneLoading:OnDisable()
    self:_RemoveListeners()
    self:_RemoveSchedules()
end

function XUiSkyGardenSGDroneLoading:OnDestroy()
end

function XUiSkyGardenSGDroneLoading:_RegisterButtonClicks()
    --在此处注册按钮事件
end

function XUiSkyGardenSGDroneLoading:_RegisterListeners()
    -- 在此处注册事件监听
end

function XUiSkyGardenSGDroneLoading:_RemoveListeners()
    -- 在此处移除事件监听
end

function XUiSkyGardenSGDroneLoading:_RegisterSchedules()
    -- 在此处注册定时器
end

function XUiSkyGardenSGDroneLoading:_RemoveSchedules()
    -- 在此处移除定时器
end

function XUiSkyGardenSGDroneLoading:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

return XUiSkyGardenSGDroneLoading
