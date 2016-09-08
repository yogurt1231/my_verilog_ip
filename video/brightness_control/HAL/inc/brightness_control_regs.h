/*
 * brightness_control_regs.h
 *
 *  Created on: 2016-9-8
 *      Author: Yogurt_SYS
 */

#ifndef BRIGHTNESS_CONTROL_REGS_H_
#define BRIGHTNESS_CONTROL_REGS_H_

#include <io.h>

#define BRIGHT_INVERT		1
#define VRIGHT_NOT_INVERT	0

#define IOWR_BRIGHTNESS_CONTROL_INVERT(base, data)		IOWR(base, 2, data)
#define IOWR_BRIGHTNESS_CONTROL_GAIN(base, data)		IOWR(base, 3, data)

#endif /* BRIGHTNESS_CONTROL_REGS_H_ */
