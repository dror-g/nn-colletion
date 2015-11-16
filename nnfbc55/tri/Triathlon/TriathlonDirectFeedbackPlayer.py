#!/usr/bin/python

# Howto, Code license, Credits, etc: http://sourceforge.net/projects/triathlon/


noGL = False   # Set noGL to True for disabling the use of OpenGL (to gain speed, or to avoid python-wx-opengl problems)


import numpy
import wx
import math
import sys
import os
import pickle
from copy import deepcopy

import InputManager
import OutputManager
import WXElements


class Current_Data():
    def __init__(self):
        self.outputMode = False

class Action():
    def __init__(self,
                 actionName             = "Push a",
                 deviceNumber           = 0,
                 fromFreq               = 10,
                 toFreq                 = 12,
                 ampMin                 = 13.0,
                 ampMax                 = 30.0,                 
                 output                 = "a"):
        self.actionName   = actionName
        self.deviceNumber = deviceNumber
        self.fromFreq     = fromFreq
        self.toFreq       = toFreq
        self.ampMin       = ampMin
        self.ampMax       = ampMax
        self.output       = output
        self.disabled     = False
        self.active       = False
        self.currentValue = 0.0
    def evaluate(self,shouldbeActive):
        if shouldbeActive==True:
            if self.active != True:
                self.active = True
            if current.outputMode and not(self.disabled):
                    inputFaker.keyHold(self.output)
        else:
            if self.active != False:
                self.active = False
            if current.outputMode and not(self.disabled):
                    inputFaker.keyRelease(self.output)
    def disable(self):
        self.disabled      = True
        inputFaker.keyRelease(self.output)
    def enable(self):
        self.disabled      = False
    def release(self):
        inputFaker.keyRelease(self.output)

class ProfileSettings():
    def __init__(self,
                 niaFPS                 = 10,
                 profileName            = "myProfile",
                 deviceName             = "OCZ Neural Impulse Actuator",
                 actions                = [Action(actionName="Strafe left",fromFreq=7,toFreq=9,ampMin=2.0,ampMax=5.0,output="a"),
                                           Action(actionName="Strafe right",fromFreq=7,toFreq=9,ampMin=7.5,ampMax=13.0,output="d"),
                                           Action(actionName="Move forward",fromFreq=0,toFreq=18,ampMin=5.0,ampMax=18.0,output="w"),
                                           Action(actionName="Move back",fromFreq=0,toFreq=18,ampMin=2.0,ampMax=5.0,output="s"),
                                           Action(actionName="Jump",fromFreq=0,toFreq=18,ampMin=11.0,ampMax=18.0,output="Space"),
                                           Action(actionName="Primary Fire",fromFreq=0,toFreq=2,ampMin=35.0,ampMax=55.0,output="Mouse Button Left"),
                                           Action(actionName="Secondary Fire",fromFreq=0,toFreq=2,ampMin=55.0,ampMax=90.0,output="Mouse Button Right")],
                 qfEnabled              = False,
                 qfAction               = "p",
                 qfThreshold            = 0.15):
        self.niaFPS                 = niaFPS
        self.profileName            = profileName
        self.deviceName             = deviceName
        self.actions                = actions
        self.qfEnabled              = qfEnabled
        self.qfAction               = qfAction
        self.qfThreshold            = qfThreshold
        self.freqRange              = (0,0)
        self.updateFreqRange()
    def releaseActions(self):
        for action in self.actions:
            action.release()
    def updateFreqRange(self):
        (frF,toF) = (100000,-100000)
        for action in self.actions:
            if action.fromFreq < frF:
                frF = action.fromFreq
            if action.toFreq > toF:
                toF = action.toFreq           
        if frF>100:
            frF = 100
        if toF>102:
            toF = 102
        if frF<0:
            frF = 0
        if toF<2:
            toF = 2
        if toF<frF:
           sw = toF
           toF = frF
           frF =sw
        if (toF-frF)<2:
           toF = frF+2
        self.freqRange = (frF,toF)

