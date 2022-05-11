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

#include "../../../src/server/gamerules.h"

class HLGameRules:CGameRules
{
	float m_flRestockTimer;
	float m_flBreakRespawnTimer;

	/* client */
	virtual void(NSClientPlayer) PlayerSpawn;
	virtual void(NSClientPlayer) PlayerConnect;
	virtual void(NSClientPlayer) PlayerDisconnect;
	virtual void(NSClientPlayer) PlayerKill;
	virtual void(NSClientPlayer) PlayerDeath;
	virtual void(NSClientPlayer) PlayerPostFrame;
	virtual void(NSClientPlayer, entity) ScientistKill;

	virtual void(NSClientPlayer) LevelDecodeParms;
	virtual void(NSClientPlayer) LevelChangeParms;
	virtual void(void) LevelNewParms;
	virtual void(void) FrameStart;
	virtual bool(void) IsMultiplayer;

	void(void) HLGameRules;
};
