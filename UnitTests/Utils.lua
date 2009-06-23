local function to_string(data, indent) 
    local str = "" 

    if(indent == nil) then 
        indent = 0 
    end 

    -- Check the type 
    if(type(data) == "string") then 
        str = str .. (" "):rep(indent) .. data .. "\n" 
    elseif(type(data) == "number") then 
        str = str .. (" "):rep(indent) .. data .. "\n" 
    elseif(type(data) == "boolean") then 
        if(data == true) then 
            str = str .. "true" 
        else 
            str = str .. "false" 
        end 
    elseif(type(data) == "table") then 
        local i, v 
        for i, v in pairs(data) do 
            -- Check for a table in a table 
            if(type(v) == "table") then 
                str = str .. (" "):rep(indent) .. i .. ":\n" 
                str = str .. to_string(v, indent + 2) 
            else 
                str = str .. (" "):rep(indent) .. i .. ": " ..  to_string(v, 0) 
            end 
        end 
    else 
        print(string.format("Error: unknown data type: %s", type(data)))
				print(debugstack())
    end 

    return str 
end 

table.to_string = to_string
