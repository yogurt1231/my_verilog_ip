/*
 * altera_avalon_clipper_regs.h
 *
 *  Created on: 2016-7-14
 *      Author: Yogurt_SYS
 */

#ifndef ALTERA_AVALON_CLIPPER_REGS_H_
#define ALTERA_AVALON_CLIPPER_REGS_H_

#include <io.h>

#define IOWR_CLIPPER_CONTROL(base, data)		IOWR(base, 0, data)
#define IORD_CLIPPER_STATUS(base, data)			IORD(base, 1)
#define IOWR_CLIPPER_LEFT(base, data)			IOWR(base, 2, data)
#define IOWR_CLIPPER_RIGHT(base, data)			IOWR(base, 3, data)
#define IOWR_CLIPPER_TOP(base, data)			IOWR(base, 4, data)
#define IOWR_CLIPPER_BOTTOM(base, data)			IOWR(base, 5, data)

#define CLIPPER_CONTROL_GO_MASK			1
#define CLIPPER_CONTROL_GO_OFST			0

#define ALTERA_AVALON_CLIPPER_SET_ALL(base, left, right, top, bottom)	\
	IOWR_CLIPPER_LEFT(base, left);										\
	IOWR_CLIPPER_RIGHT(base, right);									\
	IOWR_CLIPPER_TOP(base, top);										\
	IOWR_CLIPPER_BOTTOM(base, bottom);

#endif /* ALTERA_AVALON_CLIPPER_REGS_H_ */