class NewActionPanel(wx.Panel):
    def __init__(self, parent):        
        wx.Panel.__init__(self, parent)
        panelSizer = wx.FlexGridSizer(0,1,0,0)
        panelSizer.AddGrowableCol(0)
        namePanel = wx.Panel(self, wx.ID_ANY)
        nameSizer = wx.FlexGridSizer(1,0,0,0)
        nameSizer.Add(wx.StaticText(namePanel,label="Action name:"), 0, wx.ALIGN_CENTER, 5)
        nameSizer.Add(wx.StaticText(namePanel,label=""), 0, wx.ALIGN_CENTER, 5)
        nameSizer.AddGrowableCol(2)
        self.nameField = wx.TextCtrl(namePanel,value="new Action")
        nameSizer.Add(self.nameField, 0, wx.EXPAND, 5)
        namePanel.SetSizer(nameSizer)        
        self.actionChoice = wx.Choice(self, choices=keycodelistlabels)
        devlist = []
        for devIndex in range(len(bciDevice.devices)):
            devlist.append("Device "+str(devIndex))
        self.devChoice = wx.Choice(self, choices=devlist)
        self.devChoice.SetSelection(0)
        freqRangePanel = wx.Panel(self, wx.ID_ANY)
        freqRangeSizer = wx.FlexGridSizer(1,0,0,0)
        freqRangeSizer.Add(wx.StaticText(freqRangePanel,label="Frequency range:"), 0, wx.ALIGN_CENTER, 5)
        freqRangeSizer.AddGrowableCol(1)
        freqRangeSizer.Add(wx.StaticText(freqRangePanel,label=""), 0, wx.ALIGN_CENTER, 5)
        self.fromFreqField = wx.SpinCtrl(freqRangePanel, initial=10)
        freqRangeSizer.Add(self.fromFreqField)
        freqRangeSizer.Add(wx.StaticText(freqRangePanel,label=" - "), 0, wx.ALIGN_CENTER, 5)
        self.toFreqField = wx.SpinCtrl(freqRangePanel,initial=12)
        freqRangeSizer.Add(self.toFreqField)
        freqRangePanel.SetSizer(freqRangeSizer)
        self.newButton = wx.Button(self,label="Create Action")
        self.newButton.Bind(wx.EVT_BUTTON, self.createAction)
        panelSizer.AddGrowableRow(0)
        panelSizer.Add(wx.StaticText(self,label=" "), 0, wx.ALIGN_CENTER, 5)
        panelSizer.Add(namePanel, 0, wx.EXPAND, 5)
        panelSizer.Add(wx.StaticText(self,label=" "), 0, wx.ALIGN_CENTER, 5)
        panelSizer.Add(self.devChoice, 0, wx.EXPAND, 5)
        panelSizer.Add(freqRangePanel, 0, wx.EXPAND, 5)
        panelSizer.Add(self.actionChoice, 0, wx.EXPAND, 5)
        panelSizer.Add(wx.StaticText(self,label=" "), 0, wx.ALIGN_CENTER, 5)
        panelSizer.Add(self.newButton, 0, wx.ALIGN_CENTER, 5)
        panelSizer.AddGrowableRow(8)
        panelSizer.Add(wx.StaticText(self,label=" "), 0, wx.ALIGN_CENTER, 5)
        self.SetSizer(panelSizer)
        self.SetAutoLayout(1)
    def createAction(self, event):
        if not(self.nameField.GetValue()==""):
            fr = 0
            try:
                    fr = int(self.fromFreqField.GetValue())
            except ValueError:
                    fr = 10
            if (fr<0):
                    fr = 0
            elif (fr>100):
                    fr = 100
            to = 0
            try:
                    to = int(self.toFreqField.GetValue())
            except ValueError:
                    to = 12
            if (to<0):
                    to = 0
            elif (to>100):
                    to = 100
            if to<fr:
                sw = fr
                fr = to
                to = sw
            elif to == fr:
                to = to+2
            if abs(to-fr)==1:
                to=to+1
            self.fromFreqField.SetValue(fr)
            self.toFreqField.SetValue(to)
            profile.actions.append(Action(
                 actionName             = self.nameField.GetValue(),
                 deviceNumber           = (int)(self.devChoice.GetStringSelection()[7:]),
                 fromFreq               = fr,
                 toFreq                 = to,
                 ampMin                 = 70.0,
                 ampMax                 = 120.0,                 
                 output                 = self.actionChoice.GetStringSelection()[8:] ))
            self.GetParent().SetSelection(1)
            self.GetGrandParent().actionsPanels.setToNew()
            profile.updateFreqRange()

