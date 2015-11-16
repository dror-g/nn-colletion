#!/usr/bin/python

# Howto, Code license, Credits, etc: http://sourceforge.net/projects/triathlon/



from pyfann import libfann
import os
import math
import pickle
import wx
import numpy
import sys
from mdp import Flow
from mdp.nodes import PCANode

import InputManager
import OutputManager
import WXElements

class OutputChannel():
    def __init__(self,
                channelName,
                includeInOutput =  True,
                outputKeyList   =  [],
                lowThreshold    = -0.5,
                highThreshold   =  0.5,
                allSamples      = True):
        self.channelName     = channelName
        self.includeInOutput = includeInOutput
        self.outputKeyList   = outputKeyList
        self.lowThreshold    = lowThreshold
        self.highThreshold   = highThreshold
        self.allSamples      = allSamples

class Current_Data():
    def __init__(self):
        self.outputMode = False
        self.currentReducedSample = []
        self.output = []

class ProfileSettings():
    def __init__(self,
                 freqRange              = (0,0),
                 timeTailLength         = 0,
                 niaFPS                 = 0,
                 flowTrainingChunckSize = 0,
                 trainingClusterSize    = 0,
                 testClusterSize        = 0,
                 profileName            = "",
                 dimensionReductionFlow = "",
                 channels               = []):
        self.freqRange              = freqRange
        self.timeTailLength         = timeTailLength
        self.niaFPS                 = niaFPS,
        self.flowTrainingChunckSize = flowTrainingChunckSize
        self.trainingClusterSize    = trainingClusterSize
        self.profileName            = profileName
        self.dimensionReductionFlowLabel = dimensionReductionFlow
        self.dimensionReductionFlow = Flow([])
        self.channels               = channels
        self.flowTrainedSeparately  = False
        self.qfEnabled              = False
        self.qfAction               = ""
        self.qfThreshold            = 0.0
    
