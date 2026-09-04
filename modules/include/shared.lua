local isServerSide <const> = IsDuplicityVersion()
local WaveShield = {}
local PlayerId <const> = PlayerId
local type <const> = type
local GlobalState = GlobalState
local table_unpack <const> = table.unpack
local debug <const> = debug
local debug_getinfo <const> = debug.getinfo
local _in <const> = Citizen.InvokeNative
local GetGameTimer <const> = GetGameTimer
local Wait <const> = Wait
local _exports <const> = exports

WaveShield.exports = _exports["WaveShield"]
WaveShield.resourceName = GetCurrentResourceName()
WaveShield.Wait = Wait
WaveShield.CreateThread = CreateThread

WaveShield.GenerateSubstitution = LPH_JIT_MAX(function(key)
  local blacklist = {
      ["^"] = true,
      [" "] = true,
      ["\\"] = true
  }
  local alphabet = ""
  for i = 32, 126 do
      local char = string.char(i)
      if not blacklist or not blacklist[char] then
          alphabet = alphabet .. char
      end
  end

  local substitution = {}
  local inverseSubstitution = {}

  local shuffledAlphabet = {}
  for i = 1, #alphabet do
      shuffledAlphabet[i] = alphabet:sub(i, i)
  end

  local function hashKey(key)
      local hash = 0
      for i = 1, #key do
          hash = (hash * 31 + key:byte(i)) % 2 ^ 32
      end
      return hash
  end

  local hash = hashKey(key)

  -- Permutation déterministe de l'alphabet en fonction du hachage
  for i = 1, #shuffledAlphabet do
      local j = (hash % (#shuffledAlphabet - i + 1)) + i
      shuffledAlphabet[i], shuffledAlphabet[j] = shuffledAlphabet[j], shuffledAlphabet[i]
      hash = hash + i
  end

  -- Générer les tables de substitution
  for i = 1, #alphabet do
      substitution[alphabet:sub(i, i)] = shuffledAlphabet[i]
      inverseSubstitution[shuffledAlphabet[i]] = alphabet:sub(i, i)
  end

  return substitution, inverseSubstitution
end)

WaveShield.EncryptString = LPH_JIT_MAX(function(chaine, substitution)
  chaine = tostring(chaine)
  local result = ""

  for i = 1, #chaine do
      local char = chaine:sub(i, i)
      result = result .. (substitution[char] or char)
  end

  return result
end)

WaveShield.DecryptString = LPH_JIT_MAX(function(chaine, inverseSubstitution)
  chaine = tostring(chaine)
  local result = ""

  for i = 1, #chaine do
      local char = chaine:sub(i, i)
      result = result .. (inverseSubstitution[char] or char)
  end

  return result
end)

WaveShield.ConvertEvent = LPH_JIT_MAX(function(eventName)
  return WaveShield.EncryptString("_WS:" .. tostring(eventName), WaveShield.Substitution)
end)

if isServerSide then
  WaveShield.CreateThread(function()
      while not GlobalState[GlobalState.CFct1C6gobnW4qkaQUx3Xk9Q or ""] or not GlobalState.HHct1C6gobnW3DkIQUxiXk9Q do
          WaveShield.Wait(10)
      end

      WaveShield.SubstitutionKey = GlobalState.HHct1C6gobnW3DkIQUxiXk9Q
      WaveShield.Substitution, WaveShield.InverseSubstitution = WaveShield.GenerateSubstitution(GetConvar(WaveShield.SubstitutionKey, "weaponDamageEvent"))

      WaveShield.IsEventTokenizationReady = true
  end)
else
  if not GlobalState.HHct1C6gobnW3DkIQUxiXk9Q then while true do end end
  
  WaveShield.SubstitutionKey = GlobalState.HHct1C6gobnW3DkIQUxiXk9Q
  WaveShield.Substitution, WaveShield.InverseSubstitution = WaveShield.GenerateSubstitution(GetConvar(WaveShield.SubstitutionKey, "weaponDamageEvent"))

  WaveShield.IsEventTokenizationReady = true
end

-- Consolidated ignored events list with exact matches and glob patterns
local predefinedIgnoredEvents = {
  -- Exact matches (converted from old ignoredEvents)
  "ox_lib:validateCallback",
  "onResourceStarting",
  "mumbleDisconnected", 
  "entityDamaged",
  "onClientResourceStart",
  "onResourceStop",
  "gameEventTriggered",
  "onClientResourceStop",
  "populationPedCreating",
  "mumbleConnected",
  "onServerResourceStart",
  "onServerResourceStop", 
  "onResourceListRefresh",
  "playerConnecting",
  "playerDropped",
  "playerJoining",
  "rconCommand",
  "weaponDamageEvent",
  "vehicleComponentControlEvent",
  "ptFxEvent",
  "removeAllWeaponsEvent",
  "removeWeaponEvent",
  "startProjectileEvent",
  "giveWeaponEvent",
  "clearPedTasksEvent",
  "fireEvent",
  "respawnPlayerPedEvent",
  "explosionEvent",
  "entityCreated",
-- ZGlzY29yZC5nZy9mbWE=
  "entityCreating",
  "entityRemoved",
  "playerEnteredScope",
  "playerLeftScope",
  "hostingSession",
  "hostedSession",
  "sessionHostResult",
  "playerSpawned",
  "onClientMapStart",
  "onClientMapStop",
  "onClientGameTypeStart",
  "onClientGameTypeStop",
  "onMapStart",
  "onMapStop",
  "onGameTypeStart",
  "onGameTypeStop",
  "CEvent",
  "__WaveShield_internal:protectEvent",
  
  -- Glob patterns (converted from old prohibitedEvents)
  "__cfx_export_WaveShield_*",
  "__cfx_internal:*",
  "__cfx_nui:*", 
  "txaLogger:*",
  "txsv:*",
  "baseevents:*",
  "mapmanager:*",
  "pmc__callback_retval:*",
  "_WS:webrtc:*"
}

-- Pre-build exact match lookup table for O(1) performance
local exactMatchCache = {}
local globPatterns = {}

-- Separate exact matches from glob patterns for optimization
for i = 1, #predefinedIgnoredEvents do
  local pattern = predefinedIgnoredEvents[i]
  if pattern:find("*") then
    globPatterns[#globPatterns + 1] = pattern
  else
    exactMatchCache[pattern] = true
  end
end

-- Optimized glob pattern matching function
local function matchesGlobPattern(eventName, pattern)
  if not pattern:find("*") then
      return eventName == pattern
  end
  
  -- Handle patterns ending with *
  if pattern:sub(-1) == "*" then
      local prefix = pattern:sub(1, -2)
      return eventName:sub(1, #prefix) == prefix
  end
  
  -- Handle patterns starting with *
  if pattern:sub(1, 1) == "*" then
      local suffix = pattern:sub(2)
      return eventName:sub(-#suffix) == suffix
  end
  
  -- Handle patterns with * in the middle
  local starPos = pattern:find("*")
  if starPos then
      local prefix = pattern:sub(1, starPos - 1)
      local suffix = pattern:sub(starPos + 1)
      return eventName:sub(1, #prefix) == prefix and eventName:sub(-#suffix) == suffix
  end
  
  return eventName == pattern
end

-- Consolidated and optimized event filtering function
local isIgnoredEvent = LPH_NO_VIRTUALIZE(function(eventName)
  if not eventName or type(eventName) ~= "string" or eventName == "" then
      return true
  end

  -- Fast O(1) lookup for exact matches
  if exactMatchCache[eventName] then
      return true
  end

  -- Check predefined glob patterns
  for i = 1, #globPatterns do
      if matchesGlobPattern(eventName, globPatterns[i]) then
          return true
      end
  end

  -- Check configuration-based ignored events
  local Configuration = GlobalState[GlobalState.CFct1C6gobnW4qkaQUx3Xk9Q or ""]
  if Configuration and Configuration.Main then
      local configIgnoredEvents = Configuration.Main.IgnoredEvents
      if configIgnoredEvents then
          for i = 1, #configIgnoredEvents do
              local ignoredPattern = configIgnoredEvents[i]
              if matchesGlobPattern(eventName, ignoredPattern) then
                  return true
              end
          end
      end
  end

  return false
end)