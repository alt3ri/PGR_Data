ReaderPool = ReaderPool or {}

local Reader
if XMain.UseNativePtrReader then
    Reader = require("Binary/PtrReader")
else
    Reader = require("Binary/Reader")
end

local pool = {}

---@return Reader
function ReaderPool.GetReader()
    if #pool <= 0 then
        return Reader.New()
    else
        return table.remove(pool)
    end
end

function ReaderPool.ReleaseReader(reader)
    reader:Close()
    table.insert(pool, reader)
end

function ReaderPool.Clear()
    pool = {}
end