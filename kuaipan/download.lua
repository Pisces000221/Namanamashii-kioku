require './http'
JSON = JSON or require('./libs/JSON')
inspect = inspect or require('./libs/inspect')

http.default_referer = 'http://web.kuaipan.cn/n/drive/files'
http.xsrf_token = 'BW1BHAjD-XHu12Nq96XqSUsnz6qVYwPZZDnE'

local list_file = arg[1] or 'dirlist.csv'
local base_dir = arg[2] or './downloads'

local dirs, files = {}, {}
local tot_size = 0
function deserialize(record)
    local ret = {}
    record:gsub('([^,]+)', function (s)
        if #ret < 6 then ret[#ret + 1] = s
        else ret[6] = ret[6] .. ',' .. s end
    end)
    return table.unpack(ret)
end
local byte_unit = { ['B'] = 1, ['KB'] = 1<<10, ['MB'] = 1<<20, ['GB'] = 1<<30, ['TB'] = 1<<40 }
function parse_size(s)
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
    if size == 'DIR' then
        dirs[#dirs + 1] = {
            path = path, id = id, ctime = ctime, mtime = mtime,
        }
    else
        size = parse_size(size)
        files[#files + 1] = {
            path = path, id = id, size = size, ctime = ctime, mtime = mtime,
        }
        tot_size = tot_size + size
    end
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

function download_one(id, path)
    http.download('http://web.kuaipan.cn/n/s3/getDownload?id=' .. id, base_dir .. path)
end
function cmd_escape(s)
    return s:gsub('%$', '\\$')
end
function prepare_downloads()
    local i
    -- NOTE: Can also be replaced with lfs
    -- But here we just use os.execute for the sake of convenience
    local s = 'mkdir "' .. base_dir .. '"'
    for i = 1, #dirs do
        s = s .. ' "' .. base_dir .. cmd_escape(dirs[i].path) .. '"'
        if i % 100 == 0 then os.execute(s); s = 'mkdir' end
    end
    if s ~= 'mkdir' then os.execute(s) end
end
function start_downloads()
    local i
    local est_size = 0
    for i = 1, #files do
        est_size = est_size + files[i].size
        print(string.format('Downloading: (%d/%d %.2f%% %s) %s',
            i, #files, (est_size / tot_size) * 100, format_size(files[i].size), files[i].path))
        download_one(files[i].id, files[i].path)
    end
end

print('The file to read from is [' .. list_file .. '].')
local start_time = os.clock()
read_file()
print(#dirs .. ' directory(-ies) and ' .. #files .. ' file(s) in total. Please confirm.')
print('Total size is ~' .. format_size(tot_size) .. ' / ' .. math.floor(tot_size) .. ' Bytes'
    .. ' (estimated, actual size may differ a lot')
print('Elapsed time: ' .. tostring(os.clock() - start_time) .. ' second(s)')

start_time = os.time()
print('--------')
print('Starting downloads.')
prepare_downloads()
start_downloads()
print('Elapsed time: ' .. tostring(os.time() - start_time) .. ' second(s)')
