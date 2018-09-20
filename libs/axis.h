#ifndef AXIS_H_
#define AXIS_H_

typedef struct {
  volatile uint32_t DATA;
  volatile uint32_t STATUS;
} AXIS_Reg;

static uint32_t axis_status(AXIS_Reg *reg) {
	return (reg->STATUS >> 16) & 0x07;
}

static void axis_write(AXIS_Reg *reg, uint32_t data) {
	while((axis_status(reg) & 0x02) != 0);
	reg->DATA = data;
}

#endif /* AXIS_H_ */


