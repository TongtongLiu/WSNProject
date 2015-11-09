// $Id$

#ifndef DATATORADIO_H
#define DATATORADIO_H

enum {
  AM_DATATORADIOMSG = 7
};

typedef nx_struct DataToRadioMsg {
  nx_uint16_t id;
  nx_uint16_t data;
} DataToRadioMsg;

#endif
