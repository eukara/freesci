/*
 * Copyright (c) 2016-2023 Marco Cawthorne <marco@icculus.org>
 * Copyright (c) 2016-2023 Gethyn ThomasQuail <gethyn@vera-visions.com>
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

#define PMOVE_AIRSTEPHEIGHT 0
#define PMOVE_STEPHEIGHT 18
#define PMOVE_FRICTION 4
#define PMOVE_EDGEFRICTION 1
#define PMOVE_STOPSPEED 100
#define PMOVE_GRAVITY 800
#define PMOVE_AIRACCELERATE 10
#define PMOVE_WATERACCELERATE 10
#define PMOVE_ACCELERATE 10
#define PMOVE_MAXSPEED 270
#define PMOVE_STEP_WALKSPEED 135
#define PMOVE_STEP_RUNSPEED 220
#define PHY_VIEWPOS [0,0,28]
#define PHY_VIEWPOS_CROUCHED [0,0,12]
#include "items.h"

/* insanity changes player move and attack speed 
 * so lets override some base player functions */
void
player::Physics_InputPreMove(void)
{
	float insanecooldown;

	super::Physics_InputPreMove();

	if (gflags & GF_MADNESS) {
		/* give us a nice transition from insanity */
		insanecooldown = bound(1,sh_insaneactive * 0.1f,3);
		input_movevalues *= insanecooldown;
	}
}

/* original SciHunt only increased speed melee but it's
 * easier to do this to every weapon, plus it's more fun
 * FIXME reloading is borked when active */
void
player::Physics_InputPostMove(void)
{
	super::Physics_InputPostMove();
	if (gflags & GF_MADNESS) {
		w_attack_next = max(0, w_attack_next - input_timelength);
	}
}

float
player::Physics_MaxSpeed(void)
{
	if (gflags & GF_MADNESS) {
		return 1000.0f;
	} else {
		return super::Physics_MaxSpeed();
	}
}

void
player::Physics_Jump(void)
{
	if (waterlevel >= 2) {
		if (watertype == CONTENT_WATER) {
			velocity[2] = 100;
		} else if (watertype == CONTENT_SLIME) {
			velocity[2] = 80;
		} else {
			velocity[2] = 50;
		}
	} else {
		/* Half-Life: Longjump module */
		if (flags & FL_CROUCHING && g_items & 0x00008000i) {
			makevectors([0, v_angle[1], 0]);
			velocity = v_forward * 512;
			velocity[2] += 100;
		}
		if (flags & FL_ONGROUND)
			velocity[2] += 265;
	}
}
