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

var int autocvar_sh_insanity = 10;

void
HLGameRules::RestartRound(void)
{
	/* respawn all players and scientists */
	for (entity e = world; (e = find( e, ::classname, "player"));) {
		PlayerSpawn((NSClientPlayer)e);
	}
	for (entity e = world; (e = find( e, ::classname, "monster_scientist"));) {
		NSEntity sci = (NSEntity)e;
		sci.Respawn();
	}
	env_message_broadcast("New round, let's go!");
}

void
HLGameRules::RegisterSciDeath(void)
{
	CountScientists();
}

bool
HLGameRules::IsMultiplayer(void)
{
	return true;
}

void
HLGameRules::PlayerDeath(NSClientPlayer pl)
{

	player sh_pl = (player)pl;

	/* obituary networking */
	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, EV_OBITUARY);
	if (g_dmg_eAttacker.netname)
		WriteString(MSG_MULTICAST, g_dmg_eAttacker.netname);
	else
		WriteString(MSG_MULTICAST, g_dmg_eAttacker.classname);
	WriteString(MSG_MULTICAST, pl.netname);
	WriteByte(MSG_MULTICAST, g_dmg_iWeapon);
	WriteByte(MSG_MULTICAST, 0);
	msg_entity = world;
	multicast([0,0,0], MULTICAST_ALL);

	/* death-counter */
	pl.deaths++;
	forceinfokey(pl, "*deaths", ftos(pl.deaths));

	/* update score-counter */
	if (pl.flags & FL_CLIENT || pl.flags & FL_MONSTER)
	if (g_dmg_eAttacker.flags & FL_CLIENT) {
		if (pl == g_dmg_eAttacker)
			g_dmg_eAttacker.frags--;
		else
			g_dmg_eAttacker.frags++;
	}


	pl.Death();
	pl.takedamage = DAMAGE_NO;
	pl.gflags &= ~GF_FLASHLIGHT;
	pl.gflags &= ~GF_EGONBEAM;
	pl.gflags &= ~GF_MADNESS;

	sh_pl.sh_insaneactive = 0.0f;

	pl.think = PutClientInServer;
	pl.nextthink = time + 4.0f;
	Sound_Play(pl, CHAN_AUTO, "player.die");

	/* either gib, or make a corpse */
	if (pl.health < -50) {
		FX_GibHuman(pl.origin, vectoangles(pl.origin - g_dmg_eAttacker.origin), g_dmg_iDamage * 2.0f);
	} else {
		FX_Corpse_Spawn((player)pl, ANIM_DIESIMPLE);
	}
}

void
HLGameRules::PlayerSpawn(NSClientPlayer pp)
{
	player pl = (player)pp;
	/* this is where the mods want to deviate */
	entity spot;

	pl.classname = "player";
	pl.health = pl.max_health = 100;
	pl.takedamage = DAMAGE_YES;
	pl.solid = SOLID_SLIDEBOX;
	pl.movetype = MOVETYPE_WALK;
	pl.flags = FL_CLIENT;
	pl.viewzoom = 1.0;
	pl.model = "models/player.mdl";
	string mymodel = infokey(pl, "model");

	if (mymodel) {
		mymodel = sprintf("models/player/%s/%s.mdl", mymodel, mymodel);
		if (whichpack(mymodel)) {
			pl.model = mymodel;
		}
	}
	setmodel(pl, pl.model);

	setsize(pl, VEC_HULL_MIN, VEC_HULL_MAX);
	pl.velocity = [0,0,0];
	pl.gravity = __NULL__;
	pl.frame = 1;
	pl.SendFlags = UPDATE_ALL;
	pl.customphysics = Empty;
	pl.iBleeds = TRUE;
	forceinfokey(pl, "*spec", "0");
	forceinfokey(pl, "*deaths", ftos(pl.deaths));

	spot = Spawn_SelectRandom("info_player_deathmatch");
	setorigin(pl, spot.origin);
	pl.angles = spot.angles;

	pl.g_items = ITEM_CROWBAR | ITEM_GLOCK | ITEM_SUIT;
	pl.activeweapon = WEAPON_GLOCK;
	pl.glock_mag = 18;
	pl.ammo_9mm = 44;
	Weapons_RefreshAmmo(pl);
	SHData_GetItems(pl);

	Client_FixAngle(pl, pl.angles);
}

