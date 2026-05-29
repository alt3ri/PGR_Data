-- XMipStreamingManager
--
-- 流式纹理（MipMap Streaming）管理器 —— C# CS.XMipSteaming.XMipStreamingMgr 的 Lua 薄封装
--
-- 使用：
--   local XMipStreamingManager = require("XManager/XMipStreamingManager")
--   XMipStreamingManager.EnterBigWorld()    -- 进入空花战斗流程末尾调用（等价 Refresh）
--   XMipStreamingManager.Refresh()          -- 大世界内关卡切换时调用，按当前 IsInFaos 同步开关
--   XMipStreamingManager.ExitBigWorld()     -- 退出空花战斗时强制关闭，防御性兜底

local CSMgr = CS.XMipSteaming.XMipStreamingMgr.Instance

-- 唯一画质档位（预算MB, 最大mip削减级, 最大IO请求数, 每帧Renderer评估数）
local PRESET_LEVEL = 0

local XMipStreamingManager = {}

local _configured = false
local _streamingOpened = false   -- 当前是否已开启，作为幂等开关

local function ShouldOpen()
    -- 仅低端机进入法奥斯场景时启用
    return CS.XHardwareManager.LowMemoryDevice and XMVCA.XBigWorldGamePlay:IsInFaos()
end

local function Open()
    if _streamingOpened then return end
    XLog.Debug("XMipStreamingManager Open")
    if not _configured then
        CSMgr:ConfigurePreset(PRESET_LEVEL, 128, 2, 64, 64)
        _configured = true
    end
    CSMgr:EnableStreaming()
    CSMgr:ApplyQualityPreset(PRESET_LEVEL)
    _streamingOpened = true
end

local function Close()
    if not _streamingOpened then return end
    XLog.Debug("XMipStreamingManager Close")
    CSMgr:DisableStreaming()
    _streamingOpened = false
end

--- 按当前场景同步开关状态。幂等。
function XMipStreamingManager.Refresh()
    if ShouldOpen() then
        Open()
    else
        Close()
    end
end

function XMipStreamingManager.EnterBigWorld()
    XMipStreamingManager.Refresh()
end

function XMipStreamingManager.ExitBigWorld()
    Close()
end

return XMipStreamingManager