class ChannelPanel(wx.Panel):
    def __init__(self, parent, channelIndex):        
        wx.Panel.__init__(self, parent)
        panelSizer = wx.FlexGridSizer(0,1,0,0)
        panelSizer.AddGrowableCol(0)
        self.includeCB = wx.CheckBox(self,label="include in output")
        self.includeCB.SetValue(profile.channels[channelIndex].includeInOutput)
        self.includeCB.Bind(wx.EVT_CHECKBOX, self.IncludeChanged)
        panelSizer.Add(self.includeCB, 0, wx.ALIGN_CENTER, 5)
        labelPanel = wx.Panel(self)
        labelSizer = wx.FlexGridSizer(0,2,5,5)
        labelSizer.AddGrowableCol(0)
        labelSizer.Add(wx.StaticText(labelPanel,label=profile.channels[channelIndex].outputKeyList[0][0]), 0, wx.ALIGN_LEFT, 5)
        labelSizer.AddGrowableCol(1)
        labelSizer.Add(wx.StaticText(labelPanel,label=profile.channels[channelIndex].outputKeyList[1][0]), 0, wx.ALIGN_RIGHT, 5)
        self.lowChoice = wx.Choice(labelPanel, choices=keycodelistlabels)
        position = self.lowChoice.FindString("Action: "+profile.channels[channelIndex].outputKeyList[0][2]) 
        self.lowChoice.SetSelection (position)
        self.lowChoice.Bind(wx.EVT_CHOICE, self.LowKeycodeChanged)
        labelSizer.Add(self.lowChoice, 0, wx.ALIGN_LEFT, 5)
        self.highChoice = wx.Choice(labelPanel, choices=keycodelistlabels)
        position = self.highChoice.FindString("Action: "+profile.channels[channelIndex].outputKeyList[1][2]) 
        self.highChoice.SetSelection (position)        
        self.highChoice.Bind(wx.EVT_CHOICE, self.HighKeycodeChanged)
        labelSizer.Add(self.highChoice, 0, wx.ALIGN_RIGHT, 5)
        labelSizer.AddGrowableRow(2)
        self.lowStatus = wx.Panel(labelPanel, wx.ID_ANY, style=wx.SUNKEN_BORDER)
        labelSizer.Add(self.lowStatus, 0, wx.EXPAND, 5)
        self.highStatus = wx.Panel(labelPanel, wx.ID_ANY, style=wx.SUNKEN_BORDER)
        labelSizer.Add(self.highStatus, 0, wx.EXPAND, 5)
        labelPanel.SetSizer(labelSizer)
        panelSizer.AddGrowableRow(1)
        panelSizer.Add(labelPanel, 0, wx.EXPAND, 5)
        self.lowSlider = wx.Slider(self, maxValue=1000)
        self.lowSlider.SetValue(500+int(round(profile.channels[channelIndex].lowThreshold*500.0)))
        self.lowSlider.SetToolTip(wx.ToolTip("Low Threshold"))
        self.lowSlider.Bind(wx.EVT_SLIDER,self.LowChanged)
        panelSizer.Add(self.lowSlider, 0, wx.EXPAND, 5)
        self.currentSlider =  wx.Slider(self, maxValue=1000)
        self.currentSlider.SetToolTip(wx.ToolTip("Channel Signal"))
        panelSizer.Add(self.currentSlider, 0, wx.EXPAND, 5)
        self.highSlider =  wx.Slider(self, maxValue=1000, style=wx.SL_INVERSE)
        self.highSlider.SetValue(500-int(round(profile.channels[channelIndex].highThreshold*500.0)))
        self.highSlider.SetToolTip(wx.ToolTip("High Threshold"))
        self.highSlider.Bind(wx.EVT_SLIDER,self.HighChanged)
        panelSizer.Add(self.highSlider, 0, wx.EXPAND, 5)
        self.SetSizer(panelSizer)
        self.SetAutoLayout(1)
        self.channelIndex = channelIndex
    def IncludeChanged(self, event):
        profile.channels[self.channelIndex].includeInOutput = self.includeCB.IsChecked()
        event.Skip()
    def LowChanged(self, event):
        profile.channels[self.channelIndex].lowThreshold = (float(self.lowSlider.GetValue()) - 500.0) / 500.0
        if profile.channels[self.channelIndex].lowThreshold > profile.channels[self.channelIndex].highThreshold:
            self.highSlider.SetValue(1000-self.lowSlider.GetValue())
            profile.channels[self.channelIndex].highThreshold = profile.channels[self.channelIndex].lowThreshold
        event.Skip()
    def HighChanged(self, event):
        profile.channels[self.channelIndex].highThreshold = (-float(self.highSlider.GetValue()) + 500.0) / 500.0
        if profile.channels[self.channelIndex].lowThreshold > profile.channels[self.channelIndex].highThreshold:
            self.lowSlider.SetValue(1000-self.highSlider.GetValue())
            profile.channels[self.channelIndex].lowThreshold = profile.channels[self.channelIndex].highThreshold
        event.Skip()
    def LowKeycodeChanged(self, event):
        profile.channels[self.channelIndex].outputKeyList[0] = (profile.channels[self.channelIndex].outputKeyList[0][0],
                                                                 profile.channels[self.channelIndex].outputKeyList[0][1], 
                                                                 self.lowChoice.GetStringSelection()[8:])
        event.Skip()
    def HighKeycodeChanged(self, event):
        profile.channels[self.channelIndex].outputKeyList[1] = (profile.channels[self.channelIndex].outputKeyList[1][0],
                                                                 profile.channels[self.channelIndex].outputKeyList[1][1],
                                                                 self.highChoice.GetStringSelection()[8:])
        event.Skip()

