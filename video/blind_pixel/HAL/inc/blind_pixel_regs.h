/*
 * blind_pixel_regs.h
 *
 *  Created on: 2016-10-17
 *      Author: Yogurt_SYS
 */

#ifndef BLIND_PIXEL_REGS_H_
#define BLIND_PIXEL_REGS_H_

#include <io.h>

#define BLIND_PIXEL_MODE_VIDEO			0x00
#define BLIND_PIXEL_MODE_ENABLE 		0x01
#define BLIND_PIXEL_MODE_BACKGROUND		0x02
#define BLIND_PIXEL_MODE_TEST			0x03

#define IOWR_BLINX_PIXEL_CONTROL(base, data)			IOWR(base, 0, data)
#define IOWR_BLINX_PIXEL_BACKGROUND(base, data)			IOWR(base, 3, data)

#endif /* BLIND_PIXEL_REGS_H_ */
