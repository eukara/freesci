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

void w_needle_precache(void)
{
}

void w_needle_updateammo(player pl)
{
	Weapons_UpdateAmmo(pl, -1, -1, -1);
}
string w_needle_pmodel(player pl)
{
	return __NULL__;
}
string w_needle_deathmsg(void)
{
	return "%s poisoned %s.";
}

void w_needle_draw(player pl)
{
}

void w_needle_holster(player pl)
{
}

void w_needle_primary(player pl)
{
	if (pl.w_attack_next > 0.0) {
		return;
	}

	vector startTrace = pl.GetEyePos();
	vector endTrace;

	makevectors(pl.v_angle);
	endTrace = startTrace + (v_forward * 96);
	traceline(startTrace, endTrace, MOVE_NORMAL, pl);
	pl.w_attack_next = 1.0f;
	Animation_PlayerTop(pl, SCIANIM_PUSH_BUTTON, 1.0f);

#ifdef SERVER
	if (trace_fraction >= 1.0) {
		return;
	}

	if (trace_ent.takedamage == DAMAGE_NO) {
		return;
	}

	if not (trace_ent.flags & FL_CLIENT || trace_ent.flags & FL_MONSTER) {
		return;
	}

	Damage_Apply(trace_ent, pl, 7, WEAPON_NEEDLE, DMG_POISON);
#endif
}

void w_needle_secondary(player pl)
{
	/* TODO: switch between first/third person */
}

float w_needle_aimanim(player pl)
{
	return 0; /* not used */
}

void w_needle_hudpic(player pl, int s, vector pos, float a)
{
#ifdef CLIENT
	if (s) {
		drawsubpic(pos, [170,45], g_hammer_spr, [0,48/256], [170/256,45/256], g_hud_color, a, DRAWFLAG_ADDITIVE);
	} else {
		drawsubpic(pos, [170,45], g_hammer_spr, [0,0], [170/256,45/256], g_hud_color, a, DRAWFLAG_ADDITIVE);
	}
#endif
}

bool
w_needle_isempty(player pl)
{
	return false;
}

weapon_t w_needle =
{
	.name		= "needle",
	.id		= ITEM_NEEDLE,
	.slot		= 0,
	.slot_pos	= 2,
	.draw		= w_needle_draw,
	.holster	= w_needle_holster,
	.primary	= w_needle_primary,
	.secondary	= w_needle_secondary,
	.reload		= __NULL__,
	.release	= __NULL__,
	.postdraw	= __NULL__,
	.precache	= w_needle_precache,
	.pickup		= __NULL__,
	.updateammo	= w_needle_updateammo,
	.wmodel		= __NULL__,
	.pmodel		= w_needle_pmodel,
	.deathmsg	= w_needle_deathmsg,
	.aimanim	= w_needle_aimanim,
	.isempty	= w_needle_isempty,
	.hudpic		= w_needle_hudpic
};
