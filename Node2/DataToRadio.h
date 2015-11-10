// $Id$

#ifndef DATATORADIO_H
#define DATATORADIO_H

enum {
  MIN_INTERVAL = 40,
  SIZE_OF_QUEUE = 256,
  DATA_MIN = 0,
  DATA_RANGE = 1024,
  NEXT_HOP = 3,
  AM_DATATORADIOMSG = 7
};

typedef nx_struct DataToRadioMsg {
  nx_uint16_t id;
  //nx_uint16_t nodeid;
  nx_uint16_t resend1to2;
  nx_uint16_t resend2to3;
  nx_uint16_t buffer;
  nx_uint16_t data;
} DataToRadioMsg;

#endif
