#!/usr/bin/python

# Howto, Code license, Credits, etc: http://sourceforge.net/projects/triathlon/


import numpy

try:
    import usb
    haveLibUSB = True
except ImportError:
    haveLibUSB = False

try:
    from pywinusb import hid 
    havePyWinUSB = True
except ImportError:
    havePyWinUSB = False

if not(haveLibUSB) and not(havePyWinUSB):
    print "Error: You need either LibUSB or Pywinusb to connect with your headset."
    sys.exit(0)

import sys

from time import sleep 
import time
import threading

OCZ_NIA = 0
OCZ_NIAx2 = 1

SupportedDevices = {}
SupportedDevices["OCZ Neural Impulse Actuator"] = OCZ_NIA
SupportedDevices["2x OCZ Neural Impulse Actuator"] = OCZ_NIAx2

class NIA_Interface(): # LibUSB based
    def __init__(self,skipNIAs):
        self.VENDOR_ID = 0x1234 #: Vendor Id
        self.PRODUCT_ID = 0x0000 #: Product Id for the bridged usb cable
        self.TIME_OUT = 100
        self.handle = None
        self.device = None
        buses = usb.busses()
        found = False
        for bus in buses :
            for device in bus.devices :
                if device.idVendor == self.VENDOR_ID and device.idProduct == self.PRODUCT_ID:
                    if skipNIAs ==0:
                        self.device = device 
                        self.config = self.device.configurations[0]
                        self.interface = self.config.interfaces[0][0]
                        self.ENDPOINT1 = self.interface.endpoints[0].address
                        self.ENDPOINT2 = self.interface.endpoints[1].address
                        self.PACKET_LENGTH1 = self.interface.endpoints[0].maxPacketSize
                        self.PACKET_LENGTH2 = self.interface.endpoints[1].maxPacketSize
                        found = True
                        break
                    else:
                        skipNIAs -= 1
            if found:
                break
    def open(self) :
        if not self.device:
            print >> sys.stderr, "Error: could not find enough nia-devices"
            sys.exit(0)
        try:
            self.handle = self.device.open()
            self.handle.detachKernelDriver(0)
            self.handle.detachKernelDriver(1)
            self.handle.setConfiguration(self.config)
            self.handle.claimInterface(self.interface)
            self.handle.setAltInterface(self.interface)
        except usb.USBError, err:
            if False:            # usb debug info
                print >> sys.stderr, err
    def close(self):
        try:
            self.handle.reset()
            self.handle.releaseInterface()
        except Exception, err:
            if (False): #for debugging only
                print >> sys.stderr, err
        self.handle, self.device = None, None
    def read(self):
        return self.handle.interruptRead(self.ENDPOINT1,self.PACKET_LENGTH1,self.TIME_OUT)

class NIA_Data(): # LibUSB based
    def __init__(self,point,skipNIAs):
        self.Points = point
        self.Working_Data = []
        self.Hamming = numpy.hamming(256)
        self.interface = NIA_Interface(skipNIAs)
        self.interface.open()
        self.lastT = 0
        self.samplecounter = 0
        self.currentSamplesPerSecond = 0
        self.smoothedDownsampled = []
        self.preFFTData = []
        self.Frequencies = []
        self.absFrequencies = []
        self.Processed_Data = []
        self.Calibration = 800000.0
        self.lastSIndex = -1
        self.lastR50 = -1
        self.lastR51 = -1
        sigmoid = 1/(1 + numpy.exp(-8+0.25*numpy.arange(128)))
        self.Sigmoid_Filter = numpy.concatenate((sigmoid,sigmoid[::-1]))
        self.calibrate()
        self.timer = threading.Timer(0.0, self.update)
        self.timer.start()
    def calibrate(self):
        while len(self.Working_Data)<3844:
            self.record()
        self.Calibration = 800000.0 #sum(self.Working_Data)/len(self.Working_Data)
        self.process()
    def close(self): 
        self.interface.close() 
    def record(self):
        nowT = int(time.time())
        current_data = []
        for a in range(self.Points):
            raw_data = self.interface.read()
            for b in range(int(raw_data[54])):
                current_data.append(raw_data[b*3+2]*65536 + raw_data[b*3+1]*256 + raw_data[b*3] - 8388608)
            self.samplecounter += int(raw_data[54])
            #self.lastSIndex = raw_data[52] + raw_data[53]*256
            #self.lastR50 = raw_data[50]
            #self.lastR51 = raw_data[51]
        self.Working_Data = (self.Working_Data+current_data)[-3845:-1]
        if nowT!=self.lastT:
            self.currentSamplesPerSecond = self.samplecounter
            self.samplecounter = 0
            self.lastT = nowT
            #print self.currentSamplesPerSecond
    def process(self):
            self.smoothedDownsampled = map(lambda v,w,x,y,z: (v+2*w+3*x+2*y+z)/(9.0-self.Calibration), 
                            self.Working_Data[0:-4],
                            self.Working_Data[1:-3], 
                            self.Working_Data[2:-2], 
                            self.Working_Data[3:-1], 
                            self.Working_Data[4:]  )[::15]
            self.preFFTData = self.smoothedDownsampled*self.Hamming
            self.Frequencies = numpy.fft.fft(self.preFFTData)*self.Sigmoid_Filter
            self.absFrequencies = abs(self.Frequencies)
            self.Processed_Data = (numpy.fft.ifft(self.Frequencies)/self.Hamming)
    def update(self):
        data_thread = threading.Thread(target=self.record)
        self.timer = threading.Timer(0.0, self.update)
        data_thread.start()
        self.process()
        data_thread.join()
        self.timer.start()

