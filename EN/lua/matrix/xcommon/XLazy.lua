--[[
================================================================================
    XLazy —— 惰性求值
--------------------------------------------------------------------------------
    XLazy 的核心思想:
        1. 创建一个空的 "代理表 (proxy)", 把"原始数据"和"转换规则"暂存到
            以双下划线开头的内部字段 (__Ref / __Data / __Convertor 等);
        2. 给该 proxy 设置带有 __index / __newindex / __pairs / __len 等
            元方法的 metatable;
        3. 仅当外部第一次"访问"该 proxy (读字段 / 写字段 / 迭代 / 取长度)
            时, 才真正执行转换, 并把结果写回 proxy 自身;
        4. 转换完成后会清掉 metatable, 之后访问就是普通 table, 没有额外
            开销 —— 即"只算一次, 之后免费".

    主要能力分组:
        a) 容器形态转换 (List <-> Map):
            XLazy.ToMap / ToMapWithCustomPairs / ToKeyList / ToValueList
        b) 数据筛选 / 分类 / 自定义构建:
            XLazy.ToSelector / ToClassifier / ToBuilder
        c) 复合惰性转换器 (一次性配置多步流水线):
            XLazy.ToLazyer + ApplyLazyerSelector / Classifier / Pre / Post
        d) 复合构造器 (按多个 Output 同时构造目标):
            XLazy.ToConstructor + ApplyConstructorOutput / Pre / Post
        e) 访问器 (只在第一次使用时去取真实数据源):
            XLazy.Accessor / AccessorReadOnly
        f) 工具函数:
            XLazy.ForEach / FromData / ToMap*FromData / ToKeyListFromData ...

    常见调用约定 (回调签名):
        customPairs(value)                -> key, value
        conditional(key, value)           -> isSuccess(boolean), key, value
        classificatory(key, value)        -> type(any|nil), key, value
        convertor(key, value)             -> key, value
        output(key, value, target)        -> 无返回值
        output(key, value, builder, source, id, target)  -> 无返回值 (Constructor 形态)
        preprocessor(data)                -> 无返回值 (在转换前调用)
        postprocessor(target)             -> 无返回值 (在转换后调用)

    注意事项:
        - 所有 proxy 在"首次访问"后会清掉自己的内部缓存字段, 因此调用方不要依赖这些字段在访问后仍然存在.
        - selector / classifier 中的"value 为 nil"表示按"数组追加方式"写入, 否则按"哈希方式"写入 (key->value).
================================================================================
]]

---@class XLazy 惰性求值工具集
local XLazy = {}

--- 把 list 形态的数据"惰性"地转换为 map.
--- 行为: 遍历 list, 用 customPairs(value) 得到 (key, value), 写入 target.
--- customPairs 缺省时, 直接以 value 为 key, 用固定的 true 作为 value.
---@param target      table                           最终承载结果的目标 table (proxy 自身)
---@param list        table                           待转换的原始 list
---@param customPairs fun(value: any): any, any | nil 自定义键值映射
---@return integer count 实际写入的键值对数量
local function ConvertToMap(target, list, customPairs)
    local count = 0

    if customPairs == nil then
        customPairs = function (value)
            return value, true
        end
    end

    for _, listValue in pairs(list) do
        local key, value = customPairs(listValue)

        count = count + 1
        rawset(target, key, value)
    end
    setmetatable(target, nil)

    return count
end

--- 把 map 形态的数据"惰性"地转换为 list.
--- 行为: 遍历 map, isKey = true 时把 key 写入数组, 否则把 value 写入数组.
---@param target table   最终承载结果的目标 table (proxy 自身)
---@param map    table   原始 map
---@param isKey  boolean 是否取 key (true) 还是取 value (false)
---@return integer count 实际写入的元素数量
local function ConvertToList(target, map, isKey)
    local count = 0

    for key, value in pairs(map) do
        local arrayAt = key

        if not isKey then
            arrayAt = value
        end

        count = count + 1
        rawset(target, count, arrayAt)
    end
    setmetatable(target, nil)

    return count
end

--- 按 classificatory 把 data 分类到 target 的不同子表中.
--- classificatory(key, value) -> type, newKey, newValue:
---     type 为 nil 表示丢弃该项;
---     newValue 为 nil 时, 表示该 type 下按"数组形式"追加 newKey;
---     否则按"哈希形式" classification[newKey] = newValue.
---@param target         table 最终承载结果的目标 table (proxy 自身)
---@param data           table 原始数据
---@param classificatory fun(key: any, value: any): any, any, any
---@return integer count 实际处理的项数
local function ClassifyTo(target, data, classificatory)
    local count = 0

    for key, value in pairs(data) do
        local type = nil

        type, key, value = classificatory(key, value)

        if type ~= nil then
            local classification = rawget(target, type)

            count = count + 1

            if value == nil then
                value = key
                key = count
            end

            if classification then
                rawset(classification, key, value)
            else
                rawset(target, type, {
                    [key] = value
                })
            end
        end
    end
    setmetatable(target, nil)

    return count
end

--- 按 conditional 过滤 data 写入 target.
--- conditional(key, value) -> isSuccess, newKey, newValue:
---     isSuccess = false 表示丢弃;
---     newValue=nil 时按"数组追加"方式写入 (key 自动取 count);
---     否则按"哈希方式" target[newKey] = newValue.
---@param target      table 最终承载结果的目标 table (proxy 自身)
---@param data        table 原始数据
---@param conditional fun(key: any, value: any): boolean, any, any
---@return integer count 实际通过筛选的项数
local function SelectTo(target, data, conditional)
    local count = 0

    for key, value in pairs(data) do
        local isSuccess = false

        isSuccess, key, value = conditional(key, value)

        if isSuccess then
            count = count + 1

            if value == nil then
                value = key
                key = count
            end

            rawset(target, key, value)
        end
    end
    setmetatable(target, nil)

    return count
