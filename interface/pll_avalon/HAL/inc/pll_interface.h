#ifndef PLL_INTERFACE_H_
#define PLL_INTERFACE_H_

#define ALL_OUTPUT_COUNTERS	0x000
#define M_COUNTER			0x001
#define C0					0x100
#define C1					0x101
#define C2					0x102
#define C3					0x103
#define C4					0x104
#define C5					0x105
#define C6					0x106
#define C7					0x107
#define C8					0x108
#define C9					0x109

unsigned char pll_read_locked(unsigned int addr);
unsigned char pll_read_phasedone(unsigned int addr);

void pll_set_areset(unsigned int addr, unsigned char areset);
void pll_set_pfdena(unsigned int addr, unsigned char pfdena);

void pll_phase_up(unsigned int addr, unsigned short conter);
void pll_phase_down(unsigned int addr, unsigned short conter);

void pll_phase_ups(unsigned int addr, unsigned short conter, unsigned short cnt);
void pll_phase_downs(unsigned int addr, unsigned short conter, unsigned short cnt);

#endif /* PLL_INTERFACE_H_ */
