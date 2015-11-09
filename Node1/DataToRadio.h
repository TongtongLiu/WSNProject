// $Id$

#ifndef DATATORADIO_H
#define DATATORADIO_H

enum {
  MIN_INTERVAL = 100,
  INTERVAL_BITS = 10,
  NEXT_HOP = 2,
  SEND_ARRAY_LENGTH = 8,
  AM_DATATORADIOMSG = 7
};

typedef nx_struct DataToRadioMsg {
  nx_uint16_t id;
  nx_uint16_t resend1to2;
  nx_uint16_t resend2to3;
  nx_uint16_t data;
} DataToRadioMsg;

#endif
