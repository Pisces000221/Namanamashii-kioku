require './http'
JSON = JSON or require('./libs/JSON')
inspect = inspect or require('./libs/inspect')

http.default_referer = 'http://web.kuaipan.cn/n/drive/files'
http.xsrf_token = 'jsPTvIiZ-OKwTu6htxE4dMjgxkqZP-w8cOhM'

local list_file = arg[1] or 'dirlist.csv'
local dir_ct, file_ct = 0, 0
local files = {}
function deserialize(record)
    local ret = {}
    record:gsub('([^,]+)', function (s) ret[#ret + 1] = s end)
    return table.unpack(ret)
end
function file_info_append(num, id, size, ctime, mtime, path)
    local record = {
        path = path, id = id, size = size, ctime = ctime, mtime = mtime,
    }
    files[#files + 1] = record
    if size == 'DIR' then dir_ct = dir_ct + 1 else file_ct = file_ct + 1 end
end
function read_file()
    local f = io.open(list_file, 'r')
    local s = f:read()
    while s ~= nil do
        file_info_append(deserialize(s))
        s = f:read()
    end
    f:close()
end

print('The file to read from is [' .. list_file .. '].')
local start_time = os.clock()
read_file()
print(dir_ct .. ' directory(-ies) and ' .. file_ct .. ' file(s) in total. Please confirm.')
print('Elapsed time: ' .. tostring(os.clock() - start_time) .. ' second(s)')

start_time = os.time()
print('--------')
print('Starting downloads.')
print('Elapsed time: ' .. tostring(os.time() - start_time) .. ' second(s)')
