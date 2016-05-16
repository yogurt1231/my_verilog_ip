#ifndef I2C_AVALON_DRIVER_H_
#define I2C_AVALON_DRIVER_H_

void i2c_start(unsigned int base);
void i2c_stop(unsigned int base);
unsigned char i2c_get_ack(unsigned int base);
void i2c_write(unsigned int base,unsigned char data);
unsigned char i2c_read_with_ack(unsigned int base);
unsigned char i2c_read_with_nack(unsigned int base);

#endif /* I2C_AVALON_DRIVER_H_ */