void
HLGameRules::LevelDecodeParms(NSClientPlayer pp)
{
	player pl = (player)pp;
	g_landmarkpos[0] = parm1;
	g_landmarkpos[1] = parm2;
	g_landmarkpos[2] = parm3;
	pl.angles[0] = parm4;
	pl.angles[1] = parm5;
	pl.angles[2] = parm6;
	pl.velocity[0] = parm7;
	pl.velocity[1] = parm8;
	pl.velocity[2] = parm9;
	pl.g_items = parm10;
	pl.activeweapon = parm11;
	pl.flags = parm64;

	pl.ammo_9mm = parm12;
	pl.ammo_357 = parm13;
	pl.ammo_buckshot = parm14;
	pl.ammo_m203_grenade = parm15;
	pl.ammo_bolt = parm16;
	pl.ammo_rocket = parm17;
	pl.ammo_uranium = parm18;
	pl.ammo_handgrenade = parm19;
	pl.ammo_satchel = parm20;
	pl.ammo_tripmine = parm21;
	pl.ammo_snark = parm22;
	pl.ammo_hornet = parm23;

	pl.glock_mag = parm24;
	pl.mp5_mag = parm25;
	pl.python_mag = parm26;
	pl.shotgun_mag = parm27;
	pl.crossbow_mag = parm28;
	pl.rpg_mag = parm29;
	pl.satchel_chg = parm30;

	if (pl.flags & FL_CROUCHING) {
		setsize(pl, VEC_CHULL_MIN, VEC_CHULL_MAX);
	} else {
		setsize(pl, VEC_HULL_MIN, VEC_HULL_MAX);
	}
}

void
HLGameRules::LevelChangeParms(NSClientPlayer pp)
{
	player pl = (player)pp;
	parm1 = g_landmarkpos[0];
	parm2 = g_landmarkpos[1];
	parm3 = g_landmarkpos[2];
	parm4 = pl.angles[0];
	parm5 = pl.angles[1];
	parm6 = pl.angles[2];
	parm7 = pl.velocity[0];
	parm8 = pl.velocity[1];
	parm9 = pl.velocity[2];
	parm64 = pl.flags;
	parm10 = pl.g_items;
	parm11 = pl.activeweapon;
	parm12 = pl.ammo_9mm;
	parm13 = pl.ammo_357;
	parm14 = pl.ammo_buckshot;
	parm15 = pl.ammo_m203_grenade;
	parm16 = pl.ammo_bolt;
	parm17 = pl.ammo_rocket;
	parm18 = pl.ammo_uranium;
	parm19 = pl.ammo_handgrenade;
	parm20 = pl.ammo_satchel;
	parm21 = pl.ammo_tripmine;
	parm22 = pl.ammo_snark;
	parm23 = pl.ammo_hornet;
	parm24 = pl.glock_mag;
	parm25 = pl.mp5_mag;
	parm26 = pl.python_mag;
	parm27 = pl.shotgun_mag;
	parm28 = pl.crossbow_mag;
	parm29 = pl.rpg_mag;
	parm30 = pl.satchel_chg;
}

void
HLGameRules::LevelNewParms(void)
{
	parm1 = parm2 = parm3 = parm4 = parm5 = parm6 = parm7 =
	parm8 = parm9 = parm10 = parm11 = parm12 = parm13 = parm14 =
	parm15 = parm16 = parm17 = parm18 = parm19 = parm20 = parm21 =
	parm22 = parm23 = parm24 = parm25 = parm26 = parm27 = parm28 =
	parm29 = parm30 = 0;
	parm64 = FL_CLIENT;
}

/* we check what fields have changed over the course of the frame and network
 * only the ones that have actually changed */
