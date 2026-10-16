obs = obslua

-- Script variables
counter = 0
text = ""
text_source_name = ""
increment_hotkey_id = obs.OBS_INVALID_HOTKEY_ID
decrement_hotkey_id = obs.OBS_INVALID_HOTKEY_ID

local filter_source_name = ""
local filter_name = ""
local trigger_filter_enabled = false

-- Update the OBS text source
function update_text_source()
    if text_source_name == "" then
        return
    end

    local source = obs.obs_get_source_by_name(text_source_name)

    if source ~= nil then
        local settings = obs.obs_data_create()

        local display_text = text:gsub(
            "{count}",
            tostring(counter)
        )

        obs.obs_data_set_string(settings, "text", display_text)
        obs.obs_source_update(source, settings)

        obs.obs_data_release(settings)
        obs.obs_source_release(source)
    end
end

-- Hotkey callbacks
function increment_hotkey(pressed)
    if not pressed then
        return
    end

    trigger_filter()

    counter = counter + 1

    update_text_source()
end

function decrement_hotkey(pressed)
    if not pressed then
        return
    end

    counter = counter - 1

    update_text_source()
end

-- Reset button callback
function reset_counter(props, property)
    counter = 0

    update_text_source()

    return true
end

-- Trigger configuerd filter
function trigger_filter()
    if not trigger_filter_enabled then
        return
    end

    if filter_source_name == "" or filter_name == "" then
        return
    end

    -- Get the source containing the filter
    local source = obs.obs_get_source_by_name(filter_source_name)

    if source == nil then
        return
    end

    -- Find the filter
    local filter = obs.obs_source_get_filter_by_name(
        source,
        filter_name
    )

    if filter ~= nil then
        -- Enable the filter
        obs.obs_source_set_enabled(filter, false)
        obs.obs_source_set_enabled(filter, true)

        obs.obs_source_release(filter)
    end

    obs.obs_source_release(source)
end

-- Script description
function script_description()
    return [[
        Simple Counter

        Select a text source and configure the
        increment and decrement hotkeys in OBS Settings > Hotkeys.

        The counter is saved between OBS sessions.

        Filters are intended for the Move Transition Plugin.

        When and increment is triggered the configured filter
        is first disabled then re-enabled 
    ]]
end

-- Get filters on source/scene
function update_filter_list(props, property, settings)
    local source_name = obs.obs_data_get_string(
        settings,
        "filter_source_name"
    )

    local filter_property = obs.obs_properties_get(
        props,
        "filter_name"
    )

    obs.obs_property_list_clear(filter_property)

    local source = obs.obs_get_source_by_name(source_name)

    if source ~= nil then
        local filters = obs.obs_source_enum_filters(source)

        if filters ~= nil then
            for _, filter in ipairs(filters) do
                local name = obs.obs_source_get_name(filter)

                obs.obs_property_list_add_string(
                    filter_property,
                    name,
                    name
                )
            end

            obs.source_list_release(filters)
        end

        obs.obs_source_release(source)
    end

    return true
end

