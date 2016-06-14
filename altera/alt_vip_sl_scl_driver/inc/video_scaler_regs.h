/*
 * video_scaler_regs.h
 *
 *  Created on: 2016-6-7
 *      Author: Yogurt_SYS
 */

#ifndef VIDEO_SCALER_REGS_H_
#define VIDEO_SCALER_REGS_H_

#include <io.h>

#define IOWR_SCLAER_CONTROL(base, data)					IOWR(base, 0, data)
#define IORD_SCLAER_STATUS(base, data)					IORD(base, 1)

#define IOWR_SCLAER_OUTPUT_WIDTH(base, data)			IOWR(base, 3, data)
#define IOWR_SCLAER_OUTPUT_HEIGHT(base, data)			IOWR(base, 4, data)
#define IOWR_SCLAER_EDGE_TS(base, data)					IOWR(base, 5, data)
#define IOWR_SCLAER_LOWER_BLUR_TS(base, data)			IOWR(base, 6, data)
#define IOWR_SCLAER_UPPER_BLUR_TS(base, data)			IOWR(base, 7, data)
#define IOWR_SCLAER_HOR_COE_WR_BANK(base, data)			IOWR(base, 8, data)
#define IOWR_SCLAER_HOR_COE_RD_BANK(base, data)			IOWR(base, 9, data)
#define IOWR_SCLAER_VER_COE_WR_BANK(base, data)			IOWR(base, 10, data)
#define IOWR_SCLAER_VER_COE_RD_BANK(base, data)			IOWR(base, 11, data)
#define IOWR_SCLAER_HOR_PHASE(base, data)				IOWR(base, 12, data)
#define IOWR_SCLAER_VER_PHASE(base, data)				IOWR(base, 13, data)
#define IOWR_SCLAER_COE_DATA(base, taps, data)			IOWR(base, (14 + taps), data)

#define SCLAER_CONTROL_GO_MASK		(1)
#define SCLAER_CONTROL_EACS_MASK	(2)		/* edge adaptive coefficient selection */
#define SCLAER_CONTROL_EAS_MASK		(4)		/* edge adaptive sharpening */

#endif /* VIDEO_SCALER_REGS_H_ */
