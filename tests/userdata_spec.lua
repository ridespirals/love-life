local assert = require("tests.assert")
local userdata = require("src.userdata")
local rules = require("src.rules")
local themes = require("src.themes")
local specHelper = require("tests.spec_helper")
local test = specHelper.test
local withLoveMock = specHelper.withLoveMock

local function memoryFilesystem()
  local files = {}
  local dirs = {}

  local function normalize(path)
    return path:gsub("/+$", "")
  end

  return {
    createDirectory = function(path)
      dirs[normalize(path)] = true
      return true
    end,
    getInfo = function(path, kind)
      path = normalize(path)
      if kind == "directory" or kind == nil then
        if dirs[path] then
          return { type = "directory" }
        end
      end
      if kind == "file" or kind == nil then
        if files[path] then
          return { type = "file" }
        end
      end
      return nil
    end,
    getDirectoryItems = function(path)
      path = normalize(path)
      local prefix = path .. "/"
      local items = {}
      local seen = {}
      for filePath in pairs(files) do
        if filePath:sub(1, #prefix) == prefix then
          local rest = filePath:sub(#prefix + 1)
          local name = rest:match("^[^/]+")
          if name and not seen[name] then
            seen[name] = true
            items[#items + 1] = name
          end
        end
      end
      table.sort(items)
      return items
    end,
    read = function(path)
      return files[normalize(path)]
    end,
    write = function(path, contents)
      path = normalize(path)
      local parent = path:match("^(.+)/[^/]+$")
      if parent then
        dirs[parent] = true
      end
      files[path] = contents
      return true
    end,
    remove = function(path)
      path = normalize(path)
      if files[path] then
        files[path] = nil
        return true
      end
      return false
    end,
  }
end

test("slugify lowercases and strips unsupported characters", function()
  assert.equal(userdata.slugify("My Theme!"), "my_theme")
  assert.equal(userdata.slugify("  High-Life  "), "high_life")
  assert.equal(userdata.slugify(""), "")
end)

test("serialize and deserialize round-trip rule records", function()
  local data = {
    id = "highlife",
    name = "HighLife",
    rulestring = "B36/S23",
  }
  local chunk = userdata.serialize(data)
  local loaded = userdata.deserialize(chunk)
  assert.equal(loaded.id, "highlife")
  assert.equal(loaded.name, "HighLife")
  assert.equal(loaded.rulestring, "B36/S23")
end)

test("serialize and deserialize round-trip theme records with accent", function()
  local data = {
    id = "ink",
    name = "Ink",
    alive = "#ffffff",
    dead = "#000000",
    grid = "#808080",
    background = "#000000",
    accent = "#00aaaa",
  }
  local loaded = userdata.deserialize(userdata.serialize(data))
  assert.equal(loaded.accent, "#00aaaa")
  assert.equal(loaded.alive, "#ffffff")
end)

test("validate normalizes hex theme colors to LÖVE RGB 0-1", function()
  local valid = userdata.validate("themes", {
    id = "ink",
    name = "Ink",
    alive = "#ffffff",
    dead = "#000000",
    grid = "#808080",
    background = "#000000",
    accent = "#00aaaa",
  })
  assert.equal(valid.alive[1], 1)
  assert.equal(valid.alive[2], 1)
  assert.equal(valid.alive[3], 1)
  assert.equal(valid.dead[1], 0)
  assert.equal(valid.accent[1], 0)
  assert.isTrue(math.abs(valid.accent[2] - (0xaa / 255)) < 1e-6)
end)

test("serialize and deserialize round-trip theme records without accent", function()
  local data = {
    id = "plain",
    name = "Plain",
    alive = "#ffffff",
    dead = "#000000",
    grid = "#808080",
    background = "#111111",
  }
  local loaded = userdata.deserialize(userdata.serialize(data))
  assert.equal(loaded.accent, nil)
  assert.equal(loaded.background, "#111111")
end)

test("validate rejects invalid theme colors", function()
  local ok, err = userdata.validate("themes", {
    id = "bad",
    name = "Bad",
    alive = "nope",
    dead = "#000000",
    grid = "#000000",
    background = "#000000",
  })
  assert.equal(ok, nil)
  assert.isTrue(err ~= nil)
end)

test("save load list delete round-trip through love.filesystem mock", function()
  withLoveMock(memoryFilesystem(), function()
    userdata.ensureDirs()
    local saved = userdata.save("rules", "highlife", {
      name = "HighLife",
      rulestring = "B36/S23",
    })
    assert.equal(saved.id, "highlife")
    assert.equal(table.concat(userdata.list("rules"), ","), "highlife")

    local loaded = userdata.load("rules", "highlife")
    assert.equal(loaded.rulestring, "B36/S23")

    assert.isTrue(userdata.delete("rules", "highlife"))
    assert.equal(#userdata.list("rules"), 0)
    assert.equal(userdata.load("rules", "highlife"), nil)
  end)
end)

test("rules loadUser merges user presets and protects builtins", function()
  withLoveMock(memoryFilesystem(), function()
    userdata.save("rules", "highlife", {
      name = "HighLife",
      rulestring = "B36/S23",
    })
    -- Collision with builtin id is ignored by loadUser.
    userdata.save("rules", "conway", {
      name = "conway",
      rulestring = "B36/S23",
    })
    rules.loadUser(userdata)

    assert.isTrue(rules.isBuiltin("conway"))
    assert.isTrue(rules.isUser("highlife"))
    assert.isFalse(rules.isUser("conway"))
    assert.equal(rules.get("highlife").rulestring, "B36/S23")
    assert.equal(rules.get("conway").rulestring, "B3/S23")

    local list = table.concat(rules.list(), ",")
    assert.isTrue(list:find("highlife", 1, true) ~= nil)
    assert.isTrue(list:find("conway", 1, true) ~= nil)

    rules.loadUser(nil)
  end)
end)

test("validate accepts pattern records with cells table", function()
  local valid = userdata.validate("patterns", {
    id = "my_block",
    name = "My Block",
    cells = { { 0, 0 }, { 1, 0 }, { 0, 1 }, { 1, 1 } },
  })
  assert.equal(valid.id, "my_block")
  assert.equal(#valid.cells, 4)
end)

test("validate rejects pattern records without cells", function()
  local ok, err = userdata.validate("patterns", {
    id = "bad",
    name = "Bad",
  })
  assert.equal(ok, nil)
  assert.isTrue(err ~= nil)
end)

test("themes loadUser merges user presets with optional accent", function()
  withLoveMock(memoryFilesystem(), function()
    userdata.save("themes", "ink", {
      name = "Ink",
      alive = "#ffffff",
      dead = "#000000",
      grid = "#404040",
      background = "#000000",
      accent = "#00aaaa",
    })
    themes.loadUser(userdata)

    assert.isTrue(themes.isUser("ink"))
    assert.isTrue(themes.isBuiltin("classic"))
    local ink = themes.get("ink")
    assert.equal(ink.name, "ink")
    assert.isTrue(ink.accent ~= nil)
    assert.equal(themes.toHex(ink.accent), "#00aaaa")

    themes.loadUser(nil)
  end)
end)
