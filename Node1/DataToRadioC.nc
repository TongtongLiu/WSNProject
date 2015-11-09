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
  uses interface Timer<TMilli> as IntervalTimer;
  uses interface Timer<TMilli> as ResendTimer;
  uses interface Packet;
  uses interface AMPacket;
  uses interface AMSend;
  uses interface SplitControl as AMControl;
  uses interface Random;
  uses interface PacketAcknowledgements as Ack;
}
implementation {

  uint16_t counter = 0;
  uint16_t interval;
  bool busy = FALSE;
  message_t pkt[SEND_ARRAY_LENGTH];
  uint16_t ackflag[SEND_ARRAY_LENGTH];
  uint16_t sendbase = 0;
  uint16_t nextseqnum = 0;
  uint16_t resendTimeout = 500;

  int16_t getInterval(int16_t min, int16_t bits) {
	int16_t r = call Random.rand16();
	int16_t result;
	if (r < 0) {
	  r = -1 * r;
	}
	result = min + r / (1 >> (16 - bits));
	return result;
  }

  void showSuccess() {
	call Leds.led0Toggle();
  }

  void showFull() {
	call Leds.led1Toggle();
  }

  void showResend() {
	call Leds.led2Toggle();
  }

  task void resendMsg() {
	if (!busy) {
      DataToRadioMsg* dtrpkt = (DataToRadioMsg*)(call Packet.getPayload(&(pkt[sendbase]), sizeof(DataToRadioMsg)));
      if (dtrpkt == NULL) {
		return;
      }
	  dtrpkt->resend1to2 += 1;

      if (call AMSend.send(NEXT_HOP, &(pkt[sendbase]), sizeof(DataToRadioMsg)) == SUCCESS) {
        busy = TRUE;
		showResend();
      }
	  else {
		post resendMsg();
	  }
    }
  }

  task void sendMsg() {
    if (!busy && ackflag[nextseqnum]) {
      DataToRadioMsg* dtrpkt = (DataToRadioMsg*)(call Packet.getPayload(&(pkt[nextseqnum]), sizeof(DataToRadioMsg)));
      if (dtrpkt == NULL) {
		return;
      }
      dtrpkt->id = counter;
	  dtrpkt->resend1to2 = 0;
	  dtrpkt->resend2to3 = 0;
      dtrpkt->data = interval;
	  call Ack.requestAck(&(pkt[nextseqnum]));

      if (call AMSend.send(NEXT_HOP, &(pkt[nextseqnum]), sizeof(DataToRadioMsg)) == SUCCESS) {
		ackflag[nextseqnum] = 0;
		counter++;
		if (sendbase == nextseqnum) {
		  call ResendTimer.startOneShot(resendTimeout);
		}
		nextseqnum = (nextseqnum + 1) % SEND_ARRAY_LENGTH;
        busy = TRUE;
      }
	  else {
		post sendMsg();
	  }
    }
	else {
	  if (!ackflag[nextseqnum]) {
		showFull();
		post resendMsg();
	  }
	}
  }

  event void Boot.booted() {
    call AMControl.start();
  }

  event void AMControl.startDone(error_t err) {
	uint16_t i = 0;
    if (err == SUCCESS) {
	  for (i = 0; i < SEND_ARRAY_LENGTH; i++) {
	    ackflag[i] = 1;
	  }
	  interval = getInterval(MIN_INTERVAL, INTERVAL_BITS);
      call IntervalTimer.startOneShot(interval);
    }
    else {
      call AMControl.start();
    }
  }

  event void AMControl.stopDone(error_t err) {
  }

  event void IntervalTimer.fired() {
	post sendMsg();

	interval = getInterval(MIN_INTERVAL, INTERVAL_BITS);
	call IntervalTimer.startOneShot(interval);
  }

  event void AMSend.sendDone(message_t* msg, error_t err) {
	DataToRadioMsg* dtrpkt;
    if (err == SUCCESS) {
      busy = FALSE;
	  if (call Ack.wasAcked(msg)) {
		showSuccess();
		dtrpkt = (DataToRadioMsg*)(call Packet.getPayload(msg, sizeof(DataToRadioMsg)));
		ackflag[dtrpkt->id % SEND_ARRAY_LENGTH] = 1;
		while (ackflag[sendbase]) {
		  sendbase = (sendbase + 1) % SEND_ARRAY_LENGTH;
		}
	  }
    }
  }

  event void ResendTimer.fired() {
	post resendMsg();

	call ResendTimer.startOneShot(resendTimeout);
  }
}
