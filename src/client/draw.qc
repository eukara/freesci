/*
 * Copyright (c) 2016-2022 Vera Visions LLC.
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

var bool g_sciscore = false;

void
ClientGame_PreDraw(void) 
{

}

void
SH_DrawSciScore(void)
{
	string line;
	vector pos;

	line = "^xFA0Scientist round score info:";
	pos = (video_res / 2);
	pos[0] -= (Font_StringWidth(line, FALSE, FONT_CON) / 2);
	pos[1] -= 64;
	Font_DrawText(pos, line, FONT_CON);


	line = sprintf("^xFA0Team Red: %d kills", serverkeyfloat("teamkills_1"));
	pos = (video_res / 2);
	pos[0] -= (Font_StringWidth(line, FALSE, FONT_CON) / 2);
	pos[1] -= 36;
	Font_DrawText(pos, line, FONT_CON);


	line = sprintf("^xFA0Team Blue: %d kills", serverkeyfloat("teamkills_2"));
	pos = (video_res / 2);
	pos[0] -= (Font_StringWidth(line, FALSE, FONT_CON) / 2);
	pos[1] -= 24;
	Font_DrawText(pos, line, FONT_CON);


	line = sprintf("^xFA0Scientists left: %d", serverkeyfloat("sci_count"));
	pos = (video_res / 2);
	pos[0] -= (Font_StringWidth(line, FALSE, FONT_CON) / 2);
	Font_DrawText(pos, line, FONT_CON);
}

void
ClientGame_PostDraw(void)
{
	if (g_sciscore)
		SH_DrawSciScore();
}
