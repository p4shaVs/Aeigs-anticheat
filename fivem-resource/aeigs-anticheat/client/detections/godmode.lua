-- godmode.lua — Godmode / invincibility (kesin ban, false'suz)
-- Teknikler:
--  • İmkânsız değerler (health>200, maxHealth>200, armor>100) → anında
--  • GetPlayerInvincible / GetEntityProofs (bullet/melee proof) / config-flag(6)
--    → muaf durumlar (ölü/donmuş/ragdoll/spawn/revive/araç) DIŞINDA, 2 strike/10 sn
-- tx menüsünden godmode açılınca invincible flag'i sürekli true → yakalanır.

local strikeInv = Aeigs.strike(2, 10000)

local function exempt()
  local S = Aeigs.S
  return S.dead or S.frozen or S.ragdoll or Aeigs.spawnGuard() or Aeigs.reviveGrace()
    or IsPlayerCamControlDisabled(S.id) or S.parachute > 0 or S.cutscene
end

CreateThread(function()
  while true do
    Wait(1500)
    if Aeigs.rule('anti_invincibility', true) then
      local S = Aeigs.S
      if S.ped then
        -- İmkânsız değerler → anında (armor sunucuda da kontrol ediliyor)
        if S.health > 200 or S.maxHealth > 200 then
          Aeigs.report('GODMODE', 'CRITICAL', { health = S.health, max = S.maxHealth })
        elseif S.armor > 100 then
          Aeigs.report('GODMODE', 'CRITICAL', { armor = S.armor })
        elseif not exempt() then
          local hit = false
          if S.invincible then hit = true end
          -- Mermi/bıçak geçirmezlik (proof) — combat sırasında hasar almama
          local _, bulletProof, _, _, _, meleeProof = GetEntityProofs(S.ped)
          if bulletProof or meleeProof then hit = true end
          if GetPedConfigFlag(S.ped, 6, true) then hit = true end  -- bullet-proof vest flag
          if hit and strikeInv:hit() then
            Aeigs.report('GODMODE', 'CRITICAL', { source = 'invincible' })
          end
        end
      end
    end
  end
end)
