/*
 * Copyright (c) 2016-2020 Marco Cawthorne <marco@icculus.org>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF MIND, USE, DATA OR PROFITS, WHETHER
 * IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING
 * OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

#ifdef CLIENT
var string g_chainsaw_spr;
#endif

enum
{
	CHAINSAW_STARTFIRE,
	CHAINSAW_CONTINUEFIRE,
	CHAINSAW_STOPFIRE,
	CHAINSAW_DEPLOY,
	CHAINSAW_HOLSTER,
	CHAINSAW_IDLE1,
	CHAINSAW_IDLE2,
};

enum
{
	CHAINSAWSTATE_IDLE,
	CHAINSAWSTATE_ATTACKING,
};

void w_chainsaw_precache(void)
{
#ifdef SERVER
	Sound_Precache("weapon_chainsaw.attack");
	Sound_Precache("weapon_chainsaw.hit");
	Sound_Precache("weapon_chainsaw.hitflesh");
	Sound_Precache("weapon_chainsaw.idle");
	Sound_Precache("weapon_chainsaw.startup");
#else
	precache_model("models/v_chainsaw.mdl");
	precache_model("models/p_saw.mdl");
	g_chainsaw_spr = spriteframe("sprites/chainsaw.spr", 0, 0.0f);
#endif
}

void w_chainsaw_updateammo(player pl)
{
	Weapons_UpdateAmmo(pl, -1, -1, -1);
}
string w_chainsaw_pmodel(player pl)
{
	return "models/p_saw.mdl";
}
string w_chainsaw_deathmsg(void)
{
	return "%s killed %s with chainsaw.";
}

void w_chainsaw_draw(player pl)
{
	
	Weapons_SetModel("models/v_chainsaw.mdl");
	Weapons_ViewAnimation(pl, CHAINSAW_DEPLOY);
	
#ifdef SERVER
	Sound_Play(pl, CHAN_WEAPON, "weapon_chainsaw.startup");
#endif
}

void w_chainsaw_holster(player pl)
{
	Weapons_ViewAnimation(pl, CHAINSAW_HOLSTER);
}
void w_chainsaw_primary(player pl)
{

	/* only do it in the attack state */
	if (pl.ammo_chainsaw_state == CHAINSAWSTATE_ATTACKING)
		if (pl.w_attack_next)
			return;

	pl.ammo_chainsaw_state = CHAINSAWSTATE_ATTACKING;
	Weapons_ViewAnimation(pl, CHAINSAW_CONTINUEFIRE);

#ifdef SERVER
	Weapons_MakeVectors(pl);
	vector src = pl.origin + pl.view_ofs;
	traceline(src, src + (v_forward * 32), FALSE, pl);
	
	if (trace_fraction >= 1.0) {
		Sound_Play(pl, CHAN_WEAPON, "weapon_chainsaw.attack");
		pl.w_attack_next = 0.2f;
	} else {
		int dmg;
		FX_Impact(IMPACT_MELEE, trace_endpos, trace_plane_normal);
		
		if (trace_ent.takedamage) {
			if (trace_ent.iBleeds) {
				FX_Blood(trace_endpos, [1,0,0]);
				/* Push the player towards the victim */
				pl.velocity = normalize(trace_ent.origin - pl.origin) * 240;
			}
			dmg = Skill_GetValue("plr_chainsaw", 10);
			Damage_Apply(trace_ent, self, dmg, WEAPON_CHAINSAW, DMG_BLUNT);
			Sound_Play(pl, CHAN_WEAPON, "weapon_chainsaw.hitflesh");
		} else {
			FX_Spark(trace_endpos, trace_plane_normal);
			Sound_Play(pl, CHAN_WEAPON, "weapon_chainsaw.hit");
		}
		pl.w_attack_next = 0.1f;
	}
#endif

	pl.w_idle_next = 0.0f;
}

void w_chainsaw_release(player pl)
{

	if (pl.w_idle_next)
		return;

	if (pl.ammo_chainsaw_state == CHAINSAWSTATE_ATTACKING) {
		pl.ammo_chainsaw_state = CHAINSAWSTATE_IDLE;
		Weapons_ViewAnimation(pl, CHAINSAW_STOPFIRE);
#ifdef SERVER
			Sound_Play(pl, CHAN_WEAPON, "weapon_chainsaw.idle");
#endif
		return;
	}

	if (pl.ammo_chainsaw_state == CHAINSAWSTATE_IDLE) {
		if (pl.w_idle_next <= 0.0f) {
			/* Loop idle sound */
#ifdef SERVER
			Sound_Play(pl, CHAN_WEAPON, "weapon_chainsaw.idle");
#endif
			pl.w_idle_next = 1.45f;
		}
		if (pl.w_attack_next <= 0.0f) {
			if (random() < 0.5) {
				Weapons_ViewAnimation(pl, CHAINSAW_IDLE1);
			} else {
				Weapons_ViewAnimation(pl, CHAINSAW_IDLE2);
			}
			pl.w_attack_next = 5.3333f;
		}
	}
}

float w_chainsaw_aimanim(player pl)
{
	return pl.flags & FL_CROUCHING ? ANIM_CR_AIMEGON : ANIM_AIMEGON;
}

void w_chainsaw_hudpic(player pl, int s, vector pos, float a)
{
#ifdef CLIENT
	if (s) {
		drawsubpic(pos, [170,45], g_chainsaw_spr,
			[0,48/256], [170/256,45/256],
			g_hud_color, a, DRAWFLAG_ADDITIVE);
	} else {
		drawsubpic(pos, [170,45], g_chainsaw_spr,
			[0,0], [170/256,45/256],
			g_hud_color, a, DRAWFLAG_ADDITIVE);
	}
#endif
}

weapon_t w_chainsaw =
{
	.name		= "chainsaw",
	.id			= ITEM_CHAINSAW,
	.slot		= 0,
	.slot_pos	= 2,
	.draw		= w_chainsaw_draw,
	.holster	= w_chainsaw_holster,
	.primary	= w_chainsaw_primary,
	.secondary	= w_chainsaw_release,
	.reload		= w_chainsaw_release,
	.release	= w_chainsaw_release,
	.postdraw	= __NULL__,
	.precache	= w_chainsaw_precache,
	.pickup		= __NULL__,
	.updateammo	= w_chainsaw_updateammo,
	.wmodel		= __NULL__,
	.pmodel		= w_chainsaw_pmodel,
	.deathmsg	= w_chainsaw_deathmsg,
	.aimanim	= w_chainsaw_aimanim,
	.hudpic		= w_chainsaw_hudpic
};
