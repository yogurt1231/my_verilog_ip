#include "../inc/pll_interface.h"
#include <io.h>

unsigned char pll_read_locked(unsigned int addr);
unsigned char pll_read_phasedone(unsigned int addr);

void pll_set_areset(unsigned int addr, unsigned char areset);
void pll_set_pfdena(unsigned int addr, unsigned char pfdena);

void pll_phase_up(unsigned int addr, unsigned short conter);
void pll_phase_down(unsigned int addr, unsigned short conter);

void pll_phase_ups(unsigned int addr, unsigned short conter, unsigned short cnt);
void pll_phase_downs(unsigned int addr, unsigned short conter, unsigned short cnt);

unsigned char pll_read_locked(unsigned int addr)
{
	unsigned char locked;
	locked = IORD(addr,0);
	return (locked & 0x01);
}

unsigned char pll_read_phasedone(unsigned int addr)
{
	unsigned char phasedone;
	phasedone = IORD(addr,0);
	return (phasedone & 0x02);
}

void pll_set_areset(unsigned int addr, unsigned char areset)
{
	unsigned char control;
	control = IORD(addr,1);
	control = (control & 0x20) | areset;
	IOWR(addr,1,control);
}

void pll_set_pfdena(unsigned int addr, unsigned char pfdena)
{
	unsigned char control;
	control = IORD(addr,1);
	control = (control & 0x01) | pfdena;
	IOWR(addr,1,control);
}

void pll_phase_up(unsigned int addr, unsigned short conter)
{
	unsigned int phase_reconfig_control;
	phase_reconfig_control = 0x40000000 | conter;
	while(!pll_read_phasedone(addr));
	IOWR(addr,2,phase_reconfig_control);
	while(!pll_read_phasedone(addr));
}

void pll_phase_down(unsigned int addr, unsigned short conter)
{
	unsigned int phase_reconfig_control;
	phase_reconfig_control = 0x80000000 | conter;
	while(!pll_read_phasedone(addr));
	IOWR(addr,2,phase_reconfig_control);
	while(!pll_read_phasedone(addr));
}

void pll_phase_ups(unsigned int addr, unsigned short conter, unsigned short cnt)
{
	unsigned short i;
	for(i=0;i<cnt;i++) pll_phase_up(addr,conter);
}

void pll_phase_downs(unsigned int addr, unsigned short conter, unsigned short cnt)
{
	unsigned short i;
	for(i=0;i<cnt;i++) pll_phase_down(addr,conter);
}
