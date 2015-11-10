#!/usr/bin/python2
# -*- coding:utf-8 -*-
__author__ = 'liutongtong'

import os
import re
import sys


def matcher(content):
    pattern = re.compile(r'\w*?: Message <DataToRadioMsg> \n  \[id=\w*?\]\n  '
                         r'\[resend1to2=\w*?\]\n  \[resend2to3=\w*?\]\n  '
                         r'\[buffer=\w*?\]\n  \[data=\w*?\]')
    matches = pattern.findall(content)

    timestamps = list()
    ids = list()
    resend1to2s = list()
    resend2to3s = list()
    buffers = list()

    pattern = re.compile(r'(?P<timestamp>\w*?): Message.*\n.*\n.*\n.*\n.*\n.*')
    for i in range(len(matches)):
        timestamps.append(int(pattern.sub(r'\g<timestamp>', matches[i])))

    pattern = re.compile(r'.*\n.*\[id=(?P<id>\w*?)\]\n.*\n.*\n.*\n.*')
    for i in range(len(matches)):
        ids.append(int(pattern.sub(r'\g<id>', matches[i]), 16))

    pattern = re.compile(r'.*\n.*\n.*\[resend1to2=(?P<resend1to2>\w*?)\]\n.*\n.*\n.*')
    for i in range(len(matches)):
        resend1to2s.append(int(pattern.sub(r'\g<resend1to2>', matches[i]), 16))

    pattern = re.compile(r'.*\n.*\n.*\n.*\[resend2to3=(?P<resend2to3>\w*?)\]\n.*\n.*')
    for i in range(len(matches)):
        resend2to3s.append(int(pattern.sub(r'\g<resend2to3>', matches[i]), 16))

    pattern = re.compile(r'.*\n.*\n.*\n.*\n.*\[buffer=(?P<buffer>\w*?)\]\n.*')
    for i in range(len(matches)):
        buffers.append(int(pattern.sub(r'\g<buffer>', matches[i]), 16))

    return timestamps, ids, resend1to2s, resend2to3s, buffers


def extractor(filename):
    with open(filename, 'r') as fp:
        content = fp.read()
        timestamps, ids, resend1to2s, resend2to3s, buffers = matcher(content)
    min_id = min(ids)
    packets = list()
    for i in range(max(ids) - min_id + 1):
        packets.append([0, 0, 0, 0])
    for i in range(len(ids)):
        packet = packets[ids[i] - min_id]
        if buffers[i] > 256:
            continue
        packet[0] = max(packet[0], timestamps[i])
        packet[1] = max(packet[1], resend1to2s[i])
        packet[2] = max(packet[2], resend2to3s[i])
        packet[3] = max(packet[3], buffers[i])
    return packets


def analysis(filename):
    print "%s" % filename

    packets = extractor(filename)
    sum_resend1to2 = 0
    sum_resend2to3 = 0
    sum_buffer = 0
    min_timestamp = 0
    max_timestamp = 0
    for packet in packets:
        sum_resend1to2 += packet[1]
        sum_resend2to3 += packet[2]
        sum_buffer += packet[3]
        if min_timestamp == 0 or (packet[0] != 0 and packet[0] < min_timestamp):
            min_timestamp = packet[0]
        if max_timestamp == 0 or (packet[0] != 0 and packet[0] > max_timestamp):
            max_timestamp = packet[0]
    valid_packets = 0
    for packet in packets:
        if packet != [0, 0, 0, 0]:
            valid_packets += 1
    total_time = max_timestamp - min_timestamp

    data_rate = float(valid_packets) / (float(total_time) / 1000.0)
    buffer_usage = float(sum_buffer) / float(valid_packets)
    loss_rate1to2 = float(sum_resend1to2) / float(sum_resend1to2 + valid_packets)
    loss_rate2to3 = float(sum_resend2to3) / float(sum_resend2to3 + valid_packets)
    loss_rate = float(sum_resend1to2 + sum_resend2to3) / float(sum_resend1to2 + sum_resend2to3 + valid_packets)
    
    print "total_packets: %d" % valid_packets
    print "data_rate: %f" % data_rate
    print "buffer_usage: %f" % buffer_usage
    print "loss_rate1to2: %f" % loss_rate1to2
    print "loss_rate2to3: %f" % loss_rate2to3
    print "loss_rate: %f" % loss_rate
    return filename, data_rate, buffer_usage, loss_rate1to2, loss_rate2to3, loss_rate


if __name__ == '__main__':
    results = list()
    for listing in os.listdir(os.path.dirname(os.path.abspath('__file__'))):
        [prefix, ext] = os.path.splitext(listing)
        if ext == '.txt' and prefix != 'README':
            results.append(analysis(listing))
    results = sorted(results, key=lambda x: x[0])
    with open('result.csv', 'w') as fp:
        for result in results:
            fp.write("%s, %s, %s, %s, %s, %s\n" %
                     (result[0], str(result[1]), str(result[2]), str(result[3]), str(result[4]), str(result[5])))