end

--- 把 source 的每一项 (key, value) 通过 output 回调输出到 target.
--- output(key, value, target) 自行决定如何写入 target.
--- 调用前会清掉 target 的 metatable, 因此再次访问 target 不会再触发惰性求值.
---@param target table 目标 table (proxy 自身)
---@param source table 原始数据
---@param output fun(key: any, value: any, target: table)
---@return integer count 处理过的项数
local function BuildTo(target, source, output)
    local count = 0

    setmetatable(target, nil)
    for key, value in pairs(source) do
        count = count + 1
        output(key, value, target)
    end

    return count
end

--- 在 Lazyer 流水线中, 把单个 (key, value) 项分发到所有挂载的 selectors.
--- 每个 selector 内有 __Conditional 回调, 通过则按"数组/哈希"形式写入 selector 自身.
---@param key       any
---@param value     any
---@param selectors table[] 挂载在 lazyer 上的 selector 列表
local function SelectorsTo(key, value, selectors)
    if not XTool.IsTableEmpty(selectors) then
        for _, selector in pairs(selectors) do
            local isSuccess = false
            local conditional = rawget(selector, "__Conditional")

            isSuccess, key, value = conditional(key, value)

            if isSuccess then
                if value == nil then
                    rawset(selector, rawlen(selector) + 1, key)
                else
                    rawset(selector, key, value)
                end
            end
        end
    end
end

--- 在 Lazyer 流水线中, 把单个 (key, value) 项分发到所有挂载的 classifiers.
--- 每个 classifier 内有 __Classificatory 回调, 用其返回的 type 在 classifier 中分桶.
---@param key         any
---@param value       any
---@param classifiers table[] 挂载在 lazyer 上的 classifier 列表
local function ClassifiersTo(key, value, classifiers)
    if not XTool.IsTableEmpty(classifiers) then
        for _, classifier in pairs(classifiers) do
            local type = nil
            local classificatory = rawget(classifier, "__Classificatory")

            type, key, value = classificatory(key, value)

            if type ~= nil then
                local classification = rawget(classifier, type)

                if classification then
                    if value == nil then
                        rawset(classification, rawlen(classification) + 1, key)
                    else
                        rawset(classification, key, value)
                    end
                else
                    if value == nil then
                        rawset(classifier, type, { key })
                    else
                        rawset(classifier, type, {
                            [key] = value
                        })
                    end
                end
            end
        end
    end
end

--- 在 Constructor 流水线中, 用所有 builder 的 __Output 把 source 投影到 target.
--- 每个 builder 会拿到 (key, value, builder, source, id, target).
---@param source   table   原始数据源
---@param builders table[] 挂载在 constructor 上的 builder 列表
---@param target   table   目标 table
local function BuildersTo(source, builders, target)
    if not XTool.IsTableEmpty(builders) then
        for _, builder in pairs(builders) do
            local output = rawget(builder, "__Output")
            local id = rawget(builder, "__Id")

            for key, value in pairs(source) do
                output(key, value, builder, source, id, target)
            end
        end
    end
end

--- Lazyer (复合惰性转换器) 的实际执行函数.
--- 整体流程:
---     1. 执行所有 preprocessors(data);
---     2. 用 convertor(key, value) 把 data 转换并写入 target (value 为 nil 时按数组追加);
---     3. 清除 target 的 metatable, 之后访问就是普通 table;
---     4. 执行所有 postprocessors(target);
---     5. 重新遍历 target, 把每一项分发给挂载的 selectors / classifiers;
---     6. 清理 selector / classifier 中的内部字段, 取消其 metatable, 让它们也变成普通 table.
---@param target         table 作为结果承载的 proxy
---@param data           table 原始数据
---@param convertor      fun(k: any, v: any): any, any
---@param selectors      table[] | nil
---@param classifiers    table[] | nil
---@param preprocessors  fun(data: table)[] | nil
---@param postprocessors fun(target: table)[] | nil
---@return integer count target 中实际写入的项数
local function LazyTo(target, data, convertor, selectors, classifiers, preprocessors, postprocessors)
    local count = 0

    if not XTool.IsTableEmpty(preprocessors) then
        for _, preprocessor in pairs(preprocessors) do
            preprocessor(data)
        end
    end

    for key, value in pairs(data) do
        key, value = convertor(key, value)

        count = count + 1

        if value == nil then
            value = key
            key = count
        end

        rawset(target, key, value)
    end

    setmetatable(target, nil)

    if not XTool.IsTableEmpty(postprocessors) then
        for _, postprocessor in pairs(postprocessors) do
            postprocessor(target)
        end
    end

    for key, value in pairs(target) do
        SelectorsTo(key, value, selectors)
        ClassifiersTo(key, value, classifiers)
    end

    if not XTool.IsTableEmpty(selectors) then
        for _, selector in pairs(selectors) do
            rawset(selector, "__Lazyer", nil)
            rawset(selector, "__Conditional", nil)

            setmetatable(selector, nil)
        end
    end
    if not XTool.IsTableEmpty(classifiers) then
        for _, classifier in pairs(classifiers) do
            rawset(classifier, "__Lazyer", nil)
            rawset(classifier, "__Classificatory", nil)

            setmetatable(classifier, nil)
        end
    end

    return count
