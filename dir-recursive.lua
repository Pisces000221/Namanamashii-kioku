inspect = inspect or require('./libs/inspect')
local list_file = arg[1] or 'dirlist.csv'
local dir_file = arg[2] or 'dir.out'

local dirs, files = {}, {}
local loc_files, loc_map = {}, {}
local tot_size = 0
function list_deserialize(record)
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
function local_info_append(size, path)
    loc_files[#loc_files + 1] = { size = size, path = path }
    loc_map[path] = size
    -- if #loc_files < 60 then print(size .. ' / ' .. path) end
end
function read_list_file()
    local f = io.open(list_file, 'r')
    local s = f:read()
    while s ~= nil do
        file_info_append(list_deserialize(s))
        s = f:read()
    end
    f:close()
end
function read_dir_file()
    local f = io.open(dir_file, 'r')
    local s = f:read()
    local cur_base = ''
    local size, path
    while s ~= nil do
        if s == '' then
        elseif s:sub(-1) == ':' then
            cur_base = s:sub(2, -2)
        elseif s:sub(-1) ~= '/' then
            s:gsub('([0-9]+) (.+)', function (x, y)
                size = x  path = y
            end)
            local_info_append(size, cur_base .. '/' .. path)
        end
        s = f:read()
    end
    f:close()
end

print('Retrieving file list from [' .. list_file .. ']')
start_time = os.clock()
read_list_file()
print(#dirs .. ' directory(-ies) and ' .. #files .. ' file(s) in total. Please confirm.')
print('Total size is ~' .. format_size(tot_size) .. ' / ' .. math.floor(tot_size) .. ' Bytes'
    .. ' (estimated)')
print('Elapsed time: ' .. tostring(os.clock() - start_time) .. ' second(s)')

print('------')
start_time = os.clock()
print('Retrieving local directory list from [' .. dir_file .. ']')
read_dir_file()
print('Local files found: ' .. #loc_files .. ' total')
print('Elapsed time: ' .. tostring(os.clock() - start_time) .. ' second(s)')

print('------')
print('Comparing diff')
local warnings_cnt, notfound_cnt = 0, 0
for i = 1, #files do
    local loc_sz = loc_map[files[i].path]
    if loc_sz == nil then loc_sz = -1 end
    local rate = loc_sz / files[i].size
    if rate < 0.9 or rate > 1.1 then
        print('File (serial = ' .. i .. '): ' .. files[i].path)
        print('Expected size: ' .. files[i].size .. '  Local file size: ' .. loc_sz)
        warnings_cnt = warnings_cnt + 1
        -- if warnings_cnt >= 20 then break end
        if loc_sz == -1 then notfound_cnt = notfound_cnt + 1 end
    end
end
print('------')
print('Total diffs: ' .. warnings_cnt .. ' of which ' .. notfound_cnt .. ' is/are "not found"')
print('Lists: expected ' .. #files .. ' / found ' .. #loc_files)