-- Script properties
function script_properties()
    local props = obs.obs_properties_create()

    -- Counter Label
    obs.obs_properties_add_text(
        props,
        "text",
        "Text",
        obs.OBS_TEXT_DEFAULT
    )

    -- Text source dropdown
    local source_list = obs.obs_properties_add_list(
        props,
        "text_source",
        "Text Source",
        obs.OBS_COMBO_TYPE_LIST,
        obs.OBS_COMBO_FORMAT_STRING
    )

    -- Find available text sources
    local sources = obs.obs_enum_sources()

    if sources ~= nil then
        for _, source in ipairs(sources) do
            local source_id = obs.obs_source_get_unversioned_id(source)

            if source_id == "text_gdiplus" or
               source_id == "text_ft2_source" then

                local name = obs.obs_source_get_name(source)

                obs.obs_property_list_add_string(
                    source_list,
                    name,
                    name
                )
            end
        end

        obs.source_list_release(sources)
    end

    -- Reset button
    obs.obs_properties_add_button(
        props,
        "reset",
        "Reset Counter",
        reset_counter
    )

    -- Source dropdown
    local source_list = obs.obs_properties_add_list(
        props,
        "filter_source_name",
        "Filter Source",
        obs.OBS_COMBO_TYPE_LIST,
        obs.OBS_COMBO_FORMAT_STRING
    )

    obs.obs_property_set_modified_callback(
        source_list,
        update_filter_list
    )

    -- Filter dropdown
    local filter_list = obs.obs_properties_add_list(
        props,
        "filter_name",
        "Filter",
        obs.OBS_COMBO_TYPE_LIST,
        obs.OBS_COMBO_FORMAT_STRING
    )

    -- Populate regular sources
    local sources = obs.obs_enum_sources()

    if sources ~= nil then
        for _, source in ipairs(sources) do
            local name = obs.obs_source_get_name(source)

            obs.obs_property_list_add_string(
                source_list,
                name,
                name
            )
        end

        obs.source_list_release(sources)
    end

    -- Populate scenes
    local scenes = obs.obs_frontend_get_scenes()

    if scenes ~= nil then
        for _, scene in ipairs(scenes) do
            local name = obs.obs_source_get_name(scene)

            obs.obs_property_list_add_string(
                source_list,
                name,
                name
            )
        end

        obs.source_list_release(scenes)
    end

    -- Enable checkbox
    obs.obs_properties_add_bool(
        props,
        "trigger_filter_enabled",
        "Enable Filter on Increment"
    )

    local settings = obs.obs_data_create()

    obs.obs_data_set_string(
        settings,
        "filter_source_name",
        filter_source_name
    )

    update_filter_list(props, nil, settings)

    obs.obs_data_release(settings)

    obs.obs_properties_add_text(
        props,
        "footer",
        "<b>Fancy Increment v1.0</b><br>" ..
        "Created by itMeTofuwu<br>" ..
        "<a href='https://www.tofusgarden.com'>Website</a>",
        obs.OBS_TEXT_INFO
    )

    return props
end

-- Set default values
function script_defaults(settings)
    obs.obs_data_set_default_string(
        settings,
        "text",
        "Count: {count}"
    )

end

-- Called when script settings change
function script_update(settings)
    text_source_name = obs.obs_data_get_string(
        settings,
        "text_source"
    )

    text = obs.obs_data_get_string(
        settings,
        "text"
    )

    filter_source_name = obs.obs_data_get_string(
        settings,
        "filter_source_name"
    )

    filter_name = obs.obs_data_get_string(
        settings,
        "filter_name"
    )

    trigger_filter_enabled = obs.obs_data_get_bool(
        settings,
        "trigger_filter_enabled"
    )

    update_text_source()
end

function script_load(settings)

    -- Restore saved counter
    counter = obs.obs_data_get_int(settings, "counter")

    -- Register increment hotkey
    increment_hotkey_id = obs.obs_hotkey_register_frontend(
        "increment_counter",
        "Increment Counter",
        increment_hotkey
    )

    -- Register decrement hotkey
    decrement_hotkey_id = obs.obs_hotkey_register_frontend(
        "decrement_counter",
        "Decrement Counter",
        decrement_hotkey
    )

    -- Restore increment hotkey
    local increment_hotkey_data = obs.obs_data_get_array(
        settings,
        "increment_hotkey"
    )

    obs.obs_hotkey_load(
        increment_hotkey_id,
        increment_hotkey_data
    )

    obs.obs_data_array_release(increment_hotkey_data)

    -- Restore decrement hotkey
    local decrement_hotkey_data = obs.obs_data_get_array(
        settings,
        "decrement_hotkey"
    )

    obs.obs_hotkey_load(
        decrement_hotkey_id,
        decrement_hotkey_data
    )

    obs.obs_data_array_release(decrement_hotkey_data)
end

-- Save script state
function script_save(settings)

    obs.obs_data_set_int(
        settings,
        "counter",
        counter
    )

    -- Save increment hotkey
    local increment_hotkey_data = obs.obs_hotkey_save(
        increment_hotkey_id
    )

    obs.obs_data_set_array(
        settings,
        "increment_hotkey",
        increment_hotkey_data
    )

    obs.obs_data_array_release(increment_hotkey_data)

    -- Save decrement hotkey
    local decrement_hotkey_data = obs.obs_hotkey_save(
        decrement_hotkey_id
    )

    obs.obs_data_set_array(
        settings,
        "decrement_hotkey",
        decrement_hotkey_data
    )

    obs.obs_data_array_release(decrement_hotkey_data)
end