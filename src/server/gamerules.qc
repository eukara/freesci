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
HLGameRules::LevelDecodeParms(NSClientPlayer pp)
{
	SHPlayer pl = (SHPlayer)pp;
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

}

void
HLGameRules::LevelChangeParms(NSClientPlayer pp)
{
	SHPlayer pl = (SHPlayer)pp;
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
	SHPlayer pl = (SHPlayer)pp;

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
	SHPlayer pl = (SHPlayer)pp;

	/* obituary networking */
	if (cvar("sh_announcescideath") == 1) {
		WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
		WriteByte(MSG_MULTICAST, EV_OBITUARY);
		WriteString(MSG_MULTICAST, pl.netname);
		WriteString(MSG_MULTICAST, sci.netname);
		WriteByte(MSG_MULTICAST, g_dmg_iWeapon);
		WriteByte(MSG_MULTICAST, 0);
		msg_entity = world;
		multicast([0,0,0], MULTICAST_ALL);
	}

	/* give players a frag per scientist they kill */
	pl.frags++;

#if 0
	/* only reward melee frags for insanity, otherwise it's a bit OP */
	if (g_weapons[g_dmg_iWeapon].slot != 0)
		return;
#endif

	if (cvar("sh_insanity") == 0)
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
	if (cvar("timelimit"))
	if (time >= (cvar("timelimit") * 60)) {
		IntermissionStart();
	}

	entity e;

	/* restock players every 2 minutes */
	if (m_flRestockTimer < time) {
		m_flRestockTimer = time + 120.0f;
		
		for (e = world; (e = find(e, ::classname, "player"));) {
			SHPlayer pl = (SHPlayer)e;

			/* Don't give spectators weapons */
			if (pl.IsFakeSpectator() == false && pl.IsRealSpectator() == false)
			SHData_GetItems(pl);
		}
	}

	/* respawn breakables every 2 minutes */
	if (cvar("sh_respbreak") == 1) {
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
}

void
HLGameRules::CheckRules(void)
{
	/* last person who killed somebody has hit the limit */
	if (cvar("fraglimit"))
	if (g_dmg_eAttacker.frags >= cvar("fraglimit"))
		IntermissionStart();
}

void
HLGameRules::PlayerDeath(NSClientPlayer pl)
{
	SHPlayer sh_pl = (SHPlayer)pl;
	
	/* obituary networking */
	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, EV_OBITUARY);
	WriteString(MSG_MULTICAST, (g_dmg_eAttacker.netname) ? g_dmg_eAttacker.netname : g_dmg_eAttacker.classname);
	WriteString(MSG_MULTICAST, pl.netname);
	WriteByte(MSG_MULTICAST, g_dmg_iWeapon);
	WriteByte(MSG_MULTICAST, 0);
	msg_entity = world;
	multicast([0,0,0], MULTICAST_ALL);

	Plugin_PlayerObituary(g_dmg_eAttacker, g_dmg_eTarget, g_dmg_iWeapon, g_dmg_iHitBody, g_dmg_iDamage);

	/* death-counter */
	pl.deaths++;
	pl.SetInfoKey("*deaths", ftos(pl.deaths));

	/* update score-counter */
	if (pl.flags & FL_CLIENT || pl.flags & FL_MONSTER)
	if (g_dmg_eAttacker.flags & FL_CLIENT) {
		if (pl == g_dmg_eAttacker)
			g_dmg_eAttacker.frags--;
		else
			g_dmg_eAttacker.frags++;
	}

#ifdef VALVE
	/* explode all satchels */
	//s_satchel_detonate((entity)pl);
	/* drop their posessions into a weaponbox item */
	//weaponbox_spawn((SHPlayer)pl);
#endif

	/* either gib, or make a corpse */
	if (pl.health < -50) {
		vector gibDir = vectoangles(pl.origin - g_dmg_eAttacker.origin);
		float gibStrength = g_dmg_iDamage * 2.0f;
		BreakModel_Entity(pl, gibDir, gibStrength);
	} else {
		FX_Corpse_Spawn((SHPlayer)pl, ANIM_DIESIMPLE);
	}

	/* now let's make the real client invisible */
	//pl.Death();
	pl.SetTakedamage(DAMAGE_NO);
	pl.gflags &= ~GF_FLASHLIGHT;
	pl.gflags &= ~GF_EGONBEAM;
	pl.gflags &= ~GF_MADNESS;
	pl.poisonTimer.StopTimer();

	sh_pl.sh_insaneactive = 0.0f;

	Sound_Play(pl, CHAN_AUTO, "player.die");

	/* force respawn */
	if (cvar("mp_forcerespawn") == 1) {
		pl.ScheduleThink(PutClientInServer, 4.0f);
	}

	/* have we gone over the fraglimit? */
	CheckRules();
}

