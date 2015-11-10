COMPONENT=DataToRadioAppC
BUILD_EXTRA_DEPS += DataToRadio.class
CLEAN_EXTRA = *.class DataToRadioMsg.java

CFLAGS += -I$(TOSDIR)/lib/T2Hack

DataToRadio.class: $(wildcard *.java) DataToRadioMsg.java
	javac -target 1.4 -source 1.4 *.java

DataToRadioMsg.java:
	mig java -target=null $(CFLAGS) -java-classname=DataToRadioMsg DataToRadio.h DataToRadioMsg -o $@

CFLAGS += -DCC2420_DEF_CHANNEL=7
//CFLAGS += -I$(TOSDIR)/lib/printf
include $(MAKERULES)

