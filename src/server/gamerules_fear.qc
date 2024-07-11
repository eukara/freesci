void
SHGameFear::SHGameFear(void)
{

}


void
SHGameFear::ScientistKill(NSClientPlayer pp, entity sci)
{
	SHPlayer pl = (SHPlayer)pp;

	if (pl.IsScientist() == true) {
		pl.frags++;
	} else {
		pl.frags--;
	}
}

string
SHGameFear::Title(void)
{
	return ("Stealth");
}