bool
HLGameRules::PlayerRequestRespawn(NSClientPlayer bp)
{
	if (bp.TimeSinceDeath() > 0.5f) {
		bp.ScheduleThink(PutClientInServer, 0.0f);
		return true;
	}

	return false;
}

void
HLGameRules::PlayerSpawn(NSClientPlayer pp)
{
	SHPlayer pl = (SHPlayer)pp;
	/* this is where the mods want to deviate */
	entity spot;

	pl.MakePlayer();
	pl.classname = "player";
	pl.SetMaxHealth(100);
	pl.SetHealth(100);
	pl.SetTakedamage(DAMAGE_YES);
	pl.SetSolid(SOLID_SLIDEBOX);
	pl.SetMovetype(MOVETYPE_WALK);
	pl.AddFlags(FL_CLIENT);
	pl.viewzoom = 1.0;
	pl.model = "models/player.mdl";
	string mymodel = infokey(pl, "model");

	if (pl.team == 1) {
		pl.model = "models/scientist.mdl";
		setmodel(pl, pl.model);
		pl.SetSize(VEC_HULL_MIN + [0, 0, 64], VEC_HULL_MAX + [0, 0, 64]);
	} else {
		if (mymodel) {
			mymodel = sprintf("models/player/%s/%s.mdl", mymodel, mymodel);
			if (whichpack(mymodel)) {
				pl.model = mymodel;
			}
		}
		setmodel(pl, pl.model);
		pl.SetSize(VEC_HULL_MIN, VEC_HULL_MAX);
	}

	pl.ClearVelocity();
	pl.gravity = __NULL__;
	pl.SetFrame(1);
	pl.SendFlags = UPDATE_ALL;
	pl.SetInfoKey("*spec", "0");
	pl.SetInfoKey("*dead", "0");
	pl.SetInfoKey("*deaths", ftos(pl.deaths));
	pl.SetPropData("actor_human");
	pl.EnableBleeding();

	/* if we have team flags set, then join a team spawn 
	 * search for the entity though in case we're on a non scihunt map */
	if (pl.team == 1) {
		for (entity e = world; (e = find( e, ::classname, "info_player_team1"));) {
			spot = Spawn_SelectRandom("info_player_team1");
		}

	} else if (pl.team == 2) {
		for (entity e = world; (e = find( e, ::classname, "info_player_team2"));) {
			spot = Spawn_SelectRandom("info_player_team2");
		}
	}

	/* while different behaviour from original, this could be better for other gamemodes */
	for (entity e = world; (e = find( e, ::classname, "info_player_deathmatch"));) {
			spot = Spawn_SelectRandom("info_player_deathmatch");
	}


	/* all gamemodes use scihunt team spawns by default */
	if (!spot) {
		int r = floor(random(0,1));
		switch (r) {
		case 0:
			for (entity e = world; (e = find( e, ::classname, "info_player_team1"));) {
				spot = Spawn_SelectRandom("info_player_team1");
			}
			break;
		case 1:
			for (entity e = world; (e = find( e, ::classname, "info_player_team2"));) {
				spot = Spawn_SelectRandom("info_player_team2");
			}
			break;
		}
	}

	/* if nothing else is found, then look for standard half-life spawns (compat) */
	if (!spot) {
		for (entity e = world; (e = find( e, ::classname, "info_player_start"));) {
			spot = Spawn_SelectRandom("info_player_start");
		}
	}

	pl.SetOrigin(spot.origin);
	pl.SetAngles(spot.angles);
	Client_FixAngle(pl, pl.angles);

	pl.GiveItem("item_suit");
	SHData_GetItems(pl);
}

void
HLGameRules::InitPostEnts(void)
{
	MOTD_LoadDefault();

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
	/* HACK we'll set this here for now to ensure we don't
	 * have a race condition */
	forceinfokey(world, "sci_count", "0");

	/* if the previous map set this value but the current doesn't
	 * then set the default */
	cvar_set("sh_scispeed","40");

	cvar_set("fraglimit",cvar_string("mp_fraglimit"));

	cvar_set("timelimit",cvar_string("mp_timelimit"));

	/* this is in the settings.scr, leftover? */
	cvar_set("sh_levelexec",cvar_string("lvlconfig"));

	/* since Nuclide adopted levelexec, let's just set it like this for compat */
	cvar_set("sv_levelexec",cvar_string("sh_levelexec"));

	if (cvar("sh_levelexec") != 0) {
		/* just re-read this to prevent race conditions */
		//readcmd(sprintf("exec maps/%s.cfg\n", mapname));
	}

	/* always broadcast how many max scientists the server has set 
	 * but allow an override for server admins */
	if (cvar("sh_scimax_override") != 0) {
		forceinfokey(world, "sv_scimax", cvar_string("sh_scimax_override"));
	} else {
		forceinfokey(world, "sv_scimax", cvar_string("sh_scimax"));
	}

}

