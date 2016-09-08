/*
 * image_store_regs.h
 *
 *  Created on: 2016-8-19
 *      Author: Yogurt_SYS
 */

#ifndef IMAGE_STORE_REGS_H_
#define IMAGE_STORE_REGS_H_

#include <io.h>

#define IOWR_STORER_WRITE_ENABLE(base)				IOWR(base, 0, 0x1)
#define IOWR_STORER_WRITE_ADDRESS(base, data)		IOWR(base, 2, data)
#define IOWR_STORER_FRAMES_COUNT(base, data)		IOWR(base, 3, data)

#endif /* IMAGE_STORE_REGS_H_ */