class ActionPanel(wx.Panel):
    def __init__(self, parent):        
        wx.Panel.__init__(self, parent)
        panelSizer = wx.FlexGridSizer(0,1,0,0)
        panelSizer.AddGrowableCol(0)
        namePanel = wx.Panel(self, wx.ID_ANY)
        nameSizer = wx.FlexGridSizer(1,0,0,0)
        nameSizer.Add(wx.StaticText(namePanel,label="Action name:"), 0, wx.ALIGN_CENTER, 5)
        nameSizer.Add(wx.StaticText(namePanel,label=""), 0, wx.ALIGN_CENTER, 5)
        nameSizer.AddGrowableCol(2)
        self.nameField = wx.TextCtrl(namePanel,value="")
        self.nameField.Bind(wx.EVT_KILL_FOCUS, self.nameChanged)
        nameSizer.Add(self.nameField, 0, wx.EXPAND, 5)
        namePanel.SetSizer(nameSizer)    
        self.includedInOutputCB = wx.CheckBox(self,label="Included in output")
        self.includedInOutputCB.Bind(wx.EVT_CHECKBOX, self.disabledChanged)
        self.outputChoice = wx.Choice(self, choices=keycodelistlabels)
        self.outputChoice.Bind(wx.EVT_CHOICE, self.outputChanged)
        devlist = []
        for devIndex in range(len(bciDevice.devices)):
            devlist.append("Device "+str(devIndex))
        self.devChoice = wx.Choice(self, choices=devlist)
        self.devChoice.Bind(wx.EVT_CHOICE, self.devChanged)
        self.devChoice.SetSelection(0)
        freqRangePanel = wx.Panel(self, wx.ID_ANY)
        freqRangeSizer = wx.FlexGridSizer(1,0,0,0)
        freqRangeSizer.Add(wx.StaticText(freqRangePanel,label="Frequency range:"), 0, wx.ALIGN_CENTER, 5)
        freqRangeSizer.AddGrowableCol(1)
        freqRangeSizer.Add(wx.StaticText(freqRangePanel,label=""), 0, wx.ALIGN_CENTER, 5)
        self.fromFreqField = wx.SpinCtrl(freqRangePanel)
        self.fromFreqField.Bind(wx.EVT_SPINCTRL, self.freqsChanged)
        freqRangeSizer.Add(self.fromFreqField)
        freqRangeSizer.Add(wx.StaticText(freqRangePanel,label=" - "), 0, wx.ALIGN_CENTER, 5)
        self.toFreqField = wx.SpinCtrl(freqRangePanel)
        self.toFreqField.Bind(wx.EVT_SPINCTRL, self.freqsChanged)
        freqRangeSizer.Add(self.toFreqField)
        freqRangePanel.SetSizer(freqRangeSizer)
        self.delButton = wx.Button(self,label="Delete Action")
        self.delButton.Bind(wx.EVT_BUTTON, self.deleteAction)
        self.thresholdMinSlider = wx.Slider(self,style=wx.SL_INVERSE,maxValue=100000)
        self.thresholdMinSlider.SetToolTip(wx.ToolTip("Amplitude minimum for this Action"))
        self.thresholdMinSlider.Bind(wx.EVT_SLIDER,self.minChanged)
        self.thresholdMaxSlider = wx.Slider(self,maxValue=100000)
        self.thresholdMaxSlider.SetToolTip(wx.ToolTip("Amplitude maximum for this Action"))
        self.thresholdMaxSlider.Bind(wx.EVT_SLIDER,self.maxChanged)
        self.actionChoice = wx.Choice(self, choices=[action.actionName for action in profile.actions])
        self.actionChoice.Bind(wx.EVT_CHOICE, self.setToActionEv)
        self.actionSignalSlider = wx.Slider(self,maxValue=100000)
        self.actionSignalSlider.SetToolTip(wx.ToolTip("Current amplitude for this Action"))
        self.actionStatus = wx.Panel(self, wx.ID_ANY, style=wx.SUNKEN_BORDER)
        panelSizer.Add(self.actionChoice, 0, wx.EXPAND, 5)
        panelSizer.Add(namePanel, 0, wx.EXPAND, 5)
        panelSizer.Add(self.includedInOutputCB , 0, wx.ALIGN_CENTER, 5)
        panelSizer.AddGrowableRow(3)
        panelSizer.Add(self.actionStatus, 0, wx.EXPAND, 5)
        panelSizer.Add(self.thresholdMinSlider, 0, wx.EXPAND, 5)
        panelSizer.Add(self.actionSignalSlider, 0, wx.EXPAND, 5)
        panelSizer.Add(self.thresholdMaxSlider, 0, wx.EXPAND, 5)
        panelSizer.Add(self.devChoice, 0, wx.EXPAND, 5)
        panelSizer.Add(freqRangePanel, 0, wx.EXPAND, 5)
        panelSizer.Add(self.outputChoice, 0, wx.EXPAND, 5)
        panelSizer.Add(self.delButton, 0, wx.ALIGN_CENTER, 5)
        self.setToAction()
        self.SetSizer(panelSizer)
        self.SetAutoLayout(1)
    def setToNew(self):
        self.actionChoice.SetItems([action.actionName for action in profile.actions])
        self.actionChoice.SetSelection(len(profile.actions)-1)
        self.setToAction()
    def setToActionEv(self,event):
        self.setToAction()
    def setToAction(self):
        actIndex = self.actionChoice.GetSelection()
        if not(self.actionChoice.GetStringSelection()==""):
            self.nameField.SetValue(profile.actions[actIndex].actionName)
            self.devChoice.SetSelection(profile.actions[actIndex].deviceNumber)
            self.outputChoice.SetSelection(keycodelistlabels.index("Action: "+profile.actions[actIndex].output))
            self.fromFreqField.SetValue((profile.actions[actIndex].fromFreq))
            self.toFreqField.SetValue((profile.actions[actIndex].toFreq))
            self.SetMinSlider(profile.actions[actIndex].ampMin)
            self.SetMaxSlider(profile.actions[actIndex].ampMax)
            self.includedInOutputCB.SetValue(not(profile.actions[actIndex].disabled))
            self.actIndex = actIndex
        else:
            self.nameField.SetValue("")
            self.fromFreqField.SetValue(0)
            self.toFreqField.SetValue(0)
            self.includedInOutputCB.SetValue(False)
            self.actIndex = -1
        self.GetGrandParent().actionCountText.SetLabel("   "+str(len(profile.actions))+" Actions   ")
    def deleteAction(self,event):
        if not(self.actionChoice.GetStringSelection()==""):
            actIndex = self.actionChoice.GetSelection()
            profile.actions[actIndex].disable()
            del profile.actions[actIndex]
            profile.updateFreqRange()
            self.setToNew()
            if len(profile.actions)==0:
                self.GetParent().SetSelection(0)
    def SetMinSlider(self,val):
        self.thresholdMinSlider.SetValue(100000-(int)(val*1000))
    def SetMaxSlider(self,val):
        self.thresholdMaxSlider.SetValue((int)(val*1000))
    def nameChanged(self,event):
        if not(self.actionChoice.GetStringSelection()==""):
            actIndex = self.actionChoice.GetSelection()
            if (self.nameField.GetValue()!=''):
                profile.actions[actIndex].actionName = self.nameField.GetValue()
            else:
                self.nameField.SetValue(profile.profileName)
            self.actionChoice.SetItems([action.actionName for action in profile.actions])
            position =  self.actionChoice.FindString(profile.actions[actIndex].actionName)     
            self.actionChoice.SetSelection(position)            
    def minChanged(self,event):
        if not(self.actionChoice.GetStringSelection()==""):
            actIndex = self.actionChoice.GetSelection()
            profile.actions[actIndex].ampMin = ((float)(self.thresholdMinSlider.GetValue()) - 100000.0)* -0.001
            if profile.actions[actIndex].ampMin > profile.actions[actIndex].ampMax:
                profile.actions[actIndex].ampMax = profile.actions[actIndex].ampMin
                self.SetMaxSlider(profile.actions[actIndex].ampMax)
    def maxChanged(self,event):
        if not(self.actionChoice.GetStringSelection()==""):
            actIndex = self.actionChoice.GetSelection()
            profile.actions[actIndex].ampMax = (float)(self.thresholdMaxSlider.GetValue())*0.001
            if profile.actions[actIndex].ampMin > profile.actions[actIndex].ampMax:
                profile.actions[actIndex].ampMin = profile.actions[actIndex].ampMax
                self.SetMinSlider(profile.actions[actIndex].ampMin)
    def devChanged(self,event):
        if not(self.actionChoice.GetStringSelection()==""):
            actIndex = self.actionChoice.GetSelection()
            profile.actions[actIndex].deviceNumber = self.devChoice.GetSelection()
    def freqsChanged(self,event):
        if not(self.actionChoice.GetStringSelection()==""):
            actIndex = self.actionChoice.GetSelection()
            fr = 0
            try:
                    fr = int(self.fromFreqField.GetValue())
            except ValueError:
                    fr = profile.actions[actIndex].freqRange[0]
            if (fr<0):
                    fr = 0
            elif (fr>100):
                    fr = 100
            to = 0
            try:
                    to = int(self.toFreqField.GetValue())
            except ValueError:
                    to = profile.actions[actIndex].freqRange[1]
            if (to<0):
                    to = 0
            elif (to>100):
                    to = 100
            if to<fr:
                sw = fr
                fr = to
                to = sw
            elif to == fr:
                to = to+2
            if abs(to-fr)==1:
                to=to+1
            self.fromFreqField.SetValue(fr)
            self.toFreqField.SetValue(to)
            profile.actions[actIndex].fromFreq = fr
            profile.actions[actIndex].toFreq = to
            profile.updateFreqRange()
    def outputChanged(self,event):
        if not(self.actionChoice.GetStringSelection()==""):
            actIndex = self.actionChoice.GetSelection()
            profile.actions[actIndex].output = self.outputChoice.GetStringSelection()[8:]
    def disabledChanged(self,event):
        if not(self.actionChoice.GetStringSelection()==""):
            actIndex = self.actionChoice.GetSelection()
            if self.includedInOutputCB.GetValue():
                profile.actions[actIndex].enable()
            else:
                profile.actions[actIndex].disable()