class NIA_Win_Interface(): 
    def __init__(self,skipNIAs): 
        self.VENDOR_ID = 0x1234 #: Vendor Id 
        self.PRODUCT_ID = 0x0000 #: Product Id for the bridged usb cable 
        self.TIME_OUT = 100 
        self.handle = None 
        self.device = None 
        filter = hid.HidDeviceFilter(vendor_id = self.VENDOR_ID, product_id = self.PRODUCT_ID) 
        nias = filter.get_devices() 
        print "Found %d matching hid devices" % len(nias) 
        if len(nias) > skipNIAs: 
            self.device = nias[skipNIAs] 
    def open(self, handler) : 
        if not self.device: 
            print >> sys.stderr, "Error: could not find enough nia-devices" 
            sys.exit(0) 
        try: 
            self.handle = self.device.open() 
            self.device.set_raw_data_handler(handler) 
            device_name = unicode("Using %s %s (vID=%04x, pID=%04x)" %  
                        (self.device.vendor_name, self.device.product_name, self.device.vendor_id, self.device.product_id)) 
            print device_name 
        except hid.helpers.HIDError, err: 
            if False:            # usb debug info 
                print >> sys.stderr, err 
    def close(self): 
        try: 
            self.device.set_raw_data_handler(None) 
            self.device.close() 
        except Exception, err:
            if (False): #for debugging only
                print >> sys.stderr, err 
        self.device = None 