end

--- Constructor (复合构造器) 的实际执行函数.
--- 整体流程:
---     1. 先执行所有 preprocessors(source);
---     2. 把每个 builder 的 metatable 解开, 让其变成普通 table (避免 BuildersTo 内部访问 builder 字段时再次触发惰性求值);
---     3. 通过所有 builder 的 __Output 把 source 投影到 target;
---     4. 对每个 builder 取出其 __Id 后清理内部字段, 再依次执行 postprocessor(builder, id).
---@param target         table 目标 table
---@param source         table 原始数据
---@param builders       table[] | nil
---@param preprocessors  fun(source: table)[] | nil
---@param postprocessors fun(builder: table, id: any)[] | nil
---@return table target 与入参同一个对象, 便于链式调用
local function ConstructTo(target, source, builders, preprocessors, postprocessors)
    if not XTool.IsTableEmpty(preprocessors) then
        for _, preprocessor in pairs(preprocessors) do
            preprocessor(source)
        end
    end

    for _, builder in pairs(builders) do
        setmetatable(builder, nil)
    end

    BuildersTo(source, builders, target)

    if not XTool.IsTableEmpty(builders) then
        local isPostprocessorsEmpty = XTool.IsTableEmpty(postprocessors)

        for _, builder in ipairs(builders) do
            local id = rawget(builder, "__Id")

            rawset(builder, "__Id", nil)
            rawset(builder, "__Constructor", nil)
            rawset(builder, "__Output", nil)
            rawset(builder, "__Priority", nil)

            if not isPostprocessorsEmpty then
                for _, postprocessor in pairs(postprocessors) do
                    postprocessor(builder, id)
                end
            end
        end
    end

    return target
end

--- "List -> Map" 模式的元表. 任意访问 (读/写/迭代/取长度) 都会触发一次 ConvertToMap.
local lazyToMapMate = {
    __index = function (target, key)
        local ref = rawget(target, "__Ref")
        local customPairs = rawget(target, "__CustomPairs")

        if ref ~= nil then
            rawset(target, "__Ref", nil)
        end
        if customPairs ~= nil then
            rawset(target, "__CustomPairs", nil)
        end

        ConvertToMap(target, ref, customPairs)

        return rawget(target, key)
    end,
    __newindex = function (target, key, value)
        local ref = rawget(target, "__Ref")
        local customPairs = rawget(target, "__CustomPairs")

        if ref ~= nil then
            rawset(target, "__Ref", nil)
        end
        if customPairs ~= nil then
            rawset(target, "__CustomPairs", nil)
        end

        ConvertToMap(target, ref, customPairs)

        rawset(target, key, value)
    end,
    __pairs = function (target)
        local ref = rawget(target, "__Ref")
        local customPairs = rawget(target, "__CustomPairs")

        if ref ~= nil then
            rawset(target, "__Ref", nil)
        end
        if customPairs ~= nil then
            rawset(target, "__CustomPairs", nil)
        end

        ConvertToMap(target, ref, customPairs)

        return pairs(target)
    end,
    __len = function (target)
        local ref = rawget(target, "__Ref")
        local customPairs = rawget(target, "__CustomPairs")

        if ref ~= nil then
            rawset(target, "__Ref", nil)
        end
        if customPairs ~= nil then
            rawset(target, "__CustomPairs", nil)
        end

        return ConvertToMap(target, ref, customPairs)
    end
}

--- "Map -> List" 模式的元表. 触发一次 ConvertToList, isKey 决定取 key 还是取 value.
local lazyToListMate = {
    __index = function (target, key)
        local ref = rawget(target, "__Ref")
        local isKey = rawget(target, "__IsKey")

        if ref ~= nil then
            rawset(target, "__Ref", nil)
        end
        if isKey ~= nil then
            rawset(target, "__IsKey", nil)
        end

        ConvertToList(target, ref, isKey)

        return rawget(target, key)
    end,
    __newindex = function (target, key, value)
        local ref = rawget(target, "__Ref")
        local isKey = rawget(target, "__IsKey")

        if ref ~= nil then
            rawset(target, "__Ref", nil)
        end
        if isKey ~= nil then
            rawset(target, "__IsKey", nil)
        end

        ConvertToList(target, ref, isKey)

        rawset(target, key, value)
    end,
    __pairs = function (target)
        local ref = rawget(target, "__Ref")
        local isKey = rawget(target, "__IsKey")

        if ref ~= nil then
            rawset(target, "__Ref", nil)
        end
        if isKey ~= nil then
            rawset(target, "__IsKey", nil)
        end

        ConvertToList(target, ref, isKey)

        return pairs(target)
    end,
    __len = function (target)
        local ref = rawget(target, "__Ref")
        local isKey = rawget(target, "__IsKey")

        if ref ~= nil then
            rawset(target, "__Ref", nil)
        end
        if isKey ~= nil then
            rawset(target, "__IsKey", nil)
        end

        return ConvertToList(target, ref, isKey)
    end
}