class SettingPanel(wx.Panel):
    def __init__(self, parent):        
        wx.Panel.__init__(self, parent)
        panelSizer = wx.FlexGridSizer(0,1,0,0)
        namePanel = wx.Panel(self, wx.ID_ANY)
        nameSizer = wx.FlexGridSizer(1,0,0,0)
        nameSizer.Add(wx.StaticText(namePanel,label="Profile name:"), 0, wx.ALIGN_CENTER, 5)
        self.actionCountText = wx.StaticText(namePanel,label=("   "+str(len(profile.actions))+" Actions   "))
        nameSizer.AddGrowableCol(1)
        self.nameField = wx.TextCtrl(namePanel,value=profile.profileName)
        self.nameField.Bind(wx.EVT_KILL_FOCUS, self.nameChanged)
        nameSizer.Add(self.nameField, 0, wx.EXPAND, 5)
        nameSizer.Add(self.actionCountText, 0, wx.ALIGN_CENTER, 5)
        namePanel.SetSizer(nameSizer)
        self.activateButton = wx.Button(self,label="Start Output ( Ctrl Home )")
        self.activateButton.Bind(wx.EVT_BUTTON, self.outputSwitchButton)     
        fpsPanel = wx.Panel(self, wx.ID_ANY)
        fpsSizer = wx.FlexGridSizer(1,0,0,0)
        fpsSizer.Add(wx.StaticText(fpsPanel,label="Triathlon FPS:"), 0, wx.ALIGN_CENTER, 5)
        fpsSizer.AddGrowableCol(1)
        fpsSizer.Add(wx.StaticText(fpsPanel,label=""), 0, wx.ALIGN_CENTER, 5)
        self.fpsField = wx.SpinCtrl(fpsPanel,initial=profile.niaFPS,min=1,max=128)
        self.fpsField.Bind(wx.EVT_SPINCTRL, self.fpsChanged)
        fpsSizer.Add(self.fpsField)
        fpsPanel.SetSizer(fpsSizer)
        qfPanel = wx.Panel(self, wx.ID_ANY)
        qfSizer = wx.FlexGridSizer(1,0,0,0)
        self.qfCheckbox = wx.CheckBox(qfPanel,label='Quickfire')
        self.qfCheckbox.SetValue(profile.qfEnabled)
        self.qfCheckbox.Bind(wx.EVT_CHECKBOX, self.qfChanged)
        qfSizer.Add(self.qfCheckbox, 0, wx.ALIGN_CENTER, 5)
        qfSizer.AddGrowableCol(1)
        self.qfActionChoice = wx.Choice(qfPanel, choices=keycodelistlabels)
        position = self.qfActionChoice.FindString("Action: "+profile.qfAction)            
        self.qfActionChoice.SetSelection (position)        
        self.qfActionChoice.Bind(wx.EVT_CHOICE, self.qfActioncodeChanged)
        qfSizer.Add(self.qfActionChoice, 0, wx.ALIGN_RIGHT, 5)
        qfSizer.AddGrowableCol(2)
        self.qfStatusPanel =  wx.Panel(qfPanel, wx.ID_ANY, style=wx.SUNKEN_BORDER)
        qfSizer.Add(self.qfStatusPanel, 0, wx.EXPAND, 5)
        qfPanel.SetSizer(qfSizer)
        self.rawSPSs = [wx.StaticText(self,label=(
                        "Device "+str(i)+" Raw Samples per second: "+
                        str(bciDevice.devices[i].currentSamplesPerSecond)))
                                for i in range(len(bciDevice.devices))]
        self.actionsNotebook = wx.Notebook(self)
        self.newActionPanel = NewActionPanel(self.actionsNotebook)
        self.actionsNotebook.AddPage(self.newActionPanel,"New Action")
        self.actionsPanels = ActionPanel(self.actionsNotebook)
        self.actionsNotebook.AddPage(self.actionsPanels,"Actions")
        panelSizer.AddGrowableCol(0)
        panelSizer.Add(wx.StaticText(self,label=" "), 0, wx.ALIGN_CENTER, 5)
        panelSizer.Add(namePanel, 0, wx.EXPAND, 5)
        panelSizer.Add(fpsPanel, 0, wx.EXPAND, 5)
        panelSizer.Add(wx.StaticText(self,label=" "), 0, wx.ALIGN_CENTER, 5)
        panelSizer.Add(self.activateButton, 0, wx.EXPAND, 5)
        panelSizer.Add(wx.StaticText(self,label=" "), 0, wx.ALIGN_CENTER, 5)
        panelSizer.AddGrowableRow(6)        
        panelSizer.Add(self.actionsNotebook, 0, wx.EXPAND, 5)
        panelSizer.Add(wx.StaticText(self,label=" "), 0, wx.ALIGN_CENTER, 5)
        panelSizer.Add(qfPanel, 0, wx.EXPAND, 5)
        for  i in range(len(bciDevice.devices)):
            panelSizer.Add(self.rawSPSs[i], 0, wx.ALIGN_CENTER, 5)
        panelSizer.Add(wx.StaticText(self,label=" "), 0, wx.ALIGN_CENTER, 5)
        self.SetSizer(panelSizer)
        self.SetAutoLayout(1)
    def fpsChanged(self, event):
        val = 0
        try:
                val = self.fpsField.GetValue()
        except ValueError:
                val = profile.niaFPS
        if (val<1):
                val = 1
        elif (val>128):
                val = 128
        profile.niaFPS = val
        self.fpsField.SetValue(val)
        self.GetGrandParent().timer.Stop()
        self.GetGrandParent().timer.Start(int(1000.0/profile.niaFPS))
        event.Skip()
    def nameChanged(self, event):
        if (self.nameField.GetValue()!=''):
                profile.profileName = self.nameField.GetValue()
        else:
                self.nameField.SetValue(profile.profileName)
        event.Skip()
    def qfChanged(self, event):
        profile.qfEnabled = self.qfCheckbox.IsChecked()
        event.Skip()
    def qfActioncodeChanged(self, event):
        profile.qfAction = self.qfActionChoice.GetStringSelection()[8:]
        event.Skip()
    def outputSwitchButton(self, event):
        self.outputSwitch()
        event.Skip()
    def outputSwitch(self):
        if current.outputMode:
            current.outputMode=False
            profile.releaseActions()
            inputFaker.keyRelease(profile.qfAction)
            inputFaker.flush()
            self.activateButton.SetLabel("Continue Output ( Ctrl Home )")
        else:
            current.outputMode=True
            bciDevice.calibrateAll()            
            self.activateButton.SetLabel("Pause Output ( Ctrl End )")
        niaDirectFeedbackApp.setIcon()