class NIA_Win_Data(): 
    def __init__(self,point,skipNIAs): 
        self.Points = point 
        self.Working_Data = [] 
        self.Hamming = numpy.hamming(256) 
        self.interface = NIA_Win_Interface(skipNIAs) 
        self.a = 0 
        self.lastT = 0 
        self.samplecounter = 0 
        self.currentSamplesPerSecond = 0 
        self.smoothedDownsampled = [] 
        self.preFFTData = [] 
        self.Frequencies = [] 
        self.absFrequencies = [] 
        self.Processed_Data = [] 
        self.Calibration = 800000.0 
        self.lastSIndex = -1 
        self.lastR50 = -1 
        self.lastR51 = -1 
        self.nowT = 0 
        self.current_data = [] 
        sigmoid = 1/(1 + numpy.exp(-8+0.25*numpy.arange(128))) 
        self.Sigmoid_Filter = numpy.concatenate((sigmoid,sigmoid[::-1])) 
        self.interface.open(self.handle) 
        self.timer = threading.Timer(0.0, self.update)
        self.calibrate() 
        self.update() 
    def close(self): 
        self.interface.close() 
    def handle(self, data): 
        data.pop(0) # first is the recordID --> 0 
        if len(self.Working_Data)<3844: 
            #we want 3844 samples first 
            self.record(data) 
            return 
        if not self.calibrated: 
            self.record(data) 
            self.Calibration = 800000.0 #sum(self.Working_Data)/len(self.Working_Data) 
            self.calibrated = True 
            self.process() 
        else: 
            self.record(data)        
    def calibrate(self):  # currently defucted !
        #I honestly don't know how to do this better yet but it seems to work ^^ 
        self.calibrated=False 
        while not self.calibrated: 
            sleep(0.5) 
    def record(self, raw_data): 
        if self.a == 0: 
            self.nowT = int(time.time()) 
            self.current_data = [] 
        self.a += 1 
        for b in range(int(raw_data[54])): 
            self.current_data.append(raw_data[b*3+2]*65536 + raw_data[b*3+1]*256 + raw_data[b*3] - 8388608) 
        self.samplecounter += int(raw_data[54]) 
        #self.lastSIndex = raw_data[52] + raw_data[53]*256 
        #self.lastR50 = raw_data[50] 
        #self.lastR51 = raw_data[51] 
        if self.a == self.Points: 
            self.a=0 
            self.Working_Data = (self.Working_Data+self.current_data)[-3845:-1] 
            if self.nowT!=self.lastT: 
                self.currentSamplesPerSecond = self.samplecounter 
                self.samplecounter = 0 
                self.lastT = self.nowT 
                #print self.currentSamplesPerSecond 
    def process(self): 
            self.smoothedDownsampled = map(lambda v,w,x,y,z: (v+2*w+3*x+2*y+z)/(9.0-self.Calibration),  
                            self.Working_Data[0:-4], 
                            self.Working_Data[1:-3],  
                            self.Working_Data[2:-2],  
                            self.Working_Data[3:-1],  
                            self.Working_Data[4:]  )[::15] 
            self.preFFTData = self.smoothedDownsampled*self.Hamming 
            self.Frequencies = numpy.fft.fft(self.preFFTData)*self.Sigmoid_Filter 
            self.absFrequencies = abs(self.Frequencies) 
            self.Processed_Data = (numpy.fft.ifft(self.Frequencies)/self.Hamming) 
    def update(self): 
        self.timer = threading.Timer(0.0, self.update) 
        self.process() 
        self.timer.start() 

class BCIDevice():
    def __init__(self,deviceString):
        self.devices = []
        self.deviceType = SupportedDevices[deviceString]
        if self.deviceType == OCZ_NIA:
            if havePyWinUSB:
                self.devices.append(NIA_Win_Data(25,0))
            else:
                self.devices.append(NIA_Data(25,0))
        elif self.deviceType == OCZ_NIAx2:
            if havePyWinUSB:
                self.devices.append(NIA_Win_Data(25,0))
                self.devices.append(NIA_Win_Data(25,1))                
            else:            
                self.devices.append(NIA_Data(25,0))
                self.devices.append(NIA_Data(25,1))
    def frequencies(self,i,fromFreq,toFreq):
        return self.devices[i].Frequencies[fromFreq:toFreq]
    def frequenciesCombined(self,fromFreq,toFreq):
        result = []
        for i in range(len(self.devices)):
            result.extend(self.frequencies(i,fromFreq,toFreq))
        return result
    def absfrequencies(self,i,fromFreq,toFreq):
        return self.devices[i].absFrequencies[fromFreq:toFreq]
    def absfrequenciesCombined(self,fromFreq,toFreq):
        result = []
        for i in range(len(self.devices)):
            result.extend(self.absfrequencies(i,fromFreq,toFreq))
        return result
    def preFFTData(self,i):
        return self.devices[i].preFFTData
    def processedData(self,i):
        return self.devices[i].Processed_Data
    def rawData(self,i):
        return self.devices[i].smoothedDownsampled
    def calibrate(self,i):
        self.devices[i].calibrate()
    def calibrateAll(self):
        for i in range(len(self.devices)):
            self.calibrate(i)
    def working_Data(self,i):
        return self.devices[i].Working_Data
    def calibration(self,i):
        return self.devices[i].Calibration
    def setPoints(self,po):
        for i in range(len(self.devices)):
            self.devices[i].Points = po
    def quit(self):
        for i in range(len(self.devices)):
            self.devices[i].timer.cancel()
        sleep(0.5)
        for i in range(len(self.devices)):
            self.devices[i].close()

if __name__ == "__main__":
    import WXElements
    selection = WXElements.selection("Select your Device",SupportedDevices.keys()[0],SupportedDevices.keys())
    bciDevice = BCIDevice(selection)
    #print bciDevice.frequenciesCombined(10,30)
    #bciDevice.quit()
