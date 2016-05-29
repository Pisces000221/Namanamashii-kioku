require './http'
JSON = JSON or require('./libs/JSON')
inspect = inspect or require('./libs/inspect')

http.default_referer = 'http://web.kuaipan.cn/n/drive/files'
http.xsrf_token = 'jsPTvIiZ-OKwTu6htxE4dMjgxkqZP-w8cOhM'

local list_file = arg[1] or 'dirlist.csv'
local dir_ct, file_ct, tot_size = 0, 0, 0
local files = {}
function deserialize(record)
    local ret = {}
    record:gsub('([^,]+)', function (s) ret[#ret + 1] = s end)
    return table.unpack(ret)
end
local byte_unit = { ['B'] = 1, ['KB'] = 1<<10, ['MB'] = 1<<20, ['GB'] = 1<<30, ['TB'] = 1<<40 }
function parse_size(s)
    if s == 'DIR' then return s end
    local ret
    s:gsub('(.+) (.+)', function (x, y) ret = tonumber(x) * byte_unit[y] end)
    return ret
end
function format_size(s)
    local num, unit
    if s >= 1<<40 then num, unit = s / (1<<40), 'TB'
    elseif s >= 1<<30 then num, unit = s / (1<<30), 'GB'
    elseif s >= 1<<20 then num, unit = s / (1<<20), 'MB'
    elseif s >= 1<<10 then num, unit = s / (1<<10), 'KB'
    else num, unit = s, 'B' end
    return string.format('%.2f %s', num, unit)
end
function file_info_append(num, id, size, ctime, mtime, path)
    size = parse_size(size)
    local record = {
        path = path, id = id, size = size, ctime = ctime, mtime = mtime,
    }
    files[#files + 1] = record
    if size == 'DIR' then dir_ct = dir_ct + 1
    else file_ct = file_ct + 1; tot_size = tot_size + size end
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
print('Total size is ~' .. format_size(tot_size) .. ' / ' .. math.floor(tot_size) .. ' Bytes'
    .. ' (estimated, actual size may differ a lot')
print('Elapsed time: ' .. tostring(os.clock() - start_time) .. ' second(s)')

start_time = os.time()
print('--------')
print('Starting downloads.')
print('Elapsed time: ' .. tostring(os.time() - start_time) .. ' second(s)')
