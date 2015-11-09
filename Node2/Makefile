COMPONENT=BlinkToRadioAppC
BUILD_EXTRA_DEPS += BlinkToRadio.class
CLEAN_EXTRA = *.class BlinkToRadioMsg.java

CFLAGS += -I$(TOSDIR)/lib/T2Hack

BlinkToRadio.class: $(wildcard *.java) BlinkToRadioMsg.java
	javac -target 1.4 -source 1.4 *.java

BlinkToRadioMsg.java:
	mig java -target=null $(CFLAGS) -java-classname=BlinkToRadioMsg BlinkToRadio.h BlinkToRadioMsg -o $@

CFLAGS += -DCC2420_DEF_CHANNEL=7
include $(MAKERULES)

