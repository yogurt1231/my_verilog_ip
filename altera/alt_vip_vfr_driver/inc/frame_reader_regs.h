/*
 * frame_reader_regs.h
 *
 *  Created on: 2016-5-4
 *      Author: Yogurt_SYS
 */

#ifndef FRAME_READER_REGS_H_
#define FRAME_READER_REGS_H_

#include <io.h>

#define IOWR_READER_CONTROL(base, data)					IOWR(base, 0, data)
#define IORD_READER_STATUS(base, data)					IORD(base, 1)
#define IOWR_READER_INTERRUPT(base, data)				IOWR(base, 2, data)
#define IOWR_READER_FRAME_SELECT(base, data)			IOWR(base, 3, data)

#define IOWR_READER_FRAME_0_BASE_ADDRESS(base, data)	IOWR(base, 4, data)
#define IOWR_READER_FRAME_0_WORDS(base, data)			IOWR(base, 5, data)
#define IOWR_READER_FRAME_0_PATTERNS(base, data)		IOWR(base, 6, data)
#define IOWR_READER_FRAME_0_WIDTH(base, data)			IOWR(base, 8, data)
#define IOWR_READER_FRAME_0_HEIGHT(base, data)			IOWR(base, 9, data)
#define IOWR_READER_FRAME_0_INTERLACED(base, data)		IOWR(base, 10, data)

#define IOWR_READER_FRAME_1_BASE_ADDRESS(base, data)	IOWR(base, 11, data)
#define IOWR_READER_FRAME_1_WORDS(base, data)			IOWR(base, 12, data)
#define IOWR_READER_FRAME_1_PATTERNS(base, data)		IOWR(base, 13, data)
#define IOWR_READER_FRAME_1_WIDTH(base, data)			IOWR(base, 15, data)
#define IOWR_READER_FRAME_1_HEIGHT(base, data)			IOWR(base, 16, data)
#define IOWR_READER_FRAME_1_INTERLACED(base, data)		IOWR(base, 17, data)

#define READER_CONTROL_GO_MASK		(1)
#define READER_CONTROL_GO_SOFT		(0)
#define READER_CONTROL_INT_MASK		(2)
#define READER_CONTROL_INT_SOFT		(1)

#define VIDEO_PROGRESSIVE			0x2
#define VIDEO_INTERLACED_F0			0xA
#define VIDEO_INTERLACED_F1			0xE

/* ppw = single-cycle color patterns per words */
#define ALT_VIP_VFR_INIT(base, height, width, addr, interlaced, ppw)	\
	IOWR_READER_CONTROL(base, 0);										\
	IOWR_READER_FRAME_SELECT(base, 0);									\
	IOWR_READER_FRAME_0_BASE_ADDRESS(base, (unsigned long)(addr));		\
	IOWR_READER_FRAME_0_WORDS(base, (width)*(height)/(ppw));			\
	IOWR_READER_FRAME_0_PATTERNS(base, (width)*(height));				\
	IOWR_READER_FRAME_0_WIDTH(base, width);								\
	IOWR_READER_FRAME_0_HEIGHT(base, height);							\
	IOWR_READER_FRAME_0_INTERLACED(base, interlaced);					\
	IOWR_READER_CONTROL(base, 1);

#endif /* FRAME_READER_REGS_H_ */