class SettingPanel(wx.Panel):
    def __init__(self, parent):        
        wx.Panel.__init__(self, parent)
        panelSizer = wx.FlexGridSizer(0,1,2,2)
        panelSizer.AddGrowableCol(0)
        panelSizer.Add(wx.StaticText(self,label=" "), 0, wx.ALIGN_CENTER, 5)
        panelSizer.Add(wx.StaticText(self,label=("Profile name: "+profile.profileName+"\n")), 0, wx.ALIGN_CENTER, 5)
        qfPanel = wx.Panel(self)
        qfSizer = wx.FlexGridSizer(0,3,2,2)
        self.qfCheckbox = wx.CheckBox(qfPanel,label="include Quickfire")
        self.qfCheckbox.SetValue(profile.qfEnabled)
        self.qfCheckbox.Bind(wx.EVT_CHECKBOX, self.qfEnabledChanged)
        qfSizer.AddGrowableCol(0)
        qfSizer.Add(self.qfCheckbox, 0, wx.ALIGN_CENTER, 5)
        self.qfActionChoice = wx.Choice(qfPanel, choices=keycodelistlabels)
        position = self.qfActionChoice.FindString("Action: "+profile.qfAction) 
        self.qfActionChoice.SetSelection (position)        
        self.qfActionChoice.Bind(wx.EVT_CHOICE, self.qfActioncodeChanged)
        qfSizer.Add(self.qfActionChoice, 0, wx.ALIGN_RIGHT, 5)
        self.qfStatusPanel = wx.Panel(qfPanel, wx.ID_ANY, style=wx.SUNKEN_BORDER)
        qfSizer.AddGrowableCol(2)
        qfSizer.Add(self.qfStatusPanel, 0, wx.EXPAND, 5)
        qfPanel.SetSizer(qfSizer)
        self.outputButton = wx.Button(self, id=-1, label="Start Output ( Ctrl Home )")
        self.outputButton.Bind(wx.EVT_BUTTON, self.SwitchOutput)
        panelSizer.Add(self.outputButton, 0, wx.EXPAND, 5)
        self.nb = wx.Notebook(self)
        self.channelPanels = []
        for channelIndex in range(len(profile.channels)):
                self.channelPanels.append(ChannelPanel(self.nb,channelIndex))
                self.nb.AddPage(self.channelPanels[channelIndex],profile.channels[channelIndex].channelName)
        panelSizer.AddGrowableRow(3)
        panelSizer.Add(self.nb, 0, wx.EXPAND, 5)
        panelSizer.Add(qfPanel, 0, wx.EXPAND, 5)
        self.SetSizer(panelSizer)
        self.SetAutoLayout(1)
    def SwitchOutput(self, event):
        if current.outputMode:
            current.outputMode=False
            self.releaseAll()
        else:
            current.outputMode=True
            bciDevice.calibrateAll()            
        fannToOutputApp.setIcon()
        event.Skip()
    def releaseAll(self):
        for channelIndex in range(len(profile.channels)):
            self.releaseAllinChannel(channelIndex)
    def releaseAllinChannel(self,channelIndex):
        for (clName,cond,keystr) in profile.channels[channelIndex].outputKeyList:
            inputFaker.keyRelease(keystr)
        inputFaker.flush()
    def newReading(self):
        for channelIndex in range(len(profile.channels)):
                self.channelPanels[channelIndex].currentSlider.SetValue(500 + int(round(500.0 * current.output[channelIndex])))
    def qfActioncodeChanged(self, event):
        profile.qfAction = self.qfActionChoice.GetStringSelection()[8:]
        event.Skip()
    def qfEnabledChanged(self, event):
        profile.qfEnabled = self.qfCheckbox.IsChecked()
        event.Skip()