void
HLGameRules::PlayerPostFrame(NSClientPlayer pp)
{
	player pl = (player)pp;

	pl.sh_insaneactive = bound(0.0f, pl.sh_insaneactive - frametime, pl.sh_insaneactive);

	/* Apply insanity flag to players, and players only */
	if (pl.sh_insaneactive > 0.0f) {
			if not (pl.gflags & GF_MADNESS) {
				pl.gflags |= GF_MADNESS;
				bprint(PRINT_HIGH, sprintf("%s is going insane!\n", pl.netname));
				Sound_Play(pl, CHAN_AUTO, "player.insane");
			}
	} else {
		if (pl.gflags & GF_MADNESS) {
			bprint(PRINT_HIGH, sprintf("%s is no longer insane!\n", pl.netname));
		}
		pl.gflags &= ~GF_MADNESS;
	}

}

void
HLGameRules::CountScientists(void)
{
	m_iScientistsAlive = 0;
	for (entity s = world; (s = find(s, ::classname, "monster_scientist"));) {
		if (s.solid == SOLID_BBOX || s.solid == SOLID_SLIDEBOX)
			m_iScientistsAlive++;
	}

	forceinfokey(world, "sci_count", sprintf("%i", m_iScientistsAlive));
}

void
HLGameRules::ScientistKill(NSClientPlayer pp, entity sci)
{
	player pl = (player)pp;
	/* obituary networking */
	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, EV_OBITUARY);
	WriteString(MSG_MULTICAST, pl.netname);
	WriteString(MSG_MULTICAST, sci.netname);
	WriteByte(MSG_MULTICAST, g_dmg_iWeapon);
	WriteByte(MSG_MULTICAST, 0);
	msg_entity = world;
	multicast([0,0,0], MULTICAST_ALL);

	/* give players a frag per scientist they kill */
	pl.frags++;

	/* only reward melee frags for insanity, otherwise it's a bit OP */
	if (g_weapons[g_dmg_iWeapon].slot != 0)
		return;

	/* if this is our first kill in a while, or in the timer... */
	if (pl.sh_insanecount == 0 || pl.sh_insanetime > time) {
		pl.sh_insanecount++;
	} else {
		pl.sh_insanecount = 0;
	}

	if (pl.sh_insanecount >= autocvar_sh_insanity) {
		/* always start with a 30 second cooldown 
		 * otherwise give 3 seconds per frag */
		if (pl.gflags & GF_MADNESS) {
			pl.sh_insaneactive += 3.0f;
		} else {
			pl.sh_insaneactive += 30.0f;
		}
		
		/* clamp our timer */
		if (pl.sh_insaneactive > 60)
			pl.sh_insaneactive = 60;
	}

	/* timer gets touched every time */
	pl.sh_insanetime = time + 2.0f;
}

void
HLGameRules::FrameStart(void)
{
	entity e;

	if (m_flRestockTimer < time) {
		m_flRestockTimer = time + 120.0f;
		
		for (e = world; (e = find(e, ::classname, "player"));) {
			player pl = (player)e;
			SHData_GetItems(pl);
		}
	}

	if (autocvar(sh_respbreak, 1))
	if (m_flBreakRespawnTimer < time) {
		m_flBreakRespawnTimer = time + 120.0f;
		
		for (e = world; (e = find( e, ::classname, "func_breakable"));) {
			func_breakable br = (func_breakable)e;
			br.Respawn();
		}
		for (e = world; (e = find( e, ::classname, "func_pushable"));) {
			func_pushable pb = (func_pushable)e;
			pb.Respawn();
		}
		for (e = world; (e = find( e, ::classname, "env_shooter"));) {
			env_shooter sh = (env_shooter)e;
			sh.Respawn();
		}
	}
}

void
HLGameRules::InitPostEnts(void)
{
	forceinfokey(world, "teams", "0");
	forceinfokey(world, "team_1", "");
	forceinfokey(world, "team_2", "");
	forceinfokey(world, "teamscore_1", "0");
	forceinfokey(world, "teamscore_2", "0");
	forceinfokey(world, "teamkills_1", "0");
	forceinfokey(world, "teamkills_2", "0");
	m_iScientistsAlive = 0;
	m_flRestockTimer = 0;
	m_flBreakRespawnTimer = 0;
}

