// $Id$

/*
 * "Copyright (c) 2000-2006 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */

/**
 * Implementation of the BlinkToRadio application.  A counter is
 * incremented and a radio message is sent whenever a timer fires.
 * Whenever a radio message is received, the three least significant
 * bits of the counter in the message payload are displayed on the
 * LEDs.  Program two motes with this application.  As long as they
 * are both within range of each other, the LEDs on both will keep
 * changing.  If the LEDs on one (or both) of the nodes stops changing
 * and hold steady, then that node is no longer receiving any messages
 * from the other node.
 *
 * @author Prabal Dutta
 * @date   Feb 1, 2006
 */
#include <Timer.h>
#include "DataToRadio.h"
#include "printf.h"

module DataToRadioC {
  uses interface Boot;
  uses interface Leds;
  uses interface Timer<TMilli> as Timer0;
  uses interface Packet;
  uses interface AMPacket;
  uses interface AMSend;
  uses interface Receive;
  uses interface SplitControl as AMControl;
  uses interface BigQueue<DataToRadioMsg> as Buffer;
  uses interface PacketAcknowledgements as ack;
  uses interface Random;
}

implementation {
  uint16_t interval;
  uint16_t counter;
  bool busy = FALSE;
  message_t pkt;
  uint16_t bufferBegin;
  uint16_t bufferEnd;

  void setLeds(uint16_t val) {
    if (val & 0x01)
      call Leds.led0On();
    else 
      call Leds.led0Off();
    if (val & 0x02)
      call Leds.led1On();
    else
      call Leds.led1Off();
    if (val & 0x04)
      call Leds.led2On();
    else
      call Leds.led2Off();
  }

  event void Boot.booted() {
    uint16_t i = 0;
    call AMControl.start();
    bufferBegin = 0;
    bufferEnd = 0;
    for (i = 0;i < 200;i ++){
      printf("%u\n", i);
      printfflush();
    }
  }

  event void AMControl.startDone(error_t err) {
    if (err == SUCCESS) {
    }
    else {
      call AMControl.start();
    }
  }

  event void AMControl.stopDone(error_t err) {
  }

  task void sendMessage(){
    counter++;
    if (!busy) {
      if (!(call Buffer.empty())){
        DataToRadioMsg* btrpkt = (DataToRadioMsg*)(call Packet.getPayload(&pkt, sizeof(DataToRadioMsg)));
        if (btrpkt == NULL) {
          return;
        }
        *btrpkt = call Buffer.head();
        call ack.requestAck(&pkt);
        if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(DataToRadioMsg)) == SUCCESS) {
          busy = TRUE;
        }
      }

    }
  }

  event void Timer0.fired() {
    post sendMessage();
  }

  event void AMSend.sendDone(message_t* msg, error_t err) {
    if (&pkt == msg) {
      busy = FALSE;
    }
  }


  // for receive packet
  event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
    if (len == sizeof(DataToRadioMsg)) {
      DataToRadioMsg* btrpkt = (DataToRadioMsg*)payload;
      // judge overhead
      if (call Buffer.size() == call Buffer.maxSize()){
          dbg("queue is full");
      }
      else{
        if (call Buffer.enqueue(*btrpkt) == SUCCESS){
          dbg("receive id = %d", btrpkt->id);
        }
        else{

        }
      }    
    }
    return msg;
  }
}
