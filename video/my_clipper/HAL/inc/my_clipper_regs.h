/*
 * my_clipper_regs.h
 *
 *  Created on: 2016-7-14
 *      Author: Yogurt_SYS
 */

#ifndef MY_CLIPPER_REGS_H_
#define MY_CLIPPER_REGS_H_

#define IOWR_MY_CLIPPER_CONTROL(base, data)		IOWR(base, 0, data)
#define IORD_MY_CLIPPER_STATUS(base)			IORD(base, 1)
#define IOWR_MY_CLIPPER_LEFT(base, data)		IOWR(base, 3, data)
#define IOWR_MY_CLIPPER_RIGHT(base, data)		IOWR(base, 4, data)
#define IOWR_MY_CLIPPER_TOP(base, data)			IOWR(base, 5, data)
#define IOWR_MY_CLIPPER_BOTTOM(base, data)		IOWR(base, 6, data)

#define MY_CLIPPER_SET_ALL(base, left, right, top, bottom)		\
	IOWR_MY_CLIPPER_LEFT(base, (left));							\
	IOWR_MY_CLIPPER_RIGHT(base, (right));						\
	IOWR_MY_CLIPPER_TOP(base, (top));							\
	IOWR_MY_CLIPPER_BOTTOM(base, (bottom))

#endif /* MY_CLIPPER_REGS_H_ */
