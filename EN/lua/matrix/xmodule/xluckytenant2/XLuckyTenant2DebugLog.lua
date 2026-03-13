---调试日志工具
local XLuckyTenant2DebugLog = {}

-- 从 Unity 获取日志文件路径（Client 工程根目录下的 Log 文件夹）
local function GetLogFilePath()
    if CS and CS.UnityEngine and CS.UnityEngine.Application then
        local UnityApplication = CS.UnityEngine.Application
        local UnityRuntimePlatform = CS.UnityEngine.RuntimePlatform
        local logDir
        
        -- 判断平台类型
        if UnityApplication.platform == UnityRuntimePlatform.WindowsEditor or
           UnityApplication.platform == UnityRuntimePlatform.OSXEditor or
           UnityApplication.platform == UnityRuntimePlatform.LinuxEditor then
            -- 编辑器模式：Application.dataPath 指向 Assets 文件夹
            -- 路径：Assets -> Client -> Log
            logDir = UnityApplication.dataPath .. "/../Log"
        elseif UnityApplication.platform == UnityRuntimePlatform.WindowsPlayer or
               UnityApplication.platform == UnityRuntimePlatform.OSXPlayer or
               UnityApplication.platform == UnityRuntimePlatform.LinuxPlayer then
            -- Win/Standalone 包：Application.dataPath 指向 Application_Data 文件夹
            -- 路径：Application_Data -> exe所在目录 -> Log
            -- 例如：F:\haru\Product\Bin\Client\Win\Debug\Application_Data -> F:\haru\Product\Bin\Client\Win\Debug\Log
            logDir = UnityApplication.dataPath .. "/../Log"
        else
            -- 其他平台（Android/iOS等）：使用 persistentDataPath
            logDir = UnityApplication.persistentDataPath .. "/Log"
        end
        
        local logFilePath = logDir .. "/LogLuckytenant2.txt"
        return logFilePath
    end
    -- 降级方案：如果无法获取 Unity 路径，使用当前目录
    return "LogLuckytenant2.txt"
end

local LogFilePath = GetLogFilePath()

---写入日志到文件
---@param message string 日志消息
local function WriteLog(message)
    if not message then
        return
    end
    
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    local logLine = string.format("[%s] %s\n", timestamp, tostring(message))
    
    -- 尝试使用 C# IO 方法写入文件
    local success, err = pcall(function()
        if CS and CS.System and CS.System.IO then
            local IO = CS.System.IO
            
            -- 确保目录存在
            local directoryPath = LogFilePath:match("^(.+)\\[^\\]+$")
            if directoryPath and not IO.Directory.Exists(directoryPath) then
                IO.Directory.CreateDirectory(directoryPath)
            end
            
            -- 追加写入文件
            IO.File.AppendAllText(LogFilePath, logLine, CS.System.Text.Encoding.UTF8)
            return true
        end
        return false
    end)
    
    if not success then
        -- 如果 C# 方法失败，尝试使用 io.open
        pcall(function()
            local file = io.open(LogFilePath, "a")
            if file then
                file:write(logLine)
                file:close()
            end
        end)
    end
end

---清空日志文件
function XLuckyTenant2DebugLog.Clear()
    pcall(function()
        if CS and CS.System and CS.System.IO then
            local IO = CS.System.IO
            if IO.File.Exists(LogFilePath) then
                IO.File.Delete(LogFilePath)
            end
        else
            local file = io.open(LogFilePath, "w")
            if file then
                file:close()
            end
        end
    end)
end

---记录日志
---@param message string 日志消息
function XLuckyTenant2DebugLog.Log(message)
    WriteLog(message)
end

---记录格式化日志
---@param format string 格式化字符串
---@param ... any 参数
function XLuckyTenant2DebugLog.LogFormat(format, ...)
    local message = string.format(format, ...)
    WriteLog(message)
end

return XLuckyTenant2DebugLog