--- "Selector (筛选)" 模式的元表. 触发一次 SelectTo, 用 conditional 过滤数据.
local lazyToSelectMate = {
    __index = function (target, key)
        local data = rawget(target, "__Data")
        local conditional = rawget(target, "__Conditional")

        if data ~= nil then
            rawset(target, "__Data", nil)
        end
        if conditional ~= nil then
            rawset(target, "__Conditional", nil)
        end

        SelectTo(target, data, conditional)

        return rawget(target, key)
    end,
    __newindex = function (target, key, value)
        local data = rawget(target, "__Data")
        local conditional = rawget(target, "__Conditional")

        if data ~= nil then
            rawset(target, "__Data", nil)
        end
        if conditional ~= nil then
            rawset(target, "__Conditional", nil)
        end

        SelectTo(target, data, conditional)

        rawset(target, key, value)
    end,
    __pairs = function (target)
        local data = rawget(target, "__Data")
        local conditional = rawget(target, "__Conditional")

        if data ~= nil then
            rawset(target, "__Data", nil)
        end
        if conditional ~= nil then
            rawset(target, "__Conditional", nil)
        end

        SelectTo(target, data, conditional)

        return pairs(target)
    end,
    __len = function (target)
        local data = rawget(target, "__Data")
        local conditional = rawget(target, "__Conditional")

        if data ~= nil then
            rawset(target, "__Data", nil)
        end
        if conditional ~= nil then
            rawset(target, "__Conditional", nil)
        end

        return SelectTo(target, data, conditional)
    end
}

--- "Classifier (分类)" 模式的元表. 触发一次 ClassifyTo, 用 classificatory 把数据分桶.
local lazyToClassifyMate = {
    __index = function (target, key)
        local data = rawget(target, "__Data")
        local classificatory = rawget(target, "__Classificatory")

        if data ~= nil then
            rawset(target, "__Data", nil)
        end
        if classificatory ~= nil then
            rawset(target, "__Classificatory", nil)
        end

        ClassifyTo(target, data, classificatory)

        return rawget(target, key)
    end,
    __newindex = function (target, key, value)
        local data = rawget(target, "__Data")
        local classificatory = rawget(target, "__Classificatory")

        if data ~= nil then
            rawset(target, "__Data", nil)
        end
        if classificatory ~= nil then
            rawset(target, "__Classificatory", nil)
        end

        ClassifyTo(target, data, classificatory)

        rawset(target, key, value)
    end,
    __pairs = function (target)
        local data = rawget(target, "__Data")
        local classificatory = rawget(target, "__Classificatory")

        if data ~= nil then
            rawset(target, "__Data", nil)
        end
        if classificatory ~= nil then
            rawset(target, "__Classificatory", nil)
        end

        ClassifyTo(target, data, classificatory)

        return pairs(target)
    end,
    __len = function (target)
        local data = rawget(target, "__Data")
        local classificatory = rawget(target, "__Classificatory")

        if data ~= nil then
            rawset(target, "__Data", nil)
        end
        if classificatory ~= nil then
            rawset(target, "__Classificatory", nil)
        end

        return ClassifyTo(target, data, classificatory)
    end
}

--- "Builder (自定义构建)" 模式的元表. 触发一次 BuildTo, 用 output 自由地写入目标.
local lazyToBuildMate = {
    __index = function (target, key)
        local source = rawget(target, "__Source")
        local output = rawget(target, "__Output")

        if source ~= nil then
            rawset(target, "__Source", nil)
        end
        if output ~= nil then
            rawset(target, "__Output", nil)
        end

        BuildTo(target, source, output)

        return rawget(target, key)
    end,
    __newindex = function (target, key, value)
        local source = rawget(target, "__Source")
        local output = rawget(target, "__Output")

        if source ~= nil then
            rawset(target, "__Source", nil)
        end
        if output ~= nil then
            rawset(target, "__Output", nil)
        end

        BuildTo(target, source, output)

        rawset(target, key, value)
    end,
    __pairs = function (target)
        local source = rawget(target, "__Source")
        local output = rawget(target, "__Output")

        if source ~= nil then
            rawset(target, "__Source", nil)
        end
        if output ~= nil then
            rawset(target, "__Output", nil)
        end

        BuildTo(target, source, output)

        return pairs(target)
    end,
    __len = function (target)
        local source = rawget(target, "__Source")
        local output = rawget(target, "__Output")

        if source ~= nil then
            rawset(target, "__Source", nil)
        end
        if output ~= nil then
            rawset(target, "__Output", nil)
        end

        BuildTo(target, source, output)

        return rawlen(target)
    end
}

