#include <io.h>
#include "../inc/i2c_avalon_driver.h"

void i2c_start(unsigned int base)
{
	IOWR(base,0x0,1);
}

void i2c_stop(unsigned int base)
{
	IOWR(base,0x0,0);
}

unsigned char i2c_get_ack(unsigned int base)
{
	return (IORD(base,0x0)>>1);
}

void i2c_write(unsigned int base,unsigned char data)
{
	IOWR(base,0x1,data);
}

unsigned char i2c_read_with_ack(unsigned int base)
{
	return IORD(base,0x2);
}

unsigned char i2c_read_with_nack(unsigned int base)
{
	return IORD(base,0x3);
}