void
HLGameRules::HLGameRules(void)
{
}

/* TEAMPLAY ONLY LOGIC */
bool
SHTeamRules::IsTeamplay(void)
{
	return true;
}

void
SHTeamRules::PlayerSpawn(NSClientPlayer cl)
{
	int red = 0;
	int blue = 0;

	super::PlayerSpawn(cl);

	/* remove this if you want an auto-balance upon every death */
	if (cl.team != 0)
		return;

	for (entity e = world; (e = find( e, ::classname, "player"));) {
		if (e == cl)
			continue;
		if (e.team == 1)
			red++;
		if (e.team == 2)
			blue++;
	}

	/* assign to whatever team has fewer players */
	if (red > blue)
		cl.team = 2;
	else
		cl.team = 1;

	forceinfokey(cl, "*team", sprintf("%d", cl.team));
}

void
SHTeamRules::ScientistKill(NSClientPlayer cl, entity sci)
{
	super::ScientistKill(cl, sci);

	if (cl.team == 2)
		AddTeam2Kill();
	else if (cl.team == 1)
		AddTeam1Kill();
}

void
SHTeamRules::ScientistKillFear(NSClientPlayer cl, entity sci)
{
	super::ScientistKill(cl, sci);

	if (cl.team == 2)
		RemoveTeam2Kill();
	else if (cl.team == 1)
		AddTeam1Kill();
}


void
SHTeamRules::AddTeam1Kill(void)
{
	m_iKillsTeam1++;
	forceinfokey(world, "teamkills_1", sprintf("%i", m_iKillsTeam1));
}

void
SHTeamRules::AddTeam2Kill(void)
{
	m_iKillsTeam2++;
	forceinfokey(world, "teamkills_2", sprintf("%i", m_iKillsTeam2));
}

void
SHTeamRules::RemoveTeam1Kill(void)
{
	m_iKillsTeam1--;
	forceinfokey(world, "teamkills_1", sprintf("%i", m_iKillsTeam1));
}

void
SHTeamRules::RemoveTeam2Kill(void)
{
	m_iKillsTeam2--;
	forceinfokey(world, "teamkills_2", sprintf("%i", m_iKillsTeam2));
}

void
SHTeamRules::RegisterSciDeathHuntTeam(void)
{
	super::RegisterSciDeath();

	if (m_iScientistsAlive > 0)
		return;

	switch (g_chosen_mode) {
	case SHMODE_STANDARD:
		if (m_iKillsTeam1 > m_iKillsTeam2) {
			m_iScoreTeam1++;
			env_message_broadcast("Red team has won!");
		} else if (m_iKillsTeam1 > m_iKillsTeam2) {
			m_iScoreTeam2++;
			env_message_broadcast("Blue team has won!");
		} else {
			env_message_broadcast("Both teams are tied!");
		}

		forceinfokey(world, "teamscore_1", sprintf("%i", m_iScoreTeam1));
		forceinfokey(world, "teamscore_2", sprintf("%i", m_iScoreTeam2));
		think = RestartRound;
		nextthink = time + 5.0f;
		break;
	}
}

void
SHTeamRules::InitPostEnts(void)
{
	forceinfokey(world, "teamkills_1", sprintf("%i", m_iKillsTeam1));
	forceinfokey(world, "teamkills_2", sprintf("%i", m_iKillsTeam2));
	forceinfokey(world, "teams", "2");
	forceinfokey(world, "team_1", "Red");
	forceinfokey(world, "teamscore_1", "0");
	forceinfokey(world, "team_2", "Blue");
	forceinfokey(world, "teamscore_2", "0");
}

void
SHTeamRules::RestartRound(void)
{
	super::RestartRound();

	m_iKillsTeam1 = 0;
	m_iKillsTeam2 = 0;
	forceinfokey(world, "teamkills_1", sprintf("%i", m_iKillsTeam1));
	forceinfokey(world, "teamkills_2", sprintf("%i", m_iKillsTeam2));
}

void
SHTeamRules::SHTeamRules(void)
{
	m_iKillsTeam1 = 0;
	m_iKillsTeam2 = 0;
}