class GUIMain(wx.Frame):
    def __init__(self):
        wx.Frame.__init__(self,None,title="Triathlon Direct Feedback Player",size=(480,600))
        self.panel = wx.Panel(self, wx.ID_ANY)
        MenuBar = wx.MenuBar()
        self.FileMenu = wx.Menu()
        item = self.FileMenu.Append(wx.ID_ANY, text="Save Profile")
        self.Bind(wx.EVT_MENU, self.OnSave, item)
        item = self.FileMenu.Append(wx.ID_EXIT, text="Quit")
        self.Bind(wx.EVT_MENU, self.OnQuit, item)
        MenuBar.Append(self.FileMenu, "Menu")
        self.SetMenuBar(MenuBar)
        sizer = wx.FlexGridSizer(1,3,0,0)
        sizer.AddGrowableRow(0)
        sizer.AddGrowableCol(0)
        self.settingPanel = SettingPanel(self.panel)
        sizer.Add(self.settingPanel, 1, wx.EXPAND)
        self.qfThresholdSlider = wx.Slider(self.panel,maxValue=1000,style=wx.SL_VERTICAL|wx.SL_INVERSE)
        self.qfThresholdSlider.SetToolTip(wx.ToolTip("Quickfire Threshold"))
        self.qfThresholdSlider.SetValue(int(profile.qfThreshold*1000.0))
        self.qfThresholdSlider.Bind(wx.EVT_SLIDER,self.qfChanged)
        sizer.Add(self.qfThresholdSlider, 1, wx.EXPAND)
        self.qfSignalSlider = wx.Slider(self.panel,maxValue=1000,style=wx.SL_VERTICAL|wx.SL_INVERSE)
        self.qfSignalSlider.SetToolTip(wx.ToolTip("Quickfire Signal"))
        self.qfSignalSlider.SetValue(0.0)
        sizer.Add(self.qfSignalSlider, 1, wx.EXPAND)
        self.panel.SetSizer(sizer)
        self.panel.Layout()
        self.timer = wx.Timer(self, wx.ID_ANY)
        self.Bind(wx.EVT_TIMER, self.NiaUpdate, self.timer)
        self.oldMousePos = (wx.GetMouseState().GetX(),wx.GetMouseState().GetY())
    def OnQuit(self, event):
        self.timer.Stop()
        self.Close()
    def OnSave(self, event):
        if os.path.exists(profile.profileName+".feedback"):
            os.remove(profile.profileName+".feedback")
        workfile = open(profile.profileName+".feedback", "w")
        pickle.dump(profile, workfile)
        workfile.close()
        event.Skip()
    def qfChanged(self, event):
        profile.qfThreshold = (float(self.qfThresholdSlider.GetValue())/1000.0)
        event.Skip()
    def OnCalibrate(self, event):
        bciDevice.calibrateAll()
        event.Skip()
    def NiaUpdate(self, ev):
        self.currentReadings = bciDevice.absfrequenciesCombined(profile.freqRange[0],profile.freqRange[1])
        for actIndex in range(len(profile.actions)):
            profile.actions[actIndex].currentValue = (sum(
                   self.currentReadings[
                           (profile.actions[actIndex].fromFreq - profile.freqRange[0]) +
                            (profile.actions[actIndex].deviceNumber*(profile.freqRange[1]-profile.freqRange[0]))
                           : 
                           (profile.actions[actIndex].toFreq - profile.freqRange[0]) +
                            (profile.actions[actIndex].deviceNumber*(profile.freqRange[1]-profile.freqRange[0]))])
                                                    /((float)(profile.actions[actIndex].toFreq - profile.actions[actIndex].fromFreq)))
            if  ((profile.actions[actIndex].currentValue >= profile.actions[actIndex].ampMin) 
                 and (profile.actions[actIndex].currentValue<=profile.actions[actIndex].ampMax)):
                profile.actions[actIndex].evaluate(True)
            else:
                profile.actions[actIndex].evaluate(False)
        mousePos = (wx.GetMouseState().GetX(),wx.GetMouseState().GetY())
        wait=False
        self.raw = max (abs(float(min(bciDevice.working_Data(0)[-385:-1]))/ float(bciDevice.calibration(0))),
                        abs(float(max(bciDevice.working_Data(0)[-385:-1]))/ float(bciDevice.calibration(0))))
        if (current.outputMode and profile.qfEnabled): # Quickfire
                if (profile.qfThreshold*20.0) <= self.raw:
                        inputFaker.keyHold(profile.qfAction)
                else:
                        inputFaker.keyRelease(profile.qfAction)
        if (current.outputMode):
            inputFaker.flush()
        if (wx.GetKeyState(wx.WXK_CONTROL) and wx.GetKeyState(wx.WXK_END)): 
            if current.outputMode:                     # switch output-mode off
                self.settingPanel.outputSwitch()
        elif (wx.GetKeyState(wx.WXK_CONTROL) and wx.GetKeyState(wx.WXK_HOME)):
            if not(current.outputMode):                # switch output-mode on
                self.settingPanel.outputSwitch()
        for i in range(len(bciDevice.devices)):
            self.settingPanel.rawSPSs[i].SetLabel("Device "+str(i)+" Raw Samples per second: "+str(bciDevice.devices[i].currentSamplesPerSecond))
        self.qfSignalSlider.SetValue(int(self.raw*50.0))
        if (profile.qfEnabled):
            if (profile.qfThreshold*20.0) <= self.raw:
                self.settingPanel.qfStatusPanel.SetBackgroundColour('#E68000')
            else:
                self.settingPanel.qfStatusPanel.SetBackgroundColour('#000000')
        else:
            self.settingPanel.qfStatusPanel.SetBackgroundColour('#505050')
        if (len(profile.actions)>0):
            self.settingPanel.actionsPanels.actionSignalSlider.SetValue((int)(profile.actions[self.settingPanel.actionsPanels.actIndex].currentValue*1000.0))
            if profile.actions[self.settingPanel.actionsPanels.actIndex].disabled:
                self.settingPanel.actionsPanels.actionStatus.SetBackgroundColour('#505050')
            else:
                if profile.actions[self.settingPanel.actionsPanels.actIndex].active:
                    self.settingPanel.actionsPanels.actionStatus.SetBackgroundColour('#5050FF')
                else:
                    self.settingPanel.actionsPanels.actionStatus.SetBackgroundColour('#000000')
        ev.Skip()

