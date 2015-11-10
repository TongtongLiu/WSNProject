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

module DataToRadioC {
  uses interface Boot;
  uses interface Leds;
  uses interface Timer<TMilli> as SenderTimer;
  uses interface Timer<TMilli> as GeneratorTimer;
  uses interface LocalTime<TMilli> as LocalTimer;
  uses interface Packet;
  uses interface AMPacket;
  uses interface AMSend;
  uses interface SplitControl as AMControl;
  uses interface Random;
  uses interface PacketAcknowledgements as Ack;
}
implementation {
  uint32_t counter = 0;
  uint32_t interval = MIN_INTERVAL * 2;
  uint32_t sendstart;
  uint32_t sendstop;
  uint32_t data[SIZE_OF_QUEUE];
  uint32_t generatorptr = 0;
  uint32_t senderptr = 0;
  uint32_t lastsend = SIZE_OF_QUEUE - 1;
  bool busy = FALSE;
  bool full = FALSE;
  message_t pkt;
  
  void showSuccess() {
    call Leds.led0Toggle();
  }

  void showResend() {
    call Leds.led1Toggle();
  }

  void showFull() {
    call Leds.led2Toggle();
  }

  int32_t getRandom(int32_t minv, int32_t range) {
    int32_t randv, result;
    randv = call Random.rand32();
    if (randv < 0) {
      randv = -1 * randv;
    }
    result = minv + randv % 1024;
    return result;
  }

  task void sendMsg() {
    if (!busy) {
      DataToRadioMsg* dtrpkt = (DataToRadioMsg*)(call Packet.getPayload(&pkt, sizeof(DataToRadioMsg)));
      if (dtrpkt == NULL) {
        return;
      }
      if (senderptr != lastsend) {
        dtrpkt->id = counter;
        dtrpkt->data = data[senderptr];
        dtrpkt->resend1to2 = 0;
        dtrpkt->resend2to3 = 0;
      }
      else {
        dtrpkt->resend1to2 += 1;
      }
      call Ack.requestAck(&pkt);

      if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(DataToRadioMsg)) == SUCCESS) {
        counter++;
        lastsend = senderptr;
        busy = TRUE;
      }
      else {
        post sendMsg();
      }
    }
  }

  event void Boot.booted() {
    call AMControl.start();
  }

  event void AMControl.startDone(error_t err) {
    if (err == SUCCESS) {
      call GeneratorTimer.startPeriodic(MIN_INTERVAL);
      call SenderTimer.startOneShot(interval);
    }
    else {
      call AMControl.start();
    }
  }

  event void AMControl.stopDone(error_t err) {}

  event void GeneratorTimer.fired() {
    if (!full) {
      data[generatorptr] = getRandom(MIN_INTERVAL, INTERVAL_RANGE);
      generatorptr = (generatorptr + 1) % SIZE_OF_QUEUE;
      if (generatorptr == senderptr) {
        full = TRUE;
      }
    }
  }

  event void SenderTimer.fired() {
    if (full || generatorptr != senderptr) {
      interval = date[sendptr];
      post sendMsg();
    }
    call SenderTimer.startOneShot(interval);
  }

  event void AMSend.sendDone(message_t* msg, error_t err) {
    if (err == SUCCESS && &pkt == msg) {
      if (call Ack.wasAcked(msg)) {
        showSuccess();
        senderptr = (senderptr + 1) % SIZE_OF_QUEUE;
        full = FALSE;
        busy = FALSE;
      }
      else {
        showResend();
        busy = FALSE;
        post sendMsg();
      }
    }
    else {
      busy = FALSE;
      post sendMsg();
    }
  }
}