bool
HLGameRules::ConsoleCommand(NSClientPlayer pp, string cmd)
{
	tokenize(cmd);

	switch (argv(0)) {
	case "jumptest":
		makevectors(pp.v_angle);
		traceline(pp.origin + pp.view_ofs, pp.origin + pp.view_ofs + v_forward * 1024, FALSE, pp);
		pp.velocity = Route_GetJumpVelocity(pp.origin, trace_endpos, pp.gravity);
		break;
	default:
		return (false);
	}

	return (true);
}

/* TEAMPLAY ONLY LOGIC */
bool
SHTeamRules::IsTeamplay(void)
{
	return true;
}

void
SHTeamRules::PlayerSpawn(NSClientPlayer pp)
{
	SHPlayer pl = (SHPlayer)pp;

	if (pl.team > 0) {
		super::PlayerSpawn(pl);
		return;
	}

	pl.MakeTempSpectator(); /* replace this with a non-spectator ghost */
	Spawn_ObserverCam(pl);
}

void
SHTeamRules::ScientistKill(NSClientPlayer cl, entity sci)
{
	super::ScientistKill(cl, sci);

	if (cl.team == 2) {
		AddTeam2Kill();
	} else if (cl.team == 1) {
		AddTeam1Kill();
	}
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

/* teamplay scientist death tracking */
void
SHTeamRules::RegisterSciDeath(void)
{
	super::RegisterSciDeath();

	/* if no scientists are left then stop */
	if (m_iScientistsAlive > 0) {
		return;
	}

	/* award the kill to the appropiate team */
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
}

void
SHTeamRules::InitPostEnts(void)
{
	MOTD_LoadDefault();

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

/* invasion scientist death tracking */
void
SHInvasionRules::RegisterSciDeath(void)
{
	super::RegisterSciDeath();

	/* if no scientists are left then we win */
	if (m_iScientistsAlive > 0) {
		return;
	}

	env_message_broadcast("You have survived!\nCan you do it again?");

	think = RestartRound;
	nextthink = time + 5.0f;
}

void
SHInvasionRules::PlayerDeath(NSClientPlayer pl)
{
	pl = (SHPlayer)pl;
	super::PlayerDeath(pl);
	pl.MakeTempSpectator();

}

string
SHInvasionRules::Title(void)
{
	return ("Invasion");
}

void
SHInvasionRules::SHInvasionRules(void)
{

}



void
TriggerFlashlight(NSClient target)
{
	entity oldself = self;
	self = target;
	Flashlight_Toggle();
	self = oldself;
}

bool
HLGameRules::ImpulseCommand(NSClient bp, float num)
{
	switch (num) {
	case 100:
		TriggerFlashlight(bp);
		break;
	default:
		return super::ImpulseCommand(bp, num);
	}

	return true;
}

void
CSEv_JoinAuto(void)
{
	SHTeamRules rules = (SHTeamRules)g_grMode;
	SHPlayer pl = (SHPlayer)self;
	int red = 0;
	int blue = 0;

	/* matches Game_InitRules() */
	if (cvar("sv_playerslots") == 1 || cvar("coop") == 1) {
		return;
	}

	/* count for auto-balance */
	for (entity e = world; (e = find( e, ::classname, "player"));) {
		if (e == pl) {
			continue;
		}

		if (e.team == 1) {
			red++;
		}

		if (e.team == 2) {
			blue++;
		}
	}

	/* assign to whatever team has fewer players */
	if (red > blue) {
		pl.team = 2;
	} else {
		pl.team = 1;
	}

	forceinfokey(pl, "*team", sprintf("%d", pl.team));
	rules.PlayerSpawn(pl);
}

void
CSEv_JoinTeam_f(float teamNumber)
{
	SHTeamRules rules = (SHTeamRules)g_grMode;
	SHPlayer pl = (SHPlayer)self;

	/* matches Game_InitRules() */
	if (cvar("sv_playerslots") == 1 || cvar("coop") == 1) {
		return;
	}

	pl.team = teamNumber;
	forceinfokey(pl, "*team", sprintf("%d", pl.team));
	breakpoint();

	rules.PlayerSpawn(pl);
}

void
CSEv_JoinSpectator(void)
{
	SHTeamRules rules = (SHTeamRules)g_grMode;
	SHPlayer pl = (SHPlayer)self;
	pl.team = 0;
	forceinfokey(pl, "*team", sprintf("%d", pl.team));
	rules.PlayerSpawn(pl);
}