--- "Lazyer (复合惰性转换器)" 的元表. 触发一次 LazyTo, 内部会按顺序执行
--- preprocessor -> convertor -> postprocessor -> selectors/classifiers 分发.
local lazyerMate = {
    __index = function (target, key)
        local data = rawget(target, "__Data")
        local convertor = rawget(target, "__Convertor")
        local selectors = rawget(target, "__Selectors")
        local classifiers = rawget(target, "__Classifiers")
        local preprocessors = rawget(target, "__Preprocessors")
        local postprocessors = rawget(target, "__Postprocessors")

        if data ~= nil then
            rawset(target, "__Data", nil)
        end
        if convertor ~= nil then
            rawset(target, "__Convertor", nil)
        end
        if selectors ~= nil then
            rawset(target, "__Selectors", nil)
        end
        if classifiers ~= nil then
            rawset(target, "__Classifiers", nil)
        end
        if preprocessors ~= nil then
            rawset(target, "__Preprocessors", nil)
        end
        if postprocessors ~= nil then
            rawset(target, "__Postprocessors", nil)
        end

        LazyTo(target, data, convertor, selectors, classifiers, preprocessors, postprocessors)

        return rawget(target, key)
    end,
    __newindex = function (target, key, value)
        local data = rawget(target, "__Data")
        local convertor = rawget(target, "__Convertor")
        local selectors = rawget(target, "__Selectors")
        local classifiers = rawget(target, "__Classifiers")
        local preprocessors = rawget(target, "__Preprocessors")
        local postprocessors = rawget(target, "__Postprocessors")

        if data ~= nil then
            rawset(target, "__Data", nil)
        end
        if convertor ~= nil then
            rawset(target, "__Convertor", nil)
        end
        if selectors ~= nil then
            rawset(target, "__Selectors", nil)
        end
        if classifiers ~= nil then
            rawset(target, "__Classifiers", nil)
        end
        if preprocessors ~= nil then
            rawset(target, "__Preprocessors", nil)
        end
        if postprocessors ~= nil then
            rawset(target, "__Postprocessors", nil)
        end

        LazyTo(target, data, convertor, selectors, classifiers, preprocessors, postprocessors)

        rawset(target, key, value)
    end,
    __pairs = function (target)
        local data = rawget(target, "__Data")
        local convertor = rawget(target, "__Convertor")
        local selectors = rawget(target, "__Selectors")
        local classifiers = rawget(target, "__Classifiers")
        local preprocessors = rawget(target, "__Preprocessors")
        local postprocessors = rawget(target, "__Postprocessors")

        if data ~= nil then
            rawset(target, "__Data", nil)
        end
        if convertor ~= nil then
            rawset(target, "__Convertor", nil)
        end
        if selectors ~= nil then
            rawset(target, "__Selectors", nil)
        end
        if classifiers ~= nil then
            rawset(target, "__Classifiers", nil)
        end
        if preprocessors ~= nil then
            rawset(target, "__Preprocessors", nil)
        end
        if postprocessors ~= nil then
            rawset(target, "__Postprocessors", nil)
        end

        LazyTo(target, data, convertor, selectors, classifiers, preprocessors, postprocessors)

        return pairs(target)
    end,
    __len = function (target)
        local data = rawget(target, "__Data")
        local convertor = rawget(target, "__Convertor")
        local selectors = rawget(target, "__Selectors")
        local classifiers = rawget(target, "__Classifiers")
        local preprocessors = rawget(target, "__Preprocessors")
        local postprocessors = rawget(target, "__Postprocessors")

        if data ~= nil then
            rawset(target, "__Data", nil)
        end
        if convertor ~= nil then
            rawset(target, "__Convertor", nil)
        end
        if selectors ~= nil then
            rawset(target, "__Selectors", nil)
        end
        if classifiers ~= nil then
            rawset(target, "__Classifiers", nil)
        end
        if preprocessors ~= nil then
            rawset(target, "__Preprocessors", nil)
        end
        if postprocessors ~= nil then
            rawset(target, "__Postprocessors", nil)
        end

        return LazyTo(target, data, convertor, selectors, classifiers, preprocessors, postprocessors)
    end
}

--- 作为 Lazyer 上挂载的 Selector 的元表.
--- 自身访问时通过 #lazyer 触发 lazyer 的求值, 让数据被分发进来.
local selectorMate = {
    __index = function (target, key)
        local lazyer = rawget(target, "__Lazyer")
        local _ = #lazyer

        return rawget(target, key)
    end,
    __newindex = function (target, key, value)
        local lazyer = rawget(target, "__Lazyer")
        local _ = #lazyer

        rawset(target, key, value)
    end,
    __pairs = function (target)
        local lazyer = rawget(target, "__Lazyer")
        local _ = #lazyer

        return pairs(target)
    end,
    __len = function (target)
        local lazyer = rawget(target, "__Lazyer")
        local _ = #lazyer

        return rawlen(target)
    end
}

--- 作为 Lazyer 上挂载的 Classifier 的元表. 与 selectorMate 行为对称.
local classifierMate = {
    __index = function (target, key)
        local lazyer = rawget(target, "__Lazyer")
        local _ = #lazyer

        return rawget(target, key)
    end,
    __newindex = function (target, key, value)
        local lazyer = rawget(target, "__Lazyer")
        local _ = #lazyer

        rawset(target, key, value)
    end,
    __pairs = function (target)
        local lazyer = rawget(target, "__Lazyer")
        local _ = #lazyer

        return pairs(target)
    end,
    __len = function (target)
        local lazyer = rawget(target, "__Lazyer")
        local _ = #lazyer

        return rawlen(target)
    end
}

--- 已"激活"的 Accessor 的元表: 直接代理到 __Source 上读写.
local accessMate = {
    __index = function (target, key)
        local source = rawget(target, "__Source")

        return source and source[key] or nil
    end,
    __newindex = function (target, key, value)
        local source = rawget(target, "__Source")

        if source then
            source[key] = value
        end
    end,
    __pairs = function (target)
        local source = rawget(target, "__Source")

        return pairs(source)
    end,
    __len = function (target)
        local source = rawget(target, "__Source")

        return #source
    end
}

--- 已"激活"的只读 Accessor 的元表: 读时代理到 __Source, 写时报错.
local accessReadOnlyMate = {
    __index = function (target, key)
        local source = rawget(target, "__Source")

        return source and source[key] or nil
    end,
    __newindex = function (target, key, value)
        XLog.Error("[XLazy] It's a ReadOnly Accessor, Can't Write!")
    end,
    __pairs = function (target)
        local source = rawget(target, "__Source")

        return pairs(source)
    end,
    __len = function (target)
        local source = rawget(target, "__Source")

        return #source
    end
}