class NiaDirectFeedbackApp(wx.App):
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
        else:
                bmp = self.make_grad_image(32,32, (0,0,0), (0,0,0))
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
    global settings
    global profile
    global inputFaker
    global bciDevice
    global current
    global keycodelistlabels
    global niaDirectFeedbackApp
    inputFaker = OutputManager.InputFaker()
    if inputFaker == -1:
        print "Import-Error: You need either Win32con (Windows) or XLib (Linux, Mac)"
    else:
        keycodelistlabels = sorted(["Action: "+each for each in inputFaker.actions.keys()])
        profile = ProfileSettings()

        if (profName==""):
            if len(sys.argv)==2:
                profilefile = sys.argv[1]
                if os.path.exists(profilefile+".feedback"):
                    workfile = open(profilefile+".feedback", "r")
                    profile = pickle.load(workfile)
                    workfile.close()
                else:
                    print "no "+profilefile+".feedback"+" file found"
                    selection = WXElements.selection("Select your Device",InputManager.SupportedDevices.keys()[0],InputManager.SupportedDevices.keys())
                    profile.deviceName = selection
            else:
                selection = WXElements.selection("Select your Device",InputManager.SupportedDevices.keys()[0],InputManager.SupportedDevices.keys())
                profile.deviceName = selection
        else:
                profilefile = profName
                if os.path.exists(profilefile+".feedback"):
                    workfile = open(profilefile+".feedback", "r")
                    profile = pickle.load(workfile)
                    workfile.close()
                else:
                    profile.profileName = profilefile
        bciDevice =  InputManager.BCIDevice(profile.deviceName)
        current = Current_Data()
        niaDirectFeedbackApp = NiaDirectFeedbackApp()
        niaDirectFeedbackApp.MainLoop()
        bciDevice.quit()

if __name__ == "__main__":
    run()
