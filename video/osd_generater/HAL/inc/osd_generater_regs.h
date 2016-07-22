/*
 * osd_generater_regs.h
 *
 *  Created on: 2016-5-8
 *      Author: Yogurt_SYS
 */

#ifndef OSD_GENERATER_REGS_H_
#define OSD_GENERATER_REGS_H_

#define IOWR_OSD_CONTROL(base, data)			IOWR(base, 0, data)
#define IOWR_OSD_READ_ADDR(base, data)			IOWR(base, 2, data)
#define IOWR_OSD_VIDEO_NUM(base, data)			IOWR(base, 3, data)
#define IOWR_OSD_VIDEO_WIDTH(base, data)		IOWR(base, 4, data)
#define IOWR_OSD_VIDEO_HEIGHT(base, data)		IOWR(base, 5, data)
#define IOWR_OSD_VIDEO_DATAA(base, data)		IOWR(base, 6, data)
#define IOWR_OSD_VIDEO_DATAB(base, data)		IOWR(base, 7, data)

#endif /* OSD_GENERATER_REGS_H_ */