class GUIMain(wx.Frame):
    def __init__(self):
        wx.Frame.__init__(self,None,title="nia Triathlon Player",size=(640,380))
        self.panel = wx.Panel(self, wx.ID_ANY)
        MenuBar = wx.MenuBar()
        self.FileMenu = wx.Menu()
        item = self.FileMenu.Append(wx.ID_ANY, text="Save Profile")
        self.Bind(wx.EVT_MENU, self.OnSave, item)
        item = self.FileMenu.Append(wx.ID_EXIT, text="Quit")
        self.Bind(wx.EVT_MENU, self.OnQuit, item)
        MenuBar.Append(self.FileMenu, "Menu")
        self.SetMenuBar(MenuBar)
        self.currentTopPanel = SettingPanel(self.panel)
        sizer = wx.FlexGridSizer(1,3,4,4)
        sizer.AddGrowableRow(0)
        sizer.AddGrowableCol(0)
        sizer.Add(self.currentTopPanel, 1, wx.EXPAND)
        self.qfThresholdSlider = wx.Slider(self.panel,maxValue=1000,style=wx.SL_VERTICAL|wx.SL_INVERSE)
        self.qfThresholdSlider.SetValue(int(profile.qfThreshold*1000.0))
        self.qfThresholdSlider.SetToolTip(wx.ToolTip("Quickfire Threshold"))
        self.qfThresholdSlider.Bind(wx.EVT_SLIDER,self.qfChanged)
        sizer.Add(self.qfThresholdSlider, 1, wx.EXPAND)
        self.qfSignalSlider = wx.Slider(self.panel,maxValue=1000,style=wx.SL_VERTICAL|wx.SL_INVERSE)
        self.qfSignalSlider.SetValue(0)
        self.qfSignalSlider.SetToolTip(wx.ToolTip("Quickfire Signal"))
        sizer.Add(self.qfSignalSlider, 1, wx.EXPAND)
        self.panel.SetSizer(sizer)
        self.panel.Layout()
        self.currentReadingsAndTail = [ bciDevice.absfrequenciesCombined(profile.freqRange[0],profile.freqRange[1])
                                                        for eachIndex in range(profile.timeTailLength+1)]
        self.timer = wx.Timer(self, wx.ID_ANY)
        self.Bind(wx.EVT_TIMER, self.NiaUpdate, self.timer)
    def OnQuit(self, event):
        self.timer.Stop()
        self.Close()
    def OnCalibrate(self, event):
        bciDevice.calibrateAll()
        event.Skip()
    def OnSave(self, event):
        if os.path.exists(profile.profileName+".profile"):
            os.remove(profile.profileName+".profile")
        workfile = open(profile.profileName+".profile", "w")
        pickle.dump(profile, workfile)
        workfile.close()
        event.Skip()
    def qfChanged(self, event):
        profile.qfThreshold = (float(self.qfThresholdSlider.GetValue())/1000.0)
        event.Skip()
    def NiaUpdate(self, ev):
        self.currentReadingsAndTail = [
                    bciDevice.absfrequenciesCombined(profile.freqRange[0],profile.freqRange[1])]+self.currentReadingsAndTail[0:profile.timeTailLength]
        sample=[]
        [sample.extend(i) for i in self.currentReadingsAndTail]
        if profile.dimensionReductionFlowLabel=="None":
                current.currentReducedSample = sample
        else:
                current.currentReducedSample = profile.dimensionReductionFlow(numpy.array([sample]))[0]
        current.output = ann.run(current.currentReducedSample)
        raw = max( abs(float(max(bciDevice.working_Data(0)[-385:-1]))/ float(bciDevice.calibration(0))),
                 abs(float(min(bciDevice.working_Data(0)[-385:-1]))/ float(bciDevice.calibration(0))))
        wait=False
        if len(self.currentReadingsAndTail) < (1+profile.timeTailLength) :
            wait = True
        if not(wait):
            self.currentTopPanel.newReading()
        if (wx.GetKeyState(wx.WXK_CONTROL) and wx.GetKeyState(wx.WXK_END)): 
            if current.outputMode:                     # switch output-mode off
                current.outputMode=False
                fannToOutputApp.setIcon()
                self.currentTopPanel.releaseAll()
        elif (wx.GetKeyState(wx.WXK_CONTROL) and wx.GetKeyState(wx.WXK_HOME)):
            if not(current.outputMode):                # switch output-mode on
                current.outputMode=True
                fannToOutputApp.setIcon()
                bciDevice.calibrateAll()
        if current.outputMode:
            if (profile.qfEnabled):
                if (profile.qfThreshold*20.0) <= raw:
                        inputFaker.keyHold(profile.qfAction)
                else:
                        inputFaker.keyRelease(profile.qfAction)
            for channelIndex in range(len(profile.channels)):
                if profile.channels[channelIndex].includeInOutput:
                          out = current.output[channelIndex]
                          if (out < profile.channels[channelIndex].lowThreshold):
                              inputFaker.keyHold(profile.channels[channelIndex].outputKeyList[0][2])
                          else:
                              inputFaker.keyRelease(profile.channels[channelIndex].outputKeyList[0][2])
                          if (out > profile.channels[channelIndex].highThreshold):
                              inputFaker.keyHold(profile.channels[channelIndex].outputKeyList[1][2])
                          else:
                              inputFaker.keyRelease(profile.channels[channelIndex].outputKeyList[1][2])
            inputFaker.flush()
        for channelIndex in range(len(profile.channels)):
            if profile.channels[channelIndex].includeInOutput:
                out = current.output[channelIndex]
                if (out < profile.channels[channelIndex].lowThreshold):
                    self.currentTopPanel.channelPanels[channelIndex].lowStatus.SetBackgroundColour('#5050FF')
                    self.currentTopPanel.channelPanels[channelIndex].highStatus.SetBackgroundColour('#000000')
                elif (out > profile.channels[channelIndex].highThreshold):
                    self.currentTopPanel.channelPanels[channelIndex].lowStatus.SetBackgroundColour('#000000')
                    self.currentTopPanel.channelPanels[channelIndex].highStatus.SetBackgroundColour('#5050FF')
                else:
                    self.currentTopPanel.channelPanels[channelIndex].lowStatus.SetBackgroundColour('#000000')
                    self.currentTopPanel.channelPanels[channelIndex].highStatus.SetBackgroundColour('#000000')
                
            else:
                self.currentTopPanel.channelPanels[channelIndex].lowStatus.SetBackgroundColour('#505050')
                self.currentTopPanel.channelPanels[channelIndex].highStatus.SetBackgroundColour('#505050')
        self.qfSignalSlider.SetValue(int(raw*50.0))
        if (profile.qfEnabled):
            if (profile.qfThreshold*20.0) <= raw:
                self.currentTopPanel.qfStatusPanel.SetBackgroundColour('#E68000')
            else:
                self.currentTopPanel.qfStatusPanel.SetBackgroundColour('#000000')
        else:
            self.currentTopPanel.qfStatusPanel.SetBackgroundColour('#505050')
        ev.Skip()

