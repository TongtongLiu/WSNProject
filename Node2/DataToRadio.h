// $Id$

#ifndef DATATORADIO_H
#define DATATORADIO_H

enum {
  MIN_INTERVAL = 100,
  INTERVAL_BITS = 9,
  NEXT_HOP = 3,
  SEND_ARRAY_LENGTH = 8,
  AM_DATATORADIOMSG = 7
};

typedef nx_struct DataToRadioMsg {
  nx_uint16_t id;
  nx_uint16_t retrans1to2;
  nx_uint16_t retrans2to3;
  nx_uint16_t data;
} DataToRadioMsg;

#endif
