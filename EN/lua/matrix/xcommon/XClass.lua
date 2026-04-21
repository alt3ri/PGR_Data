local getinfo = debug.getinfo
local type = type

local _class = {}
local _classNameDic = nil
local _className2Partial = nil
local _partialClassPath2PartialKey = nil

if XMain.IsEditorDebug then
    _classNameDic = {}
    _className2Partial = {} -- 类名映射分部类路径，用于热重载
    _partialClassPath2PartialKey = {} -- 分部类路径映射分部类自己定义的字段名，用于热重载
end

local _classNameDicForPartial = {}

local function create(class, obj, ...)
    if class.Super then
        create(class.Super, obj, ...)
    end

    if class.Ctor then
        class.Ctor(obj, ...)
    end
end    

function XClass(super, className, setPartial)
    local class

    if XMain.IsEditorDebug then
        local fullClassName = className .. getinfo(2, "S").source
        class = _classNameDic[fullClassName]
        if class then
            -- 热重载重定义时先把之前的定义清空，防止误报重定义
            local vtbl = _class[class]
            
            if vtbl then
                local keyList = {}
                
                for k, v in pairs(vtbl) do
                    if rawget(vtbl, k) ~= nil and k ~= 'Super' then
                        table.insert(keyList, k)
                    end
                end

                for i, k in ipairs(keyList) do
                    rawset(vtbl, k, nil)
                end
            end
            
            -- 热重载重定义时要将分部类的文件给卸载了
            if setPartial then
                local partialClassPaths = _className2Partial[className]

                if not XTool.IsTableEmpty(partialClassPaths) then
                    for path, _ in pairs(partialClassPaths) do
                        package.loaded[path] = nil
                    end
                end
            end
            
            return class
        end

        class = {}
        _classNameDic[fullClassName] = class
    else
        class = {}
    end

    class.Ctor = false
    class.Super = super
    class.New = function(...)
        local obj = {}
        obj.__cname = className
        obj.__class = class --for typeof
        setmetatable(obj, { __index = _class[class] })
        create(class, obj, ...)
        return obj
    end

    local vtbl = {}
    _class[class] = vtbl

    if XMain.IsEditorDebug then
        setmetatable(class, {
            __newindex = function(_, k, v)
                local data = rawget(vtbl, k)
                
                if data ~= nil then 
                    XLog.Error('重复定义字段或方法 className: ' .. tostring(className) .. ' key: ' .. tostring(k))    
                end
                
                vtbl[k] = v
            end,
            __index = function(_, k)
                return vtbl[k]
            end
        })
    else
        setmetatable(class, {
            __newindex = function(_, k, v)
                vtbl[k] = v
            end,
            __index = function(_, k)
                return vtbl[k]
            end
        })
    end


    if super then
        vtbl.Super = super
        if XMain.IsEditorDebug then
            setmetatable(vtbl, {
                __index = function(_, k)
                    local ret = _class[super][k]
                    return ret
                end
            })
        else
            setmetatable(vtbl, {
                __index = function(_, k)
                    local ret = _class[super][k]
                    vtbl[k] = ret
                    return ret
                end
            })
        end
    end
    
    -- 是否设置为分部类
    if setPartial then
        if _classNameDicForPartial[className] == nil then
            _classNameDicForPartial[className] = class
        else
            XLog.Error('设置分部类时遇到重名类：' .. className)
        end
    end

    return class
end

function XClassPartial(className)
    local class = _classNameDicForPartial[className]
    
    if class == nil then
        XLog.Error('定义分部类时，该类未设置为分部类或不存在：' .. className)
    end

    if XMain.IsEditorDebug and class then
        local path = string.gsub(getinfo(2, "S").source, '@', '')

        -- debug环境下分部类的定义多套一层，用于记录分部类定义的key，在热重载时单独清空
        local realCls = {}
        
        local metaUseClass = class

        setmetatable(realCls, {
            __index = function(tab, key)
                return metaUseClass[key]
            end,

            __newindex = function(tab, key, value)
                -- 记录
                local partialKeyList = _partialClassPath2PartialKey[path] or {}

                partialKeyList[key] = true

                _partialClassPath2PartialKey[path] = partialKeyList

                metaUseClass[key] = value
            end
        })

        -- 针对热重载的情况，定义前先清空以往定义的内容
        local partialKeyList = _partialClassPath2PartialKey[path]

        if not XTool.IsTableEmpty(partialKeyList) then
            local vtbl = _class[class]
            
            for key, _ in pairs(partialKeyList) do
                vtbl[key] = nil
            end
        end
        
        -- 返回包了一层的实例
        class = realCls
    end

    return class
end

function XClassPartialRequire(path, className)
    if XMain.IsEditorDebug then
        -- 将该路径与对应的类关联起来，以便热重载时清空
        local partialClassPath = _className2Partial[className] or {}
        
        partialClassPath[path] = true
        
        _className2Partial[className] = partialClassPath
    end
    
    return require(path)
end

function GetClassVirtualTable(class)
    return _class[class]
end

function UpdateClassType(newClass, oldClass)
    if "table" ~= type(newClass) then
        return
    end
    if "table" ~= type(oldClass) then
        return
    end

    if oldClass == newClass then
        return
    end

    local new_vtbl = _class[newClass]
    local old_vtbl = _class[oldClass]
    if not new_vtbl or not old_vtbl then
        return
    end

    _class[oldClass] = new_vtbl
    _class[newClass] = nil
end

-- 检查obj是否从super中继承过来
function CheckClassSuper(obj, super)
    if obj == nil or obj.Super == nil then
        return false
    end
    local checkSuper = obj.Super
    while checkSuper do
        if checkSuper == super then
            return true
        end
        checkSuper = checkSuper.Super
    end
    return false
end

function CheckIsClass(obj)
    -- hack
    return obj.Ctor ~= nil and obj.New ~= nil
end

-- 创建匿名方法类
function CreateAnonClassInstance(funcDic, super, ...)
    local result = super.New(...)
    result.Super = super
    for funcName, func in pairs(funcDic) do
        result[funcName] = func
    end
    return result
end

function become_const(const_table, tipsError)
    function Const(const_table)
        local mt = {
            __index = function(t, k)
                if const_table[k] then
                    return const_table[k]
                elseif tipsError then
                    XLog.Error(string.format("const or enum key = %s is nil", k))
                end
            end,
            __newindex = function(t, k, v)
                XLog.Error("can't set " .. tostring(const_table) .. "." .. tostring(k) .. " to " .. tostring(v))
            end
        }
        return mt
    end

    local t = {}
    setmetatable(t, Const(const_table))
    return t
end

function enum(t, tipsError)
    local ret = {}
    for k, v in pairs(t) do
        ret[k] = v
        ret[v] = k
    end
    ret.dic = t
    return become_const(ret, tipsError)
end