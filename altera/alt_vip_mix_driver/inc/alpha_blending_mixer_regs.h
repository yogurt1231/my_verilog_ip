/*
 * alpha_blending_mixer_regs.h
 *
 *  Created on: 2016-5-4
 *      Author: Yogurt_SYS
 */

#ifndef ALPHA_BLENDING_MIXER_REGS_H_
#define ALPHA_BLENDING_MIXER_REGS_H_

#include <io.h>

#define IOWR_MIXER_CONTROL(base, data)				IOWR(base, 0, data)
#define IORD_MIXER_STATUS(base, data)				IORD(base, 1)

#define IOWR_MIXER_LAYER_X(base, layer, data)		IOWR(base, 3*(layer)-1, data)
#define IOWR_MIXER_LAYER_Y(base, layer, data)		IOWR(base, 3*(layer), data)
#define IOWR_MIXER_LAYER_ACTIVE(base, layer, data)	IOWR(base, 3*(layer)+1, data)

#define MIXER_CONTROL_GO_MASK			1
#define MIXER_CONTROL_GO_OFST			0

#define MEXER_ACTIVE_NOT_PULL_OUT		0
#define MEXER_ACTIVE_DISPLAY			1
#define MEXER_ACTIVE_CONSUMED			2

#endif /* ALPHA_BLENDING_MIXER_REGS_H_ */
