local tables = {}
local table_def = ""
local value_def = ""
local documented_tables = {}
function define_name(the_table)
  for i, p in pairs(tables) do
    if p == the_table then
     return i,true 
    end
  end
  local count = 0
  for _, _ in pairs(tables) do count=count+1 end
  tables["___TABLE"..count+1]=the_table
  table_def = table_def.."local ".."___TABLE"..(count+1).."={}\n"
  return "___TABLE"..count+1,false
end
function definer(the_table)
  local more_tables = {}
  local name = define_name(the_table)
  for i,p in pairs(the_table) do
    if type(i) == "string" then
      value_def = value_def..name.."[\""..i.."\"]="
    elseif type(i) == "number" then
      value_def = value_def..name.."["..tostring(i).."]="
    elseif type(i) == "function" then
      print("cant encode a function")
    elseif type(i) == "table" then
      local nameb,existed = define_name(i)
      if documented_tables[i]==nil and more_tables[i]==nil then
        more_tables[i]=i
      end
      value_def = value_def..name.."["..nameb.."]="
    elseif type(i) == "nil" then
      value_def = value_def..name.."[nil]="
    end

    if type(p) == "string" then
      value_def = value_def.."\""..p.."\""
    elseif type(p) == "number" then
      value_def = value_def..tostring(p)
    elseif type(p) == "function" then
      print("cant encode a function")
    elseif type(p) == "table" then
      local nameb,existed = define_name(p)
      if documented_tables[p]==nil and more_tables[p]==nil then
        more_tables[p]=p
      end
      value_def = value_def..nameb
    elseif type(p) == "nil" then
      value_def = value_def.."nil"
    end
    value_def = value_def.."\n"
  end
  documented_tables[the_table]=true
  local count = 0
  for _, _ in pairs(more_tables) do count=count+1 end
  if count>0 then
    for _, p in pairs(more_tables) do
      definer(p)
    end
  end
end
return function(the_table)
  local serialized = ""
  definer(the_table)
  serialized=table_def..value_def.."return ___TABLE1"
  return serialized
end