--- "未激活"的可读写 Accessor 的元表: 首次访问时调用 __Access() 取真实数据源,
--- 然后切换到 accessMate, 后续访问就是普通的读写代理.
local accessorMate = {
    __index = function (target, key)
        local access = rawget(target, "__Access")
        local source = access()

        rawset(target, "__Source", source)
        rawset(target, "__Access", nil)

        setmetatable(target, accessMate)

        return source and source[key] or nil
    end,
    __newindex = function (target, key, value)
        local access = rawget(target, "__Access")
        local source = access()

        rawset(target, "__Source", source)
        rawset(target, "__Access", nil)

        setmetatable(target, accessMate)

        source[key] = value
    end,
    __pairs = function (target)
        local access = rawget(target, "__Access")
        local source = access()

        rawset(target, "__Source", source)
        rawset(target, "__Access", nil)

        setmetatable(target, accessMate)

        return pairs(source)
    end,
    __len = function (target)
        local access = rawget(target, "__Access")
        local source = access()

        rawset(target, "__Source", source)
        rawset(target, "__Access", nil)

        setmetatable(target, accessMate)

        return #source
    end
}

--- "未激活"的只读 Accessor 的元表: 首次读时调用 __Access() 取真实数据源, 然后
--- 切换到 accessReadOnlyMate; 写入会触发 XLog.Error 报错.
local accessorReadOnlyMate = {
    __index = function (target, key)
        local access = rawget(target, "__Access")
        local source = access()

        rawset(target, "__Source", source)
        rawset(target, "__Access", nil)

        setmetatable(target, accessReadOnlyMate)

        return source and source[key] or nil
    end,
    __newindex = function (target, key, value)
        XLog.Error("[XLazy] It's a ReadOnly Accessor, Can't Write!")
    end,
    __pairs = function (target)
        local access = rawget(target, "__Access")
        local source = access()

        rawset(target, "__Source", source)
        rawset(target, "__Access", nil)

        setmetatable(target, accessReadOnlyMate)

        return pairs(source)
    end,
    __len = function (target)
        local access = rawget(target, "__Access")
        local source = access()

        rawset(target, "__Source", source)
        rawset(target, "__Access", nil)

        setmetatable(target, accessReadOnlyMate)

        return #source
    end
}

--- 已经构造完成的 Constructor 的"占位"元表: 再次以函数形式调用直接返回自身,
--- 避免重复构造.
local constructMate = {
    __call = function (target)
        return target
    end
}

--- "未激活"的 Constructor 的元表: 第一次以函数形式调用 (constructor()) 时, 把
--- source / builders / preprocessors / postprocessors 取出来, 切换到 constructMate,
--- 然后执行 ConstructTo 得到结果.
local constructorMate = {
    __call = function (target)
        local source = rawget(target, "__Source")
        local builders = rawget(target, "__Builders")
        local preprocessors = rawget(target, "__Preprocessors")
        local postprocessors = rawget(target, "__Postprocessors")

        if source ~= nil then
            rawset(target, "__Source", nil)
        end
        if builders ~= nil then
            rawset(target, "__Builders", nil)
        end
        if preprocessors ~= nil then
            rawset(target, "__Preprocessors", nil)
        end
        if postprocessors ~= nil then
            rawset(target, "__Postprocessors", nil)
        end

        setmetatable(target, constructMate)

        return ConstructTo(target, source, builders, preprocessors, postprocessors)
    end
}

--- 挂载在 Constructor 上的 Builder 的元表. 任意访问都会去调用一次 __Constructor()
--- (即触发 constructor 求值), 这样 builder 就能拿到该次构造产生的字段.
local builderMate = {
    __index = function (target, key)
        local constructor = rawget(target, "__Constructor")
        local _ = constructor()

        return rawget(target, key)
    end,
    __newindex = function (target, key, value)
        local constructor = rawget(target, "__Constructor")
        local _ = constructor()

        rawset(target, key, value)
    end,
    __pairs = function (target)
        local constructor = rawget(target, "__Constructor")
        local _ = constructor()

        return pairs(target)
    end,
    __len = function (target)
        local constructor = rawget(target, "__Constructor")
        local _ = constructor()

        return rawlen(target)
    end
}

--- 把 list 惰性转换为 map. 缺省把 list 中每个 value 作为 key, 用 mapValue 作为
--- 对应的 value (默认为 true). 适合做"集合判定": result[x] 为 true 说明 x 在集合中.
--- list 为 nil 时直接返回空表 (非惰性).
---@param list     table | nil
---@param mapValue any | nil 缺省 true
---@return table
function XLazy.ToMap(list, mapValue)
    if not list then
        return {}
    end
    if mapValue == nil then
        mapValue = true
    end

    local proxy = {
        __Ref = list,
        __CustomPairs = function (value)
            return value, mapValue
        end
    }

    return setmetatable(proxy, lazyToMapMate)
end

--- 把 list 惰性转换为 map, 由调用方完全自定义 (key, value) 映射函数.
---@param list        table
---@param customPairs fun(value: any): any, any
---@return table
function XLazy.ToMapWithCustomPairs(list, customPairs)
    local proxy = { __Ref = list, __CustomPairs = customPairs }

    return setmetatable(proxy, lazyToMapMate)
end

