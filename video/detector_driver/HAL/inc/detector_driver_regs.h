/*
 * detector_driver_regs.h
 *
 *  Created on: 2016-9-1
 *      Author: Yogurt_SYS
 */

#ifndef DETECTOR_DRIVER_REGS_H_
#define DETECTOR_DRIVER_REGS_H_

#include <io.h>

#define DETECTOR_OUT_VIDEO			1
#define DETECTOR_OUT_BACKGROUND		0

#define IOWR_DETECTOR_NRST(base, data)			IOWR(base, 0, data)
#define IORD_DETECTOR_VTEMP(base)				IORD(base, 1)
#define IOWR_DETECTOR_I2C_ADDR(base, data)		IOWR(base, 3, data)
#define IOWR_DETECTOR_OUT_SELECT(base, data)	IOWR(base, 4, data)
#define IOWR_DETECTOR_BACKGROUND(base, data)	IOWR(base, 5, data)

#endif /* DETECTOR_DRIVER_REGS_H_ */
