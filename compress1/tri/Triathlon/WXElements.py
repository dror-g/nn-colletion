#!/usr/bin/python

# Howto, Code license, Credits, etc: http://sourceforge.net/projects/triathlon/


import wx

class SelectionGUI(wx.Frame):
    def __init__(self,title,selection,choices):
        wx.Frame.__init__(self,None,title=title,size=(300,100))
        self.panel = wx.Panel(self, wx.ID_ANY)
        sizer = wx.FlexGridSizer(2,1,0,0)
        self.wxChoice = wx.Choice(self.panel, choices=choices)
        position = self.wxChoice.FindString(selection)
        if position == -1:
             position=0    
        self.wxChoice.SetSelection(position)    
        sizer.AddGrowableRow(0)
        sizer.AddGrowableCol(0)
        sizer.Add(self.wxChoice, 0, wx.ALIGN_CENTER, 5)
        self.okButton  = wx.Button(self.panel, id=-1, label='OK')
        self.okButton.Bind(wx.EVT_BUTTON, self.ok)
        sizer.AddGrowableRow(1)
        sizer.Add(self.okButton, 0, wx.ALIGN_CENTER, 5)
        self.panel.SetSizer(sizer)
        self.panel.Layout()
    def ok(self, event):
        global selected 
        selected = self.wxChoice.GetStringSelection()
        self.Close()

class SelectionApp(wx.App):
    def __init__(self,title,selection,choices, redirect = False):
        wx.App.__init__(self)
        self.mainWindow = SelectionGUI(title,selection,choices)
        self.mainWindow.Center()
        self.mainWindow.Show(True)

def selection(title,selection,choices):
    global selected
    selected = selection
    selector = SelectionApp(title,selection,choices)
    selector.MainLoop()
    return selected