--- 把 map 惰性转换为只含 key 的 list.
---@param map table
---@return table
function XLazy.ToKeyList(map)
    local proxy = { __Ref = map, __IsKey = true }

    return setmetatable(proxy, lazyToListMate)
end

--- 把 map 惰性转换为只含 value 的 list.
---@param map table
---@return table
function XLazy.ToValueList(map)
    local proxy = { __Ref = map, __IsKey = false }

    return setmetatable(proxy, lazyToListMate)
end

--- 创建一个"按条件筛选"的惰性结果. conditional 返回 (isSuccess, key, value).
---@param data        table
---@param conditional fun(key: any, value: any): boolean, any, any
---@return table
function XLazy.ToSelector(data, conditional)
    local proxy = { __Data = data, __Conditional = conditional }

    return setmetatable(proxy, lazyToSelectMate)
end

--- 创建一个"按规则分类"的惰性结果. classificatory 返回 (type, key, value).
---@param data           table
---@param classificatory fun(key: any, value: any): any, any, any
---@return table
function XLazy.ToClassifier(data, classificatory)
    local proxy = { __Data = data, __Classificatory = classificatory }

    return setmetatable(proxy, lazyToClassifyMate)
end

--- 创建一个"按 output 自由构建"的惰性结果. 每次访问触发一次完整 BuildTo.
---@param source table
---@param output fun(key: any, value: any, target: table)
---@return table
function XLazy.ToBuilder(source, output)
    local proxy = { __Source = source, __Output = output }

    return setmetatable(proxy, lazyToBuildMate)
end

--- 创建一个 Lazyer (复合惰性转换器). 之后可以通过 ApplyLazyer* 系列函数挂载
--- selector / classifier / preprocessor / postprocessor, 任意访问 lazyer 时
--- 才会一次性地执行整条流水线.
---@param data      table
---@param convertor fun(key: any, value: any): any, any
---@return table
function XLazy.ToLazyer(data, convertor)
    local proxy = { __Data = data, __Convertor = convertor }

    return setmetatable(proxy, lazyerMate)
end

--- 在 lazyer 上挂载一个 Selector. lazyer 求值后, 通过 conditional 的项会被
--- 写入返回的 selector. lazyer 为空或没有 __Data 时直接返回 nil.
---@param lazyer      table
---@param conditional fun(key: any, value: any): boolean, any, any
---@return table | nil
function XLazy.ApplyLazyerSelector(lazyer, conditional)
    if not lazyer then
        return
    end

    local data = rawget(lazyer, "__Data")

    if not data then
        return
    end

    local selector = { __Conditional = conditional, __Lazyer = lazyer }
    local applySelectors = rawget(lazyer, "__Selectors")

    if not applySelectors then
        rawset(lazyer, "__Selectors", {
            selector
        })
    else
        table.insert(applySelectors, selector)
    end

    return setmetatable(selector, selectorMate)
end

--- 在 lazyer 上挂载一个 Classifier. 行为与 Selector 类似, 但按 type 分桶.
---@param lazyer         table
---@param classificatory fun(key: any, value: any): any, any, any
---@return table | nil
function XLazy.ApplyLazyerClassifier(lazyer, classificatory)
    if not lazyer then
        return
    end

    local data = rawget(lazyer, "__Data")

    if not data then
        return
    end

    local classifier = { __Classificatory = classificatory, __Lazyer = lazyer }
    local applyClassifiers = rawget(lazyer, "__Classifiers")

    if not applyClassifiers then
        rawset(lazyer, "__Classifiers", {
            classifier
        })
    else
        table.insert(applyClassifiers, classifier)
    end

    return setmetatable(classifier, classifierMate)
end

--- 给 lazyer 挂载一个前置处理器. lazyer 求值前会遍历执行 preprocessor(data).
--- 若 lazyer 不可用, 静默返回.
---@param lazyer       table
---@param preprocessor fun(data: table)
function XLazy.ApplyLazyerPreprocessor(lazyer, preprocessor)
    if not lazyer then
        return
    end

    local data = rawget(lazyer, "__Data")

    if not data then
        return
    end

    local applyPreprocessors = rawget(lazyer, "__Preprocessors")

    if not applyPreprocessors then
        rawset(lazyer, "__Preprocessors", {
            preprocessor
        })
    else
        table.insert(applyPreprocessors, preprocessor)
    end
end

--- 给 lazyer 挂载一个后置处理器. lazyer 求值完成 (target 已写入) 后会执行 postprocessor(target).
---@param lazyer        table
---@param postprocessor fun(target: table)
function XLazy.ApplyLazyerPostprocessor(lazyer, postprocessor)
    if not lazyer then
        return
    end

    local data = rawget(lazyer, "__Data")

    if not data then
        return
    end

    local applyPostprocessors = rawget(lazyer, "__Postprocessors")

    if not applyPostprocessors then
        rawset(lazyer, "__Postprocessors", {
            postprocessor
        })
    else
        table.insert(applyPostprocessors, postprocessor)
    end
end

--- 创建一个 (可读写) Accessor. 第一次访问时会调用 access() 获取真实数据源,
--- 之后所有读写都会被代理到该数据源.
---@param access fun(): table 返回真实数据源的回调
---@return table
function XLazy.Accessor(access)
    local proxy = { __Access = access }

    return setmetatable(proxy, accessorMate)
end

--- 创建一个只读 Accessor. 写入时会调用 XLog.Error 报错并丢弃.
---@param access fun(): table 返回真实数据源的回调
---@return table
function XLazy.AccessorReadOnly(access)
    local proxy = { __Access = access }

    return setmetatable(proxy, accessorReadOnlyMate)