class FannToOutputApp(wx.App):
    def __init__(self, redirect = False):
        wx.App.__init__(self)
        ib = wx.IconBundle()
        bmp = self.make_grad_image(32,32, (0,0,0), (0,0,0))
        icon = wx.EmptyIcon()
        icon.CopyFromBitmap(bmp)
        ib.AddIcon(icon)
        self.mainWindow = GUIMain()
        self.mainWindow.SetIcons(ib)
        self.mainWindow.Center()
        self.mainWindow.Show(True)
        self.mainWindow.timer.Start(int(1000.0/profile.niaFPS))
    def setIcon(self):
        ib = wx.IconBundle()
        if current.outputMode:
                bmp = self.make_grad_image(32,32, (255,255,0), (0,0,0))
                self.mainWindow.currentTopPanel.outputButton.SetLabel("Pause Output ( Ctrl End )")
        else:
                bmp = self.make_grad_image(32,32, (0,0,0), (0,0,0))
                self.mainWindow.currentTopPanel.outputButton.SetLabel("Continue Output ( Ctrl Home )")
        icon = wx.EmptyIcon()
        icon.CopyFromBitmap(bmp)
        ib.AddIcon(icon)
        self.mainWindow.SetIcons(ib)
    def make_grad_image(self, width, height, col_left, col_right):
        array = numpy.zeros((height, width, 3), 'uint8')
        alpha = numpy.linspace(0.0, 1.0, width)
        color_gradient = numpy.outer(alpha, col_right) + \
               numpy.outer((1.0-alpha), col_left)
        array[:,:,:] = color_gradient
        image = wx.EmptyImage(width, height)
        image.SetData(array.tostring())
        return wx.BitmapFromImage(image)

def run(profName=""):
    global profile
    global inputFaker
    global bciDevice
    global keycodelistlabels
    global current
    global fannToOutputApp
    global ann
    inputFaker = OutputManager.InputFaker()
    if inputFaker == -1:
        print "Import-Error: You need either Win32con (Windows) or XLib (Linux, Mac)"
    else:
        profilefile = "" 
        keycodelistlabels = sorted(["Action: "+each for each in inputFaker.actions.keys()])
        if (profName==""):
            if len(sys.argv)<2:
                path = os.getcwd()
                fileList = os.listdir(path)
                profileList = []
                for fileName in fileList:
                    if fileName[-7:] == "profile":
                        profileList.append(fileName[:-8])
                if len(profileList) > 0:
                    profilefile = str(WXElements.selection("Select your Profile",profileList[0], profileList))
                else:
                    print "Error: no profiles found"
            else:
                profilefile = sys.argv[1]
    
            if len(profilefile)==0:
                print "Error: no profile name given.\nExample: python nia-Triathlon-Player.py myProfile"
            else:
                if len(profilefile)==0:
                    profilefile = sys.argv[1] 
                profileLoaded = False
                netLoaded = False
                if os.path.exists(profilefile+".profile"):
                    workfile = open(profilefile+".profile", "r")
                    profile = pickle.load(workfile)
                    workfile.close()
                    profileLoaded = True
                else:
                    print "no "+profilefile+".profile"+" file found"
                ann = libfann.neural_net()
                if os.path.exists(profilefile+".net"):
                    ann.create_from_file(profilefile+".net")
                    netLoaded = True
                else:
                    print "no "+profilefile+".net"+" file found"
                if (profileLoaded and netLoaded):
                    bciDevice =  InputManager.BCIDevice(profile.deviceName)
                    current = Current_Data()
                    fannToOutputApp = FannToOutputApp()
                    fannToOutputApp.MainLoop()
                    bciDevice.quit()
                else:
                    print "Cannot start without .profile and .net files"
        else:
            profilefile=profName
            workfile = open(profilefile+".profile", "r")
            profile = pickle.load(workfile)
            workfile.close()
            ann = libfann.neural_net()
            ann.create_from_file(profilefile+".net")
            bciDevice =  InputManager.BCIDevice(profile.deviceName)
            current = Current_Data()
            fannToOutputApp = FannToOutputApp()
            fannToOutputApp.MainLoop()
            bciDevice.quit()

if __name__ == "__main__":
    run()
