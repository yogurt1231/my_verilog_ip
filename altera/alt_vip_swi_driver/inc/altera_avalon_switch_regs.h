/*
 * altera_avalon_switch_regs.h
 *
 *  Created on: 2016-7-14
 *      Author: Yogurt_SYS
 */

#ifndef ALTERA_AVALON_SWITCH_REGS_H_
#define ALTERA_AVALON_SWITCH_REGS_H_

#include <io.h>

#define IOWR_SWITCH_CONTROL(base, data)				IOWR(base, 0, data)
#define IORD_SWITCH_STATUS(base, data)				IORD(base, 1)
#define IOWR_SWITCH_OUTPUT_SWITCH(base, data)		IOWR(base, 2, data)
#define IOWR_SWITCH_DOUT_NOT_OUTPUT(base, dout)		IOWR(base, (3+(dout)), 0)
#define IOWR_SWITCH_DOUT_CONTROL(base, dout, din)	IOWR(base, (3+(dout)), (1<<din))

#endif /* ALTERA_AVALON_SWITCH_REGS_H_ */