end

--- 返回一个无参函数, 调用它会用 pairs 遍历 data, 对每一项执行 iterator(key,value).
--- 当 iterator 返回 truthy 时立刻中断, 类似 break.
---@param data     table
---@param iterator fun(key: any, value: any): boolean | nil
---@return fun()
function XLazy.ForEach(data, iterator)
    local forEach = function ()
        for key, value in pairs(data) do
            if iterator(key, value) then
                break
            end
        end
    end

    return forEach
end

--- 创建一个 Constructor. 它本身是一个可"以函数形式调用"的 proxy:
---     constructor()  -> 触发一次 ConstructTo, 返回 constructor 自身.
--- 配合 ApplyConstructorOutput / Pre / Postprocessor 一起使用.
---@param data table 原始数据
---@return table
function XLazy.ToConstructor(data)
    local proxy = { __Source = data }

    return setmetatable(proxy, constructorMate)
end

--- 给 constructor 挂载一个 Output (Builder).
--- 行为细节:
---   - 每个 builder 内会保存 __Output / __Constructor / __Id / __Priority;
---   - 当指定了 priority 时, 会按"升序"插入到 __Builders 中 (找到第一个比自己大的位置插入);
---   - 当指定了 id 时, 会同时把该 builder 保存在 constructor[id] 中, 便于通过名字访问.
--- constructor 不可用时直接返回 nil.
---@param constructor table
---@param output      fun(key: any, value: any, builder: table, source: table, id: any, target: table)
---@param id          any | nil
---@param priority    number | nil
---@return table | nil
function XLazy.ApplyConstructorOutput(constructor, output, id, priority)
    if not constructor then
        return
    end

    local source = rawget(constructor, "__Source")

    if not source then
        return
    end

    local builder = { __Output = output, __Constructor = constructor, __Id = id, __Priority = priority }
    local applyBuilders = rawget(constructor, "__Builders")

    if not applyBuilders then
        rawset(constructor, "__Builders", {
            builder
        })
    else
        if priority then
            local isInsert = false

            for index, applyBuilder in ipairs(applyBuilders) do
                local applyPriority = rawget(applyBuilder, "__Priority") or 0

                if applyPriority < priority then
                    isInsert = true
                    table.insert(applyBuilders, index, builder)
                    break
                end
            end
            if not isInsert then
                table.insert(applyBuilders, builder)
            end
        else
            table.insert(applyBuilders, builder)
        end
    end

    if id ~= nil then
        rawset(constructor, id, builder)
    end

    return setmetatable(builder, builderMate)
end

--- 给 constructor 挂载前置处理器, ConstructTo 在遍历 builders 之前会顺序执行
--- preprocessor(source).
---@param constructor  table
---@param preprocessor fun(source: table)
function XLazy.ApplyConstructorPreprocessor(constructor, preprocessor)
    if not constructor then
        return
    end

    local source = rawget(constructor, "__Source")

    if not source then
        return
    end

    local applyPreprocessors = rawget(constructor, "__Preprocessors")

    if not applyPreprocessors then
        rawset(constructor, "__Preprocessors", {
            preprocessor
        })
    else
        table.insert(applyPreprocessors, preprocessor)
    end
end

--- 给 constructor 挂载后置处理器. constructor 求值完成 (target 已写入) 后会执行 postprocessor(target).
---@param constructor   table
---@param postprocessor fun(builder: table, id: any)
function XLazy.ApplyConstructorPostprocessor(constructor, postprocessor)
    if not constructor then
        return
    end

    local source = rawget(constructor, "__Source")

    if not source then
        return
    end

    local applyPostprocessors = rawget(constructor, "__Postprocessors")

    if not applyPostprocessors then
        rawset(constructor, "__Postprocessors", {
            postprocessor
        })
    else
        table.insert(applyPostprocessors, postprocessor)
    end
end

--- 通用辅助: 把 data[field] (若存在) 替换为 lazy(data[field], ...) 的结果.
--- 常用于把表中某个字段"原地替换"为惰性结构. 不存在该字段时不做任何修改.
---@param data  table
---@param field any
---@param lazy  fun(target: any, ...: any): any
---@return table data 同入参, 便于链式调用
function XLazy.FromData(data, field, lazy, ...)
    local target = data[field]

    if target then
        data[field] = lazy(target, ...)
    end

    return data
end

--- FromData + ToMapWithCustomPairs 的快捷方式.
---@param data        table
---@param field       any
---@param customPairs fun(value: any): any, any
---@return table data
function XLazy.ToMapCustomPairsFromData(data, field, customPairs)
    return XLazy.FromData(data, field, XLazy.ToMapWithCustomPairs, customPairs)
end

--- FromData + ToMap 的快捷方式.
---@param data     table
---@param field    any
---@param mapValue any | nil
---@return table data
function XLazy.ToMapFromData(data, field, mapValue)
    return XLazy.FromData(data, field, XLazy.ToMap, mapValue)
end

--- FromData + ToKeyList 的快捷方式.
---@param data  table
---@param field any
---@return table data
function XLazy.ToKeyListFromData(data, field)
    return XLazy.FromData(data, field, XLazy.ToKeyList)
end

--- FromData + ToValueList 的快捷方式.
---@param data  table
---@param field any
---@return table data
function XLazy.ToValueListFromData(data, field)
    return XLazy.FromData(data, field, XLazy.ToValueList)
end

return XLazy
